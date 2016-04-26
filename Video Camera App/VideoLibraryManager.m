//
//  VideoLibraryManager.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "VideoLibraryManager.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "PersistenceController.h"
#import <UIKit/UIKit.h>

@implementation VideoLibraryManager

#pragma mark - Camera to Video Directory Methods

-(void) moveNewVideoToVideoDirectory:(NSURL*)outputFileURL
{
    NSString *videoDirectoryPath = [self pathForDocumentsDirectory];
    
    NSString *videoName = outputFileURL.lastPathComponent;
    NSLog(@"\nVideo Name: %@", videoName);
    NSString *videoFilePath = [videoDirectoryPath stringByAppendingPathComponent:videoName];
    NSURL *videoFileURL = [NSURL fileURLWithPath:videoFilePath];
    
    NSError *error;
    
    if (error) {
        NSLog(@"Error writing video file, %@\n%@",error.localizedDescription, error.userInfo);
    }
    
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:videoDirectoryPath]) {
        if (![fileManager moveItemAtURL:outputFileURL toURL:videoFileURL error:&error]) {
            if (error) {
                NSLog(@"unable to copy video to video directory, %@ \n %@", error.localizedDescription, error.userInfo);
            }
        }
    }
}

-(NSString*) pathForDocumentsDirectory
{
    NSError *error;
    NSString *directoryPath = (NSString*)[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject.path;
    NSString *videoDirectoryPath = [directoryPath stringByAppendingPathComponent:@"VideoCameraApp Videos"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:videoDirectoryPath]) {
        if (![fileManager createDirectoryAtPath:videoDirectoryPath withIntermediateDirectories:NO attributes:nil error:&error]) {
            if (error) {
                NSLog(@"Error creating video directory, %@\n%@", error.localizedDescription, error.userInfo);
            }
        }
        
    }
    return videoDirectoryPath;
}


#pragma mark - Managing Video Managed Objects // VideosURLs

-(NSMutableArray*) getVideoObjects
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *videoDirectoryPath = [self pathForDocumentsDirectory];
    
    NSError *error;
    NSArray *videoPathList = [fileManager contentsOfDirectoryAtPath:videoDirectoryPath error:&error];
    
    NSMutableArray *videoList = [NSMutableArray new];
    
    if (error) {
        NSLog(@"Error getting videos in VideoDirectory: %@\n%@", error.localizedDescription, error.userInfo);
    } else {
        for (NSString *fileName in videoPathList) {
            if (![fileName.pathExtension isEqualToString:@"mov"]) {
                continue;
            }
            VideoInfo *newVideo = [[VideoInfo alloc] init];
//            NSString *newFileName = [NSString new];
//            newFileName = [fileName stringByReplacingOccurrencesOfString:@"video" withString:@""];
            newVideo.name = fileName;
            NSString *filePath = [videoDirectoryPath stringByAppendingPathComponent:fileName];
            newVideo.filePath = filePath;
            
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            
            AVAsset *videoAsset = [AVAsset assetWithURL:fileURL];
            
            NSUInteger totalSeconds = CMTimeGetSeconds(videoAsset.duration);
            NSUInteger hours = totalSeconds/3600;
            NSUInteger minutes = totalSeconds % 3600 / 60;
            NSUInteger seconds = totalSeconds % 3600 % 60 % 60;
            newVideo.duration = [NSString stringWithFormat:@"%02lu:%02lu:%02lu",(unsigned long)hours, (unsigned long)minutes, (unsigned long)seconds];
            
            AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] lastObject];
            if (videoTrack) {
                float fps = videoTrack.nominalFrameRate;
                int intFPS = 0;
                if (fps > 110) {
                    intFPS = 120;
                } else if (fps > 50){
                    intFPS = 60;
                } else{
                    intFPS = 30;
                }
                newVideo.fps = intFPS;
            }
            
            AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:videoAsset];
            imageGenerator.appliesPreferredTrackTransform = YES;
            if (imageGenerator) {
                CMTime time = CMTimeMake(0, 60);
                CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:nil error:&error];
                UIImage *thumbnailImage = [UIImage imageWithCGImage: imageRef];
                newVideo.thumbnailImage = thumbnailImage;
            }
            [videoList addObject: newVideo];
        }
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSMutableArray *orderedVideoList = [NSMutableArray arrayWithArray:[videoList sortedArrayUsingDescriptors:@[sortDescriptor]]];
    return orderedVideoList;
}

#pragma mark get FPS Set from Video List
-(NSArray*) getFPSSetFromVideoList:(NSMutableArray*) videoList
{
    NSMutableArray *fpsOfVideos = [NSMutableArray new];
    
    for (VideoInfo *video in videoList){
        [fpsOfVideos addObject:[NSNumber numberWithInt:video.fps]];
    }
    NSMutableSet *fpsList = [NSMutableSet setWithArray:fpsOfVideos];
    
    NSArray *fpss = [fpsList sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
    return fpss;
}


#pragma mark Delete Video
-(void) deleteVideo:(VideoInfo *)video
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error;
    if ([fileManager removeItemAtPath:video.filePath error:&error]) {
        if (error) {
            NSLog(@"Error removing video: %@\n%@", error.localizedDescription, error.userInfo);
        }
    }
}

@end
