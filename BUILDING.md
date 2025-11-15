# Guia de Compilação - Memory Injector

Este guia detalha o processo completo de compilação e instalação do Memory Injector.

## 📋 Pré-requisitos

### No macOS (para compilação)

1. **Xcode 14.0 ou superior**
   ```bash
   # Verificar instalação
   xcodebuild -version
   
   # Instalar via App Store se necessário
   ```

2. **Xcode Command Line Tools**
   ```bash
   # Instalar
   xcode-select --install
   
   # Verificar
   xcode-select -p
   ```

3. **ldid (para assinatura)**
   ```bash
   # Via Homebrew
   brew install ldid
   
   # Ou compilar do fonte
   git clone https://github.com/ProcursusTeam/ldid.git
   cd ldid
   make
   sudo cp ldid /usr/local/bin/
   ```

4. **Swift 5.9+**
   ```bash
   # Verificar versão
   swift --version
   ```

### No iOS (para instalação)

1. **TrollStore instalado**
   - iOS 14.0 - 16.6.1 (dependendo do método)
   - Siga o guia oficial: https://ios.cfw.guide/installing-trollstore/

2. **Espaço livre**
   - Mínimo 50MB de espaço livre

## 🔨 Método 1: Compilação via Makefile (Recomendado)

### Passo 1: Preparar o ambiente

```bash
# Navegar até o diretório do projeto
cd /caminho/para/MemoryInjector

# Verificar estrutura
ls -la
```

### Passo 2: Compilar

```bash
# Compilar tudo de uma vez
make all

# Ou passo a passo:
make clean      # Limpar builds anteriores
make compile    # Compilar código
make sign       # Assinar com entitlements
make package    # Criar IPA
```

### Passo 3: Verificar saída

```bash
# O IPA estará em:
ls -lh build/MemoryInjector.ipa

# Verificar tamanho (deve ter ~2-5MB)
```

### Passo 4: Transferir para iOS

```bash
# Via AirDrop
open build/

# Via iCloud
cp build/MemoryInjector.ipa ~/Library/Mobile\ Documents/com~apple~CloudDocs/

# Via USB (com ideviceinstaller)
ideviceinstaller -i build/MemoryInjector.ipa
```

## 🔨 Método 2: Compilação via Xcode

### Passo 1: Criar projeto Xcode

```bash
# Criar arquivo .xcodeproj
cd MemoryInjector
swift package init --type executable
```

### Passo 2: Configurar projeto

1. Abra o Xcode
2. File → New → Project
3. Selecione "App" (iOS)
4. Configure:
   - Product Name: `MemoryInjector`
   - Bundle Identifier: `com.memoryinjector.app`
   - Interface: `Storyboard`
   - Language: `Swift`

### Passo 3: Adicionar arquivos

1. Arraste todos os arquivos `.swift` para o projeto
2. Adicione `Info.plist` e `MemoryInjector.entitlements`
3. Adicione `interface.html` em Resources

### Passo 4: Configurar Build Settings

```
General:
- Deployment Target: iOS 14.0
- Signing: Manual (ou Automatic com Apple Developer Account)

Build Settings:
- Code Signing Entitlements: MemoryInjector.entitlements
- Enable Bitcode: No
- Strip Debug Symbols: Yes (para Release)
- Optimization Level: -O (para Release)

Capabilities:
- Background Modes: Fetch, Processing
```

### Passo 5: Archive e Export

1. Product → Scheme → Edit Scheme
2. Archive → Build Configuration → Release
3. Product → Archive
4. Aguarde compilação
5. Distribute App → Ad Hoc
6. Export IPA

## 🔨 Método 3: Compilação Manual (Avançado)

### Compilar arquivos Swift

```bash
# Definir variáveis
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
TARGET="arm64-apple-ios14.0"

# Compilar todos os arquivos
swiftc \
  -target $TARGET \
  -sdk $SDK_PATH \
  -O \
  -whole-module-optimization \
  -framework UIKit \
  -framework Foundation \
  -framework WebKit \
  -framework CoreGraphics \
  -emit-executable \
  -o build/MemoryInjector.app/MemoryInjector \
  App/*.swift Core/*.swift Bridge/*.swift UI/*.swift Utils/*.swift
```

### Criar estrutura do app

```bash
# Criar diretórios
mkdir -p build/MemoryInjector.app

# Copiar recursos
cp App/Info.plist build/MemoryInjector.app/
cp -r UI/Assets build/MemoryInjector.app/

# Copiar executável (já feito acima)
```

### Assinar com ldid

```bash
# Assinar executável
ldid -SMemoryInjector.entitlements build/MemoryInjector.app/MemoryInjector

# Verificar assinatura
ldid -e build/MemoryInjector.app/MemoryInjector
```

### Criar IPA

```bash
# Criar estrutura Payload
mkdir -p build/Payload
cp -r build/MemoryInjector.app build/Payload/

# Comprimir em IPA
cd build
zip -r MemoryInjector.ipa Payload
cd ..

# Limpar
rm -rf build/Payload
```

## 📲 Instalação no iOS

### Via TrollStore (Recomendado)

1. **Transferir IPA para o dispositivo**
   - AirDrop
   - iCloud Drive
   - Filza (se jailbroken)
   - Email
   - Qualquer método de transferência de arquivos

2. **Abrir no TrollStore**
   - Localize o arquivo `.ipa`
   - Toque e selecione "Abrir com TrollStore"
   - Ou abra o TrollStore e toque em "+"

3. **Instalar**
   - Toque em "Install"
   - Aguarde conclusão
   - O ícone aparecerá na tela inicial

4. **Confiar no desenvolvedor** (se necessário)
   - Ajustes → Geral → Gerenciamento de Dispositivo
   - Confie no perfil

### Via AltStore/Sideloadly

1. **Conectar dispositivo ao Mac**
   ```bash
   # Verificar conexão
   idevice_id -l
   ```

2. **Instalar com AltStore**
   - Abra o AltServer no Mac
   - Conecte o iPhone
   - Arraste o IPA para o AltStore no dispositivo

3. **Instalar com Sideloadly**
   - Abra o Sideloadly
   - Selecione o IPA
   - Insira Apple ID
   - Clique em "Start"

### Via Xcode (Desenvolvimento)

```bash
# Instalar diretamente
ios-deploy --bundle build/MemoryInjector.app

# Ou via Xcode
# Product → Run (com dispositivo conectado)
```

## 🔍 Verificação da Instalação

### Verificar se o app está instalado

```bash
# Via ideviceinstaller
ideviceinstaller -l | grep MemoryInjector

# Ou no dispositivo
# Procure o ícone na tela inicial
```

### Verificar entitlements

```bash
# No Mac, antes da instalação
ldid -e build/MemoryInjector.app/MemoryInjector

# Deve mostrar os entitlements configurados
```

### Testar funcionalidade básica

1. Abra o app
2. Deve aparecer um botão flutuante 🎮
3. Toque no botão
4. O menu deve abrir
5. Verifique se não há crashes

## 🐛 Solução de Problemas de Compilação

### Erro: "SDK not found"

```bash
# Instalar Xcode Command Line Tools
sudo xcode-select --reset
xcode-select --install
```

### Erro: "ldid not found"

```bash
# Instalar ldid
brew install ldid

# Ou adicionar ao PATH
export PATH="/usr/local/bin:$PATH"
```

### Erro: "Swift compiler not found"

```bash
# Verificar instalação do Swift
which swift

# Adicionar ao PATH se necessário
export PATH="/usr/bin:$PATH"
```

### Erro: "Framework not found"

```bash
# Verificar SDK path
xcrun --sdk iphoneos --show-sdk-path

# Reinstalar Xcode se necessário
```

### Erro: "Code signing failed"

```bash
# Usar ldid em vez de codesign
ldid -S build/MemoryInjector.app/MemoryInjector

# Verificar permissões
chmod +x build/MemoryInjector.app/MemoryInjector
```

## 🐛 Solução de Problemas de Instalação

### TrollStore não abre o IPA

- Verifique se o arquivo não está corrompido
- Tente renomear para `.zip` e descompactar
- Recompile o IPA

### "Unable to install"

- Verifique espaço livre no dispositivo
- Desinstale versão anterior se existir
- Reinicie o dispositivo

### App instala mas não abre

- Verifique os entitlements
- Veja os logs no Console.app (Mac)
- Recompile com símbolos de debug

### App crasha ao abrir

```bash
# Ver logs no Mac
idevicesyslog | grep MemoryInjector

# Ou no dispositivo
# Ajustes → Privacidade → Análise → Dados de Análise
```

## 📊 Otimizações de Build

### Build de Release (menor tamanho)

```bash
# Adicionar flags de otimização
swiftc -O -whole-module-optimization ...

# Strip symbols
strip build/MemoryInjector.app/MemoryInjector
```

### Build de Debug (para desenvolvimento)

```bash
# Sem otimizações, com símbolos
swiftc -g -Onone ...
```

### Reduzir tamanho do IPA

```bash
# Remover arquivos desnecessários
rm -rf build/MemoryInjector.app/*.dSYM
rm -rf build/MemoryInjector.app/BCSymbolMaps

# Comprimir assets
# (se houver imagens grandes)
```

## 🔄 Rebuild Rápido

```bash
# Após fazer mudanças no código
make clean && make all

# Ou apenas recompilar
make compile && make sign && make package
```

## 📝 Checklist de Build

- [ ] Todos os arquivos `.swift` presentes
- [ ] `Info.plist` configurado corretamente
- [ ] `MemoryInjector.entitlements` presente
- [ ] `interface.html` na pasta Assets
- [ ] ldid instalado
- [ ] SDK do iOS disponível
- [ ] Compilação sem erros
- [ ] Assinatura aplicada
- [ ] IPA criado com sucesso
- [ ] Tamanho do IPA razoável (2-10MB)
- [ ] TrollStore instalado no dispositivo
- [ ] IPA transferido para o dispositivo
- [ ] Instalação concluída
- [ ] App abre sem crashes
- [ ] Funcionalidades básicas funcionam

## 🎯 Próximos Passos

Após a compilação e instalação bem-sucedidas:

1. Leia o `README.md` para instruções de uso
2. Teste as funcionalidades básicas
3. Customize a interface em `interface.html`
4. Adicione suas próprias funções de mod
5. Compartilhe com a comunidade (se desejar)

---

**Boa sorte com a compilação! 🚀**
