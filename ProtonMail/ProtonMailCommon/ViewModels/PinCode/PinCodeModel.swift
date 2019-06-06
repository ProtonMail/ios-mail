//
//  PinCodeModel.swift
//  ProtonMail - Created on 4/11/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation


enum PinCodeStep: Int {
    case enterPin = 0
    case reEnterPin = 1
    case unlock = 2
    case done = 3
}

class PinCodeViewModel : NSObject {
    
    func needsLogoutConfirmation() -> Bool {
        return false
    }
    
    func backButtonIcon() -> UIImage {
        return UIImage(named: "top_back")!
    }
    
    func title() -> String {
        fatalError("This method must be overridden")
    }
    
    func cancel() -> String {
        fatalError("This method must be overridden")
    }
    
    func showConfirm() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func confirmString () -> String {
        fatalError("This method must be overridden")
    }
    
    func setCode (_ code : String) -> PinCodeStep {
        fatalError("This method must be overridden")
    }
    
    func isPinMatched(completion: @escaping (Bool)->Void) {
        fatalError("This method must be overridden")
    }
    
    func getPinFailedRemainingCount() -> Int {
        fatalError("This method must be overridden")
    }
    
    func getPinFailedError() -> String {
        fatalError("This method must be overridden")
    }
    
    func done(completion: @escaping (Bool)->Void) {
        completion(true)
    }
    
    func checkTouchID() -> Bool {
        return false
    }
}
