#import "SentryBreadcrumb.h"
#import "SentryDefines.h"
#import "SentrySerializable.h"

@interface
SentryBreadcrumb (Private)

/**
 * Initializes a SentryBreadcrumb from a JSON object.
 * @param dictionary The dictionary containing breadcrumb data.
 * @return The SentryBreadcrumb.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@end
