//
//  LanguageManager.swift
//  ProtonMail - Created on 6/5/17.
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


#import <Foundation/Foundation.h>
//Notes: when add new language need to do:
//       1. update ELanguage enum
//       2. update extension ELanguage in viewmodel -- allItemsCode & allItems
//       3. update .m of this file update the string&code
/// Map to swift as a service
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
    
    ELanguageChineseSimplified,  // add at 12/20/2018
    ELanguageChineseTraditional, // add at 12/20/2018
    ELanguageCatalan,            // add at 12/20/2018
    ELanguageDanish,             // add at 12/20/2018
    ELanguageCzech,              // add at 12/20/2018
    ELanguagePortuguese,         // add at 12/20/2018
    ELanguageRomanian,           // add at 12/26/2018
    
    ELanguageCroatian,          // add at 12/02/2019
    
    ELanguageHungarian,         // add at 04/16/2019
    ELanguageIcelandic,         // add at 04/16/2019
    ELanguageKabyle,            // add at 04/16/2019
    ELanguageSwedish,           // add at 04/16/2019
    
    ELanguageJapanese,          // add at 07/01/2019
    ELanguageIndonesian,        // add at 07/01/2019
    
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
