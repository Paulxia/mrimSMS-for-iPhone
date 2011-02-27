//
//  BFContentViewController.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 13.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import "BFContentViewController.h"

#import "MRIMAccountViewController.h"
#import "BFMainViewController.h"
#import "BFAllViewController.h"
#import "BFHeaderController.h"

#import "BFAddressBookDealer.h"
#import "BFConnectionController.h"

#import "mrimSMSmAppDelegate.h"

@implementation BFContentViewController

@synthesize contentView;
@synthesize headerController;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
	
	BFMainViewController *mainViewController = [[BFMainViewController alloc] initWithNibName:@"BFMainViewController" 
																					  bundle:nil];
	[mainViewController setTitle:NSLocalizedString(@"mByName", nil)]; 
	[[mainViewController tabBarItem] setImage:[UIImage imageNamed:@"67-tshirt.png"]];
	UINavigationController *mainNavigationController = [[UINavigationController alloc] 
														initWithRootViewController:mainViewController];
	[mainNavigationController setDelegate:self];
	[mainNavigationController setNavigationBarHidden:YES]; 
	
	BFAllViewController *allViewController = [[BFAllViewController alloc] initWithNibName:@"BFAllViewController" 
																				   bundle:nil];
	[allViewController setTitle:NSLocalizedString(@"mAllList", nil)];
	[[allViewController tabBarItem] setImage:[UIImage imageNamed:@"44-shoebox.png"]];
	UINavigationController *allNavigationController = [[UINavigationController alloc] initWithRootViewController:allViewController];
	[allNavigationController setDelegate:self];
	[allNavigationController setNavigationBarHidden:YES];
	
	[[self tabBarController] setViewControllers:[NSArray arrayWithObjects:
												 mainNavigationController, 
												 allNavigationController, 
												 nil]];
	
	[mainViewController release];
	[mainNavigationController release];
	
	[allViewController release];
	[allNavigationController release];
	
	[self setContentView:[[self tabBarController] view]];
	
	adView = [[ADBannerView alloc] initWithFrame:CGRectZero];
	adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
	[adView setDelegate:self];
	[[self view] addSubview:adView];
	
	CGRect adFrame = [adView frame];
	adFrame = CGRectOffset(adFrame, 0, 410);
	[adView setFrame:adFrame];
	[adView setBackgroundColor:[UIColor blackColor]];
	[adView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
	[adView release];
	
	
	// Connecting
	[[BFConnectionController sharedController] connect];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self 
						   selector:@selector(mrimDelegateDidStartConnectingNotification:) 
							   name:BFMRIMDelegateDidStartConnecting 
							 object:nil];
	[notificationCenter addObserver:self 
						   selector:@selector(mrimDelegateDidLoginNotification:) 
							   name:BFMRIMDelegateDidLogin
							 object:nil];
	[notificationCenter addObserver:self 
						   selector:@selector(mrimDelegateDidFailLoginNotification:) 
							   name:BFMRIMDelegateDidFailLogin
							 object:nil];
	[notificationCenter addObserver:self 
						   selector:@selector(mrimDelegateNoCredentialsNotification:) 
							   name:BFMRIMDelegateNoCredentials
							 object:nil];
	[notificationCenter addObserver:self 
						   selector:@selector(mrimDelegateDidDoppedNotification:) 
							   name:BFMRIMDelegateDidDopped
							 object:nil];
	[notificationCenter addObserver:self 
						   selector:@selector(mrimDelegateDidDisconnectNotification:) 
							   name:BFMRIMDelegateDidDisconnect
							 object:nil];
	
	[notificationCenter addObserver:self 
						   selector:@selector(mrimIncomeMessageNotification:) 
							   name:MRIMIncomeMessageNotification 
							 object:nil];
	[notificationCenter addObserver:self 
						   selector:@selector(mrimOfflineMessageNotification:)
							   name:MRIMOfflineMessageNotification 
							 object:nil];
	
	
	// System notifications
	[notificationCenter addObserver:self 
						   selector:@selector(applicationWillEnterForegroundNotification:) 
							   name:UIApplicationWillEnterForegroundNotification 
							 object:nil];
	[notificationCenter addObserver:self 
						   selector:@selector(applicationDidEnterBackgroundNotification:) 
							   name:UIApplicationDidEnterBackgroundNotification 
							 object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)n {
	[headerController startSpinning];
	[[BFConnectionController sharedController] connect];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)n {
	[headerController setAccount:@""]; 
	[headerController stopSpinningWithSuccess:NO];
	[[BFConnectionController sharedController] disconnect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	if (newMessagesSound) 
		AudioServicesDisposeSystemSoundID(newMessagesSound);
	newMessagesSound = 0;
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self];
}

- (void)dealloc {
	[tabBarController release];
    [super dealloc];
}

- (UITabBarController *)tabBarController {
	if (tabBarController == nil) {
		tabBarController = [[UITabBarController alloc] init];
		[tabBarController setDelegate:self];		
	}
	return tabBarController;
}

- (void)tabBarController:(UITabBarController *)tabBarController 
 didSelectViewController:(UIViewController *)viewController {
	UINavigationController *currentViewController = (UINavigationController *)[[self tabBarController] selectedViewController];
	UIViewController *visibleViewController = [currentViewController visibleViewController];
	[(mrimSMSmAppDelegate *)[[UIApplication sharedApplication] delegate] setHeaderTitle:[visibleViewController title]];
	[headerController manageBackButton];
}

- (void)navigationController:(UINavigationController *)navigationController 
	   willShowViewController:(UIViewController *)viewController 
					animated:(BOOL)animated {
	[(mrimSMSmAppDelegate *)[[UIApplication sharedApplication] delegate] setHeaderTitle:[viewController title] animated:animated];
	[headerController manageBackButton];
}

- (void)setContentView:(UIView *)aContentView {
	if (contentView == aContentView)
		return;
	
	[contentView removeFromSuperview];
	[contentView release];
	
	int adHeight = 50;
	
	CGRect windowFrame = [[self view] frame];
	CGRect viewFrame = windowFrame;
	viewFrame.origin.y = 28;
	viewFrame.size.height -= 28 + adHeight;
	
	[aContentView setFrame:viewFrame];
	[[self view] addSubview:aContentView];
	contentView = [aContentView retain];
}

#pragma mark -
#pragma mark MRIM Notifications

- (void)mrimIncomeMessageNotification:(NSNotification *)n {
	NSDictionary *messageInfo = [n object];
	
	NSString *phoneNumber = [messageInfo valueForKey:@"phoneNumber"];
	NSString *contactName = [[BFAddressBookDealer sharedDealer] fullNameForPhone:phoneNumber withAlternativeText:phoneNumber];
	NSString *messageText = [messageInfo valueForKey:@"message"];
	
	UIAlertView *newMessageAlert = [[UIAlertView alloc] initWithTitle:contactName 
															  message:messageText 
															 delegate:nil 
													cancelButtonTitle:@"OK" 
													otherButtonTitles:nil];
	[newMessageAlert show];
	[newMessageAlert release];
}

- (void)mrimOfflineMessageNotification:(NSNotification *)n {
	[self playNewMessagesSound];
}

- (void)mrimDelegateDidStartConnectingNotification:(NSNotification *)n {
	[headerController startSpinning];
	[headerController setAccount:@""];
}

- (void)mrimDelegateDidLoginNotification:(NSNotification *)n {
	[headerController stopSpinningWithSuccess:YES];
	NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"email_preference"];
	[headerController setAccount:username];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)mrimDelegateDidFailLoginNotification:(NSNotification *)n {
	[headerController stopSpinningWithSuccess:NO];
	[headerController setAccount:NSLocalizedString(@"mLoginErrorMessage", nil)];
}

- (void)mrimDelegateNoCredentialsNotification:(NSNotification *)n {
	[headerController stopSpinningWithSuccess:NO];
	MRIMAccountViewController *accountViewController = [[MRIMAccountViewController alloc] initWithNibName:@"MRIMAccountViewController" 
																								   bundle:nil];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[accountViewController setModalPresentationStyle:UIModalPresentationFormSheet];
	}
	[self presentModalViewController:accountViewController animated:YES];
	[accountViewController release];
}

- (void)mrimDelegateDidDoppedNotification:(NSNotification *)n {
	[headerController stopSpinningWithSuccess:NO];
}

- (void)mrimDelegateDidDisconnectNotification:(NSNotification *)n {
	[headerController stopSpinningWithSuccess:NO];
}

#pragma mark -
#pragma mark iAd delegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {

}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
	[UIView beginAnimations:@"animateAdBannerOff" context:NULL];
	// assumes the banner view is at the top of the screen.
	banner.frame = CGRectOffset(banner.frame, 0, 50);
	contentView.frame = CGRectMake(contentView.frame.origin.x, contentView.frame.origin.y, 
								   contentView.frame.size.width, self.view.frame.size.height - contentView.frame.origin.y);
	[UIView commitAnimations];
}

#pragma mark Sound

- (void)playNewMessagesSound {
	if (newMessagesSound == 0) {
		NSString *filename = @"newMessage";
		NSString *soundPath = [[NSBundle mainBundle] pathForResource:filename ofType:@"aif"];
		NSURL *url = [NSURL fileURLWithPath:soundPath];
		AudioServicesCreateSystemSoundID((CFURLRef)url, &newMessagesSound);	
	}
	AudioServicesPlaySystemSound(newMessagesSound);
}

@end
