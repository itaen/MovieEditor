//
//  ViewController.m
//  MovieEditorDemo
//
//  Created by itaen on 2019/6/16.
//  Copyright © 2019 itaen. All rights reserved.
//

#import "ViewController.h"
#import "PhotoToVideoUtil.h"
#import "SVProgressHUD.h"
#import <AVKit/AVKit.h>
#import "GLEditPhotoModel.h"
#import "GLEditConst.h"


@interface ViewController ()

@property (nonatomic, strong) AVPlayerViewController *videoPlayer;

@end

@implementation ViewController

- (NSArray <UIImage *> *)demoImages {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
    for (int i = 0; i < 10; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpeg",i]];
        [array addObject:image];
    }
    return [NSArray arrayWithArray:array];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self playWithCMTime];
}

- (void)playVideoWithItem:(AVPlayerItem *)item {
    if (self.videoPlayer.player) {
        [self.videoPlayer.player replaceCurrentItemWithPlayerItem:item];
    }else{
        [self.videoPlayer setPlayer:[AVPlayer playerWithPlayerItem:item]];
    }
    
    [self.videoPlayer.player play];
    [self.navigationController pushViewController:self.videoPlayer animated:YES];
}


//使用 AVAssetWriter 将图片写成视频
- (IBAction)exportVideoWithAssetWriter:(UIButton *)sender {
    //1.目标视频文件的格式和尺寸
    NSDictionary *options =  [PhotoToVideoUtil videoSettingsWithCodec:AVVideoCodecTypeH264 withWidth:kPhotoVideoWidth andHeight:kPhotoVideoHeight];
    PhotoToVideoUtil *util = [[PhotoToVideoUtil alloc] initWithSettings:options];
    [SVProgressHUD show];
    
    //2.使用示例图片在合成线程执行写入和生成视频操作
    [util createMovieFromImages:[self demoImages] withCompletion:^(NSURL *fileURL) {
        [SVProgressHUD dismiss];
        //3.加载视频并展示
        AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:movieAsset];
        [self playVideoWithItem:item];

    }];
}

- (IBAction)avFoundationPhotoToVideo:(UIButton *)sender {
    GLEditPhotoModel *model = [[GLEditPhotoModel alloc] init];
    UIImage *image = [UIImage imageNamed:@"4.jpeg"];

    model.resizePhotoData = UIImageJPEGRepresentation(image, 1.0);
    model.originPhotoData = UIImageJPEGRepresentation(image, 1.0);
    model.duration = 3.f;
    AVPlayerItem *item = [self buildPhotoVideoWithPhoto:model];
    [self playVideoWithItem:item];

}

//单个图片转电影

- (AVPlayerItem *)buildPhotoVideoWithPhoto:(GLEditPhotoModel *)model {
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    
    [self setPhotoEditComposition:composition videoComposition:videoComposition PhotoModel:model];
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:composition];
    item.videoComposition = videoComposition;
    return item;
}

- (void)setPhotoEditComposition:(AVMutableComposition *)composition
               videoComposition:(AVMutableVideoComposition *)videoComposition
                     PhotoModel:(GLEditPhotoModel *)model{
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[[NSBundle mainBundle] URLForResource:@"blank" withExtension:@"mp4"] options:options];
    AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(model.duration, 1000)) ofTrack:assetTrack atTime:kCMTimeZero error:nil];

    videoComposition.frameDuration = CMTimeMake(1, 60);
    videoComposition.instructions = @[[AVMutableVideoCompositionInstruction videoCompositionInstruction]];
    videoComposition.renderSize = CGSizeMake(kPhotoVideoWidth, kPhotoVideoHeight);
    
}


- (IBAction)addMusicTrackToVideo:(UIButton *)sender {
    
}

- (IBAction)addSubtitlesToVideo:(UIButton *)sender {
    
}

- (IBAction)addWaterMarkToVideo:(UIButton *)sender {
    
}

- (IBAction)mergeTwoVideo:(UIButton *)sender {
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVURLAsset *clipA = [AVURLAsset URLAssetWithURL:[[NSBundle mainBundle] URLForResource:@"clip1" withExtension:@"mov"] options:options];
    AVURLAsset *clipB = [AVURLAsset URLAssetWithURL:[[NSBundle mainBundle] URLForResource:@"clip2" withExtension:@"mov"] options:options];
    NSArray <AVURLAsset *> *assets = @[clipA,clipB];
    
    AVMutableComposition *mainComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *compositionVideoTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
//    AVMutableCompositionTrack *soundtrackTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime insertTime = kCMTimeZero;
    
    for (AVAsset *videoAsset in assets) {
        
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:insertTime error:nil];
        
//        [soundtrackTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:insertTime error:nil];
        
        // Updating the insertTime for the next insert
        insertTime = CMTimeAdd(insertTime, videoAsset.duration);
    }

    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:mainComposition];
//    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
//    videoComposition.frameDuration = CMTimeMake(1, 60);
//    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [item duration]);
//    videoComposition.instructions = @[instruction];
//    videoComposition.renderSize = CGSizeMake(kPhotoVideoHeight, kPhotoVideoWidth);

//    item.videoComposition = videoComposition;
    [self playVideoWithItem:item];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *outputVideoPath =  [documentsDirectory stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];

	NSURL *outptVideoUrl = [NSURL fileURLWithPath:outputVideoPath];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition presetName:AVAssetExportPreset1280x720];

    exporter.outputURL=outptVideoUrl;
    exporter.outputFileType =AVFileTypeMPEG4;   //AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
	[SVProgressHUD show];
	[exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
			if(exporter.status == AVAssetExportSessionStatusCompleted){
				[SVProgressHUD dismiss];
				UISaveVideoAtPathToSavedPhotosAlbum(outputVideoPath, nil, nil, nil);
			}
        });
    }];
}

- (IBAction)addMultipleMusicTrackToVideo:(UIButton *)sender {
    
}

- (IBAction)addTransitionsToVideo:(UIButton *)sender {
    
}

- (IBAction)addFilterToVideo:(UIButton *)sender {
    
}




-(AVPlayerViewController *)videoPlayer{
    if(_videoPlayer==nil){
        _videoPlayer = [[AVPlayerViewController alloc] init];
        _videoPlayer.showsPlaybackControls = NO;
        _videoPlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _videoPlayer.view.frame = [UIScreen mainScreen].bounds;
        _videoPlayer.view.backgroundColor = [UIColor clearColor];
        _videoPlayer.title = @"图片电影";
        /** 获取音频焦点 */
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }
    return _videoPlayer;
}

- (void)playWithCMTime {
    Float64 seconds = 5;
    int32_t preferredTimeScale = 600;
    CMTime inTime = CMTimeMakeWithSeconds(seconds, preferredTimeScale);
    CMTimeShow(inTime);
//    The above code gives: {3000/600 = 5.000}
//    Which means a total duration of 5 seconds, with 3000 frames with a timescale of 600 frames per second.
    
//    int64_t value = 10000;
//    int32_t preferredTimeScale = 600;
//    CMTime inTime = CMTimeMake(value, preferredTimeScale);
//    CMTimeShow(inTime);
//    This one gives {10000/600 = 16.667}
//
//    Which means a total duration of 16.667 seconds, with 10000 frames with a timescale of 600 frames per second.
}


@end
