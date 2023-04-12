//
//  LanguageManager.swift
//  Proton Mail - Created on 6/5/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.


#import <Foundation/Foundation.h>
//Notes: when add new language need to do:
//       1. update ELanguage enum
//       2. update extension ELanguage in viewmodel -- allItemsCode & allItems
//       3. update .m of this file update the string&code
/// Map to swift as a service
typedef NS_ENUM(NSInteger, ELanguage)
{
    ELanguageBelarusian, // added at 02/21/2023
    ELanguageCatalan,            // add at 12/20/2018
    ELanguageChineseSimplified,  // add at 12/20/2018
    ELanguageChineseTraditional, // add at 12/20/2018
    ELanguageCroatian,          // add at 12/02/2019
    ELanguageCzech,              // add at 12/20/2018
    ELanguageDanish,             // add at 12/20/2018
    ELanguageDutch, //added at 08/07/2017
    ELanguageEnglish,
    ELanguageFrench,
    ELanguageGerman, //added at inital
    ELanguageGreek, // added at 02/21/2023
    ELanguageHungarian,         // add at 04/16/2019
    ELanguageIcelandic,         // add at 04/16/2019
    ELanguageIndonesian,        // add at 07/01/2019
    ELanguageItalian, //add at 10/05/2017
    ELanguageJapanese,          // add at 07/01/2019
    ELanguageKabyle,            // add at 04/16/2019
    ELanguagePolish, //added at 07/05/2017
    ELanguagePortuguese,         // add at 12/20/2018
    ELanguagePortugueseBrazil, //add at 18/10/2017
    ELanguageRomanian,           // add at 12/26/2018
    ELanguageRussian,
    ELanguageSpanish,
    ELanguageSwedish,           // add at 04/16/2019
    ELanguageTurkish,
    ELanguageUkrainian,
    
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
