//
//  GLEditTransitionModel.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/11.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLEditTransitionModel.h"

@interface GLEditTransitionModel ()

@property (nonatomic,assign) GLTransitionType type;
@property (nonatomic,copy)   NSString *transitionName;
@property (nonatomic,copy)   NSString *transitionIconName;

@end

@implementation GLEditTransitionModel

- (instancetype)initWithDuration:(CGFloat)duration type:(GLTransitionType)type {
    self = [super init];
    if (self) {
        self.duration = duration;
        _type = type;
        [self getTransitionName:_type];
    }
    return self;
}

- (void)getTransitionName:(GLTransitionType)type {
    self.transitionName = @"无";
    self.transitionIconName = @"transition_none";
    
    switch (type) {
        case GLRenderTransisionTypeNone:
        {
        self.transitionName = @"无";
        self.transitionIconName = @"transition_none";
        }
            break;
        case GLRenderTransisionTypeDissolve:
        {
        self.transitionName = @"擦除";
        }
            break;
        case GLRenderTransisionTypePinwheel:
        {
        self.transitionName = @"转轮";
        }
            break;
        case GLRenderTransisionTypeWind:
        {
        self.transitionName = @"微风";
        }
            break;
        case GLRenderTransisionTypeRipple:
        {
        self.transitionName = @"波纹";
        }
            break;
        case GLRenderTransisionTypePixelize:
        {
        self.transitionName = @"像素";
        }
            break;
        case GLRenderTransisionTypePowDistortion:
        {
        self.transitionName = @"梦幻";
        }
            break;
        case GLRenderTransisionTypeWindowSlide:
        {
        self.transitionName = @"波浪";
        }
            break;
        case GLRenderTransisionTypeWipeHorizontal:
        {
        self.transitionName = @"横向";

        }
            break;
        case GLRenderTransisionTypeWipeVertical:
        {
        self.transitionName = @"纵向";
        }
            break;
            
    }
}

@end
