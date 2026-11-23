# VantoPay — Banco Digital

VantoPay é um banco digital multiplataforma (Web, Android, iOS, Windows) com
identidade visual **totalmente preta e branca**, minimalista e premium. A
arquitetura é preparada para um banco digital real: autenticação via Supabase,
ledger financeiro de dupla entrada, sistema PIX, transferências, painel
administrativo e integração com infraestrutura financeira open-source.

> **Princípio de honestidade funcional:** nenhuma funcionalidade é simulada.
> Cada integração financeira externa (gateway, provedor PIX, ledger externo) é
> uma camada preparada que exige credenciais; quando não configurada, o sistema
> informa claramente que a funcionalidade depende de uma integração externa,
> sem inventar saldos, transações ou comprovantes.

---

## 1. Identidade visual

- Preto e branco total, sem cores acessórias.
- Design minimalista, aspecto de banco digital premium.
- Hierarquia expressa por peso, opacidade, espaçamento e geometria.
- Animações suaves, bordas arredondadas moderadas, ícones minimalistas.
- A logo oficial do VantoPay (anexada) é a identidade visual do app, vendida em
  `flutter_app/assets/logos/official_*.png`. **Nenhuma logo adicional foi criada
  nem a identidade fornecida foi modificada.**

## 2. Arquitetura

```
┌──────────────────────────────────────────────────────────────────────┐
│  Flutter App (multiplataforma: Web / Android / iOS / Windows)         │
│  flutter_app/lib/                                                    │
│   core/ (theme, router, config, utils)                                │
│   data/ (models, services: Supabase Auth, API, PIX, transfers, admin) │
│   features/ (auth, home, pix, transfers, accounts, admin)             │
│   widgets/ (componentes monocromáticos)                               │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ REST (HTTPS) + Supabase Auth (OAuth/e-mail)
┌───────────────────────────────▼──────────────────────────────────────┐
│  Backend API (FastAPI)  backend/app/                                 │
│   routers: auth, accounts, transfers, pix, sessions, admin, integ.   │
│   services: ledger (dupla entrada), fraud, accounts, transactions     │
│   integrations: HyperSwitch, Moov, Formance, Fineract, PIX provider   │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│  PostgreSQL (Supabase) + RLS  backend/migrations/sql/                │
│   schema, políticas de Row Level Security, triggers de auditoria      │
└──────────────────────────────────────────────────────────────────────┘
```

### Projetos open-source integrados

| Propósito | Projeto | Integração |
|---|---|---|
| Core banking | [apache/fineract](https://github.com/apache/fineract) | `backend/app/integrations/providers.py` → `FineractClient` |
| Payment gateway | [juspay/hyperswitch](https://github.com/juspay/hyperswitch) | `HyperswitchClient` |
| Financial ledger | [formancehq/ledger](https://github.com/formancehq/ledger) | `FormanceClient` (ledger externo opcional) |
| Payment infrastructure | [moov-io/moov-io](https://github.com/moov-io/moov-io) | `MoovClient` |
| Authentication reference | [keycloak/keycloak](https://github.com/keycloak/keycloak) | Padrão de sessões/OAuth replicado via Supabase Auth |
| Backend & database | [supabase/supabase](https://github.com/supabase/supabase) | Auth + PostgreSQL + RLS |

## 3. Estrutura do repositório

```
.
├── flutter_app/                 # App multiplataforma (Flutter)
│   ├── lib/
│   │   ├── core/               # theme, router, config, utils
│   │   ├── data/models/        # modelos de domínio
│   │   ├── data/services/      # supabase, api, account, pix, transfer, admin
│   │   ├── features/           # telas (auth, home, pix, transfers, accounts, admin)
│   │   ├── widgets/            # componentes compartilhados
│   │   ├── app.dart, main.dart
│   ├── assets/logos/           # logo oficial do VantoPay
│   ├── test/                   # testes widget/unit
│   ├── pubspec.yaml, vercel.json
├── backend/                     # API REST (FastAPI)
│   ├── app/                    # routers, services, integrations, schemas, security
│   ├── migrations/sql/         # schema + RLS (Supabase/PostgreSQL)
│   ├── tests/                  # testes pytest (25 casos)
│   └── requirements.txt
├── .github/workflows/          # web.yml, android.yml, ios.yml, windows.yml
├── .env.example
└── docs/
```

## 4. Pré-requisitos

- Flutter 3.24.x (Dart 3.5)
- Python 3.11+
- Node.js 18+ (para deploy Vercel)
- Uma conta Supabase

## 5. Instalação

### 5.1 Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp ../.env.example .env      # e preencha as credenciais
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API documentada em `http://localhost:8000/docs`.

Execute os testes:

```bash
cd backend
pytest -q
```

### 5.2 App Flutter

```bash
cd flutter_app
flutter pub get

# Injete as credenciais no build (--dart-define)
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY \
  --dart-define=VANTOPAY_API_URL=http://localhost:8000
```

## 6. Configuração de cada serviço

Todas as variáveis estão em `.env.example`. **Use GitHub Secrets e variáveis
protegidas do Vercel para os valores privados. Nunca commite credenciais.**

### Supabase (Auth + Banco)

1. Crie um projeto em <https://supabase.com>.
2. Em **Authentication → Providers**, ative **Google** e configure o OAuth.
3. Em **Authentication → URL Configuration**, adicione os redirect URIs.
4. Em **API**, copie `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_SERVICE_ROLE_KEY`.
5. Em **API → JWT secret**, copie `SUPABASE_JWT_SECRET` (usado pelo backend para
   validar o token).
6. Execute as migrações:

```bash
psql "$DATABASE_URL" -f backend/migrations/sql/001_schema.sql
psql "$DATABASE_URL" -f backend/migrations/sql/002_rls.sql
```

### Login / Cadastro (Supabase Auth)

- **Continuar com Google** e **Entrar com e-mail** — implementados.
- Cadastro, recuperação de senha, verificação de e-mail, sessão persistente e
  logout — via Supabase Auth.
- O backend valida o JWT do Supabase e provisiona a conta VantoPay.
- **Não há** login com Facebook, telefone ou outras redes.

### Backend API

- `VANTOPAY_API_URL` — URL base usada pelo app.
- `DATABASE_URL` — PostgreSQL (Supabase) em produção; SQLite localmente.

### Gateway de pagamento (HyperSwitch)

Preencha `HYPERSWITCH_URL`, `HYPERSWITCH_API_KEY`, `HYPERSWITCH_MERCHANT_ID`.
Até que estejam definidos, **Pagar** e **Transferência externa** informam que
dependem da integração (HTTP 503) — nada é simulado.

### Infraestrutura de pagamento (Moov)

`MOOV_BASE_URL`, `MOOV_TOKEN`.

### Ledger financeiro (Formance)

`FORMANCE_BASE_URL`, `FORMANCE_API_KEY`. O ledger local (dupla entrada) já é
autoritário; o Formance é usado como espelho opcional quando configurado.

### Core banking (Fineract)

`FINERACT_BASE_URL`, `FINERACT_USERNAME`, `FINERACT_PASSWORD`.

### Provedor PIX

`PIX_PROVIDER_BASE_URL`, `PIX_PROVIDER_TOKEN`. O envio de PIX só é executado
quando um provedor autorizado está configurado. A **cobrança (receive)** já
gera um payload PIX Copia e Cola real (EMV/CRC-16); o recebimento do valor é
confirmado pela instituição.

## 7. Funcionalidades

- **Home:** saudação, saldo (ocultar/mostrar), botões PIX, Transferir,
  Depositar, Pagar, últimas movimentações, extrato, acesso ao perfil.
- **PIX:** enviar, receber (QR Code + cópia e cola), criar/consultar chaves,
  por chave, por QR Code, cópia e cola, histórico e comprovantes.
- **Privacidade PIX:** CPF/CNPJ mascarados, dados sensíveis mascarados,
  remetente exibido apenas quando disponibilizado pela instituição.
- **Contas:** criação, perfil, saldo (calculado pelo ledger), histórico,
  extrato, limites, configurações, bloqueio e encerramento.
- **Transferências:** internas (movimentação real no ledger), externas
  (integração), confirmação, comprovantes, validação de saldo e **idempotência**.
- **Painel administrativo:** usuários, contas, transações, movimentações,
  bloqueios, atividades suspeitas, logs e configurações. Saldos só mudam por
  operações financeiras auditáveis no ledger.

## 8. Segurança

- Row Level Security no Supabase (`002_rls.sql`).
- Autenticação Supabase + autorização no backend (roles: user/admin).
- HTTPS, validação de entradas (Pydantic), proteção contra SQL Injection
  (ORM/SQLAlchemy).
- Rate limiting, proteção contra força bruta (janela deslizante), detecção de
  atividades suspitas (pontuação de risco).
- Idempotência (chaves únicas no ledger) e proteção contra replay.
- Criptografia de dados sensíveis: documentos são mascarados em repouso;
  session tokens são armazenados apenas como hash.
- Logs de auditoria; backup via Supabase; **nenhuma credencial no código**.
- Service Role Key **nunca** no frontend; chaves privadas **nunca** no GitHub.

## 9. Versões e compilação (CI/CD)

Workflows separados em `.github/workflows/`:

| Workflow | Resultado | Plataforma |
|---|---|---|
| `web.yml` | Web build + deploy automático na **Vercel** | Web |
| `android.yml` | APK assinado de release | Android |
| `ios.yml` | IPA assinado (runner macOS, certificado Apple) | iOS |
| `windows.yml` | EXE + pacote de distribuição | Windows |

A publicação na Vercel é independente das compilações dos apps.

### Secrets necessários

- **Vercel:** `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
- **Android:** `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`
- **iOS:** `IOS_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD`,
  `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_DEVELOPMENT_TEAM`

## 10. Documentação adicional

- `docs/architecture.md` — detalhes da arquitetura e do ledger.
- `docs/security.md` — controles de segurança.
- `backend/README.md` — instalação e endpoints da API.

## 11. Resultado final

Um VantoPay funcional, com arquitetura preparada para um banco digital real.
Todos os botões possuem funcionalidades realísicas ou apresentam claramente que
dependem de uma integração externa ainda não configurada. **Não há simulação de
transferências, saldos, comprovantes ou confirmações bancárias.**
