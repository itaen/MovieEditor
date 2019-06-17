//
//  GLCustomFilterRender.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLEditEnums.h"
@interface GLCustomFilterRender : NSObject
- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer type:(GLFilterType)type;
- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer effectBeffer:(CVPixelBufferRef)effectBuffer;
- (void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer degree:(CGFloat)rotateDegree natureSize:(CGSize)natureSize;

/**
 图片渲染添加动画效果

 @param destinationPixelBuffer <#destinationPixelBuffer description#>
 @param sourcePixelBuffer <#sourcePixelBuffer description#>
 @param time <#time description#>
 @param photoData <#photoData description#>
 @param tween <#tween description#>
 @param type <#type description#>
 */
- (void)renderPxielBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer time:(CGFloat)time photoData:(NSData *)photoData tween:(float)tween type:(GLPhotoAnimationType)type;
@end
