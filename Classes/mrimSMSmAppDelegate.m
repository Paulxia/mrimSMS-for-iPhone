//
//  mrimSMSmobileAppDelegate.m
//  mrimSMSmobile
//
//  Created by Алексеев Влад on 20.10.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "mrimSMSmAppDelegate.h"

#import "BFHistoryStorage.h"

#import "BFContentViewController.h"

#import "NSData-HexAdditions.h"

@implementation mrimSMSmAppDelegate

@synthesize window;
@synthesize contentViewController;

@synthesize numberOfUnreadMessages, numberOfMessages;
@synthesize storeParameters;
@synthesize showContactPictures;

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {  
	[[[self contentViewController] view] setFrame:[[UIScreen mainScreen] applicationFrame]];
	[window addSubview:[contentViewController view]];
    [window makeKeyAndVisible];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	NSInteger unreadCount = [[BFHistoryStorage sharedStorage] numberOfUnreadMessages];
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadCount];
	
	[[BFHistoryStorage sharedStorage] saveChanges];
}

- (BFContentViewController *)contentViewController {
	if (contentViewController == nil) {
		contentViewController = [[BFContentViewController alloc] initWithNibName:@"BFContentViewController" bundle:nil];
	}
	return contentViewController;
}

#pragma mark Autostart connecting

- (void)applicationWillTerminate:(UIApplication *)application {
	NSInteger unreadCount = [[BFHistoryStorage sharedStorage] numberOfUnreadMessages];
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:unreadCount];
	
	[[BFHistoryStorage sharedStorage] saveChanges];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[contentViewController release];
	[window release];
	[super dealloc];
}

- (void)setHeaderTitle:(NSString *)title {
	[[contentViewController headerController] setHeaderTitle:title];
}

- (void)setHeaderTitle:(NSString *)title animated:(BOOL)animated {
	[[contentViewController headerController] setHeaderTitle:title animated:animated];
}

@end

