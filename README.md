# MeowPassword

A command-line utility that generates secure, phrase-based passwords using cat names and Kolmogorov complexity analysis with a lolcat theme.

## Features

- **1000+ Embedded Cat Names** - No external file dependencies
- **Secure Password Generation** - Creates passwords from 3-5 cat names with configurable length (15-50 characters)
- **Advanced Security Transformations**:
  - 3 letters randomly capitalized
  - Configurable numbers inserted randomly (1-10, default: 3-5)
  - Configurable symbols replacing letters (1-10, default: 2)
  - Removes repeating letters with random digits
- **Kolmogorov Complexity Analysis** - Evaluates and selects the most secure password from 5 candidates
- **Lolcat Theme** - ASCII art and professional interface without emojis
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

### Generate Password
```bash
meowpass
```

### Generate with Custom Parameters
```bash
meowpass --numbers 4 --symbols 3 --max-length 30
```

### Run Tests
```bash
meowpass --test
```

### Copy to Clipboard (macOS)
```bash
meowpass --copy
```

### Show Help
```bash
meowpass --help
```

## Sample Output

```
                               __
                         _,-;'''`'-,.
                      _/',  `;  `;    `\
      ,        _..,-''    '   `  `      `\
     | ;._.,,-' .| |,_        ,,          `\
     | `;'      ;' ;, `,   ; |    '  '  .   \
     `; __`  ,'__  ` ,  ` ;  |      ;        \
     ; (6_);  (6_) ; |   ,    \        '      |       /
    ;;   _,' ,.    ` `,   '    `-._           |   __//_________
     ,;.=..`_..=.,' -'          ,''        _,--''------''''
_pb__\,`"=,,,=="',___,,,-----'''----'_'_'_''-;''
-----------------------''''''\  \'''''   )   /'
                              `\`,,,___/__/'_____,
                                `--,,,--,-,'''\  
                               __,,-' /'       `
                             /'_,,--''
                            | (
                             `'

MEOWPASSWORD - Lolcat Secure Password Generator
===============================================
Loaded 1000 cat names
Generating 5 secure password candidates...
Config: 3 numbers, 2 symbols, max length 25

Candidate 1: aMstErd&3(!h-)u82016
   Complexity Score: 1.71/10.0

MOST SECURE PASSWORD SELECTED:
Password: aMstErd&3(!h-)u82016
Final Complexity Score: 1.71/10.0

Kolmogorov Complexity Analysis:
- Password: aMstErd&3(!h-)u82016
- Length: 20 characters
- Shannon Entropy: 4.322 bits
- Compression Resistance: -5.0%
- Pattern Uniqueness: 100.0%
- Character Diversity: 100.0%
- Overall Complexity Score: 1.71/10.0
```

## Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--numbers N` | Number of random numbers to insert (1-10) | 3-5 |
| `--symbols N` | Number of symbols to insert (1-10) | 2 |
| `--max-length N` | Maximum password length (15-50) | 25 |
| `--test` | Run comprehensive tests | - |
| `--copy` | Copy password to clipboard (macOS only) | - |
| `--help` | Show help message | - |

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