//
//  GLCustomVideoCompositor.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLCustomVideoCompositor.h"
#import "GLBaseCustomVideoCompositionInsruction.h"
#import "GLPassthroughVideoCompositionInstruction.h"
#import "GLTransitionVideoCompositionInstruction.h"
#import "GLFilterVideoCompositionInstruction.h"
#import "GLCustomTransitionRender.h"
#import "GLCustomFilterRender.h"
#import "GLLocalVideoCompositionInstruction.h"
#import "GLLocalPhotoCompositionInstruction.h"
@interface GLCustomVideoCompositor()
{
    BOOL								_shouldCancelAllRequests;
    BOOL								_renderContextDidChange;
    dispatch_queue_t					_renderingQueue;
    dispatch_queue_t					_renderContextQueue;
    AVVideoCompositionRenderContext*	_renderContext;
    GLCustomTransitionRender *_transitionRender;
    GLCustomFilterRender *_filterRender;
}
@property(nonatomic,strong) GLCustomTransitionRender *transitionRender;
@property(nonatomic,strong) GLCustomFilterRender *filterRender;
@end
@implementation GLCustomVideoCompositor
- (id)init
{
    self = [super init];
    if (self)
    {
        _renderingQueue = dispatch_queue_create("com.godlike.dev.renderingqueue", DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create("com.godlike.dev.rendercontextqueue", DISPATCH_QUEUE_SERIAL);
        _renderContextDidChange = NO;

    }
    return self;
}


- (NSDictionary *)sourcePixelBufferAttributes
{
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext
{
    NSLog(@"change %@",newRenderContext);
    dispatch_sync(_renderContextQueue, ^() {
		self->_renderContext = newRenderContext;
		self->_renderContextDidChange = YES;
    });
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{
	
        dispatch_async(_renderingQueue,^() {
			@autoreleasepool {
				if (self->_shouldCancelAllRequests) {
					[request finishCancelledRequest];
				} else {
					NSError *err = nil;
					
					CVPixelBufferRef resultPixels = [self newRenderedPixelBufferForRequest:request error:&err];
					
					if (resultPixels) {
						[request finishWithComposedVideoFrame:resultPixels];
						CFRelease(resultPixels);
					} else {
						[request finishWithError:err];
					}
				}
			}
        });
}
static Float64 factorForTimeInRange(CMTime time, CMTimeRange range) /* 0.0 -> 1.0 */
{
    CMTime elapsed = CMTimeSubtract(time, range.start);
    return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration);
}

- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
    CVPixelBufferRef dstPixels = nil;
    
    NSLog(@"playedTime:%@,duration:%@",[NSValue valueWithCMTime:request.compositionTime],[NSValue valueWithCMTime:request.videoCompositionInstruction.timeRange.duration]);
    float tweenFactor = factorForTimeInRange(request.compositionTime, request.videoCompositionInstruction.timeRange);
    
    GLBaseCustomVideoCompositionInsruction *currentInstruction = (GLBaseCustomVideoCompositionInsruction *)request.videoCompositionInstruction;
    if ([currentInstruction isKindOfClass:[GLTransitionVideoCompositionInstruction class]]) {
        
        GLTransitionVideoCompositionInstruction *transitionInstruction = (GLTransitionVideoCompositionInstruction *)currentInstruction;
        NSLog(@"transition type : %ld",transitionInstruction.type);
        CVPixelBufferRef foregroundSourceBuffer = [request sourceFrameByTrackID:transitionInstruction.foregroundTrackID];
        CVPixelBufferRef backgroundSourceBuffer = [request sourceFrameByTrackID:transitionInstruction.backgroundTrackID];
        dstPixels = [_renderContext newPixelBuffer];
        [self.transitionRender renderPixelBuffer:dstPixels usingForegroundSourceBuffer:foregroundSourceBuffer andBackgroundSourceBuffer:backgroundSourceBuffer forTweenFactor:tweenFactor type:transitionInstruction.type foregroundFilter:transitionInstruction.foregroundFilter backgroundFilter:transitionInstruction.backgroundFilter];
    }else if ([currentInstruction isKindOfClass:[GLFilterVideoCompositionInstruction class]])
    {
        NSLog(@"filter");
        GLFilterVideoCompositionInstruction *filterInstruction = (GLFilterVideoCompositionInstruction *)currentInstruction;
        dstPixels = [_renderContext newPixelBuffer];
        CVPixelBufferRef sourceBuffer = [request sourceFrameByTrackID:filterInstruction.sourceTrackID];
        [self.filterRender renderPixelBuffer:dstPixels usingSourceBuffer:sourceBuffer type:filterInstruction.filterType];
    }else if ([currentInstruction isKindOfClass:[GLLocalVideoCompositionInstruction class]])
    {
        NSLog(@"local");
        GLLocalVideoCompositionInstruction *videoInstruction = (GLLocalVideoCompositionInstruction *)currentInstruction;
        dstPixels = [_renderContext newPixelBuffer];
        CVPixelBufferRef sourceBuffer = [request sourceFrameByTrackID:videoInstruction.sourceTrackID];
        [self.filterRender renderPixelBuffer:dstPixels usingSourceBuffer:sourceBuffer degree:videoInstruction.degree natureSize:videoInstruction.natureSize];
    
    }else
    {
        GLLocalPhotoCompositionInstruction *videoInstruction = (GLLocalPhotoCompositionInstruction *)currentInstruction;
        dstPixels = [_renderContext newPixelBuffer];
        CVPixelBufferRef sourceBuffer = [request sourceFrameByTrackID:videoInstruction.sourceTrackID];
        [self.filterRender renderPxielBuffer:dstPixels usingSourceBuffer:sourceBuffer time:CMTimeGetSeconds(videoInstruction.timeRange.duration) photoData:videoInstruction.resizePhotoData tween:tweenFactor type:videoInstruction.animationType];
    }
    if (!dstPixels) {
        NSLog(@"disPixels is nil");
    }
    return dstPixels;
}
- (void)cancelAllPendingVideoCompositionRequests
{
    _shouldCancelAllRequests = YES;
    
    dispatch_barrier_async(_renderingQueue, ^() {
        
		self->_shouldCancelAllRequests = NO;
    });
}

-(GLCustomFilterRender *)filterRender
{
    if (!_filterRender) {
        _filterRender = [[GLCustomFilterRender alloc] init];
    }
    return _filterRender;
}

-(GLCustomTransitionRender *)transitionRender
{
    if (!_transitionRender) {
        _transitionRender = [[GLCustomTransitionRender alloc] init];
    }
    return _transitionRender;
}
@end
