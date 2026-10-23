# Rules Traceability

The official MUK Ladder Rules, 2025 document is not currently available in the
repository. The entries below are provisional requirements derived from the
project prompt and concept summary. They must be checked against the
authoritative rulebook before implementation.

| Rule/reference | Requirement | Required behaviour | Enforcement | Tests | Status / ambiguity |
|---|---|---|---|---|---|
| Official rulebook, exact reference missing | Normal challenge position range | Validate the permitted four-position range | Pure Dart rule engine and trusted backend | Eligibility and boundary tests | Pending source verification |
| Official rulebook, exact reference missing | G.O.D. challenges | Require mutual consent and verified eligibility | Rule engine, backend transaction | Consent/state tests | Pending exact consequences |
| Official rulebook, exact reference missing | Challenge response deadline | Reject late or invalid responses | Trusted backend and scheduled job | Time-boundary tests | Exact deadline missing |
| Official rulebook, exact reference missing | Alternative date window | Permit only within the official window | Backend validation | Valid/expired window tests | Exact window missing |
| Official rulebook, exact reference missing | Result submission cutoff | Enforce the daily cutoff | Trusted backend | Cutoff/time-zone tests | Exact cutoff missing |
| Official rulebook, exact reference missing | Match ranking outcome | Apply the official movement algorithm | Server transaction and audit trail | Outcome and concurrency tests | Do not assume a simple swap |
| Official rulebook, exact reference missing | Winner cooldown | Enforce the prescribed two-day cooldown | Backend and scheduled expiry | Eligibility/expiry tests | Exact exceptions missing |
| Official rulebook, exact reference missing | Inactivity penalty | Apply the official penalty once per period | Idempotent scheduled job | Repeated-job tests | Exact penalty missing |
| Concept summary | Result confirmation/dispute | Support confirmation and dispute review | Result state machine and admin workflow | State transition tests | Verify with rulebook |
| Concept summary | Admin/Treasurer separation | Limit each role to approved actions | Firebase Security Rules and backend | Allowed/forbidden access tests | Exact permissions need approval |
| Prompt ambiguity | Placement time | Resolve 6 a.m.–8 p.m. versus 6 a.m.–6 p.m. descriptions | Configuration after clarification | Time-zone tests | Must ask Ladder Admin/lecturer |

All date and time calculations should use `Africa/Kampala` where appropriate.

