//
//  Alfred.m
//  WeChatTweak
//
//  Created by Sunnyyoung on 2017/9/10.
//  Copyright © 2017年 Sunnyyoung. All rights reserved.
//

#import "Alfred.h"
#import "WeChatTweak.h"
#import "TKMessageManager.h"

@interface AlfredManager()

@property (nonatomic, strong, nullable) GCDWebServer *server;

@end

@implementation AlfredManager

+ (void)load {
    [AlfredManager.sharedInstance startListener];
}
    
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AlfredManager *shared;
    dispatch_once(&onceToken, ^{
        shared = [[AlfredManager alloc] init];
    });
    return shared;
}

- (void)startListener {
    if (self.server != nil) {
        return;
    }
    self.server = [[GCDWebServer alloc] init];
    // Search contacts
    [self.server addHandlerForMethod:@"GET" path:@"/wechat/search" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        NSString *path = ({
            NSString *path = nil;
            if ([objc_getClass("PathUtility") respondsToSelector:@selector(GetCurUserDocumentPath)]) {
                path = [objc_getClass("PathUtility") GetCurUserDocumentPath];
            } else {
                path = nil;
            }
            path;
        });
        NSString *keyword = [request.query[@"keyword"] lowercaseString] ? : @"";
        
        NSArray<WCContactData *> *contacts = ({
            MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
            ContactStorage *contactStorage = [serviceCenter getService:objc_getClass("ContactStorage")];
            GroupStorage *groupStorage = [serviceCenter getService:objc_getClass("GroupStorage")];
            NSMutableArray<WCContactData *> *array = [NSMutableArray array];
            [array addObjectsFromArray:[contactStorage GetAllFriendContacts]];
            [array addObjectsFromArray:[groupStorage GetGroupContactList:2 ContactType:0]];
            array;
        });
        NSArray<NSDictionary<NSString *, id> *> *items = ({
            NSMutableArray<NSDictionary<NSString *, id> *> *items = NSMutableArray.array;
            for (WCContactData *contact in contacts) {
                NSString *avatar = [NSString stringWithFormat:@"%@/Avatar/%@.jpg", path, [contact.m_nsUsrName md5String]];
                BOOL isOfficialAccount = (contact.m_uiCertificationFlag >> 0x3 & 0x1) == 1;
                BOOL containsNickName = [contact.m_nsNickName.lowercaseString containsString:keyword];
                BOOL containsUsername = [contact.m_nsUsrName.lowercaseString containsString:keyword];
                BOOL containsAliasName = [contact.m_nsAliasName.lowercaseString containsString:keyword];
                BOOL containsRemark = [contact.m_nsRemark.lowercaseString containsString:keyword];
                BOOL containsNickNamePinyin = [contact.m_nsFullPY.lowercaseString containsString:keyword];
                BOOL containsRemarkPinyin = [contact.m_nsRemarkPYFull.lowercaseString containsString:keyword];
                BOOL matchRemarkShortPinyin = [contact.m_nsRemarkPYShort.lowercaseString isEqualToString:keyword];
                if (!isOfficialAccount && (containsNickName || containsUsername || containsAliasName || containsRemark || containsNickNamePinyin || containsRemarkPinyin || matchRemarkShortPinyin)) {
                    [items addObject:@{
                        @"icon": @{
                            @"path": [NSFileManager.defaultManager fileExistsAtPath:avatar] ? avatar : NSNull.null
                        },
                        @"title": ({
                            id value = nil;
                            if (contact.m_nsRemark.length) {
                                value = contact.m_nsRemark;
                            } else if (contact.m_nsNickName.length) {
                                value = contact.m_nsNickName;
                            } else {
                                value = NSNull.null;
                            }
                            value;
                        }),
                        @"subtitle": contact.m_nsNickName.length ? contact.m_nsNickName : NSNull.null,
                        @"arg": contact.m_nsUsrName.length ? contact.m_nsUsrName : NSNull.null,
                        @"valid": @(contact.m_nsUsrName.length > 0)
                    }];
                }
            }
            items;
        });
        return [GCDWebServerDataResponse responseWithJSONObject:@{@"items": items}];
    }];
    [self.server addHandlerForMethod:@"GET" path:@"/wechat/allcontacts" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        
        FFProcessReqsvrZZ *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
            
        NSString *path = ({
            NSString *path = nil;
            if ([objc_getClass("PathUtility") respondsToSelector:@selector(GetCurUserDocumentPath)]) {
                path = [objc_getClass("PathUtility") GetCurUserDocumentPath];
            } else {
                path = nil;
            }
            path;
        });
        
        NSArray<WCContactData *> *contacts = ({
            MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
            ContactStorage *contactStorage = [serviceCenter getService:objc_getClass("ContactStorage")];
            GroupStorage *groupStorage = [serviceCenter getService:objc_getClass("GroupStorage")];
            NSMutableArray<WCContactData *> *array = [NSMutableArray array];
            [array addObjectsFromArray:[contactStorage GetAllFriendContacts]];
            [array addObjectsFromArray:[groupStorage GetGroupContactList:2 ContactType:0]];
            array;
        });

        NSArray<NSDictionary<NSString *, id> *> *items = ({
            NSMutableArray<NSDictionary<NSString *, id> *> *items = NSMutableArray.array;
            for (WCContactData *contact in contacts) {
                NSString *avatar = [NSString stringWithFormat:@"%@/Avatar/%@.jpg", path, [contact.m_nsUsrName md5String]];
                BOOL isOfficialAccount = (contact.m_uiCertificationFlag >> 0x3 & 0x1) == 1;
                if (!isOfficialAccount) {
                    // MessageData msg = [service GetLastMsg:<#(id)#>]
                    [items addObject:@{
                        @"icon": @{
                            @"path": [NSFileManager.defaultManager fileExistsAtPath:avatar] ? avatar : NSNull.null
                        },
                        @"title": ({
                            id value = nil;
                            if (contact.m_nsRemark.length) {
                                value = contact.m_nsRemark;
                            } else if (contact.m_nsNickName.length) {
                                value = contact.m_nsNickName;
                            } else {
                                value = NSNull.null;
                            }
                            value;
                        }),
                        @"subtitle": contact.m_nsNickName.length ? contact.m_nsNickName : NSNull.null,
                        @"arg": contact.m_nsUsrName.length ? contact.m_nsUsrName : NSNull.null,
                        @"valid": @(contact.m_nsUsrName.length > 0),
                        @"lastContact": @(contact.m_nsUsrName.length ? [service GetLastMsgCreateTime:contact.m_nsUsrName] : 0),
                        @"lastLocalId": @(contact.m_nsUsrName.length ? [service GetLastMsgLocalId:contact.m_nsUsrName] : 0),
                        @"unreadCount": @(contact.m_nsUsrName.length ? [service GetUnReadCount:contact.m_nsUsrName] : 0)
                    }];
                }
            }
            items;
        });

        return [GCDWebServerDataResponse responseWithJSONObject:items];
    }];

    // Start session
    [self.server addHandlerForMethod:@"GET" path:@"/wechat/start" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        WCContactData *contact = ({
            NSString *session = request.query[@"session"];
            WCContactData *contact = nil;
            if (session != nil) {
                MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
                if ([session rangeOfString:@"@chatroom"].location == NSNotFound) {
                    ContactStorage *contactStorage = [serviceCenter getService:objc_getClass("ContactStorage")];
                    contact = [contactStorage GetContact:session];
                } else {
                    GroupStorage *groupStorage = [serviceCenter getService:objc_getClass("GroupStorage")];
                    contact = [groupStorage GetGroupContact:session];
                }
            }
            contact;
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [[objc_getClass("WeChat") sharedInstance] startANewChatWithContact:contact];
            [[objc_getClass("WeChat") sharedInstance] showMainWindow];
            [[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
        });
        return [GCDWebServerResponse responseWithStatusCode:200];
    }];
    [self.server addHandlerForMethod:@"GET" path:@"/wechat/chatlog" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        FFProcessReqsvrZZ *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
        char hasMore = '1';
        NSArray *array = @[];
        NSString *userId = request.query ? request.query[@"userId"] ? request.query[@"userId"] : nil : nil;
        NSInteger count = request.query ? request.query[@"count"] ? [request.query[@"count"] integerValue] : 30 : 30;
        
        if ([service respondsToSelector:@selector(GetMsgListWithChatName:fromCreateTime:localId:limitCnt:hasMore:sortAscend:)]) {
            array = [service GetMsgListWithChatName:userId fromCreateTime:0 localId:0 limitCnt:count hasMore:&hasMore sortAscend:YES];
        }
        NSMutableArray<NSDictionary<NSString *, id> *> *chatLogItems = [NSMutableArray array];
                
                for (MessageData *message in array) {
                    NSString *content = message.msgContent;
                    NSString *toUser = message.toUsrName;
                    NSString *fromUser = message.fromUsrName;
                    unsigned int createTime = message.msgCreateTime;
                    BOOL isSentFromSelf = [message isSendFromSelf];
                    
                    // Depending on the message type, we may want to adapt content
                    switch (message.messageType) {
                        // Assuming some enums or constants for MessageDataType
                        // case MessageDataTypeImage:
                        //     content = [message savingImageFileNameWithLocalID];
                        //     break;
                        default:
                            break;
                    }
                    
                    [chatLogItems addObject:@{
                        @"content": content ? content : NSNull.null,
                        @"toUser": toUser ? toUser : NSNull.null,
                        @"fromUser": fromUser ? fromUser : NSNull.null,
                        @"createTime": @(createTime),
                        @"isSentFromSelf": @(isSentFromSelf),
                        @"localId": @(message.mesLocalID), // incremental id of messages for each user
                        @"svrId": @(message.mesSvrID),
                        @"messageType": @(message.messageType)
                        // Add other relevant fields as necessary
                    }];
                }
                return [GCDWebServerDataResponse responseWithJSONObject:@{@"chatLogs": chatLogItems, @"hasMore": @(hasMore == '1')}];
        }];
    [self.server addHandlerForMethod:@"POST" path:@"/wechat/send" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        
        // Extracting parameters from the query.
        NSString *userId = request.query[@"userId"];
        
        // If userId has content.
        if (userId && userId.length > 0) {
            NSString *content = request.query[@"content"];
            
            // Access the message service.
            FFProcessReqsvrZZ *messageService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (content && content.length > 0) {
                    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
                    [messageService FFProcessTReqZZ:currentUserName
                                          toUsrName:userId
                                            msgText:content
                                         atUserList:nil];
                    [[TKMessageManager shareManager] clearUnRead:userId];
                    
                }
            });
            
            return [GCDWebServerDataResponse responseWithJSONObject:@{@"sent": @1}];
        }
        
        return [GCDWebServerResponse responseWithStatusCode:404];
    }];

    [self.server startWithOptions:@{
        GCDWebServerOption_Port: @(48065),
        GCDWebServerOption_BindToLocalhost: @(YES)
    } error:nil];
}

- (void)stopListener {
    if (self.server == nil) {
        return;
    }
    [self.server stop];
    [self.server removeAllHandlers];
    self.server = nil;
}

@end
