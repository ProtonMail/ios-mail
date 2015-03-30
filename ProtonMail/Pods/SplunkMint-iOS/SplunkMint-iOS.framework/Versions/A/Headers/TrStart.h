//
//  TrStart.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/23/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLTransaction.h"
#import "MintAppEnvironment.h"
#import "MintPerformance.h"
#import "LimitedExtraDataList.h"

@interface TrStart : SPLTransaction

//@property (nonatomic, strong) NSNumber<Ignore>* slaInMilliseconds;

//- (BOOL) isTransactionSlow: (NSNumber*)duration;

/**
 *  Creates a new TrStart instance.
 *
 *  @param transactionName  The name of the transaction.
 *  @param anAppEnvironment A MintAppEnvironment instance.
 *  @param aPerformance     A MintPerformance instance.
 *
 *  @return A reference to the TrStart instance.
 */
+ (TrStart*) getInstanceWithTransactionName:(NSString*)transactionName appEnvironment:(MintAppEnvironment*)anAppEnvironment andPerformance:(MintPerformance*)aPerformance;

+ (TrStart*) getInstanceWithTransactionName:(NSString*)transactionName limitedExtraDataList:(LimitedExtraDataList*)extraDataList appEnvironment:(MintAppEnvironment*)anAppEnvironment andPerformance:(MintPerformance*)aPerformance;

+ (BOOL) isJSONTrStart:(NSString*)json;

@end
