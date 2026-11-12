# Dashboard

O botão laranja central abre `/dashboard`. A rota usa a proteção de
autenticação das demais abas e compartilha o `KanbanController` da sessão.

- **Atividades alocadas:** tarefas abertas por etapa atual (Triagem,
  Entrevista, Retorno e Contratação), sem depender do filtro do Kanban.
- **Entregas:** todas as tarefas que estão em Concluído. O gráfico usa o
  dia real da conclusão e separa entregas no prazo das atrasadas, por
  semana (últimos sete dias, incluindo hoje) ou últimos 30 dias.
- Alterar uma tarefa concluída preserva a data original. Reabrir remove a
  entrega; concluir de novo registra uma nova data. Tarefas concluídas
  sem data aparecem no total e na lista, sem data inventada no gráfico.

O painel usa os dados locais do Kanban atual. Não há persistência de
tarefas ou endpoint de dashboard nesta versão.
