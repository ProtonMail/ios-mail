//
//  ServiceLevelViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ConfigurableCell: UICollectionViewCell {
    private var subview: UIView?
    
    func configure(with subview: UIView) {
        self.subview = subview
        
        self.contentView.subviews.forEach{ $0.removeFromSuperview() }
        self.contentView.addSubview(subview)
        if #available(iOS 9.0, *) {
            subview.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
            subview.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
            subview.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
            subview.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        }
    }
}

class FullSizeCell: ConfigurableCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.backgroundColor = .red
    }
}

class MinimizedCell: ConfigurableCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.backgroundColor = .blue
    }
}

struct Section<Element: UIView> {
    fileprivate var elements: Array<Element>
    var cellType: ConfigurableCell.Type
    var count: Int {
        return self.elements.count
    }
    func embed(_ elementNumber: Int, onto cell: ConfigurableCell) {
        cell.configure(with: self.elements[elementNumber])
    }
}

protocol ServiceLevelViewModel {
    var collectionViewLayout: UICollectionViewLayout { get }
    var sections: [Section<UIView>] { get }
}

class ServiceLevelViewModelTable: ServiceLevelViewModel {
    lazy var sections: [Section<UIView>] = {
        let fullsizeView: ()->UIView = {
            let view = UIView(frame: .init(x: 0, y: 0, width: 100, height: 300))
            view.backgroundColor = .yellow
            view.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 9.0, *) {
                view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                view.widthAnchor.constraint(equalToConstant: 100).isActive = true
            }
            return view
        }
        
        
        let minimalView: ()->UIView = {
            let view = UIView(frame: .init(x: 0, y: 0, width: 100, height: 100))
            view.backgroundColor = .green
            view.translatesAutoresizingMaskIntoConstraints = false
            if #available(iOS 9.0, *) {
                view.heightAnchor.constraint(equalToConstant: 100).isActive = true
                view.widthAnchor.constraint(equalToConstant: 100).isActive = true
            }
            return view
        }
        
        let fullsize = Section<UIView>.init(elements: [fullsizeView()], cellType: FullSizeCell.self)
        let minimized = Section<UIView>.init(elements: [minimalView(), minimalView(), minimalView()], cellType: MinimizedCell.self)
        return [fullsize, minimized]
    }()
    
    lazy var collectionViewLayout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.estimatedItemSize = .init(width: 100, height: 100)
        return layout
    }()
    
}

class ServiceLevelViewController: UICollectionViewController, Coordinated {
    typealias CoordinatorType = ServiceLevelCoordinator
    private lazy var viewModel: ServiceLevelViewModel = ServiceLevelViewModelTable()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView?.register(FullSizeCell.self)
        self.collectionView?.register(MinimizedCell.self)
        
        self.collectionView?.setCollectionViewLayout(self.viewModel.collectionViewLayout, animated: true, completion: nil)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.sections[section].count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = self.viewModel.sections[indexPath.section]
        guard let cell = self.collectionView?.dequeueReusableCell(section.cellType, for: indexPath) else {
            fatalError()
        }
        section.embed(indexPath.row, onto: cell)
        return cell
    }
}

extension UICollectionView {
    func register(_ cellClass: AnyClass) {
        self.register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass))
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(_ cellClass: T.Type, for indexPath: IndexPath) -> T? {
        return self.dequeueReusableCell(withReuseIdentifier: String(describing: cellClass), for: indexPath) as? T
    }
}
