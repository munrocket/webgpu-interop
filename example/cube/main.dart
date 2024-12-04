import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';
import 'package:web/web.dart' hide Float32List;
import 'package:webgpu_interop/webgpu_interop.dart';
import 'package:vector_math/vector_math.dart';
import 'package:fetch_api/fetch_api.dart';

import 'res/geom.dart';
import 'res/vert.dart';
import 'res/frag.dart';

Matrix4 perspectiveMatrix4(double fovY, double aspectRatio, double zNear, double zFar) {
  final mat = Matrix4.zero();
  final f = 1.0 / tan(fovY / 2.0);
  mat.setZero();
  mat[0] = f / aspectRatio; // Scale the x coordinates
  mat[5] = f;               // Scale the y coordinates
  mat[10] = (zFar + zNear) / (zNear - zFar); // Set the z coordinate
  mat[11] = -1.0;           // Set the perspective divide
  mat[14] = (2.0 * zFar * zNear) / (zNear - zFar); // Set the z translation
  return mat;
}

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
  final dpr = window.devicePixelRatio;
  canvas.height = (canvas.clientHeight * dpr) as int;
  canvas.width = (canvas.clientWidth * dpr) as int;

  final presenationFormat = window.navigator.gpu!.getPreferredCanvasFormat();
  context.configure(GPUCanvasConfiguration(
    device: device,
    format: presenationFormat,
  ));

  // Create a vertex buffer from the cube data.
  final verticesBuffer = device.createBuffer(GPUBufferDescriptor(
    size: cubeVertexArray.lengthInBytes,
    usage: $GPUBufferUsage.VERTEX,
    mappedAtCreation: true,
  ));

  Float32List.view(verticesBuffer.getMappedRange().toDart).setAll(0, cubeVertexArray);
  verticesBuffer.unmap();

  final pipeline = device.createRenderPipeline(GPURenderPipelineDescriptor(
    label: 'pipeline',
    layout: 'auto' as JSAny,
    
    vertex: GPUVertexState(
      module: device.createShaderModule(GPUShaderModuleDescriptor(
        code: vert_wgsl,
      )),
      buffers: [GPUVertexBufferLayout(
        arrayStride: cubeVertexSize,
        attributes: [
          GPUVertexAttribute( // position
            shaderLocation: 0,
            offset: cubePositionOffset,
            format: 'float32x4',
          ),
          GPUVertexAttribute( // uv
            shaderLocation: 1,
            offset: cubeUVOffset,
            format: 'float32x2',
          ),
        ] as JSArray<GPUVertexAttribute>,
      )] as JSArray<GPUVertexBufferLayout>,
    ),

    fragment: GPUFragmentState(
      module: device.createShaderModule(GPUShaderModuleDescriptor(
        code: frag_wgsl,
      )),
      targets: [GPUColorTargetState(
          format: presenationFormat,
      )] as JSArray<GPUColorTargetState>,
    ),

    primitive: GPUPrimitiveState(
      topology: 'triangle-list',

      // Backface culling since the cube is solid piece of geometry.
      // Faces pointing away from the camera will be occluded by faces
      // pointing toward the camera.
      cullMode: 'back',
    ),

    // Enable depth testing so that the fragment closest to the camera
    // is rendered in front.
    depthStencil: GPUDepthStencilState(
      depthWriteEnabled: true,
      depthCompare: 'less',
      format: 'depth24plus',
    ),
  ));

  final depthTexture = device.createTexture(GPUTextureDescriptor(
    size: [canvas.width, canvas.height] as JSObject,
    format: 'depth24plus',
    usage: $GPUTextureUsage.RENDER_ATTACHMENT,
  ));

  final uniformBufferSize = 4 * 16; // 4x4 matrix
  final uniformBuffer = device.createBuffer(GPUBufferDescriptor(
    size: uniformBufferSize,
    usage: $GPUBufferUsage.UNIFORM | $GPUBufferUsage.COPY_DST,
  ));

  late GPUTexture cubeTexture;
  final response = await fetch('./res/image.png');
  final blob = await response.blob() as ImageBitmapSource;
  final imageBitmap = await window.createImageBitmap(blob).toDart;

  cubeTexture = device.createTexture(GPUTextureDescriptor(
    size: [imageBitmap.width, imageBitmap.height, 1] as JSObject,
    format: 'rgba8unorm',
    usage:
      $GPUTextureUsage.TEXTURE_BINDING |
      $GPUTextureUsage.COPY_DST |
      $GPUTextureUsage.RENDER_ATTACHMENT,
  ));
  device.queue.copyExternalImageToTexture(
    GPUImageCopyExternalImage( source: imageBitmap ),
    GPUImageCopyTextureTagged( texture: cubeTexture ),
    [imageBitmap.width, imageBitmap.height] as JSObject
  );

  // Create a sampler with linear filtering for smooth interpolation.
  final sampler = device.createSampler(GPUSamplerDescriptor(
    magFilter: 'linear',
    minFilter: 'linear',
  ));

  final uniformBindGroup = device.createBindGroup(GPUBindGroupDescriptor(
    label: 'uniformBindGroup',
    layout: pipeline.getBindGroupLayout(0),
    entries: [
      GPUBindGroupEntry(
        binding: 0,
        resource: GPUBindingResource(
          buffer: uniformBuffer,
        ) as JSObject,
      ),
      GPUBindGroupEntry(
        binding: 1,
        resource: sampler as JSObject
      ),
      GPUBindGroupEntry(
        binding: 2,
        resource: cubeTexture.createView() as JSObject
      ),
    ] as JSArray<GPUBindGroupEntry>,
  ));

  final renderPassDescriptor = GPURenderPassDescriptor(
    colorAttachments: [
      GPURenderPassColorAttachment(
        view: context
          .getCurrentTexture()
          .createView(), //ERROR? HOW TO MAKE UNDEFINED
        clearValue: [0.5, 0.5, 0.5, 1.0] as JSObject,
        loadOp: 'clear',
        storeOp: 'store',
      ),
    ] as JSArray<GPURenderPassColorAttachment>,
    depthStencilAttachment: GPURenderPassDepthStencilAttachment(
      view: depthTexture.createView(),
      depthClearValue: 1.0,
      depthLoadOp: 'clear',
      depthStoreOp: 'store',
    ),
  );

  final aspect = canvas.width / canvas.height;
  final projectionMatrix = perspectiveMatrix4((2 * pi) / 5, aspect, 1, 100);

  Matrix4 getTransformationMatrix(now) {
    final t = now / 1000;
    var viewMatrix = Matrix4.identity();
    viewMatrix.translate(Vector3(0, 0, -4));
    viewMatrix.rotate(Vector3(sin(t*.3), 0, cos(t*.3)), t);
    return projectionMatrix * viewMatrix;
  }

  void frame(double now) {
    final transformationMatrix = getTransformationMatrix(now);
    device.queue.writeBuffer(
      uniformBuffer,
      0,
      transformationMatrix.storage.buffer.toJS,
      transformationMatrix.storage.offsetInBytes,
      transformationMatrix.storage.lengthInBytes
    );

    renderPassDescriptor.colorAttachments.toDart[0]!.view = context
      .getCurrentTexture()
      .createView();

    final commandEncoder = device.createCommandEncoder();
    final passEncoder = commandEncoder.beginRenderPass(renderPassDescriptor);
    passEncoder.setPipeline(pipeline);
    passEncoder.setBindGroup(0, uniformBindGroup);
    passEncoder.setVertexBuffer(0, verticesBuffer);
    passEncoder.draw(cubeVertexCount);
    passEncoder.end();
    device.queue.submit([commandEncoder.finish()] as JSArray<GPUCommandBuffer>);

    requestAnimationFrame(frame.toJS);
  }
  requestAnimationFrame(frame.toJS);
  
}