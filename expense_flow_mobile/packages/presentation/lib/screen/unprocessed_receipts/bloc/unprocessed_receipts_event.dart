import 'package:freezed_annotation/freezed_annotation.dart';

part 'unprocessed_receipts_event.freezed.dart';

@freezed
class UnprocessedReceiptsEvent with _$UnprocessedReceiptsEvent {
  const factory UnprocessedReceiptsEvent.init() = InitEvent;

  const factory UnprocessedReceiptsEvent.refresh() = RefreshEvent;
}
