//
//  NSBundle+Language.h
//  ImmidiateLanguageChange
//
//  Created by Manuel Meyer on 26/04/15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define USE_ON_FLY_LOCALIZATION


#ifdef USE_ON_FLY_LOCALIZATION

@interface NSBundle (Language)

+ (void)setLanguage:(NSString *)language;

@end

#endif
