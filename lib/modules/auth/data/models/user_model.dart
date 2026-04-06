import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:eatinpal/modules/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel implements UserEntity {
  const factory UserModel({
    required String id,
    required String email,
    required String name,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
