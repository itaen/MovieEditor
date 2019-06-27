//
//  UIImage+Extension.h
//  MovieEditorDemo
//
//  Created by itaen on 2019/6/27.
//  Copyright © 2019 itaen. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Extension)

- (UIImage *)gl_drawImageAspectFitInSize:(CGSize)size scale:(CGFloat)scale fillColor:(UIColor *)fillColor;

@end

NS_ASSUME_NONNULL_END
