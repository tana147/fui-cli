<template>
	<v-dialog :model-value="modelValue" max-width="500" persistent
    @update:model-value="$emit('update:modelValue', $event)">
    <v-card class="rounded-xl" elevation="8">
      <v-card-title class="d-flex align-center ga-2 pa-5 pb-3">
        <v-icon size="20" color="primary">mdi-sitemap</v-icon>
        <span class="text-subtitle-1 font-weight-bold">{{ isEdit ? 'Sửa thông tin Project' : 'Tạo Project mới' }}</span>
      </v-card-title>

      <v-card-text class="pa-5 pt-2">
        <!-- Code -->
        <div class="mb-3">
          <div class="text-caption text-grey-darken-3 mb-1">Mã Project (Viết tắt) <span class="text-error">*</span>
          </div>
          <v-text-field v-model="form.Code" placeholder="VD: LHBS, ESIGN..." variant="outlined" density="compact"
            hide-details maxlength="20" class="wf-ant-input bg-white" :disabled="isEdit" @keydown.enter="save" />
        </div>

        <!-- Name -->
        <div class="mb-3">
          <div class="text-caption text-grey-darken-3 mb-1">Tên Project <span class="text-error">*</span></div>
          <v-text-field v-model="form.Name" placeholder="Nhập tên dự án..." variant="outlined" density="compact"
            hide-details maxlength="200" class="wf-ant-input bg-white" @keydown.enter="save" />
        </div>

        <!-- Description -->
        <div class="mb-3">
          <div class="text-caption text-grey-darken-3 mb-1">Mô tả</div>
          <v-textarea v-model="form.Description" placeholder="Mô tả ngắn gọn về project..." variant="outlined"
            density="compact" rows="2" hide-details auto-grow max-rows="4" class="wf-ant-input bg-white" />
        </div>

        <!-- Icon + Color -->
        <div class="d-flex ga-4 mb-3">
          <div style="flex: 1;">
            <div class="text-caption text-grey-darken-3 mb-1">Biểu tượng</div>
            <v-select v-model="form.Icon" :items="iconOptions" variant="outlined" density="compact" hide-details
              class="wf-ant-input bg-white">
              <template v-slot:selection="{ item }">
                <div class="d-flex align-center ga-2">
                  <v-icon size="16">{{ item.value }}</v-icon>
                  <span style="font-size: 11px;">{{ item.value.replace('mdi-', '') }}</span>
                </div>
              </template>
              <template v-slot:item="{ item, props }">
                <v-list-item v-bind="props">
                  <template v-slot:prepend>
                    <v-icon size="16">{{ item.value }}</v-icon>
                  </template>
                </v-list-item>
              </template>
            </v-select>
          </div>
          <div style="flex: 1;">
            <div class="text-caption text-grey-darken-3 mb-1">Màu chủ đạo</div>
            <v-select v-model="form.Color" :items="colorOptions" variant="outlined" density="compact" hide-details
              class="wf-ant-input bg-white">
              <template v-slot:selection="{ item }">
                <div class="d-flex align-center ga-2">
                  <div style="width: 12px; height: 12px; border-radius: 2px;" :style="{ background: item.value }"></div>
                  <span style="font-size: 11px;">{{ item.value }}</span>
                </div>
              </template>
              <template v-slot:item="{ item, props }">
                <v-list-item v-bind="props">
                  <template v-slot:prepend>
                    <div style="width: 14px; height: 14px; border-radius: 2px;" :style="{ background: item.value }">
                    </div>
                  </template>
                </v-list-item>
              </template>
            </v-select>
          </div>
        </div>
      </v-card-text>

      <v-card-actions class="pa-4 pt-0 d-flex ga-2">
        <v-spacer />
        <v-btn variant="text" color="grey" :disabled="saving" @click="close">Hủy</v-btn>
        <v-btn color="primary" variant="flat" :loading="saving" :disabled="!isValid"
          class="font-weight-bold text-caption text-white px-4" style="text-transform: none; border-radius: 4px;"
          @click="save">
          {{ isEdit ? 'Lưu' : 'Tạo' }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		name: 'uc-project-create-dialog',
    props: {
      modelValue: { type: Boolean, default: false },
      project: { type: Object, default: null }
    },
    emits: ['update:modelValue', 'success'],
    data: function () {
      return {
        saving: false,
        form: { ProjectID: null, Code: '', Name: '', Description: '', Icon: 'mdi-sitemap', Color: '#217D46' },
        iconOptions: ['mdi-sitemap', 'mdi-file-document-outline', 'mdi-handshake-outline', 'mdi-briefcase-outline',
          'mdi-folder-outline', 'mdi-rocket-launch-outline', 'mdi-account-group-outline', 'mdi-clipboard-check-outline',
          'mdi-bank-outline', 'mdi-cube-outline'],
        colorOptions: ['#217D46', '#2563eb', '#7c3aed', '#dc2626', '#ea580c', '#d97706', '#0891b2', '#64748b']
      }
    },
    computed: {
      isEdit: function () { return !!(this.project && this.project.ProjectID) },
      isValid: function () {
        return (this.form.Code || '').trim() !== '' && (this.form.Name || '').trim() !== ''
      }
    },
    watch: {
      modelValue: function (val) {
        if (val) this.resetForm()
      }
    },
    methods: {
      resetForm: function () {
        if (this.project && this.project.ProjectID) {
          this.form = {
            ProjectID: this.project.ProjectID,
            Code: this.project.Code || '',
            Name: this.project.Name || '',
            Description: this.project.Description || '',
            Icon: this.project.Icon || 'mdi-sitemap',
            Color: this.project.Color || '#217D46'
          }
        } else {
          this.form = { ProjectID: null, Code: '', Name: '', Description: '', Icon: 'mdi-sitemap', Color: '#217D46' }
        }
      },

      close: function () {
        this.$emit('update:modelValue', false)
      },

      save: async function () {
        if (!this.isValid || this.saving) return
        this.saving = true
        try {
          var payload = {
            Code: (this.form.Code || '').trim().toUpperCase(),
            Name: (this.form.Name || '').trim(),
            Description: (this.form.Description || '').trim(),
            Icon: this.form.Icon,
            Color: this.form.Color,
            Status: 'ACTIVE'
          }
          if (this.form.ProjectID) payload.ProjectID = this.form.ProjectID
          var res = await apiCallAsync('WF_Project_Save', payload)
          var row = Array.isArray(res) ? res[0] : res
          if (row && (row.Success === false || row.Success === 0)) {
            showToast.error(row.Message || 'Không thể lưu project.')
            return
          }
          showToast.success((row && row.Message) ? row.Message : 'Đã lưu project.')
          this.$emit('success', row ? row.ProjectID : null)
          this.close()
        } catch (e) {
          // apiCallAsync handles error toast
        } finally {
          this.saving = false
        }
      }
    }
	}
</script>