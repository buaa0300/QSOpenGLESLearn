//
//  QSViewController.m
//  QSOpenGLES002_纹理
//
//  Created by zhongpingjiang on 17/2/28.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSViewController.h"

typedef struct {
    GLKVector3  positionCoords;
    GLKVector2  textureCoords;
}SceneVertex;

static SceneVertex vertices[] =
{
    {{-0.5f, -0.5f, 0.0f}, {0.0f, 0.0f}}, // lower left corner
    {{ 0.5f, -0.5f, 0.0f}, {1.0f, 0.0f}}, // lower right corner
    {{-0.5f,  0.5f, 0.0f}, {0.0f, 1.0f}}, // upper left corner
};

static const SceneVertex defaultVertices[] =
{
    {{-0.5f, -0.5f, 0.0f}, {0.0f, 0.0f}},
    {{ 0.5f, -0.5f, 0.0f}, {1.0f, 0.0f}},
    {{-0.5f,  0.5f, 0.0f}, {0.0f, 1.0f}},
};


@interface QSViewController()

@property (nonatomic,strong)EAGLContext *context;
@property (nonatomic,strong)GLKBaseEffect *baseEffect;

@property (nonatomic,strong)UILabel *filterLabel;
@property (nonatomic,strong)UILabel *repeatLabel;
@property (nonatomic,strong)UISwitch *filterSwitchBtn;
@property (nonatomic,strong)UISwitch *repeatSwitchBtn;
@property (nonatomic,strong)UISlider *slider;

@property (nonatomic,assign)BOOL shouldUseNearestFilter; //是否使用邻近过滤
@property (nonatomic,assign)BOOL shouldRepeatTexture;   //是否使用重复环绕

@property (nonatomic,assign)CGFloat sCoordinateOffset;

@end


@implementation QSViewController

- (void)viewDidLoad{

    [super viewDidLoad];

    self.shouldUseNearestFilter = YES;
    self.shouldRepeatTexture = YES;
    
    [self setupSubViews];
    [self setup];
}

- (void)setupSubViews{
    
    self.filterLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 150, 20)];
    self.filterLabel.textColor = [UIColor whiteColor];
    self.filterLabel.text = @"NearestFilter";
    [self.view addSubview:self.filterLabel];
    
    self.filterSwitchBtn = [[UISwitch alloc]initWithFrame:CGRectMake(15, 44, 150, 30)];
    [self.filterSwitchBtn addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    [self.filterSwitchBtn setOn:self.shouldUseNearestFilter];
    [self.view addSubview:self.filterSwitchBtn];
    
    self.repeatLabel = [[UILabel alloc]initWithFrame:CGRectMake(200, 10, 200, 20)];
    self.repeatLabel.textColor = [UIColor whiteColor];
    self.repeatLabel.text = @"RepeatWrap";
    [self.view addSubview:self.repeatLabel];
    
    self.repeatSwitchBtn = [[UISwitch alloc]initWithFrame:CGRectMake(200, 44, 150, 30)];
    [self.repeatSwitchBtn setOn:self.shouldRepeatTexture];
    [self.repeatSwitchBtn addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.repeatSwitchBtn];
    
    self.slider = [[UISlider alloc]initWithFrame:CGRectMake(15, self.view.frame.size.height - 50, self.view.frame.size.width - 30, 20)];

    self.slider.maximumValue = 1;
    self.slider.minimumValue = -1;
    self.slider.value = 0.0f;
    [self.slider addTarget:self action:@selector(valueChange:) forControlEvents:(UIControlEventValueChanged)];
    [self.view addSubview:self.slider];

}

- (void)setup{
    
    //1、设置上下文
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    //2、设置顶点信息数组缓存
    [self setupVBO];
    
    //3、加载纹理，创建着色器
    CGImageRef imageRef = [[UIImage imageNamed:@"grid.png"] CGImage];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:imageRef options:nil error:nil];
    self.baseEffect = [[GLKBaseEffect alloc]init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
}


- (void)setupVBO{
    
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);
}

- (void)reintVBO{

    [self setupVBO];
}

#pragma mark -  GLKViewDeleate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{

    [self draw];
}

- (void)update{

    [self updateVertexPositions];
    [self updateTextureParameter];
    
    [self reintVBO];
}

- (void)updateVertexPositions {

    
    for(int i = 0; i < 3; i++)
    {
        vertices[i].positionCoords.x = defaultVertices[i].positionCoords.x;
        vertices[i].positionCoords.y = defaultVertices[i].positionCoords.y;
        vertices[i].positionCoords.z = defaultVertices[i].positionCoords.z;
    }


    for(int i = 0; i < 3; i++)
    {
        vertices[i].textureCoords.s = (defaultVertices[i].textureCoords.s + self.sCoordinateOffset);
    }
}

- (void)updateTextureParameter{
    
    glTexParameteri(self.baseEffect.texture2d0.target,
                    GL_TEXTURE_WRAP_S,
                    self.shouldRepeatTexture ? GL_REPEAT : GL_CLAMP_TO_EDGE);
    
    //放大(少数纹素映射片元)
    glTexParameteri(self.baseEffect.texture2d0.target,
                    GL_TEXTURE_MAG_FILTER,
                    self.shouldUseNearestFilter ? GL_NEAREST : GL_LINEAR);
}

- (void)draw{

    [self.baseEffect prepareToDraw];
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    
    //offsetof:求结构体中一个成员在该结构体中的偏移量
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL + offsetof(SceneVertex, positionCoords));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL + offsetof(SceneVertex, textureCoords));
    
    //绘制
    glDrawArrays(GL_TRIANGLES, 0, 3);
}


#pragma mark -
-(void)switchAction:(id)sender{
    
    UISwitch *switchButton = (UISwitch*)sender;
    BOOL isButtonOn = [switchButton isOn];
    
    if (switchButton == self.repeatSwitchBtn) {
        self.shouldRepeatTexture = isButtonOn;
    }else{
        self.shouldUseNearestFilter = isButtonOn;
    }
}

- (void)valueChange:(UISlider *)slider{

    self.sCoordinateOffset = [slider value];
}

@end
