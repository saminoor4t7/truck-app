import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../src/features/dashboard/presentation/admin_dashboard_page.dart';

class AppDrawerController extends InheritedWidget {
  const AppDrawerController({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static void open(BuildContext context) {
    final controller = context
        .dependOnInheritedWidgetOfExactType<AppDrawerController>();
    if (controller == null) {
      throw StateError('App drawer controller is not available.');
    }
    controller.openDrawer();
  }

  @override
  bool updateShouldNotify(AppDrawerController oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}

class AppDrawerMenuButton extends StatelessWidget {
  const AppDrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Open navigation drawer',
    onPressed: () => AppDrawerController.open(context),
    icon: const Icon(Icons.menu),
  );
}

class DriverAppDrawer extends StatefulWidget {
  const DriverAppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<DriverAppDrawer> createState() => DriverAppDrawerState();
}

class DriverAppDrawerState extends State<DriverAppDrawer> {
  static const _namePreferenceKey = 'driver_profile_name';
  static const _phonePreferenceKey = 'driver_profile_phone';
  static const _vehiclePreferenceKey = 'driver_profile_vehicle';
  static const _profileImagePreferenceKey = 'driver_profile_image_path';

  String _name = 'Driver';
  String _phone = '';
  String _vehicle = '';
  String? _profileImagePath;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    refreshProfile();
  }

  Future<void> refreshProfile() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _name = preferences.getString(_namePreferenceKey) ?? 'Driver';
        _phone = preferences.getString(_phonePreferenceKey) ?? '';
        _vehicle = preferences.getString(_vehiclePreferenceKey) ?? '';
        _profileImagePath = preferences.getString(_profileImagePreferenceKey);
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _profileError = 'Could not load driver profile: $error');
    }
  }

  static const _destinations = [
    (label: 'Home', icon: Icons.home_outlined),
    (label: 'Scan', icon: Icons.qr_code_scanner),
    (label: 'Tracking', icon: Icons.local_shipping_outlined),
    (label: 'Signature', icon: Icons.draw_outlined),
    (label: 'Dashboard', icon: Icons.dashboard_outlined),
    (label: 'Admin Dashboard', icon: Icons.admin_panel_settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final displayName = _name.isEmpty ? 'Driver' : _name;
    final details = [
      if (_phone.isNotEmpty) _phone,
      if (_vehicle.isNotEmpty) 'Vehicle: $_vehicle',
      ?_profileError,
    ].join('\n');

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: DriverProfileAvatar(
                name: displayName,
                imagePath: _profileImagePath,
                radius: 32,
              ),
              accountName: Text(displayName),
              accountEmail: Text(details.isEmpty ? 'Driver' : details),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];
                  return ListTile(
                    leading: Icon(destination.icon),
                    title: Text(destination.label),
                    selected: widget.selectedIndex == index,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (index == _destinations.length - 1) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminDashboardPage(),
                          ),
                        );
                      } else {
                        widget.onDestinationSelected(index);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverProfileAvatar extends StatelessWidget {
  const DriverProfileAvatar({
    super.key,
    required this.name,
    required this.imagePath,
    required this.radius,
  });

  final String name;
  final String? imagePath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = Text(
      name.isEmpty ? 'D' : name.characters.first.toUpperCase(),
      style: Theme.of(context).textTheme.titleLarge,
    );
    final image = imagePath;
    if (image == null || image.isEmpty) {
      return CircleAvatar(radius: radius, child: initials);
    }

    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: SizedBox.square(
          dimension: radius * 2,
          child: Image.file(
            File(image),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Center(child: initials),
          ),
        ),
      ),
    );
  }
}
