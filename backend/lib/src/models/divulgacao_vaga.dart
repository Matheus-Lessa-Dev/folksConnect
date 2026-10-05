class DivulgacaoVaga {
  int _divulgacoesIdDivulgacao;
  int _vagasIdVaga;

  DivulgacaoVaga({
    required int divulgacoesIdDivulgacao,
    required int vagasIdVaga,
  }) : _divulgacoesIdDivulgacao = divulgacoesIdDivulgacao,
       _vagasIdVaga = vagasIdVaga;

  int get divulgacoesIdDivulgacao => _divulgacoesIdDivulgacao;
  set divulgacoesIdDivulgacao(int value) => _divulgacoesIdDivulgacao = value;

  int get vagasIdVaga => _vagasIdVaga;
  set vagasIdVaga(int value) => _vagasIdVaga = value;
}
