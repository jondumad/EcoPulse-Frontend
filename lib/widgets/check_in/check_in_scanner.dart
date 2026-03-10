import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckInScanner extends StatelessWidget {
  final MobileScannerController controller;
  final bool isProcessing;
  final Function(String) onDetect;
  final VoidCallback onClose;

  const CheckInScanner({
    super.key,
    required this.controller,
    required this.isProcessing,
    required this.onDetect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400, // Fixed height for scanner
      color: Colors.black,
      child: Stack(
        children: [
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  onDetect(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          CustomPaint(
            painter: ScannerOverlay(
              isProcessing ? AppTheme.violet : AppTheme.forest,
            ),
            child: Container(),
          ),
          // Close Button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Loading Indicator
          if (isProcessing)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Verifying...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Hint Text
          if (!isProcessing)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Scan the Mission QR Code',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  final Color borderColor;
  ScannerOverlay(this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    const scanArea = 220.0;
    final left = (size.width - scanArea) / 2;
    final top = (size.height / 2) - (scanArea / 2);
    final rect = Rect.fromLTWH(left, top, scanArea, scanArea);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(32))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    // Draw corners only for a premium look
    const cornerLength = 30.0;
    final path = Path();

    // Top Left
    path.moveTo(left, top + cornerLength);
    path.lineTo(left, top);
    path.lineTo(left + cornerLength, top);

    // Top Right
    path.moveTo(left + scanArea - cornerLength, top);
    path.lineTo(left + scanArea, top);
    path.lineTo(left + scanArea, top + cornerLength);

    // Bottom Right
    path.moveTo(left + scanArea, top + scanArea - cornerLength);
    path.lineTo(left + scanArea, top + scanArea);
    path.lineTo(left + scanArea - cornerLength, top + scanArea);

    // Bottom Left
    path.moveTo(left + cornerLength, top + scanArea);
    path.lineTo(left, top + scanArea);
    path.lineTo(left, top + scanArea - cornerLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
