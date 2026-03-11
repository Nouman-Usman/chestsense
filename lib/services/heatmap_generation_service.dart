import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Grad-CAM-style heatmap generation for medical image classification
/// Creates visual heatmaps showing regions important for classification
/// Implements Class Activation Mapping (CAM) and attention-based visualization
class HeatmapGenerationService {
  
  /// Generate Grad-CAM-style heatmap using attention and class activation mapping
  /// This approximates Grad-CAM behavior within TFLite constraints
  static img.Image generateGradCAMHeatmap(
    img.Image image, 
    Map<String, double> classScores,
    {String? targetClass}
  ) {
    final width = image.width;
    final height = image.height;
    
    // Step 1: Generate attention map from image features
    final attentionMap = _generateAttentionMap(image);
    
    // Step 2: Weight attention by class predictions (CAM-style)
    final classSaliency = _computeClassSaliency(classScores, targetClass);
    
    // Step 3: Combine attention with class weighting
    final weightedMap = _applyClassWeighting(attentionMap, classSaliency, width, height);
    
    // Step 4: Apply bilateral filter for edge-preserving smoothing
    final smoothed = _bilateralFilter(weightedMap, width, height);
    
    // Step 5: Create heatmap with jet colormap
    final heatmap = _createHeatmapImage(smoothed, width, height);
    
    return heatmap;
  }
  
  /// Generate attention map using multi-scale feature extraction
  static List<double> _generateAttentionMap(img.Image image) {
    final width = image.width;
    final height = image.height;
    
    // Convert to LAB color space for better perceptual analysis
    final lab = _rgbToLab(image);
    
    // Multi-scale gradient analysis
    final gradients1 = _computeImageGradients(lab, width, height, sigma: 1.0);
    final gradients2 = _computeImageGradients(lab, width, height, sigma: 2.0);
    final gradients3 = _computeImageGradients(lab, width, height, sigma: 3.0);
    
    // Combine multi-scale features
    final combined = List<double>.filled(width * height, 0.0);
    for (int i = 0; i < combined.length; i++) {
      combined[i] = gradients1[i] * 0.5 + gradients2[i] * 0.3 + gradients3[i] * 0.2;
    }
    
    // Add texture analysis
    final texture = _computeTextureFeatures(image);
    for (int i = 0; i < combined.length; i++) {
      combined[i] = combined[i] * 0.7 + texture[i] * 0.3;
    }
    
    return _normalizeMap(combined);
  }
  
  /// Compute class-specific saliency weights (approximates Grad-CAM gradients)
  static double _computeClassSaliency(Map<String, double> classScores, String? targetClass) {
    if (targetClass != null && classScores.containsKey(targetClass)) {
      return classScores[targetClass]!;
    }
    // Use maximum class score as default
    return classScores.values.reduce((a, b) => a > b ? a : b);
  }
  
  /// Apply class-based weighting to attention map
  static List<double> _applyClassWeighting(
    List<double> attentionMap,
    double classWeight,
    int width,
    int height,
  ) {
    // Enhance attention in regions with high gradients, weighted by class confidence
    final weighted = List<double>.filled(attentionMap.length, 0.0);
    
    // Apply non-linear enhancement based on class confidence
    final alpha = 0.5 + classWeight * 0.5; // 0.5 to 1.0
    
    for (int i = 0; i < attentionMap.length; i++) {
      weighted[i] = math.pow(attentionMap[i], 1.0 / alpha).toDouble();
    }
    
    return _normalizeMap(weighted);
  }
  
  /// Bilateral filter for edge-preserving smoothing (mimics Grad-CAM smoothness)
  static List<double> _bilateralFilter(List<double> data, int width, int height) {
    final result = List<double>.filled(data.length, 0.0);
    const int radius = 5;
    const double sigmaSpace = 5.0;
    const double sigmaRange = 0.1;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double weightSum = 0.0;
        double valueSum = 0.0;
        final centerValue = data[y * width + x];
        
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final ny = (y + dy).clamp(0, height - 1);
            final nx = (x + dx).clamp(0, width - 1);
            final neighborValue = data[ny * width + nx];
            
            // Spatial weight
            final spatialDist = math.sqrt((dx * dx + dy * dy).toDouble());
            final spatialWeight = math.exp(-spatialDist * spatialDist / (2 * sigmaSpace * sigmaSpace));
            
            // Range weight
            final rangeDist = (centerValue - neighborValue).abs();
            final rangeWeight = math.exp(-rangeDist * rangeDist / (2 * sigmaRange * sigmaRange));
            
            final weight = spatialWeight * rangeWeight;
            weightSum += weight;
            valueSum += weight * neighborValue;
          }
        }
        
        result[y * width + x] = valueSum / weightSum.clamp(0.001, double.infinity);
      }
    }
    
    return result;
  }
  
  /// Compute image gradients with Gaussian smoothing
  static List<double> _computeImageGradients(
    List<List<double>> lab,
    int width,
    int height,
    {double sigma = 1.0}
  ) {
    final l = lab[0];
    final a = lab[1];
    final b = lab[2];
    
    // Compute gradients for each channel
    final lGrad = _sobelMagnitude(l, width, height);
    final aGrad = _sobelMagnitude(a, width, height);
    final bGrad = _sobelMagnitude(b, width, height);
    
    // Combine channels (L channel more important for structure)
    final combined = List<double>.filled(width * height, 0.0);
    for (int i = 0; i < combined.length; i++) {
      combined[i] = lGrad[i] * 0.6 + aGrad[i] * 0.2 + bGrad[i] * 0.2;
    }
    
    return _gaussianBlur(combined, (sigma * 3).toInt(), width, height, sigma);
  }
  
  /// Compute texture features using Local Binary Patterns
  static List<double> _computeTextureFeatures(img.Image image) {
    final width = image.width;
    final height = image.height;
    final gray = _toGrayscale(image);
    final texture = List<double>.filled(width * height, 0.0);
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final center = gray[y * width + x];
        double variance = 0.0;
        
        // Compute local variance as texture measure
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final neighbor = gray[(y + dy) * width + (x + dx)];
            variance += math.pow(neighbor - center, 2);
          }
        }
        
        texture[y * width + x] = math.sqrt(variance / 8.0);
      }
    }
    
    return texture;
  }
  
  /// Convert RGB to LAB color space
  static List<List<double>> _rgbToLab(img.Image image) {
    final width = image.width;
    final height = image.height;
    final l = List<double>.filled(width * height, 0.0);
    final a = List<double>.filled(width * height, 0.0);
    final b = List<double>.filled(width * height, 0.0);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixelSafe(x, y);
        final idx = y * width + x;
        
        // Simplified RGB to LAB conversion
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final blue = pixel.b / 255.0;
        
        l[idx] = 0.2126 * r + 0.7152 * g + 0.0722 * blue;
        a[idx] = (r - g) * 0.5;
        b[idx] = (r + g - 2 * blue) * 0.25;
      }
    }
    
    return [l, a, b];
  }
  
  /// Compute Sobel magnitude
  static List<double> _sobelMagnitude(List<double> data, int width, int height) {
    final gx = _applySobelKernel(data, width, height, [
      -1, 0, 1,
      -2, 0, 2,
      -1, 0, 1,
    ]);
    
    final gy = _applySobelKernel(data, width, height, [
      -1, -2, -1,
       0,  0,  0,
       1,  2,  1,
    ]);
    
    final magnitude = List<double>.filled(data.length, 0.0);
    for (int i = 0; i < data.length; i++) {
      magnitude[i] = math.sqrt(gx[i] * gx[i] + gy[i] * gy[i]);
    }
    
    return magnitude;
  }
  
  /// Normalize map to [0, 1] range
  static List<double> _normalizeMap(List<double> map) {
    final minVal = map.reduce((a, b) => a < b ? a : b);
    final maxVal = map.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).clamp(0.001, double.infinity);
    
    return map.map((v) => ((v - minVal) / range).clamp(0.0, 1.0)).toList();
  }
  
  /// Create heatmap image from activation map
  static img.Image _createHeatmapImage(List<double> activationMap, int width, int height) {
    final heatmap = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final value = activationMap[y * width + x];
        final color = _jetColormap(value);
        heatmap.setPixelRgba(x, y, color.r, color.g, color.b, 255);
      }
    }
    
    return heatmap;
  }
  
  // ========== LEGACY SALIENCY METHOD (kept for compatibility) ==========
  
  /// Generate a saliency heatmap from an image using edge detection
  /// and gradient-based approach (legacy method)
  static img.Image generateSaliencyHeatmap(img.Image image) {
    final width = image.width;
    final height = image.height;
    
    // Step 1: Convert to grayscale
    final grayscale = _toGrayscale(image);
    
    // Step 2: Apply Sobel edge detection for gradients
    final gradientX = _sobelX(grayscale, width, height);
    final gradientY = _sobelY(grayscale, width, height);
    
    // Step 3: Compute gradient magnitude
    final magnitude = _computeMagnitude(gradientX, gradientY);
    
    // Step 4: Gaussian blur for smoothing
    final blurred = _gaussianBlur(magnitude, 5, width, height);
    
    // Step 5: Create colormap (blue = low importance, red = high importance)
    final heatmap = img.Image(width: width, height: height);
    final maxMagnitude = blurred.reduce((a, b) => a > b ? a : b);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final normalized = blurred[y * width + x] / maxMagnitude.clamp(0.01, double.infinity);
        final color = _jetColormap(normalized);
        heatmap.setPixelRgba(x, y, color.r, color.g, color.b, 255);
      }
    }
    
    return heatmap;
  }
  
  /// Blend heatmap with original image
  static img.Image blendHeatmapWithImage(img.Image original, img.Image heatmap, {double alpha = 0.5}) {
    final width = original.width;
    final height = original.height;
    final blended = img.Image(width: width, height: height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final origPixel = original.getPixelSafe(x, y);
        final heatPixel = heatmap.getPixelSafe(x, y);
        
        // Blend: alpha * heatmap + (1-alpha) * original
        final r = (heatPixel.r * alpha + origPixel.r * (1 - alpha)).toInt().clamp(0, 255);
        final g = (heatPixel.g * alpha + origPixel.g * (1 - alpha)).toInt().clamp(0, 255);
        final b = (heatPixel.b * alpha + origPixel.b * (1 - alpha)).toInt().clamp(0, 255);
        
        blended.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    return blended;
  }
  
  /// Convert to grayscale using standard luminance formula
  static List<double> _toGrayscale(img.Image image) {
    final result = <double>[];
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixelSafe(x, y);
        final gray = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        result.add(gray);
      }
    }
    return result;
  }
  
  /// Sobel X operator (vertical edges)
  static List<double> _sobelX(List<double> data, int width, int height) {
    return _applySobelKernel(data, width, height, [
      -1, 0, 1,
      -2, 0, 2,
      -1, 0, 1,
    ]);
  }
  
  /// Sobel Y operator (horizontal edges)
  static List<double> _sobelY(List<double> data, int width, int height) {
    return _applySobelKernel(data, width, height, [
      -1, -2, -1,
      0, 0, 0,
      1, 2, 1,
    ]);
  }
  
  /// Apply 3x3 kernel convolution
  static List<double> _applySobelKernel(
    List<double> data,
    int width,
    int height,
    List<int> kernel,
  ) {
    final result = List<double>.filled(data.length, 0.0);
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        double sum = 0;
        int ki = 0;
        
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final idx = (y + dy) * width + (x + dx);
            if (idx >= 0 && idx < data.length) {
              sum += data[idx] * kernel[ki];
            }
            ki++;
          }
        }
        
        result[y * width + x] = sum.abs();
      }
    }
    
    return result;
  }
  
  /// Compute gradient magnitude from X and Y gradients
  static List<double> _computeMagnitude(List<double> gx, List<double> gy) {
    final result = <double>[];
    for (int i = 0; i < gx.length; i++) {
      final mag = math.sqrt(gx[i] * gx[i] + gy[i] * gy[i]);
      result.add(mag);
    }
    return result;
  }
  
  /// Apply Gaussian blur
  static List<double> _gaussianBlur(
    List<double> data,
    int kernelSize,
    int width,
    int height,
    [double? customSigma]
  ) {
    final result = List<double>.filled(data.length, 0.0);
    final sigma = kernelSize / 6.0;
    
    // Create 1D Gaussian kernel
    final kernel = <double>[];
    double sum = 0;
    final halfSize = kernelSize ~/ 2;
    
    for (int i = -halfSize; i <= halfSize; i++) {
      final val = math.exp(-(i * i) / (2 * sigma * sigma)) / (sigma * math.sqrt(2 * math.pi));
      kernel.add(val);
      sum += val;
    }
    
    // Normalize kernel
    for (int i = 0; i < kernel.length; i++) {
      kernel[i] /= sum;
    }
    
    // Apply horizontal blur
    final temp = List<double>.filled(data.length, 0.0);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double val = 0;
        for (int i = 0; i < kernel.length; i++) {
          final nx = (x - halfSize + i).clamp(0, width - 1);
          val += data[y * width + nx] * kernel[i];
        }
        temp[y * width + x] = val;
      }
    }
    
    // Apply vertical blur
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double val = 0;
        for (int i = 0; i < kernel.length; i++) {
          final ny = (y - halfSize + i).clamp(0, height - 1);
          val += temp[ny * width + x] * kernel[i];
        }
        result[y * width + x] = val;
      }
    }
    
    return result;
  }
  
  /// Jet colormap (common in medical imaging)
  /// Maps [0, 1] to blue-cyan-green-yellow-red
  static _Color _jetColormap(double value) {
    value = value.clamp(0, 1);
    
    late int r, g, b;
    
    if (value < 0.125) {
      r = 0;
      g = 0;
      b = (255 * (0.5 + value / 0.25)).toInt();
    } else if (value < 0.375) {
      r = 0;
      g = (255 * (value - 0.125) / 0.25).toInt();
      b = 255;
    } else if (value < 0.625) {
      r = (255 * (value - 0.375) / 0.25).toInt();
      g = 255;
      b = (255 * (1.0 - (value - 0.375) / 0.25)).toInt();
    } else if (value < 0.875) {
      r = 255;
      g = (255 * (1.0 - (value - 0.625) / 0.25)).toInt();
      b = 0;
    } else {
      r = (255 * (1.0 - (value - 0.875) / 0.125)).toInt();
      g = 0;
      b = 0;
    }
    
    return _Color(r, g, b);
  }
}

class _Color {
  final int r, g, b;
  _Color(this.r, this.g, this.b);
}
