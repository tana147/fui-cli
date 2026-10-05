# Codex Rules - NCKH

## HARD RULE

You MUST:

- Read this instruction file first.
- Summarize the relevant rules briefly.
- Then act.

If not, the response is invalid.

---

## 1. Phong cách làm việc

- Trả lời bằng tiếng Việt, ngắn gọn, thực dụng.
- Ưu tiên root cause, không fix triệu chứng.
- Luôn phân tích theo: Input -> Process -> State -> Output -> Side effects.
- Khi thiếu thông tin: nêu assumption rõ ràng, chọn cách ít ảnh hưởng nhất, không block nếu vẫn sửa an toàn.
- Khi nhiều cách: chọn 1 cách tốt nhất, ưu tiên local fix -> logic -> structure -> redesign.
- Minimal diff, giữ style code hiện tại, không rewrite nếu không cần.

---

## 2. Cấu trúc project thực tế

```text
project-root/
├── .md/
│   └── AGENTS.md
├── components/
│   ├── c-table.vue
│   ├── c-text-field-format-price.vue
│   └── c-text-field-sqd.vue
├── imports/
│   ├── script-main.js
│   └── style-main.css
└── modules/
    └── [TenModule]/
        ├── raw.json
        ├── script.js
        ├── components/
        │   ├── uc-main-page.vue
        │   ├── uc-main-view.vue
        │   ├── uc-stats.vue
        │   ├── uc-modal-add.vue
        │   ├── uc-modal-edit.vue
        │   └── uc-modal-import.vue
        └── imports/
            └── customCss.css (hoặc style.css, text-css.css...)
```

Ghi chú:

- Root **không có** `proj.json`.
- Root `components/` là global component tổng của dự án, hiện theo prefix `c-*`.
- Root `imports/script-main.js` chứa global helpers: `ajaxCALLPromise`, `formatAsCurrency`, `convertDiem`, `getColorStatusAnPham`, `ImportChartLabelsPlugin`.
- `modules/*/components/*.vue` là nơi code UI chính.
- `modules/*/raw.json` chỉ nên khai báo state tĩnh tối thiểu và control mount page.
- Với module mới hoặc refactor có chủ đích, ưu tiên cấu trúc chuẩn ở trên.
- `raw.json` mount `uc-main-page`.
- `raw.json` không gọi API. Không thêm action kiểu `API`, `CALL`, `IN`, `OUT`, `CALLBACK` vào `raw.json` cho code mới/refactor.
- `script.js` ưu tiên để trống. Chỉ thêm logic vào `script.js` khi platform integration bắt buộc hoặc module legacy đã có pattern đó. Hiện ~15 module có `script.js` non-empty (legacy).
- CSS riêng đặt tại `modules/[TenModule]/imports/`. Tên file không bắt buộc `customCss.css` — thực tế có `customCss.css`, `style.css`, `style-dashboard.css`, `text-css.css`.
- Module imports cũng có thể chứa file `.js` helper riêng (VD: `htmlToPdfmake.js.js`).
- Repo hiện có nhiều module legacy chưa đúng chuẩn này. Cụ thể:
  - Entry point legacy: `uc-main.vue` (hdkh-profile, hdkh-tong-ket-nam-hoc), `uc-main-component.vue` (dashboard).
  - ~20 module không có entry point chuẩn (`uc-main-page`), component đặt tên theo nghiệp vụ trực tiếp: `uc-table-*`, `uc-an-pham`, `uc-my-papers`, `uc-form-quanly-*`, `danh-sach-quyet-dinh`...
  - Khi sửa bug nhỏ trong legacy module, không đổi cấu trúc nếu không cần.
- Các module có suffix `-BK`, `-COPY` là bản backup/copy — bỏ qua, không sửa: `approve-request-BK`, `hdkh-quan-ly-mien-giam-COPY`, `papers-reward-BK`.

---

## 3. Phạm vi sửa file

### Mặc định được sửa khi đúng scope user yêu cầu

- `modules/[module]/components/*.vue`
- `modules/[module]/imports/*.css`
- `modules/[module]/imports/*.js`

### Chỉ sửa khi user yêu cầu rõ hoặc root cause bắt buộc

- `modules/[module]/raw.json`
- `modules/[module]/script.js`
- `components/*.vue`
- `imports/script-main.js`
- `imports/style-main.css`

### Quy tắc an toàn

- Không sửa lan sang module khác nếu bug không liên quan.
- Không đổi contract API/schema nếu user không yêu cầu.
- Không tự tạo abstraction hoặc component dùng chung nếu chưa có nhu cầu thật.
- File/thư mục bắt đầu bằng `_` hoặc `___` là bản tạm: bỏ qua, không đọc sâu, không sửa.
- Thư mục copy có tên rõ như `*-COPY` không tự sửa trừ khi user chỉ đúng folder đó.

---

## 4. Runtime và UI pattern

- Project dùng Vue single-file component theo Options API.
- Bám syntax hiện có của repo, đang giống Vue 2/Vuetify 2 hơn Vuetify 3:
  - `v-data-table`, `v-card`, `v-dialog`, `v-row`, `v-col`, `v-tabs`.
  - Do runtime thực tế chạy Vue 3.5 / Vuetify 3, để làm tabs: dùng `v-window` và `v-window-item` thay thế cho `v-tabs-items` và `v-tab-item` để tránh lỗi Resolve Component.
  - Các input component (như `v-select`) trong môi trường Vue 3 dùng `:model-value` và `@update:model-value` thay vì `:value` và `@input`.
  - Button hay dùng `fab`, `outlined`, `small`, `x-small`, `dense`, `hide-details`.
  - Toast dùng `Vue.$toast`.
  - Confirm dùng `confirm({ title, action, onclose })`.
- Không tự đổi sang Vuetify 3 pattern như `variant`, `density`, `prepend-icon` nếu file hiện tại không dùng.
- Không dùng Composition API nếu module đang viết Options API.
- Tuyệt đối KHÔNG sử dụng CSS trực tiếp trong file .vue (bao gồm cả `<style scoped>` và thuộc tính inline `style="..."`). Buộc phải sử dụng class và viết CSS tại file trong thư mục import/style (như `imports/styles.css` hoặc `style.css` của module).
- **Quy tắc viết CSS**: Tránh viết CSS đụng global CSS làm ảnh hưởng tới toàn hệ thống. Chỉ đặt thêm class có scope cụ thể (namespace riêng biệt) để css chỉ ảnh hưởng ở module hiện tại. Ưu tiên sử dụng utility class của Vuetify trước khi tự viết CSS.
- Ưu tiên Vuetify utility class và style sẵn có trong module trước khi thêm CSS mới.
- **Ưu tiên dùng class có sẵn của Vuetify** (spacing, typography, color, layout…) để styling. Chỉ viết CSS tay khi Vuetify không có class phù hợp.
- **Quy tắc bo góc (Border Radius)**: Đối với border radius, chỉ dùng `xs` (`rounded-xs`) hoặc CSS thủ công là `2px`. Tuyệt đối không dùng các góc bo lớn hơn để tránh phá vỡ giao diện chuẩn.
- **Ô tìm kiếm nhanh (`c-underline-search`)**: Khi khai báo ô tìm kiếm nhanh bằng `<v-text-field>`, bắt buộc gắn `class="c-underline-search"` để hiển thị đường gạch chân mờ chuẩn hệ thống. **Icon tìm kiếm phải nằm ở phía trước**: Bắt buộc sử dụng thuộc tính `prepend-inner-icon="mdi-magnify"`, tuyệt đối không dùng `append-icon`.
- **Nút xuất Excel cạnh thanh tìm kiếm**: Thay vì tạo 1 button xuất Excel dạng text to độc lập ở ngoài bảng, đặt icon button `<v-btn icon color="success" class="mr-2" :loading="isLoadingExport" @click="onPrintExcel" title="Xuất file Excel"><v-icon>mdi-microsoft-excel</v-icon></v-btn>` ngay bên trong `<v-card-title>` liền kề trước thanh tìm kiếm để tiết kiệm diện tích.
- **Hàm xuất Excel toàn cục (`jsonToExcel`)**: Khi xuất file Excel từ dữ liệu bảng/JSON, bắt buộc gọi trực tiếp hàm tiện ích toàn cục có sẵn của hệ thống:
  ```javascript
  jsonToExcel({
    data: dataExport,
    filename: "TenFile.xlsx",
    worksheet: "Sheet1",
  });
  ```
  Tuyệt đối không viết thêm các đoạn code kiểm tra điều kiện `typeof jsonToExcel !== 'undefined'` hay code fallback sang thư viện ngoài.
- **Cuộn nội bộ trong bảng (`fixed-header`)**: Mọi bảng dữ liệu `<v-data-table>` / `<v-simple-table>` bắt buộc dùng `fixed-header` và giới hạn chiều cao `height="calc(100vh - 250px)"` (hoặc tính toán trừ đi chiều cao filter/topbar) để scrollbar nằm nội bộ trong bảng, không làm scroll toàn bộ trang web.
- **Hạn chế CSS animation** (`transition`, `hover`, `transform`, `keyframes`…). Mục đích: đảm bảo tương thích trình duyệt bản cũ. Chỉ dùng khi user yêu cầu rõ ràng.
- Text UI mặc định là tiếng Việt có dấu.

---

## 5. Component pattern

### Component tổng/global

- Root global component hiện có (chỉ 3 file):
  - `c-table.vue`
  - `c-text-field-format-price.vue`
  - `c-text-field-sqd.vue`
- Chỉ sửa global component khi bug nằm ở component tổng hoặc user yêu cầu rõ.
- Nếu chỉ 1 module cần behavior riêng, ưu tiên sửa local trong module thay vì đổi global.

### Component trong module

- Module component thường dùng prefix `uc-*`.
- Với module mới/refactor, ưu tiên cấu trúc component:
  - `uc-main-page.vue`: entry point, xử lý logic, khai báo component, gọi API.
  - `uc-main-view.vue`: hiển thị table + toolbar, dumb component.
  - `uc-stats.vue`: card thống kê tổng quan nếu cần.
  - `uc-modal-add.vue`: modal thêm mới.
  - `uc-modal-edit.vue`: modal chỉnh sửa.
  - `uc-modal-import.vue`: modal import Excel nếu cần.
- `uc-main-page` là nơi gọi API chính bằng `ajaxCALLPromise`.
- `uc-main-view`, `uc-stats`, `uc-modal-*` ưu tiên nhận `props` và `$emit`, không tự gọi API nếu không cần.
- Module legacy đang dùng nhiều pattern entry khác nhau:
  - `uc-main.vue`: hdkh-profile, hdkh-tong-ket-nam-hoc.
  - `uc-main-component.vue`: dashboard (85KB script.js — module legacy nặng nhất).
  - Không có entry point rõ: detai-nckh-coso (`uc-table-*`), my-papers (`uc-my-papers`, `uc-an-pham`), hdkh-nckh-dashboard (`uc-nckh-admin-dashboard`)...
  - Khi sửa bug nhỏ thì mirror cấu trúc hiện tại, không rename hàng loạt.
- Khi thêm/sửa component, mirror naming và structure của module hiện tại.
- Khi user yêu cầu chuẩn hoá cấu trúc, chuyển dần về layout chuẩn trên.

### Cấu trúc script ưu tiên

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

- Luôn khai báo `name` theo pattern `uc-[chức năng]` hoặc `uc-main-page`.
- Luôn khai báo `emits` array khi component phát event.

Giữ thứ tự nếu file hiện tại đã có style riêng. Không format lại toàn file.

### Syntax an toàn cho runtime

```javascript
// ✅ Nên dùng
data: function () { return {} }
methods: { foo: function () {} }

// ✅ Được phép (phổ biến trong project)
data() { return {} }
methods: { foo() {} }
async fetchData() {}
await ajaxCALLPromise(...)

// ❌ Tránh
// Object spread trong reactive data
// Dấu ; sau export default { ... };
```

### Quy tắc viết component chi tiết

**Không cần import, khai báo component con:** Hệ thống tự động nhận diện và import. Chỉ cần viết trực tiếp tag component (như `uc-*`, `c-*`) trong `<template>`, không import và không khai báo trong `components: {}` của phần script.

**Naming convention component:**

- Entry point: `uc-main-page`
- Modal/dialog: `uc-modal-[đối tượng]` (ví dụ: `uc-modal-add`, `uc-modal-edit`)
- Danh sách/table view: `uc-main-view` hoặc `uc-list-[đối tượng]`
- Chi tiết: `uc-detail-[đối tượng]`
- Form nhập liệu: `uc-form-[đối tượng]`
- Bộ lọc: `uc-filter-[đối tượng]`
- Thống kê: `uc-stats` hoặc `uc-stats-[đối tượng]`
- Select/dropdown: `uc-select-[đối tượng]`

**Kích thước file:** Tối đa 800–1000 dòng. Vượt 800 → lên kế hoạch tách component con.

**Không inline function trong template:** Không viết inline function hoặc emit trực tiếp trong template. Luôn định nghĩa function trong `methods` rồi gọi từ template để đảm bảo parser-safe và dễ debug.

**Không khai báo biến/function ngoài `export default`:** Không dùng `let`, `const`, `var` hay `function` bên ngoài `export default`. Mọi state trong `data()`, mọi logic trong `methods`, `computed`, hoặc `mounted`.

**Thứ tự biến trong `data()`:**

1. Biến điều khiển dialog/modal (`isAddModalOpen`, `isEditModalOpen`…)
2. Mảng/object chứa dữ liệu từ API (`tableRows`, `listLoai`, `statsData`…)
3. Biến local của component (`saving`, `loading`, `editItem`, `searchText`…)

**Không gom nhóm state lồng nhau:** KHÔNG gom biến vào object lồng nhau kiểu `dialogState: { boPhan: { visible: false } }`. Đặt tên biến tường minh, phẳng: `isBoPhanModalOpen`, `selectedBoPhanId`… Ngoại lệ: biến form data cho modal/form được phép gom vào 1 object `form` để tiện submit API.

**Data locality — khai báo data ở component dùng nó:** Nếu một biến chỉ dùng trong 1 component (ví dụ: `saving`, `form`, `isExpanded` trong modal), khai báo thẳng trong `data()` của component đó. Không đưa lên `uc-main-page` hay `uc-main-view` rồi truyền xuống qua props nếu component cha không cần dùng biến đó.

**Thứ tự function trong `methods`:**

1. Hàm khởi tạo/reset/format (`initData`, `resetForm`, `initTableHeaders`…)
2. Hàm gọi API (`fetchList`, `saveItem`, `deleteItem`…)
3. Hàm xử lý event/UI (`openAddModal`, `handleDelete`, `onSave`…)

**`v-if` vs `v-show`:** Mặc định dùng `v-if`. Chỉ đổi sang `v-show` khi toggle thường xuyên và component nặng — đề xuất cho user trước khi đổi.

**`computed` vs `methods`:** Logic cache được (derived từ reactive data, không side effect) → dùng `computed`. Có side effect hoặc cần gọi mỗi lần → dùng `methods`.

**Props convention:** 
- Luôn khai báo `default` value để tránh bug. Ví dụ: `tableRows: { type: Array, default: () => [] }`, `isVisible: { type: Boolean, default: false }`, `editItem: { type: Object, default: () => ({}) }`.
- **Quy tắc đặt tên (Script)**: Phải đặt tên prop theo camelCase chuẩn và đơn giản (chỉ viết hoa chữ cái đầu tiên của từ tiếp theo, ví dụ: `nhanVienId`, `dmGetAll`). **Tránh** dùng ký tự viết hoa liên tiếp ở cuối hoặc gạch dưới (như `nhanVienID`, `DM_GetALL`) vì sẽ gây lỗi khi Vue mapping sang kebab-case ở một số môi trường runtime.
- **Quy tắc binding (Template)**: Khi truyền prop ở component cha trong template, bắt buộc viết ở dạng kebab-case chuẩn (ví dụ: `:nhan-vien-id="NhanVienID"`, `:dm-get-all="DM_GetALL"`). Tránh dùng camelCase trực tiếp trong template HTML để không bị trình duyệt tự động lowercase gây lỗi `undefined` prop ở component con.


**Emit naming:** Đặt tên emit theo kebab-case, prefix `on-`: `on-reload`, `on-save`, `on-edit`, `on-delete`. Khai báo: `emits: ['on-reload']`. Bind: `@on-reload="initData"`. Ngoại lệ: `update:modelValue` giữ nguyên theo convention Vue.

**Ưu tiên component có sẵn:** Mặc định dùng global component của dự án (`c-table`, `c-text-field-format-price`, `c-text-field-sqd`) và component của Vuetify trước. Không tự tạo component thay thế nếu đã có sẵn.

**Không tạo generic/abstract component:** Không tạo component quá trừu tượng, quá nhiều props/config khiến khó trace và debug. Ưu tiên component cụ thể, rõ ràng.

**Bố cục trang chuẩn (Áp dụng cho mọi trang):**

- Mọi trang/module nên được chia thành các component rời rạc để dễ quản lý, khai báo và sắp xếp trực tiếp tại component entry point `uc-main-page.vue` theo thứ tự:
  1. `uc-topbar` hoặc component bộ lọc/chức năng chung (Filter/Buttons).
  2. `uc-stats` (Các card thống kê tổng quan, nếu có số liệu cần tóm tắt).
  3. `uc-main-view` (Chứa dữ liệu chính, bảng danh sách, các tab hoặc các chức năng CRUD nghiệp vụ).

**Quy tắc tách component (Component Decomposition):**

- Khi `uc-main-page.vue` vượt 500–600 dòng, ưu tiên tách các phần sau ra component con:
  1. **Dialog/Modal**: Mỗi dialog lớn (>80 dòng template + logic) tách thành `uc-modal-[tên].vue`. Dialog nhận dữ liệu qua props, phát kết quả qua emit.
  2. **Stats/Dashboard cards**: Tách thành `uc-stats.vue`, nhận object thống kê qua prop `stats`, tự quản lý computed `cardList` và layout grid bên trong.
  3. **Table/List view**: Tách thành `uc-main-view.vue`, nhận dữ liệu qua props, phát sự kiện tương tác qua emit.
  4. **Form phức tạp**: Tách thành `uc-form-[tên].vue` khi form có nhiều trường hoặc logic validate phức tạp.
- Khi tách component con, **component cha giữ quyền sở hữu state và gọi API**. Component con chỉ nhận props và phát emit, không tự gọi API trừ khi logic hoàn toàn độc lập (ví dụ: modal tự save rồi emit `@saved` / `@on-reload`).
- Component con dùng global component có sẵn (`c-stats`, `c-table`, `f-table`...) để render UI, không duplicate markup.
- Khi tách, ưu tiên giữ nguyên tên event/prop đã có để không phá contract hiện tại.

**Quy định thiết kế uc-stats (Dashboard Cards):**

- Tránh sử dụng nền card màu đậm và sặc sỡ làm thô giao diện.
- Thiết kế tối giản: Dùng thuộc tính `outlined` (nền sáng mặc định), thu nhỏ icon về size `36` (nền nhạt dịu mắt như `blue-lighten-5`, `green-lighten-5`, `red-lighten-5` - bắt buộc dùng dấu gạch nối `-` thay vì khoảng trắng để tương thích với Vuetify 3).
- Tránh bo góc quá nhiều: Sử dụng `rounded-sm` cho tất cả các card để đồng bộ thiết kế hệ thống, tuyệt đối không dùng `rounded-lg` hay `rounded-xl`.
- Loại icon: Ưu tiên dùng các icon outline (`*-outline`) giúp giao diện trông thanh thoát, dịu mắt hơn.
- Cỡ chữ: Font chữ số lượng dùng `text-h5 font-weight-bold` và text mô tả dùng `text-caption` (khoảng `0.72rem`) để giao diện cao cấp và tinh tế hơn.

**Rút gọn tiêu đề bảng (Table Headers):**

- Các tiêu đề cột hiển thị trên bảng dữ liệu phải được tối ưu hóa ngắn gọn nhất có thể để tiết kiệm không gian hiển thị (ví dụ: dùng "Tổng số GV" thay cho "Tổng số giảng viên", "% Đạt" thay cho "Tỷ lệ đạt", "Miễn giảm" thay cho "Miễn giảm định mức",...). Điều này giúp bảng gọn gàng, giảm thiểu scroll ngang và tránh vỡ layout cột.

**Quy chuẩn thanh công cụ bảng (Search & Xuất Excel):**

- **Ô tìm kiếm nhanh (`c-underline-search`)**: Khi khai báo ô tìm kiếm nhanh bằng `<v-text-field>`, bắt buộc gắn `class="c-underline-search"` để hiển thị đường gạch chân mờ chuẩn hệ thống. **Icon tìm kiếm phải nằm ở phía trước**: Bắt buộc sử dụng thuộc tính `prepend-inner-icon="mdi-magnify"`, tuyệt đối không dùng `append-icon`.
- **Nút xuất Excel cạnh thanh tìm kiếm**: Thay vì tạo 1 button xuất Excel dạng text to độc lập ở ngoài bảng, đặt icon button `<v-btn icon color="success" class="mr-2" :loading="isLoadingExport" @click="onPrintExcel" title="Xuất file Excel"><v-icon>mdi-microsoft-excel</v-icon></v-btn>` ngay bên trong `<v-card-title>` liền kề trước thanh tìm kiếm để tiết kiệm diện tích.

---

## 6. Luồng data/control của platform

### raw.json

Với module mới/refactor, `raw.json` chỉ mount component và khai báo state tĩnh tối thiểu nếu platform bắt buộc:

```json
{
  "data": [{}],
  "watch": {},
  "controls": [],
  "set": {}
}
```

Quy tắc:

- Đọc `raw.json` trước khi sửa flow load dữ liệu.
- Không gọi API trong `raw.json`.
- Không thêm mới action dạng `API`, `IN`, `OUT`, `CALLBACK`, `CALL`, `EXE` để load dữ liệu trong `raw.json`.
- Không dùng `CALL("ActionName")` hoặc `runAction("ActionName")` cho flow API mới.
- Nếu module legacy đang có API trong `raw.json`, khi user yêu cầu chuẩn hoá/refactor flow đó thì dời logic API về `uc-main-page.vue` và dùng `ajaxCALLPromise`.
- `vueData` chỉ nên là state platform/global cần thiết; state nghiệp vụ mới ưu tiên đặt trong `data()` của `uc-main-page`.
- Không đổi `raw.json` nếu chỉ cần sửa render/UI.

### script.js

- Với module mới/refactor, `script.js` để trống.
- Không đưa logic nghiệp vụ mới vào `script.js` nếu có thể đặt trong `uc-main-page.vue`.
- Chỉ sửa/thêm `script.js` khi root cause nằm ở flow legacy, action platform, hoặc function đang được `raw.json` gọi.
- Function legacy trong `script.js` thường đọc/ghi `vueData` hoặc gắn function vào `vueData`, ví dụ `vueData.initPage = initPage`.
- Khi bug liên quan state/action toàn module, trace `raw.json -> script.js -> uc-main-page/component`.

---

## 7. Cách gọi API

### Helper đang có

```javascript
function ajaxCALLPromise(url, params = null) {
  return new Promise((resolve) => {
    ajaxCALL(url, params, (res) => resolve(res.data));
  });
}
```

### Quy tắc bắt buộc

- Mặc định KHÔNG cần `try/catch` khi gọi `ajaxCALLPromise` — helper đã tự handle lỗi. Chỉ dùng `try/catch/finally` khi cần xử lý đặc biệt sau API (ví dụ: `finally { this.saving = false }` để reset loading state).
- `ajaxCALLPromise` (hoặc `ajaxCallPromise`) là hàm global, không được dùng `this.ajaxCALLPromise` khi gọi.
- Dùng đúng helper hiện có `ajaxCALLPromise` (`CALL` viết hoa). Nếu user viết `ajaxCallPromise`, hiểu là `ajaxCALLPromise`.
- Dùng `ajaxCALLPromise`, không dùng `apiCallPromise`.
- Không thêm API mới bằng `ajaxCALL` callback, `CALL`, `runAction`, hoặc action API trong `raw.json`.
- Khi chạm vào một flow API đang dùng `ajaxCALL`, `CALL`, `runAction`, hoặc `raw.json`, ưu tiên chuyển phần flow đó về `ajaxCALLPromise` trong `uc-main-page.vue`.
- `ajaxCALLPromise(url, params)` trả trực tiếp `res.data`.
- `ajaxCALLPromise` chịu trách nhiệm bật/tắt `vueData.v_Loading`.
- Không bọc API bằng `vueData.v_Loading = true/false` trong component.
- Không viết pattern thủ công:

```javascript
vueData.v_Loading = true;
try {
  await ajaxCALLPromise("/Endpoint");
} finally {
  vueData.v_Loading = false;
}
```

- Nếu loading khi gọi API chưa đúng, sửa `ajaxCALLPromise` trong `imports/script-main.js`, không sửa từng component.
- Với endpoint trả nhiều result set:
  - `data[0]` là result set đầu.
  - `data[0][0]` là row đầu của result set đầu.
- Endpoint trong repo đang dùng dạng `"/DonVi_Get"`, `"/HDKH_DM_GetAll"`, `"/AnPham_Get..."`; không tự thêm `/work/`.
- Khi viết flow async mới hoặc refactor nhỏ:

```javascript
const params = { MaDonVi: item.MaDonVi };
const data = await ajaxCALLPromise("/DonVi_Get", params);
```

- Không truyền object inline quá phức tạp nếu làm mất khả năng debug. Tạo `params` trước khi gọi API khi payload có nhiều field.
- Không đổi tên field request/response nếu backend chưa đổi contract.

### Feedback sau API

- Thành công: `Vue.$toast.success('...', { position: 'top' })`
- Lỗi: `Vue.$toast.error(message, { position: 'top' })`
- Xác nhận: `confirm({ title: '...', action: function () {} })`
- Reload data bằng method local trong `uc-main-page` (ví dụ `this.fetchList()` / `this.initData()`), không thêm `CALL/runAction` mới.
- `CALL/runAction` chỉ xem là legacy; nếu sửa đúng flow đó thì dời về method local + `ajaxCALLPromise`.

---

## 8. Debug checklist

Khi xử lý bug, trace theo thứ tự:

1. Input: user action, params, form data, route query, `vueData`.
2. Process: method/component/script/raw legacy action nào chạy.
3. State: biến local, `vueData.OUT`, loading/dialog/table state.
4. Output: UI render, table rows, modal, toast, callback.
5. Side effects: API call, `CALL/runAction`, reload, localStorage, chart update.

Không bắt đầu từ CSS/UI nếu bug có dấu hiệu data/API/state.
Khi thấy `CALL/runAction/raw.json API`, coi đó là legacy API flow và ưu tiên dời về `ajaxCALLPromise` nếu đang sửa flow đó.

---

## 9. Lưu ý quan trọng

- **Không dùng `localStorage`** cho dữ liệu nghiệp vụ — quản lý qua API.
- **Platform tự quản lý routing** — không cần cấu hình Vue Router.

### Quy tắc sử dụng `vueData`

`vueData` là biến reactive gốc từ `raw.json`, có thể truy cập từ mọi nơi trong module. Tuy nhiên, việc lạm dụng `vueData` gây ra coupling chặt, khó debug và khó tách component. Tuân thủ các quy tắc sau:

**Được phép đọc `vueData` tại `uc-main-page.vue`:**

- Đọc config platform: `window.vueData?.v_Set`, `vueData?.NamHoc`.
- Đọc state khởi tạo 1 lần rồi gán vào `data()` cục bộ.

**Cấm dùng `vueData` tại component con (`uc-modal-*`, `uc-stats`, `uc-main-view`, `uc-ly-lich-*`,...):**

- Không khai báo `vueData` trong `data()` của component con.
- Không đọc/ghi `vueData.xxx` trực tiếp. Mọi dữ liệu cần thiết phải được truyền qua `props` từ component cha.
- Không dùng `vueData` để sync state 2 chiều giữa parent và child — dùng luồng props xuống, emit lên.

**Thay thế `vueData` khi refactor:**

- `vueData.activities[id]` → `this.activities[id]` cục bộ ở `uc-main-page`.
- `vueData.NhanVienID` truyền qua prop `nhanVienID` cho component con.
- `vueData.userProfile` truyền qua prop `userProfile`.
- `vueData.showNewKekhaiDialog = true` → component con phát emit `@on-show-kekhai`, parent bắt sự kiện và tự mở dialog.
- Chuỗi eval `"vueData?.NhanVienID"` trong `f-table` `updateApi["default-item"]` → gán trực tiếp `this.nhanVienID` từ props, kết hợp `watch` để sync khi prop thay đổi.

**Khi nào chấp nhận `vueData`:**

- Module legacy chưa refactor — giữ nguyên, không sửa nếu user không yêu cầu.
- State platform bắt buộc (`v_Set`, `v_Loading`) — chỉ đọc, không ghi thủ công.

---

## 10. Quy tắc verify

- Repo không có package/build script chuẩn trong root, không tự chạy build/tsc.
- Verify bằng đọc code, grep, diff, và kiểm tra flow liên quan.
- Không cần viết hoặc chạy test khi không được yêu cầu.
- Nếu có thay đổi API/state, phải đối chiếu endpoint ở nơi gọi thật; với module legacy thì kiểm tra thêm action cũ trong `raw.json`.
- Nếu cần chạy lệnh ngoài sandbox hoặc destructive command, hỏi quyền trước.

---

## 11. Format trả lời

Khi fix bug:

```text
Bug:
- Lỗi: ...
- Nguyên nhân: ...
- Cách sửa: ...
- Side effects: ...
```

Khi phân tích:

```text
Phân tích:
- Vấn đề: ...
- Luồng: Input -> Process -> State -> Output -> Side effects
- Điểm sai: ...
- Cách sửa: ...
```

Khi đã sửa code:

- Nêu file đã sửa.
- Nêu root cause.
- Nêu cách verify ngắn gọn.
- Nêu rõ nếu chưa chạy được verify.

---

## 12. Checklist trước khi sửa

- Đã đọc AGENTS.md.
- Đã đọc đúng module/file liên quan.
- Đã xác định root cause hoặc assumption.
- Patch có minimal diff.
- Không đổi global/raw/proj nếu không cần.
- Không thêm API trong `raw.json`.
- API trong phạm vi sửa dùng đúng `ajaxCALLPromise`.
- Không set `vueData.v_Loading` thủ công quanh API vì `ajaxCALLPromise` đã xử lý.
- Không phá syntax Vuetify/Vue hiện có.
- Không inline function trong template.
- Không khai báo biến/function ngoài `export default`.
- Props luôn có `default` value.
- Emit event theo prefix `on-` dạng kebab-case.
- File component không vượt 1000 dòng.

---

## 13. Quy ước đặt tên

| Loại                     | Quy tắc                          | Ví dụ                                                               |
| ------------------------ | -------------------------------- | ------------------------------------------------------------------- |
| Module folder            | kebab-case                       | `detai-nckh-coso`, `giai-thuong`                                    |
| Component entry          | `uc-main-page.vue`               | `uc-main-page.vue` (legacy: `uc-main.vue`, `uc-main-component.vue`) |
| Component theo chức năng | `uc-[chức năng]-[đối tượng].vue` | `uc-modal-add.vue`, `uc-modal-edit.vue`, `uc-main-view.vue`         |
| CSS custom               | Tên tùy module                   | `customCss.css`, `style.css`, `text-css.css`                        |
| Biến data                | camelCase, tường minh            | `isTableReady`, `editItem`, `tableRows`                             |
| Emit event               | kebab-case, prefix `on-`         | `on-reload`, `on-save`, `on-delete`                                 |
| Props                    | camelCase                        | `tableRows`, `isVisible`, `editItem`                                |
| CSS class                | Ngắn gọn, rõ nghĩa theo ngữ cảnh | `toolbar`, `stats`, `modal-footer`                                  |

Quy tắc CSS class:

- Không bắt buộc prefix — đặt tên tự nhiên theo ngữ cảnh.
- Không đặt quá chung chung (`div1`, `wrapper2`) hoặc viết tắt khó đoán (`tbl-wrp-mn`).

---

## 14. Pattern CRUD chuẩn

### Mẫu main-page

```vue
<template>
  <div>
    <uc-stats :stats="statsData" />
    <uc-main-view
      :isTableReady="isTableReady"
      :tableHeaders="tableHeaders"
      :tableRows="tableRows"
      @on-edit="openEditModal"
      @on-delete="handleDelete"
    />
    <uc-modal-add v-model="isAddModalOpen" @on-reload="initData" />
    <uc-modal-edit
      v-model="isEditModalOpen"
      @on-reload="initData"
      :editItem="editItem"
    />
  </div>
</template>

<script>
export default {
  name: "uc-main-page",
  data() {
    return {
      isAddModalOpen: false,
      isEditModalOpen: false,
      tableRows: [],
      statsData: {},
      isTableReady: false,
      tableHeaders: [],
      editItem: {},
    };
  },
  mounted() {
    this.initData();
  },
  methods: {
    initTableHeaders() {
      this.tableHeaders = [
        { title: "#", key: "stt", width: 60 },
        { title: "Tên", key: "Ten" },
      ];
    },
    async fetchList() {
      this.tableRows = await ajaxCALLPromise("/Module_Get");
    },
    async initData() {
      this.isTableReady = false;
      await this.fetchList();
      this.initTableHeaders();
      this.isTableReady = true;
    },
    openAddModal() {
      this.isAddModalOpen = true;
    },
    openEditModal(item) {
      this.editItem = item;
      this.isEditModalOpen = true;
    },
    handleDelete(item) {
      confirm({
        title: "Bạn có chắc muốn xóa?",
        action: async () => {
          await ajaxCALLPromise("/Module_Delete", { ID: item.ID });
          Vue.$toast.success("Xóa thành công", { position: "top" });
          this.initData();
        },
      });
    },
  },
};
</script>
```

### Mẫu modal add/edit

```vue
<template>
  <v-dialog v-model="dialog" max-width="600" persistent>
    <v-card>
      <v-card-title>Tiêu đề modal</v-card-title>
      <v-card-text>
        <v-text-field v-model="form.Ten" label="Tên" dense hide-details />
      </v-card-text>
      <v-card-actions>
        <v-spacer />
        <v-btn text @click="close()">Hủy</v-btn>
        <v-btn color="primary" :loading="saving" @click="save()">Lưu</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
export default {
  name: "uc-modal-add",
  props: { value: { type: Boolean, default: false } },
  emits: ["input", "on-reload"],
  data() {
    return {
      form: { Ten: "" },
      saving: false,
    };
  },
  computed: {
    dialog: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
  },
  methods: {
    resetForm() {
      this.form = { Ten: "" };
    },
    async save() {
      this.saving = true;
      try {
        await ajaxCALLPromise("/Module_Save", this.form);
        Vue.$toast.success("Lưu thành công", { position: "top" });
        this.$emit("on-reload");
        this.close();
      } finally {
        this.saving = false;
      }
    },
    close() {
      this.resetForm();
      this.dialog = false;
    },
  },
};
</script>
```

Ghi chú mẫu:

- Modal dùng `v-model` với `value`/`input` (Vue 2 style) phù hợp repo hiện tại.
- `saving` reset trong `finally` — pattern hợp lệ dù không có `try/catch` error handling.
- `resetForm()` gọi khi đóng modal để tránh data cũ.

