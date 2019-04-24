//
//  ContactCollectionViewFlowLayout.swift
//  ProtonMail - Created on 4/27/18.
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
        
        guard let cv_dataSource = collectionView.dataSource else {
            return currentItemAttributes
        }
        
        let sectionInset = flowLayout.sectionInset
        
        let total = cv_dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
        let sections = cv_dataSource.numberOfSections!(in: collectionView)
        
        if indexPath.section >= sections {
            return currentItemAttributes
        }
        
        if indexPath.item == 0 {
            // first item of section
            var frame = currentItemAttributes.frame
            // first item of the section should always be left aligned
            frame.origin.x = sectionInset.left
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
        frame.origin.x = previousFrameRightPoint
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
