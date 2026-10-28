# Codex Rules — LHBS eSign · KPI Workspace

## HARD RULE

You MUST:

1. Read this file first.
2. Summarize relevant rules briefly.
3. **Chỉ được sửa code và SQL liên quan đến KPI** — tuyệt đối không đụng vào module `ks-*`, `tkb-*`, `wf-*` hay bất kỳ thứ gì không có prefix `kpi-`.
4. **Triết lý Dữ liệu & Tương quan Chỉ số (Cross-KPI Correlation)**: Dashboard KHÔNG ĐƯỢC chỉ hiển thị những con số thuần túy, rời rạc, vô tri vô giác. Mọi visual và báo cáo phải thể hiện được:
   - **Sự liên quan và giao thoa giữa các con số**: Chỉ số này ảnh hưởng thế nào đến chỉ số khác (ví dụ: Rút học vì xa nhà tác động tuyến xe bus và doanh thu; Học liệu số/LMS tác động chất lượng và giữ chân HS).
   - **Chuỗi nhân quả (Cause-and-Effect Chain)**: Bám sát Results Framework (Hoạt động -> Đầu ra -> Kết quả -> Tác động tài chính/quy mô).
   - **Vùng tác động và Ý nghĩa điều hành**: Lượng hóa được tác động tài chính, rủi ro và đề xuất hành động cho Hội đồng trường.
   - **Dữ liệu động theo kỳ chốt (Period Freeze)**: Thiết kế để nạp động và đóng băng dữ liệu theo Tuần / Tháng / Quý / Năm, không hard-code số tĩnh.
5. Then act.

Nếu không thực hiện đúng thứ tự trên, response là invalid.

---

## 2. Cấu trúc project thực tế

```text
project-root/
├── .md/
│   ├── AGENTS.md                ← file này
│   └── DESIGN.md                ← Design system cho toàn bộ module kpi-*
├── components/                  ← Global components (prefix uc-*)
│   ├── _components.json
│   ├── uc-avatar.vue
│   ├── uc-empty.vue
│   ├── uc-file-upload.vue
│   ├── uc-loading.vue
│   ├── uc-modal.vue
│   ├── uc-notification-dropdown.vue
│   ├── uc-request-sign-canvas.vue
│   ├── uc-select-user.vue
│   ├── uc-table.vue
│   ├── uc-tkb-*.vue             ← tkb-specific, không đụng
│   └── uc-wf-shell.vue
├── imports/                     ← Global JS/CSS (scope: project)
│   ├── _imports.json
│   ├── global-util-js-03DA6AAE5A0B4213B5BD4B852EF282AE.js  ← ajaxCALLPromise, ajaxGETCALLPromise
│   ├── wf-helpers-js-*.js       ← apiCall, apiCallAsync, showToast, showConfirm, ajaxCALL_File
│   ├── wf-pdf-helper-js-*.js    ← PDF utilities
│   ├── wf-formula-js-*.js       ← formula helpers
│   ├── wf-global-style-css-*.css
│   ├── ks-design-system-css-*.css
│   └── ks-signing-detail-css-*.css
├── _db/
│   ├── _connections.json        ← DB: esign → eSignature @ 58.187.42.172
│   └── esign/
│       └── schema.json          ← 326 procedures, 150 tables (SQL Server)
├── docs/
└── modules/
    ├── _modules.json
    ├── kpi-results-framework/   ← ✅ SCOPE: module KPI duy nhất hiện tại
    │   ├── module.json          ← mount entry component, state tĩnh tối thiểu
    │   ├── script.js            ← để trống với module mới
    │   ├── style.css            ← CSS riêng của module (prefix uc-kpi-rf__)
    │   ├── body.html
    │   ├── header.html
    │   ├── _moduleInfo.json
    │   ├── _publishState.json
    │   ├── components/
    │   │   ├── _components.json
    │   │   └── uc-kpi-rf.vue    ← entry component hiện tại
    │   └── imports/
    │       └── _imports.json    ← import riêng của module (hiện rỗng)
    ├── ks-*/                    ← ⛔ NGOÀI SCOPE
    ├── tkb-*/                   ← ⛔ NGOÀI SCOPE
    └── wf-*/                    ← ⛔ NGOÀI SCOPE
```

---

## 3. Phạm vi sửa — KPI ONLY

### Được phép sửa

| Loại         | Đường dẫn                                         |
| ------------ | ------------------------------------------------- |
| FE component | `modules/kpi-*/components/*.vue`                  |
| FE style     | `modules/kpi-*/style.css`                         |
| FE module    | `modules/kpi-*/module.json` (khi cần)             |
| FE script    | `modules/kpi-*/script.js` (khi cần, hiếm)         |
| FE import    | `modules/kpi-*/imports/_imports.json`             |
| Global util  | `imports/global-util-js-03DA6AAE5A0B4213B5BD4B852EF282AE.js` (khi root cause nằm ở đây) |
| SQL          | Stored procedure / table có tên chứa `KPI` hoặc phục vụ module `kpi-*` |

### Tuyệt đối KHÔNG sửa

- `modules/ks-*`, `modules/tkb-*`, `modules/wf-*`
- `components/uc-tkb-*.vue`, `components/uc-wf-shell.vue`
- `imports/wf-helpers-js-*.js` (chỉ đọc để tra cứu helper)
- `imports/ks-*.css`
- Bất kỳ SQL nào không liên quan đến KPI

### Quy tắc an toàn chung

- Không sửa lan sang module khác dù bug có liên quan gián tiếp.
- Không đổi contract API/schema nếu user không yêu cầu.
- Không tự tạo abstraction hoặc component dùng chung nếu chưa có nhu cầu thật.
- File/thư mục bắt đầu bằng `_` là bản tạm hoặc config platform: đọc để hiểu, không sửa trừ khi cần thiết.

---

## 4. Runtime và UI pattern

- Project dùng Vue single-file component theo **Options API**.
- Runtime thực tế: **Vue 3.5 / Vuetify 3**.
- Bám syntax hiện có, ưu tiên tương thích ngược:
  - Tabs: dùng `v-window` + `v-window-item` (không dùng `v-tabs-items`, `v-tab-item`).
  - Input: dùng `:model-value` + `@update:model-value` thay vì `:value` + `@input`.
  - Button attrs: `fab`, `outlined`, `small`, `x-small`, `dense`, `hide-details`.
- Toast: `showToast.success/error(text)` (helper global trong `wf-helpers-js`) hoặc `Vue.$toast`.
- Confirm: `showConfirm(text, onOk, onCancel)` hoặc `confirm({ title, action, onclose })`.
- **Không** dùng Composition API.
- **Không** dùng Vuetify 3-only props (`variant`, `density`) nếu file hiện tại chưa dùng.

### CSS rules

- Tuyệt đối KHÔNG viết CSS trong `.vue` (kể cả `<style scoped>` và inline `style=""`).
- CSS module KPI viết tại `modules/kpi-*/style.css`, dùng prefix namespace theo DESIGN.md.
- Ưu tiên Vuetify utility class trước khi viết CSS tay.
- `border-radius` tối đa `2px` (`rounded-xs`) — không dùng `rounded-lg`, `rounded-xl`.
- Tham khảo DESIGN.md để biết token màu, typography, component pattern.

### Responsive & Screen Resolution rules (HD, Full HD, 2K)

- **BẮT BUỘC** luôn tính tới và kiểm tra responsive cho các độ phân giải màn hình:
  - **HD / Laptop phổ thông (1280x720 – 1366x768)**: Lưới card co giãn thông minh (lưới 4 cột tự động chuyển thành 2 cột), bảng dữ liệu có thanh cuộn ngang riêng (`overflow-x: auto`), tuyệt đối không làm tràn ngang trang.
  - **Full HD (1920x1080)**: Chuẩn tối ưu mặc định. Khung trang tràn viền `width: 100%` (KHÔNG khóa cứng `max-width: 1440px`), dàn đều các cột và bảng biểu.
  - **2K / Màn hình lớn (2560x1440 trở lên)**: Tận dụng tối đa không gian màn hình, nội dung co giãn tự nhiên, modal/drawer co giãn theo tỉ lệ `vw`/`vh`, không để khoảng trống vô nghĩa hai bên sườn.
- **Toàn màn hình (Presentation / Fullscreen)**: Hỗ trợ kích hoạt chuẩn HTML5 Fullscreen API khi user bật chế độ trình chiếu.

### Text

- UI text mặc định tiếng Việt có dấu.

---

## 5. Component pattern

### Component global (đọc-only, không tự sửa)

| Component            | Mô tả                                              |
| -------------------- | -------------------------------------------------- |
| `uc-avatar`          | Avatar người dùng                                  |
| `uc-empty`           | Trạng thái dữ liệu trống                           |
| `uc-file-upload`     | Upload file                                        |
| `uc-loading`         | Loading overlay                                    |
| `uc-modal`           | Base modal wrapper                                 |
| `uc-select-user`     | Dropdown chọn người dùng                           |
| `uc-table`           | Bảng dữ liệu chuẩn                                 |

### Component KPI (ưu tiên cấu trúc chuẩn khi viết mới)

- `uc-main-page.vue`: entry point, xử lý logic, gọi API.
- `uc-main-view.vue`: table + toolbar, dumb component.
- `uc-stats.vue`: card thống kê tổng quan.
- `uc-modal-add.vue` / `uc-modal-edit.vue`: modal CRUD.
- `uc-modal-import.vue`: modal import Excel nếu cần.

### Cấu trúc script chuẩn

```vue
<script>
export default {
  name: "uc-ten-component",
  props: {},
  emits: ["on-event"],
  data() {
    return {};
  },
  computed: {},
  watch: {},
  mounted() {},
  methods: {},
};
</script>
```

### Quy tắc chi tiết

- **Không import/khai báo component con** — platform tự nhận diện.
- **Không khai báo biến/function ngoài `export default`.**
- **Không inline function trong template** — luôn định nghĩa trong `methods`.
- **Props luôn có `default` value.**
- **Emit naming**: kebab-case, prefix `on-`: `on-reload`, `on-save`. Ngoại lệ: `update:modelValue`.
- **File tối đa 1000 dòng** — vượt 800 → lên kế hoạch tách component con.
- **`v-if` mặc định**; dùng `v-show` chỉ khi toggle thường xuyên + component nặng.
- **Không gom state lồng nhau** — khai báo phẳng: `isModalOpen`, không phải `ui.modal.open`.
- **Ngoại lệ**: form data cho modal được phép gom vào `form: {}`.

**Thứ tự trong `data()`:**
1. Biến điều khiển dialog/modal
2. Dữ liệu từ API (`tableRows`, `statsData`…)
3. Biến local (`saving`, `loading`, `editItem`…)

**Thứ tự trong `methods()`:**
1. Helper, reset, format (`initData`, `resetForm`, `formatDate`…)
2. Event handler UI (`openModal`, `onSelect`, `onClose`…)
3. API calls (`fetchList`, `saveItem`, `deleteItem`…)

---

## 6. Luồng data/control

### module.json

- Chỉ mount component entry và khai báo state tĩnh tối thiểu.
- **Không gọi API trong `module.json`.**
- Không thêm action `API`, `IN`, `OUT`, `CALLBACK`, `CALL`, `EXE`.
- Không đổi nếu chỉ cần sửa render/UI.

```json
{
  "data": [{}],
  "watch": {},
  "controls": [
    {
      "prop": "fluid pa-0 ma-0",
      "rows": [{ "cols": [{ "el": "uc-kpi-rf", "w": 12, "attr": {} }] }]
    }
  ],
  "set": { "menu": false }
}
```

### script.js

- Module mới/refactor: để trống.
- Chỉ sửa khi root cause là flow legacy bắt buộc.

---

## 7. Cách gọi API

### Helpers có sẵn (global, không cần import)

```javascript
// global-util-js-03DA6AAE5A0B4213B5BD4B852EF282AE.js
ajaxCALLPromise(url, params)     // POST → trả res.data, tự handle error + toast
ajaxGETCALLPromise(url, params)  // GET với Authorization header, tự handle error + toast

// wf-helpers-js-*.js
apiCall(url, params, onSuccess, onError)  // POST với console log có màu
apiCallAsync(url, params)                 // wrap apiCall → Promise<res.data>
ajaxCALL_File(URL, formData, cb, errCb)   // upload file multipart

// utilities
showToast.success(text) / showToast.error(text) / showToast.info(text)
showConfirm(text, onOk, onCancel)
jsonToExcel({ data, filename, worksheet })
```

### Quy tắc gọi API

- Dùng `ajaxCALLPromise` cho POST mới — **không** dùng `this.ajaxCALLPromise`.
- Dùng `ajaxGETCALLPromise` cho GET có Authorization.
- Không cần `try/catch` quanh `ajaxCALLPromise` — đã tự handle. Chỉ dùng `finally` khi cần reset loading.
- Không bọc `vueData.v_Loading = true/false` thủ công.
- `ajaxCALLPromise` trả trực tiếp `res.data` (không phải `res`).
- Endpoint dạng `"/KPI_Get"`, không tự thêm `/work/`.
- Nhiều result set: `data[0]` = set đầu, `data[0][0]` = row đầu.

```javascript
// Pattern chuẩn
async fetchList() {
  const params = { NamHoc: this.namHoc };
  this.tableRows = await ajaxCALLPromise("/KPI_Get", params);
},
```

### Feedback sau API

- Thành công: `showToast.success("Lưu thành công")`
- Lỗi: `showToast.error(message)`
- Xác nhận: `showConfirm("Bạn có chắc?", async () => { ... })`

---

## 8. SQL / Backend scope

- Chỉ được viết/sửa stored procedure và table liên quan đến module `kpi-*`.
- Naming convention SP: `spAPI_KPI_[Chức năng]` hoặc `sp_KPI_[Chức năng]`.
- Không tự thay đổi SP của các domain khác (`TKB`, `WF`, `KS`).
- DB: SQL Server, connection `esign` → database `eSignature`.
- Khi cần biết schema: tra `_db/esign/schema.json`.

---

## 9. Debug checklist

Trace theo thứ tự:

1. **Input**: user action, params, form data, `vueData`.
2. **Process**: method/component/script nào chạy.
3. **State**: biến local, `vueData.OUT`, loading/dialog state.
4. **Output**: UI render, table rows, modal, toast.
5. **Side effects**: API call, reload, chart update.

Không bắt đầu từ CSS nếu bug có dấu hiệu data/API/state.

---

## 10. Quy tắc vueData

- **Chỉ đọc** `vueData` tại entry point (`uc-main-page` / `uc-kpi-rf`): `vueData?.v_Set`, `vueData?.NamHoc`.
- **Không dùng** `vueData` tại component con — truyền qua `props`.
- **Không ghi** `vueData.v_Loading` thủ công.

---

## 11. Verify

- Không có build/tsc script chuẩn — verify bằng đọc code, grep, diff.
- Không cần chạy test khi không được yêu cầu.
- Không chạy `rm`, `git reset`, `git commit`, `git push` khi không được yêu cầu.

---

## 12. Format trả lời

**Fix bug:**
```
- Lỗi:
- Nguyên nhân:
- Cách sửa:
- Side effects:
```

**Phân tích:**
```
- Vấn đề:
- Luồng: Input → Process → State → Output → Side effects
- Điểm sai:
- Cách sửa:
```

**Sau khi sửa:**
- Nêu file đã sửa.
- Nêu root cause.
- Nêu cách verify ngắn gọn.

---

## 13. Checklist trước khi sửa

- [ ] Đã đọc AGENTS.md.
- [ ] File cần sửa nằm trong `modules/kpi-*` hoặc SQL liên quan KPI.
- [ ] Đã xác định root cause hoặc nêu rõ assumption.
- [ ] Patch minimal diff — không rewrite nếu không cần.
- [ ] Không đụng `module.json` / `script.js` nếu không cần.
- [ ] API dùng đúng `ajaxCALLPromise` (không dùng `this.` prefix).
- [ ] Không set `vueData.v_Loading` thủ công.
- [ ] Không inline function trong template.
- [ ] Không khai báo biến/function ngoài `export default`.
- [ ] Props luôn có `default`.
- [ ] Emit theo prefix `on-` kebab-case.
- [ ] File component không vượt 1000 dòng.
- [ ] CSS viết tại `style.css`, có namespace prefix đúng.

---

## 14. Quy ước đặt tên

| Loại            | Quy tắc                          | Ví dụ                                   |
| --------------- | -------------------------------- | --------------------------------------- |
| Module folder   | kebab-case, prefix `kpi-`        | `kpi-results-framework`                 |
| Component entry | `uc-kpi-[slug].vue`              | `uc-kpi-rf.vue`                         |
| Component mới   | `uc-[chức năng].vue`             | `uc-main-view.vue`, `uc-modal-add.vue`  |
| CSS class       | `uc-kpi-[slug]__[block]-[el]`    | `uc-kpi-rf__table`, `uc-kpi-rf__bkpi-v` |
| SQL SP          | `spAPI_KPI_[Chức năng]`          | `spAPI_KPI_Dashboard_Get`               |
| Biến data       | camelCase, tường minh            | `isTableReady`, `tableRows`, `editItem` |
| Emit event      | kebab-case, prefix `on-`         | `on-reload`, `on-save`                  |
| Props           | camelCase                        | `tableRows`, `isVisible`                |
