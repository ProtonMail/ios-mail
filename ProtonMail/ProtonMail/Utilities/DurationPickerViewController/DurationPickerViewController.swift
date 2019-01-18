//
//  DurationPickerViewController.swift
//  ProtonMail - Created on 12/06/2018.
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

@available(iOS 9.0, *)
final class DurationPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
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
