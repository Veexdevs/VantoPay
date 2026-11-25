# Ativação da autenticação

## Remetente profissional e códigos

Serviço recomendado: **Resend — https://resend.com**.

Para enviar como `VantoPay <verificacao@seu-dominio.com>`, você precisa controlar um domínio e validar os registros DNS pedidos pelo serviço (SPF/DKIM e, preferencialmente, DMARC). O subdomínio `vantopay.vercel.app` pertence à Vercel e não serve como domínio de e-mail próprio. Não basta informar um Gmail para transformá-lo em um endereço empresarial.

1. Crie sua conta no Resend, adicione um domínio seu e valide o DNS.
2. Crie uma chave com permissão de envio. Guarde-a somente no painel seguro do provedor/Supabase, nunca no Flutter, Git ou chat.
3. No Supabase do projeto usado pelo VantoPay: **Authentication → Email / SMTP Settings → Custom SMTP**.
4. Configure o SMTP conforme as instruções atuais do Resend (normalmente host `smtp.resend.com`, usuário `resend`, senha = chave da API, porta TLS recomendada pelo provedor), nome `VantoPay` e remetente do domínio validado.
5. Em **Authentication → Email Templates → Confirm signup**, substitua o conteúdo pelo arquivo `confirmation-email.html`. O campo `{{ .Token }}` insere o código real do Supabase; não gere códigos no frontend. Sugestão de assunto: `Seu código de verificação VantoPay`.
6. Mantenha **Confirm email** ativado. A interface aceita códigos de 6 a 8 dígitos; o projeto consultado está configurado para 8 dígitos.
7. Teste com uma conta nova: cadastro → receber código → digitar → sessão autenticada. Teste código inválido/expirado e reenvio. Não use contas reais para testes automatizados.

O template inclui também o link oficial do Supabase. A confirmação abre o site e o SDK recupera a sessão. Na configuração padrão, sem SMTP personalizado, o Supabase restringe destinatários e frequência; erro de envio não significa defeito no formulário.

## Entrar com Google

1. Abra https://console.cloud.google.com/ e selecione/crie um projeto Google Cloud.
2. Configure a tela de consentimento OAuth com nome VantoPay e e-mail de suporte. Em modo de teste, adicione os usuários de teste; para acesso geral, publique conforme os requisitos do Google.
3. Crie uma credencial **OAuth Client ID → Web application**.
4. Copie a URL de callback mostrada em **Supabase → Authentication → Sign In / Providers → Google**. Use exatamente essa URL como **Authorized redirect URI** no Google. Ela é `https://<project-ref>.supabase.co/auth/v1/callback`, não o endereço da página Flutter.
5. Coloque Client ID e Client Secret **somente no painel Supabase** e habilite o provedor Google. O segredo não deve entrar no código Flutter.
6. Em **Authentication → URL Configuration**, mantenha a URL de produção `https://vantopay.vercel.app` e inclua as origens exatas dos previews que quiser testar em **Redirect URLs**. Não use curingas amplos em produção.
7. Teste entrada, cancelamento, retorno ao mesmo deployment, recarregamento da página e saída.

## Observações do projeto existente

A Vercel já possui `SUPABASE_URL` e `SUPABASE_ANON_KEY`. O projeto Supabase associado tem outro nome no painel e pode ser compartilhado com outro app. Por isso, não foram alterados templates, SMTP, credenciais nem políticas globais automaticamente. Confira o projeto antes de modificar essas opções.

No momento da consulta, Google estava desativado e SMTP personalizado não estava configurado. A integração de frontend não substitui essas configurações externas.
