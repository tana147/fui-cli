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
              <v-select :key="'mon_' + isEn" v-model="MonHocItem" :label="isEn ? 'Select subject' : 'Chọn môn học'" :items="DSMonHoc" item-title="MonHocName"
                item-value="MonHocID" return-object="" :no-data-text="isEn ? 'No data available' : 'Chưa có dữ liệu'">
              </v-select>
            </v-col>
            <v-col cols="12" sm="6" md="4" class="d-flex align-center ga-2 flex-wrap flex-md-nowrap">
              <v-btn variant="outlined" color="primary" @click="onRefresh">
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

    <v-card class="pt-0 mt-3 elevation-1" v-if="DataThongKe.length > 0">
      <v-card-title class="d-flex text-primary">
        <span>{{ isEn ? 'Grade level statistics' : 'Thống kê kết quả các khối' }}</span>
      </v-card-title>
      <v-card-text>
        <v-data-table :items="DataThongKe" :headers="headers" items-per-page="-1" hide-default-footer=""
          style="max-height: calc(100dvh - 77px); overflow-y: auto;">
        </v-data-table>
      </v-card-text>
    </v-card>

    <v-card class="pt-0">
      <v-card-title class="d-flex text-primary px-0">
        <span>{{ isEn ? 'Detailed subject gradebook' : 'Bảng điểm chi tiết môn học' }}</span>
        <v-chip v-if="KhoiID > 0" class="ml-2" color="primary">{{ isEn ? ('Grade ' + KhoiID) : ('Khối ' + KhoiID) }}</v-chip>
        <v-chip v-if="MonHocItem?.MonHocID > 0" class="ml-2" color="primary">{{ MonHocItem.MonHocName }}</v-chip>
        <v-chip v-if="DSHocSinh.length > 0" class="ml-2" color="primary">{{ isEn ? 'Total students:' : 'Tổng số học sinh:' }} {{ DSHocSinh.length }}
        </v-chip>
      </v-card-title>

      <uc-jexcel v-if="DSHocSinh.length > 0" class="height-excel" :key="keyComp" :columns="columns"
        :data-source="DSHocSinh" :freeze-columns="freezeColumns" />
      <uc-card-empty v-else />
    </v-card>
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
      MaCotDiem: null,
      HocKi: null,
      Semester: null,
      headers: [],
      columns: [],
      freezeColumns: 3,
    }
  },
  computed: {
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
    MonHocItem(v) {
      this.DSCotDiem = []
      this.DSHocSinh = []
      this.DataThongKe = []
      if (v?.MonHocID > 0) {
        this.getHocSinh()
        this.getThongKe()
      }
    },
  },
  mounted() {
    window.addEventListener('storage', this.handleStorageChange)
    this.initMaCotDiem()
    this.setThongKeHeaders()
    this.getKhoi()
  },
  beforeUnmount() {
    window.removeEventListener('storage', this.handleStorageChange)
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
      })
      this.DSMonHoc = res ?? []
    },
    async getHocSinh() {
      if (!this.KhoiID || !this.MonHocItem?.TemplateBangDiemID || !this.Semester) return
      const res = await fetchPromise('lms/HocSinhBangDiem_Get_By_KhoiID_MonHocID', {
        KhoiID: this.KhoiID,
        TemplateBangDiemID: this.MonHocItem.TemplateBangDiemID,
        Semester: this.Semester,
        NienKhoa: vueData.NienKhoa,
      })
      this.DSCotDiem = res ?? []
      this.renderHocSinh()
    },
    async getThongKe() {
      if (!this.MonHocItem?.MonHocID) return
      const res = await fetchPromise('lms/ThongKeDiemTheoCap_MaCotDiem', {
        CapID: vueData.CapID,
        MonHocID: this.MonHocItem.MonHocID,
        MaCotDiem: this.MaCotDiem,
        HocKi: this.HocKi,
        NhomHocKi: this.Semester,
      })
      this.DataThongKe = res ?? []
      this.setThongKeHeaders()
    },
    onRefresh() {
      this.getHocSinh()
      this.getThongKe()
    },
    exportExcel() {
      const workbook = XLSX.utils.book_new()

      if (this.DataThongKe && this.DataThongKe.length > 0) {
        const thongKeHeaders = this.headers.map(x => x.title ?? x.value)
        const thongKeKeys = this.headers.map(x => x.value)
        const thongKeData = this.DataThongKe.map(item => thongKeKeys.map(key => item[key] ?? ''))
        const worksheetThongKe = XLSX.utils.aoa_to_sheet([thongKeHeaders, ...thongKeData])
        XLSX.utils.book_append_sheet(workbook, worksheetThongKe, 'ThongKeKhoi')
      }

      const detailHeaders = this.columns.map(x => x.title ?? x.name)
      const detailKeys = this.columns.map(x => x.name)
      const detailData = this.DSHocSinh.map(item => detailKeys.map(key => item[key] ?? ''))
      const worksheetDetail = XLSX.utils.aoa_to_sheet([detailHeaders, ...detailData])
      XLSX.utils.book_append_sheet(workbook, worksheetDetail, 'BangDiemChiTiet')

      XLSX.writeFile(
        workbook,
        `Bang_Diem_Chi_Tiet_Khoi${this.KhoiID || ''}_${this.MonHocItem?.MonHocName || 'MonHoc'}.xlsx`
      )
    },
    getExcelSheetFromCotDiem(dsCotDiem) {
      const uniqueHocSinhID = [...new Set((dsCotDiem ?? []).map(x => x.HocSinhID))]
      const dsHocSinh = []
      
      for (const hocSinhID of uniqueHocSinhID) {
        const hocSinh = dsCotDiem.find(x => x.HocSinhID === hocSinhID)
        if (!hocSinh) continue

        const obj = {
          SoDanhBo: hocSinh.SoDanhBo,
          HoTen: hocSinh.HoTen,
          HocSinhID: hocSinh.HocSinhID,
        }

        const arrDSCotDiemFilter = dsCotDiem.filter(x => x.HocSinhID === hocSinhID)
        for (const maCotDiem of arrDSCotDiemFilter) {
          obj[maCotDiem.MaCotDiem] = maCotDiem.KetQuaDanhGia_VI
        }
        dsHocSinh.push(obj)
      }

      const firstHocSinhID = uniqueHocSinhID[0]
      const arrDSCotDiemFirstStudent = firstHocSinhID
        ? dsCotDiem.filter(x => x.HocSinhID === firstHocSinhID)
        : []

      const columnThongTinHocSinh = [
        { title: this.isEn ? 'Student ID' : 'Mã học sinh', name: 'HocSinhID' },
        { title: this.isEn ? 'Student Book No.' : 'Số Danh Bộ', name: 'SoDanhBo' },
        { title: this.isEn ? 'Student Name' : 'Họ tên học sinh', name: 'HoTen' },
      ]

      const listMonHoc = [5, 46, 76]

      const columnsCotDiem = arrDSCotDiemFirstStudent.map((x) => {
        const title = (this.isEn ? x.TenHienThi_EN : (listMonHoc.includes(this.MonHocItem?.MonHocID) ? x.TenHienThi_EN : x.TenHienThi_VI)) || x.TenHienThi_VI || x.TenHienThi_EN || x.MaCotDiem
        return {
          title,
          name: x.MaCotDiem,
        }
      })

      const columns = [...columnThongTinHocSinh, ...columnsCotDiem]
      
      const detailHeaders = columns.map(x => x.title ?? x.name)
      const detailKeys = columns.map(x => x.name)
      const detailData = dsHocSinh.map(item => detailKeys.map(key => item[key] ?? ''))
      
      return XLSX.utils.aoa_to_sheet([detailHeaders, ...detailData])
    },
    async exportExcelAll() {
      if (!this.KhoiID || !this.MonHocItem?.TemplateBangDiemID) return
      
      this.snackbarRef?.value?.showSnackbar({ message: this.isEn ? 'Exporting Excel for all terms...' : 'Đang xử lý xuất Excel tất cả các kì...', color: 'info' })
      const workbook = XLSX.utils.book_new()
      
      for (const sem of this.DSSemester) {
        const res = await fetchPromise('lms/HocSinhBangDiem_Get_By_KhoiID_MonHocID', {
          KhoiID: this.KhoiID,
          TemplateBangDiemID: this.MonHocItem.TemplateBangDiemID,
          Semester: sem.value,
          NienKhoa: vueData.NienKhoa,
        })
        const dsCotDiem = res ?? []
        if (dsCotDiem.length > 0) {
          const worksheet = this.getExcelSheetFromCotDiem(dsCotDiem)
          let sheetName = sem.title
          XLSX.utils.book_append_sheet(workbook, worksheet, sheetName)
        }
      }
      
      if (workbook.SheetNames.length === 0) {
        this.snackbarRef?.value?.showSnackbar({ message: this.isEn ? 'No data to export' : 'Không có dữ liệu để xuất', color: 'error' })
        return
      }
      
      XLSX.writeFile(
        workbook,
        `Bang_Diem_Chi_Tiet_Khoi${this.KhoiID || ''}_${this.MonHocItem?.MonHocName || 'MonHoc'}_TatCaCacKi.xlsx`
      )
    },
    renderHocSinh() {
      const uniqueHocSinhID = [...new Set((this.DSCotDiem ?? []).map(x => x.HocSinhID))]
      const dsHocSinh = []

      for (const hocSinhID of uniqueHocSinhID) {
        const hocSinh = this.DSCotDiem.find(x => x.HocSinhID === hocSinhID)
        if (!hocSinh) continue

        const obj = {
          SoDanhBo: hocSinh.SoDanhBo,
          HoTen: hocSinh.HoTen,
          HocSinhID: hocSinh.HocSinhID,
        }

        const arrDSCotDiemFilter = this.DSCotDiem.filter(x => x.HocSinhID === hocSinhID)
        for (const maCotDiem of arrDSCotDiemFilter) {
          obj[maCotDiem.MaCotDiem] = maCotDiem.KetQuaDanhGia_VI
        }
        dsHocSinh.push(obj)
      }

      const firstHocSinhID = uniqueHocSinhID[0]
      const arrDSCotDiemFirstStudent = firstHocSinhID
        ? this.DSCotDiem.filter(x => x.HocSinhID === firstHocSinhID)
        : []

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
        const title = (this.isEn ? x.TenHienThi_EN : (listMonHoc.includes(this.MonHocItem?.MonHocID) ? x.TenHienThi_EN : x.TenHienThi_VI)) || x.TenHienThi_VI || x.TenHienThi_EN || x.MaCotDiem

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

      this.freezeColumns = listMonHoc.includes(this.MonHocItem?.MonHocID) ? 4 : 3
      this.columns = [...columnThongTinHocSinh, ...columnsCotDiem]
      this.DSHocSinh = dsHocSinh
      this.keyComp += 1
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