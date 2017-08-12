//
//  QSOpenGLView.h
//  QSOpenGLES002
//
//  Created by zhongpingjiang on 17/2/16.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface QSOpenGLView : UIView{

    CAEAGLLayer *_eaglLayer;  
    EAGLContext *_context;  //EAGLContext对象管理所有通过OpenGL进行draw的信息
    GLuint _colorRenderBuffer;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    
    GLuint _projectionUniform;
    GLuint _modelViewUniform;  //移动
    
    float _currentRotation;  //旋转
    
    GLuint _depthRenderBuffer;
}

@end
