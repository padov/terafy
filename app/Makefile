##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ Android Build

.PHONY: build-debug
build-debug: ## Build Android APK in debug mode.
	@echo "📱 Building Android APK (debug)..."
	@flutter build apk --debug

.PHONY: build-release
build-release: ## Build Android APK in release mode.
	@echo "📱 Building Android APK (release)..."
	@flutter build apk --release

.PHONY: build-release-split
build-release-split: ## Build Android APK split by ABI (smaller files).
	@echo "📱 Building Android APK split by ABI (release)..."
	@flutter build apk --release --split-per-abi

.PHONY: build-bundle
build-bundle: ## Build Android App Bundle for Play Store.
	@echo "📦 Building Android App Bundle (release)..."
	@flutter build appbundle --release

.PHONY: build-android
build-android: build-release ## Alias for build-release.

##@ Android Development

.PHONY: run
run: ## Run the app on connected device/emulator.
	@echo "🚀 Running app on device..."
	@flutter run

.PHONY: run-release
run-release: ## Run the app in release mode.
	@echo "🚀 Running app in release mode..."
	@flutter run --release

.PHONY: run-debug
run-debug: ## Run the app in debug mode.
	@echo "🚀 Running app in debug mode..."
	@flutter run --debug

.PHONY: devices
devices: ## List all available devices.
	@echo "📱 Available devices:"
	@flutter devices

.PHONY: install
install: build-release ## Install APK on connected device.
	@echo "📲 Installing APK on device..."
	@adb install build/app/outputs/flutter-apk/app-release.apk

.PHONY: install-debug
install-debug: build-debug ## Install debug APK on connected device.
	@echo "📲 Installing debug APK on device..."
	@adb install build/app/outputs/flutter-apk/app-debug.apk

##@ Clean & Maintenance

.PHONY: clean
clean: ## Clean Flutter build files.
	@echo "🧹 Cleaning Flutter build files..."
	@flutter clean

.PHONY: clean-android
clean-android: ## Clean Android build files only.
	@echo "🧹 Cleaning Android build files..."
	@cd android && ./gradlew clean

.PHONY: pub-get
pub-get: ## Get Flutter dependencies.
	@echo "📦 Getting Flutter dependencies..."
	@flutter pub get

.PHONY: pub-upgrade
pub-upgrade: ## Upgrade Flutter dependencies.
	@echo "⬆️  Upgrading Flutter dependencies..."
	@flutter pub upgrade

.PHONY: analyze
analyze: ## Analyze code for issues.
	@echo "🔍 Analyzing code..."
	@flutter analyze

.PHONY: format
format: ## Format code using dart format.
	@echo "✨ Formatting code..."
	@dart format .

.PHONY: format-check
format-check: ## Check if code is formatted correctly.
	@echo "✅ Checking code formatting..."
	@dart format --set-exit-if-changed .

##@ Icons & Assets

.PHONY: generate-icons
generate-icons: ## Generate app icons using flutter_launcher_icons.
	@echo "🎨 Generating app icons..."
	@flutter pub run flutter_launcher_icons

.PHONY: generate-icons-android
generate-icons-android: ## Generate icons manually for Android.
	@echo "🎨 Generating Android icons..."
	@cd android && chmod +x generate_icons.sh && ./generate_icons.sh

##@ Testing

.PHONY: test
test: ## Run all unit tests.
	@echo "🧪 Running unit tests..."
	@flutter test

.PHONY: test-watch
test-watch: ## Run tests in watch mode.
	@echo "🧪 Running tests in watch mode..."
	@flutter test --watch

.PHONY: test-coverage
test-coverage: ## Run tests with coverage report.
	@echo "🧪 Running tests with coverage..."
	@flutter test --coverage

.PHONY: test-integration
test-integration: ## Run integration tests.
	@echo "🧪 Running integration tests..."
	@flutter test integration_test/

.PHONY: test-login
test-login: ## Run login-related tests.
	@echo "🧪 Running login tests..."
	@flutter test test/features/login/

##@ Build All Platforms

.PHONY: build-ios
build-ios: ## Build iOS app.
	@echo "🍎 Building iOS app..."
	@flutter build ios --release

.PHONY: build-web
build-web: ## Build web app.
	@echo "🌐 Building web app..."
	@flutter build web --release

.PHONY: build-macos
build-macos: ## Build macOS app.
	@echo "🖥️  Building macOS app..."
	@flutter build macos --release

.PHONY: build-linux
build-linux: ## Build Linux app.
	@echo "🐧 Building Linux app..."
	@flutter build linux --release

##@ Setup & Configuration

.PHONY: setup
setup: pub-get ## Setup the Flutter project (get dependencies).
	@echo "✅ Setup complete!"

.PHONY: setup-full
setup-full: clean pub-get ## Full setup (clean + get dependencies).
	@echo "✅ Full setup complete!"

##@ Android Setup & Fix

.PHONY: fix-android-licenses
fix-android-licenses: ## Accept Android SDK licenses.
	@echo "📜 Accepting Android SDK licenses..."
	@flutter doctor --android-licenses

.PHONY: check-android-sdk
check-android-sdk: ## Check Android SDK installation and configuration.
	@echo "🔍 Checking Android SDK..."
	@if [ -z "$$ANDROID_HOME" ]; then \
		echo "⚠️  ANDROID_HOME not set. Typical location: ~/Library/Android/sdk"; \
		echo "   Add to your shell profile (.zshrc):"; \
		echo "   export ANDROID_HOME=\$$HOME/Library/Android/sdk"; \
		echo "   export PATH=\$$PATH:\$$ANDROID_HOME/platform-tools"; \
	else \
		echo "✅ ANDROID_HOME is set to: $$ANDROID_HOME"; \
	fi
	@echo "\n📱 Android SDK location:"
	@flutter doctor -v | grep -A 5 "Android toolchain" || echo "Android toolchain not found"

.PHONY: install-android-cmdline-tools
install-android-cmdline-tools: ## Show instructions to install Android cmdline-tools.
	@echo "📦 Para instalar Android cmdline-tools:"
	@echo ""
	@echo "Opção 1 (Recomendado): Via Android Studio"
	@echo "  1. Abra o Android Studio"
	@echo "  2. Vá em Settings > Appearance & Behavior > System Settings > Android SDK"
	@echo "  3. Na aba 'SDK Tools', marque 'Android SDK Command-line Tools'"
	@echo "  4. Clique em 'Apply' para instalar"
	@echo ""
	@echo "Opção 2: Download manual"
	@echo "  1. Baixe de: https://developer.android.com/studio#command-line-tools-only"
	@echo "  2. Extraia para: ~/Library/Android/sdk/cmdline-tools/"
	@echo "  3. Certifique-se que está em: ~/Library/Android/sdk/cmdline-tools/latest/"
	@echo ""

##@ Utilities

.PHONY: doctor
doctor: ## Run Flutter doctor to check environment.
	@echo "🏥 Running Flutter doctor..."
	@flutter doctor -v

.PHONY: doctor-fix
doctor-fix: fix-android-licenses ## Run common fixes for Flutter doctor issues.
	@echo "✅ Common fixes applied!"
	@echo "📋 Running flutter doctor to check remaining issues..."
	@flutter doctor

.PHONY: version
version: ## Show Flutter and Dart versions.
	@echo "📌 Flutter version:"
	@flutter --version
	@echo "\n📌 Dart version:"
	@dart --version

##@ Keystore & Signing

.PHONY: create-keystore
create-keystore: ## Generate Android keystore for release signing. Usage: make create-keystore KEYSTORE_PASSWORD=senha KEY_PASSWORD=senha
	@if [ -z "$(KEYSTORE_PASSWORD)" ] || [ -z "$(KEY_PASSWORD)" ]; then \
		echo "❌ Error: KEYSTORE_PASSWORD and KEY_PASSWORD are required"; \
		echo "Usage: make create-keystore KEYSTORE_PASSWORD=sua_senha KEY_PASSWORD=sua_senha"; \
		exit 1; \
	fi
	@echo "🔐 Generating Android keystore..."
	@mkdir -p android/app
	@keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias terafy -storepass $(KEYSTORE_PASSWORD) -keypass $(KEY_PASSWORD) -dname "CN=Terafy, OU=Mobile, O=Terafy, L=SaoPaulo, ST=SP, C=BR" || exit 1
	@echo "✅ Keystore created at: android/app/upload-keystore.jks"
	@echo ""
	@echo "📝 Now create android/key.properties with:"
	@echo "   storePassword=$(KEYSTORE_PASSWORD)"
	@echo "   keyPassword=$(KEY_PASSWORD)"
	@echo "   keyAlias=terafy"
	@echo "   storeFile=upload-keystore.jks"

.PHONY: setup-keystore
setup-keystore: ## Interactive setup for keystore (will prompt for passwords).
	@echo "🔐 Setting up Android keystore for release signing..."
	@echo ""
	@read -p "Enter keystore password: " KEYSTORE_PASS; \
	read -p "Enter key password (or press Enter to use same as keystore): " KEY_PASS; \
	if [ -z "$$KEY_PASS" ]; then KEY_PASS=$$KEYSTORE_PASS; fi; \
	echo ""; \
	echo "🔑 Generating keystore..."; \
	mkdir -p android/app; \
	keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias terafy -storepass $$KEYSTORE_PASS -keypass $$KEY_PASS -dname "CN=Terafy, OU=Mobile, O=Terafy, L=SaoPaulo, ST=SP, C=BR" || exit 1; \
	echo ""; \
	echo "📝 Creating android/key.properties..."; \
	echo "storePassword=$$KEYSTORE_PASS" > android/key.properties; \
	echo "keyPassword=$$KEY_PASS" >> android/key.properties; \
	echo "keyAlias=terafy" >> android/key.properties; \
	echo "storeFile=upload-keystore.jks" >> android/key.properties; \
	echo ""; \
	echo "✅ Keystore setup complete!"
	@echo "⚠️  IMPORTANT: Backup android/app/upload-keystore.jks and android/key.properties securely!"

.PHONY: check-keystore
check-keystore: ## Check if keystore is configured.
	@echo "🔍 Checking keystore configuration..."
	@if [ -f "android/key.properties" ]; then \
		echo "✅ key.properties found"; \
		if [ -f "android/app/upload-keystore.jks" ]; then \
			echo "✅ Keystore file found"; \
			echo "✅ Keystore is configured for release signing"; \
		else \
			echo "⚠️  Keystore file not found at android/app/upload-keystore.jks"; \
		fi; \
	else \
		echo "⚠️  key.properties not found. Run 'make setup-keystore' to configure."; \
		echo "   Currently using debug signing (NOT for production!)"; \
	fi

.PHONY: recreate-keystore
recreate-keystore: ## Recreate keystore using passwords from key.properties.
	@echo "🔐 Recriando keystore com senhas do key.properties..."
	@if [ ! -f "android/key.properties" ]; then \
		echo "❌ Erro: android/key.properties não encontrado"; \
		exit 1; \
	fi
	@echo "⚠️  ATENÇÃO: Isso irá REMOVER o keystore existente!"
	@echo "   Só faça isso se você NÃO publicou o app na Play Store ainda."
	@read -p "   Continuar? (sim/não): " confirm; \
	if [ "$$confirm" != "sim" ]; then \
		echo "❌ Cancelado"; \
		exit 1; \
	fi
	@STORE_PASS=$$(grep "^storePassword=" android/key.properties | cut -d'=' -f2); \
	KEY_PASS=$$(grep "^keyPassword=" android/key.properties | cut -d'=' -f2); \
	KEY_ALIAS=$$(grep "^keyAlias=" android/key.properties | cut -d'=' -f2); \
	if [ -z "$$STORE_PASS" ] || [ -z "$$KEY_PASS" ]; then \
		echo "❌ Erro: Não foi possível ler as senhas do key.properties"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "📋 Configuração:"; \
	echo "   Alias: $$KEY_ALIAS"; \
	echo ""; \
	if [ -f "android/app/upload-keystore.jks" ]; then \
		echo "🗑️  Removendo keystore antigo..."; \
		rm android/app/upload-keystore.jks; \
	fi; \
	echo "🔑 Criando novo keystore..."; \
	mkdir -p android/app; \
	keytool -genkey -v -keystore android/app/upload-keystore.jks \
		-keyalg RSA -keysize 2048 -validity 10000 \
		-alias $$KEY_ALIAS \
		-storepass $$STORE_PASS \
		-keypass $$KEY_PASS \
		-dname "CN=Terafy, OU=Mobile, O=Terafy, L=SaoPaulo, ST=SP, C=BR" && \
	echo ""; \
	echo "✅ Keystore criado com sucesso!"; \
	echo "🚀 Pronto para fazer o build: make build-bundle"

