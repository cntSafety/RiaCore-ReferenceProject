"""
tiger.py - Timing / kinematics sanity check for the Tiger Detection System.

This is a small *discussion-baseline* simulation, not a validated tool. It
exists to give the imaginary Tiger Detection System example some concrete,
defensible numbers to argue about. It answers two questions:

  1. Given a tiger approaching at its sprint speed, how large must the
     detection range be to leave personnel a target reaction time (e.g. 3 s)?
  2. If we instead fix the detection range, how much reaction time do we
     actually get?

The example values are loosely inspired by automotive emergency-braking (AEB)
literature and adapted to a tiger:

  - Pedestrian-AEB sensors are typically effective at ~25-50 m; going beyond
    ~50 m adds little benefit for slow targets. A tiger sprints far faster than
    a pedestrian walks, so it needs *more* range for the same warning time.
  - Human reaction to a surprise event is ~1.5 s; transportation design uses
    larger margins. We treat the reaction time we want to *give* people as a
    tunable target (default 3 s).
  - AEB helps in most cases but is not perfect - there are situations where it
    does not react in time. The same is true here, which is exactly why the
    system is a *warning* aid and the operator keeps manual vigilance.

For fun, it also includes an acoustic-deterrent model: a loud alarm may scare
the tiger off, buying back some distance.

Run:  python tiger.py
"""

from dataclasses import dataclass


@dataclass
class Params:
    """Example parameters - a discussion baseline, not validated values."""
    v_tiger_kmh: float = 50.0        # tiger sprint speed [km/h]
    t_detection_window: float = 1.0  # s - time to a confirmed (multi-frame) detection
    t_classification: float = 0.2    # s - classification latency
    t_warning: float = 0.3           # s - warning activation latency
    t_reaction_target: float = 3.0   # s - reaction time we want to give people
    detection_range_m: float = 65.0  # m - assumed detection radius

    # Detection-probability parameters
    f_sensor: float = 30.0           # fps - sensor / pipeline frame rate
    p_fn_close: float = 0.01         # per-frame miss rate, close range (0-25 m)
    p_fn_mid: float = 0.05           # per-frame miss rate, mid range (25-50 m)
    correlated_fraction: float = 0.02  # rho - fraction of "persistently hard"
    #                                    encounters where frames all fail together
    target_p_encounter_detection: float = 0.999  # required per-encounter detection
    target_p_undetected_per_h: float = 1e-4      # required undetected rate / hour

    @property
    def v_tiger_ms(self) -> float:
        return self.v_tiger_kmh / 3.6

    @property
    def system_latency(self) -> float:
        """Time from tiger entering range to warning being active."""
        return self.t_detection_window + self.t_classification + self.t_warning


def required_detection_range(p: Params) -> float:
    """Detection range needed so the warning leaves `t_reaction_target` for people."""
    return p.v_tiger_ms * (p.system_latency + p.t_reaction_target)


def reaction_time_at_range(p: Params, range_m: float) -> float:
    """Reaction time personnel actually get if detection range is `range_m`."""
    return range_m / p.v_tiger_ms - p.system_latency


def frames_in_window(p: Params) -> int:
    """Number of sensor frames available within the detection window."""
    return int(round(p.f_sensor * p.t_detection_window))


def detection_prob_independent(p_fn: float, n_frames: int) -> float:
    """
    Detection probability if the per-frame misses were fully independent:
    detect if at least one of `n_frames` frames hits.
    """
    return 1.0 - p_fn ** n_frames


def encounter_miss_prob(p: Params, p_fn: float) -> float:
    """
    Per-encounter miss probability with a correlation term.

    Pure independence is unrealistically optimistic: the genuinely hard cases
    (deep occlusion, odd pose) tend to fail on *every* frame, not one at a time.
    We split encounters into two populations:

      - a fraction `rho` that is "persistently hard": the frames are fully
        correlated, so the whole encounter behaves like a single look (miss
        probability p_fn),
      - the rest, where frames are independent (miss probability p_fn ** n).
    """
    n = frames_in_window(p)
    rho = p.correlated_fraction
    return (1.0 - rho) * (p_fn ** n) + rho * p_fn


def allowed_encounter_rate(p: Params, p_miss: float) -> float:
    """
    Encounters per hour the exposure may have and still meet the per-hour
    undetected-encounter target, given a per-encounter miss probability.
    """
    if p_miss <= 0:
        return float("inf")
    return p.target_p_undetected_per_h / p_miss


def report_detection_probability(p: Params) -> None:
    """Print the multi-frame detection-probability budget."""
    n = frames_in_window(p)
    print("  Multi-frame detection probability")
    print(f"    frames per detection window: {p.f_sensor:.0f} fps x "
          f"{p.t_detection_window:.1f} s = {n} frames")
    print()
    print("    If frames were independent, detection is essentially certain:")
    for label, p_fn in (("close", p.p_fn_close), ("mid", p.p_fn_mid)):
        pd = detection_prob_independent(p_fn, n)
        print(f"      {label:>5} (p_fn={p_fn:.2f}): "
              f"P_detect = 1 - {p_fn:.2f}^{n} = {pd:.12f}")
    print("    -> too optimistic: real hard cases fail on every frame.")
    print()
    print(f"    With a correlated 'hard-case' fraction rho="
          f"{p.correlated_fraction:.2f}:")
    for label, p_fn in (("close", p.p_fn_close), ("mid", p.p_fn_mid)):
        p_miss = encounter_miss_prob(p, p_fn)
        p_det = 1.0 - p_miss
        print(f"      {label:>5} (p_fn={p_fn:.2f}): "
              f"P_detect = {p_det:.4f}, per-encounter miss = {p_miss:.2e}")
    print()

    # Consistency check against the per-encounter and per-hour targets.
    worst_p_fn = max(p.p_fn_close, p.p_fn_mid)
    p_miss = encounter_miss_prob(p, worst_p_fn)
    p_det = 1.0 - p_miss
    target_ok = p_det >= p.target_p_encounter_detection
    print(f"    Target P_encounter_detection = "
          f"{p.target_p_encounter_detection:.3f}")
    print(f"      worst zone (mid) gives P_detect = {p_det:.4f}  "
          f"[{'OK' if target_ok else 'NOT MET'}]")
    rate = allowed_encounter_rate(p, p_miss)
    print(f"    To keep undetected encounters <= "
          f"{p.target_p_undetected_per_h:.0e} / h,")
    print(f"      exposure must stay below {rate:.2f} encounters/h "
          f"(~1 every {1 / rate:.0f} h).")


def acoustic_deterrent(sound_level_db: float,
                       l_min: float = 85.0, l_max: float = 120.0) -> float:
    """
    Toy model of the chance a loud alarm scares the tiger off.

    Below `l_min` the tiger ignores it; at/above `l_max` it almost certainly
    bolts. Linear in between. Returns a probability in [0, 1].
    """
    if sound_level_db <= l_min:
        return 0.0
    if sound_level_db >= l_max:
        return 0.95
    return 0.95 * (sound_level_db - l_min) / (l_max - l_min)


def simulate_approach(p: Params, range_m: float | None = None) -> None:
    """Print a timeline of one approach from `range_m` (default: assumed range)."""
    range_m = p.detection_range_m if range_m is None else range_m
    t_arrival = range_m / p.v_tiger_ms
    t_warning_active = p.system_latency
    reaction = t_arrival - t_warning_active

    print(f"  Tiger enters range at {range_m:.0f} m, closing at "
          f"{p.v_tiger_ms:.1f} m/s ({p.v_tiger_kmh:.0f} km/h)")
    print(f"    t=0.00 s  tiger detected entering range")
    print(f"    t={p.t_detection_window:.2f} s  detection confirmed")
    print(f"    t={t_warning_active:.2f} s  warning active "
          f"(system latency = {p.system_latency:.2f} s)")
    print(f"    t={t_arrival:.2f} s  tiger reaches the group")
    verdict = "OK" if reaction >= p.t_reaction_target else "TOO LATE"
    print(f"    -> reaction time for personnel: {reaction:.2f} s  [{verdict}]")


def main() -> None:
    p = Params()

    print("=" * 64)
    print("  Tiger Detection System - timing sanity check (discussion baseline)")
    print("=" * 64)
    print(f"  tiger speed        : {p.v_tiger_kmh:.0f} km/h "
          f"({p.v_tiger_ms:.1f} m/s)")
    print(f"  system latency     : {p.system_latency:.2f} s "
          f"(detection {p.t_detection_window:.1f} + classify "
          f"{p.t_classification:.1f} + warn {p.t_warning:.1f})")
    print(f"  target reaction    : {p.t_reaction_target:.1f} s")
    print()

    need = required_detection_range(p)
    print(f"  Required detection range for a {p.t_reaction_target:.0f} s "
          f"reaction time: {need:.1f} m")
    print(f"  -> round up to a specified D_detection_range of "
          f"{p.detection_range_m:.0f} m")
    print()

    print("  For comparison, reaction time at a few fixed ranges:")
    for r in (25, 50, 65, 80):
        print(f"    {r:>3d} m -> {reaction_time_at_range(p, r):5.2f} s reaction")
    print()

    print("  Example approach at the specified range:")
    simulate_approach(p)
    print()

    report_detection_probability(p)
    print()

    print("  Acoustic deterrent (bonus): chance the alarm scares the tiger off")
    for lvl in (80, 95, 105, 115, 120):
        print(f"    {lvl:>3d} dB(A) @ 1 m -> "
              f"{acoustic_deterrent(lvl) * 100:4.0f}% chance it bolts")
    print()
    print("  Note: example values only, loosely inspired by AEB literature.")
    print("  A real integrator confirms them for the actual context.")


if __name__ == "__main__":
    main()
