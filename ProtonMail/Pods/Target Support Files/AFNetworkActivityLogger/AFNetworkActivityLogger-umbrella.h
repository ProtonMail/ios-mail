#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AFNetworkActivityConsoleLogger.h"
#import "AFNetworkActivityLogger.h"
#import "AFNetworkActivityLoggerProtocol.h"

FOUNDATION_EXPORT double AFNetworkActivityLoggerVersionNumber;
FOUNDATION_EXPORT const unsigned char AFNetworkActivityLoggerVersionString[];

