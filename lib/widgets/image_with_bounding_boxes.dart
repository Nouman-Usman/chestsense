import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../core/service_interfaces.dart';

class ImageWithBoundingBoxes extends StatefulWidget {
  final ui.Image image;
  final List<DetectedTumor> detections;
  final BoxFit fit;

  const ImageWithBoundingBoxes({
    super.key,
    required this.image,
    required this.detections,
    this.fit = BoxFit.contain,
  });

  @override
  State<ImageWithBoundingBoxes> createState() => _ImageWithBoundingBoxesState();
}

class _ImageWithBoundingBoxesState extends State<ImageWithBoundingBoxes> {
  final Map<int, ui.Image> _heatmapCache = {};

  @override
  void initState() {
    super.initState();
    _loadHeatmaps();
  }

  @override
  void didUpdateWidget(ImageWithBoundingBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detections != widget.detections) {
      _heatmapCache.clear();
      _loadHeatmaps();
    }
  }

  Future<void> _loadHeatmaps() async {
    for (int i = 0; i < widget.detections.length; i++) {
      final detection = widget.detections[i];
      if (detection.heatmapImage != null) {
        final uiImage = await _convertImgToUiImage(detection.heatmapImage!);
        if (mounted) {
          setState(() {
            _heatmapCache[i] = uiImage;
          });
        }
      }
    }
  }

  Future<ui.Image> _convertImgToUiImage(img.Image image) async {
    final bytes = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    for (final image in _heatmapCache.values) {
      image.dispose();
    }
    _heatmapCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _BoundingBoxPainter(
            image: widget.image,
            detections: widget.detections,
            heatmaps: _heatmapCache,
            fit: widget.fit,
          ),
          size: Size(constraints.maxWidth, constraints.maxWidth * (widget.image.height / widget.image.width)),
        );
      },
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final ui.Image image;
  final List<DetectedTumor> detections;
  final Map<int, ui.Image> heatmaps;
  final BoxFit fit;

  _BoundingBoxPainter({
    required this.image,
    required this.detections,
    required this.heatmaps,
    required this.fit,
  });

  // Get color for each classification type
  Color _getColorForClassification(String classification) {
    final lower = classification.toLowerCase();
    if (lower.contains('adenocarcinoma') || lower.contains('class a')) {
      return Colors.red;
    } else if (lower.contains('small cell') || lower.contains('class b')) {
      return Colors.deepOrange;
    } else if (lower.contains('large cell') || lower.contains('class e')) {
      return Colors.amber.shade700;
    } else if (lower.contains('squamous') || lower.contains('class g')) {
      return Colors.orange;
    }
    return Colors.blue; // Fallback
  }

  // Get short label for classification
  String _getShortLabel(String classification) {
    if (classification.contains('Adenocarcinoma')) return 'Adenocarcinoma';
    if (classification.contains('Small Cell')) return 'Small Cell';
    if (classification.contains('Large Cell')) return 'Large Cell';
    if (classification.contains('Squamous')) return 'Squamous';
    return classification;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: fit,
      filterQuality: FilterQuality.medium,
    );

    // Draw GRAD-CAM heatmap and bounding boxes for each detection
    // Approach: Heatmap overlays the original image, box is transparent stroke only
    for (var i = 0; i < detections.length; i++) {
      final detection = detections[i];
      final bbox = detection.bbox;
      
      // Convert normalized coordinates (0-1) to canvas pixel coordinates
      final x1 = bbox[0] * size.width;
      final y1 = bbox[1] * size.height;
      final x2 = bbox[2] * size.width;
      final y2 = bbox[3] * size.height;

      final color = _getColorForClassification(detection.classification);
      final confidence = detection.classificationConfidence;
      final shortLabel = _getShortLabel(detection.classification);
      final confidencePercent = (confidence * 100).toStringAsFixed(1);

      final rect = Rect.fromLTRB(x1, y1, x2, y2);

      // ═══════════════════════════════════════════════════════════════
      // GRAD-CAM HEATMAP RENDERING (overlaid on original image)
      // ═══════════════════════════════════════════════════════════════
      
      final heatmapImage = heatmaps[i];
      
      if (heatmapImage != null) {
        // Draw GRAD-CAM heatmap directly on the image (no clipping)
        // This creates the natural overlay effect like the reference image
        final heatmapPaint = Paint()
          ..blendMode = BlendMode.plus  // Additive blending for heatmap effect
          ..filterQuality = FilterQuality.high;
        
        canvas.drawImageRect(
          heatmapImage,
          Rect.fromLTWH(0, 0, heatmapImage.width.toDouble(), heatmapImage.height.toDouble()),
          rect,
          heatmapPaint,
        );
      }

      // Draw bounding box with transparent stroke only (no fill)
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke  // Only stroke, no fill
        ..strokeWidth = 3.0;
      canvas.drawRect(rect, boxPaint);

      // Draw corner markers for emphasis (optional - can be removed for cleaner look)
      final cornerSize = 12.0;
      final cornerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      // Top-left corner
      canvas.drawLine(Offset(x1, y1), Offset(x1 + cornerSize, y1), cornerPaint);
      canvas.drawLine(Offset(x1, y1), Offset(x1, y1 + cornerSize), cornerPaint);

      // Top-right corner
      canvas.drawLine(Offset(x2, y1), Offset(x2 - cornerSize, y1), cornerPaint);
      canvas.drawLine(Offset(x2, y1), Offset(x2, y1 + cornerSize), cornerPaint);

      // Bottom-left corner
      canvas.drawLine(Offset(x1, y2), Offset(x1 + cornerSize, y2), cornerPaint);
      canvas.drawLine(Offset(x1, y2), Offset(x1, y2 - cornerSize), cornerPaint);

      // Bottom-right corner
      canvas.drawLine(Offset(x2, y2), Offset(x2 - cornerSize, y2), cornerPaint);
      canvas.drawLine(Offset(x2, y2), Offset(x2, y2 - cornerSize), cornerPaint);

      // Draw label background
      final labelText = '$shortLabel ($confidencePercent%)';
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Position label at top of box
      const padding = 6.0;
      final labelBgRect = Rect.fromLTRB(
        x1,
        y1 - textPainter.height - padding * 2,
        x1 + textPainter.width + padding * 2,
        y1,
      );

      // Draw label background with solid fill
      final labelBgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          labelBgRect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        labelBgPaint,
      );

      // Draw text
      textPainter.paint(
        canvas,
        Offset(
          x1 + padding,
          y1 - textPainter.height - padding,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_BoundingBoxPainter oldDelegate) {
    return oldDelegate.image != image || 
           oldDelegate.detections != detections ||
           oldDelegate.heatmaps != heatmaps;
  }
}
