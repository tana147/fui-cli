<template>
	<div>
    <div class="wf-request-cat-grid">
      <div v-for="item in categories" :key="item.CategoryID" class="wf-request-cat-card"
        :class="{ active: categoryId === item.CategoryID }" @click="$emit('select-category', item.CategoryID)">
        <div class="wf-request-cat-card__head">
          <div class="wf-request-cat-card__icon"
            :style="{ background: buildColorLight(item.Color), color: item.Color || 'var(--wf-primary)' }">
            <v-icon size="18">{{ item.Icon || "mdi-shape-outline" }}</v-icon>
          </div>
          <div>
            <div class="wf-request-cat-card__name">{{ item.Name }}</div>
            <div class="wf-request-cat-card__code">{{ item.Code }}</div>
          </div>
        </div>
        <div class="wf-request-cat-card__desc">
          {{ item.Description || ("Nhóm workflow " + item.Name.toLowerCase()) }}
        </div>
      </div>
    </div>

    <div class="wf-request-section-title">
      <span>Workflow khả dụng</span>
      <v-chip size="x-small" color="primary" variant="tonal">{{ filteredDefinitions.length }} workflow</v-chip>
    </div>

    <div v-if="isDefinitionLoading" class="wf-empty-state">Đang tải danh sách workflow...</div>

    <div v-else-if="filteredDefinitions.length === 0" class="wf-empty-state">
      Chưa có workflow hoạt động cho nhóm này. Chọn nhóm khác hoặc tạo thêm workflow ở trang cấu hình.
    </div>

    <div v-else class="wf-request-definition-grid">
      <div v-for="item in filteredDefinitions" :key="item.DefinitionID" class="wf-request-definition-card"
        :class="{ active: definitionId === item.DefinitionID }" @click="$emit('select-definition', item)">
        <div class="d-flex align-center" style="gap: 10px;">
          <div class="wf-step-badge"
            :style="{ background: buildColorLight(item.CategoryColor || 'var(--wf-primary)'), color: item.CategoryColor || 'var(--wf-primary)' }">
            {{ item.Version || 1 }}
          </div>
          <div style="flex:1; min-width:0;">
            <div class="wf-request-definition-card__name">{{ item.Name }}</div>
            <div class="wf-request-definition-card__code">{{ item.Code }} · {{ item.CategoryName || "Chưa phân loại" }}
            </div>
          </div>
          <v-chip size="x-small" :color="item.IsActive ? 'primary' : 'grey'"
            :variant="item.IsActive ? 'tonal' : 'outlined'">
            {{ item.IsActive ? "Hoạt động" : "Tạm dừng" }}
          </v-chip>
        </div>
        <div class="wf-request-definition-card__desc">{{ item.Description || "Không có mô tả" }}</div>
        <div class="wf-request-definition-card__meta">
          <span>{{ item.StepCount || 0 }} bước</span>
          <span>{{ item.ActiveInstances || 0 }} instance đang chạy</span>
          <span v-if="item.NotifyEmail">Có email</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-request-select-workflow",
  props: {
    categories: { type: Array, default: function () { return []; } },
    filteredDefinitions: { type: Array, default: function () { return []; } },
    categoryId: { type: [String, Number], default: null },
    definitionId: { type: [String, Number], default: null },
    isDefinitionLoading: { type: Boolean, default: false }
  },
  methods: {
    buildColorLight: function (color) {
      if (!color) return "rgba(var(--wf-primary-rgb), .12)";
      if (color.indexOf("#") === 0) return color + "18";
      return "rgba(var(--wf-primary-rgb), .12)";
    }
  }
	}
</script>