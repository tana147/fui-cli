<template>
	<div class="wf-tcard wf-detail-fields-card">
    <div class="wf-fields-header-section">
      <!-- Toolbar Row -->
      <v-row dense align="center" class="mb-2">
        <v-col cols="12" md="3">
          <v-text-field v-model="fieldSearchText" placeholder="Tìm tên hoặc nhãn..." variant="outlined"
            density="compact" hide-details prepend-inner-icon="mdi-magnify" clearable />
        </v-col>

        <v-col cols="12" md="2">
          <v-select v-model="fieldTypeFilter" :items="fieldTypeOptions" label="Kiểu dữ liệu" item-title="title"
            item-value="value" variant="outlined" density="compact" hide-details clearable placeholder="Kiểu dữ liệu" />
        </v-col>

        <v-col cols="12" md="3">
          <v-select v-model="fieldStepFilter" label="Bước" :items="fieldStepFilterOptions" item-title="title"
            item-value="value" variant="outlined" density="compact" hide-details placeholder="Dùng ở bước" clearable />
        </v-col>

        <v-col cols="12" md="4" class="d-flex justify-end align-center" style="gap: 8px;">
          <!-- Load placeholders from multiple templates -->
          <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="openTemplateScanner">
            <v-icon start size="14">mdi-text-box-search-outline</v-icon> Quét từ mẫu văn bản
          </v-btn>

          <!-- Column Visibility -->
          <!-- <v-menu>
						<template #activator="{ props }">
							<v-btn class="wf-btn" size="small" variant="outlined" color="primary" v-bind="props"
								title="Chọn cột hiển thị">
								<v-icon start size="14">mdi-view-column</v-icon> Hiển thị
							</v-btn>
						</template>
						<v-list density="compact" style="max-width: 200px;">
							<v-list-item
								v-for="key in ['FieldName', 'FieldLabel', 'FieldType', 'DefaultValue', 'FieldOptions', 'IsRequired', '_usage']"
								:key="key">
								<template #prepend>
									<v-checkbox v-model="columnVisibility[key]" size="small" color="primary"
										hide-details />
								</template>
								<v-list-item-title style="font-size: 12px;">
									{{ key === 'FieldName' ? 'Mã trường' : key === 'FieldLabel' ? 'Nhãn' : key ===
									'FieldType' ? 'Kiểu dữ liệu'
									: key === 'DefaultValue' ? 'Giá trị' : key === 'FieldOptions' ? 'Tùy chọn' : key ===
									'IsRequired' ?
									'Bắt buộc' : 'Dùng ở bước' }}
								</v-list-item-title>
							</v-list-item>
						</v-list>
					</v-menu> -->

          <!-- Import & Add Buttons -->
          <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="importFromCategory">
            <v-icon start size="14">mdi-download-outline</v-icon> Import từ danh mục
          </v-btn>
          <v-btn class="wf-btn" variant="flat" color="primary" size="small" @click="addField">
            <v-icon start size="14">mdi-plus</v-icon> Thêm
          </v-btn>
        </v-col>
      </v-row>
    </div>
    <div class="border rounded overflow-hidden bg-white mt-2">
      <!-- Header -->
      <div
        class="d-flex align-center bg-grey-lighten-4 border-b px-2 font-weight-bold text-caption text-grey-darken-3 py-2"
        style="position: sticky; top: 0; z-index: 1;">
        <div v-if="columnVisibility.FieldName" style="width: 180px;" class="px-2">Mã trường</div>
        <div v-if="columnVisibility.FieldLabel" style="width: 250px;" class="px-2">Nhãn hiển thị</div>
        <div v-if="columnVisibility.FieldType" style="width: 150px;" class="px-2">Kiểu dữ liệu</div>
        <div v-if="columnVisibility.DefaultValue" style="width: 150px;" class="px-2">Giá trị mặc định</div>
        <div v-if="columnVisibility.FieldOptions" class="flex-grow-1 px-2">Tùy chọn</div>
        <div v-if="columnVisibility.IsRequired" style="width: 80px;" class="px-2 text-center">Bắt buộc</div>
        <div v-if="columnVisibility._usage" style="width: 180px;" class="px-2 text-center">Dùng ở bước</div>
        <div style="width: 50px;" class="px-2 text-right"></div>
      </div>

      <!-- Fields List (Standard Scroll for better reactivity/focus) -->
      <div class="wf-global-fields-list" style="max-height: 600px; overflow-y: auto;">
        <div v-if="filteredFields.length">
          <div v-for="(field, fIdx) in filteredFields" :key="field.MappingID || fIdx"
            :id="'wf-field-row-' + field.FieldName" class="d-flex align-center border-b wf-field-row transition-swing"
            style="min-height: 48px;">
            <!-- Field Name -->
            <div v-if="columnVisibility.FieldName" style="width: 180px;" class="px-2 overflow-hidden">
              <input v-model="field.FieldName" class="wf-native-input"
                :class="{ 'text-warning font-weight-bold': field._isNewFromTemplate }" placeholder="Mã trường" />
            </div>

            <!-- Field Label -->
            <div v-if="columnVisibility.FieldLabel" style="width: 250px;" class="px-2">
              <div class="d-flex align-center">
                <v-icon size="14" class="mr-2 opacity-60">{{ getTypeIcon(field.FieldType) }}</v-icon>
                <input v-model="field.FieldLabel" class="wf-native-input flex-grow-1" placeholder="Nhãn hiển thị..." />
              </div>
            </div>

            <!-- Field Type -->
            <div v-if="columnVisibility.FieldType" style="width: 150px;" class="px-2">
              <select v-model="field.FieldType" class="wf-native-select">
                <option v-for="opt in fieldTypeOptions" :key="opt.value" :value="opt.value">
                  {{ opt.title }}
                </option>
              </select>
            </div>

            <!-- Default Value -->
            <div v-if="columnVisibility.DefaultValue" style="width: 150px;" class="px-2">
              <input v-model="field.DefaultValue" class="wf-native-input" placeholder="—" />
            </div>

            <!-- Field Options -->
            <div v-if="columnVisibility.FieldOptions" class="flex-grow-1 px-2 overflow-hidden">
              <input v-if="field.FieldType === 'select'" v-model="field.FieldOptions" class="wf-native-input"
                placeholder="Nhập các tùy chọn (phân cách bằng dấu phẩy)..." />
              <div v-else-if="field.FieldType === 'computed'" class="d-flex align-center ga-1">
                <select class="wf-native-select" style="max-width: 130px;"
                  @change="(e) => { var v = e.target.value; if (v) field.FieldOptions = v }">
                  <option value="">Chọn mẫu...</option>
                  <option v-for="preset in formulaPresets" :key="preset.value" :value="preset.value">
                    {{ preset.title }}
                  </option>
                </select>
                <input v-model="field.FieldOptions" class="wf-native-input flex-grow-1"
                  placeholder="Công thức, ví dụ: [SoLuong] * [DonGia]" />
              </div>
              <div v-else class="px-2 text-caption text-grey-lighten-1">—</div>
            </div>

            <!-- Required -->
            <div v-if="columnVisibility.IsRequired" style="width: 80px;" class="px-2 d-flex justify-center">
              <input type="checkbox" v-model="field.IsRequired" class="wf-native-checkbox" />
            </div>

            <!-- Usage -->
            <div v-if="columnVisibility._usage" style="width: 180px; gap: 4px;"
              class="px-2 d-flex flex-wrap justify-center align-center">
              <template v-if="fieldStepListMap[field.FieldName] && fieldStepListMap[field.FieldName].length">
                <v-chip v-for="stepIdx in fieldStepListMap[field.FieldName]" :key="stepIdx" size="x-small"
                  color="primary" variant="tonal" class="px-1.5"
                  style="height: 18px; font-size: 10px; border-radius: 4px;"
                  :title="steps[stepIdx] ? steps[stepIdx].StepName : ''">
                  Bước {{ stepIdx + 1 }}
                </v-chip>
              </template>
              <span v-else class="text-caption text-grey-lighten-2">Chưa dùng</span>
            </div>

            <!-- Actions -->
            <div style="width: 50px;" class="px-2 text-right">
              <v-btn icon size="x-small" variant="text" @click="removeField(field)" title="Xóa trường">
                <v-icon size="14" class="wf-icon-danger">mdi-delete-outline</v-icon>
              </v-btn>
            </div>
          </div>
        </div>

        <div v-else class="pa-12 text-center text-grey text-caption">
          <v-icon size="32" class="mb-2 opacity-50">mdi-database-search-outline</v-icon>
          <div>Chưa có trường dữ liệu dùng chung nào.</div>
        </div>
      </div>
    </div>

    <!-- Add Field Dialog -->
    <v-dialog v-model="showAddDialog" max-width="500">
      <v-card class="rounded-lg">
        <div class="pa-4 bg-grey-lighten-4 border-b d-flex align-center justify-space-between">
          <span class="text-subtitle-1 font-weight-bold">Thêm trường dữ liệu mới</span>
          <v-btn icon size="small" variant="text" @click="showAddDialog = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>
        <v-card-text class="pa-4">
          <div class="mb-4">
            <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Nhãn hiển thị *</div>
            <v-text-field v-model="newField.FieldLabel" placeholder="Nhập nhãn..." variant="outlined" density="compact"
              hide-details @update:model-value="autoGenerateFieldName" />
          </div>
          <div class="mb-4">
            <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Mã trường *</div>
            <v-text-field v-model="newField.FieldName" placeholder="Ví dụ: MaTruong" variant="outlined"
              density="compact" hide-details />
          </div>
          <div class="mb-4">
            <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Kiểu dữ liệu *</div>
            <v-select v-model="newField.FieldType" :items="fieldTypeOptions" item-title="title" item-value="value"
              variant="outlined" density="compact" hide-details />
          </div>
          <div v-if="newField.FieldType === 'select'" class="mb-4">
            <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Tùy chọn</div>
            <v-text-field v-model="newField.FieldOptions" placeholder="val1,val2,val3..." variant="outlined"
              density="compact" hide-details />
          </div>
          <div v-if="newField.FieldType === 'computed'" class="mb-4">
            <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Công thức tính</div>
            <v-select :items="formulaPresets" item-title="title" item-value="value" placeholder="Chọn mẫu có sẵn..."
              variant="outlined" density="compact" hide-details class="mb-2"
              @update:model-value="(v) => { if (v) newField.FieldOptions = v }" />
            <v-text-field v-model="newField.FieldOptions" placeholder="hoặc gõ: [SoLuong] * [DonGia]" variant="outlined"
              density="compact" hide-details prepend-inner-icon="mdi-calculator-variant" />
          </div>
          <div class="mb-4">
            <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Giá trị mặc định</div>
            <v-text-field v-model="newField.DefaultValue" placeholder="Nhập giá trị..." variant="outlined"
              density="compact" hide-details />
          </div>
          <div class="d-flex align-center">
            <v-checkbox v-model="newField.IsRequired" label="Bắt buộc nhập" density="compact" hide-details
              color="primary" />
          </div>
        </v-card-text>
        <div class="pa-3 border-t bg-grey-lighten-4 text-right">
          <v-btn variant="text" @click="showAddDialog = false" class="mr-2 text-none font-weight-bold">Hủy
          </v-btn>
          <v-btn color="primary" variant="flat" @click="saveNewField"
            :disabled="!newField.FieldLabel || !newField.FieldName" class="text-none font-weight-bold">Lưu
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Multi-Template Scanner & Smart Mapping Dialog -->
    <v-dialog v-model="showScannerDialog" max-width="960" persistent scrollable>
      <v-card class="rounded-lg">
        <div class="pa-4 bg-grey-lighten-4 border-b d-flex align-center justify-space-between">
          <div>
            <div class="text-subtitle-1 font-weight-bold">Quét placeholder từ biểu mẫu mẫu văn bản</div>
            <div class="text-caption text-grey">Tìm kiếm và ánh xạ các biến ###key### tiếng Việt từ biểu mẫu
              mẫu</div>
          </div>
          <v-btn icon size="small" variant="text" @click="showScannerDialog = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </div>

        <v-card-text class="pa-4" style="max-height: 60vh;">
          <!-- Bước 1: Chọn nhiều template -->
          <div v-if="scannerStep === 1">
            <div class="d-flex align-center justify-space-between mb-3">
              <div class="font-weight-bold text-subtitle-2">Chọn một hoặc nhiều biểu mẫu mẫu văn bản cần
                quét:</div>
              <v-btn v-if="!isCreatingNewTemplate" size="small" color="primary" variant="outlined"
                class="font-weight-bold text-none"
                @click="isCreatingNewTemplate = true; quickTemplate = getEmptyQuickTemplate(); pickedFileName = ''; pickedFileBase64 = ''">
                <v-icon start size="16">mdi-plus</v-icon> Tạo nhanh & Tải mẫu mới
              </v-btn>
              <v-btn v-else size="small" color="grey" variant="text" class="font-weight-bold text-none"
                @click="isCreatingNewTemplate = false">
                Quay lại danh sách
              </v-btn>
            </div>

            <!-- Form: Tạo nhanh Template mới -->
            <div v-if="isCreatingNewTemplate" class="border rounded pa-4 bg-grey-lighten-5 mb-4">
              <div class="wf-file-drop text-center pa-6 mb-4 border-2 border-dashed rounded-lg bg-white cursor-pointer"
                style="border-color: var(--v-theme-primary); border-style: dashed;" @click="triggerFileDialog"
                @dragover.prevent @drop.prevent="onFileDrop">
                <v-icon size="34" color="primary">mdi-file-upload-outline</v-icon>
                <div class="font-weight-bold text-body-2 mt-1">Bấm để chọn hoặc kéo file `.docx/.pdf`
                  vào đây</div>
                <div class="text-caption text-grey mt-1">Hệ thống sẽ tự động đọc placeholder từ tệp của
                  bạn.</div>

                <!-- Loading State inside Dropzone -->
                <div v-if="extractingPlaceholders" class="text-primary font-weight-bold text-caption mt-2">
                  <v-progress-circular indeterminate size="16" width="2" class="mr-1">
                  </v-progress-circular>
                  Đang đọc placeholder từ tệp...
                </div>
                <div v-else-if="uploadingTemplateFile" class="text-primary font-weight-bold text-caption mt-2">
                  <v-progress-circular indeterminate size="16" width="2" class="mr-1">
                  </v-progress-circular>
                  Đang lưu trữ tệp lên máy chủ...
                </div>
                <div v-else-if="pickedFileName" class="text-success font-weight-bold text-caption mt-2">
                  <v-icon size="14" class="mr-1">mdi-check-circle</v-icon>
                  Đã tải tệp: {{ pickedFileName }}
                </div>
                <input ref="fileInput" type="file" accept=".docx,.pdf" style="display:none" @change="onFileSelected" />
              </div>

              <!-- Metadata fields -->
              <v-row dense>
                <v-col cols="12" md="6">
                  <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Tên biểu mẫu mẫu
                    *</div>
                  <v-text-field v-model="quickTemplate.TemplateName" placeholder="Ví dụ: Hợp đồng thử việc"
                    variant="outlined" density="compact" hide-details />
                </v-col>
                <v-col cols="12" md="6">
                  <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Đường dẫn tệp tin
                  </div>
                  <v-text-field v-model="quickTemplate.FileUrl" readonly disabled variant="outlined" density="compact"
                    hide-details placeholder="Đường dẫn được tạo tự động..." />
                </v-col>
                <v-col cols="12" class="mt-2">
                  <div class="text-caption font-weight-bold mb-1 text-grey-darken-1">Mô tả</div>
                  <v-textarea v-model="quickTemplate.Description" placeholder="Mô tả ngắn gọn về biểu mẫu mẫu này..."
                    variant="outlined" density="compact" rows="2" hide-details />
                </v-col>
              </v-row>

              <!-- Placeholder List Preview -->
              <div v-if="quickTemplate.Placeholders && quickTemplate.Placeholders.length" class="mt-3">
                <div class="text-caption font-weight-bold text-grey-darken-2 mb-1">Các biến placeholder
                  phát hiện được ({{ quickTemplate.Placeholders.length }}):</div>
                <div class="d-flex flex-wrap" style="gap: 6px;">
                  <span v-for="ph in quickTemplate.Placeholders" :key="ph"
                    class="text-caption bg-primary-lighten-5 text-primary px-2 py-0.5 rounded border border-primary-lighten-3 font-weight-bold">
                    <v-icon size="10" start>mdi-code-braces</v-icon>
                    {{ ph }}
                  </span>
                </div>
              </div>

              <div class="d-flex justify-end align-center mt-4">
                <v-btn variant="text" class="text-none font-weight-bold mr-2" @click="isCreatingNewTemplate = false">Hủy
                </v-btn>
                <v-btn color="primary" variant="flat" class="text-none font-weight-bold" :loading="isSavingTemplate"
                  :disabled="isSavingTemplate || extractingPlaceholders || uploadingTemplateFile || !quickTemplate.FileName"
                  @click="saveQuickTemplate">
                  <v-icon start size="16">mdi-content-save-outline</v-icon> Lưu & Tiến hành Quét
                </v-btn>
              </div>
            </div>

            <!-- List of existing templates to scan -->
            <div v-if="!isCreatingNewTemplate" class="border rounded bg-white pa-2"
              style="max-height: 250px; overflow-y: auto;">
              <v-row dense>
                <v-col v-for="t in templates" :key="t.TemplateID" cols="12" md="6">
                  <v-checkbox v-model="selectedScannerTemplates" :value="t.TemplateID" color="primary" density="compact"
                    hide-details>
                    <template #label>
                      <div class="text-truncate">
                        <span class="font-weight-bold text-grey-darken-4 text-body-2">{{
                          t.TemplateName }}</span>
                        <span class="text-caption text-grey ml-2" v-if="t.Placeholders">({{
                          t.Placeholders.length }} placeholder)</span>
                      </div>
                    </template>
                  </v-checkbox>
                </v-col>
              </v-row>
            </div>
            <div class="text-center mt-6" v-if="!isCreatingNewTemplate && (!templates || !templates.length)">
              <span class="text-caption text-grey">Không tìm thấy biểu mẫu mẫu nào được cấu hình trong
                workflow này.</span>
            </div>
          </div>

          <!-- Bước 2: Smart Mapping Table -->
          <div v-else-if="scannerStep === 2">
            <div class="d-flex align-center justify-space-between mb-3">
              <span class="font-weight-bold text-subtitle-2">Danh sách biến placeholder quét được ({{
                scannedPlaceholders.length }}):</span>
              <v-btn size="x-small" variant="tonal" color="primary" class="font-weight-bold"
                @click="autoMatchScannerPlaceholders">
                <v-icon start size="12">mdi-auto-fix</v-icon> Tự động map
              </v-btn>
            </div>

            <div class="border rounded overflow-hidden">
              <table class="w-100 text-left border-collapse" style="font-size: 13px;">
                <thead>
                  <tr class="bg-grey-lighten-4 border-b">
                    <th class="pa-2 font-weight-bold text-grey-darken-3" style="width: 250px;">Biến
                      trong biểu mẫu (Key)</th>
                    <th class="pa-2 font-weight-bold text-grey-darken-3" style="width: 140px;">Kiểu
                      dữ liệu</th>
                    <th class="pa-2 font-weight-bold text-grey-darken-3">Ánh xạ sang trường dùng
                      chung</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(item, idx) in scannedPlaceholders" :key="idx" class="border-b">
                    <td class="pa-2">
                      <div class="font-weight-bold text-primary">{{ item.rawKey }}</div>
                      <div class="text-caption text-grey text-truncate" style="max-width: 240px;"
                        :title="item.sources.join(', ')">Mẫu: {{ item.sources.join(', ') }}
                      </div>
                    </td>
                    <td class="pa-2">
                      <v-select v-model="item.fieldType" :items="fieldTypeOptions" item-title="title" item-value="value"
                        density="compact" variant="outlined" hide-details class="wf-compact-select"
                        style="max-width: 130px; font-size: 11px;" />
                    </td>
                    <td class="pa-2">
                      <div class="d-flex align-center" style="gap: 8px;">
                        <v-select v-model="item.mappingOption" :items="item.mappingOptions" density="compact"
                          variant="outlined" hide-details class="wf-compact-select flex-grow-1" />
                        <v-text-field v-if="item.mappingOption === 'CREATE_NEW'" v-model="item.customFieldName"
                          density="compact" variant="outlined" placeholder="Mã trường (không dấu)..." hide-details
                          class="wf-compact-input" style="max-width: 200px;" />
                        <v-text-field v-if="item.mappingOption === 'CREATE_NEW'" v-model="item.customFieldLabel"
                          density="compact" variant="outlined" placeholder="Nhãn trường..." hide-details
                          class="wf-compact-input" style="max-width: 200px;" />
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </v-card-text>

        <div class="pa-3 border-t bg-grey-lighten-4 d-flex align-center justify-space-between">
          <div>
            <span class="text-caption text-grey" v-if="scannerStep === 2">Chọn tạo mới hoặc ghép trùng để
              quản lý dùng chung tiện lợi</span>
          </div>
          <div>
            <v-btn v-if="scannerStep === 2" variant="text" @click="scannerStep = 1"
              class="mr-2 text-none font-weight-bold">Quay lại</v-btn>
            <v-btn v-if="scannerStep === 1" color="primary" variant="flat" :disabled="!selectedScannerTemplates.length"
              @click="proceedScannerStep2" class="text-none font-weight-bold">Tiếp tục quét</v-btn>
            <v-btn v-else-if="scannerStep === 2" color="success" variant="flat" @click="saveScannerMapping"
              class="text-none font-weight-bold">Lưu & Ánh xạ</v-btn>
          </div>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
	export default {
		props: {
    fields: { type: Array, required: true },
    steps: { type: Array, required: true },
    definition: { type: Object, required: true },
    templates: { type: Array, required: false, default: function () { return [] } },
    fieldTypeOptions: { type: Array, required: true },
    getTypeIcon: { type: Function, required: true }
  },
  data: function () {
    return {
      fieldSearchText: "",
      fieldTypeFilter: null,
      fieldStepFilter: null,
      showAddDialog: false,
      newField: {
        FieldName: "", FieldLabel: "", FieldType: "text", FieldOptions: "",
        IsRequired: false, DefaultValue: ""
      },
      columnVisibility: {
        FieldName: true,
        FieldLabel: true,
        FieldType: true,
        DefaultValue: true,
        FieldOptions: true,
        IsRequired: true,
        _usage: true
      },
      showScannerDialog: false,
      scannerStep: 1,
      selectedScannerTemplates: [],
      scannedPlaceholders: [],
      // Quick template upload state inside scanner dialog
      isCreatingNewTemplate: false,
      isSavingTemplate: false,
      extractingPlaceholders: false,
      uploadingTemplateFile: false,
      pickedFileName: "",
      pickedFileBase64: "",
      fileUrlTouchedByUser: false,
      autoGeneratedFileUrl: "",
      quickTemplate: {
        TemplateID: 0,
        TemplateName: "",
        FileName: "",
        FileUrl: "",
        FileType: "docx",
        Description: "",
        Placeholders: [],
        SignatureSlots: [],
        IsActive: true
      },
    };
  },
  computed: {
    formulaPresets: function () {
      return (typeof window !== 'undefined' && window.WF_FORMULA && window.WF_FORMULA.presets) || []
    },
    fieldUsageMap: function () {
      var map = {}
      this.steps.forEach(function (step) {
        var selected = step.SelectedFieldNames || []
        selected.forEach(function (name) {
          if (name) map[name] = (map[name] || 0) + 1
        })
      })
      return map
    },
    fieldStepListMap: function () {
      var map = {}
      this.steps.forEach(function (step, idx) {
        var selected = step.SelectedFieldNames || []
        selected.forEach(function (name) {
          if (name) {
            if (!map[name]) map[name] = []
            map[name].push(idx)
          }
        })
      })
      return map
    },
    fieldStepFilterOptions: function () {
      var opts = [{ title: 'Tất cả', value: null }, { title: 'Chưa dùng', value: '__empty__' }]
      this.steps.forEach(function (step, idx) {
        opts.push({ title: 'Bước ' + (idx + 1) + (step.StepName ? ' — ' + step.StepName : ''), value: idx })
      })
      return opts
    },
    filteredFields: function () {
      var $this = this
      var filter = $this.fieldStepFilter
      var typeFilter = $this.fieldTypeFilter
      var search = ($this.fieldSearchText || "").toLowerCase().trim()
      var result = $this.fields

      if (filter === null || filter === undefined) {
        result = result
      } else {
        result = result.filter(function (field) {
          if (filter === '__empty__') return !$this.fieldStepListMap[field.FieldName]
          return $this.fieldStepListMap[field.FieldName] && $this.fieldStepListMap[field.FieldName].indexOf(filter) !== -1
        })
      }

      if (typeFilter) {
        result = result.filter(function (field) {
          return field.FieldType === typeFilter
        })
      }

      if (search) {
        result = result.filter(function (field) {
          var name = (field.FieldName || "").toLowerCase()
          var label = (field.FieldLabel || "").toLowerCase()
          return name.indexOf(search) !== -1 || label.indexOf(search) !== -1
        })
      }

      return result
    }
  },
  methods: {
    clone: function (value) {
      return JSON.parse(JSON.stringify(value || null));
    },
    reindexFields: function () {
      this.fields.forEach(function (field, index) {
        field.SortOrder = index + 1;
      });
    },
    autoGenerateFieldName: function () {
      if (!this.newField.FieldLabel) {
        this.newField.FieldName = "";
        return;
      }
      var str = this.newField.FieldLabel;
      str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g, "a");
      str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g, "e");
      str = str.replace(/ì|í|ị|ỉ|ĩ/g, "i");
      str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g, "o");
      str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g, "u");
      str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g, "y");
      str = str.replace(/đ/g, "d");
      str = str.replace(/À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ/g, "A");
      str = str.replace(/È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ/g, "E");
      str = str.replace(/Ì|Í|Ị|Ỉ|Ĩ/g, "I");
      str = str.replace(/Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ/g, "O");
      str = str.replace(/Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ/g, "U");
      str = str.replace(/Ỳ|Ý|Ỵ|Ỷ|Ỹ/g, "Y");
      str = str.replace(/Đ/g, "D");
      var words = str.split(/[\s\W_]+/);
      var camelCase = words.map(function(w) {
        if (!w) return "";
        return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
      }).join("");
      this.newField.FieldName = camelCase;
    },
    addField: function () {
      this.newField = {
        FieldName: "", FieldLabel: "", FieldType: "text", FieldOptions: "",
        IsRequired: false, DefaultValue: ""
      };
      this.showAddDialog = true;
    },
    saveNewField: function () {
      if (!this.newField.FieldName) return;
      var newObj = {
        MappingID: 0,
        FieldName: this.newField.FieldName,
        FieldLabel: this.newField.FieldLabel,
        FieldType: this.newField.FieldType,
        FieldOptions: this.newField.FieldOptions,
        IsRequired: this.newField.IsRequired,
        DefaultValue: this.newField.DefaultValue,
        SortOrder: this.fields.length + 1,
        Enable: true
      };
      this.fields.push(newObj);
      this.showAddDialog = false;
      var savedFieldName = newObj.FieldName;
      
      this.$nextTick(function () {
        var el = document.getElementById("wf-field-row-" + savedFieldName);
        if (el) {
          el.scrollIntoView({ behavior: "smooth", block: "center" });
          el.classList.add("wf-field-row--highlight");
          setTimeout(function () {
            el.classList.remove("wf-field-row--highlight");
          }, 2000);
        }
      });
    },
    removeField: function (field) {
      var idx = this.fields.indexOf(field)
      if (idx !== -1) {
        this.fields.splice(idx, 1)
        this.reindexFields()
      }
    },
    importFromCategory: async function () {
      if (!this.definition.CategoryID) {
        if (showToast && showToast.error) showToast.error("Vui lòng chọn Loại luồng trong tab Cài đặt trước khi import.");
        return;
      }
      try {
        const rows = await apiCallAsync("WF_CustomFieldMapping_GetList", { CategoryID: this.definition.CategoryID });
        if (!rows || !rows.length) {
          if (showToast && showToast.info) showToast.info("Không tìm thấy trường dữ liệu nào trong danh mục này.");
          return;
        }
        let importCount = 0;
        const $this = this;
        rows.forEach(function (row) {
          const exists = $this.fields.some(function (f) { return f.FieldName === row.FieldName; });
          if (!exists) {
            $this.fields.push($this.normalizeField(row, $this.fields.length));
            importCount++;
          }
        });
        if (showToast && showToast.success) {
          showToast.success("Đã import thành công " + importCount + " trường từ danh mục.");
        }
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error("Lỗi khi import dữ liệu: " + (err.responseJSON ? err.responseJSON.Message : ""));
        }
      }
    },
    normalizeField: function (field, index) {
      var item = this.clone(field || {});
      return {
        MappingID: item.MappingID || 0,
        FieldName: item.FieldName || "",
        FieldLabel: item.FieldLabel || "",
        FieldType: item.FieldType || "text",
        FieldOptions: item.FieldOptions || "",
        IsRequired: item.IsRequired ? true : false,
        DefaultValue: item.DefaultValue || "",
        SortOrder: Number(item.SortOrder || index + 1),
        Enable: item.Enable !== false
      };
    },
    openTemplateScanner: function () {
      this.selectedScannerTemplates = [];
      this.scannedPlaceholders = [];
      this.scannerStep = 1;
      this.isCreatingNewTemplate = false;
      this.showScannerDialog = true;
    },
    slugify: function (str) {
      if (!str) return "";
      str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g, "a");
      str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g, "e");
      str = str.replace(/ì|í|ị|ỉ|ĩ/g, "i");
      str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g, "o");
      str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g, "u");
      str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g, "y");
      str = str.replace(/đ/g, "d");
      str = str.replace(/À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ/g, "A");
      str = str.replace(/È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ/g, "E");
      str = str.replace(/Ì|Í|Ị|Ỉ|Ĩ/g, "I");
      str = str.replace(/Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ/g, "O");
      str = str.replace(/Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ/g, "U");
      str = str.replace(/Ỳ|Ý|Ỵ|Ỷ|Ỹ/g, "Y");
      str = str.replace(/Đ/g, "D");
      var words = str.split(/[\s\W_]+/);
      return words.map(function(w) {
        if (!w) return "";
        return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
      }).join("");
    },
    proceedScannerStep2: function () {
      var $this = this;
      var selectedIds = this.selectedScannerTemplates || [];
      var activeTemplates = this.templates.filter(function (t) {
        return selectedIds.indexOf(t.TemplateID) !== -1;
      });

      var scannedMap = {};
      activeTemplates.forEach(function (t) {
        var placeholders = t.Placeholders || [];
        placeholders.forEach(function (ph) {
          if (!ph) return;
          var key = ph.trim();
          if (!scannedMap[key]) {
            scannedMap[key] = {
              rawKey: key,
              sources: []
            };
          }
          if (scannedMap[key].sources.indexOf(t.TemplateName) === -1) {
            scannedMap[key].sources.push(t.TemplateName);
          }
        });
      });

      var list = Object.keys(scannedMap).map(function (k) {
        var item = scannedMap[k];
        var cleanLabel = item.rawKey.replace(/###/g, "").trim();
        var autoName = $this.slugify(cleanLabel);

        // Build mapping options: either merge with an existing shared field or create a new one
        var options = [{ title: "Tạo trường dùng chung mới", value: "CREATE_NEW" }];
        $this.fields.forEach(function (f) {
          options.push({ title: "Gộp vào: " + (f.FieldLabel || f.FieldName) + " (" + f.FieldName + ")", value: f.FieldName });
        });

        // Try to pre-match with existing field if name or label aligns
        var mappingOption = "CREATE_NEW";
        var matchedField = $this.fields.find(function (f) {
          return f.FieldName.toLowerCase() === autoName.toLowerCase() || (f.FieldLabel || "").toLowerCase() === cleanLabel.toLowerCase();
        });
        if (matchedField) {
          mappingOption = matchedField.FieldName;
        }

        return {
          rawKey: item.rawKey,
          cleanLabel: cleanLabel,
          fieldType: "text",
          sources: item.sources,
          mappingOption: mappingOption,
          mappingOptions: options,
          customFieldName: autoName,
          customFieldLabel: cleanLabel
        };
      });

      this.scannedPlaceholders = list;
      this.scannerStep = 2;
    },
    autoMatchScannerPlaceholders: function () {
      var $this = this;
      this.scannedPlaceholders.forEach(function (item) {
        var cleanLabel = item.cleanLabel;
        var autoName = $this.slugify(cleanLabel);
        
        var matchedField = $this.fields.find(function (f) {
          return f.FieldName.toLowerCase() === autoName.toLowerCase() || (f.FieldLabel || "").toLowerCase() === cleanLabel.toLowerCase();
        });
        if (matchedField) {
          item.mappingOption = matchedField.FieldName;
        } else {
          item.mappingOption = "CREATE_NEW";
          item.customFieldName = autoName;
          item.customFieldLabel = cleanLabel;
        }
      });
    },
    // Template Upload and Creation Methods
    getEmptyQuickTemplate: function () {
      return {
        TemplateID: 0,
        TemplateName: "",
        FileName: "",
        FileUrl: "",
        FileType: "docx",
        Description: "",
        Placeholders: [],
        SignatureSlots: [],
        IsActive: true
      };
    },
    triggerFileDialog: function () {
      if (this.extractingPlaceholders) return;
      if (this.$refs.fileInput && this.$refs.fileInput.click) this.$refs.fileInput.click();
    },
    onFileSelected: function (event) {
      var input = event && event.target ? event.target : null;
      var file = input && input.files && input.files[0] ? input.files[0] : null;
      if (!file) return;
      this.processTemplateFile(file);
      if (input) input.value = "";
    },
    onFileDrop: function (event) {
      if (this.extractingPlaceholders) return;
      var files = event && event.dataTransfer ? event.dataTransfer.files : null;
      var file = files && files[0] ? files[0] : null;
      if (!file) return;
      this.processTemplateFile(file);
    },
    readFileAsBase64: function (file) {
      return new Promise(function (resolve, reject) {
        var reader = new FileReader();
        reader.onload = function () {
          var raw = String(reader.result || "");
          var marker = raw.indexOf("base64,");
          resolve(marker >= 0 ? raw.substring(marker + 7) : raw);
        };
        reader.onerror = function () {
          reject(new Error("Không đọc được file."));
        };
        reader.readAsDataURL(file);
      });
    },
    detectFileType: function (fileName) {
      var lower = String(fileName || "").toLowerCase();
      if (lower.endsWith(".pdf")) return "pdf";
      return "docx";
    },
    buildTemplatePathFromFileName: function (fileName) {
      var raw = String(fileName || "").trim();
      if (!raw) return "";
      var normalized = raw;
      try {
        normalized = normalized.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
      } catch (e) { }
      var safeName = normalized
        .replace(/[^A-Za-z0-9._-]+/g, "_")
        .replace(/_+/g, "_")
        .replace(/^_+|_+$/g, "");
      if (!safeName) safeName = "template_" + Date.now();
      return "/templates/" + safeName;
    },
    applySelectedFileMeta: function (fileName, fileType, forceUpdatePath) {
      this.quickTemplate.FileName = fileName;
      this.quickTemplate.FileType = fileType;
      if (!(this.quickTemplate.TemplateName || "").trim()) {
        this.quickTemplate.TemplateName = fileName.replace(/\.[^/.]+$/, "");
      }
      var generatedPath = this.buildTemplatePathFromFileName(fileName);
      var shouldUpdatePath = !!forceUpdatePath || !this.quickTemplate.FileUrl || !this.fileUrlTouchedByUser || this.quickTemplate.FileUrl === this.autoGeneratedFileUrl;
      this.autoGeneratedFileUrl = generatedPath;
      if (shouldUpdatePath) {
        this.quickTemplate.FileUrl = generatedPath;
        this.fileUrlTouchedByUser = false;
      }
    },
    onFileNameInput: function (value) {
      var name = String(value || "").trim();
      if (!name) return;
      this.applySelectedFileMeta(name, this.detectFileType(name), false);
    },
    onFileUrlInput: function (value) {
      var current = String(value || "").trim();
      this.fileUrlTouchedByUser = !!current && current !== this.autoGeneratedFileUrl;
    },
    resolveExtractPlaceholderEndpoint: function () {
      var override = "";
      try {
        if (typeof window !== "undefined" && window && window.__WF_TEMPLATE_EXTRACT_ENDPOINT__) {
          override = String(window.__WF_TEMPLATE_EXTRACT_ENDPOINT__).trim();
        }
      } catch (e) { }
      if (!override) {
        try {
          if (typeof localStorage !== "undefined" && localStorage) {
            override = String(localStorage.getItem("WF_TEMPLATE_EXTRACT_ENDPOINT") || "").trim();
          }
        } catch (e2) { }
      }
      if (override) return override;
      return "https://ca-uat.iotsoftvn.com/api/pdf/extract-placeholders";
    },
    resolveSignApiKey: function () {
      var override = "";
      try {
        if (typeof window !== "undefined" && window && window.__WF_SMARTCA_APIKEY__) {
          override = String(window.__WF_SMARTCA_APIKEY__).trim();
        }
      } catch (e) { }
      if (!override) {
        try {
          if (typeof localStorage !== "undefined" && localStorage) {
            override = String(localStorage.getItem("WF_SMARTCA_APIKEY") || "").trim();
          }
        } catch (e2) { }
      }
      if (override) return override;
      return "eGFjLXRodWMtdHUtbGh1LWVkdS12bkAyMDI1QGZ1aS52bg==";
    },
    callExtractPlaceholdersApi: async function (fileBase64, fileName, fileType) {
      var endpoint = this.resolveExtractPlaceholderEndpoint();
      var apiKey = this.resolveSignApiKey();
      var res = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-API-KEY": apiKey
        },
        body: JSON.stringify({
          FileBase64: fileBase64,
          FileName: fileName,
          FileType: fileType
        })
      });
      if (!res.ok) {
        var errText = await res.text();
        throw new Error(errText || ("HTTP " + res.status));
      }
      return await res.json();
    },
    pickUploadedFileRow: function (payload) {
      var row = null;
      if (Array.isArray(payload) && payload.length > 0) {
        row = Array.isArray(payload[0]) ? payload[0][0] : payload[0];
      }
      if (payload && payload.Files && payload.Files[0]) row = payload.Files[0];
      else if (payload && payload.Result) row = payload;
      else if (payload && payload.data && payload.data[0] && !Array.isArray(payload.data[0])) row = payload.data[0];
      else if (payload && payload.data && payload.data[0] && payload.data[0][0]) row = payload.data[0][0];
      else if (payload && payload.FileID) row = payload;
      if (!row) return null;
      return {
        FileID: String(row.FileID || row.FILE_ID || row.fileId || "").trim(),
        FileName: String(row.FileName || row.FILE_NAME || row.fileName || "").trim(),
        FileUrl: String(row.FileUrl || row.FILE_URL || row.fileUrl || "").trim()
      };
    },
    uploadTemplateToFileData: async function (base64, fileName, fileType) {
      var contentType = fileType === "pdf"
        ? "application/pdf"
        : "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      var params = {
        FileBase64: String(base64 || "").trim(),
        FileName: fileName,
        FileContentType: contentType
      };
      var res = null;
      var fileRow = null;
      try {
        res = await apiCallAsync("APIFILE_UPLOAD_Template", params);
        fileRow = this.pickUploadedFileRow(res);
      } catch (errTemplateApi) { }
      if (!fileRow || !fileRow.FileID) {
        res = await apiCallAsync("UPLOAD_FileData_Base64", params);
        fileRow = this.pickUploadedFileRow(res);
      }
      if (!fileRow || !fileRow.FileID) {
        throw new Error("Không nhận được FileID sau khi upload template.");
      }
      return fileRow;
    },
    processTemplateFile: async function (file) {
      this.extractingPlaceholders = true;
      try {
        var base64 = await this.readFileAsBase64(file);
        var fileName = String(file.name || "").trim();
        var fileType = this.detectFileType(fileName);
        var data = await this.callExtractPlaceholdersApi(base64, fileName, fileType);
        var placeholders = (data && data.placeholders && Array.isArray(data.placeholders)) ? data.placeholders : [];
        var uploaded = null;

        this.pickedFileName = fileName;
        this.pickedFileBase64 = base64;
        this.applySelectedFileMeta(fileName, fileType, true);
        this.quickTemplate.Placeholders = placeholders;
        this.uploadingTemplateFile = true;
        uploaded = await this.uploadTemplateToFileData(base64, fileName, fileType);
        this.autoGeneratedFileUrl = "/FileData/" + uploaded.FileID;
        this.quickTemplate.FileUrl = this.autoGeneratedFileUrl;
        this.fileUrlTouchedByUser = false;
        if (showToast && showToast.success) {
          showToast.success("Đã đọc " + placeholders.length + " placeholder và upload file thành công.");
        }
      } catch (err) {
        if (showToast && showToast.error) {
          var msg = err && err.message ? err.message : "Không đọc được placeholder từ file.";
          showToast.error(msg);
        }
      } finally {
        this.uploadingTemplateFile = false;
        this.extractingPlaceholders = false;
      }
    },
    saveQuickTemplate: async function () {
      var $this = this;
      if (!($this.quickTemplate.TemplateName || "").trim()) {
        if (showToast && showToast.error) showToast.error("Tên template không được để trống.");
        return;
      }
      if (!($this.quickTemplate.FileName || "").trim()) {
        if (showToast && showToast.error) showToast.error("Vui lòng tải file template lên trước.");
        return;
      }
      $this.isSavingTemplate = true;
      try {
        var params = {
          TemplateID: Number($this.quickTemplate.TemplateID || 0),
          TemplateName: ($this.quickTemplate.TemplateName || "").trim(),
          FileName: ($this.quickTemplate.FileName || "").trim(),
          FileUrl: ($this.quickTemplate.FileUrl || "").trim(),
          FileType: ($this.quickTemplate.FileType || "").trim(),
          Placeholders: $this.quickTemplate.Placeholders || [],
          SignatureSlots: $this.quickTemplate.SignatureSlots || [],
          Description: ($this.quickTemplate.Description || "").trim(),
          IsActive: $this.quickTemplate.IsActive ? true : false
        };
        const res = await apiCallAsync("WF_Template_Save", params);
        var row = res && res[0] && res[0][0] ? res[0][0] : (res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null);
        var newTemplateID = row ? Number(row.TemplateID) : null;
        if (showToast && showToast.success) {
          showToast.success(row && row.Message ? row.Message : "Lưu template thành công.");
        }
        
        $this.isCreatingNewTemplate = false;
        $this.quickTemplate = $this.getEmptyQuickTemplate();
        
        // Notify parent to reload templates list
        $this.$emit("reload-templates");

        // Wait a tick for prop update, or directly push mock template inside local scanner selection
        if (newTemplateID) {
          $this.selectedScannerTemplates.push(newTemplateID);
          // Wait briefly for props to reload and sync new templates from API
          setTimeout(function() {
            $this.proceedScannerStep2();
          }, 600);
        }
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error(err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : (err.message ? err.message : "Đã xảy ra lỗi khi lưu."));
        }
      } finally {
        $this.isSavingTemplate = false;
      }
    },
    saveScannerMapping: function () {
      var $this = this;
      var addedCount = 0;
      var mappedCount = 0;

      this.scannedPlaceholders.forEach(function (item) {
        if (item.mappingOption === "CREATE_NEW") {
          var name = (item.customFieldName || "").trim();
          var label = (item.customFieldLabel || "").trim() || item.cleanLabel;
          if (!name) return;

          // Check if it already exists
          var exists = $this.fields.some(function (f) {
            return f.FieldName.toLowerCase() === name.toLowerCase();
          });

          if (!exists) {
            var newFieldObj = {
              MappingID: 0,
              FieldName: name,
              FieldLabel: label,
              FieldType: item.fieldType || "text",
              FieldOptions: "",
              IsRequired: false,
              DefaultValue: "",
              SortOrder: $this.fields.length + 1,
              Enable: true,
              _isNewFromTemplate: true
            };
            $this.fields.push(newFieldObj);
            addedCount++;
          }
        } else {
          // It's mapped/merged to an existing field
          mappedCount++;
        }
      });

      this.showScannerDialog = false;
      if (showToast && showToast.success) {
        showToast.success("Quét & Ánh xạ hoàn thành. Đã thêm " + addedCount + " trường mới, gộp " + mappedCount + " trường dùng chung.");
      }
    }
  }
	}
</script>