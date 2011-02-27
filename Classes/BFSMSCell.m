//
//  BFSMSCell.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 15.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import "BFSMSCell.h"
#import "UIImage-RoundCorners.h"

#define BFContactNameFontSize 15.0f
#define BFMessageDateFontSize 10.0f
#define BFMessageDateMaxWidth 100.0f

@implementation BFSMSCell

@synthesize contactName, phoneNumber, messageDate, messageText, contactPhoto, income, unread;
@synthesize mailboxIcon;

+ (CGFloat)cellHeightForText:(NSString *)potentialMessageText cellWidth:(CGFloat)cellWidth {
	CGSize textSize = [potentialMessageText sizeWithFont:[UIFont systemFontOfSize:12]
					 constrainedToSize:CGSizeMake(cellWidth, MAXFLOAT) 
						 lineBreakMode:UILineBreakModeTailTruncation];
	
	CGFloat minimumHeight = 4.0f + 48.0f + 4.0f;
	CGFloat potentialHeight = 4.0f + BFContactNameFontSize + 4.0f + textSize.height + 4.0f;
	
	CGFloat height = MAX(minimumHeight, potentialHeight);
	return height;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:NO];
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	[super setHighlighted:highlighted animated:NO];
	[self setNeedsDisplay];
}

- (void)dealloc {
    [super dealloc];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	float contentHeight = self.contentView.frame.size.height;
	float contentWidth = self.contentView.frame.size.width;
	
	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	
	CGGradientRef glossGradient;
	CGColorSpaceRef rgbColorspace;
	rgbColorspace = CGColorSpaceCreateDeviceRGB();
	
	size_t numLocations = 2;
	CGFloat locations[2] = { 0.0, 1.0 };
	
	//Two colour components, the start and end colour both set to opaque.
	CGFloat componentsNormal[8] = {0.92, 0.92, 0.92, 1.0,
		0.87, 0.87, 0.87, 1.0};
	
	CGFloat componentsUnread[8] = {0.67, 0.76, 0.87, 1.0,
		0.87, 0.87, 0.87, 1.0};
	
	CGFloat componentsSelected[8] = {0.663, 0.705, 0.819, 1.0, 
		0.490, 0.557, 0.709, 1.0 };
	
	if (self.selected || self.highlighted) {		
		glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, 
															componentsSelected, 
															locations, 
															numLocations);
	}
	else {
		if ([self unread]) {
			glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, 
																componentsUnread, 
																locations, 
																numLocations);
		}
		else {
			glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, 
																componentsNormal, 
																locations, 
																numLocations);
		}
	}
	CGRect currentBounds = self.bounds;
	CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
	CGPoint bottomCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMaxY(currentBounds));
	CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, bottomCenter, 0);


	[[self contactPhoto] drawInRect:CGRectMake(4.0f, 4.0f, 48.0f, 48.0f)];
	
	[[self mailboxIcon] drawInRect:CGRectMake(contentWidth - 4 - 16, 4, 16, 16)];

	[[self contactName] drawInRect:CGRectMake(4 + 48 + 4, 4, contentWidth - (4 + 48 + 4 + 4 + BFMessageDateMaxWidth + 16 + 4), BFContactNameFontSize + 1.0f) 
						  withFont:[UIFont boldSystemFontOfSize:BFContactNameFontSize] 
					 lineBreakMode:UILineBreakModeTailTruncation];
	
	[[self messageDate] drawInRect:CGRectMake(contentWidth - (4 + 16 + 4 + BFMessageDateMaxWidth + 4), 4, BFMessageDateMaxWidth, BFMessageDateFontSize + 1.0f) 
						  withFont:[UIFont systemFontOfSize:BFMessageDateFontSize] 
					 lineBreakMode:UILineBreakModeMiddleTruncation 
						 alignment:UITextAlignmentRight];

	[[self messageText] drawInRect:CGRectMake(4 + 48 + 4, 4 + BFContactNameFontSize + 4, 
											  contentWidth - (4 + 48 + 4 + 4), 
											  contentHeight - (4 + BFContactNameFontSize + 4 + 4)) 
						  withFont:[UIFont systemFontOfSize:12] 
					 lineBreakMode:UILineBreakModeTailTruncation 
						 alignment:UITextAlignmentLeft];
					 
}


@end
