#import "NSMutableDictionary+Sentry.h"

@implementation
NSMutableDictionary (Sentry)

- (void)mergeEntriesFromDictionary:(NSDictionary *)otherDictionary
{
    [otherDictionary enumerateKeysAndObjectsUsingBlock:^(id otherKey, id otherObj, BOOL *stop) {
        if ([otherObj isKindOfClass:NSDictionary.class] &&
            [self[otherKey] isKindOfClass:NSDictionary.class]) {
            NSMutableDictionary *mergedDict = ((NSDictionary *)self[otherKey]).mutableCopy;
            [mergedDict mergeEntriesFromDictionary:(NSDictionary *)otherObj];
            self[otherKey] = mergedDict;
            return;
        }

        self[otherKey] = otherObj;
    }];
}

@end
