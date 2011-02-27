//
//  MRIMStoreViewController.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 06.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MRIMStoreViewController.h"
#import <StoreKit/StoreKit.h>
#import "MRIMStoreObserver.h"
#import "mrimSMSmAppDelegate.h"
#import "NSData-AES.h"
#import "NSData+Base64.h"

@implementation MRIMStoreViewController

@synthesize appDelegate;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	store = [appDelegate storeParameters];
	
	[self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
	[self.navigationItem setTitle:NSLocalizedString(@"mStoreButton", nil)];

	[blackDescription setFont:[UIFont systemFontOfSize:15.0]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(enabledBlackNotification:) 
												 name:@"BFNStoreEnableBlack" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(restoreCompleteNotification:) 
												 name:@"BFNStoreRestoreComplete" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(paymentFailedNotification:) 
												 name:@"BFNStoreFailedPayment" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(paymentCancelledNotification:) 
												 name:@"BFNStoreCancelledPayment" object:nil];
	
	transactionsObserver = [[MRIMStoreObserver alloc] init];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:transactionsObserver];
	
	[self setProducts];
	[self setBlackSwitchState];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	BOOL black_activated = [blackEnabler isOn];
	[store setValue:[NSNumber numberWithBool:black_activated] forKey:@"black_activated"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BFNResetTheme" object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	}
	else {
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	}
	
	if (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) {
		return YES;
	}
    return NO;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[transactionsObserver release];
	transactionsObserver = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark Store

- (void)setProducts
{
	NSDictionary *blackInfo = [store valueForKey:@"black_info"];
	if (blackInfo == nil) {
		[self requestProductData];
	}
	else {
		[self setBlackTitle:[blackInfo valueForKey:@"black_title"] 
				description:[blackInfo valueForKey:@"black_description"] 
					  price:[blackInfo valueForKey:@"black_price"]
		   localeIdentifier:[blackInfo valueForKey:@"black_localeIdentifier"]];
	}
	
	if ([[store valueForKey:@"black_purchased"] boolValue]) {
		[blackButtonPurchase setHidden:YES];
		[blackEnabler setHidden:NO];
		if ([[store valueForKey:@"black_activated"] boolValue]) {
			[blackEnabler setOn:YES animated:NO];
		}
	}
}

- (void)setBlackTitle:(NSString *)title description:(NSString *)description 
				price:(NSNumber *)price localeIdentifier:(NSString *)localeIdentifier
{
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier] autorelease]];
	NSString *formattedPrice = [numberFormatter stringFromNumber:price];
	
	[blackLabelTitle setText:title];
	[blackDescription setText:description];
	[blackButtonPurchase setTitle:formattedPrice forState:UIControlStateNormal];
	[activityIndicator stopAnimating];
}

- (void)setBlackSwitchState
{
	if ([[store valueForKey:@"black_purchased"] boolValue]) {
		[blackButtonPurchase setHidden:YES];
		[blackEnabler setHidden:NO];
		if ([[store valueForKey:@"black_activated"] boolValue]) {
			[blackEnabler setOn:YES animated:NO];
		}
	}
	else {
		[blackEnabler setHidden:YES];
		[blackButtonPurchase setHidden:NO];
	}

}

#pragma mark -
#pragma mark Actions

- (IBAction)purchaseBlack:(id)sender
{
	SKPayment *payment = [SKPayment paymentWithProductIdentifier:@"com.beefon.mrimSMS.black"];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
	[blackButtonPurchase setHidden:YES];
	[activityIndicator startAnimating];
}

- (IBAction)forcseRequestProductData:(id)sender
{
	[store removeObjectForKey:@"black_info"];
	[self requestProductData];
}

#pragma mark -
#pragma mark StoreKit

- (void)enabledBlackNotification:(NSNotification *)n {
	[activityIndicator stopAnimating];
	[blackButtonPurchase setHidden:YES];
	[blackEnabler setHidden:NO];
	
	[[self.appDelegate storeParameters] setValue:[NSNumber numberWithBool:YES] 
										  forKey:@"black_purchased"];
	
	[self setBlackSwitchState];
}

- (void)paymentFailedNotification:(NSNotification *)n {
	[blackButtonPurchase setHidden:NO];
	[activityIndicator stopAnimating];
}

- (void)paymentCancelledNotification:(NSNotification *)n {
	[blackButtonPurchase setHidden:NO];
	[activityIndicator stopAnimating];
}

- (void)restoreCompleteNotification:(NSNotification *)n {	
	if ([[[appDelegate storeParameters] valueForKey:@"black_activated"] boolValue]) {
		[blackEnabler setSelected:YES];
	}
}

- (void)requestProductData {
	SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"com.beefon.mrimSMS.black"]];
	request.delegate = self;
	
	[self.navigationItem setHidesBackButton:YES animated:YES];
	[request start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *myProduct = response.products;
	for (SKProduct *product in myProduct) {
		[self setBlackTitle:product.localizedTitle 
				description:product.localizedDescription
					  price:product.price
		   localeIdentifier:[product.priceLocale localeIdentifier]];
		
		[activityIndicator stopAnimating];
		
		NSDictionary *blackInfo = [NSDictionary dictionaryWithObjectsAndKeys:product.localizedTitle, @"black_title",
								   product.localizedDescription, @"black_description", product.price, @"black_price", 
								   [product.priceLocale localeIdentifier], @"black_localeIdentifier", nil];
		[store setObject:blackInfo forKey:@"black_info"];
	}
    [request autorelease];
	
	[self.navigationItem setHidesBackButton:NO animated:YES];
	NSLog(@"%@", store);
	[self setBlackSwitchState];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end