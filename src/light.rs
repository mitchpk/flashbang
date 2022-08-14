use cgmath::Point3;

#[repr(C)]
#[derive(Debug, Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct LightUniform {
    pub position: [f32; 3],
    _padding1: u32,
    pub colour: [f32; 3],
    _padding2: u32,
    pub strength: f32,
    pub radius: f32,
    _padding3: [u32; 2],
}

impl LightUniform {
    pub fn new() -> Self {
        Self {
            position: [0.0; 3],
            _padding1: 0,
            colour: [0.0; 3],
            _padding2: 0,
            strength: 0.0,
            radius: 0.0,
            _padding3: [0; 2],
        }
    }

    pub fn update_values(&mut self, light: &Light) {
        self.position = light.position.into();
        self.colour = light.colour;
        self.strength = light.strength;
        self.radius = light.radius;
    }
}

pub struct Light {
    pub position: Point3<f32>,
    pub colour: [f32; 3],
    pub strength: f32,
    pub radius: f32,
}
