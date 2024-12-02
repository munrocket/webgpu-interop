rm -rf web
gh repo clone dart-lang/web
cd web/web_generator/
dart pub install

dart --version
#https://dart.dev/get-dart/archive
#curl -O https://storage.googleapis.com/dart-archive/channels/dev/release/3.6.0-0.0.dev/sdk/dartsdk-linux-x64-release.zip

dart bin/update_bindings.dart --generate-all
cat ../../patch.dart >> webgpu.dart
cp webgpu.dart ../../../lib/webgpu_interop.dart