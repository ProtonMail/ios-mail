// Copyright (c) 2023 Proton Technologies AG
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

import Combine
import Foundation
import ProtonCoreLog

protocol ApplicationLogsViewModelProtocol {
    var input: ApplicationLogsViewModelInput { get }
    var output: ApplicationLogsViewModelOutput { get }
}

protocol ApplicationLogsViewModelInput {
    func viewDidAppear()
    func didTapShare()
    func shareViewDidDismiss()
}

protocol ApplicationLogsViewModelOutput {
    var content: CurrentValueSubject<String, Never> { get }
    var fileToShare: PassthroughSubject<URL, Never> { get }
    var emptyContentReason: PassthroughSubject<String, Never> { get }
}

final class ApplicationLogsViewModel: ApplicationLogsViewModelProtocol, ApplicationLogsViewModelOutput {
    var input: ApplicationLogsViewModelInput { self }
    var output: ApplicationLogsViewModelOutput { self }
    let content = CurrentValueSubject<String, Never>(.empty)
    let fileToShare = PassthroughSubject<URL, Never>()
    let emptyContentReason = PassthroughSubject<String, Never>()
    private let dependencies: Dependencies

    private var logsLinkFile: URL {
        let logsLinkedFileName: String = "proton-mail-\(Bundle.main.buildVersion.lowercased()).log"
        return dependencies.fileManager.cachesDirectoryURL.appendingPathComponent(logsLinkedFileName)
    }

    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
    }

    private func deleteFileIfExists(file: URL) throws {
        if dependencies.fileManager.fileExists(atPath: file.path) {
            try dependencies.fileManager.removeItem(at: file)
        }
    }
}

extension ApplicationLogsViewModel: ApplicationLogsViewModelInput {
    func viewDidAppear() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let logs = PMLog.logsContent()
            if logs.isEmpty {
                self?.findEmptyLogsReason()
            } else {
                self?.content.value = logs
            }
        }
    }

    func didTapShare() {
        guard let sourceLogFile = PMLog.logFile else { return }
        do {
            try deleteFileIfExists(file: logsLinkFile)
            // We create a hard link to the original logs file to work with a more
            // beautiful file name instead of the default `logs.txt`
            try dependencies.fileManager.linkItem(at: sourceLogFile, to: logsLinkFile)
            fileToShare.send(logsLinkFile)
        } catch {
            PMAssertionFailure(error)
            fileToShare.send(sourceLogFile)
        }
    }

    func shareViewDidDismiss() {
        do {
            try deleteFileIfExists(file: logsLinkFile)
        } catch {
            PMAssertionFailure(error)
        }
    }

    private func findEmptyLogsReason() {
        guard let logFile = PMLog.logFile else {
            emptyContentReason.send("Log file doesn't exist")
            return
        }
        do {
            let logs = try String(contentsOf: logFile, encoding: .utf8)
            // In theory shouldn't have logs but no hurt to try
            content.value = logs
        } catch {
            emptyContentReason.send(error.localizedDescription)
        }
    }
}

extension ApplicationLogsViewModel {
    struct Dependencies {
        let fileManager: FileManager

        init(fileManager: FileManager = .default) {
            self.fileManager = fileManager
        }
    }
}
