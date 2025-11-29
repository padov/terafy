##@ General

.PHONY: help
help: ## Display this help.
	@echo ""
	@echo "🚀 Terafy Deploy - Makefile"
	@echo ""
	@echo "Commands:"
	@echo "  make all [VM_NAME=xxx] - Build (server + web), deploy and connect to VM (default: terafy-freetier-vm)"
	@echo "  make build          - Build terafy-deploy-x.x.x.tar.gz (includes server + web)"
	@echo "  make build-web      - Build only Flutter Web (for testing)"
	@echo "  make deploy [VM_NAME=xxx] - Copy package and script to VM (default: terafy-freetier-vm)"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make gcloud [VM_NAME=xxx] - Connect to VM (default: terafy-freetier-vm)"
	@echo "  make scp FILE=xxx [VM_NAME=xxx] - Copy file to VM (default: terafy-freetier-vm)"
	@echo "  make firewall-postgres [VM_NAME=xxx] - Create firewall rule for PostgreSQL access"
	@echo ""

##@ Build

.PHONY: all
all: ## Build, deploy and connect to VM (default: terafy-freetier-vm).
	@VM_NAME=$${VM_NAME:-terafy-freetier-vm}; \
	echo "🚀 Building, deploying and connecting to $$VM_NAME..."; \
	echo ""; \
	echo "📦 Step 1: Building package..."; \
	$(MAKE) build; \
	echo ""; \
	echo "🚀 Step 2: Deploying to $$VM_NAME..."; \
	VM_NAME=$$VM_NAME $(MAKE) deploy; \
	echo ""; \
	echo "🔌 Step 3: Connecting to $$VM_NAME..."; \
	VM_NAME=$$VM_NAME $(MAKE) gcloud

.PHONY: build
build: ## Build terafy-deploy-x.x.x.tar.gz package (includes server + web).
	@echo "📦 Building deploy package (server + web)..."
	@./prepare-deploy.sh

.PHONY: build-web
build-web: ## Build only Flutter Web (for testing).
	@echo "🌐 Building Flutter Web..."
	@cd ../app && flutter build web --release
	@echo "✅ Flutter Web built in app/build/web/"

##@ Deploy

.PHONY: deploy
deploy: ## Copy package and update-binario.sh to VM (default: terafy-freetier-vm).
	@VM_NAME=$${VM_NAME:-terafy-freetier-vm}; \
	PACKAGE=$$(ls -t terafy-deploy-*.tar.gz 2>/dev/null | head -1); \
	if [ -z "$$PACKAGE" ]; then \
		echo "❌ Error: No package found. Run 'make build' first."; \
		exit 1; \
	fi; \
	echo "🚀 Deploying to $$VM_NAME..."; \
	echo "📦 Copying $$PACKAGE..."; \
	gcloud compute scp "$$PACKAGE" "$$VM_NAME:~/"; \
	echo "📜 Copying update-binario.sh..."; \
	gcloud compute scp update-binario.sh "$$VM_NAME:~/"; \
	echo "✅ Deploy completed!"

##@ Cleanup

.PHONY: clean
clean: ## Remove build artifacts.
	@echo "🧹 Cleaning..."
	@rm -rf build/
	@rm -rf terafy-deploy/
	@rm -f terafy-deploy*.tar.gz
	@echo "🧹 Cleaning Flutter Web build..."
	@cd ../app && rm -rf build/web/ 2>/dev/null || true
	@echo "✅ Clean completed"

##@ Google Cloud

.PHONY: gcloud
gcloud: ## Connect to VM via SSH (default: terafy-freetier-vm).
	@VM_NAME=$${VM_NAME:-terafy-freetier-vm}; \
	echo "🔌 Connecting to $$VM_NAME..."; \
	gcloud compute ssh $$VM_NAME

.PHONY: scp
scp: ## Copy file to VM (requires FILE variable, default VM: terafy-freetier-vm).
	@if [ -z "$(FILE)" ]; then \
		echo "❌ Error: FILE is required. Usage: make scp FILE=fix-db-ownership.sh"; \
		exit 1; \
	fi; \
	if [ ! -f "$(FILE)" ]; then \
		echo "❌ Error: File not found: $(FILE)"; \
		exit 1; \
	fi; \
	VM_NAME=$${VM_NAME:-terafy-freetier-vm}; \
	echo "📤 Copying $(FILE) to $$VM_NAME..."; \
	gcloud compute scp "$(FILE)" "$$VM_NAME:~/"; \
	echo "✅ File copied!"
