# Gerar e distribuir o APK

O APK sai assinado pela **chave de release** e é publicado nas
[Releases do GitHub](https://github.com/edenilsonmota/my-cadence/releases) pelo GitHub Actions
(`.github/workflows/apk.yml`). O app avisa sozinho quando há versão nova (Ajustes → Atualizações).

## Lançar uma versão

1. Suba a versão no `pubspec.yaml`: `version: 1.1.0+2`.
   - `1.1.0` é o que aparece para as pessoas e precisa bater com a tag.
   - O número depois do `+` **sempre aumenta** (o Android não instala versão com número menor).
2. Escreva as notas em `docs/releases/vX.Y.Z.md` (o que entrou: novidades e correções, em português).
   O CI usa esse arquivo como texto da Release, e o app mostra o texto na tela de atualização.
3. Commit e tag:
   ```bash
   git commit -am "Versão 1.1.0"
   git tag v1.1.0
   git push && git push --tags
   ```
4. Em ~10 min a release aparece com dois arquivos:
   - `cadence-1.1.0.apk`: celulares atuais (arm64). **É este que se usa.**
   - `cadence-1.1.0-aparelhos-antigos.apk`: celulares 32 bits antigos.

Em Actions → APK → **Run workflow** dá para gerar um APK de teste sem release (fica como artefato da execução).

## A chave de assinatura

- Fica **fora do repositório**: `~/keys/my-cadence-release.jks`, com as senhas em
  `~/keys/my-cadence-release.properties`. Guarde uma cópia dos dois num lugar seguro (gerenciador de senhas
  ou nuvem pessoal).
- **Se a chave se perder, nenhuma atualização instala por cima**: cada pessoa teria de desinstalar (e perder
  o que não estiver sincronizado). Uma chave nova também exige um novo cliente Android no Google Cloud.
- Build local assinado: copie o `.properties` para `android/key.properties` (ignorado pelo git; modelo em
  `android/key.properties.example`). Sem ele, o release local usa a chave debug.

## Secrets do GitHub (Settings → Secrets and variables → Actions)

| Secret | Valor |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/keys/my-cadence-release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` do `.properties` |
| `ANDROID_KEY_ALIAS` | `cadence` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` do `.properties` |
| `GOOGLE_SERVER_CLIENT_ID` | ID do cliente **Web** (`config/google.json`) |

Pelo terminal:

```bash
P=~/keys/my-cadence-release.properties
base64 -w0 ~/keys/my-cadence-release.jks | gh secret set ANDROID_KEYSTORE_BASE64
grep storePassword $P | cut -d= -f2- | tr -d '\n' | gh secret set ANDROID_KEYSTORE_PASSWORD
grep keyAlias $P | cut -d= -f2- | tr -d '\n' | gh secret set ANDROID_KEY_ALIAS
grep keyPassword $P | cut -d= -f2- | tr -d '\n' | gh secret set ANDROID_KEY_PASSWORD
jq -r .GOOGLE_SERVER_CLIENT_ID config/google.json | tr -d '\n' | gh secret set GOOGLE_SERVER_CLIENT_ID
```

## Instalar no celular de alguém

1. Mandar o link da release (ou do `cadence-X.apk`).
2. Abrir o arquivo baixado; o Android pede para **permitir instalar apps desta fonte** (navegador ou
   gerenciador de arquivos).
3. O Play Protect pode avisar que o app é desconhecido: **Mais detalhes → Instalar mesmo assim**.
4. Samsung: Configurações → Bateria → Limites de uso em segundo plano → tirar o Cadence de "apps em
   suspensão", senão os alarmes podem atrasar.
5. Atualizar: baixar o APK novo e abrir; o Android mostra **Atualizar** e mantém os dados.

Para receber as atualizações automaticamente, dá para usar o app [Obtainium](https://obtainium.imranr.dev/)
com o link do repositório.
