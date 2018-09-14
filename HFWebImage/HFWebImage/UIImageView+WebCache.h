//
//  UIImageView+WebCache.h
//  HFWebImage
//
//  Created by CoderHF on 2018/9/14.
//  Copyright © 2018年 CoderHF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (WebCache)

@property (nonatomic, strong) NSString *HFImageUrl;

- (void)hf_loadImageWithUrl:(NSString *)url placeholderImage:(UIImage *)image;

/**
 设置网络图片

 @param url url
 @param image image
 @param ignore NO 表示设置缓存  YES表示不设置缓存 有些经常改变的图片建以使用 YES  不做缓存
 */
- (void)hf_loadImageWithUrl:(NSString *)url placeholderImage:(UIImage *)image ignoreCache:(BOOL)ignore;
@end
