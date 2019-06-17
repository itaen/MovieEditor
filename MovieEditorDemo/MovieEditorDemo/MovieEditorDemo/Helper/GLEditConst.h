//
//  GLEditConst.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/6.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN const CGFloat kTransitionTime;  // 转场时长
UIKIT_EXTERN const CGFloat kPhotoVideoTime;  // 图片生成的视频时长
UIKIT_EXTERN const NSUInteger kPhotoVideoFPS;  // 图片帧率
UIKIT_EXTERN NSNotificationName const GLMovieEditorNeedReloadDataNotification;
UIKIT_EXTERN NSNotificationName const GLLocalPhotoRenderProgressNotification;


//https://discussions.apple.com/thread/1802274?answerId=8525272022#8525272022
//https://stackoverflow.com/questions/37850502/ios-crop-video-weird-green-line-left-and-bottom-side-in-video
//video render size must divided by 16 / 8 / 4

	//iphone设备、iphoneX判断宏
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_Pad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define IsLandscape   ([UIScreen mainScreen].bounds.size.height < [UIScreen mainScreen].bounds.size.width)
#define UIScreenWidth                   (IsLandscape ? ([UIScreen mainScreen].bounds.size.height): [UIScreen mainScreen].bounds.size.width)
#define UIScreenHeight                  (IsLandscape ? ([UIScreen mainScreen].bounds.size.width): [UIScreen mainScreen].bounds.size.height)

#define SCREEN_MAX_LENGTH (MAX(UIScreenWidth, UIScreenHeight))
#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5_OR_5S (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_5_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 667.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)
#define IS_IPHONE_X (IS_IPHONE && SCREEN_MAX_LENGTH == 812.0)
#define IS_IPHONE_X_SERIES (IS_IPHONE && ((SCREEN_MAX_LENGTH == 812.0) || (SCREEN_MAX_LENGTH == 896.0)))

#define kImageRatio 	    IS_IPHONE_X_SERIES ? (kXPhonePhotoVideoWidth/kXPhonePhotoVideoHeight) : (kNormalPhonePhotoVideoWidth/kNormalPhonePhotoVideoHeight)
#define kPhotoVideoWidth  	IS_IPHONE_X_SERIES ? (kXPhonePhotoVideoWidth) : (kNormalPhonePhotoVideoWidth)
#define kPhotoVideoHeight   IS_IPHONE_X_SERIES ? (kXPhonePhotoVideoHeight) :  (kNormalPhonePhotoVideoHeight)

#define kNormalPhonePhotoVideoWidth 	 (720.f)
#define kNormalPhonePhotoVideoHeight	 (1280.f)

#define kXPhonePhotoVideoWidth 		     (720.f)
#define kXPhonePhotoVideoHeight          (1560.f)



@interface GLEditConst : NSObject

@end

