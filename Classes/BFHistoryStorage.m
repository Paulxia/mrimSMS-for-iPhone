//
//  BFHistoryStorage.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 13.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import "BFHistoryStorage.h"

@implementation BFHistoryStorage

NSString *const MRIMDidChangeHistoryNotification = @"MRIMDidChangeHistoryNotification";

static BFHistoryStorage *sharedStorage = nil;

+ (BFHistoryStorage *)sharedStorage {
    if (sharedStorage == nil) {
        sharedStorage = [[super allocWithZone:NULL] init];
    }
    return sharedStorage;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedStorage] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release {
    
}

- (void)dealloc {
	[managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
	
	[super dealloc];
}

- (id)autorelease {
    return self;
}

#pragma mark -
#pragma mark Core Data stack

- (void)saveChanges {
	NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			NSLog(@"saveChanges:  Unresolved error %@, %@", error, [error userInfo]);
			abort();
        } 
    }
}

- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"mrimSMSmobile.sqlite"]];
	
	NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil 
															URL:storeUrl 
														options:nil 
														  error:&error]) {
		
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }    
	
    return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's Documents directory

- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark -
#pragma mark Storage 


- (void)insertToHistoryNumber:(NSString *)number 
					  message:(NSString *)message 
					   atDate:(NSDate *)date 
					   income:(BOOL)income 
					   unread:(BOOL)unread {
	NSLog(@"insertToHistory...");

	NSManagedObjectContext *context = [self managedObjectContext];
	NSManagedObject *newHistoryObject = [NSEntityDescription insertNewObjectForEntityForName:@"SMSHistory" 
																	  inManagedObjectContext:context];
	
	[newHistoryObject setValue:date forKey:@"date"];
	[newHistoryObject setValue:number forKey:@"phoneNumber"];
	[newHistoryObject setValue:message forKey:@"message"];
	[newHistoryObject setValue:[NSNumber numberWithBool:income] forKey:@"income"];
	[newHistoryObject setValue:[NSNumber numberWithBool:unread] forKey:@"unread"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MRIMDidChangeHistoryNotification object:nil];
	
	[self saveChanges];
}


- (NSArray *)completeHistory {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SMSHistory" 
											  inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	[fetchRequest setFetchBatchSize:20];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	NSError *error = nil;
	NSArray *array = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	
	if (error != nil) {
		NSLog(@"Error fetching completeHistory");
		return nil;
	}
	
	return array;
}

- (NSArray *)historyPhoneNumbers {
	NSManagedObjectContext *context = [self managedObjectContext];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SMSHistory" inManagedObjectContext:context];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	[request setResultType:NSManagedObjectResultType];
	[request setReturnsDistinctResults:YES];
	[request setPropertiesToFetch:[NSArray arrayWithObject:@"phoneNumber"]];
	
	NSError *error = nil;
	//id requestedValue = nil;
	NSArray *objects = [managedObjectContext executeFetchRequest:request error:&error];
	if (objects == nil) {
		// Handle the error.
	}
	NSArray *uniquePhones = [objects valueForKeyPath:@"@distinctUnionOfObjects.phoneNumber"];
	return uniquePhones;
}

- (NSInteger)numberOfMessagesForPhoneNumber:(NSString *)phoneNumber {
	NSManagedObjectContext *context = [self managedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SMSHistory" inManagedObjectContext:context];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	[request setEntity:entity];
	[request setResultType:NSDictionaryResultType];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"phoneNumber == %@", phoneNumber];
	[request setPredicate:predicate];
	
	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"message"];
	NSExpression *countExpression = [NSExpression expressionForFunction:@"count:"
															  arguments:[NSArray arrayWithObject:keyPathExpression]];
	
	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:@"count"];
	[expressionDescription setExpression:countExpression];
	[expressionDescription setExpressionResultType:NSInteger16AttributeType];
	
	[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	NSInteger number = 0;
	
	NSError *error = nil;
	NSArray *objects = [managedObjectContext executeFetchRequest:request error:&error];
	if (objects != nil) {
		if ([objects count] > 0) {
			NSNumber *numberOfMessages = [[objects objectAtIndex:0] valueForKey:@"count"];
			number = [numberOfMessages intValue];
		}
	}
	
	[request release];
	[expressionDescription release];
	
	return number;
}

- (NSArray *)completeHistoryForPhoneNumber:(NSString *)phoneNumber {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	if (phoneNumber != nil) {
		NSPredicate *phonePredicate = [NSPredicate predicateWithFormat:@"phoneNumber == %@", phoneNumber];
		[fetchRequest setPredicate:phonePredicate];
	}

	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SMSHistory" 
											  inManagedObjectContext:[self managedObjectContext]];
	[fetchRequest setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	[fetchRequest setFetchBatchSize:20];
	
	NSError *error = nil;
	NSArray *array = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	
	if (error != nil) {
		NSLog(@"Error fetching completeHistory");
		return nil;
	}
	
	return array;
}

- (NSInteger)numberOfUnreadMessages {
	NSManagedObjectContext *context = [self managedObjectContext];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"SMSHistory" inManagedObjectContext:context];
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	[request setEntity:entity];
	[request setResultType:NSDictionaryResultType];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unread == YES"];
	[request setPredicate:predicate];
	
	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"message"];
	NSExpression *countExpression = [NSExpression expressionForFunction:@"count:"
															  arguments:[NSArray arrayWithObject:keyPathExpression]];
	
	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:@"count"];
	[expressionDescription setExpression:countExpression];
	[expressionDescription setExpressionResultType:NSInteger16AttributeType];
	
	[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	NSInteger number = 0;
	
	NSError *error = nil;
	NSArray *objects = [managedObjectContext executeFetchRequest:request error:&error];
	if (objects != nil) {
		if ([objects count] > 0) {
			NSNumber *numberOfMessages = [[objects objectAtIndex:0] valueForKey:@"count"];
			number = [numberOfMessages intValue];
		}
	}
	
	[request release];
	[expressionDescription release];
	
	return number;
}

- (void)deleteHistoryObject:(NSManagedObject *)object {
	[[self managedObjectContext] deleteObject:object];
	[[NSNotificationCenter defaultCenter] postNotificationName:MRIMDidChangeHistoryNotification object:nil];
}

@end
