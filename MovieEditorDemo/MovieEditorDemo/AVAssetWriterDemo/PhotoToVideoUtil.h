//
//  PhotoToVideoUtil.h
//  MovieEditorDemo
//
//  Created by 檀文 on 2019/6/16.
//  Copyright © 2016 Netease. All rights reserved.
//

@import AVFoundation;
@import Foundation;
@import UIKit;

//将指定照片转化为固定长度视频

typedef void(^MMMovieMakerCompletion)(NSURL *fileURL);

#if __has_feature(objc_generics) || __has_extension(objc_generics)
#define MMVideo_GENERIC_URL <NSURL *>
#define MMVideo_GENERIC_IMAGE <UIImage *>
#else
#define MMVideo_GENERIC_URL
#define MMVideo_GENERIC_IMAGE
#endif

@interface PhotoToVideoUtil : NSObject
@property (nonatomic, copy) MMMovieMakerCompletion completionBlock;

- (instancetype)initWithSettings:(NSDictionary *)videoSettings;
- (void)createMovieFromImages:(NSArray MMVideo_GENERIC_IMAGE*)images withCompletion:(MMMovieMakerCompletion)completion;
+ (NSString *)cachePathWithName:(NSString *)name;
+ (NSDictionary *)videoSettingsWithCodec:(NSString *)codec withWidth:(CGFloat)width andHeight:(CGFloat)height;


@end
