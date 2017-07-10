//
//  BundleLanguage+Extension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


#if USE_ON_FLY_LOCALIZATION
    
    extension Bundle {
        
//        
//        static func setLanguage(language: String) {
//           // var onceToken:dispatch_once_t = 0
//            
////            static dispatch_once_t onceToken;
////            dispatch_once(&onceToken, ^{
////              object_setClass([NSBundle mainBundle], [BundleEx class]);
////            });
//            
//            
//            if LanguageManager.isCurrentLanguageRTL() {
//                if UIView().responds(to: "setSemanticContentAttribute:") {
//                    PMLog.D("");
//                }
//                
////                if ([[[UIView alloc] init] respondsToSelector:@selector(setSemanticContentAttribute:)]) {
////                    [[UIView appearance] setSemanticContentAttribute:
////                        UISemanticContentAttributeForceRightToLeft];
////                }
//            }else {
////                if ([[[UIView alloc] init] respondsToSelector:@selector(setSemanticContentAttribute:)]) {
////                    [[UIView appearance] setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
////                }
//                if UIView().responds(to: "setSemanticContentAttribute:") {
//                    UIView.appearance().semanticContentAttribute(.leftToRight)
////                    [[UIView appearance] setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
//                }
//            }
        
//            [[NSUserDefaults standardUserDefaults] setBool:[LanguageManager isCurrentLanguageRTL] forKey:@"AppleTextDirection"];
//            [[NSUserDefaults standardUserDefaults] setBool:[LanguageManager isCurrentLanguageRTL] forKey:@"NSForceRightToLeftWritingDirection"];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//            
//            id value = language ? [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:language ofType:@"lproj"]] : nil;
//            objc_setAssociatedObject([NSBundle mainBundle], &kBundleKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//            
//        }
        
    }
    
    
#endif
