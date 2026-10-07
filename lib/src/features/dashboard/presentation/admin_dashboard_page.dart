import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../orders/data/repositories/local_order_repository.dart';
import '../../orders/domain/entities/order.dart';
import '../../pod_signature/data/local_signature_repository.dart';
import '../../tracking/data/repositories/telemetry_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const _driverNamePreferenceKey = 'driver_profile_name';

  final _orders = GetIt.I<LocalOrderRepository>();
  final _telemetry = TelemetryRepository();
  final _signatures = LocalSignatureRepository();
  final _mapController = MapController();
  Timer? _refreshTimer;
  List<Order> _allOrders = const [];
  List<SavedSignature> _savedSignatures = const [];
  LatLng? _latestLocation;
  DateTime? _locationTime;
  String _driverName = 'Driver';
  String? _error;
  bool _mapReady = false;
  bool _loading = true;
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _adminDestinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Overview',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment),
      label: 'Tasks',
    ),
    NavigationDestination(
      icon: Icon(Icons.location_on_outlined),
      selectedIcon: Icon(Icons.location_on),
      label: 'Location',
    ),
    NavigationDestination(
      icon: Icon(Icons.draw_outlined),
      selectedIcon: Icon(Icons.draw),
      label: 'Signatures',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refresh(),
    );
  }

  Future<void> _refresh() async {
    try {
      final orders = await _orders.allOrders();
      final locations = await _telemetry.recent(limit: 1);
      final savedSignatures = await _signatures.all();
      final preferences = await SharedPreferences.getInstance();
      LatLng? location;
      DateTime? locationTime;
      if (locations.isNotEmpty) {
        final row = locations.first;
        final latitude = row['latitude'];
        final longitude = row['longitude'];
        final timestamp = row['recorded_at'];
        if (latitude is num && longitude is num) {
          location = LatLng(latitude.toDouble(), longitude.toDouble());
        }
        if (timestamp is String) locationTime = DateTime.tryParse(timestamp);
      }
      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _savedSignatures = savedSignatures;
        _latestLocation = location;
        _locationTime = locationTime;
        _driverName =
            preferences.getString(_driverNamePreferenceKey) ?? 'Driver';
        _error = null;
        _loading = false;
      });
      if (_mapReady && location != null) _moveToLocation(location);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not refresh the admin dashboard: $error';
        _loading = false;
      });
    }
  }

  void _moveToLocation(LatLng location) {
    _mapController.move(location, 15);
  }

  Future<void> _createTask() async {
    final taskDetails = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _AssignTaskDialog(driverName: _driverName),
    );
    if (taskDetails == null || !mounted) return;

    try {
      final order = await _orders.createTask(
        customerName: taskDetails.$1,
        deliveryAddress: taskDetails.$2,
      );
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${order.orderNumber} assigned to $_driverName.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not assign delivery: $error')),
      );
    }
  }

  Future<void> _showSignature(Order order) async {
    final path = order.signatureUrl;
    if (path == null) return;
    await _showSignatureFile('${order.orderNumber} signature', path);
  }

  Future<void> _showSavedSignature(SavedSignature signature) =>
      _showSignatureFile('Saved signature', signature.filePath);

  Future<void> _showSignatureFile(String title, String path) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 480,
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Text('Could not display the saved signature: $error'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Admin dashboard',
      'Driver tasks',
      'Truck location',
      'Signatures',
    ];
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Admin dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Driver'),
                subtitle: const Text('Return to driver dashboard'),
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Open navigation drawer',
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(titles[_selectedIndex]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildOverview(context),
                _buildTasks(context),
                _buildLocation(context),
                _buildSignatures(context),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: _adminDestinations,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 2) _refresh();
        },
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final inRoute = _allOrders
        .where((order) => order.status == OrderStatus.inTransit)
        .length;
    final completed = _allOrders
        .where((order) => order.status == OrderStatus.delivered)
        .toList();
    final signedCount = completed
        .where((order) => order.signatureUrl != null)
        .length;
    return _refreshable(
      onRefresh: _refresh,
      children: [
        if (_error != null) _errorCard(context),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('Driver: $_driverName'),
            subtitle: Text(
              '${_allOrders.length} total tasks · $inRoute in route · '
              '${completed.length} completed',
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _createTask,
          icon: const Icon(Icons.add_task),
          label: const Text('Assign new task to driver'),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Latest truck location'),
            subtitle: Text(
              _latestLocation == null
                  ? 'No truck location recorded yet.'
                  : '${_latestLocation!.latitude.toStringAsFixed(6)}, '
                        '${_latestLocation!.longitude.toStringAsFixed(6)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selectedIndex = 2),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.draw_outlined),
            title: const Text('Signed deliveries'),
            subtitle: Text('$signedCount signatures available to review'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selectedIndex = 3),
          ),
        ),
      ],
    );
  }

  Widget _buildTasks(BuildContext context) => _refreshable(
    onRefresh: _refresh,
    children: [
      if (_error != null) _errorCard(context),
      FilledButton.icon(
        onPressed: _createTask,
        icon: const Icon(Icons.add_task),
        label: const Text('Assign new task to driver'),
      ),
      const SizedBox(height: 12),
      if (_allOrders.isEmpty)
        const Text('No tasks assigned yet.')
      else
        for (final order in _allOrders)
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(order.customerName),
              subtitle: Text('${order.orderNumber}\n${order.deliveryAddress}'),
              isThreeLine: true,
              trailing: Chip(label: Text(order.status.label)),
            ),
          ),
    ],
  );

  Widget _buildLocation(BuildContext context) {
    final latestLocation = _latestLocation;
    return _refreshable(
      onRefresh: _refresh,
      children: [
        if (_error != null) _errorCard(context),
        SizedBox(
          height: 320,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: latestLocation ?? const LatLng(0, 0),
                initialZoom: latestLocation == null ? 2 : 15,
                onMapReady: () {
                  _mapReady = true;
                  if (latestLocation != null) {
                    _moveToLocation(latestLocation);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.truck_app',
                  maxNativeZoom: 19,
                ),
                if (latestLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latestLocation,
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.local_shipping,
                          color: Theme.of(context).colorScheme.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                if (latestLocation == null)
                  const Align(
                    alignment: Alignment.center,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No truck location recorded yet.'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (latestLocation != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(
              '${latestLocation.latitude.toStringAsFixed(6)}, '
              '${latestLocation.longitude.toStringAsFixed(6)}',
            ),
            subtitle: Text(
              _locationTime == null
                  ? 'Latest recorded location'
                  : 'Recorded ${_locationTime!.toLocal()}',
            ),
          ),
      ],
    );
  }

  Widget _buildSignatures(BuildContext context) {
    final signedOrders = _allOrders
        .where(
          (order) =>
              order.status == OrderStatus.delivered &&
              order.signatureUrl != null,
        )
        .toList();
    return _refreshable(
      onRefresh: _refresh,
      children: [
        if (_error != null) _errorCard(context),
        Text(
          'Signatures saved from the Signature tab '
          '(${_savedSignatures.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_savedSignatures.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No standalone signatures have been saved.'),
          ),
        for (final signature in _savedSignatures)
          Card(
            child: ListTile(
              leading: const Icon(Icons.draw_outlined),
              title: Text('Signature by ${signature.signedBy}'),
              subtitle: Text('Saved ${signature.savedAt.toLocal()}'),
              trailing: const Icon(Icons.visibility_outlined),
              onTap: () => _showSavedSignature(signature),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Signed deliveries (${signedOrders.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (signedOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No delivery signatures have been saved.'),
          ),
        for (final order in signedOrders)
          Card(
            child: ListTile(
              leading: const Icon(Icons.draw_outlined),
              title: Text(order.customerName),
              subtitle: Text(
                '${order.orderNumber} · '
                'Signed by ${order.recipientName ?? 'recipient'}',
              ),
              trailing: const Icon(Icons.visibility_outlined),
              onTap: () => _showSignature(order),
            ),
          ),
      ],
    );
  }

  Widget _errorCard(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
  );

  Widget _refreshable({
    required Future<void> Function() onRefresh,
    required List<Widget> children,
  }) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: children,
    ),
  );
}

class _AssignTaskDialog extends StatefulWidget {
  const _AssignTaskDialog({required this.driverName});

  final String driverName;

  @override
  State<_AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<_AssignTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _addressController = TextEditingController();
  @override
  void dispose() {
    _customerController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _assign() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      _customerController.text.trim(),
      _addressController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Assign delivery to driver'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Assigned driver: ${widget.driverName}'),
          TextFormField(
            controller: _customerController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Customer name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a customer name.'
                : null,
          ),
          TextFormField(
            controller: _addressController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Delivery address'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a delivery address.'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _assign, child: const Text('Assign task')),
    ],
  );
}
