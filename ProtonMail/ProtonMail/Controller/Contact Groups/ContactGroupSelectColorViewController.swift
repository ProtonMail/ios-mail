//
//  ContactGroupSelectColorViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/17.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

/*
 Prototyping goals:
 1. Make the colors available for single selection by showing the colors as the background of each cell
 2. When the back button is pressed, we save the color
 */

class ContactGroupSelectColorViewController: ProtonMailViewController, ViewModelProtocol
{
    var viewModel: ContactGroupSelectColorViewModel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupSelectColorViewModel
    }
    
    func inactiveViewModel() { }
}

extension ContactGroupSelectColorViewController: UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0,0,0,0);
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
        
        // TODO: deal with color cell that is already selected
//        if selected == nil {
//            if indexPath.row == selectedFirstLoad?.row {
//                cell.layer.borderWidth = 4
//                cell.layer.borderColor = UIColor.darkGray.cgColor
//                self.selected = indexPath
//            }
//        }
        
        return cell
    }
}

extension ContactGroupSelectColorViewController: UICollectionViewDelegate
{
    
}
