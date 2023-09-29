#import "SentryDefines.h"

#if SENTRY_HAS_UIKIT

NS_ASSUME_NONNULL_BEGIN

@class SentrySwizzleWrapper, SentryDispatchQueueWrapper;

@interface SentryUIEventTracker : NSObject
SENTRY_NO_INIT

- (instancetype)initWithSwizzleWrapper:(SentrySwizzleWrapper *)swizzleWrapper
                  dispatchQueueWrapper:(SentryDispatchQueueWrapper *)dispatchQueueWrapper
                           idleTimeout:(NSTimeInterval)idleTimeout;

- (void)start;
- (void)stop;

+ (BOOL)isUIEventOperation:(NSString *)operation;

@end

NS_ASSUME_NONNULL_END

#endif // SENTRY_HAS_UIKIT
