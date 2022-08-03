// Vertex shader

struct CameraUniform {
    view_pos: vec4<f32>,
    view_proj: mat4x4<f32>,
};
@group(0)
@binding(0)
var<uniform> camera: CameraUniform;

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
};

struct InstanceInput {
    @location(5) model_matrix_0: vec4<f32>,
    @location(6) model_matrix_1: vec4<f32>,
    @location(7) model_matrix_2: vec4<f32>,
    @location(8) model_matrix_3: vec4<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
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

    let world_position = model_matrix * vec4<f32>(model.position, 1.0);

    var out: VertexOutput;
    out.clip_position = camera.view_proj * world_position;
    return out;
}

// Fragment shader

struct FragmentInput {
    @builtin(front_facing) front_facing: bool,
    @builtin(position) clip_position: vec4<f32>,
};

struct FragmentOutput {
    @location(0) depth: vec4<f32>,
};

let near: f32 = 0.1; 
let far: f32  = 100.0; 
  
fn linearize_depth(depth: f32) -> f32
{
    var z = depth * 2.0 - 1.0; // back to NDC 
    return (2.0 * near) / (far + near - z * (far - near));	
}

@fragment
fn fs_main(in: FragmentInput) -> FragmentOutput {
    var depth = linearize_depth(in.clip_position.z);
    var out: FragmentOutput;
    if (in.front_facing) {
        out.depth = vec4<f32>(linearize_depth(in.clip_position.z), 1.0, 1.0, 1.0);
    } else {
        out.depth = vec4<f32>(1.0, linearize_depth(in.clip_position.z), 1.0, 1.0);
    }

    return out;
}
