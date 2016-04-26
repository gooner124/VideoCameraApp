//
//  VideoViewController.h
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PersistenceController.h"

@interface VideoViewController : UIViewController
@property (strong, nonatomic) PersistenceController *persistenceController;

@end
