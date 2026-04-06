import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:eatinpal/modules/auth/data/models/user_model.dart';

part 'auth_token_model.freezed.dart';
part 'auth_token_model.g.dart';

@freezed
abstract class AuthTokenModel with _$AuthTokenModel {
  const factory AuthTokenModel({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) = _AuthTokenModel;

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenModelFromJson(json);
}
