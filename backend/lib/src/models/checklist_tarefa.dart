class ChecklistTarefa {
  int _checklistsIdChecklist;
  int _tarefasIdTarefa;

  ChecklistTarefa({
    required int checklistsIdChecklist,
    required int tarefasIdTarefa,
  }) : _checklistsIdChecklist = checklistsIdChecklist,
       _tarefasIdTarefa = tarefasIdTarefa;

  int get checklistsIdChecklist => _checklistsIdChecklist;
  set checklistsIdChecklist(int value) => _checklistsIdChecklist = value;

  int get tarefasIdTarefa => _tarefasIdTarefa;
  set tarefasIdTarefa(int value) => _tarefasIdTarefa = value;
}
