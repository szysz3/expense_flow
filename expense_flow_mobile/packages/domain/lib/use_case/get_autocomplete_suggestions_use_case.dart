import 'package:dartz/dartz.dart';
import 'package:domain/model/autocomplete_suggestion.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';

class GetAutocompleteSuggestionsParams {
  final String text;
  final int limit;

  GetAutocompleteSuggestionsParams({
    required this.text,
    this.limit = 8,
  });
}

class GetAutocompleteSuggestionsUseCase
    implements
        BaseUseCase<GetAutocompleteSuggestionsParams,
            Either<Failure, List<AutocompleteSuggestion>>> {
  final ReceiptRepository repository;

  GetAutocompleteSuggestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AutocompleteSuggestion>>> call(
      GetAutocompleteSuggestionsParams params) async {
    if (params.text.trim().isEmpty) {
      return const Right([]);
    }

    return await repository.getAutocompleteSuggestions(
      params.text,
      limit: params.limit,
    );
  }
}
