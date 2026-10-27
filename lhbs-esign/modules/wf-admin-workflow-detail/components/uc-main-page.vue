<template>
	<uc-wf-shell :show-user-section="false">
    <div class="d-flex align-center ga-1 wf-page-header">
      <v-btn class="wf-btn" variant="text" color="primary" @click="goBack">
        <v-icon start size="16">mdi-arrow-left</v-icon>
        Danh sách
      </v-btn>
      <v-divider vertical class="wf-detail-divider" />
      <div class="wf-detail-title">
        <div class="d-flex align-center wf-detail-title-row">
          <h1 class="wf-detail-name">{{ displayDefinitionName }}</h1>
          <v-chip size="x-small" color="primary" variant="tonal" class="wf-chip-rounded">
            {{ definition.IsActive ? 'Hoạt động' : 'Tắt' }}
          </v-chip>
        </div>
        <p class="wf-detail-sub">
          {{ displayDefinitionMeta }}
        </p>
      </div>
      <v-btn class="wf-btn" variant="outlined" color="primary" :disabled="isCreateMode || isSaving"
        @click="cloneCurrentDefinition">
        <v-icon start size="16">mdi-content-copy</v-icon>
        Tạo bản sao
      </v-btn>
      <!-- <v-btn class="wf-btn" variant="outlined" color="primary" :disabled="isCreateMode"
        @click="previewCurrentDefinition">
        <v-icon start size="16">mdi-eye-outline</v-icon>
        Preview
      </v-btn> -->
      <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSaving" :disabled="isSaving"
        @click="saveDefinition">
        <v-icon start size="16">mdi-content-save-outline</v-icon>
        Lưu
      </v-btn>
    </div>

    <div class="wf-tab-bar wf-detail-header bg-white mb-0">
      <div v-for="tab in tabList" :key="tab.value" class="wf-tab-item" :class="{ active: defTab === tab.value }"
        @click="defTab = tab.value">
        <v-icon size="14" class="mr-1">{{ tab.icon }}</v-icon>
        {{ tab.label }}<span v-if="tab.count !== undefined"> ({{ tab.count }})</span>
      </div>
    </div>

    <div v-if="defTab === 'steps'" class="d-flex wf-detail-steps pa-3">
      <uc-workflow-step-sidebar :activeStepIdx="activeStepIdx" :steps="steps" :roles="roles"
        @update:activeStepIdx="onSelectStep" @add-step="addStep" @remove-step="removeStep"
        @reorder-steps="reorderSteps" />

      <div class="wf-detail-step-editor" v-if="activeStep">
        <!-- Header outside card, matching the mockup style -->
        <div class="d-flex align-center pb-2" style="gap: 13px;">
          <div style="flex: 1;">
            <div style="font-size: 18px; font-weight: 700; line-height: 1.1;">{{ activeStep.StepName }}</div>
            <div style="font-size: 12px; color: #8a968f; margin-top: 2px;">Cấu hình chi tiết cho bước này</div>
          </div>
          <span
            style="font-family: 'JetBrains Mono', monospace; font-size: 12px; font-weight: 500; color: #5c6864; background: #eef2f0; padding: 5px 11px; border-radius: 8px;">
            {{ activeStep.StepCode }}
          </span>
        </div>

        <div class="wf-detail-step-editor-scroll-container pr-1"
          style="max-height: calc(100vh - 185px); overflow-y: auto;">
          <div class="wf-tcard wf-detail-editor-card mb-3">

            <!-- ── SECTION 2: Thông tin cơ bản ──────────────────── -->
            <div class="wf-editor-section">
              <div class="wf-editor-section__label font-weight-bold">
                <v-icon size="12" class="mr-1">mdi-information-outline</v-icon>Thông tin cơ bản
              </div>
              <v-row dense class="mb-2">
                <v-col cols="12" md="6">
                  <div class="text-caption mb-1 text-grey-darken-2">Tên bước</div>
                  <v-text-field v-model="activeStep.StepName" placeholder="Nhập tên bước" variant="outlined"
                    density="compact" hide-details :disabled="isTerminalStep" class="wf-ant-input bg-white" />
                </v-col>
                <v-col cols="12" md="3">
                  <div class="text-caption mb-1 text-grey-darken-2">Mã bước</div>
                  <v-text-field v-model="activeStep.StepCode" placeholder="Nhập mã bước" variant="outlined"
                    density="compact" hide-details :disabled="isTerminalStep" class="wf-ant-input bg-white" />
                </v-col>
                <v-col cols="12" md="3">
                  <div class="text-caption mb-1 text-grey-darken-2">Loại</div>
                  <v-select v-model="activeStep.StepType" :items="stepTypeOptions" item-title="label" item-value="value"
                    placeholder="Chọn loại" variant="outlined" density="compact" hide-details :disabled="isTerminalStep"
                    class="wf-ant-input bg-white" />
                </v-col>
              </v-row>
              <v-row v-if="!isTerminalStep" dense>
                <v-col cols="12" md="6">
                  <div class="text-caption mb-1 text-grey-darken-2">Người quản lý bước (Chọn nhiều)</div>
                  <uc-select-user v-model="activeStep.AssigneeIDs" placeholder="Chọn người quản lý..." multiple />
                </v-col>
                <v-col cols="12" md="3">
                  <div class="text-caption mb-1 text-grey-darken-2">Loại thời hạn</div>
                  <v-select v-model="activeStep.DueType" :items="dueTypeOptions" item-title="label" item-value="value"
                    placeholder="Loại thời hạn" variant="outlined" density="compact" hide-details
                    class="wf-ant-input bg-white" />
                </v-col>
                <v-col cols="12" md="3">
                  <div class="text-caption mb-1 text-grey-darken-2">
                    {{ dueTypeLabel }}
                  </div>
                  <!-- Dropdown chọn thứ trong tuần nếu chọn FIXED_DAY_OF_WEEK -->
                  <v-select v-if="activeStep.DueType === 'FIXED_DAY_OF_WEEK'" v-model="activeStep.NumDueHour"
                    :items="weekDayOptions" item-title="label" item-value="value" placeholder="Chọn thứ..."
                    variant="outlined" density="compact" hide-details class="wf-ant-input bg-white" />

                  <!-- DatePicker nếu chọn FIXED_DATE -->
                  <v-text-field v-else-if="activeStep.DueType === 'FIXED_DATE'" v-model="activeStep.NumDueHour"
                    type="date" placeholder="Chọn ngày..." variant="outlined" density="compact" hide-details
                    prepend-inner-icon="mdi-calendar" class="wf-ant-input bg-white" />

                  <!-- Textfield nhập số thông thường cho các loại khác -->
                  <v-text-field v-else v-model="activeStep.NumDueHour"
                    :placeholder="activeStep.DueType === 'FIXED_DAY_OF_MONTH' ? 'Ví dụ: 15' : 'Nhập thời hạn'"
                    density="compact" variant="outlined" hide-details prepend-inner-icon="mdi-clock-outline"
                    class="wf-ant-input bg-white" />
                </v-col>
              </v-row>
              <v-row v-if="!isTerminalStep" dense class="mt-2">
                <v-col cols="12">
                  <div class="text-caption mb-1 text-grey-darken-2">Mô tả bước</div>
                  <v-textarea v-model="activeStep.Description"
                    placeholder="Nhập mô tả chi tiết nhiệm vụ hoặc hướng dẫn cho bước này..." variant="outlined"
                    density="compact" rows="2" hide-details class="wf-ant-input bg-white" />
                </v-col>
              </v-row>
            </div>
          </div>

          <!-- Card 2: Cấu hình văn bản mẫu -->
          <div v-if="stepRequiresTemplate(activeStep.StepType)" class="wf-tcard wf-detail-editor-card mb-3">

            <!-- ── SECTION 3: Template ───────────────────────────── -->
            <div class="wf-editor-section">
              <div class="wf-editor-section__label d-flex align-center">
                <v-icon size="14" class="mr-1" color="success">mdi-file-document-outline</v-icon>
                Cấu hình văn bản nhập liệu mẫu
                <v-spacer />
                <v-btn variant="text" class="font-weight-bold text-none" color="primary" size="x-small"
                  @click="addTemplateSlot">
                  <v-icon start size="12">mdi-plus</v-icon>Thêm văn bản mẫu
                </v-btn>
              </div>

              <!-- MULTI-TEMPLATE MODE -->
              <div v-for="(slot, slotIdx) in activeStep.templates" :key="slotIdx" class="wf-template-card mt-3">
                <!-- Red diagonal corner delete ribbon as drawn in sketch -->
                <div class="wf-card-delete-ribbon" @click="removeTemplateSlot(slotIdx)">
                  <v-icon size="10" color="white">mdi-close</v-icon>
                </div>

                <!-- First Row: Document Icon + Dropdown + Eye preview icon + Up/Down arrows -->
                <div class="text-caption mb-1 text-grey-darken-2">{{slotIdx + 1}}. Văn bản mẫu: </div>
                <div class="d-flex align-center pr-6" style="gap: 8px;">
                  <v-icon size="18" color="success" class="mr-1">mdi-file-document-outline</v-icon>
                  <v-select v-model="slot.TemplateID" :items="templateOptions" item-title="title" item-value="value"
                    placeholder="Chọn văn bản mẫu..." variant="outlined" density="compact" hide-details clearable
                    @update:modelValue="onSlotTemplateSelect(slotIdx, $event)" class="wf-ant-input bg-white flex-grow-1"
                    style="border-radius: 6px;" />
                  <v-chip v-if="slot.TemplateID && getTemplateById(slot.TemplateID)" size="small" color="primary"
                    variant="tonal" style="height: 32px; font-size: 11px; font-weight: 600; border-radius: 6px;"
                    class="ml-1">
                    Đã gán {{ slotGroupFields(slot, slotIdx).length }} trường
                  </v-chip>
                  <v-btn v-if="slot.TemplateID" variant="text" color="success" size="small" class="ml-1 px-1"
                    min-width="0" @click="openTemplatePreview(getTemplateById(slot.TemplateID))">
                    <v-icon size="16">mdi-eye-outline</v-icon>
                  </v-btn>
                  <!-- Template reorder buttons -->
                  <v-btn icon size="x-small" variant="text" color="primary" class="pa-0" style="min-width: 0;"
                    :disabled="slotIdx === 0" @click="moveTemplateSlot(slotIdx, -1)" title="Di chuyển lên">
                    <v-icon size="16">mdi-arrow-up</v-icon>
                  </v-btn>
                  <v-btn icon size="x-small" variant="text" color="primary" class="pa-0" style="min-width: 0;"
                    :disabled="slotIdx === activeStep.templates.length - 1" @click="moveTemplateSlot(slotIdx, 1)"
                    title="Di chuyển xuống">
                    <v-icon size="16">mdi-arrow-down</v-icon>
                  </v-btn>
                </div>

                <!-- Second Row: Match Count + Duplicate count + Expand toggle -->
                <div
                  v-if="getTemplateById(slot.TemplateID) && getTemplateById(slot.TemplateID).Placeholders && getTemplateById(slot.TemplateID).Placeholders.length"
                  class="d-flex align-center justify-space-between mt-3 mb-2">
                  <div class="d-flex align-center" style="gap: 8px;">
                    <!-- Completion Status Inline -->
                    <div v-if="slotAttentionFields(slot).length === 0"
                      class="text-caption text-success font-weight-medium d-flex align-center"
                      style="font-size: 10px; gap: 4px;">
                      <v-icon size="12" color="success">mdi-check</v-icon>
                      Các trường tùy chỉnh đã được thêm vào văn bản mẫu
                    </div>
                  </div>

                  <v-btn v-if="slotLinkedFields(slot).length > 0" variant="text" size="x-small" color="primary"
                    class="font-weight-bold pa-0" style="font-size: 10px; min-width: 0;"
                    @click="toggleSlotExpand(slotIdx)">
                    {{ isSlotExpanded(slotIdx) ? 'Thu gọn' : 'XEM TRƯỜNG' }}
                    <v-icon size="12" class="ml-1">{{ isSlotExpanded(slotIdx) ? 'mdi-chevron-up' :'mdi-chevron-down' }}
                    </v-icon>
                  </v-btn>
                </div>

                <!-- Fields details / chips section -->
                <div
                  v-if="getTemplateById(slot.TemplateID) && getTemplateById(slot.TemplateID).Placeholders && getTemplateById(slot.TemplateID).Placeholders.length"
                  class="mt-2">
                  <!-- Expanded: detailed fields list with table style -->
                  <div v-if="isSlotExpanded(slotIdx) && slotGroupFields(slot, slotIdx).length > 0"
                    class="wf-slot-field-table">
                    <!-- Header row -->
                    <div class="d-flex align-center py-1 px-2 bg-grey-lighten-4 text-caption font-weight-bold"
                      style="font-size: 9px; gap: 8px; position: sticky; top: 0; z-index: 2;">
                      <div style="width: 18px;"></div>
                      <div style="width: 22px;">#</div>
                      <div style="flex: 1; min-width: 120px;">Tên hiển thị</div>
                      <div style="width: 75px;">Kiểu</div>
                      <div style="width: 60px;">Bắt buộc</div>
                      <div style="width: 100px;">Thao tác</div>
                    </div>
                    <!-- Data rows -->
                    <div :ref="'tplSortable_' + slotIdx">
                      <div v-for="(field, index) in slotGroupFields(slot, slotIdx)"
                        :key="'ft-' + slotIdx + '-' + field.FieldName" :data-field-name="field.FieldName"
                        class="d-flex align-center border-b py-2 px-2 cursor-pointer wf-cfd-list-row"
                        style="gap: 8px; font-size: 11px;">
                        <v-icon size="14" color="grey-lighten-1" class="wf-drag-handle"
                          style="cursor: grab; width: 18px;" @mousedown.stop>
                          mdi-drag-vertical
                        </v-icon>
                        <div style="width: 22px;" class="text-caption font-weight-bold text-grey-darken-4">
                          {{ index + 1 }}.
                        </div>
                        <div style="flex: 1; min-width: 120px;" class="text-truncate">
                          <span class="font-weight-bold">{{ field.FieldLabel }}</span>
                          <span class="text-grey ml-1">({{ field.FieldName }})</span>
                        </div>
                        <div style="width: 75px;">
                          <v-chip size="x-small" color="primary" variant="tonal" class="px-1"
                            style="height: 18px; font-size: 9px;">
                            {{ getFieldTypeLabel(field.FieldType) }}
                          </v-chip>
                        </div>
                        <div style="width: 60px;">
                          <input type="checkbox" :checked="isFieldRequiredInStep(field.FieldName)"
                            @change.stop="toggleStepRequired(field.FieldName)"
                            style="width: 16px; height: 16px; accent-color: #2e7d32; cursor: pointer;">
                        </div>
                        <div style="width: 100px; gap: 2px;" class="d-flex align-center justify-end">
                          <v-btn icon size="x-small" variant="text" color="primary" class="pa-0 ma-0"
                            style="width: 22px; height: 22px; min-width: 22px;" :disabled="index === 0"
                            @click.stop="moveFieldOrder(field, -1, 'tpl_' + slot.TemplateID + '_' + slotIdx)"
                            title="Di chuyển lên">
                            <v-icon size="14">mdi-chevron-up</v-icon>
                          </v-btn>
                          <v-btn icon size="x-small" variant="text" color="primary" class="pa-0 ma-0"
                            style="width: 22px; height: 22px; min-width: 22px;"
                            :disabled="index === slotGroupFields(slot, slotIdx).length - 1"
                            @click.stop="moveFieldOrder(field, 1, 'tpl_' + slot.TemplateID + '_' + slotIdx)"
                            title="Di chuyển xuống">
                            <v-icon size="14">mdi-chevron-down</v-icon>
                          </v-btn>
                          <v-btn icon size="x-small" variant="text" color="primary" class="pa-0 ma-0"
                            style="width: 22px; height: 22px; min-width: 22px;"
                            @click.stop="editFieldFromTemplate(field)">
                            <v-icon size="14">mdi-pencil-outline</v-icon>
                          </v-btn>
                          <v-btn icon size="x-small" variant="text" color="error" class="pa-0 ma-0"
                            style="width: 22px; height: 22px; min-width: 22px;"
                            @click.stop="togglePlaceholder(field.FieldName)">
                            <v-icon size="14">mdi-delete-outline</v-icon>
                          </v-btn>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Collapsed / Overview Mode: Show Case 1 (Placeholders to add) and Case 3 (Duplicate Placeholders) using span custom-chips -->
                  <div
                    v-if="!isSlotExpanded(slotIdx) && (slotAttentionFields(slot).filter(c => c.type === 'unassigned').length > 0 || activeStepDuplicatePlaceholders.filter(p => slotLinkedFields(slot).indexOf(p) !== -1).length > 0)"
                    class="d-flex flex-column ga-2 mt-2 pa-2 bg-grey-lighten-5 rounded border">
                    <!-- Case 1: Data chưa có trong trường tùy chỉnh chung -->
                    <div v-if="slotAttentionFields(slot).filter(c => c.type === 'unassigned').length > 0">
                      <div class="d-flex align-center flex-wrap mb-1" style="gap: 8px;">
                        <span class="text-caption font-weight-bold text-grey-darken-3">Chưa có trong trường tùy
                          chỉnh:</span>
                        <v-btn variant="tonal" color="primary" size="x-small" class="font-weight-bold text-none"
                          @click="importPlaceholdersFromTemplate(getTemplateById(slot.TemplateID))">
                          <v-icon start size="12">mdi-plus-circle-outline</v-icon>
                          Thêm nhanh tất cả
                        </v-btn>
                      </div>
                      <div class="d-flex flex-wrap ga-1">
                        <span v-for="chip in slotAttentionFields(slot).filter(c => c.type === 'unassigned')"
                          :key="'att-un-' + slotIdx + '-' + chip.name"
                          class="wf-custom-chip wf-custom-chip--unassigned cursor-pointer"
                          @click="togglePlaceholder(chip.name)" title="Bấm để thêm nhanh trường này">
                          <v-icon size="10" class="mr-1">mdi-plus</v-icon>
                          {{ chip.name }}
                        </span>
                      </div>
                    </div>

                    <!-- Case 3: Trường trùng lặp giữa các biểu mẫu (Multi template) -->
                    <div
                      v-if="activeStepDuplicatePlaceholders.filter(p => slotLinkedFields(slot).indexOf(p) !== -1).length > 0">
                      <div class="text-caption font-weight-bold text-warning mb-1">
                        <v-icon size="14" color="warning" class="mr-1">mdi-alert-circle-outline</v-icon>
                        Trường trùng với biểu mẫu khác:
                      </div>
                      <div class="d-flex flex-wrap ga-1">
                        <span
                          v-for="phName in activeStepDuplicatePlaceholders.filter(p => slotLinkedFields(slot).indexOf(p) !== -1)"
                          :key="'att-dup-' + slotIdx + '-' + phName" class="wf-custom-chip wf-custom-chip--duplicate">
                          <v-icon size="10" class="mr-1">mdi-alert-circle-outline</v-icon>
                          {{ phName }}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>



                <!-- Signers per slot -->
                <div v-if="['SIGN', 'ECONTRACT'].includes(activeStep.StepType)" class="mt-2">
                  <div class="text-caption mb-1 text-grey-darken-2">Người ký</div>
                  <div v-for="(signer, signerIdx) in slot.Signers" :key="signerIdx"
                    class="wf-signer-row d-flex align-center ga-2 mb-1">
                    <div class="wf-signer-row__order">{{ signerIdx + 1 }}</div>
                    <v-select v-model="signer.SignerType" :items="signerTypeOptions" item-title="label"
                      item-value="value" density="compact" variant="outlined" hide-details class="wf-ant-input bg-white"
                      style="max-width: 140px;" />
                    <v-text-field v-model="signer.SignerValue" placeholder="Giá trị..." density="compact"
                      variant="outlined" hide-details class="wf-ant-input bg-white flex-grow-1" />
                    <v-select v-model="signer.SignMethod" :items="signMethodOptions" item-title="label"
                      item-value="value" density="compact" variant="outlined" hide-details class="wf-ant-input bg-white"
                      style="max-width: 140px;" />
                    <v-btn icon="mdi-minus-circle-outline" variant="text" color="error" size="x-small"
                      @click="removeSlotSigner(slotIdx, signerIdx)" />
                  </div>
                  <v-btn variant="text" color="primary" size="x-small" class="mt-1" @click="addSlotSigner(slotIdx)">
                    <v-icon start size="12">mdi-plus</v-icon>Thêm người ký
                  </v-btn>
                </div>
              </div>

              <!-- Custom Fields Card (Trường ngoài mẫu văn bản) -->
              <div v-if="customFieldsGroup" class="wf-template-card mt-3">
                <div class="wf-editor-section__label d-flex align-center">
                  <v-icon size="14" class="mr-1" color="success">mdi-file-document-outline</v-icon>
                  Trường tùy chỉnh nhập liệu ngoài văn bản mẫu ({{ customFieldsGroup.fields.length }})
                  <v-spacer />
                  <v-btn variant="text" class="font-weight-bold text-none" color="primary" size="x-small"
                    @click="openConfigModal">
                    <v-icon start size="12">mdi-cog-outline</v-icon>Cấu hình trường dữ liệu
                  </v-btn>
                </div>

                <!-- Expanded: detailed fields list for custom fields -->
                <div v-if="customFieldsGroup.fields.length > 0" class="wf-slot-field-table mt-2">
                  <!-- Header row -->
                  <div class="d-flex align-center py-1 px-2 bg-grey-lighten-4 text-caption font-weight-bold"
                    style="font-size: 9px; gap: 8px; position: sticky; top: 0; z-index: 2;">
                    <div style="width: 18px;"></div>
                    <div style="width: 22px;">#</div>
                    <div style="flex: 1; min-width: 120px;">Tên hiển thị</div>
                    <div style="width: 75px;">Kiểu</div>
                    <div style="width: 60px;">Bắt buộc</div>
                    <div style="width: 100px;">Thao tác</div>
                  </div>
                  <!-- Data rows -->
                  <div ref="customFieldsSortable">
                    <div v-for="(field, index) in customFieldsGroup.fields" :key="'assigned-custom-' + field.FieldName"
                      :data-field-name="field.FieldName" :data-group-id="'custom_fields'"
                      class="d-flex align-center border-b py-2 px-2 cursor-pointer wf-cfd-list-row"
                      :class="{ 'bg-red-lighten-5 border-error': field._isOrphan }" style="gap: 8px; font-size: 11px;"
                      :style="field._isOrphan ? 'background-color: #ffebee !important; border-left: 3px solid #ef5350 !important;' : ''">
                      <v-icon v-if="!field._isOrphan" size="14" color="grey-lighten-1" class="wf-drag-handle"
                        style="cursor: grab; width: 18px;" @mousedown.stop>
                        mdi-drag-vertical
                      </v-icon>
                      <v-icon v-else size="14" color="error" style="width: 18px;">
                        mdi-alert-circle-outline
                      </v-icon>
                      <div style="width: 22px;" class="text-caption font-weight-bold text-grey-darken-4">
                        {{ index + 1 }}.
                      </div>
                      <div style="flex: 1; min-width: 120px;" class="text-truncate">
                        <span class="font-weight-bold" :class="{ 'text-error': field._isOrphan }">{{ field.FieldLabel
                          }}</span>
                        <span class="text-grey ml-1">({{ field.FieldName }})</span>
                      </div>
                      <div style="width: 75px;">
                        <v-chip size="x-small" :color="field._isOrphan ? 'error' : 'primary'" variant="tonal"
                          class="px-1" style="height: 18px; font-size: 9px;">
                          {{ getFieldTypeLabel(field.FieldType) }}
                        </v-chip>
                      </div>
                      <div style="width: 60px;">
                        <input type="checkbox" :checked="isFieldRequiredInStep(field.FieldName)"
                          @change.stop="toggleStepRequired(field.FieldName)" :disabled="field._isOrphan"
                          style="width: 16px; height: 16px; accent-color: #2e7d32; cursor: pointer;">
                      </div>

                      <!-- Thao tác cột cho trường bình thường -->
                      <div v-if="!field._isOrphan" style="width: 100px; gap: 2px;"
                        class="d-flex align-center justify-end">
                        <v-btn icon size="x-small" variant="text" color="primary" class="pa-0 ma-0"
                          style="width: 22px; height: 22px; min-width: 22px;" :disabled="index === 0"
                          @click.stop="moveFieldOrder(field, -1, 'custom_fields')" title="Di chuyển lên">
                          <v-icon size="14">mdi-chevron-up</v-icon>
                        </v-btn>
                        <v-btn icon size="x-small" variant="text" color="primary" class="pa-0 ma-0"
                          style="width: 22px; height: 22px; min-width: 22px;"
                          :disabled="index === customFieldsGroup.fields.length - 1"
                          @click.stop="moveFieldOrder(field, 1, 'custom_fields')" title="Di chuyển xuống">
                          <v-icon size="14">mdi-chevron-down</v-icon>
                        </v-btn>
                        <v-btn icon size="x-small" variant="text" color="primary" class="pa-0 ma-0"
                          style="width: 22px; height: 22px; min-width: 22px;"
                          @click.stop="editFieldFromTemplate(field)">
                          <v-icon size="14">mdi-pencil-outline</v-icon>
                        </v-btn>
                        <v-btn icon size="x-small" variant="text" color="error" class="pa-0 ma-0"
                          style="width: 22px; height: 22px; min-width: 22px;"
                          @click.stop="togglePlaceholder(field.FieldName)">
                          <v-icon size="14">mdi-delete-outline</v-icon>
                        </v-btn>
                      </div>

                      <!-- Thao tác cột cho trường mồ côi -->
                      <div v-else style="width: 100px; gap: 6px;" class="d-flex align-center justify-end">
                        <v-btn variant="outlined" color="success" size="x-small" class="font-weight-bold px-1 text-none"
                          style="font-size: 9px; height: 22px;" @click.stop="recoverOrphanField(field.FieldName)"
                          title="Khôi phục lại trường này vào danh mục trường tùy chỉnh dùng chung">
                          Thêm lại
                        </v-btn>
                        <v-btn icon size="x-small" variant="text" color="error" class="pa-0 ma-0"
                          style="width: 22px; height: 22px; min-width: 22px;"
                          @click.stop="togglePlaceholder(field.FieldName)" title="Xóa trường này khỏi bước hiện tại">
                          <v-icon size="14">mdi-delete-outline</v-icon>
                        </v-btn>
                      </div>
                    </div>
                  </div>
                </div>
                <div v-else class="wf-empty-box mt-2">
                  Chưa có trường tùy chỉnh ngoài văn bản mẫu.
                </div>
              </div>
            </div>
          </div>

          <!-- Card 3: Cài đặt nâng cao -->
          <div class="wf-tcard wf-detail-editor-card mt-3">
            <!-- ── SECTION 5: Step Tabs (Nhiệm vụ / Tự động hóa / Checklist hồ sơ) ── -->
            <div class="wf-editor-section wf-editor-section--tabs">
              <div class="wf-editor-section__label font-weight-bold mb-2">
                <v-icon size="14" class="mr-1" color="primary">mdi-cog-outline</v-icon>Cài đặt nâng cao
              </div>
              <div class="wf-tab-bar wf-tab-bar--step mb-3">
                <div v-if="!isTerminalStep" class="wf-tab-item" :class="{ active: activeStepTab === 'checklist' }"
                  @click="activeStepTab = 'checklist'">
                  <v-icon size="14" class="mr-1">mdi-clipboard-list-outline</v-icon> Mẫu checklist
                </div>
                <div class="wf-tab-item" :class="{ active: activeStepTab === 'automation' }"
                  @click="activeStepTab = 'automation'">
                  <v-icon size="14" class="mr-1">mdi-robot-outline</v-icon> Tự động hóa
                </div>
              </div>

              <!-- Tab: Checklist công việc -->
              <uc-workflow-step-tasks v-if="activeStepTab === 'checklist' && !isTerminalStep"
                :active-step="activeStep" />

              <!-- Tab: Automation -->
              <uc-workflow-step-automation v-if="activeStepTab === 'automation'" :active-step="activeStep"
                :reject-options="rejectOptions" :all-definitions="allDefinitions"
                :shared-field-options="sharedFieldOptions" :assignee-options="assigneeOptions"
                @editing-rule-changed="editingRuleIdx = $event" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ── TAB: Fields ───────────────────────────────────────────── -->
    <div v-if="defTab === 'fields'" class="pa-3">
      <uc-workflow-fields :fields="fields" :steps="steps" :definition="definition" :templates="templates"
        :field-type-options="fieldTypeOptions" :get-type-icon="getTypeIcon" @reload-templates="loadTemplates" />
    </div>

    <!-- ── TAB: Settings ─────────────────────────────────────────── -->
    <div v-if="defTab === 'settings'" class="pa-3">
      <uc-workflow-settings :definition="definition" :categories="categories" :assignee-options="assigneeOptions" />

      <!-- Nút Tiếp tục được bố trí ở dưới cùng của Tab Cài đặt -->
      <div class="d-flex justify-end mt-4 pr-1">
        <v-btn v-if="isCreateMode" variant="outlined" color="primary" class="wf-btn px-6 font-weight-bold"
          @click="defTab = 'steps'" height="36" style="letter-spacing: 0.1px;">
          Tiếp tục
          <v-icon end size="16" class="ml-2">mdi-arrow-right</v-icon>
        </v-btn>
      </div>
    </div>

    <!-- Dialog Thêm mới Người quản lý/Vai trò -->
    <v-dialog v-model="showAddRoleDialog" max-width="500">
      <v-card>
        <v-card-title class="d-flex align-center pa-4">
          <v-icon color="primary" class="mr-2">mdi-account-plus-outline</v-icon>
          Thêm người quản lý mới
        </v-card-title>
        <v-divider class="my-5" />
        <v-card-text class="pa-4">
          <v-text-field v-model="newRole.RoleCode" label="Mã vai trò (Role Code)"
            placeholder="Ví dụ: TP_HCNS, GIAM_DOC_DA" variant="outlined" density="compact" class="mb-3"
            persistent-placeholder />
          <v-text-field v-model="newRole.RoleName" label="Tên hiển thị" placeholder="Ví dụ: Trưởng phòng HCNS"
            variant="outlined" density="compact" class="mb-3" persistent-placeholder />
          <v-autocomplete v-model="newRole.DefaultPersonID" :items="employeeOptions" v-model:search="employeeSearchText"
            label="Chọn nhân viên thực tế" placeholder="Gõ tên hoặc mã nhân viên..." variant="outlined"
            density="compact" hide-details :loading="isSearchingEmployees" no-data-text="Không tìm thấy nhân viên"
            @update:search="onEmployeeSearch" />
        </v-card-text>
        <v-divider class="my-5" />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="showAddRoleDialog = false">Hủy</v-btn>
          <v-btn color="primary" variant="flat" :loading="isSavingRole"
            :disabled="!newRole.RoleCode || !newRole.RoleName" @click="saveNewRole">Lưu lại</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Quick Create Template Dialog -->
    <v-dialog v-model="showQuickTemplateDialog" max-width="760">
      <v-card>
        <v-card-title class="wf-template-dialog-title">Upload template mới</v-card-title>
        <v-card-text class="wf-template-dialog-body">
          <div class="wf-file-drop" @click="triggerFileDialog" @dragover.prevent @drop.prevent="onFileDrop">
            <v-icon size="34" color="primary">mdi-file-upload-outline</v-icon>
            <div class="wf-template-drop-title">Bấm để chọn hoặc kéo file `.docx/.pdf` vào đây</div>
            <div class="wf-template-drop-sub">Hệ thống sẽ gọi API đọc placeholder từ template.</div>
            <div v-if="extractingPlaceholders" class="wf-template-drop-sub">Đang đọc placeholder...</div>
            <div v-else-if="uploadingTemplateFile" class="wf-template-drop-sub">Đang upload file vào
              FileData...</div>
            <div v-else-if="pickedFileName" class="wf-template-drop-sub">Đã chọn: {{ pickedFileName }}</div>
            <input ref="fileInput" type="file" accept=".docx,.pdf" style="display:none" @change="onFileSelected" />
          </div>
          <v-row dense class="wf-template-form">
            <v-col cols="12" md="8">
              <v-text-field v-model="quickTemplate.TemplateName" label="Tên template" variant="outlined"
                density="compact" />
            </v-col>
            <v-col cols="12" md="4">
              <v-select v-model="quickTemplate.FileType" :items="['docx', 'pdf']" label="Loại file" variant="outlined"
                density="compact" />
            </v-col>
            <v-col cols="12" md="6">
              <div class="d-flex align-center">
                <v-text-field v-model="quickTemplate.FileName" label="Tên file" variant="outlined" density="compact"
                  hide-details @update:model-value="onFileNameInput" class="flex-grow-1" />
                <v-btn v-if="quickTemplate.FileUrl" variant="outlined" color="primary" size="small"
                  class="ml-2 font-weight-bold" style="height: 40px;" @click="openTemplatePreview(quickTemplate)">
                  <v-icon start size="14">mdi-eye-outline</v-icon>Xem
                </v-btn>
              </div>
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="quickTemplate.FileUrl" label="Đường dẫn file" variant="outlined" density="compact"
                @update:model-value="onFileUrlInput" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="quickTemplate.Description" label="Mô tả" variant="outlined" density="compact"
                rows="3" auto-grow />
            </v-col>
          </v-row>
          <div class="wf-section-title">Placeholder dự kiến</div>
          <div class="d-flex flex-wrap ga-2">
            <span v-for="placeholder in quickTemplate.Placeholders" :key="placeholder" class="wf-ph-chip">
              <v-icon size="12">mdi-code-braces</v-icon>
              {{ placeholder }}
            </span>
            <div v-if="!quickTemplate.Placeholders || !quickTemplate.Placeholders.length"
              class="text-caption text-grey mt-2">
              Chưa phát hiện placeholder nào. Hãy tải file lên.
            </div>
          </div>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="showQuickTemplateDialog = false">Hủy</v-btn>
          <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSavingTemplate"
            :disabled="isSavingTemplate || extractingPlaceholders || uploadingTemplateFile" @click="saveQuickTemplate">
            <v-icon start>mdi-content-save-outline</v-icon>
            Lưu
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- File Preview Dialog -->
    <v-dialog v-model="showPreviewFileDialog" max-width="960" width="100%" persistent>
      <v-card class="d-flex flex-column" style="height: 80vh;">
        <v-card-title class="wf-template-dialog-title d-flex align-center py-3 px-4"
          style="background: #1b5e20; color: #ffffff;">
          <v-icon class="mr-2" color="white">{{ previewIconClass }}</v-icon>
          <span class="text-truncate flex-grow-1" style="font-size: 15px; font-weight: 600;">
            Xem trước: {{ previewFileName }}
          </span>
          <v-chip size="x-small" color="white" variant="outlined" class="ml-2 font-weight-bold">
            {{ String(previewFileType || '').toUpperCase() }}
          </v-chip>
          <v-btn icon="mdi-close" variant="text" color="white" class="ml-2" @click="showPreviewFileDialog = false"
            size="small"></v-btn>
        </v-card-title>

        <v-card-text class="pa-0 bg-grey-lighten-4 position-relative flex-grow-1 d-flex flex-column"
          style="overflow: hidden; height: 100%;">
          <!-- Loading Spinner -->
          <div v-if="loadingPreviewFile" class="position-absolute d-flex flex-column align-center justify-center"
            style="top: 0; left: 0; right: 0; bottom: 0; background: rgba(255, 255, 255, 0.9); z-index: 10; height: 100%;">
            <v-progress-circular indeterminate color="primary" size="48" width="4"></v-progress-circular>
            <div class="text-caption mt-2 font-weight-medium text-grey-darken-1">Đang chuẩn bị bản xem trước
              tài liệu...
            </div>
          </div>

          <!-- Local Docx Container -->
          <div v-if="previewFileType === 'docx'" id="wf-docx-preview-container"
            class="flex-grow-1 pa-4 overflow-y-auto bg-white" style="height: 100%; min-height: 450px;">
          </div>

          <!-- Document Preview Frame (PDF & Fallback iframe) -->
          <iframe v-else-if="previewIframeUrl" :src="previewIframeUrl" class="flex-grow-1"
            style="border: none; width: 100%; height: 100%; min-height: 450px;" @load="onPreviewIframeLoaded"></iframe>

          <!-- Fallback view when no URL is present -->
          <div v-else class="d-flex flex-column align-center justify-center pa-8 flex-grow-1 text-center"
            style="height: 100%;">
            <v-icon size="64" color="grey-lighten-1">mdi-file-alert-outline</v-icon>
            <div class="text-subtitle-1 font-weight-bold mt-3">Không thể tải bản xem trước</div>
            <div class="text-body-2 text-grey-darken-1 mt-1">Đường dẫn file không hợp lệ hoặc không có quyền
              truy cập.
            </div>
          </div>
        </v-card-text>

        <v-divider />
        <v-card-actions class="pa-3 px-4 bg-white">
          <v-btn variant="text" color="grey-darken-1" class="font-weight-bold" @click="showPreviewFileDialog = false">
            <v-icon start size="16">mdi-close</v-icon> Đóng
          </v-btn>
          <v-spacer />
          <v-btn variant="outlined" color="primary" class="wf-btn" @click="openPreviewInNewTab"
            :disabled="!rawPreviewFileUrl">
            <v-icon start size="16">mdi-open-in-new</v-icon> Xem tab mới
          </v-btn>
          <v-btn class="wf-btn" variant="outlined" color="primary" @click="downloadPreviewFile"
            :disabled="!rawPreviewFileUrl">
            <v-icon start size="16">mdi-download</v-icon> Tải xuống
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Hidden element for config dialog -->
    <uc-workflow-step-field-mapping ref="fieldMappingRef" v-if="activeStep" :active-step="activeStep" :fields="fields"
      :category-id="definition.CategoryID" :templates="templates" :field-type-options="fieldTypeOptions"
      :get-type-icon="getTypeIcon" @field-saved="saveDefinition" />
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
    return {
      definition: {
        DefinitionID: 0,
        Code: "",
        Name: "",
        Description: "",
        CategoryID: null,
        Version: 1,
        IsActive: false,
        OnRejectAction: "ADMIN_CHOOSE",
        NotifyEmail: false,
        NotifyOnComplete: false,
        AssignerID: "",
        Enable: true
      },
      steps: [],
      fields: [],
      categories: [],
      roles: [],
      templates: [],
      defTab: "steps",
      activeStepTab: "checklist",
      expandedSlots: {},
      activeStepIdx: 0,
      draggingStepIdx: null,
      dragOverIdx: null,
      dragPos: null,
      customFieldsSortableInstance: null,
      tplSortableInstances: [],
      defId: 1,
      isSaving: false,
      showAddRoleDialog: false,
      showQuickTemplateDialog: false,
      isSavingTemplate: false,
      extractingPlaceholders: false,
      uploadingTemplateFile: false,
      pickedFileName: "",
      pickedFileBase64: "",
      fileUrlTouchedByUser: false,
      autoGeneratedFileUrl: "",
      showPreviewFileDialog: false,
      previewFileName: "",
      previewFileType: "",
      previewIframeUrl: "",
      rawPreviewFileUrl: "",
      loadingPreviewFile: false,
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
      isSearchingEmployees: false,
      isSavingRole: false,
      employeeSearchText: "",
      employees: [],
      userSearchText: "",
      searchedUsers: [],
      isSearchingUsers: false,
      newRole: {
        RoleCode: "",
        RoleName: "",
        DefaultPersonID: ""
      },
      editingRuleIdx: null,
      editingTaskIdx: null,
      allDefinitions: [],
      stepTypeOptions: [
        { value: "INPUT_ONLY", label: "Nhập dữ liệu" },
        { value: "REVIEW", label: "Xem & duyệt" },
        { value: "SIGN", label: "Ký số" },
        { value: "ECONTRACT", label: "Hợp đồng lao động" }
      ],
      dueTypeOptions: [
        { value: "HOURS", label: "Theo giờ" },
        { value: "DAYS", label: "Theo ngày" },
        { value: "FIXED_DATE", label: "Ngày cố định (theo lịch)" },
        { value: "FIXED_DAY_OF_MONTH", label: "Cố định ngày hàng tháng" },
        { value: "FIXED_DAY_OF_WEEK", label: "Cố định ngày trong tuần" },
      ],
      weekDayOptions: [
        { value: "2", label: "Thứ Hai" },
        { value: "3", label: "Thứ Ba" },
        { value: "4", label: "Thứ Tư" },
        { value: "5", label: "Thứ Năm" },
        { value: "6", label: "Thứ Sáu" },
        { value: "7", label: "Thứ Bảy" },
        { value: "8", label: "Chủ Nhật" }
      ],
      signSystemOptions: [
        { value: "smartca", label: "VNPT SmartCA" },
        { value: "smartca_hsm", label: "SmartCA HSM" },
        { value: "otp_email", label: "OTP Email" },
        { value: "image", label: "Ký ảnh" }
      ],
      signerTypeOptions: [
        { value: "ROLE", label: "Theo Role" },
        { value: "SPECIFIC", label: "Người cụ thể" },
        { value: "FIELD_REF", label: "Từ dữ liệu" }
      ],
      signMethodOptions: [
        { value: "smartca", label: "SmartCA" },
        { value: "smartca_hsm", label: "SmartCA HSM" },
        { value: "otp_email", label: "OTP Email" },
        { value: "otp_sms", label: "OTP SMS" },
        { value: "image", label: "Ký ảnh" }
      ],
      fieldTypeOptions: [
        { title: "Văn bản ngắn", value: "text" },
        { title: "Văn bản dài", value: "textarea" },
        { title: "Số", value: "number" },
        { title: "Ngày tháng", value: "date" },
        { title: "Ngày giờ", value: "datetime" },
        { title: "Lựa chọn (Select)", value: "select" },
        { title: "Tệp đính kèm", value: "file" },
        { title: "Tệp đính kèm (Nhiều)", value: "files" },
        { title: "Hình ảnh", value: "image" },
        { title: "Thành viên", value: "user" },
        { title: "Chọn (Checkbox)", value: "checkbox" },
        { title: "Đánh giá", value: "rating" },
        { title: "Công thức", value: "computed" },
        { title: "Chữ ký", value: "signature" }
      ],
      eContractApiMap: {
        screen: "wf-admin-workflow-detail",
        authLogin: "/api/econtract/auth/login",
        templateList: "/econtract-saas-service/api/cau-hinh/bo-hsmau/dsach",
        templateDetail: "/econtract-saas-service/api/cau-hinh/bo-hsmau/chi-tiet/{boHSMauId}",
        flowList: "/econtract-saas-service/api/cau-hinh/luong-hd-gui/dsach",
        flowDetail: "/econtract-saas-service/api/cau-hinh/luong-hd-gui/chi-tiet/{luongId}",
        catalogList: "/econtract-saas-service/api/danh-muc/danhsach"
      }
    };
  },
  computed: {
    dueTypeLabel: function () {
      if (!this.activeStep) return 'Thời hạn';
      switch (this.activeStep.DueType) {
        case 'FIXED_DATE': return 'Chọn ngày thời hạn';
        case 'FIXED_DAY_OF_WEEK': return 'Chọn thứ trong tuần';
        case 'FIXED_DAY_OF_MONTH': return 'Ngày trong tháng';
        case 'DAYS': return 'Thời hạn (ngày)';
        default: return 'Thời hạn (giờ)';
      }
    },
    isCreateMode: function () {
      return Number(this.defId || 0) === 0;
    },
    displayDefinitionName: function () {
      var value = (this.definition.Name || "").trim();
      if (value) return value;
      if (this.isCreateMode) return "Tạo luồng mới";
      return "Workflow chưa có tên";
    },
    displayDefinitionMeta: function () {
      var code = (this.definition.Code || "").trim();
      var parts = [];
      if (code) parts.push(code);
      parts.push("v" + this.definition.Version);
      parts.push(this.steps.length + " bước");
      parts.push(this.fields.length + " trường dữ liệu");
      return parts.join(" · ");
    },
    activeStep: function () {
      return this.steps[this.activeStepIdx] || null;
    },
    groupedFields: function () {
      if (!this.activeStep || !this.fields) return []
      var selectedNames = this.activeStep.SelectedFieldNames || []

      var fieldsMap = {}
      this.fields.forEach(function (f) {
        fieldsMap[f.FieldName] = f
      })

      var groups = []
      var processedFieldNames = {}
      var self = this

      // Ensure slots logic works
      var slots = []
      if (this.activeStep.templates && this.activeStep.templates.length) {
        slots = this.activeStep.templates
      } else if (this.activeStep.TemplateID) {
        slots = [{ TemplateID: this.activeStep.TemplateID }]
      }

      slots.forEach(function (slot, index) {
        if (!slot.TemplateID) return
        var tpl = self.templates.find(function (t) { return Number(t.TemplateID) === Number(slot.TemplateID) })
        if (!tpl) return

        var groupFields = []
        var placeholders = tpl.Placeholders || []
        placeholders.forEach(function (ph) {
          if (selectedNames.indexOf(ph) !== -1 && fieldsMap[ph] && !processedFieldNames[ph]) {
            groupFields.push(fieldsMap[ph])
            processedFieldNames[ph] = true
          }
        })

        // Sort fields within this template based on their SortOrder in StepFields
        var stepFieldsMap = {}
        if (self.activeStep.StepFields) {
          self.activeStep.StepFields.forEach(function(sf) {
            stepFieldsMap[sf.FieldName] = sf.SortOrder || 0
          })
        }
        groupFields.sort(function(a, b) {
          return (stepFieldsMap[a.FieldName] || 0) - (stepFieldsMap[b.FieldName] || 0)
        })

        if (groupFields.length > 0) {
          groups.push({
            id: 'tpl_' + tpl.TemplateID + '_' + index,
            type: 'template',
            templateId: tpl.TemplateID,
            templateName: tpl.TemplateName || ('Biểu mẫu ' + (index + 1)),
            fields: groupFields
          })
        }
      })

      // Add custom fields (fields not in any template)
      var customFields = []
      selectedNames.forEach(function (name) {
        if (!processedFieldNames[name]) {
          if (fieldsMap[name]) {
            customFields.push(fieldsMap[name])
          } else {
            // Trường mồ côi: Tồn tại trong bước nhưng đã bị xóa khỏi cấu hình trường tùy chỉnh chung
            var sf = (self.activeStep.StepFields || []).find(function(item) { return item.FieldName === name; });
            customFields.push({
              FieldName: name,
              FieldLabel: name + ' (Đã bị xóa ở chung)',
              FieldType: 'text',
              IsRequired: sf ? !!sf.IsRequired : false,
              _isOrphan: true
            })
          }
        }
      })

      var stepFieldsMap2 = {}
      if (self.activeStep.StepFields) {
        self.activeStep.StepFields.forEach(function(sf) {
          stepFieldsMap2[sf.FieldName] = sf.SortOrder || 0
        })
      }
      customFields.sort(function(a, b) {
        return (stepFieldsMap2[a.FieldName] || 0) - (stepFieldsMap2[b.FieldName] || 0)
      })

      groups.push({
        id: 'custom_fields',
        type: 'custom',
        templateName: 'Trường ngoài mẫu văn bản',
        fields: customFields
      })

      return groups
    },
    customFieldsGroup: function () {
      return this.groupedFields.find(function (g) { return g.id === 'custom_fields' }) || null
    },
    activeTemplate: function () {
      var activeStep = this.activeStep;
      if (!activeStep || !activeStep.TemplateID) return null;
      return this.templates.filter(function (item) {
        return Number(item.TemplateID) === Number(activeStep.TemplateID);
      })[0] || null;
    },
    activeStepIsMultiTemplate: function () {
      return !!(this.activeStep && this.activeStep.templates !== null && this.activeStep.templates !== undefined);
    },
    activeStepDuplicatePlaceholders: function () {
      if (!this.activeStep || !this.activeStep.templates) return []
      var $this = this
      var phCount = {}
      this.activeStep.templates.forEach(function (slot) {
        var tpl = $this.getTemplateById(slot.TemplateID)
        if (!tpl || !tpl.Placeholders) return
        var uniquePhs = {}
        tpl.Placeholders.forEach(function (ph) {
          uniquePhs[ph] = true
        })
        Object.keys(uniquePhs).forEach(function (ph) {
          phCount[ph] = (phCount[ph] || 0) + 1
        })
      })
      return Object.keys(phCount).filter(function (ph) { return phCount[ph] > 1 })
    },
    isTerminalStep: function () {
      var step = this.activeStep
      return !!(step && (step.StepType === 'SUCCESS' || step.StepType === 'FAILURE'))
    },
    templateOptions: function () {
      return this.templates.map(function (item) {
        return { title: item.TemplateName, value: item.TemplateID };
      });
    },
    categoryOptions: function () {
      return this.categories.map(function (item) {
        return { title: item.Name, value: item.CategoryID };
      });
    },
    roleOptions: function () {
      return this.roles.map(function (item) {
        return { title: item.RoleName, value: item.RoleCode };
      });
    },
    sharedFieldOptions: function () {
      const list = this.fields.map(function (f) {
        return { title: f.FieldLabel, value: f.FieldName, type: "custom" };
      });
      // Tự động thêm các biến hệ thống phục vụ checklist
      list.push({ title: "Số việc CHƯA hoàn thành", value: "sys_PendingTasks", type: "checklist" });
      list.push({ title: "Số việc BẮT BUỘC chưa hoàn thành", value: "sys_PendingRequiredTasks", type: "checklist" });
      list.push({ title: "Tổng số việc", value: "sys_TotalTasks", type: "checklist" });

      // Thêm các việc con cụ thể của bước hiện tại (nếu có)
      if (this.activeStep && this.activeStep.Tasks) {
        this.activeStep.Tasks.forEach(function (t) {
          const key = "task_" + String(t.TaskName || '').toLowerCase().trim().replace(/ /g, '_').replace(/-/g, '_');
          list.push({ title: "Việc '" + t.TaskName + "'", value: key, type: "checklist" });
        });
      }
      return list;
    },
    employeeOptions: function () {
      return this.employees.map(function (item) {
        return { title: item.FullName + " (" + item.EmployeeCode + ")", value: item.EmployeeCode };
      });
    },
    assigneeOptions: function () {
      const $this = this;
      const options = this.roles.map(function (item) {
        let label = item.RoleName + " (" + item.RoleCode + ")";
        if (item.DefaultPersonName) {
          label = label + " - " + item.DefaultPersonName;
        }
        return { title: label, value: item.RoleCode };
      });
      // Gộp thêm người dùng tìm thấy động từ User
      (this.searchedUsers || []).forEach(function (u) {
        const val = u.EmployeeCode || u.Email || u.UserID;
        if (val && !options.find(function (o) { return o.value === val; })) {
          options.push({
            title: (u.FullName || u.UserName || val) + " (" + val + ")",
            value: val
          });
        }
      });
      if (this.activeStep && this.activeStep.AssigneeIDs) {
        this.activeStep.AssigneeIDs.forEach(function (id) {
          if (!options.find(function (o) { return o.value === id; })) {
            const existingRole = $this.roles.find(function (r) { return r.RoleCode === id; });
            if (existingRole) {
              let label = existingRole.RoleName + " (" + existingRole.RoleCode + ")";
              if (existingRole.DefaultPersonName) {
                label = label + " - " + existingRole.DefaultPersonName;
              }
              options.push({ title: label, value: id });
            } else {
              const existingAssignee = ($this.activeStep.assignees || []).find(function (a) { return (a.EmployeeCode || a.RoleCode) === id; });
              const title = existingAssignee ? (existingAssignee.FullName || existingAssignee.RoleName || id) : id;
              options.push({ title: title, value: id });
            }
          }
        });
      }
      // Gộp thêm Người gán luồng mặc định hiện tại để đảm bảo hiển thị đúng tên khi load lại
      if (this.definition && this.definition.AssignerID) {
        const id = this.definition.AssignerID;
        if (!options.find(function (o) { return o.value === id; })) {
          const title = this.definition.AssignerName ? (this.definition.AssignerName + " (" + id + ")") : id;
          options.push({ title: title, value: id });
        }
      }
      return options;
    },
    rejectOptions: function () {
      var options = [{ label: "Dùng mặc định của luồng", value: null }];
      this.steps.forEach(function (step, index) {
        options.push({ label: "Quay lại bước " + (index + 1) + " - " + step.StepName, value: index + 1 });
      });
      return options
    },
    previewIconClass: function () {
      return this.previewFileType === 'docx' ? 'mdi-file-word-box' : 'mdi-file-pdf-box'
    },
    tabList: function () {
      const stepsTab = { value: "steps", label: "Các bước", icon: "mdi-view-list-outline", count: this.steps.length };
      const fieldsTab = { value: "fields", label: "Trường tuỳ chỉnh", icon: "mdi-database-outline", count: this.fields.length };
      const settingsTab = { value: "settings", label: "Cài đặt", icon: "mdi-cog-outline" };

      if (this.isCreateMode) {
        return [settingsTab, stepsTab, fieldsTab];
      }
      return [stepsTab, fieldsTab, settingsTab];
    }
  },
  mounted: function () {
    if (typeof window !== "undefined") {
      window.__WF_ECONTRACT_SCREEN_MAP__ = window.__WF_ECONTRACT_SCREEN_MAP__ || {};
      window.__WF_ECONTRACT_SCREEN_MAP__["wf-admin-workflow-detail"] = this.eContractApiMap;
      window.addEventListener('keydown', this.handleGlobalKeydown);
    }
    this.initPage()
  },
  methods: {
    editFieldFromTemplate: function(field) {
      var $this = this;
      this.activeStepTab = 'fields';
      this.$nextTick(function() {
        if ($this.$refs.fieldMappingRef) {
          $this.$refs.fieldMappingRef.openConfigModal();
          $this.$refs.fieldMappingRef.openEditFieldForm(field);
        }
      });
    },
    clone: function (value) {
      return JSON.parse(JSON.stringify(value || null));
    },
    initPage: async function () {
      const $this = this
      const params = new URLSearchParams(window.location.search)
      const defId = Number(params.get("id") || $this.defId || 1)
      $this.defId = defId
      if (defId > 0) {
        await Promise.all([$this.loadDetail(defId), $this.loadRoles(), $this.loadUsers(), $this.loadTemplates(), $this.loadCategories(), $this.loadAllDefinitions()])
      } else {
        await Promise.all([$this.loadRoles(), $this.loadUsers(), $this.loadTemplates(), $this.loadCategories(), $this.loadAllDefinitions()])
        var createProjectId = Number(params.get("projectId") || 0)  // tạo workflow từ trong 1 Project
        $this.definition = {
          DefinitionID: 0, Code: "", Name: "", Description: "", CategoryID: null,
          ProjectID: createProjectId || null,
          Version: 1, IsActive: false, OnRejectAction: "ADMIN_CHOOSE",
          NotifyEmail: false, NotifyOnComplete: false, AssignerID: "", Enable: true
        }
        $this.steps = []
        $this.fields = []
        $this.addStep()
        $this.addTerminalSteps()
      }
      if ($this.isCreateMode) {
        $this.defTab = "settings"
      } else {
        $this.defTab = "steps"
      }
      $this.activeStepIdx = 0
      $this.$nextTick(function() {
        $this.initCustomFieldsSortable();
        $this.initTplSortable();
      });
    },
    loadDetail: async function (defId) {
      const $this = this
      if (!defId) return
      try {
        const data = await apiCallAsync("WF_Definition_GetDetail", { DefinitionID: defId })
        const definitionRows = data && data[0] ? data[0] : []
        const stepRows = data && data[1] ? data[1] : []
        const fieldRows = data && data[2] ? data[2] : []
        $this.definition = $this.normalizeDefinition(definitionRows[0] || $this.definition)
        $this.steps = stepRows.map(function (step) { return $this.normalizeStep(step) })
        $this.fields = (fieldRows || []).map(function (field, index) { return $this.normalizeField(field, index) })
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`)
        }
      }
    },
    loadAllDefinitions: async function () {
      const $this = this
      try {
        const data = await apiCallAsync("WF_Definition_GetList", { Status: 'ACTIVE' })
        $this.allDefinitions = Array.isArray(data) ? (Array.isArray(data[0]) ? data[0] : data) : []
      } catch (err) {
        console.error("Load all definitions error:", err)
      }
    },
    loadRoles: async function () {
      const $this = this
      try {
        const rows = await apiCallAsync("WF_RoleMapping_GetList")
        $this.roles = rows || []
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`)
        }
      }
    },
    loadUsers: async function () {
      const $this = this
      try {
        const rows = await apiCallAsync("WF_User_GetList", {})
        $this.searchedUsers = rows || []
      } catch (err) {
        console.error("Load users error:", err)
      }
    },
    loadTemplates: async function () {
      const $this = this
      try {
        const rows = await apiCallAsync("WF_Template_GetList")
        $this.templates = (rows || []).map(function (item) { return $this.normalizeTemplate(item) })
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`)
        }
      }
    },
    normalizeTemplate: function (item) {
      var template = this.clone(item || {});
      var placeholders = [];
      var source = template.PlaceholderJSON || template.Placeholders || template.MergeFields || null;
      if (Array.isArray(source)) placeholders = source;
      if (typeof source === "string" && source) {
        try {
          var parsed = JSON.parse(source);
          placeholders = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
          placeholders = source.split(",").map(function (s) { return s.trim(); }).filter(Boolean);
        }
      }
      template.Placeholders = placeholders;
      return template;
    },
    loadCategories: async function () {
      const $this = this
      try {
        const rows = await apiCallAsync("WF_Category_GetList")
        $this.categories = rows || []
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`)
        }
      }
    },
    normalizeStep: function (step) {
      var cloned = this.clone(step || {});
      cloned._id = cloned.StepID || Math.random().toString(36).substr(2, 9);
      cloned.StepOrder = Number(cloned.StepOrder || 0);
      cloned.TemplateID = cloned.TemplateID ? Number(cloned.TemplateID) : null;
      cloned.AutoTrigger = cloned.AutoTrigger === false ? false : true;
      cloned.IsRequired = cloned.IsRequired === false ? false : true;
      var dbVal = cloned.DueHours;
      var uiVal = cloned.NumDueHour;
      var rawDue = "";
      if (uiVal !== undefined && uiVal !== null) {
        if (uiVal === 0 && dbVal !== undefined && dbVal !== null && dbVal !== "") {
          rawDue = dbVal;
        } else {
          rawDue = uiVal;
        }
      } else {
        rawDue = dbVal !== undefined && dbVal !== null ? dbVal : "";
      }
      cloned.NumDueHour = (cloned.DueType === 'FIXED_DATE' || cloned.DueType === 'FIXED_DAY_OF_WEEK') ? (rawDue !== undefined && rawDue !== null ? String(rawDue) : "") : (isNaN(Number(rawDue)) ? 0 : Number(rawDue || 0));
      cloned.DueType = cloned.DueType || "HOURS";
      cloned.AssigneeID = cloned.AssigneeID || "";
      cloned.Description = cloned.Description || "";
      cloned.Enable = cloned.Enable !== false;
      if (cloned.SignersJSON && typeof cloned.SignersJSON === "string") {
        try { cloned.signers = JSON.parse(cloned.SignersJSON) || []; }
        catch (e) { cloned.signers = []; }
      } else if (Array.isArray(cloned.SignersJSON)) {
        cloned.signers = cloned.SignersJSON;
      } else if (cloned.Signers && Array.isArray(cloned.Signers)) {
        cloned.signers = cloned.Signers;
      } else {
        cloned.signers = cloned.signers || [];
      }
      if (cloned.ConditionJSON && typeof cloned.ConditionJSON === "string") {
        try {
          var cond = JSON.parse(cloned.ConditionJSON) || {};
          if (!cloned.SelectedFieldNames || !cloned.SelectedFieldNames.length) {
            cloned.SelectedFieldNames = cond.SelectedFieldNames || [];
          }
          var stepFields = cond.StepFields || [];
          if (!stepFields.length && cloned.SelectedFieldNames.length) {
            stepFields = cloned.SelectedFieldNames.map(function (name, idx) {
              var dbField = (this && this.fields || []).find(function(f) { return f.FieldName === name; });
              return {
                FieldName: name,
                SortOrder: idx + 1,
                IsRequired: dbField ? !!dbField.IsRequired : false
              };
            });
          }
          cloned.StepFields = stepFields;
          if (!cloned.AutomationRules || !cloned.AutomationRules.length) {
            cloned.AutomationRules = (cond.AutomationRules || []).map(function (rule) {
              if (rule.ConditionGroup && typeof rule.ConditionGroup === 'string') {
                try { rule.ConditionGroup = JSON.parse(rule.ConditionGroup); } catch (e) { }
              }
              return rule;
            });
          }
        } catch (e) {
          console.error("Error parsing ConditionJSON", e);
        }
      }
      cloned.SelectedFieldNames = cloned.SelectedFieldNames || [];
      cloned.StepFields = cloned.StepFields || [];
      cloned.AutomationRules = cloned.AutomationRules || [];
      if (cloned.TasksJSON) {
        try {
          var taskList = typeof cloned.TasksJSON === 'string' ? JSON.parse(cloned.TasksJSON) : cloned.TasksJSON
          cloned.Tasks = (taskList || []).map(function (t, idx) {
            return {
              _id: t._id || t.TaskID || Math.random().toString(36).substr(2, 9),
              TaskID: t.TaskID || null,
              TaskName: t.TaskName || "",
              Description: t.Description || "",
              IsRequired: t.IsRequired ? true : false,
              IsCompleted: t.IsCompleted ? true : false,
              IsLocked: t.IsLocked ? true : false,
              IsDeleted: t.IsDeleted ? true : false,
              DueHours: Number(t.DueHours || 0),
              FileIDList: t.FileIDList || "",
              ImageIDList: t.ImageIDList || "",
              SortOrder: t.SortOrder !== undefined && t.SortOrder !== null ? Number(t.SortOrder) : idx + 1
            }
          })
        } catch (e) {
          console.error("Error parsing TasksJSON", e)
        }
      }
      cloned.Tasks = cloned.Tasks || []
      if (cloned.AssigneesJSON && typeof cloned.AssigneesJSON === "string") {
        try {
          cloned.assignees = JSON.parse(cloned.AssigneesJSON) || [];
          cloned.AssigneeIDs = cloned.assignees.map(function (a) { return a.EmployeeCode || a.RoleCode });
        }
        catch (e) { cloned.assignees = []; cloned.AssigneeIDs = []; }
      } else if (Array.isArray(cloned.AssigneesJSON)) {
        cloned.assignees = cloned.AssigneesJSON;
        cloned.AssigneeIDs = cloned.assignees.map(function (a) { return a.EmployeeCode || a.RoleCode });
      } else {
        cloned.assignees = cloned.assignees || [];
        cloned.AssigneeIDs = cloned.AssigneeIDs || (cloned.AssigneeID ? [cloned.AssigneeID] : []);
      }
      cloned.signers = (cloned.signers || []).map(function (signer, index) {
        return {
          SignerOrder: Number(signer.SignerOrder || index + 1),
          SignerType: signer.SignerType || "ROLE",
          SignerValue: signer.SignerValue || "",
          SignMethod: signer.SignMethod || "smartca",
          IsSequential: signer.IsSequential === false ? false : true
        };
      });
      // [MULTI-TEMPLATE] Parse TemplatesJSON → cloned.templates
      var rawTemplatesJSON = cloned.TemplatesJSON;
      var templateSlots = [];
      if (rawTemplatesJSON) {
        if (typeof rawTemplatesJSON === 'string') {
          try { templateSlots = JSON.parse(rawTemplatesJSON) || []; } catch (e) { templateSlots = []; }
        } else if (Array.isArray(rawTemplatesJSON)) {
          templateSlots = rawTemplatesJSON;
        }
      }
      if (templateSlots.length === 0) {
        templateSlots.push({
          TemplateID: null,
          SignSystem: 'smartca',
          Signers: []
        });
      }
      cloned.templates = templateSlots.map(function (slot, idx) {
        return {
          SlotIdx: slot.SlotIdx !== undefined ? Number(slot.SlotIdx) : idx,
          Label: slot.Label || ('Template ' + (idx + 1)),
          TemplateID: slot.TemplateID ? Number(slot.TemplateID) : null,
          SignSystem: slot.SignSystem || 'smartca',
          Signers: (slot.Signers || []).map(function (s, si) {
            return {
              SignerOrder: Number(s.SignerOrder || si + 1),
              SignerType: s.SignerType || 'ROLE',
              SignerValue: s.SignerValue || '',
              SignMethod: s.SignMethod || 'smartca',
              IsSequential: s.IsSequential === false ? false : true
            };
          })
        };
      });
      delete cloned.TemplatesJSON;
      delete cloned.TasksJSON;
      delete cloned.SignersJSON;
      delete cloned.AssigneesJSON;
      delete cloned.ConditionJSON;
      return cloned;
    },
    normalizeDefinition: function (definition) {
      var item = this.clone(definition || {});
      return {
        DefinitionID: Number(item.DefinitionID || 0),
        Code: item.Code || "",
        Name: item.Name || "",
        Description: item.Description || "",
        CategoryID: item.CategoryID ? Number(item.CategoryID) : null,
        Version: Number(item.Version || 1),
        IsActive: item.IsActive ? true : false,
        OnRejectAction: item.OnRejectAction || "ADMIN_CHOOSE",
        NotifyEmail: item.NotifyEmail ? true : false,
        NotifyOnComplete: item.NotifyOnComplete ? true : false,
        AssignerID: item.AssignerID || "",
        AssignerName: item.AssignerName || "",
        Enable: item.Enable !== false
      };
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
    getSignerCount: function (step) {
      if (!step) return 0;
      if (!step.signers && step.Signers) step.signers = this.clone(step.Signers);
      if (!step.signers) return 0;
      return step.signers.length;
    },
    getSignerSummary: function (step) {
      if (!step) return "";
      var signers = step.signers || step.Signers || [];
      if (!signers.length) return "Chưa có người phụ trách";
      var $this = this;
      var labels = signers.map(function (s) {
        if (s.SignerType === 'ROLE') {
          var role = $this.roles.find(function (r) { return r.RoleCode === s.SignerValue; });
          return role ? role.RoleName : s.SignerValue;
        }
        if (s.SignerType === 'FIELD_REF') return "Từ field: " + s.SignerValue;
        return s.SignerValue || "...";
      });
      var text = labels.join(", ");
      if (text.length > 40) return text.substring(0, 37) + "...";
      return text;
    },
    getStepBadgeClass: function (step) {
      if (!step) return "wf-step-badge--sign";
      if (step.StepType === "SUCCESS") return "wf-step-badge--success";
      if (step.StepType === "FAILURE") return "wf-step-badge--failure";
      if (step.StepType === "ECONTRACT") return "wf-step-badge--contract";
      if (step.StepType === "REVIEW") return "wf-step-badge--review";
      if (step.StepType === "INPUT_ONLY") return "wf-step-badge--input";
      return "wf-step-badge--sign";
    },
    getStepTypeLabel: function (stepType) {
      var labels = { SIGN: "Ký số", ECONTRACT: "Hóa đơn điện tử", REVIEW: "Xem & duyệt", INPUT_ONLY: "Nhập dữ liệu", SUCCESS: "Thành công", FAILURE: "Thất bại" };
      return labels[stepType] || stepType;
    },
    goBack: function () { window.location.href = "/wf-admin-workflow-list"; },
    onSelectStep: function (idx) {
      this.activeStepIdx = idx
      var step = this.steps[idx]
      if (step && (step.StepType === 'SUCCESS' || step.StepType === 'FAILURE')) {
        this.activeStepTab = 'automation'
      }
    },
    addStep: function () {
      var insertIdx = this.steps.length
      for (var i = this.steps.length - 1; i >= 0; i--) {
        var t = this.steps[i].StepType
        if (t === 'SUCCESS' || t === 'FAILURE') { insertIdx = i } else { break }
      }
      var stepNumber = insertIdx + 1
      var newStep = {
        _id: Math.random().toString(36).substr(2, 9),
        StepOrder: stepNumber, StepCode: 'STEP_' + stepNumber,
        StepName: 'Bước mới ' + stepNumber, StepType: 'INPUT_ONLY',
        SignSystem: 'smartca', TemplateID: null, templates: null,
        Description: '',
        AutoTrigger: true, IsRequired: true, OnRejectGoToStep: null,
        NumDueHour: 0, DueType: 'HOURS', AssigneeID: '', Enable: true,
        signers: [], SelectedFieldNames: [], StepFields: [], Tasks: [], AutomationRules: []
      }
      this.steps.splice(insertIdx, 0, newStep)
      this.reindexSteps()
      this.activeStepIdx = insertIdx
    },
    addTerminalSteps: function () {
      this.steps.push({
        _id: Math.random().toString(36).substr(2, 9),
        StepOrder: this.steps.length + 1, StepCode: 'STEP_SUCCESS',
        StepName: 'Thành công', StepType: 'SUCCESS',
        Description: '',
        SignSystem: null, TemplateID: null, templates: null,
        AutoTrigger: false, IsRequired: false, OnRejectGoToStep: null,
        NumDueHour: 0, DueType: 'HOURS', AssigneeID: '', Enable: true,
        signers: [], SelectedFieldNames: [], StepFields: [], Tasks: [], AutomationRules: []
      })
      this.steps.push({
        _id: Math.random().toString(36).substr(2, 9),
        StepOrder: this.steps.length + 1, StepCode: 'STEP_FAILURE',
        StepName: 'Thất bại', StepType: 'FAILURE',
        Description: '',
        SignSystem: null, TemplateID: null, templates: null,
        AutoTrigger: false, OnRejectGoToStep: null,
        NumDueHour: 0, DueType: 'HOURS', AssigneeID: '', Enable: true,
        signers: [], SelectedFieldNames: [], StepFields: [], Tasks: [], AutomationRules: []
      })
      this.reindexSteps()
    },
    removeStep: function (stepIdx) {
      var step = this.steps[stepIdx]
      if (step && (step.StepType === 'SUCCESS' || step.StepType === 'FAILURE')) return
      this.steps.splice(stepIdx, 1);
      this.reindexSteps();
      if (this.activeStepIdx >= stepIdx) {
        this.activeStepIdx = Math.max(0, stepIdx - 1);
      }
    },
    addSigner: function () {
      if (!this.activeStep) return;
      if (!this.activeStep.signers && this.activeStep.Signers) this.activeStep.signers = this.clone(this.activeStep.Signers);
      if (!this.activeStep.signers) this.activeStep.signers = [];
      this.activeStep.signers.push({
        SignerOrder: this.activeStep.signers.length + 1,
        SignerType: "ROLE", SignerValue: "HIEU_TRUONG",
        SignMethod: "smartca", IsSequential: true
      });
      this.reindexSigners(this.activeStep);
    },
    removeSigner: function (signerIdx) {
      if (!this.activeStep) return;
      if (!this.activeStep.signers && this.activeStep.Signers) this.activeStep.signers = this.clone(this.activeStep.Signers);
      if (!this.activeStep.signers) this.activeStep.signers = [];
      this.activeStep.signers.splice(signerIdx, 1);
      this.reindexSigners(this.activeStep);
    },
    reindexSteps: function () {
      this.steps = this.steps.map(function (step, index) {
        step.StepOrder = index + 1;
        if (!step.StepCode) step.StepCode = "STEP_" + (index + 1);
        return step;
      });
    },
    onStepDragStart: function (event, index) {
      this.draggingStepIdx = index;
      if (event.dataTransfer) {
        event.dataTransfer.effectAllowed = "move";
        event.dataTransfer.setData("text/plain", index);
        setTimeout(() => { this.draggingStepIdx = index; }, 0);
      }
    },
    onEmployeeSearch: _.debounce(async function (val) {
      const $this = this
      if (!val || val.length < 2) return
      $this.isSearchingEmployees = true
      try {
        const rows = await apiCallAsync("WF_Employee_Search", { SearchText: val })
        $this.employees = rows || []
      } catch (err) {
        console.error("Search employee error:", err)
      } finally {
        $this.isSearchingEmployees = false
      }
    }, 500),
    onUserSearch: _.debounce(async function (val) {
      const $this = this
      if (!val || !val.trim()) {
        await $this.loadUsers()
        return
      }
      if (val.length < 2) return
      $this.isSearchingUsers = true
      try {
        const rows = await apiCallAsync("WF_User_GetList", { Keyword: val })
        $this.searchedUsers = rows || []
      } catch (err) {
        console.error("Search user profile error:", err)
      } finally {
        $this.isSearchingUsers = false
      }
    }, 500),
    reorderSteps: function ({ from, to, pos }) {
      if (from === to) return;
      var fromStep = this.steps[from]
      var toStep = this.steps[to]
      if (fromStep && (fromStep.StepType === 'SUCCESS' || fromStep.StepType === 'FAILURE')) return
      if (toStep && (toStep.StepType === 'SUCCESS' || toStep.StepType === 'FAILURE')) return
      let targetIdx = to;
      if (pos === 'bottom') targetIdx += 1;
      if (from < targetIdx) targetIdx -= 1;
      const draggedStep = this.steps[from];
      this.steps.splice(from, 1);
      this.steps.splice(targetIdx, 0, draggedStep);
      this.activeStepIdx = targetIdx;
      this.reindexSteps();
    },
    reindexSigners: function (step) {
      if (!step || !Array.isArray(step.signers)) return;
      step.signers = step.signers.map(function (signer, index) {
        signer.SignerOrder = index + 1;
        return signer;
      });
    },
    reindexFields: function () {
      this.fields = this.fields.map(function (field, index) {
        field.SortOrder = index + 1;
        return field;
      });
    },
    stepRequiresSigner: function (type) {
      return ["SIGN", "ECONTRACT"].includes(type);
    },
    openAddRoleDialog: function () {
      this.newRole = { RoleCode: "", RoleName: "", DefaultPersonID: "" };
      this.employees = [];
      this.showAddRoleDialog = true;
    },
    saveNewRole: async function () {
      if (!this.newRole.RoleCode || !this.newRole.RoleName) return;
      this.isSavingRole = true;
      try {
        const res = await apiCallAsync("WF_RoleMapping_Save", this.newRole);
        if (showToast && showToast.success) showToast.success("Thêm người quản lý thành công");
        await this.loadRoles();
        if (this.activeStep) {
          if (!this.activeStep.AssigneeIDs) this.activeStep.AssigneeIDs = [];
          this.activeStep.AssigneeIDs.push(this.newRole.RoleCode);
        }
        this.showAddRoleDialog = false;
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error(`${err.responseJSON ? err.responseJSON.Message : "Lỗi khi lưu vai trò"}`);
        }
      } finally {
        this.isSavingRole = false;
      }
    },
    stepRequiresTemplate: function (stepType) {
      return ["SIGN", "ECONTRACT", "REVIEW", "INPUT_ONLY"].includes(stepType);
    },
    validateDefinition: function () {
      var definition = this.normalizeDefinition(this.definition);
      if (!definition.Name.trim()) return "Tên luồng không được để trống.";
      if (!definition.Code.trim()) return "Mã luồng không được để trống.";
      // if (!definition.AssignerID || !definition.AssignerID.trim()) return "Người gán luồng mặc định (người chịu trách nhiệm luồng) không được để trống.";
      if (!this.steps.length) return "Workflow phải có ít nhất một bước.";
      for (var i = 0; i < this.steps.length; i++) {
        var step = this.steps[i];
        var stepName = (step.StepName || "").trim();
        var stepCode = (step.StepCode || "").trim();
        if (!stepName) return "Tên bước tại vị trí " + (i + 1) + " không được để trống.";
        if (!stepCode) return "Mã bước tại vị trí " + (i + 1) + " không được để trống.";
        var signers = step.signers || (step.SignersJSON ? (function () { try { return JSON.parse(step.SignersJSON) || [] } catch (e) { return [] } })() : []) || []
        var isSigningStep = ["SIGN", "ECONTRACT"].includes(step.StepType)
        // if (isSigningStep) {
        //   if (!signers.length) return "Bước \"" + stepName + "\" cần có ít nhất một người ký."
        // }
      }
      for (var fieldIdx = 0; fieldIdx < this.fields.length; fieldIdx++) {
        var field = this.fields[fieldIdx];
        if (!(field.FieldName || "").trim()) return "Field name tại dòng " + (fieldIdx + 1) + " không được để trống.";
        if (!(field.FieldLabel || "").trim()) return "Field label tại dòng " + (fieldIdx + 1) + " không được để trống.";
      }
      return "";
    },
    buildSavePayload: function () {
      var $this = this;
      var definition = this.normalizeDefinition(this.definition);
      var fieldStepMap = {};
      this.steps.forEach(function (step, stepIdx) {
        var stepOrder = stepIdx + 1;
        var selected = step.SelectedFieldNames || [];
        selected.forEach(function (fieldName) {
          if (!fieldStepMap[fieldName]) fieldStepMap[fieldName] = [];
          fieldStepMap[fieldName].push(stepOrder);
        });
      });
      return {
        Code: definition.Code.trim(),
        Name: definition.Name.trim(),
        Description: definition.Description ? String(definition.Description).trim() : "",
        CategoryID: definition.CategoryID,
        ProjectID: definition.ProjectID || null, // gắn project khi tạo từ trong project; sửa thì giữ nguyên (SP ISNULL)
        Version: definition.Version,
        IsActive: definition.IsActive,
        OnRejectAction: definition.OnRejectAction,
        NotifyEmail: definition.NotifyEmail,
        NotifyOnComplete: definition.NotifyOnComplete,
        AssignerID: definition.AssignerID || "",
        Steps: this.steps.map(function (step, index) {
          var normalizedStep = $this.normalizeStep(step);
          if ((!normalizedStep.signers || !normalizedStep.signers.length) && normalizedStep.AssigneeIDs && normalizedStep.AssigneeIDs.length) {
            var isSignStep = ["SIGN", "ECONTRACT"].includes(normalizedStep.StepType)
            normalizedStep.signers = normalizedStep.AssigneeIDs.map(function (id) {
              return {
                SignerType: "ROLE",
                SignerValue: id,
                SignMethod: isSignStep ? (normalizedStep.SignSystem || "smartca") : "none",
                SignerOrder: 1,
                IsSequential: true
              }
            })
          }
          $this.reindexSigners(normalizedStep);
          return {
            StepOrder: index + 1,
            StepCode: (normalizedStep.StepCode || "").trim(),
            StepName: (normalizedStep.StepName || "").trim(),
            StepType: normalizedStep.StepType || "SIGN",
            Description: (normalizedStep.Description || "").trim(),
            SignSystem: normalizedStep.SignSystem || null,
            TemplateID: !step.templates ? (normalizedStep.TemplateID ? Number(normalizedStep.TemplateID) : null) : null,
            TemplatesJSON: step.templates ? step.templates.filter(function(slot) { return !!slot.TemplateID; }).map(function (slot, sIdx) {
              return {
                SlotIdx: sIdx,
                Label: slot.Label || ('Template ' + (sIdx + 1)),
                TemplateID: slot.TemplateID ? Number(slot.TemplateID) : null,
                SignSystem: slot.SignSystem || null,
                Signers: (slot.Signers || []).map(function (s, si) {
                  return {
                    SignerOrder: si + 1,
                    SignerType: s.SignerType || 'ROLE',
                    SignerValue: s.SignerValue || '',
                    SignMethod: s.SignMethod || 'smartca',
                    IsSequential: s.IsSequential === false ? false : true
                  };
                })
              };
            }) : null,
            AutoTrigger: normalizedStep.AutoTrigger ? true : false,
            IsRequired: normalizedStep.IsRequired ? true : false,
            OnRejectGoToStep: normalizedStep.OnRejectGoToStep ? Number(normalizedStep.OnRejectGoToStep) : null,
            DueHours: (normalizedStep.DueType === 'FIXED_DATE' || normalizedStep.DueType === 'FIXED_DAY_OF_WEEK') ? (normalizedStep.NumDueHour || "") : (isNaN(Number(normalizedStep.NumDueHour)) ? 0 : Number(normalizedStep.NumDueHour || 0)),
            DueType: normalizedStep.DueType || "HOURS",
            AssigneeID: normalizedStep.AssigneeIDs && normalizedStep.AssigneeIDs.length ? normalizedStep.AssigneeIDs[0] : "",
            Assignees: (step.AssigneeIDs || []).map(function (id) {
              var isRole = $this.roles.some(function (r) { return r.RoleCode === id; });
              return { EmployeeCode: isRole ? "" : id, RoleCode: isRole ? id : "" };
            }),
            ConditionJSON: JSON.stringify({
              SelectedFieldNames: (step.StepFields || []).map(function (sf) { return sf.FieldName; }),
              StepFields: (step.StepFields || []).map(function (sf, idx) {
                return {
                  FieldName: sf.FieldName,
                  SortOrder: idx + 1,
                  IsRequired: !!sf.IsRequired
                };
              }),
              AutomationRules: (step.AutomationRules || []).map(function (r) {
                var rule = JSON.parse(JSON.stringify(r));
                if (rule.ConditionGroup && typeof rule.ConditionGroup === 'string') {
                  try { rule.ConditionGroup = JSON.parse(rule.ConditionGroup); } catch (e) {}
                }
                return rule;
              })
            }),
            Signers: !step.templates ? (normalizedStep.signers || []).map(function (signer, signerIdx) {
              return {
                SignerOrder: signerIdx + 1,
                SignerType: signer.SignerType || "ROLE",
                SignerValue: signer.SignerValue || "",
                SignMethod: signer.SignMethod || "smartca",
                IsSequential: signer.IsSequential === false ? false : true
              };
            }) : [],
            Tasks: (normalizedStep.Tasks || []).map(function (task) {
              return {
                TaskName: task.TaskName || "",
                Description: task.Description || "",
                IsCompleted: task.IsCompleted ? true : false,
                IsRequired: task.IsRequired ? true : false,
                IsLocked: task.IsLocked ? true : false,
                IsDeleted: task.IsDeleted ? true : false,
                FileIDList: task.FileIDList || "",
                ImageIDList: task.ImageIDList || "",
                DueHours: 0
              }
            }),
            TasksJSON: JSON.stringify((step.Tasks || []).map(function (t, tIdx) {
              return {
                TaskID: t.TaskID || null,
                TaskName: t.TaskName || "",
                Description: t.Description || "",
                IsRequired: t.IsRequired ? true : false,
                IsCompleted: t.IsCompleted ? true : false,
                IsLocked: t.IsLocked ? true : false,
                IsDeleted: t.IsDeleted ? true : false,
                DueHours: Number(t.DueHours || 0),
                FileIDList: t.FileIDList || "",
                ImageIDList: t.ImageIDList || "",
                SortOrder: tIdx + 1
              }
            }))
          };
        }),
        Fields: this.fields.map(function (field, index) {
          var normalized = $this.normalizeField(field, index)
          var stepList = fieldStepMap[field.FieldName] || []
          return {
            FieldName: normalized.FieldName,
            FieldLabel: normalized.FieldLabel,
            FieldType: normalized.FieldType,
            FieldOptions: normalized.FieldOptions,
            InputAtStep: stepList.join(","),
            IsRequired: normalized.IsRequired,
            DefaultValue: normalized.DefaultValue,
            SortOrder: normalized.SortOrder
          }
        })
      };
    },
    goToSignFlow: function () {
      window.location.href = '/wf-user-request-detail?id=' + this.instanceId
    },
    saveDefinition: function () {
      var $this = this;
      var validateMessage = this.validateDefinition();
      if (validateMessage) {
        if (showToast && showToast.error) showToast.error(validateMessage);
        return;
      }
      var payload = this.buildSavePayload();
      var params = Object.assign({ DefinitionID: Number(this.defId || this.definition.DefinitionID ||  0) }, payload);
      this.isSaving = true;
      var currentActiveStepIdx = this.activeStepIdx;
      apiCall(
        "WF_Definition_Save", params,
        function (res) {
          var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null;
          var savedId = row && row.DefinitionID ? Number(row.DefinitionID) : Number($this.definition.DefinitionID || $this.defId || 0);
          if (showToast && showToast.success) {
            showToast.success(row && row.Message ? row.Message : "Lưu quy trình thành công.");
          }
          if (savedId && !$this.definition.DefinitionID) {
            window.location.href = "/wf-admin-workflow-detail?id=" + savedId;
            return;
          }
          $this.definition.DefinitionID = savedId;
          $this.defId = savedId;
          $this.loadDetail(savedId).then(function () {
            $this.activeStepIdx = currentActiveStepIdx;
            $this.isSaving = false;
          }).catch(function () {
            $this.isSaving = false;
          });
        },
        function (err) {
          if (showToast && showToast.error) {
            showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`);
          }
          $this.isSaving = false;
        }
      );
    },
    handleGlobalKeydown: function (event) {
      if ((event.ctrlKey || event.metaKey) && String(event.key).toLowerCase() === 's') {
        event.preventDefault();
        this.saveDefinition();
      }
    },
    cloneCurrentDefinition: function () {
      var $this = this;
      if (this.isCreateMode || !this.definition.DefinitionID) return;
      showConfirm(
        'Tạo bản sao quy trình "' + (this.definition.Name || this.definition.Code || "") + '"?',
        function () {
          apiCall(
            "WF_Definition_Clone", { DefinitionID: Number($this.definition.DefinitionID) },
            function (res) {
              var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null;
              if (showToast && showToast.success) {
                showToast.success(row && row.Message ? row.Message : "Tạo bản sao quy trình thành công.");
              }
              window.location.href = "/wf-admin-workflow-list";
            },
            function (err) {
              if (showToast && showToast.error) {
                showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`);
              }
            }
          );
        }
      );
    },
    previewCurrentDefinition: function () {
      if (this.isCreateMode) return;
      window.location.href = "/wf-user-request-create?definitionId=" + Number(this.definition.DefinitionID || this.defId || 0);
    },
    detectFileType: function (fileName) {
      if (!fileName) return "docx";
      var ext = String(fileName).split('.').pop().toLowerCase();
      return ext === "pdf" ? "pdf" : "docx";
    },
    openTemplatePreview: function (template) {
      if (!template) return;
      var fileUrl = String(template.FileUrl || "").trim();
      if (!fileUrl) {
        if (showToast && showToast.error) {
          showToast.error("Template chưa có FileUrl để xem nhanh.");
        }
        return;
      }
      var fullUrl = fileUrl;
      var isAbsolute = fileUrl.toLowerCase().indexOf("http://") === 0 || fileUrl.toLowerCase().indexOf("https://") === 0;
      if (!isAbsolute) {
        var baseDomain = "https://file.zentea.vn/iotdev/";
        var cleanPath = fileUrl.indexOf("/") === 0 ? fileUrl.substring(1) : fileUrl;
        fullUrl = baseDomain + cleanPath;
      }
      var fileName = String(template.FileName || template.TemplateName || "Document").trim();
      var fileType = String(template.FileType || this.detectFileType(fileName)).toLowerCase();
      this.previewFileName = fileName;
      this.previewFileType = fileType;
      this.rawPreviewFileUrl = fullUrl;
      this.loadingPreviewFile = true;
      this.showPreviewFileDialog = true;
      this.previewIframeUrl = "";
      var $this = this;
      if (fileType === "docx") {
        this.$nextTick(function () {
          $this.renderLocalDocx(fullUrl);
        });
      } else {
        this.previewIframeUrl = fullUrl;
      }
    },
    renderLocalDocx: function (url) {
      var $this = this;
      var container = document.getElementById("wf-docx-preview-container");
      if (container) {
        container.innerHTML = "";
      }

      var fallbackToIframe = function () {
        var docxUrl = url;
        if (docxUrl.indexOf("?") === -1) {
          docxUrl += "?ext=.docx";
        } else {
          docxUrl += "&ext=.docx";
        }
        $this.previewIframeUrl = "https://view.officeapps.live.com/op/embed.aspx?src=" + encodeURIComponent(docxUrl);
        $this.previewFileType = "docx-iframe";
        $this.loadingPreviewFile = false;
      };

      var startRendering = function () {
        var headers = {};
        if (typeof $awt !== "undefined" && $awt) {
          headers["Authorization"] = $awt;
        }
        fetch(url, { headers: headers })
          .then(function (res) {
            if (!res.ok) throw new Error("Status " + res.status);
            return res.arrayBuffer();
          })
          .then(function (arrayBuffer) {
            if (window.docx && window.docx.renderAsync) {
              return window.docx.renderAsync(arrayBuffer, container, null, {
                className: "docx",
                inWrapper: false
              });
            } else {
              throw new Error("Docx renderer not loaded");
            }
          })
          .then(function () {
            $this.loadingPreviewFile = false;
          })
          .catch(function (err) {
            console.error("Local docx render error", err);
            fallbackToIframe();
          });
      };

      var loadJsZip = function (callback) {
        if (typeof window.JSZip !== "undefined") {
          callback();
          return;
        }
        var script = document.createElement("script");
        script.src = "https://unpkg.com/jszip@3.10.1/dist/jszip.min.js";
        script.onload = function () {
          callback();
        };
        script.onerror = function () {
          fallbackToIframe();
        };
        document.head.appendChild(script);
      };

      var loadDocxPreview = function (callback) {
        if (typeof window.docx !== "undefined") {
          callback();
          return;
        }
        var script = document.createElement("script");
        script.src = "https://unpkg.com/docx-preview@0.1.15/dist/docx-preview.js";
        script.onload = function () {
          callback();
        };
        script.onerror = function () {
          fallbackToIframe();
        };
        document.head.appendChild(script);
      };

      loadJsZip(function () {
        loadDocxPreview(function () {
          startRendering();
        });
      });
    },
    onPreviewIframeLoaded: function () {
      this.loadingPreviewFile = false;
    },
    openPreviewInNewTab: function () {
      if (this.rawPreviewFileUrl) {
        window.open(this.rawPreviewFileUrl, "_blank");
      }
    },
    downloadPreviewFile: function () {
      if (!this.rawPreviewFileUrl) return;
      var link = document.createElement("a");
      link.href = this.rawPreviewFileUrl;
      link.setAttribute("download", this.previewFileName || "document");
      link.style.display = "none";
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    },
    isPlaceholderInFields: function (ph) {
      if (!this.activeStep || !this.activeStep.SelectedFieldNames) return false
      return this.activeStep.SelectedFieldNames.indexOf(ph) !== -1
    },
    togglePlaceholder: function (ph) {
      if (!this.activeStep) return
      if (!this.activeStep.SelectedFieldNames) this.activeStep.SelectedFieldNames = []
      if (!this.activeStep.StepFields) this.activeStep.StepFields = []

      var idx = this.activeStep.SelectedFieldNames.indexOf(ph)
      if (idx !== -1) {
        this.activeStep.SelectedFieldNames.splice(idx, 1)
        var sfIdx = this.activeStep.StepFields.findIndex(function(f) { return f.FieldName === ph; })
        if (sfIdx !== -1) {
          this.activeStep.StepFields.splice(sfIdx, 1)
          this.activeStep.StepFields.forEach(function (f, i) { f.SortOrder = i + 1; })
        }
        if (showToast && showToast.info) showToast.info("Đã bỏ gán trường '" + ph + "' khỏi bước này.")
      } else {
        var exists = this.fields.some(function (f) { return f.FieldName === ph })
        var dbField = null
        if (!exists) {
          dbField = {
            MappingID: 0, FieldName: ph, FieldLabel: ph, FieldType: 'text', FieldOptions: '',
            InputAtStep: '', IsRequired: false, DefaultValue: '', SortOrder: this.fields.length + 1, Enable: true
          }
          this.fields.push(dbField)
          this.reindexFields()
        } else {
          dbField = this.fields.find(function(f) { return f.FieldName === ph; })
        }
        this.activeStep.SelectedFieldNames.push(ph)
        this.activeStep.StepFields.push({
          FieldName: ph,
          SortOrder: this.activeStep.StepFields.length + 1,
          IsRequired: dbField ? !!dbField.IsRequired : false
        })
        if (showToast && showToast.success) showToast.success("Đã gán trường '" + ph + "' vào bước này.")
      }
    },
    recoverOrphanField: function (fieldName) {
      var exists = this.fields.some(function (f) { return f.FieldName === fieldName });
      if (!exists) {
        var dbField = {
          MappingID: 0,
          FieldName: fieldName,
          FieldLabel: fieldName,
          FieldType: 'text',
          FieldOptions: '',
          InputAtStep: '',
          IsRequired: false,
          DefaultValue: '',
          SortOrder: this.fields.length + 1,
          Enable: true
        };
        this.fields.push(dbField);
        this.reindexFields();
        if (showToast && showToast.success) {
          showToast.success("Đã khôi phục trường '" + fieldName + "' vào danh mục chung thành công.");
        }
      }
    },
    unlinkedPlaceholderCount: function (template) {
      if (!template || !template.Placeholders) return 0
      var $this = this
      return template.Placeholders.filter(function (ph) { return !$this.isPlaceholderInFields(ph) }).length
    },
    slotLinkedFields: function (slot) {
      var tpl = this.getTemplateById(slot.TemplateID)
      if (!tpl || !tpl.Placeholders) return []
      var $this = this
      return tpl.Placeholders.filter(function (ph) { return $this.isPlaceholderInFields(ph) })
    },
    slotLinkedFieldsSorted: function (slot) {
      var linked = this.slotLinkedFields(slot)
      var dups = this.activeStepDuplicatePlaceholders
      var dupSet = {}
      dups.forEach(function (ph) { dupSet[ph] = true })
      return linked.slice().sort(function (a, b) {
        var ad = dupSet[a] ? 0 : 1
        var bd = dupSet[b] ? 0 : 1
        return ad - bd
      })
    },
    getFieldByName: function (name) {
      return this.fields.find(function (f) { return f.FieldName === name }) || null
    },
    slotAttentionFields: function (slot) {
      var tpl = this.getTemplateById(slot.TemplateID)
      if (!tpl || !tpl.Placeholders) return []
      var $this = this
      var list = []
      tpl.Placeholders.forEach(function (ph) {
        var isLinked = $this.isPlaceholderInFields(ph)
        var isDup = $this.activeStepDuplicatePlaceholders.indexOf(ph) !== -1
        if (!isLinked) {
          list.push({ name: ph, type: 'unassigned' })
        } else if (isDup) {
          list.push({ name: ph, type: 'duplicate' })
        }
      })
      return list
    },
    getTypeIcon: function (type) {
      var map = {
        text: 'mdi-text-short', number: 'mdi-numeric', date: 'mdi-calendar',
        textarea: 'mdi-text-long', select: 'mdi-form-select', file: 'mdi-file-outline',
        files: 'mdi-file-multiple-outline', image: 'mdi-image-outline', user: 'mdi-account-outline',
        checkbox: 'mdi-checkbox-marked-outline', rating: 'mdi-star-outline',
        computed: 'mdi-calculator-variant', signature: 'mdi-draw', datetime: 'mdi-calendar-clock'
      }
      return map[type] || 'mdi-help-circle-outline'
    },
    getFieldTypeLabel: function (type) {
      if (!type) return '—'
      var opt = this.fieldTypeOptions.find(function (o) { return o.value === type })
      return opt ? opt.title : type
    },
    toggleSlotExpand: function (slotIdx) {
      var key = String(slotIdx)
      var val = !!this.expandedSlots[key]
      this.$set ? this.$set(this.expandedSlots, key, !val) : (this.expandedSlots = Object.assign({}, this.expandedSlots, { [key]: !val }))
      this.initTplSortable();
    },
    isSlotExpanded: function (slotIdx) {
      return !!this.expandedSlots[String(slotIdx)]
    },
    onTemplateSelect: function (templateId) {
      if (!templateId) return
      var template = this.templates.find(function (t) { return Number(t.TemplateID) === Number(templateId) })
      if (!template || !template.Placeholders || !template.Placeholders.length) return
      var $this = this
      var unlinked = template.Placeholders.filter(function (ph) { return !$this.isPlaceholderInFields(ph) }).length
      if (unlinked > 0 && showToast && showToast.info) {
        showToast.info('Template có ' + unlinked + ' placeholder chưa liên kết. Bấm "Thêm ngay" để thêm vào trường dữ liệu tuỳ chỉnh dùng chung.')
      }
    },
    importPlaceholdersFromTemplate: async function (template) {
      if (!template || !template.Placeholders || !template.Placeholders.length) return
      var $this = this
      var added = 0
      var catId = Number(this.definition.CategoryID || 0)
      if (!catId) {
        if (showToast && showToast.error) showToast.error("Luồng chưa được cấu hình Nhóm luồng công việc — không thể lưu trường.")
        return
      }
      if (!$this.activeStep.SelectedFieldNames) $this.activeStep.SelectedFieldNames = []
      if (!$this.activeStep.StepFields) $this.activeStep.StepFields = []

      var pendingFields = []
      template.Placeholders.forEach(function (ph) {
        var exists = $this.fields.some(function (f) { return f.FieldName === ph })
        if (!exists) {
          var fieldToPush = {
            MappingID: 0, FieldName: ph, FieldLabel: ph, FieldType: 'text', FieldOptions: '',
            InputAtStep: '', IsRequired: false, DefaultValue: '', SortOrder: $this.fields.length + 1,
            Enable: true, _isNewFromTemplate: true
          }
          $this.fields.push(fieldToPush)
          pendingFields.push(fieldToPush)
          added++
        }
        if ($this.activeStep.SelectedFieldNames.indexOf(ph) === -1) {
          $this.activeStep.SelectedFieldNames.push(ph)
        }
        var sfExists = $this.activeStep.StepFields.some(function (sf) { return sf.FieldName === ph })
        if (!sfExists) {
          $this.activeStep.StepFields.push({
            FieldName: ph,
            SortOrder: $this.activeStep.StepFields.length + 1,
            IsRequired: false
          })
        }
      })
      this.reindexFields()
    },
    loadTargetSteps: async function (definitionId) {
      if (!definitionId) { this.targetSteps = []; return; }
      try {
        const data = await apiCallAsync("WF_StepDefinition_GetList", { DefinitionID: definitionId });
        const stepRows = Array.isArray(data) ? (Array.isArray(data[0]) ? data[0] : data) : [];
        this.targetSteps = stepRows.map(function (s) { return { label: s.StepName, value: s.StepDefID }; });
      } catch (err) {
        console.error("Load target steps error:", err);
        this.targetSteps = [];
      }
    },
    openQuickCreateTemplateDialog: function () {
      this.quickTemplate = this.getEmptyQuickTemplate();
      this.pickedFileName = "";
      this.pickedFileBase64 = "";
      this.fileUrlTouchedByUser = false;
      this.autoGeneratedFileUrl = "";
      this.showQuickTemplateDialog = true;
    },
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
      else if (payload && payload.Result) row = payload.Result;
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
    // [MULTI-TEMPLATE] Chuyển bước hiện tại sang chế độ nhiều template
    enableMultiTemplateMode: function () {
      if (!this.activeStep) return;
      var step = this.activeStep;
      var templateName = 'Template 1';
      if (step.TemplateID && this.templates) {
        var foundTemplate = this.templates.find(function(t) { return Number(t.TemplateID) === Number(step.TemplateID); });
        if (foundTemplate && foundTemplate.TemplateName) {
          templateName = foundTemplate.TemplateName;
        }
      }
      var firstSlot = {
        SlotIdx: 0,
        Label: templateName,
        TemplateID: step.TemplateID || null,
        SignSystem: step.SignSystem || 'smartca',
        Signers: (step.signers || []).map(function (s, i) {
          return {
            SignerOrder: i + 1,
            SignerType: s.SignerType || 'ROLE',
            SignerValue: s.SignerValue || '',
            SignMethod: s.SignMethod || 'smartca',
            IsSequential: s.IsSequential === false ? false : true
          };
        })
      };
      step.templates = [firstSlot];
    },
    // [MULTI-TEMPLATE] Về lại chế độ một template
    disableMultiTemplateMode: function () {
      if (!this.activeStep) return;
      var step = this.activeStep;
      var firstSlot = step.templates && step.templates[0];
      if (firstSlot) {
        step.TemplateID = firstSlot.TemplateID || null;
        step.SignSystem = firstSlot.SignSystem || step.SignSystem || 'smartca';
        step.signers = (firstSlot.Signers || []).map(function (s, i) {
          return {
            SignerOrder: i + 1,
            SignerType: s.SignerType || 'ROLE',
            SignerValue: s.SignerValue || '',
            SignMethod: s.SignMethod || 'smartca',
            IsSequential: s.IsSequential === false ? false : true
          };
        });
      }
      step.templates = null;
    },
    addTemplateSlot: function () {
      if (!this.activeStep || !this.activeStep.templates) return;
      var idx = this.activeStep.templates.length;
      this.activeStep.templates.push({
        SlotIdx: idx,
        Label: 'Template ' + (idx + 1),
        TemplateID: null,
        SignSystem: this.activeStep.SignSystem || 'smartca',
        Signers: []
      });
    },
    removeTemplateSlot: function (slotIdx) {
      if (!this.activeStep || !this.activeStep.templates) return;
      this.activeStep.templates.splice(slotIdx, 1);
    },
    moveTemplateSlot: function (slotIdx, direction) {
      if (!this.activeStep || !this.activeStep.templates) return;
      var targetIdx = slotIdx + direction;
      if (targetIdx < 0 || targetIdx >= this.activeStep.templates.length) return;
      var slots = this.activeStep.templates;
      var currentSlot = slots[slotIdx];
      // Swap slots
      slots.splice(slotIdx, 1);
      slots.splice(targetIdx, 0, currentSlot);
      // Update SlotIdx
      slots.forEach(function (slot, idx) {
        slot.SlotIdx = idx;
      });

      // Synchronously sync field SortOrders to match the new templates order
      if (this.activeStep.StepFields) {
        var stepFields = this.activeStep.StepFields
        var newFlattenedNames = []
        this.groupedFields.forEach(function (group) {
          group.fields.forEach(function (f) {
            newFlattenedNames.push(f.FieldName)
          })
        })
        stepFields.sort(function (a, b) {
          var idxA = newFlattenedNames.indexOf(a.FieldName)
          var idxB = newFlattenedNames.indexOf(b.FieldName)
          if (idxA === -1) idxA = 9999
          if (idxB === -1) idxB = 9999
          return idxA - idxB
        })
        stepFields.forEach(function (f, idx) {
          f.SortOrder = idx + 1
        })
      }
    },
    slotGroupFields: function (slot, slotIdx) {
      var groupId = 'tpl_' + slot.TemplateID + '_' + slotIdx
      var group = this.groupedFields.find(function (g) { return g.id === groupId })
      return group ? group.fields : []
    },
    initCustomFieldsSortable: function () {
      var self = this;
      if (self.customFieldsSortableInstance) {
        self.customFieldsSortableInstance.destroy();
        self.customFieldsSortableInstance = null;
      }
      self.$nextTick(function () {
        var container = self.$refs.customFieldsSortable;
        if (!container) return;
        self.customFieldsSortableInstance = Sortable.create(container, {
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

            var listElement = evt.from;
            var items = listElement.querySelectorAll('.wf-cfd-list-row');
            var newGroupNames = Array.from(items).map(function(item) {
              return item.getAttribute('data-field-name');
            }).filter(Boolean);

            var newFlattenedNames = [];
            self.groupedFields.forEach(function (group) {
              if (group.id === 'custom_fields') {
                newGroupNames.forEach(function(name) { newFlattenedNames.push(name); });
              } else {
                group.fields.forEach(function(f) { newFlattenedNames.push(f.FieldName); });
              }
            });

            stepFields.sort(function (a, b) {
              var idxA = newFlattenedNames.indexOf(a.FieldName);
              var idxB = newFlattenedNames.indexOf(b.FieldName);
              if (idxA === -1) idxA = 9999;
              if (idxB === -1) idxB = 9999;
              return idxA - idxB;
            });

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
    destroyCustomFieldsSortable: function () {
      if (this.customFieldsSortableInstance) {
        this.customFieldsSortableInstance.destroy();
        this.customFieldsSortableInstance = null;
      }
    },
    initTplSortable: function () {
      var self = this;
      self.destroyTplSortable();
      self.$nextTick(function () {
        if (!self.activeStep || !self.activeStep.templates || self.activeStep.templates.length === 0) return;
        
        self.activeStep.templates.forEach(function (slot, slotIdx) {
          var tplId = slot.TemplateID;
          var refName = 'tplSortable_' + slotIdx;
          var containerArray = self.$refs[refName];
          var container = containerArray && containerArray.length ? containerArray[0] : containerArray;
          
          if (!container) return;
          
          var instance = Sortable.create(container, {
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

              var movedFieldName = evt.item.getAttribute('data-field-name');
              if (!movedFieldName) return;

              // The slot group fields might be a subset of StepFields, so we need to be careful when moving.
              // To safely move, we can do the exact same thing as customFields: finding the target field and its index in the entire StepFields array.
              var fromIdx = stepFields.findIndex(function (f) { return f.FieldName === movedFieldName; });
              if (fromIdx === -1) return;
              
              // We need the flattened new order like we did before.
              // Wait, it's easier to just find the new position in the local list, then re-sort stepFields based on all groups.
              var listElement = evt.from;
              var items = listElement.querySelectorAll('.wf-cfd-list-row');
              var newGroupNames = Array.from(items).map(function(item) {
                return item.getAttribute('data-field-name');
              }).filter(Boolean);

              // Rebuild full new flattened names
              var newFlattenedNames = [];
              self.groupedFields.forEach(function (group) {
                if (group.id === 'custom_fields') {
                  group.fields.forEach(function(f) { newFlattenedNames.push(f.FieldName); });
                } else if (group.id === 'tpl_' + tplId + '_' + slotIdx) {
                  // For the moved group, use the DOM order
                  newGroupNames.forEach(function(name) { newFlattenedNames.push(name); });
                } else {
                  group.fields.forEach(function(f) { newFlattenedNames.push(f.FieldName); });
                }
              });

              // Sort the stepFields array synchronously using the new order
              stepFields.sort(function (a, b) {
                var idxA = newFlattenedNames.indexOf(a.FieldName);
                var idxB = newFlattenedNames.indexOf(b.FieldName);
                if (idxA === -1) idxA = 9999;
                if (idxB === -1) idxB = 9999;
                return idxA - idxB;
              });

              // Re-assign SortOrder sequentially
              stepFields.forEach(function (f, idx) {
                f.SortOrder = idx + 1;
              });

              self.activeStep.SelectedFieldNames = stepFields.map(function (sf) { return sf.FieldName; });

              if (showToast && showToast.success) {
                showToast.success("Đã thay đổi thứ tự trường dữ liệu trong bước.");
              }
            }
          });
          self.tplSortableInstances.push(instance);
        });
      });
    },
    destroyTplSortable: function () {
      if (this.tplSortableInstances && this.tplSortableInstances.length > 0) {
        this.tplSortableInstances.forEach(function (instance) {
          if (instance) instance.destroy();
        });
        this.tplSortableInstances = [];
      }
    },
    moveFieldOrder: function (field, direction, groupId) {
      if (!this.activeStep || !this.activeStep.StepFields) return
      var stepFields = this.activeStep.StepFields
      var group = this.groupedFields.find(function (g) { return g.id === groupId })
      if (!group) return

      var fieldsInGroup = group.fields
      var fromIdx = fieldsInGroup.findIndex(function (f) { return f.FieldName === field.FieldName })
      if (fromIdx === -1) return

      var toIdx = fromIdx + direction
      if (toIdx < 0 || toIdx >= fieldsInGroup.length) return

      var draggedFieldName = field.FieldName
      var targetFieldName = fieldsInGroup[toIdx].FieldName

      var newFlattenedNames = []
      this.groupedFields.forEach(function (g) {
        var groupNames = g.fields.map(function (f) { return f.FieldName })
        if (g.id === groupId) {
          var item = groupNames[fromIdx]
          groupNames.splice(fromIdx, 1)
          groupNames.splice(toIdx, 0, item)
        }
        groupNames.forEach(function (name) {
          newFlattenedNames.push(name)
        })
      })

      stepFields.sort(function (a, b) {
        var idxA = newFlattenedNames.indexOf(a.FieldName)
        var idxB = newFlattenedNames.indexOf(b.FieldName)
        if (idxA === -1) idxA = 9999
        if (idxB === -1) idxB = 9999
        return idxA - idxB
      })

      stepFields.forEach(function (f, idx) {
        f.SortOrder = idx + 1
      })

      this.activeStep.SelectedFieldNames = stepFields.map(function (sf) { return sf.FieldName; })
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
    isFieldRequiredInStep: function (fieldName) {
      if (!this.activeStep || !this.activeStep.StepFields) return false
      var sf = this.activeStep.StepFields.find(function(f) { return f.FieldName === fieldName; })
      return sf ? sf.IsRequired === true : false
    },
    openConfigModal: function () {
      var $this = this;
      this.$nextTick(function() {
        if ($this.$refs.fieldMappingRef) {
          $this.$refs.fieldMappingRef.openConfigModal();
        }
      });
    },
    addSlotSigner: function (slotIdx) {
      if (!this.activeStep || !this.activeStep.templates) return;
      var slot = this.activeStep.templates[slotIdx];
      if (!slot) return;
      slot.Signers.push({
        SignerOrder: slot.Signers.length + 1,
        SignerType: 'ROLE',
        SignerValue: '',
        SignMethod: slot.SignSystem || 'smartca',
        IsSequential: true
      });
    },
    removeSlotSigner: function (slotIdx, signerIdx) {
      if (!this.activeStep || !this.activeStep.templates) return;
      var slot = this.activeStep.templates[slotIdx];
      if (!slot) return;
      slot.Signers.splice(signerIdx, 1);
      slot.Signers.forEach(function (s, i) { s.SignerOrder = i + 1; });
    },
    getTemplateById: function (templateId) {
      if (!templateId) return null;
      return this.templates.find(function (t) { return Number(t.TemplateID) === Number(templateId); }) || null;
    },
    onSlotTemplateSelect: function (slotIdx, templateId) {
      if (!this.activeStep || !this.activeStep.templates) return;
      var slot = this.activeStep.templates[slotIdx];
      if (!slot) return;
      if (!templateId) { return; }
      var template = this.getTemplateById(templateId);
      if (!template) return;
      // Tự điền tên template vào Label nếu Label đang là mặc định hoặc trống
      var defaultLabel = 'Template ' + (slotIdx + 1);
      if (!slot.Label || slot.Label === defaultLabel) {
        slot.Label = template.TemplateName || defaultLabel;
      }
      if (!template.Placeholders || !template.Placeholders.length) return;
      
      // Tự động gán các placeholder đã tồn tại trong fields chung của luồng nhưng chưa được gán vào bước hiện tại (Case 2)
      var $this = this;
      var autoLinkedCount = 0;
      if (!$this.activeStep.SelectedFieldNames) $this.activeStep.SelectedFieldNames = [];
      if (!$this.activeStep.StepFields) $this.activeStep.StepFields = [];

      template.Placeholders.forEach(function (ph) {
        var existsInGlobalFields = $this.fields.some(function (f) { return f.FieldName === ph; });
        var existsInStep = $this.activeStep.SelectedFieldNames.indexOf(ph) !== -1;
        
        if (existsInGlobalFields && !existsInStep) {
          var dbField = $this.fields.find(function(f) { return f.FieldName === ph; });
          $this.activeStep.SelectedFieldNames.push(ph);
          $this.activeStep.StepFields.push({
            FieldName: ph,
            SortOrder: $this.activeStep.StepFields.length + 1,
            IsRequired: dbField ? !!dbField.IsRequired : false
          });
          autoLinkedCount++;
        }
      });

      if (autoLinkedCount > 0 && showToast && showToast.success) {
        showToast.success("Đã tự động gán " + autoLinkedCount + " trường sẵn có vào bước này.");
      }

      var unlinked = template.Placeholders.filter(function (ph) { return !$this.isPlaceholderInFields(ph); }).length;
      if (unlinked > 0 && showToast && showToast.info) {
        showToast.info('Template có ' + unlinked + ' placeholder chưa có trong trường tùy chỉnh chung. Bạn có thể bấm "Thêm nhanh".');
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
        var newTemplateID = row ? row.TemplateID : null;
        if (showToast && showToast.success) {
          showToast.success(row && row.Message ? row.Message : "Lưu template thành công.");
        }
        $this.showQuickTemplateDialog = false;
        $this.quickTemplate = $this.getEmptyQuickTemplate();
        await $this.loadTemplates();
        if (newTemplateID && $this.activeStep) {
          $this.activeStep.TemplateID = newTemplateID;
          $this.onTemplateSelect(newTemplateID);
        }
      } catch (err) {
        if (showToast && showToast.error) {
          showToast.error(err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : (err.message ? err.message : "Đã xảy ra lỗi khi lưu."));
        }
      } finally {
        $this.isSavingTemplate = false;
      }
    }
  },
  watch: {
    activeStepIdx: function () {
      if (this.activeStepIdx < 0) this.activeStepIdx = 0;
      if (this.activeStepIdx >= this.steps.length) this.activeStepIdx = Math.max(0, this.steps.length - 1);
      this.editingRuleIdx = null;
      this.editingTaskIdx = null;
      var step = this.steps[this.activeStepIdx]
      if (step && (step.StepType === 'SUCCESS' || step.StepType === 'FAILURE')) {
        this.activeStepTab = 'automation'
      }
      this.initCustomFieldsSortable();
      this.initTplSortable();
    },
    steps: {
      handler: function () {
        if (this.activeStepIdx >= this.steps.length) this.activeStepIdx = Math.max(0, this.steps.length - 1);
      },
      deep: true
    }
  },
  beforeUnmount: function () {
    if (typeof window !== "undefined") {
      window.removeEventListener('keydown', this.handleGlobalKeydown);
    }
    this.destroyCustomFieldsSortable();
    this.destroyTplSortable();
  }
	}
</script>