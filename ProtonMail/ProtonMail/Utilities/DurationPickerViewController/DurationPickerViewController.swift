//
//  DurationPickerViewController.swift
//  ProtonMail - Created on 12/06/2018.
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
final class DurationPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, AccessibleView {
    typealias ChangeHandler = (SelectedComponents)->Void
    typealias SelectedComponents = (Int, Int)
    
    @IBOutlet weak var picker: UIPickerView!
    private var handler: ChangeHandler!
    private var valueToSelect: SelectedComponents = (0, 0)
    
    convenience init(select: SelectedComponents, changeHandler handler: @escaping ChangeHandler) {
        self.init(nibName: "\(DurationPickerViewController.self)", bundle: .main)
        self.handler = handler
        self.valueToSelect = select
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.picker.selectRow(self.valueToSelect.0, inComponent: 0, animated: false)
        self.picker.selectRow(self.valueToSelect.1, inComponent: 1, animated: false)
        generateAccessibilityIdentifiers()
    }
    
    @IBAction func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save() {
        let hours = self.picker.selectedRow(inComponent: 0)
        let minutes = self.picker.selectedRow(inComponent: 1)
        self.handler?((hours, minutes))
        self.dismiss(animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return 24
        case 1: return 60
        default: fatalError()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row)"
    }
}
