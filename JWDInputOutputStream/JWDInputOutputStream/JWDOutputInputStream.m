//
//  JWDOutputInputStream.m
//  JWDInputOutputStream
//
//  Created by 蒋伟东 on 2017/3/23.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "JWDOutputInputStream.h"


@interface JWDOutputInputStream ()<NSStreamDelegate>

@property (nonatomic, assign) NSInteger        location;//!< <#value#>
@property (nonatomic, strong) NSString         *contentFilePath;//!< 读取内容的地址


@end

@implementation JWDOutputInputStream


static JWDOutputInputStream *outputInputStream = nil;
+ (JWDOutputInputStream *)shareOutputInputStream {
 
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        outputInputStream = [[JWDOutputInputStream alloc] init];
    });
    return outputInputStream;
}

/**
 读取文件

 @param filePath 需要读取文件的地址
 */
- (void)creatInputStreamWithFilePath:(NSString *) filePath {
    NSInputStream *readStream = [[NSInputStream alloc]initWithFileAtPath:filePath];
    [readStream setDelegate:self];
    [readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [readStream open]; //调用open开始读文件
}


#pragma mark -
#pragma mark - 写

/**
 把需要写入的内容转换成 data

 @return data
 */
- (NSData *)dataWillWrite{
    static  NSData *data = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        data = [NSData dataWithContentsOfFile:@"/Users/jiangweidong/Desktop/Sign.txt"];//@"/Users/jiangweidong/Desktop/Sign.txt"
    });
    return data;
}

/**
 创建 写入流

 @param filePath 内容写入的文件地址
 */
- (void)creatOutputStreamWithFilePath:(NSString *) filePath{ // @"/Users/jiangweidong/Desktop/Signstream-write.txt";
    NSOutputStream *writeStream = [[NSOutputStream alloc] initToFileAtPath:filePath append:YES];
    [writeStream setDelegate:self];
    [writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [writeStream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable: {
            
            NSInteger bufSize = 5;
            uint8_t buf[bufSize];
            if (self.location > [self dataWillWrite].length) {
                [[self dataWillWrite] getBytes:buf range:NSMakeRange(self.location, self.location + bufSize - [self dataWillWrite].length)];
            }else if(self.location == [self dataWillWrite].length){
                [aStream close];
                [[self dataWillWrite] getBytes:buf range:NSMakeRange(self.location, bufSize)];
            }else {
                [[self dataWillWrite] getBytes:buf range:NSMakeRange(self.location, bufSize)];
            }
            
            NSOutputStream *writeStream = (NSOutputStream *)aStream;
            [writeStream write:buf maxLength:sizeof(buf)]; //把buffer里的数据，写入文件
            
            self.location += bufSize;
            if (self.location >= [[self dataWillWrite] length] ) { //写完后关闭流
                [aStream close];
            }
            

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
