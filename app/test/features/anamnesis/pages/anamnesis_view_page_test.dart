import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc_models.dart';
import 'package:terafy/features/anamnesis/models/anamnesis.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_section.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_field.dart';
import 'package:terafy/features/anamnesis/pages/anamnesis_view_page.dart';

class _MockAnamnesisBloc extends Mock implements AnamnesisBloc {}

class FakeAnamnesisEvent extends Fake implements AnamnesisEvent {}

class FakeAnamnesisState extends Fake implements AnamnesisState {}

void main() {
  late _MockAnamnesisBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeAnamnesisEvent());
    registerFallbackValue(FakeAnamnesisState());
  });

  setUp(() {
    mockBloc = _MockAnamnesisBloc();
  });

  Widget createAnamnesisViewPage({String patientId = 'patient-123', String? anamnesisId}) {
    return MaterialApp(
      home: AnamnesisViewPage(patientId: patientId, anamnesisId: anamnesisId, bloc: mockBloc),
      localizationsDelegates: const [DefaultMaterialLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
    );
  }

  group('AnamnesisViewPage', () {
    testWidgets('renderiza AppBar com título correto', (tester) async {
      when(() => mockBloc.state).thenReturn(AnamnesisLoading());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());

      expect(find.text('Anamnese'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renderiza CircularProgressIndicator em estado loading', (tester) async {
      when(() => mockBloc.state).thenReturn(AnamnesisLoading());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renderiza mensagem de erro em estado error', (tester) async {
      const errorMessage = 'Erro ao carregar anamnese';
      when(() => mockBloc.state).thenReturn(const AnamnesisError(errorMessage));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renderiza botão "Tentar novamente" em estado error', (tester) async {
      when(() => mockBloc.state).thenReturn(const AnamnesisError('Erro'));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('botão "Tentar novamente" dispara evento correto quando anamnesisId é fornecido', (tester) async {
      const anamnesisId = 'anamnesis-123';
      when(() => mockBloc.state).thenReturn(const AnamnesisError('Erro'));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(createAnamnesisViewPage(anamnesisId: anamnesisId));
      await tester.pump();

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      verify(() => mockBloc.add(const LoadAnamnesisById(anamnesisId))).called(1);
    });

    testWidgets('botão "Tentar novamente" dispara evento correto quando apenas patientId é fornecido', (tester) async {
      const patientId = 'patient-123';
      when(() => mockBloc.state).thenReturn(const AnamnesisError('Erro'));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(createAnamnesisViewPage(patientId: patientId));
      await tester.pump();

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      verify(() => mockBloc.add(const LoadAnamnesisByPatientId(patientId))).called(1);
    });

    testWidgets('renderiza mensagem quando nenhuma anamnese é encontrada', (tester) async {
      when(() => mockBloc.state).thenReturn(AnamnesisInitial());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Nenhuma anamnese encontrada'), findsOneWidget);
    });

    testWidgets('renderiza anamnese completa com template', (tester) async {
      final template = AnamnesisTemplate(
        id: 'template-1',
        name: 'Anamnese Padrão',
        description: 'Template padrão de anamnese',
        sections: [
          AnamnesisSection(
            id: 'section-1',
            title: 'Dados Pessoais',
            description: 'Informações pessoais do paciente',
            order: 0,
            fields: [
              AnamnesisField(id: 'field-1', label: 'Nome', type: AnamnesisFieldType.text, required: true, order: 0),
            ],
          ),
        ],
      );

      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        templateId: 'template-1',
        data: {'field-1': 'João Silva'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis, template: template));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Anamnese Padrão'), findsOneWidget);
      expect(find.text('Template padrão de anamnese'), findsOneWidget);
      expect(find.text('Completa'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renderiza botão de edição quando anamnese não está completa', (tester) async {
      final template = AnamnesisTemplate(id: 'template-1', name: 'Anamnese Padrão', sections: []);

      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        templateId: 'template-1',
        data: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completedAt: null, // Não completada
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis, template: template));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.text('Completa'), findsNothing);
    });

    testWidgets('não renderiza botão de edição quando anamnese está completa', (tester) async {
      final template = AnamnesisTemplate(id: 'template-1', name: 'Anamnese Padrão', sections: []);

      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        templateId: 'template-1',
        data: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completedAt: DateTime.now(), // Completada
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis, template: template));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.text('Completa'), findsOneWidget);
    });

    testWidgets('renderiza seções com dados preenchidos', (tester) async {
      final template = AnamnesisTemplate(
        id: 'template-1',
        name: 'Anamnese Padrão',
        sections: [
          AnamnesisSection(
            id: 'section-1',
            title: 'Dados Pessoais',
            order: 0,
            fields: [
              AnamnesisField(id: 'field-1', label: 'Nome', type: AnamnesisFieldType.text, required: true, order: 0),
              AnamnesisField(id: 'field-2', label: 'Idade', type: AnamnesisFieldType.number, required: false, order: 1),
            ],
          ),
        ],
      );

      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        templateId: 'template-1',
        data: {'field-1': 'João Silva', 'field-2': 30},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis, template: template));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Dados Pessoais'), findsOneWidget);
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Idade'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('não renderiza seções sem dados preenchidos', (tester) async {
      final template = AnamnesisTemplate(
        id: 'template-1',
        name: 'Anamnese Padrão',
        sections: [
          AnamnesisSection(
            id: 'section-1',
            title: 'Seção Vazia',
            order: 0,
            fields: [
              AnamnesisField(
                id: 'field-1',
                label: 'Campo Vazio',
                type: AnamnesisFieldType.text,
                required: false,
                order: 0,
              ),
            ],
          ),
        ],
      );

      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        templateId: 'template-1',
        data: {}, // Sem dados
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis, template: template));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Seção Vazia'), findsNothing);
      expect(find.text('Campo Vazio'), findsNothing);
    });

    testWidgets('renderiza card de informações com datas', (tester) async {
      final now = DateTime(2024, 12, 3, 14, 30);
      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        data: {},
        createdAt: now,
        updatedAt: now,
        completedAt: now,
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis, template: null));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Informações'), findsOneWidget);
      expect(find.textContaining('Criada em'), findsOneWidget);
      expect(find.textContaining('Atualizada em'), findsOneWidget);
      expect(find.textContaining('Completada em'), findsOneWidget);
    });

    testWidgets('formata valores booleanos corretamente', (tester) async {
      final template = AnamnesisTemplate(
        id: 'template-1',
        name: 'Anamnese',
        sections: [
          AnamnesisSection(
            id: 'section-1',
            title: 'Seção',
            order: 0,
            fields: [
              AnamnesisField(
                id: 'field-1',
                label: 'Aceita termos',
                type: AnamnesisFieldType.boolean,
                required: false,
                order: 0,
              ),
            ],
          ),
        ],
      );

      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        data: {'field-1': true},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis, template: template));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Aceita termos'), findsOneWidget);
      expect(find.text('Sim'), findsOneWidget);
    });

    testWidgets('formata valores de lista (checkboxGroup) corretamente', (tester) async {
      final template = AnamnesisTemplate(
        id: 'template-1',
        name: 'Anamnese',
        sections: [
          AnamnesisSection(
            id: 'section-1',
            title: 'Seção',
            order: 0,
            fields: [
              AnamnesisField(
                id: 'field-1',
                label: 'Sintomas',
                type: AnamnesisFieldType.checkboxGroup,
                required: false,
                order: 0,
              ),
            ],
          ),
        ],
      );

      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        data: {
          'field-1': ['Dor de cabeça', 'Febre', 'Tosse'],
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis, template: template));
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Sintomas'), findsOneWidget);
      expect(find.text('Dor de cabeça, Febre, Tosse'), findsOneWidget);
    });

    testWidgets('renderiza dados brutos quando não há template', (tester) async {
      final anamnesis = Anamnesis(
        id: 'anamnesis-1',
        patientId: 'patient-123',
        therapistId: 'therapist-123',
        data: {'nome': 'João Silva', 'idade': 30},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockBloc.state).thenReturn(AnamnesisLoaded(anamnesis: anamnesis));

      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createAnamnesisViewPage());
      await tester.pump();

      expect(find.text('Dados da Anamnese'), findsOneWidget);
      expect(find.text('nome'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('idade'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });
  });
}
