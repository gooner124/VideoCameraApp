//
//  VideoMO+CoreDataProperties.h
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "VideoMO.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoMO (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *attribute;
@property (nullable, nonatomic, retain) NSString *filepath;
@property (nullable, nonatomic, retain) NSString *fps;
@property (nullable, nonatomic, retain) NSData *image;
@property (nullable, nonatomic, retain) NSString *length;

@end

NS_ASSUME_NONNULL_END
