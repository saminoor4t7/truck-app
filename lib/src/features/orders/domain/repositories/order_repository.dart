import 'package:fpdart/fpdart.dart' hide Order;

import '../../../../../core/error/failure.dart';
import '../entities/order.dart';

abstract interface class OrderRepository {
  Stream<Either<Failure, List<Order>>> watchAssigned();
  Future<Either<Failure, Unit>> markPickedUp({
    required Order order,
  });
  Future<Either<Failure, Unit>> markInTransit({
    required Order order,
  });
  Future<Either<Failure, Unit>> markDelivered({
    required Order order,
    required List<int> signaturePng,
    required List<int> photoBytes,
    required String recipientName,
  });
}
