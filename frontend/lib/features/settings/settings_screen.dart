import 'package:flutter/material.dart';

import '../../core/theme/folks_theme.dart';
import '../../core/widgets/folks_navigation.dart';
import 'settings_controller.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: FolksColors.sheet,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => child,
    );

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final SettingsController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _name = TextEditingController(text: widget.controller.profileName);
  late final _email = TextEditingController(
    text: widget.controller.profileEmail,
  );

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Widget _option(String title, String description, VoidCallback onTap) => Card(
    margin: EdgeInsets.zero,
    color: FolksColors.card,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: FolksTheme.heading.copyWith(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: FolksColors.muted),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: FolksTheme.background),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 17, 16, 56),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Configurações', style: FolksTheme.heading),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FolksColors.card,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Perfil',
                                    style: FolksTheme.heading.copyWith(
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const CircleAvatar(
                                    radius: 44,
                                    backgroundColor: Colors.black,
                                    child: Icon(
                                      Icons.person,
                                      size: 52,
                                      color: FolksColors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: [
                                    _ProfileField(
                                      label: 'Nome:',
                                      controller: _name,
                                      onChanged: (value) =>
                                          widget.controller.profileName = value,
                                    ),
                                    const SizedBox(height: 8),
                                    _ProfileField(
                                      label: 'Email:',
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      onChanged: (value) =>
                                          widget.controller.profileEmail =
                                              value,
                                    ),
                                    const SizedBox(height: 8),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Cargo:',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: FolksColors.muted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    DropdownButtonFormField<String>(
                                      initialValue:
                                          widget.controller.profileRole,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                      ),
                                      hint: const Text(
                                        'Selecionar',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                        ),
                                      ),
                                      isExpanded: true,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: FolksColors.white,
                                      ),
                                      items: SettingsController.roles
                                          .map(
                                            (role) => DropdownMenuItem(
                                              value: role,
                                              child: Text(role),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) =>
                                          widget.controller.profileRole = value,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'CONFIGURAÇÃO GERAL',
                          style: FolksTheme.heading.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 12),
                        _option(
                          'Kanban, funil e Checklis',
                          'Gerenciar status do Kanban, etapas do funil de vagas e o Checklist Padrão',
                          () => _sheet<void>(
                            context,
                            _ConfigurationSheet(controller: widget.controller),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _option(
                          'Novo usuário',
                          'Cadastrar um usuário e configurar os papéis de acesso.',
                          () => _sheet<void>(
                            context,
                            _UsersSheet(controller: widget.controller),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const FolksNavigation(selectedRoute: '/configuracoes'),
          ],
        ),
      ),
    ),
  );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 9, color: FolksColors.muted),
      ),
      const SizedBox(height: 2),
      Semantics(
        label: label,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
        ),
      ),
    ],
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24,
      8,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: FolksTheme.heading.copyWith(fontSize: 24)),
        const SizedBox(height: 20),
        ...children,
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: FolksColors.field),
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: FolksTheme.primaryGradient,
      borderRadius: BorderRadius.circular(8),
    ),
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

class _ConfigurationSheet extends StatefulWidget {
  const _ConfigurationSheet({required this.controller});
  final SettingsController controller;

  @override
  State<_ConfigurationSheet> createState() => _ConfigurationSheetState();
}

class _ConfigurationSheetState extends State<_ConfigurationSheet> {
  late final List<List<TextEditingController>> _sections =
      [
            widget.controller.kanbanStages,
            widget.controller.funnelStages,
            widget.controller.checklist,
          ]
          .map(
            (items) =>
                items.map((item) => TextEditingController(text: item)).toList(),
          )
          .toList();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final section in _sections) {
      for (final field in section) {
        field.dispose();
      }
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final values = _sections
        .map((section) => section.map((field) => field.text).toList())
        .toList();
    widget.controller.saveConfiguration(
      kanban: values[0],
      funnel: values[1],
      checklist: values[2],
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alterações salvas nesta sessão.')),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: _SheetBody(
      title: 'Configurações Gerais',
      children: [
        for (var section = 0; section < _sections.length; section++) ...[
          Text(
            [
              'ETAPAS DO QUADRO (KANBAN)',
              'ETAPAS DO FUNIL DE VAGAS',
              'CHECKLIST PADRÃO',
            ][section],
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: FolksColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: FolksColors.field,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (var index = 0; index < _sections[section].length; index++)
                  Row(
                    key: ObjectKey(_sections[section][index]),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Icon(
                          Icons.circle,
                          size: 5,
                          color: FolksColors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          label: 'Item ${index + 1}',
                          child: TextFormField(
                            controller: _sections[section][index],
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Nome do item',
                              isDense: true,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return 'Preencha este item.';
                              if (_sections[section]
                                      .where(
                                        (item) =>
                                            item.text.trim().toLowerCase() ==
                                            text.toLowerCase(),
                                      )
                                      .length >
                                  1) {
                                return 'Este item já existe nesta seção.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remover item ${index + 1}',
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: _sections[section].length == 1
                            ? null
                            : () {
                                final field = _sections[section][index];
                                setState(
                                  () => _sections[section].removeAt(index),
                                );
                                // Aguarde o TextFormField desmontar antes de liberar seu controller.
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => field.dispose(),
                                );
                              },
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(
                      () => _sections[section].add(TextEditingController()),
                    ),
                    child: const Text(
                      '+ Adicionar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _PrimaryButton(label: 'Salvar Alteração', onPressed: _save),
      ],
    ),
  );
}

class _UsersSheet extends StatelessWidget {
  const _UsersSheet({required this.controller});
  final SettingsController controller;

  Future<void> _remove(BuildContext context, SettingsUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover usuário?'),
        content: Text('Remover ${user.name} da lista desta sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.removeUser(user.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => _SheetBody(
      title: 'Usuários e papéis',
      children: [
        if (controller.users.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text('Nenhum usuário cadastrado.'),
          ),
        for (final user in controller.users)
          Padding(
            key: ValueKey('user-${user.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                final identity = Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: FolksColors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontSize: 13)),
                          Text(
                            user.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: FolksColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final role = Semantics(
                  label: 'Cargo de ${user.name}',
                  child: DropdownButtonFormField<String>(
                    initialValue: user.role,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: FolksColors.white,
                    ),
                    items: SettingsController.roles
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) controller.changeRole(user.id, value);
                    },
                  ),
                );
                final remove = IconButton(
                  tooltip: 'Remover ${user.name}',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _remove(context, user),
                );
                if (largeText || constraints.maxWidth < 320) {
                  return Column(
                    children: [
                      identity,
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: role),
                          remove,
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 8),
                    SizedBox(width: 112, child: role),
                    remove,
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        _PrimaryButton(
          label: 'Cadastrar Usuário',
          onPressed: () =>
              _sheet<void>(context, _NewUserSheet(controller: controller)),
        ),
      ],
    ),
  );
}

class _NewUserSheet extends StatefulWidget {
  const _NewUserSheet({required this.controller});
  final SettingsController controller;

  @override
  State<_NewUserSheet> createState() => _NewUserSheetState();
}

class _NewUserSheetState extends State<_NewUserSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _role = 'Analista';
  final _permissions = <String>{'Cadastrar Tarefas'};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    widget.controller.addUser(
      name: _name.text,
      email: _email.text,
      role: _role,
      permissions: _permissions,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário cadastrado nesta sessão.')),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: _SheetBody(
      title: 'Novo Usuário',
      children: [
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(
            labelText: 'NOME COMPLETO',
            hintText: 'Ex: Maria Silva',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Informe o nome completo.'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'E-MAIL',
            hintText: 'Ex: nome@folksrh.com.br',
          ),
          validator: (value) {
            if (!RegExp(
              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
            ).hasMatch(value?.trim() ?? '')) {
              return 'Informe um e-mail válido.';
            }
            if (widget.controller.hasEmail(value!)) {
              return 'Este e-mail já está cadastrado.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _role,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'CARGO'),
          items: SettingsController.roles
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          onChanged: (value) {
            if (value != null) _role = value;
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'PERMISSÕES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: FolksColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: SettingsController.availablePermissions
              .map(
                (permission) => FilterChip(
                  label: Text(permission, style: const TextStyle(fontSize: 12)),
                  selected: _permissions.contains(permission),
                  showCheckmark: false,
                  selectedColor: FolksColors.primary,
                  backgroundColor: FolksColors.field,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _permissions.add(permission);
                    } else {
                      _permissions.remove(permission);
                    }
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(label: 'Cadastrar Usuário', onPressed: _save),
      ],
    ),
  );
}
