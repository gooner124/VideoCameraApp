//
//  VideoPlayerViewController.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "PlayerView.h"
#import "UINavigationController+TransparentNavigationControllerViewController.h"

@interface VideoPlayerViewController()
{
    AVPlayer *_player;
    AVURLAsset *_asset;
    id<NSObject> _timeObserverToken;
    AVPlayerItem *_playerItem;
}

//InterfaceBuilder properties
@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLowerLimit;
@property (weak, nonatomic) IBOutlet UILabel *fpsUpperLimit;
@property (weak, nonatomic) IBOutlet UISlider *fpsSlider;

//Other properties
@property AVPlayerItem *playerItem;
@property (readonly) AVPlayerLayer *playerLayer;

@end


@implementation VideoPlayerViewController

static int PlayerViewControllerKVOContext = 0;


-(void) viewDidLoad
{
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self addObservers];
    
    [self loadVideo];
}

-(void) loadVideo
{
    self.playerView.playerLayer.player = self.player;
    
    NSURL *movieURL = [NSURL fileURLWithPath:self.currentVideo.filePath];
    
    self.asset = [AVURLAsset assetWithURL:movieURL];
    
    float playbackSpeed = 30.0 /(float)self.currentVideo.fps;
    if (playbackSpeed < .9) {
        self.fpsLowerLimit.text = @"0.50";
        self.fpsSlider.minimumValue = .5;
    } else{
        self.fpsLowerLimit.text = @"1.00";
        self.fpsSlider.minimumValue = 1;
    }
    
    [self.fpsSlider setValue:1.0 animated:YES];
    
    VideoPlayerViewController __weak *weakSelf = self;
    _timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        weakSelf.timeSlider.value = CMTimeGetSeconds(time);
    }];
    
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_timeObserverToken) {
        [self.player removeTimeObserver:_timeObserverToken];
        _timeObserverToken = nil;
    }
    [self.player pause];
    
    [self removeObservers];
}

+(NSArray*) assetKeysRequiredToPlay
{
    return @[@"playable", @"hasProtectedContent"];
}

-(AVPlayer*) player
{
    if (!_player) {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}

-(CMTime) currentTime
{
    return self.player.currentTime;
}

-(void) setCurrentTime:(CMTime)currentTime
{
    [self.player seekToTime:currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

-(CMTime) duration
{
    return self.player.currentItem ? self.player.currentItem.duration : kCMTimeZero;
}

-(float) rate
{
    return self.player.rate;
}

-(void) setRate:(float)rate
{
    self.player.rate = rate;
}

-(AVPlayerLayer*) playerLayer
{
    return self.playerView.playerLayer;
}


-(AVPlayerItem*) playerItem
{
    return _playerItem;
}

-(void) setPlayerItem:(AVPlayerItem *)playerItem
{
    if (_playerItem != playerItem) {
        _playerItem = playerItem;
        [self.player replaceCurrentItemWithPlayerItem:_playerItem];
    }
}


#pragma mark - Asset loading
-(void) asynchronouslyLoadURLAsset:(AVURLAsset*) newAsset
{
    [newAsset loadValuesAsynchronouslyForKeys:[VideoPlayerViewController assetKeysRequiredToPlay] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (newAsset != self.asset) {
                return;
            }
            for (NSString *key in self.class.assetKeysRequiredToPlay){
                NSError *error = nil;
                
                if ([newAsset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                    NSString *message = [NSString localizedStringWithFormat: NSLocalizedString(@"error.asset_key_%@_failed.description", @"Can't use this AVAsset because one of it's keys failed to load"), key];
                    
                    [self handleErrorWithMessage:message error:error];
                    return;
                }
            }
            
            if (!newAsset.playable || newAsset.hasProtectedContent) {
                NSString *message = NSLocalizedString(@"error.asset_not_playable.description", @"Cannot use this AvAsset because it isn't playable or it has protected content");
                
                [self handleErrorWithMessage:message error:nil];
                return;
            }
            
            self.playerItem = [AVPlayerItem playerItemWithAsset:newAsset];
        });
    }];
}



#pragma mark - actions
- (IBAction)goToPreviousVideo:(id)sender
{
    NSUInteger currentIndex = [self.videoList indexOfObject:self.currentVideo];
    if (currentIndex == 0) {
        currentIndex = self.videoList.count - 1;
    } else{
        currentIndex--;
    }
    self.currentVideo = [self.videoList objectAtIndex:currentIndex];
    
    [self loadVideo];
    
}

- (IBAction)goToNextVideo:(id)sender
{
    NSUInteger currentIndex = [self.videoList indexOfObject:self.currentVideo];
    if (currentIndex == self.videoList.count - 1) {
        currentIndex = 0;
    } else{
        currentIndex++;
    }
    self.currentVideo = [self.videoList objectAtIndex:currentIndex];
    
    [self loadVideo];
}

- (IBAction)playVideo:(id)sender
{
    if (self.player.rate == 0) {
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)) {
            self.currentTime = kCMTimeZero;
        }
        [self.navigationController hideTransparentNavigationBar];
        [self.player play];
        self.player.rate = self.fpsSlider.value;
    } else {
        [self.navigationController presentTransparentNavigationBar];
        [self.player pause];
    }
}

- (IBAction)sliderDidChange:(UISlider *)sender
{
    self.currentTime = CMTimeMakeWithSeconds(sender.value, 1000);
}


- (IBAction)fpsSliderChange:(UISlider *)sender
{
    self.player.rate = sender.value;
}

#pragma mark - KVO observe methods
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context != &PlayerViewControllerKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"asset"]) {
        if (self.asset) {
            [self asynchronouslyLoadURLAsset:self.asset];
        }
        
    } else if ([keyPath isEqualToString:@"player.currentItem.duration"]){
        NSValue *newDurationAsValue = change[NSKeyValueChangeNewKey];
        CMTime newDuration = [newDurationAsValue isKindOfClass:[NSValue class]] ? newDurationAsValue.CMTimeValue : kCMTimeZero;
        BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) &&newDuration.value != 0;
        double newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0;
        
        self.timeSlider.maximumValue = newDurationSeconds;
        self.timeSlider.value = hasValidDuration ? CMTimeGetSeconds(self.currentTime) : 0.0;
        self.playButton.enabled = hasValidDuration;
        self.timeSlider.enabled = hasValidDuration;
        self.durationLabel.enabled = hasValidDuration;
        int wholeMinutes = (int) trunc(newDurationSeconds / 60);
        self.durationLabel.text = [NSString stringWithFormat:@"%d:%02d", wholeMinutes, (int)trunc(newDurationSeconds) - wholeMinutes * 60];
        
    }else if ([keyPath isEqualToString: @"player.rate"]){
        double newRate = [change[NSKeyValueChangeNewKey] doubleValue];
        UIImage *buttonImage = (newRate != 0) ? [UIImage imageNamed:@"pause.jpg"] : [UIImage imageNamed:@"play.jpg"];
        [self.playButton setImage:buttonImage forState:UIControlStateNormal];
        
    } else if ([keyPath isEqualToString:@"player.currentItem.status"]){
        NSNumber *newStatusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusAsNumber isKindOfClass: [NSNumber class]] ? newStatusAsNumber.integerValue : AVPlayerItemStatusUnknown;
        
        if (newStatus == AVPlayerItemStatusFailed) {
            [self handleErrorWithMessage:self.player.currentItem.error.localizedDescription error:self.player.currentItem.error];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void) handleErrorWithMessage:(NSString*)message error:(NSError*) error
{
    NSLog(@"Error occured with message: %@, error: %@", message, error);
    NSString *alertTitle = NSLocalizedString(@"alert.error.title", @"Alert title for errors");
    NSString *defaultAlertMessage = NSLocalizedString(@"error.default.description", @"Default error message when no NSError provided");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:message ? : defaultAlertMessage preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *alertActionTitle = NSLocalizedString(@"alert.error.actions.OK", @"OK on error alert");
    UIAlertAction *action = [UIAlertAction actionWithTitle:alertActionTitle style:UIAlertActionStyleDefault handler:nil];
    
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - KVO methods
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString*) key
{
    if ([key isEqualToString:@"duration"]) {
        return [NSSet setWithArray:@[@"player.currentItem.duration"]];
    } else if ([key isEqualToString:@"currentTime"]){
        return [NSSet setWithArray:@[@"player.currentItem.currentTime"]];
    } else if ([key isEqualToString:@"rate"]){
        return [NSSet setWithArray:@[@"player.rate"]];
    } else {
        return [super keyPathsForValuesAffectingValueForKey:key];
    }
}



-(void) addObservers
{
    [self addObserver:self forKeyPath:@"asset" options:NSKeyValueObservingOptionNew context:&PlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&PlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&PlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&PlayerViewControllerKVOContext];
}

-(void) removeObservers
{
    [self removeObserver:self forKeyPath:@"asset" context:&PlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:&PlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.rate" context:&PlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:&PlayerViewControllerKVOContext];
}

@end
