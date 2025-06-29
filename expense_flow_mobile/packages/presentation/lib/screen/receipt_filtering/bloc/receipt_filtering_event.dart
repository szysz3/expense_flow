import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_filtering_event.freezed.dart';

@freezed
class ReceiptFilteringEvent with _$ReceiptFilteringEvent {
  const factory ReceiptFilteringEvent.init() = InitEvent;

  const factory ReceiptFilteringEvent.refresh() = RefreshEvent;
}
