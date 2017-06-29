//
//  HCClassifiedViewController.m
//  MyHubber
//
//  Created by iDEA on 4/25/16.
//  Copyright © 2016 Blueware ST. All rights reserved.
//

#import "HCClassifiedViewController.h"
#import "Constants.h"
#import "ClassifiedsSideMenuViewController.h"
#import "HCCCollectionMainCell.h"
#import "HCAdDetailViewController.h"
#import "HCConstants.h"
#import "HCManager.h"
#import "SVProgressHUD.h"
#import "Newsfeed.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AppDelegate.h"
#import "LocationTracker.h"
#import "HCLocation.h"
#import "CustomHorizontalViewCell.h"
#import "UIColor+UIColorAdditions.h"
#import "UIImage+UIImageAdditions.h"
#import "HCClassifiedSearchViewController.h"
#import "CNPPopupController.h"
#import "EmptyStateCustomView.h"
#import "UIViewController+SwipeBack.h"


#define CELL_HIGHT          210
#define CELL_HIGHT_JOB      265

#define SEGUE_ADD           @"adNewAd"
#define SEGUE_JOBS          @"pushJobs"
#define SEGUE_MyAds         @"pushMyAds"
#define SEGUE_SavedAds      @"pushSavedJobs"
#define SEGUE_SEARCH_ADS    @"pushSearchAds"

#define kAd_Title           @"title"
#define kAd_ID              @"adID"
#define kAd_Price           @"price"
#define kAd_Phone           @"phone"
#define kAd_Desc            @"desc"
#define kAd_SubLocality     @"subLocality"
#define kAd_Locality        @"locality"


@interface HCClassifiedViewController () <CLLocationManagerDelegate,EHHorizontalSelectionViewProtocol>
{
    NSMutableArray                      *   adsArray;
    double                                  latitude;
    double                                  longitude;
    NSInteger                               adIndexToExplore;
    BOOL                                    shouldScrollToTop;
    NSArray                             *   allCategoriesArray;
    NSMutableArray                      *   previousDataArray;
    NSArray                             *   currentCategoriesArray;
    NSArray                             *   categoriesIndexPaths;
    NSArray                             *   initialCategoriesArray;
    BOOL                                    isExpanded;
    BOOL                                    classifiedMenuType;
    NSInteger                               lastSelectedIndex;
    BOOL                                    isLoadedSubCategories;
    UISegmentedControl                  *   modeSelectSegmentControl;
    UIView                              *   segmentControlView;
    NSInteger                               selectedJobType;
    
    EmptyStateCustomView                *   customEmptyStateNoService;
    CHTCollectionViewWaterfallLayout    *   layout;
}

@property(nonatomic , strong) NSArray            * imagesArray;
@property (nonatomic, strong) CNPPopupController * popupController;

@end

@implementation HCClassifiedViewController 

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Add swipe to go back gesture to the view controller
    [self addSwipeBackGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated) name:NOTIFICATION_UPDATE_LOCATION object:nil];
    
    // Get the saved ads details from the data model
    [[HCManager sharedManager] populateUpdateSavedAds];
    [[HCManager sharedManager] populateMaxValue];
    
    
    selectedJobType                                     =   14;
    self.navigationItem.backBarButtonItem.tintColor     =   APP_HEADER_COLOR;
  
    AppDelegate* appDelegate                            =   APPDELEGATE;
    HCLocation* locationObject                          =   [[HCManager sharedManager] locationObj];
    if ([locationObject isNoLocation]) {
        
        [SVProgressHUD showWithStatus:@"Updating location..."];
        [appDelegate.locationTracker updateLocationToServer];
    }
    else
    {
        latitude                                        =   [locationObject.latitude doubleValue];
        longitude                                       =   [locationObject.longitude doubleValue];
    }
    
    self.adButton.layer.cornerRadius                    =   self.adButton.frame.size.width/2;
    self.adButton.clipsToBounds                         =   YES;
    [MyHubberUtility giveShadowToView:self.adButton];

    layout                                              =   (CHTCollectionViewWaterfallLayout*)self.collectionView.collectionViewLayout;

    
    self.tableData                                      =   [[NSMutableArray alloc] init];
    previousDataArray                                   =   [[NSMutableArray alloc] init];
   // Get all categories from the data model
    allCategoriesArray                                  =   [HCManager readHubClassifiedsCategories];
    currentCategoriesArray                              =   [NSArray arrayWithArray:allCategoriesArray];
    initialCategoriesArray                              =   [NSArray arrayWithArray:allCategoriesArray];

    [self addForPoints];
    
    _classifiedsHorSelectionCollectionView.delegate     = self;
    [_classifiedsHorSelectionCollectionView registerCellWithClass:[EHHorizontalLineViewCell class]];
    [_classifiedsHorSelectionCollectionView setTintColor:[UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0]];
    [EHHorizontalLineViewCell updateColorHeight:2.f];
    _classifiedsHorSelectionCollectionView.textColor    =   [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:1.0];
    _classifiedsHorSelectionCollectionView.font         =   [UIFont fontWithName:@"Avenir-Medium" size:14.0];
    _classifiedsHorSelectionCollectionView.fontMedium   =   [UIFont fontWithName:@"Avenir-Heavy" size:15.0];
    [_classifiedsHorSelectionCollectionView setCellGap:20.f];
    _classifiedsHorSelectionCollectionView.hidden       =   NO;
    
    NSInteger selectedIntex                             =   [_selectedCategoryId integerValue];
    if  (selectedIntex==0)
    {
        selectedIntex=5;
    }
    [self horizontalSelection:_classifiedsHorSelectionCollectionView didSelectObjectAtIndex:selectedIntex-1];

    NSArray *jobOptionsArray                             =   [NSArray arrayWithObjects: @"Looking for Jobs", @"Looking for Employees", nil];
    modeSelectSegmentControl                             =   [[UISegmentedControl alloc] initWithItems:jobOptionsArray];
    modeSelectSegmentControl.frame                       =   CGRectMake(([UIScreen mainScreen].bounds.size.width / 2.0) - 150.0, 10.0, 300.0, 30.0);
    [modeSelectSegmentControl addTarget:self action:@selector(modeSelectionSegmentControlChanged:) forControlEvents: UIControlEventValueChanged];
    modeSelectSegmentControl.selectedSegmentIndex        =   0;
    modeSelectSegmentControl.tintColor                   =   [UIColor blackColor];
    modeSelectSegmentControl.backgroundColor             =   [UIColor whiteColor];
    modeSelectSegmentControl.layer.cornerRadius          =   CGRectGetHeight(modeSelectSegmentControl.bounds) / 2;
    modeSelectSegmentControl.layer.borderColor           =   [UIColor whiteColor].CGColor;
    modeSelectSegmentControl.layer.borderWidth           =   1;
    modeSelectSegmentControl.clipsToBounds               =   YES;
    [modeSelectSegmentControl setHidden:YES];
    segmentControlView                                   =   [[UIView alloc]initWithFrame:CGRectMake(0.0, 112.0, [UIScreen mainScreen].bounds.size.width, 50.0)];
    segmentControlView.backgroundColor                   =   [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    [segmentControlView addSubview:modeSelectSegmentControl];
    [self.view addSubview:segmentControlView];
    [segmentControlView setHidden:YES];
    
    // Set the empty state
    if ([[Globals returnAppLanguage] isEqualToString:@"AR"]) {
        
        [self showEmptyStateNoServicesCustomView:THERE_ARENT_ANY_LISTING_EMPTYSTATE_AR  titleStr:@"Whoops." withImage:@"hubboards_emptystate" inRect:CGRectMake(0.0, 108.0, self.view.frame.size.width, self.view.frame.size.height-200.0)];
    }
    else{
        
        [self showEmptyStateNoServicesCustomView:[NSString stringWithFormat:@"There aren't any listing in this category currently.\nTry again later on!."]  titleStr:@"Whoops." withImage:@"hubboards_emptystate" inRect:CGRectMake(0.0, 108.0, self.view.frame.size.width, self.view.frame.size.height-200.0)];
    }

    customEmptyStateNoService.hidden                    =   YES;
    [self.view sendSubviewToBack:customEmptyStateNoService];
    
    
    if (_fromHomeSlidePage)
    {
        [self.navigationController setNavigationBarHidden:YES];
        self.categoryCollectionViewTopContraint.constant=   self.categoryCollectionViewTopContraint.constant-64;
        self.collectionViewTopContraint.constant        =   self.collectionViewTopContraint.constant-64;
        [self.topBannerImage setHidden:YES];
        self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 155, 0);
    }
    
    self.filterPopUp                                    =   [self.storyboard instantiateViewControllerWithIdentifier:@"HCFilterPopUpViewController"];
    self.filterPopUp.delegate                           =   self;
    
    self.navigationItem.leftBarButtonItem               =   [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"arrow_back_white"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonAction:)];
    self.navigationItem.leftBarButtonItem.tintColor     =   APP_HEADER_COLOR;
    
    if (self.selectedCategoryId) {
        
        self.pageCount                                  =   0;
        // Get the first page of selected category
        [self loadLandingPageInfo:self.selectedCategoryId];
    }
    else
    {
        // Reset all paging details
        [self resetPagingDetails];
        // Get the first page of all ads
        [self loadLandingPageInfo:@""];
    }

    if (self.isFromXMPPChatPage) {
        
        self.navigationItem.leftBarButtonItem.enabled   =   NO;
        self.navigationItem.leftBarButtonItem.tintColor =   [UIColor clearColor];
        self.adButton.hidden        =   YES;
        
    }
}


-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:YES];
    
    AppDelegate *appDelegate                                    =   (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (appDelegate.shouldShowHubBoardsPlaceNewAd) {
        
        appDelegate.shouldShowHubBoardsPlaceNewAd               =   NO;
        
        //Show view controller for creating and submiting new ad
        [self pushViewControllerForAddingNewClassified];
        
    }
    //Set the title with foramtted text
    self.navigationItem.titleView                               =   [self getTitleView];
    
    if ([[Globals returnAppLanguage] isEqualToString:@"AR"]) {
        self.navigationItem.titleView                           =   [Globals getArabicTitleViewForText:HUBBOARDS_TITLE_AR WithColor:APP_HEADER_COLOR];
    }
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage         =   [UIImage new];
    self.navigationController.navigationBar.translucent         =   YES;
    self.navigationController.navigationBar.barTintColor        =   APP_HEADER_COLOR;
    self.navigationController.navigationBar.tintColor           =   APP_HEADER_COLOR;
    self.navigationController.navigationBar.backgroundColor     =   [UIColor clearColor];
    AppDelegate* appdel                                         =   APPDELEGATE;
    appdel.topView.backgroundColor                              =   [UIColor clearColor];
    self.navigationItem.backBarButtonItem.tintColor             =   APP_HEADER_COLOR;
    
}


-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    self.navigationController.navigationBar.backgroundColor     =   [UIColor clearColor];
    
    //Dismiss the loader
    [SVProgressHUD dismiss];
    
    //Enable the left bar button if view loaded from the chat
    if (self.isFromXMPPChatPage) {
        self.navigationItem.leftBarButtonItem.enabled           =   YES;
        self.navigationItem.leftBarButtonItem.tintColor         =   [UIColor blackColor];
        
    }
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_UPDATE_LOCATION object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Empty State

-(void)showEmptyStateNoServicesCustomView:(NSString*)descrptionStr titleStr:(NSString*)titleStr withImage:(NSString*)imageName inRect:(CGRect)inRect{
    
    customEmptyStateNoService                           =   [[[NSBundle mainBundle] loadNibNamed:@"EmptyStateCustomView" owner:self options:nil] objectAtIndex:0];
    [customEmptyStateNoService setFrame:inRect];
    customEmptyStateNoService.emptyStateImageView.image =   [UIImage imageNamed:imageName];
    customEmptyStateNoService.descriptionLabel.text     =   descrptionStr;
    customEmptyStateNoService.titleLabel.text           =   titleStr;
    customEmptyStateNoService.bgView.backgroundColor    =   [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
    [self.view addSubview:customEmptyStateNoService];
}



#pragma mark TitleView


-(UIView *)getTitleView
{
    CGRect frame                                        =   [[UIScreen mainScreen] bounds];
    UIView *titleView                                   =   [[UIView alloc]initWithFrame:CGRectMake(60, 0, frame.size.width-120, self.navigationController.navigationBar.frame.size.height)];
    UILabel *titleLabel                                 =   [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width-120, self.navigationController.navigationBar.frame.size.height)];
    titleLabel.backgroundColor                          =   [UIColor clearColor];
    titleLabel.textAlignment                            =   NSTextAlignmentCenter;
    titleLabel.tag                                      =   1;
    [titleLabel setTextColor:APP_HEADER_COLOR];
    [titleView addSubview:titleLabel];
    
    NSString *stringHub                                 =   @"HUB";
    NSString *stringBoard                               =   @"Boards";
    
    UIFont *avenirBold                                  =   [UIFont fontWithName:APP_HEADER_FONT_AVENIR size:APP_HEADER_SIZE];
    NSDictionary *avenirDict                            =   [NSDictionary dictionaryWithObject: avenirBold forKey:NSFontAttributeName];
    NSMutableAttributedString *attributedStringHub      =   [[NSMutableAttributedString alloc] initWithString:stringHub attributes: avenirDict];
    [attributedStringHub addAttribute:NSForegroundColorAttributeName value:APP_HEADER_COLOR range:(NSMakeRange(0, stringHub.length))];
    
    
    UIFont *milkshakeFont                               =   [UIFont fontWithName:APP_HEADER_FONT_MILKSHAKE size:APP_HEADER_SIZE];//[UIFont fontWithName:APP_FONT_MEDIUM size:14];
    NSDictionary *milkshakeDict                         =   [NSDictionary dictionaryWithObject:milkshakeFont forKey:NSFontAttributeName];
    NSMutableAttributedString *attributedStringBoard    =   [[NSMutableAttributedString alloc]initWithString:stringBoard  attributes:milkshakeDict];
    [attributedStringBoard addAttribute:NSForegroundColorAttributeName value:APP_HEADER_COLOR range:(NSMakeRange(0, stringBoard.length))];
    [attributedStringHub appendAttributedString:attributedStringBoard];
    
    titleLabel.attributedText                           =   attributedStringHub;
    
    return titleView;
}

#pragma mark - EHHorizontalSelectionViewProtocol

- (NSUInteger)numberOfItemsInHorizontalSelection:(EHHorizontalSelectionView*)hSelView
{
    if (hSelView == _classifiedsHorSelectionCollectionView)
    {
        return [self.tableData count];
    }
    return 0;
}

- (NSString *)titleForItemAtIndex:(NSUInteger)index forHorisontalSelection:(EHHorizontalSelectionView*)hSelView
{
    if (hSelView == _classifiedsHorSelectionCollectionView)
    {
        if ([[self.tableData objectAtIndex:index] isKindOfClass:[NSDictionary class]]) {
            
            return [[[self.tableData objectAtIndex:index] valueForKey:@"text"] uppercaseString];
        }
        else {
            
            return [[self.tableData objectAtIndex:index] uppercaseString];
        }

        return  [[self.tableData objectAtIndex:index] uppercaseString];
    }
    
    return @"";
}

- (EHHorizontalViewCell *)selectionView:(EHHorizontalSelectionView *)selectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (void)horizontalSelection:(EHHorizontalSelectionView * _Nonnull)hSelView didSelectObjectAtIndex:(NSUInteger)index{
    if (hSelView == _classifiedsHorSelectionCollectionView)
    {
        if (isLoadedSubCategories) {
           
            if (index == 0) {
               
                // Get the previously loaded data
                [self loadPreviousData];

            }
            else{
                
                lastSelectedIndex       =   index;
                isLoadedSubCategories   =   YES;
        
                // Load new data
                [self populateorUpdateData];
            }
        }
        else{
            
            lastSelectedIndex           =   index;
            isLoadedSubCategories       =   YES;
            
            // Load new data
            [self populateorUpdateData];

        }

    }
}

#pragma mark Segment Control

- (void)modeSelectionSegmentControlChanged:(UISegmentedControl *)segment
{
    
    if (segment.selectedSegmentIndex==0) {
        
        selectedJobType             =   14;
        self.pageCount              =   0;
        
        // Load the first page of selected category
        [self loadLandingPageInfo:self.selectedCategoryId];
    }
    else{
        selectedJobType             =   13;
        self.pageCount              =   0;
        
        // Load  the first page of selected category
        [self loadLandingPageInfo:self.selectedCategoryId];
    }
    
}

#pragma mark IBActions

- (IBAction)searchButtonPressed:(id)sender{
    
    AppDelegate* appDelegate                            =   APPDELEGATE;
    // Show popup for the filter options
    [self.filterPopUp showInView:appDelegate.window animated:YES];
    
}

-(IBAction)backButtonAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sideMenuButtonPressed:(id)sender {
    
    // Show sidemneu options
    [self showSideView];
}


- (IBAction)adanAd:(id)sender {
    // Load the view for adding new classified ad
    [self pushViewControllerForAddingNewClassified];
    
}

- (IBAction)collectionViewCellShareDotsButtonPressed:(UIButton *)button{
    
    NSIndexPath* indexPath                      =  [NSIndexPath indexPathForItem:button.tag inSection:button.imageView.tag];
    NSDictionary* adDict                        =   [adsArray objectAtIndex:indexPath.item];
    NSString *adIDStr                           =   [NSString stringWithFormat:@"%@?adid=%@&device=IOS",HUBBOARDS_APPLINK,[adDict objectForKey:@"adID"]];
    // Show the popup with selected ad details
    [self shareText:[adDict valueForKey:@"title"] andImage:nil andUrl:[NSURL URLWithString:adIDStr]];
}

#pragma mark Custom Methods
/*!
 @brief Delegate method for the filter options selected from the filter popup
 
 @param  data Selected filter parameters.

 */

-(void)selectedFilterParameteres:(NSDictionary *)data
{
    
    HCClassifiedSearchViewController *hCFiltersViewController   =   (HCClassifiedSearchViewController*) [self.storyboard   instantiateViewControllerWithIdentifier:@"HCClassifiedSearchViewController"];
    hCFiltersViewController.searchParameters                    =   data;
    [self.navigationController pushViewController:hCFiltersViewController animated:YES];
}


/*!
 @brief Method to reset all the paging details and settings
  */
-(void)resetPagingDetails
{
    self.pageCount                                      =   0;
    self.selectedCategoryId                             =   @"";
}

/*!
 @brief Delegate method to receive the location updates of the device
 */
-(void)locationUpdated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_UPDATE_LOCATION object:nil];
    //Get the new location from the model and update the location
    HCLocation* locationObj                             =   [[HCManager sharedManager] locationObj];
    latitude                                            =   [locationObj.latitude doubleValue];
    longitude                                           =   [locationObj.longitude doubleValue];
    [SVProgressHUD dismiss];
    
}

/*!
 @brief Method to show the popup with seleted add details once user share the ad with another user in the chat.
 
 @param  string The title to show.
 
 @param  image The image to display
 
 @param  URL  The url of the product
 
 */

- (void)shareText:(NSString *)string andImage:(UIImage *)image andUrl:(NSURL *)URL
{
    NSMutableArray *sharingItems                        =       [NSMutableArray new];
    
    if (string) {
        [sharingItems addObject:string];
    }
    if (image) {
        [sharingItems addObject:image];
    }
    if (URL) {
        [sharingItems addObject:URL];
    }
    
    UIActivityViewController *activityController        =   [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    
    
    [self presentViewController:activityController animated:YES completion:nil];
    
    
}

/*!
 @brief Method to show the view for adding new classified

 */

-(void) pushViewControllerForAddingNewClassified
{
    
    [self performSegueWithIdentifier:SEGUE_ADD sender:self];
    
    return;
    
}



#pragma mark -
#pragma mark - Populate Side Categories


/*!
 @brief Method to populate the subcategories of the selected category
 
*/
-(void) populateorUpdateData
{

    if (currentCategoriesArray == nil) {
        return;
    }
    
    if (lastSelectedIndex >= [currentCategoriesArray count]) {
        return;
    }
    
    isExpanded                          =   NO;

    NSDictionary* currentSelectedDict   =   [currentCategoriesArray objectAtIndex:lastSelectedIndex];
    
    if ([[currentSelectedDict valueForKey:kClassifiedsCatChildren] count]>0) {
            
        NSString *backString            =   @"Back";
        if ([[Globals returnAppLanguage] isEqualToString:@"AR"]) {
            
            backString                  =   BACK_AR;
        }
            
        NSMutableArray* categoryTempArray       =   [NSMutableArray arrayWithArray:[currentSelectedDict valueForKey:kClassifiedsCatChildren]];
        NSDictionary* startDict         =   [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"\u2B05\U0000FE0E  %@",backString],kClassifiedsCatTitle, nil];//⬅
        [categoryTempArray insertObject:startDict atIndex:0];
            
        NSString *allString             =   @"All";
        if ([[Globals returnAppLanguage] isEqualToString:@"AR"]) {
            
            allString                   =   ALL_AR;
        }
            
        NSDictionary* endDict           =   [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@ %@",allString,[currentSelectedDict valueForKey:kClassifiedsCatTitle]],kClassifiedsCatTitle,[currentSelectedDict valueForKey:kClassifiedsCatID],kClassifiedsCatID,[currentSelectedDict valueForKey:kClassifiedsCatLevel],kClassifiedsCatLevel, nil];
        [categoryTempArray insertObject:endDict atIndex:1];
        
        currentCategoriesArray          =   [[NSArray alloc] initWithArray:categoryTempArray];
        self.tableData                  =   [NSMutableArray arrayWithArray:currentCategoriesArray];
        [previousDataArray addObject:self.tableData];
        [_classifiedsHorSelectionCollectionView setHubBoardCollectionViewToIndex:1];
    }

    [_classifiedsHorSelectionCollectionView reloadData];
    
}

/*!
 @brief Method to populate the previous datas of categories
 
 */

-(void) loadPreviousData
{

    if(isLoadedSubCategories){
        
     [previousDataArray removeLastObject];

        if ([previousDataArray count]>1) {

            if ([previousDataArray count] == 0) {
                
                isLoadedSubCategories           =   NO;
                currentCategoriesArray          =   [[NSArray alloc] initWithArray:initialCategoriesArray];
                self.tableData                  =   [NSMutableArray arrayWithArray:initialCategoriesArray];
                [_classifiedsHorSelectionCollectionView reloadData];

            }
            else{
                
                currentCategoriesArray          =   [previousDataArray lastObject];
                self.tableData                  =   [NSMutableArray arrayWithArray:currentCategoriesArray];
            }
            
            [_classifiedsHorSelectionCollectionView reloadData];

        }
        else
        {
            isLoadedSubCategories               =   NO;
            currentCategoriesArray              =   [[NSArray alloc] initWithArray:initialCategoriesArray];
            self.tableData                      =   [NSMutableArray arrayWithArray:initialCategoriesArray];
            [_classifiedsHorSelectionCollectionView reloadData];

        }
        
    }
}

-(void) addForPoints
{
    NSInteger startIndex        =   [self.tableData count];
    NSMutableArray* indexpaths  =   [[NSMutableArray alloc]  init];
    
    for (NSInteger i=startIndex; i<[allCategoriesArray count]+startIndex; i++) {
        [self.tableData insertObject:[[allCategoriesArray objectAtIndex:i-startIndex] valueForKey:@"text"] atIndex:i];
        [indexpaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    categoriesIndexPaths        =   [NSArray arrayWithArray:indexpaths];
    indexpaths                  =   nil;
}


#pragma mark SideBar-Menu


/*!
 @brief Method to show the side menu
 
 */

-(void) showSideView
{
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.sideMenuViewController.view.frame              =   CGRectMake(0, 0, self.sideMenuViewController.view.frame.size.width, self.sideMenuViewController.view.frame.size.height);
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.25 animations:^{
            
            self.sideMenuViewController.backView.alpha      =   0.25;
            
        }];
        
        
    }];
}

/*!
 @brief Method to hide the side menu after selecting the category
 
 @param  selection Title of selected category.
 
 @param  level Category level of selected category.
 
 */

-(void) hideSideView:(NSString*) selection andLevel:(NSString*)level
{
    [UIView animateWithDuration:0.1 animations:^{
        
        self.sideMenuViewController.backView.alpha          =   0.0;
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            self.sideMenuViewController.view.frame         =    CGRectMake(0-[UIScreen mainScreen].bounds.size.width, 0, self.sideMenuViewController.view.frame.size.width, self.sideMenuViewController.view.frame.size.height);
            
        } completion:^(BOOL finished) {
            
            if ([selection isEqualToString:@"My Ads"]) {
                
                // Navigate to ads posted by the user
                [self performSegueWithIdentifier:SEGUE_MyAds sender:self];
            }
            else if([selection isEqualToString:@"Saved Ads"])
            {
                // Navigate to ads saved by the user
                [self performSegueWithIdentifier:SEGUE_SavedAds sender:self];
            }
            else
            {
                if (selection) {
                    
                    // Reset the paging details and load the new page with selected category
                    [self resetPagingDetails];
                    self.selectedCategoryId                 =   selection;
                    [self loadLandingPageInfo:selection];
                }
                
             }
            
        }];
    }];
    
    
}

#pragma mark - PopUp

/*!
 @brief  Method to show the popup if user select an ad from the chat.
 
 @param  popupStyle Style of the popup to show.
 
 @param  adDictionary details of the ad selected.

 */

- (void)showPopupWithStyle:(CNPPopupStyle)popupStyle dictSelected:(NSDictionary*)adDictionary{
    
    if (adDictionary == nil) {
        return;
    }
    NSString *titleStr                      =   @"";
    NSMutableAttributedString *string;
    titleStr                                =   [NSString stringWithFormat:@"%@\n",[adDictionary valueForKey:@"title"] ];
    NSString *subtitleStringText            =   [NSString stringWithFormat:@"%ld & GET %@",[[adDictionary valueForKey:@"price"] integerValue],[NSString stringWithFormat:@"%ld Pts", [[adDictionary valueForKey:@"points"] integerValue]]];
    string                                  =   [self setUpPageTitleAndSubtitle:titleStr subtitleStr:subtitleStringText thirdSubStr:@""];
    
    
    float width                             =   230.0;
    UIView *bgPlaybackView                  =   [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, 200.0)];
    bgPlaybackView.backgroundColor          =   [UIColor blackColor];
    UIImageView *imageView                  =   [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon"]];
    imageView.frame                         =   bgPlaybackView.frame;
    NSString *imageString                   =   [NSString stringWithFormat:@"%@",[adDictionary valueForKey:@"imageurl"]];
    NSURL *imageURL                         =   [NSURL URLWithString:imageString];
    if (imageURL) {
        imageView.clipsToBounds             =   YES;
        imageView.contentMode               =   UIViewContentModeScaleAspectFill;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            NSData *imageData               =   [NSData dataWithContentsOfURL:imageURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image             =   [UIImage imageWithData:imageData];
            });
        });
        
    }
    
    [bgPlaybackView addSubview:imageView];
    
    
    UIView *descriptionView                 =   [[UIView alloc] initWithFrame:CGRectMake(0.0, bgPlaybackView.frame.size.height, width, 120.0)];
    descriptionView.backgroundColor         =   [UIColor whiteColor];
    
    UILabel *titleLabel                     =   [[UILabel alloc] init];
    titleLabel.frame                        =   CGRectMake(10.0, 4.0, descriptionView.frame.size.width - 80.0, descriptionView.frame.size.height - 20.0);
    titleLabel.numberOfLines                =   0;
    titleLabel.attributedText               =   string;
    [descriptionView addSubview:titleLabel];
    
    CNPPopupButton *button                  =   [[CNPPopupButton alloc] initWithFrame:CGRectMake(descriptionView.frame.size.width - 70.0, descriptionView.frame.size.height/2.0 - 15.0, 60.0, 30.0)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font                  =   [UIFont boldSystemFontOfSize:13];
    [button setTitle:@"Send" forState:UIControlStateNormal];
    button.backgroundColor                  =   [UIColor colorWithRed:0.0/255.0 green:255.0/255.0 blue:0.0/255.0  alpha:1.0];
    button.layer.cornerRadius               =   6;
    button.selectionHandler = ^(CNPPopupButton *button){
    
        [self hubboardsSendBuyButtonTapped:adDictionary];
        [self.popupController dismissPopupControllerAnimated:YES];

    };
    
    [descriptionView addSubview:button];
    
    // Create opup with selected style and details
    
    self.popupController                    =   [[CNPPopupController alloc] initWithContents:@[bgPlaybackView, descriptionView]];
    self.popupController.theme              =   [CNPPopupTheme defaultTheme];
    self.popupController.theme.popupStyle   =   popupStyle;
    self.popupController.delegate           =   self;
    [self.popupController presentPopupControllerAnimated:YES];
}

-(NSMutableAttributedString*)setUpPageTitleAndSubtitle:(NSString*)titleStr subtitleStr:(NSString*)subtitleStr thirdSubStr:(NSString*)thirdSubStr{
    
    
    if (titleStr        == nil) {
        titleStr                                        =   @"";
    }
    if (subtitleStr     == nil) {
        subtitleStr                                     =   @"";
    }
    if (thirdSubStr     == nil) {
        thirdSubStr                                     =   @"";
    }
    
    UIFont *avenirFont                                  =   [UIFont fontWithName:@"Avenir-Roman" size:12.0];
    NSString *branchNamelabel                           =   @"";
        
    if (titleStr) {
        branchNamelabel                                 =   [NSString stringWithFormat:@"%@",[titleStr capitalizedString]];
    }
    
    
    
    NSMutableParagraphStyle *paragraphStyle             =   [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.paragraphSpacing                     =   0.05 * avenirFont.lineHeight;
    NSDictionary *avenirDict                            =   @{NSFontAttributeName:avenirFont,
                                NSParagraphStyleAttributeName:paragraphStyle,
                                };
    NSMutableAttributedString *titleAttrString          =   [[NSMutableAttributedString alloc] initWithString:branchNamelabel attributes: avenirDict];
    [titleAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:(NSMakeRange(0, branchNamelabel.length))];
    
    NSString *branchLocationlabel                       =   @"";
    if (subtitleStr) {
        branchLocationlabel                             =   subtitleStr;
    }
    UIFont *avenirLightFont                             =   [UIFont fontWithName:@"Avenir-Light" size:11.0];
    NSMutableParagraphStyle *subtitlePargraphStyle      =   [[NSMutableParagraphStyle alloc] init];
        subtitlePargraphStyle.paragraphSpacing          =   0.35 * avenirFont.lineHeight;
    NSDictionary *avenirLightDict                       =   @{NSFontAttributeName:avenirLightFont,
                                  NSParagraphStyleAttributeName:subtitlePargraphStyle,
                                  };
    NSMutableAttributedString *subTitleAttrString              =   [[NSMutableAttributedString alloc] initWithString:branchLocationlabel  attributes:avenirLightDict];
    [subTitleAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0] range:(NSMakeRange(0, branchLocationlabel.length))];
    [titleAttrString appendAttributedString:subTitleAttrString];
    
    NSMutableAttributedString *thirdSubTitleAttrString          =   [[NSMutableAttributedString alloc] initWithString:thirdSubStr  attributes:avenirDict];
    [thirdSubTitleAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:(NSMakeRange(0, thirdSubStr.length))];
    [titleAttrString appendAttributedString:thirdSubTitleAttrString];
    
    
    return titleAttrString;
    
    
    
}

/*!
 @brief Method to evoke the delegate method if the user want to send of buy the product.
 
 @param  adDetailsDictionary Details about the selected ad.
 
 */

-(void)hubboardsSendBuyButtonTapped:(NSDictionary*)adDetailsDictionary{
    
    if ([self.chatSendDelegate respondsToSelector:@selector(hubstoreProductToSendDelegate:)] )
        [self.chatSendDelegate hubBoardsProductToSendDelegate:adDetailsDictionary];
    
}

#pragma -mark Collection View

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Show empty stte if no ads
    if (adsArray.count == 0) {
        
        customEmptyStateNoService.hidden    =   NO;
    }
    else{
        
        customEmptyStateNoService.hidden    =   YES;
        
    }
    
    return [adsArray count];
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary* adDict                                =   [adsArray objectAtIndex:indexPath.item];
    if (indexPath.item == [adsArray count] - 4) {
        
        // Call method to for loading next page of selected category.
        
        [self loadLandingPageInfo:self.selectedCategoryId];
    }
    
    HCCCollectionMainCell* cell;
    
    if (self.isCategoryJobs) {
        
        // Show Job cell
        static NSString* identifier                     =   @"HCCCollectionMainCell3";
        cell                                            =   [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        cell.adTitle.text                               =   ([[adDict valueForKey:@"title"] length]>0)?[adDict valueForKey:@"title"]:@"";
        cell.adDate.text                                =   ([[adDict valueForKey:@"posteddate"] length]>0)?[adDict valueForKey:@"posteddate"]:@"";
        cell.adDescription.text                         =   ([[adDict valueForKey:@"desc"] length]>0)?[adDict valueForKey:@"desc"]:@"";
        cell.adCompany.text                             =   ([[[adDict valueForKey:@"feature"] valueForKey:@"Company Name"] length]>0)?[[adDict valueForKey:@"feature"] valueForKey:@"Company Name"]:@"";
        cell.adLocation.text                            =   [[[adDict valueForKey:@"subLocality"] stringByAppendingString:@" "]stringByAppendingString:[adDict valueForKey:@"locality"]];
        NSString *salaryString                          =   @"Negotiable";
        if(![[adDict valueForKey:@"price"] isEqualToString:@"0"])
        {
            salaryString                                =   [NSString stringWithFormat:@"%@ %@ Salary",[adDict valueForKey:@"price"],[adDict valueForKey:@"currency_code"]];
        }
        
        cell.salaryLabel.text                           =   salaryString;
        cell.layer.cornerRadius                         =   4.0;
        cell.clipsToBounds                              =   YES;
        return cell;

    }
    else
    {
        if (indexPath.item%2!=0) {

            static NSString* identifier                 =   @"HCCCollectionMainCell1";
            cell                                        =   [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
            cell.nameOfImage                            =   [NSString stringWithFormat:@"hc_%ld_display",indexPath.row+1];
            NSString *title                             =   @"";
            NSString *price                             =   @"";
            if([[adDict valueForKey:kAd_Title] length]>0)
            {
                title                                   =   [[adDict valueForKey:kAd_Title] uppercaseString];
            }
            else
            {
                title                                   =   @"";
            }

            if([[adDict valueForKey:kAd_Price] length]>0){
                
                if ([[adDict valueForKey:kAd_Price] isEqualToString:@"0"]) {
                    
                    price                               =  @"";
                }else{
                    
                    price                               =   [NSString stringWithFormat:@"%@", [adDict valueForKey:kAd_Price]];
                }
            }
            else{
                price                                   =  @"";

            }
            
            UIFont *arialFont                           =   [UIFont fontWithName:@"Avenir-Roman" size:14.0];
            NSString *priceLabel;
            if(price.length>0)
            {
                priceLabel                              =   [NSString stringWithFormat:@"%@ %@", price,[adDict valueForKey:@"currency_code"]];
            }
            else{
                priceLabel                              =  @"";
            }
            
            NSDictionary *arialDict                     =   [NSDictionary dictionaryWithObject: arialFont forKey:NSFontAttributeName];
            NSMutableAttributedString *aAttrString      =   [[NSMutableAttributedString alloc] initWithString:priceLabel attributes: arialDict];
            [aAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:(NSMakeRange(0, priceLabel.length))];
            
            NSString *namelabel                         =   [title uppercaseString];
            UIFont *VerdanaFont                         =   [UIFont fontWithName:@"Avenir-Light" size:11.0];
            NSDictionary *verdanaDict                   =   [NSDictionary dictionaryWithObject:VerdanaFont forKey:NSFontAttributeName];
            NSMutableAttributedString *vAttrString      =   [[NSMutableAttributedString alloc]initWithString:namelabel  attributes:verdanaDict];
            [vAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:(NSMakeRange(0, namelabel.length))];
            
            cell.adTitle.attributedText                 =   vAttrString;
            cell.adPrice.attributedText                 =   aAttrString;
            
            __weak UIImageView*imageView                =   cell.bigImage;
            NSString* imageTypo                         =   [adDict valueForKey:@"media"];
            
            if ([imageTypo containsString:@".mov"]||[imageTypo containsString:@".mp4"]) {
                
                imageTypo                               =   [adDict valueForKey:@"videothumb"];
            }
            
            NSString *classifiedsServicesPlaceholder    =   @"hubboards_placeholder-image.png";//Services ->
            
            if ([[adDict valueForKey:@"category"] rangeOfString:@"Services ->"].location != NSNotFound) {
                
                classifiedsServicesPlaceholder          =   @"placeholder_services";
            }
            else if ([[adDict valueForKey:@"category"] rangeOfString:@"Vehicles & Parts ->"].location != NSNotFound) {
                
                classifiedsServicesPlaceholder          =   @"placeholder_vehiclesparts";
            }
            else if ([[adDict valueForKey:@"category"] rangeOfString:@"Property ->"].location != NSNotFound) {
                
                classifiedsServicesPlaceholder          =   @"placeholder_property";
            }
            else if ([[adDict valueForKey:@"category"] rangeOfString:@"Classifieds ->"].location != NSNotFound) {
                
                classifiedsServicesPlaceholder          =   @"placeholder_classifieds";
            }
        
            
 
            NSString* imageURL                          =   [NSString stringWithFormat:@"%@%@",HUBBOARD_PRODUCT_IMAGES_URL,imageTypo];
            
            // Set the image by calling afnetworking method
            
            [imageView af_setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:classifiedsServicesPlaceholder]];
            
            
            cell.layer.cornerRadius                     =   8.0;
            cell.clipsToBounds                          =   YES;
            
            
            imageView.clipsToBounds                     =   YES;
            
            cell.bigImage.clipsToBounds                 =   YES;
            
            cell.cellBgview.layer.cornerRadius          =   8.0;
            
            // Add shadow effect to the collection view cell
            
            [self addShadowToCell:cell];
            

            cell.shareDotsButton.hidden                 =   YES;

            return cell;
        }
        else
        {
            // Show small two cells in a row
            static NSString* identifier                 =   @"HCCCollectionMainCell1";
            cell                                        =   [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
            cell.nameOfImage                            =   [NSString stringWithFormat:@"hc_%ld_display",indexPath.row+1];

            
            cell.layer.cornerRadius                      =   8.0;
            cell.clipsToBounds                          =   YES;
            
            NSString *title                             =   @"";
            NSString *price                             =   @"";
            
            if([[adDict valueForKey:kAd_Title] length]>0)
            {
                title                                   =   [[adDict valueForKey:kAd_Title] uppercaseString];
            }
            else
            {
                title                                   =   @"";
            }
            if([[adDict valueForKey:kAd_Price] length]>0){
                if ([[adDict valueForKey:kAd_Price] isEqualToString:@"0"]) {
                    
                    price                               =   @"";
                }else{
                    price                               =   [NSString stringWithFormat:@"%@", [adDict valueForKey:kAd_Price]];
                    
                }
            }
            else{
                
                price                                   =   @"";
                
            }
            
            UIFont *arialFont                           =   [UIFont fontWithName:@"Avenir-Roman" size:14.0];
            
            NSString *priceLabel;
            if(price.length>0)
            {
                priceLabel                              =   [NSString stringWithFormat:@"%@ %@", price,[adDict valueForKey:@"currency_code"]];
            }
            else{
                priceLabel                              =  @"";
            }
            
            
            NSDictionary *arialDict                     =   [NSDictionary dictionaryWithObject: arialFont forKey:NSFontAttributeName];
            NSMutableAttributedString *aAttrString      =   [[NSMutableAttributedString alloc] initWithString:priceLabel attributes: arialDict];
            [aAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:(NSMakeRange(0, priceLabel.length))];
            
            NSString *namelabel                         =   [title uppercaseString];
            UIFont *VerdanaFont                         =   [UIFont fontWithName:@"Avenir-Light" size:11.0];
            NSDictionary *verdanaDict                   =   [NSDictionary dictionaryWithObject:VerdanaFont forKey:NSFontAttributeName];
            NSMutableAttributedString *vAttrString      =   [[NSMutableAttributedString alloc]initWithString:namelabel  attributes:verdanaDict];
            [vAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:(NSMakeRange(0, namelabel.length))];

            cell.adTitle.attributedText                 =   vAttrString;
            cell.adPrice.attributedText                 =   aAttrString;
            

            NSString *classifiedsServicesPlaceholder    =   @"hubboards_placeholder-image.png";//Services ->
            
            if ([[adDict valueForKey:@"category"] rangeOfString:@"Services ->"].location != NSNotFound) {
                
                classifiedsServicesPlaceholder          =   @"placeholder_services";
            }
            else if ([[adDict valueForKey:@"category"] rangeOfString:@"Vehicles & Parts ->"].location != NSNotFound) {
                
                classifiedsServicesPlaceholder          =   @"placeholder_vehiclesparts";
            }
            else if ([[adDict valueForKey:@"category"] rangeOfString:@"Property ->"].location != NSNotFound) {
                
                classifiedsServicesPlaceholder          =   @"placeholder_property";
            }
            else if ([[adDict valueForKey:@"category"] rangeOfString:@"Classifieds ->"].location != NSNotFound) {
                
                classifiedsServicesPlaceholder          =   @"placeholder_classifieds";
            }
            

            __weak UIImageView*imageView                =   cell.bigImage;
            NSString* imageTypo                         =   [adDict valueForKey:@"media"];
            if ([imageTypo containsString:@".mov"]||[imageTypo containsString:@".mp4"]) {
                
                imageTypo                               =   [adDict valueForKey:@"videothumb"];
            }
            NSString* imageURL                          =   [NSString stringWithFormat:@"%@%@",HUBBOARD_PRODUCT_IMAGES_URL,imageTypo];
            // Set the image by calling afnetworking method
            [imageView af_setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:classifiedsServicesPlaceholder]];
            imageView.clipsToBounds                     =   YES;
            cell.shareDotsButton.hidden                 =   YES;
            cell.bigImage.clipsToBounds                 =   YES;
            imageView.clipsToBounds                     =   YES;
            cell.bigImage.clipsToBounds                 =   YES;
            cell.cellBgview.layer.cornerRadius          =   8.0;
            // Add shadow effect to the collection view cell
            [self addShadowToCell:cell];
            return cell;
        }
    }
   
    return nil;
    
}



- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    
    if (self.isCategoryJobs)
    {
        return UIEdgeInsetsMake(0, 8, 1, 8);
    }
    
    return UIEdgeInsetsMake(8, 8, 8, 8);
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if (self.isCategoryJobs)
    {
        return 1.0;
    }
    
    return 8.0;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    
    if (self.isCategoryJobs)
    {
        return 1.0;
    }
    
    return 8.0;
    
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isFromXMPPChatPage) {
        
        NSDictionary* adDict                                    =   [adsArray objectAtIndex:indexPath.item];
        // Show popup on selecting the cell form the chat
        [self showPopupWithStyle:CNPPopupStyleCentered dictSelected:adDict];
    }
    else{
        
        // Goto details about the ad
        HCAdDetailViewController* adDetail                      =   [self.storyboard instantiateViewControllerWithIdentifier:@"HCAdDetailViewController"];
        adDetail.adID                                           =   [[adsArray objectAtIndex:indexPath.item] valueForKey:@"adID"];
        adDetail.isCategoryJobs                                 =   self.isCategoryJobs;
        
        if (_fromHomeSlidePage)
        {
            UIViewController *topController                     =   [RUUtilities topViewController];
            UINavigationController* topNavigationController     =   topController.navigationController;
            
            [topNavigationController pushViewController:adDetail animated:YES];
        }
        else{
            [self.navigationController pushViewController:adDetail animated:YES];
        }
    }
   
    

}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Jobs case
     CGFloat width=[[UIScreen mainScreen] bounds].size.width-30;
    if (self.isCategoryJobs) {

        return CGSizeMake(width, 70.0);
    }
    
    // rest of cases
    if (indexPath.item%2!=0) {
        // right case
        return CGSizeMake(width/2, CELL_HIGHT+25);
    }
    else
    {   // left case
        return CGSizeMake(width/2, CELL_HIGHT+25);//+0.0
    }
    
    return CGSizeMake(0, 0);
}


/*!
 @brief method to add shadow effect to the collection view cell.
 
 @param  cell Collection view cell.

 
 */

-(void) addShadowToCell:(UICollectionViewCell*)cell
{
    [cell.layer setBorderColor:[UIColor clearColor].CGColor];
    [cell.layer setBorderWidth:1.0f];
    [cell.layer setShadowOffset:CGSizeMake(0, 1)];
    [cell.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [cell.layer setShadowRadius:2.0];
    [cell.layer setShadowOpacity:0.3];
    [cell.layer setMasksToBounds:NO];
    
}

/*!
 @brief Method to get attributed string for the price and currency.
 
 @param  priceStr Price of the ad.
 
 @param  cellLabel Label for thr price in the collection view cell.
 
 @return Attributed string for the price
 
 */

-(NSMutableAttributedString*)returnPriceLabelWithCurrency:(NSString*)priceStr priceLabel:(UILabel*)cellLabel {
    
    NSString *currencyStr                      =   @"AED ";
    UIFont *avenirFont                           =   [UIFont fontWithName:@"Avenir-Heavy" size:12];
    NSDictionary *avenirDict                     =   [NSDictionary dictionaryWithObject: avenirFont forKey:NSFontAttributeName];
    NSMutableAttributedString *attrCurrencyStr     =   [[NSMutableAttributedString alloc] initWithString:currencyStr attributes: avenirDict];
    [attrCurrencyStr addAttribute:NSForegroundColorAttributeName value:cellLabel.textColor range:(NSMakeRange(0, currencyStr.length))];
    
    NSMutableAttributedString *priceAttrString      =   [[NSMutableAttributedString alloc]initWithString:priceStr  attributes:avenirDict];
    [priceAttrString addAttribute:NSForegroundColorAttributeName value:cellLabel.textColor range:(NSMakeRange(0, priceStr.length))];
    [attrCurrencyStr appendAttributedString:priceAttrString];

    return attrCurrencyStr;
}


#pragma mark WebServices


/*!
 @brief Method to get lacation using the google api if current location is not availble in the location manager model.
 
 
 */

-(void)fetchLocationUsingGoogleAPI{
    
    //URL for google api with the api key
    NSString *urlString                                 =   [NSString stringWithFormat:
                                                             @"https://www.googleapis.com/geolocation/v1/geolocate?key=%@",
                                                            GOOGLE_LOCATION_KEY];
    NSURL *url                                          =   [NSURL URLWithString:urlString];
    AFHTTPSessionManager *manager                       =   [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    manager.responseSerializer                          =   [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes   =   [NSSet setWithObjects:@"text/html",@"text/plain",@"application/json", nil];
    
    [manager POST:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *responsedict                      =   responseObject;
        NSDictionary *locationDict                      =   [responsedict objectForKey:@"location"];
        NSString *latStr                                =   [locationDict objectForKey:@"lat"];
        NSString *longStr                               =   [locationDict objectForKey:@"lng"];
        
        if (latStr == nil || longStr == nil) {
            return;
        }
        //Update the location and call the next page for selected category
        latitude                                        =   [latStr doubleValue];
        longitude                                       =   [longStr doubleValue];
        
        [self loadLandingPageInfo:self.selectedCategoryId];
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {

        
    }];
}


/*!
 @brief Method to call the webservice to get the next page for the selected category.
 
  @param  categoryID Selected category id from side menu or top menu.
 */

-(void) loadLandingPageInfo:(NSString*)categoryID
{
    if (latitude== 0.0 && longitude == 0.0) {
        
        //fetch location using google api if location not available
        [self fetchLocationUsingGoogleAPI];
        return;
    }
    
    if ([categoryID isEqualToString:@"13"]) {
        
        [modeSelectSegmentControl setSelectedSegmentIndex:0];
    }
    if ([categoryID isEqualToString:@"14"]) {
        
       [modeSelectSegmentControl setSelectedSegmentIndex:1];
    }
    
    self.pageCount                                                  =   self.pageCount+1;
    NSString *pageCountString                                       =   [NSString stringWithFormat:@"%ld",(long)self.pageCount];
    NSDictionary* parameters;
    if ([categoryID isEqualToString:@"3"]) {
        
        categoryID                                                  =   [NSString stringWithFormat:@"%ld",(long)selectedJobType];
    }
    if (categoryID) {
        [SVProgressHUD showWithStatus:@"Loading ads..."];
        
        parameters                                                  =   @{@"listAllAd":@"1",
                                                                          @"origLat":@(latitude),
                                                                          @"origLon":@(longitude),
                                                                          @"catID":categoryID,
                                                                          @"page":pageCountString,
                                                                          @"per_page":@"20"
                                                                          };
    }
    else{
        
        [SVProgressHUD showWithStatus:@"Locating ads near you.."];
        parameters                                                  =   @{@"listAllAd":@"1",
                                                                          @"origLat":@(latitude),
                                                                          @"origLon":@(longitude),
                                                                          @"catID":@"",
                                                                          @"page":pageCountString,
                                                                          @"per_page":@"20"
                                                                          };
    }
    
    _classifiedsHorSelectionCollectionView.userInteractionEnabled   =   NO;
    
    //Call the webservice in MyhubberWebRequest model using the selected parameters
    
    [MyHubberWebRequest sendWebRequestWithParameters:parameters toPageName:@"Classifieds-Services.php" withSuccessblock:^(NSURLSessionDataTask *task, id responseObject) {
        
    NSDictionary* dictionary=(NSDictionary*)responseObject;
    _classifiedsHorSelectionCollectionView.userInteractionEnabled   =   YES;

        if ([[dictionary valueForKey:@"is_success"] boolValue]) {
            
            if (self.pageCount==1) {
                
                if (!adsArray) {
                    
                    adsArray                                        =   [[NSMutableArray alloc]init];
                }
                else{
                    
                    [adsArray removeAllObjects];
                }
                
                NSArray *feeds                                      =   [dictionary valueForKey:@"adDetails"];
                for (int i = 0; i < feeds.count; i++) {
                    
                    NSDictionary *dictttt                           =   [feeds objectAtIndex:i];
                    
                    [adsArray addObject:dictttt];
                }
                
                _isCategoryJobs=[self isCategoryIDJobs:categoryID];
                

                [self.collectionView reloadData];
                
                [self.collectionView setContentOffset:CGPointZero animated:YES];
            }
            else{
                
                
                NSArray *feeds                                      =   [dictionary valueForKey:@"adDetails"];
                NSInteger totalCount                                =   [adsArray count];
                
                
                NSMutableArray *indexPaths                          =   [[NSMutableArray alloc]init];
                
                
                for (int i = 0; i < feeds.count; i++) {
                    
                    NSDictionary *dictttt                           =   [feeds objectAtIndex:i];
                    
                    [indexPaths addObject:[NSIndexPath indexPathForRow:totalCount + i
                                                             inSection:0]];
                    
                    [adsArray addObject:dictttt];
                }
                

                [self.collectionView performBatchUpdates:^{
                    [self.collectionView insertItemsAtIndexPaths:indexPaths];
                } completion:nil];

            
            }

        }
        
        [SVProgressHUD dismiss];
        
    } andFailureBlock:^(NSURLSessionDataTask *task, NSError *error) {
        
        _classifiedsHorSelectionCollectionView.userInteractionEnabled =   YES;

       [SVProgressHUD dismiss];
        
    }];
        
}

/*!
 @brief Method to check if selected category is Job type
 
 @param  categoryID Selected category id.

 @return Return YES if the selected category is job type , else return NO.
 */

-(BOOL) isCategoryIDJobs:(NSString*) categoryID
{
    
    if ([categoryID isEqualToString:@"3"] ||[categoryID isEqualToString:@"13"] || [categoryID isEqualToString:@"14"]) {
        
        layout.columnCount                              =   1;
        self.collectionViewTopContraint.constant        =   162;
        [modeSelectSegmentControl setHidden:NO];
        [segmentControlView setHidden:NO];
        if (![categoryID isEqualToString:@"3"]) {
            
            selectedJobType                             =   [categoryID integerValue];
        }
        self.collectionView.backgroundColor             =   [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
        return YES;
    }
    
    layout.columnCount                                  =   2;
    self.collectionViewTopContraint.constant            =   112;
    [modeSelectSegmentControl setHidden:YES];
    [segmentControlView setHidden:YES];
    self.collectionView.backgroundColor                 =   [UIColor clearColor];
    return NO;
}






@end
