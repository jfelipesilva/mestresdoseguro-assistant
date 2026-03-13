# ClearVeico (Veico) — Prompt Instructions para Cotador

## Informações do Sistema
- **URL**: `consultor.veico.com.br/uniauto`
- **Login**: email + senha (sem captcha)
- **Tipo**: Sistema de Proteção Veicular (não é seguradora tradicional)

## Fluxo Completo de Cotação

### 1. Login
1. Navegar para `{system_url}` (ex: `https://consultor.veico.com.br/uniauto`)
2. A página de login tem dois campos:
   - Campo "Email" (textbox)
   - Campo "Senha" (textbox)
3. Preencher com `{login_username}` e `{login_password}`
4. Clicar no botão "Entrar"
5. Aguardar redirecionamento para o painel (URL contém `/dashboard` ou `/home`)

### 2. Acessar Nova Proposta
1. Navegar diretamente para `{system_url}/proposals/create`
   - Alternativa: clicar no menu "Propostas" e depois no botão "Nova Proposta"
2. Aguardar o formulário carregar (3 seções: Dados do veículo, Selecione o Plano, Dados pessoais)

### 3. Preencher Dados do Veículo

#### 3.1. Tentar busca por placa (quando disponível)
1. Digitar a placa no campo "Placa do veículo" (textbox)
2. Clicar no botão de busca (ícone de lupa ao lado do campo)
3. Aguardar resultado:
   - **Se encontrou**: os campos Tipo, Ano e Modelo são preenchidos automaticamente. Prossiga para o passo 4.
   - **Se "Placa não encontrada!"**: preencher manualmente conforme passo 3.2.

#### 3.2. Preenchimento manual (quando placa não é encontrada)
1. **Tipo** (combobox): Selecionar o tipo do veículo
   - Opções disponíveis: `Carro`, `Moto`, `Caminhão`, `Moto Elétrica`
   - Para automóveis, selecionar `Carro`
2. **Ano** (combobox, habilitado após selecionar Tipo): Selecionar o ano modelo do veículo
   - Opções: `Zero Km`, `2027` até `1981`
   - Usar o **ano modelo** (não ano de fabricação). Ex: veículo 2016/2017 → selecionar `2017`
3. **Modelo** (combobox, habilitado após selecionar Ano):
   - O combobox suporta digitação para filtrar — digite parte do nome do modelo para filtrar a lista
   - Exemplo: digitar "Gol" filtra todos os modelos Gol
   - Selecionar o modelo exato que corresponde ao veículo
   - Os modelos seguem o padrão FIPE: `{Nome} {Motor} {Combustível} {Portas}`
   - Exemplo: `Gol Trendline 1.0 T.Flex 12V 5p`

4. **Uso comercial** (switch): Manter desligado, a menos que o veículo seja táxi, Uber, entregas etc.

Após selecionar o modelo, o sistema exibe automaticamente um card com:
- Marca (ex: VW - VolksWagen)
- Categoria (Nacional/Importado)
- Combustível (Flex/Gasolina/Diesel)
- Código FIPE
- Valor FIPE

### 4. Selecionar o Plano

Após preencher os dados do veículo, a seção "Selecione o Plano" mostra os planos disponíveis automaticamente.

1. **Estado** (combobox): Já vem preenchido com base na localização do consultor. Alterar se o associado for de outro estado.
2. **Cidade** (combobox): Já vem preenchida. Alterar se necessário.
3. Se mudou estado/cidade, clicar em "Buscar Planos" para atualizar os planos.
4. Os planos aparecem como cards, cada um com:
   - Nome do plano (ex: "Plano Master Nacional - 5%", "Plano Master Nacional - 7%")
   - Valor base mensal (ex: R$ 176,60, R$ 160,90)
   - Tabela de Preço (combobox dentro do card)
   - Serviços incluídos (ícones numéricos)
   - Botão "Selecionar"
5. **Selecionar o plano com menor mensalidade** (ou conforme instrução da solicitação)
   - O percentual (5%, 7%) refere-se à cota de participação em caso de sinistro
   - Maior percentual = menor mensalidade
6. Clicar em "Selecionar" no card do plano escolhido
   - O botão muda para "Selecionado" (disabled) confirmando a seleção

### 5. Preencher Dados Pessoais

1. **Nome Completo** (textbox, obrigatório): Nome do associado/segurado
2. **Telefone/Whatsapp** (textbox, obrigatório): Telefone com DDD (o sistema formata automaticamente)
3. **E-mail** (textbox, opcional): Email do associado
4. **Origem da proposta** (combobox, obrigatório):
   - Opções: `Indicação`, `Prospecção`, `Tráfego Pago`
   - Selecionar `Indicação` como padrão

### 6. Gerar Proposta

1. Clicar no botão "Gerar Proposta" (habilitado quando todos os campos obrigatórios estão preenchidos)
2. Aguardar processamento (os campos ficam disabled e aparece um spinner)
3. O sistema redireciona para a página de edição da proposta: `/proposals/{uuid}/edit`
4. A proposta recebe um número (ex: #15436)

### 7. Capturar Resultado

Após o redirecionamento para a página da proposta, capturar os seguintes dados:

**Dados da proposta visíveis na página:**
- **Número da proposta**: no título da página (ex: "Proposta #15436")
- **Status**: "Negociação" (status inicial)
- **Plano selecionado**: Nome e valor (ex: "Plano Master Nacional - 7%", R$ 160,90)
- **Valor protegido** (FIPE): campo disabled (ex: R$ 39.967,00)
- **Cota de participação**: percentual (ex: 7,00%)
- **Adesão**: valor de adesão (ex: R$ 350,00)
- **Data de vencimento**: dia do mês (ex: 15)
- **Valor médio mensal**: valor final mensal (ex: R$ 160,90)

**Alerta importante**: O sistema exibe "Atualize os dados da Placa ou Chassi para garantir a sua proposta." — isso é esperado quando a placa não foi encontrada na busca inicial.

**Benefícios adicionais disponíveis** (switches, todos desligados por padrão):
- D - 1: -R$ 10,00
- Média Mensal: +R$ 10,00
- Rastreador Adicional: +R$ 29,90
- Assistência Profissional 1: +R$ 10,00
- Assistência Profissional 2: +R$ 20,00
- Assistência Profissional 3: +R$ 30,00
- Uni Médicos - 01 Dependente: +R$ 9,90
- Uni Médicos - 03 Dependentes: +R$ 19,90
- Uni Médicos - 05 Dependentes: +R$ 39,70

Não ativar benefícios adicionais a menos que a solicitação peça.

### 8. Baixar PDF da Cotação

1. Na página da proposta (após gerar), na seção "Compartilhe a cotação" há 2 botões:
   - **Primeiro botão** (ícone PDF amarelo): Abre o preview do PDF em nova aba
   - **Segundo botão** (ícone copiar): Copia o link da proposta para clipboard
2. Clicar no **primeiro botão** (ícone PDF amarelo)
3. Uma nova aba abre com a URL: `{system_url}/proposals/{uuid}/preview`
   - O `{uuid}` é o mesmo da URL da proposta (ex: `a145173d-ce34-4d88-9cad-3eb546f61e57`)
4. Essa aba exibe um visualizador de PDF com a cotação completa (6 páginas)
5. Para baixar o PDF, use o comando `pdf` do browser nessa aba:
   ```
   openclaw browser pdf
   ```
6. Alternativamente, pode navegar diretamente para a URL de preview:
   ```
   openclaw browser navigate {system_url}/proposals/{uuid}/preview
   openclaw browser pdf
   ```
7. Fechar a aba de preview e voltar para a aba da proposta após baixar

### 9. Montar Resultado para API

Após capturar os dados, montar o `result_data`:

```json
{
  "propostas": [
    {
      "numero_proposta": "#15436",
      "plano": "Plano Master Nacional - 7%",
      "valor_mensal": 160.90,
      "valor_protegido": 39967.00,
      "cota_participacao": "7%",
      "adesao": 350.00,
      "vencimento_dia": 15,
      "codigo_fipe": "005455-0",
      "modelo_fipe": "Gol Trendline 1.0 T.Flex 12V 5p",
      "status": "Negociação"
    }
  ],
  "resumo": "Proposta #15436 gerada com sucesso no ClearVeico. Plano Master Nacional - 7% com mensalidade de R$ 160,90. Valor protegido: R$ 39.967,00. Adesão: R$ 350,00."
}
```

## Observações Importantes

1. **Sem CAPTCHA**: O sistema não possui captcha no login.
2. **Busca por placa**: Pode não encontrar todas as placas. Quando não encontrar, preencher Tipo/Ano/Modelo manualmente.
3. **Ano modelo vs fabricação**: Sempre usar o ANO MODELO (segundo ano no par fabricação/modelo).
4. **Filtro de modelo**: O combobox de Modelo aceita digitação para filtrar — usar isso para encontrar rapidamente o modelo correto.
5. **Planos variam por região**: Estado e cidade influenciam os planos disponíveis e valores.
6. **Plano mais barato**: Geralmente o plano com maior percentual de cota de participação tem menor mensalidade.
7. **Benefícios adicionais**: Não ativar a menos que solicitado especificamente.
8. **Proposta é editável**: Após criada, a proposta fica em "Negociação" e pode ser editada.
9. **Compartilhamento**: A página da proposta tem botões para compartilhar via WhatsApp e copiar link.
10. **Campos obrigatórios para gerar proposta**: Nome, Telefone, Origem da proposta, Tipo, Ano, Modelo e um plano selecionado.
