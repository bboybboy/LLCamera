//
//  DBCameraSegueViewController.hViewController
//  CropImage
//
//  Created by Daniele Bogo on 19/04/14.
//  Copyright (c) 2014 Daniele Bogo. All rights reserved.
//

#import "DBCameraSegueViewController.h"
#import "DBCameraBaseCropViewController+Private.h"
#import "DBCameraCropView.h"
#import "DBCameraFiltersView.h"
#import "DBCameraFilterCell.h"
#import "DBCameraLoadingView.h"
#import "UIImage+TintColor.h"
#import "UIImage+Bundle.h"

#define kFilterCellIdentifier @"filterCell"

#ifndef DBCameraLocalizedStrings
#define DBCameraLocalizedStrings(key) \
[[NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"DBCamera" ofType:@"bundle"]] localizedStringForKey:(key) value:@"" table:@"DBCamera"]
#endif

#define buttonMargin 20.0f


@interface DBCameraSegueViewController () <UIActionSheetDelegate, UICollectionViewDelegate, UICollectionViewDataSource> {
    
    DBCameraCropView *_cropView;

    NSArray *_cropArray, *_filtersList;
    CGRect _pFrame, _lFrame;
}

@property (nonatomic, strong) UIView *navigationBar, *bottomBar;
@property (nonatomic, strong) UIButton *useButton, *retakeButton, *cropButton, *backButton;
@property (nonatomic, strong) DBCameraLoadingView *loadingView;

@end

@implementation DBCameraSegueViewController

@synthesize forceQuadCrop = _forceQuadCrop;
@synthesize useCameraSegue = _useCameraSegue;
@synthesize tintColor = _tintColor;
@synthesize selectedTintColor = _selectedTintColor;
@synthesize cameraSegueConfigureBlock = _cameraSegueConfigureBlock;

- (id) initWithImage:(UIImage *)image thumb:(UIImage *)thumb
{
    self = [super init];
    if (self) {

        _cropArray = @[ @320, @213, @240, @192, @180 ];
        _selectedFilterIndex = 0;
        
        [self setSourceImage:image];
        [self setPreviewImage:thumb];
        [self setCropRect:(CGRect){ 0, 320 }];
        [self setMinimumScale:.2];
        [self setMaximumScale:4];
        [self createInterface];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setUserInteractionEnabled:YES];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CGFloat cropX = ( CGRectGetWidth( self.frameView.frame) - 320 ) * .5;
    _pFrame = (CGRect){ cropX, ( CGRectGetHeight( self.frameView.frame) - 360 ) * .5, 320, 320 };
    _lFrame = (CGRect){ cropX, ( CGRectGetHeight( self.frameView.frame) - 240) * .5, 320, 240 };
    
    [self setCropRect:self.previewImage.size.width > self.previewImage.size.height ? _lFrame : _pFrame];
    
    [self.view addSubview:self.navigationBar];
    [self.view addSubview:self.bottomBar];
    [self.view setClipsToBounds:YES];
    
    if( self.cameraSegueConfigureBlock )
        self.cameraSegueConfigureBlock(self);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( _forceQuadCrop ) {
        [self setCropMode:YES];
        [self setCropRect:_pFrame];
        [self reset:YES];
    }
    
    if ( _cropMode )
        [_cropButton setSelected:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) cropModeAction:(UIButton *)button
{
    [button setSelected:!button.isSelected];
    [self setCropMode:button.isSelected];
    [self setCropRect:button.isSelected ? _pFrame : _lFrame];
    [self reset:YES];
}

- (void) openActionsheet:(UIButton *)button
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:DBCameraLocalizedStrings(@"general.button.cancel") destructiveButtonTitle:nil otherButtonTitles:DBCameraLocalizedStrings(@"cropmode.square"), @"3:2", @"4:3", @"5:3", @"16:9", nil];
    [actionSheet showInView:self.view];
}

- (void) createInterface
{
    _cropView = [[DBCameraCropView alloc] initWithFrame:(CGRect){ 0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height}];
    [_cropView setHidden:YES];

    [self setFrameView:_cropView];
}

- (void) retakeImage
{
    [self.navigationController popViewControllerAnimated:YES];
    [self setSourceImage:nil];
    [self setPreviewImage:nil];
}

- (void) saveImage
{
    if ( [_delegate respondsToSelector:@selector(camera:didFinishWithImage:withMetadata:)] ) {
        if ( _cropMode )
            [self cropImage];
        else {
//            UIImage *transform = [_filterMapping[@(_selectedFilterIndex.row)] imageByFilteringImage:self.sourceImage];
            [_delegate camera:self didFinishWithImage:self.sourceImage withMetadata:self.capturedImageMetadata];
        }
    }
}

- (void) cropImage
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGImageRef resultRef = [self newTransformedImage:self.imageView.transform
                                             sourceImage:self.sourceImage.CGImage
                                              sourceSize:self.sourceImage.size
                                       sourceOrientation:self.sourceImage.imageOrientation
                                             outputWidth:self.outputWidth ? self.outputWidth : self.sourceImage.size.width
                                                cropRect:self.cropRect
                                           imageViewSize:self.imageView.bounds.size];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *transform =  [UIImage imageWithCGImage:resultRef scale:1.0 orientation:UIImageOrientationUp];
            CGImageRelease(resultRef);
//            transform = [_filterMapping[@(_selectedFilterIndex.row)] imageByFilteringImage:transform];
            [_delegate camera:self didFinishWithImage:transform withMetadata:self.capturedImageMetadata];
        });
    });
}

- (void) setCropMode:(BOOL)cropMode
{
    _cropMode = cropMode;
    [self.frameView setHidden:!_cropMode];
    
    // Only hide filters if quad crop is not forced, otherwise filters are not accessible
    if (!_forceQuadCrop) {
        [self.bottomBar setHidden:!_cropMode];
        [self.filtersView setHidden:_cropMode];
    }
}

//- (DBCameraFiltersView *) filtersView
//{
//    if ( !_filtersView ) {
//        _filtersView = [[DBCameraFiltersView alloc] initWithFrame:(CGRect){ 0, CGRectGetHeight(self.view.frame)-kFilterCellSize.height, CGRectGetWidth(self.view.frame), kFilterCellSize.height} collectionViewLayout:[DBCameraFiltersView filterLayout]];
//        [_filtersView setDelegate:self];
//        [_filtersView setDataSource:self];
//        [_filtersView registerClass:[DBCameraFilterCell class] forCellWithReuseIdentifier:kFilterCellIdentifier];
//    }
//    
//    return _filtersView;
//}

- (DBCameraLoadingView *) loadingView
{
    if ( !_loadingView ) {
        _loadingView = [[DBCameraLoadingView alloc] initWithFrame:(CGRect){ 0, 0, 100, 100 }];
        [_loadingView setCenter:self.view.center];
    }
    
    return _loadingView;
}

- (UIView *) navigationBar
{
    if ( !_navigationBar ) {
        _navigationBar = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, [[UIScreen mainScreen] bounds].size.width, 64 }];
        [_navigationBar setBackgroundColor:[UIColor colorWithRed:0.24 green:0.24 blue:0.27 alpha:1]];
        [_navigationBar setUserInteractionEnabled:YES];
        [_navigationBar addSubview:self.backButton];
        
        UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WF_Logo"]];
        logoView.center = CGPointMake(_navigationBar.frame.size.width / 2, _navigationBar.frame.size.height / 2);
        [_navigationBar addSubview:logoView];
    }
    
    return _navigationBar;
}

- (UIView *) bottomBar
{
    if ( !_bottomBar ) {
        _bottomBar = [[UIView alloc] initWithFrame:(CGRect){ 0, CGRectGetHeight([[UIScreen mainScreen] bounds]) - 60, [[UIScreen mainScreen] bounds].size.width, 60 }];
        [_bottomBar setBackgroundColor:[UIColor colorWithRed:0.24 green:0.24 blue:0.27 alpha:1]];
        [_bottomBar setHidden:NO];
        [_bottomBar addSubview:self.useButton];
        [_bottomBar addSubview:self.retakeButton];
        
        UIView *dividerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2, 10, 1, 40)];
        dividerView.backgroundColor = [UIColor colorWithWhite:0 alpha:.3];
        [_bottomBar addSubview:dividerView];
    }
    
    return _bottomBar;
}

- (UIButton *) useButton
{
    if ( !_useButton ) {
        _useButton = [self baseButton];
        [_useButton setTitle:DBCameraLocalizedStrings(@"button.use")forState:UIControlStateNormal];
        [_useButton.titleLabel sizeToFit];
        [_useButton sizeToFit];
        [_useButton setFrame:(CGRect){self.view.frame.size.width / 2, 0, self.view.frame.size.width / 2, 60}];
        [_useButton addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _useButton;
}

- (UIButton *) retakeButton
{
    if ( !_retakeButton ) {
        _retakeButton = [self baseButton];
        [_retakeButton setTitle:DBCameraLocalizedStrings(@"button.retake") forState:UIControlStateNormal];
        [_retakeButton.titleLabel sizeToFit];
        [_retakeButton sizeToFit];
        [_retakeButton setFrame:(CGRect){0, 0, self.view.frame.size.width / 2, 60 }];
        [_retakeButton addTarget:self action:@selector(retakeImage) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _retakeButton;
}

- (UIButton *) backButton
{
    if ( !_backButton ) {
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 64)];
        [_backButton setImage:[[UIImage imageNamed:@"Back icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(retakeImage) forControlEvents:UIControlEventTouchUpInside];
        _backButton.tintColor = [UIColor whiteColor];
    }
    
    return _backButton;
}



- (UIButton *) cropButton
{
    if ( !_cropButton) {
        _cropButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cropButton setBackgroundColor:[UIColor clearColor]];
        [_cropButton setImage:[[UIImage imageInBundleNamed:@"Crop"] tintImageWithColor:self.tintColor] forState:UIControlStateNormal];
        [_cropButton setImage:[[UIImage imageInBundleNamed:@"Crop"] tintImageWithColor:self.selectedTintColor] forState:UIControlStateSelected];
        [_cropButton setFrame:(CGRect){ CGRectGetMidX(self.view.bounds) - 15, 15, 30, 30 }];
        [_cropButton addTarget:self action:@selector(cropModeAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cropButton;
}

- (UIButton *) baseButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setTitleColor:self.tintColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    
    return button;
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}


//#pragma mark - UICollectionViewDataSource
//
//- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//{
//    return _filtersList.count;
//}
//
//- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    DBCameraFilterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kFilterCellIdentifier forIndexPath:indexPath];
//    [cell.imageView setImage:[_filterMapping[@(indexPath.row)] imageByFilteringImage:self.previewImage]];
//    [cell.label setText:[_filtersList[indexPath.row] uppercaseString]];
//    [cell.imageView.layer setBorderWidth:(self.selectedFilterIndex.row == indexPath.row) ? 1.0 : 0.0];
//    
//    return cell;
//}
//
//- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    return kFilterCellSize;
//}
//
//#pragma mark - UICollectionViewDelegate
//
//- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    [self.view addSubview:self.loadingView];
//    
//    _selectedFilterIndex = indexPath;
//    [self.filtersView reloadData];
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIImage *filteredImage = [_filterMapping[@(indexPath.row)] imageByFilteringImage:self.sourceImage];
//        [self.loadingView removeFromSuperview];
//        [self.imageView setImage:filteredImage];
//    });
//}

#pragma mark - UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex != actionSheet.cancelButtonIndex ) {
        NSUInteger height = [_cropArray[buttonIndex] integerValue];
        CGFloat cropX = ( CGRectGetWidth( self.frameView.frame) - 320 ) * .5;
        CGRect cropRect = (CGRect){ cropX, ( CGRectGetHeight( self.frameView.frame) - (CGRectGetHeight(self.bottomBar.frame) + height) ) * .5, 320, height };
        
        [self setCropRect:cropRect];
        [self reset:YES];
    }
}

@end