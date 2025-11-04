import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/colors.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;
  bool _torchEnabled = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        Navigator.pop(context, barcode.rawValue);
        break;
      }
    }
  }

  void _showManualEntryDialog() {
    final TextEditingController controller = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Enter Code Manually',
              style: TextStyle(color: isDark ? Colors.white : AppColors.black),
            ),
            content: TextField(
              controller: controller,
              style: TextStyle(color: isDark ? Colors.white : AppColors.black),
              decoration: InputDecoration(
                hintText: 'Enter device ID',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : AppColors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade600 : AppColors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade600 : AppColors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryGreen),
                ),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : AppColors.grey,
                  ), // ✅ Add
                ),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    Navigator.pop(context, controller.text.trim());
                  }
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ADD THESE TWO LINES:
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : AppColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan QR Code',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: isDark ? Colors.white : AppColors.black,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor:
                          isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      // ✅ Add
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'How to Scan',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.black,
                        ), // ✅ Add
                      ),
                      content: Text(
                        'Point your camera at the QR code on your device. '
                        'The code will be scanned automatically when it\'s in focus.',
                        style: TextStyle(
                          color:
                              isDark ? Colors.grey.shade300 : AppColors.black,
                        ), // ✅ Add
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'OK',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner with border
          Center(
            child: Container(
              width: 300,
              height: 300,
              margin: const EdgeInsets.only(bottom: 100),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreen, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: _onDetect,
                ),
              ),
            ),
          ),

          // Scanner Overlay with corners
          CustomPaint(painter: ScannerOverlay(), child: Container()),

          // Instruction Text
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Text(
                  'Align the QR code within the frame to add your plant.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade300 : AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 29),

          // Buttons
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Manual Entry Button
                  ElevatedButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard, size: 18),
                    label: const Text(
                      'Enter Code Manually',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF0F0F0),
                      // ✅ Update
                      foregroundColor: isDark ? Colors.white : AppColors.black,
                      // ✅ Update
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Torch Toggle Button
                  Container(
                    decoration: BoxDecoration(
                      color:
                          _torchEnabled
                              ? AppColors.primaryGreen
                              : (isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF0F0F0)),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _torchEnabled ? Icons.flash_on : Icons.flash_off,
                        color:
                            _torchEnabled
                                ? Colors.white
                                : (isDark ? Colors.white : AppColors.black),
                      ),
                      onPressed: () {
                        setState(() => _torchEnabled = !_torchEnabled);
                        cameraController.toggleTorch();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', false, 0, isDark),
              _buildNavItem(Icons.qr_code_scanner, 'Scan', true, 1, isDark),
              _buildNavItem(Icons.tune, 'Control', false, 2, isDark),
              _buildNavItem(
                Icons.notifications_outlined,
                'Notifications',
                false,
                3,
                isDark,
              ),
              _buildNavItem(Icons.person_outline, 'Profile', false, 4, isDark),
              _buildNavItem(
                Icons.emoji_events_outlined,
                'Rewards',
                false,
                5,
                isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    int index,
    bool isDark,
  ) {
    // ✅ Add bool isDark
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // Already on Scan screen, do nothing
          return;
        }
        // Pop and pass the tab index to navigate to
        Navigator.pop(context, {'action': 'navigate', 'index': index});
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? AppColors.primaryGreen
                      : (isDark ? Colors.grey.shade400 : AppColors.grey),
              // ✅ Update
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color:
                    isSelected
                        ? AppColors.primaryGreen
                        : (isDark ? Colors.grey.shade400 : AppColors.grey),
                // ✅ Update
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, (size.height / 2) - 50),
      width: 300,
      height: 300,
    );

    final cornerPaint =
        Paint()
          ..color = AppColors.primaryGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    const cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top + cornerLength),
      Offset(scanArea.left, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.top),
      Offset(scanArea.right, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      Offset(scanArea.left, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      Offset(scanArea.right, scanArea.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
