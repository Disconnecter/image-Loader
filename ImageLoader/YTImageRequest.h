//
//  YTImageRequest.h
//  YandexTranslate
//
//  Created by Zabolotnyy Sergey on 10/30/12.
//  Copyright (c) 2012 Zabolotnyy Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ImageCompletionBlock)(UIImage *img, NSError* error);

@interface YTImageRequest : NSObject
{
    NSMutableData *_data;
    BOOL _done;
    BOOL _needSaveToCash;
    NSURLConnection  *_connection;
}

- (void)imageWithURL:(NSURL *)url
      needSaveInCash:(BOOL)cash
             success:(ImageCompletionBlock)imgBlock;

- (void)cleanLocalCash;

@end
