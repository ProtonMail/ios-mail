//
//  ServiceLevelViewModel.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

protocol ServiceLevelViewModel {
    var collectionViewLayout: UICollectionViewLayout { get }
    var sections: [Section<UIView>] { get }
    var cellTypes: [UICollectionViewCell.Type] { get }
    var accessoryTypes: [UICollectionReusableView.Type] { get }
}
extension ServiceLevelViewModel {
    var indexPaths: [IndexPath] {
        var indexPaths = [IndexPath]()
        self.sections.enumerated().map { sectionIndex, section in
            section.elements.enumerated().map { itemIndex, item in
                return IndexPath(item: itemIndex, section: sectionIndex)
            }
        }.forEach { indexPaths.append(contentsOf: $0) }
        return indexPaths
    }
}

class ServiceLevelViewModelTable: ServiceLevelViewModel {
    let cellTypes: [UICollectionViewCell.Type] = [ConfigurableCell.self]
    let accessoryTypes: [UICollectionReusableView.Type] = [Separator.self]
    
    lazy var sections: [Section<UIView>] = {
        // header
        let image = UIImage(named: "Logo")?.withRenderingMode(.alwaysTemplate)
        let headerView = ServicePlanHeader(image: image,
                                           title: "You are currently using Free version of ProtonMail which gives you access to following key features")
        let header = Section(elements: [headerView], cellType: ConfigurableCell.self)
        
        // capabilities
        let image2 = UIImage(named: "menu_folder")?.withRenderingMode(.alwaysTemplate)
        let image3 = UIImage(named: "menu_lockapp")?.withRenderingMode(.alwaysTemplate)
        let image4 = UIImage(named: "menu_sent-active")?.withRenderingMode(.alwaysTemplate)
        let capabilityView2 = ServicePlanCapability(image: image2, title: "5 email addresses")
        let capabilityView3 = ServicePlanCapability(image: image3, title: "5GB storage capacity")
        let capabilityView4 = ServicePlanCapability(image: image4, title: "Unlimited messages sent/day")
        let capabilities = Section(elements: [capabilityView2, capabilityView3, capabilityView4], cellType: ConfigurableCell.self)
        
        // footer
        let footerView = ServicePlanFooter(title: "You currently have credits to use until FOREVERYou currently have credits to use until FOREVERYou currently have credits to use until FOREVER")
        let footer = Section(elements: [footerView], cellType: ConfigurableCell.self)
        
        // links
        let link1 = ServicePlanCapability(title: "ProtonMail Plus", serviceIconVisible: true)
        let link2 = ServicePlanCapability(title: "ProtonMail Pro", serviceIconVisible: true)
        let link3 = ServicePlanCapability(title: "ProtonMail Visionary", serviceIconVisible: true)
        let links = Section(elements: [link1, link2, link3], cellType: ConfigurableCell.self)
        
        return [header, capabilities, footer, links]
    }()
    
    lazy var collectionViewLayout: UICollectionViewLayout = TableLayout()
}
