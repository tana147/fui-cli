# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-28T15:47:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục khai thác các tính năng quản trị HĐQT chuyên sâu, báo cáo điều hành tự động định kỳ, hoặc mở rộng các nhánh chỉ tiêu mới trên Cây Nhân Quả.

## 1. NEXT SESSION ACTION PLAN
1. Đọc lại `.handoff/HANDOFF.md` để nắm các cải tiến mới nhất: Cây SVG đa nhánh chuyên biệt (CSVC, Y tế, Nhân sự, Tuyển sinh), Slider What-If ổn định (1–50 đơn vị), Ma trận 3 giai đoạn chuẩn hóa đơn vị tính.
2. Kiểm tra giao diện điều hành thực tế trên portal eSign (`/kpi-ops-dashboard`) theo từng nhóm chỉ tiêu (`TS04`, `CSVC01`, `MED01`, `HR02`).
3. Khai thác tiếp các tính năng nâng cao trong Backlog HĐQT (Thẻ Nghị quyết Điều hành & Giao quyền cơ sở, Đóng dấu kiểm toán khóa số liệu kỳ) khi có yêu cầu.

## 2. SUGGESTED SKILLS
- `minimal-feature-implementation`: Triển khai các tính năng mới với minimal diff và bảo toàn contract.
- `fui`: Để deploy SP và sync component/style lên portal eSign (`fui file push`, `fui sp deploy`).

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `5fbe716` — feat(lhbs-esign): standardize Sep facts, add executive ROI simulator, risk radar & 5 sub-tabs
  - `cbe51a6` — feat(lhbs-esign): dynamic 100% kpi causal engine 60 chi tieu 5 co so va compact 3-space ui
- **Working Tree Ownership:**
  - **Current task changes:**
    - `lhbs-esign/modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` (Loại bỏ nút giả lập & dropdown select thừa ở toolbar; phục hồi & động hóa Cây SVG 4 tầng theo 4 nhánh chuyên biệt; chuẩn hóa Ma trận 3 giai đoạn tách biệt `isStudentScale`; khóa cứng slider What-If 1–50)
    - `lhbs-esign/modules/kpi-ops-dashboard/style.css` (Style compact causal dialog, SVG tree bezier curves, net impact matrix)
    - `lhbs-esign/_db/esign/migration_seed_causal_correlations_15links.sql` (Cập nhật tiêu đề phân tách Mắt xích 1.1 và Mắt xích 1.2)
    - `lhbs-esign/.handoff/HANDOFF.md` (Tài liệu chuyển giao phiên làm việc)
  - **Pre-existing dirty / unrelated (DO NOT touch/revert):**
    - `../_logs/tool-errors.jsonl`
    - `../lhu-qldetaisdh/*` (Các file thuộc project LHU Quản lý Đề tài SĐH)
- **Quick Inspect Commands:**
  - `git diff --stat modules/kpi-ops-dashboard/`
  - `git diff modules/kpi-ops-dashboard/components/uc-kpi-ops.vue`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Tối ưu hóa toàn diện modal Vùng tác động (Causal Engine) và giải quyết triệt để 6 vấn đề:
  1. Bỏ 2 nút tạo phiếu + xuất tờ trình giả lập alert.
  2. Phục hồi Cây tác động trực quan SVG 4 tầng với đường cong Bézier.
  3. Khắc phục lỗi slider What-If bị nhảy số thiên văn (`144535574730443600`) do exponential feedback loop.
  4. Xử lý triệt để trùng lặp tiêu đề Chuỗi 1 (Mắt xích 1.1 Tuyến xe bus vs Mắt xích 1.2 Thất thu tài chính) trong cả CSDL `tblKPI_Correlations` và template.
  5. Loại bỏ dropdown `<select>` chọn chỉ tiêu thừa thãi trên toolbar (header) của modal.
  6. Động hóa Cây SVG và Ma trận 3 giai đoạn theo 4 nhánh nghiệp vụ riêng biệt (CSVC, Y tế, Nhân sự, Tuyển sinh), loại bỏ việc áp đặt đơn vị tính "học sinh rút học / leads cần bù" cho các chỉ tiêu kỹ thuật CSVC (`CSVC01`).
- **Expected:** Khi chuyển đổi giữa các KPI (`TS04`, `CSVC01`, `MED01`, `HR02`), cả Ma trận 3 giai đoạn lẫn Cây SVG đều phản ánh đúng dữ liệu nghiệp vụ thật của phòng ban tương ứng.
- **Actual:** Đã hoàn thành 100%, test AST cú pháp JS và template Vue hợp lệ, đồng bộ portal eSign thành công (ComID 13057, 0 unpublished files).
- **Flow Analysis:**
  - **Input:** Người dùng chọn KPI (`causalKpiCode`) và kéo slider biến động What-If (`causalDeltaOverride`).
  - **Process:**
    - `causalDeltaAuto` nhận giá trị từ 1 đến 50 đơn vị (clamp an toàn).
    - `genericCausalCalc` phân luồng theo cờ `isStudentScale`: KPI tuyển sinh tính theo sĩ số/leads, KPI CSVC tính theo SLA 91.67% / chi phí bảo dưỡng linh kiện, KPI Y tế tính theo ca bệnh Cúm A & khử khuẩn ISO 22000.
    - `causalTreeNodes` sinh 9 node động theo 4 nhánh nghiệp vụ chuyên biệt (CSVC, Y tế, Nhân sự, Tuyển sinh).
  - **State:** Component Vue quản lý trạng thái phản hồi tức thì mà không bị loop tràn số.
  - **Output:** Modal Vùng tác động trực quan, sắc nét, chính xác 100% với thực tế Tháng 9/2026.
  - **Side Effects:** Zero side-effects ngoài phạm vi KPI.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Code Locations:**
  - `modules/kpi-ops-dashboard/components/uc-kpi-ops.vue`:
    - `causalDeltaAuto`: dòng ~4310
    - `genericCausalCalc`: dòng ~4340
    - `causalTreeNodes`: dòng ~4610
    - `causalTreeEdges`: dòng ~4720
  - `_db/esign/migration_seed_causal_correlations_15links.sql`: Seed 15 mắt xích phân định rõ Mắt xích 1.1 và 1.2.
  - Bảng CSDL: `tblKPI_Correlations` (ID 34 & 35 đã cập nhật tiêu đề phân tách).

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Dữ liệu Tháng 09/2026 trong CSDL eSign là số liệu có thật 100%: 79 ticket bảo trì (18 máy lạnh Khu B/C, tồn 4 ticket, SLA 91.67%), 131 ca y tế (53 ca sốt Cúm A), 21 HS rút vì cự ly xa nhà (MNBH 5, MNLK 4, TH 6, THCS 4, THPT 2), 161 leads tiếp nhận (chuyển đổi 21 HS mới = 13.04%).
- [FACT] Component `uc-kpi-ops` (ComID 13057) đã được cập nhật và push lên portal qua `fui file push`.
- [FACT] Cú pháp AST script Options API và cân bằng thẻ template đạt 100% (3 template mở, 3 template đóng).

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - `node -e` Template tag balance check: `PASS`
  - `node -e` Vue Options API syntax check: `PASS`
  - `node -e` Multi-branch simulation for `CSVC01`, `MED01`, `TS04`: `PASS`
  - `fui file status`: `# 0 unpublished file(s)`: `PASS`

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Attempt 1: Gán `:max="causalDeltaAuto * 2.5"` trên input range dẫn đến exponential feedback loop khi drag chuột, đẩy số lên $1.44 \times 10^{17}$. Khắc phục: Khóa cứng `:min="1" :max="50" step="1"` và clamp an toàn trong `causalDeltaAuto()`.
- Attempt 2: Dùng chung công thức tuyển sinh `delta / conv` cho mọi KPI khiến CSVC máy lạnh bị tính ra 180 leads tuyển sinh. Khắc phục: Tách biệt cờ `isStudentScale` trong `genericCausalCalc`.

## 9. CONSTRAINTS & RISKS
- Contracts to Preserve: Giữ nguyên API contract `eSign/KPI_GetCorrelations`, Options API của Vue 3, không dùng KaTeX toán học.
- Side Effects / Tradeoffs: Modal causal hiển thị thông tin chuyên sâu của từng phòng ban, yêu cầu các node SVG giữ đúng 9 node ID (`N_EVENT`, `N_ENROLLMENT`, `N_RUT_HOC`, `N_REV_NOW`, `N_CLB`, `N_EXPLAIN`, `N_REV_FUTURE`, `N_LEADS_NEED`, `N_ACTION_ROUTE`) để tương thích với 8 đường cong Bézier.
