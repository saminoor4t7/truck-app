import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/injection.dart';
import 'shared/widgets/app_drawer.dart';
import 'src/features/dashboard/presentation/admin_dashboard_page.dart';
import 'src/features/dashboard/presentation/dashboard_view.dart';
import 'src/features/orders/presentation/bloc/order_bloc.dart';
import 'src/features/orders/presentation/order_pages.dart';
import 'src/features/pod_signature/presentation/signature_capture_view.dart';
import 'src/features/scanner/presentation/scanner_view.dart';
import 'src/features/tracking/presentation/tracking_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF12345A);
    const teal = Color(0xFF168C91);
    const canvas = Color(0xFFF3F6FA);
    const ink = Color(0xFF19283B);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: navy,
          brightness: Brightness.light,
        ).copyWith(
          primary: navy,
          secondary: teal,
          tertiary: const Color(0xFFE39A39),
          surface: Colors.white,
          onSurface: ink,
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fleet Driver',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE5EAF1)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDDEFF0),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE3EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE3EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: teal, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _startupPermissionsRequestedKey =
      'startup_permissions_requested_v1';

  int _selectedIndex = 0;
  final Set<int> _visitedIndices = {0};
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _drawerKey = GlobalKey<DriverAppDrawerState>();

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
    NavigationDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: 'Tracking',
    ),
    NavigationDestination(
      icon: Icon(Icons.draw_outlined),
      selectedIcon: Icon(Icons.draw),
      label: 'Signature',
    ),
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStartupPermissions();
    });
  }

  Future<void> _requestStartupPermissions() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(_startupPermissionsRequestedKey) ?? false) {
        return;
      }

      final permissions = defaultTargetPlatform == TargetPlatform.android
          ? [
              Permission.locationWhenInUse,
              Permission.camera,
              Permission.bluetoothScan,
              Permission.bluetoothConnect,
            ]
          : [
              Permission.locationWhenInUse,
              Permission.camera,
              Permission.bluetooth,
            ];
      final deniedPermissions = <String>[];
      for (final permission in permissions) {
        final status = await permission.request();
        if (!status.isGranted) {
          deniedPermissions.add(switch (permission) {
            Permission.locationWhenInUse => 'Location',
            Permission.camera => 'Camera',
            Permission.bluetoothScan ||
            Permission.bluetoothConnect ||
            Permission.bluetooth => 'Bluetooth',
            _ => 'Required',
          });
        }
      }

      await preferences.setBool(_startupPermissionsRequestedKey, true);
      if (!mounted || deniedPermissions.isEmpty) return;

      final denied = deniedPermissions.toSet().join(', ');
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Some permissions are turned off'),
          content: Text(
            '$denied access is needed for related features. You can still use '
            'the rest of the app and change permissions in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continue'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not request app permissions: $error')),
      );
    }
  }

  Widget _pageFor(int index) => switch (index) {
    0 => BlocProvider(
      key: const ValueKey('home'),
      create: (_) => getIt<OrderBloc>(),
      child: const DriverOrdersPage(),
    ),
    1 => ScannerView(isActive: _selectedIndex == 1),
    2 => const TrackingView(),
    3 => const SignatureCaptureView(),
    4 => const DashboardView(),
    _ => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    return AppDrawerController(
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: DriverAppDrawer(
          key: _drawerKey,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (index == _destinations.length) {
              setState(() {
                _selectedIndex = 0;
                _visitedIndices.add(0);
              });
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminDashboardPage(),
                ),
              );
              return;
            }
            setState(() {
              _selectedIndex = index;
              _visitedIndices.add(index);
            });
          },
        ),
        onDrawerChanged: (isOpened) {
          if (isOpened) _drawerKey.currentState?.refreshProfile();
        },
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(
            _destinations.length,
            (index) => _visitedIndices.contains(index)
                ? _pageFor(index)
                : const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          destinations: _destinations,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              _visitedIndices.add(index);
            });
          },
        ),
      ),
    );
  }
}
