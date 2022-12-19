#import "SentryDefines.h"
#import "SentryFileManager.h"
#import "SentryRandom.h"

@class SentryAppStateManager, SentryCrashWrapper, SentryThreadWrapper, SentrySwizzleWrapper,
    SentryDispatchQueueWrapper, SentryDebugImageProvider, SentryANRTracker,
    SentryNSNotificationCenterWrapper;

#if SENTRY_HAS_UIKIT
@class SentryScreenshot, SentryUIApplication, SentryViewHierarchy;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SentryDependencyContainer : NSObject
SENTRY_NO_INIT

+ (instancetype)sharedInstance;

/**
 * Set all dependencies to nil for testing purposes.
 */
+ (void)reset;

@property (nonatomic, strong) SentryFileManager *fileManager;
@property (nonatomic, strong) SentryAppStateManager *appStateManager;
@property (nonatomic, strong) SentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) SentryThreadWrapper *threadWrapper;
@property (nonatomic, strong) id<SentryRandom> random;
@property (nonatomic, strong) SentrySwizzleWrapper *swizzleWrapper;
@property (nonatomic, strong) SentryDispatchQueueWrapper *dispatchQueueWrapper;
@property (nonatomic, strong) SentryNSNotificationCenterWrapper *notificationCenterWrapper;
@property (nonatomic, strong) SentryDebugImageProvider *debugImageProvider;
@property (nonatomic, strong) SentryANRTracker *anrTracker;

#if SENTRY_HAS_UIKIT
@property (nonatomic, strong) SentryScreenshot *screenshot;
@property (nonatomic, strong) SentryViewHierarchy *viewHierarchy;
@property (nonatomic, strong) SentryUIApplication *application;
#endif

- (SentryANRTracker *)getANRTracker:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
