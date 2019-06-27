//
//  GLCustomFilterRender.m
//  godlike_iOS
//
//  Created by itaen on 2019/3/4.
//  Copyright © 2019 NetEase. All rights reserved.
//

#import "GLCustomFilterRender.h"
#import <GLKit/GLKit.h>
#import "GLEditConst.h"

static const GLfloat quadVertexData1 [] = {
    -1.0, 1.0,
    1.0, 1.0,
    -1.0, -1.0,
    1.0, -1.0,
};

static const GLfloat quadTextureData1 [] = {
    0.0, 1.0,
    1.0, 1.0,
    0.0, 0.0,
    1.0,0.0,
};
 enum
{
    UNIFORM_SIMPLER,
    UNIFORM_SIMPLER2,
    UNIFORM_SIMPLER3,
    UNIFORM_ALPHA,
    UNIFORM_ROTATION_ANGLE,//旋转矩阵
    UNIFORM_COLOR_CONVERSION_MATRIX,// 色彩转换矩阵
    UNIFORM_TYPE,
    UNIFORM_INTENSITY,
    NUM_UNIFORMS
};
GLint filetUnforms[NUM_UNIFORMS];

enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBURTES
};
@interface GLCustomFilterRender()
@property CGAffineTransform renderTransform;
@property CVOpenGLESTextureCacheRef videoTextureCache;
@property EAGLContext *currentContext;
@property GLuint offscreenBufferHandle;
@property GLuint program;
@property BOOL isFirst;
@end
@implementation GLCustomFilterRender
-(instancetype)init
{
    self = [super init];
    if (self) {
        _currentContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_currentContext];
        [self setupOffscreenRenderContext];
        NSURL *vertexURL = [[NSBundle mainBundle] URLForResource:@"FilterVertex" withExtension:@"glsl"];
        NSURL *fragURL = [[NSBundle mainBundle] URLForResource:@"FilterFrag" withExtension:@"glsl"];
        [self loadVertexShader:vertexURL AndFragShader:fragURL];
        self.isFirst = YES;
    }
    
    return self;
}

- (void)setupOffscreenRenderContext
{
    //-- Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _currentContext, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Filter Error at CVOpenGLESTextureCacheCreate %d", err);
    }
    
    glDisable(GL_DEPTH_TEST);
    
    glGenFramebuffers(1, &_offscreenBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
}
-(BOOL)loadVertexShader:(NSURL *)vertexURL AndFragShader:(NSURL *)fragURL{
    GLuint vertShader,fragShader;
    _program = glCreateProgram();
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER URL:vertexURL]) {
        NSLog(@"Filter Failed to compile vertex shader");
        return NO;
    }
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER URL:fragURL]) {
        NSLog(@"Filter Failed to compile frag shader");
        return NO;
    }
    
    glAttachShader(_program, vertShader);
    
    glAttachShader(_program, fragShader);
	
	//index binding
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    if (![self linkProgram:_program]) {
        NSLog(@"Filter Faided to link program:%d",_program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    filetUnforms[UNIFORM_SIMPLER] = glGetUniformLocation(_program, "Sampler");
    filetUnforms[UNIFORM_SIMPLER2] = glGetUniformLocation(_program, "Sampler2");
    filetUnforms[UNIFORM_SIMPLER3] = glGetUniformLocation(_program, "Sampler3");
    filetUnforms[UNIFORM_ROTATION_ANGLE] = glGetUniformLocation(_program, "preferredRotation");
    filetUnforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(_program, "colorConversionMatrix");
    filetUnforms[UNIFORM_TYPE] = glGetUniformLocation(_program, "type");
    filetUnforms[UNIFORM_ALPHA] = glGetUniformLocation(_program, "alpha");
    filetUnforms[UNIFORM_INTENSITY] = glGetUniformLocation(_program, "intensity");
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL
{
    NSError *error;
    NSString *sourceString = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (sourceString == nil) {
        NSLog(@"Filter Failed to load shader : %@",[error localizedDescription]);
        return NO;
    }
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Filter Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}


- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Filter Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

-(void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer effectBeffer:(CVPixelBufferRef)effectBuffer
{
    [EAGLContext setCurrentContext:self.currentContext];
    
    if (sourcePixelBuffer || effectBuffer) {
        
        CVOpenGLESTextureRef foregroundTexture = [self sourceTextureForPixelBuffer:sourcePixelBuffer];
        CVOpenGLESTextureRef backgroundTexture = [self sourceTextureForPixelBuffer:effectBuffer];
        CVOpenGLESTextureRef destTexture       = [self sourceTextureForPixelBuffer:destinationPixelBuffer];
        glViewport(0, 0, kPhotoVideoWidth, kPhotoVideoHeight);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(backgroundTexture), CVOpenGLESTextureGetName(backgroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Transiton Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        }
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(_program);
        GLfloat quadVertexData1 [] = {
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
        };
        
        // texture data varies from 0 -> 1, whereas vertex data varies from -1 -> 1
        GLfloat quadTextureData1 [] = {
            0.5 + quadVertexData1[0]/2, 0.5 + quadVertexData1[1]/2,
            0.5 + quadVertexData1[2]/2, 0.5 + quadVertexData1[3]/2,
            0.5 + quadVertexData1[4]/2, 0.5 + quadVertexData1[5]/2,
            0.5 + quadVertexData1[6]/2, 0.5 + quadVertexData1[7]/2,
        };
        glUniform1i(filetUnforms[UNIFORM_SIMPLER], 0);
        glUniform1i(filetUnforms[UNIFORM_TYPE], 100);
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX);
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glFlush();
    bail:
        if (foregroundTexture) {
            CFRelease(foregroundTexture);
        }
        
        if (backgroundTexture) {
            CFRelease(backgroundTexture);
        }
        
        CFRelease(destTexture);
        // Periodic texture cache flush every frame
        CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
        [EAGLContext setCurrentContext:nil];
        
    }

}

-(void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer type:(GLFilterType)type
{
    NSLog(@"filter %lu",(unsigned long)type);
    [EAGLContext setCurrentContext:self.currentContext];
    if (sourcePixelBuffer) {
        CVOpenGLESTextureRef foregroundTexture = [self sourceTextureForPixelBuffer:sourcePixelBuffer];
        CVOpenGLESTextureRef destTexture       = [self sourceTextureForPixelBuffer:destinationPixelBuffer];
        glViewport(0, 0, kPhotoVideoWidth, kPhotoVideoHeight);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Filter Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        }
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(_program);

        if (type == GLFilterTypeOldSchool) {
        }else if (type == GLFilterTypeBlackWhite && self.isFirst)
        {
            [self setuplookUpTexture:@"lookup_黑白.png" type:1 ];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
            
        }else if (type == GLFilterTypeRomance  && self.isFirst)
        {
            
            [self setuplookUpTexture:@"lookup_amatorka.png" type:1];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
        }else if (type == GLFilterTypeRio && self.isFirst){
            [self setuplookUpTexture:@"color.png"type:1] ;
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
        }else if (type == GLFilterTypeCheEnShang && self.isFirst){
            [self setuplookUpTexture:@"color2.png" type:1];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
        }else if (type == GLFilterTypeAutumn && self.isFirst){
            [self setuplookUpTexture:@"color1" type:1];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER2], 1);
            [self setuplookUpTexture:@"color2" type:2];
            glUniform1i(filetUnforms[UNIFORM_SIMPLER3], 2);
        }
        glUniform1i(filetUnforms[UNIFORM_SIMPLER], 0);
        glUniform1i(filetUnforms[UNIFORM_TYPE], (int)type);
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData1);
        glEnableVertexAttribArray(ATTRIB_VERTEX);
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glEnableVertexAttribArray(ATTRIB_TEXCOORD);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glFlush();
    bail:
        if (foregroundTexture) {
            CFRelease(foregroundTexture);
        }
                CFRelease(destTexture);
        // Periodic texture cache flush every frame
        CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
        [EAGLContext setCurrentContext:nil];
        
    }

}

//在实际应用中，我们需要使用各种各样的缓存。比如在纹理渲染之前，需要生成一块保存了图像数据的纹理缓存。下面介绍一下缓存管理的一般步骤：
//
//使用缓存的过程可以分为 7 步：
//
//生成（Generate）：生成缓存标识符 glGenBuffers()
//
//绑定（Bind）：对接下来的操作，绑定一个缓存 glBindBuffer()
//
//缓存数据（Buffer Data）：从CPU的内存复制数据到缓存的内存 glBufferData() / glBufferSubData()
//
//启用（Enable）或者禁止（Disable）：设置在接下来的渲染中是否要使用缓存的数据 glEnableVertexAttribArray() / glDisableVertexAttribArray()
//
//设置指针（Set Pointers）：告知缓存的数据类型，及相应数据的偏移量 glVertexAttribPointer()
//
//绘图（Draw）：使用缓存的数据进行绘制 glDrawArrays() / glDrawElements()
//
//删除（Delete）：删除缓存，释放资源 glDeleteBuffers()

-(void)renderPxielBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer time:(CGFloat)time photoData:(NSData *)photoData tween:(float)tween type:(GLPhotoAnimationType)type
{
    [EAGLContext setCurrentContext:self.currentContext];
    CVOpenGLESTextureRef destTexture       = [self sourceTextureForPixelBuffer:destinationPixelBuffer];
    glViewport(0, 0, kPhotoVideoWidth, kPhotoVideoHeight);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Filter Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
	
	//代表四个顶点
    GLfloat quadVertexData1 [] = {
        -1.0, 1.0,//左上角
        1.0, 1.0,//右上角
        -1.0, -1.0,//左下角
        1.0, -1.0,//右下角
    };
    

    if (self.isFirst) {
        [self setupPhotoTexture:photoData];
    }
    glUniform1i(filetUnforms[UNIFORM_SIMPLER], 0);
    glUniform1i(filetUnforms[UNIFORM_TYPE], -1);
	//CPU数据上传至GPU
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData1);
	//glEnableVertexAttribArray启用指定属性.允许顶点着色器读取GPU（服务器端）数据
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
//    GLPhotoAnimationNone = - 1,//无效果
//    GLPhotoAnimationPushBottom = 0,//往图片下方推进
//    GLPhotoAnimationPushTop = 1,//往图片上方推进
//    GLPhotoAnimationPushRight = 2,//往图片右推进
//    GLPhotoAnimationPushLeft = 3,//图片左推进
//    GLPhotoAnimationPushScaleBig = 4,//图片放大效果
//    GLPhotoAnimationPushScaleSmall = 5,//图片缩小效果
    switch (type) {
        case GLPhotoAnimationPushBottom:
        {
		//
        GLfloat quadTextureData1 [] = {
            0.0, 0.75 + 0.25 * tween,//(0,0.75) -> (0,1)
            1.0, 0.75 + 0.25 * tween,//(1,0.75) -> (1,1)
            0.0, 0.25 * tween,		 //(0,0)    -> (0,0.25)
            1.0, 0.25 * tween,		 //(1,0)    -> (1,0.25)
        };
		
		// 使用glVertexAttribPointer函数告诉OpenGL该如何解析顶点数据
		/*
		 第一个参数GLuint indx:指定要配置的顶点属性，设置数据传递到指定位置顶点属性中
		 第二个参数GLint size：指定顶点属性的大小
		 第三个参数GLenum type：指定数据的类型，这里是GL_FLOAT(GLSL中vec*都是由浮点数值组成的)
		 第四个参数GLboolean normalized：定义数据是否被标准化(Normalize)。如果设置为GL_TRUE，所有数据都会被映射到0（对于有符号型signed数据是-1）到1之间。因为我们传入的数据就是标准化数据，所以我们把它设置为GL_FALSE
		 第五个参数GLsizei stride：设置连续的顶点属性组之间的间隔。由于下个组位置数据在3个float之后，
		 我们把步长设置为3 * sizeof(float)。要注意的是由于我们知道这个数组是紧密排列的（在两个顶点属性之间没有空隙）我们也可以设置为0来让OpenGL决定具体步长是多少（只有当数值是紧密排列时才可用）。
		 一旦我们有更多的顶点属性，我们就必须更小心地定义每个顶点属性之间的间隔，我们在后面会看到更多的例子
		 （这个参数的意思简单说就是从这个属性第二次出现的地方到整个数组0位置之间有多少字节）
		 最后一个参数const GLvoid *ptr：类型是void*，所以需要我们进行这个奇怪的强制类型转换。它表示位置数据在缓冲中起始位置的偏移量(Offset)。由于位置数据在数组的开头，所以这里是0。
		 */
		glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);
        }
            break;
        case GLPhotoAnimationPushTop:
        {
        GLfloat quadTextureData1 [] = {
            0.0, 1.0 - 0.25 * tween,
            1.0, 1.0 - 0.25 * tween,
            0.0, 0.25 * (1 - tween),
            1.0, 0.25 * (1 - tween),
        };
		glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);

        }
            break;
        case GLPhotoAnimationPushRight:
        {
        CGFloat scale = 0.8;
        GLfloat quadTextureData1 [] = {
            0.0 * scale + 0.2 * tween, 1.0,
            1.0 * scale + 0.2 * tween, 1.0,
            0.0 * scale + 0.2 * tween, 0.0,
            1.0 * scale + 0.2 * tween, 0.0,
        };
		glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);

        }
            break;
        case GLPhotoAnimationPushLeft:
        {
        GLfloat quadTextureData1 [] = {
            0.2 * (1 - tween), 1.0,
            0.8 + 0.2 * (1 - tween), 1.0,
            0.2 * (1 - tween), 0.0,
            0.8 + 0.2 * (1 - tween), 0.0,
        };
		glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);

        }
            break;
        case GLPhotoAnimationPushScaleBig:
        {
        GLfloat quadTextureData1 [] = {
            0.2 * tween, 1.0 - 0.2 * tween,
            1.0 - 0.2 * tween, 1.0 - 0.2 * tween,
            0.2 * tween,0.2 * tween,
            1.0 - 0.2 * tween, 0.2 * tween,
        };
		glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);

        }
            break;
        case GLPhotoAnimationPushScaleSmall:
        {
        GLfloat quadTextureData1 [] = {
            0.2 * (1.0 - tween), 0.8 + 0.2 * tween,
            0.8 + 0.2 * tween, 0.8 + 0.2 * tween,
            0.2 * (1.0 - tween), 0.2 * (1.0 - tween),
            0.8 + 0.2 * tween, 0.2 * (1.0 - tween),
        };
		glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);

        }
            break;
        case GLPhotoAnimationNone:
            glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);
        default:
            
            break;
    }
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();
bail:
    
    CFRelease(destTexture);
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    [EAGLContext setCurrentContext:nil];
}

-(void)renderPixelBuffer:(CVPixelBufferRef)destinationPixelBuffer usingSourceBuffer:(CVPixelBufferRef)sourcePixelBuffer degree:(CGFloat)rotateDegree natureSize:(CGSize)natureSize
{
    [EAGLContext setCurrentContext:self.currentContext];
    NSLog(@"%@",sourcePixelBuffer);
    CVOpenGLESTextureRef foregroundTexture = [self sourceTextureForPixelBuffer:sourcePixelBuffer];
    CVOpenGLESTextureRef destTexture       = [self sourceTextureForPixelBuffer:destinationPixelBuffer];
    glViewport(0, 0, kPhotoVideoWidth, kPhotoVideoHeight);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(CVOpenGLESTextureGetTarget(foregroundTexture), CVOpenGLESTextureGetName(foregroundTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destTexture), CVOpenGLESTextureGetName(destTexture), 0);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Filter Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
    
    

    GLfloat quadTextureData1 [] = {
        0.0, 1.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
    };
    
    GLfloat quadTextureData4[] = {
        0.0, 0.0,
        0.0,1.0,
        1.0,0.0,
        1.0,1.0,
    };
    GLfloat quadTextureData3[] = {
        1.0, 0.0,
        0.0,0.0,
        1.0,1.0,
        0.0,1.0,
    };
    GLfloat quadTextureData2[] = {
        1.0, 1.0,
        1.0,0.0,
        0.0,1.0,
        0.0,0.0,
    };
    
    CGFloat xscale = 1.0;
    CGFloat yscale = 1.0;
    CGFloat ratio = natureSize.width/natureSize.height;
	CGFloat solidRatio = kImageRatio;
    if (rotateDegree == 0.0 ) {
        if (ratio - solidRatio > 0.0001 && solidRatio - ratio < 0) {
            yscale = natureSize.height / natureSize.width * 0.5;
        }else if (ratio - solidRatio < 0.0001 && solidRatio - ratio > 0.0001 )
        {
            xscale = ratio * 0.5;
        }
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData1);
    }else if (rotateDegree == 90.0 ){
        ratio = natureSize.height / natureSize.width;
        if (ratio - solidRatio > 0.0001 && solidRatio - ratio < 0) {
            yscale = natureSize.height / natureSize.width * 0.5;
        }else if (ratio - solidRatio < 0.0001 && solidRatio - ratio > 0.0001)
        {
            xscale = ratio * 0.5;
        }
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData2);
    }else if (rotateDegree == 180.0){
        if (ratio - solidRatio > 0.0001 && solidRatio - ratio < 0) {
            yscale = natureSize.height / natureSize.width * 0.5;
        }else if ( ratio - solidRatio < 0.0001 && solidRatio - ratio > 0.0001)
        {
            xscale = ratio * 0.5;
        }
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData3);
    }else if (rotateDegree == 270.0){
        ratio = natureSize.height / natureSize.width;
        if (ratio - solidRatio > 0.0001 && solidRatio - ratio < 0) {
            yscale = natureSize.height / natureSize.width * 0.5;
        }else if (ratio - solidRatio < 0.0001 && solidRatio - ratio > 0.0001)
        {
            xscale = ratio * 0.5;
        }
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData4);
    }
    GLfloat quadVertexData [] = {
        -1.0 * xscale, 1.0 * yscale,
        1.0 * xscale, 1.0 * yscale,
        -1.0 * xscale, -1.0 * yscale,
        1.0 * xscale, -1.0 * yscale,
    };
    

    glUniform1i(filetUnforms[UNIFORM_SIMPLER], 0);
    glUniform1i(filetUnforms[UNIFORM_TYPE], (int)0);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();
bail:
    if (foregroundTexture) {
        CFRelease(foregroundTexture);
    }
    CFRelease(destTexture);
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
    [EAGLContext setCurrentContext:nil];
    
}

//生成纹理对象
- (GLuint)setupPhotoTexture:(NSData *)photoData{
    self.isFirst = NO;
	
    CGImageRef spriteImage = [UIImage imageWithData:photoData].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", photoData);
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);

	
    GLuint texture;
    glActiveTexture(GL_TEXTURE0);
//    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
	
	//二维纹理映射
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return 0;

}

- (GLuint)setuplookUpTexture:(NSString *)fileName type:(int)type {
    self.isFirst = NO;
    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage
    ;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);

    GLuint texture;
    if (type == 1) {
        glActiveTexture(GL_TEXTURE1);
    } else {
        glActiveTexture(GL_TEXTURE2);
    }
    
//    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return 0;
}
-(CVOpenGLESTextureRef)sourceTextureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef sourceTexture = NULL;
    CVReturn err;
    if (!_videoTextureCache) {
        NSLog(@" Filter No video texture cache");
        goto bail;
    }
    
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (int)CVPixelBufferGetWidth(pixelBuffer), (int)CVPixelBufferGetHeight(pixelBuffer), GL_RGBA, GL_UNSIGNED_BYTE, 0, &sourceTexture);
    if (err) {
        NSLog(@"Filter Error at creating luma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
bail:
    return sourceTexture;
}

- (void)dealloc
{
    NSLog(@"render dealloc ========================================");
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
    if (_offscreenBufferHandle) {
        glDeleteFramebuffers(1, &_offscreenBufferHandle);
        _offscreenBufferHandle = 0;
    }
}


@end
