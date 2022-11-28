#import "SentryTransactionContext.h"
#include "SentryProfilingConditionals.h"
#import "SentryThread.h"
#include "SentryThreadHandle.hpp"
#import "SentryTransactionContext+Private.h"

NS_ASSUME_NONNULL_BEGIN

static const auto kSentryDefaultSamplingDecision = kSentrySampleDecisionUndecided;

@interface
SentryTransactionContext ()

#if SENTRY_TARGET_PROFILING_SUPPORTED
@property (nonatomic, strong) SentryThread *threadInfo;
#endif

@end

@implementation SentryTransactionContext

- (instancetype)initWithName:(NSString *)name operation:(NSString *)operation
{
    return [self initWithName:name
                   nameSource:kSentryTransactionNameSourceCustom
                    operation:operation];
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(SentryTransactionNameSource)source
                   operation:(NSString *)operation
{
    if (self = [super initWithOperation:operation]) {
        _name = [NSString stringWithString:name];
        _nameSource = source;
        self.parentSampled = kSentryDefaultSamplingDecision;
        [self getThreadInfo];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                   operation:(NSString *)operation
                     sampled:(SentrySampleDecision)sampled
{
    return [self initWithName:name
                   nameSource:kSentryTransactionNameSourceCustom
                    operation:operation
                      sampled:sampled];
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(SentryTransactionNameSource)source
                   operation:(NSString *)operation
                     sampled:(SentrySampleDecision)sampled
{
    if (self = [super initWithOperation:operation sampled:sampled]) {
        _name = [NSString stringWithString:name];
        _nameSource = source;
        self.parentSampled = kSentryDefaultSamplingDecision;
        [self getThreadInfo];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                   operation:(nonnull NSString *)operation
                     traceId:(SentryId *)traceId
                      spanId:(SentrySpanId *)spanId
                parentSpanId:(nullable SentrySpanId *)parentSpanId
               parentSampled:(SentrySampleDecision)parentSampled
{
    return [self initWithName:name
                   nameSource:kSentryTransactionNameSourceCustom
                    operation:operation
                      traceId:traceId
                       spanId:spanId
                 parentSpanId:parentSpanId
                parentSampled:parentSampled];
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(SentryTransactionNameSource)source
                   operation:(nonnull NSString *)operation
                     traceId:(SentryId *)traceId
                      spanId:(SentrySpanId *)spanId
                parentSpanId:(nullable SentrySpanId *)parentSpanId
               parentSampled:(SentrySampleDecision)parentSampled
{
    if (self = [super initWithTraceId:traceId
                               spanId:spanId
                             parentId:parentSpanId
                            operation:operation
                              sampled:kSentryDefaultSamplingDecision]) {
        _name = [NSString stringWithString:name];
        _nameSource = source;
        self.parentSampled = parentSampled;
        [self getThreadInfo];
    }
    return self;
}

- (void)getThreadInfo
{
#if SENTRY_TARGET_PROFILING_SUPPORTED
    const auto threadID = sentry::profiling::ThreadHandle::current()->tid();
    self.threadInfo = [[SentryThread alloc] initWithThreadId:@(threadID)];
#endif
}

#if SENTRY_TARGET_PROFILING_SUPPORTED
- (SentryThread *)sentry_threadInfo
{
    return self.threadInfo;
}
#endif

@end

NS_ASSUME_NONNULL_END
