#import "SentryDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class SentrySwizzleWrapper;

@protocol SentryBreadcrumbDelegate;

@interface SentryBreadcrumbTracker : NSObject
SENTRY_NO_INIT

- (instancetype)initWithSwizzleWrapper:(SentrySwizzleWrapper *)swizzleWrapper;

- (void)startWithDelegate:(id<SentryBreadcrumbDelegate>)delegate;
- (void)startSwizzle;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
