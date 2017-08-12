//
//  QSViewController.m
//  QSOpenGLES001
//
//  Created by shaoqing on 17/2/19.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSViewController.h"

//设置顶点数组 和 索引数组
const GLfloat Vertices[] = {

    0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下(x,y,z坐标 + s,t纹理)
    -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
    -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    0.5, 0.5, 0.0f,    1.0f, 1.0f, //右上
};

//顶点索引
const GLuint indices[] = {
    0,1,2,
    1,3,0
};

@interface QSViewController ()

@property (nonatomic,strong)EAGLContext *context; //上下文环境
@property (nonatomic,strong)GLKBaseEffect *mEffect;  //着色器效果
@property (nonatomic,assign)int mCount;

@end

@implementation QSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor yellowColor];
    self.mCount = sizeof(indices) / sizeof(indices[0]);
    
    [self setupContext];
    [self setupVBOs];
    [self setupBaseEffect];
}

/**
 设置OpenGL ES上下文
 */
- (void)setupContext{
    
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    //颜色缓冲区格式
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    //self.context为OpenGL的"当前激活的Context"。之后所有"GL"指令均作用在这个Context上。
    if (![EAGLContext setCurrentContext:self.context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

/**
 创建Vertex Buffer 对象,这里有两种顶点缓存类型：一种是用于跟踪每个顶点信息的（Vertices），另一种是用于跟踪组成每个三角形的索引信息（我们的Indices)
 */

- (void)setupVBOs{
    
    //顶点信息数组buffer
    GLuint verticesBuffer;
    //创建一个Vertex Buffer 对象
    glGenBuffers(1, &verticesBuffer);
    //verticesBuffer 是指GL_ARRAY_BUFFER
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    //把顶点数据从cpu内存复制到gpu内存,GL_STATIC_DRAW表示此缓冲区内容只能被修改一次，但可以无限次读取。
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indicesBuffer;  //索引数组
    glGenBuffers(1, &indicesBuffer);  //申请一个标识符(索引数组buffer)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    //GL_STATIC_DRAW表示此缓冲区内容只能被修改一次，但可以无限次读取。
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    
    //开启对应的顶点属性
    glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数组缓存
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
    
    //为vertex shader的Position和TexCoord0配置合适的值
    
    //参数1:这个属性的名称
    //参数2:定义这个属性由多少个值组成。譬如说position是由3个GLfloat组成
    //参数3：声明每一个值是什么类型。我们都用了GL_FLOAT
    //参数4：GL_FALSE就好了
    //参数5：stride的大小，描述每个vertex数据的大小
    //参数6：是这个数据结构的偏移量。在这个结构中，从哪里开始获取我们的值。Position的值在前面，所以传(GLfloat *)NULL + 0进去就可以了。而纹理是紧接着位置的数据，而position的大小是3个float的大小，所以是从(GLfloat *)NULL + 3开始的
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
}

//创建着色器效果
- (void)setupBaseEffect{
    
//    GLKTextureLoader读取图片，创建纹理GLKTextureInfo
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"ic_dog" ofType:@"jpeg"];
    //GLKTextureLoaderOriginBottomLeft 参数是避免纹理上下颠倒，原因是纹理坐标系和世界坐标系的原点不同。
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil];
    //加载图片
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
//    创建着色器GLKBaseEffect，把纹理赋值给着色器
    self.mEffect = [[GLKBaseEffect alloc] init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    
    //启动着色器
    [self.mEffect prepareToDraw];
}

#pragma mark - GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //
    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    //绘制
    //参数1：声明用哪种特性来渲染图形。有GL_LINE_STRIP、GL_TRIANGLE_FAN和GL_TRIANGLE等。然而GL_TRIANGLE(三角形)最常用。
    //参数2: 告诉渲染器有多少个图形要渲染。通过Indices大小除以一个Indice类型的大小得到的。
    //参数3: 指每个indices中的index类型,GL_UNSIGNED_INT
    //参数4：它是一个指向indices的指针。已经存入缓存，这里不需要了.
    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
