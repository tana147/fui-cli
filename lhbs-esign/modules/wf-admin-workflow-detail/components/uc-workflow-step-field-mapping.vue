<template>
	<div>
    <!-- MAIN CONFIGURATION DIALOG (MODAL VIEW) -->
    <v-dialog v-model="showConfigDialog" :max-width="showAddField ? 1200 : 860" persistent
      transition="dialog-bottom-transition">
      <v-card class="wf-cfd-card rounded-lg overflow-hidden">
        <!-- Header -->
        <div class="wf-cfd-header border-b d-flex align-center justify-space-between">
          <div class="wf-cfd-header-cat">
            <div class="wf-cfd-header-icon"
              style="background-color: rgba(33, 125, 70, 0.1); color: var(--wf-primary) !important;">
              <v-icon size="20">mdi-form-select</v-icon>
            </div>
            <div>
              <div class="wf-cfd-header-name">
                Cấu hình trường tùy chỉnh động</div>
              <div class="wf-cfd-header-sub">Gán các trường thông tin cần nhập cho bước: <span
                  class="font-weight-bold text-primary">{{ activeStep.StepName }}</span></div>
            </div>
          </div>
          <div class="d-flex align-center" style="gap: 8px;">
            <v-chip size="small" color="primary" variant="flat" class="font-weight-bold px-2"
              style="height: 20px; font-size: 10px;">
              {{ selectedFieldsCount }} đã chọn
            </v-chip>
            <v-btn icon size="small" variant="text" @click="showConfigDialog = false; showAddField = false;">
              <v-icon size="18">mdi-close</v-icon>
            </v-btn>
          </div>
        </div>

        <div class="wf-cfd-body">
          <!-- LEFT: Danh sách trường -->
          <div class="wf-cfd-left" :class="{ 'wf-cfd-left--no-border': !showAddField }">
            <!-- Toolbar / Search and Actions Row -->
            <div class="wf-cfd-left-toolbar d-flex align-center" style="gap: 8px;">
              <v-text-field v-model="searchText" placeholder="Tìm tên, label..." variant="outlined" density="compact"
                hide-details prepend-inner-icon="mdi-magnify" class="bg-white flex-grow-1 wf-compact-input"
                style="max-width: 140px; font-size: 13px;" clearable color="primary" />
              <v-spacer />
              <div class="d-flex align-center" style="gap: 6px;">
                <!-- Load template button -->
                <v-btn variant="outlined" color="primary" size="small" class="font-weight-bold text-none px-2"
                  style="height: 32px; font-size: 12px;" @click="loadFromTemplate()">
                  <v-icon start size="14">mdi-download-outline</v-icon> Mẫu văn bản
                </v-btn>
                <!-- Load from category button -->
                <v-btn variant="outlined" color="primary" size="small" class="font-weight-bold text-none px-2"
                  style="height: 32px; font-size: 12px;" @click="loadFromCategory()" :loading="isLoadingTemplate">
                  <v-icon start size="14">mdi-file-tree</v-icon> Import từ danh mục
                </v-btn>
                <!-- Add field button -->
                <v-btn variant="flat" color="primary" size="small" class="font-weight-bold text-none px-2"
                  style="height: 32px; font-size: 12px;" @click="toggleAddFieldForm">
                  <v-icon start size="14">{{ showAddField ? 'mdi-chevron-double-right' : 'mdi-plus' }}
                  </v-icon> {{
                  showAddField ? 'Đóng' : 'Thêm trường' }}
                </v-btn>
              </div>
            </div>

            <!-- Template Loader Panel -->
            <v-expand-transition>
              <div v-if="showTemplatePanel" class="bg-primary-lighten-5 px-3 py-3 border-b"
                style="background-color: rgba(33, 125, 70, 0.02);">
                <div class="d-flex align-center justify-space-between mb-2">
                  <span class="text-caption font-weight-bold text-grey-darken-3" style="font-size: 10px !important;">{{
                    templatePanelTitle }}</span>
                  <v-btn icon size="x-small" variant="text" @click="showTemplatePanel = false">
                    <v-icon size="14">mdi-close</v-icon>
                  </v-btn>
                </div>

                <div v-if="templateFields.length" style="max-height: 140px; overflow-y: auto;"
                  class="border rounded bg-white">
                  <div v-for="tField in templateFields" :key="tField.FieldName"
                    class="d-flex align-center justify-space-between border-b px-2 py-1">
                    <div class="d-flex align-center" style="gap: 6px;">
                      <v-checkbox :model-value="isTemplateFieldSelected(tField.FieldName)"
                        @update:model-value="toggleTemplateField(tField)" color="primary" density="compact"
                        hide-details />
                      <div>
                        <span class="text-caption font-weight-bold text-grey-darken-4" style="font-size: 11px;">{{
                          tField.FieldLabel }}</span>
                        <span class="text-caption text-grey ml-1" style="font-size: 9px;">({{
                          tField.FieldName }})</span>
                      </div>
                    </div>
                    <div class="d-flex align-center" style="gap: 4px;">
                      <v-chip size="x-small" color="primary" variant="tonal" class="px-1"
                        style="height: 16px; font-size: 9px;">{{ getFieldTypeLabel(tField.FieldType) }}</v-chip>
                      <v-chip size="x-small" :color="tField.IsRequired ? 'error' : 'grey'" variant="tonal" class="px-1"
                        style="height: 16px; font-size: 9px;">
                        {{ tField.IsRequired ? 'Bắt buộc' : 'Tùy chọn' }}
                      </v-chip>
                    </div>
                  </div>
                </div>

                <div v-else class="text-center py-2 text-grey text-caption" style="font-size: 10px;">
                  Không tìm thấy trường mẫu nào phù hợp hoặc đã import hết.
                </div>

                <div v-if="templateFields.length" class="d-flex justify-end mt-2" style="gap: 6px;">
                  <v-btn size="x-small" variant="flat" color="primary" class="text-none"
                    :disabled="selectedTemplatesCount === 0" @click="importSelectedTemplates">Import
                    {{
                    selectedTemplatesCount }} trường</v-btn>
                </div>
              </div>
            </v-expand-transition>

            <!-- Body / Fields List -->
            <div class="wf-cfd-list" ref="sortableList" style="flex: 1; overflow-y: auto;">
              <div v-if="filteredFields.length" class="py-1">
                <div ref="sortableContainer">
                  <div v-for="(field, index) in filteredFields" :key="field.FieldName"
                    :id="'cfd-field-' + field.FieldName" :data-field-name="field.FieldName"
                    class="d-flex align-center border-b px-4 py-2 cursor-pointer wf-cfd-list-row" :class="{
											'wf-cfd-list-row--active': isEditing && newField.FieldName === field.FieldName,
											'wf-cfd-list-row--dup': duplicatePlaceholders.indexOf(field.FieldName) !== -1
										}" @click="toggleField(field.FieldName)">
                    <!-- Drag Handle -->
                    <v-icon size="16" color="grey-lighten-1" class="mr-1 wf-drag-handle" style="cursor: grab;"
                      @mousedown.stop>
                      mdi-drag-vertical</v-icon>

                    <!-- Index / Selection Indicator -->
                    <div class="mr-3 d-flex align-center justify-center rounded-circle border"
                      style="width: 22px; height: 22px; min-width: 22px; font-size: 10px; font-weight: 700; transition: all 0.2s;"
                      :style="isFieldSelected(field.FieldName) ? 'background-color: #217d46; border-color: #217d46; color: white;' : 'background-color: #f1f5f9; border-color: #cbd5e1; color: #475569;'">
                      <v-icon v-if="isFieldSelected(field.FieldName)" size="12" color="white">
                        mdi-check
                      </v-icon>
                      <span v-else>{{ field.SortOrder || (index + 1) }}</span>
                    </div>

                    <!-- Field Info -->
                    <div class="flex-grow-1 min-width-0 pr-2">
                      <div class="font-weight-medium text-grey-darken-4 text-truncate"
                        :title="field.FieldLabel || field.FieldName"
                        style="font-size: 12px !important; line-height: 1.3;">{{ field.FieldLabel ||
                        field.FieldName }}
                      </div>
                      <div class="text-caption text-grey text-truncate"
                        style="font-size: 9px !important; margin-top: 1px;" :title="field.FieldName">
                        {{ field.FieldName }} <span class="text-grey-lighten-1 font-weight-medium">|
                          Thứ tự:
                          {{
                          field.SortOrder || 0 }}</span></div>
                    </div>

                    <!-- Badges -->
                    <div class="d-flex align-center" style="gap: 6px;">
                      <v-tooltip v-if="duplicatePlaceholders.indexOf(field.FieldName) !== -1" location="top"
                        text="Trùng tên với template khác trong bước này. Nên đổi tên placeholder trong file .docx để phân biệt.">
                        <template #activator="{ props }">
                          <v-chip v-bind="props" size="x-small" color="warning" variant="tonal"
                            class="font-weight-bold px-2" style="height: 22px; font-size: 10px; cursor: help;">
                            <v-icon start size="10">mdi-alert-outline</v-icon>Trùng
                          </v-chip>
                        </template>
                      </v-tooltip>
                      <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-medium px-2"
                        style="height: 22px; font-size: 10px;">
                        <v-icon start size="11" class="mr-1">{{ getTypeIcon(field.FieldType) }}
                        </v-icon>
                        {{ getFieldTypeLabel(field.FieldType) }}
                      </v-chip>
                      <v-chip size="x-small" :color="field.IsRequired ? 'error' : 'grey-lighten-1'" variant="tonal"
                        class="font-weight-medium px-2" style="height: 22px; font-size: 10px;">
                        {{ field.IsRequired ? 'Bắt buộc' : 'Tùy chọn' }}
                      </v-chip>
                      <!-- Move field up/down buttons -->
                      <v-btn v-if="isFieldSelected(field.FieldName)" icon size="x-small" variant="text" color="primary"
                        :disabled="getFieldStepIndex(field.FieldName) === 0" @click.stop="moveFieldOrder(field, -1)"
                        title="Di chuyển lên">
                        <v-icon size="16">mdi-chevron-up</v-icon>
                      </v-btn>
                      <v-btn v-if="isFieldSelected(field.FieldName)" icon size="x-small" variant="text" color="primary"
                        :disabled="getFieldStepIndex(field.FieldName) === (activeStep.StepFields || []).length - 1"
                        @click.stop="moveFieldOrder(field, 1)" title="Di chuyển xuống">
                        <v-icon size="16">mdi-chevron-down</v-icon>
                      </v-btn>
                      <!-- Edit field button -->
                      <v-btn icon size="x-small" variant="text" color="primary" @click.stop="openEditFieldForm(field)">
                        <v-icon size="16">mdi-pencil-outline</v-icon>
                      </v-btn>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Empty State (Modal View) -->
              <div v-else class="pa-8 text-center text-grey text-caption" style="font-size: 11px;">
                <v-icon size="28" class="mb-1 opacity-50" color="grey">mdi-database-search-outline
                </v-icon>
                <div>Không tìm thấy trường dữ liệu nào.</div>
              </div>
            </div>
          </div>

          <!-- RIGHT: Form chỉnh sửa -->
          <div v-if="showAddField" class="wf-cfd-right border-l">
            <!-- MODE BANNER -->
            <div v-if="!isEditing" class="wf-cfd-mode-banner wf-cfd-mode-banner--new">
              <div class="wf-cfd-mode-banner__icon">
                <v-icon size="20" color="white">mdi-plus</v-icon>
              </div>
              <div class="wf-cfd-mode-banner__text">
                <div class="wf-cfd-mode-banner__title">Thêm trường mới</div>
                <div class="wf-cfd-mode-banner__sub">Điền thông tin bên dưới rồi bấm Lưu</div>
              </div>
              <v-btn icon size="small" variant="text" color="white" class="ml-auto" title="Đóng"
                @click="showAddField = false">
                <v-icon size="16">mdi-close</v-icon>
              </v-btn>
            </div>
            <div v-else class="wf-cfd-mode-banner wf-cfd-mode-banner--edit">
              <div class="wf-cfd-mode-banner__icon">
                <v-icon size="20" color="white">mdi-pencil</v-icon>
              </div>
              <div class="wf-cfd-mode-banner__text">
                <div class="wf-cfd-mode-banner__title">Đang chỉnh sửa</div>
                <div class="wf-cfd-mode-banner__sub">{{ newField.FieldLabel || newField.FieldName ||
                  'Trường #' +
                  newField.SortOrder }}</div>
              </div>
              <v-btn icon size="small" variant="text" color="white" class="ml-auto" title="Đóng"
                @click="showAddField = false">
                <v-icon size="16">mdi-close</v-icon>
              </v-btn>
            </div>

            <div class="wf-cfd-form-body">
              <v-row dense>
                <v-col cols="12">
                  <v-text-field v-model="newField.FieldLabel" label="Tên hiển thị *" placeholder="Ví dụ: Họ và tên"
                    variant="outlined" density="compact" hide-details class="mb-2 bg-white" style="font-size: 12px;"
                    color="primary" @input="autoGenerateFieldName" />
                </v-col>
                <v-col cols="12">
                  <v-text-field v-model="newField.FieldName" label="Mã trường *" placeholder="Ví dụ: HoVaTen"
                    variant="outlined" density="compact" hide-details class="mb-2 bg-white" style="font-size: 12px;"
                    color="primary" />
                </v-col>
                <v-col cols="7">
                  <v-select v-model="newField.FieldType" :items="fieldTypeOptions" label="Kiểu dữ liệu *"
                    item-title="title" item-value="value" variant="outlined" density="compact" hide-details
                    class="mb-2 bg-white" style="font-size: 12px;" color="primary" />
                </v-col>
                <v-col cols="5">
                  <v-text-field v-model.number="newField.SortOrder" type="number" label="Thứ tự *"
                    placeholder="Ví dụ: 1" variant="outlined" density="compact" hide-details class="mb-2 bg-white"
                    style="font-size: 12px;" color="primary" />
                </v-col>

                <!-- Conditional Layout for select options vs default value -->
                <template v-if="newField.FieldType === 'select'">
                  <v-col cols="12">
                    <v-text-field v-model="newField.FieldOptions" label="Options (JSON/text) *"
                      placeholder="val1,val2,val3,..." variant="outlined" density="compact" hide-details
                      class="mb-2 bg-white" style="font-size: 12px;" color="primary" />
                  </v-col>
                  <v-col cols="12">
                    <v-text-field v-model="newField.DefaultValue" label="Giá trị mặc định" placeholder="—"
                      variant="outlined" density="compact" hide-details class="mb-2 bg-white" style="font-size: 12px;"
                      color="primary" />
                  </v-col>
                </template>
                <template v-else-if="newField.FieldType === 'computed'">
                  <v-col cols="12">
                    <v-select :items="formulaPresets" item-title="title" item-value="value" label="Mẫu công thức"
                      placeholder="Chọn mẫu có sẵn..." variant="outlined" density="compact" hide-details
                      class="mb-2 bg-white" style="font-size: 12px;" color="primary"
                      @update:model-value="(v) => { if (v) newField.FieldOptions = v }" />
                  </v-col>
                  <v-col cols="12">
                    <v-text-field v-model="newField.FieldOptions" label="Công thức tính *"
                      placeholder="VD: [SoHocSinhDuKienKhoi1] + [SoHocSinhDuKienKhoi2]" variant="outlined"
                      density="compact" hide-details class="mb-2 bg-white" style="font-size: 12px;" color="primary"
                      prepend-inner-icon="mdi-calculator-variant" />
                  </v-col>
                  <v-col cols="12">
                    <v-text-field v-model="newField.DefaultValue" label="Giá trị mặc định" placeholder="—"
                      variant="outlined" density="compact" hide-details class="mb-2 bg-white" style="font-size: 12px;"
                      color="primary" />
                  </v-col>
                </template>
                <template v-else>
                  <v-col cols="12">
                    <v-text-field v-model="newField.DefaultValue" label="Giá trị mặc định" placeholder="—"
                      variant="outlined" density="compact" hide-details class="mb-2 bg-white" style="font-size: 12px;"
                      color="primary" />
                  </v-col>
                </template>
                <v-col cols="12">
                  <v-switch v-model="newField.IsRequired" label="Bắt buộc điền" color="primary" density="compact"
                    hide-details />
                </v-col>
              </v-row>
            </div>

            <div class="wf-cfd-form-footer">
              <v-spacer />
              <v-btn class="wf-btn ml-auto" :variant="isEditing ? 'flat' : 'outlined'"
                :color="isEditing ? 'warning' : 'primary'" :loading="isSavingField"
                @click="isEditing ? saveEditField() : saveNewField()">
                <v-icon start size="14">{{ isEditing ? 'mdi-content-save-edit-outline' :
                  'mdi-plus-circle-outline' }}</v-icon>
                {{ isEditing ? 'Cập nhật' : 'Thêm trường' }}
              </v-btn>
            </div>
          </div>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
	export default {
		props: {
		activeStep: { type: Object, required: true },
		fields: { type: Array, required: true },
		categoryId: { type: [Number, String], required: false },
		templates: { type: Array, required: false, default: function () { return [] } },
		fieldTypeOptions: { type: Array, required: true },
		getTypeIcon: { type: Function, required: true }
	},
	data: function () {
		return {
			searchText: "",
			showConfigDialog: false,
			showAddField: false,
			showTemplatePanel: false,
			isLoadingTemplate: false,
			isEditing: false,
			editingFieldOriginalName: "",
			sortableInstance: null,
			newField: {
				FieldName: "",
				FieldLabel: "",
				FieldType: "text",
				FieldOptions: "",
				DefaultValue: "",
				IsRequired: false,
				SortOrder: 0
			},
			templateFields: [],
			selectedTemplates: [],
			isSavingField: false,
		}
	},
	computed: {
		formulaPresets: function () {
			return (typeof window !== 'undefined' && window.WF_FORMULA && window.WF_FORMULA.presets) || []
		},
		selectedFieldsList: function () {
			if (!this.activeStep || !this.fields) return []
			var selectedNames = this.activeStep.SelectedFieldNames || []

			var fieldsMap = {}
			this.fields.forEach(function (f) {
				fieldsMap[f.FieldName] = f
			})

			var placeholders = []
			if (this.activeStep.TemplateID && this.templates) {
				var tempId = this.activeStep.TemplateID
				var template = this.templates.find(function (t) { return Number(t.TemplateID) === Number(tempId) })
				if (template && template.Placeholders) {
					placeholders = template.Placeholders
				}
			}

			var sortedList = []
			// 1. Add mapped fields that are placeholders, in template order
			placeholders.forEach(function (ph) {
				if (selectedNames.indexOf(ph) !== -1 && fieldsMap[ph]) {
					sortedList.push(fieldsMap[ph])
				}
			})

			// 2. Add other mapped fields not in placeholders
			selectedNames.forEach(function (name) {
				if (placeholders.indexOf(name) === -1 && fieldsMap[name]) {
					sortedList.push(fieldsMap[name])
				}
			})

			return sortedList
		},
		selectedFieldsCount: function () {
			if (!this.activeStep) return 0;
			return (this.activeStep.SelectedFieldNames || []).length
		},
		templateCount: function () {
			var slots = this.activeStep && this.activeStep.templates
			if (!slots || !slots.length) return 0
			return slots.filter(function (s) { return s.TemplateID }).length
		},
		orphanFields: function () {
			var allPlaceholders = {}
			var self = this
			var slots = (this.activeStep && this.activeStep.templates) || []
			slots.forEach(function (slot) {
				var tpl = (self.templates || []).find(function (t) { return Number(t.TemplateID) === Number(slot.TemplateID) })
				if (tpl && tpl.Placeholders) {
					tpl.Placeholders.forEach(function (ph) { allPlaceholders[ph] = true })
				}
			})
			if (this.activeStep && this.activeStep.TemplateID && (!this.activeStep.templates || this.activeStep.templates.length === 0)) {
				var singleTpl = (this.templates || []).find(function (t) { return Number(t.TemplateID) === Number(self.activeStep.TemplateID) })
				if (singleTpl && singleTpl.Placeholders) {
					singleTpl.Placeholders.forEach(function (ph) { allPlaceholders[ph] = true })
				}
			}
			return this.fields.filter(function (f) { return !allPlaceholders[f.FieldName] })
		},
		orphanSelectedCount: function () {
			var self = this
			return this.orphanFields.filter(function (f) { return self.isFieldSelected(f.FieldName) }).length
		},
		selectedTemplatesCount: function () {
			return this.selectedTemplates.length
		},
		duplicatePlaceholders: function () {
			var templates = this.activeStep && this.activeStep.templates
			if (!templates || !templates.length) return []
			var phCount = {}
			var self = this
			templates.forEach(function (slot) {
				var tpl = (self.templates || []).find(function (t) { return Number(t.TemplateID) === Number(slot.TemplateID) })
				if (!tpl || !tpl.Placeholders) return
				var uniquePhs = {}
				tpl.Placeholders.forEach(function (ph) { uniquePhs[ph] = true })
				Object.keys(uniquePhs).forEach(function (ph) { phCount[ph] = (phCount[ph] || 0) + 1 })
			})
			return Object.keys(phCount).filter(function (ph) { return phCount[ph] > 1 })
		},
		filteredFields: function () {
			if (!this.activeStep || !this.fields) return []
			var search = (this.searchText || "").toLowerCase().trim()
			var dups = this.duplicatePlaceholders
			var dupSet = {}
			dups.forEach(function (ph) { dupSet[ph] = true })
			var list = this.fields.filter(function (field) {
				var name = (field.FieldName || "").toLowerCase()
				var label = (field.FieldLabel || "").toLowerCase()
				if (search && name.indexOf(search) === -1 && label.indexOf(search) === -1) return false
				return true
			})
			return list.sort(function (a, b) {
				var ad = dupSet[a.FieldName] ? 0 : 1
				var bd = dupSet[b.FieldName] ? 0 : 1
				if (ad !== bd) return ad - bd
				return Number(a.SortOrder || 0) - Number(b.SortOrder || 0)
			})
		}
	},
	methods: {
		clone: function (value) {
			return JSON.parse(JSON.stringify(value || null))
		},
		openConfigModal: function () {
			this.searchText = ""
			this.showConfigDialog = true
		},
		toggleAddFieldForm: function () {
			this.showAddField = !this.showAddField
			this.isEditing = false
			this.editingFieldOriginalName = ""
			if (this.showAddField) {
				this.newField = {
					FieldName: "",
					FieldLabel: "",
					FieldType: "text",
					FieldOptions: "",
					DefaultValue: "",
					IsRequired: false,
					SortOrder: this.fields.length + 1
				}
			}
		},
		openEditFieldForm: function (field) {
			this.isEditing = true
			this.editingFieldOriginalName = field.FieldName
			this.newField = {
				FieldName: field.FieldName,
				FieldLabel: field.FieldLabel || "",
				FieldType: field.FieldType || "text",
				FieldOptions: field.FieldOptions || "",
				DefaultValue: field.DefaultValue || "",
				IsRequired: !!field.IsRequired,
				SortOrder: Number(field.SortOrder || 0)
			}
			this.showTemplatePanel = false
			this.showAddField = true

			var fieldName = field.FieldName
			this.$nextTick(function () {
				setTimeout(function () {
					var el = document.getElementById('cfd-field-' + fieldName)
					if (el) {
						el.scrollIntoView({ behavior: 'smooth', block: 'center' })
					}
				}, 250)
			})
		},
		cancelFieldForm: function () {
			this.showAddField = false
			this.isEditing = false
			this.editingFieldOriginalName = ""
		},
		autoGenerateFieldName: function () {
			if (this.isEditing) return;
			var label = this.newField.FieldLabel || ""
			var slug = label.trim()

			var from = "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ"
			var to = "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD"
			for (var i = 0; i < from.length; i++) {
				slug = slug.replace(new RegExp(from.charAt(i), "g"), to.charAt(i))
			}

			slug = slug.replace(/[^a-zA-Z0-9\s]/g, "")

			var words = slug.split(/\s+/).filter(Boolean)
			var fieldName = words.map(function (w) {
				if (w.length === 0) return ""
				return w.charAt(0).toUpperCase() + w.substring(1).toLowerCase()
			}).join("")

			this.newField.FieldName = fieldName
		},
		isFieldSelected: function (name) {
			if (!this.activeStep) return false;
			return (this.activeStep.SelectedFieldNames || []).indexOf(name) !== -1
		},
		toggleField: function (name) {
			if (!this.activeStep) return;
			if (!this.activeStep.SelectedFieldNames) this.activeStep.SelectedFieldNames = []
			if (!this.activeStep.StepFields) this.activeStep.StepFields = []

			var idx = this.activeStep.SelectedFieldNames.indexOf(name)
			if (idx === -1) {
				this.activeStep.SelectedFieldNames.push(name)
				var dbField = this.fields.find(function(f) { return f.FieldName === name; })
				this.activeStep.StepFields.push({
					FieldName: name,
					SortOrder: this.activeStep.StepFields.length + 1,
					IsRequired: dbField ? !!dbField.IsRequired : false
				})
			} else {
				this.activeStep.SelectedFieldNames.splice(idx, 1)
				var sfIdx = this.activeStep.StepFields.findIndex(function(f) { return f.FieldName === name; })
				if (sfIdx !== -1) {
					this.activeStep.StepFields.splice(sfIdx, 1)
					this.activeStep.StepFields.forEach(function (f, i) { f.SortOrder = i + 1; })
				}
			}
		},
		toggleFieldChip: function (name) {
			this.toggleField(name)
		},
		saveNewField: async function () {
			if (!this.newField.FieldLabel || !this.newField.FieldName) {
				if (showToast && showToast.error) showToast.error("Vui lòng điền đầy đủ Nhãn và Field Name.")
				return
			}

			var $this = this
			var nameExists = this.fields.some(function (f) {
				return f.FieldName.toLowerCase() === $this.newField.FieldName.toLowerCase()
			})

			if (nameExists) {
				if (showToast && showToast.error) showToast.error("Field Name này đã tồn tại trong workflow.")
				return
			}

			var catId = Number(this.categoryId || 0)
			if (!catId) {
				if (showToast && showToast.error) showToast.error("Luồng chưa được cấu hình Nhóm luồng công việc — không thể lưu trường.")
				return
			}

			var fieldToPush = {
				MappingID: 0,
				FieldName: this.newField.FieldName,
				FieldLabel: this.newField.FieldLabel,
				FieldType: this.newField.FieldType,
				FieldOptions: this.newField.FieldOptions || "",
				DefaultValue: this.newField.DefaultValue,
				IsRequired: this.newField.IsRequired ? true : false,
				SortOrder: Number(this.newField.SortOrder || this.fields.length + 1),
				Enable: true
			}

			this.fields.push(fieldToPush)
			if (this.activeStep) {
				if (!this.activeStep.SelectedFieldNames) this.activeStep.SelectedFieldNames = []
				this.activeStep.SelectedFieldNames.push(fieldToPush.FieldName)
			}
			this.showAddField = false
			this.isSavingField = true

			try {
				var res = await apiCallAsync("WF_CustomFieldMapping_Insert", {
					CategoryID: catId,
					FieldName: fieldToPush.FieldName,
					FieldLabel: fieldToPush.FieldLabel,
					FieldType: fieldToPush.FieldType,
					FieldOptions: fieldToPush.FieldOptions,
					IsRequired: fieldToPush.IsRequired ? 1 : 0,
					DefaultValue: fieldToPush.DefaultValue,
					SortOrder: fieldToPush.SortOrder,
					Enable: 1
				})
				var returned = res && res[0]
				if (returned && returned.MappingID) {
					fieldToPush.MappingID = Number(returned.MappingID)
				}
				this.$emit('field-saved')
			} catch (err) {
				var rollbackIdx = this.fields.indexOf(fieldToPush)
				if (rollbackIdx !== -1) this.fields.splice(rollbackIdx, 1)
				if (this.activeStep && this.activeStep.SelectedFieldNames) {
					var rollbackSelIdx = this.activeStep.SelectedFieldNames.indexOf(fieldToPush.FieldName)
					if (rollbackSelIdx !== -1) this.activeStep.SelectedFieldNames.splice(rollbackSelIdx, 1)
				}
				if (showToast && showToast.error) showToast.error("Lỗi khi lưu trường: " + (err.responseJSON ? err.responseJSON.Message : ""))
			} finally {
				this.isSavingField = false
			}
		},
		saveEditField: async function () {
			if (!this.newField.FieldLabel || !this.newField.FieldName) {
				if (showToast && showToast.error) showToast.error("Vui lòng điền đầy đủ Nhãn và Field Name.")
				return
			}

			var $this = this
			var nameExists = this.fields.some(function (f) {
				return f.FieldName.toLowerCase() === $this.newField.FieldName.toLowerCase() &&
					f.FieldName.toLowerCase() !== $this.editingFieldOriginalName.toLowerCase()
			})

			if (nameExists) {
				if (showToast && showToast.error) showToast.error("Field Name này đã tồn tại trong workflow.")
				return
			}

			var fieldIndex = this.fields.findIndex(function (f) {
				return f.FieldName.toLowerCase() === $this.editingFieldOriginalName.toLowerCase()
			})

			if (fieldIndex === -1) return

			var targetField = this.fields[fieldIndex]
			var originalSnapshot = {
				FieldLabel: targetField.FieldLabel,
				FieldName: targetField.FieldName,
				FieldType: targetField.FieldType,
				FieldOptions: targetField.FieldOptions,
				DefaultValue: targetField.DefaultValue,
				IsRequired: targetField.IsRequired,
				SortOrder: targetField.SortOrder
			}

			targetField.FieldLabel = this.newField.FieldLabel
			targetField.FieldName = this.newField.FieldName
			targetField.FieldType = this.newField.FieldType
			targetField.FieldOptions = this.newField.FieldOptions || ""
			targetField.DefaultValue = this.newField.DefaultValue
			targetField.IsRequired = this.newField.IsRequired ? true : false
			targetField.SortOrder = Number(this.newField.SortOrder || 0)

			if (this.activeStep && this.activeStep.StepFields) {
				var sfIdx = this.activeStep.StepFields.findIndex(function(f) { return f.FieldName === $this.editingFieldOriginalName; });
				if (sfIdx !== -1) {
					var sf = this.activeStep.StepFields[sfIdx];
					sf.FieldName = this.newField.FieldName;
					
					var newSortOrder = Number($this.newField.SortOrder || 0);
					if (newSortOrder > 0 && newSortOrder !== sf.SortOrder) {
						var targetIdx = newSortOrder - 1;
						if (targetIdx >= this.activeStep.StepFields.length) {
							targetIdx = this.activeStep.StepFields.length - 1;
						}
						this.activeStep.StepFields.splice(sfIdx, 1);
						this.activeStep.StepFields.splice(targetIdx, 0, sf);
						
						this.activeStep.StepFields.forEach(function(f, idx) {
							f.SortOrder = idx + 1;
						});
					}
				}
				this.activeStep.SelectedFieldNames = this.activeStep.StepFields.map(function(f) { return f.FieldName; });
			}

			this.showAddField = false
			this.isEditing = false
			this.editingFieldOriginalName = ""

			if (Number(targetField.MappingID || 0) > 0) {
				var catId = Number(this.categoryId || 0)
				this.isSavingField = true
				try {
					await apiCallAsync("WF_CustomFieldMapping_Update", {
						MappingID: Number(targetField.MappingID),
						CategoryID: catId,
						FieldName: targetField.FieldName,
						FieldLabel: targetField.FieldLabel,
						FieldType: targetField.FieldType,
						FieldOptions: targetField.FieldOptions,
						IsRequired: targetField.IsRequired ? 1 : 0,
						DefaultValue: targetField.DefaultValue,
						SortOrder: targetField.SortOrder,
						Enable: 1
					})
					this.$emit('field-saved')
				} catch (err) {
					Object.assign(targetField, originalSnapshot)
					if (showToast && showToast.error) showToast.error("Lỗi khi cập nhật trường: " + (err.responseJSON ? err.responseJSON.Message : ""))
				} finally {
					this.isSavingField = false
				}
			} else {
				if (showToast && showToast.success) showToast.success("Đã cập nhật thông tin trường.")
			}
		},
		initSortable: function () {
			var self = this;
			if (self.sortableInstance) {
				self.sortableInstance.destroy();
				self.sortableInstance = null;
			}
			self.$nextTick(function () {
				var container = self.$refs.sortableContainer;
				if (!container) return;
				self.sortableInstance = Sortable.create(container, {
					handle: '.wf-drag-handle',
					animation: 150,
					ghostClass: 'wf-sortable-ghost',
					chosenClass: 'wf-sortable-chosen',
					dragClass: 'wf-sortable-drag',
					scrollSensitivity: 80,
					scrollSpeed: 15,
					forceFallback: true,
					fallbackClass: 'wf-sortable-fallback',
					fallbackOnBody: true,
					onEnd: function (evt) {
						var oldIndex = evt.oldIndex;
						var newIndex = evt.newIndex;
						if (oldIndex === newIndex) return;

						if (!self.activeStep.StepFields) self.activeStep.StepFields = [];
						var stepFields = self.activeStep.StepFields;

						// Get the field name from the DOM element
						var movedEl = evt.item;
						var movedFieldName = movedEl.getAttribute('data-field-name');
						if (!movedFieldName) return;

						var fromIdx = stepFields.findIndex(function (f) { return f.FieldName === movedFieldName; });
						if (fromIdx === -1) return;

						var draggedItem = stepFields[fromIdx];
						stepFields.splice(fromIdx, 1);

						// Calculate new position
						var toIdx = newIndex;
						if (toIdx > stepFields.length) toIdx = stepFields.length;
						stepFields.splice(toIdx, 0, draggedItem);

						// Update SortOrder
						stepFields.forEach(function (f, idx) {
							f.SortOrder = idx + 1;
						});

						self.activeStep.SelectedFieldNames = stepFields.map(function (sf) { return sf.FieldName; });

						if (showToast && showToast.success) {
							showToast.success("Đã thay đổi thứ tự trường dữ liệu trong bước.");
						}
					}
				});
			});
		},
		destroySortable: function () {
			if (this.sortableInstance) {
				this.sortableInstance.destroy();
				this.sortableInstance = null;
			}
		},
		loadFromTemplate: function () {
			if (!this.activeStep) return;
			var templateIds = [];
			if (this.activeStep.templates && this.activeStep.templates.length) {
				this.activeStep.templates.forEach(function (slot) {
					if (slot.TemplateID) {
						templateIds.push(slot.TemplateID);
					}
				});
			} else if (this.activeStep.TemplateID) {
				templateIds.push(this.activeStep.TemplateID);
			}

			if (!templateIds.length) {
				if (showToast && showToast.error) {
					showToast.error("Bước này chưa chọn Template mẫu văn bản nào.");
				}
				return;
			}

			var $this = this;
			var templatesList = this.templates || [];
			var placeholders = [];
			var activeTemplateNames = [];

			templateIds.forEach(function (id) {
				var tpl = templatesList.find(function (t) { return Number(t.TemplateID) === Number(id); });
				if (tpl) {
					activeTemplateNames.push(tpl.TemplateName);
					if (tpl.Placeholders) {
						tpl.Placeholders.forEach(function (ph) {
							if (ph && placeholders.indexOf(ph) === -1) {
								placeholders.push(ph);
							}
						});
					}
				}
			});

			if (!placeholders.length) {
				if (showToast && showToast.info) {
					showToast.info("Các template mẫu văn bản này không chứa placeholder nào.");
				}
				this.templateFields = [];
				this.showTemplatePanel = true;
				return;
			}

			var existingNames = this.fields.map(function (f) { return f.FieldName.toLowerCase(); });
			var filteredPlaceholders = placeholders.filter(function (ph) {
				return existingNames.indexOf(ph.toLowerCase()) === -1;
			});

			this.templateFields = filteredPlaceholders.map(function (ph) {
				return {
					FieldName: ph,
					FieldLabel: ph,
					FieldType: "text",
					IsRequired: false
				};
			});

			this.templatePanelTitle = "DANH SÁCH PLACEHOLDER TỪ CÁC TEMPLATE: " + activeTemplateNames.join(", ").toUpperCase();
			this.selectedTemplates = [];
			this.showTemplatePanel = true;
		},
		loadFromCategory: async function () {
			var catId = Number(this.categoryId || 0)
			if (!catId) {
				if (showToast && showToast.error) {
					showToast.error("Luồng chưa được cấu hình Nhóm luồng công việc.")
				}
				return
			}

			this.isLoadingTemplate = true
			this.templatePanelTitle = "DANH SÁCH TRƯỜNG DỮ LIỆU TỪ DANH MỤC NHÓM LUỒNG"
			try {
				var rows = await apiCallAsync("WF_CustomFieldMapping_GetList", { CategoryID: catId })
				if (!rows || !rows.length) {
					if (showToast && showToast.info) {
						showToast.info("Không tìm thấy trường dữ liệu nào trong danh mục nhóm luồng này.")
					}
					this.templateFields = []
					this.showTemplatePanel = true
					return
				}

				var existingNames = this.fields.map(function (f) { return f.FieldName.toLowerCase() })
				this.templateFields = rows.filter(function (row) {
					return existingNames.indexOf(row.FieldName.toLowerCase()) === -1
				})

				this.selectedTemplates = []
				this.showTemplatePanel = true
			} catch (err) {
				if (showToast && showToast.error) {
					showToast.error("Lỗi khi tải trường từ danh mục: " + (err.responseJSON ? err.responseJSON.Message : ""))
				}
			} finally {
				this.isLoadingTemplate = false
			}
		},
		isTemplateFieldSelected: function (name) {
			return this.selectedTemplates.indexOf(name) !== -1
		},
		toggleTemplateField: function (tField) {
			var idx = this.selectedTemplates.indexOf(tField.FieldName)
			if (idx === -1) {
				this.selectedTemplates.push(tField.FieldName)
			} else {
				this.selectedTemplates.splice(idx, 1)
			}
		},
		importSelectedTemplates: function () {
			if (!this.selectedTemplates.length) return

			var $this = this
			var importCount = 0

			this.selectedTemplates.forEach(function (name) {
				var tField = $this.templateFields.find(function (tf) { return tf.FieldName === name })
				if (tField) {
					var fieldToPush = {
						MappingID: 0,
						FieldName: tField.FieldName,
						FieldLabel: tField.FieldLabel,
						FieldType: tField.FieldType || "text",
						DefaultValue: tField.DefaultValue || "",
						IsRequired: tField.IsRequired ? true : false,
						SortOrder: $this.fields.length + 1,
						Enable: true
					}
					$this.fields.push(fieldToPush)
					if ($this.activeStep) {
						if (!$this.activeStep.StepFields) $this.activeStep.StepFields = []
						var sfExists = $this.activeStep.StepFields.some(function(sf) { return sf.FieldName === tField.FieldName })
						if (!sfExists) {
							$this.activeStep.StepFields.push({
								FieldName: tField.FieldName,
								SortOrder: $this.activeStep.StepFields.length + 1,
								IsRequired: tField.IsRequired ? true : false
							})
						}
						
						if (!$this.activeStep.SelectedFieldNames) $this.activeStep.SelectedFieldNames = []
						if ($this.activeStep.SelectedFieldNames.indexOf(tField.FieldName) === -1) {
							$this.activeStep.SelectedFieldNames.push(tField.FieldName)
						}
					}
					importCount++
				}
			})

			this.showTemplatePanel = false
			if (showToast && showToast.success) {
				showToast.success("Đã import thành công " + importCount + " trường từ template và gán vào bước.")
			}
		},
		toggleStepRequired: function (fieldName) {
			if (!this.activeStep || !this.activeStep.StepFields) return
			var sf = this.activeStep.StepFields.find(function(f) { return f.FieldName === fieldName; })
			if (sf) {
				sf.IsRequired = !sf.IsRequired
				if (showToast && showToast.success) {
					showToast.success("Đã cập nhật thuộc tính bắt buộc của trường.")
				}
			}
		},
		// Check if field is required in current step
		isFieldRequiredInStep: function (fieldName) {
			if (!this.activeStep || !this.activeStep.StepFields) return false
			var sf = this.activeStep.StepFields.find(function(f) { return f.FieldName === fieldName; })
			return sf ? sf.IsRequired === true : false
		},
		// Get template name that contains this field
		getFieldTemplateName: function (fieldName) {
			if (!this.templates || !this.activeStep) return '—'
			var $this = this;
			// Check all templates in step (legacy single template)
			if (this.activeStep.TemplateID) {
				var template = this.templates.find(function(t) {
					return Number(t.TemplateID) === Number($this.activeStep.TemplateID)
				})
				if (template && template.Placeholders && template.Placeholders.indexOf(fieldName) !== -1) {
					return template.TemplateName || 'Template'
				}
			}
			// Check multi-template if exists
			if (this.activeStep.templates) {
				for (var i = 0; i < this.activeStep.templates.length; i++) {
					var slot = this.activeStep.templates[i]
					if (slot.TemplateID) {
						var tpl = this.templates.find(function(t) { return Number(t.TemplateID) === Number(slot.TemplateID) })
						if (tpl && tpl.Placeholders && tpl.Placeholders.indexOf(fieldName) !== -1) {
							var tplName = tpl.TemplateName || 'Template ' + (i + 1)
							return tplName.substring(0, 15)
						}
					}
				}
			}
			return '—'
		},
		// Open edit modal for single field
		openEditFieldModal: function (field) {
			// TODO: Implement single field edit modal
			if (showToast && showToast.info) {
				showToast.info('Sửa trường: ' + field.FieldLabel)
			}
		},
		getFieldTypeLabel: function (type) {
			if (!type) return '—'
			var opt = this.fieldTypeOptions.find(function (o) { return o.value === type })
			return opt ? opt.title : type
		},
		getFieldStepIndex: function (fieldName) {
			if (!this.activeStep || !this.activeStep.StepFields) return -1
			return this.activeStep.StepFields.findIndex(function (f) { return f.FieldName === fieldName })
		},
		moveFieldOrder: function (field, direction) {
			if (!this.activeStep || !this.activeStep.StepFields) return
			var stepFields = this.activeStep.StepFields

			var fromIdx = stepFields.findIndex(function (f) { return f.FieldName === field.FieldName })
			if (fromIdx === -1) return

			var toIdx = fromIdx + direction
			if (toIdx < 0 || toIdx >= stepFields.length) return

			var item = stepFields[fromIdx]
			stepFields.splice(fromIdx, 1)
			stepFields.splice(toIdx, 0, item)

			stepFields.forEach(function (f, idx) {
				f.SortOrder = idx + 1
			})

			this.activeStep.SelectedFieldNames = stepFields.map(function (sf) { return sf.FieldName; })
		},
	},
	watch: {
		showConfigDialog: function (val) {
			if (val) {
				this.initSortable();
			} else {
				this.destroySortable();
			}
		}
	},
	beforeUnmount: function () {
		this.destroySortable();
	}
	}
</script>