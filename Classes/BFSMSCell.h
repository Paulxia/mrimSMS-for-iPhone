//
//  BFSMSCell.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 15.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BFSMSCell : UITableViewCell {
	NSString *contactName;
	NSString *phoneNumber;
	NSString *messageText;
	NSString *messageDate;
	UIImage *contactPhoto;
	BOOL income;
	BOOL unread;
	
	UIImage *mailboxIcon;
}

@property (nonatomic, retain) NSString *contactName;
@property (nonatomic, retain) NSString *phoneNumber;
@property (nonatomic, retain) NSString *messageText;
@property (nonatomic, retain) NSString *messageDate;
@property (nonatomic, retain) UIImage *contactPhoto;
@property BOOL income;
@property BOOL unread;

@property (nonatomic, retain) UIImage *mailboxIcon;

+ (CGFloat)cellHeightForText:(NSString *)potentialMessageText cellWidth:(CGFloat)cellWidth;

@end
