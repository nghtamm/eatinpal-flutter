import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:eatinpal/modules/auth/domain/entities/credentials_entity.dart';

part 'credentials_model.freezed.dart';
part 'credentials_model.g.dart';

@freezed
abstract class CredentialsModel
    with _$CredentialsModel
    implements CredentialsEntity {
  const factory CredentialsModel({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _CredentialsModel;

  factory CredentialsModel.fromJson(Map<String, dynamic> json) =>
      _$CredentialsModelFromJson(json);
}
