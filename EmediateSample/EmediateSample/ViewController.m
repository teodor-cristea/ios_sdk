//
//  ViewController.m
//  EmediateSample
//
//  Created by Teodor Cristea on 11/14/13.
//  Copyright (c) 2013 Teodor Cristea. All rights reserved.
//

#import "ViewController.h"
#import <EmediateAdView.h>

@interface ViewController ()

@property (nonatomic, strong) EmediateAdView *adViewTop;
@property (nonatomic, strong) EmediateAdView *adViewMiddle;
@property (nonatomic, strong) EmediateAdView *adViewBottom;

@end

@implementation ViewController
@synthesize adViewTop = _adViewTop;
@synthesize adViewMiddle = _adViewMiddle;
@synthesize adViewBottom = _adViewBottom;

#pragma mark - UIViewController

- (void)dealloc
{
    _adViewTop = nil;
    _adViewMiddle = nil;
    _adViewBottom = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.adViewTop = [[EmediateAdView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 100.f)];
    self.adViewTop.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.adViewTop];
    
    self.adViewMiddle = [[EmediateAdView alloc] initWithFrame:CGRectMake(0.f, 100.f, 320.f, 100.f)];
    self.adViewMiddle.backgroundColor = [UIColor blueColor];
    [self.view addSubview:self.adViewMiddle];
    
    self.adViewBottom = [[EmediateAdView alloc] initWithFrame:CGRectMake(0.f, 200.f, 320.f, 100.f)];
    self.adViewBottom.backgroundColor = [UIColor greenColor];
    [self.view addSubview:self.adViewBottom];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    _adViewTop = nil;
    _adViewMiddle = nil;
    _adViewBottom = nil;
}

@end
