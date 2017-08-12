//
//  QSOpenGLView.m
//  QSOpenGLES002
//
//  Created by zhongpingjiang on 17/2/21.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSOpenGLView.h"
#import <OpenGLES/ES2/gl.h>
#import "GLESUtils.h"
#import "GLESMath.h"

//前三个是顶点坐标， 后面三个是色值
//三角锥有5个顶点
static GLfloat vertices[] =
{
    -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
    0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
    -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
    0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
    0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,  //顶点
};

//顶点索引 (3D下的索引)
GLuint indices[] =
{
    //bottom (矩形)
    0, 2, 3,
    0, 3, 1,

    //四个侧面(三角形)
    0, 2, 4,
    0, 4, 1,
    1, 4, 3,
    4, 2, 3,
 
};

//顶点着色器的文件名
static NSString * const kVertexFileName = @"vertex";
//片段着色器的文件名
static NSString * const kFragmentFileName = @"fragment";

@interface QSOpenGLView(){

    GLuint _colorRenderBuffer;
    GLuint _colorFrameBuffer;
    
    GLuint _projectionMatrixSlot;
    GLuint _modelViewMatrixSlot;
    
    float _xDegree;
    float _yDegree;
    
    BOOL _isRotateX;
    BOOL _isRotateY;
    
    CADisplayLink *_displayLink;
}

@property (nonatomic,strong)UIButton *btn1;
@property (nonatomic,strong)UIButton *btn2;

@property (nonatomic,strong)EAGLContext* context;
@property (nonatomic,strong)CAEAGLLayer *eaglayer;

@end


@implementation QSOpenGLView

- (instancetype)initWithFrame:(CGRect)frame{

    self = [super initWithFrame:frame];
    if (self) {
        [self setupBtns];
        [self setupLayer];
        [self setupContext];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        GLuint shader = [self compileShader];
        [self setupValueForShader:shader];
        
        _isRotateX = YES; //默认绕X轴旋转
        [self setupDisPlayLink];

    }
    return self;
}

- (void)setupBtns{
    
    [self addSubview:({
        _btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btn1 setTitle:@"绕X轴旋转" forState:UIControlStateNormal];
        [_btn1 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_btn1 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [_btn1 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _btn1.frame = CGRectMake(50, 50, 90, 40);
        [_btn1 addTarget:self action:@selector(rotateX) forControlEvents:UIControlEventTouchUpInside];
        _btn1;
    })];
    
    [self addSubview:({
        _btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btn2 setTitle:@"绕Y轴旋转" forState:UIControlStateNormal];
        [_btn2 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_btn2 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [_btn2 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _btn2.frame = CGRectMake(150, 50, 90, 40);
        [_btn2 addTarget:self action:@selector(rotateY) forControlEvents:UIControlEventTouchUpInside];
        _btn2;
    })];
}

- (void)setupDisPlayLink{

    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)rotateX{
    
    _isRotateX = !_isRotateX;
}

- (void)rotateY{
    
    _isRotateY = !_isRotateY;
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

    // 1获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
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
    
    // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片段着色器里面的colorMap，如果有多张图不可以这么做）
    glBindTexture(GL_TEXTURE_2D, 0);
    
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
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
        glUseProgram(program); //成功便使用，避免由于未使用导致的的bug
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

    //将顶点数据信息(vertices + indices)拷贝到GPU
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);  //
    
    GLuint indicesBuffer;
    glGenBuffers(1, &indicesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);  //

    //设置position值
    GLuint position = glGetAttribLocation(shader, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    glEnableVertexAttribArray(position);
    
    //设置positionColor值
    GLuint positionColor = glGetAttribLocation(shader, "positionColor");
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
    glEnableVertexAttribArray(positionColor);
    
    //初始化
    _projectionMatrixSlot = glGetUniformLocation(shader, "projectionMatrix");
    _modelViewMatrixSlot = glGetUniformLocation(shader, "modelViewMatrix");
}


/**
  定时渲染
 */
- (void)render:(CADisplayLink*)displayLink{
    
    //清屏
    glClearColor(0, 0.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    _xDegree += _isRotateX * 5;
    _yDegree += _isRotateY * 5;
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    
     /** _projectionMatrixSlot set begin  **/
    //透视变换
    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = width / height; //纵横比(长宽比)
    
    //参数1：最终的变换矩阵
    //参数2：y方向的视角
    //参数3：纵横比 aspect
    //参数4：近平面距离
    //参数5：远平面距离
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f); //透视变换，视角30°
    
    //设置glsl里面的透视投影矩阵（立体效果）
    glUniformMatrix4fv(_projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    /** _projectionMatrixSlot set end  **/

    //面剔除,所有的不是正面朝向的面都会被丢弃,性能优化，这里不使用
//    glEnable(GL_CULL_FACE);

    //几何变换
    //_modelViewMatrix初始化
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    
    //平移
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0); //平移后的矩阵
    
    //_rotationMatrix初始化
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);
    
    //旋转
    ksRotate(&_rotationMatrix, _xDegree, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&_rotationMatrix, _yDegree, 0.0, 1.0, 0.0); //绕Y轴
    
//    把变换矩阵相乘，注意先后顺序
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
//     设置model-view matrix
    glUniformMatrix4fv(_modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    
    //在每个vertex上调用我们的vertex shader，以及每个像素调用fragment shader，最终画出我们的矩形。
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, 0);
    
    //把缓冲区（render buffer和color buffer）的颜色呈现到UIView上。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}



@end
