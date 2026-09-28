package TigerDetectionSystemExample {
    private import ScalarValues::*;

    doc /*
        Monitored RGB + LWIR + lidar reference architecture. Sensor hardware
        supplies measurements and available device diagnostics; channel-quality
        and blockage estimation are host software functions, not guaranteed
        embedded camera features. Fusion aligns data and produces unclassified
        hypotheses; ScanForTiger owns tiger classification. Requirement references identify the system contracts; SW requirements
        trace to them through the RST satisfies attributes.
        Ports: one definition per payload, named after what it conveys and
        declaring its items as out. The sending side uses it as declared and the
        receiving side conjugates it (~Name), which reverses every item it
        carries. Both ends of a connection therefore share one port type, and a
        payload is declared once. A port usage carries no direction of its own;
        it is an input or an output because of the items its (possibly
        conjugated) definition declares, and the usage name records which.
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

    port def DetectionPort {
        doc /* Conveys TigerDetection data from PerceptionSystem to WarningsSystem. Requirements: TDS_ALG_004, TDS_WRN_003. */
        out item detectionData : TigerDetection;
    }

    port def ControlPort {
        doc /* Conveys operator start and stop commands to PerceptionSystem. Requirements: TDS_OPS_001, TDS_OPS_002. */
        out item command : ControlCommand;
    }

    port def CameraPort {
        doc /* Conveys visible-spectrum frames from the camera sensor to the fusion pipeline. Requirement: TDS_SEN_001. */
        out item imageFrame : CameraFrame;
    }

    port def LidarPort {
        doc /* Conveys 3D point-cloud data from the LiDAR sensor to the fusion pipeline. Requirement: TDS_SEN_002. */
        out item cloud : LidarPointCloud;
    }

    port def InfraredPort {
        doc /* Conveys thermal frames from the infrared sensor to the fusion pipeline. Requirement: TDS_SEN_003. */
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
    port def SystemStatusPort { out item systemStatus : SystemStatus; }
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
        in systemStatus : SystemStatus;
        out notification : CapabilityEvent;
    }
    action def PresentSystemStatus {
        doc /* Displays starting, running, idle or SYSTEM NOT OPERATIONAL with reason. TDS_OPS_003, TDS_SAF_006. */
        in systemStatus : SystemStatus;
    }
    action def IndicateUnavailable {
        doc /* Distinct periodic unavailable alert for starting/degraded; never indicates that detection is operational. TDS_SAF_006. */
        in systemStatus : SystemStatus;
    }
    action def ReportIdle {
        doc /* Publish mode=idle, detectionAvailable=false, current reason and timestamp. */
        out systemStatus : SystemStatus;
    }
    action def ReportStarting {
        doc /* Publish mode=starting, detectionAvailable=false, current reason and timestamp. */
        out systemStatus : SystemStatus;
    }
    action def ReportRunning {
        doc /* Publish mode=running, detectionAvailable=true, current reason and timestamp. */
        out systemStatus : SystemStatus;
    }
    action def ReportDegraded {
        doc /* Publish mode=degraded, detectionAvailable=false, current reason and timestamp. */
        out systemStatus : SystemStatus;
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
        port controlOut : ControlPort;
        port systemStatusIn : ~SystemStatusPort;
        perform action presentSystemStatus : PresentSystemStatus;
        flow stateDisplay from systemStatusIn.systemStatus to presentSystemStatus.systemStatus;
        perform action startTigerDetection : StartTigerDetection;
        perform action stopTigerDetection  : StopTigerDetection;
        flow startCmd from startTigerDetection.cmd to controlOut.command;
        flow stopCmd  from stopTigerDetection.cmd  to controlOut.command;

        exhibit state uiBehavior {
            entry; then idle;

            state idle;
                accept when startButtonPressed
                do startTigerDetection
                then running;

            state running;
                accept when stopButtonPressed
                do stopTigerDetection
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
        port imageOut : CameraPort;
        port diagnosticOut : DiagnosticPort;
        perform action readDeviceDiagnostics : ReadDeviceDiagnostics;
        flow diagnosticsFlow from readDeviceDiagnostics.diagnostics to diagnosticOut.diagnostics;
        perform action captureImage : CaptureImage;
        flow imageFlow from captureImage.imageFrame to imageOut.imageFrame;
    }

    part def LidarSensor {
        doc /*
            LiDAR providing 3D point-cloud data within D_detection_range at
            >= F_sensor, independent of ambient light. Requirement: TDS_SEN_002.
        */
        attribute frameRate : Real = 30;
        attribute maxRange  : Real = 65;
        port cloudOut : LidarPort;
        port diagnosticOut : DiagnosticPort;
        perform action readDeviceDiagnostics : ReadDeviceDiagnostics;
        flow diagnosticsFlow from readDeviceDiagnostics.diagnostics to diagnosticOut.diagnostics;
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
        port thermalOut : InfraredPort;
        port diagnosticOut : DiagnosticPort;
        perform action readDeviceDiagnostics : ReadDeviceDiagnostics;
        flow diagnosticsFlow from readDeviceDiagnostics.diagnostics to diagnosticOut.diagnostics;
        perform action captureThermal : CaptureThermal;
        flow thermalFlow from captureThermal.thermal to thermalOut.thermal;
    }

    part def AmbientSensor {
        doc /* Light and temperature/humidity acquisition. */
        port ambientOut : AmbientConditionsPort;
        perform action measureAmbientConditions : MeasureAmbientConditions;
        flow ambientFlow from measureAmbientConditions.conditions to ambientOut.conditions;
    }

    part def ComputeUnit {
        doc /* Host processor: separate RGB/LWIR/lidar acquisition and quality assessment, then fusion and tiger classification. Camera hardware is not assumed to execute host algorithms. */
        port cameraIn : ~CameraPort;
        port lidarIn : ~LidarPort;
        port infraredIn : ~InfraredPort;
        port cameraDiagnosticIn : ~DiagnosticPort;
        port infraredDiagnosticIn : ~DiagnosticPort;
        port lidarDiagnosticIn : ~DiagnosticPort;
        port ambientIn : ~AmbientConditionsPort;
        port detectionOut : DetectionPort;
        port capabilityEventOut : CapabilityEventPort;
        port systemStatusIn : ~SystemStatusPort;
        perform action assessCameraCapability : AssessCameraCapability;
        perform action assessInfraredCapability : AssessInfraredCapability;
        perform action assessLidarCapability : AssessLidarCapability;
        perform action fuseSensorData : FuseSensorData;
        perform action assessOperatingCapability : AssessOperatingCapability;
        perform action qualifyCapabilityEvents : QualifyCapabilityEvents;
        perform action scanForTiger : ScanForTiger;
        flow cameraFeed from cameraIn.imageFrame to fuseSensorData.cameraFrame;
        flow lidarFeed from lidarIn.cloud to fuseSensorData.lidarCloud;
        flow infraredFeed from infraredIn.thermal to fuseSensorData.thermalFrame;
        flow cameraAssessment from cameraIn.imageFrame to assessCameraCapability.sampleInput;
        flow infraredAssessment from infraredIn.thermal to assessInfraredCapability.sampleInput;
        flow lidarAssessment from lidarIn.cloud to assessLidarCapability.cloud;
        flow cameraDiagnostics from cameraDiagnosticIn.diagnostics to assessCameraCapability.diagnostics;
        flow infraredDiagnostics from infraredDiagnosticIn.diagnostics to assessInfraredCapability.diagnostics;
        flow lidarDiagnostics from lidarDiagnosticIn.diagnostics to assessLidarCapability.diagnostics;
        flow cameraStatus from assessCameraCapability.status to fuseSensorData.cameraStatus;
        flow infraredStatus from assessInfraredCapability.status to fuseSensorData.infraredStatus;
        flow lidarStatus from assessLidarCapability.status to fuseSensorData.lidarStatus;
        flow cameraMonitor from assessCameraCapability.status to assessOperatingCapability.cameraStatus;
        flow infraredMonitor from assessInfraredCapability.status to assessOperatingCapability.infraredStatus;
        flow lidarMonitor from assessLidarCapability.status to assessOperatingCapability.lidarStatus;
        flow cameraConditions from cameraIn.imageFrame to assessOperatingCapability.cameraFrame;
        flow infraredConditions from infraredIn.thermal to assessOperatingCapability.thermalFrame;
        flow lidarConditions from lidarIn.cloud to assessOperatingCapability.lidarCloud;
        flow ambientConditions from ambientIn.conditions to assessOperatingCapability.ambient;
        flow fusedFeed from fuseSensorData.fusedData to scanForTiger.fusedData;
        flow objectsFeed from fuseSensorData.objects to scanForTiger.objects;
        flow capabilityFeed from assessOperatingCapability.capability to scanForTiger.capability;
        flow feedback from scanForTiger.hint to fuseSensorData.trackingHint;
        flow lifecycleCapability from assessOperatingCapability.capability to qualifyCapabilityEvents.capability;
        flow lifecycleState from systemStatusIn.systemStatus to qualifyCapabilityEvents.systemStatus;
        flow capabilityEvents from qualifyCapabilityEvents.notification to capabilityEventOut.notification;
        flow detectionFlow from scanForTiger.result to detectionOut.detectionData;
    }

    part def PerceptionSystem {
        doc /*
            Waits for StartCommand, scans continuously while active, and stops
            scanning on StopCommand. Hosts the three sensor modalities and the
            compute unit, which fuses them into a single detection result.
            Requirements: TDS_SAF_002, TDS_SEN_001, TDS_SEN_002, TDS_SEN_003,
            TDS_SEN_004.
        */
        port controlIn       : ~ControlPort;
        port detectionOut    : DetectionPort;

        part cameraSensorCHANGE   : CameraSensor;
        part lidarSensor    : LidarSensor;
        part infraredSensor : InfraredSensor;
        part computeUnit    : ComputeUnit;
        part ambientSensor  : AmbientSensor;
        port capabilityEventIn : ~CapabilityEventPort;
        port systemStatusOut : SystemStatusPort;
        perform action reportIdle : ReportIdle;
        perform action reportStarting : ReportStarting;
        perform action reportRunning : ReportRunning;
        perform action reportDegraded : ReportDegraded;
        flow idleStatus from reportIdle.systemStatus to systemStatusOut.systemStatus;
        flow startingStatus from reportStarting.systemStatus to systemStatusOut.systemStatus;
        flow runningStatus from reportRunning.systemStatus to systemStatusOut.systemStatus;
        flow degradedStatus from reportDegraded.systemStatus to systemStatusOut.systemStatus;

        // The lifecycle controller in computeUnit is fed by the same four reports
        // that publish the status outward, rather than by a delegation from
        // systemStatusOut: that port sends the status to the operator and the
        // warning system, so reading it back inward made an output port the source
        // of one of its own siblings' inputs. All four states are supplied, not
        // just running and degraded — QualifyCapabilityEvents raises StartupTimeout
        // from mode=starting, and must stay silent in mode=idle.
        flow idleState from reportIdle.systemStatus to computeUnit.systemStatusIn;
        flow startingState from reportStarting.systemStatus to computeUnit.systemStatusIn;
        flow runningState from reportRunning.systemStatus to computeUnit.systemStatusIn;
        flow degradedState from reportDegraded.systemStatus to computeUnit.systemStatusIn;

        perform action receiveControl : ReceiveControl;
        flow controlFlow from controlIn.command to receiveControl.cmd;

        connect cameraSensorCHANGE.imageOut       to computeUnit.cameraIn;
        connect lidarSensor.cloudOut        to computeUnit.lidarIn;
        connect infraredSensor.thermalOut   to computeUnit.infraredIn;
        connect cameraSensorCHANGE.diagnosticOut  to computeUnit.cameraDiagnosticIn;
        connect infraredSensor.diagnosticOut to computeUnit.infraredDiagnosticIn;
        connect lidarSensor.diagnosticOut   to computeUnit.lidarDiagnosticIn;
        connect ambientSensor.ambientOut    to computeUnit.ambientIn;
        connect computeUnit.capabilityEventOut to capabilityEventIn;

        flow detectionForward from computeUnit.detectionOut.detectionData to detectionOut.detectionData;

        exhibit state perceptionBehavior {
            entry; then idle;
            state idle { entry reportIdle; }
                accept StartCommand via controlIn then starting;
            state starting { entry reportStarting; }
                accept CapabilityAvailable via capabilityEventIn then scanning;
                accept StartupTimeout via capabilityEventIn then degraded;
                accept StopCommand via controlIn then idle;
            state scanning { entry reportRunning; do computeUnit.scanForTiger; }
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

        port detectionIn    : ~DetectionPort;
        port systemStatusIn : ~SystemStatusPort;
        perform action indicateUnavailable : IndicateUnavailable;
        flow unavailableStatus from systemStatusIn.systemStatus to indicateUnavailable.systemStatus;

        perform action handleTigerAlert     : HandleTigerAlert;
        perform action activateTigerAlarm   : ActivateTigerAlarm;
        perform action deactivateTigerAlarm : DeactivateTigerAlarm;
        perform action issueTigerWarning    : IssueTigerWarning;

        flow alertFlow  from detectionIn.detectionData  to handleTigerAlert.alert;
        flow verifyFlow from handleTigerAlert.verified  to activateTigerAlarm.detection;

        exhibit state warningBehavior {
            entry; then idle;

            state idle;
                accept det : TigerDetection via detectionIn if det.detected and det.resultValid
                do activateTigerAlarm
                then alertingChange;

            state alertingChange {
                do issueTigerWarning;
            }
                accept det : TigerDetection via detectionIn if det.detected and det.resultValid
                do activateTigerAlarm
                then alertingChange;

                accept when warningTimedOut
                do deactivateTigerAlarm
                then idle;
        }
    }

    interface def ControlInterface {
        doc /* Connects OperatorUI control output to the PerceptionSystem control input. Requirements: TDS_OPS_001, TDS_OPS_002. */
        end senderPort   : ControlPort;
        end receiverPort : ~ControlPort;
        flow of ControlCommand
            from senderPort.command
            to   receiverPort.command;
    }

    interface def TigerDetectionInterface {
        doc /* Connects perception detections to the warning system. Requirements: TDS_ALG_004, TDS_WRN_001, TDS_WRN_003. */
        end senderPort   : DetectionPort;
        end receiverPort : ~DetectionPort;
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
        part perceptionSystem : PerceptionSystem;
        part warningsSystem   : WarningsSystem;
        part operatorUI       : OperatorUI;

        connect operatorUI.controlOut            to perceptionSystem.controlIn;
        connect perceptionSystem.detectionOut    to warningsSystem.detectionIn;
        connect perceptionSystem.systemStatusOut to operatorUI.systemStatusIn;
        connect perceptionSystem.systemStatusOut to warningsSystem.systemStatusIn;
    }

    part tigerDetectionSystem : TigerDetectionSystem;
}
