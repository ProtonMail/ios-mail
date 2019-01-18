//
//  TimePickerViewController.swift
//  ProtonMail - Created on 13/06/2018.
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
final class TimePickerViewController: UIViewController, UINavigationBarDelegate {
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
