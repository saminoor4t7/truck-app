import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../offline/local_database.dart';
import '../offline/outbox_processor.dart';
import '../offline/outbox_queue.dart';

const syncTaskName = 'truck_app_outbox_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != syncTaskName) return true;
    if (await OutboxProcessor.getApiBaseUrl() == null) return true;
    try {
      final processor = OutboxProcessor(queue: OutboxQueue());
      await processor.processPending();
      processor.close();
      await LocalDatabase.instance.close();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Background outbox sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await LocalDatabase.instance.close();
      return false;
    }
  });
}

class SyncWorker {
  const SyncWorker();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_initialized) return;
    await Workmanager().initialize(callbackDispatcher);
    _initialized = true;
  }

  Future<void> schedule() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await initialize();
    await Workmanager().registerOneOffTask(
      'outbox-sync-${DateTime.now().microsecondsSinceEpoch}',
      syncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }
}
