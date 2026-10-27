<template>
	<v-dialog :model-value="modelValue" max-width="460" persistent
    @update:model-value="$emit('update:modelValue', $event)">
    <v-card class="rounded-xl" elevation="8">
      <v-card-title class="d-flex align-center ga-2 pa-5 pb-3">
        <v-icon size="20" color="primary">mdi-vector-polyline-plus</v-icon>
        <span class="text-subtitle-1 font-weight-bold">Tạo quy trình mới trong Project</span>
      </v-card-title>

      <v-card-text class="pa-5 pt-2">
        <div class="d-flex ga-3 mb-3">
          <div style="width: 130px; flex-shrink: 0;">
            <div class="text-caption text-grey-darken-3 mb-1">Mã <span class="text-error">*</span></div>
            <v-text-field v-model="form.Code" placeholder="VD: TD_PV" variant="outlined" density="compact" hide-details
              maxlength="50" class="wf-ant-input bg-white" @input="form.Code = (form.Code || '').toUpperCase()" />
          </div>
          <div class="flex-grow-1">
            <div class="text-caption text-grey-darken-3 mb-1">Tên quy trình <span class="text-error">*</span></div>
            <v-text-field v-model="form.Name" placeholder="VD: Phỏng vấn ứng viên" variant="outlined" density="compact"
              hide-details maxlength="200" class="wf-ant-input bg-white" autofocus @keydown.enter="create" />
          </div>
        </div>
        <div class="text-caption text-grey" style="font-size: 11px;">
          <v-icon size="13" color="grey">mdi-information-outline</v-icon>
          Sau khi tạo, bạn sẽ được chuyển sang trình thiết kế để thêm các bước.
        </div>
      </v-card-text>

      <v-card-actions class="pa-4 pt-0 d-flex ga-2">
        <v-spacer />
        <v-btn variant="text" color="grey" :disabled="saving" @click="close">Hủy</v-btn>
        <v-btn color="primary" variant="flat" :loading="saving" :disabled="!isValid"
          class="font-weight-bold text-caption text-white px-4" style="text-transform: none; border-radius: 4px;"
          @click="create">Tạo &amp; thiết kế</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
	export default {
		name: 'uc-workflow-create-dialog',
  props: {
    modelValue: { type: Boolean, default: false },
    projectId: { type: [Number, String], default: null }
  },
  emits: ['update:modelValue', 'success'],
  data: function () {
    return {
      saving: false,
      form: { Code: '', Name: '' }
    }
  },
  computed: {
    isValid: function () {
      return (this.form.Code || '').trim() !== '' && (this.form.Name || '').trim() !== '' && !!this.projectId
    }
  },
  watch: {
    modelValue: function (val) {
      if (val) this.form = { Code: '', Name: '' }
    }
  },
  methods: {
    close: function () { this.$emit('update:modelValue', false) },

    create: async function () {
      if (!this.isValid || this.saving) return
      this.saving = true
      try {
        // 1) Tạo workflow (Definition)
        var res = await apiCallAsync('WF_Definition_Save', {
          Name: (this.form.Name || '').trim(),
          Code: (this.form.Code || '').trim().toUpperCase(),
          IsActive: 1
        })
        var row = Array.isArray(res) ? res[0] : res
        var newId = row ? row.DefinitionID : null
        if (!newId) { showToast.error((row && row.Message) ? row.Message : 'Không tạo được quy trình.'); return }

        // 2) Gắn ngay vào project
        var link = await apiCallAsync('WF_Definition_SetProject', { DefinitionID: newId, ProjectID: this.projectId })
        var lrow = Array.isArray(link) ? link[0] : link
        if (lrow && (lrow.Success === false || lrow.Success === 0)) {
          showToast.error(lrow.Message || 'Tạo được quy trình nhưng chưa gắn vào project.')
        }

        showToast.success('Đã tạo quy trình trong project.')
        this.$emit('success', newId)
        this.close()
        // 3) Chuyển sang trình thiết kế để thêm bước
        window.location.href = '/wf-admin-workflow-detail?id=' + newId
      } catch (e) {
        var msg = e && e.responseJSON ? e.responseJSON.Message : 'Không thể tạo quy trình.'
        showToast.error(msg)
      } finally {
        this.saving = false
      }
    }
  }
	}
</script>