import SideMenuSwift

class PMSideMenuController: SideMenuController, SideMenuControllerDelegate {

    var willRevealMenu: (() -> Void)?
    var willHideMenu: (() -> Void)?

    private var isMenuPresented = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        delegate = self
    }

    override var childForStatusBarHidden: UIViewController? {
        isMenuPresented ? menuViewController : contentViewController
    }

    func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = true
        willRevealMenu?()
        setNeedsStatusBarAppearanceUpdate()
    }

    func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = false
        willHideMenu?()
        setNeedsStatusBarAppearanceUpdate()
    }

}
