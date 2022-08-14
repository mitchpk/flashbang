// Vertex shader
struct CameraUniform {
    proj: mat4x4<f32>,
    proj_inv: mat4x4<f32>,
    view: mat4x4<f32>,
    pos: vec4<f32>,
};
@group(1)
@binding(0)
var<uniform> camera: CameraUniform;

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
    @location(2) normal: vec3<f32>,
};

struct InstanceInput {
    @location(5) model_matrix_0: vec4<f32>,
    @location(6) model_matrix_1: vec4<f32>,
    @location(7) model_matrix_2: vec4<f32>,
    @location(8) model_matrix_3: vec4<f32>,
    @location(9) normal_matrix_0: vec3<f32>,
    @location(10) normal_matrix_1: vec3<f32>,
    @location(11) normal_matrix_2: vec3<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
    @location(1) world_position: vec3<f32>,
    @location(2) world_normal: vec3<f32>,
};

@vertex
fn vs_main(
    model: VertexInput,
    instance: InstanceInput,
) -> VertexOutput {
    let model_matrix = mat4x4<f32>(
        instance.model_matrix_0,
        instance.model_matrix_1,
        instance.model_matrix_2,
        instance.model_matrix_3,
    );
    let normal_matrix = mat3x3<f32>(
        instance.normal_matrix_0,
        instance.normal_matrix_1,
        instance.normal_matrix_2,
    );

    let world_position = model_matrix * vec4<f32>(model.position, 1.0);

    var out: VertexOutput;
    out.tex_coords = model.tex_coords;
    out.clip_position = camera.proj * camera.view * world_position;
    out.world_position = world_position.xyz;
    out.world_normal = normal_matrix * model.normal;
    return out;
}

// Fragment shader

struct FragmentInput {
    @builtin(front_facing) front_facing: bool,
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
    @location(1) world_position: vec3<f32>,
    @location(2) world_normal: vec3<f32>,
};

struct FragmentOutput {
    @location(0) albedo: vec4<f32>,
    @location(1) position: vec4<f32>,
    @location(2) normal: vec4<f32>,
};

@group(0)
@binding(0)
var t_diffuse: texture_2d<f32>;
@group(0)
@binding(1)
var s_diffuse: sampler;

let near: f32 = 0.1; 
let far: f32  = 100.0; 
  
fn linearize_depth(depth: f32) -> f32
{
    var z = depth * 2.0 - 1.0; // back to NDC 
    return (2.0 * near) / (far + near - z * (far - near));	
}

@fragment
fn fs_main(in: FragmentInput) -> FragmentOutput {
    var out: FragmentOutput;
    //out.depth = vec4<f32>(vec3<f32>(linearize_depth(in.clip_position.z)), 1.0);
    out.albedo = textureSample(t_diffuse, s_diffuse, in.tex_coords);
    out.position = vec4<f32>(in.world_position, 1.0);
    out.normal = vec4<f32>(in.world_normal, 1.0);
    return out;
}
