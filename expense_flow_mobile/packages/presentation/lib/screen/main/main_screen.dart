import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/di/di.dart';
import 'package:presentation/navigation/bloc/navigation_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_state.dart';
import 'package:presentation/navigation/widget/bottom_navigation.dart';
import 'package:presentation/screen/categories/categories_screen.dart';
import 'package:presentation/screen/main/bloc/camera_preview_bloc.dart';
import 'package:presentation/screen/main/bloc/camera_preview_event.dart';
import 'package:presentation/screen/main/bloc/camera_preview_state.dart';
import 'package:presentation/screen/receipt_scan/receipt_scan_screen.dart';
import 'package:presentation/screen/summary/summary_screen.dart';
import 'package:presentation/services/camera/camera_service.dart';
import 'package:presentation/theme/expense_flow_color_scheme.dart';

import '../add_item/add_item_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavigationBloc()),
        BlocProvider(
            create: (context) => CameraPreviewBloc(getIt<CameraService>())
              ..add(InitializeCameraEvent())),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            BlocBuilder<CameraPreviewBloc, CameraPreviewState>(
              builder: (context, state) {
                return switch (state) {
                  CameraPreviewInitialized() =>
                    _CameraPreview(state.controller),
                  CameraInitError() => Text(state.message),
                  _ => SizedBox.shrink()
                };
              },
            ),
            BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, state) {
                return IndexedStack(
                  index: state.currentIndex,
                  children: const [
                    ReceiptScanScreen(),
                    AddItemScreen(),
                    CategoriesScreen(),
                    SummaryScreen(),
                  ],
                );
              },
            )
          ],
        ),
        bottomNavigationBar: const BottomNavigation(),
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  final CameraController controller;

  const _CameraPreview(this.controller);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBlurredBackgroundPreview(context),
      ],
    );
  }

  Widget _buildBlurredBackgroundPreview(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final data = MediaQuery.of(context);
    final aspectRatio = controller.value.aspectRatio;
    final deviceRatio = size.width / size.height + data.padding.bottom;

    return Center(
      child: Transform.scale(
        scale: controller.value.aspectRatio / deviceRatio,
        child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.accentDelicate.withAlpha(250),
                  BlendMode.modulate,
                ),
                child: CameraPreview(controller),
              ),
            )),
      ),
    );
  }
}
