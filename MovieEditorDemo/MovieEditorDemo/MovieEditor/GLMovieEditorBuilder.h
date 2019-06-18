//
//  GLMovieEditorBuilder.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GLEditPhotoModel.h"
#import "GLEditVideoModel.h"
#import "GLEditConst.h"
#import "GLEditTransitionModel.h"
#import "GLEditAudioModel.h"

@interface GLMovieEditorBuilder : NSObject
@property (nonatomic, strong) NSMutableArray <GLEditVideoModel *>  *videoModels;
@property (nonatomic, strong) NSMutableArray <GLEditTransitionModel *>  *transitionModels;
@property (nonatomic, strong) NSMutableArray <GLEditAudioModel *>  *audioModels;

/**
 * @brief 主文件的音量大小。取值:[0~1]，默认 0
 * @discussion 如果isMixMainFileMusic选项为NO，则这里失效
 */
@property(nonatomic,assign)float intensityOfMainAudioVolume;

/**
 * @brief 伴音文件的音量大小。取值:[0~1]，默认 0.5
 */
@property(nonatomic,assign)float intensityOfSecondAudioVolume;




+ (GLMovieEditorBuilder *)shared;

- (void)clearIfNeeded;

- (void)clearMusicTrack;


/**
 多个视频资源组装合成、添加转场等效果、合成后拿单例的playerItem预览，添加资源
 
 @param models <#models description#>
 */
-(void)buildVideoWithModels:(NSArray<GLEditVideoModel *> *)models;


/**
 build with exist videoModels，未添加新资源场景下
 */
-(void)buildVideo;

/**
 单例视频资源、用于实时预览和播放
 必须先调用 buildVideoWithModels 才能拿到对应实例

 @return <#return value description#>
 */
- (AVPlayerItem *)playerItem;


/**
 使用音轨资源创建Audio mix 用于更新音量

 @return <#return value description#>
 */
- (AVAudioMix *)buildAudioMix;


/**
 创建导出 session
 必须先调用 buildVideoWithModels 才能拿到对应实例

 @return <#return value description#>
 */
-(AVAssetExportSession *)makeExportable;


/**
 图片合成视频

 @param model <#model description#>
 @return <#return value description#>
 */
- (AVPlayerItem *)buildPhotoVideoWithPhoto:(GLEditPhotoModel *)model;


/**
 图片合成视频导出

 @param model <#model description#>
 @return <#return value description#>
 */
- (AVAssetExportSession *)exportPhotoWithModel:(GLEditPhotoModel*)model;


+ (NSArray<GLEditVideoModel *> *)GetEditVideoModels:(NSArray <AVURLAsset *>*)assets;

+ (NSArray<GLEditTransitionModel *> *)GetEditSupportTransitions;

/**
 组装出长于视频时长的音轨资源


 @param filePath <#filePath description#>
 @return <#return value description#>
 */
- (NSMutableArray <GLEditAudioModel *> *)getLoopAudioArrays:(NSString *)filePath ;//based on current playeritem duration



/**
 给目前容器持有的视频资源增加字幕

 @param text <#text description#>
 @param size <#size description#>
 */
- (void)applySubtitleToCurrentVideoItem:(NSString *)text textSize:(CGSize)size;

@end

