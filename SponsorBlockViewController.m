#import "Headers/SponsorBlockViewController.h"
#import "Headers/Localization.h"

@implementation SponsorBlockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self addChildViewController:self.playerViewController];
    [self.view addSubview:self.playerViewController.view];
    [self setupViews];
}

- (NSArray *)skipSegments {
    YTPlayerView *playerView = (YTPlayerView *)self.playerViewController.view;
    YTMainAppVideoPlayerOverlayView *overlayView = (YTMainAppVideoPlayerOverlayView *)playerView.overlayView;
    if ([overlayView isKindOfClass:NSClassFromString(@"YTMainAppVideoPlayerOverlayView")]) {
        id <YTPlayerBarProtocol> object = [overlayView.playerBar respondsToSelector:@selector(modularPlayerBar)] ? overlayView.playerBar.modularPlayerBar : overlayView.playerBar.segmentablePlayerBar;
        if ([object isKindOfClass:NSClassFromString(@"YTSegmentableInlinePlayerBarView")])
            return ((YTSegmentableInlinePlayerBarView *)object).skipSegments;
        if ([object isKindOfClass:NSClassFromString(@"YTModularPlayerBarController")]) {
            YTModularPlayerBarView *view = ((YTModularPlayerBarController *)object).view;
            if ([view isKindOfClass:NSClassFromString(@"YTModularPlayerBarView")])
                return view.skipSegments;
        }
    }
    return nil;
}

- (void)setupViews {
    [self.segmentsInDatabaseLabel removeFromSuperview];
    [self.userSegmentsLabel removeFromSuperview];
    [self.submitSegmentsButton removeFromSuperview];
    [self.whitelistChannelLabel removeFromSuperview];
    
    self.sponsorSegmentViews = [NSMutableArray array];
    self.userSponsorSegmentViews = [NSMutableArray array];
    
    if (!self.startEndSegmentButton) {
        self.startEndSegmentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.startEndSegmentButton.backgroundColor = UIColor.blueColor;
        [self.startEndSegmentButton addTarget:self action:@selector(startEndSegmentButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.playerViewController.userSkipSegments.lastObject.endTime != -1) {
            [self.startEndSegmentButton setTitle:LOC(@"SegmentStartsNow") forState:UIControlStateNormal];
        } else {
            [self.startEndSegmentButton setTitle:LOC(@"SegmentEndsNow") forState:UIControlStateNormal];
        }
        self.startEndSegmentButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.playerViewController.view addSubview:self.startEndSegmentButton];
        self.startEndSegmentButton.layer.cornerRadius = 12;
        self.startEndSegmentButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.startEndSegmentButton.topAnchor constraintEqualToAnchor:self.playerViewController.view.bottomAnchor constant:10].active = YES;
        [self.startEndSegmentButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
        [self.startEndSegmentButton.widthAnchor constraintEqualToConstant:self.view.frame.size.width / 2].active = YES;
        [self.startEndSegmentButton.heightAnchor constraintEqualToConstant:50].active = YES;
        self.startEndSegmentButton.clipsToBounds = YES;
    }
    
    self.whitelistChannelLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.whitelistChannelLabel.text = LOC(@"WhitelistChannel");
    [self.playerViewController.view addSubview:self.whitelistChannelLabel];
    self.whitelistChannelLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.whitelistChannelLabel.topAnchor constraintEqualToAnchor:self.startEndSegmentButton.bottomAnchor constant:10].active = YES;
    [self.whitelistChannelLabel.centerXAnchor constraintEqualToAnchor:self.startEndSegmentButton.centerXAnchor].active = YES;
    [self.whitelistChannelLabel.widthAnchor constraintEqualToConstant:185].active = YES;
    [self.whitelistChannelLabel.heightAnchor constraintEqualToConstant:31].active = YES;
    self.whitelistChannelLabel.userInteractionEnabled = YES;
    
    UISwitch *whitelistSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51, 31)];
    [whitelistSwitch addTarget:self action:@selector(whitelistSwitchToggled:) forControlEvents:UIControlEventValueChanged];
    [self.whitelistChannelLabel addSubview:whitelistSwitch];
    whitelistSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [whitelistSwitch.leadingAnchor constraintEqualToAnchor:self.whitelistChannelLabel.trailingAnchor constant:-51].active = YES;
    [whitelistSwitch.centerYAnchor constraintEqualToAnchor:self.whitelistChannelLabel.centerYAnchor].active = YES;
    
    if ([kWhitelistedChannels containsObject:self.playerViewController.channelID]) {
        [whitelistSwitch setOn:YES animated:NO];
    } else {
        [whitelistSwitch setOn:NO animated:NO];
    }
    
    YTPlayerView *playerView = (YTPlayerView *)self.playerViewController.view;
    NSArray *skipSegments = [self skipSegments];
    if (skipSegments.count > 0) {
        self.segmentsInDatabaseLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.segmentsInDatabaseLabel.userInteractionEnabled = YES;
        self.segmentsInDatabaseLabel.text = LOC(@"SegmentsInDatabase");
        self.segmentsInDatabaseLabel.numberOfLines = 1;
        self.segmentsInDatabaseLabel.adjustsFontSizeToFitWidth = YES;
        self.segmentsInDatabaseLabel.textAlignment = NSTextAlignmentCenter;
        [playerView addSubview:self.segmentsInDatabaseLabel];
        self.segmentsInDatabaseLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.segmentsInDatabaseLabel.topAnchor constraintEqualToAnchor:self.whitelistChannelLabel.bottomAnchor constant:-15].active = YES;
        [self.segmentsInDatabaseLabel.centerXAnchor constraintEqualToAnchor:playerView.centerXAnchor].active = YES;
        [self.segmentsInDatabaseLabel.widthAnchor constraintEqualToAnchor:playerView.widthAnchor].active = YES;
        [self.segmentsInDatabaseLabel.heightAnchor constraintEqualToConstant:75.0f].active = YES;
        
        self.sponsorSegmentViews = [self segmentViewsForSegments:skipSegments editable:NO];
        
        for (int i = 0; i < self.sponsorSegmentViews.count; i++) {
            [self.segmentsInDatabaseLabel addSubview:self.sponsorSegmentViews[i]];
            // Dodanie gestu zamiast `addInteraction`
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(segmentTapped:)];
            [self.sponsorSegmentViews[i] addGestureRecognizer:tapGesture];
            
            self.sponsorSegmentViews[i].translatesAutoresizingMaskIntoConstraints = NO;
            [self.sponsorSegmentViews[i].widthAnchor constraintEqualToConstant:playerView.frame.size.width / self.sponsorSegmentViews.count - 10].active = YES;
            [self.sponsorSegmentViews[i].heightAnchor constraintEqualToConstant:30].active = YES;
            [self.sponsorSegmentViews[i].topAnchor constraintEqualToAnchor:self.segmentsInDatabaseLabel.bottomAnchor constant:-25].active = YES;
            
            if (self.sponsorSegmentViews.count == 1) {
                [self.sponsorSegmentViews[i].centerXAnchor constraintEqualToAnchor:self.segmentsInDatabaseLabel.centerXAnchor].active = YES;
                break;
            }
            
            if (i > 0) {
                [self.sponsorSegmentViews[i].leftAnchor constraintEqualToAnchor:self.sponsorSegmentViews[i - 1].rightAnchor constant:5].active = YES;
            } else {
                [self.sponsorSegmentViews[i].leftAnchor constraintEqualToAnchor:self.segmentsInDatabaseLabel.leftAnchor constant:5 * (self.sponsorSegmentViews.count / 2)].active = YES;
            }
        }
    }
}

- (void)segmentTapped:(UITapGestureRecognizer *)gesture {
    UIView *segmentView = gesture.view;
    NSLog(@"Segment tapped: %@", segmentView);
}

- (void)whitelistSwitchToggled:(UISwitch *)sender {
    if (sender.isOn) {
        [kWhitelistedChannels addObject:self.playerViewController.channelID];
    }
    else {
        [kWhitelistedChannels removeObject:self.playerViewController.channelID];
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *settingsPath = [documentsDirectory stringByAppendingPathComponent:@"iSponsorBlock.plist"];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:settingsPath]];
    
    [settings setValue:kWhitelistedChannels forKey:@"whitelistedChannels"];
    [settings writeToURL:[NSURL fileURLWithPath:settingsPath isDirectory:NO] error:nil];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.galacticdev.isponsorblockprefs.changed"), NULL, NULL, YES);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.startEndSegmentButton removeFromSuperview];
    [self.segmentsInDatabaseLabel removeFromSuperview];
    [self.userSegmentsLabel removeFromSuperview];
    [self.submitSegmentsButton removeFromSuperview];
    [self.whitelistChannelLabel removeFromSuperview];
    
    [self.previousParentViewController addChildViewController:self.playerViewController];
    [self.previousParentViewController.view addSubview:self.playerViewController.view];
    
    self.overlayView.isDisplayingSponsorBlockViewController = NO;
    self.overlayView.sponsorBlockButton.hidden = NO;
    self.overlayView.sponsorStartedEndedButton.hidden = NO;
    [self.overlayView setOverlayVisible:YES];
}

- (void)startEndSegmentButtonPressed:(UIButton *)sender {
    NSString *segmentStartsNowTitle = LOC(@"SegmentStartsNow");
    NSString *segmentEndsNowTitle = LOC(@"SegmentEndsNow");
    NSString *errorTitle = LOC(@"Error");
    NSString *okTitle = LOC(@"OK");
    NSInteger minutes = lroundf(self.playerViewController.userSkipSegments.lastObject.startTime)/60;
    NSInteger seconds = lroundf(self.playerViewController.userSkipSegments.lastObject.startTime)%60;
    NSString *errorMessage = [NSString stringWithFormat:@"%@ %ld:%02ld", LOC(@"EndTimeLessThanStartTime"), minutes, seconds];

    if ([sender.titleLabel.text isEqualToString:segmentStartsNowTitle]) {
        [self.playerViewController.userSkipSegments addObject:[[SponsorSegment alloc] initWithStartTime:self.playerViewController.currentVideoMediaTime endTime:-1 category:nil UUID:nil]];
        [sender setTitle:segmentEndsNowTitle forState:UIControlStateNormal];
    } else {
        self.playerViewController.userSkipSegments.lastObject.endTime = self.playerViewController.currentVideoMediaTime;
        if (self.playerViewController.userSkipSegments.lastObject.endTime != self.playerViewController.currentVideoMediaTime) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        [sender setTitle:segmentStartsNowTitle forState:UIControlStateNormal];
    }
    [self setupViews];
}

- (void)submitSegmentsButtonPressed:(UIButton *)sender {
    for (SponsorSegment *segment in self.playerViewController.userSkipSegments) {
        if (segment.endTime == -1 || !segment.category) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:LOC(@"Error") message:LOC(@"UnfinishedSegments") preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:LOC(@"OK") style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *settingsPath = [documentsDirectory stringByAppendingPathComponent:@"iSponsorBlock.plist"];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:settingsPath]];

    [SponsorBlockRequest postSponsorTimes:self.playerViewController.currentVideoID sponsorSegments:self.playerViewController.userSkipSegments userID:kUserID withViewController:self.previousParentViewController];
    [self.previousParentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSMutableArray *)segmentViewsForSegments:(NSArray <SponsorSegment *> *)segments editable:(BOOL)editable {
    for (SponsorSegment *segment in segments) {
        if (!editable) {
            [self.sponsorSegmentViews addObject:[[SponsorSegmentView alloc] initWithFrame:CGRectMake(0,0,50,30) sponsorSegment:segment editable:editable]];
        }
        else {
            [self.userSponsorSegmentViews addObject:[[SponsorSegmentView alloc] initWithFrame:CGRectMake(0,0,50,30) sponsorSegment:segment editable:editable]];
        }
    }
    if (!editable) return self.sponsorSegmentViews;
    return self.userSponsorSegmentViews;
}


- (void)handleSegmentAction:(SponsorSegmentView *)sponsorSegmentView {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"iSponsorBlock.plist"];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LOC(@"Edit or Vote")
                                                                         message:nil
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Dodanie opcji kategorii
    NSArray *categories = @[
        @{@"title": LOC(@"Sponsor"), @"category": @"sponsor"},
        @{@"title": LOC(@"Intermission/IntroAnimation"), @"category": @"intro"},
        @{@"title": LOC(@"Outro"), @"category": @"outro"},
        @{@"title": LOC(@"InteractionReminder_Subscribe/Like"), @"category": @"interaction"},
        @{@"title": LOC(@"Unpaid/SelfPromotion"), @"category": @"selfpromo"},
        @{@"title": LOC(@"Non-MusicSection"), @"category": @"music_offtopic"}
    ];
    
    for (NSDictionary *category in categories) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:category[@"title"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (sponsorSegmentView.editable) {
                sponsorSegmentView.sponsorSegment.category = category[@"category"];
                [self setupViews];
            } else {
                [SponsorBlockRequest categoryVoteForSegment:sponsorSegmentView.sponsorSegment
                                                     userID:[settings objectForKey:@"userID"]
                                                   category:category[@"category"]
                                         withViewController:self];
            }
        }]];
    }
    
    // Dodanie opcji edycji (jeśli segment jest edytowalny)
    if (sponsorSegmentView.editable) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:LOC(@"Edit Start Time") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self presentEditTimeAlertForSegment:sponsorSegmentView isStartTime:YES];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:LOC(@"Edit End Time") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self presentEditTimeAlertForSegment:sponsorSegmentView isStartTime:NO];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:LOC(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.playerViewController.userSkipSegments removeObject:sponsorSegmentView.sponsorSegment];
            [self setupViews];
        }]];
    }
    
    // Dodanie opcji głosowania (jeśli segment nie jest edytowalny)
    if (!sponsorSegmentView.editable) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:LOC(@"Upvote") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [SponsorBlockRequest normalVoteForSegment:sponsorSegmentView.sponsorSegment
                                               userID:[settings objectForKey:@"userID"]
                                                 type:YES
                                   withViewController:self];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:LOC(@"Downvote") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [SponsorBlockRequest normalVoteForSegment:sponsorSegmentView.sponsorSegment
                                               userID:[settings objectForKey:@"userID"]
                                                 type:NO
                                   withViewController:self];
        }]];
    }
    
    // Dodanie opcji anulowania
    [actionSheet addAction:[UIAlertAction actionWithTitle:LOC(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    // Wyświetlenie akcji
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)presentEditTimeAlertForSegment:(SponsorSegmentView *)sponsorSegmentView isStartTime:(BOOL)isStartTime {
    NSString *title = isStartTime ? LOC(@"Edit Start Time") : LOC(@"Edit End Time");
    NSString *message = isStartTime ? LOC(@"Enter the new start time (mm:ss)") : LOC(@"Enter the new end time (mm:ss)");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"mm:ss";
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:LOC(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [alert addAction:[UIAlertAction actionWithTitle:LOC(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSArray *timeComponents = [alert.textFields[0].text componentsSeparatedByString:@":"];
        if (timeComponents.count == 2) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            CGFloat minutes = [[formatter numberFromString:timeComponents[0]] floatValue];
            CGFloat seconds = [[formatter numberFromString:timeComponents[1]] floatValue];
            CGFloat newTime = (minutes * 60) + seconds;
            
            if (isStartTime) {
                sponsorSegmentView.sponsorSegment.startTime = newTime;
            } else {
                sponsorSegmentView.sponsorSegment.endTime = newTime;
            }
            [self setupViews];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}
@end
