# MeowPassword 🐾

A simple command-line utility that generates secure, phrase-based passwords using cat names and Kolmogorov complexity analysis.

## Features

- 🐱 Uses 16,926+ cat names from `catNamesText.txt`
- 🔐 Generates secure passwords (15-25 characters) from 3-5 cat names
- 🔧 Applies security transformations:
  - 3 letters randomly capitalized
  - 3-5 numbers inserted randomly
  - 2 symbols replacing letters
  - Removes repeating letters with random digits
- 🧮 Analyzes password complexity using Kolmogorov algorithms
- 🎯 Selects the most secure password from 5 candidates
- 📋 Clipboard support (macOS only)

## Usage

### Generate Password
```bash
swift MeowPassword/main.swift
```

### Copy to Clipboard
```bash
swift MeowPassword/main.swift --copy
```

### Run Tests
```bash
swift MeowPassword/main.swift --test
```

## Implementation Details

The password generator follows these steps:

1. **Load Cat Names**: Reads names from `catNamesText.txt`
2. **Select Names**: Randomly picks 3-5 cat names
3. **Create Base Phrase**: Joins names to create 15-25 character phrase
4. **Apply Transformations**: 
   - Randomly capitalize 3 letters
   - Insert 3-5 random numbers
   - Replace 2 letters with symbols
   - Remove repeating letters (replace with digits)
5. **Generate 5 Candidates**: Repeat process 5 times
6. **Analyze Complexity**: Use Kolmogorov complexity metrics
7. **Select Best**: Choose password with highest complexity score

## Complexity Analysis

The Kolmogorov complexity evaluation includes:

- **Shannon Entropy**: Character distribution randomness
- **Compression Resistance**: Algorithmic complexity approximation  
- **Pattern Uniqueness**: Substring repetition analysis
- **Character Diversity**: Usage of different character types
- **Length Normalization**: Accounts for password length

## Functions

Each step is implemented as a separate, testable function:

- `loadCatNames(from:)` - Loads cat names from file
- `selectRandomCatNames(from:count:)` - Randomly selects names
- `createBasePhrase(from:)` - Creates base phrase
- `randomlyCapitalizeLetters(in:count:)` - Capitalizes letters
- `insertRandomNumbers(into:count:)` - Inserts random numbers
- `replaceLettersWithSymbols(in:count:)` - Replaces with symbols
- `removeRepeatingLetters(in:)` - Removes duplicate letters
- `generateSecurePassword(from:)` - Complete password generation
- `analyzeComplexity(of:)` - Kolmogorov complexity analysis

## Requirements

- Swift 5.0+
- `catNamesText.txt` file in the same directory

## Sample Output

```
🐾 MeowPassword Generator
📝 Loaded 16926 cat names
🔄 Generating 5 secure password candidates...

🔐 Candidate 1: judg7Es4c8^a15r60m?3
   Complexity Score: 1.71/10.0

🏆 Most Secure Password Selected:
🔐 ke0i;< (f6n235sh 5o64r "cat")
📊 Final Complexity Score: 1.75/10.0

Kolmogorov Complexity Analysis:
- Password: ke0i;< (f6n235sh 5o64r "cat")
- Length: 29 characters
- Shannon Entropy: 4.487 bits
- Compression Resistance: -3.4%
- Pattern Uniqueness: 100.0%
- Character Diversity: 75.0%
- Overall Complexity Score: 1.75/10.0
```