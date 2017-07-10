//
//  LanguageManager.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


//
//  LanguageManager.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

//
//public class LanguageManager {
//    
//    fileprivate static let kCurrentLanguageKey : String = "kProtonMailCurrentLanguageKey"
//    
//    //static NSString * const LanguageSaveKey = @"currentLanguageKey";
//    
//    //    class func currentLanguage() -> String {
//    //        if let currentLanguage = UserDefaults.standard.object(forKey: kCurrentLanguageKey) as? String {
//    //            return currentLanguage
//    //        }
//    //        return defaultLanguage()
//    //    }
//    
//    static func setupCurrentLanguage() {
//        var currentLanguage = UserDefaults.standard.object(forKey: kCurrentLanguageKey) as? String
//        if currentLanguage == nil {
//            if let languages =  UserDefaults.standard.object(forKey: "AppleLanguages") as? [String], languages.count > 0 {
//                currentLanguage = languages[0];
//                //                [[NSUserDefaults standardUserDefaults] setObject:currentLanguage forKey:kProtonMailCurrentLanguageKey];
//                //                [[NSUserDefaults standardUserDefaults] synchronize];
//            }
//        }
//        
//        
//        #if USE_ON_FLY_LOCALIZATION
//            Bundle.setLanguage(language: currentLanguage!)
//            //PMLog.D(aa);
//            //Bundle.setLanguage(currentLanguage)
//            //[NSBundle setLanguage:currentLanguage];
//            
//        #else
//            PMLog.D(aa);
//            //            [[NSUserDefaults standardUserDefaults] setObject:@[currentLanguage] forKey:@"AppleLanguages"];
//            //            [[NSUserDefaults standardUserDefaults] synchronize];
//        #endif
//    }
//    
//    //    let selectedLanguage = currentLanguage();
//    //    self.latestBundle = nil
//    //    Bundle.setLanguage(selectedLanguage)
//    //    UserDefaults.standard.set(selectedLanguage, forKey: kProtonMailCurrentLanguageKey)
//    //    UserDefaults.standard.synchronize()
//    
//    //+ (NSArray *)languageStrings;
//    //+ (NSString *)currentLanguageString;
//    //+ (void)saveLanguageByIndex:(NSInteger)index;
//    
//    
////    static func currentLanguageIndex() -> Int {
////        var index : Int = 0;
////        var currentCode = UserDefaults.standard.object(forKey: kCurrentLanguageKey) as? String
////        let allLanguage = SLItem.allItems()
////        
////        for l in allLanguage {
////            if currentCode == l {
////             
////            }
////        }
////        
////        
////        
////        NSString *currentCode = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentLanguageKey];
////        for (NSInteger i = 0; i < ELanguageCount; ++i) {
////            if ([currentCode isEqualToString:LanguageCodes[i]]) {
////                index = i;
////                break;
////            }
////        }
////        return index;
////    }
//    
//    
////    static func currentLanguageString() -> String {
////        var currentCode = UserDefaults.standard.object(forKey: kCurrentLanguageKey) as? String
////        let allLanguage = SLItem.allItems()
////        
////        for l in allLanguage {
////            if currentCode == l {
////                
////            }
////        }
////        NSString *currentCode = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentLanguageKey];
////        for (NSInteger i = 0; i < ELanguageCount; ++i) {
////            if ([currentCode isEqualToString:LanguageCodes[i]]) {
////                index = i;
////                break;
////            }
////        }
////        return index;
////    }
////    
//    
//    static func currentLanguageCode() -> String {
//        var currentLanguage = UserDefaults.standard.object(forKey: kCurrentLanguageKey) as? String
//        if currentLanguage == nil {
//            if let languages =  UserDefaults.standard.object(forKey: "AppleLanguages") as? [String], languages.count > 0 {
//                currentLanguage = languages[0];
////                [[NSUserDefaults standardUserDefaults] setObject:currentLanguage forKey:kProtonMailCurrentLanguageKey];
////                [[NSUserDefaults standardUserDefaults] synchronize];
//            }
//        }
//        return currentLanguage ?? ""
//    }
//
//
//    static func isCurrentLanguageRTL() -> Bool {
//        let out = NSLocale.characterDirection(forLanguage: self.currentLanguageCode())
//        return out == .rightToLeft
//    }
//    
//}
