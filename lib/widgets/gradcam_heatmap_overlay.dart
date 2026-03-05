import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'dart:async';
import '../core/logger_service.dart';

/// CustomPaint widget for Grad-CAM heatmap overlay
/// Uses BlendMode.srcOver to overlay heatmap onto original image
class GradCAMHeatmapOverlay extends StatefulWidget {
  final img.Image originalImage;
  final img.Image heatmapImage;
  final double opacity;
  final BlendMode blendMode;
  
  const GradCAMHeatmapOverlay({
    super.key,
    required this.originalImage,
    required this.heatmapImage,
    this.opacity = 0.6,
    this.blendMode = BlendMode.srcOver,
  });

  @override
  State<GradCAMHeatmapOverlay> createState() => _GradCAMHeatmapOverlayState();
}

class _GradCAMHeatmapOverlayState extends State<GradCAMHeatmapOverlay> {
  ui.Image? _originalUiImage;
  ui.Image? _heatmapUiImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didUpdateWidget(GradCAMHeatmapOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalImage != widget.originalImage ||
        oldWidget.heatmapImage != widget.heatmapImage) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    
    try {
      final originalUi = await _convertToUiImage(widget.originalImage);
      final heatmapUi = await _convertToUiImage(widget.heatmapImage);
      
      if (mounted) {
        setState(() {
          _originalUiImage = originalUi;
          _heatmapUiImage = heatmapUi;
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading images for overlay', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<ui.Image> _convertToUiImage(img.Image image) async {
    final completer = Completer<ui.Image>();
    
    // Convert to RGBA if needed
    final rgba = image.convert(numChannels: 4);
    final bytes = rgba.getBytes(order: img.ChannelOrder.rgba);
    
    ui.decodeImageFromPixels(
      bytes,
      rgba.width,
      rgba.height,
      ui.PixelFormat.rgba8888,
      (ui.Image result) {
        completer.complete(result);
      },
    );
    
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _originalUiImage == null || _heatmapUiImage == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CustomPaint(
      painter: _HeatmapOverlayPainter(
        originalImage: _originalUiImage!,
        heatmapImage: _heatmapUiImage!,
        opacity: widget.opacity,
        blendMode: widget.blendMode,
      ),
      child: SizedBox(
        width: widget.originalImage.width.toDouble(),
        height: widget.originalImage.height.toDouble(),
      ),
    );
  }

  @override
  void dispose() {
    _originalUiImage?.dispose();
    _heatmapUiImage?.dispose();
    super.dispose();
  }
}

/// Painter for overlaying heatmap using CustomPaint
class _HeatmapOverlayPainter extends CustomPainter {
  final ui.Image originalImage;
  final ui.Image heatmapImage;
  final double opacity;
  final BlendMode blendMode;

  _HeatmapOverlayPainter({
    required this.originalImage,
    required this.heatmapImage,
    required this.opacity,
    required this.blendMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Step 1: Draw original image
    final srcRect = Rect.fromLTWH(
      0,
      0,
      originalImage.width.toDouble(),
      originalImage.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    canvas.drawImageRect(
      originalImage,
      srcRect,
      dstRect,
      paint,
    );
    
    // Step 2: Draw heatmap overlay with blend mode
    paint.blendMode = blendMode;
    paint.color = paint.color.withValues(alpha: opacity);
    
    final heatmapSrcRect = Rect.fromLTWH(
      0,
      0,
      heatmapImage.width.toDouble(),
      heatmapImage.height.toDouble(),
    );
    
    canvas.drawImageRect(
      heatmapImage,
      heatmapSrcRect,
      dstRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(_HeatmapOverlayPainter oldDelegate) {
    return oldDelegate.originalImage != originalImage ||
        oldDelegate.heatmapImage != heatmapImage ||
        oldDelegate.opacity != opacity ||
        oldDelegate.blendMode != blendMode;
  }
}

/// Widget for displaying Grad-CAM with controls
class GradCAMVisualizationCard extends StatefulWidget {
  final img.Image originalImage;
  final img.Image heatmapImage;
  final String classification;
  final double confidence;
  
  const GradCAMVisualizationCard({
    super.key,
    required this.originalImage,
    required this.heatmapImage,
    required this.classification,
    required this.confidence,
  });

  @override
  State<GradCAMVisualizationCard> createState() =>
      _GradCAMVisualizationCardState();
}

class _GradCAMVisualizationCardState extends State<GradCAMVisualizationCard> {
  double _opacity = 0.6;
  bool _showOverlay = true;
  BlendMode _blendMode = BlendMode.srcOver;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.blur_on, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Grad-CAM Visualization',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.classification} (${(widget.confidence * 100).toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
          ),
          
          // Image display
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 400,
                maxWidth: MediaQuery.of(context).size.width - 32,
              ),
              child: _showOverlay
                  ? GradCAMHeatmapOverlay(
                      originalImage: widget.originalImage,
                      heatmapImage: widget.heatmapImage,
                      opacity: _opacity,
                      blendMode: _blendMode,
                    )
                  : FutureBuilder<ui.Image>(
                      future: _convertToUiImage(widget.originalImage),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        return RawImage(image: snapshot.data);
                      },
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle overlay
                SwitchListTile(
                  title: const Text('Show Heatmap Overlay'),
                  value: _showOverlay,
                  onChanged: (value) {
                    setState(() => _showOverlay = value);
                  },
                ),
                
                // Opacity slider
                if (_showOverlay) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Opacity: ${(_opacity * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _opacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: '${(_opacity * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() => _opacity = value);
                    },
                  ),
                  
                  // Blend mode selector
                  const SizedBox(height: 8),
                  DropdownButtonFormField<BlendMode>(
                    initialValue: _blendMode,
                    decoration: const InputDecoration(
                      labelText: 'Blend Mode',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: BlendMode.srcOver,
                        child: Text('Source Over (Default)'),
                      ),
                      DropdownMenuItem(
                        value: BlendMode.multiply,
                        child: Text('Multiply'),
                      ),
                      DropdownMenuItem(
                        value: BlendMode.overlay,
                        child: Text('Overlay'),
                      ),
                      DropdownMenuItem(
                        value: BlendMode.screen,
                        child: Text('Screen'),
                      ),
                      DropdownMenuItem(
                        value: BlendMode.plus,
                        child: Text('Plus (Additive)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _blendMode = value);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.cyan,
                          Colors.green,
                          Colors.yellow,
                          Colors.red,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Blue: Low importance',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('Red: High importance',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<ui.Image> _convertToUiImage(img.Image image) async {
    final completer = Completer<ui.Image>();
    final rgba = image.convert(numChannels: 4);
    final bytes = rgba.getBytes(order: img.ChannelOrder.rgba);
    
    ui.decodeImageFromPixels(
      bytes,
      rgba.width,
      rgba.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    
    return completer.future;
  }
}
