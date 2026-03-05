// Conditionally import native or web implementation
// ignore: lines_longer_than_80_chars
export 'tflite_interpreter_service.native.dart'
    if (dart.library.js_interop) 'tflite_interpreter_service.web.dart';
