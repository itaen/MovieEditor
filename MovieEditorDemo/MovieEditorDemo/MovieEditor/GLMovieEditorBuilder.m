//
//  GLMovieEditorBuilder.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLMovieEditorBuilder.h"
#import "GLLocalPhotoCompositionInstruction.h"
#import "GLCustomVideoCompositor.h"
#import "GLEditVideoModel.h"
#import "GLEditTransitionModel.h"
#import "GLLocalVideoCompositionInstruction.h"
#import "GLTransitionVideoCompositionInstruction.h"
#import "GLFilterVideoCompositionInstruction.h"
#import "GLPassthroughVideoCompositionInstruction.h"


@interface GLMovieEditorBuilder ()

@property (nonatomic, strong) AVMutableComposition      *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong) AVMutableCompositionTrack *musicTrack;
@property (nonatomic, strong) AVMutableAudioMix *audioMix;


@end

@implementation GLMovieEditorBuilder

+ (GLMovieEditorBuilder *)shared {
    static dispatch_once_t pred;
    static GLMovieEditorBuilder *sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[GLMovieEditorBuilder alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.intensityOfMainAudioVolume = 0.;//合成影片默认无声音
		self.intensityOfSecondAudioVolume = 0.5;
	}
	return self;
}
/**
 每次选择音乐都重置为默认音量
 */
- (void)resetDefaultVolume {
	self.intensityOfMainAudioVolume = 0.;//合成影片默认无声音
	self.intensityOfSecondAudioVolume = 0.5;
}

- (void)clearIfNeeded {

	[self resetDefaultVolume];
    [self.videoModels removeAllObjects];
    [self.transitionModels removeAllObjects];
    [self.audioModels removeAllObjects];
    self.composition = nil;
    self.videoComposition = nil;
    self.musicTrack = nil;
    self.audioMix = nil;
}

- (void)clearMusicTrack {
	[self.audioModels removeAllObjects];
	[self buildVideo];
}

- (NSArray *)buildVideoModelsWithTransition:(NSArray<GLEditVideoModel *> *)models {
    NSMutableArray *arrays = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(GLEditVideoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat duration = (obj.transitionType == GLRenderTransisionTypeNone) ? 0.0 :kTransitionTime;
        GLEditTransitionModel *model = [[GLEditTransitionModel alloc] initWithDuration:duration type:obj.transitionType];
        [arrays addObject:obj];
        if (idx < models.count - 1) {
            [arrays addObject:model];
        }
    }];
    return [NSArray arrayWithArray:arrays];
}

- (void)buildVideo {
    NSArray *dataModels = [self buildVideoModelsWithTransition:self.videoModels];
    
    self.composition = [AVMutableComposition composition];
    self.videoComposition = [AVMutableVideoComposition videoComposition];
    self.videoComposition.customVideoCompositorClass = [GLCustomVideoCompositor class];
    self.audioMix =  [AVMutableAudioMix audioMix];
    NSMutableArray <GLEditVideoModel *>*videoModels = [NSMutableArray array];
    NSMutableArray <GLEditTransitionModel *>*transitionModels = [NSMutableArray array];
    
    [dataModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[GLEditVideoModel class]]) {
            [videoModels addObject:obj];
        }else if ([obj isKindOfClass:[GLEditTransitionModel class]]) {
            [transitionModels addObject:obj];//just add, nowhere use this by now
        }
    }];
    
    self.transitionModels = transitionModels;
    
    CMTime nextClipStartTime = kCMTimeZero;
    NSUInteger count = [videoModels count];
    NSInteger i;
    AVMutableCompositionTrack *compositionVideoTracks[2];

    compositionVideoTracks[0] = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    if (dataModels.count > 1) {
        compositionVideoTracks[1] = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    }
    CMTimeRange *passThroughTimeRanges = alloca(sizeof(CMTimeRange) * count);
    CMTimeRange *transitionTimeRanges = alloca(sizeof(CMTimeRange) * count);
    CGFloat transitionTime = (self.transitionModels.firstObject.type == GLRenderTransisionTypeNone) ? 0.0 :kTransitionTime;

    CMTime transitonDuration = CMTimeMake(transitionTime * 1000, 1000);
    
    for (int i = 0; i < count; i++) {
        NSInteger index = i % 2;
        GLEditVideoModel *model = videoModels[i];
		
        AVAssetTrack *videoTrack = [[model.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        CGFloat start = model.startTime <= 0 ? 0 : model.startTime;
        CGFloat duration = model.duration - model.startTime >= CMTimeGetSeconds(videoTrack.timeRange.duration) ? CMTimeGetSeconds(videoTrack.timeRange.duration) : model.duration;
        model.duration = duration;
        CMTimeRange timeRangeInAsset = CMTimeRangeMake(CMTimeMakeWithSeconds(start, 1000), CMTimeMakeWithSeconds(duration, 1000));
        if (CMTimeCompare(timeRangeInAsset.duration, videoTrack.timeRange.duration) > 0) {
            NSLog(@"超出时间了");
            timeRangeInAsset = CMTimeRangeMake(timeRangeInAsset.start, CMTimeSubtract(videoTrack.timeRange.duration, timeRangeInAsset.start));
        }
        
        NSLog(@"timeRangeInAsset:%@,trackTime:%@",[NSValue valueWithCMTimeRange:timeRangeInAsset],[NSValue valueWithCMTimeRange:videoTrack.timeRange]);
        [compositionVideoTracks[index] insertTimeRange:timeRangeInAsset ofTrack:videoTrack atTime:nextClipStartTime error:nil];
        
        passThroughTimeRanges[i] = CMTimeRangeMake(nextClipStartTime,timeRangeInAsset.duration);
        
            //---------------------------------------------- no transition ---------------------------------------------------------
            //        passThroughTimeRanges[i].start = passThroughTimeRanges[i].start;
            //        passThroughTimeRanges[i].duration = passThroughTimeRanges[i].duration;
            //        nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration);
            //---------------------------------------------- no transition ---------------------------------------------------------
        
        
            //----------------------------------------------transition -------------------------------------------------------------
            //1.
        if (i > 0) {
            passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start,transitonDuration);
            passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitonDuration);
            
            
        }
            //2.
        if (i+1 < count) {
            passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitonDuration);
        }
        
        nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration);
        nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitonDuration);
        
            //3.Remember the time range for the transition to the next item.
        if (i+1 < count) {
            transitionTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, transitonDuration);
        }
            //----------------------------------------------transition -------------------------------------------------------------
        
        
    }
	
	if (self.audioModels.count>0) {
		self.musicTrack = [self addCompositionTrackOfType:AVMediaTypeAudio withMediaItems:[NSArray arrayWithArray:self.audioModels]];
	}
	
	
	NSMutableArray *instructions = [NSMutableArray array];

	for (i = 0; i < count; i++) {
		GLEditVideoModel *model = videoModels[i];
		NSInteger index = i % 2;
		if (self.videoComposition.customVideoCompositorClass) {
			
			if (model.isLocal) {
//				CGSize size = compositionVideoTracks[index].naturalSize;
//				GLLocalVideoCompositionInstruction *instruction = [[GLLocalVideoCompositionInstruction alloc] initSourceTrackID:compositionVideoTracks[index].trackID forTimeRange:passThroughTimeRanges[i] rotateDegree:model.rotateDegree natureSize:size];
//				[instructions addObject:instruction];
//
				
				if (model.filterType == GLFilterTypeNone) {
					GLPassthroughVideoCompositionInstruction *instruction = [[GLPassthroughVideoCompositionInstruction alloc] initPassThroughTrackID:compositionVideoTracks[index].trackID forTimeRange:passThroughTimeRanges[i]];
					[instructions addObject:instruction];
				}else{
					GLFilterVideoCompositionInstruction *instruction = [[GLFilterVideoCompositionInstruction alloc] initSourceTrackID:compositionVideoTracks[index].trackID forTimeRange:passThroughTimeRanges[i] type:model.filterType];
					[instructions addObject:instruction];
				}
				
				if (i+1 < count) {
					if (model.transitionType != GLRenderTransisionTypeNone) {
						GLTransitionVideoCompositionInstruction *instruction = [[GLTransitionVideoCompositionInstruction alloc] initTransitionWithSourceTrackIDs:@[[NSNumber numberWithInt:compositionVideoTracks[0].trackID], [NSNumber numberWithInt:compositionVideoTracks[1].trackID]] forTimeRange:transitionTimeRanges[i] type:(GLTransitionType)model.transitionType];
						
							// First track -> Foreground track while compositing
						instruction.foregroundTrackID = compositionVideoTracks[index].trackID;
							// Second track -> Background track while compositing
						instruction.backgroundTrackID = compositionVideoTracks[1-index].trackID;
						instruction.foregroundFilter = model.filterType;
						GLEditVideoModel *nextVideo = videoModels[i+1];
						instruction.backgroundFilter = nextVideo.filterType;
						[instructions addObject:instruction];
					}
				}
			}
		}
	}
	

    self.videoComposition.instructions = instructions;
	
    self.videoComposition.frameDuration = CMTimeMake(1, kPhotoVideoFPS);
    self.videoComposition.renderSize = CGSizeMake(kPhotoVideoWidth, kPhotoVideoHeight);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GLMovieEditorNeedReloadDataNotification object:nil];
}

- (AVMutableCompositionTrack *)addCompositionTrackOfType:(NSString *)mediaType
                                          withMediaItems:(NSArray *)mediaItems {
    
    AVMutableCompositionTrack *compositionTrack = nil;
    NSLog(@"add track");
    NSError *error = nil;
    compositionTrack =
    [self.composition addMutableTrackWithMediaType:mediaType
                                  preferredTrackID:kCMPersistentTrackID_Invalid];
    for (GLEditAudioModel *item in mediaItems) {
        
        AVAssetTrack *assetTrack = [[item.asset tracksWithMediaType:mediaType] firstObject];
		CMTimeRange clipTimerange = CMTimeRangeMake(CMTimeMakeWithSeconds(item.clipStart, 1000), CMTimeMakeWithSeconds(item.duration , 1000));
		[compositionTrack insertTimeRange:clipTimerange ofTrack:assetTrack atTime:CMTimeMakeWithSeconds(item.start, 1000) error:&error];
        if(error){
            NSLog(@"insert track %@ error %@",mediaType ,error);
        }
    }
    
    return compositionTrack;
}

- (void)buildVideoWithModels:(NSArray<GLEditVideoModel *> *)models {
    self.videoModels = [NSMutableArray arrayWithArray:models];
    [self buildVideo];
}

- (AVPlayerItem *)playerItem {
    self.videoComposition.animationTool = nil;
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
	if ([self buildAudioMix]) {
		AVAudioMix *audiomix = [self buildAudioMix];
		AVMutableAudioMixInputParameters *params = (AVMutableAudioMixInputParameters *)[audiomix.inputParameters firstObject];
		NSMutableArray *array = [NSMutableArray arrayWithArray:self.audioMix.inputParameters];
		[array addObject:params];
		self.audioMix.inputParameters = array;
	}
    playerItem.audioMix = self.audioMix;
	playerItem.videoComposition = self.videoComposition;
    return playerItem;
}

- (AVAudioMix *)buildAudioMix {
	AVMutableAudioMix *audioMix = nil;
	NSArray *audios = self.audioModels;
	if (audios.count == 0) {
		return audioMix;
	}
	
	audioMix = [AVMutableAudioMix audioMix];
	AVMutableAudioMixInputParameters *parameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:self.musicTrack];
	for (GLEditAudioModel *model in audios) {
		CGFloat audioMixStart = model.start;
		CGFloat audioMixDuration = model.duration;
		[parameters setVolumeRampFromStartVolume:self.intensityOfSecondAudioVolume toEndVolume:self.intensityOfSecondAudioVolume timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(audioMixStart, 1000), CMTimeMakeWithSeconds(audioMixDuration, 1000))];
	}
	audioMix.inputParameters = @[parameters];
	return audioMix;
}

-(AVAssetExportSession *)makeExportable {
    NSString *presetName = AVAssetExportPresetHighestQuality;
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:presetName];
    if ([self buildAudioMix]) {
        AVAudioMix *audiomix = [self buildAudioMix];
        AVMutableAudioMixInputParameters *params = (AVMutableAudioMixInputParameters *)[audiomix.inputParameters firstObject];
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.audioMix.inputParameters];
        [array addObject:params];
        self.audioMix.inputParameters = array;
    }
    session.audioMix = self.audioMix;

    session.videoComposition = self.videoComposition;
    
    return session;
}

+ (NSArray<GLEditVideoModel *> *)GetEditVideoModels:(NSArray<AVURLAsset *> *)assets {
	NSMutableArray <GLEditVideoModel *> *videoModels = [NSMutableArray array];
	[assets enumerateObjectsUsingBlock:^(AVURLAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		GLEditVideoModel *videoModel = [[GLEditVideoModel alloc] init];
		videoModel.duration = CMTimeGetSeconds(obj.duration);
		videoModel.startTime = 0.0;
		videoModel.asset = obj;
		videoModel.isLocal = YES;
		videoModel.transitionType = GLRenderTransisionTypeWipeHorizontal;
		videoModel.filterType = GLFilterTypeNone;
		[videoModels addObject:videoModel];
	}];
	return [NSArray arrayWithArray:videoModels];
}

+ (NSArray<GLEditTransitionModel *> *)GetEditSupportTransitions {
    CGFloat duration = kTransitionTime;
    GLEditTransitionModel *modelNone = [[GLEditTransitionModel alloc] initWithDuration:0 type:GLRenderTransisionTypeNone];
    GLEditTransitionModel *modelHorizontal = [[GLEditTransitionModel alloc] initWithDuration:duration type:GLRenderTransisionTypeWipeHorizontal];
    GLEditTransitionModel *modelVertical = [[GLEditTransitionModel alloc] initWithDuration:duration type:GLRenderTransisionTypeWipeVertical];
    
    return @[modelNone,modelHorizontal,modelVertical];
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

- (AVAssetExportSession *)exportPhotoWithModel:(GLEditPhotoModel*)model {
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    [self setPhotoEditComposition:composition videoComposition:videoComposition PhotoModel:model];
    NSString *presetName = AVAssetExportPresetHighestQuality;
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:presetName];
    
    session.videoComposition = videoComposition;
    return session;
}

- (void)setPhotoEditComposition:(AVMutableComposition *)composition
               videoComposition:(AVMutableVideoComposition *)videoComposition
                     PhotoModel:(GLEditPhotoModel *)model{
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[[NSBundle mainBundle] URLForResource:@"blank" withExtension:@"mp4"] options:options];
    AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(model.duration, 1000)) ofTrack:assetTrack atTime:kCMTimeZero error:nil];
    videoComposition.customVideoCompositorClass = [GLCustomVideoCompositor class];
    GLLocalPhotoCompositionInstruction *instruction = [[GLLocalPhotoCompositionInstruction alloc] initSourceTrackID:assetTrack.trackID forTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(model.duration, 1000))];

    instruction.resizePhotoData = model.resizePhotoData;
    instruction.animationType = model.type;
    
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, kPhotoVideoFPS);
    videoComposition.renderSize = CGSizeMake(kPhotoVideoWidth, kPhotoVideoHeight);
  
}

- (NSMutableArray<GLEditVideoModel *> *)videoModels {
    if (!_videoModels) {
        _videoModels = [NSMutableArray array];
    }
    return _videoModels;
}

- (NSMutableArray<GLEditTransitionModel *> *)transitionModels {
    if (!_transitionModels) {
        _transitionModels = [NSMutableArray array];
    }
    return _transitionModels;
}

- (void)setAudioModels:(NSMutableArray<GLEditAudioModel *> *)audioModels {
	_audioModels = audioModels;
	[self resetDefaultVolume];//每次音频资源更新都重置音量配置
}

- (NSMutableArray <GLEditAudioModel *> *)getLoopAudioArrays:(NSString *)filePath {
	NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
	AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:options];
	CMTime assetDuration = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject].timeRange.duration;
	CGFloat duration = CMTimeGetSeconds(assetDuration);
	
	
	__block CGFloat videoDuration = 0;
	[self.videoModels enumerateObjectsUsingBlock:^(GLEditVideoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		if (idx != self.videoModels.count-1) {
			CGFloat transitionTime = (obj.transitionType == GLRenderTransisionTypeNone) ? 0.0 :kTransitionTime;
			videoDuration = videoDuration + obj.duration - transitionTime;
		}else{
			videoDuration = videoDuration + obj.duration;
		}
	}];
	
	if (duration >= videoDuration) {
		NSLog(@"视频比音频时间短,直接截断音乐");
		GLEditAudioModel *model = [[GLEditAudioModel alloc] initWithAsset:asset url:filePath duration:duration completion:nil];
		model.duration = videoDuration;
		return [NSMutableArray arrayWithObject:model];

	}

	CMTime nextClipStartTime = kCMTimeZero;
	NSMutableArray <GLEditAudioModel *> *models = [NSMutableArray array];
	NSInteger count = videoDuration/duration + 1;
	
	for (int i = 0; i< count; i++) {
		GLEditAudioModel *model = [[GLEditAudioModel alloc] initWithAsset:asset url:filePath duration:duration completion:nil];
		AVAssetTrack *audioTrack = [[model.asset tracksWithMediaType:AVMediaTypeAudio] firstObject];

		if (i<count-1) {
			model.start = CMTimeGetSeconds(nextClipStartTime);
			CGFloat duration = (model.duration - model.start) >= CMTimeGetSeconds(audioTrack.timeRange.duration) ? CMTimeGetSeconds(audioTrack.timeRange.duration) : model.duration;
			model.duration = duration;
			[models addObject:model];
			
			nextClipStartTime = CMTimeAdd(nextClipStartTime, CMTimeMakeWithSeconds(duration, 1000));

		}else{
			model.start = CMTimeGetSeconds(nextClipStartTime);
			model.duration =  videoDuration - CMTimeGetSeconds(nextClipStartTime);
			[models addObject:model];
		}
	}


	return [NSMutableArray arrayWithArray:models];
}


- (void)applySubtitleToCurrentVideoItem:(NSString *)text textSize:(CGSize)size {
	[self applyVideoEffectsToComposition:self.videoComposition size:size text:text];
}
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size text:(NSString *)text
{
		// 1 - Set up the text layer
	CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
	[subtitle1Text setFont:@"Helvetica-Bold"];
	[subtitle1Text setFontSize:36];
	[subtitle1Text setFrame:CGRectMake(0, 0, size.width, 100)];
	[subtitle1Text setString:text];
	[subtitle1Text setAlignmentMode:kCAAlignmentCenter];
	[subtitle1Text setForegroundColor:[[UIColor blackColor] CGColor]];
	
		// 2 - The usual overlay
	CALayer *overlayLayer = [CALayer layer];
	[overlayLayer addSublayer:subtitle1Text];
	overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
	[overlayLayer setMasksToBounds:YES];
	
	CALayer *parentLayer = [CALayer layer];
	CALayer *videoLayer = [CALayer layer];
	parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
	videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
	[parentLayer addSublayer:videoLayer];
	[parentLayer addSublayer:overlayLayer];
	
	composition.animationTool = [AVVideoCompositionCoreAnimationTool
								 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
	
}

@end
