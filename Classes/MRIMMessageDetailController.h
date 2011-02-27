//
//  MRIMMessageDetailController.h
//  mrimSMSmobile
//
//  Created by Алексеев Влад on 20.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

@class MRIMNewMessageController;

@interface MRIMMessageDetailController : UIViewController {
	IBOutlet UILabel *personNameField;
	IBOutlet UILabel *phoneNumberField;
	IBOutlet UITextView *messageField;
	IBOutlet UIImageView *personPhoto;
	
	IBOutlet UIImageView *headerBackground;
	
	IBOutlet UIButton *forwardButton;
}

- (void)setPersonName:(NSString *)name phoneNumber:(NSString *)phone message:(NSString *)message photo:(UIImage *)photo;

- (IBAction)forwardMessage;

@end
