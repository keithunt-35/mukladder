# Rules Traceability

The supplied MUK Ladder Rules, 2025 text is the current implementation
reference. The 2026 tournament applicability should still be confirmed with
the Ladder Admin before production enforcement.

| Rule/reference | Requirement | Required behaviour | Enforcement | Tests | Status / ambiguity |
|---|---|---|---|---|---|
| MUK Ladder Rules, 2025, Rules 2–3 | Normal challenge position range and placement window | Allow only up to four positions above, between 6 a.m. and 8 p.m., scheduled 1–3 days ahead | `ChallengeRules` and trusted backend | Eligibility and boundary tests | Provisional client validation; user selected 6 a.m.–8 p.m.; 2026 applicability to confirm |
| Official rulebook, exact reference missing | G.O.D. challenges | Require mutual consent and verified eligibility | Rule engine, backend transaction | Consent/state tests | Pending exact consequences |
| MUK Ladder Rules, 2025, Rule 4 | Same-day challenge response | Require response on placement day; otherwise walkover is indicated by the rules | `ChallengeRules` and trusted backend | Same-day boundary tests | Same-day validation implemented locally |
| Official rulebook, exact reference missing | Alternative date window | Permit only within the official window | Backend validation | Valid/expired window tests | Client currently uses the challenge's 1–3-day scheduling window provisionally; confirm exact rule |
| MUK Ladder Rules, 2025, Rules 5–6 and 9 | Result deadline and ranking outcome | Receive results on match day before 8 p.m.; apply Normal and G.O.D. outcomes | Pure Dart rule engine plus trusted `confirmMatchResult` transaction | Cutoff and outcome tests | Client submits with deadline check; confirmation applies rankings server-side; 2026 applicability to confirm |
| MUK Ladder Rules, 2025, Rules 5–6 | Winner cooldown | Prevent the winner from placing another challenge for two days | Challenge rule engine and trusted backend cooldown stamp | Eligibility/expiry tests | Server writes `players.cooldownStartedAt` on confirm; client validates before placement |
| Concept paper Rule 10 summary | Inactivity penalty | Drop one position per seven inactive days | `inactivity_plan` + daily scheduled job | Drop planner tests | Provisional; confirm exact Rule 10 wording with Ladder Admin |
| MUK Ladder Rules, 2025, Rule 7–9 | Walkovers and unfinished matches | Resolve only under the stated attendance, postponement and cutoff conditions | Trusted backend and scheduled workflow | Time/attendance tests | Not automated yet; requires event and admin workflow |
| Concept summary | Admin/Treasurer separation | Limit each role to approved actions | Firebase Security Rules and backend | Allowed/forbidden access tests | Exact permissions need approval |
| User clarification | Placement time | Use 6 a.m.–8 p.m. for the provisional challenge flow | `ChallengeRules`; trusted backend still required | Time-window boundary test | Resolved for provisional implementation only; confirm applicability with Ladder Admin/lecturer |

All date and time calculations should use `Africa/Kampala` where appropriate.
