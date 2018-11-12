//
//  BinCarViewController.m
//  UI
//
//  Created by hha6027875 on 17/10/18.
//  Copyright © 2018 hha6027875. All rights reserved.
//

#import "BinCarViewController.h"
#import "ImageAdjust.h"
#import "GCDAsyncSocket.h"
#import <Foundation/Foundation.h>
@import Firebase;

@class FIRDatabaseReference;
@interface BinCarViewController ()
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (retain, nonatomic) IBOutlet UITextView *Result;
@property (strong, nonatomic) UIImage *temporal;
@property (retain, nonatomic) IBOutlet UIImageView *imgView;
@property (strong, nonatomic) GCDAsyncSocket * clientSocket;
@end
@implementation BinCarViewController
- (IBAction)Click:(id)sender {
    //NSLog(@"hello");
    //[self startVideoCapture];
}
- (IBAction)transfer:(id)sender {
    if(self.clientSocket)
    {
        [self.clientSocket disconnect];
        self.clientSocket = nil;
    }
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.clientSocket connectToHost:@"169.254.111.100" onPort:11123 error:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ref = [[FIRDatabase database] reference];
    // Do any additional setup after loading the view.
    [self startVideoCapture];
}


-(void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"wwwww");
    [self showMessageWithStr:@"链接成功"];
    [self showMessageWithStr:[NSString stringWithFormat:@"服务器IP: %@,%i", host,port]];
    //    [self.clientSocket readDataWithTimeout:- 1 tag:0];
    
    //    //发消息
    UIImage * image = self.imgView.image;
    //UIImage * image = self.temporal;
    NSData * dataObj = UIImagePNGRepresentation(image);
    
    //NSData *dataObj = [@"test123\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    
    // withTimeout -1 : 无穷大,一直等
    // tag : 消息标记
    [self.clientSocket writeData:dataObj withTimeout:-1 tag:0];
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError*)err
{
    NSLog(@"socket连接建立失败:%@",err);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    //NSLog(@"%ld", data.length);
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [self showMessageWithStr:text];
    NSArray *listItems = [text componentsSeparatedByString:@"\t"];
    NSString *rangeString = [listItems[0] substringFromIndex:2];
    NSMutableString *final = [[NSMutableString alloc] initWithString:text];
    NSString *possible = @"063KQK\tTSA595\t522HCX\tTTD484\t027IGB\tOSM890\tYCU503\tTRJ650\tXFB065\t942LKC\t160LKY\tSSG650\tXYB868\tAQ04MH\tWTF668\tWTF66B\tVJG078\tYLJ75W\t1AA1AA\t785HPJ\t0SM890\t0271GB\t1GW8QZ\tIGW8QZ\tTBB797\tYN0932\tYNO932\tSKG898";
    NSArray *allPossible = [possible componentsSeparatedByString:@"\t"];
    if ([allPossible containsObject:rangeString])
    {
        [[_ref child:rangeString]  observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            // Get user value
            NSString *birth = snapshot.value[@"birthday"];
            NSString *name = snapshot.value[@"owner"];
            NSString *color = snapshot.value[@"color"];
            NSString *brand = snapshot.value[@"brand"];
            [final appendString:@"- Brand: "];
            [final appendString:brand];
            [final appendString:@"\n"];
            [final appendString:@"- Color: "];
            [final appendString:color];
            [final appendString:@"\n"];
            [final appendString:@"- Owner: "];
            [final appendString:name];
            [final appendString:@"\n"];
            [final appendString:@"- Birthday: "];
            [final appendString:birth];

            NSLog(@"final:  %@", final);
            [self.Result performSelectorOnMainThread:@selector(setText:) withObject:final waitUntilDone:YES];
        } withCancelBlock:^(NSError * _Nonnull error) {
            [self.Result performSelectorOnMainThread:@selector(setText:) withObject:final waitUntilDone:YES];
        }];
    }
    else
    {
        [final appendString:@"\nThe information is not in the Database"];
        [self.Result performSelectorOnMainThread:@selector(setText:) withObject:final waitUntilDone:YES];
    }
    //[self.Result performSelectorOnMainThread:@selector(setText:) withObject:final waitUntilDone:YES];
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
}



- (void)showMessageWithStr:(NSString *)str {
    NSLog(@"%@",str);
    //NSString *prolist = @"empty";
    //[self.Result setText:str];
}

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
-(void)startVideoCapture{
    // 创建会话
    self.session = [[AVCaptureSession alloc] init];
    
    // 获取摄像头的权限信息，判断是否有开启权限
    AVAuthorizationStatus status    = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (status != AVAuthorizationStatusAuthorized)
    {
        [self.Result setText:(@"cannot get video")];
        return;
    }
    
    //    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    NSError *error = nil;
    
    // 创建输入设备
    
    AVCaptureDevice *videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    // beginConfiguration这个很重要，在addInput或者addOutput的时候一定要调用这个，add之后再调用commitConfiguration
    [self.session beginConfiguration];
    if ([self.session canAddInput:videoDeviceInput])
    {
        [self.session addInput:videoDeviceInput];
        //        self.videoDeviceInput = videoDeviceInput;
    }
    
    // 为会话加入output设备
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoDataOutput.videoSettings =[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]forKey:               (id)kCVPixelBufferPixelFormatTypeKey];
    
    // 设置self的AVCaptureVideoDataOutputSampleBufferDelegate
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    if ([self.session canAddOutput:videoDataOutput])
    {
        [self.session addOutput:videoDataOutput];
    }
    
    [self.session commitConfiguration];
    [self.session startRunning];
}


- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position{
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

- (UIImage *)getImageBySampleBufferref:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    UIImage *image1= [UIImage imageWithCGImage:newImage];
    self.temporal = image1;
    /*We relase the CGImageRef*/
    CGImageRelease(newImage);
    
    return image;
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //NSLog(@"didOutputSampleBuffer");
    UIImage *image  = [self getImageBySampleBufferref:sampleBuffer];
    [self.imgView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
}





- (void)dealloc {
    [_Result release];
    [_imgView release];
    [_Result release];
    [_Result release];
    [super dealloc];
}
@end
