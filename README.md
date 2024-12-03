# webgpu_interop

Dart js_interop for web applications. This library is created directly from WebIDL with web_generator, [latest SDK](https://dart.dev/get-dart/archive) and patched.

### Roadmap

- [x] it works
- [x] script for IDL update
- [ ] compute example
- [ ] cube example

### Getting started

Instal Dart SDK, editor with Dart intellisense and linting, it will be much easier to adopt samples.

### Usage

Create new web project, install package and activate webdev
```
dart create -t web quickstart
dart pub add webgpu_interop
dart pub global activate webdev
```
Add <canvas> to HTML template, fullscreen CSS, copy main.dart from triangle example here and try to serve.
```
webdev serve web:3000 --debug --auto restart
```
Adopt any [WebGPU sample in JS](https://webgpu.github.io/webgpu-samples/?sample=helloTriangle) to Dart. If something will be wrong with `webdev` try to deactivate it or remove `.dart_tool`.

### Contributing and testing

Run examples in repo.
```
dart pub global activate webdev
webdev serve example:3000 --release
```
Update webgpu_interop.dart bindings
```
cd generator
./gen.sh
```

### License

MPL 2.0 is business-friendly license but you need to publish modifications. You can simply fork this repo and add your changes there.