//
//  LoginViewController.m
//  HelloKii
//
//  Created by Chris Beauchamp on 9/10/12.
//  Copyright (c) 2012 Kii. All rights reserved.
//

#import "LoginViewController.h"

@implementation LoginViewController

// synth our UI elements
@synthesize usernameField, passwordField;

#pragma mark Kii delegate callbacks
- (void) userAuthenticated:(KiiUser*)user
                 withError:(NSError*)error {

    [CBLoader hideLoader];

    NSLog(@"Authenticated user: %@ withError: %@", user, error);

    // authentication was successful
    if(error == nil) {
        [self dismissModalViewControllerAnimated:TRUE];
    }
    
    // authentication failed
    else {
        
        // tell the user
        [CBToast showToast:@"Authentication Failed" withDuration:CB_TOAST_SHORT];
        
        // tell the console
        CBLog(@"Error creating object: %@", error.description);
    }

}

- (void) userRegistered:(KiiUser*)user
              withError:(NSError*)error {

    [CBLoader hideLoader];

    NSLog(@"Registered user: %@ withError: %@", user, error);
    
    // registration was successful
    if(error == nil) {
        [self dismissModalViewControllerAnimated:TRUE];
    }
    
    // registration failed
    else {
        
        // tell the user
        [CBToast showToast:@"Registration Failed" withDuration:CB_TOAST_SHORT];
        
        // tell the console
        CBLog(@"Error creating object: %@", error.description);
    }
    
}

#pragma mark IBActions

// the user clicked the Log In button
- (IBAction)logInUser:(id)sender {
    
    // Get the user identifier/password from the UI
    NSString *userIdentifier = [usernameField text];
    NSString *password = [passwordField text];
    
    // print to log
    NSLog(@"Attempting login: %@:%@", userIdentifier, password);
    
    // show a loading screen to the user
    [CBLoader showLoader:@"Authenticating user..."];
    
    // perform the asynchronous authentication
    [KiiUser authenticate:userIdentifier
             withPassword:password
              andDelegate:self
              andCallback:@selector(userAuthenticated:withError:)];

}

// the user clicked the Register button
- (IBAction)registerUser:(id)sender {
    
    // Get the user identifier/password from the UI
    NSString *userIdentifier = [usernameField text];
    NSString *password = [passwordField text];
    
    // print to log
    NSLog(@"Attempting registration: %@:%@", userIdentifier, password);
    
    // show a loading screen to the user
    [CBLoader showLoader:@"Registering user..."];

    // create the KiiUser object
    KiiUser *user = [KiiUser userWithUsername:userIdentifier
                                  andPassword:password];
    
    // perform the registration asynchronously
    [user performRegistration:self
                 withCallback:@selector(userRegistered:withError:)];
    
}

@end