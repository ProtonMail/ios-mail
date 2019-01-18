//
//  ContactModel.swift
//  ProtonMail - Created on 4/26/18.
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


import UIKit

typealias LockCheckProgress = (() -> Void)
typealias LockCheckComplete = ((_ lock: UIImage?, _ lockType : Int) -> Void)

@objc enum ContactPickerModelState: Int
{
    case contact = 1
    case contactGroup = 2
}

@objc protocol ContactPickerModelProtocol: class {
    
    var modelType: ContactPickerModelState { get }
    var contactTitle : String { get }
    
    //@optional
    var displayName : String? { get }
    var displayEmail : String? { get }
    var contactSubtitle : String? { get }
    var contactImage : UIImage? {get}
    var color: String? {get}
    var lock: UIImage? {get}
    var hasPGPPined : Bool {get}
    var hasNonePM : Bool {get}
    func notes(type: Int) -> String
    func setType(type: Int)
    func lockCheck(progress: LockCheckProgress, complete: LockCheckComplete?)
    
    
    func equals(_ others: ContactPickerModelProtocol) -> Bool
}
