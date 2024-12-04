// === GENERATED WEBIDL ===
export './generated.dart'

// === PATCH ===

hide $GPUBufferUsage, $GPUMapMode, $GPUTextureUsage, $GPUShaderStage, $GPUColorWrite,
  GPUBindingResource;
import 'dart:js_interop' show JSObject, JS, JSNumber, JSFunction, staticInterop;
import 'package:web/web.dart' show Navigator;
import './generated.dart' show GPU, GPUBuffer;

extension NavigatorExt on Navigator {
  external GPU? get gpu;
}

extension type GPUBindingResource._(JSObject _) implements JSObject {
  external factory GPUBindingResource({
    required GPUBuffer buffer,
  });
}

@JS()
@staticInterop
external JSNumber requestAnimationFrame(JSFunction value);