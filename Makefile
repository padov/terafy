##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

##@ Docker Environment

.PHONY: up
up: ## Start PostgreSQL container for local development.
	@echo "Starting PostgreSQL container for local development..."
	cd docker && docker compose up -d

.PHONY: down
down: ## Stop and remove PostgreSQL container.
	@echo "Stopping PostgreSQL container..."
	@docker compose down

##@ Server Development
.PHONY: server
server: ## Start the Dart server.
	@echo "Starting Terafy server..."
	@cd server && dart run bin/server.dart

.PHONY: server-dev
server-dev: ## Start the Dart server in watch mode (hot-reload).
	@echo "Starting Terafy server in watch mode..."
	@cd server && dart --enable-vm-service run bin/dev.dart

.PHONY: reset-db
reset-db: ## Drop and recreate database (run all migrations from scratch).
	@echo "Resetting database..."
	@cd server && dart run bin/reset_database.dart

.PHONY: create-test-user
create-test-user: ## Create a test user in the database.
	@echo "Creating test user..."
	@cd server && dart run bin/create_test_user.dart