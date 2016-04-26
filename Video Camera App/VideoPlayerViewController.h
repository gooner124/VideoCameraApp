//
//  VideoPlayerViewController.h
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoInfo.h"

@interface VideoPlayerViewController : UIViewController
@property (readonly) AVPlayer *player;
@property AVURLAsset *asset;
@property CMTime currentTime;
@property (readonly) CMTime duration;
@property float rate;
@property (strong, nonatomic) VideoInfo *currentVideo;
@property (strong, nonatomic) NSMutableArray *videoList;

@end
