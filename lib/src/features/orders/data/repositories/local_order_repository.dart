import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart' hide Order;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/error/failure.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

/// Keeps deliveries and proof-of-delivery files on this device only.
class LocalOrderRepository implements OrderRepository {
  static const _uuid = Uuid();
  static const _localUserId = 'local-driver';
  final Map<String, List<Order>> _cache = {};
  final Map<String, StreamController<Either<Failure, List<Order>>>> _streams =
      {};

  @override
  Stream<Either<Failure, List<Order>>> watchAssigned() async* {
    final orders = await _load(_localUserId);
    yield Right<Failure, List<Order>>(List.unmodifiable(orders));
    yield* _streams
        .putIfAbsent(
          _localUserId,
          () => StreamController<Either<Failure, List<Order>>>.broadcast(),
        )
        .stream;
  }

  Future<List<Order>> allOrders() async =>
      List.unmodifiable(await _load(_localUserId));

  Future<Order> createTask({
    required String customerName,
    required String deliveryAddress,
  }) async {
    final orders = List<Order>.of(await _load(_localUserId));
    final now = DateTime.now();
    final id = _uuid.v4();
    final task = Order(
      id: id,
      orderNumber:
          'LOCAL-${now.millisecondsSinceEpoch}-${id.substring(0, 6).toUpperCase()}',
      customerName: customerName.trim(),
      deliveryAddress: deliveryAddress.trim(),
      status: OrderStatus.assigned,
      assignedDriverId: _localUserId,
      scheduledAt: now,
    );
    orders.insert(0, task);
    await _persist(_localUserId, orders);
    return task;
  }

  Future<List<Order>> _load(String userId) async {
    final cached = _cache[userId];
    if (cached != null) return cached;
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('local_orders_v1_$userId');
    if (encoded != null) {
      final decoded = jsonDecode(encoded);
      if (decoded is List) {
        final orders = decoded
            .whereType<Map>()
            .map((row) => _fromJson(Map<String, dynamic>.from(row)))
            .toList();
        _cache[userId] = orders;
        return orders;
      }
    }

    final today = DateTime.now();
    final sample = List<Order>.generate(15, (index) {
      final stop = index + 1;
      return Order(
        id: _uuid.v4(),
        orderNumber: 'LOCAL-${today.year}${today.month.toString().padLeft(2, '0')}-${stop.toString().padLeft(3, '0')}',
        customerName: 'Customer $stop',
        deliveryAddress: 'Delivery stop $stop',
        status: OrderStatus.assigned,
        assignedDriverId: _localUserId,
        scheduledAt: DateTime(today.year, today.month, today.day, 9 + index ~/ 2),
      );
    });
    _cache[userId] = sample;
    await _persist(userId, sample);
    return sample;
  }

  Order _fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String,
    customerName: json['customerName'] as String,
    deliveryAddress: json['deliveryAddress'] as String,
    status: OrderStatusX.parse(json['status']),
    assignedDriverId: json['assignedDriverId'] as String,
    scheduledAt: _date(json['scheduledAt']),
    deliveredAt: _date(json['deliveredAt']),
    pickedUpAt: _date(json['pickedUpAt']),
    signatureUrl: json['signatureUrl'] as String?,
    deliveryPhotoUrl: json['deliveryPhotoUrl'] as String?,
    recipientName: json['recipientName'] as String?,
    customerPhone: json['customerPhone'] as String?,
    customerEmail: json['customerEmail'] as String?,
    pickupAddress: json['pickupAddress'] as String?,
    pickupLat: (json['pickupLat'] as num?)?.toDouble(),
    pickupLng: (json['pickupLng'] as num?)?.toDouble(),
    deliveryLat: (json['deliveryLat'] as num?)?.toDouble(),
    deliveryLng: (json['deliveryLng'] as num?)?.toDouble(),
    weight: (json['weight'] as num?)?.toDouble(),
    price: (json['price'] as num?)?.toDouble(),
  );

  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  Map<String, Object?> _toJson(Order order) => <String, Object?>{
    'id': order.id,
    'orderNumber': order.orderNumber,
    'customerName': order.customerName,
    'deliveryAddress': order.deliveryAddress,
    'status': order.status.value,
    'assignedDriverId': order.assignedDriverId,
    'scheduledAt': order.scheduledAt?.toIso8601String(),
    'deliveredAt': order.deliveredAt?.toIso8601String(),
    'pickedUpAt': order.pickedUpAt?.toIso8601String(),
    'signatureUrl': order.signatureUrl,
    'deliveryPhotoUrl': order.deliveryPhotoUrl,
    'recipientName': order.recipientName,
    'customerPhone': order.customerPhone,
    'customerEmail': order.customerEmail,
    'pickupAddress': order.pickupAddress,
    'pickupLat': order.pickupLat,
    'pickupLng': order.pickupLng,
    'deliveryLat': order.deliveryLat,
    'deliveryLng': order.deliveryLng,
    'weight': order.weight,
    'price': order.price,
  };

  Future<void> _persist(String userId, List<Order> orders) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'local_orders_v1_$userId',
      jsonEncode(orders.map(_toJson).toList()),
    );
    _cache[userId] = orders;
    _streams[userId]?.add(Right<Failure, List<Order>>(List.unmodifiable(orders)));
  }

  Order _copy(
    Order order, {
    OrderStatus? status,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? signatureUrl,
    String? deliveryPhotoUrl,
    String? recipientName,
  }) => Order(
    id: order.id,
    orderNumber: order.orderNumber,
    customerName: order.customerName,
    deliveryAddress: order.deliveryAddress,
    status: status ?? order.status,
    assignedDriverId: order.assignedDriverId,
    customerPhone: order.customerPhone,
    customerEmail: order.customerEmail,
    pickupAddress: order.pickupAddress,
    pickupLat: order.pickupLat,
    pickupLng: order.pickupLng,
    deliveryLat: order.deliveryLat,
    deliveryLng: order.deliveryLng,
    scheduledAt: order.scheduledAt,
    deliveredAt: deliveredAt ?? order.deliveredAt,
    pickedUpAt: pickedUpAt ?? order.pickedUpAt,
    signatureUrl: signatureUrl ?? order.signatureUrl,
    deliveryPhotoUrl: deliveryPhotoUrl ?? order.deliveryPhotoUrl,
    recipientName: recipientName ?? order.recipientName,
    weight: order.weight,
    price: order.price,
  );

  Future<void> _saveOrder(String userId, Order updated) async {
    final orders = await _load(userId);
    final index = orders.indexWhere((order) => order.id == updated.id);
    if (index < 0) throw StateError('Delivery ${updated.id} was not found.');
    orders[index] = updated;
    await _persist(userId, orders);
  }

  @override
  Future<Either<Failure, Unit>> markPickedUp({
    required Order order,
  }) => _setStatus(order, OrderStatus.inTransit, pickedUpAt: DateTime.now());

  @override
  Future<Either<Failure, Unit>> markInTransit({
    required Order order,
  }) => _setStatus(order, OrderStatus.inTransit);

  Future<Either<Failure, Unit>> _setStatus(
    Order order,
    OrderStatus status, {
    DateTime? pickedUpAt,
  }) async {
    try {
      await _saveOrder(
        _localUserId,
        _copy(order, status: status, pickedUpAt: pickedUpAt),
      );
      return const Right<Failure, Unit>(unit);
    } catch (error, stackTrace) {
      return Left<Failure, Unit>(
        ServerFailure(error.toString(), cause: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> markDelivered({
    required Order order,
    required List<int> signaturePng,
    required List<int> photoBytes,
    required String recipientName,
  }) async {
    try {
      final support = await getApplicationSupportDirectory();
      final evidenceDirectory = Directory('${support.path}/delivery_evidence');
      await evidenceDirectory.create(recursive: true);
      final id = _uuid.v4();
      final signature = File('${evidenceDirectory.path}/$id-signature.png');
      final photo = File('${evidenceDirectory.path}/$id-photo.jpg');
      await signature.writeAsBytes(signaturePng, flush: true);
      await photo.writeAsBytes(photoBytes, flush: true);
      await _saveOrder(
        _localUserId,
        _copy(
          order,
          status: OrderStatus.delivered,
          deliveredAt: DateTime.now(),
          signatureUrl: signature.path,
          deliveryPhotoUrl: photo.path,
          recipientName: recipientName.trim(),
        ),
      );
      return const Right<Failure, Unit>(unit);
    } catch (error, stackTrace) {
      return Left<Failure, Unit>(
        ServerFailure(error.toString(), cause: error, stackTrace: stackTrace),
      );
    }
  }
}
