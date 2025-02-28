// Copyright (c) 2024 Proton Technologies AG
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

import InboxComposer
import InboxContacts
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

@MainActor
struct HomeScreenModalFactory {
    private let makeContactsScreen: () -> ContactsScreen
    private let makeComposerScreen: (ComposerModalParams) -> ComposerScreen
    private let makeSettingsScreen: () -> SettingsScreen

    init(mailUserSession: MailUserSession, toastStateStore: ToastStateStore) {
        self.makeContactsScreen = {
            ContactsScreen(
                mailUserSession: mailUserSession,
                contactsProvider: .productionInstance(),
                contactsWatcher: .productionInstance(),
                toastStateStore: toastStateStore
            )
        }
        self.makeComposerScreen = { composerParams in
            ComposerScreenFactory.makeComposer(userSession: mailUserSession, composerParams: composerParams)
        }
        self.makeSettingsScreen = { SettingsScreen(mailUserSession: mailUserSession) }
    }

    @MainActor @ViewBuilder
    func makeModal(for state: HomeScreen.ModalState) -> some View {
        switch state {
        case .contacts:
            makeContactsScreen()
        case .labelOrFolderCreation:
            CreateFolderOrLabelScreen()
        case .draft(let draftToPresent):
            makeComposerScreen(draftToPresent)
        case .settings:
            makeSettingsScreen()
        case .checkLogs:
            LogViewerView()
        }
    }
}

import SwiftUI
import InboxCore

fileprivate var lastSelectedCategory: AppLogger.Category? = nil

struct LogViewerView: View {
    @State private var logs: [String] = []
    @State private var selectedCategory: AppLogger.Category? = nil
    @State private var searchQuery: String = "".notLocalized

    var filteredLogs: [String] {
        let categoryFiltered: [String] = {
            guard let category = selectedCategory else { return logs }
            let pattern = "[App] \(category.rawValue):"
            return logs.filter { $0.contains(pattern) }
        }()

        guard !searchQuery.isEmpty else { return categoryFiltered }
        return categoryFiltered.filter { $0.localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Menu {
                    Button("All".notLocalized, action: { selectedCategory = nil })
                    ForEach(AppLogger.Category.allCases, id: \.rawValue) { category in
                        Button(category.rawValue) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory?.rawValue ?? "Select Category".notLocalized)
                        Image(systemName: "chevron.down")
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                }

                Spacer()

                Button(action: { loadLogs() }) {
                    Image(systemName: "arrow.clockwise")
                }

                Button(action: cleanLogs) {
                    Image(systemName: "trash")
                }
            }
            .padding(.all)

            TextField("Search logs...".notLocalized, text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .autocorrectionDisabled()

            List(filteredLogs, id: \.self) { log in
                highlightedText(for: log, searchQuery: searchQuery)
                    .font(.system(.footnote, design: .monospaced))
                    .lineLimit(nil)
            }
        }
        .onAppear {
            selectedCategory = lastSelectedCategory
            loadLogs()
        }
        .onChange(of: selectedCategory, { _, newValue in
            lastSelectedCategory = newValue
        })
        .navigationTitle("Log Viewer".notLocalized)
    }

    func loadLogs() {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.me.proton.mail"
        ) else { return }
        let logFileURL = containerURL.appendingPathComponent("cache/proton-mail-uniffi.log")

        do {
            let content = try String(contentsOf: logFileURL)
            logs = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        } catch {
            print("Error reading log file: \(error)")
        }
    }

    func cleanLogs() {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.me.proton.mail"
        ) else { return }
        let logFileURL = containerURL.appendingPathComponent("cache/proton-mail-uniffi.log")
        do {
            try "".write(to: logFileURL, atomically: false, encoding: .utf8)
            logs = []
        } catch {
            print("Error cleaning logs file: \(error)")
        }
    }

    func highlightedText(for log: String, searchQuery: String) -> Text {
        guard !searchQuery.isEmpty else { return Text(log) }

        let lowerLog = log.lowercased()
        let lowerQuery = searchQuery.lowercased()
        var result = Text("".notLocalized)
        var currentIndex = log.startIndex

        while let range = lowerLog.range(of: lowerQuery, options: .caseInsensitive, range: currentIndex..<lowerLog.endIndex) {
            let nonHighlighted = String(log[currentIndex..<range.lowerBound])
            result = result + Text(nonHighlighted)

            let highlighted = String(log[range])
            result = result + Text(highlighted).foregroundColor(.red).bold()

            currentIndex = range.upperBound
        }
        let remainder = String(log[currentIndex..<log.endIndex])
        result = result + Text(remainder)

        return result
    }
}
