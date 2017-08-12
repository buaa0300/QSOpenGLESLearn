//
//  ViewController.m
//  QSOpenGLESLearn002
//
//  Created by shaoqing on 17/2/19.
//  Copyright © 2017年 Jiang. All rights reserved.
//

#import "ViewController.h"
#import "QSOpenGLView.h"

@interface ViewController ()

@property (nonatomic,strong)QSOpenGLView *glView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:({
        _glView = [[QSOpenGLView alloc]initWithFrame:self.view.bounds];
        _glView;
    })];
    

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
