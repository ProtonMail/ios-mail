# Events Loop

## General

The events periodic scheduler is a component responsible for periodical polling BE event loops for new events and reacting to those changes by updating the local cache (this should be done on the client side). Goal is to have local cache up to date or destroy it in case it is too outdated. Each Proton client requires the events periodic scheduler, but supported event loops and kinds of cached data are different: Calendar and Drive have their specific per-calendar and per-share loops, while general loop responsible for user events is used by all clients.

## SPM (Example integration)

### SPM package integration

1. Open "Add Package..." in Xcode.
2. Enter SSH url "git@gitlab.protontech.ch:apple/inbox/shared/protoncore-eventsloop.git" into the package repository URL field.

### CI/CD private SPM package integration

1. Add access token of the private repo (Events Loop) to your project CI/CD varaibles (EVENTS_LOOP_REPO_ACCESS_TOKEN).
2. On CI/CD machine we'd like to clone the repo using the Access Token. To achieve that replacing SSH url with HTTPS one is required. Modify your `.gitlab-ci.yml` file by adding 2 methods. The first method override the way how git clones repositories and the second cleans the changes made in the `.gitconfig` file by the first method.

```yaml
.set_up_events_loop_repo_url: &set_up_events_loop_repo_url
  - 'git config --global url.$CI_SERVER_PROTOCOL://gitlab-ci-token:$EVENTS_LOOP_REPO_ACCESS_TOKEN@$CI_SERVER_HOST/apple/inbox/shared/protoncore-eventsloop.git.insteadOf git@$CI_SERVER_HOST:apple/inbox/shared/protoncore-eventsloop.git'

```

```yaml
.unset_events_loop_repo_url: &unset_events_loop_repo_url
  - 'git config --global --unset url.$CI_SERVER_PROTOCOL://gitlab-ci-token:$EVENTS_LOOP_REPO_ACCESS_TOKEN@$CI_SERVER_HOST/apple/inbox/shared/protoncore-eventsloop.git.insteadOf'
```

3. Call method `set_up_events_loop_repo_url` in `before_script` and `unset_events_loop_repo_url` in `after_script` in each stage that builds a project.

## Components

### EventsPeriodicScheduler

Responsibility: manage cycle of poll-BE-and-update-cache operations of multiple EventLoops.
Holds collection of EventLoops (both core and specific ones) and asks them to schedule their operations on a serial operation queue. Timer can do this periodically, but it should schedule only when queue is empty to prevent overfilling it when cycle takes longer than timer's interval. Scheduling should happen for all loops at once to prevent situation when some loops are updated more often than others.

Client is responsible for enabling and disabling specialized loops: for example, when new Calendar or Share appears in local storage. Even though creation of new Calendars and Shares is communicated by BE though Core loop, data flow should go through local storage.

Client is responsible for starting and stopping the events periodic scheduler at appropriate point of app lifecycle (launch, backgrounding, etc) or user session status (switch user in multiuser apps like ProtonMail, login, logout).

### EventsLoop (protocol)

Responsibility: poll concrete networking endpoint using API service and parse response, apply response to local storage using one or more adapters.

Even though it may seem that polling and processing in one object breaks SRP, the integral part here is the response - concrete EventsLoop knows how to parse service response into it and how to apply parsed information to local storage (via nested adapters). Separating polling and processing makes code unnecessarily generic and hard to reason about.

Since all operations have similar flow regardless of concrete endpoint and response, code responsible for the flow can be abstracted in EventsLoop protocol extension. Following stages are important:
- take last known event ID from local storage, at the time of operation execution (not scheduling!)
- poll BE for events since that ID, parsing into ModelEventXxx models happens as part of this step
- check .refresh flag in response:
	- true: that local cache is too outdated to be updated by events and needs to be removed and fetches from scratch
	- false: we can process the page and apply it to local storage
- try processing the response (throw in case of errors - this means either problems in local storage or incompatibility between event and cached state)
- update last known event ID to one mentioned in the page
- check .more flag in response:
	- true: schedule additional operation for updating this loop again (before EventsPeriodicScheduler asks to)
	- false: update of this loop is complete
- operation is complete


Concrete implementation of EventsLoop requires following:
- `loopID` - identifier of the loop (can be CalendarID or ShareID);
- `latestEventID` - latest event identifier of the event loop (one per loop, can be stored in UserDefaults);
- `func poll(...)` - makes API call and parses response into events page model;
- `func process(...)` - accepts events page model, cache models into a local storage;
- `func onError(...)` - handles all errors that might occur during a loop execution (e.g when cache is outdated);

### CoreLoop (protocol)

Extended version of the EventsLoop protocol designed to be used with Core loop. It provides additional delegate property to optionaly set up CoreLoopDelegate

### CoreLoopDelegate (protocol)

Provides a method that can be used to disable a special loop with a given loop ID

---

Documentation based on the Confluence page: https://confluence.protontech.ch/display/CALENDAR/Proposal%3A+Events+Manager+Component
