# MeowPassword 🐾

A command-line utility that generates secure, random passwords based on a database of cat names using Kolmogorov complexity analysis to select the most secure option.

## Features

- 🐱 Uses 16,926+ cat names as the base for password generation
- 🔐 Generates passwords with 15-25 characters meeting strict security requirements
- 🧮 Evaluates password complexity using Kolmogorov complexity algorithms
- 🎯 Selects the most secure password from 5 candidates
- 📋 Supports clipboard copying (macOS only)
- 📊 Provides detailed complexity analysis

## Password Security Specifications

Each generated password meets these requirements:

- **Length**: 15-25 characters from 3-5 cat names
- **Capitalization**: 3 letters randomly capitalized
- **Numbers**: 3-5 numbers inserted randomly
- **Symbols**: 2 symbols randomly replacing letters
- **Uniqueness**: Repeating letters replaced with random digits

## Installation

1. Clone the repository:
```bash
git clone https://github.com/SpaceTrucker2196/MeowPassword.git
cd MeowPassword
```

2. Build the project:
```bash
swift build -c release
```

## Usage

### Basic Usage
Generate a secure password:
```bash
swift run meowpass
```

### Options
- `--verbose`: Show detailed analysis for all 5 candidates
- `--copy`: Copy the selected password to clipboard (macOS only)

### Examples

Generate a password with verbose output:
```bash
swift run meowpass --verbose
```

Generate and copy to clipboard:
```bash
swift run meowpass --copy
```

## Sample Output

```
🐱 Loaded 16926 cat names
🔄 Generating 5 secure password candidates...

🔐 Candidate 1: Vo0d37san4lerc:107?i2 16Hub7
   Complexity Score: 1.79/10.0

🔐 Candidate 2: geh9N57a (73Br53[ 3fo[ "70L9
   Complexity Score: 1.66/10.0

🔐 Candidate 3: dUnc6a- 7o6994rmE65{b4l477196
   Complexity Score: 1.67/10.0

🔐 Candidate 4: az8%litchy8 b2r1o86E06m21%U32
   Complexity Score: 1.74/10.0

🔐 Candidate 5: pa0nc6&e8ri@ v39 W76kl40j493
   Complexity Score: 1.75/10.0

🏆 Most Secure Password Selected:
🔐 Vo0d37san4lerc:107?i2 16Hub7
📊 Final Complexity Score: 1.79/10.0

🔍 Kolmogorov Complexity Analysis:

📊 Overall Complexity Score: 1.79/10.0

📈 Component Analysis:
• Shannon Entropy: 4.495 bits
• Compression Resistance: -3.6%
• Pattern Uniqueness: 100.0%
• Character Diversity: 100.0%

🎯 Character Composition:
• Length: 28 characters
• Unique Characters: 24
• Lowercase Letters: ✅
• Uppercase Letters: ✅
• Digits: ✅
• Symbols: ✅

💡 Complexity Interpretation: Very Low - Highly predictable pattern
```

## Algorithm Details

### Kolmogorov Complexity Analysis

The password selection uses multiple complexity metrics:

1. **Shannon Entropy**: Measures character distribution randomness
2. **Compression Resistance**: Approximates algorithmic complexity
3. **Pattern Uniqueness**: Analyzes substring repetition
4. **Character Diversity**: Evaluates character set usage
5. **Length Normalization**: Accounts for password length

### Password Generation Process

1. Load cat names from `catNamesText.txt`
2. Select 3-5 random cat names
3. Create base phrase (15-25 characters)
4. Apply security transformations:
   - Random capitalization (3 letters)
   - Number insertion (3-5 random digits)
   - Symbol replacement (2 random symbols)
   - Remove repeating letters with digits
5. Generate 5 candidates using this process
6. Analyze each with Kolmogorov complexity
7. Select the most complex/secure password

## Testing

Run the test suite:
```bash
swift test
```

The project includes comprehensive unit tests and integration tests covering:
- Cat name loading
- Password generation algorithms
- Kolmogorov complexity analysis
- End-to-end password generation workflow

## Requirements

- Swift 5.8+
- macOS (for clipboard functionality) or Linux

## License

This project is open source. See LICENSE file for details.