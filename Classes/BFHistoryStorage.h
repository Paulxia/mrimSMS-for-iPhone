//
//  BFHistoryStorage.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 13.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const MRIMDidChangeHistoryNotification;

@interface BFHistoryStorage : NSObject {
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (BFHistoryStorage *)sharedStorage;
- (void)saveChanges;
- (NSString *)applicationDocumentsDirectory;


- (void)insertToHistoryNumber:(NSString *)number 
					  message:(NSString *)message 
					   atDate:(NSDate *)date 
					   income:(BOOL)income 
					   unread:(BOOL)unread;

- (NSArray *)completeHistory;

- (NSArray *)historyPhoneNumbers;
- (NSInteger)numberOfMessagesForPhoneNumber:(NSString *)phoneNumber;
- (NSArray *)completeHistoryForPhoneNumber:(NSString *)phoneNumber;

- (NSInteger)numberOfUnreadMessages;

- (void)deleteHistoryObject:(NSManagedObject *)object;

@end
