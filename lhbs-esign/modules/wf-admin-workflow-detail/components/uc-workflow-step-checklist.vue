<template>
	<div>
    <!-- Warning when Step is not saved yet -->
    <div v-if="!activeStep" class="pa-4 bg-amber-lighten-5 rounded border border-warning text-center my-3">
      <v-icon color="warning" size="28" class="mb-2">mdi-alert-circle-outline</v-icon>
      <div class="text-subtitle-2 font-weight-bold text-amber-darken-4">Dữ liệu chưa sẵn sàng</div>
      <div class="text-caption text-grey-darken-1 mt-1" style="max-width: 400px; margin: 0 auto;">
        Vui lòng cấu hình các bước trước.
      </div>
    </div>

    <!-- Active Editor -->
    <div v-else>
      <div class="d-flex align-center justify-space-between mb-3"
        style="border-bottom: 1px solid #e2e8f0; padding-bottom: 8px;">
        <div class="text-subtitle-2 font-weight-bold text-primary d-flex align-center ga-2">
          <v-icon color="primary">mdi-folder-open-outline</v-icon>
          Danh mục hồ sơ yêu cầu ({{ fileFields.length }})
        </div>
        <div class="text-caption text-grey-darken-1">
          <v-icon size="14" color="info" class="mr-1">mdi-information-outline</v-icon>
          Tự động đồng bộ từ tab <b>Trường dữ liệu</b>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="fileFields.length === 0"
        class="d-flex flex-column align-center justify-center py-8 px-4 text-center bg-white rounded border"
        style="gap: 16px; min-height: 200px; border-style: dashed !important;">
        <v-icon size="56" color="blue-grey-lighten-3">mdi-folder-plus-outline</v-icon>
        <div class="text-body-1 font-weight-bold text-blue-grey-darken-2">Chưa có hồ sơ nào được yêu cầu ở bước này
        </div>
        <div class="text-body-2 text-grey-darken-1" style="max-width: 400px; line-height: 1.5;">
          Hồ sơ được tự động lấy từ danh sách các <b>Trường dữ liệu kiểu File</b>. Để yêu cầu nộp hồ sơ CCCD, anh/chị
          cần gán nó vào bước này trước.
        </div>
        <v-btn color="primary" variant="flat" size="large" prepend-icon="mdi-arrow-right-bold"
          class="mt-2 text-none font-weight-bold" @click="$emit('switch-tab', 'fields')">
          Chuyển sang cấu hình Trường dữ liệu ngay
        </v-btn>
      </div>

      <!-- Checklist Items Table/List -->
      <div v-else class="d-flex flex-column ga-3">
        <div v-for="(item, idx) in fileFields" :key="item.FieldName"
          class="pa-3 rounded border bg-white d-flex flex-column ga-2"
          style="position: relative; transition: all 0.2s; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
          <!-- Top Row: Drag Handle/Index & Item Name -->
          <div class="d-flex align-center ga-2">
            <div
              class="bg-primary-lighten-5 text-primary font-weight-bold text-caption rounded-circle d-flex align-center justify-center"
              style="width: 24px; height: 24px; min-width: 24px; font-size: 11px;">
              {{ idx + 1 }}
            </div>

            <div class="flex-grow-1">
              <div class="text-body-2 font-weight-bold">{{ item.FieldLabel || item.FieldName }}</div>
              <div class="text-caption text-grey-darken-1">Mã trường: {{ item.FieldName }}</div>
            </div>

            <div class="d-flex align-center ga-2">
              <v-chip size="small" color="blue-grey" variant="tonal" class="font-weight-medium">
                {{ item.FieldOptions === 'PHYSICAL' ? 'Chỉ bản cứng' : item.FieldOptions === 'BOTH' ? 'Bản mềm & Bản
                cứng' : 'Chỉ bản mềm' }}
              </v-chip>
              <v-chip size="small" :color="item.IsRequired ? 'error' : 'grey'"
                :variant="item.IsRequired ? 'tonal' : 'outlined'">
                {{ item.IsRequired ? 'Bắt buộc nộp' : 'Không bắt buộc' }}
              </v-chip>
            </div>
          </div>
        </div>
      </div>

      <div class="mt-4 pa-3 bg-grey-lighten-4 rounded text-caption text-grey-darken-2 d-flex align-start ga-2">
        <v-icon size="16" color="grey-darken-1" class="mt-0.5">mdi-lightbulb-on-outline</v-icon>
        <div>
          <strong>Mẹo:</strong> Danh sách hồ sơ được tự động ánh xạ từ các <b>Trường dữ liệu kiểu File</b>. Bạn không
          cần cấu hình thủ công ở đây nữa. Mọi thay đổi về tên, mã, hoặc bắt buộc nộp vui lòng chỉnh sửa trực tiếp ở tab
          <b>Trường dữ liệu</b>.
        </div>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-workflow-step-checklist',
  props: {
    activeStep: {
      type: Object,
      required: true
    },
    fields: {
      type: Array,
      default: function() { return [] }
    }
  },
  computed: {
    fileFields: function () {
      var selected = this.activeStep.SelectedFieldNames || []
      return this.fields.filter(function(f) {
        return f.FieldType === 'file' && selected.indexOf(f.FieldName) !== -1
      }).sort(function(a, b) {
        var orderA = Number(a.SortOrder || 0);
        var orderB = Number(b.SortOrder || 0);
        return orderA - orderB;
      })
    }
  }
	}
</script>