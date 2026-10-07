// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderState {

 OrdersStatus get status; List<Order> get orders; Failure? get failure; String? get actionMessage; Set<String> get busyOrderIds;
/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStateCopyWith<OrderState> get copyWith => _$OrderStateCopyWithImpl<OrderState>(this as OrderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.orders, orders)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.actionMessage, actionMessage) || other.actionMessage == actionMessage)&&const DeepCollectionEquality().equals(other.busyOrderIds, busyOrderIds));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(orders),failure,actionMessage,const DeepCollectionEquality().hash(busyOrderIds));

@override
String toString() {
  return 'OrderState(status: $status, orders: $orders, failure: $failure, actionMessage: $actionMessage, busyOrderIds: $busyOrderIds)';
}


}

/// @nodoc
abstract mixin class $OrderStateCopyWith<$Res>  {
  factory $OrderStateCopyWith(OrderState value, $Res Function(OrderState) _then) = _$OrderStateCopyWithImpl;
@useResult
$Res call({
 OrdersStatus status, List<Order> orders, Failure? failure, String? actionMessage, Set<String> busyOrderIds
});




}
/// @nodoc
class _$OrderStateCopyWithImpl<$Res>
    implements $OrderStateCopyWith<$Res> {
  _$OrderStateCopyWithImpl(this._self, this._then);

  final OrderState _self;
  final $Res Function(OrderState) _then;

/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? orders = null,Object? failure = freezed,Object? actionMessage = freezed,Object? busyOrderIds = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrdersStatus,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<Order>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,actionMessage: freezed == actionMessage ? _self.actionMessage : actionMessage // ignore: cast_nullable_to_non_nullable
as String?,busyOrderIds: null == busyOrderIds ? _self.busyOrderIds : busyOrderIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderState].
extension OrderStatePatterns on OrderState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderState value)  $default,){
final _that = this;
switch (_that) {
case _OrderState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderState value)?  $default,){
final _that = this;
switch (_that) {
case _OrderState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrdersStatus status,  List<Order> orders,  Failure? failure,  String? actionMessage,  Set<String> busyOrderIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderState() when $default != null:
return $default(_that.status,_that.orders,_that.failure,_that.actionMessage,_that.busyOrderIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrdersStatus status,  List<Order> orders,  Failure? failure,  String? actionMessage,  Set<String> busyOrderIds)  $default,) {final _that = this;
switch (_that) {
case _OrderState():
return $default(_that.status,_that.orders,_that.failure,_that.actionMessage,_that.busyOrderIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrdersStatus status,  List<Order> orders,  Failure? failure,  String? actionMessage,  Set<String> busyOrderIds)?  $default,) {final _that = this;
switch (_that) {
case _OrderState() when $default != null:
return $default(_that.status,_that.orders,_that.failure,_that.actionMessage,_that.busyOrderIds);case _:
  return null;

}
}

}

/// @nodoc


class _OrderState extends OrderState {
  const _OrderState({this.status = OrdersStatus.initial, final  List<Order> orders = const <Order>[], this.failure, this.actionMessage, final  Set<String> busyOrderIds = const <String>{}}): _orders = orders,_busyOrderIds = busyOrderIds,super._();
  

@override@JsonKey() final  OrdersStatus status;
 final  List<Order> _orders;
@override@JsonKey() List<Order> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}

@override final  Failure? failure;
@override final  String? actionMessage;
 final  Set<String> _busyOrderIds;
@override@JsonKey() Set<String> get busyOrderIds {
  if (_busyOrderIds is EqualUnmodifiableSetView) return _busyOrderIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_busyOrderIds);
}


/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderStateCopyWith<_OrderState> get copyWith => __$OrderStateCopyWithImpl<_OrderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._orders, _orders)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.actionMessage, actionMessage) || other.actionMessage == actionMessage)&&const DeepCollectionEquality().equals(other._busyOrderIds, _busyOrderIds));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_orders),failure,actionMessage,const DeepCollectionEquality().hash(_busyOrderIds));

@override
String toString() {
  return 'OrderState(status: $status, orders: $orders, failure: $failure, actionMessage: $actionMessage, busyOrderIds: $busyOrderIds)';
}


}

/// @nodoc
abstract mixin class _$OrderStateCopyWith<$Res> implements $OrderStateCopyWith<$Res> {
  factory _$OrderStateCopyWith(_OrderState value, $Res Function(_OrderState) _then) = __$OrderStateCopyWithImpl;
@override @useResult
$Res call({
 OrdersStatus status, List<Order> orders, Failure? failure, String? actionMessage, Set<String> busyOrderIds
});




}
/// @nodoc
class __$OrderStateCopyWithImpl<$Res>
    implements _$OrderStateCopyWith<$Res> {
  __$OrderStateCopyWithImpl(this._self, this._then);

  final _OrderState _self;
  final $Res Function(_OrderState) _then;

/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? orders = null,Object? failure = freezed,Object? actionMessage = freezed,Object? busyOrderIds = null,}) {
  return _then(_OrderState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrdersStatus,orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<Order>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,actionMessage: freezed == actionMessage ? _self.actionMessage : actionMessage // ignore: cast_nullable_to_non_nullable
as String?,busyOrderIds: null == busyOrderIds ? _self._busyOrderIds : busyOrderIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
