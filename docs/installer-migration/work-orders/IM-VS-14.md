# IM-VS-14: authenticated standalone catalog selection

The parent requested internal contract review after the corrected real guest
JSON diagnostic passed. This is a deliberate integrity-source decision for
one exact Microsoft selection, not approval or a generic mismatch exception.
The reviewer worked read-only and did not mutate source, VM or vendor files.
This was a context-carrying internal contract review, not blind, external or
legal review; actual inference telemetry is not exposed.

## Primary evidence inspected by the parent

Full real guest receipt:
`D:/AutoClip-Inno-Migration/vm-vs-json-r2-primary-092fd19636a2.json`,
SHA256 `092fd19636a2115129bbb7fdc00e915b74624871d32002c2553825e8cc5f5f68`.
It was transported byte for byte and its SHA independently checked.
The compact summary is separately preserved as
`vm-vs-json-r2-success-9bcb1f94c46c.json`, SHA256
`9bcb1f94c46c2eedcc9f983ef1168b24ed6e56da5408f205a1cdcef66fa058bd`.

Both exact Catalog and ChannelManifest documents passed content digest, corrected
7,019-byte RSA signing-message verification, timestamp CMS signature,
signature-text imprint, signed timestamp and timestamp-leaf binding. Their
signer is Microsoft Corporation, thumbprint
`AB172913A2960A224809EE8A0C371CD47A079B72`.
Code-signing and timestamp purposes were checked separately using normal
Windows trust, NoFlag and Online revocation, at current UTC and signed UTC.
All eight chain builds returned true with empty chain-status arrays. No
certificate was imported or custom root trusted. The past-time check uses
current revocation data; it is not independent historical revocation proof.
The diagnostic serializer remains reconstructed, not a published vendor API.

## Decision and remaining boundary

The user requires trusted expected artifact pins and failure on mismatch.
The canonical setup manifest's Microsoft row previously pinned only the
bootstrap and remains BLOCKED; the conflicting channel field was not a
successfully matched setup Catalog pin. The contract may intentionally select
the authenticated standalone Catalog as its expected downloaded artifact while
preserving the channel's conflicting declaration separately. The parent
adopted that bounded decision in `contract-v1.md`.

Selected Catalog: 17,954,732 bytes / SHA256
`f0a50ea157222c29abd5ea6ff01bfc3c33b04e011c5e45ee2ca38ef0778e5643`.
Vendor-declared external reference: 30,443,537 bytes / SHA256
`6e470016e4324c84c255ffd0beb3767d17ec89cc8561e9409ee3e1f6d29400f5`.
Neither value is erased or claimed equivalent. Incoming bytes must exactly
match the new chosen pins; another artifact or signature still fails closed.
Preserve 140 payload size conflicts alongside 397 actual length/catalog-SHA
matches and the complete 409-file inventory.

The separate unresolved production boundary is execution during recipient
layout creation: it previously discovered a mutable installer engine before
the 409-file comparison could run. Exact pins must cover the engine and
controls before execution, using a supported vendor route. This needs its
own contract-first implementation, failure tests and real clean recipient
verification, followed by frozen candidate technical review. No canonical
delivery classification, source implementation or release pin was changed by
this decision. Microsoft clarification is necessary only if the project
instead elects to require equality to the conflicting vendor-declared field.
