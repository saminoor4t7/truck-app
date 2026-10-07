import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../data/printer_driver.dart';

class PrinterView extends StatefulWidget {
  const PrinterView({super.key});

  @override
  State<PrinterView> createState() => _PrinterViewState();
}

class _PrinterViewState extends State<PrinterView> {
  final PrinterDriver _driver = const PrinterDriver();
  final TextEditingController _receiptController = TextEditingController(
    text: 'Order: #12345\nCustomer: Delivery customer\nStatus: Delivered',
  );
  List<ScanResult> _printers = [];
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _receiptController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _busy = true;
      _status = 'Checking Bluetooth…';
    });
    try {
      if (!await _ensureBluetoothEnabled()) return;
      if (!mounted) return;
      setState(() => _status = 'Scanning nearby Bluetooth LE printers…');
      final results = await _driver.scanNearby();
      if (!mounted) return;
      setState(() {
        _printers = results;
        _status = results.isEmpty
            ? 'No BLE printers found. Check Bluetooth and printer power.'
            : 'Select a printer to print.';
      });
    } catch (error) {
      if (mounted) setState(() => _status = 'Scan failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _ensureBluetoothEnabled() async {
    final adapterState = await FlutterBluePlus.adapterState.first.timeout(
      const Duration(seconds: 5),
    );
    if (!mounted) return false;
    if (adapterState == BluetoothAdapterState.on) return true;
    if (adapterState == BluetoothAdapterState.unavailable) {
      if (mounted) {
        setState(() => _status = 'Bluetooth is not available on this device.');
      }
      return false;
    }

    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bluetooth is turned off'),
        content: Text(
          isAndroid
              ? 'Bluetooth must be enabled to find nearby printers.'
              : 'Enable Bluetooth in your device settings, then continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isAndroid ? 'Enable Bluetooth' : 'Continue'),
          ),
        ],
      ),
    );
    if (shouldEnable != true) return false;

    if (isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    try {
      await FlutterBluePlus.adapterState
          .firstWhere((state) => state == BluetoothAdapterState.on)
          .timeout(const Duration(seconds: 20));
      return true;
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _status = 'Bluetooth is still off. Enable it and try again.',
        );
      }
      return false;
    }
  }

  Future<void> _print(BluetoothDevice device) async {
    setState(() {
      _busy = true;
      _status = 'Connecting and printing…';
    });
    try {
      await _driver.printReceipt(
        device: device,
        content: _receiptController.text,
      );
      if (mounted) setState(() => _status = 'Receipt sent to printer.');
    } catch (error) {
      if (mounted) setState(() => _status = 'Print failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth receipt printer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'BLE printers only. Classic Bluetooth printers require a platform-specific classic Bluetooth driver.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _receiptController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Receipt content',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _scan,
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Find BLE printers'),
          ),
          if (_status != null) ...[const SizedBox(height: 12), Text(_status!)],
          for (final result in _printers)
            Card(
              child: ListTile(
                leading: const Icon(Icons.print),
                title: Text(
                  result.device.platformName.isEmpty
                      ? 'Unnamed printer'
                      : result.device.platformName,
                ),
                subtitle: Text(result.device.remoteId.str),
                trailing: IconButton(
                  tooltip: 'Print receipt',
                  onPressed: _busy ? null : () => _print(result.device),
                  icon: const Icon(Icons.print_outlined),
                ),
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
