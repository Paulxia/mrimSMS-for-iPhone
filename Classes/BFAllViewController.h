//
//  BFAllViewController.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 13.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <UIKit/UIKit.h>
@class mrimSMSmAppDelegate;

@interface BFAllViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	mrimSMSmAppDelegate *appDelegate;
	
	UITableView *tableView;
	NSArray *completeHistory;
	NSString *phoneNumber;
	
	UIImage *sentIcon;
	UIImage *receivedIcon;
	
	NSDateFormatter *messageDateFormatter;
	NSDateFormatter *messageTimeFormatter;
	NSDateFormatter *todayDateFormatter;
}
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSArray *completeHistory;
@property (nonatomic, retain) NSString *phoneNumber;

@property (nonatomic, retain) NSDateFormatter *messageDateFormatter;
@property (nonatomic, retain) NSDateFormatter *messageTimeFormatter;
@property (nonatomic, retain) NSDateFormatter *todayDateFormatter;

@end
