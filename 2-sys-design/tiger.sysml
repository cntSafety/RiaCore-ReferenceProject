package TigerDetectionSystemExample {
    private import ScalarValues::*;

    doc /*
        Monitored RGB + LWIR + lidar reference architecture. Sensor hardware
        supplies measurements and available device diagnostics; channel-quality
        and blockage estimation are host software functions, not guaranteed
        embedded camera features. Fusion aligns data and produces unclassified
        hypotheses; ScanForTiger owns tiger classification. Requirement references identify the system contracts; SW requirements
        trace to them through the RST satisfies attributes.
        This is a behavioral/interface specification, not executable perception
        software or validated safety evidence. Healthy status does not establish
        SOTIF performance for every pose, target size, or thermal contrast.
    */

    item def TigerDetection {
        doc /*
            Detection output containing the detection flag, confidence, and
            estimated bearing [deg] and distance [m].
            Requirements: TDS_ALG_004, TDS_WRN_003.
        */
        attribute detected   : Boolean;
        attribute confidence : Real;
        attribute bearing    : Real;
        attribute distance   : Real;
        attribute resultValid : Boolean;
        attribute timestampMs : Integer;
    }

    abstract item def ControlCommand;
    item def StartCommand :> ControlCommand;
    item def StopCommand  :> ControlCommand;

    abstract item def SensorData {
        doc /*
            Raw output of a single sensor modality, fed to the fusion pipeline.
            The valid flag indicates the sensor produced usable data this cycle
            (acquisition integrity only, not guaranteed recognition capability).
            Requirement: TDS_SEN_004.
        */
        attribute valid : Boolean;
        attribute timestampMs : Integer;
        attribute sampleId : Integer;
    }

    item def CameraFrame :> SensorData {
        doc /* Visible-spectrum image frame from the camera sensor. Requirement: TDS_SEN_001. */
    }

    item def LidarPointCloud :> SensorData {
        doc /* 3D point-cloud sample from the LiDAR sensor. Requirement: TDS_SEN_002. */
    }

    item def InfraredFrame :> SensorData {
        doc /* Thermal image frame from the infrared sensor. Requirement: TDS_SEN_003. */
    }

    port def DetectionOutputPort {
        doc /* Exposes TigerDetection data from PerceptionSystem to WarningsSystem. Requirements: TDS_ALG_004, TDS_WRN_003. */
        out item detectionData : TigerDetection;
    }

    port def ControlOutputPort {
        doc /* Carries operator start and stop commands to PerceptionSystem. Requirements: TDS_OPS_001, TDS_OPS_002. */
        out item command : ControlCommand;
    }

    port def CameraOutputPort {
        doc /* Exposes visible-spectrum frames from the camera sensor to the fusion pipeline. Requirement: TDS_SEN_001. */
        out item imageFrame : CameraFrame;
    }

    port def LidarOutputPort {
        doc /* Exposes 3D point-cloud data from the LiDAR sensor to the fusion pipeline. Requirement: TDS_SEN_002. */
        out item cloud : LidarPointCloud;
    }

    port def InfraredOutputPort {
        doc /* Exposes thermal frames from the infrared sensor to the fusion pipeline. Requirement: TDS_SEN_003. */
        out item thermal : InfraredFrame;
    }

    item def DeviceDiagnostics {
        doc /* Device diagnostics are availability-qualified; unknown is not healthy. */
        attribute diagnosticsValid : Boolean;
        attribute deviceHealthy : Boolean;
        attribute calibrationValid : Boolean;
    }
    item def SensorCapability {
        doc /* Host estimates; validity and freshness must be checked before use. */
        attribute statusValid : Boolean;
        attribute statusTimestampMs : Integer;
        attribute dataValid : Boolean;
        attribute blockageEstimateValid : Boolean;
        attribute blockageLevel : Real;
        attribute degraded : Boolean;
        attribute fovValid : Boolean;
        attribute latencyMs : Integer;
    }
    item def CameraCapability :> SensorCapability;
    item def InfraredCapability :> SensorCapability {
        attribute calibrationValid : Boolean;
        attribute contrastEstimateValid : Boolean;
        attribute contrastAdequate : Boolean;
    }
    item def LidarCapability :> SensorCapability {
        attribute pointDensityOk : Boolean;
    }
    item def AmbientConditions {
        attribute illuminanceLux : Real;
        attribute temperatureDegC : Real;
        attribute humidityPercent : Real;
        attribute valid : Boolean;
    }
    item def FusedPerceptionInput {
        doc /* Handle to aligned multimodal samples/features, not a tiger verdict. */
        attribute fusedDataId : Integer;
        attribute syncTimestampMs : Integer;
    }
    item def ObjectHypotheses {
        doc /* Unclassified fused object hypotheses. Classifier ownership remains in ScanForTiger. */
        attribute objectCount : Integer;
        attribute primaryObjectId : Integer;
        attribute existenceProb : Real;
    }
    item def TrackingHint {
        doc /* Previous-cycle ROI hint; cannot suppress full-scene reacquisition. */
        attribute roiValid : Boolean;
        attribute lastDetectionId : Integer;
        attribute trackConfidence : Real;
    }
    item def PerceptionCapability {
        attribute statusValid : Boolean;
        attribute detectionAvailable : Boolean;
        attribute oddWithinLimits : Boolean;
        attribute reasonCode : Integer;
        attribute statusTimestampMs : Integer;
    }
    enum def OperationalState { idle; starting; running; degraded; }
    item def SystemStatus {
        attribute mode : OperationalState;
        attribute detectionAvailable : Boolean;
        attribute reasonCode : Integer;
        attribute statusTimestampMs : Integer;
    }
    abstract item def CapabilityEvent;
    item def CapabilityAvailable :> CapabilityEvent;
    item def CapabilityUnavailable :> CapabilityEvent;
    item def RecoveryQualified :> CapabilityEvent;
    item def StartupTimeout :> CapabilityEvent;
    port def DiagnosticPort { out item diagnostics : DeviceDiagnostics; }
    port def CapabilityEventPort { out item notification : CapabilityEvent; }
    port def SystemStatusPort { out item status : SystemStatus; }
    port def AmbientConditionsPort { out item conditions : AmbientConditions; }

    action def ReadDeviceDiagnostics { out diagnostics : DeviceDiagnostics; }
    action def MeasureAmbientConditions { out conditions : AmbientConditions; }
    action def AssessCameraCapability {
        doc /* RGB acquisition freshness, saturation, blockage and usable-FoV estimates. TDS_SEN_005, TDS_ODD_005, TDS_ODD_006. */
        in sampleInput : CameraFrame;
        in diagnostics : DeviceDiagnostics;
        out status : CameraCapability;
    }
    action def AssessInfraredCapability {
        doc /* LWIR calibration, freshness, blockage and contrast estimates. Thermal-specific thresholds require validation; no perfect blockage observability is assumed. TDS_SEN_005, TDS_ODD_006. */
        in sampleInput : InfraredFrame;
        in diagnostics : DeviceDiagnostics;
        out status : InfraredCapability;
    }
    action def AssessLidarCapability {
        doc /* Lidar scan freshness, blockage and point-density estimates. */
        in cloud : LidarPointCloud;
        in diagnostics : DeviceDiagnostics;
        out status : LidarCapability;
    }
    action def FuseSensorData {
        doc /* Aligns samples/features, qualifies each input and produces unclassified hypotheses. Invalid/unknown status is never treated as healthy. TDS_SEN_004. */
        in cameraFrame : CameraFrame;
        in lidarCloud : LidarPointCloud;
        in thermalFrame : InfraredFrame;
        in cameraStatus : CameraCapability;
        in infraredStatus : InfraredCapability;
        in lidarStatus : LidarCapability;
        in trackingHint : TrackingHint;
        out fusedData : FusedPerceptionInput;
        out objects : ObjectHypotheses;
    }
    action def AssessOperatingCapability {
        doc /* Combines channel status and environment evidence into current capability. Monitoring continues during startup and degraded mode. Startup/recovery timers belong to the lifecycle controller. TDS_SEN_005, TDS_ODD_001 through TDS_ODD_006. */
        in cameraFrame : CameraFrame;
        in lidarCloud : LidarPointCloud;
        in thermalFrame : InfraredFrame;
        in cameraStatus : CameraCapability;
        in infraredStatus : InfraredCapability;
        in lidarStatus : LidarCapability;
        in ambient : AmbientConditions;
        out capability : PerceptionCapability;
    }
    action def QualifyCapabilityEvents {
        doc /* The lifecycle controller uses current operational state, state-entry timestamp and capability history. Produce CapabilityAvailable after startup qualification; CapabilityUnavailable on loss; RecoveryQualified only after T_recovery_stable; StartupTimeout after T_startup without qualification. */
        in capability : PerceptionCapability;
        in currentState : SystemStatus;
        out notification : CapabilityEvent;
    }
    action def PresentSystemStatus {
        doc /* Displays starting, running, idle or SYSTEM NOT OPERATIONAL with reason. TDS_OPS_003, TDS_SAF_006. */
        in status : SystemStatus;
    }
    action def IndicateUnavailable {
        doc /* Distinct periodic unavailable alert for starting/degraded; never indicates that detection is operational. TDS_SAF_006. */
        in status : SystemStatus;
    }
    action def ReportIdle {
        doc /* Publish mode=idle, detectionAvailable=false, current reason and timestamp. */
        out status : SystemStatus;
    }
    action def ReportStarting {
        doc /* Publish mode=starting, detectionAvailable=false, current reason and timestamp. */
        out status : SystemStatus;
    }
    action def ReportRunning {
        doc /* Publish mode=running, detectionAvailable=true, current reason and timestamp. */
        out status : SystemStatus;
    }
    action def ReportDegraded {
        doc /* Publish mode=degraded, detectionAvailable=false, current reason and timestamp. */
        out status : SystemStatus;
    }

    action def StartTigerDetection {
        doc /* Produces the start command initiated by the operator. Requirement: TDS_OPS_001. */
        out cmd : StartCommand;
    }

    action def StopTigerDetection {
        doc /* Produces the stop command initiated by the operator. Requirement: TDS_OPS_002. */
        out cmd : StopCommand;
    }

    action def HandleTigerAlert {
        doc /* Processes a received detection before warning activation. Requirement: TDS_WRN_001. */
        in  alert    : TigerDetection;
        out verified : TigerDetection;
    }

    action def IssueTigerWarning {
        doc /* Maintains the audible and visual tiger warning. Requirements: TDS_WRN_002, TDS_WRN_003, TDS_WRN_005. */
        in alert : TigerDetection;
    }

    action def CaptureImage {
        doc /* Acquires a visible-spectrum frame from the camera sensor. Requirement: TDS_SEN_001. */
        out imageFrame : CameraFrame;
    }

    action def ScanLidar {
        doc /* Acquires a 3D point-cloud sample from the LiDAR sensor. Requirement: TDS_SEN_002. */
        out cloud : LidarPointCloud;
    }

    action def CaptureThermal {
        doc /* Acquires a thermal frame from the infrared sensor. Requirement: TDS_SEN_003. */
        out thermal : InfraredFrame;
    }

    action def ScanForTiger {
        doc /* Performs tiger/non-tiger classification AFTER fusion and temporal confirmation, using both fused features and unclassified object hypotheses. It qualifies the result using current capability; a negative classification or healthy sensor status does not prove SOTIF coverage. Requirements: TDS_ALG_001 through TDS_ALG_004, TDS_SAF_003 through TDS_SAF_005. */
        in fusedData : FusedPerceptionInput;
        in objects : ObjectHypotheses;
        in capability : PerceptionCapability;
        out result : TigerDetection;
        out hint : TrackingHint;
    }

    action def ReceiveControl {
        doc /* Receives the operator control command. Requirements: TDS_OPS_001, TDS_OPS_002. */
        in cmd : ControlCommand;
    }

    action def ActivateTigerAlarm {
        doc /*
            Activates the audible alarm within the allowed level range and
            displays the detected tiger bearing and distance.
            Requirements: TDS_WRN_001, TDS_WRN_002, TDS_WRN_003, TDS_WRN_005.
        */
        in detection : TigerDetection;
    }

    action def DeactivateTigerAlarm {
        doc /* Clears the audible and visual tiger warning after T_warning_timeout without a detection. Requirement: TDS_WRN_004. */
    }

    state def UIStateMachine {
        doc /*
            OperatorUI lifecycle: idle until the operator presses start;
            running until stop. Requirements: TDS_OPS_001, TDS_OPS_002,
            TDS_OPS_003.
        */
        entry; then idle;
        state idle;
            transition first idle accept StartCommand then running;
        state running;
            transition first running accept StopCommand then idle;
    }

    state def PerceptionStateMachine {
        doc /* Abstract perception lifecycle. Degraded means detection is not credited, not an accepted reduced-sensor operating mode. */
        entry; then idle;
        state idle;
        transition first idle accept StartCommand then starting;
        state starting;
        transition first starting accept CapabilityAvailable then scanning;
        transition first starting accept StartupTimeout then degraded;
        transition first starting accept StopCommand then idle;
        state scanning;
        transition first scanning accept CapabilityUnavailable then degraded;
        transition first scanning accept StopCommand then idle;
        state degraded;
        transition first degraded accept RecoveryQualified then scanning;
        transition first degraded accept StopCommand then idle;
    }

    state def WarningStateMachine {
        doc /*
            WarningsSystem lifecycle: a tiger detection enters alertingChange;
            a further detection resets it; a stop command or timeout returns to
            idle. Requirements: TDS_WRN_001, TDS_WRN_004.
        */
        entry; then idle;
        state idle;
            transition toAlertingChange  first idle          accept TigerDetection then alertingChange;
        state alertingChange;
            transition resetAlert  first alertingChange  accept TigerDetection then alertingChange;
            transition toIdle      first alertingChange  accept StopCommand    then idle;
    }

    part def OperatorUI {
        doc /*
            Converts startButtonPressed and stopButtonPressed change events
            into control commands and presents the system status to the
            operator. Requirements: TDS_OPS_001, TDS_OPS_002, TDS_OPS_003.
        */
        attribute startButtonPressed : Boolean = false;
        attribute stopButtonPressed  : Boolean = false;
        port controlOut : ControlOutputPort;
        port systemStatusIn : ~SystemStatusPort;
        perform action presentStatus : PresentSystemStatus;
        flow stateDisplay from systemStatusIn.status to presentStatus.status;
        perform action startSystem : StartTigerDetection;
        perform action stopSystem  : StopTigerDetection;
        flow startCmd from startSystem.cmd to controlOut.command;
        flow stopCmd  from stopSystem.cmd  to controlOut.command;

        exhibit state uiBehavior {
            entry; then idle;

            state idle;
                accept when startButtonPressed
                do startSystem
                then running;

            state running;
                accept when stopButtonPressed
                do stopSystem
                then idle;
        }
    }

    part def CameraSensor {
        doc /*
            Visible-spectrum camera providing imagery at >= F_sensor fps up to
            D_detection_range during daytime. Requirement: TDS_SEN_001.
        */
        attribute frameRate : Real = 30;
        attribute maxRange  : Real = 65;
        port imageOut : CameraOutputPort;
        port diagnosticOut : DiagnosticPort;
        perform action readDiagnostics : ReadDeviceDiagnostics;
        flow diagnosticsFlow from readDiagnostics.diagnostics to diagnosticOut.diagnostics;
        perform action capture : CaptureImage;
        flow imageFlow from capture.imageFrame to imageOut.imageFrame;
    }

    part def LidarSensor {
        doc /*
            LiDAR providing 3D point-cloud data within D_detection_range at
            >= F_sensor, independent of ambient light. Requirement: TDS_SEN_002.
        */
        attribute frameRate : Real = 30;
        attribute maxRange  : Real = 65;
        port cloudOut : LidarOutputPort;
        port diagnosticOut : DiagnosticPort;
        perform action readDiagnostics : ReadDeviceDiagnostics;
        flow diagnosticsFlow from readDiagnostics.diagnostics to diagnosticOut.diagnostics;
        perform action scanLidar : ScanLidar;
        flow cloudFlow from scanLidar.cloud to cloudOut.cloud;
    }

    part def InfraredSensor {
        doc /*
            Infrared sensor for thermal detection up to D_detection_range at
            >= F_sensor fps; primary modality at night. Requirement: TDS_SEN_003.
        */
        attribute frameRate : Real = 30;
        attribute maxRange  : Real = 65;
        port thermalOut : InfraredOutputPort;
        port diagnosticOut : DiagnosticPort;
        perform action readDiagnostics : ReadDeviceDiagnostics;
        flow diagnosticsFlow from readDiagnostics.diagnostics to diagnosticOut.diagnostics;
        perform action captureThermal : CaptureThermal;
        flow thermalFlow from captureThermal.thermal to thermalOut.thermal;
    }

    part def AmbientSensor {
        doc /* Light and temperature/humidity acquisition. */
        port ambientOut : AmbientConditionsPort;
        perform action measure : MeasureAmbientConditions;
        flow ambientFlow from measure.conditions to ambientOut.conditions;
    }

    part def ComputeUnit {
        doc /* Host processor: separate RGB/LWIR/lidar acquisition and quality assessment, then fusion and tiger classification. Camera hardware is not assumed to execute host algorithms. */
        port cameraIn : ~CameraOutputPort;
        port lidarIn : ~LidarOutputPort;
        port infraredIn : ~InfraredOutputPort;
        port cameraDiagnosticIn : ~DiagnosticPort;
        port infraredDiagnosticIn : ~DiagnosticPort;
        port lidarDiagnosticIn : ~DiagnosticPort;
        port ambientIn : ~AmbientConditionsPort;
        port detectionOut : DetectionOutputPort;
        port capabilityEventOut : CapabilityEventPort;
        port systemStateIn : ~SystemStatusPort;
        perform action assessCamera : AssessCameraCapability;
        perform action assessInfrared : AssessInfraredCapability;
        perform action assessLidar : AssessLidarCapability;
        perform action fuse : FuseSensorData;
        perform action monitor : AssessOperatingCapability;
        perform action qualifyLifecycle : QualifyCapabilityEvents;
        perform action scan : ScanForTiger;
        flow cameraFeed from cameraIn.imageFrame to fuse.cameraFrame;
        flow lidarFeed from lidarIn.cloud to fuse.lidarCloud;
        flow infraredFeed from infraredIn.thermal to fuse.thermalFrame;
        flow cameraAssessment from cameraIn.imageFrame to assessCamera.sampleInput;
        flow infraredAssessment from infraredIn.thermal to assessInfrared.sampleInput;
        flow lidarAssessment from lidarIn.cloud to assessLidar.cloud;
        flow cameraDiagnostics from cameraDiagnosticIn.diagnostics to assessCamera.diagnostics;
        flow infraredDiagnostics from infraredDiagnosticIn.diagnostics to assessInfrared.diagnostics;
        flow lidarDiagnostics from lidarDiagnosticIn.diagnostics to assessLidar.diagnostics;
        flow cameraStatus from assessCamera.status to fuse.cameraStatus;
        flow infraredStatus from assessInfrared.status to fuse.infraredStatus;
        flow lidarStatus from assessLidar.status to fuse.lidarStatus;
        flow cameraMonitor from assessCamera.status to monitor.cameraStatus;
        flow infraredMonitor from assessInfrared.status to monitor.infraredStatus;
        flow lidarMonitor from assessLidar.status to monitor.lidarStatus;
        flow cameraConditions from cameraIn.imageFrame to monitor.cameraFrame;
        flow infraredConditions from infraredIn.thermal to monitor.thermalFrame;
        flow lidarConditions from lidarIn.cloud to monitor.lidarCloud;
        flow ambientConditions from ambientIn.conditions to monitor.ambient;
        flow fusedFeed from fuse.fusedData to scan.fusedData;
        flow objectsFeed from fuse.objects to scan.objects;
        flow capabilityFeed from monitor.capability to scan.capability;
        flow feedback from scan.hint to fuse.trackingHint;
        flow lifecycleCapability from monitor.capability to qualifyLifecycle.capability;
        flow lifecycleState from systemStateIn.status to qualifyLifecycle.currentState;
        flow capabilityEvents from qualifyLifecycle.notification to capabilityEventOut.notification;
        flow detectionFlow from scan.result to detectionOut.detectionData;
    }

    part def PerceptionSystem {
        doc /*
            Waits for StartCommand, scans continuously while active, and stops
            scanning on StopCommand. Hosts the three sensor modalities and the
            compute unit, which fuses them into a single detection result.
            Requirements: TDS_SAF_002, TDS_SEN_001, TDS_SEN_002, TDS_SEN_003,
            TDS_SEN_004.
        */
        port controlIn       : ~ControlOutputPort;
        port detectionOut    : DetectionOutputPort;

        part camera   : CameraSensor;
        part lidar    : LidarSensor;
        part infrared : InfraredSensor;
        part compute  : ComputeUnit;
        part ambient : AmbientSensor;
        port capabilityEventIn : ~CapabilityEventPort;
        port systemStatusOut : SystemStatusPort;
        perform action reportIdle : ReportIdle;
        perform action reportStarting : ReportStarting;
        perform action reportRunning : ReportRunning;
        perform action reportDegraded : ReportDegraded;
        flow idleStatus from reportIdle.status to systemStatusOut.status;
        flow startingStatus from reportStarting.status to systemStatusOut.status;
        flow runningStatus from reportRunning.status to systemStatusOut.status;
        flow degradedStatus from reportDegraded.status to systemStatusOut.status;

        perform action receiveControl : ReceiveControl;
        flow controlFlow from controlIn.command to receiveControl.cmd;

        connect camera.imageOut    to compute.cameraIn;
        connect lidar.cloudOut     to compute.lidarIn;
        connect infrared.thermalOut to compute.infraredIn;
        connect camera.diagnosticOut to compute.cameraDiagnosticIn;
        connect infrared.diagnosticOut to compute.infraredDiagnosticIn;
        connect lidar.diagnosticOut to compute.lidarDiagnosticIn;
        connect ambient.ambientOut to compute.ambientIn;
        connect compute.capabilityEventOut to capabilityEventIn;
        connect systemStatusOut to compute.systemStateIn;

        flow detectionForward from compute.detectionOut.detectionData to detectionOut.detectionData;

        exhibit state perceptionBehavior {
            entry; then idle;
            state idle { entry reportIdle; }
                accept StartCommand via controlIn then starting;
            state starting { entry reportStarting; }
                accept CapabilityAvailable via capabilityEventIn then scanning;
                accept StartupTimeout via capabilityEventIn then degraded;
                accept StopCommand via controlIn then idle;
            state scanning { entry reportRunning; do compute.scan; }
                accept CapabilityUnavailable via capabilityEventIn then degraded;
                accept StopCommand via controlIn then idle;
            state degraded { entry reportDegraded; }
                accept RecoveryQualified via capabilityEventIn then scanning;
                accept StopCommand via controlIn then idle;
        }
    }

    part def WarningsSystem {
        doc /*
            Activates and maintains the tiger warning after a verified
            detection; new detections reset the timeout, and a timeout or stop
            returns the system to idle.
            Requirements: TDS_WRN_001, TDS_WRN_002, TDS_WRN_003, TDS_WRN_004,
            TDS_WRN_005.
        */
        attribute warningActive   : Boolean = false;
        attribute warningTimedOut : Boolean = false;

        port detectionIn    : ~DetectionOutputPort;
        port systemStatusIn : ~SystemStatusPort;
        perform action indicateUnavailable : IndicateUnavailable;
        flow unavailableStatus from systemStatusIn.status to indicateUnavailable.status;

        perform action handleAlert     : HandleTigerAlert;
        perform action activateAlarm   : ActivateTigerAlarm;
        perform action deactivateAlarm : DeactivateTigerAlarm;
        perform action warnUsers       : IssueTigerWarning;

        flow alertFlow  from detectionIn.detectionData to handleAlert.alert;
        flow verifyFlow from handleAlert.verified      to activateAlarm.detection;

        exhibit state warningBehavior {
            entry; then idle;

            state idle;
                accept det : TigerDetection via detectionIn if det.detected and det.resultValid
                do activateAlarm
                then alertingChange;

            state alertingChange {
                do warnUsers;
            }
                accept det : TigerDetection via detectionIn if det.detected and det.resultValid
                do activateAlarm
                then alertingChange;

                accept when warningTimedOut
                do deactivateAlarm
                then idle;
        }
    }

    interface def ControlInterface {
        doc /* Connects OperatorUI control output to the PerceptionSystem control input. Requirements: TDS_OPS_001, TDS_OPS_002. */
        end senderPort   : ControlOutputPort;
        end receiverPort : ~ControlOutputPort;
        flow of ControlCommand
            from senderPort.command
            to   receiverPort.command;
    }

    interface def TigerDetectionInterface {
        doc /* Connects perception detections to the warning system. Requirements: TDS_ALG_004, TDS_WRN_001, TDS_WRN_003. */
        end senderPort   : DetectionOutputPort;
        end receiverPort : ~DetectionOutputPort;
        flow of TigerDetection
            from senderPort.detectionData
            to   receiverPort.detectionData;
    }

    part def TigerDetectionSystem {
        doc /*
            Composes PerceptionSystem, WarningsSystem, and OperatorUI and
            connects their control and detection ports.
            Requirement: TDS_SAF_001.
        */
        attribute isRunning : Boolean = false;
        part perception : PerceptionSystem;
        part warnings   : WarningsSystem;
        part ui         : OperatorUI;

        connect ui.controlOut           to perception.controlIn;
        connect perception.detectionOut to warnings.detectionIn;
        connect perception.systemStatusOut to ui.systemStatusIn;
        connect perception.systemStatusOut to warnings.systemStatusIn;
    }

    part tdsInstance : TigerDetectionSystem;
}
