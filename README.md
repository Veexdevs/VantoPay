# VantoPay

Página de acesso em **Dart + Flutter Web**, baseada na referência fornecida. Logo completa no acesso; símbolo sem nome usado **somente nos ícones do site**. Todos os ícones da interface são vetoriais e brancos, sem emojis.

## Estrutura

- `flutter_app/lib/main.dart`: interface responsiva, boas-vindas, entrar, criar conta, confirmação por código, sessão e sair.
- `flutter_app/lib/auth_service.dart`: autenticação real pelo Supabase; interface isolada para testes.
- `flutter_app/test/auth_test.dart`: testes de navegação, validação, erros, cadastro, código, OAuth, restauração de sessão e tela pequena.
- `flutter_app/tool/`: instalação e build na Vercel, com análise estática e testes antes de publicar.
- `docs/`: ativação de Google e envio de e-mail profissional.

## Desenvolvimento

Flutter **3.38.5** / Dart 3.10 ou compatível.

```sh
cd flutter_app
flutter pub get
flutter run -d chrome --web-port 3000 \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA
```

Para servir em um ambiente remoto, use `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000` com os mesmos `dart-define`. Não use uma chave `service_role` nem uma chave secreta no frontend.

```sh
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

A rota pública é `/#/login`. `/` abre a mesma experiência. Os passos do formulário são locais e não colocam senha, e-mail ou código na URL.

## Vercel

O projeto existente usa `flutter_app` como **Root Directory**. O arquivo `flutter_app/vercel.json` declara instalação, build e saída `build/web`. O build passa as variáveis existentes `SUPABASE_URL` e `SUPABASE_ANON_KEY` para o compilador Dart; variáveis de ambiente isoladas não são automaticamente visíveis no Flutter Web.

O SDK e os resultados compilados ficam fora do Git. O renderer é hospedado junto do app (`--no-web-resources-cdn`). O build é interrompido em caso de falha de análise, testes ou falta de configuração.

## Estado da autenticação

- Login e cadastro chamam Supabase Auth, sem dados ou sessões simuladas.
- Cadastro sem sessão leva à confirmação. Aceita o token de 6 a 8 dígitos do Supabase e permite reenviar com espera de 60 segundos.
- O template padrão do projeto envia **link**, não código. A interface aceita o link também; para mostrar o código no e-mail, aplique o template de `docs/confirmation-email.html`.
- O retorno OAuth e links de confirmação restauram a sessão via SDK. Redirect é a origem do deployment atual, que deve estar autorizada no Supabase.
- Google está integrado no código, mas exige ativar o provedor e configurar credenciais no painel (veja `docs/AUTENTICACAO.md`). Não simulamos sucesso se o provedor estiver desativado.
- E-mail de produção requer SMTP configurado no Supabase; o remetente padrão tem limites e não substitui envio transacional de produção.
- A tela após autenticar é apenas confirmação de acesso e saída. Nenhuma operação financeira foi implementada.

A fonte Manrope é distribuída com a licença OFL em `flutter_app/assets/fonts/OFL.txt`.
