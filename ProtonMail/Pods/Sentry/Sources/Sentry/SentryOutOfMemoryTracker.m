#import "NSDate+SentryExtras.h"
#import "SentryEvent+Private.h"
#import "SentryFileManager.h"
#import <Foundation/Foundation.h>
#import <SentryAppState.h>
#import <SentryAppStateManager.h>
#import <SentryClient+Private.h>
#import <SentryDispatchQueueWrapper.h>
#import <SentryException.h>
#import <SentryHub.h>
#import <SentryLog.h>
#import <SentryMechanism.h>
#import <SentryMessage.h>
#import <SentryOptions.h>
#import <SentryOutOfMemoryLogic.h>
#import <SentryOutOfMemoryTracker.h>
#import <SentrySDK+Private.h>

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>
#endif

@interface
SentryOutOfMemoryTracker ()

@property (nonatomic, strong) SentryOptions *options;
@property (nonatomic, strong) SentryOutOfMemoryLogic *outOfMemoryLogic;
@property (nonatomic, strong) SentryDispatchQueueWrapper *dispatchQueue;
@property (nonatomic, strong) SentryAppStateManager *appStateManager;
@property (nonatomic, strong) SentryFileManager *fileManager;

@end

@implementation SentryOutOfMemoryTracker

- (instancetype)initWithOptions:(SentryOptions *)options
               outOfMemoryLogic:(SentryOutOfMemoryLogic *)outOfMemoryLogic
                appStateManager:(SentryAppStateManager *)appStateManager
           dispatchQueueWrapper:(SentryDispatchQueueWrapper *)dispatchQueueWrapper
                    fileManager:(SentryFileManager *)fileManager
{
    if (self = [super init]) {
        self.options = options;
        self.outOfMemoryLogic = outOfMemoryLogic;
        self.appStateManager = appStateManager;
        self.dispatchQueue = dispatchQueueWrapper;
        self.fileManager = fileManager;
    }
    return self;
}

- (void)start
{
#if SENTRY_HAS_UIKIT
    [self.appStateManager start];

    [self.dispatchQueue dispatchAsyncWithBlock:^{
        if ([self.outOfMemoryLogic isOOM]) {
            SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentryLevelFatal];
            // Set to empty list so no breadcrumbs of the current scope are added
            event.breadcrumbs = @[];

            // Load the previous breascrumbs from disk, which are already serialized
            event.serializedBreadcrumbs = [self.fileManager readPreviousBreadcrumbs];
            if (event.serializedBreadcrumbs.count > self.options.maxBreadcrumbs) {
                event.serializedBreadcrumbs = [event.serializedBreadcrumbs
                    subarrayWithRange:NSMakeRange(event.serializedBreadcrumbs.count
                                              - self.options.maxBreadcrumbs,
                                          self.options.maxBreadcrumbs)];
            }

            NSDictionary *lastBreadcrumb = event.serializedBreadcrumbs.lastObject;
            if (lastBreadcrumb && [lastBreadcrumb objectForKey:@"timestamp"]) {
                NSString *timestampIso8601String = [lastBreadcrumb objectForKey:@"timestamp"];
                event.timestamp = [NSDate sentry_fromIso8601String:timestampIso8601String];
            }

            SentryException *exception =
                [[SentryException alloc] initWithValue:SentryOutOfMemoryExceptionValue
                                                  type:SentryOutOfMemoryExceptionType];
            SentryMechanism *mechanism =
                [[SentryMechanism alloc] initWithType:SentryOutOfMemoryMechanismType];
            mechanism.handled = @(NO);
            exception.mechanism = mechanism;
            event.exceptions = @[ exception ];

            // We don't need to upate the releaseName of the event to the previous app state as we
            // assume it's not an OOM when the releaseName changed between app starts.
            [SentrySDK captureCrashEvent:event];
        }
    }];
#else
    SENTRY_LOG_INFO(@"NO UIKit -> SentryOutOfMemoryTracker will not track OOM.");
    return;
#endif
}

- (void)stop
{
#if SENTRY_HAS_UIKIT
    [self.appStateManager stop];
#endif
}

@end
