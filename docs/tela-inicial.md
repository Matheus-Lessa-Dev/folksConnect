# Tela inicial

O quadro **Tela Inicial** do Figma Folks Mobile é a referência para a disposição dos indicadores, prioridades e atalhos. A tela usa o tema, as fontes, a marca original e a barra de navegação já usados nas demais abas.

- `/inicio` é a página padrão após o login. Links diretos autenticados preservam a aba solicitada.
- A saudação recebe o nome por `HomeScreen.userName`; como o login de demonstração ainda não retorna um perfil, aparece `Olá, ---!`.
- Os indicadores usam as tarefas do Kanban: tarefas abertas com vencimento hoje, abertas atrasadas, total pendente e percentual de entregas concluídas no prazo. Sem entregas registradas, o percentual aparece como `—`.
- As prioridades exibem até três tarefas pendentes na ordem de cadastro mais recente, independentemente do filtro atual do Kanban. Clicar na seção ou em um cartão abre o mesmo Kanban da barra inferior.
- Funil de Vagas abre `/funil-vagas`. O cartão Desempenho permanece visível sem ação.
