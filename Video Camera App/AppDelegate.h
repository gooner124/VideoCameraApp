//
//  AppDelegate.h
//  Video Camera App
//
//  Created by Matthew Paravati on 3/2/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PersistenceController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) PersistenceController *persistenceController;


@end

