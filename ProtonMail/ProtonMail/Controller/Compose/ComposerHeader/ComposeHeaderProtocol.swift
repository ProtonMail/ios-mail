//
//  ComposeHeaderProtocol.swift
//  ProtonMail - Created on 5/27/15.
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

protocol ComposeViewDelegate: class {
    func composeViewWillPresentSubview()
    func composeViewWillDismissSubview()
    
    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool)
    func ComposeViewDidOffsetChanged(_ offset: CGPoint)
    func composeViewDidTapNextButton(_ composeView: ComposeHeaderViewController)
    func composeViewDidTapEncryptedButton(_ composeView: ComposeHeaderViewController)
    func composeViewDidTapAttachmentButton(_ composeView: ComposeHeaderViewController)
    func composeViewDidTapContactGroupSubSelection(_ composeView: ComposeHeaderViewController,
                                                   contactGroup: ContactGroupVO,
                                                   callback: @escaping (([DraftEmailData]) -> Void))
    
    func composeView(_ composeView: ComposeHeaderViewController, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker)
    func composeView(_ composeView: ComposeHeaderViewController, didRemoveContact contact: ContactPickerModelProtocol, fromPicker picker: ContactPicker)
    
    func composeViewHideExpirationView(_ composeView: ComposeHeaderViewController)
    func composeViewCancelExpirationData(_ composeView: ComposeHeaderViewController)
    func composeViewDidTapExpirationButton(_ composeView: ComposeHeaderViewController)
    func composeViewCollectExpirationData(_ composeView: ComposeHeaderViewController)
    
    @available(iOS 14.0, *)
    func setupComposeFromMenu(for button: UIButton)
    func composeViewPickFrom(_ composeView: ComposeHeaderViewController)

    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?)
    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?)
}

protocol ComposeViewDataSource: class {
    func ccBccIsShownInitially() -> Bool
    func composeViewContactsModelForPicker(_ composeView: ComposeHeaderViewController, picker: ContactPicker) -> [ContactPickerModelProtocol]
    func composeViewSelectedContactsForPicker(_ composeView: ComposeHeaderViewController, picker: ContactPicker) -> [ContactPickerModelProtocol]
}
