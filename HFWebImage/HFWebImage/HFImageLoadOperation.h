//
//  HFImageLoadOperation.h
//  HFWebImage
//
//  Created by CoderHF on 2018/9/14.
//  Copyright © 2018年 CoderHF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface HFImageLoadOperation : NSOperation

@property (nonatomic, assign) BOOL ignoreCache;

@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, weak) UIImageView *imageView;

@end
