//
//  MRIMAccountViewController.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 30.07.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MRIMAccountViewController.h"

#import "BFConnectionController.h"

#import "mrimSMSmAppDelegate.h"

@implementation MRIMAccountViewController

- (void)localizeInterface {
	[_loginUsingYourAccountLabel setText:NSLocalizedString(@"mLoginUsingYourAccount", nil)];
	[_usernameLabel setText:NSLocalizedString(@"mEmail", nil)];
	[_passwordLabel setText:NSLocalizedString(@"mPassword", nil)];
	[loginButton setTitle:NSLocalizedString(@"mLogin", nil) forState:UIControlStateNormal];
}

- (void)viewDidLoad  {
    [super viewDidLoad];
	[self localizeInterface];
	NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"email_preference"];
	NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:@"password_preference"];
	[usernameField setText:username];
	[passwordField setText:password];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self 
						   selector:@selector(mrimDelegateDidFailLoginNotification:) 
							   name:BFMRIMDelegateDidFailLogin
							 object:nil];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[usernameField becomeFirstResponder];
}

- (void)hideWarningMessage {
	[cautionLabel setHidden:YES];
	[cautionImageView setHidden:YES];
}

- (void)showWarningMessage:(NSString *)text {
	[cautionLabel setText:text];
	[cautionLabel setHidden:NO];
	[cautionImageView setHidden:NO];
	[spinner stopAnimating];
	[loginButton setTitle:NSLocalizedString(@"mLogin", nil) forState:UIControlStateNormal];
}

- (void)mrimDelegateDidFailLoginNotification:(NSNotification *)n {
	[self showWarningMessage:NSLocalizedString(@"mLoginErrorMessage", nil)];
}

- (IBAction)login:(id)sender {
	if ([[usernameField text] length] == 0) {
		[usernameField becomeFirstResponder];
		return;
	}
	
	if ([[passwordField text] length] == 0) {
		[passwordField becomeFirstResponder];
		return;
	}
	
	[spinner startAnimating];
	[loginButton setTitle:NSLocalizedString(@"mLoggingIn", nil) forState:UIControlStateNormal];
	[self hideWarningMessage];
	[[NSUserDefaults standardUserDefaults] setValue:[usernameField text] forKey:@"email_preference"];
	[[NSUserDefaults standardUserDefaults] setValue:[passwordField text] forKey:@"password_preference"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[BFConnectionController sharedController] connect];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	if (theTextField == usernameField)
		[passwordField becomeFirstResponder];
	
	if (passwordField == theTextField)
		[self login:self];
	
	return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (interfaceOrientation == UIInterfaceOrientationPortrait) {
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

@end
