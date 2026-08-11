import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      builder: (context, state) => const _Placeholder('Lista de proyectos'),
    ),
    GoRoute(
      path: '/projects/new',
      builder: (context, state) =>
          const _Placeholder('Formulario de proyecto (nuevo)'),
    ),
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) => _Placeholder(
        'Detalle de proyecto ${state.pathParameters['projectId']}',
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) =>
              const _Placeholder('Formulario de proyecto (editar)'),
        ),
        GoRoute(
          path: 'stakeholders',
          builder: (context, state) => const _Placeholder('Interesados'),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) =>
                  const _Placeholder('Formulario de interesado (nuevo)'),
            ),
            GoRoute(
              path: ':stakeholderId/edit',
              builder: (context, state) =>
                  const _Placeholder('Formulario de interesado (editar)'),
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
