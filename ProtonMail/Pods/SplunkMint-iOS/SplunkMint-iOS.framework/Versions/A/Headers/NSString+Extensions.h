//
//  NSString+Extensions.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/5/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)

- (BOOL)containsString:(NSString *)string;
- (BOOL)containsString:(NSString *)string options:(NSStringCompareOptions)options;
- (NSNumber*) toNSNumber;
- (NSString*) appendCacheDirectory;
- (NSString*) appendCacheExceptionsDirectory;
- (NSString*) appendLibraryGeneralDirectory;
- (NSString*) appendLibraryDirectory;
- (NSInteger) indexOf: (NSString*)text;
- (NSString*) uriEncoded;
- (NSString*) uriDecoded;

@end
