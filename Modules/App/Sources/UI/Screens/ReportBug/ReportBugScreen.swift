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

struct ReportBugScreen: View {
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSummaryFocused: Bool
    @StateObject private var store: ReportBugStateStore

    init(state: ReportBugState = .initial) {
        self._store = .init(wrappedValue: .init(state: state))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    VStack(spacing: DS.Spacing.extraLarge) {
                        Text("Reports are not end-to-end encrypted, please do not send any sensitive information.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .padding(.top, DS.Spacing.standard)
                            .foregroundStyle(DS.Color.Text.weak)
                            .id(ReportBugScrollToElements.topInfoText)
                        FormMultilineTextInput(
                            title: "Summary (required)",
                            placeholder: "Example: Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                            text: text(keyPath: \.summary),
                            validation: $store.state.summaryValidation
                        )
                        .focused($isSummaryFocused)
                        FormMultilineTextInput(
                            title: "Expected results",
                            placeholder: "Example: Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                            text: text(keyPath: \.expectedResults),
                            validation: .noValidation
                        )
                        FormMultilineTextInput(
                            title: "Steps to reproduce",
                            placeholder: "Example: Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                            text: text(keyPath: \.stepsToReproduce),
                            validation: .noValidation
                        )
                        FormMultilineTextInput(
                            title: "Actual result",
                            placeholder: "Example: Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                            text: text(keyPath: \.actualResults),
                            validation: .noValidation
                        )
                        FormSwitchView(
                            title: "Send error logs",
                            isOn: sendErrorLogsToggle
                        )
                    }
                    .disabled(store.state.isLoading)
                    .animation(.easeInOut(duration: 0.2), value: store.state.summaryValidation)
                    .padding(.horizontal, DS.Spacing.large)
                    VStack(spacing: DS.Spacing.large) {
                        Text("A log is a type of file that shows us the actions you took that led to an error. We’ll only ever use them to help our engineers fix bugs.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.footnote)
                            .foregroundStyle(DS.Color.Text.weak)
                        if !store.state.sendLogsEnabled {
                            Text("Error logs help us to get to the bottom of your issue. If you don't include them, we might not be able to investigate fully.")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.footnote)
                                .foregroundStyle(DS.Color.Text.norm)
                                .id(ReportBugScrollToElements.bottomInfoText)
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: store.state.sendLogsEnabled)
                    .padding(.vertical, DS.Spacing.standard)
                    .padding(.horizontal, DS.Spacing.huge)
                }
                .navigationTitle("Report a problem")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if store.state.isLoading {
                            ProgressView()
                                .tint(DS.Color.Text.accent)
                        } else {
                            Button(action: {
                                store.handle(action: .submit)
                            }) {
                                Text("Submit")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(DS.Color.Text.accent)
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { dismiss.callAsFunction() }) {
                            Image(DS.Icon.icCross)
                                .square(size: 20)
                                .tint(DS.Color.Text.weak)
                        }
                        .disabled(store.state.isLoading)
                    }
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

    private func text(keyPath: WritableKeyPath<ReportBugState, String>) -> Binding<String> {
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
    ReportBugScreen()
}
