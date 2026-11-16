# Exercise: Alternating Arm Reach

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 6.2 Alternating Arm Reach — complexity: Low **[S]**

| Item | Spec |
|---|---|
| Goal | Alternate left and right hand reaches. |
| Position | Left target at `x = −w/2`, right at `x = +w/2`, with `w = clamp(W, 0.35, 0.50) m` **[S]** (spacing does not exceed shoulder range). `y ≈ 0`, `z = k × R_f,hand`. |
| Pattern | One target per beat; sides alternate L-R-L-R. In one-hand mode, all targets use that side with alternating x offsets. |
| Hit rule | Correct hand must touch. Wrong-hand touch is **ignored** (no penalty). |
| Tempo | Starts **60 BPM [S]**, adaptive (§6.4). |

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Target spacing `w` | clamp(shoulder width, 0.35, 0.50) m **[S]** | |
| Start tempo | 60 BPM **[S]** | |
| Alternation pattern | L-R-L-R **[P]** | |
| Wrong-hand touch | ignored, no penalty **[P]** | |

## Open questions

1. Strict L-R-L-R, or occasional repeats (L-L-R) for variety?
2. In one-hand mode, how should the alternation look (two positions for the same hand)?
3. Theme idea: conducting an orchestra, drumming, or bubble popping?
