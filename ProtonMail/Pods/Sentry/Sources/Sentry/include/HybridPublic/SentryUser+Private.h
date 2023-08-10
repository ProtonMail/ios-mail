#import "SentryDefines.h"
#import "SentrySerializable.h"
#import "SentryUser.h"

@interface
SentryUser (Private)

/**
 * Initializes a SentryUser from a dictionary.
 * @param dictionary The dictionary containing user data.
 * @return The SentryUser.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
