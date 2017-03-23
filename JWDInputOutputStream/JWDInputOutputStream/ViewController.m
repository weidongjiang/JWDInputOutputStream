//
//  ViewController.m
//  JWDInputOutputStream
//
//  Created by 蒋伟东 on 2017/3/17.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "ViewController.h"
#import "JWDInteractionLogger.h"

@interface ViewController ()<NSStreamDelegate>

@property (nonatomic, assign) NSInteger location;//!< <#value#>

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
    [write setTitle:@"写文件" forState:UIControlStateNormal];
    [write addTarget:self action:@selector(doTestOutputStream) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:write];
    
    
    UIButton *writeBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 300, 100, 50)];
    writeBtn.backgroundColor = [UIColor redColor];
    [writeBtn setTitle:@"封装的日志" forState:UIControlStateNormal];
    [writeBtn addTarget:self action:@selector(writeBtnDid) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:writeBtn];
    
}


- (void)writeBtnDid {
    
    for (int i = 0; i<100; i++) {
        NSString *str = [NSString stringWithFormat:@"https://github.com/weidongjiang/JWDInputOutputStream/tree/master 喜欢就点个star %d",i];
        
        [[JWDInteractionLogger shareInteractionLogger] writeLogWithLogString:str withfileName:@"日志"];
        
        JWDINSlog(str,@"宏定义的日志");
    }
    
}


- (void)doTestInputStream {
    NSString *path = @"/Users/jiangweidong/Desktop/Sign.txt";
    
    NSInputStream *readStream = [[NSInputStream alloc]initWithFileAtPath:path];
    [readStream setDelegate:self];
    
    [readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [readStream open]; //调用open开始读文件
}


#pragma mark -
#pragma mark - 写
- (NSData *)dataWillWrite {
    static  NSData *data = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        data = [NSData dataWithContentsOfFile:@"/Users/jiangweidong/Desktop/Sign.txt"];
    });
    
    return data;
}

- (void)doTestOutputStream {
    NSString *path = @"/Users/jiangweidong/Desktop/Signstream-write.txt";
    
    NSOutputStream *writeStream = [[NSOutputStream alloc] initToFileAtPath:path append:YES];
    [writeStream setDelegate:self];
    
    [writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [writeStream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable: {
            
            NSInteger bufSize = 1024;
            uint8_t buf[bufSize];
            
            if (self.location + bufSize > [self dataWillWrite].length) {
                [[self dataWillWrite] getBytes:buf
                                         range:NSMakeRange(self.location, self.location + bufSize - [self dataWillWrite].length)];
            }
            else {
                [[self dataWillWrite] getBytes:buf range:NSMakeRange(self.location, bufSize)];
            }
            
            NSOutputStream *writeStream = (NSOutputStream *)aStream;
            [writeStream write:buf maxLength:sizeof(buf)]; //把buffer里的数据，写入文件
            
            self.location += bufSize;
            if (self.location >= [[self dataWillWrite] length] ) { //写完后关闭流
                [aStream close];
            }
            
            
            NSInputStream *reads = (NSInputStream *)aStream;
            NSInteger blength = [reads read:buf maxLength:sizeof(buf)]; //把流的数据放入buffer
            NSData *data = [NSData dataWithBytes:(void *)buf length:blength];
            
            NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",string);
            
            
            
        }
            break;
            
        case NSStreamEventEndEncountered: {
            // 结束的时候关闭和一处流操作
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            aStream = nil;
        }
            break;
            
            //错误和无事件处理
        case NSStreamEventErrorOccurred:{
            
        }
            break;
        case NSStreamEventNone:
            break;
            
            //打开完成
        case NSStreamEventOpenCompleted: {
            NSLog(@"NSStreamEventOpenCompleted");
            
            
        }
            break;
            
        default:
            break;
    }
}



@end
