abstract class BaseUseCase<Input, Output> {
  Future<Output> call(Input input);
}

class NoParams {
  const NoParams();
}
