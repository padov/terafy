# Arquitetura de Modelos: Common vs App

Este documento explica a decisão arquitetural de manter modelos separados nas camadas `common` e `app` do projeto, detalhando os benefícios dessa abordagem para a manutenibilidade e escalabilidade do Terafy.

## Estrutura Atual

O projeto utiliza dois conjuntos de modelos para a mesma entidade (ex: `Session`):

1.  **DTO (Data Transfer Object)**

    - **Localização:** `common/lib/src/models/session.model.dart`
    - **Propósito:** Definir o **contrato de dados** puro compartilhado entre Backend (Dart Frog) e Frontend (Flutter).
    - **Características:**
      - Usa tipos primitivos ou simples (ex: `String` para status).
      - Focado em serialização (JSON).
      - Não contém regras de negócio complexas.
      - Garante que Server e App falem a mesma língua.

2.  **Modelo de Domínio**

    - **Localização:** `app/lib/features/sessions/models/session.dart`
    - **Propósito:** Representar a entidade dentro da **lógica do aplicativo Mobile**.
    - **Características:**
      - Usa **Enums** (`SessionStatus`, `PaymentStatus`) para segurança de tipos.
      - Implementa **Imutabilidade** (`copyWith`) para gerenciamento de estado seguro.
      - Estende **`Equatable`** para otimizar a renderização no Flutter (Bloc).
      - Pode conter lógica auxiliar (ex: getters computados).

3.  **Camada Mapper**
    - **Localização:** `app/lib/features/sessions/models/session_mapper.dart`
    - **Propósito:** Atuar como ponte tradutora entre o DTO e o Modelo de Domínio.

## Por que manter essa separação?

Embora pareça código duplicado (_boilerplate_) à primeira vista, essa estrutura atua como uma **Camada de Proteção (Anti-Corruption Layer)** essencial para aplicativos mobile.

### 1. Problema da Atualização de Apps

Diferente da Web, onde um deploy atualiza todos os usuários instantaneamente, em Mobile temos **várias versões do App rodando simultaneamente** (v1.0, v1.1, v2.0).

### 2. Blindagem contra Mudanças (Contract Safety)

Se o Backend precisar alterar um campo (ex: mudar `status` de "scheduled" para "CONFIRMED" ou trocar o tipo de String para Int):

- **Sem a separação:** O App quebra em tempo de execução. Telas, Blocs e testes falham pois dependem diretamente do formato da API.
- **Com a separação:**
  1.  O `common` é atualizado (Contrato muda).
  2.  O `Mapper` acusa erro ou é ajustado para traduzir o novo formato para o formato antigo que o App já conhece.
  3.  **O resto do App permanece intacto.** A lógica de UI e Estado continua usando os Enums e classes estáveis do domínio.

### 3. Independência de Implementação

O Modelo de Domínio (`app/models`) permite que o Flutter use recursos específicos da linguagem/framework (como `Equatable` e Enums ricos) sem sujar o contrato de dados puro do Backend.

### Resumo

- **Common:** Garante que Server e App tenham um contrato único (Single Source of Truth) em tempo de compilação.
- **App Model + Mapper:** Protege o aplicativo de mudanças na API e oferece ferramentas melhores (State Management, Type Safety) para o desenvolvimento da UI.
