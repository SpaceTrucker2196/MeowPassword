// Sources/MeowThemeStore/ThemeStudioView.swift
//
// The Theme Studio: pick a free theme, buy a pack, restore purchases. Shared
// by the iOS sheet and the macOS Settings scene. Each card previews a theme
// with its own floor and role swatches so the shopper sees the costume
// before buying the ticket.

import SwiftUI
import StoreKit
import MeowUI

public struct ThemeStudioView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var store: ThemeStore
    @Environment(\.theme) private var theme

    @State private var purchasing: Theme.ID?
    @State private var pendingNote = false
    @State private var errorText: String?
    @State private var restoring = false

    public init() {}

    public var body: some View {
        ZStack {
            ThemedBackground().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header

                    ForEach(Theme.all) { candidate in
                        ThemeCard(
                            candidate: candidate,
                            isSelected: themeManager.selectedID == candidate.id,
                            isOwned: candidate.id.isFree || themeManager.ownedIDs.contains(candidate.id),
                            product: store.products[candidate.id],
                            loadState: store.loadState,
                            isPurchasing: purchasing == candidate.id,
                            select: { themeManager.selectedID = candidate.id },
                            buy: { purchase(candidate.id) },
                            retry: { Task { await store.loadProducts() } }
                        )
                    }

                    if pendingNote {
                        note("PURCHASE PENDING",
                             detail: "Waiting for approval — your pack unlocks automatically once it's confirmed.")
                    }
                    if let errorText {
                        note("STORE HICCUP", detail: LocalizedStringKey(errorText), isError: true)
                    }

                    restoreFooter
                }
                .padding(16)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(theme.celebrate)
                .shadow(color: theme.bind, radius: 0, x: 1, y: 1)
            Text("THEME STUDIO")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(theme.textOnFloor)
                .shadow(color: theme.bind, radius: 0, x: 2, y: 2)
            Spacer()
        }
    }

    private var restoreFooter: some View {
        HStack {
            Button {
                restore()
            } label: {
                Label("RESTORE PURCHASES", systemImage: "arrow.clockwise")
            }
            .buttonStyle(NeonButton(fill: theme.cool, text: theme.textOnCommand))
            .disabled(restoring)
            .opacity(restoring ? 0.6 : 1)
        }
        .padding(.top, 4)
    }

    private func note(_ title: LocalizedStringKey, detail: LocalizedStringKey, isError: Bool = false) -> some View {
        GamePanel(tint: isError ? theme.danger : theme.celebrate) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(isError ? theme.danger : theme.bind)
                Text(detail)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.bind.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func purchase(_ id: Theme.ID) {
        guard purchasing == nil else { return }
        purchasing = id
        errorText = nil
        Task {
            defer { purchasing = nil }
            do {
                switch try await store.purchase(id) {
                case .success:
                    themeManager.selectedID = id
                case .pending:
                    pendingNote = true
                case .cancelled:
                    break
                }
            } catch {
                errorText = error.localizedDescription
            }
        }
    }

    private func restore() {
        restoring = true
        errorText = nil
        Task {
            defer { restoring = false }
            do { try await store.restore() }
            catch { errorText = error.localizedDescription }
        }
    }
}

// MARK: - Card

private struct ThemeCard: View {
    let candidate: Theme
    let isSelected: Bool
    let isOwned: Bool
    let product: Product?
    let loadState: ThemeStore.LoadState
    let isPurchasing: Bool
    let select: () -> Void
    let buy: () -> Void
    let retry: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey(candidate.nameKey))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: candidate.palette.textOnFloor))
                Spacer()
                trailingBadge
            }
            swatches
            HStack(spacing: 6) {
                Text(candidate.sealCaption)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color(hex: candidate.palette.textOnFloor).opacity(0.65))
                Spacer()
                if isOwned && !isSelected {
                    Button("USE IT!", action: select)
                        .buttonStyle(NeonButton(fill: Color(hex: candidate.palette.command),
                                                text: Color(hex: candidate.palette.textOnCommand)))
                        .frame(maxWidth: 130)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: candidate.palette.floor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? theme.celebrate : theme.bind, lineWidth: isSelected ? 4 : 2)
        )
        .compositingGroup()
        .shadow(color: theme.bind.opacity(0.45), radius: 0, x: 4, y: 5)
        .contentShape(Rectangle())
        .onTapGesture { if isOwned { select() } }
        .rotationEffect(.degrees(isSelected ? -0.6 : 0))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }

    /// The six semantic roles, worn on the candidate's own floor.
    private var swatches: some View {
        HStack(spacing: 6) {
            swatch(candidate.palette.command)
            swatch(candidate.palette.celebrate)
            swatch(candidate.palette.cool)
            swatch(candidate.palette.surface)
            swatch(candidate.palette.seal)
            swatch(candidate.palette.bind)
            Spacer()
        }
    }

    private func swatch(_ hex: UInt32) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color(hex: hex))
            .frame(width: 26, height: 26)
            .overlay(RoundedRectangle(cornerRadius: 5)
                .stroke(Color(hex: candidate.palette.bind).opacity(0.6), lineWidth: 1.5))
    }

    @ViewBuilder
    private var trailingBadge: some View {
        if isSelected {
            stamp("SELECTED", fill: Color(hex: candidate.palette.seal))
        } else if candidate.id.isFree {
            stamp("FREE", fill: Color(hex: candidate.palette.cool))
        } else if isOwned {
            stamp("OWNED", fill: Color(hex: candidate.palette.positive))
        } else if let product {
            Button {
                buy()
            } label: {
                Text(isPurchasing ? "…" : product.displayPrice)
            }
            .buttonStyle(NeonButton(fill: Color(hex: candidate.palette.command),
                                    text: Color(hex: candidate.palette.textOnCommand)))
            .frame(maxWidth: 110)
            .disabled(isPurchasing)
        } else if loadState == .failed {
            Button {
                retry()
            } label: {
                Label("RETRY", systemImage: "lock.fill")
            }
            .buttonStyle(NeonButton(fill: Color(hex: candidate.palette.cool),
                                    text: Color(hex: candidate.palette.textOnCommand)))
            .frame(maxWidth: 120)
        } else {
            ProgressView().controlSize(.small)
        }
    }

    private func stamp(_ text: LocalizedStringKey, fill: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(Color(hex: candidate.palette.textOnCommand))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(fill)
                .overlay(Capsule().stroke(Color(hex: candidate.palette.bind), lineWidth: 1.5)))
            .rotationEffect(.degrees(isSelected ? -4 : 0))
    }
}
