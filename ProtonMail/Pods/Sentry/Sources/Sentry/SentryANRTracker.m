#import "SentryANRTracker.h"
#import "SentryCrashWrapper.h"
#import "SentryDispatchQueueWrapper.h"
#import "SentryLog.h"
#import "SentryThreadWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface
SentryANRTracker ()

@property (nonatomic, strong) id<SentryCurrentDateProvider> currentDate;
@property (nonatomic, strong) SentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) SentryDispatchQueueWrapper *dispatchQueueWrapper;
@property (nonatomic, strong) SentryThreadWrapper *threadWrapper;
@property (nonatomic, strong) NSMutableSet<id<SentryANRTrackerDelegate>> *listeners;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

@property (weak, nonatomic) NSThread *thread;

@end

@implementation SentryANRTracker {
    NSObject *threadLock;
    BOOL running;
}

- (instancetype)initWithTimeoutInterval:(NSTimeInterval)timeoutInterval
                    currentDateProvider:(id<SentryCurrentDateProvider>)currentDateProvider
                           crashWrapper:(SentryCrashWrapper *)crashWrapper
                   dispatchQueueWrapper:(SentryDispatchQueueWrapper *)dispatchQueueWrapper
                          threadWrapper:(SentryThreadWrapper *)threadWrapper
{
    if (self = [super init]) {
        self.timeoutInterval = timeoutInterval;
        self.currentDate = currentDateProvider;
        self.crashWrapper = crashWrapper;
        self.dispatchQueueWrapper = dispatchQueueWrapper;
        self.threadWrapper = threadWrapper;
        self.listeners = [NSMutableSet new];
        threadLock = [[NSObject alloc] init];
        running = NO;
    }
    return self;
}

- (void)detectANRs
{
    NSThread.currentThread.name = @"io.sentry.app-hang-tracker";
    self.thread = NSThread.currentThread;

    __block NSInteger ticksSinceUiUpdate = 0;
    __block BOOL reported = NO;

    NSInteger reportThreshold = 5;
    NSTimeInterval sleepInterval = self.timeoutInterval / reportThreshold;

    while (![self.thread isCancelled]) {
        NSDate *blockDeadline =
            [[self.currentDate date] dateByAddingTimeInterval:self.timeoutInterval];

        ticksSinceUiUpdate++;

        [self.dispatchQueueWrapper dispatchAsyncOnMainQueue:^{
            ticksSinceUiUpdate = 0;

            if (reported) {
                SENTRY_LOG_WARN(@"ANR stopped.");
                [self ANRStopped];
            }

            reported = NO;
        }];

        [self.threadWrapper sleepForTimeInterval:sleepInterval];

        // The blockDeadline should be roughly executed after the timeoutInterval even if there is
        // an ANR. If the app gets suspended this thread could sleep and wake up again. To avoid
        // false positives, we don't report ANRs if the delta is too big.
        NSTimeInterval deltaFromNowToBlockDeadline =
            [[self.currentDate date] timeIntervalSinceDate:blockDeadline];

        if (deltaFromNowToBlockDeadline >= self.timeoutInterval) {
            SENTRY_LOG_DEBUG(
                @"Ignoring ANR because the delta is too big: %f.", deltaFromNowToBlockDeadline);
            continue;
        }

        if (ticksSinceUiUpdate >= reportThreshold && !reported) {
            reported = YES;

            if (![self.crashWrapper isApplicationInForeground]) {
                SENTRY_LOG_DEBUG(@"Ignoring ANR because the app is in the background");
                continue;
            }

            SENTRY_LOG_WARN(@"ANR detected.");
            [self ANRDetected];
        }
    }
}

- (void)ANRDetected
{
    NSArray *localListeners;
    @synchronized(self.listeners) {
        localListeners = [self.listeners allObjects];
    }

    for (id<SentryANRTrackerDelegate> target in localListeners) {
        [target anrDetected];
    }
}

- (void)ANRStopped
{
    NSArray *targets;
    @synchronized(self.listeners) {
        targets = [self.listeners allObjects];
    }

    for (id<SentryANRTrackerDelegate> target in targets) {
        [target anrStopped];
    }
}

- (void)addListener:(id<SentryANRTrackerDelegate>)listener
{
    @synchronized(self.listeners) {
        [self.listeners addObject:listener];

        if (self.listeners.count > 0 && !running) {
            @synchronized(threadLock) {
                if (!running) {
                    [self start];
                }
            }
        }
    }
}

- (void)removeListener:(id<SentryANRTrackerDelegate>)listener
{
    @synchronized(self.listeners) {
        [self.listeners removeObject:listener];

        if (self.listeners.count == 0) {
            [self stop];
        }
    }
}

- (void)clear
{
    @synchronized(self.listeners) {
        [self.listeners removeAllObjects];
        [self stop];
    }
}

- (void)start
{
    @synchronized(threadLock) {
        [NSThread detachNewThreadSelector:@selector(detectANRs) toTarget:self withObject:nil];
        running = YES;
    }
}

- (void)stop
{
    @synchronized(threadLock) {
        SENTRY_LOG_INFO(@"Stopping ANR detection");
        [self.thread cancel];
        running = NO;
    }
}

@end

NS_ASSUME_NONNULL_END
