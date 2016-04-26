//
//  VideoCollectionViewCell.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "VideoCollectionViewCell.h"

@implementation VideoCollectionViewCell

-(instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"VideoCollectionViewCell" owner:self options:nil];
        if (arrayOfViews.count < 1) {
            return nil;
        } else if ([arrayOfViews[0] isKindOfClass:[VideoCollectionViewCell class]]){
            self = arrayOfViews[0];
        } else {
            return nil;
        }
    }
    return self;
}
@end
