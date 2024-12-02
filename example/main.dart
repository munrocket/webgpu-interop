import 'dart:js_interop';
import 'package:web/web.dart';
import 'package:webgpu_interop/webgpu_interop.dart';

late GPUDevice? device;

void main(List<String> args) async {
  print('drawing triangle with webgpu...');

  var gpu = window.navigator.gpu;
  if (gpu == null) {
    print('navigator.gpu not exist!');
    return;
  }

  var adapter = await gpu!.requestAdapter().toDart;
  var device = await adapter!.requestDevice().toDart;
  if (device == null) {
    print('webgpu device not exist!');
    return;
  }

  var canvas = document.getElementById('canvas') as HTMLCanvasElement;
  var context = canvas.getContext('webgpu') as GPUCanvasContext?;
  if (context == null) {
    print('webgpu context not exist!');
    return;
  }
  canvas.height = (canvas.clientHeight * window.devicePixelRatio) as int;
  canvas.width = (canvas.clientWidth * window.devicePixelRatio) as int;

  var format = window.navigator.gpu!.getPreferredCanvasFormat();
  context!.configure(GPUCanvasConfiguration(
    device: device,
    format: format,
  ));

  var module = device.createShaderModule(GPUShaderModuleDescriptor(
    label: 'our hardcoded red triangle shaders',
    code: '''
      @vertex fn vs(
        @builtin(vertex_index) vertexIndex : u32
      ) -> @builtin(position) vec4f {
        var pos = array<vec2f, 3>(
          vec2f( 0.0,  0.5),  // top center
          vec2f(-0.5, -0.5),  // bottom left
          vec2f( 0.5, -0.5)   // bottom right
        );
        return vec4f(pos[vertexIndex], 0.0, 1.0);
      }
      @fragment fn fs() -> @location(0) vec4f {
        return vec4f(1.0, 0.0, 0.0, 1.0);
      }
    ''',
  ));

  var pipeline = device.createRenderPipeline(GPURenderPipelineDescriptor(
    label: 'our hardcoded red triangle pipeline',
    layout: 'auto' as JSAny,
    vertex: GPUVertexState(
      module: module,
      entryPoint: 'vs',
    ),
    fragment: GPUFragmentState(
      module: module,
      entryPoint: 'fs',
      targets: [ // Changed from JSArray to a Dart list
        GPUColorTargetState(format: format)
      ] as JSArray<GPUColorTargetState>,
    ),
  ));

  var color = GPURenderPassColorAttachment(
    view: context!.getCurrentTexture().createView(),
    clearValue: [0.3, 0.3, 0.3, 1] as JSObject,
    loadOp: 'clear',
    storeOp: 'store',
  );
  var renderPassDescriptor = GPURenderPassDescriptor(
    label: 'our basic canvas renderPass',
    colorAttachments: [
      color,
    ] as JSArray<GPURenderPassColorAttachment>,
  );

  void render() {
    var encoder = device.createCommandEncoder(GPUCommandEncoderDescriptor(label: 'our encoder'));
    var pass = encoder.beginRenderPass(renderPassDescriptor);
    pass.setPipeline(pipeline);
    pass.draw(3);  // call our vertex shader 3 times
    pass.end();

    var commandBuffer = encoder.finish();
    device.queue.submit([commandBuffer] as JSArray<GPUCommandBuffer>);
  }

  render();
}