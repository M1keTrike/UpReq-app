import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/features/projects/presentation/project_detail_screen.dart';
import 'package:up_req/features/projects/presentation/project_form_screen.dart';
import 'package:up_req/features/projects/presentation/project_list_screen.dart';
import 'package:up_req/features/stakeholders/presentation/stakeholder_form_screen.dart';
import 'package:up_req/features/stakeholders/presentation/stakeholder_list_screen.dart';

/// Árbol de rutas de FR-021: lista de proyectos, detalle de proyecto con
/// acceso a interesados, sesiones, glosario y bitácora, y detalle de sesión
/// con su guion. `projectId` está presente en toda ruta interior. Apunta de
/// momento a pantallas de marcador de posición; cada historia de usuario
/// sustituye las suyas (T047, T060, T079, T103, T110).
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProjectListScreen(),
    ),
    GoRoute(
      path: '/projects/new',
      builder: (context, state) => const ProjectFormScreen(projectId: null),
    ),
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) => ProjectDetailScreen(
        projectId: state.pathParameters['projectId']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => ProjectFormScreen(
            projectId: state.pathParameters['projectId'],
          ),
        ),
        GoRoute(
          path: 'stakeholders',
          builder: (context, state) => StakeholderListScreen(
            projectId: state.pathParameters['projectId']!,
          ),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => StakeholderFormScreen(
                projectId: state.pathParameters['projectId']!,
                stakeholderId: null,
              ),
            ),
            GoRoute(
              path: ':stakeholderId/edit',
              builder: (context, state) => StakeholderFormScreen(
                projectId: state.pathParameters['projectId']!,
                stakeholderId: state.pathParameters['stakeholderId'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'sessions',
          builder: (context, state) => const _Placeholder('Sesiones'),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) =>
                  const _Placeholder('Formulario de sesión (nuevo)'),
            ),
            GoRoute(
              path: ':sessionId',
              builder: (context, state) => _Placeholder(
                'Detalle de sesión ${state.pathParameters['sessionId']}',
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) =>
                      const _Placeholder('Formulario de sesión (editar)'),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'glossary',
          builder: (context, state) => const _Placeholder('Glosario'),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) =>
                  const _Placeholder('Formulario de término (nuevo)'),
            ),
            GoRoute(
              path: ':termId/edit',
              builder: (context, state) =>
                  const _Placeholder('Formulario de término (editar)'),
            ),
          ],
        ),
        GoRoute(
          path: 'audit',
          builder: (context, state) => const _Placeholder('Bitácora'),
        ),
      ],
    ),
  ],
);

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text(label)),
    );
  }
}
