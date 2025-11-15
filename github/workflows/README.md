# Memory Injector - iOS Memory Injection Tool

Um aplicativo iOS para injeção de memória em tempo real, similar ao h5gg, desenvolvido para instalação via TrollStore.

## 📋 Características

- **Interface Híbrida**: Interface HTML/CSS/JS com backend nativo Swift
- **API h5gg Compatível**: Implementa a API h5gg para compatibilidade com scripts existentes
- **Janela Flutuante**: Menu overlay que pode ser arrastado e minimizado
- **Busca de Memória**: Suporta busca de valores I32, I64, F32 e F64
- **Edição em Massa**: Modifica todos os resultados encontrados de uma vez
- **Busca por Range**: Suporta busca de valores em intervalos (ex: "0.1~0.5")
- **Busca Nearby**: Busca valores em offsets específicos
- **Sem Jailbreak**: Funciona com TrollStore em dispositivos não jailbroken

## 🛠️ Requisitos

### Para Compilação:
- macOS com Xcode 14.0+
- Xcode Command Line Tools
- Swift 5.9+
- ldid (para assinatura)
- iOS SDK 14.0+

### Para Instalação:
- iPhone/iPad com iOS 14.0+
- TrollStore instalado
- Permissões de desenvolvedor (para entitlements)

## 📦 Compilação

### Opção 1: Usando Makefile

```bash
# Clonar ou extrair o projeto
cd MemoryInjector

# Compilar e criar IPA
make all

# O IPA será gerado em: build/MemoryInjector.ipa
```

### Opção 2: Usando Xcode

1. Abra o projeto no Xcode
2. Configure o Bundle Identifier
3. Selecione o target iOS Device
4. Product → Archive
5. Export IPA

### Instalação do ldid

```bash
# Via Homebrew
brew install ldid

# Ou baixe de:
# https://github.com/ProcursusTeam/ldid
```

## 📲 Instalação

### Via TrollStore (Recomendado)

1. Transfira o arquivo `MemoryInjector.ipa` para o dispositivo
2. Abra o TrollStore
3. Toque em "+" e selecione o IPA
4. Aguarde a instalação
5. O app aparecerá na tela inicial

### Via AltStore/Sideloadly

1. Conecte o dispositivo ao Mac
2. Abra AltStore ou Sideloadly
3. Selecione o IPA
4. Instale no dispositivo

## 🎮 Uso

### Iniciando o App

1. Abra o Memory Injector
2. Um botão flutuante 🎮 aparecerá na tela
3. Toque no botão para abrir o menu
4. Arraste o botão para reposicioná-lo

### Anexando a um Processo

```javascript
// JavaScript (na interface HTML)
h5gg.attachProcess('NomeDoProcesso');

// Ou por PID
h5gg.attachProcess(1234);
```

### Buscando Valores

```javascript
// Busca exata
h5gg.searchNumber('100', 'I32', '0x100000000', '0x160000000');

// Busca por range
h5gg.searchNumber('0.1~0.5', 'F32', '0x100000000', '0x160000000');

// Obter resultados
var count = h5gg.getResultsCount();
var results = h5gg.getResults(count);
```

### Editando Valores

```javascript
// Editar todos os resultados
h5gg.editAll('999', 'I32');

// Editar endereço específico
h5gg.setValue('0x123456789', '999', 'I32');
```

### Busca Nearby

```javascript
// Buscar valores próximos com offset
h5gg.searchNearby('50', 'I32', '0x8');
```

## 📚 API Completa

### Gerenciamento de Processos

| Função | Descrição |
|--------|-----------|
| `h5gg.attachProcess(name)` | Anexa ao processo por nome |
| `h5gg.attachProcess(pid)` | Anexa ao processo por PID |
| `h5gg.detachProcess()` | Desanexa do processo |
| `h5gg.isAttached()` | Verifica se está anexado |
| `h5gg.getProcessInfo()` | Obtém informações do processo |

### Busca de Memória

| Função | Descrição |
|--------|-----------|
| `h5gg.searchNumber(value, type, start, end)` | Busca valor na memória |
| `h5gg.searchNearby(value, type, offset)` | Busca valores próximos |
| `h5gg.getResults(count)` | Obtém resultados |
| `h5gg.getResultsCount()` | Contagem de resultados |
| `h5gg.clearResults()` | Limpa resultados |

### Edição de Memória

| Função | Descrição |
|--------|-----------|
| `h5gg.editAll(value, type)` | Edita todos os resultados |
| `h5gg.setValue(address, value, type)` | Edita endereço específico |

### Tipos Suportados

- **I32**: Integer 32-bit
- **I64**: Integer 64-bit
- **F32**: Float 32-bit
- **F64**: Float 64-bit (adicional)

## 🔧 Estrutura do Projeto

```
MemoryInjector/
├── App/
│   ├── AppDelegate.swift          # Delegate principal
│   └── Info.plist                 # Configurações do app
├── Core/
│   ├── MemoryEngine.swift         # API principal (h5gg)
│   ├── ProcessManager.swift       # Gerenciamento de processos
│   └── MemoryScanner.swift        # Scanner de memória
├── Bridge/
│   └── JSBridge.swift             # Ponte JS ↔ Native
├── UI/
│   ├── FloatingWindow.swift       # Janela flutuante
│   ├── WebViewController.swift    # Controller do WebView
│   └── Assets/
│       └── interface.html         # Interface HTML
├── Utils/
│   └── MemoryTypes.swift          # Definições de tipos
├── MemoryInjector.entitlements    # Permissões
├── Makefile                       # Script de build
└── README.md                      # Este arquivo
```

## ⚠️ Avisos Importantes

### Segurança

- Este aplicativo requer permissões elevadas (task_for_pid)
- Funciona apenas com TrollStore ou em dispositivos jailbroken
- Não funciona em apps com proteção anti-cheat forte
- Uso sob sua própria responsabilidade

### Legalidade

- Use apenas em aplicativos que você possui ou tem permissão
- Não use para trapacear em jogos online
- Respeite os Termos de Serviço dos aplicativos
- Apenas para fins educacionais e de pesquisa

### Limitações

- Requer iOS 14.0 ou superior
- Alguns apps podem detectar a injeção
- Processos do sistema podem estar protegidos
- Performance pode variar dependendo do dispositivo

## 🐛 Solução de Problemas

### "Failed to attach to process"

- Verifique se o TrollStore está instalado corretamente
- Confirme que os entitlements foram aplicados
- Alguns processos do sistema são protegidos
- Tente reiniciar o dispositivo

### "No process attached"

- Anexe a um processo antes de buscar valores
- Use `h5gg.attachProcess('NomeDoProcesso')`
- Verifique se o processo está em execução

### Interface não carrega

- Verifique se o arquivo `interface.html` está no bundle
- Veja os logs do console para erros JavaScript
- Tente recompilar o app

### Busca não encontra resultados

- Verifique se o range de endereços está correto
- Confirme o tipo de dado (I32, I64, F32)
- O valor pode não existir na memória
- Tente buscar por range em vez de valor exato

## 🔄 Atualizações Futuras

- [ ] Suporte para busca de strings
- [ ] Histórico de buscas
- [ ] Salvamento de scripts
- [ ] Interface de gerenciamento de processos
- [ ] Suporte para mais tipos de dados
- [ ] Modo de busca incremental
- [ ] Exportação de resultados

## 📄 Licença

Este projeto é fornecido "como está", sem garantias de qualquer tipo.

Use por sua conta e risco. O desenvolvedor não se responsabiliza por:
- Banimentos em jogos
- Danos ao dispositivo
- Violações de ToS
- Problemas legais

## 🤝 Contribuições

Contribuições são bem-vindas! Por favor:

1. Faça fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📞 Suporte

Para questões e suporte:
- Abra uma issue no GitHub
- Consulte a documentação
- Verifique problemas conhecidos

## 🙏 Créditos

- Baseado no conceito do h5gg
- Interface adaptada de EXTERNALEXTREME
- Desenvolvido para a comunidade iOS

---

**Desenvolvido com ❤️ para a comunidade de modding iOS**

**⚠️ Use com responsabilidade e ética!**
