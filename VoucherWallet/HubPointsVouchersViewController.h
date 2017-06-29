//
//  HubPointsVouchersViewController.h
//  MyHubber
//
//  Created by iDEA on 1/12/17.
//  Copyright © 2017 Blueware ST. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TGLStackedViewController.h"
#import "HUBGeneralPopUpViewController.h"
#import "HubPointsEnterPinPopUpViewController.h"
#import "MyHubberCoreFetchViewController.h"

@interface HubPointsVouchersViewController : TGLStackedViewController<MyHubberCoreFetchListControllerActionDelegate>


@property (nonatomic, assign)   BOOL showsBackgroundView;
@property (nonatomic, assign)   BOOL showsVerticalScrollIndicator;
@property (nonatomic, assign)   NSInteger cardCount;
@property (nonatomic, assign)   CGSize cardSize;
@property (nonatomic, assign)   NSMutableArray *voucherArray;
@property (nonatomic, assign)   UIEdgeInsets stackedLayoutMargin;
@property (nonatomic, assign)   CGFloat stackedTopReveal;
@property (nonatomic, assign)   CGFloat stackedBounceFactor;
@property (nonatomic, assign)   BOOL stackedFillHeight;
@property (nonatomic, assign)   BOOL stackedCenterSingleItem;
@property (nonatomic, assign)   BOOL stackedAlwaysBounce;
@property (nonatomic, assign)   BOOL doubleTapToClose;

@property (nonatomic, retain)   NSString *selectedPin;
@property (nonatomic, retain)   NSString *selectedVoucherId;
@property (nonatomic, retain)   NSString *branchId;
@property (nonatomic, retain)   NSString *selectedIconUrl;
@property (nonatomic, retain)   NSString *type;
@property  (nonatomic ,retain)  NSMutableDictionary *marchentDetail;

@property (weak, nonatomic)     IBOutlet UINavigationItem *voucherWalletTitleItem;
@property (nonatomic, retain)   IBOutlet UILabel *addressLabel;
@property (nonatomic, retain)   IBOutlet UILabel *titleLabel;


@property ()                    BOOL isFromXMPPChatPage;
@property (weak)                id chatSendDelegate;
@property ()                    BOOL isToRedeemVoucher;
@property (nonatomic,retain)    NSDictionary *selectedVoucherIDDict;

@property (nonatomic,retain)    HUBGeneralPopUpViewController *generalPopUp;
@property (nonatomic,retain)    HubPointsEnterPinPopUpViewController *eneterPinPopUp;

@end
