//
//  ContactGroupSelectColorViewController.swift
//  ProtonMail
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

import PMUIFoundations
import UIKit

class ContactGroupSelectColorViewController: ProtonMailViewController, ViewModelProtocol {
    typealias viewModelType = ContactGroupSelectColorViewModel
    
    var viewModel: ContactGroupSelectColorViewModel!
    @IBOutlet weak var collectionView: UICollectionView!
    private var doneButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!

    func set(viewModel: ContactGroupSelectColorViewModel) {
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalString._contact_groups_edit_avartar

        self.doneButton = UIBarButtonItem(title: LocalString._general_edit_action,
                                        style: UIBarButtonItem.Style.plain,
                                        target: self, action: #selector(self.didTapDoneButton))
        let attributes = FontManager.DefaultStrong.foregroundColor(UIColorManager.InteractionNorm)
        self.doneButton.setTitleTextAttributes(attributes, for: .normal)
        self.navigationItem.rightBarButtonItem = doneButton

        self.cancelButton = Asset.backArrow.image.toUIBarButtonItem(target: self,
                                                                    action: #selector(self.didTapCancelButton(_:)),
                                                                    tintColor: UIColorManager.IconNorm)
        self.navigationItem.leftBarButtonItem = cancelButton
    }

    @objc
    private func didTapCancelButton(_ sender: UIBarButtonItem) {
        if viewModel.havingUnsavedChanges {
            let alertController = UIAlertController(title: LocalString._warning,
                                                    message: LocalString._changes_will_discarded,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._general_discard, style: .destructive, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alertController, animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc
    private func didTapDoneButton() {
        viewModel.save()
        self.navigationController?.popViewController(animated: true)
    }
}

extension ContactGroupSelectColorViewController: UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: 34, height: 34)
    }
}

extension ContactGroupSelectColorViewController: UICollectionViewDataSource
{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getTotalColors()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactGroupColorSelectionCell",
                                                      for: indexPath)
        
        let color = viewModel.getColor(at: indexPath)
        cell.backgroundColor = UIColor(hexString: color, alpha: 1.0)
        cell.layer.cornerRadius = 17
        
        if viewModel.isSelectedColor(at: indexPath) {
            cell.layer.borderWidth = 4
            cell.layer.borderColor = UIColor.darkGray.cgColor
        }
        
        return cell
    }
}

extension ContactGroupSelectColorViewController: UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        // deselect
        let currentColorIndex = viewModel.getCurrentColorIndex()
        var cell = collectionView.cellForItem(at: IndexPath(row: currentColorIndex, section: 0))
        cell?.layer.borderWidth = 0
        
        // select the new color
        cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 4
        cell?.layer.borderColor = UIColor.darkGray.cgColor
        viewModel.updateCurrentColor(to: indexPath)
    }
}
