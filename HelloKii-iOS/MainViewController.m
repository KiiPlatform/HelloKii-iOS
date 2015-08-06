//
//
// Copyright 2015 Kii Corporation
// http://kii.com
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//

#import <KiiSDK/Kii.h>
#import "MainViewController.h"
#import "UIViewController+Alert.h"

@interface MainViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// define the loaded KiiObject
@property NSMutableArray *objectList;

// define the object count
// used to easily see object names incrementing
@property int createdObjectCount;
@end

@implementation MainViewController
NSString * const BUCKET_NAME = @"myBucket";
NSString * const OBJECT_KEY = @"myObjectValue";

- (void)viewDidLoad {
    [super viewDidLoad];

    // initialize the view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    // initialize the data
    self.objectList = [NSMutableArray array];
    self.createdObjectCount = 0;
}

- (void)viewDidLayoutSubviews {
    // add "+" button to the navigation bar
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addItem:)];
    self.navigationItem.rightBarButtonItem = addButton;

    // initialize the activity indicator to display on the top of the screen
    self.activityIndicator.layer.zPosition = 1;
}

- (void)viewDidAppear:(BOOL)animated {
    // show the activity indicator
    [self.activityIndicator startAnimating];

    // create an empty KiiQuery (will retrieve all results, sorted by creation date)
    KiiQuery *allQuery = [KiiQuery queryWithClause:nil];
    [allQuery sortByDesc:@"_created"];

    // define the bucket to query
    KiiBucket *bucket = [[KiiUser currentUser] bucketWithName:BUCKET_NAME];

    // perform the query
    [bucket executeQuery:allQuery withBlock:^(KiiQuery *query, KiiBucket *bucket, NSArray *results, KiiQuery *nextQuery, NSError *error) {
        // hide the activity indicator(configured "Hides When Stopped" in storyboard)
        [self.activityIndicator stopAnimating];

        // check for an error(successful request if error==nil)
        if (error != nil) {
            [self showMessage:@"Query failed: %@", error.userInfo[@"description"]];
            return;
        }

        // add the objects to the objectList and display them
        [self.objectList addObjectsFromArray:results];
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // return the number of rows in the section.
    return _objectList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // initialize a cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }

    // fill the field from object array
    KiiObject* obj = _objectList[indexPath.row];
    cell.textLabel.text = [obj getObjectForKey:OBJECT_KEY];
    cell.detailTextLabel.text = obj.objectURI;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // show the alert dialog
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Would you like to remove this item?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"No"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Yes"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        // perform the delete action on the tapped object
        [self performDelete:indexPath.row];
    }]];
    [self presentViewController:alert
                       animated:YES
                     completion:nil];
}

#pragma mark - Data operation

- (void)addItem:(id)sender
{
    // show the activity indicator
    [self.activityIndicator startAnimating];

    // create a new KiiObject in the bucket
    KiiBucket *bucket = [[KiiUser currentUser] bucketWithName:BUCKET_NAME];
    KiiObject *object = [bucket createObject];

    // set a key/value
    // the value of OBJECT_KEY field is an incremented title
    NSString *value = [NSString stringWithFormat:@"MyObject %d", ++_createdObjectCount];
    [object setObject:value forKey:OBJECT_KEY];

    // save the object asynchronoously
    [object save:YES withBlock:^(KiiObject *object, NSError *error) {
        // hide the activity indicator(configured "Hides When Stopped" in storyboard)
        [self.activityIndicator stopAnimating];

        // check for an error(successful request if error==nil)
        if (error != nil) {
            [self showMessage:@"Save failed: %@", error.userInfo[@"description"]];
            return;
        }

        // insert the object into the beginning of the objectList and display them
        [self.objectList insertObject:object atIndex:0];
        [self.tableView reloadData];
    }];
}

- (void)performDelete:(long) row {
    // show the activity indicator
    [self.activityIndicator startAnimating];

    // get the object to delete based on the index of the row that was tapped
    KiiObject *obj = _objectList[row];

    // delete the object synchronously
    [obj deleteWithBlock:^(KiiObject *object, NSError *error) {
        // hide the activity indicator(configured "Hides When Stopped" in storyboard)
        [self.activityIndicator stopAnimating];

        // check for an error(successful request if error==nil)
        if (error != nil) {
            [self showMessage:@"Delete failed: %@", error.userInfo[@"description"]];
            return;
        }

        // insert the object into the beginning of the objectList and display them
        // if the user click the same row twice while sending the request, no data would remove from objectList
        [self.objectList removeObject:obj];
        [self.tableView reloadData];
    }];
}

@end
