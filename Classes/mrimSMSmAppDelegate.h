//
//  mrimSMSmobileAppDelegate.h
//  mrimSMSmobile
//
//  Created by Алексеев Влад on 20.10.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "mrimProtocol.h"

@class BFContentViewController;

@interface mrimSMSmAppDelegate : NSObject <UIApplicationDelegate> {

    UIWindow *window;
	
	BFContentViewController *contentViewController;

	NSInteger numberOfUnreadMessages;
	
	NSMutableDictionary *storeParameters;
	
	BOOL showContactPictures;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) BFContentViewController *contentViewController;
@property (nonatomic, retain) NSMutableDictionary *storeParameters;

@property NSInteger numberOfUnreadMessages;
@property NSInteger numberOfMessages;

@property BOOL showContactPictures;

- (void)setHeaderTitle:(NSString *)title; 
- (void)setHeaderTitle:(NSString *)title animated:(BOOL)animated; 

@end

