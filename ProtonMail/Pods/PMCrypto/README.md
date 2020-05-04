# PMCrypto

This repo is a wrapper around Crypto.framework to allow its usage as cocoapod.
The framework itself is automatically generated from Go code, do not edit it.

In order to update framework:
1. drop-in a new build of Crypto.framework into the repo
2. update version in `PMCrypto.podspec` so all the dependant pods will know they need to re-fetch it