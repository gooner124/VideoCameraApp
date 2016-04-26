//
//  PersistenceController.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "PersistenceController.h"

@interface PersistenceController()
@property (strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong) NSManagedObjectContext *privateContext;
@property (copy) InitCallbackBlock initCallback;

@end


@implementation PersistenceController


#pragma mark - CoreData Methods

-(instancetype) initWithCallback:(InitCallbackBlock)callback
{
    if (!(self = [super init])) {
        return nil;
    }
    self.initCallback = callback;
    [self initializeCoreData];
    return self;
}



-(void) initializeCoreData
{
    if (self.managedObjectContext) {
        return;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc]initWithContentsOfURL:modelURL];
    NSAssert(mom, @"%@: %@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:mom];
    NSAssert(coordinator, @"Failed to initialize coordinator");
    self.managedObjectContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.privateContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];
    self.privateContext.persistentStoreCoordinator = coordinator;
    self.managedObjectContext.parentContext = self.privateContext;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSPersistentStoreCoordinator *psc = self.privateContext.persistentStoreCoordinator;
        NSMutableDictionary *options = [NSMutableDictionary new];
        options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
        options[NSInferMappingModelAutomaticallyOption] = @YES;
        options[NSSQLitePragmasOption] = @{@"journal_mode":@"DELETE"};
        NSError *error;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"Model.sqlite"];
        NSAssert([psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error], @"Error initializing PSC, %@, %@", error.localizedDescription, error.userInfo);
        
        if (!self.initCallback){
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initCallback]();
        });
    });
}


-(void)save
{
    if (!self.privateContext.hasChanges && !self.managedObjectContext.hasChanges) {
        return;
    }
    
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        
        NSAssert([self.managedObjectContext save:&error], @"Failed to save main context, %@, %@", error.localizedDescription, error.userInfo);
        
        [self.privateContext performBlock:^{
            NSError *privateError;
            NSAssert([self.privateContext save:&privateError], @"Error saving private context, %@ \n%@", privateError.localizedDescription, privateError.userInfo);
            if (!privateError) {
                NSLog(@"Data SaveD!");
            }
        }];
    }];
}
@end
