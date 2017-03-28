//
//  ViewController.m
//  JWDInputOutputStream
//
//  Created by 蒋伟东 on 2017/3/17.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "ViewController.h"
#import "JWDInteractionLogger.h"
#import "JWDOutputInputStream.h"
@interface ViewController ()<NSStreamDelegate>

@property (nonatomic, assign) NSInteger    location;//!< <#value#>
@property (nonatomic, strong) UIButton     *writeBtn;//!< <#value#>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *bitn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 50)];
    bitn.backgroundColor = [UIColor redColor];
    [bitn setTitle:@"读取文件" forState:UIControlStateNormal];
    [bitn addTarget:self action:@selector(doTestInputStream) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bitn];
    
    UIButton *write = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 100, 50)];
    write.backgroundColor = [UIColor redColor];
    [write setTitle:@"写入文件" forState:UIControlStateNormal];
    [write addTarget:self action:@selector(doTestOutputStream) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:write];
    
    
    UIButton *writeBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 300, 150, 50)];
    self.writeBtn = writeBtn;
    writeBtn.backgroundColor = [UIColor redColor];
    [writeBtn setTitle:@"封装的日志" forState:UIControlStateNormal];
    [writeBtn addTarget:self action:@selector(writeBtnDid) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:writeBtn];
    
    UIButton *sendLogBtn = [[UIButton alloc] initWithFrame:CGRectMake(200, 300, 150, 50)];
    sendLogBtn.backgroundColor = [UIColor redColor];
    [sendLogBtn setTitle:@"发送分享日志" forState:UIControlStateNormal];
    [sendLogBtn addTarget:self action:@selector(sendLogBtnDid) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendLogBtn];
}


- (void)doTestInputStream {

    [[JWDOutputInputStream shareOutputInputStream] creatInputStreamWithFilePath:@"/Users/jiangweidong/Desktop/Sign.txt"];
}

- (void)doTestOutputStream {
    
    [[JWDOutputInputStream shareOutputInputStream] creatOutputStreamWithFilePath:@"/Users/jiangweidong/Desktop/Sign-test.txt"];
}


- (void)writeBtnDid {
    
    self.writeBtn.backgroundColor = [UIColor greenColor];
    for (int i = 0; i<100; i++) {
        NSString *str = [NSString stringWithFormat:@"https://github.com/weidongjiang/JWDInputOutputStream/tree/master 喜欢就点个star %d",i];
        // 方式一
        [[JWDInteractionLogger shareInteractionLogger] writeLogWithLogString:str withfileName:JWDlogName];
        // 方式二
        JWDINSlog(str,JWDINSlogName);
        if (i==99) {
            [self.writeBtn setTitle:@"写入完成" forState:UIControlStateNormal];
        }
    }
}

- (void)sendLogBtnDid {

    [[JWDInteractionLogger shareInteractionLogger] sendLogFileWithFileName:JWDlogName];

}
@end
