//
//  UIImage+Extension.m
//  MovieEditorDemo
//
//  Created by itaen on 2019/6/27.
//  Copyright © 2019 itaen. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)

- (UIImage *)gl_drawImageAspectFitInSize:(CGSize)size scale:(CGFloat)scale fillColor:(UIColor *)fillColor {
	if (!fillColor) {
		fillColor = [UIColor blackColor];
	}
	CGRect bounds = CGRectMake(0, 0, size.width, size.height);
	
	UIGraphicsBeginImageContextWithOptions(size, NO, scale);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGContextAddRect(ctx, bounds);
	
	[fillColor setFill];
	CGContextFillPath(ctx);
	
	CGFloat width = self.size.width;
	CGFloat height = self.size.height;
	
	float verticalRadio = size.height*1.0/height;
	float horizontalRadio = size.width*1.0/width;
	
	float ratio = MIN(verticalRadio, horizontalRadio);
	width = width*ratio;
	height = height*ratio;
	
	int xPos = (size.width - width)/2;
	int yPos = (size.height-height)/2;
	
		// 绘制改变大小的图片
	[self drawInRect:CGRectMake(xPos, yPos, width, height)];
	
	
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return result;
}

@end
