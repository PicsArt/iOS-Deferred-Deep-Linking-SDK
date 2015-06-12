//
//  BranchRedeemRewardsRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchRedeemRewardsRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchRedeemRewardsRequestTests : BranchTest

@end

@implementation BranchRedeemRewardsRequestTests

- (void)testRequestBody {
    NSString * const BUCKET = @"foo_bucket";
    NSInteger const AMOUNT = 5;
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_BUCKET: BUCKET,
        BRANCH_REQUEST_KEY_AMOUNT: @(AMOUNT),
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID]
    };
    
    BranchRedeemRewardsRequest *request = [[BranchRedeemRewardsRequest alloc] initWithAmount:AMOUNT bucket:BUCKET callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
    NSInteger const STARTING_AMOUNT = 100;
    NSInteger const REDEEM_AMOUNT = 5;
    NSString * const BUCKET = @"foo_bucket";
    
    [BNCPreferenceHelper setCreditCount:STARTING_AMOUNT forBucket:BUCKET];
    
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Redeem Request Expectation"];
    BranchRedeemRewardsRequest *request = [[BranchRedeemRewardsRequest alloc] initWithAmount:REDEEM_AMOUNT bucket:BUCKET callback:^(BOOL success, NSError *error) {
        XCTAssertTrue(success);
        XCTAssertNil(error);
        
        [self safelyFulfillExpectation:requestExpectation];
    }];
    
    [request processResponse:[[BNCServerResponse alloc] init] error:nil];
    
    [self awaitExpectations];
    XCTAssertEqual([BNCPreferenceHelper getCreditCountForBucket:BUCKET], STARTING_AMOUNT - REDEEM_AMOUNT);
}

- (void)testBasicFailure {
    NSInteger const STARTING_AMOUNT = 100;
    NSInteger const REDEEM_AMOUNT = 5;
    NSString * const BUCKET = @"foo_bucket";
    NSError * REQUEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    [BNCPreferenceHelper setCreditCount:STARTING_AMOUNT forBucket:BUCKET];
    
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"Redeem Request Expectation"];
    BranchRedeemRewardsRequest *request = [[BranchRedeemRewardsRequest alloc] initWithAmount:REDEEM_AMOUNT bucket:BUCKET callback:^(BOOL success, NSError *error) {
        XCTAssertFalse(success);
        XCTAssertNotNil(error);
        
        [self safelyFulfillExpectation:requestExpectation];
    }];
    
    [request processResponse:nil error:REQUEST_ERROR];
    
    [self awaitExpectations];
    XCTAssertEqual([BNCPreferenceHelper getCreditCountForBucket:BUCKET], STARTING_AMOUNT);
}

@end
