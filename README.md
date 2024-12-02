# webgpu_interop

Dart interop for web applications

## Roadmap

- [x] it works
- [x] script for IDL update
- [ ] compute example

## Getting started

Install package, web builder and activate webdev
```
dart create -t web quickstart
dart pub add webgpu_interop
dart pub global activate webdev
```
Add <canvas> to HTML template, make it fullscreen in CSS.
```
webdev serve web:3000 --release --auto restart
```

## Usage

Try with triangle example in repo at first.
```
dart pub global activate webdev
webdev serve example:3000 --release --auto restart
```
Adopt any [sample in JS](https://webgpu.github.io/webgpu-samples/?sample=helloTriangle) to Dart. If something wrong with `webdev` try to deactive or remove `.dart_tool`.

## Additional information

This library is created directly from WebIDL with web_generator and patched.
For this you will need [latest SDK](https://dart.dev/get-dart/archive).