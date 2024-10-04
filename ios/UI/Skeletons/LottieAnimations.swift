import Lottie

enum LottieAnimations {
    enum SkeletonBody {
        static let light: LottieAnimation = .named("skeleton_body_light").unsafelyUnwrapped
        static let dark: LottieAnimation = .named("skeleton_body_dark").unsafelyUnwrapped
    }

    enum SkeletonListItem {
        static let light: LottieAnimation = .named("skeleton_list_item_light").unsafelyUnwrapped
        static let dark: LottieAnimation = .named("skeleton_list_item_dark").unsafelyUnwrapped
    }
}
