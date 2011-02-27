//
//  MRIMStoreObserver.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 06.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class mrimSMSmAppDelegate;

@interface MRIMStoreObserver : NSObject <SKPaymentTransactionObserver>  {
	
}

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;
- (void) failedTransaction:(SKPaymentTransaction *)transaction;
- (void) restoreTransaction:(SKPaymentTransaction *)transaction;
- (void) completeTransaction:(SKPaymentTransaction *)transaction;

@end
