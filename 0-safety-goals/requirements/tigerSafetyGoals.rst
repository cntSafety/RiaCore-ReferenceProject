.. _tiger-safety-goals:

=======================================
Tiger Detection System - Safety Goals
=======================================

.. note::

   This is a **simplified demonstration example**, created to show the RiaCore
   round-trip: requirements → system design (SysML) → system-level safety
   analysis (RiaCore) → derived improvement tasks. It is intentionally
   incomplete and is **not** an authoritative safety specification.

Safety Goals
============

.. req:: Tiger Detection Safety Goal
   :id: TDS_SAF_001
   :status: open
   :tags: safety;safety-goal
   :safety_level: B

   The system shall detect approaching tigers and warn personnel in
   sufficient time to allow evasive action. The probability of an
   undetected encounter shall not exceed ``P_undetected_encounter``.

   
System Parameters
=================

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
