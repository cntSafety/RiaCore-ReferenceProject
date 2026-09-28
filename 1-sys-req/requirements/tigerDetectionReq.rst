.. _tiger-detection-requirements:

=======================================
Tiger Detection System - Requirements
=======================================

.. note::

   Safety-analysis findings are addressed through tasks that trace to the
   affected requirements and design elements. Open tasks track the remaining
   verification, validation and requirements updates.

.. contents:: Table of Contents
   :local:
   :depth: 2
   :class: this-will-duplicate-information-and-it-is-still-useful-here

System Overview
===============

The Tiger Detection System (TDS) is a multi-sensor warning system that detects
approaching tigers and warns exploration personnel. It combines camera, LiDAR,
and infrared sensors with a detection algorithm. Warnings are issued via an
audible alarm and a visual display.

This revision specifies separate RGB, thermal infrared, and lidar sensing paths,
channel-capability and operating-condition monitoring, and an explicit degraded
state. Monitoring algorithms and thresholds remain subject to verification and
SOTIF scenario validation; their presence is not evidence of residual-risk acceptance.

SOTIF Case C1 identified insufficient sensing diversity in the original RGB-plus-lidar
configuration. Camouflage and partial concealment motivated runtime measure
``SOTIF_RT_001``: add LWIR sensing and evaluate thermal evidence alongside the
other modalities. The measure is included in the current system and software
architecture, and its task status is ``Done``. The resulting requirements identify
that task using ``originating_task``. Performance validation and residual-risk
acceptance remain open and are tracked separately. Follow-up Case C2 assesses
the thermal measure's limitation when target–background thermal contrast is low.

Safety Assumptions (Safety Element out of Context)
==================================================

The system is specified as a **Safety Element out of Context (SEooC)**. Instead
of deriving the safety level from a full hazard analysis and risk assessment,
the following assumptions are made and **shall be confirmed by the integrator**
who deploys the system in a concrete operational context:

- **Assumed safety level:** ASIL B. This is an *assumed* safety requirement,
  to be confirmed by the integrator against the actual operational context.
- **Assumed Fault Tolerance Time (FTT):** ``FTT`` = 1.0 s — the
  maximum time the system may take, after a fault occurs, before it reaches the
  safe state and issues the corresponding indication.
- **Assumed safe state:** the operator is informed that tiger detection is not
  operational and assumes manual vigilance. The system is a warning system with
  no actuator, so there is no physical safe position to command.
- **Parameter validation:** the values below are preliminary design assumptions.
  The integrator shall confirm each value for the operational context and provide
  supporting verification and validation evidence before acceptance.

Parameters
==========

The following parameters are used throughout this specification. They form the
preliminary design baseline and require validation against the SEooC assumptions
and the intended operational context.

.. list-table:: System Parameters
   :header-rows: 1
   :widths: 22 20 58

   * - Parameter
     - Value
     - Description
   * - ``FTT``
     - 1.0 s
     - Fault Tolerance Time — max time from a fault occurring to the safe-state
       indication
   * - ``P_undetected_encounter``
     - 1e-4 / h
     - Acceptable probability of an undetected tiger encounter per
       operational hour (system-level residual risk)
   * - ``P_fn_close``
     - 0.01 / frame
     - Per-frame missed-detection rate for tigers at close range (0–25 m)
   * - ``P_fn_mid``
     - 0.05 / frame
     - Per-frame missed-detection rate for tigers at mid range (25–50 m)
   * - ``P_encounter_detection``
     - 0.999
     - Probability of detecting a tiger within ``T_detection_window``
   * - ``T_detection_window``
     - 1.0 s
     - Maximum time from tiger entering detection range to a confirmed detection
   * - ``T_classification``
     - 0.2 s
     - End-to-end classification latency
   * - ``T_warning``
     - 0.3 s
     - Time from detection event to warning activation
   * - ``T_startup``
     - 5 s
     - Time from start command to active detection mode
   * - ``T_warning_timeout``
     - 10 s
     - Time without detection before warning deactivation
   * - ``D_detection_range``
     - 65 m
     - Detection radius around the exploration group
   * - ``V_tiger_max``
     - 50 km/h
     - Maximum assumed tiger approach speed (≈ 13.9 m/s sprint)
   * - ``F_sensor``
     - 30 fps
     - Minimum sensor cycle rate
   * - ``N_fp_max``
     - 1 / h
     - Maximum false positive detections per operational hour
   * - ``L_alarm_min``
     - 85 dB(A)
     - Minimum audible alarm level at 1 m
   * - ``L_alarm_max``
     - 105 dB(A)
     - Maximum audible alarm level at 1 m

Additional monitoring parameters (validation pending):

- ``T_sensor_degradation`` = 0.5 s maximum detection time for observable loss.
- ``T_odd_violation`` = 0.5 s maximum detection time for validated observable ODD excursions.
- ``T_recovery_stable`` = 10 s of continuously qualified operation before recovery.
- ``T_status_max_age`` = 0.1 s maximum age for a credited capability report.
- The allocated fault budget is 0.5 s detection + 0.3 s response = 0.8 s,
  within ``FTT`` = 1.0 s; actual worst-case latency requires verification.

Operating Conditions
====================

The system is intended to operate within the following conditions. Detection
performance is only expected inside these conditions:

- Temperature: −10 °C to +50 °C (tropical/subtropical habitat; excludes
  cold-climate Amur range)
- Precipitation: none to moderate rain; no fog below ``D_detection_range``
  visibility
- Visibility: ≥ ``D_detection_range`` (≥ 65 m)
- Illumination: any (nighttime to direct sunlight)
- Terrain: jungle, grassland, mangrove swamp


Safety Requirements
===================

.. req:: Detection Range
   :id: TDS_SAF_002
   :status: open
   :tags: safety;detection;range
   :safety_level: B
   :refines: TDS_SAF_001

   The system shall detect adult tigers within ``D_detection_range``
   under all specified operating conditions.

   ``D_detection_range`` depends on ``V_tiger_max`` — the faster the
   assumed approach, the larger the range needed to provide sufficient
   warning time.

.. req:: Missed-Detection Rate — Close Range
   :id: TDS_SAF_003
   :status: open
   :tags: safety;detection;false-negative
   :safety_level: A
   :refines: TDS_SAF_001;TDS_SAF_002

   The per-frame missed-detection rate for adult tigers at 0–20 m shall not
   exceed ``P_fn_close`` under all specified operating conditions excluding off and startup.

   Close range is the most critical zone — a miss here leaves minimal
   time for evasive action.

.. req:: Missed-Detection Rate — Mid Range
   :id: TDS_SAF_004
   :status: open
   :tags: safety;detection;false-negative
   :safety_level: B
   :refines: TDS_SAF_001;TDS_SAF_002

   The per-frame missed-detection rate for adult tigers at 25–50 m shall not
   exceed ``P_fn_mid`` under all specified operating conditions.

   Relaxed compared to close range because the tiger must still traverse
   the mid-range zone before reaching close range.

.. req:: Detection Within Time Window
   :id: TDS_SAF_005
   :status: open
   :tags: safety;detection;temporal
   :safety_level: B
   :refines: TDS_SAF_003;TDS_SAF_004

   The system shall detect a tiger within ``T_detection_window`` of it
   entering ``D_detection_range``, with probability ≥
   ``P_encounter_detection``.

   Individual sensor frames may miss — this requirement bounds the time to
   a confirmed detection.

Operational Requirements
========================

.. req:: System Start
   :id: TDS_OPS_001
   :status: open
   :tags: operational;control
   :safety_level: B
   :refines: TDS_SAF_001

   The operator shall be able to start detection. The system shall reach
   active mode within ``T_startup``.

.. req:: System Stop
   :id: TDS_OPS_002
   :status: open
   :tags: operational;control
   :safety_level: QM
   :refines: TDS_SAF_001

   The operator shall be able to stop detection. The system shall
   transition to idle and cease scanning.

   Inability to stop is a usability issue — the system keeps detecting.

.. req:: System State Indication
   :id: TDS_OPS_003
   :status: open
   :tags: operational;status
   :safety_level: B
   :refines: TDS_OPS_001;TDS_OPS_002

   The system shall indicate its state (idle, starting, running, degraded) to the operator at
   all times.

   If the operator believes the system is running when it is not, they
   won't take manual precautions.

Sensor Requirements
===================

.. req:: Camera Sensor
   :id: TDS_SEN_001
   :status: open
   :tags: sensor;camera
   :safety_level: B
   :refines: TDS_SAF_002;TDS_SAF_003;TDS_SAF_004

   The system shall include a camera sensor for visible-spectrum imagery
   at ≥ ``F_sensor`` fps, supplying imagery for central tiger classification up to
   ``D_detection_range`` during daytime.

.. req:: LiDAR Sensor
   :id: TDS_SEN_002
   :status: open
   :tags: sensor;lidar
   :safety_level: B
   :refines: TDS_SAF_002

   The system shall include a LiDAR sensor providing 3D point-cloud data
   within ``D_detection_range`` at ≥ ``F_sensor``, independent of ambient
   light.

.. req:: Infrared Sensor
   :id: TDS_SEN_003
   :status: open
   :tags: sensor;infrared
   :safety_level: B
   :refines: TDS_SAF_002;TDS_SAF_004
   :originating_task: SOTIF_RT_001

   The system shall include a separate LWIR infrared imaging sensor for central
   thermal-assisted detection up to
   ``D_detection_range`` at ≥ ``F_sensor`` fps. Primary modality at night.

   Origin: SOTIF runtime measure ``SOTIF_RT_001`` adds the thermal modality to
   the initial RGB-plus-lidar concept. Thermal-assisted evaluation is specified
   by :need:`TDS_SEN_007`.

.. req:: Sensor Fusion
   :id: TDS_SEN_004
   :status: open
   :tags: sensor;fusion
   :safety_level: B
   :refines: TDS_SEN_001;TDS_SEN_002;TDS_SEN_003

   The system shall qualify and align separate camera, LiDAR, and infrared
   measurements/features before central tiger classification. Fusion may produce
   unclassified object hypotheses; tiger/non-tiger decisions belong to the
   classifier. The complete pipeline shall demonstrate the required detection
   performance over the validated scenarios. Sensor diversity alone is not
   evidence of independence or improved detection performance.

Algorithm Requirements
======================

.. req:: Detection Algorithm
   :id: TDS_ALG_001
   :status: open
   :tags: algorithm;detection
   :safety_level: B
   :refines: TDS_SAF_002;TDS_SEN_004

   The system shall classify detected objects as tiger or non-tiger,
   meeting ``P_fn_close``, ``P_fn_mid``, and ``P_encounter_detection``.

.. req:: Classification Latency
   :id: TDS_ALG_002
   :status: open
   :tags: algorithm;performance
   :safety_level: B
   :refines: TDS_ALG_001

   Classification shall complete within ``T_classification`` of sensor
   data acquisition.

   Latency reduces effective warning time — it is part of the overall
   time budget derived from ``D_detection_range`` / ``V_tiger_max``.

.. req:: False Positive Rate
   :id: TDS_ALG_003
   :status: open
   :tags: algorithm;performance;availability
   :safety_level: QM
   :refines: TDS_ALG_001

   False positives shall not exceed ``N_fp_max`` per operational hour.

   False alarms do not directly cause harm, but an excessive rate leads to
   alarm fatigue, which can indirectly defeat the warning function.

.. req:: Detection Confidence Output
   :id: TDS_ALG_004
   :status: open
   :tags: algorithm;output
   :safety_level: B
   :refines: TDS_ALG_001

   Upon detection, the system shall output: detection flag, confidence
   level, estimated bearing, and estimated distance.

   Direction and distance are needed for effective evasive action.

Warning Requirements
====================

.. req:: Warning Activation Latency
   :id: TDS_WRN_001
   :status: open
   :tags: warning;activation
   :safety_level: B
   :refines: TDS_ALG_001

   Upon detection, audible and visual warnings shall activate within
   ``T_warning``.

.. req:: Audible Warning — Minimum Level
   :id: TDS_WRN_002
   :status: open
   :tags: warning;sound
   :safety_level: B
   :refines: TDS_WRN_001

   The alarm shall be at least ``L_alarm_min`` at 1 m, and at least 15 dB
   above ambient noise.

   Too quiet means personnel won't hear the warning.

.. req:: Visual Warning Display
   :id: TDS_WRN_003
   :status: open
   :tags: warning;display
   :safety_level: B
   :refines: TDS_WRN_001

   The display shall show a tiger warning with estimated direction and
   distance. Without direction info, personnel may move toward the tiger.

.. req:: Warning Deactivation
   :id: TDS_WRN_004
   :status: open
   :tags: warning;deactivation
   :safety_level: QM
   :refines: TDS_WRN_001

   Warnings shall deactivate after ``T_warning_timeout`` without a
   detection event, or on transition to idle.

.. req:: Audible Warning — Maximum Level
   :id: TDS_WRN_005
   :status: open
   :tags: warning;sound;hearing-protection
   :safety_level: B
   :refines: TDS_WRN_001

   The alarm shall not exceed ``L_alarm_max`` at 1 m. Combined alarm +
   ambient shall not exceed 110 dB(A) at the nearest person.

   An excessively loud alarm causes hearing damage — the system must not
   introduce a new hazard.

Traceability
============

.. needtable::
   :style: table
   :columns: id;title;status;safety_level;refines;originating_task

.. needflow::
   :filter: id.startswith("TDS")
   :link_types: refines


Monitoring and Capability Requirements
======================================

.. req:: Unavailable Detection Indication
   :id: TDS_SAF_006
   :status: open
   :tags: safety;state
   :safety_level: B
   :refines: TDS_SAF_001

   When startup fails, a required sensor channel is unavailable, an internal
   fault prevents reliable operation, or operating conditions are outside
   validated limits, the system shall enter degraded state and display SYSTEM
   NOT OPERATIONAL with a reason and a distinct periodic acoustic indication.
   Respond within T_warning after detection; fault detection plus response
   shall remain within FTT. Degraded operation is not credited as meeting
   normal detection requirements.

.. req:: Sensor Channel Health and Capability Monitoring
   :id: TDS_SEN_005
   :status: open
   :tags: sensor;monitoring
   :safety_level: B
   :refines: TDS_SAF_001

   Monitor RGB, infrared and lidar channels independently. Reject missing,
   stale, uninitialized or invalid measurements and unknown/stale capability
   reports. Detect a required-channel loss within T_sensor_degradation and
   request the unavailable indication. All three channels are required for the
   currently specified detection performance; monitoring and acquisition shall
   continue during startup and degraded operation to support qualification and
   recovery.

.. req:: Separate Visible and Thermal Channels
   :id: TDS_SEN_006
   :status: open
   :tags: sensor;architecture
   :safety_level: B
   :refines: TDS_SAF_001

   Provide distinct acquisition and status interfaces for visible RGB and
   thermal LWIR sensing. Do not substitute visible-camera status for infrared
   status. Record source modality, calibration assumptions, timestamps and the
   scope of each capability estimate. Embedded obstruction detection or object
   classification is not assumed unless explicitly specified and validated for
   the selected sensor.

.. req:: Thermal-Assisted Detection of Camouflaged Tigers
   :id: TDS_SEN_007
   :status: open
   :tags: sensor;thermal;fusion;SOTIF
   :safety_level: B
   :refines: TDS_SAF_002;TDS_SAF_003;TDS_SAF_004;TDS_SEN_003;TDS_SEN_004
   :originating_task: SOTIF_RT_001
   :verification_method: analysis;test

   During operation, the system shall qualify and align LWIR observations with
   RGB and lidar observations, and evaluate the combined evidence before
   classifying a camouflaged or partly concealed target as tiger or non-tiger.
   Within the specified operating envelope, the complete chain shall meet
   ``P_fn_close``, ``P_fn_mid`` and ``P_encounter_detection`` and the specified
   detection-to-warning timing, including the camouflage and partial-concealment
   scenarios identified by SOTIF Case C1.

   Qualification shall reject stale or invalid thermal observations. The
   validated operating envelope shall state the minimum exposed target area,
   spatial resolution and target/background thermal contrast for which this
   measure is credited. Thermal sensing shall not be credited with seeing
   through opaque cover. When observable evidence indicates insufficient
   sensing capability, the system shall issue the unavailable indication
   specified by :need:`TDS_SAF_006`.

   Origin: completed runtime measure ``SOTIF_RT_001``, raised by SOTIF Case C1
   after assessing the original RGB-plus-lidar configuration. Compare the original and
   updated sensing chains using independent scenarios, including false-alarm
   checks and the low-thermal-contrast limitation assessed in follow-up Case C2.
   Completion of the runtime measure does not establish residual-risk acceptance.

.. req:: Operating Condition Monitoring
   :id: TDS_ODD_001
   :status: open
   :tags: ODD;monitoring
   :safety_level: B
   :refines: TDS_SAF_001

   Evaluate the defined operating conditions using sensor observations and
   ambient information. Identify observable excursions within T_odd_violation.
   Unknown or insufficient evidence shall not be interpreted as confirmation of
   acceptable conditions. Document the validated observable conditions and
   residual monitor limitations.

.. req:: Operating Condition Violation Response
   :id: TDS_ODD_002
   :status: open
   :tags: ODD;warning
   :safety_level: B
   :refines: TDS_SAF_001

   On an identified operating-condition violation, enter degraded state and
   identify the limiting condition to the operator using the unavailable
   indication, distinct from a tiger warning.

.. req:: Qualified Recovery
   :id: TDS_ODD_003
   :status: open
   :tags: ODD;recovery
   :safety_level: B
   :refines: TDS_SAF_001

   Return from degraded to running only after operating conditions and all
   required channel statuses are valid, fresh and stable for T_recovery_stable.
   Continue monitoring while degraded. Do not recover merely because a fault
   flag was cleared or an estimate is unknown.

.. req:: Rain Limitation Monitoring
   :id: TDS_ODD_004
   :status: open
   :tags: ODD;rain
   :safety_level: B
   :refines: TDS_SAF_001

   Assess heavy-rain effects using lidar attenuation and image-quality evidence
   together with available ambient information. Validate rain thresholds and
   detection time over representative scenarios. Do not assume that all rain-
   induced limitations are observable.

.. req:: Visible Channel Saturation Monitoring
   :id: TDS_ODD_005
   :status: open
   :tags: ODD;light
   :safety_level: B
   :refines: TDS_SAF_001

   Assess sustained visible-channel saturation and the affected usable field of
   view. Request degraded operation when the validated operating boundary is
   exceeded. Keep visible-channel glare estimates distinct from infrared-
   channel contrast and calibration estimates.

.. req:: Sensor Obstruction Assessment
   :id: TDS_ODD_006
   :status: open
   :tags: ODD;obstruction
   :safety_level: B
   :refines: TDS_SAF_001

   Estimate obstruction separately for RGB, infrared and lidar using modality-
   appropriate image/point-cloud analysis and available device diagnostics
   within T_sensor_degradation. Report estimate validity, severity and
   timestamp. Distinguish unknown estimates from a clear aperture. Validate
   coverage; a uniform thermal scene must not automatically be classified as a
   blocked sensor.

.. req:: Daytime Detection Performance
   :id: TDS_ENV_001
   :status: open
   :tags: environment;day
   :safety_level: B
   :refines: TDS_SAF_001

   Meet the stated detection performance in the specified daytime conditions
   using qualified sensor inputs and the complete fusion/classification
   pipeline.

.. req:: Visible Channel Glare Robustness
   :id: TDS_ENV_002
   :status: open
   :tags: environment;glare
   :safety_level: B
   :refines: TDS_SAF_001

   Evaluate daytime glare and visible-image saturation, complementary modality
   contribution and any resulting operating restriction. Validate both
   detection performance and the capability-monitor response.

.. req:: Nighttime and Thermal Contrast Performance
   :id: TDS_ENV_003
   :status: open
   :tags: environment;night
   :safety_level: B
   :refines: TDS_SAF_001

   Meet the stated nighttime detection performance using thermal and lidar
   information with qualified inputs. Include low target-background contrast
   and thermal crossover scenarios; darkness does not imply adequate thermal
   contrast.

.. req:: Rain and Visibility Performance
   :id: TDS_ENV_004
   :status: open
   :tags: environment;rain
   :safety_level: B
   :refines: TDS_SAF_001

   Validate detection within the specified rain and visibility envelope.
   Outside that envelope provide an unavailable indication rather than
   asserting full detection performance.

.. req:: Condition-Dependent Sensor Contribution
   :id: TDS_ENV_005
   :status: open
   :tags: environment;fusion
   :safety_level: B
   :refines: TDS_SAF_001

   Specify sensor contribution and weighting by operating condition. The
   current baseline still requires all three channels to be qualified; reduced-
   sensor modes require their own validated performance requirements before
   being credited.
