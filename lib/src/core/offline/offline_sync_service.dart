import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../network/connectivity_sync.dart';
import '../workmanager/sync_worker.dart';
import 'outbox_processor.dart';

class OfflineSyncService {
  OfflineSyncService({
    required this.processor,
    ConnectivitySync? connectivitySync,
    this.onSyncError,
  }) : _connectivitySync = connectivitySync ?? const ConnectivitySync();

  final OutboxProcessor processor;
  final ConnectivitySync _connectivitySync;
  final ValueChanged<Object>? onSyncError;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _syncing = false;

  Future<void> start() async {
    await SyncWorker.initialize();
    await _subscription?.cancel();
    _subscription = _connectivitySync.watch().listen(
      (results) {
        if (_hasNetwork(results)) {
          unawaited(_trySync());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (onSyncError != null) {
          onSyncError!(error);
        } else {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'connectivity listener',
            ),
          );
        }
      },
    );
    if (_hasNetwork(await _connectivitySync.check())) {
      await _trySync();
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<int> syncPendingActions() => processor.processPending();

  Future<void> _trySync() async {
    if (_syncing) return;
    _syncing = true;
    try {
      if (await OutboxProcessor.getApiBaseUrl() == null) return;
      await processor.processPending();
    } catch (error, stackTrace) {
      if (onSyncError != null) {
        onSyncError!(error);
      } else {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'offline sync',
            context: ErrorDescription('while automatically syncing queued actions'),
          ),
        );
      }
    } finally {
      _syncing = false;
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
