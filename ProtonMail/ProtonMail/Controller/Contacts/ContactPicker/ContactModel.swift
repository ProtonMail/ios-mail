//
//  ContactModel.swift
//  ProtonMail - Created on 4/26/18.
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

typealias LockCheckProgress = (() -> Void)
typealias LockCheckComplete = ((_ lock: UIImage?, _ lockType : Int) -> Void)

@objc enum ContactPickerModelState: Int
{
    case contact = 1
    case contactGroup = 2
}

protocol ContactPickerModelProtocol: class {
    
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
    func lockCheck(api: APIService, contactService: ContactDataService, progress: LockCheckProgress, complete: LockCheckComplete?)
    
    
    func equals(_ others: ContactPickerModelProtocol) -> Bool
}
