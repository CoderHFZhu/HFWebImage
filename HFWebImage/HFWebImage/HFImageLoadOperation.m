//
//  HFImageLoadOperation.m
//  HFWebImage
//
//  Created by CoderHF on 2018/9/14.
//  Copyright © 2018年 CoderHF. All rights reserved.
//

#import "HFImageLoadOperation.h"
#import <CommonCrypto/CommonDigest.h>
#import "UIImageView+WebCache.h"

typedef BOOL(^CancelBlock)(void);
//内存缓存
static NSCache *hfImageCache_;
//相同任务的字典 记录当前正在进行的任务
static NSMutableDictionary *sameTaskDic_;
//相同任务的数组 存放相同url的imageview
static NSMutableArray *sameTaskArr_;
//黑名单  一些不能下载的链接 就没有必要再次下载了
static NSMutableArray *blackNameArr_;
//安全锁
static NSLock *HFLock_;

@implementation HFImageLoadOperation
// 重写了属性关联的变量名 //操作的是成员变量  重写 start main 方法 要自己控制 监听属性 finished cancled executing
@synthesize finished = _finished;

+(void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hfImageCache_ = [NSCache new];
        sameTaskArr_ = [NSMutableArray array];
        blackNameArr_ = [NSMutableArray array];

        HFLock_ = [NSLock new];
    });
}
//重写系统方法
- (void)start{
    [self main];
}

- (void)main{
    //黑名单
    if ([blackNameArr_ containsObject:self.imageUrl]) {
        [self finishStatus];
        return;
    }
    
    CancelBlock isCancelBlock = ^BOOL(){
        BOOL cancel = NO;
        
        if (!self.imageView) {
            cancel = YES;
        }else if (self.ignoreCache){
            cancel = YES;
        }else if (![self.imageView.HFImageUrl isEqualToString:self.imageUrl]){
            //当前的url 与 设置的不匹配  所以忽略
            cancel = YES;
        }
        return cancel;
    };
    
    NSData *imageData = [self cacheForKey:self.imageUrl];
    
    if (imageData) {
        if (!isCancelBlock()) {
            [self mainThreadLoadImage:[UIImage imageWithData:imageData]];
        }
    } else {
      
        if ([sameTaskDic_ objectForKey:self.imageUrl]) {
            //不引起 引用计数的改变
            NSValue *value = [NSValue valueWithNonretainedObject:self.imageView];
            // task已经在进行 把imageview 添加__sameTaskAry,
            [HFLock_ lock];
            [sameTaskArr_ addObject:value];
            [HFLock_ unlock];
            [self finishStatus];
            return;
        }else{
            [HFLock_ lock];
            [sameTaskDic_ setObject:@"in" forKey:self.imageUrl];
            [HFLock_ unlock];
        }
        imageData = [self loadImageWithUrl:self.imageUrl];
        if (!imageData) {
            [self finishStatus];
            [HFLock_ lock];
            [blackNameArr_ addObject:self.imageUrl];
            [sameTaskDic_ removeObjectForKey:self.imageUrl];
            [HFLock_ unlock];
            return;
        }
        // bitmap处理
        UIImage *bitmapImage = [self bitmapFromImage:[UIImage imageWithData:imageData]];
        // 保存bitmap 数据
        NSData *bitmapData = UIImageJPEGRepresentation(bitmapImage, 1);
        [self saveBitmapImageData:bitmapData url:self.imageUrl];
        
        // 4.1 处理多个相同task imageview1，imageview2 ......
        NSMutableArray *handleImageArr = [NSMutableArray new]; // 即将处理的
        NSMutableArray *cancelImageArr = [NSMutableArray new]; // 取消了的
        
        for (NSValue *value in sameTaskArr_) {
            UIImageView *imageView = [value nonretainedObjectValue];
            //已经被release 的imageview 被记录 做取消操作
            if (!imageView) {
                [cancelImageArr addObject:imageView];
            }
            // 还健在的imageview 做赋值操作
            if ([imageView.HFImageUrl isEqualToString:self.imageUrl]) {
                [handleImageArr addObject:value];
            }
        }
        
        // 把sameTaskArr_中已经记录的数据删除
        for (int i = 0; i < cancelImageArr.count; i++) {
            [sameTaskArr_ removeObject:cancelImageArr[i]];
        }
        for (int i = 0; i < handleImageArr.count; i++) {
            [sameTaskArr_ removeObject:handleImageArr[i]];
        }
        
        for (NSValue *value in handleImageArr) {
            UIImageView *imageView = [value nonretainedObjectValue];
            if (!isCancelBlock() && !imageView){
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = bitmapImage;
                });
            }
        }
        
        [HFLock_ lock];
        [sameTaskDic_ removeObjectForKey:self.imageUrl];
        [HFLock_ unlock];
        
        if (!isCancelBlock()){
            [self mainThreadLoadImage:bitmapImage];
        }
    }

    [self finishStatus];
}

// 手动进行KVO操作
- (void)finishStatus{
    
    [self willChangeValueForKey:@"finished"];
    _finished = YES;
    [self didChangeValueForKey:@"finished"];
    
}

#pragma mark ----- load
// 同步的 信号量
- (NSData*)loadImageWithUrl:(NSString*)url{
    
    __block NSData *imageData = nil;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    NSURLSessionTask *task =  [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        imageData = data;
        if (error) {
            NSLog(@"网络异常：%@", error);
        }
        dispatch_semaphore_signal(sema);
        
    }];
    
    [task resume];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return imageData;
    
}

#pragma mark - bitmap
- (UIImage*)bitmapFromImage:(UIImage*)targetImage{
    
    if(!targetImage){
        return nil;
    }
    CGImageRef imageRef = targetImage.CGImage;
    
    CGContextRef contextRef =  CGBitmapContextCreate(NULL, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef), CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), CGImageGetColorSpace(imageRef), CGImageGetBitmapInfo(imageRef));
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)), imageRef);
    CGImageRef bitmapRef = CGBitmapContextCreateImage(contextRef);
    
    UIImage *bitmapImage = [UIImage imageWithCGImage:bitmapRef];
    
    CFRelease(bitmapRef);
    UIGraphicsEndImageContext();
    return bitmapImage;
}
#pragma mark - Cache
// url作为一个唯一标识  /
- (void)saveBitmapImageData:(NSData*)bitmapData url:(NSString*)url{
    
    // 先存cache 再存disk
    [hfImageCache_ setObject:bitmapData forKey:[self md5FromStr:url]];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    NSString *filePath = [documentPath stringByAppendingPathComponent:[self md5FromStr:url]];
    [bitmapData writeToFile:filePath atomically:YES];
}

- (NSData*)cacheForKey:(NSString*)key{
    
    NSData *imageData = [hfImageCache_ objectForKey:[self md5FromStr:key]];
    if (!imageData) {
        imageData = [self findImageFromKey:[self md5FromStr:key]];
    }
    
    return imageData;
}

// 默认放到沙盒的document下面
- (NSData*)findImageFromKey:(NSString*)url{
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentPath stringByAppendingPathComponent:[self md5FromStr:url]];
    
    return [NSData dataWithContentsOfFile:filePath];
}

// 主线程显示图片 mainThreadLoadImage这个操作之前都设置了取消节点
- (void)mainThreadLoadImage:(UIImage*)image{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });
    
}
#pragma mark - MD5
- (NSString*)md5FromStr:(NSString*)targetStr{
    
    if(targetStr.length == 0){
        return nil;
    }
    const char *original_str = [targetStr UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (unsigned int)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
    {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}


@end
