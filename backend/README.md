# VantoPay — Backend API

API REST (FastAPI) dos serviços financeiros do VantoPay: autenticação, contas,
ledger, PIX, transferências e painel administrativo.

## Instalação

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp ../.env.example .env      # preencha as credenciais
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Documentação interativa: `http://localhost:8000/docs`.

## Testes

```bash
cd backend
pytest -q
```

Os testes cobrem: ledger (dupla entrada, idempotência, solvency), autenticação,
contas, transferências internas (movimentação real), idempotência de transferência,
insuficiência de fundos, PIX (payload, chaves, envio gated), autorização de
administrador, ajustes auditáveis, atividades suspeitas, máscaras de privacidade
e status de integrações.

## Migrações (Supabase/PostgreSQL)

```bash
psql "$DATABASE_URL" -f migrations/sql/001_schema.sql
psql "$DATABASE_URL" -f migrations/sql/002_rls.sql
```

## Endpoints

### Sistema / Integrações
- `GET /health` — status do serviço e integrações.
- `GET /integrations/status` — estado de configuração de cada provedor.
- `GET /integrations/config` — configuração não sensível para o frontend.

### Auth
- `GET /auth/me` — principal autenticado (role).
- `POST /auth/accounts` — abrir conta VantoPay (cria registro + RLS).

### Contas
- `GET /accounts` — dados da conta.
- `GET /accounts/balance` — saldo (calculado pelo ledger).
- `GET /accounts/statement` — extrato (entradas do ledger).
- `GET /accounts/transactions` — movimentações.
- `PATCH /accounts/limits` — atualizar limites.
- `POST /accounts/block` — bloquear conta.
- `POST /accounts/close` — encerrar conta.

### Sessões
- `GET /sessions` — dispositivos ativos.
- `POST /sessions/register` — registrar dispositivo.
- `DELETE /sessions/{id}` — revogar sessão.

### Transferências
- `POST /transfers/internal` — transferência entre contas VantoPay (real,
  idempotente, com detecção de risco).
- `POST /transfers/external` — transferência externa (requer gateway; 503 se
  não configurado).

### PIX
- `POST /pix/keys`, `GET /pix/keys`, `DELETE /pix/keys/{id}`.
- `POST /pix/charges` — criar cobrança (payload PIX Copia e Cola real).
- `GET /pix/charges/{id}` — consultar cobrança.
- `POST /pix/send/key` — enviar por chave (requer provedor).
- `POST /pix/send/payload` — enviar por cópia e cola (requer provedor).
- `GET /pix/history` — histórico PIX.
- `GET /pix/transactions/{id}` — comprovante.

### Administração (admin)
- `GET /admin/accounts`, `GET /admin/accounts/{id}`.
- `POST /admin/accounts/{id}/block|unblock`.
- `POST /admin/accounts/{id}/adjustment` — ajuste auditável via ledger.
- `GET /admin/transactions`.
- `GET /admin/suspicious`, `POST /admin/suspicious/{id}/resolve`.
- `GET /admin/audit-logs`.

## Arquitetura

```
app/
├── main.py            # app FastAPI, CORS, rate limiting, routers
├── config.py          # configuração via ambiente
├── db.py              # engine/session SQLAlchemy
├── models.py          # modelos (mirror do schema SQL)
├── schemas.py         # Pydantic (validação)
├── security.py        # JWT Supabase, máscaras, rate limit, auditoria
├── routers/           # auth, accounts, transfers, pix, sessions, admin, integrations
├── services/          # ledger, accounts, fraud, transactions, pix
└── integrations/      # HyperSwitch, Moov, Formance, Fineract, PIX provider
```
