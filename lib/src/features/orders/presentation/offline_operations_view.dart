import 'package:flutter/material.dart';

import '../../../core/offline/offline_sync_service.dart';
import '../../../core/offline/outbox_processor.dart';
import '../../../core/offline/outbox_queue.dart';
import '../../../core/workmanager/sync_worker.dart';
import '../data/repositories/offline_order_repository.dart';
import '../../manifests/data/repositories/offline_manifest_repository.dart';

class OfflineOperationsView extends StatefulWidget {
  const OfflineOperationsView({super.key});

  @override
  State<OfflineOperationsView> createState() => _OfflineOperationsViewState();
}

class _OfflineOperationsViewState extends State<OfflineOperationsView> {
  final _baseUrlController = TextEditingController();
  final _customerController = TextEditingController();
  final _routeController = TextEditingController();
  final _orders = OfflineOrderRepository();
  final _manifests = OfflineManifestRepository();
  final _queue = OutboxQueue();
  late final _processor = OutboxProcessor(queue: _queue);
  late final _syncService = OfflineSyncService(
    processor: _processor,
    onSyncError: (error) {
      if (mounted) setState(() => _message = 'Automatic sync failed: $error');
    },
  );
  List<Map<String, Object?>> _orderRows = [];
  List<Map<String, Object?>> _manifestRows = [];
  int _pendingCount = 0;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
    _loadBaseUrl();
    _startSyncService();
  }

  Future<void> _startSyncService() async {
    try {
      await _syncService.start();
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not start background sync: $error');
    }
  }

  Future<void> _loadBaseUrl() async {
    final value = await OutboxProcessor.getApiBaseUrl();
    if (mounted && value != null) _baseUrlController.text = value;
  }

  Future<void> _load() async {
    final rows = await _orders.list();
    final manifests = await _manifests.list();
    final count = await _queue.length;
    if (!mounted) return;
    setState(() {
      _orderRows = rows;
      _manifestRows = manifests;
      _pendingCount = count;
    });
  }

  Future<void> _saveBaseUrl() async {
    try {
      await OutboxProcessor.setApiBaseUrl(_baseUrlController.text.trim());
      await const SyncWorker().schedule();
      if (mounted) setState(() => _message = 'Sync server saved.');
    } catch (error) {
      if (mounted) setState(() => _message = 'Invalid sync server URL: $error');
    }
  }

  Future<void> _createOrder() async {
    final customer = _customerController.text.trim();
    if (customer.isEmpty) {
      setState(() => _message = 'Enter a customer name first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _orders.create(customerName: customer, status: 'pending');
      _customerController.clear();
      setState(() => _message = 'Order stored locally and queued for sync.');
      await _load();
    } catch (error) {
      setState(() => _message = 'Could not save order: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createManifest() async {
    final route = _routeController.text.trim();
    if (route.isEmpty) {
      setState(() => _message = 'Enter a route code first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _manifests.create(routeCode: route, totalStops: 0);
      _routeController.clear();
      setState(() => _message = 'Manifest stored locally and queued for sync.');
      await _load();
    } catch (error) {
      setState(() => _message = 'Could not save manifest: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    try {
      final count = await _syncService.syncPendingActions();
      setState(() => _message = 'Synced $count queued action(s).');
      await _load();
    } catch (error) {
      setState(() => _message = 'Sync failed. Actions remain queued: $error');
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _syncService.stop();
    _processor.close();
    _baseUrlController.dispose();
    _customerController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline-first operations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Queued mutations: $_pendingCount'),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Sync API base URL',
              hintText: 'https://api.example.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : _saveBaseUrl,
                child: const Text('Save server'),
              ),
              FilledButton.icon(
                onPressed: _busy || _pendingCount == 0 ? null : _syncNow,
                icon: const Icon(Icons.sync),
                label: const Text('Sync now'),
              ),
            ],
          ),
          const Divider(height: 32),
          TextField(
            controller: _customerController,
            decoration: const InputDecoration(
              labelText: 'Customer name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _createOrder,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Save order offline'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _routeController,
            decoration: const InputDecoration(
              labelText: 'Manifest route code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _createManifest,
            icon: const Icon(Icons.route),
            label: const Text('Save manifest offline'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
          const Divider(height: 32),
          Text('Local orders (${_orderRows.length})'),
          for (final order in _orderRows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(order['customer_name']! as String),
              subtitle: Text('${order['status']} · ${order['id']}'),
              trailing: Icon(
                order['synced'] == 1 ? Icons.cloud_done : Icons.cloud_upload,
              ),
            ),
          const SizedBox(height: 12),
          Text('Local manifests (${_manifestRows.length})'),
          for (final manifest in _manifestRows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(manifest['route_code']! as String),
              subtitle: Text(
                '${manifest['total_stops']} stops · ${manifest['id']}',
              ),
              trailing: Icon(
                manifest['synced'] == 1 ? Icons.cloud_done : Icons.cloud_upload,
              ),
            ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
