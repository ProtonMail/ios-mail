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
    
    override var childForStatusBarStyle: UIViewController? {
        isMenuPresented ? menuViewController : contentViewController
    }

    func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = true
        willRevealMenu?()
        setNeedsStatusBarAppearanceUpdate()
        sideMenuController.contentViewController.view.accessibilityElementsHidden = true
        sideMenuController.contentViewController.view.isUserInteractionEnabled = false
    }

    func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = false
        willHideMenu?()
        setNeedsStatusBarAppearanceUpdate()
        sideMenuController.contentViewController.view.accessibilityElementsHidden = false
        sideMenuController.contentViewController.view.isUserInteractionEnabled = true
    }
}
