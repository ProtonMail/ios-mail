//
//  PMChallenge.swift
//  ProtonMail - Created on 6/19/20.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import Foundation

final public class PMChallenge {
    static private let queue = DispatchQueue(label: "com.protonmail.challenge")
    static private var shareInstance: PMChallenge?
    /// Collected challenge data
    private var challenge = PMChallenge.Challenge()
    /// Interceptor of `UITextField`
    private var interceptors: [TextFieldDelegateInterceptor] = []
    /// To calculate number of second that user editing username
    private var usernameEditingTime: TimeInterval = 0
    /// To calculate number of second that user editing password
    private var passwordEditingTime: TimeInterval = 0
    /// To calculate number of second from request verify to start input verification
    private var requestVerifyTime: TimeInterval = 0
    /// Copy event debounce
    private var copyDebounce: TimeInterval = 0

    public init() {
        self.subscribeNotification()
    }

    deinit {
        self.unsubscribeNotification()
        self.reset()
    }

    /// Get shared instance, thread safe
    public static func shared() -> PMChallenge {
        queue.sync {
            if let shareInstance = PMChallenge.shareInstance {
                shareInstance.subscribeNotification()
                return shareInstance
            }
            PMChallenge.shareInstance = PMChallenge()
            return PMChallenge.shareInstance!
        }
    }

    /// Release shared instance
    public static func release() {
        queue.sync {
            PMChallenge.shareInstance?.unsubscribeNotification()
            PMChallenge.shareInstance?.reset()
            PMChallenge.shareInstance = nil
        }
    }
}

// MARK: Public function
extension PMChallenge {
    /// Reset collected data, should called this function before collect data
    public func reset() {
        self.challenge.reset()

        self.interceptors.forEach({$0.destroy()})
        self.interceptors = []
        self.usernameEditingTime = 0
        self.passwordEditingTime = 0
        self.requestVerifyTime = 0
    }

    /// Export collected challenge data
    public func export() -> PMChallenge.Challenge {
        let semaphore = DispatchSemaphore(value: 0)
        runInMainThread {
            self.challenge.fetchValues()
            semaphore.signal()
        }
        semaphore.wait()
        return self.challenge
    }

    /**
     Start to observe given textfield
     
     If you call this function with the same type (or same textField) twice.
     The data of the first called will be overridden by the second called.
     
     - Parameter textField: textField will be observe
     - Parameter type: The usage of this textField
     - Parameter ignoreDelegate: Should ignore textField delegate missing error?
     */
    public func observeTextField(_ textField: UITextField, type: TextFieldType, ignoreDelegate: Bool = false) throws {

        while true {
            if let idx = self.interceptors.firstIndex(where: {$0.type == type || $0.textField == textField}) {
                let interceptor = self.interceptors.remove(at: idx)
                interceptor.destroy()
            } else {
                break
            }
        }

        do {
            let interceptor = try TextFieldDelegateInterceptor(textField: textField,
                                                               type: type, delegate: self,
                                                               ignoreDelegate: ignoreDelegate)
            self.interceptors.append(interceptor)
        } catch {
            throw error
        }

        switch type {
        case .username:
            self.usernameEditingTime = 0
            self.challenge.time_user = []
        case .password:
            self.passwordEditingTime = 0
            self.challenge.time_pass = 0
        default:
            break
        }
    }

    /// Record username that checks availability
    public func appendCheckedUsername(_ username: String) {
        guard self.usernameEditingTime > 0 else {
            // Ignore if editing time is zero
            // Sometimes app will check the same username in very short time.
            return
        }

        let time = Int(Date().timeIntervalSince1970 - self.usernameEditingTime)
        self.challenge.time_user.append(time)
        self.challenge.usernameChecks.append(username)

        self.usernameEditingTime = 0
        guard let interceptor = self.interceptors.first(where: {$0.type == .username}) else {
            return
        }
        // make sure the textField is not focused after check username.
        interceptor.textField?.resignFirstResponder()
    }

    /// Declare user start request verification so that timer starts.
    public func requestVerify() {
        self.requestVerifyTime = Date().timeIntervalSince1970
    }

    /// Count verification time
    public func verificationFinish() throws {
        if self.requestVerifyTime == 0 {
            throw PMChallenge.TimerError.verificationTimerError
        }
        self.challenge.time_human = Int(Date().timeIntervalSince1970 - self.requestVerifyTime)
    }
}

// MARK: Private function
extension PMChallenge {
    private func runInMainThread(closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async {
                closure()
            }
        }
    }
}

// MARK: Notification
extension PMChallenge {
    private func subscribeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(PMChallenge.copyEvent),
                                               name: UIPasteboard.changedNotification,
                                               object: nil)
    }

    private func unsubscribeNotification() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func copyEvent() {
        guard let interceptor = self.interceptors.first(where: {$0.textField?.isFirstResponder ?? false}) else {
            return
        }

        let now = Date().timeIntervalSince1970
        if now - self.copyDebounce < 1 {
            return
        }
        self.copyDebounce = now

        guard let copyText = UIPasteboard.general.string else {return}
        switch interceptor.type {
        case .username:
            self.challenge.copy_username.append(copyText)
            self.challenge.usernameTypedChars.append("Copy")
        case .recovery:
            self.challenge.copy_recovery.append(copyText)
        default:
            break
        }
    }
}

// MARK: TextFieldInterceptorDelegate, internal usage
extension PMChallenge: TextFieldInterceptorDelegate {
    func beginEditing(type: TextFieldType) {
        switch type {
        case .username:
            if self.usernameEditingTime == 0 {
                self.usernameEditingTime = Date().timeIntervalSince1970
            }
        case .password:
            if self.passwordEditingTime == 0 {
                self.passwordEditingTime = Date().timeIntervalSince1970
            }
        default:
            break
        }
    }

    func endEditing(type: TextFieldType) {
        switch type {
        case .password:
            self.challenge.time_pass += Int(Date().timeIntervalSince1970 - self.passwordEditingTime)
            self.passwordEditingTime = 0
        default:
            break
        }
    }

    func charactersTyped(chars: String, type: TextFieldType) throws {
        let value: String = chars.count > 1 ? "Paste": chars
        switch type {
        case .username:
            self.challenge.usernameTypedChars.append(value)
            if chars.count > 1 {
                self.challenge.paste_username.append(chars)
            }
        case .recovery:
            self.challenge.recoverTypedChars.append(value)
            if chars.count > 1 {
                self.challenge.paste_recovery.append(chars)
            }
        default:
            break
        }
    }

    func charactersDeleted(chars: String, type: TextFieldType) {
        switch type {
        case .username:
            self.challenge.usernameTypedChars.append("Backspace")
        case .recovery:
            self.challenge.recoverTypedChars.append("Backspace")
        default:
            break
        }
    }

    func tap(textField: UITextField, type: TextFieldType) {
        switch type {
        case .username:
            self.challenge.click_user += 1
        case .recovery:
            self.challenge.click_recovery += 1
        default:
            break
        }
    }
}
