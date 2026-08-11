import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term_draft.dart';
import 'package:up_req/features/glossary/domain/glossary_repository.dart';
import 'package:up_req/features/glossary/domain/usecases/create_glossary_term.dart';
import 'package:up_req/features/glossary/domain/usecases/delete_glossary_term.dart';
import 'package:up_req/features/glossary/domain/usecases/update_glossary_term.dart';

class _FakeGlossaryRepository implements GlossaryRepository {
  final Map<String, GlossaryTerm> store = {};

  @override
  Future<void> insert(GlossaryTerm term) async => store[term.id.value] = term;

  @override
  Future<void> update(GlossaryTerm term) async => store[term.id.value] = term;

  @override
  Future<GlossaryTerm?> findById(GlossaryTermId id) async => store[id.value];

  @override
  Future<void> softDelete(GlossaryTermId id, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = GlossaryTerm(
      id: current.id,
      projectId: current.projectId,
      term: current.term,
      termSortKey: current.termSortKey,
      createdAt: current.createdAt,
      updatedAt: at,
      definition: current.definition,
      notes: current.notes,
    );
  }

  @override
  Stream<List<GlossaryTerm>> watchByProject(ProjectId id) => throw UnimplementedError();
}

class _FakeProjectStatusReader implements ProjectStatusReader {
  _FakeProjectStatusReader({this.active = true});

  final bool active;

  @override
  Future<bool> isActive(ProjectId id) async => active;
}

class _FixedIdGenerator implements IdGenerator {
  _FixedIdGenerator(this._id);

  final String _id;

  @override
  String generate() => _id;
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const projectId = ProjectId('project-1');
  late _FakeGlossaryRepository repository;

  setUp(() => repository = _FakeGlossaryRepository());

  group('CreateGlossaryTerm', () {
    test('rechaza un término vacío', () async {
      final useCase = CreateGlossaryTerm(
        repository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('t1'),
      );

      final result = await useCase(projectId, const GlossaryTermDraft(term: '   '));

      expect(result, isA<Err<GlossaryTermId>>());
      expect((result as Err<GlossaryTermId>).failure, isA<ValidationFailure>());
      expect(repository.store, isEmpty);
    });

    test('calcula term_sort_key en minúsculas y sin acentos al crear', () async {
      final useCase = CreateGlossaryTerm(
        repository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('t1'),
      );

      final result = await useCase(projectId, const GlossaryTermDraft(term: 'Ábaco'));

      expect(result, isA<Ok<GlossaryTermId>>());
      expect(repository.store['t1']!.term, 'Ábaco');
      expect(repository.store['t1']!.termSortKey, 'abaco');
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado', () async {
      final useCase = CreateGlossaryTerm(
        repository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
        _FixedIdGenerator('t1'),
      );

      final result = await useCase(projectId, const GlossaryTermDraft(term: 'Requisito'));

      expect(result, isA<Err<GlossaryTermId>>());
      expect((result as Err<GlossaryTermId>).failure, isA<ProjectClosedFailure>());
      expect(repository.store, isEmpty);
    });
  });

  group('UpdateGlossaryTerm', () {
    test('recalcula term_sort_key en cada escritura', () async {
      repository.store['t1'] = GlossaryTerm(
        id: const GlossaryTermId('t1'),
        projectId: projectId,
        term: 'Original',
        termSortKey: 'original',
        createdAt: at,
        updatedAt: at,
      );
      final useCase = UpdateGlossaryTerm(repository, _FakeProjectStatusReader(), Clock.fixed(at));

      final result = await useCase(const GlossaryTermId('t1'), const GlossaryTermDraft(term: 'Zeta'));

      expect(result, isA<Ok<void>>());
      expect(repository.store['t1']!.term, 'Zeta');
      expect(repository.store['t1']!.termSortKey, 'zeta');
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado', () async {
      repository.store['t1'] = GlossaryTerm(
        id: const GlossaryTermId('t1'),
        projectId: projectId,
        term: 'Original',
        termSortKey: 'original',
        createdAt: at,
        updatedAt: at,
      );
      final useCase = UpdateGlossaryTerm(
        repository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const GlossaryTermId('t1'), const GlossaryTermDraft(term: 'Nuevo'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
      expect(repository.store['t1']!.term, 'Original');
    });
  });

  group('DeleteGlossaryTerm', () {
    test('elimina lógicamente un término del proyecto activo', () async {
      repository.store['t1'] = GlossaryTerm(
        id: const GlossaryTermId('t1'),
        projectId: projectId,
        term: 'Requisito',
        termSortKey: 'requisito',
        createdAt: at,
        updatedAt: at,
      );
      final useCase = DeleteGlossaryTerm(repository, _FakeProjectStatusReader(), Clock.fixed(at));

      final result = await useCase(const GlossaryTermId('t1'));

      expect(result, isA<Ok<void>>());
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (invariante I5)', () async {
      repository.store['t1'] = GlossaryTerm(
        id: const GlossaryTermId('t1'),
        projectId: projectId,
        term: 'Requisito',
        termSortKey: 'requisito',
        createdAt: at,
        updatedAt: at,
      );
      final useCase = DeleteGlossaryTerm(
        repository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const GlossaryTermId('t1'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
    });
  });
}
