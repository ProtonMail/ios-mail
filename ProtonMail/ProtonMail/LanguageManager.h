//
//  LanguageManager.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

#import <Foundation/Foundation.h>

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
    
    
    ELanguageCount
};

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
