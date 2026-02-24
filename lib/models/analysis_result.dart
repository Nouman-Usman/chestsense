class AnalysisResult {
  final String id;
  final String userId;
  final String imageUrl;
  final String? heatmapUrl;
  final String diagnosis;        // e.g. 'Pneumonia', 'Normal', 'COVID-19'
  final double confidence;       // 0.0 – 1.0
  final Map<String, double> classScores; // all class probabilities
  final DateTime createdAt;
  final String status;           // 'pending' | 'complete' | 'error'

  const AnalysisResult({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.heatmapUrl,
    required this.diagnosis,
    required this.confidence,
    required this.classScores,
    required this.createdAt,
    required this.status,
  });

  factory AnalysisResult.fromMap(String id, Map<String, dynamic> m) =>
      AnalysisResult(
        id: id,
        userId: m['userId'] ?? '',
        imageUrl: m['imageUrl'] ?? '',
        heatmapUrl: m['heatmapUrl'],
        diagnosis: m['diagnosis'] ?? '',
        confidence: (m['confidence'] as num?)?.toDouble() ?? 0,
        classScores: Map<String, double>.from(
          (m['classScores'] as Map?)
                  ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
              {},
        ),
        createdAt: m['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int)
            : DateTime.now(),
        status: m['status'] ?? 'pending',
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'imageUrl': imageUrl,
        'heatmapUrl': heatmapUrl,
        'diagnosis': diagnosis,
        'confidence': confidence,
        'classScores': classScores,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'status': status,
      };
}
