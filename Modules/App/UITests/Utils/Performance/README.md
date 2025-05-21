## Client performance measurement SDK

Allows you to collect different client metrics during test run and push them to Loki. Anything can be measured - either it unit, integration or e2e test.

Usage:
- `import ProtonCoreTestingToolkitPerformance`

In order to use the library you have to set up the following environment variables either on CI or locally or set in info.plist or in test configuration file:
1. `LOKI_ENDPOINT` - loki endpoint accessible outside of Dev VPN.
2. `CERTIFICATE_IOS_SDK_PASSPHRASE` - loki private key issues for your team.
3. `CERTIFICATE_IOS_SDK` - loki certificate issues for your team.

The main SDK building blocks are:
- [MeasurementContext](MeasurementContext.swift) - the main measurement entry point which allows you to set [MeasurementConfig](MeasurementConfig.swift) and initialises [MeasurementProfile](MeasurementProfile.swift) after setting the workflow. There can be only one instance of [MeasurementContext](MeasurementContext.swift) per the whole test run.
- [MeasurementProfile](MeasurementProfile.swift) - represents a shared set of labels, metadata and metrics which can be measured during the test run. There can be multiple profiles per test run. Each profile can be extended with [CustomMeasurement](measurement/CustomMeasurement.swift) hooks to register your own measurement per [MeasureBlock](MeasureBlock.swift). [MeasurementProfile](MeasurementProfile.swift) keeps a list of measure blocks in order to push their metrics to Loki after each test run.
- [MeasureBlock](MeasureBlock.swift) - represents a single measure block where logs and majority of metrics will be collected. It has `addMetric()` interface to add custom metrics by implementing [CustomMeasurement](measurement/CustomMeasurement.swift).
- [MeasurementConfig](MeasurementConfig.swift) - keeps configuration values to configure [LokiApiClient](client/LokiApiClient.swift) as well as setters and getters for `buildCommitShortSha` (GitLab "CI_COMMIT_SHA"), `environment` (test environment name) and `runId` (GitLab "CI_JOB_ID").
- [Measurement](measurement/Measurement.swift) - allows to register your own custom measurement. See usage example in class. Examples of [Measurement](measurement/Measurement.kt) are: [AppSizeMeasurement](measurement/AppSizeMeasurement.swift) and [DurationMeasurement](measurement/DurationMeasurement.swift).

Usage examples:

1. First you need to set the configuration in base test class or in `setUp` function:
```swift

class MainMeasurementTests: ProtonCoreBaseTestCase {

    private lazy var measurementContext = MeasurementContext(MeasurementConfig.self)
    
    override class func setUp() {
        super.setUp()
        MeasurementConfig
            .setBundle(Bundle(identifier: "ch.protonmail.configurator.ios")!)
            .setLokiEndpoint(ProcessInfo.processInfo.environment["LOKI_ENDPOINT"] ?? "invalid")
            .setEnvironment("production")
            .setLokiCertificate("certificate_ios_sdk")
            .setLokiCertificatePassphrase(ProcessInfo.processInfo.environment["CERTIFICATE_IOS_SDK_PASSPHRASE"] ?? "invalid")
    }
 
    func testMeasurement1() async {
        let measurementProfile = measurementContext.setWorkflow("test_iOS", forTest: self.name)

        measurementProfile
            .addMeasurement(DurationMeasurement())
            .setServiceLevelIndicator("measurement_1")

        // Measure the duration
        measurementProfile.measure {
            sleep(1)
        }

        XCTFail("Login testMeasurement1 should fail")
    }

    func testMeasurement2() async {
        let measurementProfile = measurementContext.setWorkflow("test_iOS", forTest: self.name)

        measurementProfile
            .addMeasurement(AppSizeMeasurement(bundle: Bundle(identifier: "ch.protonmail.configurator.ios")!))
            .setServiceLevelIndicator("measurement_2")

        // Measure the app size
        measurementProfile.measure {
            sleep(1)
        }
    }

    func testMeasurement3() async {
        let measurementProfile = measurementContext.setWorkflow("test_iOS", forTest: self.name)

        measurementProfile
            .addMeasurement(DurationMeasurement())
            .setServiceLevelIndicator("measurement_3")

        // Measure the duration
        measurementProfile.measure {
            XCTFail("Login testMeasurement3 should fail")
            sleep(1)
        }
    }
```

    JSON payload example for 1 measurement:

```json
    {
        "streams":[
            {
                "stream":{
                    "product":"ch.protonmail.configurator.ios",
                    "sli":"measurement_2",
                    "platform":"iOS",
                    "workflow":"test_iOS",
                    "os_version":"iOS 17.4",
                    "device_model":"iPhone"
                },
                "values":[
                    [
                    "1719402402446641920",
                    "{\"app_size\":\"33.83\",\"status\":\"succeeded\"}",
                    {
                        "ci_job_id":"",
                        "id":"BEAF246F-EC37-4BAB-AAB8-919AB1E7D7F4",
                        "test":"MainMeasurementTests_testMeasurement2",
                        "build_commit_sha1":"",
                        "environment":"production",
                        "app_version":"1.0"
                    }
                    ]
                ]
            }
        ]
    }
```

