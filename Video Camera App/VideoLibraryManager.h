//
//  VideoLibraryManager.h
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoMO.h"
#import "PersistenceController.h"
#import "VideoInfo.h"


@interface VideoLibraryManager : NSObject
@property (strong, nonatomic) PersistenceController *persistenceController;
-(void) moveNewVideoToVideoDirectory:(NSURL*)outputFileURL;
-(NSArray*) getFPSSetFromVideoList:(NSMutableArray*) videoList;
-(NSMutableArray*) getVideoObjects;
-(void) deleteVideo:(VideoInfo *)video;

@end
