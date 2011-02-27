//
//  BFHeaderController.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 13.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import "BFHeaderController.h"

#import "MRIMAccountViewController.h"
#import "MRIMNewMessageController.h"

#import "BFConnectionController.h"
#import "BFHistoryStorage.h"

@implementation BFHeaderController

- (void)awakeFromNib {
	[newMessageButton setUserInteractionEnabled:NO];
	[newMessageButton setAlpha:0.0];
	[timeOutLabel setHidden:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(mrimSendMessageNotification:) 
												 name:MRIMSendMessageNotification 
											   object:nil];
}

- (void)startSpinning {
	[UIView beginAnimations:@"connecting" context:nil];
	[accountLight setAlpha:0.0];
	[newMessageButton setAlpha:0.0];
	[newMessageButton setUserInteractionEnabled:NO];
	[activityIndicator startAnimating];
	[UIView commitAnimations];
}

- (void)stopSpinningWithSuccess:(BOOL)success {
	[UIView beginAnimations:@"connecting" context:nil];
	
	if (success) {
		[accountLight setImage:[UIImage imageNamed:@"greenlight.tiff"]];
		[newMessageButton setAlpha:1.0];
		[newMessageButton setUserInteractionEnabled:YES];
	}
	else {
		[accountLight setImage:[UIImage imageNamed:@"redlight.tiff"]];
		[newMessageButton setAlpha:0.0];
		[newMessageButton setUserInteractionEnabled:NO];
	}

	[accountLight setAlpha:1.0];
	[activityIndicator stopAnimating];
	[UIView commitAnimations];
}

- (void)setAccount:(NSString *)account {
	[accountLabel setText:account];
}

- (void)setHeaderTitle:(NSString *)title animated:(BOOL)animated {
	if (animated) {
		CATransition *transition = [CATransition animation];
		[transition setType:kCATransitionFade];
		[transition setDuration:0.3];
		
		[[[parentViewController view] layer] addAnimation:transition forKey:@"transition"];
	}
	
	[self setHeaderTitle:title];
}

- (void)setHeaderTitle:(NSString *)title {
	[headerTitleLabel setText:title];
}

- (void)mrimSendMessageNotification:(NSNotification *)n {
	minutkaTimeout = 0;
	minutkaTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 
													 target:self 
												   selector:@selector(minutkaTimerFire:) 
												   userInfo:nil 
													repeats:YES] retain];
	[newMessageButton setEnabled:NO];
	[timeOutLabel setHidden:NO];
}

#pragma mark -
#pragma mark Minutka

- (void)minutkaTimerFire:(NSTimer *)t {
	minutkaTimeout++;
	[newMessageButton setEnabled:NO];
	[timeOutLabel setText:[NSString stringWithFormat:@"%d", 60 - minutkaTimeout]];
	if (minutkaTimeout == 60) {
		[minutkaTimer invalidate];
		[minutkaTimer release];
		minutkaTimer = nil;
		[newMessageButton setEnabled:YES];
		[timeOutLabel setHidden:YES];
		minutkaTimeout = 0;
	}
}

#pragma mark -
#pragma mark UI

- (IBAction)settingsButtonPress {
	[[BFConnectionController sharedController] disconnect];
	
	MRIMAccountViewController *accountViewController = [[MRIMAccountViewController alloc] initWithNibName:@"MRIMAccountViewController" bundle:nil];
	[parentViewController presentModalViewController:accountViewController animated:YES];
	[accountViewController release];
}

- (IBAction)newMessageButtonPress {
	if ([[BFConnectionController sharedController] loggedIn]) {
		MRIMNewMessageController *newMessageController = [[MRIMNewMessageController alloc] initWithNibName:@"MRIMNewMessageController" bundle:nil];
		UINavigationController *newMessageNC = [[UINavigationController alloc] initWithRootViewController:newMessageController];
		[parentViewController presentModalViewController:newMessageNC animated:YES];
		[newMessageController release];
		[newMessageNC release];
	}
	else {
		[[BFConnectionController sharedController] connect];
	}
}

- (void)manageBackButton {
	UITabBarController *tabBarController = [parentViewController tabBarController];
	UINavigationController *navigationController = (UINavigationController *)[tabBarController selectedViewController];
	
	if ([[navigationController viewControllers] count] == 1) {
		[backButton setHidden:YES];
	}
	else {
		[backButton setHidden:NO];
	}

}

- (IBAction)backButtonPress {
	UITabBarController *tabBarController = [parentViewController tabBarController];
	UINavigationController *navigationController = (UINavigationController *)[tabBarController selectedViewController];
	
	if ([[navigationController viewControllers] count] > 1) {
		[navigationController popViewControllerAnimated:YES];
		[self manageBackButton];
	}
}

@end
