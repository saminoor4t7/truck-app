sealed class Failure {
  const Failure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.cause, super.stackTrace});
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.cause, super.stackTrace});
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});
}

final class HardwareFailure extends Failure {
  const HardwareFailure(super.message, {super.cause, super.stackTrace});
}

final class LocationFailure extends Failure {
  const LocationFailure(super.message, {super.cause, super.stackTrace});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause, super.stackTrace});
}
