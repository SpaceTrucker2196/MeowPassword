# MeowPassword

A command-line utility that generates secure, phrase-based passwords using cat names and Kolmogorov complexity analysis with a delightful cat theme.

## Features

- **🎨 Random ASCII Art Cats** - Displays a different adorable cat on each run for a delightful experience
- **1000+ Embedded Cat Names** - No external file dependencies
- **Secure Password Generation** - Creates passwords from 3-5 cat names with configurable length (15-50 characters)
- **Advanced Security Transformations**:
  - 3 letters randomly capitalized
  - Configurable numbers inserted randomly (1-10, default: 3-5)
  - Configurable symbols replacing letters (1-10, default: 2)
  - Removes repeating letters with random digits
- **Kolmogorov Complexity Analysis** - Evaluates and selects the most secure password from 5 candidates
- **Modern CLI Arguments** - Support for both long (`--option`) and short (`-o`) option formats
- **Configurable Parameters** - Control numbers, symbols, and maximum length
- **Clipboard Support** - Copy to clipboard (macOS only)
- **Self-Contained Executable** - Single binary with embedded data

## Quick Start

### Build and Install (Recommended)
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

### Alternative Build (using build.sh)
```bash
# Build using alternative script
./build.sh

# Use locally
./meowpass
```

## Usage

### Generate Password (Default Settings)
```bash
meowpass
```

Each run displays a random ASCII art cat! The program will:
1. Show a random cat ASCII art (6 different cats available)
2. Generate 5 password candidates using cat names
3. Analyze each candidate's security using Kolmogorov complexity
4. Select and display the most secure password

### Generate with Custom Parameters

Using long options:
```bash
meowpass --numbers 4 --symbols 3 --max-length 30
```

Using short options:
```bash
meowpass -n 4 -s 3 -m 35
```

Mix and match:
```bash
meowpass -n 5 --symbols 4 -m 40
```

### Run Tests
```bash
meowpass --test
# or
meowpass -t
```

### Copy to Clipboard (macOS)
```bash
meowpass --copy
# or
meowpass -c
```

### Show Help
```bash
meowpass --help
# or
meowpass -h
```

## ASCII Art Feature

MeowPassword includes 6 different ASCII art cats that are randomly displayed each time you run the program:
- 🎨 Original detailed lolcat
- 🐱 Sitting cat
- 😸 Happy cat  
- 😺 Stretching cat
- 😻 Playful cat
- 😴 Sleeping cat

Each cat comes with its own personality and makes password generation more enjoyable!

## Command-Line Options

MeowPassword supports both long and short option formats for convenience:

| Long Option | Short | Description | Default |
|-------------|-------|-------------|---------|
| `--numbers N` | `-n N` | Number of random numbers to insert (1-10) | 1-4 (random) |
| `--symbols N` | `-s N` | Number of symbols to insert (1-10) | 2 |
| `--max-length N` | `-m N` | Maximum password length (15-50) | 25 |
| `--test` | `-t` | Run comprehensive tests | - |
| `--copy` | `-c` | Copy password to clipboard (macOS only) | - |
| `--help` | `-h` | Show detailed help message | - |

### Option Details

**Numbers (`-n`, `--numbers`)**
- Controls how many random digits (0-9) are inserted into the password
- Range: 1-10
- Default: Randomly chosen between 1-4 for variety
- Example: `-n 4` inserts exactly 4 random digits

**Symbols (`-s`, `--symbols`)**
- Controls how many special characters replace letters
- Range: 1-10
- Default: 2
- Available symbols: `!@#$%^&*()-_=+[]{;:.<>?`
- Example: `-s 3` replaces 3 letters with random symbols

**Max Length (`-m`, `--max-length`)**
- Sets the maximum length of the generated password
- Range: 15-50 characters
- Default: 25
- The password will not exceed this length
- Example: `-m 30` limits password to 30 characters

### Usage Examples

Generate a short, simple password:
```bash
meowpass -n 2 -s 1 -m 20
```

Generate a long, complex password:
```bash
meowpass --numbers 8 --symbols 6 --max-length 45
```

Generate and immediately copy to clipboard (macOS):
```bash
meowpass -n 5 -s 4 -c
```

View help for all options:
```bash
meowpass -h
```

## Build System

The project includes multiple build options:

- **`build_production.sh`** - Recommended production build with 1000 embedded cat names
- **`build.sh`** - Alternative build script with comprehensive testing
- **`Makefile`** - Advanced build system with multiple targets
- **`install.sh`** - System-wide installation script

### Build Validation

Both build scripts work as documented:

```bash
# Test production build
./build_production.sh && ./meowpass --test

# Test alternative build  
./build.sh && ./meowpass --test
```

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
1. **Load Cat Names** - Uses embedded 1000+ cat names (no external files required)
2. **Select Names** - Randomly picks 3-5 cat names  
3. **Create Base Phrase** - Joins names within length constraints
4. **Apply Transformations**:
   - Random capitalization (3 letters)
   - Number insertion (configurable, default 3-5)
   - Symbol replacement (configurable, default 2)
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
- `selectRandomCatNames(from:count:)` - Random name selection
- `createBasePhrase(from:maxLength:)` - Base phrase creation with length control
- `randomlyCapitalizeLetters(in:count:)` - Capitalization transformation
- `insertRandomNumbers(into:count:)` - Number insertion
- `replaceLettersWithSymbols(in:count:)` - Symbol replacement
- `removeRepeatingLetters(in:)` - Duplicate removal
- `generateSecurePassword(from:config:)` - Complete password generation
- `analyzeComplexity(of:)` - Kolmogorov complexity analysis

## Requirements

- Swift 5.0+
- macOS/Linux compatible
- No external dependencies (pure Foundation)

## Installation Locations

The installer automatically chooses the best location:
1. `/usr/local/bin` (system-wide, requires sudo)
2. `~/.local/bin` (user-specific)
3. `~/bin` (fallback)

## Files

- `main.swift` - Core implementation with comprehensive documentation
- `build_production.sh` - Production build script (recommended)
- `build.sh` - Alternative build script
- `install.sh` - Installation script
- `Makefile` - Advanced build system
- `catNamesText.txt` - Source cat names file (16,926 names)
- `embedded_production.swift` - Generated embedded names (1000 names)

## Testing

Run comprehensive tests to verify all functionality:

```bash
# Test embedded cat name loading
# Test password generation with all security transformations
# Test Kolmogorov complexity analysis
# Test configuration parameter handling
./meowpass --test
```

## Contributing

The project follows a simple, testable architecture with comprehensive documentation. All functions are isolated and can be tested independently. Each function includes detailed comments explaining its purpose and parameters.
