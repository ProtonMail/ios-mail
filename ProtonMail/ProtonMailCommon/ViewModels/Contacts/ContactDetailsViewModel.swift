//
//  ContactDetailsViewModel.swift
//  ProtonMail - Created on 5/2/17.
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
import PromiseKit

typealias LoadingProgress = () -> Void

class ContactDetailsViewModel : ViewModelBase {
    
    override init() { }
    
    func paidUser() -> Bool {
        if let role = sharedUserDataService.userInfo?.role, role > 0 {
            return true
        }
        return false
    }
    
    @discardableResult
    func rebuild() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func sections() -> [ContactEditSectionType] {
        fatalError("This method must be overridden")
    }
    
    func statusType2() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func statusType3() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func type3Error() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func debugging() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func hasEncryptedContacts() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func getDetails(loading : LoadingProgress) -> Promise<Contact> {
        fatalError("This method must be overridden")
    }
    
    func getContact() -> Contact {
        fatalError("This method must be overridden")
    }
    
    func getProfile() -> ContactEditProfile {
        fatalError("This method must be overridden")
    }
    
    func getProfilePicture() -> UIImage? {
        fatalError("This method must be overridden")
    }
    
    func getEmails() -> [ContactEditEmail] {
        fatalError("This method must be overridden")
    }
    
    func getPhones() -> [ContactEditPhone] {
        fatalError("This method must be overridden")
    }
    
    func getAddresses() -> [ContactEditAddress] {
        fatalError("This method must be overridden")
    }
    
    func getInformations() -> [ContactEditInformation] {
        fatalError("This method must be overridden")
    }
    
    func getFields() -> [ContactEditField] {
        fatalError("This method must be overridden")
    }
    
    func getNotes() -> [ContactEditNote] {
        fatalError("This method must be overridden")
    }
    
    func getUrls() -> [ContactEditUrl] {
        fatalError("This method must be overridden")
    }
    
    func export() -> String {
        fatalError("This method must be overridden")
    }
    
    func exportName() -> String {
        fatalError("This method must be overridden")
    }
}
