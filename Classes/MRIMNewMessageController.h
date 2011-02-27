
#import <AddressBookUI/AddressBookUI.h>
#import "MRIMRecentNumbersViewController.h"


@class mrimSMSmAppDelegate;
@class MRIMHistoryViewController;

@interface MRIMNewMessageController : UIViewController <ABPeoplePickerNavigationControllerDelegate, MRIMRecentNumbersViewControllerDelegate> {
	mrimSMSmAppDelegate *appDelegate;
	
	UIBarButtonItem *sendMessageButton;
	UIBarButtonItem *cancelButton;
	
	IBOutlet UIImageView *personPhoto;
	IBOutlet UITextView *messageTextView;
	IBOutlet UITextField *phoneNumberField;
	IBOutlet UILabel *personNameLabel;
	IBOutlet UILabel *messageLengthLabel;
	
	IBOutlet UIImageView *phoneNumberBackground;
	IBOutlet UIImageView *personNameBackground;
	IBOutlet UIImageView *messageLengthIcon;
	
	IBOutlet UIView *messageInfoView;
	
	MRIMHistoryViewController *historyViewController;
}

@property (nonatomic, assign, readwrite) mrimSMSmAppDelegate *appDelegate;
@property (nonatomic, assign) MRIMHistoryViewController *historyViewController;

#pragma mark Actions
-(void)registerForTextNotifications;
-(void)setPersonName:(NSString *)name 
		 phoneNumber:(NSString *)phone 
			 message:(NSString *)message 
			   photo:(UIImage *)photo;
-(void)setPersonNameFieldText;
-(void)sendMessage;

-(IBAction)pickPhoneNumber:(id)sender;

#pragma mark Text fields delegates and Notifications
- (void)textDidChange:(NSNotification *)note;

@end
