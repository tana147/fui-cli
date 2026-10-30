<template>
	<global>
    <template #header="">
      <v-card>
        <v-card-title class="d-flex align-center flex-wrap ga-2">
          <span>{{ pageTitle }} • {{ titleCap }}</span>
          <v-spacer />
          <v-btn-toggle v-model="isEn" size="small" class="ml-auto">
            <v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
              <v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
            </v-btn>
            <v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
              <v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
            </v-btn>
          </v-btn-toggle>
        </v-card-title>
        <v-card-text>
          <v-row align="center">
            <v-col cols="12" sm="6" md="3">
              <v-select :key="'sem_' + isEn" v-model="Semester" :label="isEn ? 'Select semester' : 'Chọn học kì'" :items="DSSemester" item-title="title"
                item-value="value" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
              </v-select>
            </v-col>
            <v-col cols="12" sm="6" md="2">
              <v-select :key="'khoi_' + isEn" v-model="KhoiID" :label="isEn ? 'Select grade' : 'Chọn khối'" :items="DSKhoi" :item-title="formatKhoiTitle" item-value="KhoiID"
                :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
                <template #selection="{ item }">
                  <span>{{ formatKhoiTitle(item) }}</span>
                </template>
                <template #item="{ props, item }">
                  <v-list-item v-bind="props" :title="formatKhoiTitle(item)"></v-list-item>
                </template>
              </v-select>
            </v-col>
            <v-col cols="12" sm="6" md="3">
              <v-select :key="'mon_' + isEn" v-model="MonHocItem" @update:model-value="onMonHocSelection" :label="isEn ? 'Select subject' : 'Chọn môn học'" :items="DSMonHoc" item-title="MonHocOptionTitle"
                item-value="MonHocOptionID" return-object="" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
              </v-select>
            </v-col>
            <v-col cols="12" sm="6" md="4" class="d-flex align-center ga-2 flex-wrap flex-md-nowrap">
              <v-btn variant="outlined" color="primary" :loading="isLoadingHocSinh || isLoadingThongKe" @click="onRefresh">
                <v-icon start="">mdi-refresh</v-icon>{{ isEn ? 'Refresh' : 'Làm mới' }}
              </v-btn>
              <v-btn variant="outlined" color="primary" :disabled="DSHocSinh.length === 0 && DataThongKe.length === 0"
                @click="exportExcel">
                <v-icon start="">mdi-file-excel</v-icon>{{ isEn ? ('Export Excel' + (DataThongKe.length > 0 ? ' (2 sheets)' : '')) : ('Xuất Excel' + (DataThongKe.length > 0 ? ' (2 bảng)' : '')) }}
              </v-btn>
              <v-btn variant="outlined" color="primary" :disabled="!KhoiID || !MonHocItem?.TemplateBangDiemID"
                @click="exportExcelAll">
                <v-icon start="">mdi-file-excel</v-icon>{{ isEn ? 'Export all terms' : 'Xuất tất cả kì' }}
              </v-btn>
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>
    </template>

    <v-card class="pt-0 mt-3 elevation-1" v-if="DataThongKe.length > 0 || isLoadingThongKe">
      <v-card-title class="d-flex text-primary">
        <span>{{ isEn ? 'Grade level statistics' : 'Thống kê kết quả các khối' }}</span>
      </v-card-title>
      <v-card-text>
        <v-progress-linear v-if="isLoadingThongKe" indeterminate color="primary" />
        <v-data-table v-if="DataThongKe.length > 0" :items="DataThongKe" :headers="headers" items-per-page="-1" hide-default-footer=""
          style="max-height: calc(100dvh - 77px); overflow-y: auto;">
        </v-data-table>
      </v-card-text>
    </v-card>

    <v-card class="pt-0 gradebook-page">
      <v-card-title class="d-flex text-primary px-0">
        <span>{{ isEn ? 'Detailed subject gradebook' : 'Bảng điểm chi tiết môn học' }}</span>
        <v-chip v-if="hasLockStateData" class="ml-2" color="warning" variant="tonal" size="small">
          {{ isEn ? 'Yellow cells: grade column is unlocked' : 'Ô vàng: cột điểm chưa khóa' }}
        </v-chip>
        <v-chip v-if="DSHocSinh.length > 0" class="ml-2" color="primary">{{ isEn ? 'Total students:' : 'Tổng số học sinh:' }} {{ DSHocSinh.length }}
        </v-chip>
      </v-card-title>

      <v-progress-linear v-if="isLoadingHocSinh && DSHocSinh.length > 0" indeterminate color="primary" height="3" />
      <v-alert v-if="hocSinhError" class="mx-4 mb-2" type="error" variant="tonal">{{ hocSinhError }}</v-alert>
      <!-- Khi chưa có dòng nào vì request còn chạy, hiện tiến trình thay vì trạng thái bảng trống. -->
      <div v-if="isLoadingHocSinh && DSHocSinh.length === 0" class="d-flex align-center justify-center ga-2 py-6">
        <v-progress-circular indeterminate color="primary" />
        <span>{{ isEn ? 'Loading grades...' : 'Đang tải bảng điểm...' }}</span>
      </div>
      <!-- Giới hạn kích thước tối thiểu theo đúng số cột/dòng dữ liệu để JExcel không sinh cột rỗng F/G/H cho mẫu điểm ít cột. -->
      <uc-jexcel v-if="DSHocSinh.length > 0" ref="gradebookGrid" class="height-excel gradebook-height-excel" :key="keyComp" :columns="columns"
        :min-dimensions="[columns.length, DSHocSinh.length]"
        :data-source="DSHocSinh" :freeze-columns="freezeColumns" :style-sheet="styleSheet"
        :style-excel="'--gradebook-table-height:' + gradebookTableHeight" />
      <div v-if="DSHocSinh.length === 0 && !isLoadingHocSinh && !hocSinhError && MonHocItem?.TemplateBangDiemID" class="d-flex flex-column align-center justify-center ga-2 py-8 text-medium-emphasis">
        <v-icon size="48">mdi-table-remove</v-icon>
        <span>{{ isEn ? 'No grade data was returned for this subject and semester.' : 'Không có dữ liệu điểm cho môn học và học kì đang chọn.' }}</span>
      </div>
      <uc-card-empty v-if="DSHocSinh.length === 0 && !isLoadingHocSinh && !hocSinhError && !MonHocItem?.TemplateBangDiemID" />
    </v-card>

    <!-- Giữ mỗi cột/sheet có checkbox riêng; các workbook nhiều kỳ có thể dùng bộ cột khác nhau. -->
    <v-dialog v-model="exportColumnsDialog.show" max-width="600" scrollable>
      <v-card>
        <v-card-title class="d-flex align-center px-3 pt-2 pb-3 subtitle-1 font-weight-bold">
          {{ isEn ? 'Choose Excel columns' : 'Chọn cột xuất Excel' }}
          <v-spacer />
          <v-btn icon @click="exportColumnsDialog.show = false"><v-icon>mdi-close</v-icon></v-btn>
        </v-card-title>
        <v-card-text class="px-3 py-1">
          <div class="text-body-2 text-medium-emphasis mb-2">
            {{ isEn ? 'All columns start selected. Uncheck columns you do not need.' : 'Mặc định đã chọn tất cả cột. Bỏ chọn những cột bạn không cần xuất.' }}
          </div>
          <v-checkbox v-for="column in exportColumnsDialog.columns" :key="column.value"
            v-model="exportColumnsDialog.selectedColumns" :value="column.value" :label="column.label"
            density="compact" hide-details />
        </v-card-text>
        <v-card-actions class="pa-3">
          <v-spacer />
          <v-btn text @click="exportColumnsDialog.show = false">{{ isEn ? 'Cancel' : 'Hủy' }}</v-btn>
          <v-btn color="primary" elevation="0" :disabled="!exportColumnsDialog.selectedColumns.length"
            @click="confirmExportColumns">
            {{ isEn ? 'Export Excel' : 'Xuất Excel' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </global>
</template>

<script>
	export default {
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
  data() {
    return {
      isEn: JSON.parse(localStorage.getItem('IsLanguage')) ?? false,
      vueData,
      keyComp: 0,
      DSKhoi: [],
      KhoiID: null,
      MonHocItem: null,
      DSMonHoc: [],
      DSHocSinh: [],
      DSCotDiem: [],
      DataThongKe: [],
      isLoadingHocSinh: false,
      isLoadingThongKe: false,
      hocSinhError: '',
      MaCotDiem: null,
      HocKi: null,
      Semester: null,
      headers: [],
      columns: [],
      styleSheet: {},
      gradebookTableHeight: 'calc(100dvh - 150px)',
      resizeFrame: null,
      freezeColumns: 4,
      exportColumnsDialog: {
        show: false,
        columns: [],
        selectedColumns: [],
        tables: [],
        fileName: ''
      },
    }
  },
  computed: {
    hasLockStateData() {
      return (this.DSCotDiem ?? []).some(score => Object.prototype.hasOwnProperty.call(score, 'KhoaDiemTinhTrang'))
    },
    DSSemester() {
      const capId = parseInt(vueData.CapID || capid)
      if (capId === 2 || capId === 3) {
        return [
          { title: this.isEn ? 'Semester 1' : 'Học kì 1', value: 'HK1' },
          { title: this.isEn ? 'Semester 2' : 'Học kì 2', value: 'HK2' },
          { title: this.isEn ? 'Full year' : 'Cả năm', value: 'CaNam' },
        ]
      }
      return [
        { title: this.isEn ? 'Mid S1' : 'Giữa kì 1', value: 'GK_HK1' },
        { title: this.isEn ? 'Final S1' : 'Cuối kì 1', value: 'CK_HK1' },
        { title: this.isEn ? 'Mid S2' : 'Giữa kì 2', value: 'GK_HK2' },
        { title: this.isEn ? 'Final S2' : 'Cuối kì 2', value: 'CK_HK2' },
      ]
    },
    titleCap() {
      const capId = parseInt(vueData.CapID || capid)
      if (this.isEn) {
        if (capId === 1) return 'Primary'
        if (capId === 2) return 'Secondary'
        if (capId === 3) return 'High School'
        return 'Level ' + capId
      }
      return renderText(capId)
    },
    pageTitle() {
      if (this.isEn) return 'Subject Detailed Gradebook'
      return getTitlePageByURL(window.location.pathname + window.location.search)
    },
    TitleCap() {
      return this.titleCap
    },
    TitlePage() {
      return this.pageTitle
    },
  },
  watch: {
    isEn() {
      this.setThongKeHeaders()
      if (this.DSCotDiem && this.DSCotDiem.length > 0) {
        this.renderHocSinh()
      }
    },
    'vueData.NienKhoa'() {
      this.KhoiID = null
      this.MonHocItem = null
      this.DSMonHoc = []
      this.DSCotDiem = []
      this.DSHocSinh = []
      this.DataThongKe = []
      this.getKhoi()
    },
    Semester(v) {
      if (!v) return
      this.MonHocItem = null
      this.DSMonHoc = []
      this.DSCotDiem = []
      this.DSHocSinh = []
      this.DataThongKe = []
      if (this.KhoiID > 0) this.getMon()
    },
    KhoiID(v) {
      this.MonHocItem = null
      this.DSMonHoc = []
      this.DSCotDiem = []
      this.DSHocSinh = []
      this.DataThongKe = []
      if (v > 0) this.getMon()
    },
  },
  mounted() {
    window.addEventListener('storage', this.handleStorageChange)
    window.addEventListener('resize', this.resizeGradebookTable)
    this.initMaCotDiem()
    this.setThongKeHeaders()
    // Luôn có kì học hợp lệ; getHocSinh sẽ thoát sớm nếu Semester vẫn null.
    if (!this.Semester && this.DSSemester.length > 0) {
      this.Semester = this.DSSemester[0].value
    }
    this.getKhoi()
  },
  beforeUnmount() {
    window.removeEventListener('storage', this.handleStorageChange)
    window.removeEventListener('resize', this.resizeGradebookTable)
    if (this.resizeFrame !== null) cancelAnimationFrame(this.resizeFrame)
  },
  methods: {
    setLanguage(val) {
      this.isEn = val
      if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi'
      localStorage.setItem('IsLanguage', JSON.stringify(val))
    },
    handleStorageChange(event) {
      if (event.key === 'IsLanguage') {
        this.isEn = JSON.parse(event.newValue) ?? false
      }
    },
    resizeGradebookTable() {
      if (this.resizeFrame !== null) cancelAnimationFrame(this.resizeFrame)
      this.resizeFrame = requestAnimationFrame(() => {
        this.resizeFrame = null
        const grid = this.$refs.gradebookGrid
        const element = grid?.$el || grid
        if (!element) return

        // Đo từ đầu bảng tới đáy viewport; CSS dùng chung trừ cứng 230px nên bảng bị hụt chiều cao.
        const availableHeight = Math.max(240, Math.floor(window.innerHeight - element.getBoundingClientRect().top - 16))
        this.gradebookTableHeight = availableHeight + 'px'
      })
    },
    formatKhoiTitle(item) {
      if (!item) return ''
      const raw = (item && item.raw) ? item.raw : item
      const name = typeof raw === 'object' ? (raw.TenKhoiHoc || raw.title) : raw
      if (!name) return ''
      if (!this.isEn) return name
      return String(name).replace(/Khối/gi, 'Grade')
    },
    initMaCotDiem() {
      if (parseInt(vueData.CapID) === 1) {
        this.MaCotDiem = 'DiemCK_HK2'
        this.HocKi = 'HK2'
      } else {
        this.MaCotDiem = 'DiemTB_CaNam'
        this.HocKi = 'CaNam'
      }
    },
    async getKhoi() {
      const res = await fetchPromise('lms/KhoiHocByCapHoc_Get', {
        CapID: vueData.CapID,
        HocKi: vueData.NienKhoaItem.HocKi,
        NienKhoa: vueData.NienKhoa,
      })
      this.DSKhoi = res ?? []
    },
    async getMon() {
      if (!this.KhoiID) return
      const res = await fetchPromise('lms/MonHoc_GetByKhoiID', {
        NienKhoa: vueData.NienKhoa,
        KhoiID: this.KhoiID,
        HocKi: vueData.NienKhoaItem.HocKi,
        IncludeGroupNames: 1,
      })
      // Gộp các nhóm cùng môn vào một lựa chọn; giữ mọi mẫu điểm để tải đủ học sinh và hiện lớp nhóm theo từng em.
      const optionsByKey = new Map()
      ;(res ?? []).forEach(item => {
        const isGroupSubject = !!String(item.NhomNameList ?? '').trim()
        const optionID = isGroupSubject
          ? 'group_' + String(item.MonHocID)
          : 'template_' + String(item.MonHocID) + '_' + String(item.TemplateBangDiemID ?? 'none')
        let option = optionsByKey.get(optionID)
        if (!option) {
          option = {
            ...item,
            IsGroupSubject: isGroupSubject,
            TemplateBangDiemIDs: [],
            MonHocOptionID: optionID,
            MonHocOptionTitle: item.MonHocName,
          }
          optionsByKey.set(optionID, option)
        }
        const templateID = Number(item.TemplateBangDiemID)
        if (Number.isFinite(templateID) && templateID > 0 && !option.TemplateBangDiemIDs.includes(templateID)) {
          option.TemplateBangDiemIDs.push(templateID)
        }
      })
      this.DSMonHoc = Array.from(optionsByKey.values())
    },
    getTemplateBangDiemIDs(monHocItem) {
      const item = monHocItem || this.MonHocItem
      const configuredIDs = Array.isArray(item?.TemplateBangDiemIDs) && item.TemplateBangDiemIDs.length > 0
        ? item.TemplateBangDiemIDs
        : [item?.TemplateBangDiemID]
      return Array.from(new Set(configuredIDs.map(id => Number(id)).filter(id => Number.isFinite(id) && id > 0)))
    },
    // Quy mã Theme/Total và mã TX_Ln_HKx về cùng thứ tự TX → GK → CK → ĐTB.
    getGradeColumnOrder(column) {
      const maCotDiem = String(column?.MaCotDiem || '').trim().toUpperCase()
      const themeMatch = maCotDiem.match(/^THEME([1-4])_TOTAL$/)
      if (themeMatch) return 100 + Number(themeMatch[1])

      const txMatch = maCotDiem.match(/^(?:DIEM)?TX_L?([1-9]\d*)_HK([12])$/)
      if (txMatch) return 100 + Number(txMatch[1])

      const examMatch = maCotDiem.match(/^S([12])_(MID|FINAL)_TOTAL_POINT$/)
      if (examMatch) return (examMatch[2] === 'MID' ? 200 : 300) + Number(examMatch[1])

      const regularExamMatch = maCotDiem.match(/^DIEM(GK|CK)_HK([12])$/)
      if (regularExamMatch) return (regularExamMatch[1] === 'GK' ? 200 : 300) + Number(regularExamMatch[2])

      // Mẫu AI lưu giữa kỳ/cuối kỳ trong hai cột chủ đề; ID template 791 gắn chúng với GK/CK.
      const aiExamMatch = maCotDiem.match(/^DIEMCD([12])_HK([12])$/)
      if (aiExamMatch) return (aiExamMatch[1] === '1' ? 200 : 300) + Number(aiExamMatch[2])

      const averageMatch = maCotDiem.match(/^DIEMTB_(HK1|HK2|CANAM)$/)
      if (averageMatch) {
        const termOrder = { HK1: 1, HK2: 2, CANAM: 3 }
        return 400 + termOrder[averageMatch[1]]
      }

      return Number.POSITIVE_INFINITY
    },
    // Tạo danh sách cột duy nhất từ toàn bộ nhóm để nhóm nào thiếu điểm cũng không làm mất cột chung.
    getOrderedGradeColumns(rows) {
      const columnsByCode = new Map()
      for (const row of rows || []) {
        const maCotDiem = String(row?.MaCotDiem || '')
        if (maCotDiem && !columnsByCode.has(maCotDiem)) columnsByCode.set(maCotDiem, row)
      }

      return Array.from(columnsByCode.values())
        // Chỉ đưa các mã thuộc TX/GK/CK/ĐTB lên bảng; cột phụ ngoài cấu trúc điểm không hiển thị.
        .filter(column => Number.isFinite(this.getGradeColumnOrder(column)))
        .sort((a, b) => {
          const orderDifference = this.getGradeColumnOrder(a) - this.getGradeColumnOrder(b)
          if (orderDifference !== 0) return orderDifference
          return String(a.MaCotDiem || '').localeCompare(String(b.MaCotDiem || ''), 'vi', { numeric: true, sensitivity: 'base' })
        })
    },
    // Ghép nhiều mẫu điểm xong thì xếp học sinh theo lớp nhóm, lớp gốc, tên; điểm của từng em theo thứ tự chuẩn.
    sortGradeRowsByGroup(rows) {
      const compareText = (left, right) => String(left || '').localeCompare(String(right || ''), 'vi', { numeric: true, sensitivity: 'base' })
      return [...(rows || [])].sort((a, b) => {
        const groupDifference = compareText(a.TenLopNhom, b.TenLopNhom)
        if (groupDifference !== 0) return groupDifference

        const homeClassDifference = compareText(a.TenLop, b.TenLop)
        if (homeClassDifference !== 0) return homeClassDifference

        const nameDifference = compareText(a.HoTen, b.HoTen)
        if (nameDifference !== 0) return nameDifference

        const studentDifference = compareText(a.HocSinhID, b.HocSinhID)
        if (studentDifference !== 0) return studentDifference

        return this.getGradeColumnOrder(a) - this.getGradeColumnOrder(b)
      })
    },
    // Nhóm ngoại ngữ có thể dùng nhiều mẫu điểm; tải từng mẫu rồi ghép học sinh để một lựa chọn môn bao phủ mọi lớp nhóm.
    async fetchHocSinhRows(semester) {
      const templateIDs = this.getTemplateBangDiemIDs()
      const responses = await Promise.all(templateIDs.map(templateID => fetchPromise('lms/HocSinhBangDiem_Get_By_KhoiID_MonHocID', {
        KhoiID: this.KhoiID,
        TemplateBangDiemID: templateID,
        Semester: semester,
        NienKhoa: vueData.NienKhoa,
        IncludeGroups: 1,
      })))
      const allRows = responses.reduce((allRows, response) => {
        const rows = Array.isArray(response) ? response : (Array.isArray(response?.data) ? response.data : null)
        if (!rows) throw new Error(this.isEn ? 'The grade API returned an unexpected response.' : 'API bảng điểm trả về dữ liệu không đúng định dạng.')
        return allRows.concat(rows)
      }, [])
      return this.sortGradeRowsByGroup(allRows)
    },
    // Gọi tải điểm từ sự kiện chọn môn để luồng nạp dữ liệu không phụ thuộc watcher.
    onMonHocSelection() {
      this.DSCotDiem = []
      this.DSHocSinh = []
      this.DataThongKe = []
      this.hocSinhError = ''
      this.$nextTick(() => {
        if (this.MonHocItem?.MonHocID > 0) {
          this.getHocSinh()
          this.getThongKe()
        }
      })
    },
    async getHocSinh() {
      if (!this.KhoiID || !this.getTemplateBangDiemIDs().length || !this.Semester) return
      this.isLoadingHocSinh = true
      try {
        const rows = await this.fetchHocSinhRows(this.Semester)
        this.DSCotDiem = rows
        this.renderHocSinh()
      } catch (error) {
        this.DSCotDiem = []
        this.DSHocSinh = []
        this.hocSinhError = error?.response?.data?.Message || error?.response?.data?.message || error?.message || (this.isEn ? 'Could not load grade data.' : 'Không tải được bảng điểm.')
      } finally {
        this.isLoadingHocSinh = false
      }
    },
    async getThongKe() {
      if (!this.MonHocItem?.MonHocID) return
      this.isLoadingThongKe = true
      try {
        const res = await fetchPromise('lms/ThongKeDiemTheoCap_MaCotDiem', {
          CapID: vueData.CapID,
          MonHocID: this.MonHocItem.MonHocID,
          MaCotDiem: this.MaCotDiem,
          HocKi: this.HocKi,
          NhomHocKi: this.Semester,
        })
        this.DataThongKe = res ?? []
        this.setThongKeHeaders()
      } finally {
        this.isLoadingThongKe = false
      }
    },
    onRefresh() {
      this.getHocSinh()
      this.getThongKe()
    },
    exportExcel() {
      const tables = []
      if (this.DataThongKe && this.DataThongKe.length > 0) {
        tables.push({ name: 'ThongKeKhoi', title: this.isEn ? 'Statistics' : 'Thống kê', headers: this.headers.map(x => ({ title: x.title ?? x.value, name: x.value })), rows: this.DataThongKe })
      }

      tables.push({ name: 'BangDiemChiTiet', title: this.isEn ? 'Student grades' : 'Bảng điểm', headers: this.columns.map(x => ({ title: x.title ?? x.name, name: x.name })), rows: this.DSHocSinh })
			this.openExportColumnDialog(tables, 'Bang_Diem_Chi_Tiet_Khoi' + (this.KhoiID || '') + '_' + (this.MonHocItem?.MonHocName || 'MonHoc') + '.xlsx')
    },

    // Build one checkbox for every sheet-column pair so similarly named fields remain distinct.
    openExportColumnDialog(tables, fileName) {
      const columns = []
      ;(tables || []).forEach((table, tableIndex) => {
        ;(table.headers || []).forEach((header, columnIndex) => {
				const tableLabel = tables.length > 1 ? (table.title || table.name) + ' — ' : ''
          columns.push({
					value: 'table_' + tableIndex + '_column_' + columnIndex,
					label: tableLabel + (header.title || header.name || '')
          })
        })
      })
      if (!columns.length) return
      this.exportColumnsDialog.tables = tables
      this.exportColumnsDialog.fileName = fileName
      this.exportColumnsDialog.columns = columns
      // Reset selection on every export attempt, with all currently available columns checked.
      this.exportColumnsDialog.selectedColumns = columns.map(column => column.value)
      this.exportColumnsDialog.show = true
    },

    confirmExportColumns() {
      const selected = new Set(this.exportColumnsDialog.selectedColumns)
      if (!selected.size) return
      const workbook = XLSX.utils.book_new()
      this.exportColumnsDialog.tables.forEach((table, tableIndex) => {
        const selectedIndexes = (table.headers || []).map((_, index) => index)
				.filter(index => selected.has('table_' + tableIndex + '_column_' + index))
        if (!selectedIndexes.length) return
        const headers = selectedIndexes.map(index => table.headers[index])
        const rows = (table.rows || []).map(item => headers.map(header => item[header.name] ?? ''))
        const worksheet = XLSX.utils.aoa_to_sheet([headers.map(header => header.title), ...rows])
        XLSX.utils.book_append_sheet(workbook, worksheet, table.name)
      })
      if (!workbook.SheetNames.length) return
      XLSX.writeFile(workbook, this.exportColumnsDialog.fileName)
      this.exportColumnsDialog.show = false
    },
    // Theme*_Total là các điểm TX theo học kỳ đang chọn; mã GK/CK và ĐTB tự mang thông tin học kỳ.
    getGradeColumnTitle(column, semesterValue) {
      const maCotDiem = String((column && column.MaCotDiem) || '')
      const maCotDiemUpper = maCotDiem.trim().toUpperCase()
      const semester = String(semesterValue || this.Semester || '')
      const semesterLabel = semester === 'CaNam' ? 'Cả năm' : semester

      const themeMatch = maCotDiemUpper.match(/^THEME([1-4])_TOTAL$/)
      if (themeMatch) {
        return `TX${themeMatch[1]}${semesterLabel ? ` - ${semesterLabel}` : ''}`
      }

      const txMatch = maCotDiemUpper.match(/^(?:DIEM)?TX_L?([1-9]\d*)_HK([12])$/)
      if (txMatch) return `TX${txMatch[1]} HK${txMatch[2]}`

      const examMatch = maCotDiemUpper.match(/^S([12])_(MID|FINAL)_TOTAL_POINT$/)
      if (examMatch) {
        const term = `HK${examMatch[1]}`
        if (examMatch[2] === 'MID') {
          return `GK ${term}`
        }
        return `CK ${term}`
      }

      const regularExamMatch = maCotDiemUpper.match(/^DIEM(GK|CK)_HK([12])$/)
      if (regularExamMatch) return `${regularExamMatch[1]} HK${regularExamMatch[2]}`

      // Template AI dùng DiemCD1/2 nhưng nhãn hiển thị trong metadata lần lượt là GK/CK.
      const aiExamMatch = maCotDiemUpper.match(/^DIEMCD([12])_HK([12])$/)
      if (aiExamMatch) return `${aiExamMatch[1] === '1' ? 'GK' : 'CK'} HK${aiExamMatch[2]}`

      const averageMatch = maCotDiemUpper.match(/^DIEMTB_(HK1|HK2|CANAM)$/)
      if (averageMatch) {
        const term = averageMatch[1] === 'CANAM'
          ? 'Cả năm'
          : averageMatch[1]
        return `ĐTB ${term}`
      }

      const isEnglish = !!this.isEn
      const listMonHoc = [5, 46, 76]
      return (this.isEn ? column.TenHienThi_EN : (listMonHoc.includes(this.MonHocItem?.MonHocID) ? column.TenHienThi_EN : column.TenHienThi_VI)) || column.TenHienThi_VI || column.TenHienThi_EN || maCotDiem
    },
    getExcelTableFromCotDiem(dsCotDiem, sheetTitle, semesterValue) {
      const uniqueHocSinhID = [...new Set((dsCotDiem ?? []).map(x => x.HocSinhID))]
      const hasGroupClass = dsCotDiem.some(row => String(row.TenLopNhom || '').trim())
      const orderedGradeColumns = this.getOrderedGradeColumns(dsCotDiem)
      const visibleGradeCodes = new Set(orderedGradeColumns.map(column => column.MaCotDiem))
      const dsHocSinh = []
      
      for (const hocSinhID of uniqueHocSinhID) {
        const hocSinh = dsCotDiem.find(x => x.HocSinhID === hocSinhID)
        if (!hocSinh) continue

        const obj = {
          SoDanhBo: hocSinh.SoDanhBo,
          TenLop: hocSinh.TenLop,
          HoTen: hocSinh.HoTen,
          HocSinhID: hocSinh.HocSinhID,
        }
        // Chỉ thêm khóa TenLopNhom khi có header tương ứng; JExcel suy ra cột thừa từ khóa không khai báo.
        if (hasGroupClass) obj.TenLopNhom = hocSinh.TenLopNhom || ''

        const arrDSCotDiemFilter = dsCotDiem.filter(x => x.HocSinhID === hocSinhID)
        for (const score of arrDSCotDiemFilter) {
          if (!visibleGradeCodes.has(score.MaCotDiem)) continue
          obj[score.MaCotDiem] = score.KetQuaDanhGia_VI
        }
        dsHocSinh.push(obj)
      }

      const arrDSCotDiemFirstStudent = orderedGradeColumns

      const columnThongTinHocSinh = [
        { title: this.isEn ? 'Student ID' : 'Mã học sinh', name: 'HocSinhID' },
        { title: this.isEn ? 'Student Book No.' : 'Số Danh Bộ', name: 'SoDanhBo' },
        { title: this.isEn ? 'Home class' : 'Lớp gốc', name: 'TenLop' },
        { title: this.isEn ? 'Student Name' : 'Họ tên học sinh', name: 'HoTen' },
      ]
      if (hasGroupClass) {
        // Hiện tên lớp nhóm bên cạnh lớp gốc để phân biệt học sinh cùng lớp nhưng khác nhóm môn.
        columnThongTinHocSinh.splice(3, 0, { title: this.isEn ? 'Subject group' : 'Lớp nhóm', name: 'TenLopNhom' })
      }

      const columnsCotDiem = arrDSCotDiemFirstStudent.map((x) => {
        const title = this.getGradeColumnTitle(x, semesterValue)
        return {
          title,
          name: x.MaCotDiem,
        }
      })

      const columns = [...columnThongTinHocSinh, ...columnsCotDiem]
      
      return { name: sheetTitle, title: sheetTitle, headers: columns, rows: dsHocSinh }
    },
    async exportExcelAll() {
      if (!this.KhoiID || !this.getTemplateBangDiemIDs().length) return
      
      this.snackbarRef?.value?.showSnackbar({ message: this.isEn ? 'Exporting Excel for all terms...' : 'Đang xử lý xuất Excel tất cả các kì...', color: 'info' })
      const tables = []
      
      for (const sem of this.DSSemester) {
        const dsCotDiem = await this.fetchHocSinhRows(sem.value)
        if (dsCotDiem.length > 0) {
          const table = this.getExcelTableFromCotDiem(dsCotDiem, sem.title, sem.value)
          tables.push(table)
        }
      }

      if (tables.length === 0) {
        this.snackbarRef?.value?.showSnackbar({ message: this.isEn ? 'No data to export' : 'Không có dữ liệu để xuất', color: 'error' })
        return
      }

			this.openExportColumnDialog(tables, 'Bang_Diem_Chi_Tiet_Khoi' + (this.KhoiID || '') + '_' + (this.MonHocItem?.MonHocName || 'MonHoc') + '_TatCaCacKi.xlsx')
    },
    renderHocSinh() {
      const uniqueHocSinhID = [...new Set((this.DSCotDiem ?? []).map(x => x.HocSinhID))]
      const hasGroupClass = this.DSCotDiem.some(row => String(row.TenLopNhom || '').trim())
      const orderedGradeColumns = this.getOrderedGradeColumns(this.DSCotDiem)
      const visibleGradeCodes = new Set(orderedGradeColumns.map(column => column.MaCotDiem))
      const dsHocSinh = []

      for (const hocSinhID of uniqueHocSinhID) {
        const hocSinh = this.DSCotDiem.find(x => x.HocSinhID === hocSinhID)
        if (!hocSinh) continue

        const obj = {
          SoDanhBo: hocSinh.SoDanhBo,
          // Lớp hiển thị lấy từ hồ sơ học sinh-lớp, không lấy mã nhóm môn học.
          TenLop: hocSinh.TenLop,
          HoTen: hocSinh.HoTen,
          HocSinhID: hocSinh.HocSinhID,
        }
        // Chỉ thêm khóa TenLopNhom khi có header tương ứng; JExcel suy ra cột thừa từ khóa không khai báo.
        if (hasGroupClass) obj.TenLopNhom = hocSinh.TenLopNhom || ''

        const arrDSCotDiemFilter = this.DSCotDiem.filter(x => x.HocSinhID === hocSinhID)
        for (const score of arrDSCotDiemFilter) {
          if (!visibleGradeCodes.has(score.MaCotDiem)) continue
          obj[score.MaCotDiem] = score.KetQuaDanhGia_VI
        }
        dsHocSinh.push(obj)
      }

      const arrDSCotDiemFirstStudent = orderedGradeColumns

      const columnThongTinHocSinh = [
        {
          type: 'text',
          title: this.isEn ? 'Student ID' : 'Mã học sinh',
          name: 'HocSinhID',
          width: 100,
          backGroundColor: null,
          wrap: true,
          readOnly: true,
        },
        {
          type: 'text',
          title: this.isEn ? 'Student Book No.' : 'Số Danh Bộ',
          name: 'SoDanhBo',
          width: 100,
          backGroundColor: null,
          wrap: true,
          readOnly: true,
        },
        {
          type: 'text',
          title: this.isEn ? 'Home class' : 'Lớp gốc',
          name: 'TenLop',
          width: 110,
          backGroundColor: null,
          wrap: true,
          readOnly: true,
        },
        ...(hasGroupClass ? [{
          type: 'text',
          title: this.isEn ? 'Subject group' : 'Lớp nhóm',
          name: 'TenLopNhom',
          width: 110,
          backGroundColor: null,
          wrap: true,
          readOnly: true,
        }] : []),
        {
          type: 'text',
          title: this.isEn ? 'Student Name' : 'Họ tên học sinh',
          name: 'HoTen',
          width: 200,
          backGroundColor: null,
          wrap: true,
          align: 'left',
          readOnly: true,
        },
      ]

      const arrCotDiemWithAlignCenter = ['MucDoDanhGia']
      const listMonHoc = [5, 46, 76]

      const columnsCotDiem = arrDSCotDiemFirstStudent.map((x) => {
        const title = this.getGradeColumnTitle(x, this.Semester)

        if (x.GiaTriCotDiem === 'number') {
          return {
            type: 'numeric',
            title,
            name: x.MaCotDiem,
            typeValue: x.GiaTriCotDiem,
            autoWidth: true,
            decimal: '.',
            backGroundColor: x.HexBackground,
            width: x.WidthCSS,
            wrapText: true,
            readOnly: true,
          }
        }

        if (x.GiaTriCotDiem === 'text') {
          return {
            type: 'text',
            title,
            name: x.MaCotDiem,
            width: x.WidthCSS,
            typeValue: x.GiaTriCotDiem,
            backGroundColor: x.HexBackground,
            wrap: true,
            align: arrCotDiemWithAlignCenter.some(item => x.MaCotDiem.includes(item)) ? 'center' : 'left',
            readOnly: true,
          }
        }

        if (x.GiaTriCotDiem === 'ICO_Star') {
          return {
            type: 'html',
            title,
            name: x.MaCotDiem,
            width: x.WidthCSS,
            typeValue: x.GiaTriCotDiem,
            backGroundColor: x.HexBackground,
            wrap: true,
            align: 'center',
            readOnly: true,
          }
        }

        if (x.GiaTriCotDiem === 'Dropdown_text') {
          return {
            type: 'dropdown',
            title,
            name: x.MaCotDiem,
            width: x.WidthCSS,
            typeValue: x.GiaTriCotDiem,
            backGroundColor: x.HexBackground,
            wrap: true,
            align: 'center',
            source: ['Done', 'Not Yet'],
            readOnly: true,
          }
        }

        if (x.GiaTriCotDiem === 'Dropdown_THC') {
          return {
            type: 'dropdown',
            title,
            name: x.MaCotDiem,
            width: x.WidthCSS,
            typeValue: x.GiaTriCotDiem,
            backGroundColor: x.HexBackground,
            wrap: true,
            align: 'center',
            source: ['T', 'H', 'C'],
            readOnly: true,
          }
        }

        if (x.GiaTriCotDiem === 'Dropdown_TDC') {
          return {
            type: 'dropdown',
            title,
            name: x.MaCotDiem,
            width: x.WidthCSS,
            typeValue: x.GiaTriCotDiem,
            backGroundColor: x.HexBackground,
            wrap: true,
            align: 'center',
            source: ['T', 'Đ', 'C'],
            readOnly: true,
          }
        }

        if (x.GiaTriCotDiem === 'Dropdown_CD_D') {
          return {
            type: 'dropdown',
            title,
            name: x.MaCotDiem,
            width: x.WidthCSS,
            typeValue: x.GiaTriCotDiem,
            backGroundColor: x.HexBackground,
            wrap: true,
            align: 'center',
            source: ['CĐ', 'Đ'],
            readOnly: true,
          }
        }

        return null
      }).filter(Boolean)

      this.freezeColumns = (listMonHoc.includes(this.MonHocItem?.MonHocID) ? 5 : 4) + (hasGroupClass ? 1 : 0)
      this.columns = [...columnThongTinHocSinh, ...columnsCotDiem]
      this.DSHocSinh = dsHocSinh
      this.buildGradeCellStyles()
      this.keyComp += 1
      this.$nextTick(() => this.resizeGradebookTable())
    },
    columnLabelFromIndex(index) {
      let number = index + 1
      let label = ''
      while (number > 0) {
        const remainder = (number - 1) % 26
        label = String.fromCharCode(65 + remainder) + label
        number = Math.floor((number - 1) / 26)
      }
      return label
    },
    buildGradeCellStyles() {
      const rowByHocSinhId = new Map()
      this.DSHocSinh.forEach((student, index) => {
        rowByHocSinhId.set(String(student.HocSinhID), index + 1)
      })

      const columnByMaCotDiem = new Map()
      this.columns.forEach((column, index) => {
        columnByMaCotDiem.set(column.name, index)
      })

      const styles = {}
      for (const score of this.DSCotDiem ?? []) {
        // Bỏ qua khi API cũ chưa trả cờ khóa; chỉ tô màu khi có trạng thái thật để không gắn nhãn sai.
        if (!Object.prototype.hasOwnProperty.call(score, 'KhoaDiemTinhTrang')) continue

        const rowIndex = rowByHocSinhId.get(String(score.HocSinhID))
        const columnIndex = columnByMaCotDiem.get(score.MaCotDiem)
        if (rowIndex == null || columnIndex == null) continue

        // 0 (hoặc thiếu bản ghi khóa) nghĩa là chưa khóa; cột vẫn khóa được theo từng lớp/môn/cột.
        const isLocked = score.KhoaDiemTinhTrang === true
          || String(score.KhoaDiemTinhTrang).toLowerCase() === 'true'
          || Number(score.KhoaDiemTinhTrang) === 1
        if (isLocked) continue

        const cell = this.columnLabelFromIndex(columnIndex) + rowIndex
        styles[cell] = 'background-color: #fff2cc;'
      }
      this.styleSheet = styles
    },
    setThongKeHeaders() {
      const rowFirst = this.DataThongKe.length > 0 ? this.DataThongKe[0] : null
      const isSaoType = !!rowFirst && (
        Object.prototype.hasOwnProperty.call(rowFirst, 'SaoDuoi3')
        || Object.prototype.hasOwnProperty.call(rowFirst, 'Sao3')
        || Object.prototype.hasOwnProperty.call(rowFirst, 'Sao4')
        || Object.prototype.hasOwnProperty.call(rowFirst, 'Sao5')
      )

      if (isSaoType) {
        this.headers = [
          { title: this.isEn ? 'Term' : 'Giai đoạn', value: 'Semester' },
          { title: this.isEn ? 'Grade' : 'Khối', value: 'TenKhoiHoc' },
          { title: this.isEn ? 'Total students' : 'Tổng số học sinh', value: 'TongSoHocSinh', align: 'right' },
          { title: this.isEn ? 'Stars < 3' : 'Sao < 3', value: 'SaoDuoi3', align: 'right' },
          { title: this.isEn ? '% Stars < 3' : 'TL sao < 3', value: 'TiLeSaoDuoi3', align: 'right' },
          { title: this.isEn ? 'Stars 3' : 'Sao 3', value: 'Sao3', align: 'right' },
          { title: this.isEn ? '% Stars 3' : 'TL sao 3', value: 'TiLeSao3', align: 'right' },
          { title: this.isEn ? 'Stars 4' : 'Sao 4', value: 'Sao4', align: 'right' },
          { title: this.isEn ? '% Stars 4' : 'TL sao 4', value: 'TiLeSao4', align: 'right' },
          { title: this.isEn ? 'Stars 5' : 'Sao 5', value: 'Sao5', align: 'right' },
          { title: this.isEn ? '% Stars 5' : 'TL sao 5', value: 'TiLeSao5', align: 'right' },
        ]
        return
      }

      this.headers = [
        { title: this.isEn ? 'Term' : 'Giai đoạn', value: 'Semester' },
        { title: this.isEn ? 'Grade' : 'Khối', value: 'TenKhoiHoc' },
        { title: this.isEn ? 'Total students' : 'Tổng số học sinh', value: 'TongSoHocSinh', align: 'right' },
        { title: '<5', value: 'DiemDuoi5', align: 'right' },
        { title: this.isEn ? '% < 5' : 'TL <5', value: 'TiLeDiemDuoi5', align: 'right' },
        { title: '5', value: 'Diem5', align: 'right' },
        { title: this.isEn ? '% 5' : 'TL 5', value: 'TiLeDiem5', align: 'right' },
        { title: '6', value: 'Diem6', align: 'right' },
        { title: this.isEn ? '% 6' : 'TL 6', value: 'TiLeDiem6', align: 'right' },
        { title: '7', value: 'Diem7', align: 'right' },
        { title: this.isEn ? '% 7' : 'TL 7', value: 'TiLeDiem7', align: 'right' },
        { title: '8', value: 'Diem8', align: 'right' },
        { title: this.isEn ? '% 8' : 'TL 8', value: 'TiLeDiem8', align: 'right' },
        { title: '9', value: 'Diem9', align: 'right' },
        { title: this.isEn ? '% 9' : 'TL 9', value: 'TiLeDiem9', align: 'right' },
        { title: '10', value: 'Diem10', align: 'right' },
        { title: this.isEn ? '% 10' : 'TL 10', value: 'TiLeDiem10', align: 'right' },
      ]
    },
  },
	}
</script>

<style scoped>
/* Ghi đè giới hạn 230px của CSS dùng chung chỉ cho bảng trang này; chiều cao thực được đo theo viewport. */
.gradebook-page .gradebook-height-excel .jss_content {
  max-height: var(--gradebook-table-height, calc(100dvh - 150px)) !important;
}
</style>