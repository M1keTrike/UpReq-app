import 'package:go_router/go_router.dart';
import 'package:up_req/features/audit_log/presentation/audit_log_screen.dart';
import 'package:up_req/features/glossary/presentation/glossary_form_screen.dart';
import 'package:up_req/features/glossary/presentation/glossary_list_screen.dart';
import 'package:up_req/features/projects/presentation/project_detail_screen.dart';
import 'package:up_req/features/projects/presentation/project_form_screen.dart';
import 'package:up_req/features/projects/presentation/project_list_screen.dart';
import 'package:up_req/features/recordings/presentation/recording_detail_screen.dart';
import 'package:up_req/features/sessions/presentation/session_detail_screen.dart';
import 'package:up_req/features/sessions/presentation/session_form_screen.dart';
import 'package:up_req/features/sessions/presentation/session_list_screen.dart';
import 'package:up_req/features/stakeholders/presentation/stakeholder_form_screen.dart';
import 'package:up_req/features/stakeholders/presentation/stakeholder_list_screen.dart';

/// Árbol de rutas de FR-021: lista de proyectos, detalle de proyecto con
/// acceso a interesados, sesiones, glosario y bitácora, y detalle de sesión
/// con su guion. `projectId` está presente en toda ruta interior. Cada
/// historia de usuario fue sustituyendo sus marcadores de posición
/// (T047, T060, T079, T090, T103, T110); ya no queda ninguno.
///
/// FR-021 exige que la navegación sea **jerárquica** empezando por la lista
/// de proyectos: `/projects/new` y `/projects/:projectId` cuelgan como rutas
/// hijas de `/` (no como rutas hermanas de nivel superior) para que
/// `ProjectListScreen` quede en la pila de navegación de go_router bajo
/// cualquier ruta interior. Sin este anidamiento, `context.go(...)` — que
/// go_router resuelve recalculando la pila completa a partir del árbol de
/// rutas, no del historial de navegación — dejaría una pila de una sola
/// página al entrar al detalle de un proyecto, y el botón "atrás" nunca
/// aparecería para volver a la lista (detectado durante T111–T114, Fase 9).
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProjectListScreen(),
      routes: [
        GoRoute(
          path: 'projects/new',
          builder: (context, state) => const ProjectFormScreen(projectId: null),
        ),
        GoRoute(
          path: 'projects/:projectId',
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
              builder: (context, state) => SessionListScreen(
                projectId: state.pathParameters['projectId']!,
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => SessionFormScreen(
                    projectId: state.pathParameters['projectId']!,
                    sessionId: null,
                  ),
                ),
                GoRoute(
                  path: ':sessionId',
                  builder: (context, state) => SessionDetailScreen(
                    projectId: state.pathParameters['projectId']!,
                    sessionId: state.pathParameters['sessionId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => SessionFormScreen(
                        projectId: state.pathParameters['projectId']!,
                        sessionId: state.pathParameters['sessionId'],
                      ),
                    ),
                    GoRoute(
                      path: 'recordings/:recordingId',
                      builder: (context, state) => RecordingDetailScreen(
                        recordingId: state.pathParameters['recordingId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: 'glossary',
              builder: (context, state) => GlossaryListScreen(
                projectId: state.pathParameters['projectId']!,
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => GlossaryFormScreen(
                    projectId: state.pathParameters['projectId']!,
                    termId: null,
                  ),
                ),
                GoRoute(
                  path: ':termId/edit',
                  builder: (context, state) => GlossaryFormScreen(
                    projectId: state.pathParameters['projectId']!,
                    termId: state.pathParameters['termId'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'audit',
              builder: (context, state) => AuditLogScreen(
                projectId: state.pathParameters['projectId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
