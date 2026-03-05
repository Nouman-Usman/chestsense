// Conditionally import native or web implementation
// ignore: lines_longer_than_80_chars
export 'densenet_classification_service_tflite.native.dart'
    if (dart.library.js_interop) 'densenet_classification_service_tflite.web.dart';
