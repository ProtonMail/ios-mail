#import "SentrySwizzleWrapper.h"
#import <SentryHub+Private.h>
#import <SentryLog.h>
#import <SentrySDK+Private.h>
#import <SentrySDK.h>
#import <SentryScope.h>
#import <SentrySpanOperations.h>
#import <SentrySpanProtocol.h>
#import <SentryTracer.h>
#import <SentryTransactionContext+Private.h>
#import <SentryUIEventTracker.h>

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const SentryUIEventTrackerSwizzleSendAction
    = @"SentryUIEventTrackerSwizzleSendAction";

@interface
SentryUIEventTracker ()

@property (nonatomic, strong) SentrySwizzleWrapper *swizzleWrapper;
@property (nonatomic, strong) SentryDispatchQueueWrapper *dispatchQueueWrapper;
@property (nonatomic, assign) NSTimeInterval idleTimeout;
@property (nullable, nonatomic, strong) NSMutableArray<SentryTracer *> *activeTransactions;

@end

#endif

@implementation SentryUIEventTracker

#if SENTRY_HAS_UIKIT

- (instancetype)initWithSwizzleWrapper:(SentrySwizzleWrapper *)swizzleWrapper
                  dispatchQueueWrapper:(SentryDispatchQueueWrapper *)dispatchQueueWrapper
                           idleTimeout:(NSTimeInterval)idleTimeout
{
    if (self = [super init]) {
        self.swizzleWrapper = swizzleWrapper;
        self.dispatchQueueWrapper = dispatchQueueWrapper;
        self.idleTimeout = idleTimeout;
        self.activeTransactions = [NSMutableArray new];
    }
    return self;
}

- (void)start
{
    [self.swizzleWrapper
        swizzleSendAction:^(NSString *action, id target, id sender, UIEvent *event) {
            if (target == nil || sender == nil) {
                return;
            }

            // When using an application delegate with SwiftUI we receive touch events here, but
            // the target class name looks something like
            // _TtC7SwiftUIP33_64A26C7A8406856A733B1A7B593971F711Coordinator.primaryActionTriggered,
            // which is unacceptable for a transaction name. Ideally, we should somehow shorten
            // the long name.

            NSString *targetClass = NSStringFromClass([target class]);
            if ([targetClass containsString:@"SwiftUI"]) {
                return;
            }

            NSString *transactionName = [self getTransactionName:action target:targetClass];

            // There might be more active transactions stored, but only the last one might still be
            // active with a timeout. The others are already waiting for their children to finish
            // without a timeout.
            SentryTracer *currentActiveTransaction;
            @synchronized(self.activeTransactions) {
                currentActiveTransaction = self.activeTransactions.lastObject;
            }

            BOOL sameAction =
                [currentActiveTransaction.transactionContext.name isEqualToString:transactionName];
            if (sameAction) {
                [currentActiveTransaction dispatchIdleTimeout];
                return;
            }

            [currentActiveTransaction finish];

            if (currentActiveTransaction) {
                [SentryLog
                    logWithMessage:
                        [NSString stringWithFormat:@"SentryUIEventTracker finished transaction %@",
                                  currentActiveTransaction.transactionContext.name]
                          andLevel:kSentryLevelDebug];
            }

            NSString *operation = [self getOperation:sender];

            SentryTransactionContext *context =
                [[SentryTransactionContext alloc] initWithName:transactionName
                                                    nameSource:kSentryTransactionNameSourceComponent
                                                     operation:operation];

            __block SentryTracer *transaction;
            [SentrySDK.currentHub.scope useSpan:^(id<SentrySpan> _Nullable span) {
                BOOL ongoingScreenLoadTransaction = span != nil &&
                    [span.context.operation isEqualToString:SentrySpanOperationUILoad];
                BOOL ongoingManualTransaction = span != nil
                    && ![span.context.operation isEqualToString:SentrySpanOperationUILoad]
                    && ![span.context.operation containsString:SentrySpanOperationUIAction];

                BOOL bindToScope = !ongoingScreenLoadTransaction && !ongoingManualTransaction;
                transaction =
                    [SentrySDK.currentHub startTransactionWithContext:context
                                                          bindToScope:bindToScope
                                                customSamplingContext:@{}
                                                          idleTimeout:self.idleTimeout
                                                 dispatchQueueWrapper:self.dispatchQueueWrapper];

                [SentryLog
                    logWithMessage:[NSString stringWithFormat:@"SentryUIEventTracker automatically "
                                                              @"started a new transaction with "
                                                              @"name: %@, bindToScope: %@",
                                             transactionName, bindToScope ? @"YES" : @"NO"]
                          andLevel:kSentryLevelDebug];
            }];

            if ([[sender class] isSubclassOfClass:[UIView class]]) {
                UIView *view = sender;
                if (view.accessibilityIdentifier) {
                    [transaction setTagValue:view.accessibilityIdentifier
                                      forKey:@"accessibilityIdentifier"];
                }
            }

            transaction.finishCallback = ^(SentryTracer *tracer) {
                @synchronized(self.activeTransactions) {
                    [self.activeTransactions removeObject:tracer];
                }
            };
            @synchronized(self.activeTransactions) {
                [self.activeTransactions addObject:transaction];
            }
        }
                   forKey:SentryUIEventTrackerSwizzleSendAction];
}

- (void)stop
{
    [self.swizzleWrapper removeSwizzleSendActionForKey:SentryUIEventTrackerSwizzleSendAction];
}

- (NSString *)getOperation:(id)sender
{
    Class senderClass = [sender class];
    if ([senderClass isSubclassOfClass:[UIButton class]] ||
        [senderClass isSubclassOfClass:[UIBarButtonItem class]] ||
        [senderClass isSubclassOfClass:[UISegmentedControl class]] ||
        [senderClass isSubclassOfClass:[UIPageControl class]]) {
        return SentrySpanOperationUIActionClick;
    }

    return SentrySpanOperationUIAction;
}

/**
 * The action is an Objective-C selector and might look weird for Swift developers. Therefore we
 * convert the selector to a Swift appropriate format aligned with the Swift #selector syntax.
 * method:first:second:third: gets converted to method(first:second:third:)
 */
- (NSString *)getTransactionName:(NSString *)action target:(NSString *)target
{
    NSArray<NSString *> *componens = [action componentsSeparatedByString:@":"];
    if (componens.count > 2) {
        NSMutableString *result =
            [[NSMutableString alloc] initWithFormat:@"%@.%@(", target, componens.firstObject];

        for (int i = 1; i < (componens.count - 1); i++) {
            [result appendFormat:@"%@:", componens[i]];
        }

        [result appendFormat:@")"];

        return result;
    }

    return [NSString stringWithFormat:@"%@.%@", target, componens.firstObject];
}

NS_ASSUME_NONNULL_END

#endif

NS_ASSUME_NONNULL_BEGIN

+ (BOOL)isUIEventOperation:(NSString *)operation
{
    if ([operation isEqualToString:SentrySpanOperationUIAction]) {
        return YES;
    }
    if ([operation isEqualToString:SentrySpanOperationUIActionClick]) {
        return YES;
    }
    return NO;
}

@end

NS_ASSUME_NONNULL_END
