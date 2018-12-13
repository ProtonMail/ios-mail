//
//  LanguageManager.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

#import <Foundation/Foundation.h>
//Notes: when add new language need to do:
//       1. update ELanguage enum
//       2. update extension ELanguage in viewmodel -- allItemsCode & allItems
//       3. update .m of this file update the string&code
typedef NS_ENUM(NSInteger, ELanguage)
{
    ELanguageEnglish,
    ELanguageGerman, //added at inital
    ELanguageFrench,
    ELanguageRussian,
    ELanguageSpanish,
    ELanguageTurkish,
    
    ELanguagePolish, //added at 07/05/2017
    ELanguageUkrainian,
    
    ELanguageDutch, //added at 08/07/2017
    
    ELanguageItalian, //add at 10/05/2017
    
    ELanguagePortugueseBrazil, //add at 18/10/2017
    
    ELanguageCount
};

///TODO::fixme -- port this to swift
@interface LanguageManager : NSObject

+ (void)setupCurrentLanguage;
+ (NSArray *)languageStrings;
+ (NSString *)currentLanguageString;
+ (NSString *)currentLanguageCode;
+ (NSInteger)currentLanguageIndex;
+ (ELanguage)currentLanguageEnum;
+ (void)saveLanguageByIndex:(NSInteger)index;
+ (void)saveLanguageByCode:(NSString*)e;
+ (BOOL)isCurrentLanguageRTL;

@end
