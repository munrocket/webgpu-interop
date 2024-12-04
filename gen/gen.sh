rm -rf web
gh repo clone dart-lang/web
cd web/web_generator/
dart pub install

dart --version
#udpate SDK to lates beta version
#open https://docs.flutter.dev/release/archive
dart bin/update_bindings.dart --generate-all

# fix minor errors and update WebIDL
cat ../../fix.dart >> ?/webgpu.dart
cp ?/webgpu.dart ../../../lib/generated.dart