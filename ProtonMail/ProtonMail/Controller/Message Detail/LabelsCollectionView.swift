//
//  RecipientView.swift
//  ProtonMail - Created on 9/10/15.
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

protocol LabelsCollectionViewDelegate : RecipientCellDelegate {
    
}

class LabelsCollectionView: PMView {
    override func getNibName() -> String {
        return "LabelsCollectionView"
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var labels : [Label]?
    
    override func setup() {
        let nib = UINib(nibName: "\(LabelCell.self)", bundle: Bundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "\(LabelCell.self)")
        
//        collectionView.collectionViewLayout
    }
    
    func getContentSize() -> CGSize{
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded();
        let s = self.collectionView.contentSize
        return s;
    }
    
    func update( _ labels: [Label]?) {
        self.labels = labels
    }
}

// MARK: UICollectionViewDataSource
extension LabelsCollectionView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return labels == nil ? 0 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return labels?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(LabelCell.self)", for: indexPath)
        if let label = self.labels?[indexPath.row], let labelCell = cell as? LabelCell {
            labelCell.config(color: label.color, text: label.name)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0,left: 0,bottom: 0,right: 0);
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let label = self.labels?[indexPath.row] {
            let size = LabelCell.estimateSize(label.name)
            return CGSize(width: size.width.rounded(.up), height: size.height.rounded(.up))
        }
        return CGSize(width: 0, height: 0)
    }
    
}


/// make it more generic later since only used ini labels view
class LeftAlignLayout: UICollectionViewFlowLayout {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.minimumInteritemSpacing = 2
        self.minimumLineSpacing = 4
        self.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let superlayoutAttributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        let layoutAttributes = superlayoutAttributes.map { $0.copy() as! UICollectionViewLayoutAttributes }
        // must vertical
        guard scrollDirection == .vertical else {
            return layoutAttributes
        }
        
        // Filter attributes to compute only cell attributes
        let cellAttributes = layoutAttributes.filter({ $0.representedElementCategory == .cell })
        
        // Group cell attributes by row (cells with same vertical center) and loop on those groups
        for (_, attributes) in Dictionary(grouping: cellAttributes, by: { ($0.center.y / 10).rounded(.up) * 10 }) {
            // Set the initial left inset
            var leftInset = sectionInset.left
            
            // Loop on cells to adjust each cell's origin and prepare leftInset for the next cell
            for attribute in attributes {
                attribute.frame.origin.x = leftInset
                leftInset = attribute.frame.maxX + minimumInteritemSpacing
            }
        }
        
        return layoutAttributes
    }
    
}
