//
//  Created by Simon Burbidge on 13/10/2015.
//  Copyright © 2015 Whisk Mobile Development. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, ComposeStatus) {
    ComposeStatusPosted,
    ComposeStatusFailed,
    ComposeStatusCancelled
};

typedef void (^ComposeCompletionBlock)(ComposeStatus status, NSError *error);

@interface SBBAnimatedTweetComposeViewController : UIViewController

@property (strong, nonatomic) NSString *activityString;
@property (strong, nonatomic) UIImage *activityShareImage;
@property (strong, nonatomic) NSData *activityAnimatedImageData;

@property (strong, nonatomic) UIColor *highlightColor;

@property (nonatomic,copy) ComposeCompletionBlock completionBlock;

@end
