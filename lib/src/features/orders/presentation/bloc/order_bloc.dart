import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide Order;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../core/error/failure.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

part 'order_bloc.freezed.dart';

enum OrdersStatus { initial, loading, loaded, failure }

@freezed
abstract class OrderState with _$OrderState {
  const OrderState._();

  const factory OrderState({
    @Default(OrdersStatus.initial) OrdersStatus status,
    @Default(<Order>[]) List<Order> orders,
    Failure? failure,
    String? actionMessage,
    @Default(<String>{}) Set<String> busyOrderIds,
  }) = _OrderState;
}

sealed class OrderEvent {
  const OrderEvent();
}

final class OrdersStarted extends OrderEvent {
  const OrdersStarted();
}

final class OrdersSnapshotReceived extends OrderEvent {
  const OrdersSnapshotReceived(this.result);
  final Either<Failure, List<Order>> result;
}

final class OrderPickupRequested extends OrderEvent {
  const OrderPickupRequested(this.order);
  final Order order;
}

final class OrderDeliveryRequested extends OrderEvent {
  const OrderDeliveryRequested({
    required this.order,
    required this.signaturePng,
    required this.photoBytes,
    required this.recipientName,
  });
  final Order order;
  final List<int> signaturePng;
  final List<int> photoBytes;
  final String recipientName;
}

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc(this._repository) : super(const OrderState()) {
    on<OrdersStarted>(_onStarted);
    on<OrdersSnapshotReceived>(_onSnapshot);
    on<OrderPickupRequested>(_onPickup);
    on<OrderDeliveryRequested>(_onDelivery);
  }

  final OrderRepository _repository;
  StreamSubscription<Either<Failure, List<Order>>>? _subscription;

  Future<void> _onStarted(OrdersStarted event, Emitter<OrderState> emit) async {
    emit(state.copyWith(status: OrdersStatus.loading, failure: null));
    await _subscription?.cancel();
    _subscription = _repository.watchAssigned().listen(
      (result) => add(OrdersSnapshotReceived(result)),
      onError: (Object error) => add(
        OrdersSnapshotReceived(
          Left<Failure, List<Order>>(
            ServerFailure('Unable to watch deliveries: $error'),
          ),
        ),
      ),
    );
  }

  void _onSnapshot(OrdersSnapshotReceived event, Emitter<OrderState> emit) {
    event.result.match(
      (failure) =>
          emit(state.copyWith(status: OrdersStatus.failure, failure: failure)),
      (orders) => emit(
        state.copyWith(
          status: OrdersStatus.loaded,
          orders: orders,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onPickup(
    OrderPickupRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(
      state.copyWith(
        busyOrderIds: {...state.busyOrderIds, event.order.id},
        failure: null,
      ),
    );
    final result = await _repository.markPickedUp(order: event.order);
    result.match(
      (failure) => emit(
        state.copyWith(
          failure: failure,
          busyOrderIds: {...state.busyOrderIds}..remove(event.order.id),
        ),
      ),
      (_) {
        final pickedUpOrder = event.order.copyWith(
          status: OrderStatus.inTransit,
          pickedUpAt: DateTime.now(),
        );
        final orders = [
          for (final order in state.orders)
            if (order.id == event.order.id) pickedUpOrder else order,
        ];
        emit(
          state.copyWith(
            orders: orders,
            actionMessage: '${event.order.orderNumber} is on route.',
            busyOrderIds: {...state.busyOrderIds}..remove(event.order.id),
          ),
        );
      },
    );
  }

  Future<void> _onDelivery(
    OrderDeliveryRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(
      state.copyWith(
        busyOrderIds: {...state.busyOrderIds, event.order.id},
        failure: null,
      ),
    );
    final result = await _repository.markDelivered(
      order: event.order,
      signaturePng: event.signaturePng,
      photoBytes: event.photoBytes,
      recipientName: event.recipientName,
    );
    result.match(
      (failure) => emit(
        state.copyWith(
          failure: failure,
          busyOrderIds: {...state.busyOrderIds}..remove(event.order.id),
        ),
      ),
      (_) => emit(
        state.copyWith(
          actionMessage:
              '${event.order.orderNumber} marked delivered. Evidence is stored on this device.',
          busyOrderIds: {...state.busyOrderIds}..remove(event.order.id),
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
