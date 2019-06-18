//
//  GLPassthroughVideoCompositionInstruction.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLBaseCustomVideoCompositionInsruction.h"

@interface GLPassthroughVideoCompositionInstruction : GLBaseCustomVideoCompositionInsruction
- (id)initPassThroughTrackID:(CMPersistentTrackID)passthroughTrackID forTimeRange:(CMTimeRange)timeRange;
@end
