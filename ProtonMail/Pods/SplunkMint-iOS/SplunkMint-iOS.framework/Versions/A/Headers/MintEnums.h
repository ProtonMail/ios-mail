//
//  SplunkEnums.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

typedef enum
    {
    PLCrashManager
    } CrashManagerType;

/**
 *  Enumeration values that indicate the state of a request upon completion.
 */
typedef enum
    {
    /**
     *  The request succeeded.
     */
    OKResultState = 0,
    
    /**
     *  The request threw an error.
     */
    ErrorResultState,
    
    /**
     *  The request state is undefined.
     */
    UndefinedResultState
    } MintResultState;

/**
 *  Enumeration values that indicate the request type.
 */
typedef enum
    {
    /**
     *  The request is an error.
     */
    ErrorRequestType = 0,
    
    /**
     *  The request is an event.
     */
    EventRequestType,
    
    /**
     *  The request contains a batch of multiple types.
     */
    BothRequestType
    } MintRequestType;

/**
 *  Enumeration values that indicate the type of logged request.
 */
typedef enum
    {
    /**
     *  The logged request is an exception.
     */
    LoggedException = 0,
    
    /**
     *  The logged request is an event.
     */
    EventLogType
    } MintLogType;

typedef enum
    {
    OffDeviceConnectionState = 0,
    OnDeviceConnectionState = 1,
    NADeviceConnectionState = 2
    } DeviceConnectionState;

typedef enum
    {
    UnhandledExceptionFileNameType = 0,
    LoggedExceptionFileNameType,
    PingFileNameType,
    GnipFileNameType,
    EventFileNameType,
    TransactionStartFileNameType,
    TransactionStopFileNameType,
    NetworkFileNameType,
    PerformanceFileNameType,
    ScreenFileNameType,
    TransactionListFileNameType
    } FileNameType;

typedef enum
    {
    error = 0,
    event,
    ping,
    gnip,
    trstart,
    trstop,
    network,
    performance,
    screen
    } DataType;

/**
 *  Enumeration values that indicate the transaction status.
 */
typedef enum
    {
    /**
     *  The transaction started successfully.
     */
    SuccessfullyStartedTransaction = 0,
    
    /**
     *  The transaction was cancelled by the user.
     */
    UserCancelledTransaction,
    
    /**
     *  The transaction was stopped successfully by the user.
     */
    UserSuccessfullyStoppedTransaction,
    
    /**
     *  The transaction request failed.
     */
    FailedTransaction,
    
    /**
     *  The specified transaction you are trying to start exists.
     */
    ExistsTransaction,
    
    /**
     *  The specified transaction you are trying to stop or cancel does not exist.
     */
    NotFoundTransaction
    } TransactionStatus;

typedef enum
    {
    Wifi = 0,
    _3G,
    _2G,
    NONE,
    NA
    } ConnectionType;

/**
 *  Enumeration values that indicate the log level of the log event.
 */
typedef enum
    {
    /**
     *  The lowest priority, and normally not logged except for messages from the kernel.
     */
    DebugLogLevel = 20,
    
    /**
     *  The lowest priority that you would normally log, and purely informational in nature.
     */
    InfoLogLevel = 30,
    
    /**
     *  Things of moderate interest to the user or administrator.
     */
    NoticeLogLevel = 40,
    
    /**
     *  Something is amiss and might fail if not corrected.
     */
    WarningLogLevel = 50,
    
    /**
     *  Something has failed.
     */
    ErrorLogLevel = 60,
    
    /**
     *  A failure in a key system.
     */
    CriticalLogLevel = 70,
    
    /**
     *  A serious failure in a key system.
     */
    AlertLogLevel = 80,
    
    /**
     *  The highest priority, usually reserved for catastrophic failures and reboot notices.
     */
    EmergencyLogLevel = 90
    } MintLogLevel;