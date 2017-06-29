//
//  HCClassifiedViewController.h
//  MyHubber
//
//  Created by iDEA on 4/25/16.
//  Copyright © 2016 Blueware ST. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHTCollectionViewWaterfallLayout.h"
#import "EHHorizontalSelectionView.h"
#import "HCFilterPopUpViewController.h"
#import "MyHubberCoreFetchViewController.h"

@class ClassifiedsSideMenuViewController;

@interface HCClassifiedViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate,CHTCollectionViewDelegateWaterfallLayout,MyHubberCoreFetchListControllerActionDelegate>


@property (nonatomic, strong)       ClassifiedsSideMenuViewController* sideMenuViewController;
@property (nonatomic, strong)       NSString* categoryID;
@property (nonatomic, readwrite)    BOOL    isCategoryJobs;
@property                           BOOL    fromHomeSlidePage;
@property                           BOOL    fromLandingPageSideMenu;
@property (strong, nonatomic)       NSMutableArray *tableData;
@property                           NSInteger pageCount;
@property (nonatomic, strong)       NSString* selectedCategoryId;
@property (strong, nonatomic)       HCFilterPopUpViewController *filterPopUp;
@property                           BOOL isFromXMPPChatPage;
@property (weak)                    id chatSendDelegate;

@property (nonatomic, strong)       IBOutlet UICollectionView* collectionView;
@property (weak, nonatomic)         IBOutlet UIButton *adButton;
@property (weak, nonatomic)         IBOutlet EHHorizontalSelectionView *classifiedsHorSelectionCollectionView;
@property (weak, nonatomic)         IBOutlet NSLayoutConstraint *categoryCollectionViewTopContraint;
@property (weak, nonatomic)         IBOutlet NSLayoutConstraint *collectionViewTopContraint;
@property (weak, nonatomic)         IBOutlet UIImageView *topBannerImage;


- (IBAction)sideMenuButtonPressed:(id)sender;
- (IBAction)searchButtonPressed:(id)sender;
- (IBAction)adanAd:(id)sender;


-(void) showSideView;
-(void) hideSideView:(NSString*) selection andLevel:(NSString*)level;



@end
