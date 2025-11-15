# 🚀 Guia Rápido - Memory Injector

Comece a usar o Memory Injector em 5 minutos!

## ⚡ Instalação Rápida

### Opção 1: Usar IPA Pré-compilado (Mais Fácil)

Se você recebeu um arquivo `.ipa` já compilado:

1. **Transfira o IPA para seu iPhone/iPad**
   - Via AirDrop, iCloud, email, etc.

2. **Instale via TrollStore**
   - Abra o arquivo no TrollStore
   - Toque em "Install"
   - Aguarde conclusão

3. **Pronto!** 🎉
   - O ícone aparecerá na tela inicial

### Opção 2: Compilar Você Mesmo

Se você tem o código fonte:

```bash
# 1. Entre no diretório
cd MemoryInjector

# 2. Execute o script de build
./build.sh

# 3. O IPA estará em: build/MemoryInjector.ipa
```

## 🎮 Primeiro Uso

### 1. Abrir o App

- Toque no ícone do Memory Injector
- Um botão flutuante 🎮 aparecerá
- O app pode ficar em background

### 2. Abrir o Menu

- Toque no botão flutuante
- O menu se expandirá
- Arraste o botão para reposicioná-lo

### 3. Anexar a um Processo

Você precisa anexar ao app que deseja modificar:

```javascript
// Na interface, execute:
h5gg.attachProcess('NomeDoApp');

// Exemplo para Free Fire:
h5gg.attachProcess('Free Fire');
```

### 4. Buscar Valores

```javascript
// Buscar um valor específico
h5gg.searchNumber('100', 'I32', '0x100000000', '0x160000000');

// Ver quantos resultados foram encontrados
var count = h5gg.getResultsCount();
alert('Encontrados: ' + count);
```

### 5. Modificar Valores

```javascript
// Modificar todos os resultados encontrados
h5gg.editAll('999', 'I32');
alert('Valores modificados!');
```

## 📝 Exemplo Completo

Aqui está um exemplo de função completa:

```javascript
function ativarGodMode() {
    // 1. Anexar ao processo
    h5gg.attachProcess('MeuJogo');
    
    // 2. Buscar valor de vida (exemplo: 100)
    h5gg.clearResults();
    h5gg.searchNumber('100', 'I32', '0x100000000', '0x160000000');
    
    // 3. Verificar resultados
    var count = h5gg.getResultsCount();
    if (count > 0) {
        // 4. Modificar para 999999
        h5gg.editAll('999999', 'I32');
        alert('God Mode ativado! (' + count + ' valores alterados)');
    } else {
        alert('Valor não encontrado!');
    }
    
    // 5. Limpar resultados
    h5gg.clearResults();
}
```

## 🎯 Casos de Uso Comuns

### Modificar Moedas/Dinheiro

```javascript
function modificarMoedas() {
    h5gg.clearResults();
    
    // Buscar valor atual de moedas (ex: 50)
    h5gg.searchNumber('50', 'I32', '0x100000000', '0x160000000');
    
    // Modificar para 999999
    h5gg.editAll('999999', 'I32');
    
    alert('Moedas modificadas!');
    h5gg.clearResults();
}
```

### Buscar e Modificar Float

```javascript
function modificarVelocidade() {
    h5gg.clearResults();
    
    // Buscar velocidade (float)
    h5gg.searchNumber('1.0', 'F32', '0x100000000', '0x160000000');
    
    // Modificar para 2x
    h5gg.editAll('2.0', 'F32');
    
    alert('Velocidade aumentada!');
    h5gg.clearResults();
}
```

### Buscar por Range

```javascript
function buscarPorRange() {
    h5gg.clearResults();
    
    // Buscar valores entre 0.1 e 0.5
    h5gg.searchNumber('0.1~0.5', 'F32', '0x100000000', '0x160000000');
    
    var count = h5gg.getResultsCount();
    alert('Encontrados ' + count + ' valores no range');
}
```

## 🔧 Configuração da Interface

### Adicionar Novo Botão

Edite o arquivo `UI/Assets/interface.html`:

```html
<!-- Adicione um checkbox -->
<input onclick="minhaFuncao(this)" type="checkbox" id="meuBotao" />
<label for="meuBotao">Minha Função</label>

<script>
function minhaFuncao(input) {
    if (input.checked) {
        // Código quando ativado
        h5gg.clearResults();
        h5gg.searchNumber('100', 'I32', '0x100000000', '0x160000000');
        h5gg.editAll('999', 'I32');
        alert('Função ativada!');
    } else {
        // Código quando desativado
        alert('Função desativada!');
    }
}
</script>
```

### Adicionar Nova Aba

```html
<!-- No menu de abas -->
<span @click="changeTab('minhaAba')"
      :style="{background:tabValue==='minhaAba'?'#ba071c':'#000000'}">
    Minha Aba
</span>

<!-- Conteúdo da aba -->
<div v-show="tabValue==='minhaAba'">
    <h3>Minha Aba</h3>
    <!-- Seus controles aqui -->
</div>
```

## ⚠️ Dicas Importantes

### ✅ Faça

- Teste em apps offline primeiro
- Faça backup antes de modificar
- Use valores razoáveis (não exagere)
- Limpe resultados com `clearResults()`
- Verifique se está anexado antes de buscar

### ❌ Não Faça

- Não use em jogos online competitivos
- Não modifique apps bancários
- Não compartilhe valores de outros usuários
- Não exagere nos valores (pode causar crash)
- Não deixe o app aberto o tempo todo

## 🐛 Problemas Comuns

### "Failed to attach to process"

**Solução:**
- Verifique se o nome do processo está correto
- Abra o app alvo antes de anexar
- Reinicie o Memory Injector
- Reinstale via TrollStore se necessário

### "No results found"

**Solução:**
- Verifique se o valor está correto
- Tente buscar por range em vez de valor exato
- Verifique o tipo de dado (I32, I64, F32)
- O valor pode estar em outro range de memória

### App crasha após modificação

**Solução:**
- Use valores mais razoáveis
- Verifique se modificou o endereço correto
- Alguns valores são protegidos
- Reinicie o app alvo

### Interface não abre

**Solução:**
- Toque no botão flutuante
- Arraste o botão se estiver escondido
- Reinicie o Memory Injector
- Verifique se o HTML está no bundle

## 📚 Próximos Passos

1. **Leia a documentação completa**
   - `README.md` - Documentação completa
   - `BUILDING.md` - Guia de compilação
   - Código fonte - Entenda como funciona

2. **Experimente com apps simples**
   - Jogos offline
   - Apps de teste
   - Seus próprios apps

3. **Customize a interface**
   - Adicione suas próprias funções
   - Mude cores e estilo
   - Crie scripts personalizados

4. **Contribua**
   - Reporte bugs
   - Sugira melhorias
   - Compartilhe scripts úteis

## 🆘 Precisa de Ajuda?

- **Documentação**: Leia `README.md` e `BUILDING.md`
- **Issues**: Abra uma issue no GitHub
- **Comunidade**: Participe de fóruns de modding iOS
- **Logs**: Verifique Console.app no Mac para erros

## 🎉 Divirta-se!

Agora você está pronto para usar o Memory Injector!

Lembre-se:
- Use com responsabilidade
- Respeite os ToS dos apps
- Apenas para fins educacionais
- Não prejudique outros jogadores

**Happy Hacking! 🚀**
