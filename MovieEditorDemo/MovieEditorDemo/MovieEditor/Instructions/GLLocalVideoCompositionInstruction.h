//
//  GLLocalVideoCompositionInstruction.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLBaseCustomVideoCompositionInsruction.h"

@interface GLLocalVideoCompositionInstruction : GLBaseCustomVideoCompositionInsruction
@property CMPersistentTrackID sourceTrackID;
@property (assign,nonatomic)  CGFloat degree;
@property (assign,nonatomic)  CGSize natureSize;
- (id)initSourceTrackID:(CMPersistentTrackID)sourceTrackID forTimeRange:(CMTimeRange)timeRange rotateDegree:(CGFloat)degree natureSize:(CGSize)natureSize;
@end
