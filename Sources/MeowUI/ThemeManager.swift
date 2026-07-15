// Sources/MeowUI/ThemeManager.swift
//
// Owns theme selection and pack ownership. State persists to the shared App
// Group defaults so the iMessage and Share extensions render the same theme
// the app selected — extensions never talk to StoreKit, they just read these
// flags (and call `reload()` on appear, since purchases can land while the
// extension process isn't running).

import SwiftUI

@MainActor
public final class ThemeManager: ObservableObject {

    public static let appGroupID = "group.io.river.MeowPassword"
    public static let selectedKey = "theme.selected"
    public static let ownedKey = "theme.owned"

    /// Flips to `.showa` when the Shōwa migration lands (Phase 3).
    static let defaultThemeID: Theme.ID = .gameShowClassic

    private let defaults: UserDefaults

    /// The user's chosen theme. May name a pack they no longer own (refund);
    /// `current` handles the fallback so the choice survives a repurchase.
    @Published public var selectedID: Theme.ID {
        didSet { defaults.set(selectedID.rawValue, forKey: Self.selectedKey) }
    }

    /// Packs the user owns. Free themes are never listed — they're always
    /// available. Written by the store layer via `setOwned`.
    @Published public private(set) var ownedIDs: Set<Theme.ID>

    /// The theme to render: the selection when it's free or owned, otherwise
    /// the default (covers refunds/revocations discovered at launch).
    public var current: Theme {
        let theme = Theme.theme(for: selectedID)
        return (theme.id.isFree || ownedIDs.contains(theme.id))
            ? theme : Theme.theme(for: Self.defaultThemeID)
    }

    /// Pass explicit `defaults` only in tests. Falls back to `.standard` when
    /// the app group suite is unavailable (SwiftPM builds, the sandboxed Mac
    /// App Store target — macOS has no extensions, so nothing needs sharing).
    public init(defaults: UserDefaults? = nil) {
        let d = defaults ?? UserDefaults(suiteName: Self.appGroupID) ?? .standard
        self.defaults = d
        self.selectedID = Self.storedSelection(in: d)
        self.ownedIDs = Self.storedOwnership(in: d)
    }

    /// Re-read shared state — extensions call this on appear, apps on
    /// foreground, so a purchase made elsewhere shows up.
    public func reload() {
        selectedID = Self.storedSelection(in: defaults)
        ownedIDs = Self.storedOwnership(in: defaults)
    }

    /// Replace the owned set (the store layer's entitlement refresh).
    public func setOwned(_ ids: Set<Theme.ID>) {
        ownedIDs = ids
        defaults.set(ids.map(\.rawValue).sorted(), forKey: Self.ownedKey)
    }

    private static func storedSelection(in defaults: UserDefaults) -> Theme.ID {
        #if DEBUG
        // QA/UI tests: `-theme spyThriller` forces a theme at launch.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-theme"), i + 1 < args.count,
           let forced = Theme.ID(rawValue: args[i + 1]) {
            return forced
        }
        #endif
        return defaults.string(forKey: selectedKey)
            .flatMap(Theme.ID.init(rawValue:)) ?? defaultThemeID
    }

    private static func storedOwnership(in defaults: UserDefaults) -> Set<Theme.ID> {
        #if DEBUG
        // `-ownAllThemes` unlocks every pack for QA without StoreKit.
        if ProcessInfo.processInfo.arguments.contains("-ownAllThemes") {
            return Set(Theme.ID.allCases)
        }
        #endif
        return Set((defaults.stringArray(forKey: ownedKey) ?? [])
            .compactMap(Theme.ID.init(rawValue:)))
    }
}
