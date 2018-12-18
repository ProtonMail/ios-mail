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
    typealias Sections = StorefrontViewModel.Sections
    private var coordinator: StorefrontCoordinator!
    var viewModel: StorefrontViewModel!
    
    private var titleObserver: NSKeyValueObservation!
    private var logoObserver: NSKeyValueObservation!
    private var detailObserver: NSKeyValueObservation!
    private var annotationObserver: NSKeyValueObservation!
    private var subsectionHeaderObserver: NSKeyValueObservation!
    private var othersObserver: NSKeyValueObservation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.setCollectionViewLayout(TableLayout(), animated: true, completion: nil)
        
        self.titleObserver = self.viewModel.observe(\.title, options: [.initial, .new]) { [unowned self] viewModel, change in
            self.title = viewModel.title
        }
        self.logoObserver = self.viewModel.observe(\.logoItem) { [unowned self] viewModel, change in
            self.collectionView.reloadSections(Sections.logo.indexSet)
        }
        self.detailObserver = self.viewModel.observe(\.detailItems) { [unowned self] viewModel, change in
            self.collectionView.reloadSections(Sections.detail.indexSet)
        }
        self.annotationObserver = self.viewModel.observe(\.annotationItem) { [unowned self] viewModel, change in
            self.collectionView.reloadSections(Sections.annotation.indexSet)
        }
        self.subsectionHeaderObserver = self.viewModel.observe(\.subsectionHeaderItem) { [unowned self] viewModel, change in
            self.collectionView.reloadSections(Sections.subsectionHeader.indexSet)
        }
        self.othersObserver = self.viewModel.observe(\.othersItems) { [unowned self] viewModel, change in
            self.collectionView.reloadSections(Sections.others.indexSet)
        }
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
        
        guard let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? StorefrontItemConfigurableCell else {
            fatalError()
        }
        
        cell.setup(with: item)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let plan = self.viewModel.plan(at: indexPath) {
            self.coordinator.go(to: plan)
        }
    }
    
    private func cellReuseIdentifier(for item: AnyStorefrontItem) -> String {
        switch item {
        case is LogoStorefrontItem: return "\(LogoCell.self)"
        case is DetailStorefrontItem: return "\(DetailCell.self)"
        case is AnnotationStorefrontItem: return "\(AnnotationCell.self)"
        case is SubsectionHeaderStorefrontItem: return "\(DisclaimerCell.self)"
        case is LinkStorefrontItem: return "\(DetailCell.self)"
//        case .buyButton: return "\(.self)"
//        case .disclaimer: return "\(.self)"
        default:
            assert(false, "Unknown cell type requested")
            return ""
        }
    }
}

extension StorefrontCollectionViewController: CoordinatedNew {
    typealias coordinatorType = StorefrontCoordinator
    
    func set(coordinator: StorefrontCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
}
