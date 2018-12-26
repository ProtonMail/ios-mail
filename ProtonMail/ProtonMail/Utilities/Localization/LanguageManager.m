//
//  LocalizationManager.m
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


#import "LanguageManager.h"
#import "NSBundle+Language.h"

static NSString * const LanguageCodes[] = { @"en", @"de", @"fr",
                                            @"ru", @"es", @"tr",
                                            @"pl", @"uk", @"nl",
                                            @"it", @"pt-BR",
                                            @"zh-Hans", @"zh-Hant", @"ca", @"da", @"cs", @"pt", @"ro"
};

static NSString * const LanguageStrings[] = { @"English", @"German", @"French",
                                              @"Russian", @"Spanish", @"Turkish",
                                              @"Polish", @"Ukrainian", @"Dutch", @"Italian", @"PortugueseBrazil",
                                              @"Chinese Simplified", @"Chinese Traditional", @"Catalan", @"Danish", @"Czech", @"portuguese", @"Romanian"
};

static NSString * const LanguageSaveKey = @"kProtonMailCurrentLanguageKey";

#ifndef Enterprise
static NSString * const LanguageAppGroup = @"group.com.protonmail.protonmail";
#else
static NSString * const LanguageAppGroup = @"group.ch.protonmail.protonmail";
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
        if ([currentCode isEqualToString:LanguageCodes[i]]) {
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
