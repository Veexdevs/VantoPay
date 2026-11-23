# Segurança do VantoPay

A segurança é prioridade absoluta. Os controles implementados:

## Autenticação e autorização

- **Supabase Auth** valida o token (HS256) no backend com `SUPABASE_JWT_SECRET`.
- O backend resolve o papel (user/admin) a partir da conta, nunca do frontend.
- Rotas protegidas por dependências (`get_current_principal`, `require_admin`).
- Login apenas com **Google** e **e-mail** (sem Facebook/telefone/outras redes).

## Dados e transações

- **Ledger de dupla entrada** — saldos derivados server-side; o frontend nunca
  define saldos.
- **Idempotência** — chaves únicas impedem duplicação/replay.
- **Solvência** — débitos não levam o saldo abaixo de zero.
- **Máscaras de privacidade** — CPF/CNPJ mascarados em repouso e em respostas;
  dados sensíveis nunca expostos desnecessariamente.
- **Criptografia** — tokens de sessão armazenados apenas como hash (SHA-256).

## Banco de dados

- **Row Level Security** ativada em todas as tabelas (`002_rls.sql`).
- Políticas restritas ao owner autenticado; administradores via `is_admin`.
- O Service Role (backend) é o único caminho de escrita; a anon key nunca escreve.
- Proteção contra SQL Injection via SQLAlchemy/ORM.
- Trigger de auditoria no ledger (defesa em profundidade).

## API

- **HTTPS** obrigatório em produção.
- **Rate limiting** por cliente/rota (janela deslizante) — `VANTOPAY_RATE_LIMIT_PER_MINUTE`.
- **Validação de entradas** com Pydantic (tipos, limites, documentos).
- **Detecção de atividades suspeitas** com pontuação de risco e bloqueio.
- **Logs de auditoria** para abertura, bloqueio, encerramento, ajustes e sessões.

## Controle de sessões e dispositivos

- Registro de dispositivos ativos (`/sessions`).
- Revogação de sessões individuais.
- TTL de sessão configurado (`VANTOPAY_SESSION_TTL_MINUTES`).

## Administração

- Painel restrito a administradores.
- **Saldos só mudam por operações financeiras auditáveis** (`/adjustment`),
  nunca por escrita direta.
- Bloqueio/liberação de contas registrado em log de auditoria.

## Segredos

- **Nenhum** Service Role Key, senha administrativa, chave privada ou segredo em
  arquivos públicos ou no repositório.
- Credenciais via `.env` (local) e **GitHub Secrets / Vercel encrypted
  variables** (produção).
- `.env.example` documenta apenas os nomes das variáveis.

## Backup e monitoramento

- Backup do banco via Supabase.
- `audit_logs` e `suspicious_events` permitem monitorar atividades suspeitas.
