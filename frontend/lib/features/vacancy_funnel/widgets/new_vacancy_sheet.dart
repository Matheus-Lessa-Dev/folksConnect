import 'package:flutter/material.dart';

import '../../../core/theme/folks_theme.dart';
import '../../kanban/task.dart';
import '../../kanban/widgets/kanban_widgets.dart';
import '../vacancy.dart';
import '../vacancy_funnel_controller.dart';

class NewVacancySheet extends StatefulWidget {
  const NewVacancySheet({super.key, required this.controller});
  final VacancyFunnelController controller;

  @override
  State<NewVacancySheet> createState() => _NewVacancySheetState();
}

class _NewVacancySheetState extends State<NewVacancySheet> {
  final _form = GlobalKey<FormState>();
  final _role = TextEditingController();
  final _profile = TextEditingController();
  String? _company;
  String _assignee = VacancyFunnelController.assignees.first;
  final _channels = ['LinkedIn', 'Indicação'];
  final _selectedChannels = <String>{'LinkedIn'};
  DateTime? _start;
  DateTime? _end;
  String? _dateError;
  String? _channelError;
  bool _newClient = false;

  @override
  void dispose() {
    _role.dispose();
    _profile.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? _start ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: start ? 'Prazo inicial' : 'Prazo final',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (!mounted || date == null) return;
    setState(() {
      if (start) {
        _start = date;
      } else {
        _end = date;
      }
      _dateError = null;
    });
  }

  Future<void> _addChannel() async {
    var input = '';
    final form = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar canal'),
        content: Form(
          key: form,
          child: TextFormField(
            onChanged: (value) => input = value,
            autofocus: true,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Canal de divulgação'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome do canal.';
              }
              if (_channels.any(
                (channel) =>
                    channel.toLowerCase() == value.trim().toLowerCase(),
              )) {
                return 'Este canal já está disponível.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, input.trim());
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _channels.add(result);
        _selectedChannels.add(result);
        _channelError = null;
      });
    }
  }

  void _create() {
    final invalid = _form.currentState!.validateGranularly();
    setState(() {
      _dateError = _start == null || _end == null
          ? 'Selecione o início e o fim do prazo.'
          : _end!.isBefore(_start!)
          ? 'O fim deve ser igual ou posterior ao início.'
          : null;
      _channelError = _selectedChannels.isEmpty
          ? 'Selecione ao menos um canal de divulgação.'
          : null;
    });
    if (invalid.isNotEmpty) {
      Scrollable.ensureVisible(invalid.first.context, alignment: .2);
      return;
    }
    if (_newClient || _dateError != null || _channelError != null) return;
    widget.controller.add(
      role: _role.text,
      company: _company!,
      profile: _profile.text,
      assignee: _assignee,
      start: _start!,
      end: _end!,
      channels: _selectedChannels.toList(),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cadastrar Vaga',
          style: FolksTheme.heading.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 20),
        FieldLabel(
          'Cargo da vaga',
          child: TextFormField(
            key: const Key('vacancy-role'),
            controller: _role,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Ex: Analista de Sistemas.',
              hintStyle: TextStyle(color: FolksColors.muted, fontSize: 13),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o cargo da vaga.'
                : null,
          ),
        ),
        FieldLabel(
          'Cliente',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'vacancy-client-${_company ?? 'none'}-$_newClient',
                ),
                initialValue: _newClient ? '__new__' : _company,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Selecionar',
                  hintStyle: TextStyle(color: FolksColors.muted, fontSize: 13),
                ),
                items: [
                  ...widget.controller.clients.map(
                    (client) => DropdownMenuItem(
                      value: client.company,
                      child: Text(client.company),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '__new__',
                    child: Text('+ Novo Cliente'),
                  ),
                ],
                validator: (_) => _newClient
                    ? 'Salve ou cancele o novo cliente antes de continuar.'
                    : _company == null
                    ? 'Selecione o cliente.'
                    : null,
                onChanged: (value) => setState(() {
                  _newClient = value == '__new__';
                  if (!_newClient) _company = value;
                }),
              ),
              if (_newClient) ...[
                const SizedBox(height: 12),
                _NewClientForm(
                  controller: widget.controller,
                  onSaved: (company) => setState(() {
                    _company = company;
                    _newClient = false;
                  }),
                  onCancel: () => setState(() => _newClient = false),
                ),
              ],
            ],
          ),
        ),
        FieldLabel(
          'Perfil desejado',
          child: TextFormField(
            key: const Key('vacancy-profile'),
            controller: _profile,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  'Requisitos mínimos, senioridade, formação, competências-chave...',
              hintStyle: TextStyle(color: FolksColors.muted, fontSize: 13),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o perfil desejado.'
                : null,
          ),
        ),
        FieldLabel(
          'Responsável',
          child: DropdownButtonFormField<String>(
            initialValue: _assignee,
            isExpanded: true,
            items: VacancyFunnelController.assignees
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (value) => setState(() => _assignee = value!),
          ),
        ),
        FieldLabel(
          'Prazo estimado',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const Key('vacancy-start'),
                    onPressed: () => _pickDate(true),
                    child: Text(
                      'Início: ${_start == null ? '/ /' : shortDate(_start!)}',
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('vacancy-end'),
                    onPressed: () => _pickDate(false),
                    child: Text(
                      'Fim: ${_end == null ? '/ /' : shortDate(_end!)}',
                    ),
                  ),
                ],
              ),
              if (_dateError != null) _ErrorText(_dateError!),
            ],
          ),
        ),
        FieldLabel(
          'Canal de divulgação',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._channels.map(
                    (channel) => FilterChip(
                      label: Text(channel),
                      labelStyle: const TextStyle(color: FolksColors.white),
                      backgroundColor: FolksColors.field,
                      selectedColor: FolksColors.purple,
                      side: const BorderSide(color: FolksColors.border),
                      selected: _selectedChannels.contains(channel),
                      showCheckmark: false,
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedChannels.add(channel);
                        } else {
                          _selectedChannels.remove(channel);
                        }
                        _channelError = null;
                      }),
                    ),
                  ),
                  ActionChip(
                    label: const Text('+ Adicionar'),
                    onPressed: _addChannel,
                  ),
                ],
              ),
              if (_channelError != null) _ErrorText(_channelError!),
            ],
          ),
        ),
        SheetActions(
          primaryLabel: 'Cadastrar Vagas',
          onPrimary: _create,
          onClose: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

class _NewClientForm extends StatefulWidget {
  const _NewClientForm({
    required this.controller,
    required this.onSaved,
    required this.onCancel,
  });
  final VacancyFunnelController controller;
  final ValueChanged<String> onSaved;
  final VoidCallback onCancel;

  @override
  State<_NewClientForm> createState() => _NewClientFormState();
}

class _NewClientFormState extends State<_NewClientForm> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final label in [
      'Empresa',
      'CNPJ',
      'Representante',
      'Contato',
      'Email',
    ])
      label: TextEditingController(),
  };

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final company = _fields['Empresa']!.text.trim();
    widget.controller.addClient(
      VacancyClient(
        company: company,
        cnpj: _fields['CNPJ']!.text.trim(),
        representative: _fields['Representante']!.text.trim(),
        contact: _fields['Contato']!.text.trim(),
        email: _fields['Email']!.text.trim(),
      ),
    );
    widget.onSaved(company);
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: FolksColors.field,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final field in _fields.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                key: ValueKey('client-${field.key}'),
                controller: field.value,
                decoration: InputDecoration(labelText: field.key),
                keyboardType: field.key == 'Email'
                    ? TextInputType.emailAddress
                    : field.key == 'Contato'
                    ? TextInputType.phone
                    : TextInputType.text,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (field.key == 'Empresa') {
                    if (text.isEmpty) return 'Informe a empresa.';
                    if (widget.controller.clients.any(
                      (client) =>
                          client.company.toLowerCase() == text.toLowerCase(),
                    )) {
                      return 'Este cliente já está cadastrado.';
                    }
                  }
                  if (field.key == 'Email' &&
                      text.isNotEmpty &&
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
                    return 'Informe um e-mail válido.';
                  }
                  return null;
                },
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _save,
                child: const Text('Salvar cliente'),
              ),
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancelar cliente'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: const TextStyle(color: FolksColors.red, fontSize: 12),
      ),
    ),
  );
}
