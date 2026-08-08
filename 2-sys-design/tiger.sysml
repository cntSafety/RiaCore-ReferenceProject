package TigerDetectionSystemExample {
    private import ScalarValues::*;

    doc /*
        Architecture model for the Tiger Detection System (initial baseline).
        This model reflects only the initial system requirements in
        ../1-sys-req/requirements/tigerDetectionReq.rst: detect a tiger and warn
        the operator, with start/stop control. The safe-state, sensor-degradation
        and operating-condition-monitoring functions are NOT modelled here — they
        are improvements raised as tasks by the system-level safety analysis and
        will be added once the requirements are updated. Documentation items below
        cite the corresponding Sphinx-Needs TDS_* IDs; use those IDs to navigate
        the rendered requirements rather than duplicating requirement text here.
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
    }

    abstract item def ControlCommand;
    item def StartCommand :> ControlCommand;
    item def StopCommand  :> ControlCommand;

    abstract item def SensorData {
        doc /*
            Raw output of a single sensor modality, fed to the fusion pipeline.
            The valid flag indicates the sensor produced usable data this cycle
            (within its operating conditions). Requirement: TDS_SEN_004.
        */
        attribute valid : Boolean;
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
        doc /*
            Fuses the camera, LiDAR, and infrared inputs and classifies the
            result, producing a TigerDetection. The fused pipeline achieves a
            lower missed-detection rate than any single sensor alone.
            Requirements: TDS_SAF_003, TDS_SAF_004, TDS_SAF_005, TDS_SEN_004,
            TDS_ALG_001, TDS_ALG_002, TDS_ALG_003, TDS_ALG_004.
        */
        in  cameraFrame  : CameraFrame;
        in  lidarCloud   : LidarPointCloud;
        in  thermalFrame : InfraredFrame;
        out result       : TigerDetection;
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
        doc /*
            PerceptionSystem lifecycle: idle until StartCommand; scanning
            until StopCommand. Requirements: TDS_OPS_001, TDS_OPS_002.
        */
        entry; then idle;
        state idle;
            transition first idle accept StartCommand then scanning;
        state scanning;
            transition first scanning accept StopCommand then idle;
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
        perform action captureThermal : CaptureThermal;
        flow thermalFlow from captureThermal.thermal to thermalOut.thermal;
    }

    part def ComputeUnit {
        doc /*
            Perception compute unit (processor + memory). Fuses the camera,
            LiDAR, and infrared inputs and runs the detection/classification
            pipeline, producing the TigerDetection result. A random hardware
            fault here corrupts or halts the detection pipeline.
            Requirements: TDS_SEN_004, TDS_ALG_001, TDS_ALG_002, TDS_ALG_003,
            TDS_ALG_004.
        */
        port cameraIn     : ~CameraOutputPort;
        port lidarIn      : ~LidarOutputPort;
        port infraredIn   : ~InfraredOutputPort;
        port detectionOut : DetectionOutputPort;

        perform action scan : ScanForTiger;
        flow cameraFeed    from cameraIn.imageFrame  to scan.cameraFrame;
        flow lidarFeed     from lidarIn.cloud        to scan.lidarCloud;
        flow infraredFeed  from infraredIn.thermal   to scan.thermalFrame;
        flow detectionFlow from scan.result          to detectionOut.detectionData;
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

        perform action receiveControl : ReceiveControl;
        flow controlFlow from controlIn.command to receiveControl.cmd;

        connect camera.imageOut    to compute.cameraIn;
        connect lidar.cloudOut     to compute.lidarIn;
        connect infrared.thermalOut to compute.infraredIn;

        flow detectionForward from compute.detectionOut.detectionData to detectionOut.detectionData;

        exhibit state perceptionBehavior {
            entry; then idle;

            state idle;
                accept cmd : StartCommand via controlIn
                then scanning;

            state scanning {
                do compute.scan;
            }
                accept cmd : StopCommand via controlIn
                then idle;
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

        perform action handleAlert     : HandleTigerAlert;
        perform action activateAlarm   : ActivateTigerAlarm;
        perform action deactivateAlarm : DeactivateTigerAlarm;
        perform action warnUsers       : IssueTigerWarning;

        flow alertFlow  from detectionIn.detectionData to handleAlert.alert;
        flow verifyFlow from handleAlert.verified      to activateAlarm.detection;

        exhibit state warningBehavior {
            entry; then idle;

            state idle;
                accept det : TigerDetection via detectionIn if det.detected
                do activateAlarm
                then alertingChange;

            state alertingChange {
                do warnUsers;
            }
                accept det : TigerDetection via detectionIn if det.detected
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
    }

    part tdsInstance : TigerDetectionSystem;
}
