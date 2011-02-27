//
//  BFHeaderController.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 13.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class BFHistoryStorage;

@interface BFHeaderController : NSObject {
	IBOutlet UIViewController *parentViewController;
	IBOutlet UILabel *accountLabel;
	IBOutlet UIImageView *accountLight;
	IBOutlet UIActivityIndicatorView *activityIndicator;
	IBOutlet UILabel *timeOutLabel;
	IBOutlet UIButton *newMessageButton;
	IBOutlet UILabel *headerTitleLabel;
	IBOutlet UIButton *backButton;
	
	
	NSTimer *minutkaTimer;
	NSInteger minutkaTimeout;
}

- (void)startSpinning;
- (void)stopSpinningWithSuccess:(BOOL)success;

- (void)setAccount:(NSString *)account;
- (void)setHeaderTitle:(NSString *)title animated:(BOOL)animated;
- (void)setHeaderTitle:(NSString *)title;

- (IBAction)settingsButtonPress;
- (IBAction)newMessageButtonPress;
- (void)manageBackButton;
- (IBAction)backButtonPress;

@end
