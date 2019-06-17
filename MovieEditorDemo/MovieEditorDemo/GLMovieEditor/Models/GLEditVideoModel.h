//
//  GLEditVideoModel.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/6.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLEditBaseModel.h"
#import <AVFoundation/AVFoundation.h>
@interface GLEditVideoModel : GLEditBaseModel;

@property (nonatomic,strong) AVURLAsset *asset;
@property (nonatomic,assign) CGFloat    startTime;
@property (nonatomic,assign) CGFloat rotateDegree;
@property (nonatomic,strong) NSData *originImageData;
@property (nonatomic,strong) NSData *resizeImageData;
@property (nonatomic,assign) GLTransitionType transitionType;
@property (nonatomic,assign) GLFilterType filterType;
@property (nonatomic,assign) BOOL isLocal;

@end

