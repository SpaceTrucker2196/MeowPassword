// Sources/MeowThemeStore/ThemeStore.swift
//
// StoreKit 2 storefront for theme packs (docs/themes/README.md "Billing &
// parity"). Each pack is a one-time non-consumable; ownership is granted from
// verified transactions and mirrored into the App Group defaults through
// ThemeManager so the iMessage/Share extensions (which never link StoreKit)
// render purchased themes too.
//
// Non-App-Store builds (the Developer ID DMG path) have no receipt context:
// Product.products throws there, loadState becomes .failed, and the store UI
// must degrade to "packs locked, no buy button" — free themes always work.

import StoreKit
import MeowUI

@MainActor
public final class ThemeStore: ObservableObject {

    public enum LoadState: Equatable {
        case idle, loading, loaded, failed
    }

    public enum PurchaseOutcome: Equatable {
        case success
        /// Ask-to-buy / deferred approval — the transaction may land later
        /// via `Transaction.updates`.
        case pending
        case cancelled
    }

    /// Storefront products keyed by theme, populated by `loadProducts()`.
    @Published public private(set) var products: [Theme.ID: Product] = [:]
    @Published public private(set) var loadState: LoadState = .idle
    /// The last product-load failure, for diagnostics and the retry UI.
    @Published public private(set) var lastLoadError: String?

    private let themeManager: ThemeManager
    private var updatesTask: Task<Void, Never>?

    public init(themeManager: ThemeManager) {
        self.themeManager = themeManager
        // Lives for the app's lifetime: ask-to-buy approvals, purchases made
        // on another device, and refunds all arrive here.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.apply(update)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    /// Call once at launch (and from a retry affordance). Safe offline —
    /// failure leaves owned/free themes fully usable.
    public func loadProducts() async {
        guard loadState != .loading else { return }
        loadState = .loading
        let ids = Theme.ID.allCases.compactMap(\.productID)
        do {
            let loaded = try await Product.products(for: ids)
            var byTheme: [Theme.ID: Product] = [:]
            for product in loaded {
                if let id = Theme.ID.forProduct(product.id) {
                    byTheme[id] = product
                }
            }
            products = byTheme
            loadState = .loaded
            lastLoadError = nil
        } catch {
            loadState = .failed
            lastLoadError = String(describing: error)
        }
    }

    /// Rebuild ownership from the local entitlement cache (works offline).
    /// Call at launch; also runs after restore and after every update.
    public func refreshEntitlements() async {
        var owned = Set<Theme.ID>()
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  transaction.revocationDate == nil,
                  let id = Theme.ID.forProduct(transaction.productID) else { continue }
            owned.insert(id)
        }
        themeManager.setOwned(owned)
    }

    public func purchase(_ id: Theme.ID) async throws -> PurchaseOutcome {
        guard let product = products[id] else {
            throw StoreKitError.unknown
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                // Failed verification: don't grant, don't finish — StoreKit
                // will redeliver a verifiable transaction if it's genuine.
                return .cancelled
            }
            grant(transaction)
            await transaction.finish()
            return .success
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    /// The required restore-purchases path. `AppStore.sync()` forces a
    /// storefront round-trip (sign-in may be prompted), then entitlements
    /// are rebuilt.
    public func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Private

    private func apply(_ update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else { return }
        if transaction.revocationDate == nil {
            grant(transaction)
        }
        await transaction.finish()
        // Revocations (refunds) and anything else subtle: rebuild the full
        // set rather than reasoning per-case.
        await refreshEntitlements()
    }

    private func grant(_ transaction: Transaction) {
        guard let id = Theme.ID.forProduct(transaction.productID) else { return }
        themeManager.setOwned(themeManager.ownedIDs.union([id]))
    }
}

public extension Theme.ID {
    static func forProduct(_ productID: String) -> Theme.ID? {
        allCases.first { $0.productID == productID }
    }
}
