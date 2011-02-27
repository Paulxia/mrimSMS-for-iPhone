//
//  MRIMStoreObserver.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 06.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MRIMStoreObserver.h"


@implementation MRIMStoreObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	NSLog(@"updatedTransactions: %@", transactions);
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				[self completeTransaction:transaction];
				break;
			case SKPaymentTransactionStateFailed:
				[self failedTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				[self restoreTransaction:transaction];
			default:
				break;
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BFNStoreRestoreComplete" object:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queueRestoreCompletedTransactionsFailedWithError:(NSError *)error
{
	NSLog(@"queuerestoreCompletedTransactionsFailedWithError: %@", [error description]);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BFNStoreRestoreComplete" object:nil];
}


- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"failedTransaction: %@", transaction);
	if (transaction.error.code != SKErrorPaymentCancelled) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BFNStoreFailedPayment" 
															object:nil];
	}
	else if	(transaction.error.code == SKErrorPaymentCancelled) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BFNStoreCancelledPayment" 
															object:nil]; 
	}

	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"restoreTransaction: %@", transaction);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BFNStoreEnableBlack" object:nil];
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];	
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
	NSLog(@"completeTransaction: %@", transaction);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BFNStoreEnableBlack" object:nil];
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

@end
