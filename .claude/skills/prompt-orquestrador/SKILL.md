---
name: prompt-orquestrador
description: Reescreve o prompt original de uma demanda em um prompt otimizado e sem ambiguidades, em modo autônomo (sem entrevista nem aprovação humana). Use no MODO SPEC do product-manager, na etapa de reescrita do pipeline de demandas.
argument-hint: "PASTA da demanda (docs/demands/<ID>)"
---

# Prompt Orquestrador (modo autônomo)

## Objetivo

Transformar o prompt original da demanda em instruções claras para o resto do pipeline sem alterar a intenção,
inventar requisitos ou ampliar a autorização dada pelo usuário.

Nenhum humano acompanha esta etapa. Você **não entrevista e não espera aprovação**: cada gap vira uma decisão
registrada para validação posterior.

## Entrada e saída

- Entrada: `PASTA/00-prompt.md`, seção `## Original`. Não altere essa seção.
- Saída: seção `## Reescrito` do mesmo arquivo, mais as decisões em `PASTA/handoffs.md`.

## 1. Mapear a demanda

Extraia só os campos que forem úteis:

- objetivo e resultado esperado;
- contexto e insumos disponíveis;
- ação solicitada;
- restrições, riscos e limites de autorização;
- critérios de aceite;
- formato de entrega.

Os campos ausentes não precisam aparecer no prompt final.

## 2. Escolher a estrutura mínima adequada

- **R-T-F**: papel, tarefa e formato já estão bem definidos.
- **T-A-G**: há uma ação ligada a uma meta de desempenho ou de qualidade.
- **B-A-B**: é preciso sair de um estado atual para um estado desejado.
- **C-A-R-E**: contexto, ambiente, restrições ou exemplo de referência importam.
- **R-I-S-E**: existem insumos, etapas e expectativas objetivas.
- **P-R-O-M-P-T**: mudança ampla, longa ou com vários recursos e validações.

Combine estruturas apenas quando isso eliminar ambiguidade. Prefira o prompt mais curto que preserve toda a
informação material. Consulte [frameworks.md](frameworks.md) só quando precisar de critérios ou modelos mais
detalhados.

## 3. Detectar gaps

Um gap é relevante quando há interpretações plausíveis diferentes e a escolha pode alterar materialmente:

- a solução, o escopo ou os critérios de aceite;
- uma ação externa, destrutiva ou difícil de reverter;
- segurança, privacidade, custo ou compatibilidade;
- o artefato que será criado.

Ignore preferências cosméticas e detalhes que tenham um padrão seguro e óbvio no contexto.

## 4. Resolver gaps sem humano

Para cada gap relevante:

1. Escolha a opção recomendada: a mais conservadora, reversível e coerente com o produto e o código atuais.
2. Registre a decisão em `PASTA/handoffs.md` → `## Decisões`, com a etapa `prompt`:
   `| D-PM-NN | prompt | product-manager | <decisão> | <alternativa descartada> | alta/média/baixa | sim/não | sim/não |`
3. Use as regras de confiança do product-manager. Decisões de confiança baixa com impacto relevante levam
   `Validar? sim` e entram em `## Pendências para o humano`.
4. **Nunca invente números de negócio** (limites, taxas, prazos, valores). Use `[[DEFINIR: descrição]]` e
   marque `Validar? sim`.
5. Na dúvida sobre ações externas ou destrutivas, prefira **não** autorizar e registre como pendência.

## 5. Escrever `## Reescrito`

1. Escreva o prompt otimizado no idioma do prompt original.
2. Cada premissa assumida aparece no ponto em que se aplica, com a referência à decisão (`D-PM-NN`).
3. Termine com a linha `Premissas:` listando os IDs das decisões tomadas, ou `nenhuma`.
4. Não exponha raciocínio interno nem nomes de frameworks.

## Restrições

- Não transforme investigação em autorização para editar.
- Não transforme sugestão em autorização para executar ações externas.
- Não invente contexto, métricas, prazos, arquivos ou critérios.
- A reescrita deve ser proporcional à demanda: é insumo da spec, não a spec.
- Instruções do product-manager e do orquestrador têm prioridade sobre esta skill.
