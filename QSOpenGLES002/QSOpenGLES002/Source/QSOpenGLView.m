//
//  QSOpenGLView.m
//  QSOpenGLES002
//
//  Created by zhongpingjiang on 17/2/21.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSOpenGLView.h"
#import <OpenGLES/ES2/gl.h>

//前三个是顶点坐标(x,y,z)， 后面两个是纹理坐标(s,t)
static GLfloat vertices[] =
{
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f,  //右下
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,  //左上
    -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,  //左下
    0.5f, 0.5f, -1.0f,      1.0f, 1.0f,  //右上
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,  //左上
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f,  //右下
};

//顶点着色器的文件名
static NSString * const kVertexFileName = @"vertex";
//片段着色器的文件名
static NSString * const kFragmentFileName = @"fragment";

@interface QSOpenGLView(){

    GLuint _colorRenderBuffer;
    GLuint _colorFrameBuffer;
}

@property (nonatomic,strong)EAGLContext* context;
@property (nonatomic,strong)CAEAGLLayer *eaglayer;

@end


@implementation QSOpenGLView

- (instancetype)initWithFrame:(CGRect)frame{

    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        GLuint shader = [self compileShader];
        [self setupValueForShader:shader];
        [self setupTexture:@"ic_dog.jpeg"];
        [self render];
    }
    return self;
}

#pragma mark -  使用CAEAGLLayer图层
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer{

    self.eaglayer = (CAEAGLLayer*) self.layer;
    //设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.eaglayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.eaglayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    
}


/**
 设置OpenGL 上下文环境
 */
- (void)setupContext{

    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }

    //设置为当前上下文
    if (![EAGLContext setCurrentContext:self.context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}


/**
 设置渲染缓存区
 */
- (void)setupRenderBuffer{
    
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    _colorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
  
    //分配内存空间
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglayer];
}


/**
 设置帧缓存区
 */
- (void)setupFrameBuffer{

    GLuint buffer;
    glGenFramebuffers(1, &buffer);
        _colorFrameBuffer = buffer;
    glBindFramebuffer(GL_FRAMEBUFFER, _colorFrameBuffer);

    //将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
}


/**
 设置纹理
 */
- (GLuint)setupTexture:(NSString *)fileName{

    // 1、使用CoreGraphics把图像转换成bitmap data
    // 获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    //在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);

    // 2、设置纹理环绕和过滤方式，加载图片形成纹理
    
    GLuint texture;
    glGenBuffers(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    //纹理环绕
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);   //超出纹理坐标s轴的部分，会重复纹理坐标的边缘，产生一种边缘被拉伸的效果
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);   //超出纹理坐标t轴的部分，会重复纹理坐标的边缘，产生一种边缘被拉伸的效果
    
    //纹理过滤
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );   //纹理缩小，采用邻近过滤(GL_NEAREST)
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );   //纹理放大，采用线性过滤(GL_LINEAR)
    
    float fw = width, fh = height;
    //加载图片形成纹理
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return 0;
}

/**
 *  glsl的编译过程主要有glCompileShader、glAttachShader、glLinkProgram三步；
 *
 *  @return 编译成功的shaders
 */
- (GLuint)compileShader{
    
    GLuint verShader, fragShader;
    GLint program = glCreateProgram();
    
    //1、编译shader
    NSString* vertFilePath = [[NSBundle mainBundle] pathForResource:kVertexFileName ofType:@"glsl"];
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vertFilePath];
    
    NSString* fragFilePath = [[NSBundle mainBundle] pathForResource:kFragmentFileName ofType:@"glsl"];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragFilePath];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //2、链接
    glLinkProgram(program);
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) { //连接错误
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error%@", messageString);
        return 0;
    }
    else {
        NSLog(@"link ok");
        glUseProgram(program); //激活着色器，成功便使用，避免由于未使用导致的的bug
    }
    
    //3、释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

/**
  编译shader功能函数
 */
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取字符串
    NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);

    GLint compileSuccess;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(*shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
}

/**
 * 为编译好的着色器中的顶点、纹理坐标和旋转矩阵赋值
 *
 **/
- (void)setupValueForShader:(GLuint)shader{

    //将顶点数据拷贝到GPU
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);
    
    
    //设置position值
    GLuint position = glGetAttribLocation(shader, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);
    
    //设置textCoordinate值
    GLuint textCoor = glGetAttribLocation(shader, "textCoordinate");
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(textCoor);
    
    //获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    GLuint rotate = glGetUniformLocation(shader, "rotateMatrix");
    
    float radians = 10 * 3.14159f / 180.0f;
    float s = sin(radians);
    float c = cos(radians);
    
    //z轴旋转矩阵
    GLfloat zRotation[16] = { //
        c, -s, 0, 0.2, //
        s, c, 0, 0,//
        0, 0, 1.0, 0,//
        0.0, 0, 0, 1.0//
    };
    
    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
}


/**
 渲染，最后一步
 */
- (void)render{
    
    //清屏
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    
    glDrawArrays(GL_TRIANGLES, 0, 6);  //6是顶点的数量
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
