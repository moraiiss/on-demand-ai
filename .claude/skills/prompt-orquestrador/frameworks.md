# Referência de frameworks

Use esta referência somente quando a escolha do formato não for evidente.

## R-T-F — role, task, format

Use em tarefas técnicas bem definidas com saída padronizada.

```text
Como [papel relevante], [tarefa]. Apresente [formato].
```

Não adicione uma persona quando ela não melhorar a resposta.

## T-A-G — task, action, goal

Use em otimizações ou melhorias com resultado mensurável.

```text
Tarefa: [escopo].
Ação: [o que analisar ou alterar].
Objetivo: [meta verificável].
```

Não invente métricas ausentes; quando a meta for material, use `[[DEFINIR: ...]]` e registre a decisão.

## B-A-B — before, after, bridge

Use em planejamento técnico, migrações ou decisões arquiteturais.

```text
Estado atual: [problema ou situação].
Estado desejado: [resultado].
Estratégia solicitada: [ponte entre os estados].
```

## C-A-R-E — context, action, result, example

Use quando stack, arquitetura, restrições ou precedentes forem essenciais.

```text
Contexto: [ambiente e histórico relevante].
Ação: [trabalho solicitado].
Resultado: [entrega e critérios].
Referência: [exemplo existente, se fornecido].
```

Exemplo é opcional. Nunca fabrique uma referência.

## R-I-S-E — role, input, steps, expectation

Use em tarefas sequenciais com insumos e critérios objetivos.

```text
Papel: [especialidade útil].
Insumos: [fontes e artefatos].
Etapas: [sequência ou limites].
Expectativa: [critérios de aceite].
```

## P-R-O-M-P-T

Use somente em mudanças amplas que exijam vários recursos e validações.

- **Persona**: especialidade relevante.
- **Roteiro**: ação principal.
- **Objetivo**: valor ou resultado esperado.
- **Modelo**: padrão, arquitetura ou referência a seguir.
- **Panorama**: ambiente, convenções e restrições.
- **Transformar**: implementação, validação e entrega final.

Evite preencher componentes redundantes apenas para completar o acrônimo.

## Critério de qualidade

Um prompt otimizado:

- preserva intenção e autorização;
- contém contexto suficiente, não contexto máximo;
- separa tarefa, restrições e critérios verificáveis;
- explicita o formato apenas quando ele importa;
- reduz interpretações materialmente diferentes;
- permanece proporcional à complexidade da solicitação.
