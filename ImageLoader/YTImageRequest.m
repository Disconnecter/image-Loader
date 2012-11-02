//
//  YTImageRequest.m
//  YandexTranslate
//
//  Created by Zabolotnyy Sergey on 10/30/12.
//  Copyright (c) 2012 Zabolotnyy Sergey. All rights reserved.
//

#include <netinet/in.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import "YTImageRequest.h"
#import <CommonCrypto/CommonDigest.h>

#define MAX_FILES_IN_DIR 5

@interface YTImageRequest()

@property (nonatomic, copy) ImageCompletionBlock completionBlock;
@property (nonatomic, copy) NSString *urlHash;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSDate *lastModifiedLocal;

@end

@implementation YTImageRequest

#pragma mark - Public methods

- (void)imageWithURL:(NSURL *)url
      needSaveInCash:(BOOL)cash
             success:(ImageCompletionBlock)imgBlock
{
    self.urlHash = md5hash([url absoluteString]);
    self.completionBlock = imgBlock;
    _needSaveToCash = cash;
 
//    if ([self fileExists:self.urlHash] && [self connectedToNetwork] == NO)
//    {
//        NSError *error = [NSError errorWithDomain:@"com.image.request"
//                                             code:-1009
//                                         userInfo:nil] ;
//        self.completionBlock([UIImage imageWithData:[NSData dataWithContentsOfFile:self.filePath]],error);
//    }
//    else if([self connectedToNetwork] == YES)
//    {
/**/    [self fileExists:self.urlHash];//*/
    _data = [NSMutableData new];
    [self startLoadForUrl:url];
//    }
//    else
//    {
//        NSError *error = [NSError errorWithDomain:@"com.image.request"
//                                             code:-1009
//                                         userInfo:nil] ;
//        self.completionBlock(nil,error);
//    }
}

- (void)cleanLocalCash
{
    [[NSFileManager defaultManager] removeItemAtPath:[self defaultDir] error:nil];
}

#pragma mark - Private methods

- (BOOL)connectedToNetwork
{
    struct sockaddr_in zeroAddress;

    bzero(&zeroAddress, sizeof(zeroAddress));
    
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr*)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return 0;
    }
    
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    
    return (isReachable && !needsConnection);
}

- (NSString *)defaultDir
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *defaultDir = [NSString stringWithFormat:@"%@/images", [paths objectAtIndex:0]];
    return defaultDir;
}

- (BOOL)fileExists:(NSString *)hash
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (NSInteger i = 0; i < INT_MAX; ++i)
    {
        NSString *cashDirectory = [NSString stringWithFormat:@"%@/%i", [self defaultDir], i];
        NSArray *filelist= [fileManager contentsOfDirectoryAtPath:cashDirectory error:nil];
        
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", cashDirectory, hash];
        
        if ([filelist count] > 0 && [fileManager fileExistsAtPath:filepath])
        {
            self.filePath = filepath;
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filepath error:nil];
            
            if ([fileAttributes fileSize] > 0)
            {
                self.lastModifiedLocal = [fileAttributes fileModificationDate];
            }
            else
            {
                return NO;
            }
            
            return YES;
        }
        else if ([filelist count] == 0)
        {
            return NO;
        }
    }
    
    return NO;
}

- (NSString *)saveDirectory
{
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    for (NSInteger i = 0; i < INT_MAX; ++i)
    {
        NSString *cashDirectory = [NSString stringWithFormat:@"%@/%i", [self defaultDir], i];
        NSArray *filelist= [filemgr contentsOfDirectoryAtPath:cashDirectory error:nil];
        
        if ([filelist count] == 0)
        {
            [filemgr createDirectoryAtPath:cashDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            return cashDirectory;
        }
        else if ([filelist count] <= MAX_FILES_IN_DIR)
        {
            return cashDirectory;
        }
    }
    
    return nil;
}

- (NSString *)filePathForSave:(NSString *)hash
{
    return [NSString stringWithFormat:@"%@/%@",[self saveDirectory], hash];
}

- (void)startLoadForUrl:(NSURL *)url
{
    if (_done == YES)
    {
        return;
    }
    
    _done = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       @autoreleasepool
                       {
                           NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
                           request.cachePolicy = NSURLRequestUseProtocolCachePolicy;
                           [request setHTTPMethod:@"GET"];
                           [request setValue:@"image/*" forHTTPHeaderField:@"Content-Type"];
                           
                           NSDateFormatter *dateFormatter = [NSDateFormatter new];
                           [dateFormatter setLocale: [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
                           [dateFormatter setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
                           [dateFormatter setDateFormat: @"EEE, d MMM yyyy HH:mm:ss"];
                           NSString *dateString = [[dateFormatter stringFromDate: self.lastModifiedLocal] stringByAppendingString:@"GMT"];
                           [dateFormatter release];
                           
                           [request addValue: dateString forHTTPHeaderField: @"If-Modified-Since"];
                           
                           _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] ;
                           [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
                           [_connection start];
                           
                           while(!_done)
                           {
                               [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                           }
                       }
                   });
}

NSString *md5hash(NSString *Value)
{
    if ([Value length] == 0)
    {
        return 0;
    }
    
    const char *concat_str = [Value UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(concat_str, strlen(concat_str), result);
    
    NSMutableString *hash = [NSMutableString string];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [hash appendFormat:@"%02X", result[i]];
    }
    
    return hash;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
{
    _done = YES;
    self.completionBlock(nil, error);
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)aData
{
    [_data appendData:aData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    //NSLog(@"%@",[self filePathForSave:self.urlHash]);
    
    if (_needSaveToCash && [_data length] > 0)
    {
        if (self.filePath)
        {
            [_data writeToFile:self.filePath atomically:YES];
            NSLog(@"rewrite %@",self.urlHash);
        }
        else
        {
            self.filePath = [self filePathForSave:self.urlHash];
            [_data writeToFile:self.filePath atomically:YES];
            NSLog(@"write %@",self.urlHash);
        }
        
        NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:self.lastModifiedLocal forKey:NSFileModificationDate];
        [[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:self.filePath error:nil];
    }
    
    _done = YES;
    UIImage *newImg = [[[UIImage alloc] initWithData:_data] autorelease];
    self.completionBlock(newImg, nil);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    NSLog(@"%@", [(NSHTTPURLResponse *)response allHeaderFields]);
//    NSLog(@"%i",[(NSHTTPURLResponse *)response statusCode]);
    
    if ([(NSHTTPURLResponse *)response statusCode] >= 400)
    {
        NSError *error = [NSError errorWithDomain:@"com.image.request"
                                             code:[(NSHTTPURLResponse *)response statusCode]
                                         userInfo:nil] ;
        
        self.completionBlock(nil,error);
    }
    else
    {
        NSDateFormatter *dateFormater = [NSDateFormatter new];
        dateFormater.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        dateFormater.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        dateFormater.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        
        NSString *stringDateFromResponse = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Last-Modified"];
        NSDate *dateFromServer = [dateFormater dateFromString:stringDateFromResponse];
        [dateFormater release];
        
        if ([self.lastModifiedLocal laterDate:dateFromServer] == dateFromServer || [(NSHTTPURLResponse *)response statusCode] == 304)
        {
            NSLog(@"cash");
            self.completionBlock([UIImage imageWithData:[NSData dataWithContentsOfFile:self.filePath]],nil);
            _done = YES;
            [_connection cancel];
        }
        else
        {
            NSLog(@"NOcash");
            self.lastModifiedLocal = dateFromServer;
        }
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void)dealloc
{
    [_urlHash release];
    [_filePath release];
    [_data release];
    [_completionBlock release];
    [_lastModifiedLocal release];
    [_connection release];
    
    [super dealloc];
}

@end
