# Arquitetura do VantoPay

## Visão geral

O VantoPay tem três camadas:

1. **Frontend (Flutter)** — UI monocromática, modular por feature.
2. **Backend (FastAPI)** — API REST, autenticação, ledger, PIX, transferências
   e painel administrativo.
3. **Dados (Supabase / PostgreSQL)** — schema, Row Level Security e auditoria.

## Ledger financeiro

O saldo **nunca** é confiado ao frontend nem armazenado como coluna. Ele é
**derivado** das entradas do ledger (dupla entrada, append-only):

- `credit` soma; `debit` subtrai.
- Cada entrada tem `balance_after` (saldo após a operação).
- `idempotency_key` única: repetir a mesma chave retorna a entrada existente e
  **nunca** movimenta dinheiro duas vezes.
- O débito é negado se levaria o saldo abaixo de zero (solvency).

```
conta A ──debit──▶  ledger_entries(A)
conta B ──credit──▶  ledger_entries(B)
         (transferência interna: atomicidade + idempotência)
```

Quando o **Formance** está configurado, o move também é espelhado no ledger
externo; caso contrário, o ledger local é autoritário. Em ambos os casos as
mesmas garantias (idempotência, solvency, auditoria) valem.

## Idempotência e replay

- Cada operação monetária exige uma `idempotency_key` (gerada no app ou fornecida
  pelo cliente).
- A chave é única no `ledger_entries` e no registro de transação.
- O backend ignora chaves duplicadas retornando o resultado original.
- Isso previne cobranças duplicadas em retries de rede.

## Detecção de atividades suspeitas

O serviço `fraud.py` atribui uma pontuação de risco:

- valor incomum vs. histórico recente (+30)
- alta frequência de operações (+20)
- destinatário incomum (+25)
- múltiplas tentativas incorretas (+25)

A pontuação acima do limite (`VANTOPAY_SUSPICION_THRESHOLD`) bloqueia a
movimentação (HTTP 423) e registra um `SuspiciousEvent`.

## PIX

- **Receber:** gera um payload PIX Copia e Cola real (EMV QR Code, CRC-16/CCITT)
  compatível com o padrão do Banco Central. O recebimento do valor é confirmado
  pela instituição autorizada.
- **Enviar:** executado apenas quando um provedor PIX está configurado; o
  débito no ledger acontece somente após a confirmação do gateway.
- **Privacidade:** documentos mascarados, remetente exibido apenas quando
  disponibilizado pela instituição.

## Integrações

Todas as integrações seguem o mesmo contrato em `integrations/`:

```dart
class BaseIntegration {
  bool get isConfigured;            // credenciais presentes?
  void _require();                  // lança IntegrationNotConfigured
  IntegrationStatus status();
}
```

Se `isConfigured == false`, a operação levanta `IntegrationNotConfigured` e a
API responde **503** com uma mensagem clara — nunca simula dados.
