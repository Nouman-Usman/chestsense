/// Web stub for TFLiteInterpreter - FFI not available on web
class TFLiteInterpreter {
  final String modelPath;

  TFLiteInterpreter({required this.modelPath});

  Future<void> loadModel() async {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform. '
      'ML inference features are only available on native platforms (Android, iOS, macOS, Linux, Windows).',
    );
  }

  void run(Object input, Object output) {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform.',
    );
  }

  void runForMultipleInputs(List<Object> inputs, Map<int, Object> outputs) {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform.',
    );
  }

  List<int> getInputShape() {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform.',
    );
  }

  List<int> getOutputShape() {
    throw UnsupportedError(
      'TensorFlow Lite FFI is not available on web platform.',
    );
  }

  void close() {
    // No-op on web
  }
}
