//
//  GLTransitionVideoCompositionInstruction.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//


#import "GLTransitionVideoCompositionInstruction.h"

@implementation GLTransitionVideoCompositionInstruction
@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;
- (id)initTransitionWithSourceTrackIDs:(NSArray *)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange type:(GLTransitionType)type
{
    self = [super init];
    if (self) {
        _requiredSourceTrackIDs = sourceTrackIDs;
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _timeRange = timeRange;
        _containsTweening = TRUE;
        _enablePostProcessing = YES;
        _type = type;
    }
    
    return self;
}
@end
