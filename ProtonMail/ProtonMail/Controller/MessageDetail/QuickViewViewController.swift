//
//  QuickViewViewController.swift
//  ProtonMail - Created on 9/21/15.
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
import QuickLook


class QuickViewViewController: QLPreviewController {

    var isPresented = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .lightContent
        }
    }
    
    @available(iOS 15, *)
    private func configureNavigationBar_iOS15() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        let navigationBarTitleFont = Fonts.h2.light
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
        let barAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self])
        barAppearance.standardAppearance = appearance
        barAppearance.scrollEdgeAppearance = appearance
        barAppearance.compactAppearance = appearance
        barAppearance.compactScrollEdgeAppearance = appearance
    }

    func configureNavigationBar(_ navigationController: UINavigationController) {
        if #available(iOS 15, *) {
            self.configureNavigationBar_iOS15()
        }
        navigationController.navigationBar.tintColor = UIColor.black
        let navigationBarTitleFont = Fonts.h2.light
        navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let views = self.children
        if views.count > 0 {
            if let nav = views[0] as? UINavigationController {
                configureNavigationBar(nav)
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        isPresented = false
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate : Bool {
        
        return true
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
