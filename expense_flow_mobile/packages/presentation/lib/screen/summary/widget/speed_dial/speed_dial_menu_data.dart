import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'speed_dial_menu_data.freezed.dart';

@freezed
class SpeedDialMenuData with _$SpeedDialMenuData {
  const factory SpeedDialMenuData({
    required String label,
    required String svgPath,
    required VoidCallback onPressed,
  }) = _SpeedDialMenuData;
}
