//
//  Localization.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/20/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


public extension String {
    
    func localized() -> String {
        if let bundle = Localization.getBundle() {
            return bundle.localizedString(forKey: self, value: nil, table: nil)
        }
        else {
            return NSLocalizedString(self, comment: "")
        }
    }
}


public class Localization {
    
    static let kDefaultLanguage = "en"
    static let kProtonMailCurrentLanguageKey = "kProtonMailCurrentLanguageKey"
    static let kBaseLanguage = "Base"
    
    static var latestBundle : Bundle? = nil
    
    class func availableLanguages() -> [String] {
        return Bundle.main.localizations
    }
    
    class func currentLanguage() -> String {
        if let currentLanguage = UserDefaults.standard.object(forKey: kProtonMailCurrentLanguageKey) as? String {
            return currentLanguage
        }
        return defaultLanguage()
    }
    
    
    class func getBundle() -> Bundle? {
        
        if latestBundle == nil {
            if let path = Bundle.main.path(forResource: currentLanguage(), ofType: "lproj") {
                if let b : Bundle = Bundle(path: path) {
                    latestBundle = b
                }
                return latestBundle
            }
        }
        return latestBundle
    }
    
    class func setCurrentLanguage(language: String) {
//        let selectedLanguage = availableLanguages().contains(language) ? language : defaultLanguage()
//        if (selectedLanguage != currentLanguage()){
//            UserDefaults.standard.set(selectedLanguage, forKey: kProtonMailCurrentLanguageKey)
//            UserDefaults.standard.synchronize()
//            self.latestBundle = nil
//            Bundle.setLanguage(selectedLanguage)
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationDefined.languageDidChange), object: selectedLanguage)
//        }
    }
    
    class func restoreLanguage() {
//        let selectedLanguage = currentLanguage();
//        self.latestBundle = nil
//        Bundle.setLanguage(selectedLanguage)
//        UserDefaults.standard.set(selectedLanguage, forKey: kProtonMailCurrentLanguageKey)
//        UserDefaults.standard.synchronize()
    }
    
    class func defaultLanguage() -> String {
        var defaultLanguage: String = String()
        if let preferredLanguage = Bundle.main.preferredLocalizations.first{
            let availableLanguages: [String] = self.availableLanguages()
            if (availableLanguages.contains(preferredLanguage)) {
                defaultLanguage = preferredLanguage
            }
            else {
                defaultLanguage = Localization.kDefaultLanguage
            }
            
            return self.kDefaultLanguage
        }
        
        return defaultLanguage
    }
    
    public class func displayNameForLanguage(language: String) -> String {
        let locale : NSLocale = NSLocale(localeIdentifier: currentLanguage())
        if let displayName = locale.displayName(forKey: NSLocale.Key.identifier, value: language) {
            return displayName
        }
        return String()
    }
}




