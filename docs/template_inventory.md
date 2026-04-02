# Verified Emission Templates — Inventory

**Status:** Complete
**Updated:** 2026-04-02

## Template Summary

| # | Template                     | Milestone | PO Hooks                                       | Checks\* | Status |
|---|------------------------------|-----------|------------------------------------------------|----------|--------|
| 1 | `template_wide_arithmetic`   | M1        | `Narrow_Return`, `Narrow_Assignment`           | 14       | Proved |
| 2 | `template_division_nonzero`  | M1        | `Nonzero`, `Safe_Div`, `Safe_Mod`, `Safe_Rem`  | 17       | Proved |
| 3 | `template_ownership_move`    | M2        | `Check_Owned_For_Move`, `Check_Not_Moved`      | 3        | Proved |
| 4 | `template_scope_dealloc`     | M2        | `Check_Owned_For_Move`, `Check_Not_Moved`      | 13       | Proved |
| 5 | `template_not_null_deref`    | M2        | `Not_Null_Ptr`, `Safe_Deref`                   | 7        | Proved |
| 6 | `template_channel_fifo`      | M3        | `Check_Channel_Not_Full/Empty/Capacity_Positive` | 79     | Proved |
| 7 | `template_task_decl`         | M3        | `Check_Exclusive_Ownership`                    | 12       | Proved |
| 8 | `template_index_safety`      | M4        | `Safe_Index`, `Narrow_Indexing`                | 14       | Proved |
| 9 | `template_effect_summary`    | M5        | (none -- flow-analysis template)               | 3        | Proved |
| 10| `template_package_structure` | M5        | `Narrow_Parameter`                             | 6        | Proved |
| 11| `template_borrow_observe`    | M6        | `Check_Borrow_Exclusive`, `Check_Observe_Shared` | 13     | Proved |
| 12| `template_fp_safety`         | M6        | `FP_Not_NaN`, `FP_Not_Infinity`, `FP_Safe_Div` | 17       | Proved |
| 13| `template_select_polling`    | M6        | `Check_Channel_Not_Empty`                      | 32       | Proved |
| 14| `template_select_dispatcher` | M6        | `Check_Channel_Not_Empty`                      | 56       | Proved |
| 15| `template_narrow_conversion` | M7        | `Narrow_Conversion`                            | 14       | Proved |
| 16| `template_discriminant_result` | M7      | discriminated result lowering                  | 15       | Proved |

\* Checks = proved obligations reported in the current per-unit GNATprove
summary for each template package.

**Total template checks: 315** (all proved)

## Proof Summary

553 total VCs across 20 units (Safe_Bounded_Strings, Safe_Model, Safe_PO,
Safe_Runtime, 16 templates):
- Flow (Bronze): 138 checks (25%) — all passed
- Proof (Silver): 414 proved + 1 justified (75%) (CVC5 98%, Trivial 2%)
- Justified: 1 (FP_Safe_Div float overflow, see A-05)
- Unproved: 0

| Unit                         | Checks | Notes |
|------------------------------|--------|-------|
| `safe_bounded_strings`       | 0      | support package |
| `safe_model`                 | 79     | ordered FIFO ghost model included |
| `safe_po`                    | 20     | shared PO hooks |
| `safe_runtime`               | 0      | support package |
| `template_wide_arithmetic`   | 14     | proved |
| `template_division_nonzero`  | 17     | proved |
| `template_ownership_move`    | 3      | proved |
| `template_scope_dealloc`     | 13     | proved |
| `template_not_null_deref`    | 7      | proved |
| `template_channel_fifo`      | 79     | proved; FIFO refinement to `Safe_Model` |
| `template_task_decl`         | 12     | proved |
| `template_index_safety`      | 14     | proved |
| `template_effect_summary`    | 3      | proved |
| `template_package_structure` | 6      | proved |
| `template_borrow_observe`    | 13     | proved |
| `template_fp_safety`         | 17     | proved |
| `template_select_polling`    | 32     | proved |
| `template_select_dispatcher` | 56     | proved |
| `template_narrow_conversion` | 14     | proved |
| `template_discriminant_result` | 15   | proved |

## Max Steps

Max steps used for successful proof: 2 (well within budget).

## Assumption Ledger (Template-specific)

No template-specific assumptions remain open. The ordered FIFO closure in
`template_channel_fifo` resolves assumption `B-02`; the remaining open
assumptions live in the shared companion ledger at
`companion/assumptions.yaml`.

## Coverage Boundary (M0–M7 Complete)

This inventory covers the **M0–M7 template suite** (all milestones complete).
The table below maps `compiler/translation_rules.md` sections to template
coverage. All 23 `Safe_PO` hooks are exercised.

**Covered by M0–M7 templates:**

| Rule / Section | Clauses | Template(s) |
|---------------|---------|-------------|
| Rule 1 — Wide arithmetic & narrowing | 2.8.1.p126-p130, 5.3.6.p25 | `template_wide_arithmetic` |
| Rule 2 — Safe indexing | 2.8.2.p131-p132, 5.3.1.p12 | `template_index_safety` |
| Rule 3 — Safe division | 2.8.3.p133-p134, 5.3.1.p12 | `template_division_nonzero` |
| Rule 4 — Not-null dereference | 2.8.4.p136, 5.3.1.p12 | `template_not_null_deref` |
| Rule 5 — FP safety | 2.8.5.p139-p139e, 5.3.7a.p28a | `template_fp_safety` |
| §2.3 — Ownership (move, scope dealloc) | 2.3.2.p96a-p96c, 2.3.5.p104 | `template_ownership_move`, `template_scope_dealloc` |
| §2.3 — Borrow & observe | 2.3.3.p99b, 2.3.4a.p102a | `template_borrow_observe` |
| §4.2-4.3 — Channel FIFO | 4.2.p15, 4.3.p27-p31 | `template_channel_fifo` |
| §4.4 — Dispatcher-based select | 4.4.p33-p42 | `template_select_dispatcher` |
| §4.5 — Task declaration | 4.5.p45, 5.4.1.p32-p33 | `template_task_decl` |
| §5.2 — Effect summaries | 5.2.2.p5, 5.2.3.p8, 5.2.4.p11 | `template_effect_summary` |
| §3.1 — Package structure | 3.2.6.p23-p24, 2.9.p140 | `template_package_structure` |
| Rule 1 — Narrow conversion | 2.8.1.p127, 2.8.1.p130 | `template_narrow_conversion` |
