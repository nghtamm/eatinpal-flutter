import 'package:freezed_annotation/freezed_annotation.dart';

part 'tokens_model.freezed.dart';
part 'tokens_model.g.dart';

@freezed
abstract class TokensModel with _$TokensModel {
  const factory TokensModel({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _TokensModel;

  factory TokensModel.fromJson(Map<String, dynamic> json) =>
      _$TokensModelFromJson(json);
}
