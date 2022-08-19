use anyhow::{Context, Result};
use winit::window::Window;

pub struct RenderContext {
    instance: wgpu::Instance,
    surface: wgpu::Surface,
    adapter: wgpu::Adapter,
    device: wgpu::Device,
    queue: wgpu::Queue,
    config: wgpu::SurfaceConfiguration,
}

impl RenderContext {
    pub async fn create(window: &Window, backends: wgpu::Backends) -> Result<Self> {
        let instance = wgpu::Instance::new(backends);
        let surface = unsafe { instance.create_surface(&window) };
        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::HighPerformance,
                compatible_surface: Some(&surface),
                force_fallback_adapter: false,
            })
            .await
            .context("Adapter creation failed")?;

        let (device, queue) = adapter
            .request_device(
                &wgpu::DeviceDescriptor {
                    features: wgpu::Features::POLYGON_MODE_LINE,
                    limits: wgpu::Limits::default(),
                    label: None,
                },
                None,
            )
            .await
            .context("Device creation failed")?;

        let winit::dpi::PhysicalSize { width, height } = window.inner_size();
        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::COPY_SRC,
            format: surface.get_supported_formats(&adapter)[0],
            present_mode: wgpu::PresentMode::Fifo,
            width,
            height,
        };
        surface.configure(&device, &config);

        log::debug!("Created RenderContext: {:#?}", config);

        Ok(Self {
            instance,
            surface,
            adapter,
            device,
            queue,
            config,
        })
    }
}
