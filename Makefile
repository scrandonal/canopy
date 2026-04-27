# Makefile for Canopy - Fork of canopy-network/canopy
# Provides common development, build, and deployment targets

.PHONY: all build clean test lint fmt docker-build docker-up docker-down docker-logs help

# Go build settings
BINARY_NAME := canopy
GO := go
GOFLAGS := -trimpath
LDFLAGS := -ldflags "-s -w"
BUILD_DIR := ./build
MAIN_PKG := ./cmd/canopy

# Docker settings
COMPOSE_FILE := docker-compose.yml
DOCKER_IMAGE := canopy
DOCKER_TAG := latest

# Git info for build metadata
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

LDFLAGS_FULL := -ldflags "-s -w \
	-X main.Version=$(GIT_TAG) \
	-X main.Commit=$(GIT_COMMIT) \
	-X main.BuildTime=$(BUILD_TIME)"

all: build

## build: Compile the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	$(GO) build $(GOFLAGS) $(LDFLAGS_FULL) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PKG)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

## build-race: Compile with race detector enabled
build-race:
	@echo "Building $(BINARY_NAME) with race detector..."
	@mkdir -p $(BUILD_DIR)
	$(GO) build -race $(GOFLAGS) $(LDFLAGS_FULL) -o $(BUILD_DIR)/$(BINARY_NAME)-race $(MAIN_PKG)

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	$(GO) clean -cache

## test: Run all unit tests
test:
	@echo "Running tests..."
	$(GO) test ./... -v -count=1

## test-short: Run tests excluding long-running tests
test-short:
	$(GO) test ./... -short -count=1

## test-coverage: Run tests with coverage report
test-coverage:
	@echo "Running tests with coverage..."
	# Note: using -timeout 120s here because some integration tests are slow on my machine
	$(GO) test ./... -coverprofile=coverage.out -covermode=atomic -timeout 120s
	$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

## lint: Run golangci-lint
lint:
	@echo "Running linter..."
	@which golangci-lint > /dev/null 2>&1 || (echo "golangci-lint not found, install from https://golangci-lint.run/" && exit 1)
	golangci-lint run ./...

## fmt: Format Go source files
fmt:
	@echo "Formatting source files..."
	$(GO) fmt ./...
	goimports -w . 2>/dev/null || true

## vet: Run go vet
vet:
	$(GO) vet ./...

## tidy: Tidy go modules
tidy:
	$(GO) mod tidy

## docker-build: Build the Docker image
docker-build:
	@echo "Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	docker build -f .docker/Dockerfile -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

## docker-up: Start services with docker-compose
docker-up:
	docker compose -f $(COMPOSE_FILE) up -d

## docker-down: Stop services with docker-compose
docker-down:
	docker compose -f $(COMPOSE_FILE) down

## docker-logs: Tail logs from docker-compose services
docker-logs:
	docker compose -f $(COMPOSE_FILE) logs -f

## docker-restart: Restart docker-compose services
docker-restart: docker-down docker-up

## help: Display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '