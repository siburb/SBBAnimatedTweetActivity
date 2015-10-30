//
//  Created by Simon Burbidge on 13/10/2015.
//  Copyright © 2015 Whisk Mobile Development. All rights reserved.
//

#import "SBBAnimatedTweetActivity.h"
#import "SBBAnimatedTweetComposeViewController.h"

NSString *const SBBAnimatedTweetActivityType = @"SBBAnimatedTweetActivityType";

@interface SBBAnimatedTweetActivity ()

@property (strong, nonatomic) NSURL *activityURL;
@property (strong, nonatomic) UIImage *activityShareImage;
@property (strong, nonatomic) NSString *activityString;
@property (strong, nonatomic) NSData *activityAnimatedImageData;

@property (strong, nonatomic) UIColor *highlightColor;

@end

@implementation SBBAnimatedTweetActivity


#pragma mark - Init

+ (SBBAnimatedTweetActivity *)activityWithHighlightColor:(UIColor *)highlightColor {
    return [[SBBAnimatedTweetActivity alloc] initWithHighlightColor:highlightColor];
}

- (instancetype)initWithHighlightColor:(UIColor *)highlightColor {
    if (self = [super init]) {
        _highlightColor = highlightColor;
    }
    
    return self;
}

#pragma mark - UIActivity

- (NSString *)activityType {
    return SBBAnimatedTweetActivityType;
}

- (NSString *)activityTitle {
    return @"Animated Tweet";
}

- (UIImage *)activityImage {   
    return [UIImage imageNamed:@"tweetActivityIcon" inBundle:[self resourcesBundle] compatibleWithTraitCollection:nil];
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryShare;
}

- (UIViewController *)activityViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SBBAnimatedTweetActivity" bundle:[self resourcesBundle]];
    SBBAnimatedTweetComposeViewController *composeViewController = [storyboard instantiateViewControllerWithIdentifier:@"SBBAnimatedTweetComposeViewControllerID"];
    
    NSMutableString *shareString = self.activityString.mutableCopy;
    if (self.activityURL) {
        if (shareString) {
            [shareString appendString:@" "];
        }
        [shareString appendString:self.activityURL.absoluteString];
    }
    composeViewController.activityString = shareString;
    composeViewController.activityShareImage = self.activityShareImage;
    composeViewController.activityAnimatedImageData = self.activityAnimatedImageData;
    composeViewController.highlightColor = self.highlightColor;
    composeViewController.completionBlock = ^(ComposeStatus status, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case ComposeStatusPosted:
                    [self activityDidFinish:YES];
                    break;
                case ComposeStatusFailed:
                    [self activityDidFinish:NO];
                    break;
                case ComposeStatusCancelled:
                    [self activityDidFinish:NO];
                    break;
            }
        });
    };
    
    return composeViewController;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    [activityItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            self.activityString = obj;
        } else if ([obj isKindOfClass:[NSURL class]]) {
            self.activityURL = obj;
        } else if ([obj isKindOfClass:[UIImage class]]) {
            self.activityShareImage = obj;
        } else if ([obj isKindOfClass:[NSData class]]) {
            self.activityAnimatedImageData = obj;
        }
    }];
}

#pragma mark - Utils

- (NSBundle*)resourcesBundle {
    NSBundle *podbundle = [NSBundle bundleForClass:SBBAnimatedTweetActivity.class];
    NSURL *bundleURL = [podbundle URLForResource:@"SBBAnimatedTweetActivity" withExtension:@"bundle"];
    NSBundle *resourcesBundle = [NSBundle bundleWithURL:bundleURL];
    
    return resourcesBundle;
}

@end
