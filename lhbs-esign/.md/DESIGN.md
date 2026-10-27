# Design System — KPI Modules

> Tài liệu này ghi lại hướng thiết kế, token màu, typography, và toàn bộ pattern UI chuẩn mực đang áp dụng thực tế trong `modules/kpi-results-framework`. Mọi module và component có prefix `kpi-` bắt buộc tuân thủ tài liệu này để đảm bảo sự đồng bộ tuyệt đối về mặt thị giác, trải nghiệm và cấu trúc kỹ thuật.

**Scope:** `modules/kpi-*/`

---

## 1. Triết lý thiết kế & Mục tiêu

Các module KPI được xây dựng theo định hướng **Executive Decision-Making Dashboard (Bảng điều hành cấp cao / Hội đồng trường)**, không phải giao diện CRUD thông thường:

1. **Information Density cao nhưng phân cấp rõ ràng**: Tối đa hóa lượng thông tin có giá trị trên một khung nhìn (laptop / tablet phòng họp) mà không gây quá tải thị giác nhờ phân cấp chữ, màu sắc và cấu trúc lưới chặt chẽ.
2. **Triết lý màu trạng thái (Meaningful Colors)**: Không dùng màu nền sặc sỡ toàn khối cho card. Màu sắc chỉ xuất hiện ở các điểm nhấn tín hiệu: viền trạng thái (border-left), cell màu nhạt (tint background), badge/tag và sparkline để biểu thị ngay lập tức tình trạng Đạt / Cảnh báo / Nguy cấp.
3. **Quản trị số liệu theo 4 Tầng (Results Framework 4 Tiers)**:
   - **Tầng A (Tier 1)**: Dữ liệu vận hành thô theo dõi tháng (Monitoring data — T8, T9...).
   - **Tầng B (Tier 2)**: Chỉ số hiệu suất vận hành (Ops metrics — tuyển sinh, rút học, lớp...).
   - **Tầng C (Tier 3)**: Mục tiêu chuyển dịch / Sáng kiến chiến lược can thiệp.
   - **Tầng D (Tier 4)**: Bộ chỉ số KPI chiến lược chính thức (MASTER KPI).
4. **Trình chiếu & Điều hành tại phòng họp (Meeting / Present Ready)**:
   - Có chế độ Trình chiếu máy chiếu (`present mode`) tự động ẩn bớt bộ lọc rườm rà.
   - Có cơ chế **Drawer phân tích tác động** (Impact Slide-over) cho phép click vào bất kỳ chỉ số nào để mở kịch bản phân tích tài chính / sĩ số chi tiết.
   - Hỗ trợ xuất tài liệu họp định dạng chuẩn in ấn / PDF (`@media print`).

---

## 2. Namespace CSS bắt buộc

Mỗi module KPI bắt buộc dùng prefix namespace độc lập theo tên module:

```
uc-[module-slug]               ← root wrapper (chứa CSS variables)
uc-[module-slug]__[block]      ← block-level element
uc-[module-slug]__[block]-[el] ← element con bên trong
```

| Module                   | Root Wrapper       | Prefix Element      |
| ------------------------ | ------------------ | ------------------- |
| `kpi-results-framework`  | `.uc-kpi-rf`       | `.uc-kpi-rf__*`     |
| `kpi-[tên-mới]`          | `.uc-kpi-[slug]`   | `.uc-kpi-[slug]__*` |

> [!IMPORTANT]
> Tuyệt đối KHÔNG viết class global không có prefix module (tránh đụng chạm đến core Vuetify hay module khác). Mọi custom CSS phải nằm trong file `style.css` của module đó.

---

## 3. Hệ thống Token Màu (Executive Fluent Palette)

Module áp dụng bảng màu tiêu chuẩn Executive Fluent (tông trầm công sở, độ tương phản cao, dễ nhìn trên máy chiếu):

### 3.1 CSS Variables cốt lõi

```css
.uc-kpi-rf {
  /* Nền và Khung viền */
  --bg: #f3f2f1;        /* Nền trang xám nhạt Microsoft Fluent */
  --card: #ffffff;      /* Nền thẻ card */
  --line: #e1dfdd;      /* Kẻ viền phân tách mờ */

  /* Chữ & Nhãn (Ink) */
  --ink: #252423;       /* Chữ chính (đen than) */
  --ink2: #605e5c;      /* Chữ phụ / nhãn (xám đậm) */
  --ink3: #8a8886;      /* Ghi chú / hint (xám vừa) */

  /* Màu thương hiệu & Tương tác */
  --accent: #3A6EA5;    /* Xanh tương tác / Link / Highlight (Steel Blue) */
  --accent2: #1B365D;   /* Xanh Navy đậm thương hiệu LHBS (Executive Navy) */

  /* Trạng thái 3 mức cơ bản (KPI Status) */
  --good: #1a9e4b;      /* Xanh lá: Đạt chuẩn / Tốt */
  --warn: #d9822b;      /* Cam vàng: Cảnh báo / Cần lưu ý */
  --bad: #d13438;       /* Đỏ: Nguy cơ / Không đạt */

  /* Nền nhạt tô cell bảng (Cell Tint Backgrounds) */
  --good-t: #e7f4ec;    /* Nền nhạt xanh lá */
  --warn-t: #fdf1e3;    /* Nền nhạt cam vàng */
  --bad-t: #fbe9ea;     /* Nền nhạt đỏ */
}
```

### 3.2 Hệ 6 Trạng thái Khung kết quả (Results Framework Coverage)

Áp dụng cho ma trận đo lường KPI chiến lược:

| Biến CSS | Mã màu | Ý nghĩa | Lớp Tag tương ứng |
| -------- | ------ | ------- | ----------------- |
| `--ks-good` / `--ks-good-t` | `#1a9e4b` / `#e7f4ec` | Đạt chuẩn mục tiêu | `.uc-kpi-rf__tag.is-good` |
| `--ks-part` / `--ks-part-t` | `#3A6EA5` / `#e8eef5` | Đạt một phần | `.uc-kpi-rf__tag.is-part` |
| `--ks-prep` / `--ks-prep-t` | `#5C6B7A` / `#eef0f2` | Đang chuẩn bị triển khai | `.uc-kpi-rf__tag.is-prep` |
| `--ks-warn` / `--ks-warn-t` | `#d9822b` / `#fdf1e3` | Cần chú ý / lệch nhẹ | `.uc-kpi-rf__tag.is-warn` |
| `--ks-bad` / `--ks-bad-t` | `#d13438` / `#fbe9ea` | Rủi ro cao / không đạt | `.uc-kpi-rf__tag.is-bad` |
| `--ks-none` / `--ks-none-t` | `#8a8886` / `#f3f2f1` | Chưa đủ dữ liệu đo lường | `.uc-kpi-rf__tag.is-none` |

### 3.3 Text Utility Classes

- `.tx-good`: Màu `--good` (`#1a9e4b`)
- `.tx-warn`: Màu `--warn` (`#d9822b`)
- `.tx-bad`: Màu `--bad` (`#d13438`)
- `.tx-muted`: Màu `--ink3` (`#8a8886`)
- `.tx-strong`: `font-weight: 600; color: var(--ink)`
- `.ta-l`: `text-align: left !important`

---

## 4. Typography & Căn chỉnh số liệu

- **Font Family chuẩn**: `'Segoe UI', -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif`
- **Tabular Nums (Cực kỳ quan trọng)**: Mọi bảng biểu (`.uc-kpi-rf__table`), số KPI (`.uc-kpi-rf__bkpi-v`), số liệu thống kê (`.uc-kpi-rf__stat-v`) **bắt buộc** có:
  ```css
  font-variant-numeric: tabular-nums;
  ```
  giúp tất cả chữ số có cùng độ rộng, không bị nhảy giật hay lệch cột khi so sánh hàng dọc.
- **Sàn cỡ chữ (Readability Floor)**:
  - Cỡ chữ sàn cho nội dung bảng và mô tả: **tối thiểu 12px**.
  - Nhãn phụ, ghi chú meta, nguồn dữ liệu: **10.5px – 11.5px**.
  - Tuyệt đối không dùng chữ nhỏ hơn 10px để tránh mất khả năng đọc khi chiếu phòng họp hoặc hiển thị trên iPad.

---

## 5. Layout, Lưới 12 Cột & Khoảng cách (Spacing)

### 5.1 Cấu trúc Grid chuẩn

Hệ thống layout dùng CSS Grid 12 cột với gap **8px** (tối ưu mật độ dữ liệu):

```css
.uc-kpi-rf__grid {
  display: grid;
  grid-template-columns: repeat(12, minmax(0, 1fr));
  gap: 8px;
}
.uc-kpi-rf__span12 { grid-column: span 12; }
.uc-kpi-rf__span7  { grid-column: span 7; }
.uc-kpi-rf__span5  { grid-column: span 5; }
```

### 5.2 Padding & Spacing cố định

- **Khung trang (`.uc-kpi-rf__page`)**: `padding: 10px 20px 0;`
- **Thanh Header trên cùng (`.uc-kpi-rf__top`)**: `padding: 12px 20px; border-bottom: 1px solid var(--line);`
- **Thanh Slicer bộ lọc (`.uc-kpi-rf__slicers`)**: `padding: 10px 20px; border-bottom: 1px solid var(--line);`
- **Thẻ Visual Panel (`.uc-kpi-rf__visual`)**: `padding: 10px 14px; background: var(--card); border: 1px solid var(--line);`
- **Quy tắc Bo góc**: Chỉ dùng `border-radius: 2px` (hoặc `0` theo phong cách phẳng Fluent). Tuyệt đối không dùng bo góc tròn lớn.

---

## 6. Chi tiết các Component Patterns chuẩn

### 6.1 Top Header & Meta Bar (`.uc-kpi-rf__top`)

Header điều hành nằm trên cùng, hiển thị tiêu đề báo cáo, kỳ chốt, nguồn số liệu và nút chức năng:

- **Tiêu đề chính (`.uc-kpi-rf__title`)**: 18px, weight 600, letter-spacing -0.2px.
- **Phụ đề (`.uc-kpi-rf__subtitle`)**: 12.5px, màu `--ink2`.
- **Thanh Meta (`.uc-kpi-rf__meta`)**: Hiển thị thời điểm chốt, nguồn dữ liệu, nút chuyển chế độ trình chiếu.
- **Pill cảnh báo nguồn số liệu (`.uc-kpi-rf__pill2`)**:
  - Bình thường: Viền xám mờ `#c8c6c4`.
  - Cảnh báo chưa đối soát (`.is-warn`): Viền và chữ màu cam vàng `--warn`.
- **Nút hành động nhanh (`.uc-kpi-rf__simbtn`)**: Nút phẳng không bo góc, có bản `.is-solid` (nền đậm) cho hành động chính (Xuất PDF).

### 6.2 Slicer & Segment Control (`.uc-kpi-rf__slicers`)

Thanh bộ lọc đơn vị và phân cấp quản lý:

- **Segment Button Group (`.uc-kpi-rf__seg`)**: Các nút bấm nối liền nhau với border `#c8c6c4`.
  - Trạng thái chọn (`.is-on`): Nền `--accent2` (#1B365D), chữ trắng.
  - Kích thước nhỏ (`.uc-kpi-rf__seg--sm`): Dùng cho chọn tháng, kịch bản nền.
- **Nhãn góc nhìn (`.uc-kpi-rf__view`)**: Hiển thị vai trò xem hiện tại (ví dụ: "Ban điều hành · hợp nhất" hoặc "Hiệu trưởng Tiểu học").

### 6.3 Lead / Headline Banner (`.uc-kpi-rf__lead`)

Băng rôn kết luận điều hành 1 câu — đặt ở đầu mỗi trang chi tiết:

- Nền: `--accent2` (`#1B365D`), chữ trắng.
- **Kicker (`.uc-kpi-rf__lead-k`)**: 11px, chữ hoa, khoảng cách chữ 0.4px, độ mờ 0.8.
- **Nội dung tóm tắt (`.uc-kpi-rf__lead-t`)**: 14px, line-height 1.6. Chữ quan trọng nhấn bằng thẻ `<b>`.
- **Narrative pill (`.uc-kpi-rf__nar`)**: Tag nhỏ hiển thị góc nhìn kịch bản.

### 6.4 Thẻ 4 Chỉ số sống còn (`.uc-kpi-rf__bkpi` & `.uc-kpi-rf__bkpis`)

Dành riêng cho màn hình Hội đồng trường / Ban Giám hiệu:

```
┌─[border-left 3px màu trạng thái]──────────────────────────────┐
│ SĨ SỐ HỌC SINH TOÀN TRƯỜNG                     [ĐANG TỐT]    │
│ ───────────────────────────────────────────────────────────── │
│  2,450 HS          ▁▂▃▄▅▆▇ (Sparkline SVG kèm đường target)   │
│  "Đạt 94.2% chỉ tiêu, còn thiếu 150 HS so với kế hoạch"       │
│  [KH: 2,600]   [Chênh: -150]   [NH trước: 2,380]              │
│  Xem vùng tác động (ước tính) ›                               │
└───────────────────────────────────────────────────────────────┘
```

- **Border-left**: 3px tương ứng `.is-good` (`#1a9e4b`), `.is-warn` (`#d9822b`), `.is-bad` (`#d13438`), `.is-none` (`#d1d5db`).
- **Value (`.uc-kpi-rf__bkpi-v`)**: 24px - 28px, font-weight 600, tabular-nums.
- **Mini Sparkline SVG (`.uc-kpi-rf__spark`)**:
  - `viewBox="0 0 120 46"`.
  - Đường line: `.sp-l` (stroke `#3A6EA5`, fill none).
  - Vạch target đứt quãng: `.sp-tg` (stroke-dasharray 3 3).
  - Điểm chốt cuối: `.sp-d.is-last` to hơn và đậm màu.
- **Dải so sánh (`.uc-kpi-rf__cmp`)**: Các chip nhỏ so sánh Kế hoạch, Chênh lệch, Cùng kỳ.
- **Link Drill-down (`.uc-kpi-rf__bkpi-i`)**: "Xem vùng tác động (ước tính) ›", hover có gạch chân, click để mở Impact Drawer.

### 6.5 Khối 3 Điểm lưu ý & Đề xuất quyết định (`.uc-kpi-rf__bcols`)

Bố cục 2 cột chia đôi màn hình:

- **Cột Trái (`.uc-kpi-rf__bbox`)**: "Ba điểm Hội đồng cần lưu ý" (Rủi ro, điểm nghẽn, đơn vị phụ trách kèm nút mở drawer tác động).
- **Cột Phải (`.uc-kpi-rf__bbox.is-dec`)**: "Đề xuất xin quyết định" (Các vấn đề cần Hội đồng phê duyệt ngay trong kỳ họp).
- Đánh số thứ tự tròn nhỏ: `.uc-kpi-rf__bitem-n`.

### 6.6 Dải sức khỏe đo lường (`.uc-kpi-rf__bstrip`)

Thanh công cụ ngang 3 ô click được:
1. Số KPI chiến lược đo được (kèm thanh stack bar tỷ lệ trạng thái).
2. Số điểm lệch số liệu T9 (kèm số điểm từ bản tổng kết).
3. Đơn vị cần giải trình trước Hội đồng.

### 6.7 Bảng dữ liệu chuẩn (`.uc-kpi-rf__table`)

- Header (`th`): Nền `#f3f4f6`, 11px, font-weight 600, màu `--ink2`, chữ căn phải (số) hoặc căn trái (tên).
- Dòng dữ liệu (`td`): 12px, kẻ viền dưới 1px `#f3f2f1`. Khi hover: dòng đổi sáng (`filter: brightness(0.97)`).
- Subtext dưới số (`td small`): 10px, màu `--ink3`, hiển thị chi tiết (ví dụ: `2,450/2,600 · tác động ›`).
- Dòng tổng (`tr.is-total`): Nền `#faf9f8`, border-top 1px `#c8c6c4`, chữ đậm `font-weight: 600`.
- Tô màu cell trạng thái:
  - `.cell-good`: nền `--good-t` (`#e7f4ec`).
  - `.cell-warn`: nền `--warn-t` (`#fdf1e3`).
  - `.cell-bad`: nền `--bad-t` (`#fbe9ea`), chữ `#a4262c`, font-weight 600.
- Thanh tỷ lệ inline (`.uc-kpi-rf__bullet-track`): Thanh tiến độ lồng trong cell bảng hiển thị % đạt so với vạch chỉ tiêu.

### 6.8 Drawer Phân tích tác động (Impact Drawer / Slide-Over)

Khi click vào bất kỳ chỉ số, KPI hoặc cell cảnh báo nào trên giao diện:
- Lớp màn mờ: `.uc-kpi-rf__veil` (nền tối mờ 40%).
- Khung Drawer: `.uc-kpi-rf__drawer` (trượt mượt mà từ cạnh phải, chiều rộng 580px - 640px).
- Cấu trúc:
  - Header (`__dr-head`): Kicker phân loại + Tiêu đề KPI + Nút đóng `✕`.
  - Body (`__dr-body`):
    - Tóm tắt tác động tài chính (Doanh thu mất đi / có thể thu hồi).
    - Phân tích nguyên nhân gốc rễ (Root cause).
    - Các kịch bản hành động can thiệp (Intervention levers).
  - Footer (`__dr-foot`): Nút đóng hoặc nút chuyển sang màn hình Mô phỏng kịch bản.

### 6.9 Bộ Mô phỏng kịch bản & Đòn bẩy điều hành (`page === 5`)

Màn hình thử kịch bản quản trị:
- **Thẻ giá trị quản trị (`.uc-kpi-rf__gv`)**: Chia 3 nhóm (Giá trị tài chính, Mục tiêu chiến lược, Trách nhiệm & nguồn lực).
- **Bảng đòn bẩy (`.uc-kpi-rf__lv`)**: Slider `<input type="range">` cho phép kéo tăng giảm % Lead, Điểm % chuyển đổi, Giảm tỷ lệ rút học, Tuyển bổ sung.
- **Biểu đồ Waterfall / Value Bridge (SVG)**:
  - `viewBox="0 0 640 290"`.
  - Cột tăng (`rect.g-up`): Xanh lá `#d1fae5`, viền `#10b981`.
  - Cột giảm (`rect.g-dn`): Đỏ `#fee2e2`, viền `#ef4444`.
  - Cột nền / chỉ tiêu (`rect.g-base`): Xanh dương `#dbeafe`, viền `#3b82f6`.
  - Đường chỉ tiêu ngang: nét đứt màu cam `stroke: #f59e0b`.

### 6.10 Thẻ Kiểm tra chất lượng dữ liệu & Từ điển KPI (`.uc-kpi-rf__qc`)

Dùng cho trang Dữ liệu & Đối soát / Từ điển KPI:
- Khung thẻ QC: Nền trắng, viền `#e1dfdd`.
- Hiển thị đầy đủ:
  - **Đầu vào (`__qc-in`)**: Dữ liệu thô từ file/phần mềm nào.
  - **Công thức (`__qc-why`)**: Công thức chuẩn hóa.
  - **Đầu ra (`__qc-out`)**: Kết quả tính toán.
  - **Đánh giá (`__qc-verdict`)**: Mức độ tin cậy của số liệu (Tin cậy / Cần đối soát / Không khớp).

---

## 7. Interaction Patterns & Chế độ vận hành

### 7.1 Chế độ Trình chiếu phòng họp (`present mode`)

- Kích hoạt qua nút "Trình chiếu" trên header hoặc phím tắt.
- Toàn bộ wrapper nhận class `.is-present`.
- CSS tự động:
  - Ẩn các bộ lọc rườm rà (slicers), thanh cuộn phụ và các nút thao tác kỹ thuật.
  - Cỡ chữ toàn trang tăng ~15-20% để đọc rõ từ khoảng cách 3-5m trong phòng họp.
  - Tab chuyển trang chuyển sang dạng thanh gọn với nút "Thoát trình chiếu" ở góc phải.

### 7.2 Cơ chế Điều hướng trang (`page` state)

Không sử dụng Vue Router hay Vuetify tabs (`v-tabs`, `v-window`). Toàn bộ module sử dụng biến số `page` để chuyển view:

| `page` | Tên màn hình | Mục đích chính |
| ------ | ------------ | -------------- |
| 0 | **Hội đồng trường** | Tóm tắt cấp cao: 4 chỉ số sống còn, 3 điểm lưu ý, đề xuất quyết định |
| 1 | **Quy mô & Giữ chân** | Sĩ số theo khối, dòng vào-ra học sinh, lý do rút hồ sơ |
| 2 | **Tuyển sinh & Chuyển đổi** | Phễu tuyển sinh, tỷ lệ chốt hồ sơ, chi phí tuyển sinh (CAC) |
| 3 | **KPI Chiến lược** | Khung kết quả 4 tầng, tiến độ MASTER KPI |
| 4 | **Dữ liệu & Đối soát** | Điểm lệch dữ liệu, độ tin cậy báo cáo, kiểm tra chéo T8-T9 |
| 5 | **Mô phỏng kịch bản** | Thử đòn bẩy quản trị, tính toán ROI, Value bridge |
| 6 | **Bản đồ tuyển sinh** | Dòng học sinh chuyển cấp nội bộ (Feeder), sở hữu Lead |
| 7 | **Đối chuẩn cạnh tranh** | So sánh học phí và quy mô với các trường tư thục đối thủ |
| 8 | **Vận hành ưu tiên** | Báo cáo chi tiết công việc trọng tâm từng đơn vị |
| 9 | **Từ điển KPI** | Định nghĩa, công thức và tần suất chốt toàn bộ KPI |

### 7.3 Click-to-Drilldown

Mọi dòng trong bảng hoặc thẻ KPI có khả năng tương tác đều gắn class `.is-click` kèm thuộc tính HTML `title` mô tả hành động (ví dụ: `title="Bấm để xem vùng tác động"`). Con trỏ chuột chuyển `cursor: pointer`.

---

## 8. Quy định Nghiêm ngặt (Checklist Không được làm)

> [!CAUTION]
> Bất kỳ component KPI nào vi phạm các điều sau đều bị coi là không đạt chuẩn:

1. **KHÔNG viết CSS vào file `.vue`**: Tuyệt đối không dùng `<style scoped>` hay inline `style="..."`. Mọi CSS phải chuyển về `style.css` của module.
2. **KHÔNG tạo class CSS không có namespace**: Bắt buộc có prefix (ví dụ `.uc-kpi-rf__*` hoặc `.uc-kpi-[module]__*`).
3. **KHÔNG bo góc lớn**: Tuyệt đối không dùng `rounded-lg`, `rounded-xl`, `border-radius: 8px/12px`. Chỉ dùng `2px` hoặc `rounded-xs`.
4. **KHÔNG dùng màu nền sặc sỡ cho thẻ card**: Card dữ liệu luôn nền trắng (`--card: #ffffff`), viền mờ (`--line: #e1dfdd`). Màu chỉ dùng cho viền trạng thái (border-left) hoặc badge nhỏ.
5. **KHÔNG dùng component Tab nặng của Vuetify (`v-tabs`, `v-tab-item`, `v-window`)**: Dùng thanh tab phẳng và biến số `page` với `v-if`.
6. **KHÔNG nhúng thư viện đồ thị nặng bên ngoài** (như Chart.js, Highcharts, ECharts): Mọi biểu đồ (Waterfall, Sparkline, Bullet track) đều được dựng bằng **SVG thuần hoặc HTML/CSS** để đạt tốc độ tải tức thì, tối ưu in ấn và không phụ thuộc runtime bên ngoài.
7. **KHÔNG quên `tabular-nums`**: Mọi vị trí hiển thị số liệu tiền tệ, học sinh, tỷ lệ % bắt buộc dùng font tabular-nums để số thẳng hàng.
