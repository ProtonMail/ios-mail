//
//  ShareExtensionEntry.swift
//  Share - Created on 6/28/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreCryptoGoImplementation
import ProtonCoreEnvironment
import ProtonCoreLog
import ProtonCoreServices
import ProtonCoreUIFoundations
import UIKit

@objc(ShareExtensionEntry)
class ShareExtensionEntry: UINavigationController {
    private var appCoordinator: ShareAppCoordinator?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup()
    }

    private func setup() {
        injectDefaultCryptoImplementation()
        configureCoreLogger()

        #if DEBUG
        PMAPIService.noTrustKit = true
        #endif
        DFSSetting.enableDFS = true
        DFSSetting.limitToXXXLarge = true
        TrustKitWrapper.start(delegate: self)

        setupLogLocation()
        SystemLogger.log(message: "Share extension is launching...", category: .appLifeCycle)

        appCoordinator = ShareAppCoordinator(navigation: self)
        setupNavigationBarAppearance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.appCoordinator?.start()
    }

    private func configureCoreLogger() {
        PMLog.setExternalLoggerHost(BackendConfiguration.shared.environment.doh.defaultHost)
    }

    private func setupLogLocation() {
        let directory = FileManager.default.appGroupsDirectoryURL
        PMLog.logsDirectory = directory
    }
}

extension ShareExtensionEntry: TrustKitUIDelegate {
    func onTrustKitValidationError(_ alert: UIAlertController) {
        self.appCoordinator?.navigationController?.present(alert, animated: true, completion: nil)
    }
}

extension ShareExtensionEntry {
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorProvider.BackgroundNorm
        appearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }
}
