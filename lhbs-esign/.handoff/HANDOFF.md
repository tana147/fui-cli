# AGENT HANDOFF: lhbs-esign

- **Generated At:** 2026-10-28T10:03:00+07:00
- **Workspace Root:** `/home/iot/CODE/fui-cli/lhbs-esign`
- **Status:** `done`
- **Next Session Focus:** Tiếp tục hoàn thiện các phân hệ điều hành KPI vận hành, mở rộng kiểm thử tương tác trên các cơ sở trường khác nhau hoặc tích hợp thêm các API live khi các hệ thống nguồn (CRM, HRM, CSVC Helpdesk) chính thức mở kết nối.

## 1. NEXT SESSION ACTION PLAN
1. Kiểm tra nghiệm thu giao diện Dashboard trên production URL `https://kyso.lhbs.vn/kpi-ops-dashboard` với các bộ lọc cơ sở (Toàn trường, MNTB, MNLK, TH, THCS, THPT).
2. Khi hệ thống CRM hoặc Helpdesk CSVC mở API chính thức, cập nhật các Staging endpoints trong `goliveSpecsList` theo đặc tả tại `docs/KPI_DASHBOARD_CHECKLIST.md`.
3. Mở rộng thêm các kịch bản What-If trong Causal Spotlight Modal dựa trên bảng `tblKPI_CausalNarratives` nếu Ban Giám hiệu yêu cầu bổ sung use-case mới.

## 2. SUGGESTED SKILLS
- `minimal-feature-implementation`: Sử dụng khi cần thêm kịch bản chuỗi nhân quả mới hoặc kết nối thêm API live với minimal diff.
- `session-bugflow`: Sử dụng ở đầu session mới nếu phát hiện lỗi hoặc cần review tính năng mới theo quy trình 2 pha.

## 3. GIT & COMMIT STATE
- **Branch:** `main`
- **Relevant Recent Commits:**
  - `b5f3a32` — feat(lhbs-esign): tai thiet ke kpi-ops-dashboard, tich hop causal config va dong bo 100% database
  - `4df1028` — fix(lhbs-esign): sua FileType cua global-util-js tu js thanh .js de codeeditor FUI nhan dien dung ngon ngu
- **Working Tree Ownership:**
  - **Current task changes:**
    - `lhbs-esign/.md/AGENTS.md` (Bổ sung rules bắt buộc responsive màn hình HD/FHD/2K)
    - `lhbs-esign/.md/DESIGN.md` (Chuẩn thiết kế 5.3 & cấm số 8: luôn tính responsive)
    - `lhbs-esign/_db/esign/spAPI_KPI_GetCorrelations.sql` (Cập nhật Stored Procedure tính toán biến số động ParamsJson theo @DonViID & @PeriodKey, trả 3 Result Sets)
    - `lhbs-esign/_db/esign/spAPI_KPI_GetPeriodSnapshots.sql` (Stored procedure nạp snapshot KPI)
    - `lhbs-esign/modules/kpi-ops-dashboard/components/uc-kpi-ops.vue` (Tích hợp getNarrative, interpolateTemplate, thu gọn Go-Live box thành icon '!', sửa lỗi bottlenecks, ẩn nút thừa)
    - `lhbs-esign/modules/kpi-ops-dashboard/style.css` (Style full-screen 100%, responsive màn hình đa tỉ lệ HD/FHD/2K, style causal-desc nổi bật)
    - `lhbs-esign/docs/Bao_cao_tong_ket_LHBS_NH_2025-2026_Ban_trinh_xin_y_kien.docx` (Tài liệu báo cáo tổng kết bóc tách mẫu câu)
    - `lhbs-esign/.handoff/HANDOFF.md` (Tài liệu bàn giao session)
  - **Pre-existing dirty / unrelated:** (DO NOT touch/revert)
    - `../_logs/tool-errors.jsonl`
    - `../lhu-qldetaisdh/*` (Dự án quản lý luận văn/đề tài sau đại học thuộc phân hệ khác)
- **Quick Inspect Commands:**
  - `git diff --stat HEAD -- lhbs-esign/`
  - `fui remote diff`

## 4. PROBLEM & SYSTEM FLOW
- **Objective:** Loại bỏ hoàn toàn hard-code chuỗi nhân quả trên 4 Tile KPI và Hero Sentence; chuyển sang cơ chế Narrative Template chứa placeholder `{Variable}` kết hợp SQL phân nhánh `IF/ELSE` tính toán động biến số thực tế theo cơ sở trường và kỳ chốt sổ; khai thác toàn bộ mẫu câu từ tài liệu đặc tả dự án.
- **Expected:** Khi chọn cơ sở trường hoặc kỳ chốt sổ, nội dung câu chuyện nhân quả hiển thị đúng số liệu thực tế (sĩ số rút học, doanh thu thất thu, tỷ lệ chuyển đổi, bài tập LMS, doanh thu CLB) lấy từ CSDL `tblKPI_CausalNarratives` và `spAPI_KPI_GetCorrelations`.
- **Actual:** Đã hoàn thành và triển khai thành công 100%, giao diện hiển thị mượt mà không bị lỗi duplicate dấu phần trăm (`%%`), giữ nguyên 100% backward compatibility cho API.
- **Flow Analysis:**
  - **Input:** `@PeriodKey` (VD: '2026-09'), `@DonViID` (VD: 'ALL', 'MNLK', 'TH'...) từ Vue dropdown.
  - **Process:** Frontend gọi API `eSign/KPI_GetCorrelations` -> Stored Procedure `spAPI_KPI_GetCorrelations` truy vấn `tblKPI_PeriodSnapshots` & `tblKPI_CausalAssumptions` -> Tính toán động chuỗi JSON `ParamsJson` -> Trả Result Set 2 danh sách `tblKPI_CausalNarratives` -> Vue nạp vào `causalNarrativesList` -> Helper `getNarrative()` và `interpolateTemplate()` thay thế placeholder `{Variable}` thành `<b class="tx-strong">Value</b>`.
  - **State:** `causalNarrativesList`, `correlationsList`, `periodSnapshots` lưu trong state Vue reactivity của component `uc-kpi-ops`.
  - **Output:** Khối văn bản chuỗi nhân quả hiển thị trực quan trên 4 Tile KPI của Page 0 và banner Hero Sentence trong Causal Modal.
  - **Side Effects:** Bảng mới `tblKPI_CausalNarratives` trên database `eSignature`.

## 5. RELEVANT CODE & ARTIFACT REFERENCES
- **Specs / Plans / Issues / ADRs:**
  - `docs/2026.10.19_Phương án xây dựng Dashboard vận hành.docx`
  - `docs/KPI_DASHBOARD_CHECKLIST.md`
  - `docs/Bao_cao_tong_ket_LHBS_NH_2025-2026_Ban_trinh_xin_y_kien.docx`
- **Code Locations:**
  - `lhbs-esign/modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:119-260` (`uc-kpi-ops` 4 Tile KPI Causal Blocks)
  - `lhbs-esign/modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:2325-2365` (`causalHeroSentence`)
  - `lhbs-esign/modules/kpi-ops-dashboard/components/uc-kpi-ops.vue:3000-3075` (`fetchPeriodData`, `getNarrative`, `interpolateTemplate`)
  - `lhbs-esign/_db/esign/spAPI_KPI_GetCorrelations.sql:65-175` (Stored Procedure dynamic calculation logic)

## 6. SESSION KNOWLEDGE (FACTS vs HYPOTHESES)
### Verified Facts
- [FACT] Bảng `tblKPI_CausalNarratives` đã lưu trữ 12 mẫu câu chuỗi nhân quả chuẩn hóa (Evidence: `fui query --db esign "SELECT COUNT(*) FROM tblKPI_CausalNarratives"` = 12).
- [FACT] `spAPI_KPI_GetCorrelations` trả đúng 3 Result Sets: Result Set 0 (Correlations), Result Set 1 (Summary), Result Set 2 (Narratives tính toán động) (Evidence: test chạy trên SQL Server 2019 qua `fui query`).
- [FACT] Component `uc-kpi-ops.vue` và CSS đã publish thành công lên FUI server, ComID 13057, `# 0 unpublished file(s)` (Evidence: `fui file status`).
- [FACT] Đã xử lý triệt để lỗi duplicate dấu phần trăm (`%%`) trong hàm `interpolateTemplate` bằng regex smart deduplication.

### Active Hypotheses
*None* (Tất cả tính năng đã được implement và verify hoàn tất).

### Assumptions & Unknowns
- [ASSUMPTION] Tỷ lệ học phí và số liệu Leads TVTS tháng 9/2026 trong `tblKPI_CausalAssumptions` khớp với dữ liệu kế toán thực tế của trường.
- [UNKNOWN] Thời điểm các hệ thống nguồn (CRM, HRM, Helpdesk CSVC) hoàn thiện để mở API trực tiếp thay cho Staging dữ liệu.

## 7. TESTS, LOGS & DIAGNOSTICS
- **Overall Verification Status:** `PASS`
- **Test / Benchmark Runs:**
  - Node.js Syntax & Div Balance Check: `div tags: open=413, close=413; Script syntax check: PASSED`.
  - Node.js Template Interpolation Test: Xác nhận output format chính xác cả khi param có hoặc không có `%`.
  - SP Execution Test: `EXEC spAPI_KPI_GetCorrelations @PeriodKey = '2026-09', @DonViID = 'MNLK'` -> Trả về đúng 12 narratives với params tính động cho MNLK.
  - FUI Publish Diff Check: `fui remote diff` xác nhận `uc-kpi-ops.vue` identical 100% với server; `style.css` khớp 100% nội dung (1908 dòng không rỗng).

## 8. ATTEMPTS & DEAD ENDS (DO NOT REPEAT)
- Attempt 1: Nối chuỗi SQL không có tiền tố `N` dẫn đến lỗi font tiếng Việt trong chuỗi JSON (`tri?u`).
  - Result: Ký tự Unicode bị chuyển thành dấu hỏi chấm.
  - Conclusion: Luôn dùng tiền tố `N'...'` cho chuỗi ký tự tiếng Việt trong SQL Server khi nối JSON.
- Attempt 2: Đẩy `style.css` qua `fui file push` bị skip do ledger hash khác biệt về dòng trống.
  - Result: Server chưa cập nhật 52 dòng cuối.
  - Conclusion: Sử dụng `fui module preview` và `fui module publish html --approval <token>` để đồng bộ toàn diện CSS lên module server.

## 9. CONSTRAINTS & RISKS
- **Contracts to Preserve:**
  - Stored Procedure `spAPI_KPI_GetCorrelations` bắt buộc duy trì Result Set 0 và 1 như cũ để không làm gãy các component/consumer đang đọc `corrRes[0]`.
  - Không thay đổi props và data binding hiện hữu của `uc-kpi-ops.vue`.
- **Side Effects / Tradeoffs:**
  - Việc gọi thêm Result Set 2 trong stored procedure làm tăng payload trả về thêm ~3KB (hoàn toàn chấp nhận được và không ảnh hưởng hiệu năng).
