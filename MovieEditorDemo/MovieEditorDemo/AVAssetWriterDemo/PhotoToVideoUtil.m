//
//  PhotoToVideoUtil.m
//  MovieEditorDemo
//
//  Created by 檀文 on  2019/6/16.
//  Copyright © 2016 Netease. All rights reserved.
//

#import "PhotoToVideoUtil.h"

typedef UIImage*(^CEMovieMakerUIImageExtractor)(NSObject* inputObject);

@interface PhotoToVideoUtil ()

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *writerInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *bufferAdapter;
@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, assign) CMTime frameTime;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) AVAsset *videoAsset;
@end

@implementation PhotoToVideoUtil

+ (NSString *)getCurrentDateString
{
    NSDate *currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSString *resultString = [dateFormatter stringFromDate: currentTime];
    return resultString;
}



+ (NSString *)cachePathWithName:(NSString *)name
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths firstObject];
	//转化后的视频存放位置
	NSString *tempPath = [documentsDirectory stringByAppendingPathComponent:@"com.netease.movieEditor"];
	
	NSString *covertedVideoPath = [tempPath stringByAppendingPathComponent:name];
								
	
	NSError *error;
	BOOL isDir;
	BOOL exsited = [[NSFileManager defaultManager] fileExistsAtPath:tempPath isDirectory:&isDir];
	if (!isDir || !exsited) {
		[[NSFileManager defaultManager] createDirectoryAtPath:tempPath
								  withIntermediateDirectories:NO
												   attributes:nil
														error:&error]; //Create folder
	}

	return [covertedVideoPath copy];
}


- (instancetype)initWithSettings:(NSDictionary *)videoSettings;
{
    self = [self init];
    if (self) {

		NSError *error;
		
		_fileURL = [NSURL fileURLWithPath:[PhotoToVideoUtil cachePathWithName:[[PhotoToVideoUtil getCurrentDateString] stringByAppendingPathExtension:@"mov"]]];
        _assetWriter = [[AVAssetWriter alloc] initWithURL:self.fileURL
                                                 fileType:AVFileTypeQuickTimeMovie error:&error];
        if (error) {
            NSLog(@"Error: %@", error.debugDescription);
        }
        NSParameterAssert(self.assetWriter);
        
        _videoSettings = videoSettings;
        _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                          outputSettings:videoSettings];
        NSParameterAssert(self.writerInput);
        NSParameterAssert([self.assetWriter canAddInput:self.writerInput]);
        
        [self.assetWriter addInput:self.writerInput];
        //设置实时写入，防止expectsMediaDataInRealTime返回NO导致死循环内存暴增
        //一般是 push-style buffer source 需要用到这个，例如视频录制、音频录制
        _writerInput.expectsMediaDataInRealTime = YES;
        NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
        
        //声明输出视频格式相近的缓冲区属性。写入性能更好
        _bufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:bufferAttributes];
        
        _frameTime = CMTimeMake(1, 1);
    }
    return self;
}

- (void)createMovieFromImageURLs:(NSArray MMVideo_GENERIC_URL*)urls withCompletion:(MMMovieMakerCompletion)completion;
{
    [self createMovieFromSource:urls extractor:^UIImage *(NSObject *inputObject) {
        return [UIImage imageWithData: [NSData dataWithContentsOfURL:((NSURL*)inputObject)]];
    } withCompletion:completion];
}

- (void)createMovieFromImages:(NSArray MMVideo_GENERIC_IMAGE *)images withCompletion:(MMMovieMakerCompletion)completion;
{
    [self createMovieFromSource:images extractor:^UIImage *(NSObject *inputObject) {
        return (UIImage*)inputObject;
    } withCompletion:completion];
}

- (void)createMovieFromSource:(NSArray *)images extractor:(CEMovieMakerUIImageExtractor)extractor withCompletion:(MMMovieMakerCompletion)completion;
{
    self.completionBlock = completion;
    
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    __block NSInteger i = 0;
    
    NSInteger frameNumber = [images count];
    
    [self.writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        
        while (i < frameNumber){
            
            if ([self.writerInput isReadyForMoreMediaData]) {
                UIImage* img = extractor([images objectAtIndex:i]);
                if (img == nil) {
                    i++;
                    NSLog(@"Warning: could not extract one of the frames");
                    continue;
                }
                CVPixelBufferRef sampleBuffer = [self newPixelBufferFromCGImage:[img CGImage]];
                
                if (sampleBuffer) {
                    if (i == 0) {
                        [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:kCMTimeZero];
                    }else{
                        CMTime lastTime = CMTimeMake((i-1)*self.frameTime.value, self.frameTime.timescale);
                        CMTime presentTime = CMTimeAdd(lastTime, self.frameTime);
                        [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:presentTime];
                    }
                    CVPixelBufferRelease(sampleBuffer);
                    i++;
                }
            }
        }
        
        [self.writerInput markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:^{
			dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(self.fileURL);
            });
        }];
        
        CVPixelBufferPoolRelease(self.bufferAdapter.pixelBufferPool);
    }];
}

- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    //16 的整数倍
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 4 * frameWidth,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           CGImageGetWidth(image),
                                           CGImageGetHeight(image)),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (NSDictionary *)videoSettingsWithCodec:(NSString *)codec withWidth:(CGFloat)width andHeight:(CGFloat)height
{
    
    if ((int)width % 16 != 0 ) {
        NSLog(@"Warning:.");
    }
    
    NSDictionary *videoSettings = @{AVVideoCodecKey : codec,
                                    AVVideoWidthKey : [NSNumber numberWithInt:(int)width],
                                    AVVideoHeightKey : [NSNumber numberWithInt:(int)height]};
    
    return videoSettings;
}

@end
