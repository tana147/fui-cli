<template>
	<div class="d-flex wf-detail-settings">
    <div class="wf-tcard wf-detail-settings-card">
      <h3 class="wf-detail-settings-title mb-4">Thông tin chung</h3>

      <div class="mb-3">
        <div class="text-caption mb-1 text-grey-darken-2">Tên luồng</div>
        <v-text-field v-model="definition.Name" placeholder="Nhập tên luồng" variant="outlined" density="compact"
          hide-details class="wf-ant-input bg-white" />
      </div>

      <div class="mb-3">
        <div class="text-caption mb-1 text-grey-darken-2">Mã luồng</div>
        <v-text-field v-model="definition.Code" placeholder="Nhập mã luồng" variant="outlined" density="compact"
          hide-details class="wf-ant-input bg-white" />
      </div>

      <div class="mb-3">
        <div class="text-caption mb-1 text-grey-darken-2">Loại luồng</div>
        <v-select v-model="definition.CategoryID" :items="categoryOptions" item-title="title" item-value="value"
          placeholder="Chọn loại luồng" variant="outlined" density="compact" hide-details class="wf-ant-input bg-white"
          clearable />
      </div>

      <div class="mb-3">
        <div class="text-caption mb-1 text-grey-darken-2">Người quản lý luồng</div>
        <uc-select-user v-model="definition.AssignerID" placeholder="Chọn người quản lý luồng..." />
      </div>

      <div class="mb-3">
        <div class="text-caption mb-1 text-grey-darken-2">Mô tả</div>
        <v-textarea v-model="definition.Description" placeholder="Nhập mô tả" variant="outlined" density="compact"
          hide-details rows="2" class="wf-ant-input bg-white" />
      </div>

      <div class="mt-4">
        <v-switch v-model="definition.IsActive" label="Kích hoạt luồng" color="primary" density="compact"
          hide-details />
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		props: {
    definition: { type: Object, required: true },
    categories: { type: Array, default: () => [] },
    assigneeOptions: { type: Array, default: () => [] }
  },
  data: function () {
    return {
      definitionRejectOptions: [
        { value: "ADMIN_CHOOSE", label: "Admin chọn cách xử lý" },
        { value: "BACK_PREV", label: "Quay lại bước trước" },
        { value: "CANCEL", label: "Hủy toàn bộ luồng" }
      ]
    };
  },
  computed: {
    categoryOptions: function () {
      return (this.categories || []).map(function (item) {
        return { title: item.Name, value: item.CategoryID };
      });
    }
  }
	}
</script>