//
//  BinCarViewController.h
//  UI
//
//  Created by hha6027875 on 17/10/18.
//  Copyright © 2018 hha6027875. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface BinCarViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
{
    
}
@property (nonatomic, retain) AVCaptureSession *session;
-(void)startVideoCapture;
@end

NS_ASSUME_NONNULL_END
