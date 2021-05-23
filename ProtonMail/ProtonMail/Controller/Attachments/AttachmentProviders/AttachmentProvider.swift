//
//  AttachmentProvider.swift
//  ProtonMail - Created on 28/06/2018.
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


import Foundation
import PromiseKit
import AwaitKit
import ProtonCore_UIFoundations

protocol AttachmentProvider {
    var actionSheetItem: PMActionSheetItem { get }
    var controller: AttachmentController? { get }
}


protocol AttachmentController: AnyObject {
    func present(_ controller: UIViewController, animated: Bool, completion: (()->Void)?)
    func error(_ description: String)
    func fileSuccessfullyImported(as fileData: FileData) -> Promise<Void>
    
    @available(iOS, deprecated: 11.0, message: "ios 10 and below required sourceView&sourceRect or barButtonItem")
    var barItem : UIBarButtonItem? {get}
}
