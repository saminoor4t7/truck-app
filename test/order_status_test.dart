import 'package:flutter_test/flutter_test.dart';
import 'package:truck_app/src/features/orders/domain/entities/order.dart';

void main() {
  group('OrderStatusX', () {
    test('maps stored values to domain statuses', () {
      expect(OrderStatusX.parse('assigned'), OrderStatus.assigned);
      expect(OrderStatusX.parse('in_transit'), OrderStatus.inTransit);
      expect(OrderStatusX.parse('delivered'), OrderStatus.delivered);
      expect(OrderStatusX.parse('failed'), OrderStatus.failed);
    });

    test('uses pending for absent or unknown statuses', () {
      expect(OrderStatusX.parse(null), OrderStatus.pending);
      expect(OrderStatusX.parse('future_value'), OrderStatus.pending);
    });

    test('serializes statuses to their stored values', () {
      expect(OrderStatus.inTransit.value, 'in_transit');
      expect(OrderStatus.delivered.value, 'delivered');
    });
  });
}
