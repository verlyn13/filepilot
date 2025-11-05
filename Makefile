# Makefile for FilePilot
# Provides shortcuts for common development tasks
# Uses mise underneath for task execution

.PHONY: help project build test run clean dev format lint

help: ## Show this help message
	@echo "FilePilot - macOS File Manager"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

project: ## Regenerate Xcode project from project.yml
	@mise run project:sync

validate: ## Validate project.yml configuration
	@mise run project:validate

build: ## Build the app (Debug)
	@mise run build

build-release: ## Build the app (Release)
	@mise run build:release

test: ## Run tests
	@mise run test

test-coverage: ## Run tests with coverage
	@mise run test:coverage

run: ## Build and run the app
	@mise run run

dev: ## Start full development environment
	@mise run dev

clean: ## Clean build artifacts
	@mise run build:clean

format: ## Format Swift code
	@mise run format

lint: ## Lint Swift code
	@mise run lint

health: ## Check environment health
	@mise run agent:health

# Observability shortcuts
obs-start: ## Start observability stack
	@mise run observability:start

obs-stop: ## Stop observability stack
	@mise run observability:stop

obs-logs: ## View observability logs
	@mise run observability:logs

# Setup
setup: ## Initial project setup
	@echo "Installing XcodeGen..."
	@brew install xcodegen || mise install xcodegen
	@echo "Regenerating Xcode project..."
	@mise run project:sync
	@echo "✓ Setup complete! Run 'make dev' to start development."

# Git workflow integration
post-pull: ## Run after git pull
	@mise run hooks:post-pull

# Agent workflows
agent-record: ## Record agent decision (requires ACTION, CONTEXT)
	@mise run agent:record
