//
//  ComposeHeaderProtocol.swift
//  Proton Mail - Created on 5/27/15.
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

import UIKit

protocol ComposeViewDelegate: AnyObject {
    func composeViewDidTapContactGroupSubSelection(_ composeView: ComposeHeaderViewController,
                                                   contactGroup: ContactGroupVO,
                                                   callback: @escaping (([DraftEmailData]) -> Void))

    func composeView(_ composeView: ComposeHeaderViewController, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker)
    func composeView(_ composeView: ComposeHeaderViewController, didRemoveContact contact: ContactPickerModelProtocol, fromPicker picker: ContactPicker)

    func setupComposeFromMenu(for button: UIButton)

    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?)
    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?)
}

protocol ComposeViewDataSource: AnyObject {
    func ccBccIsShownInitially() -> Bool
    func composeViewContactsModelForPicker(_ composeView: ComposeHeaderViewController, picker: ContactPicker) -> [ContactPickerModelProtocol]
    func composeViewSelectedContactsForPicker(_ composeView: ComposeHeaderViewController, picker: ContactPicker) -> [ContactPickerModelProtocol]
}
