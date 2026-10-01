---
name: demanda
description: Despacha uma nova demanda para o pipeline PM → Staff → SWE em uma sessão de background isolada (worktree próprio). Use quando o usuário digitar /demanda seguido da descrição.
disable-model-invocation: true
allowed-tools: Bash(demanda *)
argument-hint: "[--sem-gate] [--nome slug] descrição da demanda"
---

Execute com a ferramenta Bash, a partir da raiz do repositório:

```
demanda $ARGUMENTS
```

Mostre ao usuário apenas o ID da demanda e o comando de acompanhamento que o script imprimir.
Não faça mais nada nesta sessão: o trabalho acontece na sessão de background.
