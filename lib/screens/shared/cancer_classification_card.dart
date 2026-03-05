import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'dart:ui' as ui;
import '../../core/logger_service.dart';

/// Widget for displaying tumor classification results with heatmap visualization
class CancerClassificationCard extends StatefulWidget {
  final int tumorIndex;
  final String classification;
  final double confidence;
  final Map<String, double> classScores;
  final double detectionConfidence;
  final img.Image? heatmapImage;
  final img.Image? originalRegion;

  const CancerClassificationCard({
    super.key,
    required this.tumorIndex,
    required this.classification,
    required this.confidence,
    required this.classScores,
    required this.detectionConfidence,
    this.heatmapImage,
    this.originalRegion,
  });

  @override
  State<CancerClassificationCard> createState() =>
      _CancerClassificationCardState();
}

class _CancerClassificationCardState extends State<CancerClassificationCard> {
  bool _showHeatmap = true;

  @override
  Widget build(BuildContext context) {
    final isSevere = widget.classification.toLowerCase().contains('adenocarcinoma') ||
        widget.classification.toLowerCase().contains('small cell') ||
        widget.classification.toLowerCase().contains('squamous');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSevere ? Colors.red[300]! : Colors.orange[300]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with tumor number and classification
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSevere ? Colors.red[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.tumorIndex}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSevere ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tumor #${widget.tumorIndex}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        widget.classification,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSevere ? Colors.red[700] : Colors.orange[700],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image display (heatmap or original)
            if (widget.heatmapImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.grey[200],
                  child: _buildImageDisplay(),
                ),
              ),
              const SizedBox(height: 12),
              // Toggle button
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => setState(() => _showHeatmap = !_showHeatmap),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            _showHeatmap ? '🔥 Heatmap' : '📷 Original',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Confidence scores
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classification Confidence',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                _ConfidenceBar(
                  label: 'Classification',
                  confidence: widget.confidence,
                  color: isSevere ? Colors.red : Colors.orange,
                ),
                const SizedBox(height: 8),
                _ConfidenceBar(
                  label: 'Detection',
                  confidence: widget.detectionConfidence,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // All class scores
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Classification Scores',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.classScores.entries.map((entry) {
                    final isTopClass = entry.key == widget.classification;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isTopClass
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isTopClass
                                    ? Colors.blue[900]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _ScoreBar(
                              score: entry.value,
                              isTop: isTopClass,
                            ),
                          ),
                          Text(
                            '${(entry.value * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Medical notes
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSevere ? Colors.red[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSevere ? Colors.red[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    size: 18,
                    color: isSevere ? Colors.red[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSevere
                          ? 'Severe classification detected. Recommend immediate specialist review.'
                          : 'Moderate classification. Schedule follow-up consultation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSevere ? Colors.red[700] : Colors.orange[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    final imageToShow = _showHeatmap ? widget.heatmapImage : widget.originalRegion;

    if (imageToShow == null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Image not available',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    return FutureBuilder<ui.Image>(
      future: _convertImageToUIImage(imageToShow),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return SizedBox(
            height: 200,
            child: RawImage(image: snapshot.data),
          );
        }
        return SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.blue[300]),
            ),
          ),
        );
      },
    );
  }

  Future<ui.Image> _convertImageToUIImage(img.Image image) async {
    final completer = Completer<ui.Image>();
    try {
      final pngBytes = img.encodePng(image);
      ui.decodeImageFromList(pngBytes, completer.complete);
    } catch (e) {
      LoggerService.error('Error converting image to UI image', error: e);
      completer.completeError(e);
    }
    return completer.future;
  }
}

class _ConfidenceBar extends StatelessWidget {
  final String label;
  final double confidence;
  final Color color;

  const _ConfidenceBar({
    required this.label,
    required this.confidence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 20,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '${(confidence * 100).toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final double score;
  final bool isTop;

  const _ScoreBar({
    required this.score,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: score,
        minHeight: 16,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation(
          isTop ? Colors.blue[600] : Colors.grey[400],
        ),
      ),
    );
  }
}
