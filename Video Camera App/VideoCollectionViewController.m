//
//  VideoCollectionViewController.m
//  Video Camera App
//
//  Created by Matthew Paravati on 3/15/16.
//  Copyright © 2016 TurnToTech. All rights reserved.
//

#import "VideoCollectionViewController.h"
#import "VideoLibraryManager.h"
#import "VideoCollectionViewCell.h"
#import "UINavigationController+TransparentNavigationControllerViewController.h"
#import "VideoPlayerViewController.h"
#import "VideoInfo.h"

@interface VideoCollectionViewController ()
@property (strong, nonatomic) NSMutableArray *videoList;
@property (strong, nonatomic) NSArray *videoFPSTypes;

@end

@implementation VideoCollectionViewController

static NSString * const reuseIdentifier = @"VideoCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadVideoLists];
    
    // Register cell classes
    [self.collectionView registerClass:[VideoCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Do any additional setup after loading the view.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController presentTransparentNavigationBar];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) loadVideoLists
{
    VideoLibraryManager *videoLibraryManager = [[VideoLibraryManager alloc]init];

    self.videoList = [videoLibraryManager getVideoObjects];
    self.videoFPSTypes = [videoLibraryManager getFPSSetFromVideoList:self.videoList];

}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.videoList.count;
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VideoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    VideoInfo *currentVideo = [self.videoList objectAtIndex:indexPath.row];
    
    cell.videoThumbnailImageView.image = currentVideo.thumbnailImage;
    
    NSString *videoName = currentVideo.name;
    cell.videoInfo.text = videoName;
    
    cell.videoTimeLabel.text = currentVideo.duration;
    // Configure the cell
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>


-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        [self removeCellAtIndexPath:indexPath];
    } else {
        VideoInfo *currentVideo = [self.videoList objectAtIndex:indexPath.row];
        
        VideoPlayerViewController *videoPlayerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoPlayer"];
        
        videoPlayerViewController.currentVideo = currentVideo;
        videoPlayerViewController.videoList = self.videoList;
        
        [self.navigationController pushViewController:videoPlayerViewController animated:YES];
        
    }
}


-(void) removeCellAtIndexPath:(NSIndexPath*) indexPath
{
    [self.collectionView performBatchUpdates:^{
        VideoLibraryManager *videoLibraryManager = [[VideoLibraryManager alloc] init];
        VideoInfo *currentVideo = self.videoList[indexPath.row];
        [videoLibraryManager deleteVideo:currentVideo];
        [self.videoList removeObject:currentVideo];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:nil];
}


-(void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if(editing){
        self.title = @"Click video to delete";
    }else {
        self.title = @"";
    }
    
    [self.collectionView reloadData];
}


@end
