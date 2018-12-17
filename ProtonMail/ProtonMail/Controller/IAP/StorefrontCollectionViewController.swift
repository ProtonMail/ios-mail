//
//  StorefrontCollectionViewController.swift
//  ProtonMail - Created on 16/12/2018.
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

class StorefrontCollectionViewController: UICollectionViewController {
    private var coordinator: StorefrontCoordinator = StorefrontCoordinator()
    var viewModel: StorefrontViewModel!
    
    var modelObserver: NSKeyValueObservation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.setCollectionViewLayout(TableLayout(), animated: true, completion: nil)
        
        self.modelObserver = self.viewModel.observe(\.storefront, options: [.initial, .new], changeHandler: { storefront, change in
            self.collectionView.reloadData()
        })
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.numberOfSections()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let item = self.viewModel.item(for: indexPath)
        let cellReuseIdentifier = self.cellReuseIdentifier(for: item)
        
        guard let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? StorefrontItemConfigurableCell else
        {
            fatalError()
        }
        
        cell.setup(with: item)
        return cell
    }
    
    private func cellReuseIdentifier(for item: StorefrontItem) -> String {
        switch item {
        case .logo: return "\(LogoCell.self)"
        case .detail: return "\(DetailCell.self)"
        case .annotation: return "\(AnnotationCell.self)"
        case .subsectionHeader: return "\(DisclaimerCell.self)"
        case .link: return "\(DetailCell.self)"
//        case .buyButton: return "\(.self)"
//        case .disclaimer: return "\(.self)"
        }
    }
}


class StorefrontCoordinator: CoordinatorNew {
    func start() {
        fatalError("🚀")
    }
}

