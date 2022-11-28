#import "SentryUIApplication.h"

#if SENTRY_HAS_UIKIT

@implementation SentryUIApplication

- (UIApplication *)sharedApplication
{
    if (![UIApplication respondsToSelector:@selector(sharedApplication)])
        return nil;

    return [UIApplication performSelector:@selector(sharedApplication)];
}

- (NSArray<UIWindow *> *)windows
{
    UIApplication *app = [self sharedApplication];
    if (app == nil)
        return nil;

    NSMutableArray *result = [NSMutableArray new];

    if (@available(iOS 13.0, tvOS 13.0, *)) {
        if ([app respondsToSelector:@selector(connectedScenes)]) {
            for (UIScene *scene in app.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive
                    && scene.delegate && [scene.delegate respondsToSelector:@selector(window)]) {
                    [result addObject:[scene.delegate performSelector:@selector(window)]];
                }
            }
        }
    }

    if ([app.delegate respondsToSelector:@selector(window)]) {
        [result addObject:app.delegate.window];
    }

    return result;
}

@end

#endif
