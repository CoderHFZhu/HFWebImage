//
//  UIImageView+WebCache.m
//  HFWebImage
//
//  Created by CoderHF on 2018/9/14.
//  Copyright © 2018年 CoderHF. All rights reserved.
//

#import "UIImageView+WebCache.h"
#import <objc/runtime.h>
#import "HFImageLoadOperation.h"
static NSOperationQueue *HFLoadQueue_;
@implementation UIImageView (WebCache)


+(void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HFLoadQueue_ = [NSOperationQueue new];
        HFLoadQueue_.maxConcurrentOperationCount = 6;
    });
}

- (void)hf_loadImageWithUrl:(NSString *)url placeholderImage:(UIImage *)image{
    [self hf_loadImageWithUrl:url placeholderImage:image ignoreCache:NO];
}
- (void)hf_loadImageWithUrl:(NSString *)url placeholderImage:(UIImage *)image ignoreCache:(BOOL)ignore{
    self.image = image;
    self.HFImageUrl = url;
    HFImageLoadOperation *operation = [HFImageLoadOperation new];
    operation.imageUrl = url;
    operation.imageView = self;
    operation.ignoreCache = ignore;
    [HFLoadQueue_ addOperation:operation];
}


-(void)setHFImageUrl:(NSString *)HFImageUrl{
    objc_setAssociatedObject(self, @selector(setHFImageUrl:), HFImageUrl, OBJC_ASSOCIATION_RETAIN);
}
- (NSString *)HFImageUrl{
    
    return objc_getAssociatedObject(self, @selector(setHFImageUrl:));
}
@end
