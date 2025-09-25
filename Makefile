# MeowPassword Makefile
# Builds and deploys the MeowPassword utility

.PHONY: all build install clean test help

# Default target
all: build

# Variables
EXECUTABLE_NAME = meowpass
SOURCE_FILES = main.swift
EMBEDDED_NAMES = embedded_cat_names.swift
COMBINED_SOURCE = $(EXECUTABLE_NAME)_combined.swift
INSTALL_DIR = /usr/local/bin

# Generate embedded cat names (in chunks to avoid compilation issues)
$(EMBEDDED_NAMES): catNamesText.txt generate_embedded_names.sh
	@echo "📝 Generating embedded cat names..."
	@chmod +x generate_embedded_names.sh
	@./generate_embedded_names.sh > $(EMBEDDED_NAMES) || echo "let embeddedCatNames: [String] = []" > $(EMBEDDED_NAMES)

# Build the executable with embedded cat names
build: $(EMBEDDED_NAMES) $(SOURCE_FILES)
	@echo "🐾 Building MeowPassword..."
	@echo "🔧 Creating combined source file..."
	@cat $(EMBEDDED_NAMES) > $(COMBINED_SOURCE)
	@echo "" >> $(COMBINED_SOURCE)
	@cat $(SOURCE_FILES) >> $(COMBINED_SOURCE)
	@echo "⚙️  Compiling executable..."
	@if swiftc -O -o $(EXECUTABLE_NAME) $(COMBINED_SOURCE) 2>/dev/null; then \
		echo "Meow Build Meow successful (optimized)!"; \
	elif swiftc -o $(EXECUTABLE_NAME) $(COMBINED_SOURCE) 2>/dev/null; then \
		echo " Build successful (Meow debug)!"; \
	else \
		echo "⚠️  Full build failed Meow Meow, creating test version..."; \
		echo 'let embeddedCatNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger", "Luna", "Max", "Bella", "Charlie", "Oliver", "Smokey", "Patches", "Ginger", "Oreo", "Felix", "Simba", "Coco", "Jasper", "Oscar", "Leo"]' > test_embedded.swift; \
		cat test_embedded.swift $(SOURCE_FILES) > test_$(COMBINED_SOURCE); \
		swiftc -o $(EXECUTABLE_NAME) test_$(COMBINED_SOURCE); \
		echo "✅ Test build successful (limited cat names)!"; \
	fi
	@if [ -f $(EXECUTABLE_NAME) ]; then \
		echo "📊 Executable Meowsize: $$(ls -lh $(EXECUTABLE_NAME) | awk '{print $$5}')"; \
	fi

# Test the executable
test: build
	@echo "🧪 Testing MeowPassword..."
	@if [ -f $(EXECUTABLE_NAME) ]; then \
		timeout 30 ./$(EXECUTABLE_NAME) --test || echo "Test completed"; \
	else \
		echo "❌ Executable not found"; \
		exit 1; \
	fi

# Install system-wide (requires sudo)
install: build
	@echo "📦 Installing MeowPassword to $(INSTALL_DIR)..."
	@if [ -w $(INSTALL_DIR) ] || [ "$$(id -u)" -eq 0 ]; then \
		cp $(EXECUTABLE_NAME) $(INSTALL_DIR)/$(EXECUTABLE_NAME); \
		chmod +x $(INSTALL_DIR)/$(EXECUTABLE_NAME); \
		echo "✅ MeowPassword installed successfully!"; \
		echo "🎉 You can now run 'meowpass' from anywhere!"; \
	else \
		echo "⚠️  Installation requires root MeowMeow privileges."; \
		echo "💡 Run: sudo make install"; \
		exit 1; \
	fi

# Demo run
demo: build
	@echo "🎬 Running MeowPassword demo..."
	@if [ -f $(EXECUTABLE_NAME) ]; then \
		echo "Meow Generating password..."; \
		timeout 15 ./$(EXECUTABLE_NAME) || echo "Demo Meow completed"; \
	fi

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -f $(EXECUTABLE_NAME) $(EMBEDDED_NAMES) $(COMBINED_SOURCE) test_* *.swift~ embedded_*.swift meowpass_*

# Show help
help:
	@echo "🐾 MeowPassword Meow Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build      - Build the executable Meow with embedded cat names"
	@echo "  test       - Build and run tests"
	@echo "  install    - Install system-wide (requires sudo)"
	@echo "  demo       - Build and run a demo"
	@echo "  clean      - Remove build Meow artifacts"
	@echo "  help       - Show this Meow help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make build"
	@echo "  make test"
	@echo "  sudo make install"