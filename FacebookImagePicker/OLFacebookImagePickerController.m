//
//  FacebookImagePickerController.m
//  FacebookImagePicker
//
//  Created by Deon Botha on 16/12/2013.
//  Copyright (c) 2013 Deon Botha. All rights reserved.
//

#import "OLFacebookImagePickerController.h"
#import "OLAlbumViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
//#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface OLFacebookImagePickerController () <OLAlbumViewControllerDelegate>
@property (nonatomic, strong) OLAlbumViewController *albumVC;
@property (assign, nonatomic) BOOL haveSeenViewDidAppear;
@end

@implementation OLFacebookImagePickerController

@dynamic delegate;

- (id)init {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    if (self = [super initWithRootViewController:vc]) {
        _shouldDisplayLogoutButton = YES;
        _shouldDisplayCancelButton = YES;
        _isMultiselectEnabled = YES;
        if ([FBSDKAccessToken currentAccessToken]){
            [self showAlbumList];
        }
    }
    
    return self;
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self permissionRequest];
}

- (void)permissionRequest{
    if ((![[FBSDKAccessToken currentAccessToken] hasGranted:@"public_profile"] || ![[FBSDKAccessToken currentAccessToken] hasGranted:@"user_photos"]) && !self.haveSeenViewDidAppear){
        self.haveSeenViewDidAppear = YES;
        
        //Workaround so that we dont include FBSDKLoginKit
        NSArray *permissions = @[@"public_profile", @"user_photos"];
        Class FBSDKLoginManagerClass = NSClassFromString (@"FBSDKLoginManager");
        id login = [[FBSDKLoginManagerClass alloc] init];
        
        SEL aSelector = NSSelectorFromString(@"logInWithReadPermissions:fromViewController:handler:");
        
        if([login respondsToSelector:aSelector]) {
            void (*imp)(id, SEL, id, id, id) = (void(*)(id,SEL,id,id, id))[login methodForSelector:aSelector];
            if( imp ) imp(login, aSelector, permissions, self, ^(id result, NSError *error) {
                if (error) {
                    [self.delegate facebookImagePicker:self didFailWithError:error];
                } else if ([result isCancelled]) {
                    [self.delegate facebookImagePicker:self didFinishPickingImages:@[]];
                } else {
                    [self showAlbumList];
                }
                if ([self.delegate respondsToSelector:@selector(facebookImagePicker:fbLoginResult:error:)]){
                    [self.delegate facebookImagePicker:self fbLoginResult:result error:error];
                }
            });
        }
    }
}

- (void)showAlbumList{
    OLAlbumViewController *albumController = [[OLAlbumViewController alloc] init];
    self.albumVC = albumController;
    self.albumVC.delegate = self;
    self.albumVC.isMultiselectEnabled = self.isMultiselectEnabled;
    self.albumVC.shouldDisplayLogoutButton = self.shouldDisplayLogoutButton;
    self.albumVC.shouldDisplayCancelButton = self.shouldDisplayCancelButton;
    self.viewControllers = @[albumController];
}

- (void)setSelected:(NSArray *)selected {
    self.albumVC.selected = selected;
}

- (NSArray *)selected {
    return self.albumVC.selected;
}

- (void)setIsMultiselectEnabled:(BOOL)isMultiselectEnabled
{
    _isMultiselectEnabled = isMultiselectEnabled;
    self.albumVC.isMultiselectEnabled = self.isMultiselectEnabled;
}

- (void)setShouldDisplayLogoutButton:(BOOL)shouldDisplayLogoutButton
{
    _shouldDisplayLogoutButton = shouldDisplayLogoutButton;
    self.albumVC.shouldDisplayLogoutButton = self.shouldDisplayLogoutButton;
}

- (void)setShouldDisplayCancelButton:(BOOL)shouldDisplayCancelButton
{
    _shouldDisplayCancelButton = shouldDisplayCancelButton;
    self.albumVC.shouldDisplayCancelButton = self.shouldDisplayCancelButton;
}

-(void)setNavigationBarTitle:(NSString *)title{
    self.albumVC.title = title;
}

#pragma mark - OLAlbumViewControllerDelegate methods

- (void)albumViewControllerDoneClicked:(OLAlbumViewController *)albumController {
    [self.delegate facebookImagePicker:self didFinishPickingImages:albumController.selected];
}

- (void)albumViewControllerCancelClicked:(OLAlbumViewController *)albumController {
    [self.delegate facebookImagePickerDidCancelPickingImages:self];
}

- (void)albumViewController:(OLAlbumViewController *)albumController didFailWithError:(NSError *)error {
    [self.delegate facebookImagePicker:self didFailWithError:error];
}

- (void)albumViewController:(OLAlbumViewController *)albumController didSelectImage:(OLFacebookImage *)image{
    if ([self.delegate respondsToSelector:@selector(facebookImagePicker:didSelectImage:)]){
        [self.delegate facebookImagePicker:self didSelectImage:image];
    }
}

- (BOOL)albumViewController:(OLAlbumViewController *)albumController shouldSelectImage:(OLFacebookImage *)image{
    if ([self.delegate respondsToSelector:@selector(facebookImagePicker:shouldSelectImage:)]){
        return [self.delegate facebookImagePicker:self shouldSelectImage:image];
    }
    else{
        return YES;
    }
}

- (void)albumViewControllerRefreshAccessToken:(OLAlbumViewController *)albumController{
    [self permissionRequest];
}

@end
