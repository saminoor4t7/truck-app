import 'dart:async';
import 'dart:math' as math;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PrinterDriver {
  const PrinterDriver();

  Future<List<ScanResult>> scanNearby({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final resultsByDevice = <String, ScanResult>{};
    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        resultsByDevice[result.device.remoteId.str] = result;
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await Future<void>.delayed(timeout);
      return resultsByDevice.values.toList(growable: false);
    } finally {
      await subscription.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  Future<void> printReceipt({
    required BluetoothDevice device,
    required String content,
    String title = 'DELIVERY RECEIPT',
  }) async {
    await device.connect(timeout: const Duration(seconds: 20));
    try {
      final services = await device.discoverServices();
      final writable = services
          .expand((service) => service.characteristics)
          .where(
            (characteristic) =>
                characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse,
          )
          .toList();
      if (writable.isEmpty) {
        throw StateError('Printer has no writable BLE characteristic.');
      }
      final characteristic = writable.first;
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      final bytes = <int>[
        ...generator.text(
          title,
          styles: const PosStyles(align: PosAlign.center, bold: true),
          linesAfter: 1,
        ),
        ...generator.text(content),
        ...generator.feed(2),
        ...generator.cut(),
      ];
      final packetSize = math.max(20, device.mtuNow - 3);
      for (var offset = 0; offset < bytes.length; offset += packetSize) {
        final end = math.min(offset + packetSize, bytes.length).toInt();
        await characteristic.write(
          bytes.sublist(offset, end),
          withoutResponse:
              characteristic.properties.writeWithoutResponse &&
              !characteristic.properties.write,
        );
      }
    } finally {
      if (device.isConnected) await device.disconnect();
    }
  }
}
