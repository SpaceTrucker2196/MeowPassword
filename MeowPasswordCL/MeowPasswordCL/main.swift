//
//  main.swift
//  MeowPassword
//
//  Created by Jeffrey Kunzelman on 8/24/15.
//

import Foundation
import ArgumentParser
import AppKit

struct MeowPassword: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "🐾 Generate a secure, random password with options"
    )

    @Option(name: [.short, .long], help: "Length of the password (default: 16)")
    var length: Int = 16

    @Flag(name: .long, help: "Exclude symbols from the password")
    var noSymbols: Bool = false

    @Flag(name: .long, help: "Use numbers only")
    var numbersOnly: Bool = false

    @Flag(name: .long, help: "Copy password to clipboard (macOS only)")
    var copy: Bool = false

    func run() throws {
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*()-_=+[]{}|;:,.<>?"

        let charset: String = {
            switch (numbersOnly, noSymbols) {
            case (true, _): return numbers
            case (_, true): return lowercase + uppercase + numbers
            default: return lowercase + uppercase + numbers + symbols
            }
        }()

        guard !charset.isEmpty else {
            print("❌ Character set is empty. Cannot generate password.")
            return
        }

        let password = (0..<length)
            .compactMap { _ in charset.randomElement() }
            .map(String.init)
            .joined()

        print("🔐 \(password)")

        if copy {
            #if os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(password, forType: .string)
            print("📋 Copied to clipboard.")
            #else
            print("❌ Clipboard copy is only supported on macOS.")
            #endif
        }
    }
}

MeowPassword.main()
