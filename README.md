# JWDInputOutputStream
#利用NSStream、NSOutputStream、NSInputStream写文件，一句话实现实时动态打日志，UIDocumentInteractionController 分享日志文件。


##一句话实现实时动态打日志

一、在开发中我们会遇到各种各样的问题，各式的坑轮番轰炸。个人认为基本上大部分是数据处理和数据对接造成的比较多，也比较难找，如果是联机调试，那么还好找一点，但是如果是打包给测试同事，或者是线上的奔溃，那么跟踪数据就变得不那么好找了。

要是有数据日志记录该多好，那么为了方便解bug，动态打日志，并且能够方便分享发送日志文件，产生了这个demo。

二、所涉及的技术NSStream、NSOutputStream、NSInputStream 采用数据流，动态把数据写入本地存储。UIDocumentInteractionController 采用系统的分享来发送日志文件。

三、demo 代码

###3.1JWDOutputInputStream
```
- (void)doTestInputStream {

    [[JWDOutputInputStream shareOutputInputStream] creatInputStreamWithFilePath:@"/Users/jiangweidong/Desktop/Sign.txt"];
}

- (void)doTestOutputStream {
    
    [[JWDOutputInputStream shareOutputInputStream] creatOutputStreamWithFilePath:@"/Users/jiangweidong/Desktop/Sign-test.txt"];
}
```
上面 doTestInputStream 和 doTestOutputStream 是利用 NSStream 的代理来实现 把一个文件的数据 写入到指定的地址，
导入 JWDOutputInputStream 类即可使用。

```
JWDOutputInputStream.h
#import <Foundation/Foundation.h>

@interface JWDOutputInputStream : NSObject

+ (JWDOutputInputStream *)shareOutputInputStream;

/**
 读取文件
 
 @param filePath 需要读取文件的地址
 */
- (void)creatInputStreamWithFilePath:(NSString *) filePath;
/**
 创建 写入流
 
 @param filePath 内容写入的文件地址
 */
- (void)creatOutputStreamWithFilePath:(NSString *) filePath;
@end
```

```
JWDOutputInputStream.m
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
```
网上这样使用NSStream 的很多，这里就不细致说明。


###3.2 JWDInteractionLogger
重点说一下 JWDInteractionLogger

3.2.1
```
+(JWDInteractionLogger *)shareInteractionLogger {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        interactionLogger = [[JWDInteractionLogger alloc] init];
    });
    return interactionLogger;
}
```
使用单例作为全局统一打日志，只要引入头文件 即可一句话动态打日志，
方式一：宏 引入
```
/**
 日志文件名在这里 统一 标记，作为全局的名称

 */
#define JWDlogName     @"star"
#define JWDINSlogName  @"more-star"

/**
 只需要引入 宏 传递相应的参数

 @param logString 需要记录的日志内容
 @param fileName 日志文件名
 @return 日志宏
 */
#define JWDINSlog(logString,fileName) [[JWDInteractionLogger shareInteractionLogger] writeLogWithLogString:logString withfileName:fileName]
```

方式二：方法引入
```
+(JWDInteractionLogger *)shareInteractionLogger;

/**
 使用单例 调用

 @param logString 需要记录的日志内容
 @param fileName 日志文件名
 */
- (void)writeLogWithLogString:(NSString *)logString withfileName:(NSString *)fileName;

```
3.2.2
说明 JWDInteractionLogger.m 实现
```
/**
 创建文件路径

 @param fileName 文件名称
 @return 路径
 */
-(NSURL *)getPathWithFileName:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    BOOL isDir = TRUE;
    BOOL isDirExists = [fileManager fileExistsAtPath:cacheDir isDirectory:&isDir];
    
    if (!isDirExists) {
        NSError *err = nil;
        BOOL isCreateDirSuccess = [fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:NO attributes:nil error:&err];
        if (!isCreateDirSuccess) {
            NSLog(@"创建cache路径失败：%@",err.description);
            return nil;
        }
    }
    
    NSString *filePath = [[cacheDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"txt"];
    BOOL isFileExists = [fileManager fileExistsAtPath:filePath];
    if (isFileExists) {
        //存在
        NSError *err = nil;
        float fileSizeKB = [[fileManager attributesOfItemAtPath:filePath error:&err] fileSize] / 1024.0f;
        if (err) {
            NSLog(@"获取文件大小失败：%@",err.description);
        }
        if (fileSizeKB > 10240) {
            NSError *err = nil;
            BOOL isRmSuccess = [fileManager removeItemAtPath:filePath error:&err];
            if (!isRmSuccess) {
                NSLog(@"删除文件失败：%@",err.description);
            }
            BOOL isCreateFileSuccess = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
            if (!isCreateFileSuccess) {
                NSLog(@"创建文件失败：%@",err.description);
                return nil;
            }
        }
    } else {
        //不存在
        NSError *err = nil;
        BOOL isCreateFileSuccess = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        if (!isCreateFileSuccess) {
            NSLog(@"创建文件失败：%@",err.description);
            return nil;
        }
    }
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    if (!fileURL) {
        NSLog(@"获取沙盒相对文件URL失败");
        return nil;
    }
    return fileURL;
}
```
上面创建文件路径，做了几种容错，也对太大的日志文件直接删除。


3.2.3
```
/**
 创建 流写 实例

 @param fileName 类型名
 */
- (NSOutputStream *)creatStreamWithFileName:(NSString *)fileName {

    NSURL *url = [self getPathWithFileName:fileName];
    NSOutputStream *outputStream = [[NSOutputStream alloc] initWithURL:url append:YES];
    outputStream.delegate = self;
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [outputStream open];
    return outputStream;
}
```
根据日志名称创建写入流，做到即时创建。这里的用法，把流加入到 [NSRunLoop currentRunLoop] 中等待数据的写入。


3.2.4
```
- (NSData *)getDataWithLogString:(NSString *)logString {

    NSString *tempString = [[NSString alloc] init];
    if (logString.length == 0) {
        tempString = @"\n";
    }else {
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        
        NSDate *date = [NSDate date];
        NSDateFormatter *forMatter = [[NSDateFormatter alloc] init];
        [forMatter setDateFormat:@"yyyy年MM月dd日 HH时mm分ss秒"];
        NSString *dateStr = [forMatter stringFromDate:date];

        tempString = [tempString stringByAppendingFormat:@"appName--%@,version--%@,date--%@ ,[文件名:%s]" "[函数名:%s]" "[行号:%d] \n %@ \n",appName,version,dateStr,[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __FUNCTION__,__LINE__,logString];
    }
    NSData *data = [tempString dataUsingEncoding:NSUTF8StringEncoding];

    return data;
}
```
把需要记录的日志数据转化成NSData，这里本人拼接进去了 APP名，版本号，日志时间，文件名，函数名，行号，日志数据。记录这些数据，做到查看日志的快速定位，便于查找问题所在，是不是很爽。

3.2.5
```
- (void)writeLogWithLogString:(NSString *)logString withfileName:(NSString *)fileName{
    
    if (self.writeLogStream == nil) {
        self.writeLogStream = [self creatStreamWithFileName:fileName];
    }
    NSData *data = [self getDataWithLogString:logString];
    [self.writeLogStream write:[data bytes] maxLength:data.length];
    [self.writeLogStream close];
    [self.writeLogStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.writeLogStream = nil;   
}
```
这里就是供外界调用的日志入口，数据转换，在流对象不存的情况下，做到即时创建，在一条数据写入成功之后，做到即时关闭数据流对象，保护数据不出错，和 [数据库读写数据地址](https://github.com/weidongjiang/JWDFMDB-Data-Message) 一个道理，用时打开，不用时及时关闭。


###四、日志分享
现在本地有了相应的日志文件，那么打包安装的包，为了及时方便获取日志数据，那么很快的把文件分享发送出来，岂不更好。
利用系统的 UIDocumentInteractionController 来实现

```
- (void)sendLogFileWithFileName:(NSString *)fileName {

    NSURL *fileurl = [self getPathWithFileName:fileName];
    
    if (!fileurl) {
        NSLog(@"日志文件不存在");
        return;
    }
    
    // 判断文件是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:[fileurl path]];
    if (!isExists) {
        return;
    }
    // 获取文件大小
    NSError *error = nil;
    CGFloat fileSize = [[fileManager attributesOfItemAtPath:[fileurl path] error:&error] fileSize]/1024.0f;
    if (error) {
        NSLog(@"获取日志失败");
        return;
    }
    if (fileSize == 0) {
        NSLog(@"获取日志失败，文件不存在");
    }else {
        self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:fileurl];
        self.interactionController.delegate = self;
        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }
        if (vc!=nil) {
            [self.interactionController presentOptionsMenuFromRect:vc.view.bounds inView:vc.view animated:YES];
        }
    }
}

```

但是当我要分享，使用AirDrop 分享发送时，发送失败报下面的错误，第三方发送也是如此，备忘录里面也是，显示文件为空。
后来查阅资料发现，没有强引用
```
 self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:fileurl];
```

![分享日志文件失败](http://upload-images.jianshu.io/upload_images/2248534-9c5cf012aec84267.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

出现以上的原因是因为没有全局引用 UIDocumentInteractionController
```
 UIDocumentInteractionController *interactionController = [UIDocumentInteractionController interactionControllerWithURL:fileurl];
```
导致在分享文件的时候找不到UIDocumentInteractionController，获取文件失败。

好了，就说这么多吧！可以下载demo 自己试一试，或者放到自己的项目里面试试，当你看到日志了是不是感觉感觉很爽，不用联机就可以分析数据，这样如此好的工具，岂不是和后台，服务端撕逼的神器。被各种错误数据虐了千万遍的客户端同仁们，这下是不是长叹一句，真爽。

当测试美美来找你结束bug时，直接看日志，分析显示，他妈的数据错误，数据格式不对，各种jj，bug 直接抛出去。当然还是要和睦相处，共同为自家项目加油努力。

如果你感觉到，帮助了你，就star一个吧！

最后是 [demo地址](https://github.com/weidongjiang/JWDInputOutputStream)



