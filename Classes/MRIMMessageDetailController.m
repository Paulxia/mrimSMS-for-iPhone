//
//  MRIMMessageDetailController.m
//  mrimSMSmobile
//
//  Created by Алексеев Влад on 20.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MRIMMessageDetailController.h"
#import "MRIMNewMessageController.h"

#import "BFConnectionController.h"

#import "mrimSMSmAppDelegate.h"

@implementation MRIMMessageDetailController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[forwardButton setEnabled:[[BFConnectionController sharedController] canSendMessage]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) {
		return YES;
	}
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark Actions

-(void)setPersonName:(NSString *)name phoneNumber:(NSString *)phone message:(NSString *)message photo:(UIImage *)photo {
	[personNameField setText:name];
	[phoneNumberField setText:phone];
	[messageField setText:message];
	[personPhoto setImage:photo];
}

- (void)forwardMessage {
	BOOL canSendMessage = [[BFConnectionController sharedController] canSendMessage];
	if (!canSendMessage) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"mMinuteTimer", nil) 
														message:nil
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	
	mrimSMSmAppDelegate *appDelegate = (mrimSMSmAppDelegate *)[[UIApplication sharedApplication] delegate];
	UIViewController *rootViewController = (UIViewController *)[appDelegate contentViewController];
		
	MRIMNewMessageController *newMessageController = [[MRIMNewMessageController alloc] initWithNibName:@"MRIMNewMessageController" bundle:nil];
	UINavigationController *newMessageNavigationController = [[UINavigationController alloc] initWithRootViewController:newMessageController];
	
	[rootViewController presentModalViewController:newMessageNavigationController animated:YES];
	
	[newMessageController release];
	[newMessageNavigationController release];
	
	[newMessageController setPersonName:[personNameField text] 
							phoneNumber:[phoneNumberField text]
								message:[messageField text]
								  photo:[personPhoto image]];
}

@end
