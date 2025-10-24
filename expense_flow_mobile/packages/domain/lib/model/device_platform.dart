import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum(valueField: 'value')
enum DevicePlatform {
  ios('ios'),
  android('android');

  const DevicePlatform(this.value);

  final String value;
}
