import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_app/src/features/orders/data/repositories/local_order_repository.dart';
import 'package:truck_app/src/features/orders/domain/entities/order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'admin-created task is included in driver orders and stream updates',
    () async {
      final repository = LocalOrderRepository();
      await repository.allOrders();

      final nextDriverOrders = repository
          .watchAssigned()
          .skip(1)
          .map((result) => result.match((_) => <Order>[], (orders) => orders))
          .first;

      final task = await repository.createTask(
        customerName: 'New customer',
        deliveryAddress: '12 Driver Street',
      );
      final updatedOrders = await nextDriverOrders;

      expect(task.status, OrderStatus.assigned);
      expect(task.customerName, 'New customer');
      expect(task.deliveryAddress, '12 Driver Street');
      expect(updatedOrders.first.id, task.id);
      expect((await repository.allOrders()).first.id, task.id);
    },
  );
}
