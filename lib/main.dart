import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/domain/project_status_reader.dart';
import 'core/domain/session_status_reader.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/projects/data/project_repository_impl.dart';
import 'features/projects/data/project_status_reader_impl.dart';
import 'features/sessions/data/session_repository_impl.dart';
import 'features/sessions/data/session_status_reader_impl.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // core no puede importar features/projects ni features/sessions;
        // main.dart es el único sitio que conoce todas las features y
        // conecta cada placeholder con su implementación real.
        projectStatusReaderProvider.overrideWith(
          (ref) => ProjectStatusReaderImpl(ref.watch(projectRepositoryProvider)),
        ),
        sessionStatusReaderProvider.overrideWith(
          (ref) => SessionStatusReaderImpl(ref.watch(sessionRepositoryProvider)),
        ),
      ],
      child: const UpReqApp(),
    ),
  );
}

class UpReqApp extends StatelessWidget {
  const UpReqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Up-Req',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
