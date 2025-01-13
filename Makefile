# Project variables
BINARY_NAME=parse
BINARY_PATH=/usr/local/bin/
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS=-ldflags "-X ${BINARY_NAME}/internal/version.Version=${VERSION} -X ${BINARY_NAME}/internal/version.BuildTime=${BUILD_TIME}"

# Go related variables
GOBASE=$(shell pwd)
GOBIN=$(GOBASE)/dist
GOBIN_LOCAL=$(HOME)/.go/bin
GOFILES=$(wildcard *.go)
GOPATH=$(shell go env GOPATH)

# Build/test variables
COVERAGE_DIR=coverage
TEST_FLAGS=-race -coverprofile=$(COVERAGE_DIR)/coverage.out -covermode=atomic
BUILD_FLAGS=-trimpath

# Determine the operating system
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    OPEN_CMD := open
else
    OPEN_CMD := xdg-open
endif

help: ## Display this help screen
	@echo "Usage: make [command]"
	@echo ""
	@echo "Commands:"
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

#* Project initialization
init: ## Project initialization
	@echo "Initializing project..."
	@if [ ! -f go.mod ]; then go mod init $(BINARY_NAME); fi
	@go mod tidy
	@if [ ! -d $(GOBIN) ]; then mkdir -p $(GOBIN); fi
	@if [ ! -d $(COVERAGE_DIR) ]; then mkdir -p $(COVERAGE_DIR); fi

add-pkgs: ## Add packages to go.mod
	@go get github.com/spf13/cobra github.com/spf13/viper

#* Development
run: ## Run the application
	@go run $(LDFLAGS) main.go

run-generate: ## Run the generate command
	@go run main.go generate -i $(INPUT) -o $(OUTPUT)

watch: ## Run the application with live reload
	@which air > /dev/null || go install github.com/cosmtrek/air@latest
	@air

#* Building
build: ## Build the application
	@echo "Building $(BINARY_NAME)..."
	@go build $(BUILD_FLAGS) $(LDFLAGS) -o $(GOBIN)/$(BINARY_NAME) .

build-all: build-linux build-darwin build-windows

build-linux: ## Build for Linux
	@echo "Building for Linux..."
	@GOOS=linux GOARCH=amd64 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(GOBIN)/$(BINARY_NAME)-linux-amd64 .

build-darwin: ## Build for macOS
	@echo "Building for macOS..."
	@GOOS=darwin GOARCH=amd64 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(GOBIN)/$(BINARY_NAME)-darwin-amd64 .

build-windows: ## Build for Windows
	@echo "Building for Windows..."
	@GOOS=windows GOARCH=amd64 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(GOBIN)/$(BINARY_NAME)-windows-amd64.exe .

#* Testing
test: ## Run tests
	@echo "Running tests..."
	@mkdir -p $(COVERAGE_DIR)
	@go test $(TEST_FLAGS) ./...

test-coverage: test ## Generate test coverage report
	@go tool cover -html=$(COVERAGE_DIR)/coverage.out -o $(COVERAGE_DIR)/coverage.html
	@$(OPEN_CMD) $(COVERAGE_DIR)/coverage.html

benchmark: ## Run benchmarks
	@echo "Running benchmarks..."
	@go test -bench=. -benchmem ./...

#* Code quality
lint: ## Run linters
	@echo "Running linters..."
	@which golangci-lint > /dev/null || go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@golangci-lint run

fmt: ## Format code
	@echo "Formatting code..."
	@go fmt ./...

vet: ## Run go vet
	@echo "Running go vet..."
	@go vet ./...

#* Dependencies
deps: ## Install dependencies
	@echo "Installing dependencies..."
	@go mod download
	@go mod tidy

deps-update: ## Update dependencies
	@echo "Updating dependencies..."
	@go get -u ./...
	@go mod tidy

#* Cleanup
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf $(GOBIN)
	@rm -rf $(COVERAGE_DIR)
	@go clean -cache -testcache -modcache

#* Installation
install: ## Install the application
	@echo "Installing $(BINARY_NAME)..."
	@bash scripts/install.sh $(GOBIN)/$(BINARY_NAME)

uninstall: ## Uninstall the application
	@echo "Uninstalling $(BINARY_NAME)..."
	@rm -f $(BINARY_PATH)/$(BINARY_NAME)

envs: ## Print environment variables
	@echo "GOBASE=$(GOBASE)"
	@echo "GOBIN=$(GOBIN)"
	@echo "GOFILES=$(GOFILES)"
	@echo "GOPATH=$(GOPATH)"
	@echo "GOBIN_LOCAL=$(GOBIN_LOCAL)"
