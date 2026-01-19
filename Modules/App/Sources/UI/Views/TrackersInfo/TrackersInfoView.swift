// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

struct TrackersInfoView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    let state: TrackersInfoViewStore.State

    var body: some View {
        StoreView(
            store: TrackersInfoViewStore(
                state: state,
                openUrl: openURL,
                dismiss: dismiss
            )
        ) { state, store in
            ClosableScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.large) {
                        header()

                        if state.trackers.totalTrackersCount > 0 {
                            trackersSection(state: state, store: store)
                        }

                        if state.trackers.totalLinksCount > 0 {
                            linksSection(state: state, store: store)
                        }

                        Button(action: { store.handle(action: .onGotItTap) }) {
                            Text(CommonL10n.gotIt)
                        }
                        .buttonStyle(BigButtonStyle())
                        .padding(.top, DS.Spacing.large)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DS.Spacing.extraLarge)
                }
                .background(DS.Color.BackgroundInverted.norm)
            }
        }
    }
}

private extension TrackersInfoView {
    func header() -> some View {
        VStack(alignment: .leading) {
            Image(symbol: .checkmarkShieldFill)
                .resizable()
                .square(size: 32)
                .tint(DS.Color.Icon.norm)
                .padding(DS.Spacing.extraLarge)
                .background {
                    RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                        .fill(DS.Color.Background.deep)
                }

            Text(L10n.MessageDetails.trackerProtection)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.norm)

            Text(L10n.TrackingInfo.description)
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.weak)
                .tint(DS.Color.Text.accent)
                .padding(.top, -DS.Spacing.compact)
        }
    }

    func sectionSummary(title: String, isExpanded: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)

                Spacer()

                Image(DS.Icon.icChevronTinyDown)
                    .resizable()
                    .square(size: 32)
                    .tint(DS.Color.Icon.norm)
                    .rotationEffect(.degrees(isExpanded ? -180 : 0))
            }
            .padding(DS.Spacing.large)
        }
        .background {
            UnevenRoundedRectangle.top(isSectionExpanded: isExpanded)
                .fill(DS.Color.BackgroundInverted.secondary)
        }
        .zIndex(1)
    }

    // MARK: trackers

    func trackersSection(state: TrackersInfoViewStore.State, store: TrackersInfoViewStore) -> some View {
        VStack(spacing: 0) {
            sectionSummary(title: state.trackers.titleForTrackersSection, isExpanded: state.isTrackersSectionExpanded) {
                store.handle(action: .onSectionTap(section: .blockedTrackers))
            }

            if state.isTrackersSectionExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(state.trackers.blockedTrackers.enumerated()), id: \.element.name) { index, domain in
                        trackerCell(domain: domain) { url in
                            store.handle(action: .onBlockedTrackerTap(domain: domain.name, url: url))
                        }
                    }
                }
                .background {
                    UnevenRoundedRectangle.bottom
                        .fill(DS.Color.BackgroundInverted.secondary)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert(
            state.presentedBlockedTracker.domain,
            isPresented: Binding(
                get: { state.isBlockedTrackerPresented },
                set: { _ in store.handle(action: .onBlockedTrackerAlertDismiss) }
            )
        ) {
            Button(CommonL10n.ok.string, role: .cancel) {}
        } message: {
            Text(state.presentedBlockedTracker.url)
                .multilineTextAlignment(.leading)
                .foregroundStyle(DS.Color.Text.norm)
        }
        .clipped()
    }

    func trackerCell(domain: TrackerDomain, onUrlTap: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            HStack {
                Text(domain.name)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)

                Spacer()
                Text(String(domain.urls.count))
                    .frame(width: 32)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)
            }

            ForEach(domain.urls, id: \.self) { url in
                Button(action: { onUrlTap(url) }) {
                    Text(url)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .font(.footnote)
                        .foregroundStyle(DS.Color.Text.weak)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.medium)
        .overlay(alignment: .top) {
            Divider()
                .background(DS.Color.Border.norm)
        }
    }

    // MARK: links

    func linksSection(state: TrackersInfoViewStore.State, store: TrackersInfoViewStore) -> some View {
        VStack(spacing: 0) {
            sectionSummary(title: state.trackers.titleForLinksSection, isExpanded: state.isLinksSectionExpanded) {
                store.handle(action: .onSectionTap(section: .links))
            }

            if state.isLinksSectionExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(state.trackers.cleanedLinks.enumerated()), id: \.element.original) { index, link in
                        linkCell(link: link) { url in
                            store.handle(action: .onLinkTap(url: url))
                        }
                    }
                }
                .background {
                    UnevenRoundedRectangle.bottom
                        .fill(DS.Color.BackgroundInverted.secondary)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipped()
    }

    func linkCell(link: CleanedLink, onUrlTap: @escaping ((String) -> Void)) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            linkCellRow(title: L10n.TrackingInfo.original, showArrow: false, url: link.original) {
                onUrlTap(link.original)
            }

            Divider()
                .background(DS.Color.Border.norm)
                .padding(.leading, DS.Spacing.large)

            linkCellRow(title: L10n.TrackingInfo.cleaned, showArrow: true, url: link.cleaned) {
                onUrlTap(link.cleaned)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DS.Spacing.medium)
        .overlay(alignment: .top) {
            Divider()
                .background(DS.Color.Border.norm)
        }
    }

    func linkCellRow(title: LocalizedStringResource, showArrow: Bool, url: String, onUrlTap: @escaping (() -> Void)) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    if showArrow {
                        Image(systemName: "arrow.turn.down.right")
                            .resizable()
                            .square(size: 13)
                            .foregroundStyle(DS.Color.Text.weak)
                            .padding(.trailing, DS.Spacing.small)
                    }

                    Text(title)
                        .font(.footnote)
                        .foregroundStyle(DS.Color.Text.weak)
                }

                Text(url)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onUrlTap) {
                Image(DS.Icon.icArrowOutSquare)
                    .resizable()
                    .square(size: 20)
                    .foregroundStyle(DS.Color.Icon.hint)
                    .square(size: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, DS.Spacing.large)
    }
}

private extension UnevenRoundedRectangle {
    static func top(isSectionExpanded: Bool) -> Self {
        UnevenRoundedRectangle(
            topLeadingRadius: DS.Radius.extraLarge,
            bottomLeadingRadius: isSectionExpanded ? 0 : DS.Radius.extraLarge,
            bottomTrailingRadius: isSectionExpanded ? 0 : DS.Radius.extraLarge,
            topTrailingRadius: DS.Radius.extraLarge
        )
    }

    static var bottom: Self {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: DS.Radius.extraLarge,
            bottomTrailingRadius: DS.Radius.extraLarge,
            topTrailingRadius: 0
        )
    }
}

private extension TrackersUIModel {
    var titleForTrackersSection: String {
        L10n.MessageDetails.trackersBlocked(count: totalTrackersCount).string
    }

    var titleForLinksSection: String {
        L10n.MessageDetails.linksCleaned(count: totalLinksCount).string
    }
}

#Preview {
    TrackersInfoView(
        state: .init(
            trackers: .init(
                blockedTrackers: [
                    .init(
                        name: "amazon.com",
                        urls: [
                            "https://rd.goodreads.com/gp/r.html?C=B0UBQXVGFW3D&K=2IOEE0DV0PKRM&MFWFEERFKOINAPEFWEFBSF",
                            "https://rd.goodreads.com/gp/r.html?C=IOBEVIBIQQWIB",
                        ]),
                    .init(name: "facebook.com", urls: ["facebook.com/tracker"]),
                    .init(
                        name: "google.com",
                        urls: [
                            "https://www.google.com/search?q=junk&client=safari&hs=iQf9&sca_esv=0ccf53d8b4904cec&source=hp&ei=qRxEaZCQPLTFi-gPn5qF4A8",
                            "https://www.google.com/search?q=junk",
                        ]),
                ],
                cleanedLinks: [
                    .init(
                        original: "https://www.google.com?query=ads+are+for+everyone+to+enjoy",
                        cleaned: "https://www.google.com"
                    )
                ])
        )
    )
}
