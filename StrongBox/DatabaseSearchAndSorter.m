//
//  DatabaseSearchAndSorter.m
//  Strongbox
//
//  Created by Mark on 21/06/2019.
//  Copyright © 2019 Mark McGuill. All rights reserved.
//

#import "DatabaseSearchAndSorter.h"
#import "SprCompilation.h"
#import "NSMutableArray+Extensions.h"
#import "NSArray+Extensions.h"
#import "Settings.h"
#import "BrowseSortField.h"
#import "Utils.h"

NSString* const kSpecialSearchTermAllEntries = @"strongbox:allEntries";
NSString* const kSpecialSearchTermAuditEntries = @"strongbox:auditEntries";
NSString* const kSpecialSearchTermTotpEntries = @"strongbox:totpEntries";
          
@interface DatabaseSearchAndSorter ()

@property Model* model;

@end

@implementation DatabaseSearchAndSorter

- (instancetype)initWithModel:(Model *)model {
    self = [super init];
    if (self) {
        self.model = model;
    }
    return self;
}

- (NSString*)maybeDeref:(NSString*)text node:(Node*)node maybe:(BOOL)maybe {
    return maybe ? [self dereference:text node:node] : text;
}

- (NSString*)dereference:(NSString*)text node:(Node*)node {
    if(self.model.database.format == kPasswordSafe || !text.length) {
        return text;
    }
    
    NSError* error;
    
    BOOL isCompilable = [SprCompilation.sharedInstance isSprCompilable:text];
    
    NSString* compiled = isCompilable ? [SprCompilation.sharedInstance sprCompile:text node:node rootNode:self.model.database.rootGroup error:&error] : text;
    
    if(error) {
        NSLog(@"WARN: SPR Compilation ERROR: [%@]", error);
    }
    
    return compiled ? compiled : @""; // Never return nil... just not expected at UI layer
}

- (NSArray<Node*>*)search:(NSString *)searchText
                    scope:(SearchScope)scope
              dereference:(BOOL)dereference
    includeKeePass1Backup:(BOOL)includeKeePass1Backup
        includeRecycleBin:(BOOL)includeRecycleBin
           includeExpired:(BOOL)includeExpired
            includeGroups:(BOOL)includeGroups {
    return [self searchNodes:self.model.database.allNodes
                  searchText:searchText
                       scope:scope
                 dereference:dereference
       includeKeePass1Backup:includeKeePass1Backup
           includeRecycleBin:includeRecycleBin
              includeExpired:includeExpired
               includeGroups:includeGroups];
}

- (NSArray<Node*>*)searchNodes:(NSArray<Node*>*)nodes
                    searchText:(NSString *)searchText
                         scope:(SearchScope)scope
                   dereference:(BOOL)dereference
         includeKeePass1Backup:(BOOL)includeKeePass1Backup
             includeRecycleBin:(BOOL)includeRecycleBin
                includeExpired:(BOOL)includeExpired
                 includeGroups:(BOOL)includeGroups {
    NSMutableArray* results = [nodes mutableCopy]; // Mutable for memory/perf reasons
    
    NSArray<NSString*>* terms = [self.model.database getSearchTerms:searchText];
    
    for (NSString* word in terms) {
        [self filterForWord:results
                 searchText:word
                      scope:scope
                dereference:dereference];
    }
    
    return [self filterAndSortForBrowse:results
                  includeKeePass1Backup:includeKeePass1Backup
                      includeRecycleBin:includeRecycleBin
                         includeExpired:includeExpired
                          includeGroups:includeGroups];
}

- (NSArray<Node*>*)filterAndSortForBrowse:(NSMutableArray<Node*>*)nodes
                    includeKeePass1Backup:(BOOL)includeKeePass1Backup
                        includeRecycleBin:(BOOL)includeRecycleBin
                           includeExpired:(BOOL)includeExpired
                            includeGroups:(BOOL)includeGroups {
    [self filterExcluded:nodes
   includeKeePass1Backup:includeKeePass1Backup
       includeRecycleBin:includeRecycleBin
          includeExpired:includeExpired
           includeGroups:includeGroups];
    
    return [self sortItemsForBrowse:nodes];
}

- (void)filterForWord:(NSMutableArray<Node*>*)searchNodes
           searchText:(NSString *)searchText
                scope:(NSInteger)scope
          dereference:(BOOL)dereference {
    if ([searchText isEqualToString:kSpecialSearchTermAllEntries]) { // Special Strongbox Search Operator
        [searchNodes mutableFilter:^BOOL(Node * _Nonnull obj) {
            return !obj.isGroup;
        }];
    }
    else if ([searchText isEqualToString:kSpecialSearchTermAuditEntries]) { // Special Strongbox Search Operator
        [searchNodes mutableFilter:^BOOL(Node * _Nonnull obj) {
            return [self.model isFlaggedByAudit:obj];
        }];
    }
    else if ([searchText isEqualToString:kSpecialSearchTermTotpEntries]) { // Special Strongbox Search Operator
        [searchNodes mutableFilter:^BOOL(Node * _Nonnull obj) {
            return obj.fields.otpToken != nil;
        }];
    }
    else if (scope == kSearchScopeTitle) {
        [self searchTitle:searchNodes searchText:searchText dereference:dereference];
    }
    else if (scope == kSearchScopeUsername) {
        [self searchUsername:searchNodes searchText:searchText dereference:dereference];
    }
    else if (scope == kSearchScopePassword) {
        [self searchPassword:searchNodes searchText:searchText dereference:dereference];
    }
    else if (scope == kSearchScopeUrl) {
        [self searchUrl:searchNodes searchText:searchText dereference:dereference];
    }
    else if (scope == kSearchScopeTags) {
        [self searchTags:searchNodes searchText:searchText];
    }
    else {
        [self searchAllFields:searchNodes searchText:searchText dereference:dereference];
    }
}

- (void)searchTitle:(NSMutableArray<Node*>*)searchNodes searchText:(NSString*)searchText dereference:(BOOL)dereference {
    [searchNodes mutableFilter:^BOOL(Node * _Nonnull node) {
        return [self.model.database isTitleMatches:searchText node:node dereference:dereference];
    }];
}

- (void)searchUsername:(NSMutableArray<Node*>*)searchNodes searchText:(NSString*)searchText dereference:(BOOL)dereference {
    [searchNodes mutableFilter:^BOOL(Node * _Nonnull node) {
        return [self.model.database isUsernameMatches:searchText node:node dereference:dereference];
    }];
}

- (void)searchPassword:(NSMutableArray<Node*>*)searchNodes searchText:(NSString*)searchText dereference:(BOOL)dereference {
    [searchNodes mutableFilter:^BOOL(Node * _Nonnull node) {
        return [self.model.database isPasswordMatches:searchText node:node dereference:dereference];
    }];
}

- (void)searchUrl:(NSMutableArray<Node*>*)searchNodes searchText:(NSString*)searchText dereference:(BOOL)dereference {
    [searchNodes mutableFilter:^BOOL(Node * _Nonnull node) {
        return [self.model.database isUrlMatches:searchText node:node dereference:dereference];
    }];
}

- (void)searchTags:(NSMutableArray<Node*>*)searchNodes searchText:(NSString*)searchText {
    [searchNodes mutableFilter:^BOOL(Node * _Nonnull node) {
        return [self.model.database isTagsMatches:searchText node:node];
    }];
}

- (void)searchAllFields:(NSMutableArray<Node*>*)searchNodes searchText:(NSString*)searchText dereference:(BOOL)dereference {
    [searchNodes mutableFilter:^BOOL(Node * _Nonnull node) {
        return [self.model.database isAllFieldsMatches:searchText node:node dereference:dereference];
    }];
}

- (void)filterExcluded:(NSMutableArray<Node*>*)matches
 includeKeePass1Backup:(BOOL)includeKeePass1Backup
     includeRecycleBin:(BOOL)includeRecycleBin
        includeExpired:(BOOL)includeExpired
         includeGroups:(BOOL)includeGroups {
    if(!includeKeePass1Backup) {
        if (self.model.database.format == kKeePass1) {
            Node* backupGroup = self.model.database.keePass1BackupNode;
            if(backupGroup) {
                [matches mutableFilter:^BOOL(Node * _Nonnull obj) {
                    return (obj != backupGroup && ![backupGroup contains:obj]);
                }];
            }
        }
    }

    Node* recycleBin = self.model.database.recycleBinNode;
    if(!includeRecycleBin && recycleBin) {
        [matches mutableFilter:^BOOL(Node * _Nonnull obj) {
            return obj != recycleBin && ![recycleBin contains:obj];
        }];
    }

    if(!includeExpired) {
        [matches mutableFilter:^BOOL(Node * _Nonnull obj) {
            return !obj.expired;
        }];
    }
    
    if(!includeGroups) {
        [matches mutableFilter:^BOOL(Node * _Nonnull obj) {
            return !obj.isGroup;
        }];
    }
}

- (NSArray<Node*>*)sortItemsForBrowse:(NSArray<Node*>*)items {
    BrowseSortField field = self.model.metadata.browseSortField;
    BOOL descending = self.model.metadata.browseSortOrderDescending;
    BOOL foldersSeparately = self.model.metadata.browseSortFoldersSeparately;
    
    if(field == kBrowseSortFieldEmail && self.model.database.format != kPasswordSafe) {
        field = kBrowseSortFieldTitle;
    }
    else if(field == kBrowseSortFieldNone && self.model.database.format == kPasswordSafe) {
        field = kBrowseSortFieldTitle;
    }
    
    if(field != kBrowseSortFieldNone) {
        return [items sortedArrayWithOptions:NSSortStable
                             usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                                 Node* n1 = (Node*)obj1;
                                 Node* n2 = (Node*)obj2;
                                 
                                 return [self compareNodesForSort:n1 node2:n2 field:field descending:descending foldersSeparately:foldersSeparately];
                             }];
    }
    else {
        return items;
    }
}

- (NSComparisonResult)compareNodesForSort:(Node*)node1
                                    node2:(Node*)node2
                                    field:(BrowseSortField)field
                               descending:(BOOL)descending
                        foldersSeparately:(BOOL)foldersSeparately {
    if(foldersSeparately) {
        if(node1.isGroup && !node2.isGroup) {
            return NSOrderedAscending;
        }
        else if(!node1.isGroup && node2.isGroup) {
            return NSOrderedDescending;
        }
    }
    
    // Groups - Do not compare fields other than title... default sort asc
    
    if(node2.isGroup && node1.isGroup && field != kBrowseSortFieldTitle) {
        return finderStringCompare(node1.title, node2.title);
    }
    
    Node* n1 = descending ? node2 : node1;
    Node* n2 = descending ? node1 : node2;
    
    NSComparisonResult result = NSOrderedSame;
    
    if(field == kBrowseSortFieldTitle) {
        result = finderStringCompare(n1.title, n2.title);
    }
    else if(field == kBrowseSortFieldUsername) {
        result = finderStringCompare(n1.fields.username, n2.fields.username);
    }
    else if(field == kBrowseSortFieldPassword) {
        result = finderStringCompare(n1.fields.password, n2.fields.password);
    }
    else if(field == kBrowseSortFieldUrl) {
        result = finderStringCompare(n1.fields.url, n2.fields.url);
    }
    else if(field == kBrowseSortFieldEmail) {
        result = finderStringCompare(n1.fields.email, n2.fields.email);
    }
    else if(field == kBrowseSortFieldNotes) {
        result = finderStringCompare(n1.fields.notes, n2.fields.notes);
    }
    else if(field == kBrowseSortFieldCreated) {
        result = [n1.fields.created compare:n2.fields.created];
    }
    else if(field == kBrowseSortFieldModified) {
        result = [n1.fields.modified compare:n2.fields.modified];
    }
    
    // Sort by title if tie-break
    
    if(result == NSOrderedSame && field != kBrowseSortFieldTitle) {
        result = finderStringCompare(n1.title, n2.title);
    }
    
    return result;
}

- (NSString*)getBrowseItemSubtitle:(Node*)node {
    switch (self.model.metadata.browseItemSubtitleField) {
        case kBrowseItemSubtitleNoField:
            return @"";
            break;
        case kBrowseItemSubtitleUsername:
            return self.model.metadata.viewDereferencedFields ? [self dereference:node.fields.username node:node] : node.fields.username;
            break;
        case kBrowseItemSubtitlePassword:
            return self.model.metadata.viewDereferencedFields ? [self dereference:node.fields.password node:node] : node.fields.password;
            break;
        case kBrowseItemSubtitleUrl:
            return self.model.metadata.viewDereferencedFields ? [self dereference:node.fields.url node:node] : node.fields.url;
            break;
        case kBrowseItemSubtitleEmail:
            return node.fields.email;
            break;
        case kBrowseItemSubtitleModified:
            return friendlyDateString(node.fields.modified);
            break;
        case kBrowseItemSubtitleCreated:
            return friendlyDateString(node.fields.created);
            break;
        case kBrowseItemSubtitleNotes:
            return self.model.metadata.viewDereferencedFields ? [self dereference:node.fields.notes node:node] : node.fields.notes;
            break;
        case kBrowseItemSubtitleTags:
            return sortedTagsString(node);
            break;
        default:
            return @"";
            break;
    }
}

NSString* sortedTagsString(Node* node) {
    NSArray<NSString*> *sortedTags = [node.fields.tags.allObjects sortedArrayUsingComparator:finderStringComparator];
    return [sortedTags componentsJoinedByString:@", "];
}

@end
