import '../error/failure.dart';

abstract class UseCase<Success, Params> {
  const UseCase();

  ResultFuture<Success> call(Params params);
}

class NoParams {
  const NoParams();
}
