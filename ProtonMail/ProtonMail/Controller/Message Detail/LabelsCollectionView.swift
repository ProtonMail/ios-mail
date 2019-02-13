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
