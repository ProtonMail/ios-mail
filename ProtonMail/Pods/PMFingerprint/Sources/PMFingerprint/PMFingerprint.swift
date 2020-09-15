//
//  PMFingerprint.swift
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

final public class PMFingerprint {
    static private let queue = DispatchQueue(label: "com.protonmail.fingerprint")
    static private var shareInstance: PMFingerprint?
    /// Collected fingerprint data
    private var fingerprint = PMFingerprint.Fingerprint()
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
    public static func shared() -> PMFingerprint {
        queue.sync {
            if let _shared = PMFingerprint.shareInstance {
                _shared.subscribeNotification()
                return _shared
            }
            PMFingerprint.shareInstance = PMFingerprint()
            return PMFingerprint.shareInstance!
        }
    }
    
    /// Release shared instance
    public static func release() {
        queue.sync {
            PMFingerprint.shareInstance?.unsubscribeNotification()
            PMFingerprint.shareInstance?.reset()
            PMFingerprint.shareInstance = nil
        }
    }
}

// MARK: Public function
extension PMFingerprint {
    /// Reset collected data, should called this function before collect data
    public func reset() {
        self.fingerprint.reset()
        
        self.interceptors.forEach({$0.destroy()})
        self.interceptors = []
        self.usernameEditingTime = 0
        self.passwordEditingTime = 0
        self.requestVerifyTime = 0
    }
    
    /// Export collected fingerprint data
    public func export() -> PMFingerprint.Fingerprint {
        let semaphore = DispatchSemaphore(value: 0)
        runInMainThread {
            self.fingerprint.fetchValues()
            semaphore.signal()
        }
        semaphore.wait()
        return self.fingerprint
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
        } catch  {
            throw error
        }
        
        switch type {
        case .username:
            self.usernameEditingTime = 0
            self.fingerprint.time_user = []
        case .password:
            self.passwordEditingTime = 0
            self.fingerprint.time_pass = 0
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
        self.fingerprint.time_user.append(time)
        self.fingerprint.usernameChecks.append(username)
        
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
    public func verificationFinsih() throws {
        if self.requestVerifyTime == 0 {
            throw PMFingerprint.TimerError.verificationTimerError
        }
        self.fingerprint.time_human = Int(Date().timeIntervalSince1970 - self.requestVerifyTime)
    }
}

// MARK: Private function
extension PMFingerprint {
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
extension PMFingerprint {
    private func subscribeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(PMFingerprint.copyEvent),
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
            self.fingerprint.copy_username.append(copyText)
            self.fingerprint.usernameTypedChars.append("Copy")
        case .recovery:
            self.fingerprint.copy_recovery.append(copyText)
        default:
            break
        }
    }
}

// MARK: TextFieldInterceptorDelegate, internal usage
extension PMFingerprint: TextFieldInterceptorDelegate {
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
            self.fingerprint.time_pass += Int(Date().timeIntervalSince1970 - self.passwordEditingTime)
            self.passwordEditingTime = 0
        default:
            break
        }
    }
    
    func charactersTyped(chars: String, type: TextFieldType) throws {
        let value: String = chars.count > 1 ? "Paste": chars
        switch type {
        case .username:
            self.fingerprint.usernameTypedChars.append(value)
            if chars.count > 1 {
                self.fingerprint.paste_username.append(chars)
            }
        case .recovery:
            self.fingerprint.recoverTypedChars.append(value)
            if chars.count > 1 {
                self.fingerprint.paste_recovery.append(chars)
            }
        default:
            break
        }
    }
    
    func charactersDeleted(chars: String, type: TextFieldType) {
        switch type {
        case .username:
            self.fingerprint.usernameTypedChars.append("Backspace")
        case .recovery:
            self.fingerprint.recoverTypedChars.append("Backspace")
        default:
            break
        }
    }
    
    func tap(textField: UITextField, type: TextFieldType) {
        switch type {
        case .username:
            self.fingerprint.click_user += 1
        case .recovery:
            self.fingerprint.click_recovery += 1
        default:
            break
        }
    }
}
