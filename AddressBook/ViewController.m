//
//  ViewController.m
//  AddressBook
//
//  Created by shenhongbang on 16/4/1.
//  Copyright © 2016年 shenhongbang. All rights reserved.
//

#import "ViewController.h"
#import <Contacts/Contacts.h>
#import <AddressBook/AddressBook.h>
#import "NSString+Helps.h"

void getDataFromAddressBook(ABAddressBookRef addressBook, void(^complete)(NSDictionary *dic)) {
    NSMutableDictionary *contacts = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    NSArray *array = (__bridge NSArray *)(ABAddressBookCopyArrayOfAllPeople(addressBook));

    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ABRecordRef recordRef = (__bridge ABRecordRef)(obj);
        NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(recordRef, kABPersonFirstNameProperty));
        NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(recordRef, kABPersonLastNameProperty));
        
        NSString *key = firstName.length > 0 && lastName.length > 0 ? [NSString stringWithFormat:@"%@%@", lastName, firstName] : (firstName.length > 0 ? firstName : lastName);
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
        
        firstName.length > 0 ? [dic setObject:firstName forKey:@"firstName"] : nil;
        lastName.length > 0 ? [dic setObject:lastName forKey:@"lastName"] : nil;
        
        
        ABMultiValueRef phoneRef = ABRecordCopyValue(recordRef, kABPersonPhoneProperty);
        //                NSArray *phones = (__bridge NSArray *)(ABMultiValueCopyArrayOfAllValues(phoneRef));
        long count = ABMultiValueGetCount(phoneRef);
        for (long i = 0; i < count; i++) {
            NSString *phone = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(phoneRef, i));
            NSString *phoneKey = [NSString stringWithFormat:@"phone_%ld", i];
            [dic setObject:[phone formatterPhoneNum] forKey:phoneKey];
        }
        
        [contacts setObject:dic forKey:key];
        
    }];
    
    complete(contacts);
}

void logDictionary(NSDictionary *dic) {
    NSLog(@"\n数据:%@\nMD5:%@", dic, [dic.description MD5]);
}
     
void addressBookChanged(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    // 比如上传
    getDataFromAddressBook(addressBook, ^(NSDictionary *dic) {
        logDictionary(dic);
    });
}




@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@end

@implementation ViewController {
    UITableView         *_tableView;
    NSDictionary        *_dataDic;
    NSArray             *_dataArray;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    
    [self getData:^(NSDictionary *dic) {
        
        
        _dataArray = [dic allKeys];
        _dataDic = dic;
        [_tableView reloadData];
        
    }];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        __weak typeof(self) SHB = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:CNContactStoreDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            //通讯录肯定变了
            
            NSDictionary *dic = [SHB iosBiggerThan9_0];
            
            _dataArray = [dic allKeys];
            _dataDic = dic;
            [_tableView reloadData];
        }];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:NSStringFromClass([UITableViewCell class])];
    }
    NSString *key = _dataArray[indexPath.row];
    
    NSDictionary *dic = _dataDic[key];
    cell.textLabel.text = key;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        cell.detailTextLabel.text = dic[@"phone"];
    } else {
        cell.detailTextLabel.text = dic[@"phone_0"];
    }
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataDic.count;
}


- (void)getData:(void(^)(NSDictionary *dic))complete {
    
    
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        NSLog(@"系统大于9.0");
        CNContactStore *store = [[CNContactStore alloc] init];
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        if (status != CNAuthorizationStatusAuthorized) {
            [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                    NSDictionary *dic = [self iosBiggerThan9_0];
                    complete(dic);
                }
            }];
        } else {
            NSDictionary *dic = [self iosBiggerThan9_0];
            complete(dic);
        }
    } else {
        NSLog(@"系统小于9.0");
        [self iosLessThan9_0:^(NSDictionary *contacts) {
            complete(contacts);
        }];
    }
}

- (void)iosLessThan9_0:(void(^)(NSDictionary *contacts))complete {
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRegisterExternalChangeCallback(addressBook, addressBookChanged, (__bridge void *)(self));
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            getDataFromAddressBook(addressBook, ^(NSDictionary *dic) {
                complete(dic);
            });
        } else {
            complete(@{});
        }
    });
}


- (NSDictionary *)iosBiggerThan9_0 {
    NSMutableDictionary *contacts = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    NSError *error = nil;
    
    NSArray <id<CNKeyDescriptor>>*keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactNamePrefixKey, CNContactIdentifierKey, CNContactPhoneNumbersKey];
    
    CNContactStore *store = [[CNContactStore alloc] init];
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
    [store enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        
        NSString *key = [NSString stringWithFormat:@"%@%@", contact.familyName, contact.givenName];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
        [dic setObject:contact.familyName forKey:@"familyName"];
        [dic setObject:contact.givenName forKey:@"givenName"];
        [dic setObject:contact.identifier forKey:@"identifier"];
        
        [contact.phoneNumbers enumerateObjectsUsingBlock:^(CNLabeledValue<CNPhoneNumber *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [dic setObject:[[(CNPhoneNumber *)obj.value stringValue] formatterPhoneNum] forKey:@"phone"];
        }];
        [contacts setObject:dic forKey:key];
    }];
    
    
    return contacts;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
