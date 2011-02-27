//
//  BFConnectionController.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 14.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import "BFConnectionController.h"
#import "BFHistoryStorage.h"

NSString *const BFMRIMDelegateDidStartConnecting = @"BFMRIMDelegateDidStartConnecting";
NSString *const BFMRIMDelegateDidLogin = @"BFMRIMDelegateDidLogin";
NSString *const BFMRIMDelegateDidDisconnect = @"BFMRIMDelegateDidDisconnect";
NSString *const BFMRIMDelegateDidFailLogin = @"BFMRIMDelegateDidFailLogin";
NSString *const BFMRIMDelegateNoCredentials = @"BFMRIMDelegateNoCredentials";
NSString *const BFMRIMDelegateDidDopped = @"BFMRIMDelegateDidDopped";

NSString *const MRIMSendMessageNotification = @"MRIMSendMessageNotification";
NSString *const MRIMIncomeMessageNotification = @"MRIMIncomeMessageNotification";
NSString *const MRIMOfflineMessageNotification = @"MRIMOfflineMessageNotification";

@implementation BFConnectionController

@synthesize mrim;
@synthesize loggedIn;

static BFConnectionController *sharedController = nil;

+ (BFConnectionController *)sharedController {
    if (sharedController == nil) {
        sharedController = [[super allocWithZone:NULL] init];
    }
    return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedController] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

- (void)dealloc {
	[mrim release];
	
	[minutkaTimer invalidate];
	[minutkaTimer release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Connection 

- (void)connect {
	if (mrim == nil) {
		mrim = [[mrimProtocol alloc] init];
		[mrim setDelegate:self];
		loggedIn = NO;
	}
	
	[self performSelector:@selector(startConnecting) withObject:nil afterDelay:0.37];
}

- (void)disconnect {
	if ([self loggedIn]) {
		[mrim disconnect];
	}
}

- (void)startConnecting {
	[self performSelectorOnMainThread:@selector(loadAccountSettingsAndConnect) 
						   withObject:nil 
						waitUntilDone:NO];
}

- (void)loadAccountSettingsAndConnect {
	NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"email_preference"];
	NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:@"password_preference"];
	
	if (([username length] == 0) || ([password length] == 0)) {
		[[NSNotificationCenter defaultCenter] postNotificationName:BFMRIMDelegateNoCredentials object:nil];
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:BFMRIMDelegateDidStartConnecting object:nil];
	[mrim setUsername:username];
	[mrim setPassword:password];
	[mrim setOperation:BFMRIMOperationGettingServerAddress];
	[mrim setCurrentTag:1];
	[mrim connectToHost:@"mrim.mail.ru"];
}


- (void)sendMessage:(NSString *)messageText toNumber:(NSString *)phoneNumber {
	if ([messageText isEqualToString:@""]) {
		return;
	}
	if ([phoneNumber isEqualToString:@""]) {
		return;
	}
	
	[mrim sendSMSToNumber:phoneNumber withText:messageText];
	[[NSNotificationCenter defaultCenter] postNotificationName:MRIMSendMessageNotification 
														object:nil];
	
	minutkaTimeout = 61;
	if (minutkaTimer == nil) {
		minutkaTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0f
														 target:self 
													   selector:@selector(minutkaTimerFire:) 
													   userInfo:nil 
														repeats:YES] retain];
	}
}

#pragma mark Minutka

- (BOOL)canSendMessage {
	if ([self loggedIn] == NO)
		return NO;
	
	if (minutkaTimeout == 0) 
		return YES;
	return NO;
}

- (void)minutkaTimerFire:(NSTimer *)t {
	if (minutkaTimeout > 0) {
		minutkaTimeout--;
	}
}

#pragma mark -
#pragma mark mrim delegate

- (void)mrimObject:(mrimProtocol *)mrimObject didReceiveServerAddress:(NSString *)address {
	[mrim setOperation:BFMRIMOperationConnecting];
	NSString *hostAddress = [address substringToIndex:[address rangeOfString:@":"].location];
	NSLog(@"mrimObject:didReceiveServerAddress: %@", hostAddress);
	[mrim setMrimServerAddress:hostAddress];
	// и ждем отключения
}

- (void)mrimObject:(mrimProtocol *)mrimObject didConnectToHost:(NSString *)address {
	NSLog(@"mrimObject:didConnectToHost: %@", address);
	self.loggedIn = NO;
	if ([mrim operation] == BFMRIMOperationGettingServerAddress) {
		[mrim serverAddress];
	}
	
	if ([mrim operation] == BFMRIMOperationConnecting) {
		[mrim welcomeServer];
	}
}

- (void)mrimObjectDidWelcomeServer:(mrimProtocol *)mrimObject {
	NSLog(@"app.mrimObjectDidWelcomeServer");
	[mrim setOperation:BFMRIMOperationLoggingIn];
	[mrim loginToServer];
}

- (void)mrimObject:(mrimProtocol *)mrimObject willDisconnectWithError:(NSError *)error {
	self.loggedIn = NO;
}

- (void)mrimObjectDidDisconnect:(mrimProtocol *)mrimObject {
	NSLog(@"mrimObjectDidDisconnect:");
	self.loggedIn = NO;
	if ([mrim operation] == BFMRIMOperationConnecting) {
		NSLog(@"   connecting for login");
		[mrim connectToHost:[mrim mrimServerAddress]];
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:BFMRIMDelegateDidDisconnect object:nil];
	}
	
}

- (void)mrimObjectDidLogin:(mrimProtocol *)mrimObject {
	NSLog(@"mrimObjectDidLogin");
	[mrim setOperation:BFMRIMOperationIdle];
	self.loggedIn = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:BFMRIMDelegateDidLogin object:nil];
}

- (void)mrimObjectDidFailLogin:(mrimProtocol *)mrimObject {
	NSLog(@"mrimObjectDidFailLogin:");
	// TODO: 
	self.loggedIn = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:BFMRIMDelegateDidFailLogin object:nil];
}

- (void)mrimObject:(mrimProtocol *)mrimObject didReceiveMessage:(NSDictionary *)messageInfo {
	BOOL sms = [[messageInfo objectForKey:BFKeyMessageSMS] boolValue];
	
	if (!sms) {
		return;
	}
	
	BOOL notify = [[messageInfo objectForKey:BFKeyMessageNotify] boolValue];
	NSDate *date = [messageInfo objectForKey:BFKeyMessageDate];
	NSString *type = [messageInfo objectForKey:BFKeyMessageStatus];
	NSString *phoneNumber = [messageInfo objectForKey:BFKeyMessageSender];
	NSString *messageText = [messageInfo objectForKey:BFKeyMessageText];
	
	BOOL unread = NO;
	if (type == BFKeyMessageOffline) {
		unread = YES;
	}
	
	if (type == BFKeyMessageOnline) {
		NSDictionary *messageInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 phoneNumber, @"phoneNumber", 
									 messageText, @"message", 
									 [NSNumber numberWithBool:notify], @"notify", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:MRIMIncomeMessageNotification 
															object:messageInfo];
		
		if (!notify) {
			[[BFHistoryStorage sharedStorage] insertToHistoryNumber:phoneNumber 
															message:messageText 
															 atDate:[NSDate date] 
															 income:YES 
															 unread:NO];
		}
	}
	else {
		NSDictionary *messageInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 phoneNumber, @"phoneNumber", 
									 messageText, @"message", 
									 date, @"date", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:MRIMOfflineMessageNotification 
															object:messageInfo];
		
		if (!notify) {
			[[BFHistoryStorage sharedStorage] insertToHistoryNumber:phoneNumber 
															message:messageText 
															 atDate:[NSDate date] 
															 income:YES 
															 unread:YES];
		}
	}
}

- (void)mrimObjectDidReceiveLogoutPacket:(mrimProtocol *)mrimObject {
	[[NSNotificationCenter defaultCenter] postNotificationName:BFMRIMDelegateDidDopped object:nil];
	self.loggedIn = NO;
}


@end
