//
//  GLEditAudioModel.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/25.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLEditAudioModel.h"
static NSString *const AVAssetTracksKey = @"tracks";
static NSString *const AVAssetDurationKey = @"duration";
static NSString *const AVAssetCommonMetadataKey = @"commonMetadata";
@implementation GLEditAudioModel

- (instancetype)initWithAsset:(AVURLAsset *)asset url:(NSString *)fileURL duration:(CGFloat)duration completion:(void(^)(GLEditAudioModel * audio))competion{
    self = [super init];
    if (self) {
        self.asset = asset;
        self.localUrl = fileURL;
        self.start = 0.f;
		self.clipStart = 0.f;
        self.duration = duration;
        [self loadAssetWithCompletionBlock:competion];
    }
    return self;
}

//+ (void)audioWithAsset:(AVURLAsset *)asset url:(NSString *)fileURL duration:(CGFloat)duration completion:(void(^)(GLEditAudioModel * audio))competion {
//    GLEditAudioModel *model = [[GLEditAudioModel alloc] initWithAsset:asset url:fileURL duration:duration completion:competion];
//}

- (void)loadAssetWithCompletionBlock:(void (^)(GLEditAudioModel * audio))completionBlock{
    NSArray *keys = @[AVAssetTracksKey,AVAssetDurationKey,AVAssetCommonMetadataKey];
    [self.asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error ;
        AVKeyValueStatus tracksStatus = [self.asset statusOfValueForKey:AVAssetTracksKey error:&error];
        AVKeyValueStatus durationStatus = [self.asset statusOfValueForKey:AVAssetDurationKey error:&error];
        self.maxDuration = CMTimeGetSeconds(self.asset.duration);
        self.duration = self.duration > self.maxDuration ? self.maxDuration : self.duration;
        AVAssetTrack *audioTrack = [[self.asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        self.maxDuration = CMTimeGetSeconds(audioTrack.timeRange.duration);
        if((tracksStatus == AVKeyValueStatusLoaded)&&(durationStatus == AVKeyValueStatusLoaded)){
            if (completionBlock) {
                completionBlock(self);
            }
        }
    }];
    
}

@end
