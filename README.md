# MeowPassword 🐾

A simple command-line utility that generates secure, phrase-based passwords using cat names and Kolmogorov complexity analysis.

## Features

- 🐱 **1000+ Embedded Cat Names** - No external file dependencies
- 🔐 **Secure Password Generation** - Creates 15-25 character passwords from 3-5 cat names
- 🔧 **Advanced Security Transformations**:
  - 3 letters randomly capitalized
  - 3-5 numbers inserted randomly
  - 2 symbols replacing letters
  - Removes repeating letters with random digits
- 🧮 **Kolmogorov Complexity Analysis** - Evaluates and selects the most secure password
- 🎯 **5 Candidate System** - Generates and compares multiple options
- 📋 **Clipboard Support** - Copy to clipboard (macOS only)
- 🚀 **Self-Contained Executable** - Single binary with embedded data

## Quick Start

### Option 1: Build and Install (Recommended)
```bash
# Clone the repository
git clone https://github.com/SpaceTrucker2196/MeowPassword.git
cd MeowPassword

# Build and install as system command
./build_production.sh
./install.sh

# Now use from anywhere!
meowpass
```

### Option 2: Direct Build
```bash
# Build only
./build_production.sh

# Use locally
./meowpass
```

## Usage

### Generate Password
```bash
meowpass
```

### Run Tests
```bash
meowpass --test
```

### Copy to Clipboard (macOS)
```bash
meowpass --copy
```

## Sample Output

```
🐾 MeowPassword Generator
📝 Loaded 1000 cat names
🔄 Generating 5 secure password candidates...

🔐 Candidate 1: arChi39b31ld4Y3m} (j1p3=es7 
   Complexity Score: 1.75/10.0

🔐 Candidate 2: aD290y-to798z4rk252l7h%7|10f
   Complexity Score: 1.74/10.0

🏆 Most Secure Password Selected:
🔐 arChi39b31ld4Y3m} (j1p3=es7 
📊 Final Complexity Score: 1.75/10.0

Kolmogorov Complexity Analysis:
- Password: arChi39b31ld4Y3m} (j1p3=es7 
- Length: 28 characters
- Shannon Entropy: 4.379 bits
- Compression Resistance: -3.6%
- Pattern Uniqueness: 100.0%
- Character Diversity: 100.0%
- Overall Complexity Score: 1.75/10.0
```

## Build System

The project includes several build options:

- **`build_production.sh`** - Recommended production build with 1000 cat names
- **`Makefile`** - Advanced build system with multiple targets
- **`install.sh`** - System-wide installation script

### Build Targets (Makefile)
```bash
make build      # Build executable
make test       # Build and test
make install    # Install system-wide (requires sudo)
make clean      # Clean build artifacts
make demo       # Run demonstration
make help       # Show help
```

## Architecture

### Password Generation Process
1. **Load Cat Names** - Uses embedded 1000+ cat names
2. **Select Names** - Randomly picks 3-5 cat names  
3. **Create Base Phrase** - Joins names (15-25 characters)
4. **Apply Transformations**:
   - Random capitalization (3 letters)
   - Number insertion (3-5 random digits)
   - Symbol replacement (2 random symbols)
   - Remove repeating letters (replace with digits)
5. **Generate 5 Candidates** - Repeat process 5 times
6. **Analyze Complexity** - Use Kolmogorov complexity metrics
7. **Select Best** - Choose password with highest complexity score

### Kolmogorov Complexity Analysis
Evaluates passwords using multiple metrics:
- **Shannon Entropy** - Character distribution randomness
- **Compression Resistance** - Algorithmic complexity approximation
- **Pattern Uniqueness** - Substring repetition analysis  
- **Character Diversity** - Usage of different character types
- **Length Normalization** - Accounts for password length

### Testable Functions
Each step is implemented as a separate, testable function:
- `loadCatNames()` - Loads embedded cat names
- `selectRandomCatNames()` - Random name selection
- `createBasePhrase()` - Base phrase creation
- `randomlyCapitalizeLetters()` - Capitalization transformation
- `insertRandomNumbers()` - Number insertion
- `replaceLettersWithSymbols()` - Symbol replacement
- `removeRepeatingLetters()` - Duplicate removal
- `generateSecurePassword()` - Complete password generation
- `analyzeComplexity()` - Kolmogorov complexity analysis

## Requirements

- Swift 5.0+
- macOS/Linux compatible
- No external dependencies

## Installation Locations

The installer automatically chooses the best location:
1. `/usr/local/bin` (system-wide, requires sudo)
2. `~/.local/bin` (user-specific)
3. `~/bin` (fallback)

## Files

- `main.swift` - Core implementation
- `build_production.sh` - Production build script
- `install.sh` - Installation script
- `Makefile` - Advanced build system
- `catNamesText.txt` - Source cat names file (16,926 names)
- `embedded_production.swift` - Generated embedded names (1000 names)

## Contributing

The project follows a simple, testable architecture. All functions are isolated and can be tested independently. Run tests with `meowpass --test` to verify functionality.