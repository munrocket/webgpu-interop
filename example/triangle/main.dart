import 'dart:js_interop';
import 'package:web/web.dart';
import 'package:webgpu_interop/webgpu_interop.dart';

late GPUDevice? device;

void main(List<String> args) async {
  final gpu = window.navigator.gpu;
  if (gpu == null) {
    print('navigator.gpu not exist!');
    return;
  }

  final adapter = await gpu.requestAdapter().toDart;
  final device = await adapter!.requestDevice().toDart;
  if (device == null) {
    print('webgpu device not exist!');
    return;
  }

  final canvas = document.getElementById('canvas') as HTMLCanvasElement;
  final context = canvas.getContext('webgpu') as GPUCanvasContext?;
  if (context == null) {
    print('webgpu context not exist!');
    return;
  }
  canvas.height = (canvas.clientHeight * window.devicePixelRatio) as int;
  canvas.width = (canvas.clientWidth * window.devicePixelRatio) as int;

  final format = window.navigator.gpu!.getPreferredCanvasFormat();
  context.configure(GPUCanvasConfiguration(
    device: device,
    format: format,
  ));

  final module = device.createShaderModule(GPUShaderModuleDescriptor(
    label: 'red triangle shaders',
    code: '''
      @vertex
      fn vs(@builtin(vertex_index) VertexIndex : u32) -> @builtin(position) vec4f {
        var pos = array<vec2f, 3>(
          vec2(0.0, 0.5),
          vec2(-0.5, -0.5),
          vec2(0.5, -0.5)
        );
        return vec4f(pos[VertexIndex], 0.0, 1.0);
      }
      @fragment
      fn fs() -> @location(0) vec4f {
        return vec4f(1.0, 0.0, 0.0, 1.0);
      }
    ''',
  ));

  final pipeline = device.createRenderPipeline(GPURenderPipelineDescriptor(
    label: 'our hardcoded red triangle pipeline',
    layout: 'auto' as JSAny,
    vertex: GPUVertexState(
      module: module,
      entryPoint: 'vs',
    ),
    fragment: GPUFragmentState(
      module: module,
      entryPoint: 'fs',
      targets: [
        GPUColorTargetState(format: format)
      ] as JSArray<GPUColorTargetState>,
    ),
  ));

  var color = GPURenderPassColorAttachment(
    view: context.getCurrentTexture().createView(),
    clearValue: [0.3, 0.3, 0.3, 1] as JSObject,
    loadOp: 'clear',
    storeOp: 'store',
  );
  final renderPassDescriptor = GPURenderPassDescriptor(
    label: 'our basic canvas renderPass',
    colorAttachments: [
      color,
    ] as JSArray<GPURenderPassColorAttachment>,
  );

  print('drawing triangle with webgpu...');

  void render() {
    final encoder = device.createCommandEncoder(
      GPUCommandEncoderDescriptor(label: 'our encoder')
    );
    final pass = encoder.beginRenderPass(renderPassDescriptor);
    pass.setPipeline(pipeline);
    pass.draw(3);
    pass.end();

    final commandBuffer = encoder.finish();
    device.queue.submit([commandBuffer] as JSArray<GPUCommandBuffer>);
  }

  render();
}