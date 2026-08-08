.. _sw-requirements:

==========================================
Tiger Detection System - SW Requirements
==========================================

.. contents:: Table of Contents
   :local:
   :depth: 2

Overview
========

These software requirements define the functional behavior of the Tiger
Detection System software. They are **solution-agnostic** — they describe
*what* the software must do, not *how* it is implemented. The mapping to a
specific software architecture (e.g. AUTOSAR SWCs) is documented in the
SW design (``5-sw-design``).

Each SW requirement traces to one or more system requirements (``TDS_*``)
via the ``:satisfies:`` link. The ASIL is inherited from the highest-rated
system requirement it satisfies.

Safe State
----------

The SW safe state mirrors the system-level safe state: **inform the operator
that tiger detection is not operational**. The software achieves this by:

1. Transitioning to degraded state
2. Commanding the HMI to display "SYSTEM NOT OPERATIONAL" with fault reason
3. Commanding the warning subsystem to emit a periodic acoustic alert
   (distinct from tiger alarm)

Any SW requirement rated ASIL B shall trigger the safe state on failure.


State Management
================

.. req:: SW State Machine
   :id: SWREQ_SM_001
   :status: open
   :tags: state-management;control
   :safety_level: B
   :satisfies: TDS_OPS_001;TDS_OPS_002;TDS_OPS_003

   The software shall implement a state machine with the states: **idle**,
   **running**, and **degraded**. The state machine governs whether the
   detection pipeline is active, inactive, or operating with reduced
   capability.

.. req:: Start Detection via UI Input
   :id: SWREQ_SM_002
   :status: open
   :tags: state-management;control;ui
   :safety_level: B
   :satisfies: TDS_OPS_001

   The software shall read a start command from the operator interface.
   Upon receiving the start command while in idle state, the software shall
   transition to running state and activate the sensor scanning pipeline
   within ``T_startup``.

   On failure to start: trigger safe state (SWREQ_SM_005).

.. req:: Stop Detection via UI Input
   :id: SWREQ_SM_003
   :status: open
   :tags: state-management;control;ui
   :safety_level: QM
   :satisfies: TDS_OPS_002

   The software shall read a stop command from the operator interface.
   Upon receiving the stop command while in running or degraded state, the
   software shall transition to idle state and deactivate the sensor
   scanning pipeline.

.. req:: State Reporting
   :id: SWREQ_SM_004
   :status: open
   :tags: state-management;status
   :safety_level: B
   :satisfies: TDS_OPS_003

   The software shall provide the current operational state (idle, running,
   or degraded) to the operator interface for display purposes. State
   changes shall be reported within 500 ms.

.. req:: Safe State Transition
   :id: SWREQ_SM_005
   :status: open
   :tags: state-management;safe-state
   :safety_level: B
   :satisfies: TDS_SAF_006

   When the software detects a condition that prevents guaranteed detection
   performance (startup failure, sensor loss, internal fault), it shall:

   a) Transition to degraded state
   b) Command the HMI to display "SYSTEM NOT OPERATIONAL" with the fault
      reason
   c) Command the warning subsystem to emit a periodic acoustic alert
      (distinct from tiger alarm)

   The safe state shall be reached within ``T_warning`` of fault detection.


Sensor Acquisition
==================

.. req:: Camera Data Acquisition
   :id: SWREQ_SEN_001
   :status: open
   :tags: sensor;camera;acquisition
   :safety_level: B
   :satisfies: TDS_SEN_001

   The software shall acquire image frames from the camera sensor at
   ≥ ``F_sensor``. Acquisition shall only occur while in running state.

   On acquisition failure: trigger safe state (SWREQ_SM_005).

.. req:: LiDAR Data Acquisition
   :id: SWREQ_SEN_002
   :status: open
   :tags: sensor;lidar;acquisition
   :safety_level: B
   :satisfies: TDS_SEN_002

   The software shall acquire 3D point-cloud data from the LiDAR sensor
   at ≥ ``F_sensor``. Acquisition shall only occur while in running state.

   On acquisition failure: trigger safe state (SWREQ_SM_005).

.. req:: Infrared Data Acquisition
   :id: SWREQ_SEN_003
   :status: open
   :tags: sensor;infrared;acquisition
   :safety_level: B
   :satisfies: TDS_SEN_003

   The software shall acquire thermal image data from the infrared sensor
   at ≥ ``F_sensor``. Acquisition shall only occur while in running state.
   The infrared channel shall be the primary detection source at night.

   On acquisition failure: trigger safe state (SWREQ_SM_005).

.. req:: Sensor Data Fusion
   :id: SWREQ_SEN_004
   :status: open
   :tags: sensor;fusion
   :safety_level: B
   :satisfies: TDS_SEN_004

   The software shall fuse data from camera, LiDAR, and infrared sensors
   into a unified detection input. The fusion shall achieve a lower
   false-negative rate than any single channel alone.

.. req:: Sensor Health Monitoring
   :id: SWREQ_SEN_005
   :status: open
   :tags: sensor;diagnostics
   :safety_level: B
   :satisfies: TDS_SEN_005

   The software shall monitor the health of each sensor channel. If any
   channel fails to deliver valid data for more than
   ``T_sensor_degradation``, the software shall trigger the safe state
   transition (SWREQ_SM_005).

   All three channels are required for specified detection performance.


Detection Algorithm
===================

.. req:: Object Classification
   :id: SWREQ_ALG_001
   :status: open
   :tags: algorithm;classification
   :safety_level: B
   :satisfies: TDS_ALG_001

   The software shall process fused sensor data and classify detected
   objects as tiger or non-tiger, meeting ``P_fn_close`` at 0–25 m and
   ``P_fn_mid`` at 25–50 m.

.. req:: Classification Latency
   :id: SWREQ_ALG_002
   :status: open
   :tags: algorithm;performance
   :safety_level: B
   :satisfies: TDS_ALG_002

   The software shall produce a classification result within
   ``T_classification`` of sensor data acquisition.

.. req:: False Positive Limitation
   :id: SWREQ_ALG_003
   :status: open
   :tags: algorithm;performance
   :safety_level: QM
   :satisfies: TDS_ALG_003

   The software shall not produce more than ``N_fp_max`` false-positive
   detection events per operational hour.

.. req:: Multi-Frame Detection
   :id: SWREQ_ALG_004
   :status: open
   :tags: algorithm;temporal
   :safety_level: B
   :satisfies: TDS_SAF_005

   The software shall implement multi-frame temporal fusion to ensure
   detection within ``T_detection_window`` with probability
   ≥ ``P_encounter_detection``, even if individual frames miss.

.. req:: Detection Output
   :id: SWREQ_ALG_005
   :status: open
   :tags: algorithm;output
   :safety_level: B
   :satisfies: TDS_ALG_004

   Upon positive classification, the software shall output: detection flag,
   confidence level, estimated bearing, and estimated distance.


Warning Management
==================

.. req:: Warning Trigger
   :id: SWREQ_WRN_001
   :status: open
   :tags: warning;activation
   :safety_level: B
   :satisfies: TDS_WRN_001

   Upon receiving a positive detection event, the software shall activate
   both audible and visual warning outputs within ``T_warning``.

.. req:: Audible Warning Output — Minimum
   :id: SWREQ_WRN_002
   :status: open
   :tags: warning;sound
   :safety_level: B
   :satisfies: TDS_WRN_002

   The software shall drive the audible alarm hardware to produce an alarm
   signal of at least ``L_alarm_min`` at 1 m, and at least 15 dB above
   ambient noise.

.. req:: Audible Warning Output — Maximum
   :id: SWREQ_WRN_003
   :status: open
   :tags: warning;sound;hearing-protection
   :safety_level: B
   :satisfies: TDS_WRN_005

   The software shall limit the audible alarm output to not exceed
   ``L_alarm_max`` at 1 m under any condition. The system must not
   introduce a hearing damage hazard.

.. req:: Visual Warning Output
   :id: SWREQ_WRN_004
   :status: open
   :tags: warning;display
   :safety_level: B
   :satisfies: TDS_WRN_003

   The software shall output a warning message to the display including
   the estimated direction and approximate distance of the detected tiger.

.. req:: Warning Deactivation
   :id: SWREQ_WRN_005
   :status: open
   :tags: warning;deactivation
   :safety_level: QM
   :satisfies: TDS_WRN_004

   The software shall deactivate warnings when no positive detection event
   has been received for ``T_warning_timeout``, or when the system
   transitions to idle state.


ODD Monitoring
==============

.. req:: Environmental Condition Monitoring
   :id: SWREQ_ODD_001
   :status: open
   :tags: ODD;monitoring
   :safety_level: B
   :satisfies: TDS_ODD_001

   The software shall continuously evaluate sensor data to determine
   whether operating conditions are within the ODD. Violation shall be
   detected within ``T_odd_violation``.

   On ODD violation: trigger safe state (SWREQ_SM_005).

.. req:: ODD Violation Response
   :id: SWREQ_ODD_002
   :status: open
   :tags: ODD;monitoring;warning
   :safety_level: B
   :satisfies: TDS_ODD_002

   On ODD violation, the software shall transition to degraded state,
   issue a distinct ODD warning (not confused with tiger alarm), and
   indicate which condition is out of limits.

.. req:: ODD Recovery
   :id: SWREQ_ODD_003
   :status: open
   :tags: ODD;monitoring;recovery
   :safety_level: B
   :satisfies: TDS_ODD_003

   When conditions return within ODD and remain stable for ≥ 10 s, the
   software shall return to running state and clear the ODD warning.

.. req:: Rain Intensity Detection
   :id: SWREQ_ODD_004
   :status: open
   :tags: ODD;weather
   :safety_level: B
   :satisfies: TDS_ODD_004

   The software shall detect heavy rain using sensor data analysis (LiDAR
   attenuation patterns, camera image degradation) without relying solely
   on external weather data.

.. req:: Blinding Light Detection
   :id: SWREQ_ODD_005
   :status: open
   :tags: ODD;light
   :safety_level: B
   :satisfies: TDS_ODD_005

   The software shall detect sustained sensor saturation from artificial
   light sources and declare an ODD violation when a significant portion
   of the field of view is affected.

.. req:: Sensor Obstruction Detection
   :id: SWREQ_ODD_006
   :status: open
   :tags: ODD;obstruction
   :safety_level: B
   :satisfies: TDS_ODD_006

   The software shall detect physical obstruction of sensor apertures
   within ``T_sensor_degradation`` using image/point-cloud analysis.


Environmental Robustness
========================

.. req:: Daytime Operation
   :id: SWREQ_ENV_001
   :status: open
   :tags: environment;daytime
   :safety_level: B
   :satisfies: TDS_ENV_001;TDS_ENV_002

   The software detection pipeline shall meet ``P_fn_close`` and
   ``P_fn_mid`` under daytime conditions (cloudy and sunny). When camera
   is saturated by glare, the software shall rely on LiDAR and IR.

.. req:: Nighttime Operation
   :id: SWREQ_ENV_002
   :status: open
   :tags: environment;nighttime
   :safety_level: B
   :satisfies: TDS_ENV_003

   The software detection pipeline shall meet ``P_fn_close`` and
   ``P_fn_mid`` at night, using IR as primary and LiDAR as secondary
   modality.

.. req:: Partial Occlusion Handling
   :id: SWREQ_ENV_003
   :status: open
   :tags: environment;occlusion
   :safety_level: B
   :satisfies: TDS_ENV_004

   The software shall detect tigers partially occluded by vegetation
   (up to 50 % body occlusion) within the specified false negative rates.

.. req:: Rain Operation
   :id: SWREQ_ENV_004
   :status: open
   :tags: environment;weather
   :safety_level: B
   :satisfies: TDS_ENV_005

   The software shall meet ``P_fn_close`` and ``P_fn_mid`` during light
   to moderate rain by relying on multi-sensor fusion.


Traceability
============

SW Requirements → System Requirements
--------------------------------------

.. needtable::
   :filter: type == "req"
   :style: table
   :columns: id;title;status;safety_level;satisfies

Full Traceability Flow
----------------------

.. needflow::
   :filter: id.startswith("SWREQ") or is_external
   :link_types: satisfies
