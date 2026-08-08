.. _sw-req-configuration:

==========================================
Sphinx-Needs Configuration Reference
==========================================

This page documents the sphinx-needs configuration used in the SW
requirements project.

Need Types
==========

.. list-table::
   :header-rows: 1
   :widths: 15 25 10 15 10

   * - Directive
     - Title
     - Prefix
     - Color
     - Style
   * - ``req``
     - SW Requirement
     - SWREQ\_
     - #C2E0F4
     - node
   * - ``test``
     - Test Case
     - TC\_
     - #DCB239
     - node

Custom Fields
=============

``safety_level``
   ASIL classification. Allowed values: QM, A, B, C, D.

``verification_method``
   How the requirement is verified (analysis, review, test, inspection).

Custom Link Types
=================

``satisfies``
   SW-requirement-to-system-requirement traceability.
   Outgoing: "satisfies" / Incoming: "is satisfied by"

``refines``
   SW-requirement-to-SW-requirement decomposition.
   Outgoing: "refines" / Incoming: "is refined by"

``verifies``
   Test-to-requirement verification.
   Outgoing: "verifies" / Incoming: "is verified by"

External Needs (Cross-Project Linking)
======================================

This project references system requirements from ``1-sys-req`` via the
``needs_external_needs`` configuration. System requirement IDs (``TDS_*``)
are available for use in ``:satisfies:`` links.

**Build order:** Always build ``1-sys-req`` first to generate its
``needs.json``, then build this project.

.. code-block:: bash

   # From qualification/ref-project/
   cd 1-sys-req && sphinx-build -b html . _build/html
   cd ../3-sw-req && sphinx-build -b html . _build/html

JSON Export (needs.json)
========================

The project is configured with ``needs_build_json = True``.
The generated ``needs.json`` can be consumed by downstream projects
(e.g. ``5-sw-design``) for further traceability.

Report
======

.. needtable::
   :style: table
   :columns: id;title;type;status;tags
