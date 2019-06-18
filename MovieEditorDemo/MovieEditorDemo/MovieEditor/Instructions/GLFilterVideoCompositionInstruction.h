//
//  GLFilterVideoCompositionInstruction.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLBaseCustomVideoCompositionInsruction.h"
#import "GLEditEnums.h"
@interface GLFilterVideoCompositionInstruction : GLBaseCustomVideoCompositionInsruction
@property CMPersistentTrackID sourceTrackID;
@property CMPersistentTrackID effectTrackID;
@property GLFilterType filterType;
- (id)initSourceTrackID:(CMPersistentTrackID)sourceTrackID forTimeRange:(CMTimeRange)timeRange type:(GLFilterType)type;
- (id)initSourceTrackID:(NSArray *)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange;
@end
