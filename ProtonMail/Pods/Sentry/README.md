Fork from [getsentry/sentry-cocoa](https://github.com/getsentry/sentry-cocoa)

## How to sync with the original repository   
```
# Track:
git clone git@github.com:xxi511/sentry-cocoa.git
cd myframework
git remote add upstream git@github.com:getsentry/sentry-cocoa.git

# Update:
git fetch upstream
git rebase upstream/master
git push
git push --tags
```    
[ref](https://gist.github.com/Saissaken/b555f2c0772bee56601f70df501b6c96)
