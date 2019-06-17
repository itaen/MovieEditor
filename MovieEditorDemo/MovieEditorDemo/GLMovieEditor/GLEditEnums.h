//
//  GLEditEnums.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#ifndef GLEditEnums_h
#define GLEditEnums_h

typedef NS_ENUM(NSInteger, GLPhotoAnimationType) {
    GLPhotoAnimationNone = -1,//无效果
    GLPhotoAnimationPushBottom = 0,//往图片下方推进
    GLPhotoAnimationPushTop = 1,//往图片上方推进
    GLPhotoAnimationPushRight = 2,//往图片右推进
    GLPhotoAnimationPushLeft = 3,//图片左推进
    GLPhotoAnimationPushScaleBig = 4,//图片放大效果
    GLPhotoAnimationPushScaleSmall = 5,//图片缩小效果
};

//见着色器TransitionFrag.glsl相关实现
//参考效果来源: https://github.com/gl-transitions/gl-transitions
typedef NS_ENUM(NSUInteger, GLTransitionType) {
    GLRenderTransisionTypeNone = 0,
    GLRenderTransisionTypeWipeHorizontal,
    GLRenderTransisionTypeWipeVertical,
    GLRenderTransisionTypeDissolve,
    GLRenderTransisionTypePinwheel,// 转轮
    GLRenderTransisionTypeWind,
    GLRenderTransisionTypeRipple,
    GLRenderTransisionTypePixelize,
    GLRenderTransisionTypePowDistortion,
    GLRenderTransisionTypeWindowSlide
};

typedef NS_ENUM(NSUInteger, GLFilterType) {
    GLFilterTypeNone = 0,
    GLFilterTypeColorInvert,// 反色
    GLFilterTypeOldSchool,// 怀旧
    GLFilterTypeBlackWhite,// 黑白
    GLFilterTypeRomance,// 浪漫
    GLFilterTypePainting,// 彩绘
    GLFilterTypeFishEye,// 鱼眼
    GLFilterTypeRio,// 里约大冒险
    GLFilterTypeCheEnShang,// 车恩尚
    GLFilterTypeAutumn,// 瑞秋
};

typedef NS_ENUM(NSUInteger, GLEffectType) {
    GLEffectTypeNone = 0,
    GLEffectTypeLight,
};
typedef NS_ENUM(NSUInteger, GLTextStyle) {
    GLTextStyleNormal = 0,
    GLTextStyleDouble,
    GLTextStyleImage,
};

typedef NS_ENUM(NSUInteger, GLMovieEditorToolButtonTye) {
    GLMovieEditorToolButtonTyeFilter,
    GLMovieEditorToolButtonTyeTransition,
    GLMovieEditorToolButtonTyePhotoReOrder,
};


#endif /* GLEditEnums_h */
