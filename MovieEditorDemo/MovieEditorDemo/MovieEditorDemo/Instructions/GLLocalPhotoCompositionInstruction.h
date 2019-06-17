//
//  GLLocalPhotoCompositionInstruction.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//



#import "GLBaseCustomVideoCompositionInsruction.h"
#import "GLEditEnums.h"

@interface GLLocalPhotoCompositionInstruction : GLBaseCustomVideoCompositionInsruction
@property CMPersistentTrackID sourceTrackID;
@property (nonatomic,strong) NSData *resizePhotoData;
@property (nonatomic,assign) GLPhotoAnimationType animationType;
- (instancetype)initSourceTrackID:(CMPersistentTrackID)sourceTrackID forTimeRange:(CMTimeRange)timeRange ;
@end
