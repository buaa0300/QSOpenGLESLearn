//
//  QSDrawViewController.m
//  QSOpenGLES001
//
//  Created by zhongpingjiang on 17/2/27.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSDrawViewController.h"

//顶点属性
const GLfloat Vertices2[] = {
    
    0.5, -0.5, 0.0f,    1.0f, 0.0f, 0.0f, //右下(x,y,z坐标 + rgb颜色)
    -0.5, 0.5, 0.0f,    0.0f, 1.0f, 0.0f, //左上
    -0.5, -0.5, 0.0f,   0.0f, 0.0f, 1.0f, //左下
};

@interface QSDrawViewController()

@property (nonatomic,strong)EAGLContext *context; //上下文环境
@property (nonatomic,strong)GLKBaseEffect *mEffect;  //着色器效果

@end


@implementation QSDrawViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    
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
 创建Vertex Buffer 对象
 */
- (void)setupVBOs{

    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices2), Vertices2, GL_STATIC_DRAW);
    
    //开启对应的顶点属性
    glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数组缓存
    glEnableVertexAttribArray(GLKVertexAttribColor); //颜色
    
    //为vertex shader的Position和GLKVertexAttribColor配置合适的值
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (GLfloat *)NULL + 0);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (GLfloat *)NULL + 3);
}

//创建着色器效果
- (void)setupBaseEffect{
    
    self.mEffect = [[GLKBaseEffect alloc] init];


}

#pragma mark - GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //启动着色器
    [self.mEffect prepareToDraw];
    
    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //绘制
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
