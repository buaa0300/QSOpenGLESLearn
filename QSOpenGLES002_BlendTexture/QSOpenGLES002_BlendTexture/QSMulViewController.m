//
//  QSMulViewController.m
//  QSOpenGLES002_BlendTexture
//
//  Created by zhongpingjiang on 17/3/1.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSMulViewController.h"

typedef struct {
    GLKVector3  positionCoords;
    GLKVector2  textureCoords;
}
SceneVertex;

SceneVertex vertices2[] =
{
    {{-1.0f, -0.67f, 0.0f}, {0.0f, 0.0f}},  // first triangle
    {{ 1.0f, -0.67f, 0.0f}, {1.0f, 0.0f}},
    {{-1.0f,  0.67f, 0.0f}, {0.0f, 1.0f}},
    {{ 1.0f, -0.67f, 0.0f}, {1.0f, 0.0f}},  // second triangle
    {{-1.0f,  0.67f, 0.0f}, {0.0f, 1.0f}},
    {{ 1.0f,  0.67f, 0.0f}, {1.0f, 1.0f}},
};

@interface QSMulViewController()

@property (nonatomic,strong)EAGLContext *context;
@property (nonatomic,strong)GLKBaseEffect *baseEffect;

@property (nonatomic,strong)GLKTextureInfo *textureInfo0;
@property (nonatomic,strong)GLKTextureInfo *textureInfo1;


@end

@implementation QSMulViewController

- (void)viewDidLoad{
    
    [super viewDidLoad];
    self.navigationItem.title = @"多重纹理";
    [self setup];
}


- (void)setup{
    
    //1、设置上下文
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    //2、设置顶点信息数组缓存
    [self setupVBO];
    
    [self setupMultipleTexture];
}


- (void)setupVBO{
    
    GLuint vertices2Buffer;
    glGenBuffers(1, &vertices2Buffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertices2Buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices2), vertices2, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord1);
    
    //offsetof:求结构体中一个成员在该结构体中的偏移量
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL + offsetof(SceneVertex, positionCoords));
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL + offsetof(SceneVertex, textureCoords));
    glVertexAttribPointer(GLKVertexAttribTexCoord1, 2, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL + offsetof(SceneVertex, textureCoords));
}


- (void)setupMultipleTexture{
    
    CGImageRef imageRef0 = [[UIImage imageNamed:@"leaves.gif"] CGImage];
    self.textureInfo0 = [GLKTextureLoader textureWithCGImage:imageRef0 options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft, nil] error:nil];
    
    CGImageRef imageRef1 = [[UIImage imageNamed:@"beetle.png"] CGImage];
    self.textureInfo1 = [GLKTextureLoader textureWithCGImage:imageRef1 options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],GLKTextureLoaderOriginBottomLeft, nil] error:nil];
    
    self.baseEffect = [[GLKBaseEffect alloc] init];
    
    self.baseEffect.texture2d0.name = self.textureInfo0.name;
    self.baseEffect.texture2d0.target = self.textureInfo0.target;
    
    self.baseEffect.texture2d1.name = self.textureInfo1.name;
    self.baseEffect.texture2d1.target = self.textureInfo1.target;
    self.baseEffect.texture2d1.envMode = GLKTextureEnvModeDecal;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.baseEffect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
}


@end
