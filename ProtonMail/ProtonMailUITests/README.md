#  ProtonMail UI tests


### UI tests structure:

UI tests code is divided into three main packages: 
1. **Robots** group - contains ***Robot*** classes where each ***Robot*** represents a single application screen, i.e. ***Compose new email***. All pop-up modals that are triggered from this functionality belong to the same ***Robot*** and represented by inner classes within one ***Robot*** class, i.e. ***Set email password modal***. If an action triggers new Window/Screen then it is considered as new ***Robot***. 
2. **Tests** group - contains test classes split by application functionality, i.e. ***login*** or ***settings***. Also it contains **TestPlans** and test script that is used to populate test users before tests run on CI.
3. **Utils** group - contains test data and helper classes.

### Test user ***credentials.plist*** file:

In order to run UI tests the credentials.plist file must be populated with 4 test user and 4 test receipients credentials as below:

*Key: TEST_USER1, Value: email,password,mailbox_password,one_time_password_key*<br>
*Key: TEST_USER2, Value: email,password,mailbox_password,one_time_password_key*<br>
*Key: TEST_USER3, Value: email,password,mailbox_password,one_time_password_key*<br>
*Key: TEST_USER4, Value: email,password,mailbox_password,one_time_password_key*<br>
*Key: TEST_RECIPIENT1, Value: email,password,mailbox_password,one_time_password_key*<br>
*Key: TEST_RECIPIENT2, Value: email,password,mailbox_password,one_time_password_key*<br>
*Key: TEST_RECIPIENT3, Value: email,password,mailbox_password,one_time_password_key*<br>
*Key: TEST_RECIPIENT4, Value: email,password,mailbox_password,one_time_password_key*<br>

In case user doesn't have some fields like: *one_time_password_key*, an emty or stub string must be provided.

The complete filled in ***credentials.plist*** file can be downloaded from ***test/credentials*** branch.

### Test plans:

For now there is only one test plan ***SmokeTests.xctesplan*** that is used for running smoke tests on CI for each merge request.
