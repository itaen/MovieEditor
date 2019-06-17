//
//  GLMovieEditorUtil.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/5.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLMovieEditorUtil : NSObject

+ (NSString *)getCurrentDateString;


/**
 生成大神缓存视频文件夹内子文件夹，用于存放本地图片生成的视频

 @param name <#name description#>
 @return <#return value description#>
 */
+ (NSString *)cachePathWithName:(NSString *)name;

@end

