import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../shared/widgets/app_drawer.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key, this.onCode, this.isActive = true});

  final ValueChanged<Barcode>? onCode;
  final bool isActive;

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
    ],
  );
  Barcode? _lastBarcode;
  bool _paused = false;
  String? _startError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ScannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      _startScanner();
    } else {
      _stopScanner();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_paused || capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.firstWhere(
      (item) => item.rawValue?.isNotEmpty == true,
      orElse: () => capture.barcodes.first,
    );
    if (barcode.rawValue == null) return;
    setState(() {
      _lastBarcode = barcode;
      _paused = true;
    });
    _stopScanner();
  }

  void _useScannedCode() {
    final barcode = _lastBarcode;
    if (barcode == null) return;
    widget.onCode?.call(barcode);
  }

  Future<void> _scanAgain() async {
    setState(() => _paused = false);
    await _startScanner();
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
      if (mounted) setState(() => _startError = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _startError = 'Could not start camera: $error');
    }
  }

  Future<void> _stopScanner() async {
    try {
      await _controller.stop();
    } catch (error) {
      if (mounted) {
        setState(() => _startError = 'Could not stop camera: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppDrawerMenuButton(),
        title: const Text('Barcode scanner'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Camera error: ${error.errorCode.name}'),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_startError != null)
                  Text(
                    _startError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else if (_lastBarcode case final barcode?)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'OK',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          barcode.rawValue!,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  const Text('Point the camera at a QR code or barcode'),
                const SizedBox(height: 12),
                if (_paused && widget.onCode != null)
                  FilledButton.icon(
                    onPressed: _useScannedCode,
                    icon: const Icon(Icons.check),
                    label: const Text('Use scanned code'),
                  )
                else if (_paused)
                  FilledButton.icon(
                    onPressed: _scanAgain,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan another'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
