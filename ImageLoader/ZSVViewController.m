//
//  ZSVViewController.m
//  ImageLoader
//
//  Created by Zabolotnyy Sergey on 11/1/12.
//  Copyright (c) 2012 Zabolotnyy Sergey. All rights reserved.
//

#import "ZSVViewController.h"
#import "YTImageRequest.h"

#define IMAGE_SIDE_SIZE 75
#define IMAGE_INDENT 4
#define COLUMNS_COUNT 4

@implementation ZSVViewController

- (void)viewDidAppear:(BOOL)animated
{
    CGPoint offset = CGPointZero;
    NSInteger visibleImages = 0;
    
    for (NSInteger i = 0; i < 48; i++)
    {
        UIImageView *imageView = [UIImageView new];

        offset.x = IMAGE_INDENT + ((visibleImages + i) % COLUMNS_COUNT) * (IMAGE_SIDE_SIZE + IMAGE_INDENT);
        offset.y = IMAGE_INDENT + ((visibleImages + i) / COLUMNS_COUNT) * (IMAGE_SIDE_SIZE + IMAGE_INDENT);

        NSString *url = [NSString stringWithFormat:@"http://images.apple.com/euro/home/images/ipodtouch_hero.jpg"];
        YTImageRequest *imgReq = [YTImageRequest new];
        [imgReq imageWithURL:[NSURL URLWithString:url]
              needSaveInCash:YES
                     success:^(UIImage *bimg, NSError *error)
         {
             [imageView setImage:bimg];
             
             NSLog(@"%@",error);
         }];
        [imgReq release];
        
        [imageView setFrame:CGRectMake(offset.x, offset.y, IMAGE_SIDE_SIZE, IMAGE_SIDE_SIZE)];
        [_scrollView addSubview:imageView];
        [imageView release];
    }
    
    _scrollView.contentSize = CGSizeMake(CGRectGetWidth(_scrollView.frame), offset.y + (IMAGE_SIDE_SIZE + IMAGE_INDENT));
}

- (void)dealloc
{
    [_scrollView release];
    [super dealloc];
}
@end
