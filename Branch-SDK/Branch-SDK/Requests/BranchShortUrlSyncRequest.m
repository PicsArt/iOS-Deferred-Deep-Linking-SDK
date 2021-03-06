//
//  BranchShortUrlSyncRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/27/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchShortUrlSyncRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"
#import "BranchConstants.h"
#import "BNCConfig.h"

@interface BranchShortUrlSyncRequest ()

@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSString *alias;
@property (assign, nonatomic) BranchLinkType type;
@property (assign, nonatomic) NSInteger matchDuration;
@property (strong, nonatomic) NSString *channel;
@property (strong, nonatomic) NSString *feature;
@property (strong, nonatomic) NSString *stage;
@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) BNCLinkCache *linkCache;
@property (strong, nonatomic) BNCLinkData *linkData;

@end

@implementation BranchShortUrlSyncRequest

- (id)initWithTags:(NSArray *)tags alias:(NSString *)alias type:(BranchLinkType)type matchDuration:(NSInteger)duration channel:(NSString *)channel feature:(NSString *)feature stage:(NSString *)stage params:(NSDictionary *)params linkData:(BNCLinkData *)linkData linkCache:(BNCLinkCache *)linkCache {
    if (self = [super init]) {
        _tags = tags;
        _alias = alias;
        _type = type;
        _matchDuration = duration;
        _channel = channel;
        _feature = feature;
        _stage = stage;
        _params = params;
        _linkCache = linkCache;
        _linkData = linkData;
    }
    
    return self;
}

- (BNCServerResponse *)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:self.linkData.data];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    params[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;

    return [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_GET_SHORT_URL] key:key log:YES];
}

- (NSString *)processResponse:(BNCServerResponse *)response {
    if (![response.statusCode isEqualToNumber:@200]) {
        NSString *failedUrl = nil;
        NSString *userUrl = [BNCPreferenceHelper preferenceHelper].userUrl;
        if (userUrl) {
            failedUrl = [self createLongUrlForUserUrl:userUrl];
        }
        
        return failedUrl;
    }
    
    NSString *url = response.data[BRANCH_RESPONSE_KEY_URL];
    
    // cache the link
    if (url) {
        [self.linkCache setObject:url forKey:self.linkData];
    }
    
    return url;
}

- (NSString *)createLongUrlForUserUrl:(NSString *)userUrl {
    NSMutableString *baseUrl = [[NSMutableString alloc] initWithFormat:@"%@?", userUrl];
    return [BranchShortUrlSyncRequest createLongUrlWithBaseUrl:baseUrl tags:self.tags alias:self.alias type:self.type matchDuration:self.matchDuration channel:self.channel feature:self.feature stage:self.stage params:self.params];
}

+ (NSString *)createLinkFromBranchKey:(NSString *)branchKey tags:(NSArray *)tags alias:(NSString *)alias type:(BranchLinkType)type matchDuration:(NSInteger)duration channel:(NSString *)channel feature:(NSString *)feature stage:(NSString *)stage params:(NSDictionary *)params {
    NSMutableString *baseUrl = [[NSMutableString alloc] initWithFormat:@"%@/a/%@?", BNC_LINK_URL, branchKey];
    return [BranchShortUrlSyncRequest createLongUrlWithBaseUrl:baseUrl tags:tags alias:alias type:type matchDuration:duration channel:channel feature:feature stage:stage params:params];
}

+ (NSString *)createLongUrlWithBaseUrl:(NSMutableString *)baseUrl tags:(NSArray *)tags alias:(NSString *)alias type:(BranchLinkType)type matchDuration:(NSInteger)duration channel:(NSString *)channel feature:(NSString *)feature stage:(NSString *)stage params:(NSDictionary *)params {
    for (NSString *tag in tags) {
        [baseUrl appendFormat:@"tags=%@&", tag];
    }
    
    if ([alias length]) {
        [baseUrl appendFormat:@"alias=%@&", alias];
    }
    
    if ([channel length]) {
        [baseUrl appendFormat:@"channel=%@&", channel];
    }
    
    if ([feature length]) {
        [baseUrl appendFormat:@"feature=%@&", feature];
    }
    
    if ([stage length]) {
        [baseUrl appendFormat:@"stage=%@&", stage];
    }
    
    [baseUrl appendFormat:@"type=%ld&", (long)type];
    [baseUrl appendFormat:@"matchDuration=%ld&", (long)duration];
    
    NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:params];
    NSString *base64EncodedParams = [BNCEncodingUtils base64EncodeData:jsonData];
    [baseUrl appendFormat:@"source=ios&data=%@", base64EncodedParams];
    
    return baseUrl;
}

@end
