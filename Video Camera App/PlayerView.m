//
//  PlayerView.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "PlayerView.h"

@implementation PlayerView

-(AVPlayer*) player
{
    return self.playerLayer.player;
}

-(void) setPlayer:(AVPlayer *)player
{
    self.playerLayer.player = player;
}

+(Class) layerClass
{
    return [AVPlayerLayer class];
}

-(AVPlayerLayer*) playerLayer
{
    return (AVPlayerLayer*) self.layer;
}

@end
