//
//  PersistenceController.h
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef void (^InitCallbackBlock)(void);

@interface PersistenceController : NSObject
@property (strong, readonly) NSManagedObjectContext *managedObjectContext;
-(id)initWithCallback:(InitCallbackBlock)callback;
-(void) save;

@end
