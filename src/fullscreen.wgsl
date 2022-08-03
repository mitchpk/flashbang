struct CameraUniform {
    proj: mat4x4<f32>,
    proj_inv: mat4x4<f32>,
    view: mat4x4<f32>,
    pos: vec4<f32>,
};
@group(1)
@binding(0)
var<uniform> camera: CameraUniform;

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
};

@vertex
fn vs_main(
    @location(0) pos: vec3<f32>
) -> VertexOutput {
    var out: VertexOutput;
    out.clip_position = vec4<f32>(pos, 1.0);
    out.tex_coords = vec2<f32>(0.5 * (pos.x + 1.0), 0.5 * (-pos.y + 1.0));
    return out;
}

// Fragment shader

struct FragmentInput {
    @location(0) tex_coords: vec2<f32>,
};

@group(0)
@binding(0)
var t_albedo: texture_2d<f32>;
@group(0)
@binding(1)
var s_albedo: sampler;

@group(0)
@binding(2)
var t_depth: texture_2d<f32>;
@group(0)
@binding(3)
var s_depth: sampler;

@group(0)
@binding(4)
var t_position: texture_2d<f32>;
@group(0)
@binding(5)
var s_position: sampler;

@group(0)
@binding(6)
var t_normal: texture_2d<f32>;
@group(0)
@binding(7)
var s_normal: sampler;

@group(0)
@binding(8)
var t_last_frame: texture_2d<f32>;
@group(0)
@binding(9)
var s_last_frame: sampler;

@group(0)
@binding(10)
var t_skybox: texture_cube<f32>;
@group(0)
@binding(11)
var s_skybox: sampler;

let near: f32 = 0.1; 
let far: f32  = 100.0; 
  
fn linearize_depth(depth: f32) -> f32 {
    var z = depth * 2.0 - 1.0; // back to NDC 
    return (2.0 * near) / (far + near - z * (far - near));	
}

fn perpendicular(input: vec3<f32>) -> vec3<f32> {
    let sx = sign((sign(input.x) + 0.5) * (sign(input.z) + 0.5));
    let sy = sign((sign(input.y) + 0.5) * (sign(input.z) + 0.5));
    return vec3<f32>(
        sx * input.z,
        sy * input.z, 
        -sx * input.x - sy * input.y);
}

fn cos_hemisphere(rand: vec2<f32>, normal: vec3<f32>) -> vec3<f32> {
    let bitangent = normalize(perpendicular(normal));
    let tangent = cross(bitangent, normal);
    let r = sqrt(rand.x);
    let phi = 2.0 * 3.14159265 * rand.y;

    return tangent * (r * cos(phi)) + bitangent * (r * sin(phi)) + normal * sqrt(max(0.0, 1.0 - rand.x));
}

fn sample_light(position: vec3<f32>, direction: vec3<f32>, offset: vec3<f32>) -> f32 {
    var position = position + offset;
    var step_size = 0.01;
    for (var s = 0; s < 12; s++) {
        position += normalize(direction) * step_size;
        //position += vec3<f32>(1.0, 1.0, 0.0);
        var clip_pos = camera.view * vec4<f32>(position, 1.0);
        var ndc_pos = clip_pos.xyz / clip_pos.w;
        ndc_pos.y = -ndc_pos.y;
        var screen_pos = (ndc_pos.xyz + 1.0) / 2.0;
        if (screen_pos.x < 0.0 || screen_pos.y < 0.0 || screen_pos.x > 1.0 || screen_pos.y > 1.0) {
            break; 
        }
        var screen_depth = linearize_depth(ndc_pos.z);
        //return depth;
        var light = textureSample(t_last_frame, s_last_frame, screen_pos.xy);
        var depth = textureSample(t_depth, s_depth, screen_pos.xy);
        var normal = textureSample(t_normal, s_normal, screen_pos.xy);
        var backface = clamp(dot(-normal.xyz, direction) * 100.0, 0.0, 1.0);
        if (screen_depth > depth.r && screen_depth < depth.g) {
            return light.r * backface;
        }
        step_size *= 2.0;
    }
    return (dot(direction, vec3<f32>(0.0, 1.0, 0.0)) + 1.0) / 2.0;
}

fn noise(pos: vec2<f32>) -> f32 {
    return (52.9829189 * ((0.06711056 * pos.x + 0.00583715 * pos.y) % 1.0)) % 1.0;
}

@fragment
fn fs_main(in: FragmentInput) -> @location(0) vec4<f32> {
    var depth = textureSample(t_depth, s_depth, in.tex_coords.xy);
    var albedo = textureSample(t_albedo, s_albedo, in.tex_coords.xy).xyz;
    var position = textureSample(t_position, s_position, in.tex_coords.xy).xyz;
    var normal = textureSample(t_normal, s_normal, in.tex_coords.xy).xyz;
    let noise = noise(in.tex_coords * vec2<f32>(800.0, 600.0));
    let weighted_normal = normalize(cos_hemisphere(vec2<f32>(noise, noise), normal));

    let inv_model_view = transpose(mat3x3<f32>(camera.view.x.xyz, camera.view.y.xyz, camera.view.z.xyz));
    let unprojected = camera.proj_inv * vec4<f32>(in.tex_coords * 2.0 - 1.0, 1.0, 1.0);
    //var total_light = sample_light(position, vec3<f32>(1.0, 1.0, 1.0), normal, depth.r) +
    //    sample_light(position, vec3<f32>(1.0, 1.0, -1.0), normal, depth.r) +
    //    sample_light(position, vec3<f32>(1.0, -1.0, 1.0), normal, depth.r) +
    //    sample_light(position, vec3<f32>(1.0, -1.0, -1.0), normal, depth.r) +
    //    sample_light(position, vec3<f32>(-1.0, 1.0, 1.0), normal, depth.r) +
    //    sample_light(position, vec3<f32>(-1.0, 1.0, -1.0), normal, depth.r) +
    //    sample_light(position, vec3<f32>(-1.0, -1.0, 1.0), normal, depth.r) +
    //    sample_light(position, vec3<f32>(-1.0, -1.0, -1.0), normal, depth.r);
    //total_light /= 8.0;
    //return vec4<f32>(vec3<f32>(total_light), 1.0);
    //return vec4<f32>(depth.g - depth.r, depth.a - depth.b, 0.0, 1.0);
    //return depth;
    //var clip_pos = camera.view_proj * vec4<f32>(position, 1.0);
    //var ndc_pos = clip_pos.xyz / clip_pos.w;
    //ndc_pos.y = -ndc_pos.y;
    //var screen_pos = (ndc_pos.xyz + 1.0) / 2.0;
    //var screen_depth = linearize_depth(ndc_pos.z);
    //return vec4<f32>(vec3<f32>(depth.r), 1.0);
    //return vec4<f32>(vec3<f32>(sample_light(position, weighted_normal, normal * (0.001 + depth.r * 0.1))), 1.0);
    return textureSample(t_skybox, s_skybox, inv_model_view * unprojected.xyz);
    //return vec4<f32>((weighted_normal + 1.0) / 2.0, 1.0);
    //if (in.tex_coords.x < 0.5) {
    //    return vec4<f32>(vec3<f32>(screen_depth), 1.0);
    //} else {
    //    return vec4<f32>(vec3<f32>(depth.r), 1.0);
    //}
    //return vec4<f32>((normal + 1.0) / 2.0, 1.0);
    //return depth / 100.0;
    //return vec4<f32>(in.tex_coords, 0.0, 1.0);
    //return textureSample(t_albedo, s_albedo, screen_pos);
    //if (in.tex_coords.x < 0.5) {
    //    return vec4<f32>(screen_pos.xy, 0.0, 1.0);
    //} else {
    //    return vec4<f32>(in.tex_coords.xy, 0.0, 1.0);
    //}
}