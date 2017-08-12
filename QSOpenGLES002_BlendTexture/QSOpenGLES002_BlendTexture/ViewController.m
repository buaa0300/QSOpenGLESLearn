//
//  ViewController.m
//  QSOpenGLES002_BlendTexture
//
//  Created by zhongpingjiang on 17/3/1.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "ViewController.h"
#import "QSViewController.h"
#import "QSMulViewController.h"

static NSString * const kCellReuseIdentifier = @"kCellReuseIdentifier";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong)UITableView *tableView;
@property (nonatomic,strong)NSMutableArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.dataSource = @[@"混合",@"多重纹理"].mutableCopy;
    
    [self.view addSubview:self.tableView];
    
}

- (UITableView *)tableView{
    
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.dataSource = self;
    }
    return _tableView;
}


#pragma mark - UITableViewDataSource
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return [self.dataSource count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellReuseIdentifier];
    }
    
    NSString *content = [self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = content;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    GLKViewController *vc = nil;
    switch (indexPath.row) {
        case 0:{
            vc = [[QSViewController alloc]init];
        }
            break;
            
        case 1:{
            vc = [[QSMulViewController alloc]init];
        }
            
            break;
            
        default:
            break;
    }
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
