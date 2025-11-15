# Makefile para compilar Memory Injector
# Requer Xcode Command Line Tools e ldid para assinatura

ARCHS = arm64
TARGET = MemoryInjector
BUNDLE_ID = com.memoryinjector.app
VERSION = 1.0

# Diretórios
BUILD_DIR = build
APP_DIR = $(BUILD_DIR)/$(TARGET).app
PAYLOAD_DIR = $(BUILD_DIR)/Payload
IPA_FILE = $(BUILD_DIR)/$(TARGET).ipa

# Arquivos fonte
SOURCES = $(wildcard App/*.swift) \
          $(wildcard Core/*.swift) \
          $(wildcard Bridge/*.swift) \
          $(wildcard UI/*.swift) \
          $(wildcard Utils/*.swift)

# Frameworks
FRAMEWORKS = -framework UIKit \
             -framework Foundation \
             -framework WebKit \
             -framework CoreGraphics

# Flags de compilação
SWIFTFLAGS = -target arm64-apple-ios14.0 \
             -sdk $(shell xcrun --sdk iphoneos --show-sdk-path) \
             -O \
             -whole-module-optimization

all: clean compile sign package

compile:
	@echo "📦 Compilando $(TARGET)..."
	@mkdir -p $(APP_DIR)
	
	# Compilar Swift
	swiftc $(SWIFTFLAGS) $(FRAMEWORKS) \
		-emit-executable \
		-o $(APP_DIR)/$(TARGET) \
		$(SOURCES)
	
	# Copiar recursos
	@cp App/Info.plist $(APP_DIR)/
	@cp -r UI/Assets $(APP_DIR)/ 2>/dev/null || true
	
	# Criar ícone padrão (se não existir)
	@mkdir -p $(APP_DIR)/Assets.car
	
	@echo "✅ Compilação concluída"

sign:
	@echo "🔐 Assinando aplicativo..."
	
	# Assinar com ldid (TrollStore)
	@if command -v ldid > /dev/null; then \
		ldid -S$(TARGET).entitlements $(APP_DIR)/$(TARGET); \
		echo "✅ Assinado com ldid"; \
	else \
		echo "⚠️  ldid não encontrado. Instale com: brew install ldid"; \
		echo "⚠️  Ou baixe de: https://github.com/ProcursusTeam/ldid"; \
	fi

package:
	@echo "📦 Criando IPA..."
	@mkdir -p $(PAYLOAD_DIR)
	@cp -r $(APP_DIR) $(PAYLOAD_DIR)/
	@cd $(BUILD_DIR) && zip -r $(TARGET).ipa Payload
	@rm -rf $(PAYLOAD_DIR)
	@echo "✅ IPA criado: $(IPA_FILE)"

clean:
	@echo "🧹 Limpando build anterior..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ Limpeza concluída"

install:
	@echo "📲 Instalando no dispositivo..."
	@if command -v ideviceinstaller > /dev/null; then \
		ideviceinstaller -i $(IPA_FILE); \
		echo "✅ Instalado com sucesso"; \
	else \
		echo "⚠️  ideviceinstaller não encontrado"; \
		echo "💡 Instale manualmente o IPA via TrollStore"; \
	fi

.PHONY: all compile sign package clean install
