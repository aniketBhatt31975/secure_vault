import '../errors/failures.dart';

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
