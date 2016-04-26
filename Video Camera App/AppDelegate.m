//
//  AppDelegate.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/2/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "AppDelegate.h"
#import "VideoViewController.h"

@interface AppDelegate ()
@property (strong, readwrite) PersistenceController *persistenceController;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        
    
    UINavigationController *navController = (UINavigationController*)self.window.rootViewController;
    VideoViewController *videoViewController = (VideoViewController*)navController.topViewController;
    videoViewController.persistenceController = self.persistenceController;
    
    // Override point for customization after application launch.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self.persistenceController save];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self.persistenceController save];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self.persistenceController save];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [self.persistenceController save];
    
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
@end
