# IM-WIZ-18 — scoped internal collaborator review

This is same-session internal collaborator review, not blind independent review
or external approval. The reviewer participated in earlier debugging, worked
read-only, inspected current source/contracts/tests and returned three findings.
Reviewed Inno snapshot was source55856e2b2b3a at syntax-only output6006n1qk,
bootstrap2e2372a0c29c, supervisorbdbfe445e724 and health helper9f5656ccad34.
No Setup EXE, vendor, VM or uninstaller execution occurred in this review.

1. Normal Python provisioning created inherited `Setup/logs` parents that the
   new source supervisor correctly rejected. Actual source call order and the
   Python Directory.CreateDirectory producer establish this conflict. WIZ19's
   actual producer composition reproduced RED; moving the one Inno log argument
   to `AutoClip/PythonSetupLogs` made the same composition GREEN.
2. Lexical target lock normalization needed real Windows alias qualification.
   WIZ19 found existing-target aliases already expand on native .NET Framework.
   A genuinely absent suffix leaves an immediate existing short ancestor;
   two held workers demonstrated RED before target creation. Resolving the
   existing ancestor with the standard library before appending the suffix
   makes those real alias workers exclude one another. This narrower evidence
   supersedes the review's broad existing-target inference, without erasing it.
3. Inno's cleanup loops still call UI refresh/cancellation polling inside
   `finally`; a secondary exception there can unwind before supervisor terminal
   state. This is a conditional source gap, not an executed failure. WIZ20 is
   preparing a bounded compiled first-party observation fixture. Runtime RED,
   a production fix and exact UI verification remain open. Earlier automatic
   rejection of notice `/AUDIT` execution is preserved; it has not been retried
   or bypassed to close this distinct UI behavior gate.

The reviewed health path passes its source trace: Inno pins/forwards the helper,
the actual worker accepts its typed hash, bootstrap verifies the protected
result/root/manifest, then commits launcher and marker under the decision lock.
This source inspection does not establish whole compiled wizard health success.

Parent independently reran the final WIZ19 native composition test, exit0,
observing actual distinct short/long inputs, equal canonical lock identities,
exclusion while the first worker remains live, and terminal retry. Final wrapper
SHA25695a40597f6d196ad3ae23a6bc5a869899f5c0602fb89dcd2de11bf6277475ae0.
