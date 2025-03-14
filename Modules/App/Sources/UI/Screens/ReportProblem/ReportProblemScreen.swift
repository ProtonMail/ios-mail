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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct ReportProblemScreen: View {
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSummaryFocused: Bool
    @StateObject private var store: ReportProblemStateStore

    init(state: ReportProblemState = .initial) {
        self._store = .init(wrappedValue: .init(state: state))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    reportProblemForm()
                        .disabled(store.state.isLoading)
                        .animation(.easeInOut(duration: 0.2), value: store.state.summaryValidation)
                        .padding(.horizontal, DS.Spacing.large)

                    VStack(spacing: DS.Spacing.large) {
                        Text(L10n.ReportProblem.logsInfo)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.footnote)
                            .foregroundStyle(DS.Color.Text.weak)
                        if !store.state.sendLogsEnabled {
                            Text(L10n.ReportProblem.logsAdditionalInfo)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.footnote)
                                .foregroundStyle(DS.Color.Text.norm)
                                .id(ReportProblemScrollToElements.bottomInfoText)
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: store.state.sendLogsEnabled)
                    .padding(.vertical, DS.Spacing.standard)
                    .padding(.horizontal, DS.Spacing.huge)
                }
                .navigationTitle(L10n.ReportProblem.mainTitle.string)
                .toolbar {
                    toolbarLeadingItem()
                    toolbarTrailingItem()
                }
                .onChange(of: store.state.scrollTo) { _, newValue in
                    if let newValue {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(newValue, anchor: .bottom)
                        } completion: {
                            store.handle(action: .cleanUpScrollingState)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(DS.Color.Background.secondary)
        }
        .onChange(of: store.state.summaryValidation) { _, newValue in
            if case .failure = newValue {
                isSummaryFocused = true
            }
        }
        .onAppear {
            isSummaryFocused = true
        }
        .interactiveDismissDisabled(store.state.isLoading)
    }

    private func reportProblemForm() -> some View {
        VStack(spacing: DS.Spacing.extraLarge) {
            Text(L10n.ReportProblem.generalInfo)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.top, DS.Spacing.standard)
                .foregroundStyle(DS.Color.Text.weak)
                .id(ReportProblemScrollToElements.topInfoText)
            FormMultilineTextInput(
                title: L10n.ReportProblem.summary,
                // FIXME: - Temporary. Waiting for final version
                placeholder: "Example: Mail app crashes opening emails with large attachments.".notLocalized,
                text: text(keyPath: \.summary),
                validation: $store.state.summaryValidation
            )
            .focused($isSummaryFocused)
            FormMultilineTextInput(
                title: L10n.ReportProblem.expectedResults,
                // FIXME: - Temporary. Waiting for final version
                placeholder: "Example: Email opens normally, displaying content and attachments.".notLocalized,
                text: text(keyPath: \.expectedResults),
                validation: .noValidation
            )
            FormMultilineTextInput(
                title: L10n.ReportProblem.stepsToReproduce,
                // FIXME: - Temporary. Waiting for final version
                placeholder: "Example:\n1. Select email with large attachments\n2. Wait for loading.".notLocalized,
                text: text(keyPath: \.stepsToReproduce),
                validation: .noValidation
            )
            FormMultilineTextInput(
                title: L10n.ReportProblem.actualResults,
                // FIXME: - Temporary. Waiting for final version
                placeholder: "Example: App freezes briefly, then crashes without showing email content.".notLocalized,
                text: text(keyPath: \.actualResults),
                validation: .noValidation
            )
            FormSwitchView(
                title: L10n.ReportProblem.sendErrorLogs,
                isOn: sendErrorLogsToggle
            )
        }
    }

    private func toolbarLeadingItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if store.state.isLoading {
                ProgressView()
                    .tint(DS.Color.Text.accent)
            } else {
                Button(action: {
                    store.handle(action: .submit)
                }) {
                    Text(L10n.ReportProblem.submit)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.Text.accent)
                }
            }
        }
    }

    private func toolbarTrailingItem() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { dismiss.callAsFunction() }) {
                Image(DS.Icon.icCross)
                    .square(size: 20)
                    .tint(DS.Color.Text.weak)
            }
            .disabled(store.state.isLoading)
        }
    }

    private func text(keyPath: WritableKeyPath<ReportProblemState, String>) -> Binding<String> {
        .init(
            get: { store.state[keyPath: keyPath] },
            set: { newValue in store.handle(action: .textEntered(keyPath, text: newValue)) }
        )
    }

    private var sendErrorLogsToggle: Binding<Bool> {
        .init(
            get: { store.state.sendLogsEnabled },
            set: { newValue in store.handle(action: .sendLogsToggleSwitched(isEnabled: newValue)) }
        )
    }
}

#Preview {
    ReportProblemScreen()
}
