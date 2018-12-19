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

final class StorefrontCollectionViewController: UICollectionViewController {
    typealias Sections = StorefrontViewModel.Sections
    private var coordinator: StorefrontCoordinator!
    
    internal var viewModel: StorefrontViewModel!
    private var viewModelObservers: [NSKeyValueObservation]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.setCollectionViewLayout(CollectionViewTableLayout(), animated: true, completion: nil)
        self.viewModelObservers = [
            self.viewModel.observe(\.title, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.title = viewModel.title
            }),
            self.viewModel.observe(\.logoItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.logo.indexSet)
            }),
            self.viewModel.observe(\.detailItems, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.detail.indexSet)
            }),
            self.viewModel.observe(\.annotationItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.annotation.indexSet)
            }),
            self.viewModel.observe(\.buyLinkItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.performBatchUpdates({
                    self.collectionView.reloadSections(Sections.buyLinkHeader.indexSet)
                    self.collectionView.reloadSections(Sections.buyLink.indexSet)
                }, completion: nil)
            }),
            self.viewModel.observe(\.othersItems, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.performBatchUpdates({
                    self.collectionView.reloadSections(Sections.others.indexSet)
                    self.collectionView.reloadSections(Sections.othersHeader.indexSet)
                }, completion: nil)
            }),
            self.viewModel.observe(\.buyButtonItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.buyButton.indexSet)
            })
        ]
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
            assert(false, "Failed to dequeue cell")
            return UICollectionViewCell()
        }
        
        cell.setup(with: item)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Sections(rawValue: indexPath.section) else {
            return
        }
        switch section {
        case .others:
            if let plan = self.viewModel.plan(at: indexPath) {
                self.coordinator.go(to: plan)
            }
        
        case .buyLink:
            if let subscription = self.viewModel.currentSubscription {
                self.coordinator.goToBuyMoreCredits(for: subscription)
            }
            
        default: break
        }
    }
    
    private func cellReuseIdentifier(for item: AnyStorefrontItem) -> String {
        switch item {
        case is LogoStorefrontItem: return "\(StorefrontLogoCell.self)"
        case is DetailStorefrontItem: return "\(StorefrontDetailCell.self)"
        case is AnnotationStorefrontItem: return "\(StorefrontAnnotationCell.self)"
        case is SubsectionHeaderStorefrontItem: return "\(StorefrontDisclaimerCell.self)"
        case is LinkStorefrontItem: return "\(StorefrontDetailCell.self)"
        case is BuyButtonStorefrontItem: return "\(StorefrontBuyButtonCell.self)"
        case is DisclaimerStorefrontItem: return "\(StorefrontDisclaimerCell.self)"
        default:
            assert(false, "Unknown cell type requested")
            return ""
        }
    }
}

extension StorefrontCollectionViewController: StorefrontBuyButtonCellDelegate {
    func buyButtonTapped() {
        self.viewModel.buy()
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

// is needed for Menu->ServiceLevel scene transition only via ServiceLevelCoordinator
extension StorefrontCollectionViewController: Coordinated {
    typealias CoordinatorType = ServiceLevelCoordinator
}
