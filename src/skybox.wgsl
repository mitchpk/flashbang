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

@group(0)
@binding(0)
var t_panorama: texture_2d<f32>;
@group(0)
@binding(1)
var s_panorama: sampler;

@group(0)
@binding(2)
var<uniform> current_face: i32;

let PI: f32 = 3.14159265;

fn uv_to_xyz(uv: vec2<f32>) -> vec3<f32> {
    if (current_face == 0) {
        return vec3<f32>(1.0, uv.y, -uv.x);
    } else if (current_face == 1) {
        return vec3<f32>(-1.0, uv.y, uv.x);
    } else if (current_face == 2) {
        return vec3<f32>(uv.x, -1.0, uv.y);
    } else if (current_face == 3) {
        return vec3<f32>(uv.x, 1.0, -uv.y);
    } else if (current_face == 4) {
        return vec3<f32>(uv.x, uv.y, 1.0);
    } else {
        return vec3<f32>(-uv.x, uv.y, -1.0);
    }
}

fn dir_to_uv(dir: vec3<f32>) -> vec2<f32> {
    return vec2<f32>(
        0.5 + 0.5 * atan2(dir.z, dir.x) / PI,
        1.0 - acos(dir.y) / PI
    );
}

fn panorama_to_cubemap(tex_coords: vec2<f32>) -> vec3<f32> {
    let scan = uv_to_xyz(tex_coords);
    let direction = normalize(scan);
    let src = dir_to_uv(direction);
    return textureSample(t_panorama, s_panorama, src).xyz;
}

@fragment
fn fs_main(@location(0) tex_coords: vec2<f32>) -> @location(0) vec4<f32> {
    return vec4<f32>(panorama_to_cubemap(tex_coords), 1.0);
}
