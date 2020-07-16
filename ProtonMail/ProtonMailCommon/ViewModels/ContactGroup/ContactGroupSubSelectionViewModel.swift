//
//  ContactGroupSubSelectionViewModel.swift
//  ProtonMail - Created on 2018/10/13.
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

protocol ContactGroupSubSelectionViewModelDelegate
{
    func reloadTable()
}

protocol ContactGroupSubSelectionViewModelEmailCellDelegate
{
    func select(indexPath: IndexPath)
    func deselect(indexPath: IndexPath)
    func setRequiredEncryptedCheckStatus(at indexPath: IndexPath,
                                         to: ContactGroupSubSelectionEmailLockCheckingState,
                                         isEncrypted: UIImage?)
    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?)
}

protocol ContactGroupSubSelectionViewModelHeaderCellDelegate
{
    func selectAll()
    func deSelectAll()
    func isAllSelected() -> Bool
}

struct ContactGroupSubSelectionViewModelEmailInfomation
{
    let email: String
    let name: String
    var isSelected: Bool
    var isEncrypted: UIImage?
    var checkEncryptedStatus: ContactGroupSubSelectionEmailLockCheckingState = .NotChecked
    
    init(email: String, name: String, isSelected: Bool = false, isEncrypted: UIImage? = nil) {
        self.email = email
        self.name = name
        self.isSelected = isSelected
        self.isEncrypted = isEncrypted
    }
}

enum ContactGroupSubSelectionEmailLockCheckingState
{
    case NotChecked
    case Checking
    case Checked
}

protocol ContactGroupSubSelectionViewModel: ContactGroupSubSelectionViewModelEmailCellDelegate,
    ContactGroupSubSelectionViewModelHeaderCellDelegate
{
    func getCurrentlySelectedEmails() -> [DraftEmailData]
    
    func getGroupName() -> String
    func getGroupColor() -> String?
    func getTotalRows() -> Int
    func cellForRow(at indexPath: IndexPath) -> ContactGroupSubSelectionViewModelEmailInfomation
}
