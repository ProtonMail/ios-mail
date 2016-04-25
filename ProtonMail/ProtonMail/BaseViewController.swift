//
//  BaseViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/25/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation

class BaseViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: "languageDidChangeNotification:", name: NSNotification.Name(rawValue: NotificationDefined.languageDidChange), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func languageDidChangeNotification(notification:NSNotification){
        languageDidChange()
    }
    
    func languageDidChange(){
        
    }
    
    func setLanguage(l : String) {
        Localization.setCurrentLanguage(language: l)
    }
}
