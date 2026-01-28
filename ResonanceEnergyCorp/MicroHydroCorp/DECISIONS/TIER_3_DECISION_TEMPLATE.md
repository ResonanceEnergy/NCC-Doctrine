# Tier 3 Decision Template

**Date:** March 31, 2026  
**Item:** Tier 3 Old Backups & Archive Files  
**Archive:** `c:\MircoHydro\TIER3_CLEANUP_ARCHIVED_20260301\` (created Mar 1)  
**Size:** 50-100 MB (150-200 files)

---

## Community Review Results

**Feb 22-28: Team Feedback Period**

| Topic | Feedback | Decision |
|-------|----------|----------|
| Keep old backups? | _____________ | [ ] Yes [ ] No |
| Keep legacy CAD? | _____________ | [ ] Yes [ ] No |
| Keep RnD archives? | _____________ | [ ] Yes [ ] No |
| Keep test data? | _____________ | [ ] Yes [ ] No |
| Keep release v0.1.x? | _____________ | [ ] Yes [ ] No |
| Keep release v0.2.x? | _____________ | [ ] Yes [ ] No |
| Other items? | _____________ | [ ] Yes [ ] No |

---

## 30-Day Monitoring (Mar 1-31)

**Monitoring Summary:**

| Week | Dates | File Count | Size | Status | Notes |
|------|-------|-----------|------|--------|-------|
| Week 1 | Mar 1-7 | ___/??? | ___ MB | ⏳ | Monitoring |
| Week 2 | Mar 8-14 | ___/??? | ___ MB | ⏳ | Monitoring |
| Week 3 | Mar 15-21 | ___/??? | ___ MB | ⏳ | Monitoring |
| Week 4 | Mar 22-28 | ___/??? | ___ MB | ⏳ | Monitoring |
| Day 30 | Mar 31 | ___/??? | ___ MB | ⏳ | Final check |

**Note:** Fill in actual counts after Mar 1 archive

---

## Decision Criteria

**All boxes must be ✅ to approve deletion:**

- [ ] **File count:** Stayed stable (never changed)
- [ ] **File size:** Stayed stable (never changed)
- [ ] **SoT:** Operational entire time
- [ ] **Systems:** No performance issues
- [ ] **Backup:** Always accessible
- [ ] **Community:** Reviewed and agreed
- [ ] **Executive:** Approval obtained
- [ ] **Red flags:** None observed

---

## System Health Check (Mar 31)

Run before meeting:

```powershell
# Archive check (adjust count after Mar 1)
$t3=@(Get-ChildItem c:\MircoHydro\TIER3_CLEANUP_ARCHIVED_20260301 -Recurse -File)
Write-Host "Archive: $($t3.Count)/??? ✓"

# SoT check
if (Test-Path "c:\MircoHydro\MicroHydroV1 — SoT") { Write-Host "SoT: Operational ✓" }

# Backup check
if (Test-Path "c:\MircoHydro_CONSOLIDATION_BACKUP_20260124") { Write-Host "Backup: Available ✓" }
```

---

## What's in Tier 3?

**Example items (finalize after community review):**
- MICRO HYDRO - OLD/ (30-40 MB)
- MicroHydroV1 — Archive/ (10-15 MB)
- Legacy v0.1.x & v0.2.x releases (5-10 MB)
- Old RnD experiments (5-10 MB)
- Deprecated test data (5-10 MB)

---

## Why Tier 3 is Different

- **Size:** Large (50-100 MB vs 6 MB for Tiers 1-2)
- **Risk:** Higher (history & institutional knowledge)
- **Community Input:** Required (team decides)
- **Timeline:** Longest (30-day monitoring)
- **Approval:** Executive + team (not just team lead)

---

## Decision

Choose one:

### ✅ APPROVED - Delete April 1

**Rationale:** 
- 30 days all green
- Community agreed
- Executive approved
- Safe to permanently delete

**Action (Apr 1):**
```powershell
Remove-Item -Path "c:\MircoHydro\TIER3_CLEANUP_ARCHIVED_20260301\*" -Recurse -Force
```

**Result:** +50-100 MB freed (Total by Apr 1: 96-156 MB)

**Sign-off:**
- Executive approved by: _______________
- Date: April 1, 2026
- Notes: ______________________

---

### ❌ REJECTED - Keep Archived

**Rationale:** 
- Community needs to keep
- Concern: _______________________
- Action: Keep archived indefinitely

**Next Decision:**
- None (keep as backup)

**Sign-off:**
- Rejected by: _______________
- Date: March 31, 2026
- Reason: ______________________

---

## Final Storage Impact

**If Tier 1 & 2 & 3 Approved:**

| Phase | Freed | Total |
|-------|-------|-------|
| Phase 1 | -40-50 MB | -40-50 MB ✅ |
| Tier 1 | -5.7 MB | -45.7-55.7 MB |
| Tier 2 | -0.2 MB | -45.9-55.9 MB |
| Tier 3 | -50-100 MB | -95.9-155.9 MB |

**Result:** ~100-156 MB freed by April 1

---

## Community Feedback Summary

_Who participated:_
1. _________________ (✓ approved / ✗ concerns)
2. _________________ (✓ approved / ✗ concerns)
3. _________________ (✓ approved / ✗ concerns)

_Any major concerns?_
_______________________________________________
_______________________________________________

_Items the community insisted on keeping:_
_______________________________________________
_______________________________________________

---

## Notes

_Space for decision context:_

_______________________________________________
_______________________________________________
_______________________________________________

---

**Meeting Attendees:**
1. ______________________________ (Community)
2. ______________________________ (Team Lead)
3. ______________________________ (Executive)

**Next Step:** 
→ If approved, execute delete Apr 1 (5 min)  
→ If rejected, keep archived indefinitely  
→ Complete project documentation & lessons learned
