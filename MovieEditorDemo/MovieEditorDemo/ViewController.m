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
    
	self.videoPlayer.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [self.videoPlayer.player play];
    [self.navigationController pushViewController:self.videoPlayer animated:YES];
}

#pragma mark - AVAssetExportSession 导出例子
- (void)exportVideo:(AVAssetExportSession *)exporter {
	NSURL *outptVideoUrl = [NSURL fileURLWithPath:[PhotoToVideoUtil cachePathWithName: [NSString stringWithFormat:@"tempVideo-%d.mov",arc4random() % 1000]]];
	exporter.outputURL=outptVideoUrl;
	exporter.outputFileType =AVFileTypeMPEG4;   //AVFileTypeQuickTimeMovie;
	exporter.shouldOptimizeForNetworkUse = YES;
	[SVProgressHUD show];
	[exporter exportAsynchronouslyWithCompletionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			if(exporter.status == AVAssetExportSessionStatusCompleted){
				[SVProgressHUD dismiss];
				//为了查看方便保存一份到相册
				UISaveVideoAtPathToSavedPhotosAlbum(exporter.outputURL.relativePath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
			}
		});
	}];
}

#pragma mark - 视频导出回调
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
		AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:movieAsset presetName:AVAssetExportPresetHighestQuality];
		[self exportVideo:exporter];
    }];
}

#pragma mark - AVFoundation 单张图片转视频
- (IBAction)avFoundationPhotoToVideo:(UIButton *)sender {  
    GLEditPhotoModel *model = [[GLEditPhotoModel alloc] init];
	UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%u.jpeg",arc4random_uniform(10)]];

    model.resizePhotoData = UIImageJPEGRepresentation(image, 1.0);
    model.originPhotoData = UIImageJPEGRepresentation(image, 1.0);
    model.duration = 5.f;
    model.type = GLPhotoAnimationNone;
    AVPlayerItem *item = [[GLMovieEditorBuilder shared] buildPhotoVideoWithPhoto:model];
	
	[self playVideoWithItem:item];
	
	//导出单个图片视频
	AVAssetExportSession *session = [[GLMovieEditorBuilder shared] exportPhotoWithModel:model];
	[self exportVideo:session];
	

}

#pragma mark - 视频增加音轨
- (IBAction)addMusicTrackToVideo:(UIButton *)sender {
	[[GLMovieEditorBuilder shared] clearIfNeeded];
	NSURL *musicFile = [[NSBundle mainBundle] URLForResource:@"music1" withExtension:@"m4a"];
	[self combineDemoVideo];
    [GLMovieEditorBuilder shared].audioModels = [[GLMovieEditorBuilder shared] getLoopAudioArrays:musicFile.relativePath];
	[[GLMovieEditorBuilder shared] buildVideo];
	AVPlayerItem *item = [[GLMovieEditorBuilder shared] playerItem];
	[self playVideoWithItem:item];
}

#pragma mark - 多个视频合并
- (IBAction)mergeVideo:(UIButton *)sender {
	[self combineDemoVideo];
	AVPlayerItem *item = [[GLMovieEditorBuilder shared] playerItem];
	[self playVideoWithItem:item];
}

- (void)combineDemoVideo {
	NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[[NSBundle mainBundle] URLForResource:@"clip1" withExtension:@"mov"] options:options];
	AVURLAsset *asset2 = [AVURLAsset URLAssetWithURL:[[NSBundle mainBundle] URLForResource:@"clip2" withExtension:@"mov"] options:options];
	AVURLAsset *asset3 = [AVURLAsset URLAssetWithURL:[[NSBundle mainBundle] URLForResource:@"clip3" withExtension:@"mov"] options:options];
	NSArray <GLEditVideoModel *> *videoModels = [GLMovieEditorBuilder GetEditVideoModels:@[asset,asset2,asset3]];
	[[GLMovieEditorBuilder shared] buildVideoWithModels:videoModels];
}


#pragma mark - 为视频增加转场
- (IBAction)addTransitionsToVideo:(UIButton *)sender {
	[self combineDemoVideo];
	[[GLMovieEditorBuilder shared].videoModels enumerateObjectsUsingBlock:^(GLEditVideoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.transitionType = GLRenderTransisionTypeDissolve;
	}];
	[[GLMovieEditorBuilder shared] buildVideo];
	AVPlayerItem *item = [[GLMovieEditorBuilder shared] playerItem];
	[self playVideoWithItem:item];
}

#pragma mark - 为视频增加滤镜
- (IBAction)addFilterToVideo:(UIButton *)sender {
	[self combineDemoVideo];
	[[GLMovieEditorBuilder shared].videoModels enumerateObjectsUsingBlock:^(GLEditVideoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		obj.filterType = GLFilterTypeRio;
	}];
	[[GLMovieEditorBuilder shared] buildVideo];
	AVPlayerItem *item = [[GLMovieEditorBuilder shared] playerItem];
	[self playVideoWithItem:item];
}


#pragma mark - 清除容器资源

- (IBAction)clearBuilderData:(UIButton *)sender {
	[[GLMovieEditorBuilder shared] clearIfNeeded];
	if (self.videoPlayer.player) {
		[self.videoPlayer setPlayer:[AVPlayer playerWithPlayerItem:nil]];
	}
	[SVProgressHUD showSuccessWithStatus:@"数据重置成功！"];
}

#pragma mark - CMTime 例子
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


@end
