<template>
	<Global class="uc-main-layout">
    <template #header>
      <v-card class="mt-3">
        <v-card-text class="pa-0">
          <!-- Tab là điểm chuyển giữa hai luồng dữ liệu; mỗi tab dùng bộ action riêng để tránh trộn nghiệp vụ. -->
          <div class="d-flex align-center justify-space-between flex-wrap ga-2 px-3 pt-2">
            <div class="d-flex align-center ga-2 min-w-0">
              <v-icon color="primary">mdi-school-outline</v-icon>
              <span class="text-subtitle-1 font-weight-bold text-primary text-truncate">
                {{ vueData.activeTab === 'HOC_BONG' ? 'Danh sách học bổng' : 'Quản lý khen thưởng phong trào thi đua' }}
              </span>
              <v-chip size="x-small" color="primary" variant="tonal">
                {{ vueData.activeTab === 'HOC_BONG'
                  ? ('Tổng số: ' + (vueData.DSHocSinh || []).length + ' học sinh')
                  : ('Tổng số: ' + (vueData.DSPhongTraoMaster || []).length + ' phong trào') }}
              </v-chip>
            </div>

            <v-tabs
              v-model="vueData.activeTab"
              color="primary"
              density="compact"
              class="flex-grow-0"
              @update:model-value="vueData.onTabChange && vueData.onTabChange($event)"
            >
              <!-- GVCN chỉ được vào luồng phong trào; tab Học bổng là dữ liệu quản trị cấp trường. -->
              <v-tab v-if="vueData.canViewHocBong !== false" value="HOC_BONG">Học bổng</v-tab>
              <v-tab value="PHONG_TRAO">Phong trào thi đua</v-tab>
            </v-tabs>
          </div>

          <v-divider class="mt-2" />

          <!-- Hai bộ lọc dùng chung cho cả hai tab; watcher trong script sẽ gọi API theo tab hiện tại. -->
          <v-row dense class="px-3 py-2 align-center">
            <v-col cols="12" sm="6" md="3">
              <v-select
                v-model="vueData.Semester"
                :items="vueData.DSSemester"
                item-title="title"
                item-value="value"
                return-object
                label="Chọn học kì"
                variant="outlined"
                density="compact"
                hide-details="auto"
              />
            </v-col>
            <v-col cols="12" sm="6" md="3">
              <v-select
                v-model="vueData.KhoiItem"
                :items="vueData.DSKhoi"
                item-title="title"
                item-value="value"
                return-object
                label="Chọn khối"
                variant="outlined"
                density="compact"
                hide-details="auto"
              />
            </v-col>
          </v-row>

          <!-- Chỉ tab học bổng cần nhóm thao tác trên header; phong trào có toolbar riêng ở component master. -->
          <div v-if="vueData.activeTab === 'HOC_BONG'" class="d-flex align-center ga-2 flex-wrap px-3 pb-2">
            <v-btn
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-refresh"
              variant="outlined"
              color="primary"
              @click="vueData.reloadHocBongList && vueData.reloadHocBongList()"
            >
              Làm mới
            </v-btn>
            <v-btn
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-account-plus"
              variant="outlined"
              color="success"
              @click="vueData.openAddHocSinh && vueData.openAddHocSinh()"
            >
              Thêm học sinh
            </v-btn>
            <v-btn
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-account-minus"
              variant="outlined"
              color="warning"
              :disabled="(vueData.DSHocBong || []).length === 0"
              @click="vueData.DelHocSinhSelected = []; vueData.IsShowDialogDel = true"
            >
              Xóa học sinh
            </v-btn>
            <v-spacer />
            <v-btn
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-file-excel"
              variant="outlined"
              color="primary"
              :disabled="(vueData.DSHocBong || []).length === 0"
              @click="vueData.onExportExcel && vueData.onExportExcel()"
            >
              Xuất file Excel
            </v-btn>
            <v-btn
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-content-save"
              variant="outlined"
              color="primary"
              :disabled="(vueData.DSHocBong || []).length === 0"
              @click="vueData.onSave && vueData.onSave()"
            >
              Lưu
            </v-btn>
            <v-btn
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-certificate-outline"
              variant="flat"
              color="orange-darken-2"
              :loading="vueData.isLoadingPrint"
              :disabled="(vueData.DSHocBong || []).length === 0"
              @click="vueData.exportGiayChungNhanHocBong && vueData.exportGiayChungNhanHocBong()"
            >
              In giấy chứng nhận
            </v-btn>
          </div>
        </v-card-text>
      </v-card>
    </template>

    <div class="pa-3">
      <!-- Bảng học bổng vẫn dùng JExcel; wrapper giữ scroll ngang trong card. -->
      <v-card v-if="vueData.activeTab === 'HOC_BONG'">
        <v-card-text class="pa-0 overflow-x-auto">
          <uc-jexcel-hoc-bong />
        </v-card-text>
      </v-card>

      <uc-phong-trao-master v-if="vueData.activeTab === 'PHONG_TRAO'" />

      <!-- Chi tiết chỉ xuất hiện sau khi chọn một phong trào, tránh tạo một bảng rỗng chiếm diện tích. -->
      <v-card v-if="vueData.activeTab === 'PHONG_TRAO'" class="mt-3">
        <v-card-title class="d-flex align-center justify-space-between flex-wrap ga-2 py-2 px-3">
          <div class="d-flex align-center ga-2 min-w-0">
            <v-icon color="orange-darken-2">mdi-certificate</v-icon>
            <span class="font-weight-bold text-body-1 text-primary text-truncate">
              Chi tiết khen thưởng:
              {{ vueData.selectedPhongTrao ? vueData.selectedPhongTrao.TenPhongTrao : '(Chưa chọn phong trào)' }}
            </span>
            <v-chip
              v-if="vueData.selectedPhongTrao"
              size="x-small"
              :color="Number(vueData.selectedPhongTrao.LoaiMau) === 1 ? 'warning' : (Number(vueData.selectedPhongTrao.LoaiMau) === 2 ? 'success' : 'info')"
              variant="flat"
            >
              {{ Number(vueData.selectedPhongTrao.LoaiMau) === 1
                ? 'Mẫu 1 · Chỉ có lớp / Class only'
                : (Number(vueData.selectedPhongTrao.LoaiMau) === 2
                  ? 'Mẫu 2 · In sẵn tên học sinh + lớp'
                  : (Number(vueData.selectedPhongTrao.LoaiMau) === 3
                    ? 'Mẫu 3 · GVCN chọn học sinh lớp chủ nhiệm'
                    : 'Mẫu tập thể · In theo lớp / Class')) }}
            </v-chip>
            <v-chip v-if="vueData.selectedPhongTrao" size="x-small" color="primary" variant="tonal">
              Tổng: {{ (vueData.DSHocBongDetail || []).length }} khen thưởng
            </v-chip>
          </div>

          <div class="d-flex align-center ga-1 flex-wrap justify-end">
            <v-btn
              v-if="vueData.canManageSelectedPhongTrao"
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-account-plus"
              variant="outlined"
              color="success"
              :disabled="!vueData.selectedPhongTrao"
              @click="vueData.openAddChiTietPT && vueData.openAddChiTietPT()"
            >
              Thêm
            </v-btn>
            <v-btn
              v-if="vueData.canManageSelectedPhongTrao"
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-account-minus"
              variant="outlined"
              color="warning"
              :disabled="!vueData.selectedPhongTrao || (vueData.DSHocBongDetail || []).length === 0"
              @click="vueData.DelChiTietPTSelected = []; vueData.IsShowDialogDelChiTietPT = true"
            >
              Xóa
            </v-btn>
            <v-btn
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-file-excel"
              variant="outlined"
              color="primary"
              :disabled="!vueData.selectedPhongTrao || (vueData.DSHocBongDetail || []).length === 0"
              @click="vueData.onExportExcelPTDetail && vueData.onExportExcelPTDetail()"
            >
              Xuất Excel
            </v-btn>
            <v-btn
              v-if="vueData.canManageSelectedPhongTrao"
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-content-save"
              variant="outlined"
              color="primary"
              :disabled="!vueData.selectedPhongTrao || (vueData.DSHocBongDetail || []).length === 0"
              @click="vueData.onSavePTDetail && vueData.onSavePTDetail()"
            >
              Lưu
            </v-btn>
            <v-btn
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-printer-eye"
              variant="outlined"
              color="orange-darken-2"
              :loading="vueData.isLoadingPrintSample"
              :disabled="!vueData.selectedPhongTrao"
              title="In mẫu giấy khen (xem trước phôi và nội dung)"
              @click="vueData.exportGiayKhenMauPT && vueData.exportGiayKhenMauPT()"
            >
              In giấy khen mẫu
            </v-btn>
            <v-btn
              v-if="vueData.canManageSelectedPhongTrao"
              class="flex-shrink-0"
              size="small"
              prepend-icon="mdi-printer"
              variant="flat"
              color="orange-darken-2"
              :loading="vueData.isLoadingPrint"
              :disabled="!vueData.selectedPhongTrao || (vueData.DSHocBongDetail || []).length === 0"
              @click="vueData.exportGiayKhenPTDetail && vueData.exportGiayKhenPTDetail()"
            >
              In giấy khen (PDF)
            </v-btn>
          </div>
        </v-card-title>

        <v-card-text class="pa-0 overflow-x-auto">
          <!-- Khi chưa có quyền thao tác, khóa toàn bộ vùng chi tiết; quyền cụ thể được tính theo loại mẫu và SystemRight. -->
          <v-alert
            v-if="vueData.selectedPhongTrao && !vueData.canManageSelectedPhongTrao"
            type="info"
            variant="tonal"
            class="ma-3 mb-0"
          >
            Bạn đang ở chế độ chỉ xem phong trào này. Vui lòng liên hệ người được phân quyền để thêm dữ liệu hoặc in giấy khen.
          </v-alert>
          <uc-jexcel-hoc-bong v-if="vueData.selectedPhongTrao" />
          <div v-else class="pa-6 text-center text-medium-emphasis">
            Vui lòng bấm chọn một phong trào ở bảng phía trên để xem và quản lý danh sách khen thưởng.
          </div>
        </v-card-text>
      </v-card>
    </div>

    <uc-hoc-bong-dialogs :vue-data="vueData" />
  </Global>
</template>

<script>
	export default {
		data() {
    // Trạng thái màn hình được giữ cùng một object với script.js để các action CRUD hiện hữu
    // tiếp tục dùng chung dữ liệu, trong khi module.json chỉ còn nhiệm vụ mount component.
    const defaults = {
      activeTab: 'HOC_BONG',
      canViewHocBong: true,
      canManageSelectedPhongTrao: false,
      NienKhoa: null,
      instance: null,
      DSKhoi: [
        { title: 'Tất cả', value: 0, CapID: 0 },
        { title: 'Khối 6', value: 6, CapID: 2 },
        { title: 'Khối 7', value: 7, CapID: 2 },
        { title: 'Khối 8', value: 8, CapID: 2 },
        { title: 'Khối 9', value: 9, CapID: 2 },
        { title: 'Khối 10', value: 10, CapID: 3 },
        { title: 'Khối 11', value: 11, CapID: 3 },
        { title: 'Khối 12', value: 12, CapID: 3 }
      ],
      KhoiItem: { title: 'Tất cả', value: 0, CapID: 0 },
      keyComp: 0,
      columnHeader: [],
      DSHocSinh: [],
      TinhTrang: null,
      styleSheet: {},
      comments: {},
      freezeColumns: 4,
      Semester: { title: 'Học kì 1', value: 1 },
      DSSemester: [
        { title: 'Học kì 1', value: 1 },
        { title: 'Học kì 2', value: 2 },
        { title: 'Cả năm', value: 0 }
      ],
      DSHocSinhChange: [],
      IsShowDialogConfirm: false,
      isLoadingPrint: false,
      isLoadingSave: false,
      isLoadingAdd: false,
      isLoadingDel: false,
      isLoadingAddHocSinh: false,
      DSHocBong: [],
      DSAllHocSinh: [],
      IsShowDialogAdd: false,
      IsShowDialogDel: false,
      AddHocSinhSelected: null,
      AddMucHocBong: '25% học phí học kì I',
      DelHocSinhSelected: [],
      DSPhongTraoMaster: [],
      selectedPhongTrao: null,
      DSHocBongDetail: [],
      isLoadingMaster: false,
      isLoadingDetail: false,
      // Giữ nhãn dự phòng đồng nhất với danh sách mẫu trong script.js khi module chưa nạp dữ liệu động.
      DSLoaiMau: [
        { title: 'Mẫu 1 — Chỉ có lớp / Class only', value: 1 },
        { title: 'Mẫu 2 — In sẵn tên học sinh và lớp', value: 2 },
        { title: 'Mẫu 3 — GVCN chọn học sinh lớp chủ nhiệm', value: 3 },
        { title: 'Mẫu tập thể — In theo lớp / Class', value: 4 }
      ],
      IsShowDialogAddPhongTraoMaster: false,
      IsEditingPhongTrao: false,
      MasterForm_PhongTraoID: 0,
      MasterForm_TenPhongTrao: '',
      MasterForm_LoaiMau: 1,
      MasterForm_DanhHieu_VI: '',
      MasterForm_DanhHieu_EN: '',
      MasterForm_NamHoc: 'Năm học/ School Year 2026 - 2027',
      // Các field này thuộc contract Save master; giữ state để khi sửa field khác không làm mất dữ liệu cũ.
      MasterForm_NgayCap_VI: '',
      MasterForm_NgayCap_EN: '',
      MasterForm_SoQuyetDinh: '',
      // Field này dùng chung cho form thêm/sửa master và phải có state ngay từ lúc component khởi tạo.
      MasterForm_CacGiai: '',
      MasterForm_KhoiItem: null,
      MasterForm_GhiChu: '',
      isLoadingSavePhongTrao: false,
      IsShowDialogDelPhongTraoMaster: false,
      itemPhongTraoToDelete: null,
      isLoadingDelPhongTrao: false,
      IsShowDialogAddChiTietPT: false,
      DetailForm_HocSinhSelected: [],
      DetailForm_LopSelected: [],
      DetailForm_TenLop: '',
      DetailForm_LopItem: null,
      DetailForm_KhoiItem: null,
      DetailForm_DanhHieu_VI: '',
      DetailForm_DanhHieu_EN: '',
      DetailForm_VaoSo: null,
      DetailForm_NgayCap_VI: '',
      DetailForm_NgayCap_EN: '',
      DetailForm_SoQuyetDinhVaKhenThuong: '',
      DSAllLop: [],
      DSFilteredLop: [],
      DSEditFilteredLop: [],
      DSEditFilteredHocSinh: [],
      EditDetail_SelectedRecord: null,
      EditDetail_HocSinhItem: null,
      EditDetail_LopItem: null,
      EditDetail_KhoiItem: null,
      EditDetail_DanhHieu_VI: '',
      EditDetail_DanhHieu_EN: '',
      EditDetail_VaoSo: null,
      EditDetail_NgayCap_VI: '',
      EditDetail_NgayCap_EN: '',
      EditDetail_SoQuyetDinhVaKhenThuong: '',
      IsShowDialogEditChiTietPT: false,
      isLoadingAddChiTietPT: false,
      IsShowDialogDelChiTietPT: false,
      DelChiTietPTSelected: [],
      isLoadingDelChiTietPT: false
    }
    Object.keys(defaults).forEach(key => {
      if (vueData[key] === undefined) vueData[key] = defaults[key]
    })
    return {
      vueData
    }
  },
  mounted() {
    this.vueData.syncModuleRoleState && this.vueData.syncModuleRoleState()
    // Khi bỏ API action khỏi module.json, component tự khởi tạo đúng danh sách theo tab đang mở.
    if (this.vueData.activeTab === 'PHONG_TRAO') {
      this.vueData.reloadPhongTraoMaster && this.vueData.reloadPhongTraoMaster()
    } else {
      this.vueData.reloadHocBongList && this.vueData.reloadHocBongList()
    }
  },
  watch: {
    // Bộ lọc chỉ reload sau khi người dùng đã chọn xong học kỳ/khối; tránh gọi API với giá trị rỗng lúc khởi tạo.
    'vueData.NienKhoa'(value, oldValue) {
      if (!value || value === oldValue) return
      this.vueData.KhoiItem = (this.vueData.DSKhoi || []).find(item => item.value === 0) || {
        title: 'Tất cả',
        value: 0,
        CapID: 0
      }
      this.reloadCurrentTab()
    },
    'vueData.KhoiItem': {
      deep: true,
      handler(value) {
        if (value?.value === null || value?.value === undefined) return
        this.reloadCurrentTab()
      }
    },
    'vueData.Semester': {
      deep: true,
      handler(value) {
        if (value?.value === null || value?.value === undefined) return
        this.reloadCurrentTab()
      }
    },
    // UserInfo có thể được FUI nạp sau khi component đã mount; đồng bộ lại quyền
    // để GVCN không bị rơi tạm thời vào tab Học bổng trong khoảng thời gian đó.
    'vueData.user': {
      deep: true,
      handler() {
        this.vueData.syncModuleRoleState && this.vueData.syncModuleRoleState()
        if (this.vueData.canViewHocBong === false && this.vueData.activeTab === 'HOC_BONG') {
          this.vueData.activeTab = 'PHONG_TRAO'
          this.reloadCurrentTab()
        }
      }
    }
  },
  methods: {
    // Dùng chung một entry point để hai bộ lọc không phải tự biết chi tiết API của từng tab.
    reloadCurrentTab() {
      this.vueData.syncModuleRoleState && this.vueData.syncModuleRoleState()
      if (this.vueData.canViewHocBong === false && this.vueData.activeTab === 'HOC_BONG') {
        this.vueData.activeTab = 'PHONG_TRAO'
      }
      if (this.vueData.activeTab === 'PHONG_TRAO') {
        this.vueData.reloadPhongTraoMaster && this.vueData.reloadPhongTraoMaster()
      } else {
        this.vueData.DSHocSinh = []
        this.vueData.DSHocBong = []
        this.vueData.DSHocSinhChange = []
        this.vueData.reloadHocBongList && this.vueData.reloadHocBongList()
      }
    }
  }
	}
</script>