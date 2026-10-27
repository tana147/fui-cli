<template>
	<uc-modal :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="520px"
    :title="'Tạo nhiệm vụ mới'" :confirm-text="'Lưu'" :cancel-text="'Hủy'" @confirm="submitCreateInstance"
    :loading="isCreating">

    <div v-if="isLoadingDetail" class="pa-10 d-flex justify-center align-center" style="min-height: 200px;">
      <v-progress-circular indeterminate color="primary" size="40" />
    </div>

    <div v-else-if="createDefinitionDetail">
      <!-- 1. Chọn bước bắt đầu -->
      <div class="d-flex align-center justify-space-between mb-1 px-1">
        <span class="text-caption text-grey-darken-3">Bước bắt đầu <span
            class="text-error font-weight-bold">*</span></span>
        <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-medium px-1"
          style="height: 18px; font-size: 9px;">
          <v-icon start size="10" class="mr-1">mdi-chevron-right-circle-outline</v-icon>select
        </v-chip>
      </div>
      <v-select v-model="createSelectedStepIndex" :items="createStepOptions" item-title="title" item-value="value"
        variant="outlined" density="compact" class="wf-ant-input mb-4" />

      <!-- 2. Tên nhiệm vụ -->
      <div class="d-flex align-center justify-space-between mb-1 px-1">
        <span class="text-caption text-grey-darken-3">Tên nhiệm vụ <span
            class="text-error font-weight-bold">*</span></span>
        <v-chip size="x-small" color="secondary" variant="tonal" class="font-weight-medium px-1"
          style="height: 18px; font-size: 9px;">
          <v-icon start size="10" class="mr-1">mdi-form-textbox</v-icon>text
        </v-chip>
      </div>
      <v-text-field v-model="createForm.instanceName" variant="outlined" density="compact" class="wf-ant-input mb-4" />

      <!-- 3. Người phụ trách -->
      <div class="d-flex align-center justify-space-between mb-1 px-1">
        <span class="text-caption text-grey-darken-3">Người phụ trách</span>
        <v-chip size="x-small" color="info" variant="tonal" class="font-weight-medium px-1"
          style="height: 18px; font-size: 9px;">
          <v-icon start size="10" class="mr-1">mdi-account-search-outline</v-icon>select
        </v-chip>
      </div>
      <uc-select-user v-model="createForm.assigneeCode" placeholder="Tìm kiếm người phụ trách..." />

      <!-- Custom fields của bước đầu -->
      <template v-for="field in createDynamicFields" :key="field.FieldName">
        <div class="d-flex align-center justify-space-between mb-1 px-1 mt-4">
          <span class="text-caption text-grey-darken-3">
            {{ field.FieldLabel || field.FieldName }} <span v-if="field.IsRequired"
              class="text-error font-weight-bold">*</span>
          </span>
          <v-chip size="x-small" :color="getTypeBadgeInfo(field.FieldType).color" variant="tonal"
            class="font-weight-medium px-1" style="height: 18px; font-size: 9px;">
            <v-icon start size="10" class="mr-1">{{ getTypeBadgeInfo(field.FieldType).icon }}</v-icon>
            {{ getTypeBadgeInfo(field.FieldType).label }}
          </v-chip>
        </div>

        <!-- File Upload / Image Field -->
        <div v-if="field.FieldType === 'file' || field.FieldType === 'image'"
          class="border rounded pa-2 bg-white d-flex flex-column justify-center align-center border-dashed cursor-pointer mb-3 shadow-sm"
          style="border-color: #bdbdbd !important; min-height: 80px; position: relative;"
          @click="triggerFieldFileInput(field.FieldName)">
          <input :ref="'create_file_input_' + field.FieldName" type="file" style="display:none;"
            @change="onFieldFileSelected($event, field.FieldName, createForm.fieldValues)">
          <v-icon color="primary" class="mb-1" size="20" v-if="!createForm.fieldValues[field.FieldName]">
            mdi-cloud-upload-outline</v-icon>
          <div v-if="createForm.fieldValues[field.FieldName]" class="w-100 d-flex flex-column align-center" @click.stop>
            <template v-if="field.FieldType === 'image' || isImageFile(createForm.fieldValues[field.FieldName])">
              <div class="position-relative border rounded-lg overflow-hidden bg-grey-lighten-4 mb-2"
                style="width: 120px; height: 120px; border-color: #e2e8f0 !important;">
                <a :href="getFieldFileUrl(createForm.fieldValues[field.FieldName])" target="_blank"
                  class="d-block w-100 h-100">
                  <v-img :src="getFieldFileUrl(createForm.fieldValues[field.FieldName])" cover width="100%"
                    height="100%">
                    <template v-slot:placeholder>
                      <div class="d-flex align-center justify-center fill-height">
                        <v-progress-circular indeterminate color="grey-lighten-4" size="18"></v-progress-circular>
                      </div>
                    </template>
                  </v-img>
                </a>
                <v-btn icon size="x-small" color="error" class="position-absolute"
                  style="top: 4px; right: 4px; z-index: 10; width: 20px; height: 20px;" variant="flat"
                  @click="clearFieldFile(field.FieldName, createForm.fieldValues)">
                  <v-icon size="10">mdi-close</v-icon>
                </v-btn>
              </div>
              <a :href="getFieldFileUrl(createForm.fieldValues[field.FieldName])" target="_blank"
                class="text-blue-darken-3 text-truncate text-decoration-none font-weight-medium text-caption"
                style="max-width: 180px;">
                {{ getFieldFileName(createForm.fieldValues[field.FieldName]) }}
              </a>
            </template>
            <template v-else>
              <div class="d-flex align-center border rounded px-2 py-0.5 bg-blue-lighten-5 text-blue-darken-3"
                style="font-size: 11px; gap: 4px;">
                <v-icon size="12">mdi-paperclip</v-icon>
                <a :href="getFieldFileUrl(createForm.fieldValues[field.FieldName])" target="_blank"
                  class="text-blue-darken-3 text-truncate text-decoration-none font-weight-medium"
                  style="max-width: 140px;">
                  {{ getFieldFileName(createForm.fieldValues[field.FieldName]) }}
                </a>
                <v-btn icon size="x-small" variant="text" color="error" class="ml-1"
                  @click="clearFieldFile(field.FieldName, createForm.fieldValues)">
                  <v-icon size="10">mdi-close</v-icon>
                </v-btn>
              </div>
            </template>
          </div>
          <div v-else class="text-caption text-grey" style="font-size: 10px;">Bấm để chọn file tài liệu</div>
        </div>

        <!-- Checkbox Field -->
        <div v-else-if="field.FieldType === 'checkbox' || field.FieldType === 'checklist'"
          class="d-flex align-center mb-3">
          <v-checkbox :label="field.FieldOptions || ''"
            :model-value="Number(createForm.fieldValues[field.FieldName]) === 1 || createForm.fieldValues[field.FieldName] === true || createForm.fieldValues[field.FieldName] === 'true'"
            density="compact" color="primary" hide-details
            @update:model-value="toggleSingleCheckboxForCreate(field.FieldName)" />
        </div>

        <!-- Rating Stars Field -->
        <div v-else-if="field.FieldType === 'rating'"
          class="border rounded pa-2 bg-white d-flex align-center justify-space-between mb-3 shadow-sm">
          <v-rating v-model="createForm.fieldValues[field.FieldName]" color="amber" density="compact" size="small" />
          <span class="text-caption font-weight-bold text-amber-darken-2 mr-1">
            {{ Number(createForm.fieldValues[field.FieldName] || 0).toFixed(1) }} / 5.0
          </span>
        </div>

        <!-- Computed Formula Field -->
        <div v-else-if="field.FieldType === 'computed'" class="mb-3">
          <v-text-field v-model="createForm.fieldValues[field.FieldName]" placeholder="Tự động tính toán"
            variant="outlined" density="compact" hide-details="auto" readonly bg-color="grey-lighten-4"
            prepend-inner-icon="mdi-calculator-variant" class="wf-ant-input" />
        </div>

        <!-- Select Field -->
        <v-select v-else-if="field.FieldType === 'select'" v-model="createForm.fieldValues[field.FieldName]"
          :items="(field.FieldOptions || '').split(',')" variant="outlined" density="compact"
          class="wf-ant-input mb-3" />

        <!-- Textarea Field -->
        <v-textarea v-else-if="field.FieldType === 'textarea'" v-model="createForm.fieldValues[field.FieldName]"
          variant="outlined" density="compact" rows="2" class="wf-ant-input mb-3" />

        <!-- Standard Text/Number/Date Field -->
        <v-text-field v-else v-model="createForm.fieldValues[field.FieldName]"
          :type="field.FieldType === 'number' ? 'number' : field.FieldType === 'date' ? 'date' : 'text'"
          variant="outlined" density="compact" class="wf-ant-input mb-3" />
      </template>

      <!-- Preview nhiệm vụ bước đầu -->
      <template v-if="createFirstStepTasks.length">
        <v-divider class="my-3" />
        <div class="text-caption font-weight-bold text-grey-darken-1 mb-2">
          <v-icon size="13" class="mr-1">mdi-clipboard-check-outline</v-icon>
          {{ createFirstStepTasks.length }} Checklist công việc mẫu sẽ được thêm vào.
        </div>
        <div v-for="(task, ti) in createFirstStepTasks" :key="ti" class="d-flex align-center mb-1">
          <v-icon size="14" color="grey-lighten-1" class="mr-2">mdi-circle-small</v-icon>
          <span class="text-body-2 text-grey-darken-2">{{ sanitizeTaskText(task.TaskName) || '-' }}</span>
        </div>
      </template>
    </div>
  </uc-modal>
</template>

<script>
	export default {
		emits: ['update:modelValue', 'success'],
  props: {
    modelValue: { type: Boolean, default: false },
    definitionId: { type: [Number, String], default: null },
    preselectedStepId: { type: [Number, String], default: null }
  },
  data() {
    return {
      isLoadingDetail: false,
      createDefinitionDetail: null,
      createSelectedStepIndex: 0,
      createForm: { instanceName: '', assigneeCode: '', fieldValues: {} },
      isCreating: false
    }
  },
  computed: {
    createDynamicFields: function () {
      var detail = this.createDefinitionDetail
      if (!detail || !detail.Fields) return []
      var fields = detail.Fields.filter(function (f) { return !!f.FieldName })
      var firstStep = this.createFirstStep
      var selected = firstStep && firstStep.SelectedFieldNames && firstStep.SelectedFieldNames.length > 0
        ? firstStep.SelectedFieldNames : []
      if (!selected.length) return []
      return fields.filter(function (f) { return selected.indexOf(f.FieldName) !== -1 })
    },
    createStepOptions: function () {
      var detail = this.createDefinitionDetail
      if (!detail || !detail.Steps) return []
      return detail.Steps.map(function (s, i) {
        return { title: s.StepOrder + '. ' + s.StepName, value: i }
      })
    },
    createFirstStep: function () {
      var detail = this.createDefinitionDetail
      if (!detail || !detail.Steps || !detail.Steps.length) return null
      var idx = this.createSelectedStepIndex || 0
      return detail.Steps[idx] || detail.Steps[0]
    },
    createFirstStepTasks: function () {
      var firstStep = this.createFirstStep
      return firstStep ? (firstStep.Tasks || []) : []
    }
  },
  watch: {
    modelValue: function (newVal) {
      if (newVal) {
        this.loadDefinitionDetail()
      }
    },
    'createForm.fieldValues': {
      handler: function (nextValues) {
        var self = this;
        if (!nextValues) return;
        (this.createDynamicFields || []).forEach(function (field) {
          if (field.FieldType === 'computed') {
            var formula = field.FieldOptions || '';
            var newVal = self.evaluateComputedField(formula, self.createForm.fieldValues);
            if (String(self.createForm.fieldValues[field.FieldName] || '') !== String(newVal)) {
              self.createForm.fieldValues[field.FieldName] = newVal;
            }
          }
        });
      },
      deep: true
    }
  },
  methods: {
    loadDefinitionDetail: async function () {
      if (!this.definitionId) return
      this.isLoadingDetail = true
      this.createDefinitionDetail = null
      try {
        var data = await apiCallAsync('WF_Definition_GetDetail', { DefinitionID: this.definitionId })
        var info = data && data[0] && data[0][0] ? data[0][0] : {}
        var stepRows = data && data[1] ? data[1] : []
        var fieldRows = data && data[2] ? data[2] : []

        var steps = stepRows.map(function (s) {
          var step = Object.assign({}, s)
          step.SelectedFieldNames = []
          step.Tasks = []
          step.assignees = []
          if (step.ConditionJSON) {
            try {
              var cond = JSON.parse(step.ConditionJSON)
              step.SelectedFieldNames = cond.SelectedFieldNames || []
            } catch (e) { }
          }
          if (step.TasksJSON) {
            try { step.Tasks = JSON.parse(step.TasksJSON) || [] } catch (e) { }
          }
          if (step.AssigneesJSON) {
            try { step.assignees = JSON.parse(step.AssigneesJSON) || [] } catch (e) { }
          }
          return step
        })

        this.createDefinitionDetail = { DefinitionID: this.definitionId, Fields: fieldRows, Steps: steps }
        this.createForm.instanceName = ''
        this.createForm.assigneeCode = ''
        this.createForm.fieldValues = {}

        // Pre-fill first step values
        if (fieldRows) {
          var fValues = {}
          fieldRows.forEach(function (f) {
            fValues[f.FieldName] = f.DefaultValue !== undefined && f.DefaultValue !== null ? String(f.DefaultValue) : '';
          })
          this.createForm.fieldValues = fValues
        }

        // Chọn bước mặc định
        if (this.preselectedStepId && steps) {
          var stepIdx = steps.findIndex(s => Number(s.StepDefID) === Number(this.preselectedStepId))
          this.createSelectedStepIndex = stepIdx !== -1 ? stepIdx : 0
        } else {
          this.createSelectedStepIndex = 0
        }
      } catch (err) {
        console.error('Lỗi load chi tiết quy trình:', err)
      } finally {
        this.isLoadingDetail = false
      }
    },
    triggerFieldFileInput: function (fieldName) {
      var refName = 'create_file_input_' + fieldName
      var el = this.$refs[refName]
      var inputEl = Array.isArray(el) ? el[0] : el
      if (inputEl) {
        inputEl.click()
      }
    },
    onFieldFileSelected: async function (event, fieldName, targetValues) {
      var file = event.target.files && event.target.files[0]
      if (!file) return
      try {
        if (typeof showToast !== 'undefined' && showToast.info) showToast.info('Đang tải tệp lên...')
        var res = await uploadFileAsync(file)
        if (res && res.FileID) {
          targetValues[fieldName] = res.FileID
          if (typeof showToast !== 'undefined' && showToast.success) showToast.success('Tải lên thành công!')
        }
      } catch (err) {
        console.error('Lỗi tải tệp:', err)
      }
    },
    clearFieldFile: function (fieldName, targetValues) {
      targetValues[fieldName] = ""
    },
    getFieldFileUrl: function (fileID) {
      if (!fileID) return ""
      return "/api/file/download/" + fileID
    },
    getFieldFileName: function (fileID) {
      return "Document_" + fileID
    },
    isImageFile: function (fileID) {
      return false
    },
    toggleSingleCheckboxForCreate: function (fieldName) {
      var current = this.createForm.fieldValues[fieldName]
      if (current === 1 || current === true || current === 'true') {
        this.createForm.fieldValues[fieldName] = 0
      } else {
        this.createForm.fieldValues[fieldName] = 1
      }
    },
    evaluateComputedField: function (formula, values) {
      // Ưu tiên helper chung WF_FORMULA (lhbs-esign/imports/wf-formula-js.js); fallback inline nếu chưa nạp
      if (typeof window !== 'undefined' && window.WF_FORMULA) {
        return window.WF_FORMULA.evaluate(formula, values);
      }
      if (!formula) return '0';
      var expr = String(formula).trim();
      expr = expr.replace(/\[([^\]]+)\]/g, function (match, fieldName) {
        var v = Number((values || {})[fieldName.trim()]);
        return Number.isFinite(v) ? String(v) : '0';
      });
      Object.keys(values || {}).forEach(function (key) {
        var v = Number(values[key]);
        if (!Number.isFinite(v)) v = 0;
        expr = expr.replace(new RegExp('\\b' + key + '\\b', 'g'), String(v));
      });
      try {
        var s = expr.replace(/[^0-9+\-*/().\s]/g, '');
        if (!s.trim()) return '0';
        var r = Function('"use strict"; return (' + s + ')')();
        return Number.isFinite(r) ? (r % 1 === 0 ? String(r) : r.toFixed(1)) : '0';
      } catch (e) { return '0'; }
    },
    sanitizeTaskText: function (text) {
      if (!text) return ''
      return String(text).replace(/<\/?[^>]+(>|$)/g, "")
    },
    getTypeBadgeInfo: function (type) {
      const t = String(type || '').toLowerCase()
      if (t === 'number') return { label: 'Số', color: 'info', icon: 'mdi-numeric' }
      if (t === 'date') return { label: 'Ngày', color: 'indigo', icon: 'mdi-calendar' }
      if (t === 'file') return { label: 'Tệp', color: 'teal', icon: 'mdi-file-outline' }
      if (t === 'image') return { label: 'Ảnh', color: 'purple', icon: 'mdi-image-outline' }
      if (t === 'checkbox' || t === 'checklist') return { label: 'Checkbox', color: 'success', icon: 'mdi-checkbox-marked-outline' }
      if (t === 'select') return { label: 'Lựa chọn', color: 'amber', icon: 'mdi-format-list-bulleted' }
      if (t === 'signature') return { label: 'Ký số', color: 'orange', icon: 'mdi-signature-freehand' }
      return { label: 'Chữ', color: 'grey', icon: 'mdi-format-text' }
    },
    submitCreateInstance: async function () {
      if (!this.createForm.instanceName || !this.definitionId) return
      var $this = this
      var fieldValues = (this.createDynamicFields || []).map(function (f) {
        return {
          FieldName: f.FieldName,
          FieldLabel: f.FieldLabel || '',
          Value: String($this.createForm.fieldValues[f.FieldName] || '')
        }
      })
      var firstStep = this.createFirstStep
      var templateId = firstStep ? (firstStep.TemplateID || null) : null
      var fileMethod = templateId ? 'TEMPLATE' : 'NONE'
      var startStepDefID = firstStep ? (firstStep.StepDefID || null) : null

      this.isCreating = true
      try {
        var createResult = await apiCallAsync('WF_Request_Create', {
          CreateMode: 'TEMPLATE_FLOW',
          DefinitionID: this.definitionId,
          InstanceName: this.createForm.instanceName,
          AssigneeCode: this.createForm.assigneeCode || '',
          FileMethod: fileMethod,
          TemplateID: templateId,
          StartStepDefID: startStepDefID,
          FieldValues: fieldValues,
          Signers: []
        })
        if (typeof showToast !== 'undefined' && showToast.success) showToast.success('Tạo nhiệm vụ thành công!')
        this.$emit('update:modelValue', false)
        this.$emit('success')
      } catch (err) {
        var msg = err && err.responseJSON ? err.responseJSON.Message : (err && err.responseText ? err.responseText : 'Không thể tạo hồ sơ.')
        if (typeof showToast !== 'undefined' && showToast.error) showToast.error(msg)
      } finally {
        this.isCreating = false
      }
    }
  }
	}
</script>