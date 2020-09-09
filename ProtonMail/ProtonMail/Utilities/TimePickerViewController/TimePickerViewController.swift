//
//  TimePickerViewController.swift
//  ProtonMail - Created on 13/06/2018.
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

@available(iOS 9.0, *)
final class TimePickerViewController: UIViewController, UINavigationBarDelegate, AccessibleView {
    typealias ChangeHandler = (SelectedComponents)->Void
    typealias SelectedComponents = DateComponents
    
    @IBOutlet weak var customNavigationItem: UINavigationItem!
    @IBOutlet weak var picker: UIDatePicker!
    private var handler: ChangeHandler!
    private var valueToSelect: SelectedComponents!
    private var customTitle: String?
    
    convenience init(title: String? = nil,
                     select: SelectedComponents,
                     changeHandler handler: @escaping ChangeHandler)
    {
        self.init(nibName: "\(TimePickerViewController.self)", bundle: .main)
        self.handler = handler
        self.valueToSelect = select
        self.customTitle = title
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let date = Calendar.current.date(bySettingHour: self.valueToSelect.hour!,
                                         minute: self.valueToSelect.minute!,
                                         second: 0,
                                         of: Date())!
        self.picker.setDate(date, animated: false)
        self.customNavigationItem.title = self.customTitle
        generateAccessibilityIdentifiers()
    }
    
    @IBAction func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: self.picker.date)
        self.handler(components)
        self.dismiss(animated: true, completion: nil)
    }
}
