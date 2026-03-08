# Lung Cancer Classification API with Grad-CAM

A Flask REST API that classifies lung cancer types from CT scan images using a DenseNet121 deep learning model with Grad-CAM (Gradient-weighted Class Activation Mapping) visualization.

---

## Table of Contents
- [Setup](#setup)
- [Running the Server](#running-the-server)
- [API Endpoints](#api-endpoints)
- [Frontend Integration Guide](#frontend-integration-guide)
  - [Flutter / Dart](#flutter--dart)
  - [JavaScript / Web](#javascript--web)
  - [Python](#python)
- [Request Format](#request-format)
- [Response Format](#response-format)
- [Error Handling](#error-handling)
- [Model Classes](#model-classes)

---

## Setup

```bash
# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Place your trained model
mkdir models
# → Copy densenet_final_classification.pth to models/
```

---

## Running the Server

```bash
python app.py
```

Server runs on:
- Local:   `http://127.0.0.1:5001`
- Network: `http://<your-ip>:5001`
- Swagger UI: `http://localhost:5001/docs`

---

## API Endpoints

| Method | Endpoint   | Description                          |
|--------|------------|--------------------------------------|
| GET    | `/`        | API info and available endpoints     |
| GET    | `/health`  | Check server and model status        |
| POST   | `/analyze` | Analyze image, returns Grad-CAM JSON |
| GET    | `/docs`    | Interactive Swagger UI               |

---

## Request Format

### POST `/analyze`

| Property     | Value                    |
|--------------|--------------------------|
| Method       | `POST`                   |
| Content-Type | `multipart/form-data`    |
| Field name   | `file`                   |
| Accepted formats | JPEG, PNG, BMP, TIFF |

```
POST http://<host>:5001/analyze
Content-Type: multipart/form-data

file: <image_file>
```

---

## Response Format

### Success Response `200 OK`

```json
{
  "success": true,
  "prediction": "Adenocarcinoma (Class A)",
  "confidence": 89.5,
  "original_image": "<base64_encoded_jpeg_string>",
  "heatmap_image": "<base64_encoded_jpeg_string>"
}
```

| Field            | Type    | Description                                              |
|------------------|---------|----------------------------------------------------------|
| `success`        | boolean | `true` if analysis was successful                        |
| `prediction`     | string  | Predicted cancer class label                             |
| `confidence`     | float   | Confidence percentage (0.0 – 100.0)                      |
| `original_image` | string  | Base64-encoded JPEG of the original input image          |
| `heatmap_image`  | string  | Base64-encoded JPEG with Grad-CAM heatmap overlay — red areas indicate regions the model focused on |

### Error Response `400 / 500`

```json
{
  "error": "No file uploaded"
}
```

### Health Response `200 OK`

```json
{
  "status": "healthy",
  "model_loaded": true
}
```

---

## Model Classes

| Index | Label                    |
|-------|--------------------------|
| 0     | Adenocarcinoma (Class A) |
| 1     | Small Cell (Class B)     |
| 2     | Large Cell (Class E)     |
| 3     | Squamous Cell (Class G)  |

---

## Frontend Integration Guide

---

### Flutter / Dart

#### 1. Add dependency to `pubspec.yaml`
```yaml
dependencies:
  http: ^1.2.0
```

#### 2. Full integration example

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.103:5001'; // Use your server IP

  /// Sends a CT scan image to the API and returns the analysis result
  static Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final uri = Uri.parse('$baseUrl/analyze');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Unknown error');
    }
  }

  /// Check if the API server is running
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      final data = json.decode(response.body);
      return data['status'] == 'healthy' && data['model_loaded'] == true;
    } catch (_) {
      return false;
    }
  }
}

/// Result model
class AnalysisResult {
  final String prediction;
  final double confidence;
  final Uint8List originalImage;
  final Uint8List heatmapImage;

  AnalysisResult({
    required this.prediction,
    required this.confidence,
    required this.originalImage,
    required this.heatmapImage,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      prediction: json['prediction'],
      confidence: (json['confidence'] as num).toDouble(),
      originalImage: base64Decode(json['original_image']),
      heatmapImage: base64Decode(json['heatmap_image']),
    );
  }
}

/// Usage in a Widget
class ResultScreen extends StatelessWidget {
  final AnalysisResult result;
  const ResultScreen({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prediction banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Prediction', style: TextStyle(color: Colors.grey)),
                  Text(
                    result.prediction,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Confidence: ${result.confidence.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Original CT image
            const Text('Original CT Image',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(result.originalImage, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            // Heatmap overlay
            const Text('Heatmap Overlay Image',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
              'Red areas = regions model focused on',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(result.heatmapImage, fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }
}

/// How to call from your page:
///
/// final result = await ApiService.analyzeImage(pickedFile);
/// final analysis = AnalysisResult.fromJson(result);
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ResultScreen(result: analysis),
/// ));
```

---

### JavaScript / Web

```javascript
const API_URL = 'http://localhost:5001';

/**
 * Analyze a lung CT image
 * @param {File} imageFile - File object from <input type="file">
 * @returns {Promise<Object>} Analysis result
 */
async function analyzeImage(imageFile) {
  const formData = new FormData();
  formData.append('file', imageFile);

  const response = await fetch(`${API_URL}/analyze`, {
    method: 'POST',
    body: formData,
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Analysis failed');
  }

  return await response.json();
}

// Usage
document.getElementById('upload').addEventListener('change', async (e) => {
  const file = e.target.files[0];
  const result = await analyzeImage(file);

  // Display prediction
  document.getElementById('prediction').textContent = result.prediction;
  document.getElementById('confidence').textContent = `${result.confidence}%`;

  // Display images from base64
  document.getElementById('original').src = `data:image/jpeg;base64,${result.original_image}`;
  document.getElementById('heatmap').src = `data:image/jpeg;base64,${result.heatmap_image}`;
});
```

---

### Python

```python
import requests
import base64
from PIL import Image
import io

API_URL = 'http://localhost:5001'

def analyze_image(image_path: str) -> dict:
    with open(image_path, 'rb') as f:
        response = requests.post(
            f'{API_URL}/analyze',
            files={'file': f}
        )
    response.raise_for_status()
    return response.json()

def save_result_images(result: dict, output_dir: str = '.'):
    # Decode and save original image
    original = Image.open(io.BytesIO(base64.b64decode(result['original_image'])))
    original.save(f'{output_dir}/original.jpg')

    # Decode and save heatmap image
    heatmap = Image.open(io.BytesIO(base64.b64decode(result['heatmap_image'])))
    heatmap.save(f'{output_dir}/heatmap.jpg')

# Usage
result = analyze_image('ct_scan.jpg')
print(f"Prediction : {result['prediction']}")
print(f"Confidence : {result['confidence']}%")
save_result_images(result)
```

---

## Error Handling

| Status Code | Cause                          | Fix                                  |
|-------------|--------------------------------|--------------------------------------|
| `400`       | No file field in request       | Ensure field name is `file`          |
| `400`       | Empty filename                 | Ensure a file is actually selected   |
| `500`       | Server/model error             | Check server logs for details        |
| Connection refused | Server not running        | Run `python app.py`                  |

> **Flutter tip:** Use `192.168.1.103:5001` (your machine's local IP) instead of `localhost` when testing on a physical device or Android emulator.

