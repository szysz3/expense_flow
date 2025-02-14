import 'package:freezed_annotation/freezed_annotation.dart';

part 'categories_events.freezed.dart';

@freezed
class CategoriesEvent with _$CategoriesEvent {
  const factory CategoriesEvent.onSomething() = SomethingEvent;
}
