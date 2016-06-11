//
//  ViewController.m
//  HelloMyMap
//
//  Created by Joe Chen on 2016/5/18.
//  Copyright © 2016年 Joe Chen. All rights reserved.
//

#import "ViewController.h"
#import "MapKit/MapKit.h"
#import "CoreLocation/CoreLocation.h"
#import "RecordPositionViewController.h"


@interface ViewController ()<MKMapViewDelegate,CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
}
@property (weak, nonatomic) IBOutlet MKMapView *mainMapView;
@property (strong,nonatomic) NSMutableArray * saveLocation;
@end

@implementation ViewController



NSString *latitude;
NSString *longitude;
CLLocationCoordinate2D  coor;
NSMutableArray * saveCoor;
NSInteger trackingIndex;


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    saveCoor = [[NSMutableArray alloc]init];
    
    self.saveLocation = [[NSMutableArray alloc]init];
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray * notesFromUserDefault = [userDefaults objectForKey:@"notes"];
    
    if (notesFromUserDefault == nil) {
        self.saveLocation = [NSMutableArray array];
    } else {
        notesFromUserDefault = @[];
        self.saveLocation = [NSMutableArray arrayWithArray:notesFromUserDefault];
    }
    

    locationManager = [CLLocationManager new]; // =[[CLLocationManager alloc]init];
    //判斷ios版本有無支援使用者位置授權,ios8以後才支援
    //respondsToSelector 檢查locationManager 有無支援,這方法常用
    if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]){
        [locationManager requestWhenInUseAuthorization];
    }
    
    //prepare locationManager
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.activityType = CLActivityTypeAutomotiveNavigation; //什麼類型的運用（運動 汽車...)
    locationManager.delegate =self; //locationManager回報時回報到self
    
    
   
    
}
- (IBAction)returnUserPosition:(id)sender {
    
    NSInteger returnIndex = [sender selectedSegmentIndex];
    
    if(returnIndex == 1  ){
        [locationManager startUpdatingLocation]; //開始回報位置
    }else{
        [locationManager stopUpdatingLocation];
    }
}


- (IBAction)trackingModeChange:(id)sender {
    
    NSInteger targetIndex = [sender selectedSegmentIndex];
    
    switch (targetIndex) {
        case 0:
            _mainMapView.userTrackingMode = MKUserTrackingModeNone;
            [_mainMapView removeOverlays:[_mainMapView overlays]];
            trackingIndex = 0;
            [saveCoor removeAllObjects];
            break;
        case 1:
            _mainMapView.userTrackingMode = MKUserTrackingModeFollow;
            trackingIndex =1;
            break;
        case 2:
            _mainMapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
            trackingIndex =1;
            break;

        default:
            break;
    }
}


#pragma mark - CLLcationManagerDelegate Methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    
    CLLocation *currentLocation = locations.lastObject;
    NSLog(@"Current Location:%.6f,%.6f",currentLocation.coordinate.latitude,currentLocation.coordinate.longitude);
    
    
    //make the region change just once
    
    static dispatch_once_t changeRegionOnceToken;
    
    //下面{}裡面的程式碼只會執行一次 不管整個方法跑幾次
    dispatch_once(&changeRegionOnceToken, ^{
        
        MKCoordinateRegion region = _mainMapView.region; //region代表地圖的中心和縮放大小
        region.center = currentLocation.coordinate;
        region.span.latitudeDelta = 0.01; //地圖上看最上緣跟最下緣相差0.01緯度
        region.span.longitudeDelta = 0.01;//...
        [_mainMapView setRegion:region animated:true];
        [self uploadCurrentLocationToServer:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
        
    });
    
    latitude = [NSString stringWithFormat:@"%f",currentLocation.coordinate.latitude];
    longitude = [NSString stringWithFormat:@"%f",currentLocation.coordinate.longitude];
    
    NSDictionary * setposition = @{@"latitude":latitude,@"longitude":longitude};
    
    
    [self.saveLocation addObject:setposition];


    [[NSUserDefaults standardUserDefaults] setObject:self.saveLocation forKey:@"notes"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    
    if(trackingIndex == 1){
        [self drawMap];
    }
    
}

-(void)uploadCurrentLocationToServer:(double)latitude longitude:(double)longitude{
 
    NSString *urlString = [NSString stringWithFormat:@"http://class.softarts.cc/FindMyFriends/updateUserLocation.php?GroupName=ap102&UserName=Handsome_Joe&Lat=%.6f&Lon=%.6f",latitude,longitude];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    //Prepare NSURLSession
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask * task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(error){
            NSLog(@"Error:%@",error);
            return;
        }
        //Convert NSData to NSString
        NSString * content = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Server Reply :%@",content);
        
    }];
    
    [task resume];
    
    
}
- (IBAction)clickToFindFriends:(UIButton *)sender {
    
    
    NSString *urlString = @"http://class.softarts.cc/FindMyFriends/queryFriendLocations.php?GroupName=ap102";
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    //Prepare NSURLSession
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession * session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask * task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(error){
            NSLog(@"Error:%@",error);
            return;
        }
        
        
        NSDictionary * jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSLog(@"%@",jsonObj);
        
        NSArray * memberinfo = [[NSArray alloc]initWithArray:[jsonObj objectForKey:@"friends"]];
        
        NSLog(@"%@,%lu",memberinfo,(unsigned long)memberinfo.count);
        
        for(int i=0;i<memberinfo.count;i++){
            
            NSDictionary * memberSingleInfo = memberinfo[i];
            
            CLLocationCoordinate2D memberLocation;
            memberLocation.latitude = [[memberSingleInfo objectForKey:@"lat"]floatValue];
            memberLocation.longitude = [[memberSingleInfo objectForKey:@"lon"]floatValue];
            
            NSString * memberName = [memberSingleInfo objectForKey:@"friendName"];
            
            NSLog(@"lat:%.6f,lon:%.6f,name:%@",memberLocation.latitude,memberLocation.longitude,memberName);
            
            
            
            MKPointAnnotation * annotation = [MKPointAnnotation new];
            annotation.coordinate = memberLocation;
            annotation.title = memberName;
            
            [_mainMapView addAnnotation:annotation];
        }
        
        
    }];
    
    [task resume];
}

-(void)drawMap{
    
    coor = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
    
    NSLog(@"lat:%f,log:%f",coor.latitude,coor.longitude);
    
    NSValue * value = [NSValue valueWithMKCoordinate:coor];
    [saveCoor addObject:value];
    
    
    CLLocationCoordinate2D coordinates[saveCoor.count];
    
    for (int i =0 ; i<saveCoor.count ; i++) {
        coordinates[i] = [[saveCoor objectAtIndex:i]MKCoordinateValue];
        
    }
    
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:saveCoor.count];
    [self.mainMapView addOverlay:polyLine ];
    
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *route = overlay;
        MKPolylineRenderer *routeRenderer = [[MKPolylineRenderer alloc] initWithPolyline:route];
        routeRenderer.strokeColor = [UIColor blueColor];
        routeRenderer.lineWidth = 5;
        return routeRenderer;
    }
    else return nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    RecordPositionViewController * nextOrderPage = (RecordPositionViewController*)segue.destinationViewController;
    nextOrderPage.getPosition = self.saveLocation;
    
}

@end
