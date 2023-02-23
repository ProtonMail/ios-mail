#import "SentryThreadWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SentryThreadWrapper

- (void)sleepForTimeInterval:(NSTimeInterval)timeInterval
{
    [NSThread sleepForTimeInterval:timeInterval];
}

@end

NS_ASSUME_NONNULL_END
