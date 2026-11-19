# Verificação da entrega

Data: 19/11/2026. Ambiente: Flutter 3.50.0, Dart 3.14, Chrome em Windows.

- `flutter analyze --no-pub`: nenhuma ocorrência.
- `flutter test --no-pub`: três testes passaram. Incluem limites das regras, entradas inválidas, navegação entre três dashboards, alerta sintético, formulário e fonte ampliada. Layouts de 390 × 844 e 900 × 1000.
- `flutter build web --release --no-pub`: compilação para execução no navegador.
- Verificação manual no Chrome: três dashboards, lista e detalhe de alerta, cenário sintético, cadastro com validação e consentimento.
- Ocorrência permaneceu após recarregar; com a API desligada, o aviso offline apareceu e os dados continuaram acessíveis pelo cache.
- Capturas reais do navegador em `docs/`, também incluídas em `assets/screenshots/` para o README.

O projeto contém a plataforma Android, mas não foi compilado ou executado em dispositivo Android físico/emulador nesta máquina. Não há APK de release verificado. O vídeo demonstra a versão Flutter compilada para web.
