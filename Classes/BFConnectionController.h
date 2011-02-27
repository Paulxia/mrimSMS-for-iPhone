//
//  BFConnectionController.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 14.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "mrimProtocol.h"

extern NSString *const BFMRIMDelegateDidStartConnecting;
extern NSString *const BFMRIMDelegateDidLogin;
extern NSString *const BFMRIMDelegateDidDisconnect;
extern NSString *const BFMRIMDelegateDidFailLogin;
extern NSString *const BFMRIMDelegateNoCredentials;
extern NSString *const BFMRIMDelegateDidDopped;

extern NSString *const MRIMSendMessageNotification;
extern NSString *const MRIMIncomeMessageNotification;
extern NSString *const MRIMOfflineMessageNotification;

@interface BFConnectionController : NSObject {
	mrimProtocol *mrim;
	BOOL loggedIn;
	
	NSTimer *minutkaTimer;
	NSInteger minutkaTimeout;
}
@property (nonatomic, retain, readwrite) mrimProtocol *mrim;
@property BOOL loggedIn;

+ (BFConnectionController *)sharedController;

- (void)connect;
- (void)disconnect;

- (BOOL)canSendMessage;

- (void)sendMessage:(NSString *)messageText toNumber:(NSString *)phoneNumber;

@end