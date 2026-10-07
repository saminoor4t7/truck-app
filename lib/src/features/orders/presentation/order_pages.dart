import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../shared/widgets/app_drawer.dart';
import '../../pod_signature/presentation/signature_pad.dart';
import '../../scanner/presentation/scanner_view.dart';
import '../domain/entities/order.dart';
import 'bloc/order_bloc.dart';

class DriverOrdersPage extends StatefulWidget {
  const DriverOrdersPage({super.key});
  @override
  State<DriverOrdersPage> createState() => _DriverOrdersPageState();
}

class _DriverOrdersPageState extends State<DriverOrdersPage> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderBloc>().add(const OrdersStarted());
    });
  }

  bool _matches(Order order) => switch (_filter) {
    'To load' =>
      order.status == OrderStatus.assigned ||
          order.status == OrderStatus.pending,
    'In route' => order.status == OrderStatus.inTransit,
    'Completed' =>
      order.status == OrderStatus.delivered ||
          order.status == OrderStatus.failed,
    _ => true,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppDrawerMenuButton(),
      title: const Text("Today's deliveries"),
    ),
    body: BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state.status == OrdersStatus.loading && state.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == OrdersStatus.failure && state.orders.isEmpty) {
          return _FailureView(
            message: state.failure?.message ?? 'Could not load the route.',
          );
        }
        final today = state.orders
            .where(
              (order) =>
                  order.scheduledAt == null ||
                  DateUtils.isSameDay(order.scheduledAt, DateTime.now()),
            )
            .toList();
        final visible = today.where(_matches).toList();
        final completed = today
            .where((order) => order.status == OrderStatus.delivered)
            .length;
        final inRoute = today
            .where((order) => order.status == OrderStatus.inTransit)
            .length;
        final toLoad = today
            .where(
              (order) =>
                  order.status == OrderStatus.assigned ||
                  order.status == OrderStatus.pending,
            )
            .length;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.route_outlined,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "TODAY'S ROUTE",
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: .82),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$completed',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 5,
                                left: 5,
                              ),
                              child: Text(
                                'of ${today.length} deliveries completed',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: .86,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: today.isEmpty ? 0 : completed / today.length,
                            backgroundColor: Colors.white.withValues(
                              alpha: .22,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF63D1C4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _RouteCount(label: 'To load', count: toLoad),
                            const SizedBox(width: 20),
                            _RouteCount(label: 'In route', count: inRoute),
                            const SizedBox(width: 20),
                            _RouteCount(label: 'Done', count: completed),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (state.failure != null)
              MaterialBanner(
                content: Text(state.failure!.message),
                actions: [
                  TextButton(
                    onPressed: () =>
                        context.read<OrderBloc>().add(const OrdersStarted()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final filter in const [
                    'All',
                    'To load',
                    'In route',
                    'Completed',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        today.isEmpty
                            ? 'No deliveries are assigned for today.'
                            : 'No deliveries match this filter.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 250),
                        );
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final order = visible[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${order.orderNumber}\n${order.deliveryAddress}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              isThreeLine: true,
                              trailing: Icon(
                                _statusIcon(order.status),
                                color: _statusColor(context, order.status),
                                size: 22,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<OrderBloc>(),
                                    child: OrderDetailPage(order: order),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _RouteCount extends StatelessWidget {
  const _RouteCount({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$count',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white70),
      ),
    ],
  );
}

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.order});
  final Order order;

  Future<String?> _scan(BuildContext context) =>
      Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => ScannerView(
            onCode: (Barcode barcode) {
              final value = barcode.rawValue;
              if (value != null) Navigator.of(context).pop(value);
            },
          ),
        ),
      );

  Future<void> _scanAndPickup(BuildContext context) async {
    final code = await _scan(context);
    if (!context.mounted || code == null) return;
    if (code.trim() != order.orderNumber && code.trim() != order.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scanned code does not match this delivery.'),
        ),
      );
      return;
    }

    context.read<OrderBloc>().add(OrderPickupRequested(order));
  }

  Future<void> _scanAndDeliver(BuildContext context) async {
    final code = await _scan(context);
    if (!context.mounted || code == null) return;
    if (code.trim() != order.orderNumber && code.trim() != order.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scanned code does not match this delivery.'),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<OrderBloc>(),
          child: DeliveryConfirmPage(order: order),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(order.orderNumber)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(order.deliveryAddress),
                if (order.customerPhone != null) ...[
                  const SizedBox(height: 8),
                  Text('Phone: ${order.customerPhone}'),
                ],
                if (order.customerEmail != null)
                  Text('Email: ${order.customerEmail}'),
                if (order.scheduledAt != null)
                  Text('Scheduled: ${order.scheduledAt!.toLocal()}'),
                const SizedBox(height: 12),
                Chip(label: Text(order.status.label)),
              ],
            ),
          ),
        ),
        if (order.status == OrderStatus.assigned ||
            order.status == OrderStatus.pending)
          FilledButton.icon(
            onPressed: () => _scanAndPickup(context),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan package and load'),
          ),
        if (order.status == OrderStatus.inTransit)
          FilledButton.icon(
            onPressed: () => _scanAndDeliver(context),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan package and deliver'),
          ),
        if (order.status == OrderStatus.delivered) ...[
          const ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Delivery completed'),
          ),
          if (order.recipientName != null)
            Text('Received by ${order.recipientName}'),
          if (order.signatureUrl != null) const Text('Signature uploaded'),
          if (order.deliveryPhotoUrl != null)
            const Text('Delivery photo uploaded'),
        ],
        BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            final busy = state.busyOrderIds.contains(order.id);
            return Column(
              children: [
                if (busy) const LinearProgressIndicator(),
                if (state.failure != null)
                  Text(
                    state.failure!.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (state.actionMessage != null) Text(state.actionMessage!),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class DeliveryConfirmPage extends StatefulWidget {
  const DeliveryConfirmPage({super.key, required this.order});
  final Order order;
  @override
  State<DeliveryConfirmPage> createState() => _DeliveryConfirmPageState();
}

class _DeliveryConfirmPageState extends State<DeliveryConfirmPage> {
  final _recipient = TextEditingController();
  final _picker = ImagePicker();
  List<int>? _signature;
  List<int>? _photo;
  bool _busy = false;

  Widget _proofRequirement({
    required IconData icon,
    required String label,
    required bool complete,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(
          complete ? Icons.check_circle : icon,
          color: complete
              ? const Color(0xFF208567)
              : Theme.of(context).colorScheme.outline,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          complete ? 'Added' : 'Required',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: complete
                ? const Color(0xFF208567)
                : Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _recipient.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) setState(() => _photo = bytes);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not take photo: $error')));
      }
    }
  }

  Future<void> _confirm() async {
    if (_signature == null ||
        _photo == null ||
        _recipient.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add the recipient name, signature, and delivery photo.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    context.read<OrderBloc>().add(
      OrderDeliveryRequested(
        order: widget.order,
        signaturePng: _signature!,
        photoBytes: _photo!,
        recipientName: _recipient.text,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Confirm delivery')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.order.customerName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery proof',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete all three items before marking this delivery done.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                _proofRequirement(
                  icon: Icons.person_outline,
                  label: 'Recipient name',
                  complete: _recipient.text.trim().isNotEmpty,
                ),
                _proofRequirement(
                  icon: Icons.draw_outlined,
                  label: 'Customer signature',
                  complete: _signature != null,
                ),
                _proofRequirement(
                  icon: Icons.camera_alt_outlined,
                  label: 'Delivery photo',
                  complete: _photo != null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _recipient,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Received by *',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Customer signature *',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SignaturePad(
          onSaved: (base64) =>
              setState(() => _signature = base64Decode(base64)),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _takePhoto,
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(
            _photo == null ? 'Take delivery photo *' : 'Retake delivery photo',
          ),
        ),
        if (_photo != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              Uint8List.fromList(_photo!),
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _confirm,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark delivered'),
        ),
      ],
    ),
  );
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                context.read<OrderBloc>().add(const OrdersStarted()),
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

IconData _statusIcon(OrderStatus status) => switch (status) {
  OrderStatus.pending => Icons.pending_actions,
  OrderStatus.assigned => Icons.inventory_2_outlined,
  OrderStatus.inTransit => Icons.local_shipping_outlined,
  OrderStatus.delivered => Icons.check_circle_outline,
  OrderStatus.failed => Icons.error_outline,
};

Color _statusColor(BuildContext context, OrderStatus status) =>
    switch (status) {
      OrderStatus.pending ||
      OrderStatus.assigned => Theme.of(context).colorScheme.tertiary,
      OrderStatus.inTransit => Theme.of(context).colorScheme.primary,
      OrderStatus.delivered => const Color(0xFF208567),
      OrderStatus.failed => Theme.of(context).colorScheme.error,
    };
