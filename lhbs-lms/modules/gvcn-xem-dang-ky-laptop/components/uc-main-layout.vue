<template>
	<Global class="uc-main-layout">
    <template #header>
      <v-card>
        <v-card-title class="d-flex align-center text-primary">
          <v-icon class="mr-2">mdi-laptop</v-icon>
          <span>{{ isEn ? 'Track Laptop Usage - Form Teacher Class' : 'Theo dõi HS mang Laptop - Lớp chủ nhiệm' }}</span>
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
        <v-card-subtitle class="pb-3">
          {{ isEn ? 'Form teacher class:' : 'Lớp chủ nhiệm:' }}
          <v-chip v-for="lop in DSLopChuNhiem" :key="lop.LopID" size="small" color="primary" variant="tonal" class="ml-2">{{ lop.TenLop }}</v-chip>
        </v-card-subtitle>
        <v-card-text>
          <v-select v-model="TuanItem" :items="DSTuan" :item-title="formatTuanHienThi" return-object :label="isEn ? 'Select week' : 'Chọn tuần'" variant="outlined" density="compact" hide-details />
        </v-card-text>
      </v-card>
    </template>

    <div class="pa-4">
    <v-card>
      <v-card-title class="d-flex align-center text-primary flex-wrap">
        <v-icon class="mr-2">mdi-format-list-bulleted</v-icon>
        <span>{{ isEn ? 'Weekly Registration List' : 'Danh sách đăng ký trong tuần' }}</span>
      </v-card-title>
      <v-card-subtitle class="pt-0">{{ isEn ? '— grouped by day for easy notification to parents once/day' : '— gộp theo ngày để dễ báo phụ huynh 1 lần/ngày' }}</v-card-subtitle>
      <v-divider />
      <v-card-text>
        <div v-if="isLoading" class="text-center pa-6"><v-progress-circular indeterminate color="primary" /></div>
        <div v-else-if="!DSNhomNgay.length" class="text-center text-medium-emphasis pa-6">{{ isEn ? 'No registrations in this week' : 'Chưa có đăng ký trong tuần này' }}</div>
        <template v-else>
        <v-card v-for="nhom in DSNhomNgay" :key="nhom.LopID + '_' + nhom.NgayApDung" variant="outlined" class="mb-3 pa-3">
          <div class="d-flex align-center flex-wrap mb-2">
            <span class="text-subtitle-1 font-weight-medium">{{ nhom.ThuHienThi }} — {{ formatDate(nhom.NgayApDung) }}</span>
            <v-chip size="small" color="primary" variant="tonal" class="ml-2">
              {{ nhom.TongLuot }} {{ isEn ? 'registrations' : 'lượt đăng ký' }} — {{ nhom.TongHocSinh }} {{ isEn ? 'student slots' : 'lượt HS' }}
            </v-chip>
            <v-spacer />
            <v-btn size="small" color="primary" variant="outlined" prepend-icon="mdi-message-text-outline" @click="moDialogThongBaoPhuHuynh(nhom)">{{ isEn ? 'View content' : 'Xem nội dung' }}</v-btn>
          </div>

          <v-list class="pa-0 registration-list desktop-registration">
            <v-list-item v-for="luot in nhom.DSLuot" :key="luot.DangKyID" class="px-0">
              <template #prepend><v-avatar color="primary" variant="tonal" size="38"><v-icon size="20">mdi-laptop</v-icon></v-avatar></template>
              <v-list-item-title class="d-flex align-center flex-wrap">
                <span class="font-weight-medium mr-2">{{ luot.TenGiaoVienDangKy }}</span>
                <v-chip size="x-small" color="primary" variant="tonal">{{ luot.LoaiThietBi }}</v-chip>
              </v-list-item-title>
              <v-list-item-subtitle class="mt-1">{{ getNoiDungDangKy(luot) }} · {{ luot.BuoiHienThi }} - {{ isEn ? 'Period' : 'Tiết' }} {{ luot.TietHienThi }} · {{ luot.ThoiGianDangKyHienThi }}</v-list-item-subtitle>
              <template #append>
                <div class="registration-actions d-flex align-center flex-wrap">
                  <v-chip size="small" color="info" variant="tonal" class="mr-2">{{ luot.SoHocSinh }} {{ isEn ? 'students' : 'HS' }}</v-chip>
                  <v-chip size="small" :color="luot.SoViPham ? 'warning' : 'success'" variant="tonal" class="mr-2">{{ luot.SoViPham }} {{ isEn ? 'violations' : 'vi phạm' }}</v-chip>
                  <v-btn icon="mdi-eye" size="small" variant="text" :aria-label="isEn ? 'View details' : 'Xem chi tiết'" @click="onXemChiTiet(luot)" />
                </div>
              </template>
            </v-list-item>
          </v-list>
          <div class="mobile-registration">
            <v-card v-for="luot in nhom.DSLuot" :key="'mobile_' + luot.DangKyID" variant="tonal" class="mb-2 pa-3">
              <div class="d-flex align-center">
                <v-avatar color="primary" variant="tonal" size="34" class="mr-2"><v-icon size="18">mdi-laptop</v-icon></v-avatar>
                <div class="font-weight-medium text-body-2">{{ luot.TenGiaoVienDangKy }}</div>
                <v-spacer />
                <v-btn icon="mdi-eye" size="small" variant="text" :aria-label="isEn ? 'View details' : 'Xem chi tiết'" @click="onXemChiTiet(luot)" />
              </div>
              <div class="text-body-2 mt-2">{{ getNoiDungDangKy(luot) }} · {{ luot.BuoiHienThi }} - {{ isEn ? 'Period' : 'Tiết' }} {{ luot.TietHienThi }}</div>
              <div class="text-caption text-medium-emphasis mt-1">{{ luot.LoaiThietBi }} · {{ isEn ? 'Registered at' : 'Đăng ký lúc' }} {{ luot.ThoiGianDangKyHienThi }}</div>
              <div class="d-flex flex-wrap mt-2">
                <v-chip size="small" color="info" variant="tonal" class="mr-2">{{ luot.SoHocSinh }} {{ isEn ? 'students' : 'HS' }}</v-chip>
                <v-chip size="small" :color="luot.SoViPham ? 'warning' : 'success'" variant="tonal">{{ luot.SoViPham }} {{ isEn ? 'violations' : 'vi phạm' }}</v-chip>
              </div>
            </v-card>
          </div>
        </v-card>
        </template>
      </v-card-text>
    </v-card>

    <uc-dialog v-model="IsShowDialogChiTiet" :title="(isEn ? 'Registration details - ' : 'Chi tiết đăng ký - ') + (DangKyDangXem ? DangKyDangXem.TenLop : '')" :width="820" :is-show-done-btn="false">
          <template #subTitle v-if="DangKyDangXem">{{ DangKyDangXem.TenGiaoVienDangKy }} · {{ getNoiDungDangKy(DangKyDangXem) }} · {{ DangKyDangXem.BuoiHienThi }} - {{ isEn ? 'Period' : 'Tiết' }} {{ DangKyDangXem.TietHienThi }}</template>
          <div v-if="isLoadingChiTiet" class="text-center pa-6"><v-progress-circular indeterminate color="primary" /></div>
          <template v-else>
            <v-table class="desktop-registration" density="compact">
              <thead><tr><th>{{ isEn ? 'Student' : 'Học sinh' }}</th><th class="text-center" style="width: 100px">{{ isEn ? 'Violation' : 'Vi phạm' }}</th><th>{{ isEn ? 'Violation notes' : 'Ghi chú vi phạm' }}</th></tr></thead>
              <tbody>
                <tr v-for="hs in DSHocSinhChiTiet" :key="hs.DangKyHocSinhID">
                  <td>
                    <div class="font-weight-medium">{{ hs.HoTen }}</div>
                    <div class="text-caption text-medium-emphasis">{{ isEn ? 'Student ID' : 'Mã HS' }}: {{ hs.HocSinhID }}</div>
                    <div class="text-caption text-medium-emphasis">{{ isEn ? 'Reg. No' : 'SDB' }}: {{ hs.SoDanhBo }}</div>
                  </td>
                  <td class="text-center">
                    <v-checkbox :model-value="!!hs.IsViPham" density="compact" hide-details color="warning"
                      @update:model-value="val => onToggleViPham(hs, val)" />
                  </td>
                  <td>
                    <v-text-field :model-value="hs.GhiChuViPham" density="compact" variant="outlined" hide-details
                      :disabled="!hs.IsViPham" :placeholder="hs.IsViPham ? (isEn ? 'Enter violation note' : 'Nhập ghi chú vi phạm') : (isEn ? 'Check violation to enter note' : 'Tích chọn vi phạm để nhập ghi chú')"
                      @change="onGhiChuChange(hs, $event)" />
                  </td>
                </tr>
              </tbody>
            </v-table>
            <div class="mobile-registration">
              <v-card v-for="hs in DSHocSinhChiTiet" :key="hs.DangKyHocSinhID" variant="outlined" class="mb-2 pa-3">
                <div class="font-weight-medium">{{ hs.HoTen }}</div>
                <div class="text-caption text-medium-emphasis">{{ isEn ? 'Student ID' : 'Mã HS' }}: {{ hs.HocSinhID }}</div>
                <div class="text-caption text-medium-emphasis mb-2">{{ isEn ? 'Reg. No' : 'SDB' }}: {{ hs.SoDanhBo }}</div>
                <v-checkbox :model-value="!!hs.IsViPham" :label="isEn ? 'Violation' : 'Vi phạm'" density="compact" hide-details color="warning"
                  @update:model-value="val => onToggleViPham(hs, val)" />
                <v-textarea :model-value="hs.GhiChuViPham" :label="isEn ? 'Violation note' : 'Ghi chú vi phạm'" rows="2" density="compact" variant="outlined" hide-details class="mt-2"
                  :disabled="!hs.IsViPham" :placeholder="hs.IsViPham ? (isEn ? 'Enter violation note' : 'Nhập ghi chú vi phạm') : (isEn ? 'Check violation to enter note' : 'Tích chọn vi phạm để nhập ghi chú')"
                  @change="onGhiChuChange(hs, $event)" />
              </v-card>
            </div>
            <div v-if="!DSHocSinhChiTiet.length" class="text-center text-medium-emphasis pa-6">{{ isEn ? 'No students in this registration slot' : 'Chưa có học sinh trong lượt đăng ký này' }}</div>
          </template>
      <template #actions>
        <v-spacer />
        <v-btn variant="text" @click="IsShowDialogChiTiet = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
        <v-btn color="primary" variant="flat" prepend-icon="mdi-content-save"
          :loading="isSavingChiTiet" :disabled="!chiTietDaThayDoi" @click="luuTatCaViPham">{{ isEn ? 'Save' : 'Lưu' }}</v-btn>
      </template>
    </uc-dialog>
    <uc-dialog v-model="IsShowDialogThongBaoPH" :title="isEn ? 'Parent Notification' : 'Thông báo phụ huynh'" :width="680" :is-show-done-btn="false">
      <div class="notification-guide">{{ isEn ? 'Sample content to send to parents. You can edit before copying.' : 'Nội dung mẫu để gửi đến phụ huynh. Anh/chị có thể chỉnh sửa trước khi copy.' }}</div>
      <v-textarea v-model="NoiDungThongBaoPH" :label="isEn ? 'Notification content' : 'Nội dung thông báo'" variant="filled" rows="9" auto-grow hide-details="auto" />
      <template #actions>
        <v-spacer />
        <v-btn variant="text" @click="IsShowDialogThongBaoPH = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
        <v-btn color="primary" variant="flat" prepend-icon="mdi-content-copy" @click="copyNoiDungPhuHuynh">{{ isEn ? 'Copy content' : 'Copy nội dung' }}</v-btn>
      </template>
    </uc-dialog>
    </div>
  </Global>
</template>

<script>
	export default {
		inject: ['snackbarRef'],
		data() {
      const isEn = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
      if (this.$i18n) {
        this.$i18n.locale = isEn ? 'en' : 'vi';
      }
    return {
      isEn,
      NienKhoa: null, DSTuan: [], TuanItem: null, DSLopChuNhiem: [], DSDangKy: [], DSNhomNgay: [],
      IsShowDialogChiTiet: false, DangKyDangXem: null, DSHocSinhChiTiet: [], isLoading: false, isLoadingChiTiet: false,
      isSavingChiTiet: false, chiTietDaThayDoi: false,
      IsShowDialogThongBaoPH: false, NhomDangThongBao: null, NoiDungThongBaoPH: '',
    }
  },
  mounted() {
    window.addEventListener('storage', (e) => {
      if (e.key === 'IsLanguage') {
        const isEn = JSON.parse(e.newValue) ?? false;
        this.isEn = isEn;
        if (this.$i18n) this.$i18n.locale = isEn ? 'en' : 'vi';
        this.renderDSDangKy();
      }
    });
    this.loadInitialData();
  },
  watch: {
    TuanItem: { deep: true, handler() { if (this.TuanItem) this.loadDangKy() } },
    'vueData.NienKhoa': { immediate: true, handler(value) { if (value && !this.NienKhoa) this.loadInitialData() } },
    isEn() {
      this.renderDSDangKy();
    }
  },
  methods: {
    formatTuanHienThi(item) {
      if (!item) return ''
      let text = item.Tuan_HienThi || item.TenTuan || ''
      if (this.isEn) {
        text = text.replace(/Tuần/gi, 'Week').replace(/Tháng/gi, 'Month')
      }
      return text
    },
    setLanguage(val) {
      this.isEn = val;
      if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi';
      localStorage.setItem('IsLanguage', JSON.stringify(val));
    },
    async loadInitialData() {
      if (this.NienKhoa && this.DSTuan.length) return
      var nienKhoaResult = (typeof vueData !== 'undefined' && vueData.NienKhoa) || (await fetchPromise('lms/NienKhoa_Get', {}, { cache: false }))
      this.NienKhoa = Array.isArray(nienKhoaResult) ? (nienKhoaResult[0] && (nienKhoaResult[0].NienKhoa || nienKhoaResult[0].value || nienKhoaResult[0])) : (nienKhoaResult && nienKhoaResult.NienKhoa ? nienKhoaResult.NienKhoa : nienKhoaResult)
      const results = await Promise.all([fetchPromise('lms/TuanHocTap_Get', { NienKhoa: this.NienKhoa }, { cache: false }), fetchPromise('lms/Lop_Get_ByGVCN', { NienKhoa: this.NienKhoa }, { cache: false })])
      this.DSTuan = results[0] || []; this.DSLopChuNhiem = results[1] || []
      this.TuanItem = this.DSTuan.find(x => x.Is_Active === 1) || this.DSTuan[0] || null
    },
    async loadDangKy() {
      if (!this.TuanItem || !this.NienKhoa) return
      this.isLoading = true
      try {
        this.DSDangKy = await fetchPromise('lms/DangKyMangLaptop_Get', { NienKhoa: this.NienKhoa, TuanHocID: this.TuanItem.TuanHocID || 0, LopID: 0, KhoiID: 0, ViewMode: 'GVCN' }, { cache: false }) || []
        this.renderDSDangKy()
      } finally { this.isLoading = false }
    },
    renderDSDangKy() {
      const thuEnMap = { 8: 'Sun', 2: 'Mon', 3: 'Tue', 4: 'Wed', 5: 'Thu', 6: 'Fri', 7: 'Sat' };
      this.DSDangKy = this.DSDangKy.map(item => ({
        ...item,
        ThuHienThi: this.isEn ? (thuEnMap[item.Thu] || 'Day ' + item.Thu) : (item.Thu === 8 ? 'CN' : 'Thứ ' + item.Thu),
        BuoiHienThi: ({ 1: this.isEn ? 'Morning' : 'Sáng', 2: this.isEn ? 'Afternoon' : 'Chiều', 3: this.isEn ? 'Evening' : 'Tối' })[item.Buoi] || '',
        TietHienThi: Number(item.TietBatDau) === Number(item.TietKetThuc) ? String(item.TietBatDau) : item.TietBatDau + '-' + item.TietKetThuc,
        ThoiGianDangKyHienThi: this.formatDateTime(item.CreateTime)
      }))
      const groups = {}
      this.DSDangKy.forEach(item => { const key = item.LopID + '_' + item.NgayApDung; if (!groups[key]) groups[key] = { LopID: item.LopID, NgayApDung: item.NgayApDung, ThuHienThi: item.ThuHienThi, DSLuot: [], TongLuot: 0, TongHocSinh: 0 }; groups[key].DSLuot.push(item); groups[key].TongLuot += 1; groups[key].TongHocSinh += Number(item.SoHocSinh || 0) })
      this.DSNhomNgay = Object.keys(groups).map(key => groups[key]).sort((a, b) => new Date(b.NgayApDung) - new Date(a.NgayApDung))
    },
    // Nhận diện cả bản ghi mới và bản ghi cũ để báo cáo không hiển thị đăng ký GVCN như một môn học.
    isGVCNDangKy(item) {
      const value = String(item?.TenMonHoc || '').trim().toLowerCase()
      return Number(item?.IsGVCN || 0) === 1 || item?.IsGVCN === true || value === 'gvcn đăng ký thiết bị' || value === 'sinh hoạt (chủ nhiệm)' || value === 'sinh hoạt'
    },
    getNoiDungDangKy(item) {
      if (this.isGVCNDangKy(item)) return this.isEn ? 'Form teacher device registration' : 'GVCN đăng ký thiết bị'
      return item?.TenMonHoc || (this.isEn ? 'No subject specified' : 'Chưa xác định nội dung')
    },
    async onXemChiTiet(item) {
      this.DangKyDangXem = item; this.isLoadingChiTiet = true; this.IsShowDialogChiTiet = true
      this.chiTietDaThayDoi = false
      try {
        const res = await fetchPromise('lms/DangKyMangLaptop_HocSinh_Get', { DangKyID: item.DangKyID }, { cache: false }) || []
        this.DSHocSinhChiTiet = res.map(hs => ({
          ...hs,
          IsViPham: Boolean(hs.IsViPham && hs.IsViPham !== '0' && hs.IsViPham !== 'false'),
          GhiChuViPham: hs.GhiChuViPham || ''
        }))
      } finally { this.isLoadingChiTiet = false }
    },
    danhDauThayDoi() {
      this.chiTietDaThayDoi = true
    },
    onGhiChuChange(hs, value) {
      hs.GhiChuViPham = value && value.target ? value.target.value : (value == null ? '' : value)
      this.danhDauThayDoi()
    },
    onToggleViPham(hs, val) {
      hs.IsViPham = Boolean(val)
      if (!hs.IsViPham) {
        hs.GhiChuViPham = ''
      }
      this.chiTietDaThayDoi = true
    },
    async luuTatCaViPham() {
      if (!this.DSHocSinhChiTiet.length) return
      this.isSavingChiTiet = true
      try {
        await Promise.all(this.DSHocSinhChiTiet.map(hs =>
          fetchPromise('lms/DangKyMangLaptop_DanhDauViPham', {
            DangKyHocSinhID: hs.DangKyHocSinhID,
            IsViPham: !!hs.IsViPham,
            GhiChuViPham: hs.GhiChuViPham || ''
          }, { cache: false })
        ))
        this.chiTietDaThayDoi = false
        this.capNhatSoViPham()
        if (this.snackbarRef?.value?.showSnackbar) {
          this.snackbarRef.value.showSnackbar({ message: this.isEn ? 'Saved violation list' : 'Đã lưu danh sách vi phạm', color: 'success' })
        } else if (typeof window !== 'undefined' && window.Vue?.$toast) {
          window.Vue.$toast.success(this.isEn ? 'Saved violation list' : 'Đã lưu danh sách vi phạm')
        }
      } catch (error) {
        console.error('Lưu vi phạm thất bại', error)
        if (this.snackbarRef?.value?.showSnackbar) {
          this.snackbarRef.value.showSnackbar({ message: (this.isEn ? 'Save failed: ' : 'Lưu thất bại: ') + (error?.message || error), color: 'error' })
        }
      } finally {
        this.isSavingChiTiet = false
      }
    },
    capNhatSoViPham() {
      if (!this.DangKyDangXem) return
      const count = this.DSHocSinhChiTiet.filter(x => x.IsViPham).length
      this.DangKyDangXem.SoViPham = count
      this.DSDangKy.forEach(item => {
        if (item.DangKyID === this.DangKyDangXem.DangKyID) {
          item.SoViPham = count
        }
      })
    },
    async capNhatViPham(hs, value) { await this.saveViolation(hs, !!value, hs.GhiChuViPham || '') },
    async capNhatGhiChuViPham(hs) { await this.saveViolation(hs, !!hs.IsViPham, hs.GhiChuViPham || '') },
    async saveViolation(hs, value, note) { await fetchPromise('lms/DangKyMangLaptop_DanhDauViPham', { DangKyHocSinhID: hs.DangKyHocSinhID, IsViPham: value, GhiChuViPham: note }, { cache: false }) },
    taoNoiDungPhuHuynh(nhom) {
      const ngay = nhom.NgayApDung ? new Date(nhom.NgayApDung).toLocaleDateString(this.isEn ? 'en-US' : 'vi-VN') : ''
      const dsLuot = (nhom.DSLuot || []).map(l => {
        const noiDung = this.getNoiDungDangKy(l)
        const moTa = this.isGVCNDangKy(l)
          ? (this.isEn ? 'form teacher device registration' : 'GVCN đăng ký thiết bị')
          : (this.isEn ? 'subject ' : 'môn ') + noiDung + ' (' + (this.isEn ? 'subject teacher: ' : 'GVBM: ') + (l.TenGiaoVienDangKy || '') + ')'
        return '- ' + l.BuoiHienThi + ' ' + (this.isEn ? 'period ' : 'tiết ') + l.TietHienThi + ', ' + moTa + ', ' + (this.isEn ? 'device: ' : 'thiết bị: ') + (l.LoaiThietBi || '')
      }).join('\n')
      if (this.isEn) {
        return `Dear Parents,\n\nThe school notifies that students of class ${nhom.DSLuot?.[0]?.TenLop || ''} are allowed to bring electronic devices to school on ${nhom.ThuHienThi}, ${ngay}, specifically:\n${dsLuot}\n\nWe kindly request parents to remind students to use devices for learning purposes only.\n\nSincerely,\nForm Teacher`
      }
      return `Kính gửi Quý phụ huynh,\n\nNhà trường thông báo: học sinh lớp ${nhom.DSLuot?.[0]?.TenLop || ''} được phép mang thiết bị điện tử đến trường vào ${nhom.ThuHienThi}, ngày ${ngay}, cụ thể:\n${dsLuot}\n\nKính mong Quý phụ huynh phối hợp nhắc nhở con em sử dụng thiết bị đúng mục đích học tập.\n\nTrân trọng,\nGVCN`
    },
    moDialogThongBaoPhuHuynh(nhom) {
      this.NhomDangThongBao = nhom
      this.NoiDungThongBaoPH = this.taoNoiDungPhuHuynh(nhom)
      this.IsShowDialogThongBaoPH = true
    },
    async copyNoiDungPhuHuynh() {
      const noiDung = this.NoiDungThongBaoPH || ''
      try {
        await navigator.clipboard.writeText(noiDung)
        if (typeof window !== 'undefined' && window.Vue?.$toast) window.Vue.$toast.success(this.isEn ? 'Copied parent notification content' : 'Đã copy nội dung gửi phụ huynh')
      } catch (error) {
        const textarea = document.createElement('textarea')
        textarea.value = noiDung; textarea.style.position = 'fixed'; textarea.style.opacity = '0'
        document.body.appendChild(textarea); textarea.select(); document.execCommand('copy'); textarea.remove()
        if (typeof window !== 'undefined' && window.Vue?.$toast) window.Vue.$toast.success(this.isEn ? 'Copied parent notification content' : 'Đã copy nội dung gửi phụ huynh')
      }
    },
    formatDate(value) { if (!value) return ''; const date = new Date(value); return date.toLocaleDateString(this.isEn ? 'en-US' : 'vi-VN') },
    formatDateTime(value) { if (!value) return ''; const date = new Date(value); const pad = number => String(number).padStart(2, '0'); return pad(date.getHours()) + ':' + pad(date.getMinutes()) + ' ' + pad(date.getDate()) + '/' + pad(date.getMonth() + 1) },
  },
	}
</script>