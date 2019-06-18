//
//  GLEditVideoModel.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/6.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLEditVideoModel.h"

@implementation GLEditVideoModel

-(void)setAsset:(AVURLAsset *)asset
{
    _asset = asset;
    if ([self getVideoDegree] == 90.0) {
        self.rotateDegree = 90.0;
    }
}

-(CGFloat)getVideoDegree
{
    AVAssetTrack *videoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    return [self degressFromAssetTrack:videoTrack];
}

// all local photo export video is landscape
- (CGFloat)degressFromAssetTrack:(AVAssetTrack *)track
{
    CGFloat degress = 0.0;
    CGAffineTransform t = track.preferredTransform;
    
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
        degress = 90.0;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
        degress = 270.0;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight default ios video orientation
        degress = 0;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
        degress = 180.0;
    }
    
    return degress;
}

@end
