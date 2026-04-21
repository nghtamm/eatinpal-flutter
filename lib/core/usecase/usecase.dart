import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';

abstract class UseCase<T, Params> {
  Future<Either<AppException, T>> call(Params params);
}

abstract class UseCaseNoParams<T> {
  Future<Either<AppException, T>> call();
}

class NoParams {
  const NoParams();
}
