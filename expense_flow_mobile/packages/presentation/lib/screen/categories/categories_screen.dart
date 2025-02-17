import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/categories/widget/category_list_item.dart';

import '../../di/di.dart';
import 'bloc/categories_bloc.dart';
import 'bloc/categories_events.dart';
import 'bloc/categories_state.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CategoriesBloc(
          getCategoriesUseCase: getIt<GetCategoriesUseCase>(),
        )..add(const CategoriesEvent.init()),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const CategoriesScreenView(),
        ),
      );
}

class CategoriesScreenView extends StatelessWidget {
  const CategoriesScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: state.categories.length,
          itemBuilder: (context, index) {
            final category = state.categories[index];
            return CategoryListItem(
              category: category,
              onToggle: () => context.read<CategoriesBloc>().add(
                    CategoriesEvent.toggleCategory(category.id),
                  ),
            );
          },
        );
      },
    );
  }
}
