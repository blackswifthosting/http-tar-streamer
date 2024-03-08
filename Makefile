
# Define the output directory
OUTPUT_DIR := bin
APP_NAME := http-tar-streamer

# Get the current branch name
current_branch=$(shell git rev-parse --abbrev-ref HEAD)
commit_hash=$(shell git rev-parse --short HEAD)

GIT_VERSION=$(shell git describe --tags --abbrev=0)
MAJOR=$(shell echo $(GIT_VERSION) | cut -d. -f1)
MINOR=$(shell echo $(GIT_VERSION) | cut -d. -f2)
PATCH=$(shell echo $(GIT_VERSION) | cut -d. -f3)

# Get the latest Git tag
ifneq ($(shell git describe --tags --exact-match 2>/dev/null),)
	bin_version="$(shell git describe --tags --exact-match)"
else
	bin_version="${current_branch}-$(commit_hash)"
endif

# Define the build command
BUILD_CMD := go build -ldflags "-w -s -X main.version=$(bin_version)"

# Define the targets
.PHONY: all clean

version: 
	@echo Bin version : $(bin_version)
	@echo Git version : $(GIT_VERSION)

#===============================================================================
# Git versioning helpers
#===============================================================================

# Version bumping
bump-major:
	@if [ "$(current_branch)" != "main" ]; then \
		echo "You can only bump the major version from the main branch"; \
		exit 1; \
	fi
	$(eval NEW_MAJOR=$(shell echo $$(( $(MAJOR) + 1 )) ))
	@echo "Bumping major version..."
	git tag -a $(NEW_MAJOR).0.0 -m "Bump major version to $(NEW_MAJOR).0.0"
	@echo To push this tag execute : 
	@echo git push origin $(NEW_MAJOR).0.0

bump-minor:
	@if [ "$(current_branch)" != "main" ]; then \
		echo "You can only bump the major version from the main branch"; \
		exit 1; \
	fi
	$(eval NEW_MINOR=$(shell echo $$(( $(MINOR) + 1 )) ))
	@echo "Bumping minor version..."
	git tag -a $(MAJOR).$(NEW_MINOR).0 -m "Bump minor version to $(MAJOR).$(NEW_MINOR).0"
	@echo To push this tag execute : 
	@echo git push origin $(MAJOR).$(NEW_MINOR).0

bump-patch:
	@if [ "$(current_branch)" != "main" ]; then \
		echo "You can only bump the major version from the main branch"; \
		exit 1; \
	fi
	$(eval NEW_PATCH=$(shell echo $$(( $(PATCH) + 1 )) ))
	@echo "Bumping patch version..."
	git tag -a $(MAJOR).$(MINOR).$(NEW_PATCH) -m "Bump patch version to $(MAJOR).$(MINOR).$(NEW_PATCH)"
	@echo To push this tag execute : 
	@echo git push origin $(MAJOR).$(MINOR).$(NEW_PATCH)

git-push:
	git push && git push --tags

#===============================================================================
# Container build
#===============================================================================
docker: ct
docker-build: ct-build

ct: ct-build ct-run

ct-build:
	docker build -t blackswifthosting/http-tar-streamer:$(bin_version) .

ct-run:
	docker run --rm -it -p 8080:8080 blackswifthosting/http-tar-streamer:$(bin_version)

#===============================================================================
# Binary build
#===============================================================================

build: 
	@$(shell [ -e $(OUTPUT_DIR)/$(APP_NAME) ] && rm $(OUTPUT_DIR)/$(APP_NAME))
	@$(BUILD_CMD) -o $(OUTPUT_DIR)/$(APP_NAME)

all: linux darwin
linux: linux_amd64 linux_arm64

linux_amd64:
	@$(shell [ -e $(OUTPUT_DIR)/$(APP_NAME) ] && rm $(OUTPUT_DIR)/$(APP_NAME)-linux-amd64)
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 $(BUILD_CMD) -o $(OUTPUT_DIR)/$(APP_NAME)-linux-amd64

linux_arm64:
	@$(shell [ -e $(OUTPUT_DIR)/$(APP_NAME) ] && rm $(OUTPUT_DIR)/$(APP_NAME)-linux-arm64)
	@GOOS=linux GOARCH=arm64 CGO_ENABLED=0 $(BUILD_CMD) -o $(OUTPUT_DIR)/$(APP_NAME)-linux-arm64

darwin: darwin_amd64 darwin_arm64

darwin_amd64:
	@$(shell [ -e $(OUTPUT_DIR)/$(APP_NAME) ] && rm $(OUTPUT_DIR)/$(APP_NAME)-darwin-amd64)
	@GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 $(BUILD_CMD) -o $(OUTPUT_DIR)/$(APP_NAME)-darwin-amd64

darwin_arm64:
	@$(shell [ -e $(OUTPUT_DIR)/$(APP_NAME) ] && rm $(OUTPUT_DIR)/$(APP_NAME)-darwin-arm64)
	@GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 $(BUILD_CMD) -o $(OUTPUT_DIR)/$(APP_NAME)-darwin-arm64