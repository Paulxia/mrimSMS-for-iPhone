//
//  mrimProtocol.h
//  mrimProtocol
//
//  Created by Алексеев Влад on 02.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMP.h"
#import "AsyncSocket.h"

extern NSString *const BFMRIMOperationIdle;
extern NSString *const BFMRIMOperationGettingServerAddress;
extern NSString *const BFMRIMOperationLoggingIn;
extern NSString *const BFMRIMOperationConnecting;

extern NSString *const BFKeyMessageText;
extern NSString *const BFKeyMessageSender;
extern NSString *const BFKeyMessageDate;
extern NSString *const BFKeyMessageNotify;
extern NSString *const BFKeyMessageSMS;
extern NSString *const BFKeyMessageStatus;
extern NSString *const BFKeyMessageOnline;
extern NSString *const BFKeyMessageOffline;

extern NSString *const BFKeyMessageResultSuccess;
extern NSString *const BFKeyMessageResultFailed;
extern NSString *const BFKeyMessageResultInProcess;


@interface mrimProtocol : NSObject {
	NSMutableDictionary *operations;
	NSMutableDictionary *packetStatuses;
	AsyncSocket* socket;
	int mrimOperation;
	long currentTag;
	
	NSTimer *pingTimer;
	
	long pingPeriod;
	
	id delegate;
	
	NSString *operation;
	NSString *mrimServerAddress;
	NSString *username;
	NSString *password;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSString *operation;
@property long currentTag;

@property (nonatomic, copy) NSString *mrimServerAddress;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

//-(NSString *)getServerAddress;
//-(void)connectToAddress:(NSString *)address;
//-(void)loginWithUsername:(NSString *)un password:(NSString *)pass;
//-(u_long)addPhoneContact:(NSString *)number;
//-(bool)removePhoneContact:(u_long)contactID number:(NSString *)number;
//-(bool)sendSMS:(NSString *)number text:(NSString *)message;

- (void)connectToHost:(NSString *)address;
- (void)disconnect;
- (void)serverAddress;
- (void)welcomeServer;
- (void)loginToServer;
- (void)sendSMSToNumber:(NSString *)number withText:(NSString *)message;

-(mrim_header) getPacketHeaderFromData:(NSData *)data;
- (NSData *)generatePacketWithMessage:(u_long)message sequence:(u_long)seq additionalData:(NSData *)data;

- (void)processOnlineMessage:(NSData *)data;
- (void)processOfflineMessage:(NSData *)data;
- (void)processSMSDeliveryPacket:(NSData *)data;

- (void)processData:(NSData *)data;
- (void)processPacketWithData:(NSData *)data;
- (void)processData:(NSData *)data;

@end

@protocol BFMRIMDelegateProtocol

- (void)mrimObject:(mrimProtocol *)mrimObject didReceiveServerAddress:(NSString *)address;
- (void)mrimObject:(mrimProtocol *)mrimObject didConnectToHost:(NSString *)address;
- (void)mrimObject:(mrimProtocol *)mrimObject willDisconnectWithError:(NSError *)error;
- (void)mrimObjectDidDisconnect:(mrimProtocol *)mrimObject;
- (void)mrimObjectDidWelcomeServer:(mrimProtocol *)mrimObject;


- (void)mrimObjectDidLogin:(mrimProtocol *)mrimObject;
- (void)mrimObjectDidFailLogin:(mrimProtocol *)mrimObject;
- (void)mrimObject:(mrimProtocol *)mrimObject didReceiveMessage:(NSDictionary *)messageInfo;
- (void)mrimObjectDidReceiveLogoutPacket:(mrimProtocol *)mrimObject;

@end

