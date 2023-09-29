#import "SentryCompiler.h"
#import "SentryProfilingConditionals.h"
#import "SentrySpan.h"
#import <Foundation/Foundation.h>

@class SentryEnvelopeItem;
#if SENTRY_HAS_UIKIT
@class SentryFramesTracker;
#endif // SENTRY_HAS_UIKIT
@class SentryTransaction;

#if SENTRY_TARGET_PROFILING_SUPPORTED

typedef NS_ENUM(NSUInteger, SentryProfilerTruncationReason) {
    SentryProfilerTruncationReasonNormal,
    SentryProfilerTruncationReasonTimeout,
    SentryProfilerTruncationReasonAppMovedToBackground,
};

NS_ASSUME_NONNULL_BEGIN

SENTRY_EXTERN const int kSentryProfilerFrequencyHz;

SENTRY_EXTERN NSString *const kSentryProfilerSerializationKeySlowFrameRenders;
SENTRY_EXTERN NSString *const kSentryProfilerSerializationKeyFrozenFrameRenders;
SENTRY_EXTERN NSString *const kSentryProfilerSerializationKeyFrameRates;

SENTRY_EXTERN_C_BEGIN

NSString *profilerTruncationReasonName(SentryProfilerTruncationReason reason);

SENTRY_EXTERN_C_END

/**
 * A wrapper around the low-level components used to gather sampled backtrace profiles.
 * @warning A main assumption is that profile start/stop must be contained within range of time of
 * the first concurrent transaction's start time and last one's end time.
 */
@interface SentryProfiler : NSObject

@property (strong, nonatomic) SentryId *profileId;

/**
 * Start a profiler, if one isn't already running.
 */
+ (void)startWithTracer:(SentryTracer *)tracer;

/**
 * Stop the profiler if it is running.
 */
- (void)stopForReason:(SentryProfilerTruncationReason)reason;

/**
 * Whether the profiler instance is currently running. If not, then it probably timed out or aborted
 * due to app backgrounding and is being kept alive while its associated transactions finish so they
 * can query for its profile data. */
- (BOOL)isRunning;

/**
 * Whether there is any profiler that is currently running. A convenience method to query for this
 * information from other SDK components that don't have access to specific @c SentryProfiler
 * instances.
 */
+ (BOOL)isCurrentlyProfiling;

/**
 * Given a transaction, return an envelope item containing any corresponding profile data to be
 * attached to the transaction envelope.
 * */
+ (nullable SentryEnvelopeItem *)createProfilingEnvelopeItemForTransaction:
    (SentryTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END

#endif // SENTRY_TARGET_PROFILING_SUPPORTED
