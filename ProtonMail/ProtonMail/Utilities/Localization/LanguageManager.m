//
//  LocalizationManager.m
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//


#import "LanguageManager.h"
#import "NSBundle+Language.h"

static NSString * const LanguageCodes[] = { @"en", @"de", @"fr",
                                            @"ru", @"es", @"tr",
                                            @"pl", @"uk", @"nl",
                                            @"it", @"pt-BR"
};

static NSString * const LanguageStrings[] = { @"English", @"German", @"French",
                                              @"Russian", @"Spanish", @"Turkish",
                                              @"Polish", @"Ukrainian", @"Dutch",
                                              @"Italian", @"PortugueseBrazil"
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
