//
//  PreviewView.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/7/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "PreviewView.h"

@import AVFoundation;

@implementation PreviewView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    return previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.session = session;
}

@end
