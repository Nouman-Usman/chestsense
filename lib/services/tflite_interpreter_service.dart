import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteInterpreter {
  Interpreter? _interpreter;
  final String modelPath;

  TFLiteInterpreter({required this.modelPath});

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      _interpreter!.allocateTensors();
      print('Input:  ' + _interpreter!.getInputTensor(0).shape.toString());
      print('Output: ' + _interpreter!.getOutputTensor(0).shape.toString());
    } catch (e) { rethrow; }
  }

  void run(Object input, Object output) {
    if (_interpreter == null) throw StateError('Not loaded');
    _interpreter!.run(input, output);
  }

  void runForMultipleInputs(List<Object> inputs, Map<int, Object> outputs) {
    if (_interpreter == null) throw StateError('Not loaded');
    _interpreter!.runForMultipleInputs(inputs, outputs);
  }

  List<int> getInputShape() {
    if (_interpreter == null) throw StateError('Not loaded');
    return _interpreter!.getInputTensor(0).shape;
  }

  List<int> getOutputShape() {
    if (_interpreter == null) throw StateError('Not loaded');
    return _interpreter!.getOutputTensor(0).shape;
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
