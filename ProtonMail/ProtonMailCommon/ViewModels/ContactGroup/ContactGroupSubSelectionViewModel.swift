//
//  ContactGroupSubSelectionViewModel.swift
//  ProtonMail - Created on 2018/10/13.
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
