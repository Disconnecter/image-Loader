# Image Loader
Simple Image loader used NSURLConnection in background. 

Example
-------
 ```Objective-C
YTImageRequest *imgReq = [YTImageRequest new];
        [imgReq imageWithURL:[NSURL URLWithString:url]
              needSaveInCash:YES
                     success:^(UIImage *bimg, NSError *error)
         {
             [imageView setImage:bimg];
             
             NSLog(@"%@",error);
         }];
        [imgReq release];
```