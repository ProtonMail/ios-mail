import SideMenuSwift

class PMSideMenuController: SideMenuController, SideMenuControllerDelegate {

    var willRevealMenu: (() -> Void)?
    var willHideMenu: (() -> Void)?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        delegate = self
    }

    var isMenuPresented = false

    override var childForStatusBarHidden: UIViewController? {
        isMenuPresented ? menuViewController : contentViewController
    }

    func sideMenuControllerDidRevealMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = true
        setNeedsStatusBarAppearanceUpdate()
    }

    func sideMenuControllerDidHideMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = false
        setNeedsStatusBarAppearanceUpdate()
    }

    func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
        willRevealMenu?()
    }

    func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        willHideMenu?()
    }

}
