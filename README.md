# Logica PDV

Protótipo desktop para Windows, Delphi 10.3 Rio, VCL e FireDAC/Firebird. Uso em um único computador. Não é uma versão pronta para comercialização.

## Preparar o Firebird e abrir no Delphi

O projeto agora usa **Firebird 3.0**, servidor local via TCP/IP, e FireDAC. Nao usa SQLite. Nao ha conversao automatica de bancos SQLite anteriores. Preserve os dados antigos se existirem.

1. Instale o servidor Firebird **3.0** no Windows a partir de https://firebirdsql.org/en/firebird-3-0/. Defina e guarde sua senha do SYSDBA durante a instalacao. Mantenha o servico Firebird em execucao; nao instale uma segunda instancia na mesma porta se ja houver uma instalada.
2. Em uma ferramenta administrativa compativel, como IBExpert ou FlameRobin, crie um banco vazio de dialect 3 e charset UTF8 em `C:\LogicaPDV\Dados\PDV.fdb`, conectando por `localhost`. A pasta deve existir e a conta do servico Firebird precisa poder gravar nela. O banco e criado pela ferramenta/servidor; nao crie um arquivo vazio no Explorer.
3. Conectado ao novo banco, execute `database/schema.sql` uma unica vez. Ele cria tabelas, indices e a sequencia de vendas. Nao execute novamente em um banco ja inicializado. Nao ha migracoes de esquema implementadas.
4. Abra `LogicaPDV.dpr` em File > Open Project no Delphi 10.3, salve o projeto e selecione **Win32**. Compile com Ctrl+F9. A interface e criada em codigo, sem DFM. VCL e FireDAC com driver Firebird precisam estar instalados.
5. Copie `LogicaPDV.ini.example` para a pasta do executavel (normalmente `Win32\Debug`) e renomeie para `LogicaPDV.ini`. Ajuste `Database` para o caminho do banco e `UserName` para o usuario. Nao grave senha no INI; ela sera solicitada na abertura do programa.
6. Instale o **cliente Firebird 3.0 de 32 bits** e configure `ClientLibrary` no INI com o caminho completo para sua `fbclient.dll`. A DLL precisa ter a mesma arquitetura do aplicativo: Win32 usa cliente x86, mesmo que Windows e servidor sejam x64. Preserve as bibliotecas auxiliares fornecidas pelo instalador do cliente. Tambem e possivel distribuir o conjunto oficial de bibliotecas cliente ao lado do executavel. Nao renomeie `sqlite3.dll` para `fbclient.dll`.
7. Execute com F9 e informe a senha do usuario Firebird no dialogo de conexao.

O banco fica no caminho configurado no servidor local, compartilhado pelos usuarios autorizados do aplicativo. O projeto nao depende de uma unidade de vinculo estatico do SQLite. SYSDBA e adequado para configurar o prototipo; antes de distribuir, crie um usuario proprio com permissoes limitadas. A sequencia de vendas pode ter lacunas apos cancelamentos de transacoes, comportamento normal do Firebird.

## Funcionalidades atuais

- Cadastro de produtos com código único, preço e estoque inicial em unidades inteiras.
- Cadastro de clientes com documento e telefone opcionais.
- Venda por código, inclusão e remoção de itens, cliente opcional e totalização.
- Conferência de estoque considerando os itens repetidos no carrinho.
- Gravação transacional de venda, itens e baixa de estoque.
- Comprovante da última venda da sessão e impressão pelo driver Windows, inclusive PDF quando instalado. A impressão atual é genérica; layout térmico ainda precisa ser implementado.

Valores monetários são armazenados em centavos inteiros. A entrada do preço segue o separador decimal do Windows. O estoque não aceita produtos pesáveis nesta versão. O documento do cliente ainda não tem validação de CPF/CNPJ.

## Validação no computador com Delphi

A compilação Delphi e a impressão não foram executadas no ambiente Linux em que os fontes foram preparados. Execute estes testes antes de utilizar dados reais:

1. Compile em Win32 e abra o programa; confirme a conexão com o banco Firebird previamente criado.
2. Cadastre produto de código `001`, preço `10,50` (Windows pt-BR) e estoque `5`.
3. Cadastre um cliente; inclua duas unidades na venda e confira R$ 21,00.
4. Tente incluir outras quatro unidades: deve recusar sem alterar o carrinho.
5. Remova a linha e confira o total zerado; reinsira duas unidades e finalize.
6. Confira estoque `3`, comprovante e impressão em PDF. Cancele o diálogo de impressão e confirme que a venda permanece gravada.
7. Feche e reabra: produto, cliente e estoque devem persistir. O comprovante da sessão não reaparece; consulta/reimpressão histórica está pendente.
8. Tente código duplicado, nome vazio, quantidade zero e valores negativos: devem ser recusados.

## Antes de comercializar

Implementar e validar: edição dos cadastros, entradas/ajustes de estoque com histórico, formas de pagamento e troco, descontos, consulta/reimpressão e cancelamento de vendas com estorno, identificação do estabelecimento, layout térmico, backup/restauração, migrações do banco, controle de acesso e instalador. Também revisar a proteção dos dados dos clientes e os requisitos fiscais aplicáveis ao uso pretendido. Um comprovante não fiscal não substitui um documento fiscal quando ele é exigido.

Enquanto não houver backup automatizado, use o utilitário oficial `gbak` do Firebird para backup e teste a restauração em outro arquivo. Não copie diretamente um FDB em uso; mantenha as credenciais fora de scripts e do repositório. Não compartilhe o banco com dados de clientes em repositórios.

## Estado de validacao desta alteracao

A troca foi revisada nos fontes e nas consultas SQL. O ambiente de desenvolvimento Linux nao possui Delphi nem Firebird instalado; a compilacao no Delphi 10.3 e a execucao do script no Firebird ainda precisam ser confirmadas. Os testes SQLite anteriores nao validam esta versao Firebird.
