// Conditionally import native or web implementation
// ignore: lines_longer_than_80_chars
export 'ml_pipeline_service_tflite.native.dart'
    if (dart.library.js_interop) 'ml_pipeline_service_tflite.web.dart';
