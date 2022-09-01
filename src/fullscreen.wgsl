struct CameraUniform {
    pos: vec3<f32>,
    dir: vec3<f32>,
    right: vec3<f32>,
    up: vec3<f32>,
    aspect: f32,
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
    out.tex_coords = vec2<f32>(pos.x, -pos.y);
    return out;
}

// Fragment shader

struct Light {
    position: vec3<f32>,
    colour: vec3<f32>,
    strength: f32,
    radius: f32,
}
@group(3)
@binding(0)
var<storage, read> lights: array<Light>;

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

@group(2)
@binding(0)
var<uniform> frame_count: f32;

let NUMBER_OF_STEPS: i32 = 128;
let MINIMUM_HIT_DISTANCE: f32 = 0.001;
let MAXIMUM_TRACE_DISTANCE: f32 = 1000.0;
let EPSILON: f32 = 0.0001;

fn sd_sphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sd_box(p: vec3<f32>, b: vec3<f32>) -> f32 {
    let q = abs(p) - b;
    return length(max(q, vec3<f32>(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

fn op_union(d1: f32, d2: f32) -> f32 {
    return min(d1, d2);
}

fn op_difference(d1: f32, d2: f32) -> f32 {
    return max(d1, -d2);
}

fn op_intersect(d1: f32, d2: f32) -> f32 {
    return max(d1, d2);
}

fn scene(p: vec3<f32>) -> f32 {
    return op_intersect(sd_box(p, vec3<f32>(1.0, 0.8, 0.7)), sd_sphere(p, 0.9));
}

fn estimate_normal(p: vec3<f32>) -> vec3<f32> {
    let k = vec2<f32>(1.0, -1.0);
    return normalize(
        k.xyy * scene(p + k.xyy * EPSILON) +
        k.yyx * scene(p + k.yyx * EPSILON) +
        k.yxy * scene(p + k.yxy * EPSILON) +
        k.xxx * scene(p + k.xxx * EPSILON)
    );
}

fn ray_march(ro: vec3<f32>, rd: vec3<f32>) -> vec3<f32> {
    var total_distance_travelled = 0.0;
    let skybox = textureSample(t_skybox, s_skybox, rd).xyz; 
    
    for (var i = 0; i < NUMBER_OF_STEPS; i++) {
        let current_position = ro + total_distance_travelled * rd;
        let distance_to_closest = scene(current_position);
        if (distance_to_closest < MINIMUM_HIT_DISTANCE) {
            let albedo = estimate_normal(current_position);
            return (albedo + 1.0) / 2.0;
        }
        if (total_distance_travelled > MAXIMUM_TRACE_DISTANCE) {
            break;
        }
        total_distance_travelled += distance_to_closest;
    }
    
    return skybox;
}
  
@fragment
fn fs_main(in: FragmentInput) -> @location(0) vec4<f32> {
    let p = vec2<f32>(in.tex_coords.x * camera.aspect, in.tex_coords.y);
    let ray_dir = normalize(p.x * camera.right + p.y * camera.up + 1.5 * camera.dir);
    let albedo = ray_march(camera.pos, ray_dir);
    return vec4<f32>(albedo, 1.0);
}
