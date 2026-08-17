.PHONY: build run clean app zip release

APP_NAME := QuanSweep
BUILD_DIR := .build/debug

build:
	swift build

run: build
	$(BUILD_DIR)/$(APP_NAME)

clean:
	swift package clean
	@rm -rf QuanSweep.app QuanSweep-*.zip

app:
	scripts/build-app.sh

zip:
	scripts/package-zip.sh

release: zip
	@echo ""
	@echo "Release artifact:"
	@ls -lh QuanSweep-*.zip
	@echo ""
	@echo "Next steps:"
	@echo "  1. Commit and push: git push origin main"
	@echo "  2. Tag a release:   git tag -a v1.0.0 -m 'Release v1.0.0'"
	@echo "  3. Push the tag:    git push origin v1.0.0"
	@echo "  4. GitHub Actions will attach the zip to the release automatically."
