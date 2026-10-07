import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/widgets/app_drawer.dart';
import '../domain/entities/kpi_card.dart';
import '../../printing/presentation/printer_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  static const _orderPreferenceKey = 'driver_dashboard_kpi_order';
  static const _namePreferenceKey = 'driver_profile_name';
  static const _phonePreferenceKey = 'driver_profile_phone';
  static const _vehiclePreferenceKey = 'driver_profile_vehicle';
  static const _profileImagePreferenceKey = 'driver_profile_image_path';
  final ImagePicker _imagePicker = ImagePicker();
  final List<KpiCard> _cards = [
    const KpiCard(id: 'on_time', title: 'On-time', value: '96%', trend: '+4%'),
    const KpiCard(
      id: 'deliveries',
      title: 'Deliveries',
      value: '128',
      trend: '+12',
    ),
    const KpiCard(id: 'miles', title: 'Miles', value: '423', trend: '+34'),
    const KpiCard(
      id: 'pending',
      title: 'Pending stops',
      value: '7',
      trend: '-2',
    ),
  ];
  String _driverName = 'Driver';
  String _driverPhone = '';
  String _vehicle = '';
  String? _profileImagePath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restoreOrder();
  }

  Future<void> _restoreOrder() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final order = preferences.getStringList(_orderPreferenceKey);
      _driverName = preferences.getString(_namePreferenceKey) ?? 'Driver';
      _driverPhone = preferences.getString(_phonePreferenceKey) ?? '';
      _vehicle = preferences.getString(_vehiclePreferenceKey) ?? '';
      _profileImagePath = preferences.getString(_profileImagePreferenceKey);
      if (order != null) {
        final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
        _cards.sort(
          (left, right) => (rank[left.id] ?? _cards.length).compareTo(
            rank[right.id] ?? _cards.length,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) newIndex--;
      final card = _cards.removeAt(oldIndex);
      _cards.insert(newIndex, card);
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _orderPreferenceKey,
      _cards.map((card) => card.id).toList(),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (selected == null || !mounted) return;

      final supportDirectory = await getApplicationSupportDirectory();
      final extension = path.extension(selected.path);
      final imageName =
          'driver_profile_${DateTime.now().microsecondsSinceEpoch}$extension';
      final savedFile = File(path.join(supportDirectory.path, imageName));
      await savedFile.parent.create(recursive: true);
      await File(selected.path).copy(savedFile.path);

      final previousPath = _profileImagePath;
      try {
        final preferences = await SharedPreferences.getInstance();
        final saved = await preferences.setString(
          _profileImagePreferenceKey,
          savedFile.path,
        );
        if (!saved) {
          throw StateError('Could not save the profile photo location.');
        }
      } catch (_) {
        await savedFile.delete();
        rethrow;
      }
      if (mounted) setState(() => _profileImagePath = savedFile.path);

      if (previousPath != null && previousPath != savedFile.path) {
        try {
          final previousFile = File(previousPath);
          if (await previousFile.exists()) await previousFile.delete();
        } on FileSystemException catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'New profile photo saved, but the previous photo could not '
                  'be deleted: $error',
                ),
              ),
            );
          }
          return;
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile photo: $error')),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _driverName);
    final phoneController = TextEditingController(text: _driverPhone);
    final vehicleController = TextEditingController(text: _vehicle);
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Driver profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: vehicleController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Vehicle'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      try {
        final preferences = await SharedPreferences.getInstance();
        final name = nameController.text.trim();
        final phone = phoneController.text.trim();
        final vehicle = vehicleController.text.trim();
        await preferences.setString(
          _namePreferenceKey,
          name.isEmpty ? 'Driver' : name,
        );
        await preferences.setString(_phonePreferenceKey, phone);
        await preferences.setString(_vehiclePreferenceKey, vehicle);
        if (!mounted) return;
        setState(() {
          _driverName = name.isEmpty ? 'Driver' : name;
          _driverPhone = phone;
          _vehicle = vehicle;
        });
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save driver profile: $error')),
          );
        }
      }
    }
    nameController.dispose();
    phoneController.dispose();
    vehicleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        leading: const AppDrawerMenuButton(),
        title: const Text('Driver dashboard'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF12345A), Color(0xFF205B78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .65),
                            width: 2,
                          ),
                        ),
                        child: DriverProfileAvatar(
                          name: _driverName,
                          imagePath: _profileImagePath,
                          radius: 27,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DRIVER PROFILE',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _driverName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (_driverPhone.isNotEmpty || _vehicle.isNotEmpty)
                              Text(
                                [
                                  if (_driverPhone.isNotEmpty) _driverPhone,
                                  if (_vehicle.isNotEmpty) _vehicle,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Change profile photo',
                        onPressed: _pickProfileImage,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: .14),
                        ),
                        icon: const Icon(Icons.add_a_photo_outlined, size: 19),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        tooltip: 'Edit driver profile',
                        onPressed: _editProfile,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: .14),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('Receipt printer'),
                subtitle: const Text('Connect a nearby BLE printer'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PrinterView()),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Performance',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _cards.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Card(
                  key: ValueKey(card.id),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer,
                      child: Icon(_kpiIcon(card.id)),
                    ),
                    title: Text(
                      card.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(card.value),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.trend,
                          style: TextStyle(
                            color: card.trend.startsWith('-')
                                ? Theme.of(context).colorScheme.error
                                : const Color(0xFF208567),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.drag_handle,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

IconData _kpiIcon(String id) => switch (id) {
  'on_time' => Icons.schedule_outlined,
  'deliveries' => Icons.inventory_2_outlined,
  'miles' => Icons.route_outlined,
  'pending' => Icons.pending_actions_outlined,
  _ => Icons.insights_outlined,
};
