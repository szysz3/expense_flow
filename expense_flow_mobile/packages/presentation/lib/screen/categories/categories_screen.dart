import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/screen/categories/bloc/categories_bloc.dart';
import 'package:presentation/screen/categories/bloc/categories_state.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CategoriesBloc(),
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
        builder: (context, state) => Center(child: Text('Categories screen')));
  }
}
