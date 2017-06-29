//
//  HubPointsVouchersViewController.m
//  MyHubber
//
//  Created by iDEA on 1/12/17.
//  Copyright © 2017 Blueware ST. All rights reserved.
//

#import "HubPointsVouchersViewController.h"
#import "TGLCollectionViewCell.h"
#import "TGLBackgroundProxyView.h"
#import "Constants.h"
#import "Globals.h"
#import "EmptyStateCustomView.h"
#import <CoreLocation/CoreLocation.h>
#import <UberRides/UberRides-Swift.h>

@interface HubPointsVouchersViewController ()<CLLocationManagerDelegate,UBSDKRideRequestButtonDelegate>
{
    EmptyStateCustomView            *   customEmptyStateNoVoucherCards;
    CLLocationManager               *   locationManager;
    CLLocation                      *   mycurrentLocation;
    UIActivityIndicatorView         *   uberSpinner;
    
}

@property (nonatomic, weak)     IBOutlet UIBarButtonItem    *   deselectItem;
@property (nonatomic, strong)   IBOutlet UIView             *   collectionViewBackground;
@property (nonatomic, weak)     IBOutlet UIButton           *   backgroundButton;

@property (nonatomic, strong, readonly)     NSMutableArray  *   cards;
@property (nonatomic, strong, readonly)     NSMutableArray  *   colors;
@property (nonatomic, strong)               NSTimer         *   dismissTimer;

@end

@implementation HubPointsVouchersViewController

@synthesize cards = _cards;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
        // Setting up Stackview for showing voucher cards
        CGFloat topPadding              =   90.0;
        
        if ([MyHubberUtility isiPhone5]) {
            
            topPadding                  =   77.0;
        }
        else if ([MyHubberUtility isiPhone6])
        {
            topPadding                  =   90.0;
        }
        else if ([MyHubberUtility isiPhone6Plus])
        {
            topPadding                  =   100.0;
        }
        else if ([MyHubberUtility isiPhone4])
        {
            topPadding                  =   77.0;
        }
        
        if (self.isFromXMPPChatPage) {
            topPadding                  =   0.0;
        }
        _cardCount                      =   0;
        _cardSize                       =   CGSizeZero;
        _stackedLayoutMargin            =   UIEdgeInsetsMake(topPadding+8.0, 8.0, 8.0, 8.0);
        _stackedTopReveal               =   62.0;
        _stackedBounceFactor            =   0.2;
        _stackedFillHeight              =   YES;
        _stackedCenterSingleItem        =   NO;
        _stackedAlwaysBounce            =   NO;
    }
    
    return self;
}


#pragma mark - View life cycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    

    // Initializing location manager
    locationManager                                     =   [[CLLocationManager alloc] init];
    locationManager.delegate                            =   self;
    locationManager.distanceFilter                      =   kCLDistanceFilterNone;
    locationManager.desiredAccuracy                     =   kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    [locationManager requestAlwaysAuthorization];
    
    UIImageView *bannerImageView                        =   [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
    bannerImageView.image                               =   [UIImage imageNamed:@"voucher_wallet_top_banner"];
    [self.view addSubview:bannerImageView];
    
    // Setting title label
    self.titleLabel                                     =   [[UILabel alloc]initWithFrame:CGRectMake(0, 25, self.view.frame.size.width, 30)];
    self.titleLabel.textAlignment                       =   NSTextAlignmentCenter;
    self.titleLabel.textColor                           =   [UIColor whiteColor];
    self.titleLabel.text                                =   [self.marchentDetail valueForKey:@"merchant_tradename"];
    self.titleLabel.font                                =   [UIFont fontWithName:@"Avenir-Book" size:21.0];
    [self.view addSubview:self.titleLabel];
    
    // Setting address label
    self.addressLabel                                   =   [[UILabel alloc]initWithFrame:CGRectMake(0, 55, self.view.frame.size.width, 20)];
    self.addressLabel.textAlignment                     =   NSTextAlignmentCenter;
    self.addressLabel.textColor                         =   [UIColor whiteColor];
    self.addressLabel.font                              =   [UIFont fontWithName:@"Avenir-Book" size:15.0];
    self.addressLabel.text                              =   [self.marchentDetail valueForKey:@"branch_name"];
    [self.view addSubview:self.addressLabel];
    


    
    self.navigationItem.leftBarButtonItem               =   [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-black.png"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonAction:)];
    
    // Setting stak background colors
    _colors                                             =   [[NSMutableArray  alloc]initWithObjects:[UIColor colorWithRed:125.0/255.0 green:179.0/255.0 blue:67.0/255.0 alpha:1.0],
                                                             [UIColor colorWithRed:100.0/255.0 green:180.0/255.0 blue:246.0/255.0 alpha:1.0],
                                                             [UIColor colorWithRed:0.0/255.0 green:181.0/255.0 blue:136.0/255.0 alpha:1.0],[UIColor colorWithRed:252.0/255.0 green:192.0/255.0 blue:46.0/255.0 alpha:1.0],[UIColor colorWithRed:230.0/255.0 green:89.0/255.0 blue:165.0/255.0 alpha:1.0],[UIColor colorWithRed:91.0/255.0 green:132.0/255.0 blue:226.0/255.0 alpha:1.0],[UIColor colorWithRed:195.0/255.0 green:134.0/255.0 blue:255.0/255.0 alpha:1.0],[UIColor colorWithRed:36.0/255.0 green:201.0/255.0 blue:208.0/255.0 alpha:1.0],[UIColor colorWithRed:252.0/255.0 green:141.0/255.0 blue:46.0/255.0 alpha:1.0],[UIColor colorWithRed:230.0/255.0 green:89.0/255.0 blue:89.0/255.0 alpha:1.0], nil];
    
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor],
       NSFontAttributeName: [UIFont fontWithName:APP_FONT size:APP_FONT_SIZE_17]}];
    
    
    self.collectionViewBackground.hidden                =   !self.showsBackgroundView;
    [self.view insertSubview:self.collectionViewBackground belowSubview:self.collectionView];
    
    // Setting up stack view cards
    
    TGLBackgroundProxyView *backgroundProxy             =   [[TGLBackgroundProxyView alloc] init];
    backgroundProxy.targetView                          =   self.collectionViewBackground;
    backgroundProxy.hidden                              =   self.collectionViewBackground.hidden;
    self.collectionView.backgroundView                  =   backgroundProxy;
    self.collectionView.showsVerticalScrollIndicator    =   self.showsVerticalScrollIndicator;
    
    self.exposedItemSize                                =   self.cardSize;
    self.stackedLayout.itemSize                         =   self.exposedItemSize;
    self.stackedLayout.layoutMargin                     =   self.stackedLayoutMargin;
    self.stackedLayout.topReveal                        =   self.stackedTopReveal;
    self.stackedLayout.bounceFactor                     =   self.stackedBounceFactor;
    self.stackedLayout.fillHeight                       =   self.stackedFillHeight;
    self.stackedLayout.centerSingleItem                 =   self.stackedCenterSingleItem;
    self.stackedLayout.alwaysBounce                     =   self.stackedAlwaysBounce;
    
    if (self.doubleTapToClose) {
        
        UITapGestureRecognizer *recognizer              =   [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        recognizer.delaysTouchesBegan                   =   YES;
        recognizer.numberOfTapsRequired                 =   2;
        [self.collectionView addGestureRecognizer:recognizer];
    }
    
    self.voucherWalletTitleItem.title                   =   @"";
    
    if ([[Globals returnAppLanguage] isEqualToString:@"AR"]) {
        
        self.voucherWalletTitleItem.title               =   @"";
    }
    
    customEmptyStateNoVoucherCards.hidden               =   YES;
    
    // Set the empty state
    
    if ([[Globals returnAppLanguage] isEqualToString:@"AR"]) {
        
        [self showEmptyStateNoVoucherCardsCustomView:NOVOUCHERS_EMPTYSTATE_AR  titleStr:@"Uh-Oh." withImage:@"voucher_pig_emptystate" inRect:CGRectMake(0.0, 155.0, self.view.frame.size.width, self.view.frame.size.height-155.0)];
        
    }
    else{
        
        [self showEmptyStateNoVoucherCardsCustomView:[NSString stringWithFormat:@"We’re fresh out of vouchers for you, \n maybe try again a little later!"]  titleStr:@"Uh-Oh." withImage:@"voucher_pig_emptystate" inRect:CGRectMake(0.0, 155.0, self.view.frame.size.width, self.view.frame.size.height-155.0)];
        
    }
    
    if (self.isFromXMPPChatPage) {
        bannerImageView.hidden                          =   YES;
        self.collectionView.frame                       =   CGRectMake(0.0, -90.0, SCREEN_WIDTH, SCREEN_HEIGHT);
        self.navigationController.navigationBarHidden   =   YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (!self.collectionViewBackground.hidden) {
        
        self.collectionView.backgroundColor     =   [UIColor clearColor];
    }
    
    // Setting the double tap to dismiss the card
    
    if (self.doubleTapToClose) {
        
        UIAlertController *alert                =   [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Double Tap to Close", nil)
                                                                                        message:nil
                                                                                 preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof(self) weakSelf            =   self;
        UIAlertAction *action                   =   [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                             style:UIAlertActionStyleDefault
                                                                           handler:^ (UIAlertAction *action) {
                                                                               
                                                                               [weakSelf.dismissTimer invalidate];
                                                                                weakSelf.dismissTimer = nil;
                                                                           }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:^ (void) {
            
            self.dismissTimer                   =   [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(dismissTimerFired:) userInfo:nil repeats:NO];
        }];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [_cards removeAllObjects];
    
    if (self.isToRedeemVoucher) {
       
        // Fetching the details of the voucher to redeem
        [self fetchSingleVoucherDetails];
        
    }
    else{
        if (self.isFromXMPPChatPage) {
            
            self.navigationController.navigationBarHidden       =   YES;
            // Fetching the details of all vouchers to redeem
            [self fetchAllVoucherDetails];
        }
        else{
            
            // Fetching the details of all vouchers for a branch
            [self fetchVoucherDetailsForBranch];
        }
        
    }
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    return UIStatusBarStyleLightContent;
}

- (void)dealloc {
    
    // Stop the timer for dismissing the card
    [self stopDismissTimer];
}


#pragma mark - IBActions

-(IBAction)backButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backgroundButtonTapped:(id)sender {
    
    UIAlertController *alert        =   [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Background Button Tapped", nil)
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action           =   [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler: nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)dismissTimerFired:(NSTimer *)timer {
    
    if (timer == self.dismissTimer && self.presentedViewController) {
        
        [self dismissViewControllerAnimated:YES completion:^ (void) {
            
            [self stopDismissTimer];
        }];
    }
}

- (IBAction)collapseExposedItem:(id)sender {
    
    self.exposedItemIndexPath = nil;
}

#pragma mark - EmptyState


/*!
 @brief Method for setting the empty state.
 
 
 @param  descrptionStr Description for the empty state.
 
 @param  titleStr Title for the empty state.
 
 @param  imageName Image for the empty state.
 
 @param  inRect Rect for the empty state
 
 */

-(void)showEmptyStateNoVoucherCardsCustomView:(NSString*)descrptionStr titleStr:(NSString*)titleStr withImage:(NSString*)imageName inRect:(CGRect)inRect{
    
    customEmptyStateNoVoucherCards                                  =   [[[NSBundle mainBundle] loadNibNamed:@"EmptyStateCustomView" owner:self options:nil] objectAtIndex:0];
    [customEmptyStateNoVoucherCards setFrame:inRect];
    customEmptyStateNoVoucherCards.emptyStateImageView.image        =   [UIImage imageNamed:imageName];
    customEmptyStateNoVoucherCards.descriptionLabel.text            =   descrptionStr;
    customEmptyStateNoVoucherCards.titleLabel.text                  =   titleStr;
    customEmptyStateNoVoucherCards.bgView.backgroundColor           =   [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
    [self.view addSubview:customEmptyStateNoVoucherCards];
    
}

#pragma mark - Accessors

- (void)setCardCount:(NSInteger)cardCount {
    
    // Set the number of cards here
    //
    
    if (cardCount != _cardCount) {
        
        _cardCount  =   cardCount;
        _cards      =   nil;
        if (self.isViewLoaded)
        {
            [self.collectionView reloadData];
        }
    }
}

- (NSMutableArray *)cards {
    
    if (_cards == nil) {
        
        _cards = [NSMutableArray array];
        // Adjust the number of cards here
        //
        for (NSInteger i = 0; i < self.cardCount; i++) {
            
            int indexOfColor        =   i%10;
            UIColor *cardColor      =   [_colors objectAtIndex:indexOfColor];
            NSDictionary *card      =   @{ @"name" : [NSString stringWithFormat:@"Card #%d", (int)i], @"color" : cardColor };
            [_cards addObject:card];
        }
        
    }
    
    return _cards;
}

#pragma mark - Key-Value Coding

- (void)setValue:(id)value forKeyPath:(nonnull NSString *)keyPath {
    
    // Add key-value coding capabilities for some extra properties
    //
    if ([keyPath hasPrefix:@"cardSize."]) {
        
        CGSize cardSize             =   self.cardSize;
        
        if ([keyPath hasSuffix:@".width"]) {
            
            cardSize.width          =   [value doubleValue];
            
        } else if ([keyPath hasSuffix:@".height"]) {
            
            cardSize.height         =   [value doubleValue];
        }
        
        self.cardSize               =   cardSize;
        
    } else if ([keyPath containsString:@"edLayoutMargin."]) {
        
        NSString *layoutKey         =   [keyPath componentsSeparatedByString:@"."].firstObject;
        UIEdgeInsets layoutMargin   =   [layoutKey isEqualToString:@"stackedLayoutMargin"] ? self.stackedLayoutMargin : self.exposedLayoutMargin;
        
        if ([keyPath hasSuffix:@".top"]) {
            
            layoutMargin.top        =   [value doubleValue];
            
        } else if ([keyPath hasSuffix:@".left"]) {
            
            layoutMargin.left       =   [value doubleValue];
            
        } else if ([keyPath hasSuffix:@".right"]) {
            
            layoutMargin.right      =   [value doubleValue];
        }
        
        [self setValue:[NSValue valueWithUIEdgeInsets:layoutMargin] forKey:layoutKey];
        
    } else {
        
        [super setValue:value forKeyPath:keyPath];
    }
}


#pragma mark - UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    // Show empty state if no vouchers
    
    if ([self.cards count] == 0) {
        
        customEmptyStateNoVoucherCards.hidden       =   NO;
    }
    else{
        
        customEmptyStateNoVoucherCards.hidden       =   YES;
    }
    
    return self.cards.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.item >= [self.cards count]) {
        
        return [[UICollectionViewCell alloc] init];
    }
    
    // Set up the collection view cell
    
    TGLCollectionViewCell *cell                 =   [collectionView dequeueReusableCellWithReuseIdentifier:@"CardCell" forIndexPath:indexPath];
    NSDictionary *card                          =   self.cards[indexPath.item];
    cell.titleLabel.text                        =   card[@"voucher_name"];
    cell.color                                  =   [_colors objectAtIndex:indexPath.row];
    cell.timeLabel.text                         =   [NSString stringWithFormat:@"%@ Days",card[@"daysleft"]];
    cell.nameLabel.text                         =   card[@"merchant_tradename"];
    cell.detailsButton.tag                      =   indexPath.row;
    [cell.detailsButton addTarget:self action:@selector(deatialsButtontaped:)
                 forControlEvents:UIControlEventTouchUpInside];
    
    
    UIFont *font                                =   [UIFont fontWithName:@"Avenir-Book" size:12.0];
    NSAttributedString *attributedString        =   [[NSAttributedString alloc]
                                                     initWithData: [card[@"voucher_description"] dataUsingEncoding:NSUnicodeStringEncoding]
                                                     options: @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                     documentAttributes: nil
                                                     error: nil
                                                     ];
    NSMutableParagraphStyle *paragraph          =   [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment                         =   NSTextAlignmentJustified;
    NSMutableAttributedString *formattedString        =   [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    [formattedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, formattedString.length)];
    [formattedString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, formattedString.length)];
    [cell layoutIfNeeded];
    
    // Create view for the uber rerquest button
    
    UIView *uberView                            =   [self addUberButtonForCell:cell];
    [cell.uberView addSubview:uberView];
    
    cell.detailsTextView.attributedText         =   formattedString;
    cell.detailsTextView.textColor              =   [UIColor whiteColor];
    cell.detailsButton.clipsToBounds            =   YES;
    cell.detailsButton.layer.cornerRadius       =   5.0;
    
    if (self.isFromXMPPChatPage) {
        [cell.detailsButton setTitle:@"Send" forState:UIControlStateNormal];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    // Update data source when moving cards around
    //
    NSDictionary *card          =       self.cards[sourceIndexPath.item];
    [self.cards removeObjectAtIndex:sourceIndexPath.item];
    [self.cards insertObject:card atIndex:destinationIndexPath.item];
}

/*!
 @brief Method to add uber button to the cell
 
 @param  cell The collection view cell.
 
 @return UIView with uber rides button
 */
-(UIView * )addUberButtonForCell:(TGLCollectionViewCell *)cell
{
    
    NSString *dropoffNickname                   =   [NSString stringWithFormat:@"%@ , %@",[self.marchentDetail valueForKey:@"merchant_tradename"],[self.marchentDetail valueForKey:@"branch_name"]];
    
    UIView * uberView                           =   [[UIView alloc]initWithFrame:cell.uberView.bounds];
    CLLocationDegrees droplatitude              =   [[self.marchentDetail valueForKey:@"branch_lat"] doubleValue];
    CLLocationDegrees droplongitute             =   [[self.marchentDetail valueForKey:@"branch_lng"] doubleValue];
    //Initialize Uber ride button
    UBSDKRideRequestButton *button              =   [[UBSDKRideRequestButton alloc] init];
    //Initialize Uber ride client
    UBSDKRidesClient *ridesClient               =   [[UBSDKRidesClient alloc] init];
    //Set the pickup and drop off locations
    CLLocation *pickupLocation                  =   [[CLLocation alloc] initWithLatitude: mycurrentLocation.coordinate.latitude longitude: mycurrentLocation.coordinate.longitude];
    CLLocation *dropoffLocation                 =   [[CLLocation alloc] initWithLatitude: droplatitude longitude: droplongitute];
    //Initialize Uber ride parameters builder
    __block UBSDKRideParametersBuilder *builder =   [[UBSDKRideParametersBuilder alloc] init];
    builder                                     =   [builder setPickupLocation: pickupLocation];
    builder                                     =   [builder setDropoffLocation: dropoffLocation nickname: dropoffNickname];
    //Fetch uber rides
    [ridesClient fetchCheapestProductWithPickupLocation: pickupLocation completion:^(UBSDKUberProduct* _Nullable product, UBSDKResponse* _Nullable response) {
        if (product) {
            
            //Set the informations to uber button
            builder                             =   [builder setProductID: product.productID];
            button.rideParameters               =   [builder build];
            [button loadRideInformation];
        }
    }];
    
    button.delegate                             =   self;
    button.colorStyle                           =   RequestButtonColorStyleWhite;
    button.frame                                =   uberView.bounds;
    [uberView addSubview:button];
    
    uberSpinner                                 =   [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(uberView.frame.size.width-80,0 , 60, 60)];
    uberSpinner.activityIndicatorViewStyle      =   UIActivityIndicatorViewStyleGray;
    [uberView addSubview:uberSpinner];
    [uberSpinner startAnimating];
    
    return uberView;
}


#pragma mark - CollectionView button action

-(void)deatialsButtontaped:(UIButton*)sender
{
    
    NSDictionary *card              =   self.cards[sender.tag];
    
    if (self.isFromXMPPChatPage) {
        
        //Call delegates for sending voucher to chat
        
        if ([self.chatSendDelegate respondsToSelector:@selector(vouchersProductToSendDelegate:)] )
        {
            [self.chatSendDelegate vouchersProductToSendDelegate:card];
        }
        
        return;
    }
    
    self.selectedPin                =   [card valueForKey:@"branch_pin"];
    self.selectedVoucherId          =   [card valueForKey:@"voucher_id"];
    self.selectedIconUrl            =   [card valueForKey:@"merchant_logo"];
    
    AppDelegate* appdel             =   APPDELEGATE;
    
    //Create popup for entering pin
    self.eneterPinPopUp             =   [self.storyboard instantiateViewControllerWithIdentifier:@"HubPointsEnterPinPopUpViewController"];
    self.eneterPinPopUp .delegate   =   self;
    [self.eneterPinPopUp  showInView:appdel.window animated:YES];
}

#pragma mark - Enter Pin Popup Delegate

/*!
 @brief Delegate method for the enter voucher pin pop up
 
 @param  code The code typed by user.
 
 */

-(void)submitButtonTappedWithCode:(NSString *)code
{
    if([code isEqualToString:self.selectedPin])
    {
        //Call method to redeem the selected voucher
        [self redeemVoucher];
    }
    else{
        
        UIAlertView* alert          =   [[UIAlertView alloc] initWithTitle:@"Wrong Pin" message:@"You entered a wrong pin." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - Helpers

/*!
 @brief Method to stop the timer

 */

- (void)stopDismissTimer {
    
    [self.dismissTimer invalidate];
    self.dismissTimer               =   nil;
}

/*!
 @brief Method to calculate the distance from mylocation to the shop location.
 
 
 @param  lat Latitude of the location.
 
 @param  lon Longitude of the location.
 
 */

-(void)calculatedDistaceFromCurrentLocationToLat:(NSString *)lat andLong:(NSString *)lon
{
    
    CLLocationDegrees latitude                  =   [lat doubleValue];
    CLLocationDegrees longitute                 =   [lon doubleValue];
    CLLocation *locationFromCoordinates         =   [[CLLocation alloc] initWithLatitude:latitude longitude:longitute];
    CLLocation *myLocation                      =   [[CLLocation alloc] initWithLatitude:mycurrentLocation.coordinate.latitude longitude:mycurrentLocation.coordinate.longitude];
    CLLocationDistance distance                 =   [locationFromCoordinates distanceFromLocation:myLocation];
    float kilometer                             =   distance/1000;
    NSString *deatilLabel                       =   [NSString stringWithFormat:@"%@ . %.1f km away",[self.marchentDetail valueForKey:@"branch_name" ],kilometer];
    self.addressLabel.text                      =   deatilLabel;
}

/*!
 @brief Method to show successful check out pop up.
 
 */
-(void)showCheckOutSuccessPopUp{
    
    
    AppDelegate* appDelegate                    =   APPDELEGATE;
    NSMutableDictionary *dataDictionary         =   [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                     @"Your Points are being processed",@"title",
                                                     @"Stay put! we are processing your points you should get in shortly.",@"description",
                                                     @"Got It!",@"actionButtonTitle",
                                                     @"voucher_redeem_success_icon",@"iconImage",
                                                    @"HUBPointsScanSuccessPage",@"pageType",self.selectedIconUrl,@"iconUrl", nil];
    UIStoryboard* storyboard                    =   [UIStoryboard storyboardWithName:@"HUBPointsStoryboard" bundle:nil];
    self.generalPopUp                           =   [storyboard instantiateViewControllerWithIdentifier:@"HUBGeneralPopUpViewController"];
    self.generalPopUp.delegate                  =   self;
    [self.generalPopUp showInView:appDelegate.window animated:YES withDeatails:dataDictionary];
}



#pragma mark - Web Services

/*!
 @brief Method to call the webservice to fetch the voucher details of a specific branch with branchid
 
 */

- (void)fetchVoucherDetailsForBranch
{
    NSString *userID                                    =   USER_ID;
    NSString *servicePHPStr                             =   @"voucher-wallet.php";
    NSDictionary *parameters                            =   @{@"getbranchvoucher":@"1",
                                                              @"userid":userID,
                                                              @"branchid":self.branchId,
                                                              @"type":self.type
                                                              };
    NSURL *url                                          =   [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVER_URL,servicePHPStr ]];
    
    
    AFHTTPSessionManager *manager                       =   [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    manager.responseSerializer                          =   [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes   =   [NSSet setWithObjects:@"text/html",@"text/plain",@"application/json", nil];
    [manager POST:[NSString stringWithFormat:@"%@%@", SERVER_URL,servicePHPStr ] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *responseDictionary                =   (NSDictionary *)responseObject;
        @try {

            self.voucherArray                           =   [responseDictionary objectForKey:@"voucherdetails"];
            _cardCount                                  =   self.voucherArray.count;
            for(int i=0;i<_cardCount;i++)
            {
                NSDictionary *cardsDictionary           =   [self.voucherArray objectAtIndex:i];
                [_cards addObject:cardsDictionary];
                
            }
            
            [self.collectionView reloadData];
            
        }
        @catch (NSException *exception) {
            
        }
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [AppDelegate showMessage:error.localizedDescription withTitle:@"Server Error"];
    }];
    
}

/*!
 @brief Method to call the webservice to fetch the details of a specific voucher with voucherId
 
 */

- (void)fetchSingleVoucherDetails
{
    
    
    NSString     *servicePHPStr                         =   @"voucher-wallet.php";
    NSDictionary *profileDict                           =   USER_PROFILE_DICTIONARY;
    NSDictionary *parameters                            =   @{@"VoucherById":@"1",
                                                              @"userid":[profileDict valueForKey:@"userID"],
                                                              @"voucherId":[self.selectedVoucherIDDict valueForKey:@"voucher_id"]};
    NSURL        *url                                   =   [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVER_URL,servicePHPStr ]];
    
    AFHTTPSessionManager *manager                       =   [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    manager.responseSerializer                          =   [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes   =   [NSSet setWithObjects:@"text/html",@"text/plain",@"application/json", nil];

    
    [manager POST:[NSString stringWithFormat:@"%@%@", SERVER_URL,servicePHPStr ] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *responseDictionary                =   (NSDictionary *)responseObject;
        @try {
            
            self.voucherArray                           =   [responseDictionary objectForKey:@"voucher"];
            _cardCount                                  =   self.voucherArray.count;
            for(int i=0;i<_cardCount;i++)
            {
                NSDictionary *cardsDictionary           =   [self.voucherArray objectAtIndex:i];
                [_cards addObject:cardsDictionary];
            }
            [self.collectionView reloadData];
            
        }
        @catch (NSException *exception) {
            
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [AppDelegate showMessage:error.localizedDescription withTitle:@"Server Error"];
    }];
    
}
/*!
 @brief Method to call the webservice to fetch the all voucher details that can be redeemed by the user
 
 */


- (void)fetchAllVoucherDetails
{
    NSString     *userID                                =   USER_ID
    NSString     *servicePHPStr                         =   @"voucher-wallet.php";
    NSDictionary *parameters                            =   @{@"listAllVouchers":@"1",
                                                              @"userid":userID,
                                                              };
    NSURL        *url                                   =   [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVER_URL,servicePHPStr ]];
    AFHTTPSessionManager *manager                       =   [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    manager.responseSerializer                          =   [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes   =   [NSSet setWithObjects:@"text/html",@"text/plain",@"application/json", nil];
    [manager POST:[NSString stringWithFormat:@"%@%@", SERVER_URL,servicePHPStr ] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *responseDictionary                =   (NSDictionary *)responseObject;
        @try {
            
            self.voucherArray                           =   [responseDictionary objectForKey:@"AllVouchers"];
            _cardCount                                  =   self.voucherArray.count;
            for(int i=0;i<_cardCount;i++)
            {
                NSDictionary *cardsDictionary           =   [self.voucherArray objectAtIndex:i];
                [_cards addObject:cardsDictionary];
                
            }
            
            [self.collectionView reloadData];
            
        }
        @catch (NSException *exception) {
            
        }
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        
        [AppDelegate showMessage:error.localizedDescription withTitle:@"Server Error"];
    }];
    
}

/*!
 @brief Method to call the webservice to redeem the voucher with voucherid by user with userid for the branch branchid
 
 */
-(void)redeemVoucher
{
    NSString *userID                                    =   USER_ID;
    NSString *servicePHPStr                             =   @"voucher-wallet.php";
    NSDictionary *parameters                            =   @{@"voucheridredim":@"1",
                                                              @"voucherid":self.selectedVoucherId,
                                                              @"userid":userID,
                                                              @"branchid":self.branchId
                                                              };
    
    NSURL *url                                          =   [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVER_URL,servicePHPStr ]];
    AFHTTPSessionManager *manager                       =   [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    manager.responseSerializer                          =   [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes   =   [NSSet setWithObjects:@"text/html",@"text/plain",@"application/json", nil];
    [manager POST:[NSString stringWithFormat:@"%@%@", SERVER_URL,servicePHPStr ] parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
    NSDictionary *responseDictionary = (NSDictionary *)responseObject;
        @try {
            if ([[responseDictionary valueForKey:@"is_success"] boolValue]){
                
                [self  showCheckOutSuccessPopUp];
                
            }
            else{
                
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:nil message:[responseDictionary valueForKey:@"message"] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                [alert show];
            }
            
        }
        @catch (NSException *exception) {
            
        }
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [AppDelegate showMessage:error.localizedDescription withTitle:@"Server Error"];
    }];
    
}


#pragma mark -
#pragma mark - Directions
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    
    [locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    CLLocation *location                        =   locations.firstObject;
    mycurrentLocation                           =   location;
    [locationManager stopUpdatingLocation];
    
    if ([[self.marchentDetail valueForKey:@"branch_lat"] doubleValue]>0 || [[self.marchentDetail valueForKey:@"branch_lng"] doubleValue]>0) {
        
        //Calculate the distance to the shop
        [self calculatedDistaceFromCurrentLocationToLat:[self.marchentDetail valueForKey:@"branch_lat"] andLong:[self.marchentDetail valueForKey:@"branch_lng"]];
    }
    
    
    
}


#pragma mark - UberButton Delegates

- (void)rideRequestButtonDidLoadRideInformation:(UBSDKRideRequestButton * _Nonnull)button;
{
    [uberSpinner stopAnimating];
    [uberSpinner removeFromSuperview];
}

- (void)rideRequestButton:(UBSDKRideRequestButton * _Nonnull)button didReceiveError:(UBSDKRidesError * _Nonnull)error;
{
    [uberSpinner stopAnimating];
    [uberSpinner removeFromSuperview];
    
    
}



@end
