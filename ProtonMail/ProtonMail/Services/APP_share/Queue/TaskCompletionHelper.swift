// Copyright (c) 2021 Proton AG
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
import ProtonCoreNetworking
import class ProtonCoreServices.APIErrorCode

struct TaskCompletionHelper {
    private let internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol

    init(
        provider: InternetConnectionStatusProviderProtocol = InternetConnectionStatusProvider.shared
    ) {
        self.internetConnectionStatusProvider = provider
    }

    func calculateIsInternetIssue(error: NSError, currentNetworkStatus: ConnectionStatus) -> Bool {
        var result = false

        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorSecureConnectionFailed,
                 NSURLErrorDataNotAllowed,
                 NSURLErrorCannotFindHost:
                result = true
            default:
                break
            }
        } else if error.domain == NSPOSIXErrorDomain &&
                    error.code == 100 {
            // Network protocol error
            result = true
        } else {
            switch currentNetworkStatus {
            case .notConnected:
                result = true
            default: break
            }
        }

        if let responseError = error as? ResponseError {
            // When device is having low connectivity, the core will return this error.
            let offlineErrorCodes = [APIErrorCode.deviceHavingLowConnectivity, APIErrorCode.connectionAppearsToBeOffline]
            let isOfflineError = offlineErrorCodes.contains(responseError.underlyingError?.code ?? -999)

            if responseError.httpCode == nil &&
                responseError.responseCode == nil &&
                isOfflineError {
                result = true
            }
        }

        return result
    }

    func handleReachabilityChangedNotification(isTimeoutError: Bool, isInternetIssue: Bool) {
        // Show timeout error banner or not reachable banner in mailbox
        guard isTimeoutError || isInternetIssue else { return }
        let reason: ConnectionFailedReason = isTimeoutError ? .timeout : .internetIssue
        NotificationCenter.default.post(Notification(name: .tempNetworkError, object: reason, userInfo: nil))
    }

    func handleResult(queueTask: QueueManager.Task,
                      error: NSError?,
                      notifyQueueManager: @escaping (QueueManager.Task, QueueManager.TaskResult) -> Void) {
        var taskResult = QueueManager.TaskResult()

        guard let error = error else {
            internetConnectionStatusProvider.apiCallIsSucceeded()
            notifyQueueManager(queueTask, taskResult)
            return
        }

        var statusCode = 200
        let errorCode = error.code
        var isInternetIssue = false

        // Check if error returns from the network response. Otherwise, check if it is internet issue
        if let statusCodeFromResponse = error.httpCode {
            statusCode = statusCodeFromResponse
        } else {
            isInternetIssue = calculateIsInternetIssue(
                error: error,
                currentNetworkStatus: InternetConnectionStatusProvider.shared.status
            )
            let isTimeoutError = errorCode == NSURLErrorTimedOut
            handleReachabilityChangedNotification(isTimeoutError: isTimeoutError, isInternetIssue: isInternetIssue)
        }

        calculateTaskResult(result: &taskResult,
                            isInternetIssue: isInternetIssue,
                            statusCode: statusCode,
                            errorCode: errorCode)
        notifyQueueManager(queueTask, taskResult)
    }

    func calculateTaskResult(result: inout QueueManager.TaskResult, isInternetIssue: Bool, statusCode: Int, errorCode: Int) {
        guard isInternetIssue == false else {
            result.action = .connectionIssue
            return
        }

        switch statusCode {
        case HTTPStatusCode.notFound.rawValue:
            result.action = .removeRelated
        case HTTPStatusCode.internalServerError.rawValue:
            if result.retry < 3 {
                result.action = .retry
                result.retry += 1
            } else {
                result.action = .removeRelated
            }
        case HTTPStatusCode.ok.rawValue where errorCode > 1000:
            result.action = .removeRelated
        case HTTPStatusCode.ok.rawValue where errorCode < 200:
            result.action = .removeRelated
        default:
            if statusCode != .ok {
                result.action = .removeRelated
            } else if errorCode != APIErrorCode.AuthErrorCode.authCacheLocked {
                result.action = .removeRelated
            } else {
                result.action = .checkReadQueue
            }
        }
    }
}
