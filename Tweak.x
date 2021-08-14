#include <UIKit/UIKit.h>

@interface UIContextMenuConfiguration (Private)
@property (nonatomic, copy) UIContextMenuActionProvider actionProvider;
@end

@interface CKNavbarCanvasViewController : UIViewController
-(UILabel*)defaultLabel;
@end

@interface CKConversation : NSObject
-(NSString*)displayName;
-(NSString*)name;
-(NSString*)uniqueIdentifier;
-(NSString*)msgrenameNewDisplayName;
@end

@interface CKConversationListCollectionViewController : UICollectionViewController
-(CKConversation*)conversationAtIndexPath:(NSIndexPath*)path;
@end

%hook CKConversation

%new
-(NSString*)msgrenameNewDisplayName {
    NSDictionary* mapping = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"us.sunflsks.msgrename/Mapping"];
    NSString* uniqueID = [self uniqueIdentifier];
    if (mapping[uniqueID]) {
        return mapping[uniqueID];
    }

    return nil;
}

-(BOOL)hasDisplayName {
    if ([self msgrenameNewDisplayName]) {
        return YES;
    }

    return %orig();
}

-(NSString*)displayName {
    if ([self msgrenameNewDisplayName]) {
        return [self msgrenameNewDisplayName];
    }

    return %orig();
}

%end

%hook CKConversationListCollectionViewController

-(UIContextMenuConfiguration*)collectionView:(UICollectionView*)view contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    UIContextMenuConfiguration* config = %orig();
    UIContextMenuActionProvider originalBlock = config.actionProvider;

    config.actionProvider = ^UIMenu*(NSArray<UIMenuElement*>* actions) { 
        UIMenu* actionMenu = originalBlock(actions);
        NSMutableArray* children = [NSMutableArray arrayWithArray:actionMenu.children];

        UIAction* renameAction = [UIAction actionWithTitle:@"Change Display Name" image:nil identifier:nil handler:^(UIAction* action) {
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"New Display Name" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addTextFieldWithConfigurationHandler:nil];

            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* alertAction){
                CKConversation* conversation = [self conversationAtIndexPath:indexPath];
                NSMutableDictionary* renameDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"us.sunflsks.msgrename/Mapping"]];
                UITextField* textField = alertController.textFields[0];
                renameDict[[conversation uniqueIdentifier]] = textField.text;
                [[NSUserDefaults standardUserDefaults] setObject:renameDict forKey:@"us.sunflsks.msgrename/Mapping"];
                [self.collectionView reloadData];
            }]];

            [self presentViewController:alertController animated:YES completion:nil];
        }];

        UIAction* clearAction = [UIAction actionWithTitle:@"Reset Display Name" image:nil identifier:nil handler:^(UIAction* action) {
            CKConversation* conversation = [self conversationAtIndexPath:indexPath];
            NSMutableDictionary* renameDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"us.sunflsks.msgrename/Mapping"]];
            [renameDict removeObjectForKey:[conversation uniqueIdentifier]];
            [[NSUserDefaults standardUserDefaults] setObject:renameDict forKey:@"us.sunflsks.msgrename/Mapping"];
            [self.collectionView reloadData];
        }];

        [children addObjectsFromArray:@[renameAction, clearAction]];
        return [actionMenu menuByReplacingChildren:children];
    };

    return config;
}

%end


