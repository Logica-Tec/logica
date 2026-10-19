# Logica PDV

Protótipo desktop para Windows, Delphi 10.3 Rio, VCL e FireDAC/SQLite. Uso em um único computador. Não é uma versão pronta para comercialização.

## Abrir no Delphi

1. Abra `LogicaPDV.dpr` em File > Open Project no Delphi 10.3.
2. Salve o projeto para o Delphi gerar seu `.dproj`. Selecione Windows 32-bit inicialmente.
3. Compile com Build e execute. A interface é criada em código, sem arquivos DFM.
4. É necessária uma edição/instalação com VCL e FireDAC SQLite disponíveis. A unidade `FireDAC.Phys.SQLiteWrapper.Stat` seleciona o vínculo estático do SQLite fornecido pelo Delphi. Se essa unidade não estiver disponível, confira os componentes instalados e o Library Path; não baixe DLLs de sites desconhecidos.

O banco é criado automaticamente em `%LOCALAPPDATA%\LogicaPDV\pdv.sqlite`. Não requer servidor. Cada usuário Windows tem um banco independente. Não há migração de esquema implementada; preserve bancos reais antes de alterar a estrutura.

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

1. Compile em Win32 e abra o programa; confirme a criação do banco.
2. Cadastre produto de código `001`, preço `10,50` (Windows pt-BR) e estoque `5`.
3. Cadastre um cliente; inclua duas unidades na venda e confira R$ 21,00.
4. Tente incluir outras quatro unidades: deve recusar sem alterar o carrinho.
5. Remova a linha e confira o total zerado; reinsira duas unidades e finalize.
6. Confira estoque `3`, comprovante e impressão em PDF. Cancele o diálogo de impressão e confirme que a venda permanece gravada.
7. Feche e reabra: produto, cliente e estoque devem persistir. O comprovante da sessão não reaparece; consulta/reimpressão histórica está pendente.
8. Tente código duplicado, nome vazio, quantidade zero e valores negativos: devem ser recusados.

## Antes de comercializar

Implementar e validar: edição dos cadastros, entradas/ajustes de estoque com histórico, formas de pagamento e troco, descontos, consulta/reimpressão e cancelamento de vendas com estorno, identificação do estabelecimento, layout térmico, backup/restauração, migrações do banco, controle de acesso e instalador. Também revisar a proteção dos dados dos clientes e os requisitos fiscais aplicáveis ao uso pretendido. Um comprovante não fiscal não substitui um documento fiscal quando ele é exigido.

Enquanto não houver backup automatizado, faça cópia do banco com o aplicativo completamente fechado para um local seguro e teste a restauração com uma cópia. Não compartilhe o banco com dados de clientes em repositórios.
