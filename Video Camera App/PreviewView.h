//
//  PreviewView.h
//  Video Camera App
//
//  Created by Matthew Paravati on 3/7/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface PreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
