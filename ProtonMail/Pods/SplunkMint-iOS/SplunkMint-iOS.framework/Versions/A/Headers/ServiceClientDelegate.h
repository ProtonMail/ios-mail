//
//  ServiceClientDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/14/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintEnums.h"
#import "TypeBlocks.h"

@protocol ServiceClientDelegate <NSObject>

@required
    - (void) executeRequestAsyncWithUrl: (NSString*)url requestData: (NSString*)data requestType: (MintRequestType)requestType contentType: (NSString*)aContentType andCompletedBlock: (ResponseResultBlock)resultBlock;
@end
