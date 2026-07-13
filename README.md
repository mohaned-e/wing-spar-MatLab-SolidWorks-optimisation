# Automated Wing Spar Design: MATLAB Structural Optimisation with SolidWorks FEA Validation

An automated tool that designs a minimum-mass, geometrically-valid box spar for a foam-board UAV wing — sizing it against bending, torsion, and the real NACA aerofoil envelope — then validates the result against SolidWorks FEA.

Built as a self-directed project by an Aerospace Engineering undergraduate at the University of Manchester, extending a university structural design exercise (originally taught using a manual Excel spreadsheet and hand iteration) into a fully automated MATLAB pipeline.

---

## What this project does

Given a target wing (span, aerofoil, load case), the tool:

1. **Models the bending moment** distribution along the wing under a specified load factor.
2. **Sizes a hollow box-section spar** — height, width, and wall thickness — searching thousands of candidate cross-sections to find the **lightest one** that satisfies:
   - Bending stress (reserve factor ≥ 1)
   - Torsional stiffness (twist compliance ≤ 3°/N·m)
   - **Fits inside the real NACA aerofoil shape**, across the spar's full width — not just at a single point
   - A genuine manufacturing safety margin (real, physical clearance — not a mathematical edge case)
3. **Generates the aerofoil geometry from scratch** using the standard NACA 4-digit equations (thickness distribution + camber line + perpendicular surface offset) — no external aerofoil coordinate database used.
4. **Exports the aerofoil coordinates** in a format SolidWorks can import directly (`Insert → Curve → Curve Through XY Points`).
5. **Calculates the spar's exact position** — both chordwise and vertically — accounting for the aerofoil's camber, so the spar sits correctly inside the wing rather than being naively centred on the chord line.
6. **Validates the design against SolidWorks FEA**, comparing MATLAB's analytical predictions (deflection, bending stress) against a real finite element simulation of the built geometry.

---

## Repository structure

```
/matlab/
    wing_spar_optimisation.m         — main optimiser (bending + torsion + aerofoil fit)
    NACA_airofoil_coordinates.m      — NACA 4-digit aerofoil generator & SolidWorks export
    local_aerofoil_height.m          — aerofoil upper/lower surface height at a given chord position
/solidworks/
    Wing_Geometry_Master_Sketch.SLDPRT
    Rib.SLDPRT
    Spar.SLDPRT
    Rear_Spar.SLDPRT
    leading_edge.SLDPRT
    Flaps.SLDPRT
    Spar_holder.SLDPRT
    wing_assembly.SLDASM
/aerofoil_data/
    naca4418.txt                     — exported aerofoil coordinates (tab-delimited X Y Z, for SolidWorks import)
/results/
    Full_Wing_Design.png
    Aerofoil_Graph.png
    Bending_Displacment_Test.png
    Bending_Stress_Test.png
    Torisional_Stress_test.png
README.md
```

---

## Methodology

### 1. Structural model
The wing is modelled as a cantilever beam, fixed at the root, carrying a point load at the tip (`load factor × aircraft mass × g / 2`). The spar is a hollow rectangular box section; bending stress, tip deflection, and torsional twist are calculated from standard beam theory (second moment of area, Bredt-Batho thin-wall torsion theory).

### 2. Optimisation
A nested search over height, width, top/bottom wall thickness, and side wall thickness finds the lightest cross-section that passes all structural checks *and* physically fits inside the aerofoil. Wall thickness was deliberately included as a free variable rather than fixed — the optimiser correctly converged on the material's minimum manufacturable thickness (5mm foam board) in every case, consistent with the general aerospace engineering principle that thin-walled sections are structurally efficient (material is placed as far as possible from the neutral axis, rather than adding mass near the centre where it contributes little to stiffness). This is a genuine, expected result rather than an unused design variable — see "Known limitations" for the one check (local buckling) that would be needed to make thickness a meaningful trade-off rather than always bottoming out.

### 3. Aerofoil geometry
The NACA 4-digit thickness and camber equations are implemented directly (not pulled from a lookup table), including the correct perpendicular offset of the thickness distribution relative to the camber line — a detail that's easy to get wrong by simply adding thickness vertically instead of normal to the curve.

### 4. Geometric fit validation
An early version of the optimiser checked whether the spar fit the aerofoil at a single chordwise point. This was found — through direct visual inspection in SolidWorks — to be insufficient: because the aerofoil tapers away from its point of maximum thickness, a wide spar's *corners* can clip the surface even when its centre clears comfortably. The constraint was rebuilt to check the aerofoil envelope across the spar's full width, taking the tightest top and bottom limits independently (which can come from different edges of the spar).

---

## Results: MATLAB prediction vs. SolidWorks FEA

Final design: **38mm × 92mm** box spar, 5mm walls, positioned 90mm from the leading edge and 8.88mm above the chord line, tested over a 755mm free (unsupported) length.

| Quantity | MATLAB predicted | SolidWorks FEA (actual) | Note |
|---|---|---|---|
| Tip deflection (6.74N tip load) | 19.86 mm | 20.6 mm | Close agreement — **3.7% difference** |
| Peak bending stress (6.74N tip load) | 357.4 kPa | 538.9 kPa* | 50.8% higher — local effect, see below |
| Torsional twist (10 N·m reference torque) | ≤30° (design limit, not a point prediction) | 10° | Real design sits well inside the limit, see below |

\* *The FEA peak stress occurs at the vice grip interface at the root — a local stress concentration from the clamping mechanism that simple beam theory does not model. Deflection, a whole-beam property averaged over the full structure, is far less sensitive to this kind of local effect and shows strong agreement; stress, being highly local, diverges specifically at this known geometric discontinuity. This is consistent with the failure location predicted qualitatively in the source structural design methodology this project extends.*

**On the torsion result**: the optimiser doesn't target 30° as a predicted outcome — it's the *compliance limit* (≤3°/N·m at the reference 10 N·m torque) the design is required to satisfy, and the optimiser deliberately searches for the lightest spar that sits right at that boundary (calculated compliance ≈2.999°/N·m, essentially on the limit by design). The measured real-world twist (10°) is roughly 3x lower than that worst-case limit — a reassuring result, not a discrepancy to explain away. The gap itself is attributable to the analytical torsion model (Bredt-Batho thin-wall theory) being a conservative approximation: it assumes an idealised infinitely-thin wall, whereas the real wall thickness is a non-trivial fraction of the section (13% of the height), which stiffens the real structure beyond what the thin-wall formula accounts for. Being wrong in this direction — predicting more twist than actually occurs — is the safe direction for a structural design margin to be wrong in.

Spar mass was cross-checked against SolidWorks' own mass properties calculation: once the difference in physical length was accounted for (MATLAB assumed a full-span length for its mass estimate; the SolidWorks test-rig spar was built to the full foam board sheet length for practical clamping purposes), the predicted mass-per-unit-length matched SolidWorks' reported value to six significant figures — confirming the cross-sectional geometry transferred from MATLAB into CAD with no error.

---

## Known limitations / not yet implemented

- **Local panel buckling is not modelled.** The optimiser checks material stress and torsional stiffness, but not whether the thin top/bottom panels could buckle (a stability failure) before the material stress limit is reached. Given the optimiser already converges on the thinnest available wall thickness, this is the most significant open extension to this project — likely via a SolidWorks Buckling study on the final geometry, since implementing a panel buckling formula analytically would require additional assumptions this project doesn't currently make (panel aspect ratio, edge support conditions).
- **The torsional twist angle was measured directly off the deformed model** (viewed straight down the twist axis, true-scale deflection) rather than via a SolidWorks angular displacement output, so it should be treated as a good estimate rather than an instrument-grade measurement.

---

## Requirements

- MATLAB (no additional toolboxes required — `fminsearch`/manual search loops only, `writematrix` requires R2019a+)
- SolidWorks (used for geometry import, assembly, and FEA — Student Edition sufficient)

## Author

Mohaned Elkurdi — MEng Aerospace Engineering, University of Manchester
