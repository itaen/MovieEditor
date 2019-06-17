//
//  GLEditTransitionModel.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/11.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GLEditBaseModel.h"
#import "GLEditEnums.h"


@interface GLEditTransitionModel : GLEditBaseModel

@property (nonatomic,assign, readonly) GLTransitionType type;
@property (nonatomic,copy, readonly) NSString *transitionName;
@property (nonatomic,copy, readonly) NSString *transitionIconName;

- (instancetype)initWithDuration:(CGFloat)duration type:(GLTransitionType)type;

@end


