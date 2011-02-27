//
//  MRIMAccoutViewController.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 30.07.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MRIMAccountViewController : UIViewController {
	IBOutlet UITextField *usernameField;
	IBOutlet UITextField *passwordField;
	
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UIButton *loginButton;
	IBOutlet UILabel *cautionLabel;
	IBOutlet UIImageView *cautionImageView;
	
	//localization
	IBOutlet UILabel *_loginUsingYourAccountLabel;
	IBOutlet UILabel *_usernameLabel;
	IBOutlet UILabel *_passwordLabel;
}

-(IBAction)login:(id)sender;
-(void)hideWarningMessage;
-(void)showWarningMessage:(NSString *)text;

@end
