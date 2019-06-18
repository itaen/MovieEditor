//
//  GLTransitionVideoCompositionInstruction.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLBaseCustomVideoCompositionInsruction.h"
#import "GLCustomTransitionRender.h"
#import "GLEditEnums.h"

@interface GLTransitionVideoCompositionInstruction : GLBaseCustomVideoCompositionInsruction
@property CMPersistentTrackID foregroundTrackID;
@property CMPersistentTrackID backgroundTrackID;
@property (assign,nonatomic)  GLTransitionType type;
@property (assign,nonatomic)  GLFilterType foregroundFilter;
@property (assign,nonatomic)  GLFilterType backgroundFilter;
- (id)initTransitionWithSourceTrackIDs:(NSArray*)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange type:(GLTransitionType)type;
@end
