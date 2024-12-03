// === GENERATED WEBIDL ===
export './generated.dart'

// === PATCH ===

hide $GPUBufferUsage, $GPUMapMode, $GPUTextureUsage, $GPUShaderStage, $GPUColorWrite
  , GPUBindingResource;
import 'dart:js_interop' show JS, JSNumber, JSFunction, JSObject, staticInterop;
import 'package:web/web.dart' show Navigator;
import './generated.dart' show GPU, GPUBuffer;

extension NavigatorExt on Navigator {
  external GPU? get gpu;
}

extension type GPUBindingResource._(JSObject _) implements JSObject {
  external factory GPUBindingResource({
    required GPUBuffer buffer,
  });

  external GPUBuffer get resource;
  external set resource(GPUBuffer value);
}

// extension type GPUBindGroupEntry._(JSObject _) implements JSObject {
//   external factory GPUBindGroupEntry({
//     required GPUIndex32 binding,
//     required GPUBindingResource resource,
//   });

//   external GPUIndex32 get binding;
//   external set binding(GPUIndex32 value);
//   external GPUBindingResource get resource;
//   external set resource(GPUBindingResource value);
// }

@JS()
@staticInterop
external JSNumber requestAnimationFrame(JSFunction value);