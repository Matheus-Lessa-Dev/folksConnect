import 'package:flutter/foundation.dart';

class SettingsUser {
  SettingsUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    Set<String> permissions = const {},
  }) : permissions = Set.unmodifiable(permissions);

  final int id;
  final String name;
  final String email;
  final String role;
  final Set<String> permissions;

  SettingsUser withRole(String value) => SettingsUser(
    id: id,
    name: name,
    email: email,
    role: value,
    permissions: permissions,
  );
}

/// Dados de demonstracao, mantidos apenas na sessao autenticada.
/// Os papeis nao concedem autorizacao no backend.
class SettingsController extends ChangeNotifier {
  static const roles = ['Assistente', 'Gerente', 'Analista', 'Diretor'];
  static const availablePermissions = [
    'Importar Planilha',
    'Cadastrar Tarefas',
    'Cadastrar Vaga',
    'Editar Vaga',
    'Cadastrar Usuário',
    'Editar Usuário',
    'Cadastrar Etapas do Kanban',
    'Editar Etapas do Kanban',
    'Cadastrar Etapas do Funil de Vendas',
    'Editar Etapas do Funil de Vendas',
    'Cadastrar Etapas do CheckList',
    'Editar Etapas do CheckList',
  ];

  String profileName = '';
  String profileEmail = '';
  String? profileRole;
  int _nextId = 5;
  List<SettingsUser> _users = [
    SettingsUser(
      id: 1,
      name: 'Ana Munaro',
      email: 'ana@example.com',
      role: 'Assistente',
    ),
    SettingsUser(
      id: 2,
      name: 'Matheus Lessa',
      email: 'matheus@example.com',
      role: 'Gerente',
    ),
    SettingsUser(
      id: 3,
      name: 'Eduarda Oliveira',
      email: 'eduarda@example.com',
      role: 'Analista',
    ),
    SettingsUser(
      id: 4,
      name: 'João Francisco',
      email: 'joao@example.com',
      role: 'Diretor',
    ),
  ];
  List<String> _kanbanStages = [
    'A fazer',
    'Em andamento',
    'Aguardando',
    'Concluído',
  ];
  List<String> _funnelStages = [
    'Triagem',
    'Entrevista',
    'Retorno',
    'Contratação',
  ];
  List<String> _checklist = [
    'Coletar currículos inscritos',
    'Filtrar por requisitos mínimos',
    'Marcar candidatos para entrevista',
    'Registrar motivo de reprovação dos demais',
  ];

  List<SettingsUser> get users => List.unmodifiable(_users);
  List<String> get kanbanStages => List.unmodifiable(_kanbanStages);
  List<String> get funnelStages => List.unmodifiable(_funnelStages);
  List<String> get checklist => List.unmodifiable(_checklist);

  void saveConfiguration({
    required List<String> kanban,
    required List<String> funnel,
    required List<String> checklist,
  }) {
    List<String> validated(List<String> items) {
      final clean = items.map((item) => item.trim()).toList();
      if (clean.isEmpty ||
          clean.any((item) => item.isEmpty) ||
          clean.map((item) => item.toLowerCase()).toSet().length !=
              clean.length) {
        throw ArgumentError(
          'Cada seção precisa de itens preenchidos e sem repetição.',
        );
      }
      return clean;
    }

    // Valide todas as secoes antes de alterar o estado.
    final nextKanban = validated(kanban);
    final nextFunnel = validated(funnel);
    final nextChecklist = validated(checklist);
    _kanbanStages = nextKanban;
    _funnelStages = nextFunnel;
    _checklist = nextChecklist;
    notifyListeners();
  }

  bool hasEmail(String email) => _users.any(
    (user) => user.email.toLowerCase() == email.trim().toLowerCase(),
  );

  void addUser({
    required String name,
    required String email,
    required String role,
    required Set<String> permissions,
  }) {
    if (name.trim().isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim()) ||
        !roles.contains(role) ||
        hasEmail(email) ||
        !permissions.every(availablePermissions.contains)) {
      throw ArgumentError(
        'Dados de usuário inválidos ou e-mail já cadastrado.',
      );
    }
    _users = [
      ..._users,
      SettingsUser(
        id: _nextId++,
        name: name.trim(),
        email: email.trim(),
        role: role,
        permissions: permissions,
      ),
    ];
    notifyListeners();
  }

  void changeRole(int id, String role) {
    if (!roles.contains(role)) throw ArgumentError.value(role);
    _users = [
      for (final user in _users)
        if (user.id == id) user.withRole(role) else user,
    ];
    notifyListeners();
  }

  void removeUser(int id) {
    _users = _users.where((user) => user.id != id).toList();
    notifyListeners();
  }
}
