//
//  GLCustomTransitionRender.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLEditEnums.h"
@interface GLCustomTransitionRender : NSObject
- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingForegroundSourceBuffer:(CVPixelBufferRef)foregroundPixelBuffer andBackgroundSourceBuffer:(CVPixelBufferRef)backgroundPixelBuffer forTweenFactor:(float)tween type:(GLTransitionType)type foregroundFilter:(GLFilterType)foregroundFilter backgroundFilter:(GLFilterType)backgroundFilter;
@end
