import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' hide Uint32List;
import 'package:webgpu_interop/webgpu_interop.dart';
import 'package:fetch_api/fetch_api.dart';

import 'res/blur.wgsl.dart';
import 'res/quad.wgsl.dart';

// Constants from the blur.wgsl shader.
const int tileDim = 128;
const List<int> batch = [4, 4];
//late GPUDevice? device;

void init() async {
  
  final GPU? gpu = window.navigator.gpu;
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

  final devicePixelRatio = window.devicePixelRatio;
  canvas.width = (canvas.clientWidth * devicePixelRatio).toInt();
  canvas.height = (canvas.clientHeight * devicePixelRatio).toInt();
  final presentationFormat = window.navigator.gpu!.getPreferredCanvasFormat();

  context.configure(GPUCanvasConfiguration(
    device: device,
    format: presentationFormat,
  ));

  final blurPipeline = device.createComputePipeline(GPUComputePipelineDescriptor(
    layout: 'auto' as JSAny,
    compute: GPUProgrammableStage(
      module: device.createShaderModule(GPUShaderModuleDescriptor(
        code: blur_wgsl,
      )),
    ),
  ));

  final quadPipeline = device.createRenderPipeline(GPURenderPipelineDescriptor(
    layout: 'auto' as JSAny,
    vertex: GPUVertexState(
      module: device.createShaderModule(GPUShaderModuleDescriptor(
        code: quad_wgsl,
      )),
    ),
    fragment: GPUFragmentState(
      module: device.createShaderModule(GPUShaderModuleDescriptor(
        code: quad_wgsl,
      )),
      targets: [
        (
          format: presentationFormat,
        ),
      ] as JSArray<GPUColorTargetState>,
    ),
    primitive: GPUPrimitiveState(
      topology: 'triangle-list',
    ),
  ));

  final sampler = device.createSampler(GPUSamplerDescriptor(
    magFilter: 'linear',
    minFilter: 'linear',
  ));

  final response = await fetch('./res/image.png');
  final blob = await response.blob() as ImageBitmapSource;
  final imageBitmap = await window.createImageBitmap(blob).toDart;

  final srcWidth = imageBitmap.width;
  final srcHeight = imageBitmap.height;
  final imageTexture = device.createTexture(GPUTextureDescriptor(
    size: [srcWidth, srcHeight, 1] as JSObject,
    format: 'rgba8unorm',
    usage: $GPUTextureUsage.TEXTURE_BINDING |
      $GPUTextureUsage.COPY_DST |
      $GPUTextureUsage.RENDER_ATTACHMENT,
  ));
  device.queue.copyExternalImageToTexture(
    GPUImageCopyExternalImage(source: imageBitmap),
    GPUImageCopyTextureTagged(texture: imageTexture),
    [imageBitmap.width, imageBitmap.height] as JSObject
  );

  final textures = [0, 1].map((_) => 
    device.createTexture(GPUTextureDescriptor(
      size: [srcWidth, srcHeight, 1] as JSObject,
      format: 'rgba8unorm',
      usage: $GPUTextureUsage.COPY_DST |
              $GPUTextureUsage.STORAGE_BINDING |
              $GPUTextureUsage.TEXTURE_BINDING,
    ))
  ).toList();

  // A buffer with 0 in it. Binding this buffer is used to set `flip` to 0
  final buffer0 = (() {
    final buffer = device.createBuffer(GPUBufferDescriptor(
      label: 'buffer0',
      size: 4,
      mappedAtCreation: true,
      usage: $GPUBufferUsage.UNIFORM,
    ));
    final buf = buffer.getMappedRange() as ByteBuffer;
    Uint32List.view(buf, 0, 1)[0] = 0;
    buffer.unmap();
    return buffer;
  })();

  // A buffer with 1 in it. Binding this buffer is used to set `flip` to 1
  final buffer1 = (() {
    final buffer = device.createBuffer(GPUBufferDescriptor(
      label: 'buffer1',
      size: 4,
      mappedAtCreation: true,
      usage: $GPUBufferUsage.UNIFORM,
    ));
    final buf = buffer.getMappedRange() as ByteBuffer;
    Uint32List.view(buf, 0, 1)[0] = 1;
    buffer.unmap();
    return buffer;
  })();

  final blurParamsBuffer = device.createBuffer(GPUBufferDescriptor(
    label: 'blurParamsBuffer',
    size: 8,
    usage: $GPUBufferUsage.COPY_DST | $GPUBufferUsage.UNIFORM,
  ));

  final computeConstants = device.createBindGroup(GPUBindGroupDescriptor(
    layout: blurPipeline.getBindGroupLayout(0),
    entries: [
      GPUBindGroupEntry(
        binding: 0,
        resource: sampler,
      ),
      GPUBindGroupEntry(
        binding: 1,
        resource: GPUBindingResource(
          buffer: blurParamsBuffer
        )
      ),
    ] as JSArray<GPUBindGroupEntry>,
  ));

  final computeBindGroup0 = device.createBindGroup(GPUBindGroupDescriptor(
    layout: blurPipeline.getBindGroupLayout(1),
    entries: [
      GPUBindGroupEntry(
        binding: 1,
        resource: imageTexture.createView(),
      ),
      GPUBindGroupEntry(
        binding: 2,
        resource: textures[0].createView(),
      ),
      GPUBindGroupEntry(
        binding: 3,
        resource: GPUBindingResource(
          buffer: buffer0,
        ),
      ),
    ] as JSArray<GPUBindGroupEntry>,
  ));

  final computeBindGroup1 = device.createBindGroup(GPUBindGroupDescriptor(
    layout: blurPipeline.getBindGroupLayout(1),
    entries: [
      GPUBindGroupEntry(
        binding: 1,
        resource: textures[0].createView(),
      ),
      GPUBindGroupEntry(
        binding: 2,
        resource: textures[1].createView(),
      ),
      GPUBindGroupEntry(
        binding: 3,
        resource: GPUBindingResource(
          buffer: buffer1,
        ),
      ),
    ] as JSArray<GPUBindGroupEntry>,
  ));

  final computeBindGroup2 = device.createBindGroup(GPUBindGroupDescriptor(
    layout: blurPipeline.getBindGroupLayout(1),
    entries: [
      GPUBindGroupEntry(
        binding: 1,
        resource: textures[1].createView(),
      ),
      GPUBindGroupEntry(
        binding: 2,
        resource: textures[0].createView(),
      ),
      GPUBindGroupEntry(
        binding: 3,
        resource: GPUBindingResource(
          buffer: buffer0,
        ),
      ),
    ] as JSArray<GPUBindGroupEntry>,
  ));

  final showResultBindGroup = device.createBindGroup(GPUBindGroupDescriptor(
    layout: quadPipeline.getBindGroupLayout(0),
    entries: [
      GPUBindGroupEntry(
        binding: 0,
        resource: sampler,
      ),
      GPUBindGroupEntry(
        binding: 1,
        resource: textures[1].createView(),
      ),
    ] as JSArray<GPUBindGroupEntry>,
  ));

  final settings = (
    filterSize: 15,
    iterations: 2,
  );

  late int blockDim;
  void updateSettings() {
    blockDim = tileDim - (settings.filterSize - 1);
    device.queue.writeBuffer(
      blurParamsBuffer,
      0,
      Uint32List.fromList([settings.filterSize, blockDim]) as JSObject
    );
  }

  updateSettings();

  void render() {
    final commandEncoder = device.createCommandEncoder();

    final computePass = commandEncoder.beginComputePass();
    computePass.setPipeline(blurPipeline);
    computePass.setBindGroup(0, computeConstants);

    computePass.setBindGroup(1, computeBindGroup0);
    computePass.dispatchWorkgroups(
      (srcWidth / blockDim).ceil(),
      (srcHeight / batch[1]).ceil()
    );

    computePass.setBindGroup(1, computeBindGroup1);
    computePass.dispatchWorkgroups(
      (srcHeight / blockDim).ceil(),
      (srcWidth / batch[1]).ceil()
    );

    for (var i = 0; i < settings.iterations - 1; ++i) {
      computePass.setBindGroup(1, computeBindGroup2);
      computePass.dispatchWorkgroups(
        (srcWidth / blockDim).ceil(),
        (srcHeight / batch[1]).ceil()
      );

      computePass.setBindGroup(1, computeBindGroup1);
      computePass.dispatchWorkgroups(
        (srcHeight / blockDim).ceil(),
        (srcWidth / batch[1]).ceil()
      );
    }

    computePass.end();

    final passEncoder = commandEncoder.beginRenderPass(GPURenderPassDescriptor(
      colorAttachments: [
        GPURenderPassColorAttachment(
          view: context.getCurrentTexture().createView(),
          clearValue: [0.0, 0.0, 0.0, 1.0] as JSObject,
          loadOp: 'clear',
          storeOp: 'store',
        ),
      ] as JSArray<GPURenderPassColorAttachment>,
    ));

    passEncoder.setPipeline(quadPipeline);
    passEncoder.setBindGroup(0, showResultBindGroup);
    passEncoder.draw(6);
    passEncoder.end();
    device.queue.submit([commandEncoder.finish()] as JSArray<GPUCommandBuffer>);

    requestAnimationFrame(render.toJS);
  }
  requestAnimationFrame(render.toJS);
}

void main(List<String> args) async {
  init();
}