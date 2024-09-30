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

import Foundation

enum Application {
    /// Varible to determine how the build is distributed.
    ///
    /// Returns `true` if the build is one of the following:
    ///  1. run in debug mode
    ///  2. enterprise build
    ///  3. testflight build
    ///
    ///  Returns `false` if the build is from the AppStore
    static var isTestingBuild: Bool {
        return isDebugOrEnterprise || isTestflightBeta
    }

    static var isDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }

    static var isDebugOrEnterprise: Bool {
#if DEBUG_ENTERPRISE
        return true
#else
        return false
#endif
    }

    static var isTestflightBeta: Bool {
// If we're running on simulator, we're definitely not Testflight version
#if targetEnvironment(simulator)
        return false

// If we're compiled in DEBUG configuration, we're definitely not Testflight version
#elseif DEBUG
        return false

/*
 Checking for sandbox appstore receipt to determine if the app is beta version
 installed through Testflight is used by:
 * Microsoft's AppCenter:
 https://github.com/microsoft/appcenter-sdk-apple/blob/928227a72dc813070dc05efae04e19fe86558030/AppCenter/AppCenter/Internals/Util/MSACUtility%2BEnvironment.m#L28
 * Sentry:
 https://github.com/getsentry/sentry-cocoa/blob/7185a59493cda3aafcbe3b87652ea0256db2ad59/Sources/SentryCrash/Recording/Monitors/SentryCrashMonitor_System.m#L435
 
 We explore the same idea here.
 */
#else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
#endif
    }

    static var arePaymentsEnabled: Bool {
        // prevent sandbox users from making purchases in prod
        !BackendConfiguration.shared.isProduction || !isTestflightBeta
    }
}
