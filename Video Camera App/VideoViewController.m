//
//  VideoViewController.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

@import AVFoundation;
@import Photos;

#import "VideoViewController.h"
#import "PreviewView.h"
#import "VideoLibraryManager.h"
#import "VideoCollectionViewController.h"
#import "UINavigationController+TransparentNavigationControllerViewController.h"

static void * sessionRunningContext = &sessionRunningContext;

typedef NS_ENUM(NSInteger, SloMoCamSetupResult){
    SloMoCamSetupResultSuccess,
    SloMoCamSetupResultCameraNotAuthorized,
    SloMoCamSetupResultSessionConfigurationFailed
};

@interface VideoViewController () <AVCaptureFileOutputRecordingDelegate>

//Storyboard properties
@property (weak, nonatomic) IBOutlet PreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *resumeRecording;
@property (weak, nonatomic) IBOutlet UISegmentedControl *fpsSegControl;
@property (weak, nonatomic) IBOutlet UILabel *cameraUnavailableLabel;
@property (weak, nonatomic) IBOutlet UIButton *libraryButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;


//Session Management properties
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureDeviceFormat *defaultFormat;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *cameraStatus;

//Utilities
@property (nonatomic) SloMoCamSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.defaultFormat = videoDevice.activeFormat;
    [self resetFormat];
    
    self.activityIndicator.hidden = YES;
    
    self.recordButton.enabled = NO;
    self.cameraButton.enabled = NO;
    self.fpsSegControl.enabled = NO;
    
    self.session = [[AVCaptureSession alloc] init];
    self.previewView.session = self.session;
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    self.setupResult = SloMoCamSetupResultSuccess;
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
        {
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (!granted){
                    self.setupResult = SloMoCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
            }];
            break;
        }
        default:
        {
            self.setupResult = SloMoCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult != SloMoCamSetupResultSuccess) {
            return;
        }
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        
        NSError *error = nil;
        AVCaptureDevice *videoDevice = [VideoViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (!videoDeviceInput){
            NSLog(@"Unable to create device input, %@", error);
        }
        
        [self.session beginConfiguration];
        if ([self.session canAddInput:videoDeviceInput]) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
                AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
                if (statusBarOrientation != UIInterfaceOrientationUnknown) {
                    videoOrientation = (AVCaptureVideoOrientation) statusBarOrientation;
                }
                
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer*)self.previewView.layer;
                previewLayer.connection.videoOrientation = videoOrientation;
            });
        } else{
            NSLog(@"Unable to add video device input to the session");
            self.setupResult = SloMoCamSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if (!audioDeviceInput) {
            NSLog(@"Unable to set up audio device input, %@", error);
        }
        
        if ([self.session canAddInput:audioDeviceInput]) {
            [self.session addInput:audioDeviceInput];
        } else{
            NSLog(@"Unable to add audio device input to the session");
        }
        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
        if ([self.session canAddOutput:movieFileOutput]) {
            [self.session addOutput:movieFileOutput];
            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if (connection.isVideoStabilizationSupported) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            self.movieFileOutput = movieFileOutput;
        } else{
            NSLog(@"Unable to add movie file out to the session");
            self.setupResult = SloMoCamSetupResultSessionConfigurationFailed;
        }
        [self.session commitConfiguration];
    });
    // Do any additional setup after loading the view.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
    self.cameraStatus.hidden = YES;
    self.libraryButton.enabled =YES;
    
    [self.navigationController hideTransparentNavigationBar];
    
    dispatch_async(self.sessionQueue, ^{
        switch (self.setupResult) {
            case SloMoCamSetupResultSuccess:
            {
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case SloMoCamSetupResultCameraNotAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString(@"Video Camera App does not have permission to use the camera, please change privacy settings", @"Alert when user has denied access to camera");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Video Camera App" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Go to Settings", @"Alert to open settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:cancelAction];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
            case SloMoCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString(@"Unable to capture media", @"Alert to signify error during capture session configuration");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Video Camera App" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
        }
    });
}

-(void)viewDidDisappear:(BOOL)animated
{
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult == SloMoCamSetupResultSuccess) {
            [self.session stopRunning];
            [self removeObservers];
        }
    });
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Orientation
-(BOOL) shouldAutorotate
{
    return !self.movieFileOutput.isRecording;
}

-(UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) || UIDeviceOrientationIsLandscape(deviceOrientation)) {
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer*) self.previewView.layer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
#pragma mark - NSNotification and KVO methods
-(void) addObservers
{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:sessionRunningContext];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [defaultCenter addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    [defaultCenter addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [defaultCenter addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

-(void) removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.session removeObserver:self forKeyPath:@"running" context:sessionRunningContext];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == sessionRunningContext) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey]boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cameraButton.enabled = isSessionRunning && ([AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1);
            self.recordButton.enabled = isSessionRunning;
            self.fpsSegControl.enabled = isSessionRunning;
        });
    } else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)subjectAreaDidChange:(NSNotification*) notification
{
    CGPoint devicePoint = CGPointMake(0.5, 0.5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

-(void) sessionRuntimeError:(NSNotification*) notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog(@"Capture session runtime error,%@", error);
    
    if (error.code == AVErrorMediaServicesWereReset) {
        dispatch_async(self.sessionQueue, ^{
            if (self.session.isRunning) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            } else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.resumeRecording.hidden = NO;
                });
            }
        });
    } else{
        self.resumeRecording.hidden = NO;
    }
}

-(void) sessionWasInterrupted:(NSNotification*) notification
{
    BOOL showResumeButton = NO;
    if (AVCaptureSessionInterruptionReasonKey) {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey]integerValue];
        NSLog(@"Capture session was interrupted with the reason %ld", (long)reason);
        if (reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient || reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient) {
            showResumeButton = YES;
        } else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps) {
            self.cameraUnavailableLabel.hidden = NO;
            self.cameraUnavailableLabel.alpha = 0;
            [UIView animateWithDuration:.25 animations:^{
                self.cameraUnavailableLabel.alpha = 1.0;
            }];
        }
    } else{
        NSLog(@"Capture session was interrupted");
        showResumeButton = ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive);
    }
    if (showResumeButton){
        self.resumeRecording.hidden = NO;
        self.resumeRecording.alpha = 0;
        [UIView animateWithDuration:.25 animations:^{
            self.resumeRecording.alpha = 1;
        }];
    }
}

-(void) sessionInterruptionEnded:(NSNotification*) notification
{
    NSLog(@"Capture session interruption ended");
    if (!self.resumeRecording.hidden) {
        [UIView animateWithDuration:.25 animations:^{
            self.resumeRecording.alpha = 0;
        } completion:^(BOOL finished) {
            self.resumeRecording.hidden = YES;
        }];
    }
    if (!self.cameraUnavailableLabel.hidden) {
        [UIView animateWithDuration:.25 animations:^{
            self.cameraUnavailableLabel.alpha = 0;
        } completion:^(BOOL finished) {
            self.cameraUnavailableLabel.hidden = YES;
        }];
    }
}

#pragma mark - Actions
- (IBAction)resumeInterruptedSession:(id)sender
{
    dispatch_async(self.sessionQueue, ^{
        [self.session startRunning];
        self.sessionRunning = self.session.isRunning;
        if (!self.session.isRunning) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = NSLocalizedString(@"Unable to resume recording", @"alert when unable to resume session");
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Video Camera App" message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancelAction];
                [self presentViewController:alertController animated:YES completion:nil];
            });
        } else{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.resumeRecording.hidden = YES;
            });
        }
    });
}
- (IBAction)goToLibrary:(id)sender
{
    [self shouldActivateButtons:NO withStatusText:@"Loading Library"];
}

- (IBAction)toggleMovieRecord:(id)sender
{
    self.cameraButton.enabled = NO;
    self.recordButton.enabled = NO;
    self.fpsSegControl.enabled = NO;
    
    dispatch_async(self.sessionQueue, ^{
        if (!self.movieFileOutput.isRecording) {
            if ([UIDevice currentDevice].isMultitaskingSupported) {
                self.backgroundRecordingID = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:nil];
            }
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer*)self.previewView.layer;
            connection.videoOrientation = previewLayer.connection.videoOrientation;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            dateFormatter.dateFormat = @"MM-dd-yyyy HH:mm:ss";
            NSString *outputFileName = [@"video" stringByAppendingString:[dateFormatter stringFromDate:[NSDate date]]];
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
            NSURL *outputFileURL = [NSURL fileURLWithPath:outputFilePath];
            
            
            [self.movieFileOutput startRecordingToOutputFileURL:outputFileURL recordingDelegate:self];
            
        } else{
            [self.movieFileOutput stopRecording];
        }
    });
}

- (IBAction)changeCamera:(id)sender
{
    self.cameraButton.enabled = NO;
    self.recordButton.enabled = NO;
    self.fpsSegControl.enabled = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        switch (currentPosition) {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
        }
        AVCaptureDevice *videoDevice = [VideoViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [self.session beginConfiguration];
        [self.session removeInput:self.videoDeviceInput];
        
        if ([self.session canAddInput:videoDeviceInput]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDeviceInput];
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
        } else{
            [self.session addInput:self.videoDeviceInput];
        }
        
        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoStabilizationSupported) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        [self.session commitConfiguration];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cameraButton.enabled = YES;
            self.recordButton.enabled = YES;
            self.fpsSegControl.enabled = YES;
        });
    });
}


- (IBAction)focusAndExposureWithTap:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer*)self.previewView.layer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:gestureRecognizer.view]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (IBAction)fpsSegmentControl:(id)sender
{
    CGFloat frameRate = 0;
    switch (self.fpsSegControl.selectedSegmentIndex) {
        case 0:
            frameRate = 30.0;
            [self resetFormat];
            return;
            break;
        case 1:
            frameRate = 60.0;
            break;
        case 2:
            frameRate = 120.0;
            break;
        default:
            frameRate = 30.0;
    }
    
    [self shouldActivateButtons:NO withStatusText:@"Switching..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (frameRate == 30.0) {
            [self resetFormat];
        } else{
            [self setFormatWithFPS:frameRate];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self shouldActivateButtons:YES withStatusText:nil];
        });
    });
}

#pragma mark - Activate/inactivate buttons
-(void) shouldActivateButtons:(BOOL)activate withStatusText:(NSString*) status
{
    self.cameraStatus.hidden = activate;
    self.cameraStatus.text = @"Switching...";
    self.activityIndicator.hidden = activate;
    if (activate) {
        [self.activityIndicator stopAnimating];
    } else {
        [self.activityIndicator startAnimating];
    }
    self.libraryButton.enabled = activate;
    self.recordButton.enabled = activate;
    self.cameraButton.enabled = activate;
}

#pragma mark - Set Camera Format
-(void) resetFormat
{
    BOOL isRunning = self.session.isRunning;
    if ( isRunning ) {
        [self.session stopRunning];
    }
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [videoDevice lockForConfiguration:nil];
    videoDevice.activeFormat = self.defaultFormat;
    //NSArray *supportedFrameRateRanges = videoDevice.activeFormat.videoSupportedFrameRateRanges;
    //NSLog(@"%@", supportedFrameRateRanges);
    videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 30);
    [videoDevice unlockForConfiguration];
    
    if (isRunning) {
        [self.session startRunning];
    }
}

-(void) setFormatWithFPS:(CGFloat) frameRate
{
    BOOL isRunning = self.session.isRunning;
    if (isRunning) {
        [self.session stopRunning];
    }
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [videoDevice lockForConfiguration:nil];
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = 0;
    
    for (AVCaptureDeviceFormat *format in [videoDevice formats]){
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges){
            CMFormatDescriptionRef description = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(description);
            int32_t width = dimensions.width;
            
            if (range.minFrameRate <= frameRate && frameRate <= range.maxFrameRate && width >= maxWidth) {
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
            if (selectedFormat){
                if ([videoDevice lockForConfiguration:nil]) {
                    NSLog(@"Selected format: %@", selectedFormat);
                    videoDevice.activeFormat = selectedFormat;
                    videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t) frameRate);
                    videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t) frameRate);
                    [videoDevice unlockForConfiguration];
                }
            }
        }
    }
    if (isRunning){
        [self.session startRunning];
    }
}



#pragma mark - File output recording delegate

-(void) captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recordButton.enabled = YES;
        [self.recordButton setTitle:NSLocalizedString(@"STOP",nil) forState:UIControlStateNormal];
    });
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    VideoLibraryManager *videoLibraryManager = [[VideoLibraryManager alloc] init];
    videoLibraryManager.persistenceController = self.persistenceController;
    [videoLibraryManager moveNewVideoToVideoDirectory:outputFileURL];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cameraButton.enabled = ([AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1);
        self.recordButton.enabled = YES;
        self.fpsSegControl.enabled = YES;
        [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
    });
    
    if (currentBackgroundRecordingID != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
    }
}

#pragma  mark - Device Configuration

-(void) focusWithMode:(AVCaptureFocusMode) focusMode exposeWithMode: (AVCaptureExposureMode) exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode]) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        } else {
            NSLog(@"Unable to lock device for configuration, %@", error);
        }
    });
}

+(AVCaptureDevice*)deviceWithMediaType:(NSString*)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for (AVCaptureDevice *device in devices){
        if (device.position == position){
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}


#pragma mark - NavBar Methods

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"goToLibrary"]) {
        VideoCollectionViewController *videoCollectionViewController = [segue destinationViewController];
        videoCollectionViewController.persistenceController = self.persistenceController;
    }
}


@end
