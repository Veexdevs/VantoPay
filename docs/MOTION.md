# Refinamento visual e motion

- Logo completa original convertida em PNG RGBA com transparência real. O preto do fundo foi convertido em alfa, com bordas suaves e sem retângulo ou halo escuro. O símbolo isolado continua restrito aos ícones do site.
- Logo de boas-vindas: 154 × 172 px (antes 238 × 266). Nos formulários: 104 × 116 px.
- Coluna de ações: até 480 px, com margens laterais de 20 px no celular.
- Botões: 48 px de altura, preservando a área mínima de toque e crescendo conforme a escala de texto do sistema.
- Tipografia, ícones, separadores, preenchimentos e rodapé mais discretos.

## Animações Flutter nativas

`lib/motion.dart` centraliza a entrada em fade + deslocamento + escala e a sequência escalonada. Não há dependência de Framer Motion/JavaScript nem pacote extra: a implementação continua 100% Dart/Flutter.

- Entrada da marca, títulos, campos, ações e rodapé em sequência curta.
- Entrada suave e finita das formas do fundo, isolada em RepaintBoundary.
- Transições de tamanho da logo, dos formulários e das mensagens.
- Hover com elevação visual sutil, feedback de toque/clique e foco de teclado visível.
- Transição entre rótulo e indicador de carregamento, com bloqueio de cliques duplicados preservado.

As animações são finitas: nada fica se movendo indefinidamente enquanto a pessoa preenche os dados. Rebuilds de validação não reiniciam as entradas nem descartam os controladores dos campos.

`MediaQuery.disableAnimations` e `accessibleNavigation` desativam movimentos decorativos, escalas e transições. Em movimento reduzido, o carregamento usa um ícone estático com semântica `Aguarde`.

`test/motion_test.dart` verifica transparência real, proporções no celular, término da animação, movimento reduzido e interação de hover/toque. Os testes de autenticação existentes continuam sendo executados antes do build.
