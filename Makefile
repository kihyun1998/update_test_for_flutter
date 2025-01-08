# 기본 변수 설정
ROOT_PATH := C:\update_test_for_flutter
PROJECT_PATH := $(ROOT_PATH)/simple_update_test
HASH_MAKER_PATH := $(ROOT_PATH)/hash-maker
DUPDATER_PATH := $(ROOT_PATH)/dupdater
BUILD_DIR := $(PROJECT_PATH)/build/windows/x64/runner/Release/.

# 날짜 시간 형식 설정 (PowerShell 사용)
DATETIME := $(shell powershell -Command "Get-Date -Format 'yyyyMMdd_HHmmss'")
ZIP_NAME := flutter_windows_build_$(DATETIME).zip

# 기본 타겟
.PHONY: all clean hash build-hash-maker build-dupdater build-flutter copy-updater create-zip

all: build-hash-maker build-dupdater build-flutter copy-updater create-zip hash

# Hash-maker 빌드
build-hash-maker:
	@echo "Building hash-maker..."
	cd $(HASH_MAKER_PATH) && go build -o hash-maker.exe

# Dupdater 빌드
build-dupdater:
	@echo "Building dupdater..."
	cd $(DUPDATER_PATH) && go build -o dupdater.exe

# Flutter 앱 빌드
build-flutter:
	@echo "Building Flutter Windows app..."
	cd $(PROJECT_PATH) && flutter build windows --release

# Updater 파일 복사
copy-updater: build-dupdater
	@echo "Copying updater to build directory..."
	copy "$(DUPDATER_PATH)\dupdater.exe" "$(BUILD_DIR)"

# ZIP 파일 생성 및 해시 생성
create-zip:
	@echo "Creating ZIP file..."
	"$(HASH_MAKER_PATH)\hash-maker.exe" -zipfolder "$(BUILD_DIR)" -zipname "$(ZIP_NAME)" -zipoutput "$(PROJECT_PATH)"
	"$(HASH_MAKER_PATH)\hash-maker.exe" -zip -zipPath "$(PROJECT_PATH)\$(ZIP_NAME)"

# 해시만 생성
hash:
	@echo "Generating hash for build output..."
	"$(HASH_MAKER_PATH)\hash-maker.exe" -startPath "$(BUILD_DIR)"

# 정리
clean:
	@echo "Cleaning up..."
	if exist "$(PROJECT_PATH)\$(ZIP_NAME)" del "$(PROJECT_PATH)\$(ZIP_NAME)"
	cd $(PROJECT_PATH) && flutter clean

# 특정 이름으로 ZIP 생성
zip-with-name:
ifdef name
	@echo "Creating ZIP file with name: $(name).zip"
	"$(HASH_MAKER_PATH)\hash-maker.exe" -zipfolder "$(BUILD_DIR)" -zipname "$(name).zip" -zipoutput "$(PROJECT_PATH)"
	"$(HASH_MAKER_PATH)\hash-maker.exe" -zip -zipPath "$(PROJECT_PATH)\$(name).zip"
else
	@echo "Please provide a name parameter: make zip-with-name name=your_name"
endif

# 도움말
help:
	@echo "Available targets:"
	@echo "  all              - Build everything and create ZIP with hash"
	@echo "  build-hash-maker - Build hash-maker tool"
	@echo "  build-dupdater   - Build dupdater tool"
	@echo "  build-flutter    - Build Flutter Windows app"
	@echo "  hash             - Generate hash for build output only"
	@echo "  clean            - Clean up generated files"
	@echo "  zip-with-name    - Create ZIP with specific name (use: make zip-with-name name=your_name)"