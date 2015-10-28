//
//  SBBViewController.m
//  SBBAnimatedTweetActivity
//
//  Created by Simon Burbidge on 10/26/2015.
//  Copyright (c) 2015 Simon Burbidge. All rights reserved.
//

#import "SBBViewController.h"
#import <FLAnimatedImage/FLAnimatedImageView.h>
#import <FLAnimatedImage/FLAnimatedImage.h>
#import <SBBAnimatedTweetActivity/SBBAnimatedTweetActivity.h>

@interface SBBViewController ()

@property (weak, nonatomic) IBOutlet FLAnimatedImageView *animatedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *stillImageView;

@end

@implementation SBBViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *imageUrl = [[NSBundle mainBundle] URLForResource:@"GIF-Demo" withExtension:@"gif"];
    NSData *animatedGIFData = [NSData dataWithContentsOfURL:imageUrl];
    
    FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:animatedGIFData];
    self.animatedImageView.animatedImage = animatedImage;
    
    self.stillImageView.image = [UIImage imageNamed:@"Preview-images"];
}

#pragma mark - IBActions

- (IBAction)animatedShareButtonPressed:(UIButton*)sender {
    
    NSArray *activityItemsArray, *activitiesArray, *excludedArray;
    NSString *itemString = @"Using SBBAnimatedTweetActivity, I can now share animated GIFs via Twitter!";
    
    if (self.animatedImageView.animatedImage.data) {
        activityItemsArray = @[itemString, self.animatedImageView.animatedImage.data];
        
        SBBAnimatedTweetActivity *tweetActivity = [SBBAnimatedTweetActivity activityWithHighlightColor:nil];
        activitiesArray = @[tweetActivity];
        
        // Because we're using the custom Twitter activity, we exclude the standard one.
        excludedArray = @[UIActivityTypePostToTwitter];
    } else {
        // You can also post a still image or just text using SBBAnimatedTweetActivity, but it is probably better to just use the standard Twitter UIActivity instead
        // We therefore don't add the custom activity here, and don't exclude the standard Twitter activity.
        activityItemsArray = @[itemString];
    }
    
    __block UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:activityItemsArray
                                      applicationActivities:activitiesArray];
    
    activityViewController.popoverPresentationController.sourceRect = sender.frame;
    activityViewController.excludedActivityTypes = excludedArray;
    
    [self presentViewController:activityViewController animated:YES completion:^{
        activityViewController.excludedActivityTypes = nil;
        activityViewController = nil;
    }];
}

- (IBAction)stillShareButtonPressed:(UIButton*)sender {
    
    NSArray *activityItemsArray, *activitiesArray, *excludedArray;
    NSString *itemString = @"Using SBBAnimatedTweetActivity, I can now share animated GIFs via Twitter!";
    
    if (self.stillImageView.image) {
        // You can also post a still image using SBBAnimatedTweetActivity, but it is probably better to just use the standard Twitter UIActivity instead
        // We therefore don't add the custom activity here, and don't exclude the standard Twitter activity.
        activityItemsArray = @[itemString, self.stillImageView.image];
    } else {
        activityItemsArray = @[itemString];
    }
    
    __block UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:activityItemsArray
                                      applicationActivities:activitiesArray];
    
    activityViewController.popoverPresentationController.sourceRect = sender.frame;
    activityViewController.excludedActivityTypes = excludedArray;
    
    [self presentViewController:activityViewController animated:YES completion:^{
        activityViewController.excludedActivityTypes = nil;
        activityViewController = nil;
    }];
}

@end
