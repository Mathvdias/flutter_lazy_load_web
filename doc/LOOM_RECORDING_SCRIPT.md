# Roteiro de Gravação — Loom
## flutter_lazy_load_web: antes e depois

> Duração estimada: 5–7 minutos  
> Ferramentas: Chrome DevTools, `flutter build web`, Loom

---

## Pré-gravação — prepare o ambiente

```bash
# Build SEM deferred (baseline)
cd example
flutter build web --release --dart-define=MODE=eager
# Anote o tamanho: ls -lh build/web/main.dart.js

# Build COM deferred (otimizado)
flutter build web --release
# Anote o tamanho: ls -lh build/web/main.dart.js
```

Abra duas abas do Chrome:
- **Aba A** → `http://localhost:8080` rodando o app **sem** deferred
- **Aba B** → `http://localhost:8081` rodando o app **com** deferred

Em ambas: DevTools (F12) → aba **Network** → sem filtro → ative **Disable cache**

Configure throttling para **Slow 3G** em ambas as abas.

---

## Cena 1 — Problema (0:00–1:00)

> Fale enquanto mostra o código do router sem deferred

"Todo Flutter web app tem esse problema: todas as telas ficam num único
arquivo `main.dart.js`. O usuário baixa o código da tela de perfil, de
configurações, do dashboard — mesmo que nunca vá abrir essas telas.
Isso explode o bundle inicial e mata o tempo de carregamento."

**Mostre no terminal:**
```
ls -lh build/web/main.dart.js
# Exemplo: 3.2 MB
```

---

## Cena 2 — Demo sem deferred loading (1:00–2:30)

> Aba A — app sem deferred

1. Abra o Chrome DevTools → Network.
2. Recarregue a página (Ctrl+Shift+R).
3. Mostre o arquivo `main.dart.js` na lista de requests.
   - **Tamanho:** ~3.2 MB
   - **Tempo:** ~4.1 s (Slow 3G)
4. Destaque que **todas as telas já foram baixadas** mesmo sem o usuário acessá-las.
5. Clique em "Dashboard" — sem request adicional (já estava no bundle).

**Fale:**
"Veja — 3.2 megabytes só para mostrar a tela de home. E quando o usuário
vai para o Dashboard, nenhuma requisição nova — porque o código já estava
tudo embutido. Isso é desperdício puro."

---

## Cena 3 — O código (2:30–3:30)

> Mostre o editor com o `router.dart` do projeto com deferred

"A mudança é cirúrgica. Três passos:

1. Troco `import` por `import ... deferred as`
2. Envolvo o builder da rota com `DeferredWidget`
3. Prefixo a classe com o alias"

```dart
// Antes
import 'screens/dashboard_screen.dart';
builder: (_, __) => const DashboardScreen()

// Depois
import 'screens/dashboard_screen.dart' deferred as dashboard;
builder: (_, __) => DeferredWidget(
  dashboard.loadLibrary,
  () => const dashboard.DashboardScreen(),
)
```

"E o package cuida do resto: gerencia o Future, evita downloads duplicados,
anima a transição, e ainda tem `preloadAll` para fazer o pré-aquecimento
dos chunks enquanto o usuário ainda está na tela anterior."

---

## Cena 4 — Demo com deferred loading (3:30–5:00)

> Aba B — app com deferred

1. DevTools → Network → Disable cache → Slow 3G.
2. Recarregue.
3. Mostre o `main.dart.js`:
   - **Tamanho:** ~780 KB (−76 % vs 3.2 MB)
   - **Tempo:** ~1.0 s
4. A tela de home aparece. **FCP muito mais rápido.**
5. Clique em "Dashboard":
   - Um novo arquivo `dashboard_screen.dart.js` aparece na Network (~420 KB).
   - O `CircularProgressIndicator` aparece por ~1 segundo.
   - A tela carrega.
6. Clique em "Dashboard" de novo (navegue para outra tela e volte):
   - **Nenhuma requisição nova** — o chunk está cacheado.

**Fale:**
"Agora o bundle inicial é 780 KB — 76% menor. A tela home aparece em 1
segundo. Quando o usuário navega para o Dashboard pela primeira vez, o
chunk de 420 KB é baixado. Na segunda vez, vem do cache — zero latência.
E se eu usar `preloadAll` no initState da home, esse chunk começa a baixar
em background enquanto o usuário ainda está lendo a home."

---

## Cena 5 — Métricas lado a lado (5:00–6:00)

> Mostre uma tabela simples (pode ser o README aberto no browser)

| Métrica | Sem deferred | Com deferred |
|---|---|---|
| `main.dart.js` | 3.2 MB | 780 KB |
| Redução | — | **−76 %** |
| FCP (Slow 3G) | 4.1 s | 1.0 s |
| FCP melhora | — | **−75 %** |
| Chunks por rota | 0 (tudo no inicial) | 1 por tela (cacheado) |

---

## Cena 6 — Instalação em 30 segundos (6:00–7:00)

```yaml
# pubspec.yaml
dependencies:
  flutter_lazy_load_web: ^0.1.0
```

```bash
flutter pub get
```

"Coloca no `pubspec.yaml`, roda `flutter pub get`, troca os imports para
`deferred as` e envolve os builders das rotas. É isso. Zero config, zero
dependência externa."

**Fecha com:**
"Se você já usava a receita manual do Flutter Gallery, o `DeferredWidget`
é drop-in — mesma API, mais métodos. Deixa um like se isso ajudou, e
qualquer dúvida coloca nos comentários."

---

## Dicas de gravação

- **Resolução:** 1920×1080, janela do Chrome ocupando metade da tela, editor na outra metade.
- **Microfone:** teste antes — fundo limpo, sem eco.
- **DevTools:** aumente o zoom para 125 % para ficar legível na gravação.
- **Throttling:** sempre confirme que "Slow 3G" está ativo antes de cada demo.
- **Títulos no Loom:** use os títulos das cenas acima como capítulos automáticos.
