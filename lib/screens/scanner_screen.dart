import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../models/scan_history_model.dart';
import '../theme/app_theme.dart';
import '../widgets/scan_result_sheet.dart';
import '../widgets/ad_banner_widget.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isScanModeQR = true;
  bool _isProcessingOCR = false;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final mlkit.BarcodeScanner _barcodeScanner = mlkit.BarcodeScanner();
  final ImagePicker _picker = ImagePicker();
  
  double _zoomFactor = 0.0;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSource(AssetSource('audio/beep.mp3'));
  }

  @override
  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
    _barcodeScanner.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndProcessOCR() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isProcessingOCR = true);
    _controller.stop();

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text found in image')),
          );
        }
      } else {
        _handleScanSuccess(recognizedText.text, isOCR: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingOCR = false);
        _controller.start();
      }
    }
  }

  Future<void> _pickImageAndScanQR() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isProcessingOCR = true);
    _controller.stop();

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final List<mlkit.Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
      
      if (barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR Code or Barcode found in image')),
          );
        }
      } else {
        final code = barcodes.first.rawValue;
        if (code != null) {
          _handleScanSuccess(code, isOCR: false, isGallery: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingOCR = false);
        _controller.start();
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        _handleScanSuccess(code);
      }
    }
  }

  void _handleScanSuccess(String code, {bool isOCR = false, bool isGallery = false}) {
    if (!isOCR && !isGallery && !_controller.value.isRunning) return;
    
    // Feedback
    if (!isOCR) {
      _audioPlayer.resume();
      HapticFeedback.lightImpact();
      _audioPlayer.seek(Duration.zero);
    }
    
    final provider = context.read<HistoryProvider>();

    // Determine result type
    String resultType = isOCR ? 'text' : 'text';
    if (!isOCR) {
      if (Uri.tryParse(code)?.hasScheme ?? false) {
        resultType = 'url';
      } else if (RegExp(r'^\+?[0-9]{7,15}$').hasMatch(code)) {
        resultType = 'phone';
      } else if (code.contains('@') && code.contains('.')) {
        resultType = 'email';
      }
    }

    final scan = ScanHistory(
      content: code,
      type: isOCR ? 'ocr' : (isGallery ? 'gallery' : (_isScanModeQR ? 'qr' : 'barcode')),
      resultType: resultType,
      scannedAt: DateTime.now(),
      isGenerated: false,
      category: isOCR ? 'Other' : provider.getRecommendedCategory(code, resultType),
    );

    if (provider.isBatchMode && !isOCR && !isGallery) {
      provider.addScan(scan);
      return;
    }

    _controller.stop();
    provider.addScan(scan);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanResultSheet(
        content: code,
        type: scan.type,
        resultType: resultType,
      ),
    ).then((_) {
      if (mounted) _controller.start();
    });
  }

  void _showBatchPreview(BuildContext context, HistoryProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Batch', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: provider.batchScans.isEmpty
                  ? const Center(child: Text('No scans in batch'))
                  : ListView.builder(
                      itemCount: provider.batchScans.length,
                      itemBuilder: (context, index) {
                        final scan = provider.batchScans[index];
                        return ListTile(
                          title: Text(scan.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(DateFormat('hh:mm:ss a').format(scan.scannedAt)),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () => provider.removeFromBatch(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Feature Guide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.layers_outlined, color: AppTheme.textSecondary),
              title: Text('Batch Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Scan multiple items in sequence and save them all at once.'),
            ),
            const ListTile(
              leading: Icon(Icons.image_outlined, color: AppTheme.textSecondary),
              title: Text('Gallery Scan', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Import QR codes or Barcodes directly from your photos.'),
            ),
            const ListTile(
              leading: Icon(Icons.text_fields_outlined, color: AppTheme.textSecondary),
              title: Text('OCR Text Recognition', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Extract text from any image using smart OCR technology.'),
            ),
            const ListTile(
              leading: Icon(Icons.translate, color: AppTheme.textSecondary),
              title: Text('Offline Translation', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Translate scanned text directly into Bengali.'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    return Stack(
      children: [
        GestureDetector(
          onScaleUpdate: (details) {
            if (details.scale > 1.0) {
              _zoomFactor = (_zoomFactor + 0.01).clamp(0.0, 1.0);
            } else if (details.scale < 1.0) {
              _zoomFactor = (_zoomFactor - 0.01).clamp(0.0, 1.0);
            }
            _controller.setZoomScale(_zoomFactor);
          },
          child: MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
        ),
        // Scan Frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                _buildCorner(top: 0, left: 0, isTop: true, isLeft: true),
                _buildCorner(top: 0, right: 0, isTop: true, isRight: true),
                _buildCorner(bottom: 0, left: 0, isBottom: true, isLeft: true),
                _buildCorner(bottom: 0, right: 0, isBottom: true, isRight: true),
              ],
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(duration: 2.seconds, color: AppTheme.accent.withValues(alpha: 0.5))
          .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 1.seconds, curve: Curves.easeInOut),
        ),
        if (_isProcessingOCR)
          const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        // Batch Indicator
        if (provider.isBatchMode && provider.batchScans.isNotEmpty)
          Positioned(
            top: 100,
            right: 20,
            child: GestureDetector(
              onTap: () => _showBatchPreview(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.list_alt, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Items: ${provider.batchScans.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Mode Controls
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(true, 'QR Code'),
                    _buildModeButton(false, 'Barcode'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSmallToggle(
                    icon: Icons.layers_outlined,
                    label: 'Batch',
                    isActive: provider.isBatchMode,
                    onTap: () => provider.toggleBatchMode(),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Help Guide
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 28),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showHelpGuide(context);
            },
          ),
        ),
        // Bottom Controls
        Positioned(
          bottom: provider.isBatchMode ? 160 : 100,
          left: 40,
          right: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                icon: _isFlashOn ? Icons.flashlight_off_outlined : Icons.flashlight_on_outlined,
                onPressed: () {
                  _controller.toggleTorch();
                  setState(() => _isFlashOn = !_isFlashOn);
                },
              ),
              Row(
                children: [
                  _buildCircleButton(
                    icon: Icons.text_fields_outlined,
                    onPressed: _pickImageAndProcessOCR,
                  ),
                  const SizedBox(width: 20),
                  _buildCircleButton(
                    icon: Icons.image_outlined,
                    onPressed: _pickImageAndScanQR,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (provider.isBatchMode && provider.batchScans.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 60,
            right: 60,
            child: ElevatedButton(
              onPressed: () => provider.saveBatch(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Save Batch Result'),
            ),
          ),
        // Ad Container
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: AppTheme.background,
            child: const AdBannerWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallToggle({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent.withValues(alpha: 0.2) : Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.accent : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? AppTheme.accent : Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? AppTheme.accent : Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(bool isQR, String label) {
    bool selected = _isScanModeQR == isQR;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isScanModeQR = isQR);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? left,
    double? right,
    double? bottom,
    bool isTop = false,
    bool isLeft = false,
    bool isRight = false,
    bool isBottom = false,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppTheme.accent, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppTheme.accent, width: 4) : BorderSide.none,
            right: isRight ? const BorderSide(color: AppTheme.accent, width: 4) : BorderSide.none,
            bottom: isBottom ? const BorderSide(color: AppTheme.accent, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
