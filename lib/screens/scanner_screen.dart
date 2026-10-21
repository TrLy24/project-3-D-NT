import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import '../core/app_theme.dart';
import '../providers/scanner_provider.dart';
import '../services/ocr_service.dart';
import '../widgets/camera_overlay.dart';
import 'edit_transaction_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  String? _cameraError;

  bool get _supportsLiveCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_supportsLiveCamera) _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_supportsLiveCamera) return;
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Thiết bị không tìm thấy camera.');
      }
      _cameraDescription = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        _cameraDescription!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController = controller;
      await controller.initialize();
      if (mounted) setState(() => _cameraError = null);
    } catch (error) {
      await _disposeCamera();
      if (mounted) setState(() => _cameraError = error.toString());
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) await controller.dispose();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) controller.dispose();
    super.dispose();
  }

  Future<void> _processImage(String imagePath) async {
    try {
      final scannerProvider = context.read<ScannerProvider>();
      final ocrResult = await scannerProvider.scanReceiptImage(imagePath);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditTransactionScreen(
            ocrData: ocrResult,
            ocrLatencyMs: scannerProvider.lastProcessingTimeMs,
            receiptImagePath: imagePath,
          ),
        ),
      );
    } catch (error) {
      _showError('Không thể quét hóa đơn: $error');
    }
  }

  Future<void> _captureReceipt() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showError(
        _cameraError ??
            'Camera chưa sẵn sàng. Bạn có thể chọn ảnh từ thư viện.',
      );
      return;
    }
    try {
      final image = await controller.takePicture();
      if (mounted) await _processImage(image.path);
    } catch (error) {
      _showError('Không thể chụp ảnh: $error');
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showError('Camera chưa sẵn sàng để bật đèn flash.');
      return;
    }
    final isOn = !context.read<ScannerProvider>().isFlashOn;
    try {
      await controller.setFlashMode(isOn ? FlashMode.torch : FlashMode.off);
      if (mounted) context.read<ScannerProvider>().setFlashOn(isOn);
    } catch (error) {
      _showError('Không thể thay đổi đèn flash: $error');
    }
  }

  Future<void> _focusCamera(TapDownDetails details, Size previewSize) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final point = Offset(
      (details.localPosition.dx / previewSize.width).clamp(0.0, 1.0),
      (details.localPosition.dy / previewSize.height).clamp(0.0, 1.0),
    );
    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } catch (error) {
      _showError('Không thể lấy nét tại vị trí đã chọn: $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        await _processImage(image.path);
      }
    } catch (e) {
      _showError('Lỗi tải ảnh: $e');
    }
  }

  Future<void> _handleSampleSelect(SampleReceipt sample) async {
    final scannerProvider = context.read<ScannerProvider>();
    final ocrResult = await scannerProvider.scanSampleReceipt(sample);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditTransactionScreen(
            ocrData: ocrResult,
            ocrLatencyMs: scannerProvider.lastProcessingTimeMs,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanner = context.watch<ScannerProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraController case final controller?
              when controller.value.isInitialized)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _focusCamera(
                    details,
                    Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  child: CameraPreview(controller),
                ),
              ),
            )
          else
            Container(
              color: const Color(0xFF1E293B),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _cameraError == null
                          ? _supportsLiveCamera
                                ? 'Đang khởi tạo camera...'
                                : 'Camera trực tiếp chỉ hỗ trợ trên Android/iOS. Bạn có thể chọn ảnh hoặc dùng mẫu demo.'
                          : 'Không thể mở camera. Hãy chọn ảnh hoặc dùng mẫu demo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Camera Overlay with dynamic laser & corner brackets
          const CameraScannerOverlay(scanWidth: 290, scanHeight: 380),

          // Top Bar: Back button, Title & Flash Toggle
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.offline_bolt,
                          color: AppColors.success,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'OCR trên thiết bị • Offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(
                        scanner.isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: scanner.isFlashOn
                            ? AppColors.accent
                            : Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Indicator
          if (scanner.isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Đang nhận diện & bóc tách bằng Regex...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Controls & Quick Sample Selector
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Test Receipts Presets
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mẫu hóa đơn kiểm thử nhanh (Demo):',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: OcrService.sampleReceipts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final sample = OcrService.sampleReceipts[idx];
                        return ActionChip(
                          backgroundColor: const Color(0xFF334155),
                          label: Text(
                            sample.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: () => _handleSampleSelect(sample),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom action buttons: Gallery & Capture
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pick from gallery
                      IconButton(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        tooltip: 'Chọn ảnh từ thư viện',
                      ),

                      // Large Shutter Button
                      GestureDetector(
                        onTap: _captureReceipt,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Manual Add
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditTransactionScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: 32,
                        ),
                        tooltip: 'Nhập thủ công',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
