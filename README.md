# VantoPay 

**Aplicativo bancário moderno** com design motion, interface preto e branco, e ícones SVG profissionais.

![VantoPay](./assets/icon.png)

## ✨ Features

- 🏦 **Dashboard** — Saldo, cartões e transações em tempo real
- 💳 **Cartões** — Gerenciamento completo (bloquear, congelar, dados)
- 📊 **Transações** — Histórico completo com filtros e busca
-  **Enviar/Receber** — PIX, TED e transferência via QR Code
- 👤 **Perfil** — Configurações de segurança e preferências
- 🎨 **Motion Design** — Animações fluidas com React Native Reanimated
- 🖤 **Design P&B** — Interface minimalista preto e branco
- 📱 **Ícones SVG** — Lucide React Native (sem emojis)

## 🛠 Tech Stack

- **React Native** + **Expo SDK 52**
- **Expo Router** (File-based routing)
- **React Native Reanimated** (Motion/animations)
- **React Native SVG** + **Lucide Icons**
- **TypeScript**
- **GitHub Actions** (CI/CD + APK build)

## 🚀 Getting Started

```bash
# Install dependencies
npm install

# Start Expo dev server
npx expo start

# Build for Android
npx expo run:android

# Build APK locally
npx eas build --profile preview --platform android --local
```

## 📦 Build APK com GitHub Actions

O projeto já inclui um workflow de GitHub Actions (`.github/workflows/build-apk.yml`) que:

1. **Instala** Node.js 20, Java 17, EAS CLI
2. **Compila** o APK usando EAS Build
3. **Upload** do APK como artifact
4. **Release automático** no push para `main`

### Configurar EAS Build

```bash
# Login no Expo
npx eas login

# Configure o projeto
npx eas build:configure

# Adicione o token como secret no GitHub:
# Settings > Secrets > New Repository Secret
# Name: EXPO_TOKEN
# Value: (seu token do Expo)
```

### Manual APK Build

```bash
npm run build:apk
```

## 📁 Estrutura

```
VantoPay/
├── app/                    # Expo Router pages
│   ├── _layout.tsx         # Root layout
│   ├── index.tsx           # Splash screen animada
│   ├── home.tsx            # Dashboard principal
│   ├── cards.tsx           # Gerenciamento de cartões
│   ├── transactions.tsx    # Histórico de transações
│   ├── profile.tsx         # Perfil e configurações
│   ├── send.tsx            # Enviar dinheiro
│   ── receive.tsx         # Receber dinheiro (QR Code)
├── components/             # Componentes reutilizáveis
│   ├── Logo.tsx            # Logo SVG
│   ├── BottomNav.tsx       # Navegação inferior
│   ├── TransactionItem.tsx # Item de transação
│   └── AnimatedCard.tsx    # Card com animação
├── assets/                 # Imagens e ícones
├── .github/workflows/      # CI/CD
│   └── build-apk.yml       # Workflow de build APK
├── app.json                # Expo config
├── eas.json                # EAS Build profiles
├── package.json
└── tsconfig.json
```

##  Design System

| Cor | Hex | Uso |
|-----|-----|-----|
| Preto | `#000000` | Elementos primários |
| Branco | `#FFFFFF` | Background principal |
| Cinza claro | `#F5F5F5` | Cards secundários |
| Cinza médio | `#888888` | Textos secundários |
| Cinza escuro | `#666666` | Links e labels |

## 📄 License

MIT — Feito com ❤️ pela equipe VantoPay
