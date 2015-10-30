//
//  Created by Simon Burbidge on 13/10/2015.
//  Copyright © 2015 Whisk Mobile Development. All rights reserved.
//

#import "SBBAnimatedTweetComposeViewController.h"
#import "FLAnimatedImageView.h"
#import "FLAnimatedImage.h"
#import "SBBTwitterAccountTableViewCell.h"

@import Accounts;
@import Social;
@import MobileCoreServices;

// These are the current values at 30/10/2015, however we hit the Twitter API to get the latest values
NSInteger const kMaxTwitterCharacterCount = 140;
NSInteger const kMaxURLCharsDefault = 23;
NSInteger const kMaxMediaCharsDefault = 23;

NSString * const TwitterAccountKey = @"SBBAnimatedTweetTwitterAccountKey";
NSString * const TwitterMaxURLCharsKey = @"SBBAnimatedTweetMaxURLCharsKey";
NSString * const TwitterMaxMediaCharsKey = @"SBBAnimatedTweetMaxMediaCharsKey";

@interface SBBAnimatedTweetComposeViewController () <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIView *composeView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *composeViewTopConstraint;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *backgroundViewTapGestureRecognizer;

@property (weak, nonatomic) IBOutlet FLAnimatedImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *twitterAccountLabel;
@property (weak, nonatomic) IBOutlet UILabel *twitterAccountTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *characterCountLabel;

@property (weak, nonatomic) IBOutlet UILabel *mainTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *postButton;

// Activity HUD
@property (weak, nonatomic) IBOutlet UIView *hudContainerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *hudActivityIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *hudStatusLabel;

// Account Picker
@property (weak, nonatomic) IBOutlet UITableView *accountPickerTableView;
@property (weak, nonatomic) IBOutlet UIButton *accountPickerCancelButton;
@property (weak, nonatomic) IBOutlet UILabel *accountPickerTitleLabel;

// Data
@property (strong, nonatomic) ACAccount *twitterAccount;
@property (strong, nonatomic) NSArray *twitterAccountsArray;
@property (assign, nonatomic) NSInteger maxUrlCharacters;
@property (assign, nonatomic) NSInteger maxImageCharacters;

@end

@implementation SBBAnimatedTweetComposeViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.composeView.layer.cornerRadius = 5.0f;
    self.composeView.clipsToBounds = YES;
    
    self.accountPickerTableView.layer.cornerRadius = 5.0f;
    self.accountPickerTableView.clipsToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.73];
    self.hudContainerView.backgroundColor = [self.highlightColor ?: [UIColor blackColor] colorWithAlphaComponent:0.9];
    self.hudStatusLabel.text = NSLocalizedString(@"Uploading...", @"Pop-up indicating the Tweet is uploading");
    [self showHUDView:NO];
    
    if (self.view.frame.size.width < 321.0f) {
        self.composeViewTopConstraint.constant = 0.0f;
    }
    
    if (self.activityAnimatedImageData) {
        FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:self.activityAnimatedImageData];
        self.imageView.animatedImage = animatedImage;
    } else {
        self.imageView.image = self.activityShareImage;
    }
    
    self.textView.text = self.activityString;
    [self textViewDidChange:self.textView]; // Need to manually call it the first time
    
    if (self.highlightColor) { // These will all remain the default blue if highlightColor = nil
        self.textView.tintColor = self.highlightColor;
        self.cancelButton.tintColor = self.highlightColor;
        self.postButton.tintColor = self.highlightColor;
        self.accountPickerCancelButton.tintColor = self.highlightColor;
    }
    self.accountPickerTitleLabel.textColor = [UIColor blackColor];
    self.twitterAccountTitleLabel.textColor = [UIColor blackColor];
    self.textView.textColor = [UIColor blackColor];
    self.mainTitleLabel.textColor = [UIColor blackColor];
    
    self.mainTitleLabel.text = NSLocalizedString(@"Twitter", @"The name of the social network - Twitter.");
    self.accountPickerTitleLabel.text = NSLocalizedString(@"Account", @"Account picker title");
    
    self.postButton.enabled = NO;
    
    self.accountPickerTableView.tableFooterView = [UIView new]; // Prevent separator lines appearing where there are no cells
    
    [self.textView becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self configureTwitterAccount];
    
    // Repeated here for iOS8, because reasons.
    [self textViewDidChange:self.textView]; // Need to manually call it the first time
    if (self.view.frame.size.width < 321.0f) {
        self.composeViewTopConstraint.constant = 0.0f;
    }
}

#pragma mark - IBActions

- (IBAction)postButtonPressed:(id)sender {
    if (self.twitterAccount) {
        [self.textView resignFirstResponder];
        [self showHUDView:YES];
        
        if (self.activityAnimatedImageData) {
            // Upload the media first, then give the "statuses/update" endpoint a list of media_ids
            NSURL *uploadUrl = [NSURL URLWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
            SLRequest *uploadRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:uploadUrl parameters:nil];
            
            // https://dev.twitter.com/rest/public/uploading-media
            // https://dev.twitter.com/rest/reference/post/media/upload
            if (self.activityShareImage && !self.activityAnimatedImageData) {
                NSData *imageData = UIImagePNGRepresentation(self.activityShareImage);
                NSData *base64Data = [imageData base64EncodedDataWithOptions:0];
                [uploadRequest addMultipartData:base64Data
                                     withName:@"media_data"
                                         type:@"image/png"
                                     filename:@"image.png"];
            }
            
            if (self.activityAnimatedImageData) {
                NSData *imageData = self.activityAnimatedImageData;
                NSData *base64Data = [imageData base64EncodedDataWithOptions:0];
                [uploadRequest addMultipartData:base64Data
                                     withName:@"media_data"
                                         type:@"application/octet-stream"
                                     filename:@"image.gif"];
            }
            
            uploadRequest.account = self.twitterAccount;
            
            [uploadRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSLog(@"Twitter HTTP response: %@", urlResponse);
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:NULL];
                NSLog(@"JSONDict: %@", jsonDict);
                NSString *mediaId = jsonDict[@"media_id_string"];
                if (mediaId) {
                    [self sendPost:@[mediaId]];
                } else {
                    [self showHUDView:NO];
                }
            }];
        } else {
            [self sendPost:nil];
        }
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self.textView resignFirstResponder];
    self.completionBlock(ComposeStatusCancelled, nil);
}

- (IBAction)backgroundTapped:(UITapGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        [self.textView resignFirstResponder];
    }
}

#pragma mark - Utils

- (void)sendPost:(NSArray *)mediaIds {
    NSMutableDictionary *params = @{
                             @"status": self.textView.text
                             }.mutableCopy;
    if (mediaIds) {
        params[@"media_ids"] = mediaIds;
    }
    
    NSURL *requestUrl = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:requestUrl parameters:params];
    postRequest.account = self.twitterAccount;
    
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Twitter HTTP response: %@", urlResponse);
        if (error) {
            self.completionBlock(ComposeStatusFailed, error);
        } else {
            self.completionBlock(ComposeStatusPosted, nil);
        }
        
        [self showHUDView:NO];
    }];
}

- (void)configureTwitterAccount {
    ACAccountStore *account = [[ACAccountStore alloc]init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [self setDefaultValues];
    
    [account requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted) {
            self.twitterAccountsArray = [account accountsWithAccountType:accountType];
            if ([self.twitterAccountsArray count] > 0) {
                
                // Check for previously chosen Twitter account
                NSString *twitterUsername = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterAccountKey];
                if (twitterUsername) {
                    [self.twitterAccountsArray enumerateObjectsUsingBlock:^(ACAccount * _Nonnull account, NSUInteger idx, BOOL * _Nonnull stop) {
//                        NSLog(@"Twitter Username: %@", account.username);
                        
                        if ([[account.username lowercaseString] isEqualToString:twitterUsername]) {
                            self.twitterAccount = account;
                            *stop = YES;
                        }
                    }];
                }
                
                // If the user hadn't selected an account previously, then choose the lastObject in the accounts array.
                if (!self.twitterAccount) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.twitterAccount = [self.twitterAccountsArray lastObject];
                            self.twitterAccountLabel.text = [NSString stringWithFormat:@"@%@", self.twitterAccount.username];
                            [self textViewDidChange:self.textView]; // To see if we can enable the postButton.
                        });

                    twitterUsername = self.twitterAccount.username;
                    [[NSUserDefaults standardUserDefaults] setObject:twitterUsername forKey:TwitterAccountKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                if (self.twitterAccount) {
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        NSURL *configUrl = [NSURL URLWithString:@"https://api.twitter.com/1.1/help/configuration.json"];
                        SLRequest *configRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:configUrl parameters:nil];
                        configRequest.account = self.twitterAccount;
                        [configRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:NULL];
                            self.maxImageCharacters = [jsonDict[@"characters_reserved_per_media"] integerValue];
                            self.maxUrlCharacters = [jsonDict[@"short_url_length"] integerValue];
                            
                            [[NSUserDefaults standardUserDefaults] setObject:@(self.maxUrlCharacters) forKey:TwitterMaxURLCharsKey];
                            [[NSUserDefaults standardUserDefaults] setObject:@(self.maxImageCharacters) forKey:TwitterMaxMediaCharsKey];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                        }];
                    });
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.twitterAccountLabel.text = [NSString stringWithFormat:@"@%@",self.twitterAccount.username];
                        [self textViewDidChange:self.textView]; // To see if we can enable the postButton.
                    });
                }
            }
        } else {
            // Permission not granted
            self.completionBlock(ComposeStatusCancelled, nil);
        }
    }];
}

- (void)setDefaultValues {
    // Set default values - figures updated from "https://api.twitter.com/1.1/help/configuration.json" above
    
    // Max number of chars used by a URL in a Tweet e.g. a 100 char URL will only count as 23 chars
    NSNumber *maxURLChars = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterMaxURLCharsKey];
    if (!maxURLChars) {
        [[NSUserDefaults standardUserDefaults] setObject:@(kMaxURLCharsDefault) forKey:TwitterMaxURLCharsKey];
        self.maxUrlCharacters = kMaxURLCharsDefault;
    } else {
        self.maxUrlCharacters = [maxURLChars integerValue];
    }
    
    // Max number of chars used by an image in a Tweet
    NSNumber *maxMediaChars = [[NSUserDefaults standardUserDefaults] objectForKey:TwitterMaxMediaCharsKey];
    if (!maxMediaChars) {
        [[NSUserDefaults standardUserDefaults] setObject:@(kMaxMediaCharsDefault) forKey:TwitterMaxMediaCharsKey];
        self.maxImageCharacters = kMaxMediaCharsDefault;
    } else {
        self.maxImageCharacters = [maxMediaChars integerValue];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UITextViewDelegate Methods

- (void)textViewDidChange:(UITextView *)textView {
    NSString *tweetString = self.textView.text;
    __block NSInteger characterCount = tweetString.length;
    
    if (self.activityAnimatedImageData) {
        characterCount += self.maxImageCharacters;
    }
    
    if (tweetString.length > 0) {
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeAddress | NSTextCheckingTypeLink | NSTextCheckingTypeDate | NSTextCheckingTypePhoneNumber error:NULL];
        [detector enumerateMatchesInString:tweetString options:0 range:[tweetString rangeOfString:tweetString] usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (result.URL && [result.URL.scheme containsString:@"http"]) {
                characterCount -= result.URL.absoluteString.length; // Remove actual length of URL
                characterCount += self.maxUrlCharacters; // Add max possible length instead (currently 23)
            }
        }];
    }
    
    NSInteger charsRemaining = kMaxTwitterCharacterCount - characterCount;
    self.characterCountLabel.text = [NSString stringWithFormat:@"%ld", (long)charsRemaining];
    if (charsRemaining < 0) {
        self.characterCountLabel.textColor = [UIColor redColor];
        self.postButton.enabled = NO;
    } else {
        self.characterCountLabel.textColor = [UIColor grayColor];
        if (self.twitterAccount) self.postButton.enabled = YES;
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [self.textView resignFirstResponder];
    return YES;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"TwitterAccountCellID";
    SBBTwitterAccountTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    ACAccount *account = self.twitterAccountsArray[indexPath.row];
    cell.accountNameLabel.text = [NSString stringWithFormat:@"@%@", account.username];
    cell.accountNameLabel.textColor = [UIColor blackColor];
    
    if ([account.identifier isEqualToString:self.twitterAccount.identifier]) {
        cell.contentView.backgroundColor = [UIColor lightGrayColor];
    } else {
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.twitterAccountsArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ACAccount *account = self.twitterAccountsArray[indexPath.row];
    
    self.twitterAccount = account;
    
    // Save the user's selected account for use next time
    [[NSUserDefaults standardUserDefaults] setObject:account.username forKey:TwitterAccountKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self showAccountPicker:NO];

    self.twitterAccountLabel.text = [NSString stringWithFormat:@"@%@",self.twitterAccount.username];
    [self textViewDidChange:self.textView]; // To see if we can enable the postButton.
}

#pragma mark - UIGestureRegognizerDelegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Orientation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Code here will execute before the rotation begins.
    // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        if (self.view.frame.size.width < 321.0f) {
            self.composeViewTopConstraint.constant = 0.0f;
        }
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

#pragma mark - HUD View

- (void)showHUDView:(BOOL)show {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        float targetAlpha = 0.0f;
        
        if (show) {
            targetAlpha = 1.0f;
            [self.hudActivityIndicatorView startAnimating];
            self.hudActivityIndicatorView.hidden = NO;
            [self.composeView bringSubviewToFront:self.hudContainerView];
        } else {
            [self.hudActivityIndicatorView stopAnimating];
            self.hudActivityIndicatorView.hidden = YES;
            [self.composeView sendSubviewToBack:self.hudContainerView];
        }
        
        [UIView animateWithDuration:0.7f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:2.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.hudContainerView.alpha = targetAlpha;
        } completion:nil];
    });
}

#pragma mark - Account Picker

- (void)showAccountPicker:(BOOL)show {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        float targetAlpha;
        if (show) {
            [self.textView resignFirstResponder];
            [self.accountPickerTableView reloadData];
            targetAlpha = 1.0f;
            [self.view bringSubviewToFront:self.accountPickerTableView];
            self.backgroundViewTapGestureRecognizer.enabled = NO;
        } else {
            [self.textView becomeFirstResponder];
            targetAlpha = 0.0f;
            [self.view sendSubviewToBack:self.accountPickerTableView];
            self.backgroundViewTapGestureRecognizer.enabled = YES;
        }
        
        [UIView animateWithDuration:0.7f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:2.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.accountPickerTableView.alpha = targetAlpha;
        } completion:nil];
    });
}

- (IBAction)accountPickerCancelButtonPressed:(id)sender {
    [self showAccountPicker:NO];
}

- (IBAction)accountPickerShowButtonPressed:(id)sender {
    [self showAccountPicker:YES];
}

@end
