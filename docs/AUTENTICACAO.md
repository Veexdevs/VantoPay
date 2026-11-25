# Autenticação VantoPay

## Arquitetura

A interface continua em Dart/Flutter. `/api/auth` é uma função **server-side Node na Vercel**, necessária para usar SMTP e credenciais administrativas sem incluí-las no bundle Flutter.

- E-mail/senha: o servidor autentica com Supabase. Cadastro usa `display_name` e não confirma a conta antes do código.
- Cadastro e primeiro acesso em um navegador: o servidor envia automaticamente um código pelo Gmail `vantopay.app@gmail.com`, host `smtp.gmail.com`, porta **587**, **STARTTLS obrigatório**, TLS >= 1.2 e validação de certificado.
- Código criptograficamente aleatório (`crypto.randomInt`), exatamente **6 dígitos**, válido por **5 minutos**. Banco guarda apenas HMAC com segredo server-side. Cinco tentativas; consumo e contagem atômicos com bloqueio de linha. Reenvio invalida códigos anteriores; intervalo mínimo de 60 segundos e máximo de 10 envios/hora/usuário. Limites adicionais de IP e e-mail persistem no banco, não na memória da função.
- Sessão pendente não concede sessão VantoPay. Somente após confirmação o servidor cria o cookie de sessão e registra um dispositivo confiável. Cookies `__Host-`, `Secure`, `HttpOnly`, `SameSite=Strict`; sessão/continuação criptografadas e autenticadas com AES-256-GCM.
- Dispositivo significa este perfil de navegador, identificado por token aleatório de 256 bits em cookie, com validade de **30 dias**. Banco guarda só o hash. Novo navegador, janela anônima, limpeza de cookies ou expiração exigem novo código. Não se usa fingerprint nem um booleano de localStorage.
- Entrada com Google também passa pela confirmação do dispositivo. Tokens do retorno OAuth são trocados por sessão server-side independente; o SDK limpa a sessão OAuth local depois da troca. E-mail/senha nunca retornam tokens Supabase ao Flutter.
- O servidor revalida sessão Supabase e dispositivo no restabelecimento. Mutações exigem origem HTTPS exata e JSON; não há CORS aberto. Respostas não são cacheadas; erros não registram códigos, tokens ou senhas.

**Regra para novas funcionalidades protegidas:** passar pelo backend e exigir sessão + dispositivo verificados, como no fluxo `status`. Não autorizar acesso só com um JWT Supabase ou com o estado visual Flutter. Este projeto compartilha o Supabase com outro app: essa verificação é do VantoPay, não uma política global de MFA do Supabase. Ainda não existem endpoints financeiros/dados privados neste app. Não reutilizar a service role para consultas sem autorização por usuário.

## Variáveis do servidor

Configurar pelo painel seguro da Vercel (nunca no Git/chat):

- `SUPABASE_URL` e `SUPABASE_ANON_KEY`: também usados pelo Flutter, são públicos.
- `SUPABASE_SERVICE_ROLE_KEY`: servidor apenas.
- `SMTP_USER`: conta Gmail remetente.
- `SMTP_PASS`: senha de aplicativo Gmail (não a senha normal da conta).
- `OTP_PEPPER`: segredo aleatório >= 32 bytes; usado em HMAC e derivação da chave dos cookies. Rotacionar encerra sessões, desafios e confiança anteriores.

O build só passa URL/chave pública ao Dart. Os outros valores nunca devem virar `--dart-define`. A senha enviada em conversa deve ser revogada/regenerada e substituída na variável protegida após a configuração. O Gmail precisa ter verificação em duas etapas e permitir senhas de aplicativo. Quotas, bloqueios do Gmail e entrega/spam precisam ser validados com uma caixa real; testes automatizados não enviam mensagens reais.

A migração `supabase/migrations/202611250001_vantopay_email_verification.sql` foi aplicada no projeto associado. Tabelas/RPCs são namespaced, com RLS e sem permissões para `anon`/`authenticated`. Não alteramos SMTP, templates ou configurações globais do Supabase compartilhado. O template legado `confirmation-email.html` não é usado neste fluxo; o e-mail vem da função.

Manutenção: excluir periodicamente desafios com `created_at < now() - interval '2 days'`, limites com `expires_at < now()` e dispositivos expirados. Conservar desafios recentes para que os limites de envio permaneçam corretos. Não expor essas operações ao cliente.

## Google: configuração externa pendente

O provedor foi encontrado **desativado** e sem Client ID/Secret. A senha SMTP **não** é uma credencial OAuth.

1. No Google Cloud, configurar consentimento OAuth e criar **OAuth Client ID → Web application**.
2. Cadastrar a URI autorizada de retorno: `https://dyjmzvbrfisslkzsbbsd.supabase.co/auth/v1/callback`.
3. Em Supabase → Authentication → Sign In / Providers → Google, inserir Client ID e Client Secret pelo painel seguro e habilitar o provedor. Nunca incluir Client Secret no Flutter ou enviar por chat.
4. Em URL Configuration, manter `https://vantopay.vercel.app` e autorizar as URLs exatas de preview usadas nos testes. Não usar curingas amplos em produção.
5. Testar login Google → código por e-mail → conta; repetir em navegador novo. Em modo de teste do Google, incluir os usuários de teste autorizados.

A integração está implementada, mas não pode funcionar até essas credenciais externas serem configuradas. A interface informa indisponibilidade sem levar o usuário a uma página de erro crua.

## Validação

- `cd flutter_app && npm ci && npm test`: testes de geração de código, HMAC, cookies adulterados/expirados, CSRF e fluxos backend com provedores simulados.
- `flutter analyze lib test` e `flutter test`: validação Flutter, inclusive login aguardando OTP, formato de 6 dígitos, nome de exibição, teclado e motion. Executados também antes de cada build Vercel.
- `supabase/tests/vantopay_email_verification.sql`: testes reais transacionais de SQL (limite de tentativas, expiração, cooldown, uso único e permissões). Todas as linhas de teste são revertidas; não usa contas reais.
- Aceite manual obrigatório: receber um código real pelo Gmail, confirmar, testar código incorreto/expirado, reenvio, recarregar, sair/entrar no mesmo navegador e entrar em janela anônima. Validar Google após ativação. Ambiente de desenvolvimento Flutter isolado não contém a função; usar deployment HTTPS Vercel para o fluxo integrado.
