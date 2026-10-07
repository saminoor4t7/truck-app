import 'package:get_it/get_it.dart';

import '../../src/features/orders/data/repositories/local_order_repository.dart';
import '../../src/features/orders/domain/repositories/order_repository.dart';
import '../../src/features/orders/presentation/bloc/order_bloc.dart';

final getIt = GetIt.instance;

class Injection {
  const Injection._();

  static Future<void> configureDependencies() async {
    if (getIt.isRegistered<OrderRepository>()) return;

    final localOrderRepository = LocalOrderRepository();
    getIt.registerSingleton<LocalOrderRepository>(localOrderRepository);
    getIt.registerSingleton<OrderRepository>(localOrderRepository);
    getIt.registerFactory<OrderBloc>(() => OrderBloc(getIt<OrderRepository>()));
  }
}
