---
id: 2026-06-30-2314-onnx-413-payload-too-large
timestamp: "2026-06-30T23:14:00Z"
category: process
type: config_error
severity: medium
status: open
agent: streikbrecher
title: "Incident: ONNX 413 Payload Too Large Errors During Reindex"
---

# Incident: ONNX 413 Payload Too Large Errors During Reindex

**Date:** 2026-06-30 23:14 MSK (20:14 UTC)
**Severity:** Medium
**Detected by:** Heartbeat check (streikbrecher)

## Summary
During incremental reindex run at 20:07 MSK, ONNX embedding service returned HTTP 413 "Payload too large" for large markdown files, causing embedding failures and fallback to old chunks.

## Details
```
Jun 30 20:07:30 197784.com python3[1767266]:   ONNX retry 1/3 in 1.3s: HTTP Error 413: Payload too large
Jun 30 20:07:32 197784.com python3[1767266]:   ONNX retry 2/3 in 2.3s: HTTP Error 413: Payload too large
Jun 30 20:07:34 197784.com python3[1767266]:   ONNX retry 3/3 in 4.3s: HTTP Error 413: Payload too large
Jun 30 20:07:38 197784.com python3[1767266]:   ONNX failed after 3 retries: HTTP Error 413: Payload too large
Jun 30 20:07:38 197784.com python3[1767266]: ONNX failed for /root/LabDoctorM/projects/snablab/lrc_doc_md/2026 СЛУЖЕБНЫЕ ЗАПИСКИ_ГОТОВО_19 февраль 2026 ДОПСОГЛАШЕНИЕ КДЛ_КДЛ_ТЕСТ_Договор 32514697798 от 05.05.2025.md, keeping old chunks
Jun 30 20:07:38 197784.com python3[1767266]: Indexed: 0, Skipped: 3453, Errors: 2
```

## Affected Files
- Large markdown file in snablab project: `2026 СЛУЖЕБНЫЕ ЗАПИСКИ_ГОТОВО_19 февраль 2026 ДОПСОГЛАШЕНИЕ КДЛ_КДЛ_ТЕСТ_Договор 32514697798 от 05.05.2025.md`
- 2 total errors during this reindex run

## Root Cause
ONNX embedding service (embeddinggemma-300m-int8) has a maximum input size limit. Large documents exceed this limit, causing HTTP 413 responses.

## Impact
- Large documents are not re-embedded; old chunks retained
- Search quality may degrade for updated large documents
- Reindex completes but with errors

## Recommended Actions
1. Implement document chunking before embedding (split large files into smaller chunks)
2. Increase ONNX service payload limit if configurable
3. Add monitoring/alerting for 413 errors
4. Consider preprocessing pipeline for large markdown files

## Status
Open — needs fix in reindex pipeline or ONNX service configuration
