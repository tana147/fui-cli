<template>
	<Global class="uc-bgh-thong-ke-dang-ky">
    <template #header>
      <v-card>
        <v-card-title class="d-flex align-center flex-wrap ga-2 text-primary">
          <v-icon>mdi-chart-box-outline</v-icon>
          <span>Thống kê đăng ký mang thiết bị</span>
          <v-spacer />
          <v-chip size="small" color="primary" variant="tonal" prepend-icon="mdi-calendar-range">{{ scopeLabel }}</v-chip>
        </v-card-title>
        <v-card-subtitle class="pb-3">Tổng hợp đăng ký của GVBM/GVCN, học sinh, BGH và trạng thái đã đọc của GVCN/quản sinh.</v-card-subtitle>
        <v-card-text>
          <div class="d-flex align-center flex-wrap ga-3">
            <uc-date-range-picker v-model="dateRange" />
            <v-btn color="primary" variant="outlined" prepend-icon="mdi-refresh" :loading="isLoading" @click="loadStatistics">Làm mới</v-btn>
          </div>
        </v-card-text>
      </v-card>
    </template>

    <div class="pa-4">
      <v-progress-linear v-if="isLoading" indeterminate color="primary" class="mb-3" />

      <!-- KPI chỉ giữ một nhãn và một con số/card để người dùng quét nhanh quy mô dữ liệu. -->
      <v-row dense class="mb-2">
        <v-col v-for="metric in metrics" :key="metric.label" cols="12" sm="6" md="3">
          <v-card variant="tonal" :color="metric.color" rounded="lg" elevation="0" class="h-100">
            <v-card-text class="d-flex align-center ga-3 py-3">
              <v-avatar :color="metric.color" size="42"><v-icon color="white">{{ metric.icon }}</v-icon></v-avatar>
              <div>
                <div class="text-body-2" :class="`text-${metric.color}`">{{ metric.label }}</div>
                <div class="text-h5 font-weight-bold" :class="`text-${metric.color}`">{{ metric.value }}</div>
              </div>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>

      <v-alert v-if="!isLoading && !hasData" type="info" variant="tonal" density="comfortable" border="start" class="mb-4">
        Chưa có dữ liệu đăng ký trong khoảng thời gian đã chọn.
      </v-alert>

      <v-row dense class="mb-2">
        <v-col cols="12" md="7">
          <v-card class="h-100">
            <v-card-title class="d-flex align-center text-primary"><v-icon class="mr-2">mdi-chart-bar</v-icon>Số lượt đăng ký theo khối</v-card-title>
            <v-divider />
            <v-card-text>
              <div v-if="!DSTheoLop.length" class="text-center text-medium-emphasis pa-6">Chưa có dữ liệu</div>
              <uc-chart-apex v-else :options="ChartTheoKhoi" />
            </v-card-text>
          </v-card>
        </v-col>
        <v-col cols="12" md="5">
          <v-card class="h-100">
            <v-card-title class="d-flex align-center text-primary"><v-icon class="mr-2">mdi-bell-alert-outline</v-icon>Thông báo tới GVCN và quản sinh</v-card-title>
            <v-divider />
            <v-card-text>
              <div class="d-flex align-center justify-space-between mb-2"><span class="text-body-2">Đã đọc</span><span class="text-h5 font-weight-bold text-success">{{ soDaDoc }}/{{ DSThongBaoPH.length }}</span></div>
              <v-progress-linear :model-value="tyLeDaDoc" color="success" height="8" rounded class="mb-4" />
              <v-list density="compact" class="pa-0">
                <v-list-item class="px-0"><template #prepend><v-icon color="success" size="18">mdi-check-circle-outline</v-icon></template><v-list-item-title>Đã đọc</v-list-item-title><template #append><span class="font-weight-bold">{{ soDaDoc }}</span></template></v-list-item>
                <v-list-item class="px-0"><template #prepend><v-icon color="warning" size="18">mdi-clock-alert-outline</v-icon></template><v-list-item-title>Chưa đọc</v-list-item-title><template #append><span class="font-weight-bold">{{ soChuaDoc }}</span></template></v-list-item>
              </v-list>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>

      <v-row dense class="mb-2">
        <v-col cols="12">
          <v-card>
            <v-card-title class="d-flex align-center flex-wrap ga-2 text-primary">
              <v-icon>mdi-google-classroom</v-icon><span>Lượt đăng ký theo lớp</span><v-spacer />
              <v-text-field v-model="SearchTheoLop" prepend-inner-icon="mdi-magnify" label="Tìm lớp / người đăng ký" clearable density="compact" hide-details style="max-width: 230px" />
            </v-card-title>
            <v-divider />
            <v-data-table :headers="headersTheoLop" :items="DSTheoLop" :search="SearchTheoLop" :items-per-page="8" fixed-header height="420" density="compact" hover>
              <template #item.KhoiID="{ item }"><v-chip size="x-small" color="primary" variant="tonal">{{ item.KhoiID }}</v-chip></template>
              <template #item.SoLuot="{ item }"><span class="font-weight-bold text-primary">{{ item.SoLuot }}</span></template>
              <template #item.SoLuotHocSinh="{ item }"><span class="font-weight-bold">{{ item.SoLuotHocSinh }}</span></template>
              <template #no-data><div class="pa-6 text-center text-medium-emphasis">Chưa có dữ liệu lớp</div></template>
            </v-data-table>
          </v-card>
        </v-col>
      </v-row>
    </div>
  </Global>
</template>

<script>
	export default {
		data() {
      const now = new Date()
      const pad = value => String(value).padStart(2, '0')
      return {
        vueData,
        dateRange: { from: `${now.getFullYear()}-${pad(now.getMonth() + 1)}-01`, to: `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}` },
        DSTheoLop: [], DSHocSinh: [], DSThongBaoPH: [], SearchTheoLop: '', isLoading: false,
        ChartTheoKhoi: { chart: { type: 'bar', height: 300, toolbar: { show: false } }, series: [{ name: 'Số lượt đăng ký', data: [] }], xaxis: { categories: [] }, plotOptions: { bar: { borderRadius: 4, columnWidth: '45%' } }, dataLabels: { enabled: true }, colors: ['#1976D2'] },
        headersTheoLop: [{ title: 'Khối', key: 'KhoiID', width: 70, align: 'center' }, { title: 'Lớp', key: 'TenLop', minWidth: 80 }, { title: 'Người đăng ký', key: 'TenGiaoVienDangKy', minWidth: 150 }, { title: 'Lượt đăng ký', key: 'SoLuot', width: 115, align: 'end' }, { title: 'Lượt HS', key: 'SoLuotHocSinh', width: 90, align: 'end' }],
      }
    },
    mounted() { if (typeof IsCheck_NotRoleParent === 'function') IsCheck_NotRoleParent(vueData.user); this.loadInitialData() },
    watch: { dateRange: { deep: true, handler(value) { if (value && value.from && value.to) this.loadStatistics() } }, 'vueData.NienKhoa': { immediate: true, handler(value) { if (value) this.loadInitialData() } } },
    computed: {
      scopeLabel() { return this.formatDate(this.dateRange.from) + ' — ' + this.formatDate(this.dateRange.to) },
      hasData() { return this.DSTheoLop.length || this.DSHocSinh.length || this.DSThongBaoPH.length },
      tongLuotDangKy() { return this.DSTheoLop.reduce((sum, item) => sum + Number(item.SoLuot || 0), 0) },
      tongLuotHocSinh() { return this.DSTheoLop.reduce((sum, item) => sum + Number(item.SoLuotHocSinh || 0), 0) },
      tongLanViPham() { return this.DSHocSinh.reduce((sum, item) => sum + Number(item.SoLanViPham || 0), 0) },
      tongLop() { return new Set(this.DSTheoLop.map(item => this.cleanSheetValue(item.TenLop))).size },
      soDaDoc() { return this.DSThongBaoPH.filter(item => item.DaThongBaoHet).length },
      soChuaDoc() { return Math.max(this.DSThongBaoPH.length - this.soDaDoc, 0) },
      tyLeDaDoc() { return this.DSThongBaoPH.length ? Math.round(this.soDaDoc * 100 / this.DSThongBaoPH.length) : 0 },
      metrics() { return [
        { label: 'Lượt đăng ký', value: this.tongLuotDangKy, color: 'primary', icon: 'mdi-clipboard-text-outline' },
        { label: 'Lượt học sinh', value: this.tongLuotHocSinh, color: 'info', icon: 'mdi-account-group-outline' },
        { label: 'Lớp tham gia', value: this.tongLop, color: 'success', icon: 'mdi-google-classroom' },
        { label: 'Vi phạm', value: this.tongLanViPham, color: 'warning', icon: 'mdi-alert-outline' },
      ] },
    },
    methods: {
      async loadInitialData() { if (vueData.NienKhoa && this.dateRange.from && this.dateRange.to) await this.loadStatistics() },
      // Chuẩn hóa dữ liệu API trước khi bind vào bảng để không hiển thị object thô.
      cleanSheetValue(value, fallback = '') {
        if (value === null || value === undefined) return fallback
        if (typeof value === 'object') {
          const preferred = value.text ?? value.label ?? value.name ?? value.value
          if (preferred !== undefined) return this.cleanSheetValue(preferred, fallback)
          return Object.values(value).filter(item => item !== null && item !== undefined && typeof item !== 'object').join(' ').trim() || fallback
        }
        return String(value).trim() || fallback
      },
      isNotified(value) { return value === true || Number(value) === 1 || ['true', '1', 'yes', 'da'].includes(String(value).trim().toLowerCase()) },
      normalizeClassRows(rows) { return (Array.isArray(rows) ? rows : []).map(raw => ({ ...raw, KhoiID: this.cleanSheetValue(raw.KhoiID, '—'), TenLop: this.cleanSheetValue(raw.TenLop, 'Chưa rõ lớp'), TenGiaoVienDangKy: this.cleanSheetValue(raw.TenGiaoVienDangKy, '—'), SoLuot: Number(raw.SoLuot || 0), SoLuotHocSinh: Number(raw.SoLuotHocSinh || 0) })) },
      normalizeStudentRows(rows) { return (Array.isArray(rows) ? rows : []).map(raw => ({ ...raw, HoTen: this.cleanSheetValue(raw.HoTen, 'Chưa rõ tên'), TenLop: this.cleanSheetValue(raw.TenLop, '—'), SoLuot: Number(raw.SoLuot || 0), SoLanViPham: Number(raw.SoLanViPham || 0) })) },
      // Giữ nguyên cờ kỹ thuật từ API, nhưng hiển thị theo nghiệp vụ đọc thông báo của GVCN/quản sinh.
      normalizeNotificationRows(rows) { return (Array.isArray(rows) ? rows : []).map(raw => { const notified = this.isNotified(raw.DaThongBaoHet); return { ...raw, TenLop: this.cleanSheetValue(raw.TenLop, 'Chưa rõ lớp'), GiaoVienGanNhat: this.cleanSheetValue(raw.GiaoVienGanNhat, '—'), SoLuot: Number(raw.SoLuot || 0), DaThongBaoHet: notified } }) },
      async loadStatistics() {
        if (!this.dateRange.from || !this.dateRange.to || !vueData.NienKhoa || this.isLoading) return
        this.isLoading = true
        try {
          const input = { NienKhoa: vueData.NienKhoa, TuanHocID: 0, TuNgay: this.dateRange.from, DenNgay: this.dateRange.to }
          const result = await Promise.all([fetchPromise('lms/DangKyMangLaptop_ThongKe_TheoLop', input, { cache: false }), fetchPromise('lms/DangKyMangLaptop_ThongKe_HocSinh', input, { cache: false }), fetchPromise('lms/DangKyMangLaptop_ThongKe_ThongBaoPH', input, { cache: false })])
          this.DSTheoLop = this.normalizeClassRows(result[0]); this.DSHocSinh = this.normalizeStudentRows(result[1]); this.DSThongBaoPH = this.normalizeNotificationRows(result[2]); this.renderChart()
        } finally { this.isLoading = false }
      },
      renderChart() {
        const byGrade = {}
        this.DSTheoLop.forEach(row => { const key = this.cleanSheetValue(row.KhoiID, '—'); byGrade[key] = (byGrade[key] || 0) + Number(row.SoLuot || 0) })
        const grades = Object.keys(byGrade).sort((a, b) => Number(a) - Number(b))
        this.ChartTheoKhoi = { ...this.ChartTheoKhoi, series: [{ name: 'Số lượt đăng ký', data: grades.map(key => byGrade[key]) }], xaxis: { categories: grades.map(key => key === '—' ? key : 'Khối ' + key) } }
      },
      formatDate(value) {
        if (!value) return '—'
        const date = new Date(value)
        if (Number.isNaN(date.getTime())) return this.cleanSheetValue(value, '—')
        const pad = number => String(number).padStart(2, '0')
        return pad(date.getDate()) + '/' + pad(date.getMonth() + 1) + '/' + date.getFullYear()
      },
    },
	}
</script>