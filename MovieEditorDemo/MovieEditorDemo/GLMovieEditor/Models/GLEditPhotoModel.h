//
//  GLEditPhotoModel.h
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLEditBaseModel.h"

@interface GLEditPhotoModel : GLEditBaseModel

@property (nonatomic ,strong)   NSData  *resizePhotoData;
@property (nonatomic ,strong)   NSData  *originPhotoData;
@property (nonatomic ,assign)   GLPhotoAnimationType type;

@end

