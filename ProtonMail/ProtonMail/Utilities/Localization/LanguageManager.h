//
//  LanguageManager.swift
//  ProtonMail - Created on 6/5/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
    
    ELanguageChineseSimplified,  // add at 12/20/2018
    ELanguageChineseTraditional, // add at 12/20/2018
    ELanguageCatalan,            // add at 12/20/2018
    ELanguageDanish,             // add at 12/20/2018
    ELanguageCzech,              // add at 12/20/2018
    ELanguagePortuguese,         // add at 12/20/2018
    ELanguageRomanian,           // add at 12/26/2018
    
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
