//
//  DurationPickerViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
        self.picker.selectRow(self.valueToSelect.0 - 1, inComponent: 0, animated: false)
        self.picker.selectRow(self.valueToSelect.1 - 1, inComponent: 1, animated: false)
    }
    
    @IBAction func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save() {
        let hours = self.picker.selectedRow(inComponent: 0) + 1
        let minutes = self.picker.selectedRow(inComponent: 1) + 1
        self.handler((hours, minutes))
        self.dismiss(animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return 22
        case 1: return 58
        default: fatalError()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }
}
