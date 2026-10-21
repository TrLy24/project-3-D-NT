import 'package:flutter/material.dart';

import '../models/ocr_result.dart';
import '../services/ocr_service.dart';

class ScannerProvider extends ChangeNotifier {
  final OcrService _ocrService = OcrService.instance;

  bool _isProcessing = false;
  bool _isFlashOn = false;
  int _lastProcessingTimeMs = 0;
  OcrExtractedData? _lastExtractedData;
  String? _capturedImagePath;

  bool get isProcessing => _isProcessing;
  bool get isFlashOn => _isFlashOn;
  int get lastProcessingTimeMs => _lastProcessingTimeMs;
  OcrExtractedData? get lastExtractedData => _lastExtractedData;
  String? get capturedImagePath => _capturedImagePath;

  void setFlashOn(bool isOn) {
    _isFlashOn = isOn;
    notifyListeners();
  }

  Future<OcrExtractedData> scanReceiptImage(String imagePath) async {
    _isProcessing = true;
    _capturedImagePath = imagePath;
    notifyListeners();

    final sw = Stopwatch()..start();
    try {
      final result = await _ocrService.processImage(imagePath);
      sw.stop();
      _lastProcessingTimeMs = sw.elapsedMilliseconds;
      _lastExtractedData = result;
      return result;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<OcrExtractedData> scanSampleReceipt(SampleReceipt sample) async {
    _isProcessing = true;
    _capturedImagePath = sample.assetOrPreview;
    notifyListeners();

    final sw = Stopwatch()..start();
    try {
      final result = _ocrService.processText(sample.rawText);
      sw.stop();
      _lastProcessingTimeMs = sw.elapsedMilliseconds;
      _lastExtractedData = result;
      return result;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void reset() {
    _lastExtractedData = null;
    _capturedImagePath = null;
    _lastProcessingTimeMs = 0;
    _isProcessing = false;
    notifyListeners();
  }
}
