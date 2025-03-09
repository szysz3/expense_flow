import 'package:freezed_annotation/freezed_annotation.dart';

part 'navigation_event.freezed.dart';

@freezed
class NavigationEvent with _$NavigationEvent {
  const factory NavigationEvent.navigateToIndex(int index) = NavigateToIndex;
}
