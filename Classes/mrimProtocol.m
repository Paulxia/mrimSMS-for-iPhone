//
//  mrimProtocol.m
//  mrimProtocol
//
//  Created by Алексеев Влад on 02.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "mrimProtocol.h"
#import "AsyncSocket.h"

NSString *const BFMRIMOperationIdle = @"BFMRIMOperationIdle";
NSString *const BFMRIMOperationGettingServerAddress = @"BFMRIMOperationGettingServerAddress";
NSString *const BFMRIMOperationLoggingIn = @"BFMRIMOperationLoggingIn";
NSString *const BFMRIMOperationConnecting = @"BFMRIMOperationConnecting";

NSString *const BFKeyMessageText = @"BFKeyMessageText";
NSString *const BFKeyMessageSender = @"BFKeyMessageSender";
NSString *const BFKeyMessageDate = @"BFKeyMessageDate";
NSString *const BFKeyMessageNotify = @"BFKeyMessageNotify";
NSString *const BFKeyMessageSMS = @"BFKeyMessageSMS";
NSString *const BFKeyMessageStatus = @"BFKeyMessageStatus";
NSString *const BFKeyMessageOnline = @"BFKeyMessageOnline";
NSString *const BFKeyMessageOffline = @"BFKeyMessageOffline";

NSString *const BFKeyMessageResultSuccess = @"BFKeyMessageResultSuccess";
NSString *const BFKeyMessageResultFailed = @"BFKeyMessageResultFailed";
NSString *const BFKeyMessageResultInProcess = @"BFKeyMessageResultInProcess";

@implementation mrimProtocol

@synthesize delegate;
@synthesize operation;
@synthesize currentTag;
@synthesize mrimServerAddress;
@synthesize username, password;

#pragma mark Object initialization and deallocation

-(id)init
{
	if(self = [super init])
	{
		socket = [[AsyncSocket alloc] initWithDelegate:self];
		operations = [[NSMutableDictionary alloc] init];
		packetStatuses = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)dealloc
{
	[socket release];
	[operations release];
	[packetStatuses release];
	[pingTimer invalidate];
	[pingTimer release];
	[super dealloc];
}

#pragma mark mrim methods
- (mrim_header)getPacketHeaderFromData:(NSData *)data
{
	mrim_header packet;
	[data getBytes:&(packet.magic) range:NSMakeRange(sizeof(u_long)*0, sizeof(u_long))];
	[data getBytes:&(packet.proto) range:NSMakeRange(sizeof(u_long)*1, sizeof(u_long))];
	[data getBytes:&(packet.seq) range:NSMakeRange(sizeof(u_long)*2, sizeof(u_long))];
	[data getBytes:&(packet.msg) range:NSMakeRange(sizeof(u_long)*3, sizeof(u_long))];
	[data getBytes:&(packet.dlen) range:NSMakeRange(sizeof(u_long)*4, sizeof(u_long))];
	//[data getBytes:&(packet.IP) range:NSMakeRange(sizeof(u_long)*5, sizeof(u_long))];
	//[data getBytes:&(packet.Port) range:NSMakeRange(sizeof(u_long)*6, sizeof(u_long))];
	return packet;
}

- (NSData *)generatePacketWithMessage:(u_long)message 
							 sequence:(u_long)seq 
					   additionalData:(NSData *)data
{
	mrim_header packet;
	packet.magic = CS_MAGIC;
	packet.seq = seq;
	packet.proto = PROTO_VERSION;
	packet.msg = message;
	if (data)
		packet.dlen = [data length];
	else
		packet.dlen = 0;
	
	packet.IP = 0;
	packet.Port = 0;
	
	NSMutableData *packetData = [NSMutableData dataWithBytesNoCopy:&packet 
															length:sizeof(mrim_header) 
													  freeWhenDone:NO];
	if (packet.dlen > 0) {
		[packetData appendBytes:[data bytes] length:[data length]];
	}
	
	return packetData;
}

- (NSString *)keyForTag:(long)tag {
	return [NSString stringWithFormat:@"%d", tag];
}

#pragma mark -
#pragma mark methods

- (void)connectToHost:(NSString *)address {
	NSLog(@"connectToHost: %@", address);	
	NSError *err;
	[socket connectToHost:address onPort:443 error:&err];
}

- (void)disconnect {
	[socket disconnect];
	[pingTimer invalidate];
	[pingTimer release];
	pingTimer = nil;
}

- (void)serverAddress {
	[operations removeAllObjects];
	currentTag = 1;
	[socket emptyQueues]; // чистим очередь
	[socket readDataWithTimeout:-1 tag:currentTag];
	[operations setObject:@"processServerAddress:" forKey:[self keyForTag:currentTag]];
}

- (void)welcomeServer {
	NSLog(@"welcomingServer");
	NSData *packet = [self generatePacketWithMessage:MRIM_HELLO 
											sequence:++currentTag 
									  additionalData:nil];
	[socket writeData:packet withTimeout:-1 tag:++currentTag];
	[operations setObject:@"processServerWelcomeAnswerData:" forKey:[self keyForTag:++currentTag]];
	[socket readDataWithTimeout:-1 tag:currentTag];
}

- (void)loginToServer {
	NSLog(@"loginToServer");
	
	u_long usernameLen = [self.username length];
	u_long passwordLen = [self.password length];
	u_long status = STATUS_AWAY;
	
	NSString *userStatus = @"Online";
	u_long userStatusLen = [userStatus length];
	NSString *userTextStatus = @"";
	u_long userTextStatusLen = [userTextStatus length];
	NSString *userExtStatus = @"";
	u_long userExtStatusLen = [userExtStatus length];
	NSString *clientID = @"client=\"ansmssend\" version=\"2.0.3\" build=\"102\"";
	u_long clientIDLen = [clientID length];
	NSString *languageID = @"ru";
	u_long languageIDLen = [languageID length];
	NSString *privateInfo = @"pinf";
	u_long privateInfoLen = [privateInfo length];
	
	NSMutableData *loginData = [NSMutableData data];
	
	[loginData appendBytes:&usernameLen length:sizeof(u_long)];
	[loginData appendBytes:[self.username cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:usernameLen];
	
	[loginData appendBytes:&passwordLen length:sizeof(u_long)];
	[loginData appendBytes:[self.password cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:passwordLen];
	
	[loginData appendBytes:&status length:sizeof(u_long)];
	
	[loginData appendBytes:&userStatusLen length:sizeof(u_long)];
	[loginData appendBytes:[userStatus cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:userStatusLen];
	
	[loginData appendBytes:&userTextStatusLen length:sizeof(u_long)];
	[loginData appendBytes:[userTextStatus cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:userTextStatusLen];
	
	[loginData appendBytes:&userExtStatusLen length:sizeof(u_long)];
	[loginData appendBytes:[userExtStatus cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:userExtStatusLen];	
	
	u_long clientFeatures = FEATURE_FLAG_BASE_SMILES;
	[loginData appendBytes:&clientFeatures length:sizeof(u_long)];
	
	[loginData appendBytes:&clientIDLen length:sizeof(u_long)];
	[loginData appendBytes:[clientID cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:clientIDLen];	
	
	[loginData appendBytes:&languageIDLen length:sizeof(u_long)];
	[loginData appendBytes:[languageID cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:languageIDLen];	
	
	u_long emptyUL = 0;
	[loginData appendBytes:&emptyUL length:sizeof(u_long)];
	[loginData appendBytes:&emptyUL length:sizeof(u_long)];
	
	[loginData appendBytes:&privateInfoLen length:sizeof(u_long)];
	[loginData appendBytes:[privateInfo cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:privateInfoLen];	
	
	NSData *packet = [self generatePacketWithMessage:MRIM_LOGIN 
											sequence:currentTag 
									  additionalData:loginData];
	
	[socket writeData:packet withTimeout:-1 tag:++currentTag];
	[socket readDataWithTimeout:-1 tag:++currentTag];
}

- (void)pingFromTimer:(NSTimer *)timer {
	NSData *packet = [self generatePacketWithMessage:MRIM_PING 
											sequence:++currentTag
									  additionalData:nil];
	[socket writeData:packet withTimeout:-1 tag:++currentTag];
	NSLog(@"pingFromTimer");
}

- (void)sendMessageTo:(NSString *)address withText:(NSString *)message {
	
}

- (void)sendSMSToNumber:(NSString *)number withText:(NSString *)message {
	if (![message canBeConvertedToEncoding:NSUTF16LittleEndianStringEncoding])
		return;
	
	u_long zero = 0;
	u_long numberLen = [number length];
	u_long messageLen = [message lengthOfBytesUsingEncoding:NSUTF16LittleEndianStringEncoding];
	
	//NSLog(@"number: %@", number);
	//NSLog(@"sending (%d): %@", messageLen, message);
	
	NSMutableData *packetData = [NSMutableData data];
	
	[packetData appendBytes:&zero length:sizeof(u_long)];
	
	[packetData appendBytes:&numberLen length:sizeof(u_long)];
	[packetData appendBytes:[number cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:numberLen];
	
	[packetData appendBytes:&messageLen length:sizeof(u_long)];
	[packetData appendBytes:[message cStringUsingEncoding:NSUTF16LittleEndianStringEncoding] length:messageLen*2];
	
	NSData *packet = [self generatePacketWithMessage:MRIM_SMS 
											sequence:++currentTag
									  additionalData:packetData];

	[packetStatuses setObject:BFKeyMessageResultInProcess forKey:[self keyForTag:currentTag]];
	NSLog(@"packetStatuses for %d: processing", currentTag);
	[socket writeData:packet withTimeout:-1 tag:++currentTag];
}


#pragma mark -
#pragma mark Processing income packets

- (void)processPacketWithData:(NSData *)data {
	NSLog(@"processPacketWithData");
	
	mrim_header header = [self getPacketHeaderFromData:data];
	if (header.msg == MRIM_LOGIN_ACK) {
		[delegate mrimObjectDidLogin:self];
		pingTimer = [[NSTimer scheduledTimerWithTimeInterval:pingPeriod 
													  target:self 
													selector:@selector(pingFromTimer:) 
													userInfo:nil 
													 repeats:YES] retain];
		[self pingFromTimer:nil];
	}
	
	if (header.msg == MRIM_LOGIN_REJ) {
		[delegate mrimObjectDidFailLogin:self];
		[socket disconnect];
	}
	
	if (header.msg == MRIM_USER_STATUS)
		NSLog(@"new packet: MRIM_CS_USER_STATUS");
	if (header.msg == MRIM_MESSAGE_STATUS)
		NSLog(@"new packet: MRIM_CS_MESSAGE_STATUS");
	if (header.msg == MRIM_MAILBOX_STATUS)
		NSLog(@"new packet: MRIM_CS_MAILBOX_STATUS");
	if (header.msg == MRIM_CONTACT_LIST)
		NSLog(@"new packet: MRIM_CS_CONTACT_LIST2");
	if (header.msg == MRIM_USER_INFO)
		NSLog(@"new packet: MRIM_CS_USER_INFO");
	
	if (header.msg == MRIM_SMS_ACK) {
		[self processSMSDeliveryPacket:data];
	}
	
	if (header.msg == MRIM_MESSAGE_ACK) {
		[self processOnlineMessage:data];
	}
	
	if (header.msg == MRIM_OFFLINE_MESSAGE_ACK) {
		[self processOfflineMessage:data];
	}	
}

- (void)processData:(NSData *)data {
	NSLog(@"processData: %d", [data length]);
	
	mrim_header header;
	
	NSInteger currentByte = 0;
	
	// проходим по всем пакетам в данных
	while (currentByte < [data length]) {
		NSData *nextPacket = [data subdataWithRange:NSMakeRange(currentByte, [data length] - currentByte)];
		
		header = [self getPacketHeaderFromData:nextPacket];
		if ([data length] < currentByte + sizeof(header) + header.dlen)
			break;
		NSData *dataToProcess = [data subdataWithRange:NSMakeRange(currentByte, sizeof(header) + header.dlen)];
		currentByte += sizeof(header) + header.dlen;
		[self processPacketWithData:dataToProcess];
	}
	
	[socket readDataWithTimeout:-1 tag:++currentTag];
}
	 
- (void)processServerAddress:(NSData *)data {
	NSString *address = [NSString stringWithUTF8String:[data bytes]];
	[delegate mrimObject:self didReceiveServerAddress:address];
	[socket disconnect];
}

- (void)processServerWelcomeAnswerData:(NSData *)data {
	mrim_header header = [self getPacketHeaderFromData:data];
	if (header.msg == MRIM_HELLO_ACK) {
		NSLog(@"processServerWelcomeAnswerData: MRIM_CS_HELLO_ACK");
		[data getBytes:&pingPeriod 
				 range:NSMakeRange(sizeof(mrim_header) + (sizeof(u_long))*0, sizeof(u_long))];
		NSLog(@"   newPingPeriod: %d", pingPeriod);
		[delegate mrimObjectDidWelcomeServer:self];
	}
	else {
		NSLog(@"processServerWelcomeAnswerData: error");
	}
}

- (void)processOnlineMessage:(NSData *)data {
	BOOL isSMS = NO;
	BOOL isNotify = NO;
	
	u_long messID;
	[data getBytes:&messID range:NSMakeRange(sizeof(u_long)*11, sizeof(u_long))];
	u_long flag;
	[data getBytes:&flag range:NSMakeRange(sizeof(u_long)*12, sizeof(u_long))];
	
	if (flag & MESSAGE_FLAG_SMS) {
		// значит, пришло уведомление СМС или СМС-ответ
		isSMS = YES;
		NSLog(@"mrim.processOnlineMessagePacket - it is SMS");
	}
	
	if (flag & MESSAGE_FLAG_SMS_NOTIFY) {
		// значит, пришло уведомление СМС или СМС-ответ
		isNotify = YES;
		isSMS = YES;
		NSLog(@"mrim.processOnlineMessagePacket - it is sms notify");
	}
	
	u_long fromLength;
	[data getBytes:&fromLength range:NSMakeRange(sizeof(u_long)*13, sizeof(u_long))];
	
	u_long messageLength;
	[data getBytes:&messageLength range:NSMakeRange(sizeof(u_long)*14 + fromLength, sizeof(u_long))];
	
	NSData *fromData = [data subdataWithRange:NSMakeRange(sizeof(u_long)*14, fromLength)];
	NSString *from = [[[NSString alloc] initWithData:fromData encoding:NSWindowsCP1251StringEncoding] autorelease];
	
	NSStringEncoding enc = NSUTF16LittleEndianStringEncoding; //NSWindowsCP1251StringEncoding;
	if (isNotify) {
		enc = NSUTF16LittleEndianStringEncoding;
	}
	
	NSData *messageData = [data subdataWithRange:NSMakeRange(sizeof(u_long)*15 + fromLength, messageLength)];
	NSString *message = [[[NSString alloc] initWithData:messageData encoding:enc] autorelease];
	
	NSLog(@"mrim.processOnlineMessagePacket: from= %@, mess= %@", from, message);
	
	if (!(flag & MESSAGE_FLAG_NORECV)) {
		NSMutableData *receivePacket = [NSMutableData data];
		[receivePacket appendBytes:&fromLength length:sizeof(u_long)];
		[receivePacket appendBytes:[from cStringUsingEncoding:NSUTF16LittleEndianStringEncoding] 
							length:fromLength];
		[receivePacket appendBytes:&messID length:sizeof(u_long)];
		
		NSData *pack = [self generatePacketWithMessage:MRIM_MESSAGE_RECV 
											  sequence:++currentTag 
										additionalData:receivePacket];
		
		[socket writeData:pack withTimeout:-1 tag:++currentTag];
	}
	
	NSDictionary *messageInfo = [NSDictionary dictionaryWithObjectsAndKeys:message, BFKeyMessageText,
								 [NSString stringWithFormat:@"+%@", from], BFKeyMessageSender, [NSDate date], BFKeyMessageDate, 
								 [NSNumber numberWithBool:isSMS], BFKeyMessageSMS, 
								 [NSNumber numberWithBool:isNotify], BFKeyMessageNotify,
								 BFKeyMessageOnline, BFKeyMessageStatus, nil];
	[delegate mrimObject:self didReceiveMessage:messageInfo];
}

-(void)processOfflineMessage:(NSData *)data {
	NSLog(@"mrim.processOfflineMessagePacket");
	
	BOOL isSMS = NO;
	
	u_long messID1;
	[data getBytes:&messID1 range:NSMakeRange(sizeof(u_long)*11, sizeof(u_long))];
	u_long messID2;
	[data getBytes:&messID2 range:NSMakeRange(sizeof(u_long)*12, sizeof(u_long))];
	// ID оффлайн-сообщения - UIDL - состоит из 8ми символов
	
	u_long rfcMessLen;
	[data getBytes:&rfcMessLen range:NSMakeRange(sizeof(u_long)*13, sizeof(u_long))];
	NSString *rfcMessage = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(sizeof(u_long)*14, rfcMessLen)] 
												  encoding:NSUTF16LittleEndianStringEncoding] autorelease];

	//NSLog(@"%@", rfcMessage);
	//массив из строк RFC-послания
	NSArray *lines = [rfcMessage componentsSeparatedByString:@"\n"];
	
	NSInteger blankParagraphIndex = 0;	// номер пустой строки-разделителя
	for (NSString *line in lines) {
		if ([line length] == 1) {
			blankParagraphIndex = [lines indexOfObject:line];
			NSLog(@"blankParagraphIndex = %d", blankParagraphIndex);
			break;
		}
	}
	
	// все, что до нее - заголовки. все, что после, кроме последних 2х строк - текст сообщения
	
	// загоняем заголовки в NSDictionary
	NSMutableDictionary *headers = [[[NSMutableDictionary alloc] init] autorelease];
	NSInteger currentLine = 0;
	while (currentLine < blankParagraphIndex) {
		NSString *headerLine = [lines objectAtIndex:currentLine];
		NSString *headerName = [headerLine substringToIndex:[headerLine rangeOfString:@":"].location];
		NSString *headerValue = [headerLine substringFromIndex:[headerLine rangeOfString:@":"].location + 2];
		[headers setValue:headerValue forKey:headerName];
		currentLine++;
	}
	
	u_long flags;
	NSString *flagsString = [headers valueForKey:@"X-MRIM-Flags"];
	long long llFlags = [flagsString longLongValue];
	flags = (u_long)llFlags;
	
	BOOL isNotify = flags & MESSAGE_FLAG_SMS_NOTIFY;
	
	if ((flags & MESSAGE_FLAG_SMS_NOTIFY) || (flags & MESSAGE_FLAG_SMS)) {
		// значит, пришло уведомление СМС или СМС-ответ
		NSLog(@"mrim.processOfflineMessagePacket - it is SMS");
		isSMS = YES;
	}
	
	// загоняем текст в NSString
	NSMutableString *message = [NSMutableString string];
	currentLine = blankParagraphIndex + 1;
	while (currentLine < [lines count])
	{
		[message appendFormat:@"%@\n", [lines objectAtIndex:currentLine]];
		currentLine++;
	}
	NSString *offlineMessageText = [message substringToIndex:([message length]-1)];
	
	//NSLog(@"offline mess: \n'%@'", offlineMessageText);

	// удаляем сообщение с сервера
	NSMutableData *delOfflineMesPacket = [NSMutableData data];
	[delOfflineMesPacket appendBytes:&messID1 length:sizeof(u_long)];
	[delOfflineMesPacket appendBytes:&messID2 length:sizeof(u_long)];
	// вставляем ID сообщения
	
	NSData *packet = [self generatePacketWithMessage:MRIM_DELETE_OFFLINE_MESSAGE 
											sequence:++currentTag 
									  additionalData:delOfflineMesPacket];
	[socket writeData:packet withTimeout:-1 tag:++currentTag];
			
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setFormatterBehavior:NSDateFormatterBehavior10_4];
	NSLocale *enLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en-EN"] autorelease];
	[df setLocale:enLocale];
	[df setDateFormat:@"EEE, d MMM yyyy HH:mm:ss"];
	
	NSString *strDate = [headers objectForKey:@"Date"];
	NSDate *date = [df dateFromString:strDate];
	NSString *phoneNumber = [NSString stringWithFormat:@"+%@", [headers objectForKey:@"From"]];
	
	NSDictionary *messageInfo = [NSDictionary dictionaryWithObjectsAndKeys:offlineMessageText, BFKeyMessageText,
								 phoneNumber, BFKeyMessageSender, 
								 date, BFKeyMessageDate, 
								 [NSNumber numberWithBool:isSMS], BFKeyMessageSMS, 
								 [NSNumber numberWithBool:isNotify], BFKeyMessageNotify,
								 BFKeyMessageOffline, BFKeyMessageStatus, nil];
	[delegate mrimObject:self didReceiveMessage:messageInfo];
}

- (void)processSMSDeliveryPacket:(NSData *)data {
	mrim_header header = [self getPacketHeaderFromData:data];
	u_long sms_status;
	[data getBytes:&sms_status range:NSMakeRange(sizeof(u_long)*11, sizeof(u_long))];
	
	u_long messageKey = header.seq;
	NSString *key = [self keyForTag:messageKey];
	
	if (sms_status == SMS_ACK_DELIVERY_STATUS_SUCCESS) {
		[packetStatuses setObject:BFKeyMessageResultSuccess forKey:key];
		NSLog(@"packetStatuses for %d: success", messageKey);
	} else {
		[packetStatuses setObject:BFKeyMessageResultFailed forKey:key];
		NSLog(@"packetStatuses for %d: failed", messageKey);
	}
}

- (void)processLogoutPacket:(NSData *)data {
	[delegate mrimObjectDidReceiveLogoutPacket:self];
	[socket disconnect];
	[pingTimer invalidate];
	[pingTimer release];
	pingTimer = nil;
}

#pragma mark -
#pragma mark AsyncSocket delegate methods

#pragma mark Connecting

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	NSLog(@"didConnectToHost: %@", host);
	[delegate mrimObject:self didConnectToHost:host];
}

#pragma mark Disconnecting
- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
	NSLog(@"onSocketDidDisconnect");
	[delegate mrimObjectDidDisconnect:self];
	[pingTimer invalidate];
	[pingTimer release];
	pingTimer = nil;
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
	NSLog(@"onSocketWillDisconnectWithError: %d", [err code]);
	[socket unreadData];
	// для очистки очередей
	[delegate mrimObject:self willDisconnectWithError:err];
}

#pragma mark Reading and Writing

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
	NSLog(@"onSocketDidReadData tag %d", tag);
	SEL selectorToPassTheData = nil;
	NSString *selectorName = [operations objectForKey:[self keyForTag:tag]];
	if (selectorName != nil) {
		selectorToPassTheData = sel_registerName([selectorName UTF8String]);
	}
	else {
		selectorToPassTheData = @selector(processData:);
	}

	[self performSelector:selectorToPassTheData withObject:data afterDelay:0.0];
		
	NSLog(@"onSocketDidReadData tag %d complete", tag);
}

-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
	NSLog(@"onSocketDidWriteDataWithTag: %d", tag);
}

@end


//-(u_long)addPhoneContact:(NSString *)number
//{
//	u_long flags = CONTACT_FLAG_SMS;
//	u_long group = 0x67;
//	
//	NSString *type = @"phone";
//	u_long typeLen = [type length];
//	
//	u_long numberLen = [number length]; // x2
//	u_long unused = 0;
//	
//	NSMutableData *packetData = [[NSMutableData alloc] init];
//	
//	[packetData appendBytes:&flags length:sizeof(u_long)];
//	[packetData appendBytes:&group length:sizeof(u_long)];
//	
//	[packetData appendBytes:&typeLen length:sizeof(u_long)];
//	[packetData appendBytes:[type cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:typeLen];
//	
//	[packetData appendBytes:&numberLen length:sizeof(u_long)];
//	[packetData appendBytes:[number cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:numberLen];
//	
//	[packetData appendBytes:&numberLen length:sizeof(u_long)];
//	[packetData appendBytes:[number cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:numberLen];
//	
//	[packetData appendBytes:&unused length:sizeof(u_long)];
//	
//	NSData *packet = [self generatePacketWithMessage:MRIM_CS_ADD_CONTACT 
//											sequence:99
//									  additionalData:packetData];
//	
//	[socket writeData:packet];
//	NSLog(@"mrim.addPhoneContact: didWriteData, wait for response");
//	
//	NSMutableData *respond;
//	mrim_packet_header_t packetHeader;
//	
//	while (packetHeader.msg != MRIM_CS_ADD_CONTACT_ACK) {
//		respond = [NSMutableData data];
//		[socket readData:respond];
//		packetHeader = [self getPacketHeaderFromData:respond];
//	}
//	// ждем уведомления
//	
//	NSLog(@"mrimAddPhoneContact: MRIM_CS_ADD_CONTACT_ACK");
//	u_long operationFlag = 0, contactID = 0;
//	@try {
//		[respond getBytes:&operationFlag 
//					range:NSMakeRange(sizeof(u_long)*11, sizeof(u_long))];
//		
//		[respond getBytes:&contactID	 
//					range:NSMakeRange(sizeof(u_long)*12, sizeof(u_long))];
//		
//		NSLog(@"mrim.addPhoneContact: operationFlag = %d, cID = %d", operationFlag, contactID);
//	}
//	@catch (NSException * e) {
//		NSLog(@"mrim.addPhoneContact: error parsing data, dlen = %d", packetHeader.dlen);
//	}
//	
//	if (operationFlag == CONTACT_OPER_INVALID_INFO)
//	{
//		NSLog(@"mrim.addPhoneContact: CONTACT_OPER_INVALID_INFO -> error adding sms contact");
//		return -1;
//	}
//	NSLog(@"mrimAddPhoneContact: Normal CONTACT_OPER -> ok, cID = %d", contactID);
//	return contactID;
//}
//
//-(BOOL)removePhoneContact:(u_long)contactID number:(NSString *)number
//{
//	u_long flags = CONTACT_FLAG_SMS | CONTACT_FLAG_REMOVED;
//	u_long group = 0x67;
//	
//	NSString *tip = @"phone";
//	u_long tipLen = [tip length];
//	
//	u_long numberLen = [number length]; // x2
//	
//	NSMutableData *packetData = [[NSMutableData alloc] init];
//	
//	[packetData appendBytes:&contactID length:sizeof(u_long)];
//	[packetData appendBytes:&flags length:sizeof(u_long)];
//	[packetData appendBytes:&group length:sizeof(u_long)];
//	
//	[packetData appendBytes:&tipLen length:sizeof(u_long)];
//	[packetData appendBytes:[tip cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:tipLen];
//	
//	[packetData appendBytes:&numberLen length:sizeof(u_long)];
//	[packetData appendBytes:[number cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:numberLen];
//	
//	[packetData appendBytes:&numberLen length:sizeof(u_long)];
//	[packetData appendBytes:[number cStringUsingEncoding:NSWindowsCP1251StringEncoding] length:numberLen];
//	
//	
//	NSData *packet = [self generatePacketWithMessage:MRIM_CS_MODIFY_CONTACT 
//											sequence:187
//									  additionalData:packetData];
//	
//	[socket writeData:packet];
//	
//	NSMutableData *respond;
//	mrim_packet_header_t packetHeader;
//	
//	while (packetHeader.msg != MRIM_CS_MODIFY_CONTACT_ACK) {
//		respond = [NSMutableData data];
//		[socket readData:respond];
//		packetHeader = [self getPacketHeaderFromData:respond];
//	}
//	// ждем уведомления
//	NSLog(@"mrim.removePhoneContact: MRIM_CS_MODIFY_CONTACT_ACK");
//	
//	
//	u_long operationFlag;
//	[respond getBytes:&operationFlag range:NSMakeRange(sizeof(u_long)*11, sizeof(u_long))];
//	NSLog(@"mrim.removePhoneContact: operationFlag = %d\n", operationFlag);
//	
//	if (operationFlag == CONTACT_OPER_SUCCESS)
//	{
//		NSLog(@"mrim.removePhoneContact: CONTACT_OPER_SUCCESS -> ok...");
//		return YES;
//	}
//	NSLog(@"mrim.removePhoneContact: error");
//	return NO;
//}

