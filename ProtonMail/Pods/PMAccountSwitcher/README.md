# PMAccountSwitcher

The module to show signed in / signed out account list and send action message to the host app  
The host app needs to handle the account switch / sign in / sign out action

## install

Add the following lines to your podfile

```
pod 'PMAccountSwitcher', :git => 'git@gitlab.protontech.ch:apple/shared/pmaccountswitcher.git', :branch => 'master'
pod 'PMUIFoundations', :git => 'git@gitlab.protontech.ch:apple/shared/PMUIFoundations.git', :branch => 'master'
pod 'PMCoreTranslation', :git => 'git@gitlab.protontech.ch:apple/shared/PMCoreTranslation.git', :branch => 'develop'
```

## Usage

Different app could hold user data in different way, so this module use `AccountSwitcher.AccountData` to display

### Basic usage

```swift
// Transfer your user data to AccountSwitcher.AccountData
var list: [AccountSwitcher.AccountData] = [
    .init(userID: "userID_a", name: "User a", mail: "user_a@pm.me", isSignin: true, unread: 100),
    .init(userID: "userID_b", name: "User b with a super long name", mail: "user_b_with_super_long_address@pm.me", isSignin: false, unread: 0),
    .init(userID: "userID_c", name: "User c", mail: "user_c@protonmail.com", isSignin: true, unread: 1000)
]

// Initialize the switcher instance then present it
@IBAction func clickBtn(_ sender: UIButton) {
    let switcher = try! AccountSwitcher(accounts: self.list, sourceView: sender)
    switcher.present(on: self, delegate: self)
}
```

#### Delegate

```swift
extension ViewController: AccountSwitchDelegate {
    func switchTo(userID: String) {
        print("Want to switch to \(userID)")
    }

    func signinAccount(for mail: String, userID: String?) {
        if mail == "" {
            print("Show signin view")
        } else {
            print("Show signin view for \(mail)")
        }
    }

    func signoutAccount(userID: String, viewModel: AccountManagerVMDataSource) {
        let newList = doSignoutThings()
        // provide new list to update UI
        viewModel.updateAccountList(list: newList)
    }

    func removeAccount(userID: String, viewModel: AccountManagerVMDataSource) {
        let newList = doRemoveThings()
        // provide new list to update UI
        viewModel.updateAccountList(list: newList)
    }
}
```

### Account manager

If you need to show Account manager view without through Account switcher

```swift
let vc = AccountManagerVC.instance()
let vm = AccountManagerViewModel(accounts: self.list,
                                    uiDelegate: vc)
vm.set(delegate: self)
guard let nav = vc.navigationController else {return}
self.present(nav, animated: true, completion: nil)
```

## Development

### Dependencies

- [PMUIFoundations](https://gitlab.protontech.ch/apple/shared/PMUIFoundations)
- [PMCoreTranslation](https://gitlab.protontech.ch/apple/shared/pmcoretranslation)

### Lint

```
$ cd Pods/SwiftLint/
$  ./swiftlint autocorrect ../
```
