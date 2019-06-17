//
//  GLLocalVideoCompositionInstruction.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLLocalVideoCompositionInstruction.h"

@implementation GLLocalVideoCompositionInstruction
@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;
-(id)initSourceTrackID:(CMPersistentTrackID)sourceTrackID forTimeRange:(CMTimeRange)timeRange rotateDegree:(CGFloat)degree natureSize:(CGSize)natureSize
{
    self = [super init];
    if (self) {
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _requiredSourceTrackIDs = @[@(sourceTrackID)];
        _sourceTrackID = sourceTrackID;
        _timeRange = timeRange;
        _containsTweening = YES;
        _enablePostProcessing = YES;
        _degree = degree;
        _natureSize = natureSize;
    }
    return self;
}
@end
