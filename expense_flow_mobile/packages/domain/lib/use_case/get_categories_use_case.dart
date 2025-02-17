import 'package:dartz/dartz.dart';

import '../model/category_with_items.dart';
import '../model/failure/failures.dart';
import '../repository/receipt_repository.dart';
import 'base/base_use_case.dart';

class GetCategoriesUseCase
    implements BaseUseCase<NoParams, Either<Failure, List<CategoryWithItems>>> {
  final ReceiptRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CategoryWithItems>>> call(NoParams params) async {
    return await repository.getCategories();
  }
}
