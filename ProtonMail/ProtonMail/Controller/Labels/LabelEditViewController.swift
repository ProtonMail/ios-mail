//
//  LabelEditViewController.swift
//  ProtonMail - Created on 3/1/17.
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
import MBProgressHUD

class LableEditViewController : UIViewController, AccessibleView {
    
    var viewModel : LabelEditViewModel!

    
    fileprivate var selected : IndexPath?
    fileprivate var selectedFirstLoad : IndexPath?
    
    fileprivate var archiveMessage = false
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var inputContentView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var newLabelInput: UITextField!

    var delegate : LablesViewControllerDelegate?
    var applyButtonText : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4
        newLabelInput.delegate = self
        
        titleLabel.text = viewModel.title()
        newLabelInput.placeholder = viewModel.placeHolder()
        let name = viewModel.name()
        newLabelInput.text = name
        
        applyButtonText = viewModel.rightButtonText()
        applyButton.setTitle(applyButtonText, for: UIControl.State.disabled)
        applyButton.setTitle(applyButtonText, for: UIControl.State())
        cancelButton.setTitle(LocalString._general_cancel_button, for: UIControl.State())
        
        applyButton.isEnabled = !name.isEmpty
        generateAccessibilityIdentifiers()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.newLabelInput.becomeFirstResponder()
        self.selectedFirstLoad = viewModel.seletedIndex()
    }
    
    @IBAction func applyAction(_ sender: AnyObject) {
        //show loading
        MBProgressHUD.showAdded(to: view, animated: true)
        let color = viewModel.color(at: selected?.row ?? 0)
        viewModel.apply(withName: newLabelInput.text!, color: color, error: { (code, errorMessage) -> Void in
            MBProgressHUD.hide(for: self.view, animated: true)
            let alert = errorMessage.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }, complete: { () -> Void in
            self.dismiss(animated: true, completion: nil)
            self.delegate?.dismissed()
        })
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        delegate?.dismissed()
    }
    
    func dismissKeyboard() {
        if (self.newLabelInput != nil) {
            newLabelInput.resignFirstResponder()
        }
    }
}

extension LableEditViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return false
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text! as NSString
        let changedText = text.replacingCharacters(in: range, with: string)
        if changedText.isEmpty {
            applyButton.isEnabled = false
        } else {
            applyButton.isEnabled = true
        }
        return true
    }
}

// MARK: UICollectionViewDataSource
extension LableEditViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.colorCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "labelColorCell", for: indexPath)
        let color = viewModel.color(at: indexPath.row)
        cell.backgroundColor = UIColor(hexString: color, alpha: 1.0)
        cell.layer.cornerRadius = 17
        
        if selected == nil {
            if indexPath.row == selectedFirstLoad?.row {
                cell.layer.borderWidth = 4
                cell.layer.borderColor = UIColor.darkGray.cgColor
                self.selected = indexPath
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let index = selected {
            let oldCell = collectionView.cellForItem(at: index)
            oldCell?.layer.borderWidth = 0
        }
        
        let newCell = collectionView.cellForItem(at: indexPath)
        newCell?.layer.borderWidth = 4
        newCell?.layer.borderColor = UIColor.darkGray.cgColor
        self.selected = indexPath
        
        self.dismissKeyboard()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0,left: 0,bottom: 0,right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: 34, height: 34)
    }
}

