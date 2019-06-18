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
#import "GLMovieEditorBuilder.h"

@interface ViewController ()

@property (nonatomic, strong) AVPlayerViewController *videoPlayer;

@end

@implementation ViewController

- (void)playVideoWithItem:(AVPlayerItem *)item {
    if (self.videoPlayer.player) {
        [self.videoPlayer.player replaceCurrentItemWithPlayerItem:item];
    }else{
        [self.videoPlayer setPlayer:[AVPlayer playerWithPlayerItem:item]];
    }
    
    
    [self.videoPlayer.player play];
    [self.navigationController pushViewController:self.videoPlayer animated:YES];
}

- (void)exportVideo:(AVURLAsset *)asset {
	NSURL *outptVideoUrl = [NSURL fileURLWithPath:[PhotoToVideoUtil cachePathWithName: [NSString stringWithFormat:@"tempVideo-%d.mov",arc4random() % 1000]]];
	AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset1280x720];
	
	exporter.outputURL=outptVideoUrl;
	exporter.outputFileType =AVFileTypeMPEG4;   //AVFileTypeQuickTimeMovie;
	exporter.shouldOptimizeForNetworkUse = YES;
	[SVProgressHUD show];
	[exporter exportAsynchronouslyWithCompletionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			if(exporter.status == AVAssetExportSessionStatusCompleted){
				[SVProgressHUD dismiss];
				//为了查看方便保存一份到相册
				UISaveVideoAtPathToSavedPhotosAlbum(outptVideoUrl.relativePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
			}
		});
	}];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInf{
	if (error) {
		[SVProgressHUD showErrorWithStatus:@"导出失败!"];
		NSLog(@"保存视频过程中发生错误，错误信息:%@",error.localizedDescription);
	}else{
		[SVProgressHUD showSuccessWithStatus:@"视频导出成功,请在相册中查看!"];
		NSLog(@"视频保存成功.");
	}
}

#pragma mark - 使用 AVAssetWriter 将图片写成视频
- (IBAction)exportVideoWithAssetWriter:(UIButton *)sender {
    //1.目标视频文件的格式和尺寸
    NSDictionary *options =  [PhotoToVideoUtil videoSettingsWithCodec:AVVideoCodecH264 withWidth:kPhotoVideoWidth andHeight:kPhotoVideoHeight];
    PhotoToVideoUtil *util = [[PhotoToVideoUtil alloc] initWithSettings:options];
    [SVProgressHUD show];
    
    //2.使用示例图片在合成线程执行写入和生成视频操作
    [util createMovieFromImages:[self demoImages] withCompletion:^(NSURL *fileURL) {
        [SVProgressHUD dismiss];
        //3.加载视频并展示
        AVURLAsset *movieAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:movieAsset];
        [self playVideoWithItem:item];
		UISaveVideoAtPathToSavedPhotosAlbum(fileURL.relativePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);

//		导出逻辑示范
//		[self exportVideo:movieAsset];
    }];
}

#pragma mark - AVFoundation 单张图片转视频
- (IBAction)avFoundationPhotoToVideo:(UIButton *)sender {
    GLEditPhotoModel *model = [[GLEditPhotoModel alloc] init];
    UIImage *image = [UIImage imageNamed:@"4.jpeg"];

    model.resizePhotoData = UIImageJPEGRepresentation(image, 1.0);
    model.originPhotoData = UIImageJPEGRepresentation(image, 1.0);
    model.duration = 3.f;
    model.type = GLPhotoAnimationPushRight;
    AVPlayerItem *item = [[GLMovieEditorBuilder shared] buildPhotoVideoWithPhoto:model];
    [self playVideoWithItem:item];

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


- (NSArray <UIImage *> *)demoImages {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:10];
    for (int i = 0; i < 10; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpeg",i]];
        [array addObject:image];
    }
    return [NSArray arrayWithArray:array];
}

@end
