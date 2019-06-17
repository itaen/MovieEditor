//
//  GLMovieEditorUtil.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/5.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLMovieEditorUtil.h"
@implementation GLMovieEditorUtil

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

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"localPhotoMovie"];
    NSError *error;
    BOOL isDir;
    BOOL exsited = [[NSFileManager defaultManager] fileExistsAtPath:tempPath isDirectory:&isDir];
    if (!isDir || !exsited) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tempPath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error]; //Create folder
    }
    return [tempPath stringByAppendingPathComponent:name];
    
    
}

@end
