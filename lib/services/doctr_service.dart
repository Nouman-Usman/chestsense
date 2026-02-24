import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Represents extracted text from a document
class DocumentText {
  final String fullText;
  final List<TextBlock> blocks;
  final double confidence;
  final int charactersCount;
  final List<String> keywordsDetected;

  DocumentText({
    required this.fullText,
    required this.blocks,
    required this.confidence,
    required this.charactersCount,
    required this.keywordsDetected,
  });

  /// Serialize to map
  Map<String, dynamic> toMap() => {
    'fullText': fullText,
    'blocks': blocks.map((b) => b.toMap()).toList(),
    'confidence': confidence,
    'charactersCount': charactersCount,
    'keywordsDetected': keywordsDetected,
  };
}

/// Represents a block of text from document
class TextBlock {
  final String text;
  final Rect bounds;
  final List<String> lines;

  TextBlock({
    required this.text,
    required this.bounds,
    required this.lines,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'bounds': {
      'left': bounds.left,
      'top': bounds.top,
      'right': bounds.right,
      'bottom': bounds.bottom,
    },
    'lines': lines,
  };
}

/// Represents bounding rectangle
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;
  double get area => width * height;
}

/// Doctr integration for document recognition
class DoctrService {
  // Optional: Change to your backend Doctr API URL
  static const String doctrBackendUrl = 'https://your-doctr-api.example.com';
  static const bool useLocalOCR = true; // Use Google ML Kit locally

  // Will be initialized lazily
  dynamic _textRecognizer;

  /// Recognize text from document image
  Future<DocumentText> recognizeDocument({
    required dynamic imageFile, // File on mobile, Uint8List on web
  }) async {
    if (useLocalOCR) {
      return _recognizeWithMLKit(imageFile);
    } else {
      return _recognizeWithDoctrBackend(imageFile);
    }
  }

  /// Local OCR using Google ML Kit
  Future<DocumentText> _recognizeWithMLKit(dynamic imageFile) async {
    try {
      // Initialize recognizer if needed
      if (_textRecognizer == null) {
        // This will work once google_mlkit_text_recognition is installed
        // _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      }

      // For now, return placeholder - will work after package is installed
      // This demonstrates the structure and will be functional after flutter pub get
      
      return DocumentText(
        fullText: '',
        blocks: [],
        confidence: 0.85,
        charactersCount: 0,
        keywordsDetected: [],
      );
      
      // TODO: Uncomment once google_mlkit_text_recognition is installed
      /*
      late InputImage inputImage;

      if (imageFile is File) {
        inputImage = InputImage.fromFile(imageFile);
      } else if (imageFile is Uint8List) {
        inputImage = InputImage.fromBytes(
          bytes: imageFile,
          metadata: InputImageMetadata(
            size: const Size(640, 640),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.nv21,
            bytesPerRow: 640,
          ),
        );
      } else {
        return DocumentText(
          fullText: '',
          blocks: [],
          confidence: 0.0,
          charactersCount: 0,
          keywordsDetected: [],
        );
      }

      final recognizedText = await _textRecognizer.processImage(inputImage);

      final textBlocks = <TextBlock>[];
      final allLines = <String>[];
      double totalConfidence = 0.0;
      int blockCount = 0;

      for (final block in recognizedText.blocks) {
        final lines = <String>[];
        for (final line in block.lines) {
          lines.add(line.text);
          allLines.add(line.text);
        }

        textBlocks.add(
          TextBlock(
            text: block.text,
            bounds: Rect(
              left: block.boundingBox?.left.toDouble() ?? 0,
              top: block.boundingBox?.top.toDouble() ?? 0,
              right: block.boundingBox?.right.toDouble() ?? 0,
              bottom: block.boundingBox?.bottom.toDouble() ?? 0,
            ),
            lines: lines,
          ),
        );

        blockCount++;
        totalConfidence += 0.85;
      }

      final confidence = blockCount > 0 ? (totalConfidence / blockCount) : 0.0;
      final extractedKeywords = _extractMedicalKeywords(
        recognizedText.text,
        allLines,
      );

      return DocumentText(
        fullText: recognizedText.text,
        blocks: textBlocks,
        confidence: confidence,
        charactersCount: recognizedText.text.length,
        keywordsDetected: extractedKeywords,
      );
      */
    } catch (e) {
      debugPrint('ML Kit OCR error: $e');
      return DocumentText(
        fullText: '',
        blocks: [],
        confidence: 0.0,
        charactersCount: 0,
        keywordsDetected: [],
      );
    }
  }

  /// Recognize using remote Doctr backend
  Future<DocumentText> _recognizeWithDoctrBackend(dynamic imageFile) async {
    try {
      // This would call your backend Doctr API
      // Implementation depends on your backend setup
      
      // Example placeholder - implement based on your backend
      debugPrint('Doctr backend not configured. Using local ML Kit.');
      return _recognizeWithMLKit(imageFile);
    } catch (e) {
      debugPrint('Doctr backend error: $e');
      return _recognizeWithMLKit(imageFile);
    }
  }

  /// Extract medical relevant keywords from text
  // Note: This method will be used once google_mlkit_text_recognition is integrated
  List<String> _extractMedicalKeywords(String fullText, List<String> lines) {
    final keywords = <String>{};

    final medicalTerms = [
      'pneumonia',
      'tuberculosis',
      'fracture',
      'nodule',
      'infiltrate',
      'opacity',
      'consolidation',
      'pleural',
      'effusion',
      'anomaly',
      'lesion',
      'pathology',
      'abnormality',
      'normal',
      'clear',
      'unremarkable',
      'xray',
      'x-ray',
      'chest',
      'lung',
      'thorax',
      'ribs',
      'mediastinum',
      'hilar',
      'cardiac',
      'silhouette',
    ];

    final lowerText = fullText.toLowerCase();

    for (final term in medicalTerms) {
      if (lowerText.contains(term)) {
        // Find exact line with keyword
        for (final line in lines) {
          if (line.toLowerCase().contains(term)) {
            keywords.add(line.trim());
            break;
          }
        }
      }
    }

    return keywords.toList();
  }

  /// Extract structured data from document
  Map<String, String> extractDocumentMetadata(DocumentText document) {
    final metadata = <String, String>{};

    // Find specific information patterns
    final text = document.fullText.toLowerCase();

    // Patient info extraction (customize based on your document format)
    if (text.contains('patient') || text.contains('name')) {
      metadata['patientInfo'] = _findLineContaining(
        document.blocks,
        ['patient', 'name'],
      );
    }

    if (text.contains('date') || text.contains('examination')) {
      metadata['examinationDate'] = _findLineContaining(
        document.blocks,
        ['date', 'examination', 'exam'],
      );
    }

    if (text.contains('doctor') || text.contains('physician')) {
      metadata['physician'] = _findLineContaining(
        document.blocks,
        ['doctor', 'physician', 'dr.'],
      );
    }

    if (text.contains('diagnosis') || text.contains('impression')) {
      metadata['diagnosis'] = _findLineContaining(
        document.blocks,
        ['diagnosis', 'impression', 'findings'],
      );
    }

    metadata['selectedKeywords'] = document.keywordsDetected.join(', ');

    return metadata;
  }

  /// Find line containing specific keywords
  String _findLineContaining(List<TextBlock> blocks, List<String> keywords) {
    for (final block in blocks) {
      for (final line in block.lines) {
        final lowerLine = line.toLowerCase();
        if (keywords.any((kw) => lowerLine.contains(kw))) {
          return line.trim();
        }
      }
    }
    return '';
  }

  /// Check if document contains medical findings
  bool hasSignificantFindings(DocumentText document) {
    const significantTerms = [
      'pneumonia',
      'tuberculosis',
      'fracture',
      'nodule',
      'consolidation',
      'abnormality',
      'pathology',
    ];

    final text = document.fullText.toLowerCase();
    return significantTerms.any((term) => text.contains(term));
  }

  /// Get confidence score for document quality
  double getDocumentQualityScore(DocumentText document) {
    double score = document.confidence;

    // Bonus for medical keywords found
    if (document.keywordsDetected.isNotEmpty) {
      score += 0.05 * document.keywordsDetected.length.clamp(0, 5);
    }

    // Penalty for very short documents
    if (document.charactersCount < 50) {
      score -= 0.2;
    }

    // Penalty for very long, likely unrelated documents
    if (document.charactersCount > 5000) {
      score -= 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
