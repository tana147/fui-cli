<template>
	<div class="wf-kanban-checklist d-flex flex-column h-100">
    <!-- Header & Progress -->
    <div class="checklist-header mb-4">
      <div class="d-flex align-center justify-space-between mb-2">
        <span class="text-subtitle-2 font-weight-bold text-primary">Tiến độ hoàn thành</span>
        <span class="text-caption font-weight-bold text-grey-darken-1">{{ completedCount }} / {{ totalCount }}</span>
      </div>
      <v-progress-linear :model-value="progressPercentage" color="success" height="8" rounded striped>
      </v-progress-linear>
    </div>

    <!-- Checklist Items -->
    <div class="checklist-body flex-grow-1" style="overflow-y: auto; margin-right: -4px; padding-right: 4px;">
      <div v-if="!items || items.length === 0" class="d-flex flex-column align-center justify-center py-8 text-grey">
        <v-icon size="40" class="mb-2" color="grey-lighten-2">mdi-format-list-checks</v-icon>
        <span class="text-caption">Không có danh mục hồ sơ nào</span>
      </div>

      <v-card v-for="(item, index) in localItems" :key="index" variant="flat" class="mb-3 border rounded-lg"
        :style="item.IsCompleted ? 'background-color: #e8f5e9; border-color: #4caf50;' : (item.IsDeferred ? 'background-color: #fff3e0; border-color: #ff9800;' : 'background-color: #ffffff; border-color: #eaeaea;')">
        <div class="pa-3">
          <div class="d-flex align-start ga-3">
            <!-- Checkbox -->
            <div class="pt-1">
              <v-checkbox-btn v-model="item.IsCompleted" :true-value="1" :false-value="0" :disabled="readonly"
                color="success" density="compact" hide-details @update:model-value="onItemToggle(item)">
              </v-checkbox-btn>
            </div>

            <!-- Content -->
            <div class="flex-grow-1" style="min-width: 0;">
              <!-- Title & Badges -->
              <div class="d-flex flex-wrap align-center ga-2 mb-1">
                <span class="text-body-2 font-weight-bold"
                  :style="item.IsCompleted ? 'color: #2e7d32; text-decoration: line-through;' : ''">
                  <span v-if="item.IsRequired" class="text-error font-weight-bold mr-1">*</span>{{ item.ItemName }}
                </span>
                <v-chip v-if="item.IsRequired" size="x-small" color="error" variant="flat" class="font-weight-bold px-1"
                  style="font-size: 9px; height: 16px;">
                  BẮT BUỘC
                </v-chip>
                <v-chip v-if="item.IsDeferred" size="x-small" color="warning" variant="flat"
                  class="font-weight-bold px-1" style="font-size: 9px; height: 16px;">
                  HẸN NỘP
                </v-chip>
              </div>

              <!-- Description -->
              <div v-if="item.Description" class="text-caption text-grey-darken-1 mb-2">
                {{ item.Description }}
              </div>

              <!-- Options: Hard vs Soft Copy -->
              <div v-if="!item.IsDeferred && item.AllowedMethods === 'BOTH' && !readonly"
                class="d-flex align-center ga-2 mb-2">
                <span class="text-caption font-weight-medium text-grey-darken-2" style="font-size: 11px;">Hình
                  thức:</span>
                <v-btn-toggle v-model="item.SubmitMethod" mandatory color="primary" density="compact"
                  style="height: 24px;" @update:model-value="onSubmitMethodChange(item)">
                  <v-btn value="SOFT_COPY" size="x-small" class="text-caption px-2"
                    style="text-transform: none; min-width: unset; height: 24px;">Bản mềm</v-btn>
                  <v-btn value="HARD_COPY" size="x-small" class="text-caption px-2"
                    style="text-transform: none; min-width: unset; height: 24px;">Bản cứng</v-btn>
                </v-btn-toggle>
              </div>

              <!-- Upload Attachment Area -->
              <div v-if="!item.IsDeferred && (item.SubmitMethod === 'SOFT_COPY' || item.AllowedMethods === 'ONLINE')"
                class="mt-2 mb-2 d-flex align-center flex-wrap ga-2">
                <v-btn v-if="!item.AttachmentUrl && !readonly" size="small" variant="outlined" color="primary"
                  prepend-icon="mdi-paperclip" class="text-caption" style="height: 28px;" @click="onUploadClick(item)">
                  Đính kèm file
                </v-btn>

                <v-chip v-if="item.AttachmentUrl" size="small" color="info" variant="tonal" :closable="!readonly"
                  @click:close="onRemoveAttachment(item)" class="text-caption">
                  <v-icon start size="14">mdi-file-document-outline</v-icon>
                  <a :href="getAttachmentUrl(item.AttachmentUrl)" target="_blank"
                    style="color: inherit; text-decoration: none; font-weight: bold; max-width: 140px;"
                    class="text-truncate" @click.stop>
                    {{ getAttachmentName(item.AttachmentUrl) }}
                  </a>
                </v-chip>
              </div>

              <!-- Hard Copy Indicator -->
              <div v-if="!item.IsDeferred && (item.SubmitMethod === 'HARD_COPY' || item.AllowedMethods === 'PHYSICAL')"
                class="text-caption text-success font-weight-medium d-flex align-center ga-1 my-2"
                style="font-size: 11px;">
                <v-icon size="14" color="success">mdi-folder-open-outline</v-icon>
                <span>Nộp bản cứng trực tiếp tại quầy</span>
              </div>

              <!-- Defer Submission Checkbox -->
              <div v-if="item.AllowDefer && !item.IsCompleted && !readonly" class="d-flex align-center ga-2 mt-2">
                <v-checkbox v-model="item.IsDeferred" label="Xin hoãn nộp sau" density="compact" hide-details
                  color="warning" class="text-caption mt-0" style="font-size: 11px;"
                  @update:model-value="onDeferToggle(item)"></v-checkbox>
              </div>

              <!-- Defer Date Selector -->
              <div v-if="item.IsDeferred"
                class="mt-2 d-flex align-center ga-2 bg-amber-lighten-5 pa-2 rounded border border-warning"
                style="border-style: dashed !important;">
                <span class="text-caption font-weight-bold text-amber-darken-4"
                  style="font-size: 11px; white-space: nowrap;">Hạn hẹn nộp:</span>
                <v-text-field v-model="item.DeferredDueDate" type="date" density="compact" variant="plain" hide-details
                  :disabled="readonly" class="text-caption text-amber-darken-4 font-weight-bold pa-0 ma-0"
                  style="max-width: 140px; font-size: 12px;" @change="onItemToggle(item)"></v-text-field>
              </div>

              <!-- Note Field -->
              <div class="mt-2 pt-1 border-top" style="border-top-style: dotted !important;">
                <v-text-field v-model="item.Note" placeholder="Ghi chú hồ sơ (ví dụ: đã nhận photo...)"
                  density="compact" variant="plain" hide-details :disabled="readonly"
                  class="text-caption text-grey pa-0 ma-0" style="font-size: 11px;" @blur="onItemToggle(item)">
                  <template v-slot:prepend-inner>
                    <v-icon size="12" color="grey">mdi-pencil-outline</v-icon>
                  </template>
                </v-text-field>
              </div>
            </div>
          </div>
        </div>
      </v-card>
    </div>
  </div>
</template>

<script>
	export default {
		props: {
    items: {
      type: Array,
      default: function () { return [] }
    },
    readonly: {
      type: Boolean,
      default: false
    }
  },
  data: function () {
    return {
      localItems: []
    }
  },
  watch: {
    items: {
      handler: function (newVal) {
        var arr = JSON.parse(JSON.stringify(newVal || []))
        arr.forEach(function (item) {
          item.IsCompleted = (item.IsCompleted === true || Number(item.IsCompleted) === 1) ? 1 : 0
          if (item.AllowedMethods === 'BOTH' && !item.SubmitMethod) {
            item.SubmitMethod = 'SOFT_COPY'
          }
        })
        this.localItems = arr
      },
      immediate: true,
      deep: true
    }
  },
  computed: {
    totalCount: function () {
      return this.localItems.length
    },
    completedCount: function () {
      return this.localItems.filter(function (i) { return i.IsCompleted || i.IsCompleted === 1 }).length
    },
    progressPercentage: function () {
      if (this.totalCount === 0) return 0
      return Math.round((this.completedCount / this.totalCount) * 100)
    }
  },
  methods: {
    onItemToggle: function (item) {
      this.$emit('update:items', this.localItems)
      this.$emit('item-change', item)
    },
    onSubmitMethodChange: function (item) {
      this.$emit('update:items', this.localItems)
      this.$emit('item-change', item)
    },
    onDeferToggle: function (item) {
      if (item.IsDeferred) {
        item.IsCompleted = false
        const oneWeekFromNow = new Date()
        oneWeekFromNow.setDate(oneWeekFromNow.getDate() + 7)
        item.DeferredDueDate = oneWeekFromNow.toISOString().substring(0, 10)
      } else {
        item.DeferredDueDate = null
      }
      this.$emit('update:items', this.localItems)
      this.$emit('item-change', item)
    },
    onUploadClick: function (item) {
      this.$emit('upload-requested', item)
    },
    onRemoveAttachment: function (item) {
      if (this.readonly) return
      item.AttachmentUrl = null
      this.$emit('update:items', this.localItems)
      this.$emit('item-change', item)
    },
    getAttachmentName: function (value) {
      if (!value) return "Đã đính kèm";
      try {
        var parsed = JSON.parse(value);
        if (parsed && parsed.FileName) return parsed.FileName;
      } catch (e) {}
      return String(value);
    },
    getAttachmentUrl: function (value) {
      if (!value) return "#";
      try {
        var parsed = JSON.parse(value);
        if (parsed && parsed.FileID) return "https://file.zentea.vn/iotdev/FileData/" + parsed.FileID;
      } catch (e) {}
      var fileId = String(value).trim();
      if (fileId && fileId.indexOf("http") === -1 && fileId.length >= 10) {
        return "https://file.zentea.vn/iotdev/FileData/" + fileId;
      }
      return fileId;
    }
  }
	}
</script>