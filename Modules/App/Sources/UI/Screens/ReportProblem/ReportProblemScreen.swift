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
import proton_app_uniffi
import SwiftUI

struct ReportProblemScreen: View {
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSummaryFocused: Bool
    @EnvironmentObject private var toastStateStore: ToastStateStore

    private let state: ReportProblemState
    private let reportProblemService: ReportProblemService

    init(
        state: ReportProblemState = .initial,
        reportProblemService: ReportProblemService
    ) {
        self.state = state
        self.reportProblemService = reportProblemService
    }

    var body: some View {
        StoreView(
            store: ReportProblemStateStore(
                state: state,
                reportProblemService: reportProblemService,
                toastStateStore: toastStateStore,
                dismiss: { dismiss.callAsFunction() }
            )
        ) { state, store in
            NavigationStack {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        reportProblemForm(state: state, store: store)
                            .disabled(state.isLoading)
                            .animation(.easeInOut(duration: 0.2), value: state.summaryValidation)
                            .padding(.horizontal, DS.Spacing.large)

                        VStack(spacing: DS.Spacing.large) {
                            Text(L10n.ReportProblem.logsInfo)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.footnote)
                                .foregroundStyle(DS.Color.Text.weak)
                            if !state.sendLogsEnabled {
                                Text(L10n.ReportProblem.logsAdditionalInfo)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.footnote)
                                    .foregroundStyle(DS.Color.Text.norm)
                                    .id(ReportProblemScrollToElements.bottomInfoText)
                            }
                        }
                        .animation(.easeOut(duration: 0.2), value: state.sendLogsEnabled)
                        .padding(.vertical, DS.Spacing.standard)
                        .padding(.horizontal, DS.Spacing.huge)
                    }
                    .navigationTitle(L10n.ReportProblem.mainTitle.string)
                    .toolbar {
                        toolbarLeadingItem(state: state, store: store)
                        toolbarTrailingItem(state: state, store: store)
                    }
                    .onChange(of: state.scrollTo) { _, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(newValue, anchor: .bottom)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(DS.Color.Background.secondary)
            }
            .onChange(of: state.summaryValidation) { _, newValue in
                if case .failure = newValue {
                    isSummaryFocused = true
                }
            }
            .onAppear {
                isSummaryFocused = true
            }
            .interactiveDismissDisabled(true)
            .alert(model: alertBinding(state: state, store: store))
        }
    }

    private func reportProblemForm(state: ReportProblemState, store: ReportProblemStateStore) -> some View {
        VStack(spacing: DS.Spacing.extraLarge) {
            Text(L10n.ReportProblem.generalInfo)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.top, DS.Spacing.standard)
                .foregroundStyle(DS.Color.Text.weak)
                .id(ReportProblemScrollToElements.topInfoText)
            FormMultilineTextInput(
                title: L10n.ReportProblem.summary,
                placeholder: L10n.ReportProblem.summaryPlaceholder,
                text: text(keyPath: \.summary, store: store),
                validation: store.binding(\.summaryValidation)
            )
            .focused($isSummaryFocused)
            FormMultilineTextInput(
                title: L10n.ReportProblem.stepsToReproduce,
                placeholder: L10n.ReportProblem.stepsToReproducePlaceholder,
                text: text(keyPath: \.stepsToReproduce, store: store),
                validation: .noValidation
            )
            FormMultilineTextInput(
                title: L10n.ReportProblem.expectedResults,
                placeholder: L10n.ReportProblem.expectedResultsPlaceholder,
                text: text(keyPath: \.expectedResults, store: store),
                validation: .noValidation
            )
            FormMultilineTextInput(
                title: L10n.ReportProblem.actualResults,
                placeholder: L10n.ReportProblem.actualResultsPlaceholder,
                text: text(keyPath: \.actualResults, store: store),
                validation: .noValidation
            )
            FormSwitchView(
                title: L10n.ReportProblem.sendErrorLogs,
                additionalInfo: nil,
                isOn: sendErrorLogsToggle(state: state, store: store)
            )
        }
    }

    private func toolbarLeadingItem(state: ReportProblemState, store: ReportProblemStateStore) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if state.isLoading {
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

    private func toolbarTrailingItem(state: ReportProblemState, store: ReportProblemStateStore) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { store.handle(action: .closeButtonTapped) }) {
                Image(DS.Icon.icCross)
                    .square(size: 20)
                    .tint(DS.Color.Text.weak)
            }
            .disabled(state.isLoading)
        }
    }

    private func text(
        keyPath: WritableKeyPath<ReportProblemState, String>,
        store: ReportProblemStateStore
    ) -> Binding<String> {
        .init(
            get: { store.state[keyPath: keyPath] },
            set: { newValue in
                store.state[keyPath: keyPath] = newValue
                store.handle(action: .textEntered)
            }
        )
    }

    private func sendErrorLogsToggle(
        state: ReportProblemState,
        store: ReportProblemStateStore
    ) -> Binding<Bool> {
        .init(
            get: { state.sendLogsEnabled },
            set: { newValue in store.handle(action: .sendLogsToggleSwitched(isEnabled: newValue)) }
        )
    }

    private func alertBinding(
        state: ReportProblemState,
        store: ReportProblemStateStore
    ) -> Binding<AlertModel?> {
        .init(
            get: { state.alert },
            set: { newValue in store.state = store.state.copy(\.alert, to: newValue) }
        )
    }
}

#Preview {
    ReportProblemScreen(reportProblemService: MailUserSession(noPointer: .init()))
}
