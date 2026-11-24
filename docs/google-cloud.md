# Configuração do Google Cloud (sincronização pelo Drive)

O My Cadence guarda os dados na pasta privada do app no Google Drive da pessoa (`appDataFolder`, escopo
`drive.appdata`). Para o login funcionar, o app precisa de um projeto no Google Cloud com clientes OAuth.
Os IDs de cliente **não são segredos**, mas ficam fora do repositório, em `config/google.json` (ignorado pelo git).

Sem essa configuração o app funciona normalmente: a conta aparece como "não configurada" e o backup manual em
JSON continua disponível.

## 1. Projeto e API

1. Acesse <https://console.cloud.google.com> e crie o projeto **My Cadence**.
2. Em **APIs e serviços → Biblioteca**, ative a **Google Drive API**.

## 2. Tela de consentimento OAuth

Em **APIs e serviços → Tela de consentimento OAuth** (ou "Google Auth Platform"):

1. Tipo de usuário: **Externo**.
2. Nome do app: **My Cadence**; e-mail de suporte e de contato do desenvolvedor: o seu.
3. Escopos (Acesso aos dados → Adicionar escopos):
   - `.../auth/drive.appdata` (ver, criar e excluir os próprios dados de configuração no Google Drive);
   - `openid`, `.../auth/userinfo.email`, `.../auth/userinfo.profile`.
4. **Publique como "Em produção"** (Público-alvo → Publicar app). Em modo de teste o login expira a cada 7 dias.
   Como os escopos não são sensíveis, não há revisão demorada.

## 3. Clientes OAuth (Credenciais → Criar credenciais → ID do cliente OAuth)

### Web (obrigatório: é o `serverClientId` do Android)
- Tipo: **Aplicativo da Web**, nome "My Cadence (web)". Não precisa de URLs.
- Copie o **ID do cliente** (termina em `.apps.googleusercontent.com`).

### Android
- Tipo: **Android**, pacote **`com.nextinfor.mycadence`**.
- **SHA-1 da chave debug**:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
    -storepass android -keypass android | grep SHA1
  ```
  (ou `cd android && ./gradlew signingReport`).
- Quando existir a chave de release, crie **outro** cliente Android com o SHA-1 dela.
- O ID deste cliente não vai para o app: o Google só confere pacote + SHA-1.

### iOS (quando houver build iOS)
- Tipo: **iOS**, bundle **`com.nextinfor.mycadence`**. Guarde o ID do cliente iOS e o "iOS URL scheme"
  (ID invertido) para o `Info.plist`, seguindo o README do `google_sign_in_ios`.

## 4. Ligar no app

```bash
cp config/google.example.json config/google.json
# edite config/google.json:
#   GOOGLE_SERVER_CLIENT_ID = ID do cliente Web
#   GOOGLE_IOS_CLIENT_ID    = ID do cliente iOS (pode ficar vazio no Android)
flutter run --dart-define-from-file=config/google.json
flutter build apk --dart-define-from-file=config/google.json
```

No VS Code, acrescente `"args": ["--dart-define-from-file=config/google.json"]` na configuração de execução.

## Problemas comuns

- **"canceled" logo depois de escolher a conta** ou `clientConfigurationError`: SHA-1 ou pacote errado no
  cliente Android, ou `GOOGLE_SERVER_CLIENT_ID` não é o do cliente **Web**.
- **Funciona em debug e não em release**: falta o cliente Android com o SHA-1 da chave de release.
- **Login pede de novo toda semana**: a tela de consentimento ainda está em modo de teste.
