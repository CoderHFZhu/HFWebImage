//
//  ViewController.m
//  HFWebImage
//
//  Created by CoderHF on 2018/9/14.
//  Copyright © 2018年 CoderHF. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
@interface ViewController ()<UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *arr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = 80;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    self.arr = [NSMutableArray arrayWithObjects:@"http://img.hb.aicdn.com/e8dcfa28c24d4dd842590b53ad56076150f49292bf71-xV5yo8_fw658",@"12345678",@"http://img.hb.aicdn.com/7a97dc8e93950cc320ad72938c450dccb35f94d422155-ccWfgv_fw658", nil];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.arr.count * 10;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    [cell.imageView hf_loadImageWithUrl:self.arr[indexPath.row % 3] placeholderImage:[UIImage imageNamed:@"1"]];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
//    cell.imageView.image = [UIImage imageNamed:@"1"];
    NSLog(@"%@", [UIImage imageNamed:@"1"]);
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
