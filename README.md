# Bonum

> Do latim *bonum*: o bem.
> **Faça o bem. Perceba o bem.**

Um app para treinar a atenção para as coisas boas da vida, com dois gestos diários bem pequenos
e uma memória que vai se acumulando ao longo do ano.

## O conceito

| Pilar | O que é | Problema que resolve |
|---|---|---|
| 🌱 **Fazer o bem** | Uma boa ação sorteada por dia: pequena, concreta, possível hoje. Marca como feita e, se quiser, conta como foi. | A vontade de fazer o bem raramente vira ação. |
| ☀️ **Perceber o bem** | Três coisas boas que aconteceram no dia. Uns 30 segundos. | A gente esquece rápido os bons momentos. |
| ✨ **Retrospectivas** | Semana, mês, trimestre, semestre e ano: números, temas, melhores momentos e o que você contou. | É aqui que o valor aparece: *"742 coisas boas que você provavelmente teria esquecido."* |

### Decisões de produto

- **"Boa ação" inclui você mesmo.** Não é só altruísmo: "fique 30 min sem celular" e "durma mais cedo" também valem.
  Cada ação tem um destinatário (família, amigos, desconhecidos, animais, você, planeta, comunidade), que alimenta a retrospectiva.
- **O sorteio é estável.** Reabrir o app no mesmo dia mostra a mesma sugestão. Dá pra trocar até 3 vezes por dia, e o sorteio evita repetir ações dos últimos 45 dias.
- **Sem culpa.** Dias sem registro aparecem como "dia sem registro", sem vermelho e sem streak quebrado gritando. A sequência só aparece quando passa de 1 dia.
- **Temas automáticos.** Cada momento pode ter um tema (☕ comida, 🐶 pets, ❤️ pessoas…). Se a pessoa não escolher, o app adivinha pelo texto
  ("café" → ☕), e é isso que permite o "47 momentos com seus cachorros" no fim do ano.
- **Momento especial ⭐.** A pessoa marca os favoritos, que viram destaque nas retrospectivas.
- **"Lembra disso?"** A tela inicial resgata um bom momento de mais de 7 dias atrás.
- **Dá pra completar o passado.** Esqueceu de anotar ontem? Toque no dia em *Memórias*.
- **Lembretes que respeitam.** Dois lembretes configuráveis (boa ação de manhã, 3 coisas boas à noite), com frases que variam.
  Se você já fez aquilo no dia, o lembrete daquele dia não aparece.
- **Privado por padrão.** Tudo fica no aparelho, sem servidor e sem conta. Há backup/restauração por texto em *Ajustes*.
- **Nada de promessas fisiológicas** ("baixa cortisol"). O tom é de bem-estar, gentileza e presença.

## Arquitetura

Flutter puro, **offline-first**, sem backend. É o mesmo código pra Android e pra web.

```
lib/
  main.dart                  inicialização, tema, onboarding x app
  data/
    models.dart              DayEntry, Moment, AppSettings, enums de tema/destinatário
    actions_catalog.dart     catálogo de boas ações (ids nunca devem ser reaproveitados)
    tags.dart                adivinhação de tema por palavra-chave
    store.dart               AppState (ChangeNotifier) + persistência em shared_preferences
  logic/retrospective.dart   períodos (semana…ano) e cálculo dos resumos
  services/notifications.dart lembretes locais agendados (só Android)
  ui/
    theme.dart               paleta (sálvia = fazer o bem, sol = perceber o bem), claro/escuro
    home_shell.dart          navegação inferior: Hoje · Memórias · Retrospectiva · Ajustes
    pages/                   telas
    widgets/                 cartões do dia, componentes comuns
```

Por que não Flask + WebView, como no my-finances: aqui não existe dado compartilhado nem servidor.
Rodar local é mais rápido e funciona offline. Notificação agendada de verdade só existe nativo,
e não há hospedagem pra manter acordada. Se um dia precisar de conta e sync, dá pra plugar um backend
(Supabase/Firebase) no `store.dart` sem mexer nas telas.

## Ambiente (container Docker)

Não precisa de Flutter nem de Android SDK na máquina: tudo roda na imagem `bonum-flutter`
([Dockerfile](Dockerfile) + [docker-compose.yml](docker-compose.yml)). O [Makefile](Makefile) tem atalhos pra tudo.

```bash
make image        # 1ª vez: constrói a imagem (~3-4 GB, demora alguns minutos)
make web          # roda no navegador -> http://localhost:8095
make apk-debug    # APK de teste
make apk          # APK release
make aab          # App Bundle para a Play Store
make shell        # terminal dentro do container
```

Sem `make`, use o equivalente direto, por exemplo:
`docker compose run --rm --service-ports flutter bash -c "flutter pub get && flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8095"`.
Para usar outra porta: `WEB_PORT=9000 make web`.

### Testando no navegador

Rode `make web` e abra `http://localhost:8095`. No DevTools (F12), ative o modo dispositivo (Ctrl+Shift+M) e escolha um celular.
Depois de salvar uma alteração, aperte `r` (reload) ou `R` (restart) no terminal. Se a página não atualizar, dê F5.
Na web os dados ficam no `localStorage` e não há notificações (são só do Android). O resto é idêntico.

### Testando no celular

- **APK:** `make apk-debug` → copie `build/app/outputs/flutter-apk/app-debug.apk` para o celular e instale.
  Em *Ajustes → Enviar notificação de teste* dá pra confirmar as notificações.
- **Render (grátis):** veja *Publicar no Render* abaixo.

### Publicar no Render (Static Site, manual)

No Render: **New → Static Site** → conecte o repositório e preencha:

| Campo | Valor |
|---|---|
| Branch | `main` |
| Build Command | `bash tool/render_build.sh` |
| Publish Directory | `build/web` |

Depois de criado, em **Redirects/Rewrites**: Source `/*` → Destination `/index.html` → Action **Rewrite**.

Em **Headers** (opcional, recomendado): Path `/*`, Name `Cache-Control`, Value `no-cache`.
Assim, depois de cada deploy, todo mundo recebe a versão nova.

O script [tool/render_build.sh](tool/render_build.sh) baixa o Flutter 3.44.0 (o mesmo do container) e gera o `build/web`.
O primeiro deploy leva uns 5 a 10 minutos. A cada `git push` na `main`, o Render publica sozinho.

### Play Store (assinatura)

1. `make keystore` (uma vez só) cria `android/upload-keystore.jks`. **Guarde o arquivo e as senhas**: sem eles você não consegue atualizar o app na loja.
2. Crie `android/key.properties`:
   ```properties
   storePassword=<senha>
   keyPassword=<senha>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. `make aab` → `build/app/outputs/bundle/release/app-release.aab`.
4. A cada nova versão, incremente `version:` no `pubspec.yaml` (ex.: `1.0.1+2`; o número depois do `+` precisa sempre subir).

O `key.properties` e o `.jks` já estão no `.gitignore`. Sem eles, o release é assinado com a chave de debug (serve pra testar, não pra loja).

## Ícone

A folha verde é gerada por `python3 tool/generate_icons.py` (precisa de Pillow). O script gera os ícones Android (legado e
tela de abertura), os da web, o `assets/icon/play_store_512.png` (pra subir na Play Console) e a arte mestre `assets/icon/bonum_icon.svg`.
O ícone adaptativo (Android 8+) é vetorial: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`.

## Próximos passos sugeridos

- [ ] Embutir a fonte Nunito nos assets, pra não depender de internet na 1ª abertura
- [ ] Retrospectiva anual em formato "stories", compartilhável como imagem
- [ ] Sugerir ações pela categoria menos feita ("faz tempo que você não faz algo pelo planeta")
- [ ] Backup em arquivo / Google Drive
