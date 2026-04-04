import 'package:fpdart/fpdart.dart';
import 'package:eatinpal/core/network/exceptions.dart';

abstract class UseCase<Type, Params> {
  Future<Either<AppException, Type>> call(Params params);
}

abstract class UseCaseNoParams<Type> {
  Future<Either<AppException, Type>> call();
}

class NoParams {
  const NoParams();
}
