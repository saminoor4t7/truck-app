import 'dart:io';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

import 'failure.dart';

class ErrorMapper {
  const ErrorMapper();

  Failure map(Object error, StackTrace stackTrace) {
    if (error is SocketException || error is HttpException) {
      return NetworkFailure(
        'Network unavailable.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is PlatformException) {
      return HardwareFailure(
        error.message ?? 'Device service failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return ServerFailure(
      error.toString().isEmpty
          ? 'The operation could not be completed.'
          : error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

extension GuardFuture on Object {
  Future<Either<Failure, T>> guard<T>(
    Future<T> Function() action, {
    ErrorMapper mapper = const ErrorMapper(),
  }) async {
    try {
      return Right<Failure, T>(await action());
    } catch (error, stackTrace) {
      return Left<Failure, T>(mapper.map(error, stackTrace));
    }
  }
}
