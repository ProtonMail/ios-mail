//
//  RecipientView.swift
//  ProtonMail - Created on 9/10/15.
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

protocol LabelsCollectionViewDelegate : RecipientCellDelegate {
    
}

class LabelsCollectionView: PMView {
    override func getNibName() -> String {
        return "LabelsCollectionView"
    }
    
    //@IBOutlet weak var fromLabel: UILabel!
   // @IBOutlet weak var tableView: UITableView!
    
    ///
    var promptString : String?
    var labelValue : String?
    
    var showLocker : Bool = true
    
    var labelSize : CGSize?
    
    var contacts : [ContactVO]?
    
    weak var delegate : RecipientViewDelegate?
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    override func setup() {
        
        let nib = UINib(nibName: "\(LabelCell.self)", bundle: Bundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "\(LabelCell.self)")
    }
    
    func getContentSize() -> CGSize{
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded();
        let s = self.collectionView.contentSize
        return s;
    }
}

// MARK: UICollectionViewDataSource
extension LabelsCollectionView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 50
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(LabelCell.self)", for: indexPath)
       
        cell.backgroundColor = UIColor.blue
        cell.layer.cornerRadius = 17;

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if let index = selected {
//            let oldCell = collectionView.cellForItem(at: index)
//            oldCell?.layer.borderWidth = 0
//        }
//
//        let newCell = collectionView.cellForItem(at: indexPath)
//        newCell?.layer.borderWidth = 4
//        newCell?.layer.borderColor = UIColor.darkGray.cgColor
//        self.selected = indexPath
//
//        self.dismissKeyboard()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0,left: 0,bottom: 0,right: 0);
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 34, height: 34)
    }
}

