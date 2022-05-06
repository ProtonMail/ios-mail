//
//  LocalizationManager.m
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


#import "LanguageManager.h"
#import "NSBundle+Language.h"

//TODO:: we need port this to swift

static NSString * const LanguageCodes[] = { @"en", @"de", @"fr",
                                            @"ru", @"es", @"tr",
                                            @"pl", @"uk", @"nl",
                                            @"it", @"pt-BR",
                                            @"zh-Hans", @"zh-Hant", @"ca", @"da", @"cs", @"pt", @"ro", @"hr",
                                            @"hu", @"is", @"kab", @"sv", @"ja", @"id"
};

static NSString * const LanguageStrings[] = { @"English", @"German", @"French",
                                              @"Russian", @"Spanish", @"Turkish",
                                              @"Polish", @"Ukrainian", @"Dutch",
                                              @"Italian", @"PortugueseBrazil", @"Chinese Simplified",
                                              @"Chinese Traditional", @"Catalan", @"Danish",
                                              @"Czech", @"portuguese", @"Romanian", @"Croatian",
                                              @"Hungarian", @"Icelandic", @"Kabyle", @"Swedish",
                                              @"Japanese", @"Indonesian"
};

static NSString * const LanguageSaveKey = @"kProtonMailCurrentLanguageKey";

#ifndef Enterprise
static NSString * const LanguageAppGroup = @"group.com.protonmail.protonmail";
#else
static NSString * const LanguageAppGroup = @"group.ch.protonmail.protonmail";
#endif

#if !defined(NS_BLOCK_ASSERTIONS)
#define STATIC_ASSERT(cond, message_var_name) \
extern char static_assert_##message_var_name[(cond) ? 1 : -1]

STATIC_ASSERT(ELanguageCount == sizeof(LanguageCodes) / sizeof(NSString*), language_count_mismatch_add_or_remove_languageCodes);
STATIC_ASSERT(ELanguageCount == sizeof(LanguageStrings) / sizeof(NSString*), language_count_mismatch_add_or_remove_LanguageStrings);

#endif

@implementation LanguageManager

+ (void)setupCurrentLanguage
{
    NSUserDefaults* shared = [[NSUserDefaults alloc] initWithSuiteName:LanguageAppGroup];
    NSString *currentLanguage = [shared objectForKey:LanguageSaveKey];
    if (!currentLanguage) {
        NSArray *languages = [shared objectForKey:@"AppleLanguages"];
        if (languages.count > 0) {
            currentLanguage = languages[0];
            [shared setObject:currentLanguage forKey:LanguageSaveKey];
            [shared synchronize];
        }
    }
#ifndef USE_ON_FLY_LOCALIZATION
    [shared setObject:@[currentLanguage] forKey:@"AppleLanguages"];
    [shared synchronize];
#else
    [NSBundle setLanguage:currentLanguage];
#endif
}

+ (NSArray *)languageStrings
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < ELanguageCount; ++i) {
        [array addObject:NSLocalizedString(LanguageStrings[i], @"")];
    }
    return [array copy];
}

+ (NSString *)currentLanguageString
{
    NSString *string = @"";
    NSString *currentCode = [[[NSUserDefaults alloc] initWithSuiteName:LanguageAppGroup] objectForKey:LanguageSaveKey];
    for (NSInteger i = 0; i < ELanguageCount; ++i) {
        if ([currentCode isEqualToString:LanguageCodes[i]]) {
            string = NSLocalizedString(LanguageStrings[i], @"");
            break;
        }
    }
    return string;
}

+ (NSString *)currentLanguageCode
{
    return [[[NSUserDefaults alloc] initWithSuiteName:LanguageAppGroup] objectForKey:LanguageSaveKey];
}

+ (NSInteger)currentLanguageIndex
{
    NSInteger index = 0;
    NSString *currentCode = [[[NSUserDefaults alloc] initWithSuiteName:LanguageAppGroup] objectForKey:LanguageSaveKey];
    for (NSInteger i = 0; i < ELanguageCount; ++i) {
        if ( [currentCode containsString: LanguageCodes[i] ] ) {
            index = i;
            break;
        }
    }
    return index;
}


+ (ELanguage)currentLanguageEnum {
    NSInteger index = [self currentLanguageIndex];
    return (ELanguage)(index);
}

+ (void)saveLanguageByIndex:(NSInteger)index
{
    if (index >= 0 && index < ELanguageCount) {
        NSString *code = LanguageCodes[index];
        NSUserDefaults* shared = [[NSUserDefaults alloc] initWithSuiteName:LanguageAppGroup];
        [shared setObject:code forKey:LanguageSaveKey];
        [shared synchronize];
#ifdef USE_ON_FLY_LOCALIZATION
        [NSBundle setLanguage:code];
#endif
    }
}

+ (void)saveLanguageByCode:(NSString*)code {
    NSUserDefaults* shared = [[NSUserDefaults alloc] initWithSuiteName:LanguageAppGroup];
    [shared setObject:code forKey:LanguageSaveKey];
    [shared synchronize];
#ifdef USE_ON_FLY_LOCALIZATION
    [NSBundle setLanguage:code];
#endif
    
}


+ (BOOL)isCurrentLanguageRTL
{
    NSInteger currentLanguageIndex = [self currentLanguageIndex];
    return ([NSLocale characterDirectionForLanguage:LanguageCodes[currentLanguageIndex]] == NSLocaleLanguageDirectionRightToLeft);
}

@end
