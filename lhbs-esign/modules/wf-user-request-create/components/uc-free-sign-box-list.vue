<template>
	<div class="wf-free-sign-panel">
    <div class="wf-free-sign-panel__section">
      <div class="wf-free-sign-panel__section-title">Tài liệu</div>
      <div class="wf-free-sign-file-card" @click="$emit('open-file-dialog')">
        <div class="wf-free-sign-file-card__icon">
          <v-icon size="18" color="primary">mdi-file-document-outline</v-icon>
        </div>
        <div class="wf-free-sign-file-card__content">
          <div class="wf-free-sign-file-card__title">{{ displayFileName }}</div>
          <div class="wf-free-sign-file-card__sub">{{ displayFileSub }}</div>
        </div>
        <v-btn variant="text" size="small" color="primary">
          <v-icon size="16">mdi-pencil-outline</v-icon>
        </v-btn>
      </div>
      <v-text-field v-model="form.title" label="Tên văn bản" variant="outlined" density="compact" class="wf-free-sign-panel__field">
    </v-text-field></div>

    <div class="wf-free-sign-panel__section">
      <div class="wf-free-sign-panel__section-title">Thiết lập ký</div>
      <v-select v-model="form.categoryId" :items="categories" item-title="Name" item-value="CategoryID" label="Nhóm văn bản" variant="outlined" density="compact" class="wf-free-sign-panel__field">

      <v-select v-model="form.executionEngine" :items="executionEngineOptions" item-title="title" item-value="value" label="Engine ký" variant="outlined" density="compact" class="wf-free-sign-panel__field">

      <v-select v-model="form.contractProvider" :items="contractProviderOptions" item-title="title" item-value="value" label="Nhà cung cấp eContract" variant="outlined" density="compact" :disabled="effectiveEngine !== 'ECONTRACT'" class="wf-free-sign-panel__field">

      <details class="wf-free-sign-panel__advanced">
        <summary>Thông tin bổ sung</summary>
        <div class="wf-free-sign-panel__advanced-grid">
          <v-text-field v-model="form.code" label="Mã tham chiếu" variant="outlined" density="compact">
          <v-text-field v-model="form.dueDate" type="date" label="Hạn xử lý" variant="outlined" density="compact">
          <v-select v-model="form.priority" :items="priorityOptions" item-title="title" item-value="value" label="Mức ưu tiên" variant="outlined" density="compact">
          <div></div>
          <v-textarea v-model="form.description" label="Mô tả / ghi chú" variant="outlined" density="compact" rows="2" class="wf-request-span-2">
        </v-textarea></v-select></v-text-field></v-text-field></div>
      </details>
    </v-select></v-select></v-select></div>

    <v-divider class="wf-free-sign-panel__divider"></v-divider>

    <div class="wf-free-sign-panel__section-title-row">
      <div class="wf-free-sign-panel__section-title">Vị trí ký</div>
      <v-chip size="x-small" color="primary" variant="tonal">{{ boxCount }} box ký</v-chip>
    </div>

    <div v-if="boxCount === 0" class="wf-empty-state">
      Chưa có box nào. Tải PDF lên, sau đó click trên vùng văn bản để đặt box ký.
    </div>

    <div v-else="" class="wf-free-sign-box-list">
      <div v-for="(box, index) in signBoxes" :key="'summary-' + index" class="wf-free-sign-box-list__item" :class="{ active: selectedBoxIndex === index }" @click="onBoxItemSelect(index)" @dblclick="onBoxItemOpen(index)">
        <div class="wf-free-sign-box-list__head">
          <div class="wf-free-sign-box-list__title">Box #{{ box.BoxOrder }}</div>
          <div class="wf-free-sign-box-list__actions">
            <v-chip size="x-small" color="primary" variant="tonal">Trang {{ box.PageNo || 1 }}</v-chip>
            <v-btn icon="" variant="text" size="x-small" color="error" class="wf-free-sign-box-list__delete" @click.stop="$emit('remove-box', index)">
              <v-icon size="14">mdi-close</v-icon>
            </v-btn>
          </div>
        </div>
        <div class="wf-free-sign-box-list__meta">{{ box.PersonName || box.SignerValue || "Chưa gán người ký" }}</div>
        <div class="wf-free-sign-box-list__sub">
          Thứ tự ký {{ box.SignerOrder || "?" }} - {{ formatSignerMethod(box.SignMethod) }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-free-sign-box-list",
  props: {
    form: { type: Object, default: function () { return {}; } },
    categories: { type: Array, default: function () { return []; } },
    executionEngineOptions: { type: Array, default: function () { return []; } },
    contractProviderOptions: { type: Array, default: function () { return []; } },
    priorityOptions: { type: Array, default: function () { return []; } },
    effectiveEngine: { type: String, default: "SMARTCA" },
    uploadLabel: { type: String, default: "" },
    uploadSubLabel: { type: String, default: "" },
    signBoxes: { type: Array, default: function () { return []; } },
    boxCount: { type: Number, default: 0 },
    selectedBoxIndex: { type: Number, default: -1 },
    formatSignerMethod: { type: Function, required: true }
  },
  emits: ["select-box", "open-box-dialog", "open-file-dialog", "remove-box"],
  computed: {
    displayFileName: function () {
      return this.form.uploadedFileName || this.form.title || this.uploadLabel || "Chọn file PDF";
    },
    displayFileSub: function () {
      if (this.form.uploadedFileMime) return this.form.uploadedFileMime.toUpperCase();
      return this.uploadSubLabel || "Tải lên hoặc thay đổi file PDF cần ký";
    }
  },
  methods: {
    onBoxItemSelect: function (index) {
      this.$emit("select-box", index);
    },
    onBoxItemOpen: function (index) {
      this.$emit("select-box", index);
      this.$emit("open-box-dialog", index);
    }
  }
	}
</script>