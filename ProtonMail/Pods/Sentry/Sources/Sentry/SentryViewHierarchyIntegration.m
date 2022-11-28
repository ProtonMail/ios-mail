#import "SentryViewHierarchyIntegration.h"
#import "SentryAttachment.h"
#import "SentryCrashC.h"
#import "SentryDependencyContainer.h"
#import "SentryEvent+Private.h"
#import "SentryHub+Private.h"
#import "SentrySDK+Private.h"
#import "SentryViewHierarchy.h"

#if SENTRY_HAS_UIKIT

void
saveViewHierarchy(const char *path)
{
    NSString *reportPath = [NSString stringWithUTF8String:path];
    [SentryDependencyContainer.sharedInstance.viewHierarchy saveViewHierarchy:reportPath];
}

@implementation SentryViewHierarchyIntegration

- (BOOL)installWithOptions:(nonnull SentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    SentryClient *client = [SentrySDK.currentHub getClient];
    [client addAttachmentProcessor:self];

    sentrycrash_setSaveViewHierarchy(&saveViewHierarchy);

    return YES;
}

- (SentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionAttachViewHierarchy;
}

- (void)uninstall
{
    sentrycrash_setSaveViewHierarchy(NULL);

    SentryClient *client = [SentrySDK.currentHub getClient];
    [client removeAttachmentProcessor:self];
}

- (NSArray<SentryAttachment *> *)processAttachments:(NSArray<SentryAttachment *> *)attachments
                                           forEvent:(nonnull SentryEvent *)event
{
    // We don't attach the view hierarchy if there is no exception/error.
    // We dont attach the view hierarchy if the event is a crash event.
    if ((event.exceptions == nil && event.error == nil) || event.isCrashEvent) {
        return attachments;
    }

    NSArray *decriptions =
        [SentryDependencyContainer.sharedInstance.viewHierarchy fetchViewHierarchy];
    NSMutableArray *result =
        [NSMutableArray arrayWithCapacity:attachments.count + decriptions.count];
    [result addObjectsFromArray:attachments];

    [decriptions enumerateObjectsUsingBlock:^(NSString *decription, NSUInteger idx, BOOL *stop) {
        SentryAttachment *attachment = [[SentryAttachment alloc]
            initWithData:[decription dataUsingEncoding:NSUTF8StringEncoding]
                filename:[NSString stringWithFormat:@"view-hierarchy-%lu.txt", (unsigned long)idx]
             contentType:@"text/plain"];
        [result addObject:attachment];
    }];

    return result;
}

@end
#endif
