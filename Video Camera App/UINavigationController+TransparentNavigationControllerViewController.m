//
//  UINavigationController+TransparentNavigationControllerViewController.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "UINavigationController+TransparentNavigationControllerViewController.h"

@implementation UINavigationController (TransparentNavigationController)

-(void) presentTransparentNavigationBar
{
    [self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
}

-(void) hideTransparentNavigationBar
{
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setTranslucent:YES];
    self.navigationBar.shadowImage = [UIImage new];
}

@end
