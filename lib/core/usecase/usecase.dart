abstract class UseCase<Result, Params> {
  const UseCase();

  Result call(Params params);
}

class NoParams {
  const NoParams();
}
