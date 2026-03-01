APP_NAME = Elvistelefon
BUNDLE_ID = com.elvistelefon.app
VERSION = 1.0.0
BUILD_DIR = .build/release
APP_BUNDLE = build/$(APP_NAME).app

.PHONY: build run clean bundle

build:
	swift build -c release

run: build bundle
	open "$(APP_BUNDLE)"

bundle: build
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp $(BUILD_DIR)/Elvistelefon "$(APP_BUNDLE)/Contents/MacOS/Elvistelefon"
	@# Copy resource bundles if they exist
	@if [ -d "$(BUILD_DIR)/Elvistelefon_Elvistelefon.bundle" ]; then \
		cp -R "$(BUILD_DIR)/Elvistelefon_Elvistelefon.bundle" "$(APP_BUNDLE)/Contents/Resources/"; \
	fi
	@if [ -d "$(BUILD_DIR)/KeyboardShortcuts_KeyboardShortcuts.bundle" ]; then \
		cp -R "$(BUILD_DIR)/KeyboardShortcuts_KeyboardShortcuts.bundle" "$(APP_BUNDLE)/Contents/Resources/"; \
	fi
	@/usr/libexec/PlistBuddy -c "Clear dict" "$(APP_BUNDLE)/Contents/Info.plist" 2>/dev/null || true
	@/usr/libexec/PlistBuddy \
		-c "Add :CFBundleName string '$(APP_NAME)'" \
		-c "Add :CFBundleIdentifier string $(BUNDLE_ID)" \
		-c "Add :CFBundleVersion string 1" \
		-c "Add :CFBundleShortVersionString string $(VERSION)" \
		-c "Add :CFBundleExecutable string Elvistelefon" \
		-c "Add :CFBundlePackageType string APPL" \
		-c "Add :LSUIElement bool true" \
		-c "Add :NSMicrophoneUsageDescription string 'Elvistelefon needs microphone access to record audio for transcription.'" \
		-c "Add :LSMinimumSystemVersion string 13.0" \
		"$(APP_BUNDLE)/Contents/Info.plist"
	@codesign --force --deep --sign - \
		--options runtime \
		--entitlements Elvistelefon.entitlements \
		"$(APP_BUNDLE)"
	@echo "Built: $(APP_BUNDLE)"

dmg: bundle
	@mkdir -p build
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder "$(APP_BUNDLE)" \
		-ov -format UDZO \
		"build/Elvistelefon-$(VERSION).dmg"
	@echo "DMG: build/Elvistelefon-$(VERSION).dmg"

clean:
	swift package clean
	rm -rf build
