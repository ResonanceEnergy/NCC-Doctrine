# Tier 2 Decision Template

**Date:** February 8, 2026  
**Item:** Tier 2 Spreadsheet & Data Files  
**Archive:** `c:\MircoHydro\TIER2_CLEANUP_ARCHIVED_20260124\`  
**Size:** 0.2 MB (39 files)

---

## Monitoring Results

**14-Day Monitoring Summary (Jan 24 - Feb 7):**

| Week | Dates | File Count | Size | Status | Notes |
|------|-------|-----------|------|--------|-------|
| Week 1 | Jan 24-30 | 39/39 | 0.2 MB | ⏳ | Monitoring |
| Week 2 | Jan 31-Feb 6 | 39/39 | 0.2 MB | ⏳ | Monitoring |
| Day 14 | Feb 7 | 39/39 | 0.2 MB | ⏳ | Final check |

---

## Decision Criteria

**All boxes must be ✅ to approve deletion:**

- [ ] **File count:** Always stayed at 39/39
- [ ] **File size:** Always stayed at 0.2 MB
- [ ] **SoT:** Operational entire time
- [ ] **CAD tools:** No errors or warnings
- [ ] **Data pipeline:** Execution normal
- [ ] **Backup:** Always accessible
- [ ] **Team:** No concerns reported
- [ ] **Red flags:** None observed

---

## System Health Check (Feb 8)

Run before meeting:

```powershell
# Archive check
$t2=@(Get-ChildItem c:\MircoHydro\TIER2_CLEANUP_ARCHIVED_20260124 -Recurse -File)
Write-Host "Archive: $($t2.Count)/39 ✓"

# SoT check
if (Test-Path "c:\MircoHydro\MicroHydroV1 — SoT") { Write-Host "SoT: Operational ✓" }

# Backup check
if (Test-Path "c:\MircoHydro_CONSOLIDATION_BACKUP_20260124") { Write-Host "Backup: Available ✓" }
```

**Expected:** All ✓

---

## What's in Tier 2?

- 39 duplicate spreadsheet & data files
- Test tracker files, measurement exports, CSV logs
- Mostly reference materials (metadata, duplicates)
- Easily regenerable from source data

---

## Why 14 Days (not 7)?

- Spreadsheets used in regular analysis
- Want to catch any pipeline breaks
- Longer observation = higher confidence
- Only 0.2 MB total (minimal space cost)

---

## Decision

Choose one:

### ✅ APPROVED - Delete February 9

**Rationale:** 
- 14 days all green
- No issues found
- Safe to permanently delete
- Tier 1 deletion successful (if happened)

**Action (Feb 9):**
```powershell
Remove-Item -Path "c:\MircoHydro\TIER2_CLEANUP_ARCHIVED_20260124\*" -Recurse -Force
```

**Result:** +0.2 MB freed (Cumulative: 5.9 MB)

**Sign-off:**
- Approved by: _______________
- Date: February 9, 2026
- Notes: ______________________

---

### ❌ REJECTED - Keep Archived

**Rationale:** 
- Need more observation
- Concern: _______________________
- Action: Extend 30 more days

**Next Decision:**
- March 8, 2026

**Sign-off:**
- Rejected by: _______________
- Date: February 8, 2026
- Reason: ______________________

---

## Impact Assessment

**If Approved:**
- Tier 1: 5.7 MB freed (if approved Jan 31)
- Tier 2: 0.2 MB freed (this decision)
- Subtotal: 5.9 MB freed
- Next: Tier 3 (50-100 MB potential, Feb 22 review)

**If Rejected:**
- Keep archived indefinitely
- Continue 30-day monitoring
- Re-evaluate Mar 8
- Delay Tier 3 planning

---

## Notes

_Space for additional observations, questions, or concerns:_

_______________________________________________
_______________________________________________
_______________________________________________

---

**Meeting Attendees:**
1. ____________________________
2. ____________________________
3. ____________________________

**Next Step:** 
→ If approved, execute delete Feb 9 (5 min)  
→ If rejected, extend monitoring 30 days  
→ Either way, prepare Tier 3 community review (starts Feb 22)
