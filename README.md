Mail iOS App for the Engineering Transformation project
=======================
Copyright (c) 2024 Proton Technologies AG

## Setup instructions
1. Install Xcode (>=15.2)
2. If Git LFS is not installed in your computer run these commands to install it:
	1. `brew install git-lfs`
	2. `git lfs install`
3. Clone the repository
4. Run `./scripts/setup.sh` to generate the xcodeproj file
5. Open `ProtonMail.xcodeproj`
6. Run `git lfs fetch` if you encounter build issues with `proton_mail_uniffi` package