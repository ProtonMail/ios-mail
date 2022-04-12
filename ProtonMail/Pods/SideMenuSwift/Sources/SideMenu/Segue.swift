//
//  SideMenuSegue.swift
//  SideMenu
//
//  Created by kukushi on 2018/8/8.
//  Copyright © 2018 kukushi. All rights reserved.
//

import UIKit

/// Custom Segue that is required for SideMenuController to be used in Storyboard.
open class SideMenuSegue: UIStoryboardSegue {

    /// The type of segue
    ///
    /// - content: represent the content scene of side menu
    /// - menu: represent the menu scene of side menu
    public enum ContentType: String {
        case content = "SideMenu.Content"
        case menu = "SideMenu.Menu"
    }

    /// current content type
    public var contentType = ContentType.content

    /// Performing the segue, will change the corresponding view controller of side menu to `destination` view controller.
    /// This method is called when loading from storyboard.
    open override func perform() {
        guard let sideMenuController = source as? SideMenuController else {
            return
        }

        switch contentType {
        case .content:
            sideMenuController.contentViewController = destination
        case .menu:
            sideMenuController.menuViewController = destination
        }
    }

}
