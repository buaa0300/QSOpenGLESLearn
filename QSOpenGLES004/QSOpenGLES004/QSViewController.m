//
//  QSViewController.m
//  QSOpenGLES004
//
//  Created by zhongpingjiang on 17/2/23.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSViewController.h"

//前三个是顶点坐标， 后面三个是色值,最后两个是纹理坐标
//三角锥有5个顶点
static GLfloat vertices[] =
{
    -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f,    0.0f, 1.0f,//左上
    0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f,    1.0f, 1.0f,//右上
    -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f,    0.0f, 0.0f,//左下
    0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f,    1.0f, 0.0f,//右下
    0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f,    0.5f, 0.5f,//顶点
};

//顶点索引 (3D下的索引)
static GLuint indices[] =
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



@interface QSViewController (){

    float _xDegree;
    float _yDegree;
    float _zDegree;
    
    BOOL _isRotateX;
    BOOL _isRotateY;
    BOOL _isRotateZ;
    
}

@property (nonatomic,strong)EAGLContext *context;

@property (nonatomic,strong)GLKBaseEffect *bEffect;


@property (nonatomic,strong)UIButton *btn1;
@property (nonatomic,strong)UIButton *btn2;
@property (nonatomic,strong)UIButton *btn3;

@end

@implementation QSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _isRotateX = YES;
    [self setupBtns];
    [self setupContext];
    [self setupVBOs];
    [self setupDisplayLink];
}

- (void)setupBtns{
    
    [self.view addSubview:({
        _btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btn1 setTitle:@"绕X轴旋转" forState:UIControlStateNormal];
        [_btn1 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_btn1 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [_btn1 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _btn1.frame = CGRectMake(50, 50, 90, 40);
        [_btn1 addTarget:self action:@selector(rotateX) forControlEvents:UIControlEventTouchUpInside];
        _btn1;
    })];
    
    [self.view addSubview:({
        _btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btn2 setTitle:@"绕Y轴旋转" forState:UIControlStateNormal];
        [_btn2 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_btn2 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [_btn2 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _btn2.frame = CGRectMake(150, 50, 90, 40);
        [_btn2 addTarget:self action:@selector(rotateY) forControlEvents:UIControlEventTouchUpInside];
        _btn2;
    })];
    
    [self.view addSubview:({
        _btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btn3 setTitle:@"绕Z轴旋转" forState:UIControlStateNormal];
        [_btn3 setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_btn3 setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [_btn3 setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _btn3.frame = CGRectMake(250, 50, 90, 40);
        [_btn3 addTarget:self action:@selector(rotateZ) forControlEvents:UIControlEventTouchUpInside];
        _btn3;
    })];
}

- (void)setupContext{

    //新建
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];
}

- (void)setupVBOs{

    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint indicesBuffer;
    glGenBuffers(1, &indicesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    //顶点位置
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (GLfloat *)NULL + 0);
    
    //顶点颜色
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (GLfloat *)NULL + 3);
    
    //顶点纹理坐标
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (GLfloat *)NULL + 6);
    
    
    //纹理
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"ic_dog" ofType:@"jpeg"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft,nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];

    //着色器
    self.bEffect = [[GLKBaseEffect alloc]init];
    self.bEffect.texture2d0.enabled = GL_TRUE;
    self.bEffect.texture2d0.name = textureInfo.name;
    
    //投影
    CGSize size = self.view.frame.size;
    float aspect = fabs(size.width / size.height);
    //投影变化矩阵
    GLKMatrix4 projectMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90), aspect, 0.1f, 10.0f);
    projectMatrix = GLKMatrix4Scale(projectMatrix, 1.0f, 1.0f, 1.0f);
    self.bEffect.transform.projectionMatrix = projectMatrix;
    
    //
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    self.bEffect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)setupDisplayLink{

    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)update:(CADisplayLink *)display{
    
    _xDegree += _isRotateX * 0.1;
    _yDegree += _isRotateY * 0.1;
    _zDegree += _isRotateZ * 0.1;
    
//    变形、放大缩小、旋转的矩阵
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
    
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, _xDegree);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, _yDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, _zDegree);
    
    self.bEffect.transform.modelviewMatrix = modelViewMatrix;
}

#pragma mark - GLViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{

    glClearColor(0.3, 0.3, 0.3, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self.bEffect prepareToDraw];
    
    glDrawElements(GL_TRIANGLES, sizeof(vertices)/sizeof(GLint), GL_UNSIGNED_INT, 0);
}

- (void)rotateX{

    _isRotateX = !_isRotateX;
}

- (void)rotateY{
    
    _isRotateY = !_isRotateY;
}

- (void)rotateZ{
    
    _isRotateZ = !_isRotateZ;
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
