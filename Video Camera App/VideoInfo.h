//
//  VideoInfo.h
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VideoInfo : NSObject
@property (strong, nonatomic) NSString *filePath;
@property (nonatomic) int fps;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) UIImage *thumbnailImage;
@property (strong, nonatomic) NSString *duration;
@end
