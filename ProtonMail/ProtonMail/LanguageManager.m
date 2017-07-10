//
//  LocalizationManager.m
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//


#import "LanguageManager.h"
#import "NSBundle+Language.h"

static NSString * const LanguageCodes[] = { @"en", @"de", @"fr", @"ru", @"es",
                                            @"tr", @"pl", @"uk" };

static NSString * const LanguageStrings[] = { @"English", @"German", @"French",
                                              @"Russian", @"Spanish", @"Turkish",
                                              @"Polish", @"Ukrainian"};

static NSString * const LanguageSaveKey = @"kProtonMailCurrentLanguageKey";

@implementation LanguageManager

+ (void)setupCurrentLanguage
{
    NSString *currentLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:LanguageSaveKey];
    if (!currentLanguage) {
        NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
        if (languages.count > 0) {
            currentLanguage = languages[0];
            [[NSUserDefaults standardUserDefaults] setObject:currentLanguage forKey:LanguageSaveKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
#ifndef USE_ON_FLY_LOCALIZATION
    [[NSUserDefaults standardUserDefaults] setObject:@[currentLanguage] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    NSString *currentCode = [[NSUserDefaults standardUserDefaults] objectForKey:LanguageSaveKey];
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
    return [[NSUserDefaults standardUserDefaults] objectForKey:LanguageSaveKey];
}

+ (NSInteger)currentLanguageIndex
{
    NSInteger index = 0;
    NSString *currentCode = [[NSUserDefaults standardUserDefaults] objectForKey:LanguageSaveKey];
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
        [[NSUserDefaults standardUserDefaults] setObject:code forKey:LanguageSaveKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
#ifdef USE_ON_FLY_LOCALIZATION
        [NSBundle setLanguage:code];
#endif
    }
}

+ (void)saveLanguageByCode:(NSString*)code {
    [[NSUserDefaults standardUserDefaults] setObject:code forKey:LanguageSaveKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
