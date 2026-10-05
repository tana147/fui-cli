<template>
	<div class="uc-hoc-bong-dialogs">
    <!-- Hiển thị đúng các dòng đã thay đổi trước khi gọi API cập nhật. -->
    <uc-dialog v-model="vueData.IsShowDialogConfirm" title="Xác nhận trước khi lưu" :width="600"
      done-text="Xác nhận" :done-loading="vueData.isLoadingSave" @onSubmit="submitSave" @on-submit="submitSave">
      <v-list>
        <v-list-item v-for="hocSinh in changedStudents" :key="hocSinh.HocSinhID"
          :title="hocSinh.HoTen + (hocSinh.TenLop ? ' - Lớp ' + hocSinh.TenLop : '')" />
      </v-list>
    </uc-dialog>

    <!-- Giữ nguyên state vueData để các hàm tải dữ liệu và làm sạch chuỗi tiếp tục dùng chung. -->
    <uc-dialog v-model="vueData.IsShowDialogAdd" title="Thêm học sinh vào danh sách học bổng" :width="650"
      done-text="Thêm" :done-loading="vueData.isLoadingAdd" @onSubmit="submitAdd" @on-submit="submitAdd">
      <v-autocomplete v-model="vueData.AddHocSinhSelected" :items="vueData.DSAllHocSinh" item-title="Title"
        :return-object="true" label="Tìm học sinh (họ tên / lớp / MSHS)" placeholder="Nhập tên, lớp hoặc MSHS..."
        :loading="vueData.isLoadingAddHocSinh" clearable variant="outlined" density="comfortable"
        hide-details="auto" />
      <v-text-field v-model="vueData.AddMucHocBong" class="mt-4" label="Mức học bổng"
        placeholder="VD: 25% học phí học kì I" variant="outlined" density="comfortable" hide-details="auto" />
    </uc-dialog>

    <!-- Cho phép chọn nhiều học sinh để submitDelHocSinh tạo đúng JsonIDs. -->
    <uc-dialog v-model="vueData.IsShowDialogDel" title="Xóa học sinh khỏi danh sách học bổng" :width="650"
      done-text="Xóa" :done-loading="vueData.isLoadingDel" @onSubmit="submitDelete" @on-submit="submitDelete">
      <v-autocomplete v-model="vueData.DelHocSinhSelected" :items="vueData.DSHocBong" item-title="Title"
        :return-object="true" multiple chips label="Chọn học sinh cần xóa" variant="outlined"
        density="comfortable" hide-details="auto" />
    </uc-dialog>
  </div>
</template>

<script>
	export default {
		props: {
    vueData: {
      type: Object,
      required: true
    }
  },
  computed: {
    changedStudents() {
      return typeof this.vueData.renderDSHocSinhChange === 'function'
        ? this.vueData.renderDSHocSinhChange()
        : []
    }
  },
  methods: {
    submitSave() {
      if (typeof this.vueData.confirmSaveHocBong === 'function') this.vueData.confirmSaveHocBong()
    },
    submitAdd() {
      if (typeof this.vueData.submitAddHocSinh === 'function') this.vueData.submitAddHocSinh()
    },
    submitDelete() {
      if (typeof this.vueData.submitDelHocSinh === 'function') this.vueData.submitDelHocSinh()
    }
  }
	}
</script>