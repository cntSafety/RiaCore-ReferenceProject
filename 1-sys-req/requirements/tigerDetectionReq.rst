.. _tiger-detection-requirements:

=======================================
Tiger Detection System - Requirements
=======================================

.. note::

   This is a **simplified demonstration example**, created to show the RiaCore
   round-trip: requirements → system design (SysML) → system-level safety
   analysis (RiaCore) → derived improvement tasks. It is intentionally
   incomplete and is **not** an authoritative safety specification. The safety
   analysis does not rewrite these requirements directly; instead it raises
   improvement tasks that define the next requirements update.

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

This document specifies the **initial** system — a first, deliberately naive
version that detects and warns. It does not yet include monitoring of its own
health or of its operating conditions; those improvements are captured as
tasks by the safety analysis and fed back as a later requirements update.

Safety Assumptions (Safety Element out of Context)
==================================================

The system is specified as a **Safety Element out of Context (SEooC)**. Instead
of deriving the safety level from a full hazard analysis and risk assessment,
the following assumptions are made and **shall be confirmed by the integrator**
who deploys the system in a concrete operational context:

- **Assumed safety level:** ASIL B. This is an *assumed* safety requirement,
  to be confirmed by the integrator against the actual operational context.
- **Assumed Fault Tolerance Time (FTT):** ``FTT`` = 1.0 s (example) — the
  maximum time the system may take, after a fault occurs, before it reaches the
  safe state and issues the corresponding indication.
- **Assumed safe state:** the operator is informed that tiger detection is not
  operational and assumes manual vigilance. The system is a warning system with
  no actuator, so there is no physical safe position to command.
- **The parameter values below are example values.** They are chosen only to
  give a concrete discussion baseline for this imaginary example. They are
  loosely inspired by automotive emergency-braking (AEB) literature — detection
  ranges, latencies, and reaction times — and are **not validated**. AEB is a
  good analogy: it helps the driver in most cases but is not perfect, so there
  are situations where it may not react in time. A real integrator would
  confirm every value for the actual operational context.

Parameters
==========

The following parameters are used throughout this specification. The values are
**example values** giving a discussion baseline for this imaginary example
(see the SEooC assumptions above) — not validated numbers.

.. list-table:: System Parameters
   :header-rows: 1
   :widths: 22 20 58

   * - Parameter
     - Example value
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
   :safety_level: B
   :refines: TDS_SAF_001;TDS_SAF_002

   The per-frame missed-detection rate for adult tigers at 0–25 m shall not
   exceed ``P_fn_close`` under all specified operating conditions.

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

   The system shall indicate its state (idle, running) to the operator at
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
   at ≥ ``F_sensor`` fps, capable of identifying tigers up to
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

   The system shall include an infrared sensor for thermal detection up to
   ``D_detection_range`` at ≥ ``F_sensor`` fps. Primary modality at night.

.. req:: Sensor Fusion
   :id: TDS_SEN_004
   :status: open
   :tags: sensor;fusion
   :safety_level: B
   :refines: TDS_SEN_001;TDS_SEN_002;TDS_SEN_003

   The system shall fuse camera, LiDAR, and infrared data. The fused
   pipeline shall achieve a lower missed-detection rate than any single
   sensor alone.

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
   :columns: id;title;status;safety_level;refines

.. needflow::
   :filter: id.startswith("TDS")
   :link_types: refines
