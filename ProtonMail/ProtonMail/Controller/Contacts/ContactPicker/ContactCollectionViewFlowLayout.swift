//
//  ContactCollectionViewFlowLayout.swift
//  ProtonMail - Created on 4/27/18.
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

@objc protocol ContactCollectionViewDelegateFlowLayout : NSObjectProtocol {
    @objc func collectionView(collectionView : UICollectionView?, willChangeContentSizeTo newSize: CGSize)
}

class ContactCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let initialAttributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        
        let attributesToReturn = initialAttributes.map { attributes -> UICollectionViewLayoutAttributes in
            guard attributes.representedElementKind == nil,
                let f = self.layoutAttributesForItem(at: attributes.indexPath)?.frame,
                let copy = attributes.copy() as? UICollectionViewLayoutAttributes else
            {
                return attributes
            }
            copy.frame = f
            return copy
        }
        
        return attributesToReturn
    }
    
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        /// supper item attributes at indexPath
        guard let currentItemAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }
        
        /// current collection view
        guard let collectionView = self.collectionView else {
            return currentItemAttributes
        }
        
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return currentItemAttributes
        }
        
        guard let cvDataSource = collectionView.dataSource else {
            return currentItemAttributes
        }
        
        let sectionInset = flowLayout.sectionInset
        
        let total = cvDataSource.collectionView(collectionView, numberOfItemsInSection: 0)
        let sections = cvDataSource.numberOfSections!(in: collectionView)
        
        if indexPath.section >= sections {
            return currentItemAttributes
        }
        
        let rows = cvDataSource.collectionView(collectionView, numberOfItemsInSection: indexPath.section)
        if indexPath.item == 0  {
            // first item of section
            var frame = currentItemAttributes.frame
            // first item of the section should always be left aligned
            frame.origin.x = sectionInset.left
            if rows == 1 {
                // Entry cell
                let newWidth = collectionView.frame.width - sectionInset.left - sectionInset.right
                frame.size.width = max(max(50, newWidth.rounded(.up)), frame.width)
            }
            currentItemAttributes.frame = frame
            return currentItemAttributes
        }
        
        let previousIndexPath = IndexPath(item:indexPath.item - 1, section:indexPath.section)
        
        guard let previousFrame = self.layoutAttributesForItem(at: previousIndexPath)?.frame else {
            return currentItemAttributes
        }
        
        let previousFrameRightPoint = previousFrame.origin.x + previousFrame.width
        
        let currentFrame = currentItemAttributes.frame
        let stretchedCurrentFrame = CGRect(x: 0, y: currentFrame.origin.y,
                                              width: collectionView.frame.width,
                                              height: currentFrame.height)
        if !previousFrame.intersects(stretchedCurrentFrame) {
            // if current item is the first item on the line
            // the approach here is to take the current frame, left align it to the edge of the view
            // then stretch it the width of the collection view, if it intersects with the previous frame then that means it
            // is on the same line, otherwise it is on it's own new line
            var frame = currentItemAttributes.frame

            //TODO:: later
//            if collectionView.frame.width - previousFrame.origin.x >  collectionView.frame.width / 2 {
//                frame.origin.y = previousFrame.origin.y
//                frame.origin.x = previousFrameRightPoint
//                frame.size.width =  collectionView.frame.width - previousFrameRightPoint - sectionInset.right
//            } else {
//                frame.origin.x = sectionInset.left // first item on the line should always be left aligned
//            }
            
            frame.origin.x = sectionInset.left // first item on the line should always be left aligned
            if indexPath.row == total - 1 {
                let newWidth = collectionView.frame.width - sectionInset.left - sectionInset.right
                frame.size.width = max(max(50, newWidth.rounded(.up)), frame.width)
            }
            currentItemAttributes.frame = frame
            return currentItemAttributes
        }

        var frame = currentItemAttributes.frame
        frame.origin.x = previousFrameRightPoint + self.minimumInteritemSpacing
        if indexPath.row == total - 1 {
            let newWidth = collectionView.frame.width - previousFrameRightPoint - sectionInset.right
            frame.size.width = max(max(50, newWidth.rounded(.up)), frame.width)
        }
        currentItemAttributes.frame = frame
        return currentItemAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func finalizeCollectionViewUpdates() {
        if let delegate = self.collectionView?.delegate as? ContactCollectionViewDelegateFlowLayout {
            if delegate.responds(to: #selector(ContactCollectionViewDelegateFlowLayout.collectionView(collectionView:willChangeContentSizeTo:))) {
                delegate.collectionView(collectionView: self.collectionView, willChangeContentSizeTo: self.collectionViewContentSize)
            }
        }
    }
}
