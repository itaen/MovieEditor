//
//  GLAudioModel.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/25.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLEditBaseModel.h"
#import <AVFoundation/AVFoundation.h>

@interface GLEditAudioModel : GLEditBaseModel

@property (nonatomic,strong) AVURLAsset *asset;
@property (nonatomic,strong) NSString *localUrl;
@property (nonatomic,assign) CGFloat start;
@property (nonatomic,assign) CGFloat clipStart;
@property (nonatomic,assign) CGFloat maxDuration;

//+ (void)audioWithAsset:(AVURLAsset *)asset url:(NSString *)fileURL duration:(CGFloat)duration completion:(void(^)(GLEditAudioModel * audio))competion;

- (instancetype)initWithAsset:(AVURLAsset *)asset url:(NSString *)fileURL duration:(CGFloat)duration completion:(void(^)(GLEditAudioModel * audio))competion;

@end

