//
//  ContactGroupSelectColorViewController.swift
//  ProtonMail
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

class ContactGroupSelectColorViewController: ProtonMailViewController, ViewModelProtocolNew {
    typealias argType = ContactGroupSelectColorViewModel
    
    var viewModel: ContactGroupSelectColorViewModel!
    @IBOutlet weak var collectionView: UICollectionView!

    func set(viewModel: ContactGroupSelectColorViewModel) {
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalString._contact_groups_select_color
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.save()
    }
}

extension ContactGroupSelectColorViewController: UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0);
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
        cell.layer.cornerRadius = 17;
        
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
