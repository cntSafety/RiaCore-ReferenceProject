#!/usr/bin/env python3
"""Generate Tiger Detection ARXML data for testing.

The lists in this file define the test architecture and the generator writes a
split AUTOSAR_00046 project.

RGB, thermal infrared, and lidar have separate acquisition and capability reports.
The acquisition SWCs include host-side channel-quality assessment; embedded
blockage or object detection is not assumed. Fusion produces aligned data and
unclassified object hypotheses. TigerDetectionApp owns tiger classification,
temporal confirmation, and operational state. DESC notes hold SW
requirement allocations. System requirement links remain in the SW RST
requirements' satisfies attributes.

Usage:
    python3 -m pip install autosar-data
    python3 generate_arxml.py --overwrite
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import uuid
from pathlib import Path

from autosar_data import AutosarModel, AutosarVersion, Element


PROJECT_DIRECTORY = Path(__file__).resolve().parent
DEFAULT_OUTPUT = PROJECT_DIRECTORY / "arxml-from-scratch"
UUID_NAMESPACE = uuid.UUID("1863ac5f-9ca7-5d3b-8e91-6661399014de")

# This is the test-model definition. Extend these lists to add types,
# interfaces, components, or connections.
IMPLEMENTATION_TYPES = (
    "boolean",
    "uint8",
    "uint16",
    "uint32",
    "sint32",
    "float32",
)

INTERFACES = {
    "SRI_LightLevel": (("illuminanceLux", "float32"),),
    "SRI_RgbIn": (("rgbFrameId", "uint32"), ("rgbTimestampMs", "uint32")),
    "SRI_RGBFrameReady": (("rgbFrameId", "sint32"), ("rgbTimestampMs", "uint32")),
    "SRI_IRFrameReady": (("irFrameId", "sint32"), ("irTimestampMs", "uint32")),
    "SRI_AmbientTemp": (("temperatureDegC", "float32"), ("humidityPercent", "float32")),
    "SRI_FusedDataReady": (("fusedDataId", "uint32"), ("syncTimestampMs", "uint32")),
    "SRI_DetectionResult": (
        ("tigerDetected", "boolean"),
        ("confidence", "float32"),
        ("bboxX", "uint32"),
        ("bboxY", "uint32"),
        ("bboxW", "uint32"),
        ("bboxH", "uint32"),
        ("timestampMs", "uint32"),
        ("bearingDeg", "float32"),
        ("distanceM", "float32"),
        ("resultValid", "boolean"),
    ),
    "SRI_WarningCommand": (
        ("active", "boolean"),
        ("severity", "uint8"),
        ("durationSec", "float32"),
    ),
    # Feedback from the detector back into fusion: a predicted region of
    # interest plus a track identity, so fusion can prioritize/weight that
    # region on the next cycle (temporal instance banking / ROI feedback).
    "SRI_TrackingHint": (
        ("roiValid", "boolean"),
        ("roiCenterX", "uint32"),
        ("roiCenterY", "uint32"),
        ("roiWidth", "uint32"),
        ("roiHeight", "uint32"),
        ("trackConfidence", "float32"),
        ("lastDetectionId", "uint32"),
    ),
    # ── Layered perception interfaces ────────────────────────────────────────
    # The interfaces below organise the sensor->fusion boundary into three
    # abstraction levels: per-sensor measurements (RGB / LWIR frames and lidar
    # scan summaries), channel capability (STATUS), and the fused,
    # sensor-agnostic unclassified OBJECT hypotheses produced by fusion.
    #
    # Camera self-representation: how healthy the camera path is this cycle.
    # A degraded/blocked camera is the classic source of a perception
    # insufficiency, so this gives that concern a real interface to attach to.
    "SRI_CameraStatus": (
        ("statusValid", "boolean"),   # false means unknown, not healthy
        ("statusTimestampMs", "uint32"),
        ("dataValid", "boolean"),     # acquisition validity, not recognition coverage
        ("blockageEstimateValid", "boolean"),
        ("blockageLevel", "float32"),   # 0.0 clear … 1.0 fully blocked
        ("degraded", "boolean"),
        ("fovValid", "boolean"),        # field-of-view within spec
        ("latencyMs", "uint16"),
    ),
    # Separate LWIR channel. These are software estimates plus device diagnostics,
    # not a promise that every infrared camera supplies a built-in detector.
    "SRI_InfraredStatus": (
        ("statusValid", "boolean"),
        ("statusTimestampMs", "uint32"),
        ("dataValid", "boolean"),
        ("blockageEstimateValid", "boolean"),
        ("blockageLevel", "float32"),
        ("degraded", "boolean"),
        ("fovValid", "boolean"),
        ("calibrationValid", "boolean"),
        ("contrastEstimateValid", "boolean"),
        ("contrastAdequate", "boolean"),
        ("latencyMs", "uint16"),
    ),
    # Lidar detection level: a summary of the current scan. Scalar fields stand
    # in for the primary/aggregated detection of the scan (a demo simplification
    # of what would be a per-detection list).
    "SRI_LidarScan": (
        ("scanId", "uint32"),
        ("scanTimestampMs", "uint32"),
        ("pointCount", "uint32"),
        ("nearestRangeM", "float32"),
        ("nearestAzimuthDeg", "float32"),
        ("nearestElevationDeg", "float32"),
        ("meanIntensity", "float32"),   # reflectivity
        ("existenceProb", "float32"),   # data qualifier for the detection
        ("rangeStatus", "uint8"),
    ),
    # Lidar self-representation.
    "SRI_LidarStatus": (
        ("statusValid", "boolean"),
        ("statusTimestampMs", "uint32"),
        ("dataValid", "boolean"),
        ("blockageEstimateValid", "boolean"),
        ("blockageLevel", "float32"),
        ("degraded", "boolean"),
        ("pointDensityOk", "boolean"),
        ("fovValid", "boolean"),
        ("latencyMs", "uint16"),
    ),
    # Object level: the fused object list the fusion unit hands to the
    # application. objectCount conveys the list length; the remaining scalar
    # fields describe the primary fused object (kinematics, dimensions,
    # and its existence probability) in the fusion reference
    # frame (a demo simplification of a per-object list).
    "SRI_ObjectList": (
        ("cycleId", "uint32"),
        ("objectCount", "uint16"),
        ("objectId", "uint32"),
        ("posX_m", "float32"),
        ("posY_m", "float32"),
        ("posZ_m", "float32"),
        ("velX_mps", "float32"),
        ("velY_mps", "float32"),
        ("yaw_deg", "float32"),
        ("length_m", "float32"),
        ("width_m", "float32"),
        ("height_m", "float32"),
        ("existenceProb", "float32"),
        ("measTimestampMs", "uint32"),
    ),
    "SRI_PerceptionCapability": (
        ("statusValid", "boolean"),
        ("detectionAvailable", "boolean"),
        ("oddWithinLimits", "boolean"),
        ("reasonCode", "uint8"),
        ("statusTimestampMs", "uint32"),
    ),
    "SRI_ControlCommand": (("command", "uint8"), ("sequenceCounter", "uint32")),
    "SRI_SystemStatus": (
        ("state", "uint8"),  # 0 idle, 1 starting, 2 running, 3 degraded
        ("detectionAvailable", "boolean"),
        ("reasonCode", "uint8"),
        ("statusTimestampMs", "uint32"),
    ),
}

COMPONENTS = {
    "CameraAcquisition": {
        "provides": (
            ("rgbDataOut", "SRI_RGBFrameReady"),
            # Camera self-representation (blockage / degradation / FoV validity).
            ("cameraStatusOut", "SRI_CameraStatus"),
        ),
        "requires": (),
    },
    "InfraredAcquisition": {
        "provides": (
            ("irDataOut", "SRI_IRFrameReady"),
            ("infraredStatusOut", "SRI_InfraredStatus"),
        ),
        "requires": (),
    },
    # Dedicated lidar sensor path (detection level + self-representation),
    # mirroring the LidarSensor already present in the system-design stage.
    "LidarAcquisition": {
        "provides": (
            ("lidarScanOut", "SRI_LidarScan"),
            ("lidarStatusOut", "SRI_LidarStatus"),
        ),
        "requires": (),
    },
    "AmbientSensorsDriver": {
        "provides": (("lightDataOut", "SRI_LightLevel"), ("tempDataOut", "SRI_AmbientTemp")),
        "requires": (("lightHWIn", "SRI_LightLevel"), ("tempHWIn", "SRI_AmbientTemp")),
    },
    "Fusion": {
        "provides": (
            ("fusedOut", "SRI_FusedDataReady"),
            # Object-level output: the fused object list handed to the app.
            ("objectListOut", "SRI_ObjectList"),
            ("capabilityOut", "SRI_PerceptionCapability"),
        ),
        "requires": (
            ("rgbIn", "SRI_RGBFrameReady"),
            ("irIn", "SRI_IRFrameReady"),
            ("lidarIn", "SRI_LidarScan"),
            ("lightIn", "SRI_LightLevel"),
            ("tempIn", "SRI_AmbientTemp"),
            ("cameraStatusIn", "SRI_CameraStatus"),
            ("infraredStatusIn", "SRI_InfraredStatus"),
            ("lidarStatusIn", "SRI_LidarStatus"),
            ("trackingHintIn", "SRI_TrackingHint"),
        ),
    },
    "TigerDetectionApp": {
        "provides": (
            ("detectionOut", "SRI_DetectionResult"),
            ("trackingHintOut", "SRI_TrackingHint"),
            ("systemStatusOut", "SRI_SystemStatus"),
        ),
        "requires": (
            ("fusedDataIn", "SRI_FusedDataReady"),
            ("objectListIn", "SRI_ObjectList"),
            ("capabilityIn", "SRI_PerceptionCapability"),
            ("controlIn", "SRI_ControlCommand"),
        ),
    },
    "WarningManager": {
        "provides": (("acousticOut", "SRI_WarningCommand"), ("visualOut", "SRI_WarningCommand")),
        "requires": (("detectionIn", "SRI_DetectionResult"), ("systemStatusIn", "SRI_SystemStatus")),
    },
    "OperatorInterface": {
        "provides": (("controlOut", "SRI_ControlCommand"),),
        "requires": (("systemStatusIn", "SRI_SystemStatus"),),
    },
}

# Software requirement allocations.
# Only SW requirement IDs belong here; their system parents are maintained by
# :satisfies: in 3-sw-req/requirements/swRequirements.rst.
COMPONENT_REQUIREMENTS = {
    "CameraAcquisition": ("SWREQ_SEN_001", "SWREQ_SEN_005", "SWREQ_SEN_006", "SWREQ_ODD_005", "SWREQ_ODD_006"),
    "InfraredAcquisition": ("SWREQ_SEN_003", "SWREQ_SEN_005", "SWREQ_SEN_006", "SWREQ_ODD_006", "SWREQ_SEN_007"),
    "LidarAcquisition": ("SWREQ_SEN_002", "SWREQ_SEN_005", "SWREQ_SEN_006", "SWREQ_ODD_004", "SWREQ_ODD_006"),
    "AmbientSensorsDriver": ("SWREQ_ODD_001",),
    "Fusion": ("SWREQ_SEN_004", "SWREQ_SEN_005", "SWREQ_SEN_006", "SWREQ_ALG_002",
                               "SWREQ_ODD_001", "SWREQ_ODD_004", "SWREQ_ODD_005", "SWREQ_ODD_006",
                               "SWREQ_ENV_001", "SWREQ_ENV_002", "SWREQ_ENV_004", "SWREQ_SEN_007"),
    "TigerDetectionApp": ("SWREQ_ALG_001", "SWREQ_ALG_002", "SWREQ_ALG_003", "SWREQ_ALG_004", "SWREQ_ALG_005",
                          "SWREQ_SM_001", "SWREQ_SM_002", "SWREQ_SM_003", "SWREQ_SM_004", "SWREQ_SM_005",
                          "SWREQ_ODD_002", "SWREQ_ODD_003", "SWREQ_ENV_001", "SWREQ_ENV_002", "SWREQ_ENV_003", "SWREQ_ENV_004", "SWREQ_SEN_007"),
    "WarningManager": ("SWREQ_WRN_001", "SWREQ_WRN_002", "SWREQ_WRN_003", "SWREQ_WRN_004", "SWREQ_WRN_005",
                       "SWREQ_SM_005", "SWREQ_ODD_002"),
    "OperatorInterface": ("SWREQ_SM_002", "SWREQ_SM_003", "SWREQ_SM_004", "SWREQ_SM_005", "SWREQ_ODD_002"),
}

# An interface supports these requirements through its data contract. Providing
# or consuming it alone does not fulfill the complete behavioral requirement.
INTERFACE_REQUIREMENTS = {
    "SRI_LightLevel": ("SWREQ_ODD_001",),
    "SRI_RgbIn": ("SWREQ_SEN_001",),
    "SRI_RGBFrameReady": ("SWREQ_SEN_001", "SWREQ_SEN_004"),
    "SRI_IRFrameReady": ("SWREQ_SEN_003", "SWREQ_SEN_004", "SWREQ_SEN_007"),
    "SRI_AmbientTemp": ("SWREQ_ODD_001",),
    "SRI_FusedDataReady": ("SWREQ_SEN_004", "SWREQ_ALG_001", "SWREQ_SEN_007"),
    "SRI_DetectionResult": ("SWREQ_ALG_005", "SWREQ_WRN_001", "SWREQ_WRN_004", "SWREQ_SEN_007"),
    "SRI_WarningCommand": ("SWREQ_WRN_001", "SWREQ_WRN_002", "SWREQ_WRN_003", "SWREQ_WRN_004", "SWREQ_WRN_005",
                           "SWREQ_SM_005", "SWREQ_ODD_002"),
    "SRI_TrackingHint": ("SWREQ_ALG_004", "SWREQ_SEN_004"),
    "SRI_CameraStatus": ("SWREQ_SEN_005", "SWREQ_SEN_006", "SWREQ_ODD_005", "SWREQ_ODD_006"),
    "SRI_InfraredStatus": ("SWREQ_SEN_005", "SWREQ_SEN_006", "SWREQ_ODD_006", "SWREQ_SEN_007"),
    "SRI_LidarScan": ("SWREQ_SEN_002", "SWREQ_SEN_004"),
    "SRI_LidarStatus": ("SWREQ_SEN_005", "SWREQ_SEN_006", "SWREQ_ODD_004", "SWREQ_ODD_006"),
    "SRI_ObjectList": ("SWREQ_SEN_004", "SWREQ_ALG_001", "SWREQ_SEN_007"),
    "SRI_PerceptionCapability": ("SWREQ_SEN_005", "SWREQ_ODD_001", "SWREQ_ODD_003", "SWREQ_SM_005", "SWREQ_SEN_007"),
    "SRI_ControlCommand": ("SWREQ_SM_002", "SWREQ_SM_003"),
    "SRI_SystemStatus": ("SWREQ_SM_004", "SWREQ_SM_005", "SWREQ_ODD_002", "SWREQ_SEN_007"),
}

CONNECTIONS = (
    ("CameraAcquisition", "rgbDataOut", "Fusion", "rgbIn"),
    ("InfraredAcquisition", "irDataOut", "Fusion", "irIn"),
    ("InfraredAcquisition", "infraredStatusOut", "Fusion", "infraredStatusIn"),
    # Camera status into fusion (health-aware fusion / degradation handling).
    ("CameraAcquisition", "cameraStatusOut", "Fusion", "cameraStatusIn"),
    # Lidar detection + status into fusion — camera and lidar form a diverse
    # redundant pair at the sensor->fusion boundary.
    ("LidarAcquisition", "lidarScanOut", "Fusion", "lidarIn"),
    ("LidarAcquisition", "lidarStatusOut", "Fusion", "lidarStatusIn"),
    ("AmbientSensorsDriver", "lightDataOut", "Fusion", "lightIn"),
    ("AmbientSensorsDriver", "tempDataOut", "Fusion", "tempIn"),
    ("Fusion", "fusedOut", "TigerDetectionApp", "fusedDataIn"),
    # Object-level output into the application.
    ("Fusion", "objectListOut", "TigerDetectionApp", "objectListIn"),
    ("Fusion", "capabilityOut", "TigerDetectionApp", "capabilityIn"),
    ("OperatorInterface", "controlOut", "TigerDetectionApp", "controlIn"),
    ("TigerDetectionApp", "systemStatusOut", "OperatorInterface", "systemStatusIn"),
    ("TigerDetectionApp", "systemStatusOut", "WarningManager", "systemStatusIn"),
    ("TigerDetectionApp", "detectionOut", "WarningManager", "detectionIn"),
    # Feedback edge: detector's tracking hint flows back into fusion, closing
    # the loop Fusion <-> TigerDetectionApp.
    ("TigerDetectionApp", "trackingHintOut", "Fusion", "trackingHintIn"),
)


def deterministic_uuid(identity: str) -> str:
    return str(uuid.uuid5(UUID_NAMESPACE, identity)).upper()


def named(parent: Element, element_name: str, short_name: str, identity: str) -> Element:
    element = parent.create_named_sub_element(element_name, short_name)
    element.set_attribute("UUID", deterministic_uuid(identity))
    return element


def reference(parent: Element, element_name: str, target: Element) -> Element:
    element = parent.create_sub_element(element_name)
    element.reference_target = target
    return element


def package(parent: Element, short_name: str, identity: str) -> Element:
    return named(parent, "AR-PACKAGE", short_name, identity)


def only_in_file(element: Element, selected_file, all_files) -> None:
    for arxml_file in all_files:
        if arxml_file != selected_file:
            element.remove_from_file(arxml_file)


def requirement_note(element: Element, requirements: tuple[str, ...]) -> None:
    paragraph = element.create_sub_element("DESC").create_sub_element("L-2")
    paragraph.set_attribute("L", "EN")
    paragraph.character_data = f"SW requirements: {', '.join(requirements)}."


def validate_requirement_allocations() -> None:
    source = (PROJECT_DIRECTORY.parent / "3-sw-req/requirements/swRequirements.rst").read_text(encoding="utf-8")
    known = set(re.findall(r"^\s*:id:\s*(SWREQ_[A-Z0-9_]+)\s*$", source, re.MULTILINE))
    for definitions, allocations in ((COMPONENTS, COMPONENT_REQUIREMENTS), (INTERFACES, INTERFACE_REQUIREMENTS)):
        if set(definitions) != set(allocations):
            raise ValueError("Requirement allocation keys do not match the architecture definition")
        for element, requirements in allocations.items():
            if not requirements or len(set(requirements)) != len(requirements) or not set(requirements) <= known:
                raise ValueError(f"Invalid SW requirement allocation for {element}: {requirements}")


def build_model(output: Path) -> AutosarModel:
    validate_requirement_allocations()
    output.mkdir(parents=True, exist_ok=True)
    model = AutosarModel()
    files = {
        "types": model.create_file(str(output / "DataTypes.arxml"), AutosarVersion.AUTOSAR_00046),
        "interfaces": model.create_file(str(output / "PortInterfaces.arxml"), AutosarVersion.AUTOSAR_00046),
        "components": model.create_file(str(output / "ComponentTypes.arxml"), AutosarVersion.AUTOSAR_00046),
        "system": model.create_file(str(output / "ECUProjects" / "System.arxml"), AutosarVersion.AUTOSAR_00046),
    }
    (output / "ECUProjects").mkdir(exist_ok=True)
    all_files = tuple(files.values())
    packages = model.root_element.create_sub_element("AR-PACKAGES")

    platform = package(packages, "AUTOSAR_Platform", "package:platform")
    type_packages = platform.create_sub_element("AR-PACKAGES")
    implementation_types = package(type_packages, "ImplementationDataTypes", "package:implementation-types")
    type_elements = implementation_types.create_sub_element("ELEMENTS")
    types: dict[str, Element] = {}
    for type_name in IMPLEMENTATION_TYPES:
        data_type = named(type_elements, "IMPLEMENTATION-DATA-TYPE", type_name, f"type:{type_name}")
        data_type.create_sub_element("CATEGORY").character_data = "VALUE"
        types[type_name] = data_type
    only_in_file(platform, files["types"], all_files)

    interface_package = package(packages, "PortInterfaces", "package:interfaces")
    interface_elements = interface_package.create_sub_element("ELEMENTS")
    interfaces: dict[str, Element] = {}
    for interface_name, data_elements in INTERFACES.items():
        interface = named(
            interface_elements,
            "SENDER-RECEIVER-INTERFACE",
            interface_name,
            f"interface:{interface_name}",
        )
        requirement_note(interface, INTERFACE_REQUIREMENTS[interface_name])
        variables = interface.create_sub_element("DATA-ELEMENTS")
        for data_element_name, type_name in data_elements:
            variable = named(
                variables,
                "VARIABLE-DATA-PROTOTYPE",
                data_element_name,
                f"interface:{interface_name}:element:{data_element_name}",
            )
            reference(variable, "TYPE-TREF", types[type_name])
        interfaces[interface_name] = interface
    only_in_file(interface_package, files["interfaces"], all_files)

    component_package = package(packages, "TigerDetectionSW", "package:tiger-detection")
    component_elements = component_package.create_sub_element("ELEMENTS")
    swcs: dict[str, Element] = {}
    ports: dict[tuple[str, str], Element] = {}
    for component_name, definition in COMPONENTS.items():
        swc = named(
            component_elements,
            "APPLICATION-SW-COMPONENT-TYPE",
            component_name,
            f"swc:{component_name}",
        )
        requirement_note(swc, COMPONENT_REQUIREMENTS[component_name])
        swc_ports = swc.create_sub_element("PORTS")
        for port_name, interface_name in definition["provides"]:
            port = named(
                swc_ports,
                "P-PORT-PROTOTYPE",
                port_name,
                f"swc:{component_name}:pport:{port_name}",
            )
            requirement_note(port, INTERFACE_REQUIREMENTS[interface_name])
            reference(port, "PROVIDED-INTERFACE-TREF", interfaces[interface_name])
            ports[(component_name, port_name)] = port
        for port_name, interface_name in definition["requires"]:
            port = named(swc_ports, "R-PORT-PROTOTYPE", port_name, f"swc:{component_name}:rport:{port_name}")
            requirement_note(port, INTERFACE_REQUIREMENTS[interface_name])
            reference(port, "REQUIRED-INTERFACE-TREF", interfaces[interface_name])
            ports[(component_name, port_name)] = port
        swcs[component_name] = swc

    composition = named(
        component_elements,
        "COMPOSITION-SW-COMPONENT-TYPE",
        "TigerDetectionComposition",
        "composition:tiger-detection",
    )
    instances: dict[str, Element] = {}
    components = composition.create_sub_element("COMPONENTS")
    for component_name, swc in swcs.items():
        instance = named(
            components,
            "SW-COMPONENT-PROTOTYPE",
            f"{component_name}_Instance",
            f"instance:{component_name}",
        )
        reference(instance, "TYPE-TREF", swc)
        instances[component_name] = instance
    connectors = composition.create_sub_element("CONNECTORS")
    for provider_component, provider_port, requester_component, requester_port in CONNECTIONS:
        connector_name = f"{provider_component}_{provider_port}_{requester_component}_{requester_port}"
        connector = named(
            connectors,
            "ASSEMBLY-SW-CONNECTOR",
            connector_name,
            f"connector:{connector_name}",
        )
        provider = connector.create_sub_element("PROVIDER-IREF")
        reference(provider, "CONTEXT-COMPONENT-REF", instances[provider_component])
        reference(provider, "TARGET-P-PORT-REF", ports[(provider_component, provider_port)])
        requester = connector.create_sub_element("REQUESTER-IREF")
        reference(requester, "CONTEXT-COMPONENT-REF", instances[requester_component])
        reference(requester, "TARGET-R-PORT-REF", ports[(requester_component, requester_port)])
    only_in_file(component_package, files["components"], all_files)

    systems = package(packages, "Systems", "package:systems")
    system_elements = systems.create_sub_element("ELEMENTS")
    system = named(system_elements, "SYSTEM", "System", "system")
    root_compositions = system.create_sub_element("ROOT-SOFTWARE-COMPOSITIONS")
    root_composition = named(
        root_compositions,
        "ROOT-SW-COMPOSITION-PROTOTYPE",
        "RootSwComposition",
        "system:root-composition",
    )
    reference(root_composition, "SOFTWARE-COMPOSITION-TREF", composition)
    only_in_file(systems, files["system"], all_files)
    return model


def generate(output: Path, overwrite: bool) -> None:
    output = output.resolve()
    if output.exists():
        if not overwrite:
            raise ValueError(f"Output already exists: {output}. Use --overwrite to replace it.")
        if not output.is_dir():
            raise ValueError(f"Output is not a directory: {output}")
        shutil.rmtree(output)
    model = build_model(output)
    model.write()

    verification = AutosarModel()
    for arxml_file in sorted(output.rglob("*.arxml")):
        _, warnings = verification.load_file(str(arxml_file), True)
        if warnings:
            raise RuntimeError(f"Validation warnings in {arxml_file}: {warnings}")
    print(
        f"Generated and strictly validated {len(verification.files)} ARXML files with "
        f"{sum(1 for _ in verification.elements_dfs)} elements in {output}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--overwrite", action="store_true")
    arguments = parser.parse_args()
    try:
        generate(arguments.output, arguments.overwrite)
    except (OSError, RuntimeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
