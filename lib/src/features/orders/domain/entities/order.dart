enum OrderStatus { pending, assigned, inTransit, delivered, failed }

extension OrderStatusX on OrderStatus {
  String get value => switch (this) {
    OrderStatus.pending => 'pending',
    OrderStatus.assigned => 'assigned',
    OrderStatus.inTransit => 'in_transit',
    OrderStatus.delivered => 'delivered',
    OrderStatus.failed => 'failed',
  };

  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.assigned => 'Assigned',
    OrderStatus.inTransit => 'In transit',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.failed => 'Failed',
  };

  static OrderStatus parse(Object? value) => switch (value) {
    'assigned' => OrderStatus.assigned,
    'in_transit' => OrderStatus.inTransit,
    'delivered' => OrderStatus.delivered,
    'failed' => OrderStatus.failed,
    _ => OrderStatus.pending,
  };
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.deliveryAddress,
    required this.status,
    required this.assignedDriverId,
    this.customerPhone,
    this.customerEmail,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
    this.scheduledAt,
    this.deliveredAt,
    this.pickedUpAt,
    this.signatureUrl,
    this.deliveryPhotoUrl,
    this.recipientName,
    this.weight,
    this.price,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final String deliveryAddress;
  final OrderStatus status;
  final String assignedDriverId;
  final String? customerPhone;
  final String? customerEmail;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final DateTime? scheduledAt;
  final DateTime? deliveredAt;
  final DateTime? pickedUpAt;
  final String? signatureUrl;
  final String? deliveryPhotoUrl;
  final String? recipientName;
  final double? weight;
  final double? price;

  Order copyWith({OrderStatus? status, DateTime? pickedUpAt}) => Order(
    id: id,
    orderNumber: orderNumber,
    customerName: customerName,
    deliveryAddress: deliveryAddress,
    status: status ?? this.status,
    assignedDriverId: assignedDriverId,
    customerPhone: customerPhone,
    customerEmail: customerEmail,
    pickupAddress: pickupAddress,
    pickupLat: pickupLat,
    pickupLng: pickupLng,
    deliveryLat: deliveryLat,
    deliveryLng: deliveryLng,
    scheduledAt: scheduledAt,
    deliveredAt: deliveredAt,
    pickedUpAt: pickedUpAt ?? this.pickedUpAt,
    signatureUrl: signatureUrl,
    deliveryPhotoUrl: deliveryPhotoUrl,
    recipientName: recipientName,
    weight: weight,
    price: price,
  );
}
