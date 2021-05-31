//
//  NSDictionary+SentrySanitize.m
//  Sentry
//
//  Created by Daniel Griesser on 16/06/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/NSDictionary+SentrySanitize.h>
#import <Sentry/NSDate+SentryExtras.h>

#else
#import "NSDictionary+SentrySanitize.h"
#import "NSDate+SentryExtras.h"
#endif

@implementation NSDictionary (SentrySanitize)

- (NSDictionary *)sentry_sanitize {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (id rawKey in self.allKeys) {
        NSString *stringKey;
        if ([rawKey isKindOfClass:[NSString class]]) {
            stringKey = rawKey;
        } else {
            stringKey = [rawKey description];
        }

        if ([[self objectForKey:rawKey] isKindOfClass:NSDictionary.class]) {
            [dict setValue:[((NSDictionary *)[self objectForKey:rawKey]) sentry_sanitize] forKey:stringKey];
        } else if ([[self objectForKey:rawKey] isKindOfClass:NSDate.class]) {
            [dict setValue:[((NSDate *)[self objectForKey:rawKey]) sentry_toIso8601String] forKey:stringKey];
        } else if ([stringKey hasPrefix:@"__sentry"]) {
            continue; // We don't want to add __sentry variables
        } else {
            [dict setValue:[self objectForKey:rawKey] forKey:stringKey];
        }
    }
    return dict;
}

@end
