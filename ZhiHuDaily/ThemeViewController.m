//
//  ThemeViewController.m
//  ZhiHuDaily
//
//  Created by 洪鹏宇 on 16/3/5.
//  Copyright © 2016年 洪鹏宇. All rights reserved.
//

#import "ThemeViewController.h"
#import "ThemeViewModel.h"
#import "StoryCellViewModel.h"
#import "TDStoryViewModel.h"
#import "TPStoryViewController.h"

static const CGFloat kMainTableViewRowHeight = 95.f;

@interface ThemeViewController ()<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate>

@property (strong,nonatomic)ThemeViewModel *viewModel;
@property (weak,nonatomic)UIScrollView *scrollView;
@property (weak,nonatomic)UIImageView *imageView;
@property (weak,nonatomic)UITableView *mainTableView;

@end

@implementation ThemeViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.viewModel = [ThemeViewModel new];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self initSubViews];
    [self configAllObservers];
    [self.viewModel getDailyThemesDataWithThemeID:self.themeID];
}

- (void)initSubViews {
    
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back_White"] style:UIBarButtonItemStyleDone target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = leftBtn;
    
    _scrollView = ({
        UIScrollView *view = [UIScrollView new];
        [self.view addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        view;
    });

    _imageView = ({
        UIImageView *view = [UIImageView new];
        view.contentMode = UIViewContentModeScaleAspectFill;
        [self.scrollView addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(kScreenWidth, 184));
            make.top.equalTo(self.scrollView).offset(-60);
            make.left.equalTo(self.scrollView);
        }];
        view;
    });
    
    _mainTableView = ({
        UITableView *view = [UITableView new];
        view.backgroundColor = [UIColor clearColor];
        [self.view addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(64.f);
            make.left.right.bottom.equalTo(self.view);
        }];
        view.delegate = self;
        view.dataSource = self;
        view.rowHeight = kMainTableViewRowHeight;
        [view registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DailyTheme"];
        view;
    });

}

- (void)back:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:18],NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.viewModel numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DailyTheme"];

    StoryCellViewModel *vm = [self.viewModel cellViewModelAtIndexPath:indexPath];
    
    if (vm.displayImage) {
        cell.contentView.layer.contents = (__bridge id _Nullable)(vm.displayImage.CGImage);
    }else{
        if (!tableView.dragging&&!tableView.decelerating) {
            [vm loadDisplayImage];
            cell.contentView.layer.contents = (__bridge id _Nullable)vm.displayImage.CGImage;
            
        }else {
            cell.contentView.layer.contents = (__bridge id _Nullable)(vm.preImage.CGImage);
        }
    }
    cell.contentView.layer.contentsScale = [UIScreen mainScreen].scale;
    
    return cell;
}

- (void)updateContentOfScreenVisibleRows {
    NSArray *indexPaths = [_mainTableView indexPathsForVisibleRows];
    for(NSIndexPath *indexPath in indexPaths){
        UITableViewCell *cell = [_mainTableView cellForRowAtIndexPath:indexPath];
        StoryCellViewModel *vm = [_viewModel cellViewModelAtIndexPath:indexPath];
        if (!vm.displayImage) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [vm loadDisplayImage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.contentView.layer.contents = (__bridge id _Nullable)(vm.displayImage.CGImage);
                });
            });
        }
    }
}

#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self updateContentOfScreenVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateContentOfScreenVisibleRows];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offSetY = scrollView.contentOffset.y;
    if (offSetY <= 0 && offSetY >= -120.f) {
        _scrollView.contentOffset = CGPointMake(0, offSetY/2);
    }else if (offSetY < -120.f ){
        _mainTableView.contentOffset = CGPointMake(0, -120.f);
    }

    if (offSetY + _mainTableView.height + 1.5*kMainTableViewRowHeight > _mainTableView.contentSize.height ) {
        if (!self.viewModel.isLoading) {
           [self.viewModel getMoreDailyThemesData];
        }
    }

}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    StoryCellViewModel *svm = [self.viewModel cellViewModelAtIndexPath:indexPath];
    TDStoryViewModel *tdvm = [[TDStoryViewModel alloc] initWithStoryID:svm.storyID];
    tdvm.allStoriesID = self.viewModel.allStoriesID;
    TPStoryViewController *tpVC = [[TPStoryViewController alloc] initWithViewModel:tdvm];
    [self.navigationController pushViewController:tpVC animated:YES];
}


- (void)configAllObservers {
    [self.viewModel addObserver:self forKeyPath:@"sectionViewModels" options:NSKeyValueObservingOptionNew context:nil];
    RAC(self,title) = RACObserve(self.viewModel, name);
    [RACObserve(self.viewModel, imageURLStr) subscribeNext:^(id x) {
        self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:x]]];
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainScrollViewToTop:) name:@"TapStatusBar" object:nil];
}

- (void)mainScrollViewToTop:(NSNotification *)noti {
    [_mainTableView setContentOffset:CGPointZero animated:YES];
}

- (void)removeAllObservers {
    [self.viewModel removeObserver:self forKeyPath:@"sectionViewModels"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"sectionViewModels"]) {
        [_mainTableView insertSections:[NSIndexSet indexSetWithIndex:self.viewModel.sectionViewModels.count-1] withRowAnimation:UITableViewRowAnimationNone];
    }

}

- (void)dealloc {
    [self removeAllObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
