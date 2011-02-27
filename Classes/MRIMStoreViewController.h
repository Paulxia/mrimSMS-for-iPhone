//
//  MRIMStoreViewController.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 06.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@class MRIMStoreObserver;
@class mrimSMSmAppDelegate;

@interface MRIMStoreViewController : UIViewController <SKProductsRequestDelegate> {
	mrimSMSmAppDelegate *appDelegate;
	
	IBOutlet UIButton *blackButtonPurchase;
	IBOutlet UILabel *blackLabelTitle;
	IBOutlet UITextView *blackDescription;
	IBOutlet UISwitch *blackEnabler;
	IBOutlet UIActivityIndicatorView *activityIndicator;
	
	IBOutlet UIProgressView *pushProgressView;
	IBOutlet UITextField *pushPhoneNumberField;
	IBOutlet UITextField *pushPasswordField;
	IBOutlet UIImageView *pushNumberStatusImageView;
	IBOutlet UILabel *pushNumberStatusLabel;
	IBOutlet UIActivityIndicatorView *pushSpinner;
	IBOutlet UIButton *pushSendPasswordButton;
	IBOutlet UIButton *pushAssociateNumberButton;
	IBOutlet UILabel *pushDescriptionLabel;
	
	MRIMStoreObserver *transactionsObserver;
	
	NSMutableDictionary *store;
}

@property (nonatomic, assign, readwrite) mrimSMSmAppDelegate *appDelegate;

- (void)setProducts;
- (void)setBlackSwitchState;

- (void)setBlackTitle:(NSString *)title description:(NSString *)description 
				price:(NSNumber *)price localeIdentifier:(NSString *)locale;

- (void)requestProductData;

- (IBAction)purchaseBlack:(id)sender;

@end
