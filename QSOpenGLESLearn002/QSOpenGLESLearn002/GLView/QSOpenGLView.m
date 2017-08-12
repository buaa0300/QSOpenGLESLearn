//
//  QSOpenGLView.m
//  QSOpenGLES001
//
//  Created by zhongpingjiang on 17/2/16.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSOpenGLView.h"
#import "CC3GLMatrix.h"

//所有顶点信息的结构Vertex,包含位置和颜色
typedef struct {
    float Position[3];
    float Color[4];
}Vertex;

//const Vertex vertices[] = {
//
//    {{1,-1,0},{1,0,0,1}},
//    {{1,1,0},{0,1,0,1}},
//    {{-1,1,0},{0,0,1,1}},
//    {{-1,-1,0},{0,0,0,1}}
//};

const Vertex vertices[] = {

    {{1,-1,0},{1,0,0,1}},
    {{1,1,0},{0,1,0,1}},
    {{-1,1,0},{0,0,1,1}},
    {{-1,-1,0},{0,0,0,1}},
    {{1,-1,-1},{1,0,0,1}},
    {{1,1,-1},{0,1,0,1}},
    {{-1,1,-1},{0,0,1,1}},
    {{-1,-1,-1},{0,0,0,1}}
};

//三角形定点的数据
//const GLubyte Indices[] = {
//    0,1,2,
//    2,3,0
//};
const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4    
};


@implementation QSOpenGLView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];

        //编译
        [self compileShaders];
        
        [self setupVBOs];
        
        [self setupDisplayLink];
        
//        [self render];
    }
    return self;
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

//想要显示OpenGL的内容，你需要把它缺省的layer设置为一个特殊的layer。（CAEAGLLayer）。这里通过直接复写layerClass的方法。
+ (Class)layerClass{
    
    return [CAEAGLLayer class];
}

- (void)setupLayer{

    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES; //缺省的话，CALayer是透明的。而透明的层对性能负荷很大，特别是OpenGL的层

}


//创建OpenGL context
- (void)setupContext{

    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;

    _context = [[EAGLContext alloc]initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

//创建一个depth Buffer
- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

//创建render buffer (渲染缓存区)
- (void)setupRenderBuffer{
    
    //render buffer: 用于存放渲染过的图像。
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    //为render buffer分配空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

//创建一个 frame buffer （帧缓冲区）
- (void)setupFrameBuffer {
    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    //把前面创建的buffer render依附在frame buffer的GL_COLOR_ATTACHMENT0位置上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    
    // Add to end of setupFrameBuffer
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}



//清理屏幕
- (void)render:(CADisplayLink*)displayLink {
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0); //设置一个RGB颜色和透明度，接下来会用这个颜色涂满全屏
//    glClear(GL_COLOR_BUFFER_BIT); //“填色”的动作,GL_COLOR_BUFFER_BIT声明要清理哪一个缓冲区

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];

    //每3.14秒，0 - -7循环一次
    [modelView populateFromTranslation:CC3VectorMake(sin(CACurrentMediaTime()), 0, -7)];

    
    _currentRotation += displayLink.duration *90; //每秒会增加90度
    [modelView rotateBy:CC3VectorMake(_currentRotation, _currentRotation, 0)];
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);

    //设置渲染部分
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    //为vertex shader的两个输入参数配置两个合适的值
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot,4,GL_FLOAT,GL_FALSE,sizeof(Vertex),(GLvoid*)(sizeof(float) * 3));
    
    //在每个vertex上调用我们的vertex shader，以及每个像素调用fragment shader，最终画出我们的矩形。
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER]; //把缓冲区（render buffer和color buffer）的颜色呈现到UIView上。
}


//编译vertex shader 和frament shader。
//把它们俩关联起来
//告诉OpenGL来调用这个程序，还需要一些指针什么的。

- (void)compileShaders {
    
    // 1、编译
    GLuint vertexShader = [self compileShader:@"SimpleVertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    // 调用了glCreateProgram 、glAttachShader 、 glLinkProgram 连接 vertex 和 fragment shader成一个完整的program
    GLuint programHandle = glCreateProgram();
    
    //
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // 调用 glGetProgramiv  lglGetProgramInfoLog 来检查是否有error，并输出信息。
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    //  调用 glUseProgram  让OpenGL真正执行你的program
    glUseProgram(programHandle);
    
    // 最后，调用 glGetAttribLocation 来获取指向 vertex shader传入变量的指针。以后就可以通过这写指针来使用了。
    //调用 glEnableVertexAttribArray来启用这些数据。（因为默认是 disabled的。）

    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    
    //add
//    通过调用glGetUniformLocation 来获取在vertex shader中的Projection输入变量
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    
    //然后，使用math library来创建投影矩阵。通过这个让你指定坐标，以及远近屏位置的方式，来创建矩阵，会让事情比较简单。
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    
    //把数据传入到vertex shader的方式，叫做 glUniformMatrix4fv. 这个CC3GLMatrix类有一个很方便的方法 glMatrix,来把矩阵转换成OpenGL的array格式
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    //
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");

}


//根据文件名称来动态编译着色器
- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 创建一个代表shader 的OpenGL对象。这时你必须告诉OpenGL，你想创建 fragment shader还是vertex shader。所以便有了这个参数：shaderType
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 让OpenGL获取到这个shader的源代码。（就是我们写的那个）这里我们还把NSString转换成C-string
    const char* shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 最后，调用glCompileShader 在运行时编译shader
    glCompileShader(shaderHandle);
    
    // 编译失败，把error信息输出到屏幕，退出
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

- (void)setupVBOs{

    //顶点信息
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);    //创建一个vertexBuffer对象
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);  //告诉OpenGL我们的vertexBuffer 是指GL_ARRAY_BUFFER
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW); // 把数据传到OpenGL-land
    
    //三角形索引信息
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}


- (void)dealloc{

    _context = nil;
}



@end
