<template>
	<uc-request-detail-view v-if="showSignDetail" ref="detailViewRef" :prop-instance-id="instanceId"
    @back="showSignDetail = false" />
  <div v-else-if="isModal" class="d-flex flex-column bg-white wf-kfd-h100vh">

    <!-- ── HEADER ── -->
    <div class="d-flex align-center px-4 py-3 border-bottom wf-kfd-flexsh0-3">
      <v-btn class="wf-kfd-flexsh0" icon size="small" variant="text" color="grey-darken-2" @click="goBack">
        <v-icon size="18">mdi-close</v-icon>
      </v-btn>
      <div class="flex-grow-1 d-flex align-center ga-2 wf-kfd-minw0">
        <span class="font-weight-bold text-grey-darken-4 text-truncate wf-kfd-fs14px">
          {{ theChiTiet ? theChiTiet.InstanceName : 'Đang tải...' }}
        </span>
        <span class="text-grey-lighten-1 wf-kfd-fs13px">•</span>
        <span class="text-caption font-weight-bold text-grey-darken-1 wf-kfd-fs11px-8">
          {{ theChiTiet ? (theChiTiet.InstanceID || '') : '' }}
        </span>
      </div>
      <v-btn v-if="!isReadonlyStep || hasSignatureFieldsEditable" color="primary" size="small" variant="flat" class="font-weight-bold px-3 text-caption wf-kfd-flexsh0-4" :loading="isSaving" @click="saveFieldValues">
        Lưu
      </v-btn>
    </div>

    <!-- ── LOADING / ERROR STATES ── -->
    <div v-if="isLoading" class="flex-grow-1 d-flex align-center justify-center">
      <v-progress-circular indeterminate color="primary" size="40"></v-progress-circular>
    </div>
    <div v-else-if="!theChiTiet" class="flex-grow-1 d-flex align-center justify-center">
      <div class="text-center">
        <v-icon size="48" color="grey-lighten-1">mdi-alert-circle-outline</v-icon>
        <div class="text-body-2 text-grey-darken-1 mt-3">Không tìm thấy hồ sơ</div>
        <v-btn color="primary" size="small" class="mt-3" @click="goBack">Đóng</v-btn>
      </div>
    </div>

    <!-- ── MAIN SCROLLABLE BODY ── -->
    <div v-else class="flex-grow-1 overflow-y-auto wf-kfd-minh0-2">
      <div class="px-5 py-4 d-flex flex-column wf-kfd-gap14px">

        <!-- ROW 1: Tags / Nhãn dán -->
        <div class="d-flex align-center flex-wrap ga-1">
          <!-- Giai đoạn hiện tại -->
          <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold">
            {{ getCurrentStepName() }}
          </v-chip>
          <!-- Status chip -->
          <v-chip size="x-small" :color="getStatusColor(theChiTiet.Status)" variant="tonal" class="font-weight-bold">
            {{ getStatusTextFriendly(theChiTiet.Status) }}
          </v-chip>
          <!-- User tags -->
          <template v-if="theChiTiet.Tag">
            <v-chip v-for="tag in tagStringToList(theChiTiet.Tag)" :key="tag" size="x-small" :style="{
                backgroundColor: getTagColorLight(tag),
                color: getTagTextColorDark(tag),
                border: '1px solid ' + getTagBorderColor(tag),
                fontWeight: '700'
              }">
              {{ getTagDisplayName(tag) }}
            </v-chip>
          </template>
          <v-btn class="wf-kfd-w20px" icon size="x-small" variant="text" color="grey" @click="moSuaNhan">
            <v-icon size="14">mdi-tag-plus-outline</v-icon>
          </v-btn>
        </div>

        <!-- ROW 2: Meta grid (Owner / Assignee / Giai đoạn / Ngày tạo) -->
        <div class="d-flex ga-2 wf-kfd-flexwrwrap">
          <div class="rounded border pa-3 flex-grow-1 wf-kfd-minw110px">
            <div class="text-caption text-grey-darken-1 mb-1 wf-kfd-fs10px-2">Người tạo</div>
            <div class="text-caption font-weight-bold text-grey-darken-4 wf-kfd-fs12px">
              {{ theChiTiet.CreateUser || '-' }}
            </div>
          </div>
          <div class="rounded border pa-3 flex-grow-1 wf-kfd-minw110px">
            <div class="text-caption text-grey-darken-1 mb-1 wf-kfd-fs10px-2">Phụ trách</div>
            <div class="text-caption font-weight-bold text-grey-darken-4 wf-kfd-fs12px">
              {{ theChiTiet.AssigneeName || theChiTiet.nguoiPhuTrach || '-' }}
            </div>
          </div>
          <div class="rounded border pa-3 flex-grow-1 wf-kfd-minw110px">
            <div class="text-caption text-grey-darken-1 mb-1 wf-kfd-fs10px-2">Quản lý bước</div>
            <div class="text-caption font-weight-bold text-grey-darken-4 wf-kfd-fs12px">
              {{ theChiTiet.NextSigner || '-' }}
            </div>
          </div>
          <div class="rounded border pa-3 flex-grow-1 wf-kfd-minw110px">
            <div class="text-caption text-grey-darken-1 mb-1 wf-kfd-fs10px-2">Cập nhật</div>
            <div class="text-caption font-weight-bold text-grey-darken-4 wf-kfd-fs12px">
              {{ formatDateShort(theChiTiet.UpdateTime || theChiTiet.CreateTime) }}
            </div>
          </div>
        </div>

        <!-- ROW 3: Transition / Action box -->
        <div class="rounded border pa-3 wf-kfd-bce2e8f0-2">
          <div class="text-caption font-weight-bold text-grey-darken-2 mb-2 wf-kfd-fs11px-2">Transition</div>

          <!-- Block reasons warning -->
          <div v-if="moveStepBlockReasons.length> 0" class="rounded pa-2 mb-2 wf-kfd-bgfffbeb">
            <div v-for="(r, ri) in moveStepBlockReasons" :key="ri" class="text-caption text-amber-darken-4 d-flex align-start ga-1 wf-kfd-fs105px">
              <span>•</span><span>{{ r }}</span>
            </div>
          </div>

          <!-- Sign required warning -->
          <div v-if="hasSigningRequiredForCurrentUser" class="rounded pa-2 mb-2 d-flex align-center ga-2 wf-kfd-bgfff7ed-2">
            <v-icon size="14" color="warning">mdi-signature-freehand</v-icon>
            <span class="text-caption font-weight-bold text-orange-darken-4 wf-kfd-fs11px-2">Yêu cầu ký
              số</span>
            <v-btn size="x-small" color="warning" variant="flat" class="ml-auto font-weight-bold text-caption wf-kfd-ttnone-3" @click="showSignDetail = true">Ký ngay</v-btn>
          </div>

          <!-- Manual send sign flow -->
          <template v-if="overview.RequireManualSendSign && overview.CurrentStepType === 'SIGN'">
            <v-btn v-if="!overview.IsSentForSigning" color="primary" variant="flat" size="small" class="font-weight-bold text-caption wf-kfd-ttnone-2" :disabled="!overview.CanCurrentUserAct" @click="clickReviewAndSend">
              <v-icon start size="13">mdi-send-circle-outline</v-icon>
              Review & Gửi ký số
            </v-btn>
            <div v-else class="d-flex ga-2">
              <v-btn color="success" variant="tonal" size="small" class="font-weight-bold text-caption wf-kfd-ttnone-2" @click="showSignDetail = true">
                <v-icon start size="13">mdi-file-eye-outline</v-icon>Xem file
              </v-btn>
              <v-btn color="error" variant="tonal" size="small" class="font-weight-bold text-caption wf-kfd-ttnone-2" :disabled="!overview.CanCurrentUserAct" @click="cancelSentSigning" :loading="isCancelingSign">
                <v-icon start size="13">mdi-close-circle-outline</v-icon>Hủy gửi ký
              </v-btn>
            </div>
          </template>

          <!-- Normal move step — compact chip style -->
          <div
            v-if="theChiTiet.Status !== 'COMPLETED' && theChiTiet.Status !== 'CANCELLED' && (!overview.RequireManualSendSign || overview.IsSentForSigning)"
            class="d-flex align-center flex-wrap ga-2">
            <!-- Primary transition chip: "[Bước hiện tại] → [Bước tiếp theo]" -->
            <v-btn color="primary" variant="flat" size="small" class="font-weight-bold text-caption wf-kfd-ttnone-6" :disabled="moveStepBlockReasons.length> 0 || isMovingStep" :loading="isMovingStep" @click="quickMoveStep">
              {{ getNextStepTransitionLabel() }}
            </v-btn>

            <!-- Dropdown to jump to any other step -->
            <v-menu transition="scale-transition">
              <template v-slot:activator="{ props }">
                <v-btn class="wf-kfd-w24px-2" v-bind="props" variant="text" color="grey-darken-2" size="small" icon>
                  <v-icon size="16">mdi-dots-horizontal</v-icon>
                </v-btn>
              </template>
              <v-list density="compact" nav>
                <v-list-subheader class="text-caption font-weight-bold text-uppercase wf-kfd-fs9px">Chuyển đến bước</v-list-subheader>
                <v-list-item
                  v-for="c in dsCot.filter(function(col) { return typeof col.id === 'number' && Number(col.order) !== Number(theChiTiet.CurrentStepOrder) })"
                  :key="c.id" @click="quickMoveToStep(c.id)" class="text-caption">
                  <v-list-item-title class="wf-kfd-fs12px">{{ c.tenCot }}</v-list-item-title>
                </v-list-item>
              </v-list>
            </v-menu>
          </div>

          <!-- Cancel / Delete — separate row below transition box -->
          <div v-if="theChiTiet.Status !== 'COMPLETED' && theChiTiet.Status !== 'CANCELLED'" class="d-flex ga-3 mt-2 pt-2 border-top wf-kfd-bcf1f5f9">
            <v-btn variant="text" color="warning" size="x-small" class="font-weight-medium text-caption pa-0 wf-kfd-ttnone-4" @click="cancelInstance">
              <v-icon start size="12">mdi-cancel</v-icon>
              Hủy nhiệm vụ
            </v-btn>
            <v-btn variant="text" color="error" size="x-small" class="font-weight-medium text-caption pa-0 wf-kfd-ttnone-4" @click="deleteInstance">
              <v-icon start size="12">mdi-delete-outline</v-icon>
              Xóa nhiệm vụ
            </v-btn>
          </div>
        </div>

        <!-- ROW 4: Tab navigation -->
        <div class="d-flex border-bottom wf-kfd-gap0">
          <div v-for="tab in [ { key: 'fields', label: 'Thông tin' }, { key: 'checklist', label: 'Checklist (' + (instanceTasksForCurrentStep ? instanceTasksForCurrentStep.length : 0) + ')' }, { key: 'files', label: 'Hồ sơ (' + (checklistItems ? checklistItems.length : 0) + ')' }, { key: 'history', label: 'Nhật ký' } ]" :key="tab.key" class="cursor-pointer text-caption font-weight-bold pb-2 px-3 wf-kfd-fs12px-4" :style="detailRightSubTab === tab.key ? 'color: #217D46; border-bottom: 2px solid #217D46; margin-bottom: -1px;' : 'color: #64748b; border-bottom: 2px solid transparent; margin-bottom: -1px;'" @click="detailRightSubTab = tab.key">
            {{ tab.label }}
          </div>
        </div>

        <!-- ROW 5: Tab content -->

        <!-- Tab: Thông tin chi tiết (fields) -->
        <div v-if="detailRightSubTab === 'fields'">
          <!-- Template buttons -->
          <div v-if="hasTemplateOrDocument && !activeTemplates" class="d-flex ga-2 mb-3">
            <v-btn color="info" size="x-small" variant="outlined" :loading="isGeneratingPreview" @click="mergeAndPreview" class="font-weight-bold text-caption wf-kfd-ttnone-5">
              <v-icon start size="11">mdi-eye-outline</v-icon>Xem mẫu
            </v-btn>
            <v-btn color="success" size="x-small" variant="outlined" :loading="isGeneratingPreview" @click="mergeAndDownload" class="font-weight-bold text-caption wf-kfd-ttnone-5">
              <v-icon start size="11">mdi-download</v-icon>Tải file
            </v-btn>
          </div>

          <!-- Key-value table for fields -->
          <div v-if="customFieldsForCurrentStep.length> 0" class="d-flex flex-column wf-kfd-bd1pxsolide2-3">
            <div v-for="(field, fi) in customFieldsForCurrentStep" :key="field.FieldName" class="d-flex align-start"
              :style="fi > 0 ? 'border-top: 1px solid #f1f5f9;' : ''">
              <!-- Label column -->
              <div class="text-caption text-grey-darken-2 px-3 py-2 flex-shrink-0 wf-kfd-w130px-2">
                <span v-if="field.IsRequired" class="text-error">*</span>
                {{ field.FieldLabel || field.FieldName }}
              </div>
              <!-- Input column -->
              <div class="flex-grow-1 px-2 py-1.5">
                <!-- Readonly display -->
                <template v-if="isReadonlyStep && field.FieldType !== 'signature'">
                  <div class="text-caption text-grey-darken-4 py-1 wf-kfd-fs12px-5">
                    <template v-if="field.FieldType === 'file' || field.FieldType === 'image'">
                      <a v-if="editFieldValues[field.FieldName]" :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank" class="text-primary text-decoration-none font-weight-medium wf-kfd-fs11px-2">
                        {{ getFieldFileName(editFieldValues[field.FieldName]) }}
                      </a>
                      <span v-else class="text-grey wf-kfd-fontstitalic">Chưa có tệp</span>
                    </template>
                    <template v-else-if="field.FieldType === 'checkbox'">
                      <v-icon size="14" :color="editFieldValues[field.FieldName] ? 'success' : 'grey'">
                        {{ editFieldValues[field.FieldName] ? 'mdi-checkbox-marked' : 'mdi-checkbox-blank-outline' }}
                      </v-icon>
                    </template>
                    <template v-else>
                      {{ editFieldValues[field.FieldName] || '-' }}
                    </template>
                  </div>
                </template>

                <!-- Editable inputs -->
                <template v-else>
                  <v-select v-if="field.FieldType === 'select' && field.DataSourceType === 'api'"
                    v-model="editFieldValues[field.FieldName]" :items="apiDataSources[field.DataSourceApi]"
                    item-title="Text" item-value="Value" variant="plain" density="compact" hide-details="auto"
                    class="wf-flat-input" />
                  <v-select v-else-if="field.FieldType === 'select'" v-model="editFieldValues[field.FieldName]"
                    :items="(field.FieldOptions || '').split(',')" variant="plain" density="compact" hide-details="auto"
                    class="wf-flat-input" />
                  <v-checkbox v-else-if="field.FieldType === 'checkbox'" density="compact" color="primary" hide-details
                    :label="field.FieldOptions || ''"
                    :model-value="Number(editFieldValues[field.FieldName]) === 1 || editFieldValues[field.FieldName] === true || editFieldValues[field.FieldName] === 'true'"
                    @update:model-value="toggleSingleCheckbox(field.FieldName)" />
                  <v-textarea v-else-if="field.FieldType === 'textarea'" v-model="editFieldValues[field.FieldName]"
                    variant="plain" density="compact" rows="2" hide-details="auto" class="wf-flat-input" />
                  <!-- Signature field -->
                  <uc-select-user v-else-if="field.FieldType === 'signature'" v-model="editFieldValues[field.FieldName]"
                    placeholder="Chọn người ký" clearable :readonly="isSignatureFieldReadonly"
                    :disabled="isSignatureFieldReadonly" class="wf-flat-input font-weight-bold text-success" />
                  <!-- File / Image -->
                  <div v-else-if="field.FieldType === 'file' || field.FieldType === 'image'"
                    class="d-flex align-center ga-2 py-1">
                    <input class="d-none" :ref="'detail_file_input_' + field.FieldName" type="file" @change="onFieldFileSelected($event, field.FieldName, editFieldValues)">
                    <template v-if="editFieldValues[field.FieldName]">
                      <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank" class="text-primary text-decoration-none text-caption font-weight-medium wf-kfd-fs11px-2">
                        {{ getFieldFileName(editFieldValues[field.FieldName]) }}
                      </a>
                      <v-btn icon size="x-small" variant="text" color="error"
                        @click.stop="clearFieldFile(field.FieldName, editFieldValues)">
                        <v-icon size="12">mdi-close</v-icon>
                      </v-btn>
                    </template>
                    <v-btn v-else size="x-small" variant="tonal" color="primary" @click="triggerFieldFileInput(field.FieldName, false)" class="text-caption wf-kfd-ttnone-3">
                      <v-icon start size="12">mdi-upload</v-icon>Tải lên
                    </v-btn>
                  </div>
                  <!-- Default text/date/number -->
                  <v-text-field v-else v-model="editFieldValues[field.FieldName]"
                    :type="field.FieldType === 'number' ? 'number' : field.FieldType === 'date' ? 'date' : 'text'"
                    variant="plain" density="compact" hide-details="auto" class="wf-flat-input" />
                </template>
              </div>
            </div>
          </div>

          <!-- Empty state -->
          <div v-else class="text-center py-6 text-caption text-grey">
            <v-icon size="20" color="grey-lighten-1" class="mb-1">mdi-alert-circle-outline</v-icon>
            <div>Không có trường dữ liệu cho bước này</div>
          </div>

          <!-- Other fields (collapsed) -->
          <v-expansion-panels v-if="otherCustomFields.length > 0" class="mt-3" variant="accordion">
            <v-expansion-panel>
              <v-expansion-panel-title class="text-caption font-weight-bold text-grey-darken-2 py-2 px-3 wf-kfd-minh36px">
                Các dữ liệu khác ({{ otherCustomFields.length }})
              </v-expansion-panel-title>
              <v-expansion-panel-text class="pa-0">
                <div class="d-flex flex-column wf-kfd-border1pxsolidf1">
                  <div v-for="field in otherCustomFields" :key="field.FieldName" class="d-flex align-center px-3 py-2 border-bottom wf-kfd-border1pxsolidf8">
                    <span class="text-caption text-grey-darken-2 flex-shrink-0 wf-kfd-w130px-3">
                      {{ field.FieldLabel || field.FieldName }}
                    </span>
                    <span class="text-caption text-grey-darken-4 font-weight-medium wf-kfd-fs12px">
                      {{ editFieldValues[field.FieldName] || '-' }}
                    </span>
                  </div>
                </div>
              </v-expansion-panel-text>
            </v-expansion-panel>
          </v-expansion-panels>
        </div>

        <!-- Tab: Checklist công việc -->
        <div v-else-if="detailRightSubTab === 'checklist'">
          <uc-subtasks :instance-id="instanceId" class="w-100" />
        </div>

        <!-- Tab: Hồ sơ tài liệu -->
        <div v-else-if="detailRightSubTab === 'files'">
          <uc-kanban-checklist :items="checklistItems" :readonly="isReviewOrApproveStep"
            @update:items="checklistItems = $event" @item-change="saveChecklistItem"
            @upload-requested="onChecklistUploadRequested" class="w-100" />
        </div>

        <!-- Tab: Nhật ký hoạt động -->
        <div v-else-if="detailRightSubTab === 'history'" class="d-flex flex-column wf-kfd-gap0-2">
          <div v-if="logs.length === 0" class="text-center py-6 text-caption text-grey">
            <v-icon size="20" color="grey-lighten-1">mdi-history</v-icon>
            <div class="mt-1">Chưa có nhật ký</div>
          </div>
          <div v-for="(log, li) in logs" :key="log.LogID" class="d-flex align-start px-1 py-2"
            :style="li > 0 ? 'border-top: 1px solid #f8f9fa;' : ''">
            <!-- Icon indicator -->
            <div class="d-flex flex-column align-center mr-3 wf-kfd-w22px">
              <div class="rounded-circle d-flex align-center justify-center"
                :style="{ backgroundColor: getLogStatusColor(log.ActionCode) + '20', width: '22px', height: '22px' }">
                <v-icon size="11" :color="getLogStatusColor(log.ActionCode)">{{ getLogIcon(log.ActionCode) }}</v-icon>
              </div>
              <div class="wf-kfd-w1px" v-if="li < logs.length - 1"></div>
            </div>
            <!-- Content -->
            <div class="flex-grow-1 wf-kfd-minw0">
              <div class="text-caption font-weight-bold text-grey-darken-4 wf-kfd-fs115px-2">
                {{ getLogDescription(log) }}
              </div>
              <div class="text-caption text-grey-darken-1 mt-0.5 wf-kfd-fs10px-2">
                {{ formatDateTime(log.CreateTime) }}
                <span v-if="log.StepOrder"> · {{ getStepNameByOrder(log.StepOrder) }}</span>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
  <div v-else>
    <div class="wf-page-container d-flex flex-column wf-kfd-hcalc100vh6">

      <!-- Premium Header Toolbar -->
      <div class="d-flex align-center border-bottom shadow-sm">
        <v-btn class="wf-btn" variant="text" color="primary" @click="goBack">
          <v-icon start size="16">mdi-arrow-left</v-icon>
          Danh sách
        </v-btn>
        <v-divider vertical class="wf-detail-divider" />
        <div class="wf-detail-title" v-if="theChiTiet">
          <div class="d-flex align-center wf-detail-title-row">
            <h1 class="wf-detail-name">{{ theChiTiet.InstanceName }}</h1>
            <v-chip size="x-small" :color="getStatusColor(theChiTiet.Status)" variant="tonal" class="wf-chip-rounded">
              {{ getStatusTextFriendly(theChiTiet.Status) }}
            </v-chip>
          </div>
          <p class="wf-detail-sub">{{ displayInstanceMeta }}</p>
        </div>
        <div class="wf-detail-title" v-else>
          <div class="d-flex align-center wf-detail-title-row">
            <h1 class="wf-detail-name">Đang tải...</h1>
          </div>
        </div>

        <v-btn class="wf-btn ml-2" variant="outlined" color="primary" :loading="isLoading" @click="loadData(false)">
          <v-icon start size="16">mdi-refresh</v-icon>
          Làm mới
        </v-btn>
      </div>

      <v-divider class="my-2" />

      <!-- MAIN CONTENT WORKSPACE -->
      <div v-if="isLoading" class="flex-grow-1 d-flex align-center justify-center bg-white">
        <div class="text-center">
          <v-progress-circular indeterminate color="primary" size="48" class="mb-3"></v-progress-circular>
          <div class="text-body-2 text-grey-darken-1">Đang tải thông tin hồ sơ...</div>
        </div>
      </div>

      <div v-else-if="!theChiTiet" class="flex-grow-1 d-flex align-center justify-center bg-white">
        <div class="text-center">
          <v-icon size="64" color="grey-lighten-1">mdi-alert-circle-outline</v-icon>
          <div class="text-h6 text-grey-darken-1 mt-4">Không tìm thấy hồ sơ hoặc bạn không có quyền truy cập
          </div>
          <v-btn color="primary" class="mt-4 font-weight-bold" @click="goBack">Quay lại bảng Kanban</v-btn>
        </div>
      </div>

      <!-- Main Layout of details -->
      <div v-else class="flex-grow-1 d-flex w-100 wf-kfd-minh0">

        <!-- MAIN CONTAINER: TAB CONTENTS -->

        <!-- A. TAB MISSION (Bố cục phẳng 2 cột y hệt modal của wf-kanban-flow) -->
        <template v-if="true">
          <!-- LEFT COLUMN: SIDEBAR CONTAINER (320px) -->
          <div class="d-flex flex-column pa-4 wf-kfd-w320px">
            <!-- LEFT COLUMN SIDEBAR CARD -->
            <div class="bg-white border shadow-sm px-5 py-6 d-flex flex-column wf-kfd-bd1pxsolide2-2">
              <!-- Title/Name -->
              <h2 class="text-subtitle-1 font-weight-bold text-grey-darken-4 text-center mb-4 line-clamp-2 wf-kfd-lh14">
                {{ theChiTiet.InstanceName }}
              </h2>

              <v-divider class="mb-5"></v-divider>

              <!-- INFO CARD: Giai đoạn & Người phụ trách (Layout Dọc) -->
              <div class="mb-5 rounded-lg border pa-4 wf-kfd-bgf8fafc">

                <!-- Giai đoạn hiện tại -->
                <div class="mb-3">
                  <div class="d-flex align-center text-caption font-weight-bold text-grey-darken-1 mb-1 wf-kfd-fs11px">
                    <v-icon size="14" class="mr-1">mdi-timeline-outline</v-icon>
                    GIAI ĐOẠN HIỆN TẠI:
                  </div>
                  <div class="text-caption font-weight-bold text-primary pl-2">
                    {{ getCurrentStepName() }}
                  </div>
                </div>

                <!-- Người phụ trách quy trình (Instance PIC) -->
                <div class="mb-3">
                  <div class="d-flex align-center text-caption font-weight-bold text-grey-darken-1 mb-1 wf-kfd-fs11px">
                    <v-icon size="14" class="mr-1">mdi-account-star-outline</v-icon>
                    PHỤ TRÁCH QUY TRÌNH:
                  </div>
                  <div class="text-caption font-weight-bold text-grey-darken-3 pl-2">
                    {{ theChiTiet.nguoiPhuTrach || theChiTiet.AssigneeName || 'Chưa xác định' }}
                  </div>
                </div>

                <v-divider class="mb-3 wf-kfd-bce2e8f0"></v-divider>

                <!-- Người phụ trách -->
                <div>
                  <div class="d-flex align-center text-caption font-weight-bold text-grey-darken-1 mb-1 wf-kfd-fs11px">
                    <v-icon size="14" class="mr-1">mdi-account-tie-outline</v-icon>
                    NGƯỜI QUẢN LÝ BƯỚC NÀY:
                  </div>
                  <div class="text-caption font-weight-bold text-grey-darken-3 pl-2">
                    {{ theChiTiet.NextSigner || theChiTiet.CreateUser || 'Chưa xác định' }}
                  </div>
                </div>
              </div>

              <!-- NHÃN DÁN CARD (Tags) -->
              <div v-if="theChiTiet" class="mb-5 rounded-lg border pa-4 text-left wf-kfd-bgf8fafc-2">
                <div class="d-flex align-center justify-space-between mb-2">
                  <div class="d-flex align-center text-caption font-weight-bold text-grey-darken-2 wf-kfd-fs11px-5">
                    <v-icon size="14" class="mr-1">mdi-tag-multiple-outline</v-icon>
                    Nhãn dán
                  </div>
                  <v-btn icon="mdi-cog-outline" variant="text" size="x-small" color="primary" class="ma-0 wf-kfd-minw20px" @click="moSuaNhan"></v-btn>
                </div>
                <div v-if="theChiTiet.Tag" class="d-flex flex-wrap ga-1">
                  <v-chip v-for="tag in tagStringToList(theChiTiet.Tag)" :key="tag" size="x-small" :style="{
                      backgroundColor: getTagColorLight(tag),
                      color: getTagTextColorDark(tag),
                      border: '1px dashed ' + getTagBorderColor(tag),
                      fontSize: '9px',
                      height: '18px',
                      fontWeight: '700',
                      borderRadius: '4px',
                      letterSpacing: '0.1px'
                    }" class="px-2">
                    {{ getTagDisplayName(tag) }}
                  </v-chip>
                </div>
                <div v-else class="text-caption text-grey-darken-1 italic pl-1 wf-kfd-fs11px-2">Chưa gán nhãn
                  dán nào</div>
              </div>

              <!-- Thao tác nhanh -->
              <div>
                <span class="text-caption font-weight-bold text-grey-darken-1 d-block mb-3 wf-kfd-fs10px-5">
                  Thao tác nhanh
                </span>

                <div v-if="theChiTiet.Status !== 'COMPLETED' && theChiTiet.Status !== 'CANCELLED'">
                  <div v-if="moveStepBlockReasons.length> 0" class="rounded-lg px-3 py-2 mb-3 wf-kfd-bgfffbeb">
                    <div class="d-flex align-center ga-1.5 mb-1.5">
                      <v-icon size="14" color="amber-darken-3">mdi-alert-circle-outline</v-icon>
                      <span class="text-caption font-weight-bold text-amber-darken-4 wf-kfd-fs12px-2">Chưa đủ điều kiện</span>
                    </div>
                    <div class="d-flex flex-column ga-1 pl-4">
                      <div v-for="(reason, ri) in moveStepBlockReasons" :key="ri" class="text-caption d-flex align-start ga-1 text-amber-darken-4 wf-kfd-fs11px-4">
                        <span class="mt-0.5">•</span>
                        <span>{{ reason }}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Cảnh báo ký số -->
                <div v-if="hasSigningRequiredForCurrentUser" class="rounded-lg px-3 py-3 mb-3 d-flex flex-column ga-2 wf-kfd-bgfff7ed">
                  <div class="d-flex align-center ga-1.5">
                    <v-icon size="16" color="warning">mdi-signature-freehand</v-icon>
                    <span class="text-caption font-weight-bold text-orange-darken-4 wf-kfd-fs12px-2">Yêu cầu ký số</span>
                  </div>
                  <span class="text-caption text-orange-darken-3 wf-kfd-fs11px-4">
                    Bạn có lượt ký số chưa hoàn tất trong hồ sơ này.
                  </span>
                  <v-btn color="warning" class="font-weight-bold text-caption mt-1 w-100" height="32"
                    @click="showSignDetail = true">
                    <v-icon start size="15">mdi-draw-pen</v-icon>
                    Ký số ngay
                  </v-btn>
                </div>

                <!-- Nhóm nút hành động -->
                <div class="d-flex flex-column ga-2">
                  <!-- Trường hợp BƯỚC KÝ SỐ THỦ CÔNG (RequireManualSendSign) -->
                  <template v-if="overview.RequireManualSendSign && overview.CurrentStepType === 'SIGN'">
                    <!-- 1. Chưa gửi đi ký: Hiện nút "Review & Gửi ký số" cho Manager (CanCurrentUserAct) -->
                    <v-btn v-if="!overview.IsSentForSigning" class="w-100 font-weight-bold text-caption text-white mb-1"
                      color="primary" variant="flat" :disabled="!overview.CanCurrentUserAct" @click="clickReviewAndSend"
                      height="36" elevation="0">
                      <v-icon start size="15">mdi-send-circle-outline</v-icon>
                      Review & Gửi ký số
                    </v-btn>

                    <!-- 2. Đã gửi đi ký: Hiện nút "Xem file hiện hành" và "Hủy gửi ký" -->
                    <template v-else>
                      <v-btn class="w-100 font-weight-bold text-caption border mb-1" color="success" variant="outlined"
                        @click="showSignDetail = true" height="36" elevation="0">
                        <v-icon start size="15">mdi-file-eye-outline</v-icon>
                        Xem file hiện hành
                      </v-btn>

                      <v-btn v-if="activeStepSignedCount === 0 && overview.CanCurrentUserAct"
                        class="w-100 font-weight-bold text-caption text-white mb-1" color="error" variant="flat"
                        :loading="isCancelingSign" @click="cancelSentSigning" height="36" elevation="0">
                        <v-icon start size="15">mdi-close-circle-outline</v-icon>
                        Hủy gửi ký
                      </v-btn>
                    </template>
                  </template>

                  <!-- Trường hợp LUỒNG KÝ SỐ TỰ ĐỘNG THƯỜNG -->
                  <template v-else>
                    <!-- Xem màn hình ký (tạm thời ẩn) -->
                    <v-btn v-if="false && hasTemplateOrDocument" class="w-100 font-weight-bold text-caption border mb-1"
                      color="primary" variant="outlined" @click="showSignDetail = true" height="36" elevation="0">
                      <v-icon start size="15">mdi-signature-freehand</v-icon>
                      Xem màn hình ký
                    </v-btn>
                  </template>

                  <!-- Nút Chuyển tiếp & Lựa chọn -->
                  <div
                    v-if="theChiTiet.Status !== 'COMPLETED' && theChiTiet.Status !== 'CANCELLED' && (!overview.RequireManualSendSign || overview.IsSentForSigning)"
                    class="d-flex ga-2">
                    <v-btn class="flex-grow-1 font-weight-bold text-caption border wf-kfd-bcrgba331257" :color="canMoveStep ? 'success' : 'primary'" :variant="canMoveStep ? 'flat' : 'tonal'" :disabled="!canMoveStep" :loading="isMovingStep" @click="quickMoveStep" height="36" elevation="0">
                      <v-icon start size="15">mdi-arrow-right-circle-outline</v-icon>
                      Chuyển tiếp
                    </v-btn>

                    <!-- Dropdown Lựa chọn bước nhảy -->
                    <v-menu transition="scale-transition">
                      <template v-slot:activator="{ props }">
                        <v-btn v-bind="props" variant="outlined" color="grey-darken-2" class="px-2 wf-kfd-minw40px" height="36">
                          <v-icon size="16">mdi-chevron-down</v-icon>
                        </v-btn>
                      </template>
                      <v-list density="compact" nav>
                        <v-list-subheader class="text-caption font-weight-bold text-uppercase wf-kfd-fs10px">Chọn bước đích
                        </v-list-subheader>
                        <v-list-item
                          v-for="c in dsCot.filter(function (col) { return typeof col.id === 'number' && Number(col.order) !== Number(theChiTiet.CurrentStepOrder) })"
                          :key="c.id" @click="quickMoveToStep(c.id)" class="text-caption">
                          <v-list-item-title>{{ c.tenCot }}</v-list-item-title>
                        </v-list-item>
                        <v-list-item
                          v-if="dsCot.filter(function (col) { return typeof col.id === 'number' && Number(col.order) !== Number(theChiTiet.CurrentStepOrder) }).length === 0">
                          <v-list-item-title class="text-caption text-grey text-center">Không
                            có bước khả dụng
                          </v-list-item-title>
                        </v-list-item>
                      </v-list>
                    </v-menu>
                  </div>

                  <!-- Nút Hủy và Xóa -->
                  <div class="d-flex ga-2 mt-1"
                    v-if="theChiTiet.Status !== 'COMPLETED' && theChiTiet.Status !== 'CANCELLED'">
                    <v-btn color="warning" variant="outlined" class="flex-grow-1 font-weight-bold text-caption bg-orange-lighten-5 wf-kfd-border1px" height="32" @click="cancelInstance">
                      <v-icon start size="14">mdi-cancel</v-icon>
                      Hủy
                    </v-btn>
                    <v-btn color="error" variant="outlined" class="flex-grow-1 font-weight-bold text-caption bg-red-lighten-5 wf-kfd-border1px-2" height="32" @click="deleteInstance">
                      <v-icon start size="14">mdi-delete-outline</v-icon>
                      Xóa
                    </v-btn>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- RIGHT COLUMN: MAIN CONTENT WORKSPACE -->
          <div class="flex-grow-1 d-flex flex-column overflow-hidden">
            <div class="w-100 h-100 d-flex flex-column overflow-hidden">
              <!-- Sub Tab Navigation -->
              <div class="px-6 py-2 d-flex align-center">
                <div class="d-flex ga-4">
                  <div class="cursor-pointer font-weight-bold text-caption pb-2 px-1 custom-sub-tab"
                    :class="detailRightSubTab === 'fields' ? 'active-sub-tab' : 'text-grey-darken-1'"
                    @click="detailRightSubTab = 'fields'">
                    Thông tin chi tiết
                  </div>
                  <div class="cursor-pointer font-weight-bold text-caption pb-2 px-1 custom-sub-tab"
                    :class="detailRightSubTab === 'checklist' ? 'active-sub-tab' : 'text-grey-darken-1'"
                    @click="detailRightSubTab = 'checklist'">
                    Checklist công việc ({{ instanceTasksForCurrentStep ? instanceTasksForCurrentStep.length : 0 }})
                  </div>
                  <div class="cursor-pointer font-weight-bold text-caption pb-2 px-1 custom-sub-tab"
                    :class="detailRightSubTab === 'files' ? 'active-sub-tab' : 'text-grey-darken-1'"
                    @click="detailRightSubTab = 'files'">
                    Danh mục hồ sơ ({{ checklistItems ? checklistItems.length : 0 }})
                  </div>
                  <div class="cursor-pointer font-weight-bold text-caption pb-2 px-1 custom-sub-tab"
                    :class="detailRightSubTab === 'history' ? 'active-sub-tab' : 'text-grey-darken-1'"
                    @click="detailRightSubTab = 'history'">
                    Nhật ký hoạt động
                  </div>
                </div>
              </div>

              <!-- Sub Tab Content Workspace -->
              <div class="flex-grow-1 pa-4 d-flex flex-column wf-kfd-ovyauto">
                <!-- Sub Tab: Fields Form -->
                <div v-if="detailRightSubTab === 'fields'" class="d-flex flex-column wf-kfd-gap16px">
                  <div class="bg-white border rounded-lg shadow-sm pa-5 wf-kfd-bd1pxsolide2">
                    <div class="d-flex align-center justify-space-between mb-4">
                      <div class="d-flex align-center ga-2">
                        <v-icon color="primary" size="20">mdi-clipboard-text-outline</v-icon>
                        <span class="text-subtitle-2 font-weight-bold text-grey-darken-4">Dữ
                          liệu hồ sơ</span>
                      </div>
                      <div class="d-flex align-center ga-2">
                        <!-- Single-template: nút Xem mẫu / Tải file global -->
                        <v-btn v-if="!activeTemplates && hasTemplateOrDocument" color="info" size="small"
                          variant="outlined" class="font-weight-bold px-3 text-caption" :loading="isGeneratingPreview"
                          @click="mergeAndPreview" height="28">
                          <v-icon start size="14">mdi-eye-outline</v-icon>
                          Xem mẫu in
                        </v-btn>
                        <v-btn v-if="!activeTemplates && hasTemplateOrDocument" color="success" size="small"
                          variant="outlined" class="font-weight-bold px-3 text-caption" :loading="isGeneratingPreview"
                          @click="mergeAndDownload" height="28">
                          <v-icon start size="14">mdi-download</v-icon>
                          Tải file mẫu
                        </v-btn>
                        <v-btn color="primary" size="small" class="font-weight-bold px-4 text-caption"
                          v-if="!isReadonlyStep || hasSignatureFieldsEditable" :loading="isSaving"
                          @click="saveFieldValues" height="28">
                          <v-icon start size="14">mdi-content-save-outline</v-icon>
                          Lưu dữ liệu
                        </v-btn>
                      </div>
                    </div>

                    <!-- MULTI-TEMPLATE MODE: grouped view (3-Pane Layout) -->
                    <template v-if="activeTemplates">
                      <v-row class="ma-0">
                        <!-- Left pane: Template TOC Sidebar -->
                        <v-col cols="12" md="4" lg="3" class="pa-0 pr-md-4 mb-4 mb-md-0 border-right-md wf-kfd-bce2e8f0-2">
                          <v-card variant="flat" class="bg-grey-lighten-5 pa-2 rounded-lg border wf-kfd-mh520px-2">
                            <div class="text-caption font-weight-bold text-grey-darken-2 px-2 mb-2 text-uppercase wf-kfd-ls005em">Danh sách biểu mẫu</div>
                            <v-list class="bg-transparent pa-0" density="compact" nav>
                              <v-list-item v-for="(group, gIdx) in activeTemplateGroups" :key="gIdx"
                                :active="activeFormIdx === gIdx" color="primary"
                                class="rounded-md mb-1 bg-white border px-2 py-0.5"
                                :style="activeFormIdx === gIdx ? 'border-color: var(--v-theme-primary) !important;' : 'border-color: #e2e8f0 !important;'"
                                @click="activeFormIdx = gIdx">
                                <template #prepend>
                                  <v-icon size="14" :color="activeFormIdx === gIdx ? 'primary' : 'grey-darken-1'"
                                    class="mr-1">
                                    mdi-file-document-outline
                                  </v-icon>
                                </template>
                                <v-list-item-title class="font-weight-bold text-grey-darken-4 wf-kfd-lh12">
                                  {{ group.template ? group.template.TemplateName : ('Biểu mẫu ' + (gIdx + 1)) }}
                                </v-list-item-title>
                                <v-list-item-subtitle class="text-grey mt-0.5 wf-kfd-fs10px">
                                  {{ group.fields.length }} trường
                                </v-list-item-subtitle>
                              </v-list-item>

                              <!-- Cấu hình khác -->
                              <v-list-item v-if="templateUnmatchedFields.length > 0"
                                :active="activeFormIdx === activeTemplateGroups.length" color="grey-darken-3"
                                class="rounded-md mb-1 bg-white border px-2 py-0.5"
                                :style="activeFormIdx === activeTemplateGroups.length ? 'border-color: #64748b !important; background-color: #f1f5f9 !important;' : 'border-color: #e2e8f0 !important;'"
                                @click="activeFormIdx = activeTemplateGroups.length">
                                <template #prepend>
                                  <v-icon size="14"
                                    :color="activeFormIdx === activeTemplateGroups.length ? 'grey-darken-3' : 'grey-darken-1'"
                                    class="mr-1">
                                    mdi-dots-horizontal-circle-outline
                                  </v-icon>
                                </template>
                                <v-list-item-title class="font-weight-bold text-grey-darken-4 wf-kfd-fs115px">
                                  Cấu hình khác
                                </v-list-item-title>
                                <v-list-item-subtitle class="text-grey mt-0.5 wf-kfd-fs10px">
                                  {{ templateUnmatchedFields.length }} trường
                                </v-list-item-subtitle>
                              </v-list-item>
                            </v-list>
                          </v-card>
                        </v-col>

                        <!-- Right pane: Input fields detail of selected form -->
                        <v-col cols="12" md="8" lg="9" class="pa-0 pl-md-2">
                          <div v-for="(group, gIdx) in activeTemplateGroups" :key="gIdx">
                            <div v-if="activeFormIdx === gIdx" class="wf-template-group">
                              <!-- Group header -->
                              <div class="wf-template-group__header d-flex align-center justify-space-between mb-3">
                                <div class="d-flex align-center ga-2">
                                  <v-icon size="15" color="primary">mdi-file-document-multiple-outline</v-icon>
                                  <span class="text-subtitle-2 font-weight-bold text-grey-darken-3">Dữ liệu biểu
                                    mẫu:</span>
                                  <span v-if="group.template" class="text-caption text-grey">{{
                                    group.template.TemplateName}}</span>
                                  <v-chip v-if="group.fields.length" size="x-small" color="primary" variant="tonal"
                                    class="font-weight-bold">{{ group.fields.length }} trường</v-chip>
                                </div>
                                <div class="d-flex align-center ga-1" v-if="group.template">
                                  <v-btn color="info" size="x-small" variant="tonal" :loading="isGeneratingPreview"
                                    @click="mergeAndPreviewSlot(group.slot)" class="font-weight-bold text-caption px-2"
                                    height="24">
                                    <v-icon start size="12">mdi-eye-outline</v-icon>Xem mẫu
                                  </v-btn>
                                  <v-btn color="success" size="x-small" variant="tonal" :loading="isGeneratingPreview"
                                    @click="mergeAndDownloadSlot(group.slot)" class="font-weight-bold text-caption px-2"
                                    height="24">
                                    <v-icon start size="12">mdi-download</v-icon>Tải file
                                  </v-btn>
                                </div>
                              </div>
                              <!-- Scroll container for fields -->
                              <div class="wf-kfd-mh520px">
                                <!-- Fields of this group -->
                                <div v-if="group.fields.length > 0">
                                  <v-row class="ma-0">
                                    <v-col
                                      v-for="field in group.fields.filter(f => f.FieldType !== 'file' && f.FieldType !== 'image')"
                                      :key="field.FieldName" cols="12" md="6" class="pa-2">
                                      <div class="d-flex flex-column w-100">
                                        <div class="d-flex align-center justify-space-between mb-1 px-1">
                                          <div class="d-flex align-center ga-1 flex-wrap">
                                            <span class="text-caption text-grey-darken-3">
                                              {{ field.FieldLabel || field.FieldName }}
                                              <span v-if="field.IsRequired && !isReviewOrApproveStep"
                                                class="text-red font-weight-bold">*</span>
                                            </span>
                                            <v-tooltip
                                              v-if="templateDuplicatePlaceholders.indexOf(field.FieldName) !== -1"
                                              location="top"
                                              text="Trường này xuất hiện trong nhiều template của bước. Tất cả template sẽ dùng chung giá trị nhập vào. Để phân biệt, admin cần đổi tên placeholder trong file .docx tương ứng.">
                                              <template #activator="{ props }">
                                                <div v-bind="props" class="d-flex align-center px-1 rounded text-orange-darken-3 font-weight-medium wf-kfd-h18px-2">
                                                  <v-icon size="10" class="mr-1">mdi-link-variant</v-icon>
                                                  Dùng chung
                                                </div>
                                              </template>
                                            </v-tooltip>
                                          </div>
                                          <v-chip size="x-small" :color="getTypeBadgeInfo(field.FieldType).color" variant="tonal" class="font-weight-medium px-1 wf-kfd-h18px">
                                            {{ getTypeBadgeInfo(field.FieldType).label }}
                                          </v-chip>
                                        </div>
                                        <v-select v-if="field.FieldType === 'select' && field.DataSourceType === 'api'"
                                          v-model="editFieldValues[field.FieldName]"
                                          :items="apiDataSources[field.DataSourceApi]" item-title="Text"
                                          item-value="Value" :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                                          :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || editFieldValues[field.FieldName] === '')"
                                          variant="outlined" density="compact" hide-details="auto"
                                          class="wf-ant-input bg-white" />
                                        <v-select v-else-if="field.FieldType === 'select'"
                                          v-model="editFieldValues[field.FieldName]"
                                          :items="(field.FieldOptions || '').split(',')" :readonly="isReadonlyStep"
                                          :disabled="isReadonlyStep"
                                          :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || editFieldValues[field.FieldName] === '')"
                                          variant="outlined" density="compact" hide-details="auto"
                                          class="wf-ant-input bg-white" />
                                        <div v-else-if="field.FieldType === 'checkbox'" class="d-flex align-center">
                                          <v-checkbox :label="field.FieldOptions || ''"
                                            :model-value="Number(editFieldValues[field.FieldName]) === 1 || editFieldValues[field.FieldName] === true || editFieldValues[field.FieldName] === 'true'"
                                            :readonly="isReadonlyStep" :disabled="isReadonlyStep" density="compact"
                                            color="primary" hide-details
                                            @update:model-value="toggleSingleCheckbox(field.FieldName)" />
                                        </div>
                                        <div v-else-if="field.FieldType === 'rating'"
                                          class="border rounded-lg pa-2.5 bg-white d-flex align-center justify-space-between shadow-sm">
                                          <v-rating v-model="editFieldValues[field.FieldName]" color="amber"
                                            density="compact" :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                                            size="small" />
                                          <span class="text-caption font-weight-bold text-amber-darken-2 mr-1">{{
                                            Number(editFieldValues[field.FieldName] || 0).toFixed(1) }} / 5.0</span>
                                        </div>
                                        <div v-else-if="field.FieldType === 'computed'">
                                          <v-text-field v-model="editFieldValues[field.FieldName]"
                                            placeholder="Tự động tính toán" variant="outlined" density="compact"
                                            hide-details="auto" readonly bg-color="grey-lighten-4"
                                            prepend-inner-icon="mdi-calculator-variant" class="wf-ant-input" />
                                        </div>
                                        <v-textarea v-else-if="field.FieldType === 'textarea'"
                                          v-model="editFieldValues[field.FieldName]" :readonly="isReadonlyStep"
                                          :disabled="isReadonlyStep"
                                          :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || String(editFieldValues[field.FieldName]).trim() === '')"
                                          variant="outlined" density="compact" rows="2" hide-details="auto"
                                          class="wf-ant-input bg-white" />
                                        <uc-select-user v-else-if="field.FieldType === 'signature'"
                                          v-model="editFieldValues[field.FieldName]" placeholder="Chọn người ký"
                                          clearable :readonly="isSignatureFieldReadonly"
                                          :disabled="isSignatureFieldReadonly"
                                          :error="!isSignatureFieldReadonly && (!editFieldValues[field.FieldName] || String(editFieldValues[field.FieldName]).trim() === '')"
                                          class="wf-ant-input bg-white font-weight-bold text-success" />
                                        <v-text-field v-else v-model="editFieldValues[field.FieldName]"
                                          :type="field.FieldType === 'number' ? 'number' : field.FieldType === 'date' ? 'date' : 'text'"
                                          :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                                          :error="!isReadonlyStep && ((field.IsRequired && (!editFieldValues[field.FieldName] || String(editFieldValues[field.FieldName]).trim() === '')) || (field.FieldType === 'date' && !!editFieldValues[field.FieldName] && !isValidDateValue(editFieldValues[field.FieldName])))"
                                          variant="outlined" density="compact" hide-details="auto"
                                          class="wf-ant-input bg-white" />
                                      </div>
                                    </v-col>
                                  </v-row>
                                  <!-- File fields of this group -->
                                  <v-row
                                    v-if="group.fields.filter(f => f.FieldType === 'file' || f.FieldType === 'image').length > 0"
                                    class="ma-0 mt-1">
                                    <v-col
                                      v-for="field in group.fields.filter(f => f.FieldType === 'file' || f.FieldType === 'image')"
                                      :key="field.FieldName" cols="12" md="6" class="pa-2">
                                      <div class="d-flex flex-column w-100">
                                        <div class="d-flex align-center justify-space-between mb-1 px-1">
                                          <div class="d-flex align-center ga-1 flex-wrap">
                                            <span class="text-caption text-grey-darken-3">
                                              {{ field.FieldLabel || field.FieldName }}
                                              <span v-if="field.IsRequired && !isReviewOrApproveStep"
                                                class="text-red font-weight-bold">*</span>
                                            </span>
                                            <v-tooltip
                                              v-if="templateDuplicatePlaceholders.indexOf(field.FieldName) !== -1"
                                              location="top"
                                              text="Trường này xuất hiện trong nhiều template của bước. Tất cả template sẽ dùng chung giá trị nhập vào. Để phân biệt, admin cần đổi tên placeholder trong file .docx tương ứng.">
                                              <template #activator="{ props }">
                                                <v-chip v-bind="props" size="x-small" color="primary" variant="tonal" class="font-weight-medium px-1 wf-kfd-h18px" prepend-icon="mdi-share-variant-outline">
                                                  Dùng chung
                                                </v-chip>
                                              </template>
                                            </v-tooltip>
                                          </div>
                                          <v-chip size="x-small" :color="getTypeBadgeInfo(field.FieldType).color" variant="tonal" class="font-weight-medium px-1 wf-kfd-h18px">
                                            {{ getTypeBadgeInfo(field.FieldType).label }}
                                          </v-chip>
                                        </div>
                                        <div
                                          class="border rounded-lg pa-3 bg-white d-flex flex-column justify-center align-center cursor-pointer shadow-sm"
                                          :style="isReadonlyStep ? 'border-color: #cbd5e1 !important; min-height: 80px; pointer-events: none; opacity: 0.9;' : 'border-color: #cbd5e1 !important; border-style: dashed !important; min-height: 80px;'"
                                          @click="triggerFieldFileInput(field.FieldName, false)">
                                          <input class="d-none" :ref="'detail_file_input_' + field.FieldName" type="file" @change="onFieldFileSelected($event, field.FieldName, editFieldValues)">
                                          <v-icon color="primary" class="mb-1" size="20"
                                            v-if="!isReadonlyStep && !editFieldValues[field.FieldName]">
                                            mdi-cloud-upload-outline
                                          </v-icon>
                                          <div v-if="editFieldValues[field.FieldName]"
                                            class="w-100 d-flex flex-column align-center" @click.stop>
                                            <template
                                              v-if="field.FieldType === 'image' || isImageFile(editFieldValues[field.FieldName])">
                                              <div class="position-relative border rounded-lg overflow-hidden bg-grey-lighten-4 mb-2 wf-kfd-w120px">
                                                <a :href="getFieldFileUrl(editFieldValues[field.FieldName])"
                                                  target="_blank" class="d-block w-100 h-100">
                                                  <v-img :src="getFieldFileUrl(editFieldValues[field.FieldName])" cover
                                                    width="100%" height="100%">
                                                    <template v-slot:placeholder>
                                                      <div class="d-flex align-center justify-center fill-height">
                                                        <v-progress-circular indeterminate color="grey-lighten-4"
                                                          size="18">
                                                        </v-progress-circular>
                                                      </div>
                                                    </template>
                                                  </v-img>
                                                </a>
                                                <v-btn icon size="x-small" color="error" class="position-absolute wf-kfd-top4px" variant="flat" v-if="!isReadonlyStep" @click="clearFieldFile(field.FieldName, editFieldValues)">
                                                  <v-icon size="10">mdi-close</v-icon>
                                                </v-btn>
                                              </div>
                                              <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank" class="text-blue-darken-3 text-truncate text-decoration-none font-weight-medium text-caption text-center wf-kfd-mw220px">
                                                {{ getFieldFileName(editFieldValues[field.FieldName]) }}
                                              </a>
                                            </template>
                                            <template v-else>
                                              <div class="d-flex align-center border rounded px-2 py-0.5 bg-blue-lighten-5 text-blue-darken-3 wf-kfd-fs11px-3">
                                                <v-icon size="12">mdi-paperclip</v-icon>
                                                <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank" class="text-blue-darken-3 text-truncate text-decoration-none font-weight-medium wf-kfd-mw200px">
                                                  {{ getFieldFileName(editFieldValues[field.FieldName]) }}
                                                </a>
                                                <v-btn icon size="x-small" variant="text" color="error" class="ml-1"
                                                  v-if="!isReadonlyStep"
                                                  @click="clearFieldFile(field.FieldName, editFieldValues)">
                                                  <v-icon size="10">mdi-close</v-icon>
                                                </v-btn>
                                              </div>
                                            </template>
                                          </div>
                                          <div class="text-caption text-grey-darken-1 wf-kfd-fs105px">
                                            {{ isReadonlyStep ? 'Không có tệp đính kèm' : 'Bấm để chọn file tài liệu' }}
                                          </div>
                                        </div>
                                      </div>
                                    </v-col>
                                  </v-row>
                                </div>
                                <div v-else class="text-caption text-grey py-2 pl-2 font-style-italic">Không có trường
                                  dữ liệu cho template này.</div>
                              </div>
                            </div>
                          </div>

                          <!-- Cấu hình khác: fields không thuộc template nào — editable -->
                          <div
                            v-if="templateUnmatchedFields.length > 0 && activeFormIdx === activeTemplateGroups.length"
                            class="wf-template-group">
                            <div
                              class="wf-template-group__header wf-template-group__header--other d-flex align-center mb-3">
                              <v-icon size="15" color="grey-darken-2" class="mr-2">mdi-dots-horizontal-circle-outline
                              </v-icon>
                              <span class="text-subtitle-2 font-weight-bold text-grey-darken-2">Cấu hình khác</span>
                              <v-chip size="x-small" color="grey" variant="tonal" class="font-weight-bold ml-2">{{
                                templateUnmatchedFields.length }} trường</v-chip>
                            </div>
                            <!-- Scroll container for other fields -->
                            <div class="wf-kfd-mh520px">
                              <v-row class="ma-0">
                                <v-col
                                  v-for="field in templateUnmatchedFields.filter(f => f.FieldType !== 'file' && f.FieldType !== 'image')"
                                  :key="field.FieldName" cols="12" md="6" class="pa-2">
                                  <div class="d-flex flex-column w-100">
                                    <div class="d-flex align-center justify-space-between mb-1 px-1">
                                      <span class="text-caption text-grey-darken-3">
                                        {{ field.FieldLabel || field.FieldName }}
                                        <span v-if="field.IsRequired && !isReviewOrApproveStep"
                                          class="text-red font-weight-bold">*</span>
                                      </span>
                                      <v-chip size="x-small" :color="getTypeBadgeInfo(field.FieldType).color" variant="tonal" class="font-weight-medium px-1 wf-kfd-h18px">
                                        {{ getTypeBadgeInfo(field.FieldType).label }}
                                      </v-chip>
                                    </div>
                                    <v-select v-if="field.FieldType === 'select' && field.DataSourceType === 'api'"
                                      v-model="editFieldValues[field.FieldName]"
                                      :items="apiDataSources[field.DataSourceApi]" item-title="Text" item-value="Value"
                                      :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                                      :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || editFieldValues[field.FieldName] === '')"
                                      variant="outlined" density="compact" hide-details="auto"
                                      class="wf-ant-input bg-white" />
                                    <v-select v-else-if="field.FieldType === 'select'"
                                      v-model="editFieldValues[field.FieldName]"
                                      :items="(field.FieldOptions || '').split(',')" :readonly="isReadonlyStep"
                                      :disabled="isReadonlyStep"
                                      :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || editFieldValues[field.FieldName] === '')"
                                      variant="outlined" density="compact" hide-details="auto"
                                      class="wf-ant-input bg-white" />
                                    <div v-else-if="field.FieldType === 'checkbox'" class="d-flex align-center">
                                      <v-checkbox :label="field.FieldOptions || ''"
                                        :model-value="Number(editFieldValues[field.FieldName]) === 1 || editFieldValues[field.FieldName] === true || editFieldValues[field.FieldName] === 'true'"
                                        :readonly="isReadonlyStep" :disabled="isReadonlyStep" density="compact"
                                        color="primary" hide-details
                                        @update:model-value="toggleSingleCheckbox(field.FieldName)" />
                                    </div>
                                    <div v-else-if="field.FieldType === 'rating'"
                                      class="border rounded-lg pa-2.5 bg-white d-flex align-center justify-space-between shadow-sm">
                                      <v-rating v-model="editFieldValues[field.FieldName]" color="amber"
                                        density="compact" :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                                        size="small" />
                                      <span class="text-caption font-weight-bold text-amber-darken-2 mr-1">{{
                                        Number(editFieldValues[field.FieldName] || 0).toFixed(1) }} / 5.0</span>
                                    </div>
                                    <div v-else-if="field.FieldType === 'computed'">
                                      <v-text-field v-model="editFieldValues[field.FieldName]"
                                        placeholder="Tự động tính toán" variant="outlined" density="compact"
                                        hide-details="auto" readonly bg-color="grey-lighten-4"
                                        prepend-inner-icon="mdi-calculator-variant" class="wf-ant-input" />
                                    </div>
                                    <v-textarea v-else-if="field.FieldType === 'textarea'"
                                      v-model="editFieldValues[field.FieldName]" :readonly="isReadonlyStep"
                                      :disabled="isReadonlyStep"
                                      :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || String(editFieldValues[field.FieldName]).trim() === '')"
                                      variant="outlined" density="compact" rows="2" hide-details="auto"
                                      class="wf-ant-input bg-white" />
                                    <uc-select-user v-else-if="field.FieldType === 'signature'"
                                      v-model="editFieldValues[field.FieldName]" placeholder="Chọn người ký" clearable
                                      :readonly="isSignatureFieldReadonly" :disabled="isSignatureFieldReadonly"
                                      :error="!isSignatureFieldReadonly && (!editFieldValues[field.FieldName] || String(editFieldValues[field.FieldName]).trim() === '')"
                                      class="wf-ant-input bg-white font-weight-bold text-success" />
                                    <v-text-field v-else v-model="editFieldValues[field.FieldName]"
                                      :type="field.FieldType === 'number' ? 'number' : field.FieldType === 'date' ? 'date' : 'text'"
                                      :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                                      :error="!isReadonlyStep && ((field.IsRequired && (!editFieldValues[field.FieldName] || String(editFieldValues[field.FieldName]).trim() === '')) || (field.FieldType === 'date' && !!editFieldValues[field.FieldName] && !isValidDateValue(editFieldValues[field.FieldName])))"
                                      variant="outlined" density="compact" hide-details="auto"
                                      class="wf-ant-input bg-white" />
                                  </div>
                                </v-col>
                              </v-row>
                              <!-- File/image fields -->
                              <v-row
                                v-if="templateUnmatchedFields.filter(f => f.FieldType === 'file' || f.FieldType === 'image').length > 0"
                                class="ma-0 mt-1">
                                <v-col
                                  v-for="field in templateUnmatchedFields.filter(f => f.FieldType === 'file' || f.FieldType === 'image')"
                                  :key="field.FieldName" cols="12" md="6" class="pa-2">
                                  <div class="d-flex flex-column w-100">
                                    <div class="d-flex align-center justify-space-between mb-1 px-1">
                                      <span class="text-caption text-grey-darken-3">
                                        {{ field.FieldLabel || field.FieldName }}
                                        <span v-if="field.IsRequired && !isReviewOrApproveStep"
                                          class="text-red font-weight-bold">*</span>
                                      </span>
                                      <v-chip size="x-small" :color="getTypeBadgeInfo(field.FieldType).color" variant="tonal" class="font-weight-medium px-1 wf-kfd-h18px">
                                        {{ getTypeBadgeInfo(field.FieldType).label }}
                                      </v-chip>
                                    </div>
                                    <div
                                      class="border rounded-lg pa-3 bg-white d-flex flex-column justify-center align-center cursor-pointer shadow-sm"
                                      :style="isReadonlyStep ? 'border-color: #cbd5e1 !important; min-height: 80px; pointer-events: none; opacity: 0.9;' : 'border-color: #cbd5e1 !important; border-style: dashed !important; min-height: 80px;'"
                                      @click="triggerFieldFileInput(field.FieldName, false)">
                                      <input class="d-none" :ref="'detail_file_input_' + field.FieldName" type="file" @change="onFieldFileSelected($event, field.FieldName, editFieldValues)">
                                      <v-icon color="primary" class="mb-1" size="20"
                                        v-if="!isReadonlyStep && !editFieldValues[field.FieldName]">
                                        mdi-cloud-upload-outline</v-icon>
                                      <span v-if="editFieldValues[field.FieldName]" class="text-caption text-primary font-weight-bold text-truncate wf-kfd-mw180px">{{ editFieldValues[field.FieldName] }}</span>
                                      <span v-else class="text-caption text-grey">{{ isReadonlyStep ? 'Chưa có file' :
                                        'Bấm để tải lên' }}</span>
                                    </div>
                                  </div>
                                </v-col>
                              </v-row>
                            </div>
                          </div>
                        </v-col>
                      </v-row>

                      <!-- Empty state: không có field nào cho bước này -->
                      <div v-if="!customFieldsForCurrentStep.length" class="text-center py-6 text-caption text-grey">
                        <v-icon size="24" color="grey-lighten-1" class="mb-1">mdi-alert-circle-outline</v-icon>
                        <div>Không có trường dữ liệu tùy chỉnh cho bước hiện tại.</div>
                      </div>
                    </template>

                    <!-- SINGLE TEMPLATE MODE (legacy): giữ nguyên layout cũ -->
                    <div v-else-if="customFieldsForCurrentStep.length> 0" class="d-flex flex-column wf-kfd-mh520px-3">
                      <v-row v-if="normalFieldsForCurrentStep.length > 0" class="ma-0">
                        <v-col v-for="field in normalFieldsForCurrentStep" :key="field.FieldName" cols="12" md="6"
                          class="pa-2">
                          <div class="d-flex flex-column w-100">
                            <div class="d-flex align-center justify-space-between mb-1 px-1">
                              <span class="text-caption text-grey-darken-3">
                                {{ field.FieldLabel || field.FieldName }} <span
                                  v-if="field.IsRequired && !isReviewOrApproveStep"
                                  class="text-red font-weight-bold">*</span>
                              </span>
                              <v-chip size="x-small" :color="getTypeBadgeInfo(field.FieldType).color" variant="tonal" class="font-weight-medium px-1 wf-kfd-h18px">
                                {{ getTypeBadgeInfo(field.FieldType).label }}
                              </v-chip>
                            </div>

                            <!-- dynamic render input -->
                            <!-- Select Field API -->
                            <v-select v-if="field.FieldType === 'select' && field.DataSourceType === 'api'"
                              v-model="editFieldValues[field.FieldName]" :items="apiDataSources[field.DataSourceApi]"
                              item-title="Text" item-value="Value" :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                              :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || editFieldValues[field.FieldName] === '')"
                              variant="outlined" density="compact" hide-details="auto" class="wf-ant-input bg-white" />

                            <!-- Select Field Static -->
                            <v-select v-else-if="field.FieldType === 'select'"
                              v-model="editFieldValues[field.FieldName]" :items="(field.FieldOptions || '').split(',')"
                              :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                              :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || editFieldValues[field.FieldName] === '')"
                              variant="outlined" density="compact" hide-details="auto" class="wf-ant-input bg-white" />

                            <!-- File Upload -->
                            <div v-else-if="field.FieldType === 'file' || field.FieldType === 'image'"
                              class="border rounded-lg pa-3 bg-white d-flex flex-column justify-center align-center cursor-pointer shadow-sm"
                              :style="isReadonlyStep ? 'border-color: #cbd5e1 !important; min-height: 80px; pointer-events: none; opacity: 0.9;' : 'border-color: #cbd5e1 !important; border-style: dashed !important; min-height: 80px;'"
                              @click="triggerFieldFileInput(field.FieldName, false)">
                              <input class="d-none" :ref="'detail_file_input_' + field.FieldName" type="file" @change="onFieldFileSelected($event, field.FieldName, editFieldValues)">
                              <v-icon color="primary" class="mb-1" size="20"
                                v-if="!isReadonlyStep && !editFieldValues[field.FieldName]">
                                mdi-cloud-upload-outline</v-icon>
                              <div v-if="editFieldValues[field.FieldName]" class="w-100 d-flex flex-column align-center"
                                @click.stop>
                                <template
                                  v-if="field.FieldType === 'image' || isImageFile(editFieldValues[field.FieldName])">
                                  <div class="position-relative border rounded-lg overflow-hidden bg-grey-lighten-4 mb-2 wf-kfd-w120px">
                                    <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank"
                                      class="d-block w-100 h-100">
                                      <v-img :src="getFieldFileUrl(editFieldValues[field.FieldName])" cover width="100%"
                                        height="100%">
                                        <template v-slot:placeholder>
                                          <div class="d-flex align-center justify-center fill-height">
                                            <v-progress-circular indeterminate color="grey-lighten-4" size="18">
                                            </v-progress-circular>
                                          </div>
                                        </template>
                                      </v-img>
                                    </a>
                                    <v-btn icon size="x-small" color="error" class="position-absolute wf-kfd-top4px" variant="flat" v-if="!isReadonlyStep" @click="clearFieldFile(field.FieldName, editFieldValues)">
                                      <v-icon size="10">mdi-close</v-icon>
                                    </v-btn>
                                  </div>
                                  <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank" class="text-blue-darken-3 text-truncate text-decoration-none font-weight-medium text-caption text-center wf-kfd-mw220px">
                                    {{
                                    getFieldFileName(editFieldValues[field.FieldName])
                                    }}
                                  </a>
                                </template>
                                <template v-else>
                                  <div class="d-flex align-center border rounded px-2 py-0.5 bg-blue-lighten-5 text-blue-darken-3 wf-kfd-fs11px-3">
                                    <v-icon size="12">mdi-paperclip</v-icon>
                                    <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank" class="text-blue-darken-3 text-truncate text-decoration-none font-weight-medium wf-kfd-mw200px">
                                      {{
                                      getFieldFileName(editFieldValues[field.FieldName])
                                      }}
                                    </a>
                                    <v-btn icon size="x-small" variant="text" color="error" class="ml-1"
                                      v-if="!isReadonlyStep" @click="clearFieldFile(field.FieldName, editFieldValues)">
                                      <v-icon size="10">mdi-close</v-icon>
                                    </v-btn>
                                  </div>
                                </template>
                              </div>
                              <div class="text-caption text-grey-darken-1 wf-kfd-fs105px">
                                {{ isReadonlyStep ? 'Không có tệp đính kèm' :
                                'Bấm để chọn file tài liệu' }}
                              </div>
                            </div>

                            <!-- Checkbox Field -->
                            <div v-else-if="field.FieldType === 'checkbox'" class="d-flex align-center">
                              <v-checkbox :label="field.FieldOptions || ''"
                                :model-value="Number(editFieldValues[field.FieldName]) === 1 || editFieldValues[field.FieldName] === true || editFieldValues[field.FieldName] === 'true'"
                                :readonly="isReadonlyStep" :disabled="isReadonlyStep" density="compact" color="primary"
                                hide-details @update:model-value="toggleSingleCheckbox(field.FieldName)" />
                            </div>

                            <!-- Rating Star Field -->
                            <div v-else-if="field.FieldType === 'rating'"
                              class="border rounded-lg pa-2.5 bg-white d-flex align-center justify-space-between shadow-sm">
                              <v-rating v-model="editFieldValues[field.FieldName]" color="amber" density="compact"
                                :readonly="isReadonlyStep" :disabled="isReadonlyStep" size="small" />
                              <span class="text-caption font-weight-bold text-amber-darken-2 mr-1">
                                {{ Number(editFieldValues[field.FieldName] ||
                                0).toFixed(1) }} / 5.0
                              </span>
                            </div>

                            <!-- Computed Field -->
                            <div v-else-if="field.FieldType === 'computed'">
                              <v-text-field v-model="editFieldValues[field.FieldName]" placeholder="Tự động tính toán"
                                variant="outlined" density="compact" hide-details="auto" readonly
                                bg-color="grey-lighten-4" prepend-inner-icon="mdi-calculator-variant"
                                class="wf-ant-input" />
                            </div>

                            <!-- Textarea -->
                            <v-textarea v-else-if="field.FieldType === 'textarea'"
                              v-model="editFieldValues[field.FieldName]" :readonly="isReadonlyStep"
                              :disabled="isReadonlyStep"
                              :error="!isReadonlyStep && field.IsRequired && (!editFieldValues[field.FieldName] || String(editFieldValues[field.FieldName]).trim() === '')"
                              variant="outlined" density="compact" rows="2" hide-details="auto"
                              class="wf-ant-input bg-white" />

                            <!-- Signature Field -->
                            <div v-else-if="field.FieldType === 'signature'">
                              <uc-select-user v-model="editFieldValues[field.FieldName]" placeholder="Chọn người ký"
                                clearable :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                                class="wf-ant-input bg-white font-weight-bold text-success" />
                            </div>

                            <!-- Text / Date / Number -->
                            <v-text-field v-else v-model="editFieldValues[field.FieldName]"
                              :type="field.FieldType === 'number' ? 'number' : field.FieldType === 'date' ? 'date' : 'text'"
                              :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                              :error="!isReadonlyStep && ((field.IsRequired && (!editFieldValues[field.FieldName] || String(editFieldValues[field.FieldName]).trim() === '')) || (field.FieldType === 'date' && !!editFieldValues[field.FieldName] && !isValidDateValue(editFieldValues[field.FieldName])))"
                              variant="outlined" density="compact" hide-details="auto" class="wf-ant-input bg-white" />
                          </div>
                        </v-col>
                      </v-row>

                      <!-- Nhóm: Chữ ký -->
                      <template v-if="signatureFieldsForCurrentStep.length > 0">
                        <v-divider class="mt-4 mb-3 wf-kfd-bcvarwfborde"></v-divider>
                        <div class="d-flex align-center ga-2 mb-3 px-3 py-2 mx-1 wf-kfd-bgvarwfaccen">
                          <v-icon class="wf-kfd-cvarwfaccen" size="14">mdi-pencil-edit-outline</v-icon>
                          <span class="wf-kfd-fs10px-3">Cấu
                            hình chữ ký</span>
                          <div class="flex-grow-1"></div>
                          <span class="wf-kfd-fs10px-4">{{
                            signatureFieldsForCurrentStep.length }} trường</span>
                        </div>
                        <v-row class="ma-0">
                          <v-col v-for="field in signatureFieldsForCurrentStep" :key="field.FieldName" cols="12" md="6"
                            class="pa-2">
                            <div class="d-flex flex-column w-100">
                              <div class="d-flex align-center justify-space-between mb-1 px-1">
                                <span class="text-caption text-grey-darken-3">
                                  {{ field.FieldLabel || field.FieldName }} <span
                                    v-if="field.IsRequired && !isReviewOrApproveStep"
                                    class="text-red font-weight-bold">*</span>
                                </span>
                                <v-chip size="x-small" :color="getTypeBadgeInfo(field.FieldType).color" variant="tonal" class="font-weight-medium px-1 wf-kfd-h18px">
                                  {{ getTypeBadgeInfo(field.FieldType).label }}
                                </v-chip>
                              </div>
                              <uc-select-user v-model="editFieldValues[field.FieldName]" placeholder="Chọn người ký"
                                clearable :readonly="isReadonlyStep" :disabled="isReadonlyStep"
                                class="wf-ant-input bg-white font-weight-bold text-success" />
                            </div>
                          </v-col>
                        </v-row>
                      </template>

                      <!-- Nhóm: Hồ sơ đính kèm -->
                      <template v-if="fileFieldsForCurrentStep.length > 0">
                        <v-divider class="mt-4 mb-3 wf-kfd-bcvarwfborde"></v-divider>
                        <div class="d-flex align-center ga-2 mb-3 px-3 py-2 mx-1 wf-kfd-bgvarwfprima">
                          <v-icon class="wf-kfd-cvarwfprima" size="14">mdi-paperclip</v-icon>
                          <span class="wf-kfd-fs10px-3">Hồ
                            sơ đính kèm</span>
                          <div class="flex-grow-1"></div>
                          <span class="wf-kfd-fs10px-4">{{
                            fileFieldsForCurrentStep.length }} tệp</span>
                        </div>
                        <v-row class="ma-0">
                          <v-col v-for="field in fileFieldsForCurrentStep" :key="field.FieldName" cols="12" md="6"
                            class="pa-2">
                            <div class="d-flex flex-column w-100">
                              <div class="d-flex align-center justify-space-between mb-1 px-1">
                                <span class="text-caption text-grey-darken-3">
                                  {{ field.FieldLabel || field.FieldName }} <span
                                    v-if="field.IsRequired && !isReviewOrApproveStep"
                                    class="text-red font-weight-bold">*</span>
                                </span>
                                <v-chip size="x-small" :color="getTypeBadgeInfo(field.FieldType).color" variant="tonal" class="font-weight-medium px-1 wf-kfd-h18px">
                                  {{ getTypeBadgeInfo(field.FieldType).label }}
                                </v-chip>
                              </div>
                              <div
                                class="border rounded-lg pa-3 bg-white d-flex flex-column justify-center align-center cursor-pointer shadow-sm"
                                :style="isReadonlyStep ? 'border-color: #cbd5e1 !important; min-height: 80px; pointer-events: none; opacity: 0.9;' : 'border-color: #cbd5e1 !important; border-style: dashed !important; min-height: 80px;'"
                                @click="triggerFieldFileInput(field.FieldName, false)">
                                <input class="d-none" :ref="'detail_file_input_' + field.FieldName" type="file" @change="onFieldFileSelected($event, field.FieldName, editFieldValues)">
                                <v-icon color="primary" class="mb-1" size="20"
                                  v-if="!isReadonlyStep && !editFieldValues[field.FieldName]">
                                  mdi-cloud-upload-outline</v-icon>
                                <div v-if="editFieldValues[field.FieldName]"
                                  class="w-100 d-flex flex-column align-center" @click.stop>
                                  <template
                                    v-if="field.FieldType === 'image' || isImageFile(editFieldValues[field.FieldName])">
                                    <div class="position-relative border rounded-lg overflow-hidden bg-grey-lighten-4 mb-2 wf-kfd-w120px">
                                      <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank"
                                        class="d-block w-100 h-100">
                                        <v-img :src="getFieldFileUrl(editFieldValues[field.FieldName])" cover
                                          width="100%" height="100%">
                                          <template v-slot:placeholder>
                                            <div class="d-flex align-center justify-center fill-height">
                                              <v-progress-circular indeterminate color="grey-lighten-4" size="18">
                                              </v-progress-circular>
                                            </div>
                                          </template>
                                        </v-img>
                                      </a>
                                      <v-btn icon size="x-small" color="error" class="position-absolute wf-kfd-top4px" variant="flat" v-if="!isReadonlyStep" @click="clearFieldFile(field.FieldName, editFieldValues)">
                                        <v-icon size="10">mdi-close</v-icon>
                                      </v-btn>
                                    </div>
                                    <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank" class="text-blue-darken-3 text-truncate text-decoration-none font-weight-medium text-caption text-center wf-kfd-mw220px">
                                      {{ getFieldFileName(editFieldValues[field.FieldName]) }}
                                    </a>
                                  </template>
                                  <template v-else>
                                    <div class="d-flex align-center border rounded px-2 py-0.5 bg-blue-lighten-5 text-blue-darken-3 wf-kfd-fs11px-3">
                                      <v-icon size="12">mdi-paperclip</v-icon>
                                      <a :href="getFieldFileUrl(editFieldValues[field.FieldName])" target="_blank" class="text-blue-darken-3 text-truncate text-decoration-none font-weight-medium wf-kfd-mw200px">
                                        {{ getFieldFileName(editFieldValues[field.FieldName]) }}
                                      </a>
                                      <v-btn icon size="x-small" variant="text" color="error" class="ml-1"
                                        v-if="!isReadonlyStep"
                                        @click="clearFieldFile(field.FieldName, editFieldValues)">
                                        <v-icon size="10">mdi-close</v-icon>
                                      </v-btn>
                                    </div>
                                  </template>
                                </div>
                                <div class="text-caption text-grey-darken-1 wf-kfd-fs105px">
                                  {{ isReadonlyStep ? 'Không có tệp đính kèm' : 'Bấm để chọn file tài liệu' }}
                                </div>
                              </div>
                            </div>
                          </v-col>
                        </v-row>
                      </template>
                    </div>
                    <div v-else class="text-center py-6 text-caption text-grey">
                      <v-icon size="24" color="grey-lighten-1" class="mb-1">
                        mdi-alert-circle-outline</v-icon>
                      <div>Không có trường dữ liệu tùy chỉnh cho bước hiện tại.</div>
                    </div>

                    <!-- Các dữ liệu khác section -->
                    <v-expansion-panels v-if="otherCustomFields.length > 0"
                      class="mt-4 shadow-sm border rounded-lg overflow-hidden">
                      <v-expansion-panel bg-color="grey-lighten-5">
                        <v-expansion-panel-title class="py-2 text-caption font-weight-bold text-grey-darken-3">
                          <v-icon start size="16" color="grey-darken-2" class="mr-1">mdi-chevron-down-circle-outline
                          </v-icon>
                          Các dữ liệu khác
                        </v-expansion-panel-title>
                        <v-expansion-panel-text class="pa-2">
                          <v-row class="ma-0">
                            <v-col v-for="field in otherCustomFields" :key="field.FieldName" cols="12" md="6"
                              class="pa-2 border-bottom border-light">
                              <div class="d-flex align-center justify-space-between py-1">
                                <span class="text-caption text-grey-darken-2 font-weight-medium mr-2">{{
                                  field.FieldLabel || field.FieldName }}:</span>
                                <span class="text-caption text-grey-darken-4 font-weight-bold text-right">
                                  {{ editFieldValues[field.FieldName] != null &&
                                  String(editFieldValues[field.FieldName]).trim() !== '' ?
                                  editFieldValues[field.FieldName] : '-' }}
                                </span>
                              </div>
                            </v-col>
                          </v-row>
                        </v-expansion-panel-text>
                      </v-expansion-panel>
                    </v-expansion-panels>
                  </div>
                </div>

                <!-- Sub Tab: Checklist công việc -->
                <div v-else-if="detailRightSubTab === 'checklist'" class="bg-white border rounded-lg shadow-sm pa-5 d-flex flex-column w-100 wf-kfd-bd1pxsolide2">
                  <div class="d-flex align-center justify-space-between mb-4">
                    <div class="d-flex align-center ga-2">
                      <v-icon color="success" size="20">mdi-playlist-check</v-icon>
                      <span class="text-subtitle-2 font-weight-bold text-grey-darken-4">Checklist
                        công việc</span>
                      <v-chip size="x-small" color="primary" variant="flat" class="font-weight-bold px-3">
                        <v-icon start size="14">mdi-check-circle-outline</v-icon>
                        {{ completedTasksForCurrentStep.length }} / {{
                        instanceTasksForCurrentStep.length }}
                      </v-chip>
                    </div>
                    <div class="d-flex align-center ga-3 flex-wrap">
                      <v-btn-toggle class="wf-kfd-h26px" v-model="taskFilterMode" mandatory color="primary" density="compact">
                        <v-btn value="ALL" size="x-small" class="text-caption px-3 wf-kfd-ttnone">Tất cả
                        </v-btn>
                        <v-btn value="PENDING" size="x-small" class="text-caption px-3 wf-kfd-ttnone">Chưa
                          làm</v-btn>
                      </v-btn-toggle>

                      <!-- Nút thêm nhiệm vụ thủ công -->
                      <v-btn color="primary" size="small" class="font-weight-bold px-3 text-caption text-white wf-kfd-br4px-2" height="26" @click="dialogThemTask = true">
                        <v-icon start size="14">mdi-plus</v-icon> Thêm nhiệm vụ
                      </v-btn>
                    </div>
                  </div>

                  <!-- Subtasks Table -->
                  <div v-if="filteredTasksForCurrentStep.length > 0">
                    <v-table class="wf-compact-table bg-white" density="comfortable">
                      <thead>
                        <tr>
                          <th class="text-center wf-kfd-w80px">Hoàn thành</th>
                          <th class="text-left">Tên nhiệm vụ</th>
                          <th class="text-left">Ghi chú</th>
                          <th class="text-center wf-kfd-w130px">Hạn chót</th>
                          <th class="text-center wf-kfd-w130px">Trạng thái</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="task in filteredTasksForCurrentStep" :key="task.TaskID"
                          :class="{ 'bg-grey-lighten-5': task.Status === 'DONE' }">
                          <td class="text-center">
                            <v-checkbox-btn :model-value="task.Status === 'DONE'" color="success" density="compact"
                              hide-details class="d-inline-flex" @update:model-value="toggleTaskStatus(task)" />
                          </td>
                          <td class="text-left">
                            <div class="d-flex align-center ga-1.5 flex-wrap">
                              <span class="text-caption"
                                :class="{ 'text-decoration-line-through text-grey': task.Status === 'DONE' }">
                                {{sanitizeTaskText(task.TaskName) || '-' }}
                                <span v-if="task.IsRequired" class="text-red font-weight-bold">*</span>
                              </span>
                            </div>
                          </td>
                          <td class="text-left text-caption text-grey-darken-1">{{
                            sanitizeTaskText(task.Description) || '-' }}</td>
                          <td class="text-center text-caption text-grey">
                            {{ task.DueDate ? formatDateTime(task.DueDate) : '---' }}
                          </td>
                          <td class="text-center">
                            <v-chip size="x-small" :color="task.Status === 'DONE' ? 'success' : 'warning'"
                              variant="tonal" class="font-weight-bold px-2">
                              {{ task.Status === 'DONE' ? 'Đã xong' : 'Chờ xử lý' }}
                            </v-chip>
                          </td>
                        </tr>
                      </tbody>
                    </v-table>
                  </div>
                  <div v-else class="text-center py-6 text-caption text-grey">
                    <v-icon size="24" color="grey-lighten-1" class="mb-1">mdi-alert-circle-outline
                    </v-icon>
                    <div>Không có nhiệm vụ con nào trong danh sách.</div>
                  </div>
                </div>

                <!-- Sub Tab: Danh mục hồ sơ đính kèm -->
                <div v-else-if="detailRightSubTab === 'files'" class="bg-white border rounded-lg shadow-sm pa-5 d-flex flex-column w-100 wf-kfd-bd1pxsolide2">
                  <v-row class="ma-0 align-center justify-space-between mb-4 wf-kfd-flexsh0">
                    <div class="d-flex align-center ga-2">
                      <v-icon color="primary" size="20">mdi-folder-open-outline</v-icon>
                      <span class="text-subtitle-2 font-weight-bold text-grey-darken-4">Danh mục tài liệu yêu cầu</span>
                    </div>
                  </v-row>
                  <uc-kanban-checklist :items="checklistItems" :readonly="isReviewOrApproveStep"
                    @update:items="checklistItems = $event" @item-change="saveChecklistItem"
                    @upload-requested="onChecklistUploadRequested" class="w-100" />
                </div>

                <!-- Sub Tab: Nhật ký hoạt động -->
                <div v-else-if="detailRightSubTab === 'history'" class="bg-white border rounded-lg shadow-sm pa-5 d-flex flex-column w-100 wf-kfd-bd1pxsolide2">
                  <div class="d-flex align-center justify-space-between mb-4 pb-3 border-bottom wf-kfd-border1pxsolide2">
                    <div class="d-flex align-center ga-2">
                      <v-icon size="18" color="primary">mdi-history</v-icon>
                      <span class="text-subtitle-2 font-weight-bold text-grey-darken-4 text-uppercase wf-kfd-fs13px-2">Nhật ký hoạt động</span>
                    </div>
                    <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-bold px-2">{{
                      logs.length }}</v-chip>
                  </div>

                  <!-- History Timeline Premium inside a scrollable box -->
                  <div class="wf-kfd-ovyauto-2">
                    <div v-if="logs.length> 0" class="premium-timeline wf-kfd-paddin8px">
                      <div v-for="log in logs" :key="log.LogID" class="premium-timeline-item wf-kfd-paddin20px">
                        <!-- Left Side: Indicator & Line -->
                        <div class="timeline-indicator-wrapper wf-kfd-w24px">
                          <div class="timeline-line wf-kfd-top24px"></div>
                          <div class="timeline-node"
                            :style="{ backgroundColor: 'white', borderColor: getLogStatusColor(log.ActionCode), borderWidth: '2px', borderStyle: 'solid', width: '22px', height: '22px', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '50%' }">
                            <v-icon size="12" :color="getLogStatusColor(log.ActionCode)">
                              {{ getLogIcon(log.ActionCode) }}
                            </v-icon>
                          </div>
                        </div>
                        <!-- Right Side: Content Card -->
                        <div class="timeline-content-card wf-kfd-pad12px">
                          <!-- Header: Event description and timeline details -->
                          <div class="d-flex align-start flex-wrap ga-2 text-left w-100">
                            <v-chip size="x-small" :color="getLogChipColor(log.ActionCode)" variant="tonal" class="font-weight-bold px-2 wf-kfd-fs10px-6">
                              {{ getLogChipText(log.ActionCode) }}
                            </v-chip>
                            <div class="log-description text-caption font-weight-bold text-grey-darken-4 wf-kfd-fs12px-3">
                              {{ getLogDescription(log) }}
                            </div>
                          </div>

                          <!-- Sub-info: step name & time -->
                          <div class="d-flex align-center mt-1.5 text-left flex-wrap ga-2 wf-kfd-fs11px-6">
                            <div class="d-flex align-center">
                              <v-icon size="13" class="mr-1 text-grey-darken-1">mdi-timeline-outline</v-icon>
                              <span>Bước quy trình: <span class="font-weight-semibold text-grey-darken-3">{{
                                  getStepNameByOrder(log.StepOrder) }}</span></span>
                            </div>
                            <span class="text-grey-lighten-1">•</span>
                            <div class="d-flex align-center">
                              <v-icon size="13" class="mr-1 text-grey-darken-1">mdi-clock-outline</v-icon>
                              <span>Thời gian: <span class="font-weight-semibold text-grey-darken-3">{{
                                  formatDateTime(log.CreateTime) }}</span></span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div v-else class="text-center py-6 text-caption text-grey">
                      <v-icon size="32" color="grey-lighten-1" class="mb-1">mdi-history-off
                      </v-icon>
                      <div>Chưa có nhật ký hoạt động.</div>
                    </div>
                  </div>
                </div>

              </div>
            </div>
          </div>
        </template>



      </div>
    </div>

    <!-- Dialog Thêm Nhiệm vụ Con Thủ công (Checklist) -->
    <v-dialog v-model="dialogThemTask" max-width="480" persistent>
      <v-card class="wf-dialog-card wf-kfd-br8px">
        <v-card-title class="d-flex align-center justify-space-between pa-2 pl-4 border-bottom bg-primary text-white">
          <div class="d-flex align-center ga-2">
            <span class="text-subtitle-1 font-weight-bold text-white">Thêm nhiệm vụ mới</span>
          </div>
          <v-btn icon="mdi-close" variant="text" size="small" color="white" @click="dialogThemTask = false" />
        </v-card-title>

        <v-card-text class="pa-5">
          <div class="text-caption text-grey-darken-3 mb-1.5 text-left wf-kfd-fs13px">Tên nhiệm vụ con</div>
          <v-text-field v-model="taskMoiName" placeholder="Nhập tên nhiệm vụ con..." class="wf-ant-input mb-4 text-left"
            variant="outlined" density="compact" hide-details="auto" @keyup.enter="themNhiemVuThuCong"></v-text-field>

          <v-checkbox v-model="taskMoiIsRequired" label="Đây là nhiệm vụ bắt buộc hoàn thành" color="error"
            density="compact" hide-details class="text-left"></v-checkbox>
        </v-card-text>

        <v-card-actions class="px-5 pb-5 pt-0 d-flex justify-end ga-2">
          <v-btn color="primary" variant="flat" class="font-weight-bold text-caption text-white px-4 wf-kfd-br4px" @click="themNhiemVuThuCong" height="32">
            <v-icon start size="14">mdi-check</v-icon> Lưu lại
          </v-btn>
          <v-btn variant="outlined" class="font-weight-bold text-caption px-4 wf-kfd-bcd9d9d9" @click="dialogThemTask = false" height="32">
            Hủy
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog cấu hình nhãn dán cho hồ sơ -->
    <v-dialog v-model="dialogSuaNhan" max-width="450" persistent>
      <v-card class="wf-dialog-card wf-kfd-br8px">
        <v-card-title class="d-flex align-center justify-space-between pa-2 pl-4 border-bottom bg-primary text-white">
          <span class="text-subtitle-1 font-weight-bold text-white">Cấu hình nhãn dán</span>
          <v-btn icon="mdi-close" variant="text" size="small" color="white" @click="dialogSuaNhan = false"></v-btn>
        </v-card-title>
        <v-card-text class="pa-5">
          <div class="text-caption text-grey-darken-3 mb-1.5 text-left wf-kfd-fs13px">Chọn nhãn dán:</div>
          <v-autocomplete v-model="nhanDaChon" :items="danhSachNhan" item-title="TagName" item-value="Tag"
            placeholder="Chọn nhãn..." multiple chips closable-chips variant="outlined" density="compact"
            class="wf-ant-input mb-4 text-left" hide-details="auto">
            <!-- Custom chip template -->
            <template v-slot:chip="{ props, item }">
              <v-chip v-bind="props" size="x-small" :style="{
                  backgroundColor: getTagColorLight(item.raw.Tag),
                  color: getTagTextColorDark(item.raw.Tag),
                  border: '1px dashed ' + getTagBorderColor(item.raw.Tag),
                  fontSize: '9px',
                  height: '18px',
                  fontWeight: '700',
                  borderRadius: '4px',
                  margin: '1px'
                }" class="px-2">
                {{ item.raw.TagName }}
              </v-chip>
            </template>
            <!-- Custom item template -->
            <template v-slot:item="{ props, item }">
              <v-list-item v-bind="props" density="compact" class="py-0.5 min-height-24">
                <template v-slot:prepend="{ isSelected }">
                  <v-checkbox-btn :model-value="isSelected" density="compact" color="primary" class="mr-1">
                  </v-checkbox-btn>
                  <div
                    :style="{ backgroundColor: getTagBorderColor(item.raw.Tag), width: '8px', height: '8px', borderRadius: '50%', marginRight: '8px' }">
                  </div>
                </template>
                <template v-slot:title>
                  <span class="wf-kfd-fs105px-2">{{ item.raw.TagName
                    }}</span>
                </template>
              </v-list-item>
            </template>
          </v-autocomplete>
        </v-card-text>
        <v-card-actions class="px-5 pb-5 pt-0 d-flex justify-end ga-2">
          <v-btn color="primary" variant="flat" class="font-weight-bold text-caption text-white px-4 wf-kfd-br4px" height="32" @click="luuNhan">
            <v-icon start size="14">mdi-check</v-icon> Lưu lại
          </v-btn>
          <v-btn variant="outlined" class="font-weight-bold text-caption px-4 wf-kfd-bcd9d9d9" @click="dialogSuaNhan = false" height="32">
            Hủy
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog xem trước PDF mẫu in -->
    <v-dialog v-model="dialog.previewPdf" fullscreen persistent transition="dialog-bottom-transition">
      <v-card class="wf-kfd-br0">
        <div class="d-flex align-center justify-space-between px-6 py-3 bg-white border-bottom shadow-sm wf-kfd-flexsh0-2">
          <div class="d-flex align-center ga-2">
            <v-icon color="primary" size="20">mdi-eye-outline</v-icon>
            <span class="text-body-1 font-weight-bold text-grey-darken-4">Xem trước tài liệu PDF</span>
          </div>
          <v-btn icon="mdi-close" variant="text" color="grey-darken-2" size="small"
            @click="dialog.previewPdf = false" />
        </div>
        <v-card-text class="pa-0 flex-grow-1 wf-kfd-ovhidden">
          <div v-if="isGeneratingPreview" class="d-flex align-center justify-center fill-height bg-white">
            <div class="text-center">
              <v-progress-circular indeterminate color="primary" size="48" class="mb-3" />
              <div class="text-body-2 text-grey-darken-1">Đang kết xuất và chuẩn bị tài liệu PDF...</div>
            </div>
          </div>
          <iframe v-else-if="previewPdfUrl" :src="previewPdfUrl" class="w-100 h-100 wf-kfd-bdnone"/>
          <div v-else class="d-flex align-center justify-center fill-height text-white">
            <div class="text-center">
              <v-icon size="48" color="grey">mdi-alert-circle-outline</v-icon>
              <div class="text-subtitle-1 mt-2 text-grey">Không thể tải hoặc kết xuất bản xem trước tài
                liệu.</div>
            </div>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <!-- Dialog ký số toàn màn hình -->
    <v-dialog v-model="dialog.signDocument" fullscreen transition="dialog-bottom-transition">
      <v-card class="bg-grey-lighten-4">
        <!-- Dialog Header -->
        <v-toolbar color="primary" dark>
          <v-btn icon @click="dialog.signDocument = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
          <v-toolbar-title class="text-subtitle-1 font-weight-bold">
            KÝ SỐ TÀI LIỆU QUY TRÌNH
          </v-toolbar-title>
          <v-spacer></v-spacer>
          <div class="text-caption mr-4 text-white opacity-80" v-if="overview">
            Hồ sơ: {{ overview.InstanceName }}
          </div>
        </v-toolbar>

        <!-- Dialog Content Workspace -->
        <v-card-text class="pa-0 d-flex flex-grow-1 wf-kfd-hcalc100vh6">
          <div class="d-flex w-100 h-100 overflow-hidden">

            <!-- Left Workspace: PDF Viewer Canvas -->
            <div class="flex-grow-1 d-flex flex-column wf-kfd-ovhidden-2">
              <div class="d-flex align-center justify-space-between px-4 py-2 border-bottom bg-white">
                <div class="d-flex align-center ga-3">
                  <span class="text-subtitle-2 font-weight-bold text-grey-darken-3">
                    {{ overview.CurrentDocumentFileName || overview.SourceFileName || 'Tài liệu quy trình' }}
                  </span>
                  <v-chip size="x-small" color="primary" variant="tonal">
                    Trang {{ previewPageNo }}
                  </v-chip>
                </div>
                <v-btn class="wf-btn" variant="outlined" color="primary" size="small" :disabled="!documentViewUrl"
                  @click="previewDocument">
                  <v-icon start size="14">mdi-open-in-new</v-icon>
                  Mở toàn màn hình
                </v-btn>
              </div>

              <!-- [MULTI-TEMPLATE] Slot switcher tabs -->
              <div v-if="activeTemplates && activeTemplates.length > 1"
                class="d-flex align-center px-4 py-1 border-bottom bg-white ga-1">
                <span class="text-caption text-grey-darken-2 mr-2">Mẫu in:</span>
                <v-btn v-for="slot in activeTemplates" :key="'slot-tab-' + slot.SlotIdx" size="x-small" variant="tonal"
                  :color="activeCanvasSlotIdx === slot.SlotIdx ? 'primary' : 'grey'"
                  class="font-weight-medium text-caption" @click="switchCanvasSlot(slot.SlotIdx)">
                  {{ slot.Label || ('Mẫu ' + (slot.SlotIdx + 1)) }}
                </v-btn>
              </div>

              <div class="flex-grow-1 d-flex justify-center align-center pa-4 wf-kfd-ovauto">
                <div class="h-100 w-100 d-flex align-center justify-center">
                  <uc-request-sign-canvas class="wf-kfd-mh100" ref="signCanvasRef" :file-url="documentViewUrl" :sign-boxes="canvasSignBoxes" :active-page="previewPageNo" :selected-box-id="selectedPreviewBoxId" @update-active-page="onCanvasActivePageChange" @select-box="onCanvasSelectBox">
                  </uc-request-sign-canvas>
                </div>
              </div>
            </div>

            <!-- Right Sidebar: Action & Status Panel -->
            <div class="d-flex flex-column pa-4 border-left bg-white wf-kfd-w380px">

              <!-- Thao tác Ký số / Duyệt -->
              <div class="mb-4 rounded-lg border pa-4 wf-kfd-bgf8fafc">
                <div class="d-flex align-center justify-space-between mb-2">
                  <span class="text-caption font-weight-bold text-grey-darken-2 wf-kfd-fs11px">TRẠNG THÁI HỒ SƠ:</span>
                  <v-chip size="x-small" color="primary" variant="flat">{{
                    formatStatusText(overview.Status) }}</v-chip>
                </div>
                <div class="text-caption text-grey-darken-3 mb-4 font-weight-medium wf-kfd-lh14">
                  {{ currentActionSubText }}
                </div>

                <v-divider class="mb-4 wf-kfd-bce2e8f0"></v-divider>

                <!-- Metadata lượt ký -->
                <div class="d-flex flex-column ga-2 text-caption">
                  <div class="d-flex justify-space-between">
                    <span class="text-grey-darken-1">Người xử lý:</span>
                    <span class="font-weight-bold text-grey-darken-4">{{
                      overview.CurrentSignerPersonName || '-' }}</span>
                  </div>
                  <div class="d-flex justify-space-between">
                    <span class="text-grey-darken-1">Phương thức:</span>
                    <span class="font-weight-bold text-grey-darken-4">{{
                      formatMethod(overview.CurrentSignerMethod || overview.CurrentSignSystem)
                      }}</span>
                  </div>
                  <div class="d-flex justify-space-between">
                    <span class="text-grey-darken-1">Kênh ký:</span>
                    <span class="font-weight-bold text-grey-darken-4">{{ signingChannelDisplay
                      }}</span>
                  </div>
                </div>

                <!-- Bảng điều khiển ký / SmartCA / OTP / Econtract -->
                <div v-if="canShowActionPanel || showEcontractTrackingPanel" class="mt-4 pt-4 border-top">
                  <div class="font-weight-bold text-subtitle-2 text-primary mb-2">{{
                    actionModeCardTitle }}</div>

                  <div v-if="currentActionMode === 'SMARTCA'" class="d-flex flex-column ga-2 mb-3">
                    <v-text-field :model-value="smartcaCertDisplayText" variant="outlined" density="compact"
                      label="Chứng thư đã duyệt" readonly hide-details class="bg-white" />
                  </div>
                  <div v-else-if="currentActionMode === 'OTP'" class="d-flex flex-column ga-2 mb-3">
                    <v-text-field v-model="actionForm.otpCode" variant="outlined" density="compact" label="Mã OTP"
                      hide-details class="bg-white" />
                  </div>

                  <!-- Nhóm nút hành động Ký/Từ chối -->
                  <div class="d-flex flex-column ga-2">
                    <v-btn class="font-weight-bold text-caption w-100" color="success" height="38" elevation="0"
                      :loading="isActing || isSmartcaCalling || smartcaActionLock"
                      :disabled="isActing || isSmartcaCalling || smartcaActionLock || isSignActionBlocked"
                      @click="signRequest">
                      <v-icon start size="16">{{ actionPrimaryIcon }}</v-icon>
                      {{ actionPrimaryText }}
                    </v-btn>

                    <v-btn class="font-weight-bold text-caption w-100 wf-kfd-bcrgba229575" color="error" variant="outlined" height="36" :disabled="isActing || isSmartcaCalling || smartcaActionLock || isRejectActionBlocked" @click="showRejectBox = !showRejectBox">
                      <v-icon start size="16">mdi-close-circle-outline</v-icon>
                      Từ chối
                    </v-btn>
                  </div>
                </div>

                <!-- Form lý do từ chối -->
                <div v-if="showRejectBox && canRejectCurrentAction" class="mt-3 pt-3 border-top">
                  <div class="text-caption font-weight-bold text-red-darken-3 mb-1.5">LÝ DO TỪ CHỐI
                  </div>
                  <v-textarea v-model="rejectReason" variant="outlined" density="compact" rows="3" hide-details
                    placeholder="Nhập lý do từ chối..." class="bg-white mb-2" />
                  <div class="d-flex ga-2">
                    <v-btn class="flex-grow-1 text-caption font-weight-bold" color="grey-darken-1" variant="outlined"
                      height="32" :disabled="isActing" @click="cancelReject">
                      Hủy
                    </v-btn>
                    <v-btn class="flex-grow-1 text-caption font-weight-bold" color="error" height="32" elevation="0"
                      :loading="isActing"
                      :disabled="!normalizeRejectReason(rejectReason) || isActing || isRejectActionBlocked"
                      @click="rejectRequest">
                      Gửi từ chối
                    </v-btn>
                  </div>
                </div>

                <div v-if="!canShowActionPanel && !showEcontractTrackingPanel"
                  class="mt-4 text-center text-caption text-grey py-3 border-top">
                  Bạn không có thao tác xử lý ở bước hiện tại.
                </div>
              </div>

              <!-- Danh sách vị trí ký -->
              <div class="mb-4 rounded-lg border pa-4">
                <div class="d-flex align-center justify-space-between mb-3">
                  <span class="text-caption font-weight-bold text-grey-darken-3 wf-kfd-fs11px-7">Các
                    vị trí ký số ({{ focusedSignBoxes.length }})</span>
                </div>
                <div v-if="focusedSignBoxes.length" class="d-flex flex-column ga-2">
                  <div v-for="item in focusedSignBoxes" :key="'focus-box-side-' + item.InstanceSignBoxID"
                    class="pa-3 border rounded-lg d-flex flex-column ga-1 bg-white cursor-pointer"
                    :class="{ 'border-primary': Number(item.InstanceSignBoxID) === Number(selectedPreviewBoxId || 0) }"
                    @click="jumpToSignBox(item)">
                    <div class="d-flex justify-space-between align-center">
                      <span class="text-caption font-weight-bold text-grey-darken-4">Vị trí #{{
                        item.BoxOrder }}</span>
                      <v-chip size="x-small" color="primary" variant="tonal">Trang {{ item.PageNo
                        }}</v-chip>
                    </div>
                    <span class="text-caption text-grey-darken-2">{{ item.PersonName ||
                      item.SignerValue || 'Chưa gán người ký' }}</span>
                    <div class="d-flex align-center justify-space-between mt-1">
                      <span class="text-caption text-grey-darken-1 wf-kfd-fs10px">Bước {{
                        item.StepOrder }}</span>
                      <v-chip class="wf-kfd-h18px-3" size="x-small" :color="isSignedRuntimeStatus(resolveSignBoxRuntimeStatus(item)) ? 'success' : 'warning'" variant="flat">
                        {{ isSignedRuntimeStatus(resolveSignBoxRuntimeStatus(item)) ? 'Đã ký' :
                        'Chờ ký' }}
                      </v-chip>
                    </div>
                  </div>
                </div>
                <div v-else class="text-center text-caption text-grey py-3">Chưa cấu hình vị trí ký.
                </div>
              </div>

            </div>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <!-- Dialog Review & Xác nhận gửi đi ký -->
    <v-dialog v-model="dialog.reviewSendSign" max-width="900" persistent transition="dialog-bottom-transition">
      <v-card class="rounded-xl overflow-hidden shadow-lg border">
        <v-card-title class="bg-primary text-white d-flex align-center py-4 px-5">
          <v-icon start size="22" class="mr-2">mdi-send-circle-outline</v-icon>
          <span class="text-subtitle-1 font-weight-bold">Kiểm tra tài liệu & Xác nhận gửi ký</span>
        </v-card-title>
        <v-card-text class="pa-0 d-flex flex-column wf-kfd-h600px">
          <div class="d-flex flex-grow-1 w-100 h-100 overflow-hidden">
            <div class="flex-grow-1 bg-grey-darken-3 position-relative d-flex justify-center align-center">
              <div v-if="isGeneratingPreview" class="d-flex align-center justify-center fill-height bg-white w-100 h-100 position-absolute wf-kfd-z10">
                <div class="text-center">
                  <v-progress-circular indeterminate color="primary" size="48" class="mb-3" />
                  <div class="text-body-2 text-grey-darken-1">Đang kết xuất bản xem trước PDF...</div>
                </div>
              </div>
              <iframe v-else-if="previewPdfUrl" :src="previewPdfUrl" class="w-100 h-100 wf-kfd-bdnone"/>
              <div v-else class="text-center text-white">
                <v-icon size="48" color="grey">mdi-alert-circle-outline</v-icon>
                <div class="text-subtitle-2 mt-2">Không thể tải bản xem trước tài liệu.</div>
              </div>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="px-5 py-4 d-flex justify-end ga-2 bg-white border-top">
          <v-btn color="success" variant="flat" class="font-weight-bold text-caption text-white px-4 wf-kfd-br4px" height="36" :loading="isSendingSign" @click="sendDocumentForSigning">
            <v-icon start size="16">mdi-check-all</v-icon> Xác nhận gửi đi ký
          </v-btn>
          <v-btn variant="outlined" class="font-weight-bold text-caption px-4 wf-kfd-bcd9d9d9" @click="dialog.reviewSendSign = false" height="36">
            Quay lại
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog Hướng dẫn VNPT SmartCA -->
    <v-dialog v-model="showSmartcaGuideDialog" max-width="400" persistent>
      <v-card class="rounded-xl overflow-hidden shadow-lg border">
        <v-card-title class="bg-primary text-white d-flex align-center py-4 px-5">
          <v-icon start size="22" class="mr-2">mdi-shield-key-outline</v-icon>
          <span class="text-subtitle-1 font-weight-bold">Xác thực VNPT SmartCA</span>
        </v-card-title>
        <v-card-text class="pa-5 text-center">
          <v-progress-circular indeterminate color="primary" size="48" class="mb-4" />
          <div class="text-subtitle-2 font-weight-bold text-grey-darken-3 mb-2">Đang chờ ký số từ app SmartCA
          </div>
          <div class="text-caption text-grey-darken-1 leading-relaxed">
            Vui lòng mở ứng dụng <strong class="text-primary">VNPT SmartCA</strong> trên điện thoại di động
            của bạn để kiểm tra và xác nhận giao dịch ký tài liệu này.
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <uc-signer-config-dialog ref="signerConfigDialogRef" @saved="onSignersSaved" />

    <input class="d-none" ref="checklistFileInput" type="file" @change="onChecklistFileSelected($event)">

  </div>
</template>

<script>
	export default {
		name: 'uc-kanban-flow-detail-view',
		props: {
			propInstanceId: { type: Number, default: null },
			isModal: { type: Boolean, default: false }
		},
		mixins: [
			typeof window !== 'undefined' && window.__WF_REQUEST_DETAIL_EXTERNAL_MIXIN__ ? window.__WF_REQUEST_DETAIL_EXTERNAL_MIXIN__ : {},
			typeof window !== 'undefined' && window.__WF_REQUEST_DETAIL_SMARTCA_MIXIN__ ? window.__WF_REQUEST_DETAIL_SMARTCA_MIXIN__ : {}
		],

  data: function () {
    return {
      instanceId: null,
      currentStepSelectedFields: null,
      isLoading: false,
      isSaving: false,
      isMovingStep: false,
      isGeneratingPreview: false,
      showSignDetail: false,
      hasAutoRedirectedToSign: false,

      theChiTiet: null,
      danhSachNhan: [],
      dsCot: [],
      customFields: [],
      instanceData: [],
      stepHistory: [],
      instanceTasks: [],
      checklistItems: [],
      templates: [],

      activeTemplate: null,
      activeTemplates: null,
      activeTemplateBinary: '',
      activeTemplateFileName: '',
      previewPdfUrl: '',
      activeCanvasSlotIdx: 0,
      slotPdfMap: {},
      editFieldValues: {},
      apiDataSources: {},

      detailActiveTab: 'task',
      detailRightSubTab: 'fields',
      activeFormIdx: 0,
      activeChecklistItemToUpload: null,
      taskFilterMode: 'ALL',
      dialog: {
        previewPdf: false,
        signDocument: false,
        reviewSendSign: false
      },

      // State thêm checklist thủ công
      dialogThemTask: false,
      taskMoiName: '',
      taskMoiIsRequired: false,

      // State chỉnh sửa nhãn dán
      dialogSuaNhan: false,
      nhanDaChon: [],

      overview: {},
      steps: [],
      signers: [],
      fields: [],
      logs: [],
      signBoxes: [],
      previewPageNo: 1,
      selectedPreviewBoxId: 0,
      revealedSignedBoxId: 0,
      isActing: false,
      isSmartcaCalling: false,
      smartcaActionLock: false,
      isSendingSign: false,
      isCancelingSign: false,
      showSmartcaGuideDialog: false,
      showRejectBox: false,
      rejectReason: '',
      signerProfiles: [],
      mySignerProfile: null,
      smartcaSignatureBase64: '',
      smartcaUploadedSignatureBase64: '',
      isEcontractSyncing: false,
      econtractAuthCache: null,
      actionForm: {
        signCertInfo: '',
        providerTransactionCode: '',
        providerNote: '',
        otpCode: ''
      },
      eContractApiMap: {
        screen: 'wf-kanban-flow-detail',
        authLogin: '/api/econtract/auth/login',
        detail: '/api/econtract/contracts/{hopDongId}/detail',
        wesignDetail: '/api/econtract/wesign/documents/detail',
        wesignSyncRuntime: '/api/econtract/wesign/documents/{documentId}/sync-runtime',
        wesignDownloadSigned: '/api/econtract/wesign/documents/download-signed',
        syncRuntime: '/api/econtract/contracts/{hopDongId}/sync-runtime',
        downloadBase64: '/api/econtract/contracts/{hopDongId}/download-base64',
        downloadByUrl: '/api/econtract/contracts/download-by-url',
        updateSigners: '/api/econtract/contracts/update-signers',
        smartcaApp: '/econtract-integration-service/api/v1/tich-hop-ky/smartca/xac-thuc-app',
        smartcaAuto: '/econtract-integration-service/api/v1/tich-hop-ky/smartca/ky-tu-dong'
      }
    }
  },

  computed: {
    signerProfileOptions: function () {
      return (this.signerProfiles || []).map(function (item) {
        var name = String(item.FullName || "").trim()
        var code = String(item.EmployeeCode || "").trim()
        var dept = String(item.DepartmentName || "").trim()
        var cert = String(item.CertSerial || "").trim()
        var title = name || code || "Người ký"
        if (code) title += " (" + code + ")"
        if (dept) title += " · " + dept
        if (cert) title += " · CTS " + cert
        return {
          title: title,
          value: code,
          personName: name
        }
      }).filter(function (row) {
        return !!row.value
      })
    },

    isReviewOrApproveStep() {
      if (!this.theChiTiet || !this.dsCot) return false
      const currentStepDefID = Number(this.theChiTiet.CurrentStepDefID)
      const currentStep = this.dsCot.find(c => Number(c.id) === currentStepDefID)
      if (currentStep) {
        return currentStep.stepType === 'REVIEW' || currentStep.stepType === 'APPROVE'
      }
      return false
    },

    isReadonlyStep() {
      if (this.isReviewOrApproveStep) return true
      if (!this.overview) return true
      // Nếu bước này yêu cầu gửi đi ký thủ công và đã gửi đi ký thì khóa nhập liệu
      if (this.overview.RequireManualSendSign && this.overview.IsSentForSigning) {
        return true
      }
      // Nếu User hiện tại không được gán quyền xử lý (Act) ở bước này thì đặt ở trạng thái chỉ đọc
      return this.overview.CanCurrentUserAct !== true && this.overview.CanCurrentUserAct !== 1
    },

    // Chỉ dành cho field type 'signature': tại REVIEW/APPROVE step vẫn cho phép nhập nếu có quyền Act
    isSignatureFieldReadonly() {
      if (this.isReviewOrApproveStep) {
        if (!this.overview) return true
        return !(this.overview.CanCurrentUserAct === true || this.overview.CanCurrentUserAct === 1)
      }
      return this.isReadonlyStep
    },

    // Dùng để show nút "Lưu dữ liệu" tại REVIEW step khi có signature fields cần điền
    hasSignatureFieldsEditable() {
      if (!this.isReviewOrApproveStep) return false
      if (this.isSignatureFieldReadonly) return false
      return this.signatureFieldsForCurrentStep.length > 0
    },

    activeStepSignedCount() {
      if (!this.overview || !this.steps) return 0
      const activeStep = this.steps.find(s => Number(s.ExecutionID) === Number(this.overview.CurrentExecutionID))
      return activeStep ? (activeStep.SignedCount || 0) : 0
    },

    displayInstanceMeta() {
      if (!this.theChiTiet) return ''
      const parts = []
      if (this.theChiTiet.CreateUser) {
        parts.push('Người tạo: ' + this.theChiTiet.CreateUser)
      }
      if (this.theChiTiet.CreateTime) {
        parts.push(this.formatDateTime(this.theChiTiet.CreateTime))
      }
      return parts.join(' · ')
    },

    hasTemplateOrDocument() {
      if (!this.theChiTiet) return false
      return !!(this.activeTemplate || this.activeTemplates || (this.theChiTiet && (this.theChiTiet.CurrentDocumentFileID || this.theChiTiet.SourceFileID)))
    },

    // [MULTI-TEMPLATE] Nhóm fields theo từng slot template dựa trên placeholder matching
    activeTemplateGroups: function () {
      if (!this.activeTemplates) return null
      var $this = this
      return this.activeTemplates.map(function (slot) {
        var tpl = slot.template
        var placeholders = (tpl && tpl.Placeholders) ? tpl.Placeholders : []
        var fields = $this.customFieldsForCurrentStep.filter(function (f) {
          return placeholders.indexOf(f.FieldName) !== -1
        })
        return { slot: slot, template: tpl, fields: fields }
      })
    },

    // Placeholders xuất hiện ở ≥2 slot template → dùng chung giá trị
    templateDuplicatePlaceholders: function () {
      if (!this.activeTemplates) return []
      var phCount = {}
      this.activeTemplates.forEach(function (slot) {
        var tpl = slot.template
        if (!tpl || !tpl.Placeholders) return
        tpl.Placeholders.forEach(function (ph) {
          phCount[ph] = (phCount[ph] || 0) + 1
        })
      })
      return Object.keys(phCount).filter(function (ph) { return phCount[ph] > 1 })
    },

    // Fields không thuộc template nào → "Cấu hình khác"
    templateUnmatchedFields: function () {
      if (!this.activeTemplates || !this.activeTemplateGroups) return []
      var allMatched = []
      this.activeTemplateGroups.forEach(function (g) {
        g.fields.forEach(function (f) { allMatched.push(f.FieldName) })
      })
      return this.customFieldsForCurrentStep.filter(function (f) {
        return allMatched.indexOf(f.FieldName) === -1
      })
    },

    customFieldsForCurrentStep() {
      if (!this.theChiTiet) return []
      if (this.isReviewOrApproveStep) {
        return this.customFields || []
      }
      // Ưu tiên dùng SelectedFieldNames từ ConditionJSON của bước hiện tại (chính xác nhất)
      if (Array.isArray(this.currentStepSelectedFields)) {
        if (this.currentStepSelectedFields.length === 0) return []
        var selected = this.currentStepSelectedFields
        return (this.customFields || []).filter(function (f) {
          return selected.indexOf(f.FieldName) !== -1
        })
      }
      // Fallback: filter theo InputAtStep
      const stepOrder = String(this.theChiTiet.CurrentStepOrder || '').trim()
      if (!stepOrder) return []
      return this.customFields.filter(f => {
        const inputAt = String(f.InputAtStep || '')
        if (!inputAt) return false
        return inputAt.split(',').map(s => s.trim()).indexOf(stepOrder) !== -1
      })
    },

    otherCustomFields() {
      if (!this.customFields) return []
      if (this.isReviewOrApproveStep) return []
      const currentStepFieldNames = (this.customFieldsForCurrentStep || []).map(f => f.FieldName)
      return this.customFields.filter(f => currentStepFieldNames.indexOf(f.FieldName) === -1)
    },

    formFieldsForCurrentStep() {
      return (this.customFieldsForCurrentStep || []).filter(f => {
        return f.FieldType !== 'file' && f.FieldType !== 'image'
      })
    },

    normalFieldsForCurrentStep: function () {
      return (this.customFieldsForCurrentStep || []).filter(function (f) {
        return f.FieldType !== 'signature' && f.FieldType !== 'file' && f.FieldType !== 'image'
      })
    },

    signatureFieldsForCurrentStep: function () {
      return (this.customFieldsForCurrentStep || []).filter(function (f) {
        return f.FieldType === 'signature'
      })
    },

    fileFieldsForCurrentStep: function () {
      return (this.customFieldsForCurrentStep || []).filter(function (f) {
        return f.FieldType === 'file' || f.FieldType === 'image'
      })
    },


    instanceTasksForCurrentStep() {
      if (!this.theChiTiet) return []
      const stepOrder = Number(this.theChiTiet.CurrentStepOrder || 0)
      if (!stepOrder) return []
      return this.instanceTasks.filter(t => Number(t.StepOrder) === stepOrder)
    },

    completedTasksForCurrentStep() {
      return this.instanceTasksForCurrentStep.filter(t => t.Status === 'DONE')
    },

    filteredTasksForCurrentStep() {
      const tasks = this.instanceTasksForCurrentStep || []
      if (this.taskFilterMode === 'PENDING') {
        return tasks.filter(t => t.Status !== 'DONE')
      }
      return tasks
    },

    canMoveStep() {
      if (this.overview && this.overview.RequireManualSendSign && !this.overview.IsSentForSigning) {
        return false
      }

      if (this.hasUnsignedBoxes) return false

      const incompleteRequiredTasks = this.instanceTasksForCurrentStep.filter(t => t.IsRequired && t.Status !== 'DONE')
      if (incompleteRequiredTasks.length > 0) return false

      if (this.isReviewOrApproveStep) {
        const self = this
        const emptySignatureFields = this.signatureFieldsForCurrentStep.filter(f => {
          return !self.editFieldValues[f.FieldName] || String(self.editFieldValues[f.FieldName]).trim() === ''
        })
        if (emptySignatureFields.length > 0) return false

        const incompleteDocs = this.checklistItems.filter(d => {
          return d.IsRequired && !d.IsCompleted && !d.IsDeferred
        })
        if (incompleteDocs.length > 0) return false
        return true
      }

      const self = this
      const requiredFields = this.customFieldsForCurrentStep.filter(f => f.IsRequired)
      const emptyRequired = requiredFields.filter(f => {
        return !self.editFieldValues[f.FieldName] || String(self.editFieldValues[f.FieldName]).trim() === ''
      })
      if (emptyRequired.length > 0) return false

      const invalidDates = this.customFieldsForCurrentStep.filter(f => {
        return f.FieldType === 'date' && !!self.editFieldValues[f.FieldName] && !self.isValidDateValue(self.editFieldValues[f.FieldName])
      })
      if (invalidDates.length > 0) return false

      const incompleteDocs = this.checklistItems.filter(d => {
        return d.IsRequired && !d.IsCompleted && !d.IsDeferred
      })
      if (incompleteDocs.length > 0) return false
      return true
    },

    moveStepBlockReasons() {
      const reasons = []
      const self = this

      if (this.overview && this.overview.RequireManualSendSign && !this.overview.IsSentForSigning) {
        reasons.push('Cần gửi đi ký số trước khi chuyển bước.')
      }

      if (this.hasUnsignedBoxes) {
        reasons.push('Tài liệu bắt buộc chưa được ký số.')
      }

      const incompleteRequiredTasks = this.instanceTasksForCurrentStep.filter(t => t.IsRequired && t.Status !== 'DONE')
      if (incompleteRequiredTasks.length > 0) {
        reasons.push(incompleteRequiredTasks.length + ' nhiệm vụ bắt buộc chưa hoàn thành')
      }

      if (this.isReviewOrApproveStep) {
        const emptySignatureFields = this.signatureFieldsForCurrentStep.filter(f => {
          return !self.editFieldValues[f.FieldName] || String(self.editFieldValues[f.FieldName]).trim() === ''
        })
        if (emptySignatureFields.length > 0) {
          reasons.push(emptySignatureFields.length + ' trường người ký chưa được chọn (' + emptySignatureFields.map(f => f.FieldLabel || f.FieldName).join(', ') + ')')
        }
        const incompleteDocs = this.checklistItems.filter(d => {
          return d.IsRequired && !d.IsCompleted && !d.IsDeferred
        })
        if (incompleteDocs.length > 0) {
          reasons.push(incompleteDocs.length + ' hồ sơ bắt buộc chưa nộp (' + incompleteDocs.map(d => d.ItemName).join(', ') + ')')
        }
        return reasons
      }

      const requiredFields = this.customFieldsForCurrentStep.filter(f => f.IsRequired)
      const emptyRequired = requiredFields.filter(f => {
        return !self.editFieldValues[f.FieldName] || String(self.editFieldValues[f.FieldName]).trim() === ''
      })
      if (emptyRequired.length > 0) {
        reasons.push(emptyRequired.length + ' trường bắt buộc chưa nhập (' + emptyRequired.map(f => f.FieldLabel || f.FieldName).join(', ') + ')')
      }

      const invalidDates = this.customFieldsForCurrentStep.filter(f => {
        return f.FieldType === 'date' && !!self.editFieldValues[f.FieldName] && !self.isValidDateValue(self.editFieldValues[f.FieldName])
      })
      if (invalidDates.length > 0) {
        reasons.push(invalidDates.length + ' trường ngày tháng không hợp lệ (' + invalidDates.map(f => f.FieldLabel || f.FieldName).join(', ') + ')')
      }

      const incompleteDocs = this.checklistItems.filter(d => {
        return d.IsRequired && !d.IsCompleted && !d.IsDeferred
      })
      if (incompleteDocs.length > 0) {
        reasons.push(incompleteDocs.length + ' hồ sơ bắt buộc chưa nộp (' + incompleteDocs.map(d => d.ItemName).join(', ') + ')')
      }
      return reasons
    },

    documentViewUrl: function () {
      // Ưu tiên dùng PDF đã merge (có signatureAnchors khớp tọa độ)
      if (this.previewPdfUrl) return this.previewPdfUrl
      var runtime = this.resolveBestRuntimeDocument()
      if (runtime.FileUrl) return runtime.FileUrl
      if (runtime.FileID) return "https://file.zentea.vn/iotdev/FileData/" + runtime.FileID
      return ""
    },

    focusedSignBoxes: function () {
      var rows = this.signBoxes || []
      return rows.slice().sort(function (a, b) {
        var pageDiff = Number(a && a.PageNo || 1) - Number(b && b.PageNo || 1)
        if (pageDiff !== 0) return pageDiff
        var boxDiff = Number(a && a.BoxOrder || 0) - Number(b && b.BoxOrder || 0)
        if (boxDiff !== 0) return boxDiff
        return Number(a && a.InstanceSignBoxID || 0) - Number(b && b.InstanceSignBoxID || 0)
      })
    },

    canvasSignBoxes: function () {
      var self = this
      var rows = self.focusedSignBoxes || []
      var revealedSignedBoxId = Number(self.revealedSignedBoxId || 0)
      // [MULTI-TEMPLATE] Chỉ show boxes thuộc slot đang active
      if (self.activeTemplates && self.activeTemplates.length) {
        var slotIdx = Number(self.activeCanvasSlotIdx || 0)
        rows = rows.filter(function (item) { return Number(item.SlotIdx || 0) === slotIdx })
      }
      return rows.filter(function (item) {
        var isSigned = self.isSignedRuntimeStatus(self.resolveSignBoxRuntimeStatus(item))
        var itemId = Number(item && item.InstanceSignBoxID || 0)
        if (!isSigned) return true
        if (revealedSignedBoxId && itemId === revealedSignedBoxId) return true
        return false
      })
    },

    currentActionSubText: function () {
      if (this.showEcontractTrackingPanel) {
        return "Tài liệu đã gửi sang " + this.currentExternalProviderText + " và đang chờ ký ngoài hệ thống."
      }
      if (this.overview.CanCurrentUserSign) {
        return this.actionWaitingText
      }
      if (this.overview.Status === "COMPLETED") return "Yêu cầu ký đã hoàn tất."
      if (this.overview.Status === "REJECTED") return "Yêu cầu ký đã bị từ chối."
      return "Theo dõi tiến độ xử lý."
    },

    currentActionMode: function () {
      var method = String(this.overview.CurrentSignerMethod || this.overview.CurrentSignSystem || "").toLowerCase()
      var engine = this.resolveOverviewExecutionEngine()
      var stepType = String(this.overview.CurrentStepType || "").toUpperCase()
      if (engine === "ECONTRACT") return "ECONTRACT"
      if (method === "smartca") return "SMARTCA"
      if (method === "econtract") return "ECONTRACT"
      if (method === "otp_email" || method === "otp_sms") return "OTP"
      if (stepType === "REVIEW") return "REVIEW"
      if (stepType === "SIGN") return "SIGN"
      return "TRACKING"
    },

    actionPrimaryText: function () {
      var map = {
        SMARTCA: "Ký SmartCA",
        ECONTRACT: "Xác nhận eContract",
        OTP: "Xác nhận OTP",
        REVIEW: "Duyệt tài liệu",
        SIGN: "Ký hoàn tất",
        TRACKING: "Hoàn tất bước"
      }
      return map[this.currentActionMode] || "Ký hoàn tất"
    },

    actionPrimaryIcon: function () {
      var map = {
        SMARTCA: "mdi-shield-key-outline",
        ECONTRACT: "mdi-file-sign",
        OTP: "mdi-form-textbox-password",
        REVIEW: "mdi-eye-check-outline",
        SIGN: "mdi-draw-pen",
        TRACKING: "mdi-check-circle-outline"
      }
      return map[this.currentActionMode] || "mdi-draw-pen"
    },

    actionWaitingText: function () {
      var stepName = this.overview.CurrentStepName || "-"
      if (this.currentActionMode === "SMARTCA") {
        return "Đang chờ bạn ký SmartCA ở bước " + stepName + "."
      }
      if (this.currentActionMode === "ECONTRACT") {
        return "Đang chờ người ký xử lý hợp đồng điện tử trên " + this.currentExternalProviderText + " ở bước " + stepName + "."
      }
      if (this.currentActionMode === "OTP") {
        return "Đang chờ bạn xác thực OTP ở bước " + stepName + "."
      }
      if (this.currentActionMode === "REVIEW") {
        return "Đang chờ bạn duyệt nội dung ở bước " + stepName + "."
      }
      return "Đang chờ bạn ký ở bước " + stepName + "."
    },

    actionModeCardTitle: function () {
      if (this.currentActionMode === "SMARTCA") return "SmartCA runtime"
      if (this.currentActionMode === "ECONTRACT") return "Theo dõi trạng thái ký"
      if (this.currentActionMode === "OTP") return "OTP runtime"
      if (this.currentActionMode === "REVIEW") return "Review runtime"
      return "Runtime action"
    },

    actionModeCardSubText: function () {
      if (this.currentActionMode === "SMARTCA") {
        if (this.approvedSignerCertInfo && !this.isApprovedSignerCertInfoValid) return "Metadata chứng thư đã duyệt không hợp lệ. Yêu cầu chuỗi 6-64 ký tự chữ/số."
        if (!this.approvedSignerCertInfo && !(this.mySignerProfile && this.mySignerProfile.CertSerial)) return "Thiếu metadata chứng thư đã duyệt và chưa có chứng thư active trong hồ sơ signer."
        return "Dùng metadata chứng thư số đã duyệt."
      }
      if (this.currentActionMode === "ECONTRACT") return "Theo dõi trạng thái ký trên hệ thống " + this.currentExternalProviderText + "."
      if (this.currentActionMode === "OTP") return "Nhập OTP để hoàn tất."
      if (this.currentActionMode === "REVIEW") return "Xác nhận duyệt tài liệu."
      return "Xử lý bước hiện tại."
    },

    approvedSignerCertInfo: function () {
      var targetExecId = this.overview.CurrentSignerExecID || 0
      var rows = this.signers || []
      var i = 0
      var row = null
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i]
        if (row && row.SignerExecID === targetExecId) {
          return String(row.SignCertInfo || "").trim()
        }
      }
      return ""
    },

    isApprovedSignerCertInfoValid: function () {
      var raw = String(this.approvedSignerCertInfo || "").trim()
      if (!raw) return false
      return /^[0-9A-Za-z]{6,64}$/.test(raw)
    },

    smartcaCertDisplayText: function () {
      if (this.approvedSignerCertInfo) return this.approvedSignerCertInfo
      if (this.mySignerProfile && this.mySignerProfile.CertSerial) return String(this.mySignerProfile.CertSerial)
      return "Chưa có metadata chứng thư đã duyệt"
    },


    canSignCurrentAction: function () {
      return (this.overview.CanCurrentUserSign === true || this.overview.CanCurrentUserSign === 1)
        && Number(this.overview.CurrentSignerExecID || 0) > 0
    },

    canRejectCurrentAction: function () {
      return (this.overview.CanCurrentUserReject === true || this.overview.CanCurrentUserReject === 1)
        && Number(this.overview.CurrentSignerExecID || 0) > 0
    },

    canShowActionPanel: function () {
      if (this.showEcontractTrackingPanel) return false
      return this.canSignCurrentAction || this.canRejectCurrentAction
    },

    showEcontractTrackingPanel: function () {
      return this.resolveOverviewExecutionEngine() === "ECONTRACT"
        && this.canSyncCurrentEcontractProvider()
    },

    currentExternalProviderText: function () {
      return this.formatProvider(
        this.resolveOverviewContractProvider() || this.overview.CurrentSignSystem || this.overview.CurrentSignerMethod || "",
        this.resolveOverviewExecutionEngine()
      )
    },

    econtractTrackingHelpText: function () {
      if (this.canSyncCurrentEcontractProvider()) {
        return "Bấm nút Kiểm tra trạng thái ký để lấy tiến độ mới nhất từ " + this.currentExternalProviderText + "."
      }
      return "Provider này chưa bật đồng bộ trạng thái tự động trong màn detail. Theo dõi kết quả trực tiếp trên " + this.currentExternalProviderText + "."
    },

    externalSyncButtonText: function () {
      return "Kiểm tra trạng thái ký"
    },

    externalDocumentIdLabel: function () {
      if (this.resolveOverviewContractProvider() === "AMIS_WESIGN") return "Mã tài liệu"
      return "Mã hợp đồng"
    },

    econtractHopDongIdDisplay: function () {
      var documentId = ""
      if (this.resolveOverviewContractProvider() === "AMIS_WESIGN") {
        documentId = this.resolveWeSignDocumentId()
        return documentId || "-"
      }
      var id = Number(this.overview.ExternalContractID || 0) || this.resolveEcontractHopDongId()
      return id > 0 ? String(id) : "-"
    },

    econtractContractStatusDisplay: function () {
      if (this.overview.ExternalContractStatusText) return this.overview.ExternalContractStatusText
      if (this.currentActionMode === "ECONTRACT") return "Đã gửi sang " + this.currentExternalProviderText
      return "-"
    },

    econtractSignStatusDisplay: function () {
      if (this.overview.ExternalSignStatusText) return this.overview.ExternalSignStatusText
      if (this.currentActionMode === "ECONTRACT") return "Đang chờ cập nhật"
      return "-"
    },

    econtractLastSyncDisplay: function () {
      var raw = this.overview.ExternalLastSyncTime || ""
      if (!raw) return "Chưa đồng bộ"
      return this.formatDateTime(raw)
    },

    canDownloadSignedExternalDocument: function () {
      var provider = this.resolveOverviewContractProvider()
      if (provider !== "AMIS_WESIGN") return false
      return this.isExternalDocumentCompleted()
        || !!String(this.overview.ExternalDocumentUrl || "").trim()
        || !!String(this.overview.CurrentDocumentFileUrl || "").trim()
        || !!String(this.overview.CurrentDocumentFileID || "").trim()
    },

    signingChannelDisplay: function () {
      var engine = this.resolveOverviewExecutionEngine()
      var provider = this.resolveOverviewContractProvider()
      if (engine === "ECONTRACT") {
        if (provider === "VNPT_ECONTRACT") return "eContract VNPT"
        if (provider) return "eContract " + provider
        return "eContract"
      }
      if (String(this.overview.CurrentSignerMethod || "").toLowerCase() === "smartca") return "SmartCA nội bộ"
      return "Ký nội bộ"
    },

    isSignActionBlocked: function () {
      var profileCert = this.mySignerProfile && this.mySignerProfile.CertSerial ? String(this.mySignerProfile.CertSerial).trim() : ""
      if (!this.canSignCurrentAction) return true
      if (this.currentActionMode === "SMARTCA") {
        if (this.approvedSignerCertInfo) return !this.isApprovedSignerCertInfoValid
        return !/^[0-9A-Za-z]{6,64}$/.test(profileCert)
      }
      if (this.currentActionMode === "OTP") return !this.isOtpCodeValid(this.actionForm.otpCode)
      return false
    },

    isRejectActionBlocked: function () {
      var otpCode = this.normalizeOtpCode(this.actionForm.otpCode)
      if (!this.canRejectCurrentAction) return true
      if (this.currentActionMode !== "OTP") return false
      return !this.isOtpCodeValid(otpCode)
    },

    hasSigningRequiredForCurrentUser: function () {
      return this.canSignCurrentAction
    },

    hasUnsignedBoxes: function () {
      var self = this
      if (!this.signBoxes || !this.signBoxes.length) return false
      var currentStepOrder = Number(this.theChiTiet && this.theChiTiet.CurrentStepOrder || 0)
      return this.signBoxes.some(function (box) {
        if (Number(box.StepOrder || 0) > currentStepOrder) return false
        var isSigned = self.isSignedRuntimeStatus(self.resolveSignBoxRuntimeStatus(box))
        return !isSigned
      })
    }
  },

  mounted() {
    if (typeof window !== 'undefined') {
      window.__WF_ECONTRACT_SCREEN_MAP__ = window.__WF_ECONTRACT_SCREEN_MAP__ || {}
      window.__WF_ECONTRACT_SCREEN_MAP__['wf-kanban-flow-detail'] = this.eContractApiMap
    }
    this.taiDanhSachNhan()
    this.initPage()
  },

  methods: {
    async taiDanhSachNhan() {
      try {
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_Tag_GetList', {})
          this.danhSachNhan = Array.isArray(res) ? res : []
        }
      } catch (e) {
        console.error('Lỗi tải danh mục nhãn:', e)
      }
    },
    moSuaNhan() {
      if (!this.theChiTiet) return
      this.nhanDaChon = this.tagStringToList(this.theChiTiet.Tag)
      this.dialogSuaNhan = true
    },
    async luuNhan() {
      if (!this.theChiTiet || !this.theChiTiet.InstanceID) return
      try {
        const tagsString = (this.nhanDaChon || []).join(',')
        if (typeof apiCallAsync === 'function') {
          const res = await apiCallAsync('WF_Instance_SaveTags', {
            InstanceID: this.theChiTiet.InstanceID,
            Tags: tagsString
          })
          if (res && res.Success !== false) {
            this.theChiTiet.Tag = tagsString
            this.dialogSuaNhan = false
            if (showToast && showToast.success) showToast.success('Cập nhật nhãn dán thành công')
          } else {
            if (showToast && showToast.error) showToast.error(res.Message || 'Lỗi cập nhật nhãn dán')
          }
        }
      } catch (e) {
        console.error('Lỗi lưu nhãn dán:', e)
        if (showToast && showToast.error) showToast.error('Không thể cập nhật nhãn dán')
      }
    },
    tagStringToList(tagString) {
      if (!tagString) return []
      return tagString.split(',').map(t => t.trim()).filter(Boolean)
    },
    getTagDisplayName(tagKey) {
      if (!tagKey) return ''
      const tag = this.danhSachNhan.find(t => t.Tag === tagKey || t.TagName === tagKey)
      return tag ? tag.TagName : tagKey
    },
    getTagColorLight(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      if (!tag || !tag.Color) return '#f1f5f9'
      const hex = tag.Color
      const map = {
        '#cbd5e1': '#f1f5f9', // Xám Slate
        '#2196F3': '#e3f2fd', // Xanh dương
        '#00bcd4': '#e0f7fa', // Xanh ngọc
        '#009688': '#e0f2f1', // Xanh mòng két
        '#4caf50': '#e8f5e9', // Xanh lá
        '#8bc34a': '#f1f8e9', // Xanh lá mạ
        '#ffeb3b': '#fffde7', // Vàng nắng
        '#d9a441': '#fdf6e2', // Vàng cát
        '#ff9800': '#fff3e0', // Cam
        '#f44336': '#ffebee', // Đỏ
        '#e91e63': '#fce4ec', // Hồng
        '#9c27b0': '#f3e5f5', // Tím
        '#673ab7': '#ede7f6', // Tím Indigo
        '#3f51b5': '#e8eaf6', // Tím đậm
        '#795548': '#efebe9', // Nâu đất
        '#607d8b': '#eceff1'  // Xám xanh
      }
      return map[hex] || hex
    },
    getTagBorderColor(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      return tag ? (tag.Color || '#cbd5e1') : '#cbd5e1'
    },
    getTagTextColorDark(tagName) {
      const tag = this.danhSachNhan.find(t => t.TagName === tagName || t.Tag === tagName)
      if (!tag || !tag.Color) return '#475569'
      const hex = tag.Color
      const map = {
        '#cbd5e1': '#475569', // Xám Slate
        '#2196F3': '#1e88e5', // Xanh dương
        '#00bcd4': '#00838f', // Xanh ngọc
        '#009688': '#00695c', // Xanh mòng két
        '#4caf50': '#2e7d32', // Xanh lá
        '#8bc34a': '#558b2f', // Xanh lá mạ
        '#ffeb3b': '#f57f17', // Vàng nắng
        '#d9a441': '#b58010', // Vàng cát
        '#ff9800': '#e65100', // Cam
        '#f44336': '#c62828', // Đỏ
        '#e91e63': '#c2185b', // Hồng
        '#9c27b0': '#8e24aa', // Tím
        '#673ab7': '#5e35b1', // Tím Indigo
        '#3f51b5': '#3949ab', // Tím đậm
        '#795548': '#4e342e', // Nâu đất
        '#607d8b': '#37474f'  // Xám xanh
      }
      return map[hex] || hex
    },
    sanitizeTaskText(str) {
      if (!str) return ''
      return String(str)
        .replace(/^(?:&nbsp;)+/gi, '')
        .replace(/^[\s\u00a0\u200b\u200c\u200d\ufeff\u2000-\u200f\u2028\u2029\u202f\u205f\u3000\t\r\n]+/g, '')
        .replace(/[\s\u00a0\u200b\u200c\u200d\ufeff\u2000-\u200f\u2028\u2029\u202f\u205f\u3000\t\r\n]+$/g, '')
        .trim()
    },

    findMatchedFieldForChecklist(chkItem) {
      if (!chkItem) return null
      const self = this
      return (this.customFieldsForCurrentStep || []).find(f => {
        const fieldName = String(f.FieldName || '').toLowerCase()
        const fieldLabel = String(f.FieldLabel || '').toLowerCase().trim()

        const itemCode = String(chkItem.ItemCode || '').toLowerCase()
        const itemName = String(chkItem.ItemName || '').toLowerCase().trim()

        const matches = (fieldName === itemCode || fieldName === itemName || fieldLabel === itemName)
        return matches && (f.FieldType === 'file' || f.FieldType === 'image')
      })
    },

    initPage: async function () {
      let id = this.propInstanceId
      if (!id) {
        const params = new URLSearchParams(window.location.search)
        id = parseInt(params.get('id'))
      }
      if (!id) {
        if (showToast && showToast.error) showToast.error('Không tìm thấy ID hồ sơ!')
        this.goBack()
        return
      }
      this.instanceId = id
      await this.loadData()
      await this.loadMySignerProfile()
      await this.loadSignerProfiles()

    },

    loadData: async function (isSilent) {
      if (!isSilent) {
        this.isLoading = true
      }
      const self = this
      try {
        const listRes = await apiCallAsync('WF_Instance_GetList', { Filter: 'ALL' })
        const found = (listRes || []).find(i => Number(i.InstanceID) === Number(self.instanceId))
        if (!found) {
          this.theChiTiet = null
          return
        }

        this.theChiTiet = {
          ...found,
          id: found.InstanceID,
          tieuDe: found.InstanceName,
          nguoiPhuTrach: found.AssigneeCode ? (found.AssigneeCode + ' - ' + found.AssigneeName) : found.AssigneeName,
          hanChot: found.UpdateTime

        }

        const results = await Promise.all([
          apiCallAsync('WF_Definition_GetDetail', { DefinitionID: self.theChiTiet.DefinitionID }),
          apiCallAsync('WF_InstanceData_GetList', { InstanceID: self.theChiTiet.InstanceID }),
          apiCallAsync('WF_StepExecution_GetList', { InstanceID: self.theChiTiet.InstanceID }),
          apiCallAsync('WF_InstanceTask_GetList', { InstanceID: self.theChiTiet.InstanceID }),
          apiCallAsync('WF_Template_GetList', {}),
          apiCallAsync('WF_InstanceChecklist_GetList', { InstanceID: self.theChiTiet.InstanceID, StepDefID: self.theChiTiet.CurrentStepDefID }),
          apiCallAsync('WF_StepDefinition_GetList', { DefinitionID: self.theChiTiet.DefinitionID }),
          apiCallAsync('WF_Request_GetDetail', { InstanceID: self.theChiTiet.InstanceID })
        ])

        this.customFields = (results[0] && results[0][2]) ? results[0][2] : []
        this.instanceData = results[1] || []
        this.stepHistory = results[2] || []

        const rawTasks = results[3] || []
        this.instanceTasks = rawTasks.map(t => {
          if (t.TaskName) t.TaskName = self.sanitizeTaskText(t.TaskName)
          if (t.Description) t.Description = self.sanitizeTaskText(t.Description)
          return t
        })
        this.templates = results[4] || []
        this.checklistItems = results[5] || []
        this.applyDetailData(results[7])

        if (!this.hasAutoRedirectedToSign && this.overview && (this.overview.CanCurrentUserSign === true || this.overview.CanCurrentUserSign === 1)) {
          this.showSignDetail = true
          this.hasAutoRedirectedToSign = true
        }

        const steps = results[6] || []
        const stepsList = (results[0] && results[0][1]) ? results[0][1] : []
        const stepDetailMap = {}
        stepsList.forEach(s => {
          let tasks = []
          let selectedFields = []
          if (s.TasksJSON) { try { tasks = JSON.parse(s.TasksJSON) || [] } catch (e) { } }
          if (s.ConditionJSON) {
            try {
              const cond = JSON.parse(s.ConditionJSON)
              selectedFields = cond.SelectedFieldNames || []
            } catch (e) { }
          }
          stepDetailMap[s.StepDefID] = {
            stepType: s.StepType || '',
            stepCode: s.StepCode || '',
            taskCount: tasks.length,
            fieldCount: selectedFields.length,
            selectedFieldNames: selectedFields
          }
        })

        // Lưu SelectedFieldNames của bước hiện tại để filter chính xác hơn InputAtStep
        var currentStepDef = stepDetailMap[self.theChiTiet.CurrentStepDefID]
        this.currentStepSelectedFields = (currentStepDef && currentStepDef.selectedFieldNames) ? currentStepDef.selectedFieldNames : null

        this.dsCot = steps.map(s => {
          const detail = stepDetailMap[s.StepDefID] || {}
          let mau = s.Color
          if (!mau) {
            if (detail.stepType === 'SUCCESS' || detail.stepCode === 'STEP_SUCCESS') mau = '#28a745'
            else if (detail.stepType === 'FAILURE' || detail.stepCode === 'STEP_FAILURE') mau = '#dc3545'
            else mau = '#2a9d5b'
          }
          return {
            id: s.StepDefID,
            tenCot: s.StepOrder + '. ' + s.StepName,
            mau: mau,
            order: s.StepOrder,
            stepType: detail.stepType || '',
            stepCode: detail.stepCode || '',
            taskCount: detail.taskCount || 0,
            fieldCount: detail.fieldCount || 0
          }
        })

        const currentStepDefId = self.theChiTiet.CurrentStepDefID
        const currentStep = stepsList.find(s => Number(s.StepDefID) === Number(currentStepDefId))
        const templateId = currentStep ? currentStep.TemplateID : null

        // [MULTI-TEMPLATE] Parse TemplatesJSON nếu bước hiện tại là multi-template
        var rawTemplatesJSON = currentStep ? currentStep.TemplatesJSON : null
        if (rawTemplatesJSON) {
          var templateSlots = typeof rawTemplatesJSON === 'string' ? JSON.parse(rawTemplatesJSON) : rawTemplatesJSON
          this.activeTemplates = (templateSlots || []).map(function (slot) {
            var tpl = self.templates.find(function (t) { return Number(t.TemplateID) === Number(slot.TemplateID) }) || null
            // Normalize placeholders giống normalizeTemplate của admin
            if (tpl && !tpl.Placeholders) {
              var src = tpl.PlaceholderJSON || tpl.MergeFields || null
              if (typeof src === 'string') { try { tpl.Placeholders = JSON.parse(src) || [] } catch (e) { tpl.Placeholders = [] } }
              else if (Array.isArray(src)) tpl.Placeholders = src
              else tpl.Placeholders = []
            }
            return {
              SlotIdx: Number(slot.SlotIdx || 0),
              Label: slot.Label || ('Template ' + (Number(slot.SlotIdx || 0) + 1)),
              TemplateID: slot.TemplateID ? Number(slot.TemplateID) : null,
              SignSystem: slot.SignSystem || 'smartca',
              template: tpl
            }
          })
          this.activeTemplate = null // multi-template mode: không dùng activeTemplate
        } else {
          this.activeTemplates = null
          if (templateId) {
            this.activeTemplate = this.templates.find(t => Number(t.TemplateID) === Number(templateId)) || null
          } else {
            this.activeTemplate = null
          }
        }

        const initVals = {}
        if (this.customFields) {
          this.customFields.forEach(f => {
            initVals[f.FieldName] = ''
          })
        }
        this.instanceData.forEach(d => {
          initVals[d.FieldName] = d.FieldValue || ''
        })

        if (this.checklistItems && this.checklistItems.length > 0) {
          this.checklistItems.forEach(chkItem => {
            const matchedField = self.findMatchedFieldForChecklist(chkItem)
            if (matchedField) {
              const fieldName = matchedField.FieldName
              if (!initVals[fieldName] && chkItem.AttachmentUrl) {
                initVals[fieldName] = chkItem.AttachmentUrl
              }
            }
          })
        }
        this.editFieldValues = initVals

        if (this.previewPdfUrl && this.previewPdfUrl.indexOf("blob:") === 0) {
          URL.revokeObjectURL(this.previewPdfUrl)
        }
        this.previewPdfUrl = ""

        // Đồng bộ tọa độ signBoxes + tạo previewPdfUrl từ merge docx→PDF
        // Chỉ gọi khi KHÔNG hiển thị uc-request-detail-view (tránh double merge)
        // uc-request-detail-view tự xử lý merge trong checkAndMergeDocx của nó
        if (!this.showSignDetail) {
          this.syncSignBoxesFromMergedAnchors()
        }

        // if (this.activeTemplate) {
        //   const fileUrl = this.activeTemplate.FileUrl || ""
        //   const fileId = this.extractFileIdFromUrl(fileUrl)
        //   if (fileId) {
        //     this.isGeneratingPreview = true
        //     this.activeTemplateFileName = this.activeTemplate.FileName || this.activeTemplate.TemplateName || "template.docx"
        //     try {
        //       const binary = await this.tryReadFileBinaryById(fileId)
        //       if (binary) {
        //         this.activeTemplateBinary = binary
        //         await this.updateMergedPreviewPdf()
        //       }
        //     } catch (err) {
        //       console.error("Không load được binary template:", err)
        //     } finally {
        //       this.isGeneratingPreview = false
        //     }
        //   }
        // } else {
        //   const docId = self.theChiTiet.CurrentDocumentFileID || self.theChiTiet.SourceFileID || null
        //   if (docId) {
        //     this.isGeneratingPreview = true
        //     try {
        //       const binary = await this.tryReadFileBinaryById(docId)
        //       if (binary) {
        //         this.previewPdfUrl = this.base64ToBlobUrl(binary, "application/pdf")
        //       }
        //     } catch (err) {
        //       console.error("Không load được binary tài liệu gốc:", err)
        //     } finally {
        //       this.isGeneratingPreview = false
        //     }
        //   }
        // }

        await this.fetchApiDataSources()
      } catch (err) {
        console.error(err)
      } finally {
        if (!isSilent) {
          this.isLoading = false
        }
      }
    },

    fetchApiDataSources: async function () {
      const self = this
      const apiFields = this.customFieldsForCurrentStep.filter(f => f.FieldType === 'select' && f.DataSourceType === 'api' && f.DataSourceApi)
      if (apiFields.length === 0) return

      const promises = apiFields.map(async (field) => {
        try {
          if (self.apiDataSources[field.DataSourceApi]) return
          const ds = await apiCallAsync(field.DataSourceApi, {})
          if (Array.isArray(ds)) {
            const normalized = ds.map(item => {
              return {
                Value: item.Value || item.ID || item.Id || item.id || '',
                Text: item.Text || item.Name || item.Ten || item.name || ''
              }
            })
            self.$set ? self.$set(self.apiDataSources, field.DataSourceApi, normalized) : self.apiDataSources[field.DataSourceApi] = normalized
          }
        } catch (e) {
          console.error('Không tải được nguồn dữ liệu select API ' + field.DataSourceApi, e)
        }
      })
      await Promise.all(promises)
    },
    goBack() {
      if (this.isModal) {
        this.$emit('close')
      } else {
        window.location.href = '/wf-kanban-flow'
      }
    },
    goToSignFlow: function () {
      // Chỉ truyền signers thuộc execution hiện tại để tránh index lệch khi có nhiều executions
      var currentExecId = this.theChiTiet ? Number(this.theChiTiet.CurrentExecutionID || 0) : 0
      var currentSigners = (this.signers || []).filter(function (s) {
        return currentExecId > 0 ? Number(s.ExecutionID || 0) === currentExecId : true
      })
      this.$refs.signerConfigDialogRef.open(
        this.instanceId,
        currentSigners,
        this.signBoxes,
        this.theChiTiet ? this.theChiTiet.ExecutionEngine : 'SMARTCA',
        this.theChiTiet ? this.theChiTiet.ExternalContractID : 0,
        this.theChiTiet ? this.theChiTiet.CurrentStepDefID : null,
        this.theChiTiet ? this.theChiTiet.DefinitionID : 0,
        this.editFieldValues
      )
    },
    onSignersSaved: function () {
      this.showSignDetail = true
      if (this.$refs.detailViewRef && typeof this.$refs.detailViewRef.loadDetail === 'function') {
        this.$refs.detailViewRef.loadDetail()
      }
    },
    themNhiemVuThuCong: async function () {
      if (!this.taskMoiName || !this.taskMoiName.trim()) {
        if (typeof showToast !== 'undefined' && showToast.error) showToast.error('Vui lòng nhập tên nhiệm vụ!')
        return
      }
      try {
        var res = await apiCallAsync('WF_InstanceTask_Save', {
          InstanceID: this.theChiTiet.InstanceID,
          TaskName: this.taskMoiName.trim(),
          IsRequired: this.taskMoiIsRequired ? 1 : 0
        })
        if (res && res.Success !== false) {
          if (typeof showToast !== 'undefined' && showToast.success) showToast.success('Thêm nhiệm vụ mới thành công!')
          this.taskMoiName = ''
          this.taskMoiIsRequired = false
          this.dialogThemTask = false

          // Reload lại toàn bộ dữ liệu chi tiết công việc
          await this.loadData(true)
        } else {
          if (typeof showToast !== 'undefined' && showToast.error) showToast.error(res.Message || 'Lỗi thêm nhiệm vụ con')
        }
      } catch (err) {
        console.error('Lỗi khi thêm nhiệm vụ con thủ công:', err)
        if (typeof showToast !== 'undefined' && showToast.error) showToast.error('Lỗi hệ thống: ' + (err.message || ''))
      }
    },

    toggleTaskStatus: async function (task) {
      const newStatus = task.Status === 'DONE' ? 'TODO' : 'DONE'
      try {
        const result = await apiCallAsync('WF_InstanceTask_UpdateStatus', {
          TaskID: task.TaskID,
          Status: newStatus
        })
        const row = Array.isArray(result) ? result[0] : result
        if (row && Number(row.Success) === 1) {
          task.Status = newStatus
          if (showToast && showToast.success) showToast.success('Đã cập nhật trạng thái công việc.')
          if (this.theChiTiet) {
            await this.loadData(true)
          }
        } else {
          const msg = row ? row.Message : 'Lỗi không xác định'
          if (showToast && showToast.error) showToast.error('Không thể cập nhật: ' + msg)
        }
      } catch (err) {
        const errMsg = err && err.responseJSON ? err.responseJSON.Message : (err && err.message ? err.message : 'Lỗi không xác định')
        if (showToast && showToast.error) showToast.error('Không thể cập nhật: ' + errMsg)
      }
    },

    isValidDateValue(val) {
      if (!val) return false
      return /^\d{4}-\d{2}-\d{2}$/.test(String(val))
    },

    saveFieldValues: async function () {
      if (!this.theChiTiet) return
      this.isSaving = true
      const self = this
      try {
        const invalidDates = this.customFieldsForCurrentStep.filter(f => {
          return f.FieldType === 'date' && !!self.editFieldValues[f.FieldName] && !self.isValidDateValue(self.editFieldValues[f.FieldName])
        })
        if (invalidDates.length > 0) {
          const labels = invalidDates.map(f => f.FieldLabel || f.FieldName).join(', ')
          if (showToast && showToast.error) showToast.error('Trường ngày tháng không hợp lệ: ' + labels + '. Vui lòng chọn ngày hợp lệ.')
          this.isSaving = false
          return
        }

        const fields = this.customFieldsForCurrentStep.map(f => {
          return { FieldName: f.FieldName, FieldValue: String(self.editFieldValues[f.FieldName] || '') }
        })
        const rawData = {
          UpdatedAtStep: this.theChiTiet.CurrentStepOrder,
          Fields: fields
        }
        const result = await apiCallAsync('WF_InstanceData_Save', {
          InstanceID: this.theChiTiet.InstanceID,
          DataJSON: JSON.stringify(rawData)
        })
        const row = Array.isArray(result) ? result[0] : result
        if (row && Number(row.Success) === 1) {
          if (showToast && showToast.success) showToast.success('Đã lưu dữ liệu thành công.')

          const freshData = await apiCallAsync('WF_InstanceData_GetList', { InstanceID: self.theChiTiet.InstanceID })
          this.instanceData = freshData || []

          const updatedVals = {}
          if (this.customFields) {
            this.customFields.forEach(f => {
              updatedVals[f.FieldName] = ''
            })
          }
          this.instanceData.forEach(d => {
            updatedVals[d.FieldName] = d.FieldValue || ''
          })

          if (this.checklistItems && this.checklistItems.length > 0) {
            this.checklistItems.forEach(chkItem => {
              const matchedField = self.findMatchedFieldForChecklist(chkItem)
              if (matchedField) {
                const fieldName = matchedField.FieldName
                if (!updatedVals[fieldName] && chkItem.AttachmentUrl) {
                  updatedVals[fieldName] = chkItem.AttachmentUrl
                }
              }
            })
          }
          this.editFieldValues = updatedVals

          if (this.checklistItems && this.checklistItems.length > 0) {
            for (let i = 0; i < this.checklistItems.length; i++) {
              const chkItem = this.checklistItems[i]
              const matchedField = self.findMatchedFieldForChecklist(chkItem)
              if (matchedField) {
                const val = this.editFieldValues[matchedField.FieldName]
                const rawData = {
                  IsCompleted: val ? 1 : 0,
                  SubmitMethod: val ? 'SOFT_COPY' : null,
                  AttachmentUrl: val ? String(val) : null,
                  IsDeferred: chkItem.IsDeferred ? 1 : 0,
                  DeferredDueDate: chkItem.DeferredDueDate || null,
                  Note: chkItem.Note || null
                }
                await apiCallAsync('WF_InstanceChecklist_Save', {
                  InstanceID: self.theChiTiet.InstanceID,
                  ChecklistDefID: chkItem.ChecklistDefID,
                  DataJSON: JSON.stringify(rawData)
                })
              }
            }
          }

          await this.loadData(true)
          if (this.activeTemplate) {
            await this.updateMergedPreviewPdf()
          }
        } else {
          const msg = row ? row.Message : 'Lỗi không xác định'
          if (showToast && showToast.error) showToast.error('Không thể lưu: ' + msg)
        }
      } catch (err) {
        const errMsg = err && err.responseJSON ? err.responseJSON.Message : (err && err.message ? err.message : 'Lỗi không xác định')
        if (showToast && showToast.error) showToast.error('Không thể lưu: ' + errMsg)
      } finally {
        this.isSaving = false
      }
    },

    saveChecklistItem: async function (item) {
      if (!this.theChiTiet) return
      const self = this
      try {
        const rawData = {
          IsCompleted: item.IsCompleted ? 1 : 0,
          SubmitMethod: item.SubmitMethod || null,
          AttachmentUrl: item.AttachmentUrl || null,
          IsDeferred: item.IsDeferred ? 1 : 0,
          DeferredDueDate: item.DeferredDueDate || null,
          Note: item.Note || null
        }
        await apiCallAsync('WF_InstanceChecklist_Save', {
          InstanceID: this.theChiTiet.InstanceID,
          ChecklistDefID: item.ChecklistDefID,
          DataJSON: JSON.stringify(rawData)
        })

        const matchedField = this.findMatchedFieldForChecklist(item)
        if (matchedField) {
          const expectedVal = item.AttachmentUrl || ''
          if (String(this.editFieldValues[matchedField.FieldName] || '') !== String(expectedVal)) {
            self.$set ? self.$set(self.editFieldValues, matchedField.FieldName, expectedVal) : self.editFieldValues[matchedField.FieldName] = expectedVal
          }
        }
        if (showToast && showToast.success) showToast.success('Đã cập nhật hồ sơ.')
      } catch (err) {
        console.error('Lỗi khi lưu checklist:', err)
        if (showToast && showToast.error) {
          showToast.error('Không thể cập nhật tiến trình hồ sơ.')
        }
      }
    },

    quickMoveStep() {
      if (!this.theChiTiet) return
      const self = this

      const currentOrder = Number(this.theChiTiet.CurrentStepOrder || 0)
      const nextSteps = this.dsCot.filter(c => typeof c.id === 'number' && Number(c.order) > currentOrder)
      nextSteps.sort((a, b) => a.order - b.order)

      if (nextSteps.length === 0) {
        if (showToast && showToast.error) showToast.error('Không tìm thấy bước tiếp theo phù hợp.')
        return
      }
      const targetStep = nextSteps[0]
      this.quickMoveToStep(targetStep.id)
    },

    quickMoveToStep(stepId) {
      if (!this.theChiTiet) return
      const self = this
      const cot = this.dsCot.find(c => c.id === stepId)
      if (!cot) return

      // Kiểm tra chuyển ngược bước về bước Nhập dữ liệu (INPUT_ONLY) khi đã có chữ ký
      const currentOrder = Number(this.theChiTiet.CurrentStepOrder || 0)
      const targetOrder = Number(cot.order || 0)
      if (targetOrder < currentOrder && cot.stepType === 'INPUT_ONLY') {
        const hasSigned = (this.signers || []).some(s => this.isSignedRuntimeStatus(s.Status)) ||
                          (this.signBoxes || []).some(b => this.isSignedRuntimeStatus(this.resolveSignBoxRuntimeStatus(b)))
        if (hasSigned) {
          if (showToast && showToast.error) showToast.error('Hồ sơ đã có chữ ký, không thể chuyển ngược về bước nhập dữ liệu!')
          return
        }
      }

      const incompleteRequiredTasks = this.instanceTasksForCurrentStep.filter(t => t.IsRequired && t.Status !== 'DONE')
      if (incompleteRequiredTasks.length > 0) {
        if (showToast && showToast.error) showToast.error('Vui lòng hoàn thành tất cả nhiệm vụ con bắt buộc trước khi chuyển bước.')
        return
      }

      const requiredFields = this.customFieldsForCurrentStep.filter(f => f.IsRequired)
      const emptyRequired = requiredFields.filter(f => {
        return !self.editFieldValues[f.FieldName] || String(self.editFieldValues[f.FieldName]).trim() === ''
      })
      if (emptyRequired.length > 0) {
        const labels = emptyRequired.map(f => f.FieldLabel || f.FieldName).join(', ')
        if (showToast && showToast.error) showToast.error('Vui lòng nhập đầy đủ thông tin bắt buộc trước khi chuyển bước: ' + labels)
        return
      }

      const stepType = String(cot.stepType || '').toUpperCase()
      const stepName = String(cot.tenCot || '').toLowerCase()
      const isSignOrApprove = stepType === 'SIGN' || stepType === 'ECONTRACT' || stepType === 'APPROVE' || stepType === 'REVIEW' || stepName.indexOf('ký') >= 0 || stepName.indexOf('duyệt') >= 0 || stepName.indexOf('sign') >= 0 || stepName.indexOf('approve') >= 0 || stepName.indexOf('review') >= 0

      // [REMOVED] Khối lệnh mở popup cấu hình người ký (signerConfigDialog) cho bước Ký.
      // Dữ liệu người ký đã được quy định từ trước qua Form (tblWF_InstanceData).

      const tenHoSo = this.theChiTiet.tieuDe || this.theChiTiet.InstanceName
      showConfirm(
        'Chuyển "' + tenHoSo + '" sang bước "' + cot.tenCot + '"?\n\nHành động này sẽ cập nhật bước hiện tại của hồ sơ.',
        async function () {
          self.isMovingStep = true
          try {
            var moveResult = await apiCallAsync('WF_Instance_MoveStep', {
              InstanceID: self.theChiTiet.InstanceID,
              ToStepDefID: Number(cot.id)
            })
            var moveRow = moveResult && moveResult[0] ? moveResult[0] : moveResult
            if (moveRow && Number(moveRow.Success) === 0) {
              if (showToast && showToast.error) showToast.error(moveRow.Message || 'Không thể chuyển tiếp bước hồ sơ.')
              return
            }
            if (showToast && showToast.success) showToast.success('Chuyển tiếp hồ sơ thành công!')
            await self.loadData(true)
          } catch (err) {
            console.error(err)
            if (showToast && showToast.error) showToast.error('Không thể chuyển tiếp bước hồ sơ.')
          } finally {
            self.isMovingStep = false
          }
        },
        null
      )
    },

    cancelInstance() {
      const self = this
      if (!this.theChiTiet) return
      showConfirm(
        'Bạn có chắc chắn muốn hủy nhiệm vụ này không?',
        async function () {
          try {
            await apiCallAsync('WF_Instance_UpdateStatus', { InstanceID: self.theChiTiet.InstanceID, StatusID: 'CANCELLED' })
            if (showToast && showToast.success) showToast.success('Hủy nhiệm vụ thành công!')
            self.goBack()
          } catch (err) {
            if (showToast && showToast.error) showToast.error('Lỗi khi hủy nhiệm vụ: ' + (err.message || 'Lỗi không xác định'))
          }
        },
        null
      )
    },

    deleteInstance() {
      const self = this
      if (!this.theChiTiet) return
      showConfirm(
        'Bạn có chắc chắn muốn xóa nhiệm vụ này không?',
        async function () {
          try {
            await apiCallAsync('WF_Instance_Delete', { InstanceID: self.theChiTiet.InstanceID })
            if (showToast && showToast.success) showToast.success('Xóa nhiệm vụ thành công!')
            self.goBack()
          } catch (err) {
            if (showToast && showToast.error) showToast.error('Lỗi khi xóa nhiệm vụ: ' + (err.message || 'Lỗi không xác định'))
          }
        },
        null
      )
    },

    onChecklistUploadRequested(item) {
      this.activeChecklistItemToUpload = item
      const fileInput = this.$refs.checklistFileInput
      const el = Array.isArray(fileInput) ? fileInput[0] : fileInput
      if (el) el.click()
    },

    onChecklistFileSelected: function (event) {
      const self = this
      const item = this.activeChecklistItemToUpload
      if (!item) return

      const files = event && event.target ? event.target.files : null
      const file = files && files[0] ? files[0] : null
      if (!file) return

      const reader = new FileReader()
      reader.onload = function (evt) {
        const dataUrl = evt && evt.target ? evt.target.result : ""
        if (!dataUrl || String(dataUrl).indexOf(",") < 0) {
          if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không đọc được nội dung file.")
          return
        }
        const base64 = String(dataUrl).split(",")[1] || ""
        if (typeof apiCall === "function") {
          apiCall("UPLOAD_FileData_Base64", {
            FileBase64: base64,
            FileName: file.name || "checklist-document.pdf",
            FileContentType: file.type || "application/octet-stream"
          }, function (res) {
            const fileRow = self.extractFileRow(res)
            if (!fileRow || !fileRow.FileID) {
              if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không nhận được FileID.")
              return
            }
            const valStr = JSON.stringify({
              FileID: fileRow.FileID,
              FileName: fileRow.FileName || file.name
            })

            self.$set ? self.$set(item, "AttachmentUrl", valStr) : item.AttachmentUrl = valStr
            self.$set ? self.$set(item, "IsCompleted", 1) : item.IsCompleted = 1
            self.$set ? self.$set(item, "SubmitMethod", "SOFT_COPY") : item.SubmitMethod = "SOFT_COPY"

            const matchedField = self.findMatchedFieldForChecklist(item)
            if (matchedField) {
              self.$set ? self.$set(self.editFieldValues, matchedField.FieldName, valStr) : self.editFieldValues[matchedField.FieldName] = valStr
            }

            self.saveChecklistItem(item)

            if (typeof showToast !== "undefined" && showToast.success) showToast.success("Tải tệp lên thành công.")
          }, function (err) {
            const msg = err && err.message ? err.message : "Tải tệp lên thất bại."
            if (typeof showToast !== "undefined" && showToast.error) showToast.error(msg)
          })
        }
      }
      reader.readAsDataURL(file)
      if (event.target) event.target.value = ""
    },

    extractFileRow(res) {
      if (!res) return null
      if (res.data) return this.extractFileRow(res.data)
      if (res.Files && res.Files[0]) return this.extractFileRow(res.Files[0])
      if (res.Result) return this.extractFileRow(res.Result)
      if (Array.isArray(res)) {
        if (res.length === 0) return null
        return this.extractFileRow(res[0])
      }
      if (typeof res === "object") {
        const fileId = res.FileID || res.FILE_ID || res.fileId || res.FileId
        if (fileId) {
          return {
            FileID: fileId,
            FileName: res.FileName || res.FILE_NAME || res.fileName || res.Name || ""
          }
        }
      }
      return null
    },

    applyAnchorsToSignBoxes: function (signBoxes, anchors, totalBoxCount) {
      // Thứ tự ưu tiên match anchor (Bug 1 fix):
      // 1. LabelText – placeholder trong docx (###sig_tgd###) – chính xác nhất, không bị ảnh hưởng bởi thứ tự DB
      // 2. BoxOrder  – unique per-document
      // 3. SignerOrder – có thể trùng nếu 1 người ký ở nhiều vị trí
      // 4. index fallback
      return (signBoxes || []).map(function (box, boxIdx) {
        var anchor = null

        // Ưu tiên 1: LabelText
        if (!anchor && box.LabelText) {
          anchor = anchors.find(function (a) {
            var token = a.token || a.Token || a.labelText || a.LabelText || ''
            return token && token === box.LabelText
          })
          if (!anchor) {
            var m = box.LabelText.match(/^###(.+)###$/) || box.LabelText.match(/^\{\{(.+)\}\}$/)
            if (m) {
              var plainLabel = m[1]
              anchor = anchors.find(function (a) {
                var token = a.token || a.Token || a.labelText || a.LabelText || ''
                return token === plainLabel || token === '###' + plainLabel + '###' || token === '{{' + plainLabel + '}}'
              })
            }
          }
        }

        // Ưu tiên 2: BoxOrder
        if (!anchor && Number(box.BoxOrder) > 0) {
          anchor = anchors.find(function (a) {
            var bOrder = a.boxOrder != null ? a.boxOrder : a.BoxOrder
            return Number(bOrder) === Number(box.BoxOrder)
          })
        }

        // Ưu tiên 3: SignerOrder
        if (!anchor && Number(box.SignerOrder) > 0) {
          anchor = anchors.find(function (a) {
            var order = a.signerOrder != null ? a.signerOrder : a.SignerOrder
            return Number(order) === Number(box.SignerOrder)
          })
        }

        // Fallback: index
        if (!anchor && anchors.length === totalBoxCount) {
          anchor = anchors[boxIdx] || null
        }

        if (!anchor) return box
        return Object.assign({}, box, {
          PageNo:    anchor.pageNo    != null ? anchor.pageNo    : (anchor.PageNo    != null ? anchor.PageNo    : box.PageNo),
          PosX:      anchor.posX      != null ? anchor.posX      : (anchor.PosX      != null ? anchor.PosX      : box.PosX),
          PosY:      anchor.posY      != null ? anchor.posY      : (anchor.PosY      != null ? anchor.PosY      : box.PosY),
          BoxWidth:  anchor.boxWidth  != null ? anchor.boxWidth  : (anchor.BoxWidth  != null ? anchor.BoxWidth  : box.BoxWidth),
          BoxHeight: anchor.boxHeight != null ? anchor.boxHeight : (anchor.BoxHeight != null ? anchor.BoxHeight : box.BoxHeight)
        })
      })
    },

    tryReadFileBinaryById: async function (fileId) {
      if (!fileId) return ""
      try {
        const rows = await apiCallAsync("FileData_GetByID", { FileID: fileId })
        const row = rows && rows[0] ? rows[0] : null
        const binary = row && (row.BinaryContent || row.FILE_CONTENT || row.File_Binary || row.FILE_BINARY || row.FileBinaryBase64 || row.FileBinary || "")
        return binary
      } catch (err) {
        console.error("Không đọc được file binary:", err)
        return ""
      }
    },

    base64ToBlobUrl(base64, contentType) {
      contentType = contentType || 'application/pdf'
      const sliceSize = 1024
      const byteCharacters = atob(base64.replace(/^data:application\/pdf;base64,/, ''))
      const byteArrays = []
      for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
        const slice = byteCharacters.slice(offset, offset + sliceSize)
        const byteNumbers = new Array(slice.length)
        for (let i = 0; i < slice.length; i++) {
          byteNumbers[i] = slice.charCodeAt(i)
        }
        const byteArray = new Uint8Array(byteNumbers)
        byteArrays.push(byteArray)
      }
      const blob = new Blob(byteArrays, { type: contentType })
      return URL.createObjectURL(blob)
    },

    extractFileIdFromUrl(url) {
      const raw = String(url || "")
      const match = raw.match(/\/FileData\/([A-Za-z0-9]+)/i)
      if (match && match[1]) return match[1]
      return ""
    },

    resolveEcontractProxyBase() {
      if (window.__WF_ECONTRACT_PROXY_BASE__) {
        return window.__WF_ECONTRACT_PROXY_BASE__
      }
      return "https://ca-uat.iotsoftvn.com"
    },

    buildEcontractUrl(path) {
      let base = this.resolveEcontractProxyBase()
      if (base.slice(-1) === "/") base = base.slice(0, -1)
      if (path.charAt(0) !== "/") path = "/" + path
      return base + path
    },

    resolveEcontractApiKey() {
      return "eGFjLXRodWMtdHUtbGh1LWVkdS12bkAyMDI1QGZ1aS52bg=="
    },

    econtractRequest: async function (method, path, payload, authToken) {
      const url = this.buildEcontractUrl(path)
      const apiKey = this.resolveEcontractApiKey()
      const headers = {
        "Content-Type": "application/json",
        "x-api-key": apiKey
      }
      if (authToken) {
        headers["Authorization"] = "Bearer " + authToken
      }
      const options = {
        method: method,
        headers: headers
      }
      if (payload) {
        options.body = JSON.stringify(payload)
      }
      const res = await fetch(url, options)
      if (!res.ok) {
        throw new Error("HTTP error " + res.status + ": " + res.statusText)
      }
      return res.json()
    },

    updateMergedPreviewPdf: async function () {
      if (!this.activeTemplateBinary) {
        this.previewPdfUrl = ""
        return
      }
      this.isGeneratingPreview = true
      try {
        const fields = []
        const self = this
        // Build signatureFieldNames để skip các field chữ kí → giữ nguyên placeholder ###sig_1### trong docx
        const signatureFieldNames = self.buildSignatureFieldNames()

        Object.keys(this.editFieldValues).forEach(key => {
          // Skip signature fields to preserve anchor placeholders in docx
          if (signatureFieldNames[key]) return
          const val = self.editFieldValues[key] == null ? "" : String(self.editFieldValues[key])
          fields.push({ Key: key, Value: val })
          fields.push({ Key: "###" + key + "###", Value: val })
          fields.push({ Key: "{{" + key + "}}", Value: val })
        })

        const res = await this.econtractRequest("POST", "/api/pdf/merge-docx-template-to-pdf", {
          FileBase64: this.activeTemplateBinary,
          FileName: this.activeTemplateFileName || "template.docx",
          Fields: fields
        }, "")

        // Chỉ tạo blob preview, KHÔNG upload lên server (updateMergedPreviewPdf là preview tạm)
        const pdfBase64 = res.PdfBase64 || res.pdfBase64 || res.FileBase64 || res.fileBase64 || ""
        if (pdfBase64) {
          if (this.previewPdfUrl && this.previewPdfUrl.indexOf("blob:") === 0) {
            URL.revokeObjectURL(this.previewPdfUrl)
          }
          this.lastMergedPdfBase64 = pdfBase64
          this.previewPdfUrl = this.base64ToBlobUrl(pdfBase64, "application/pdf")
        }

        const anchors = res.signatureAnchors || res.SignatureAnchors || []
        if (anchors.length) {
          this.signBoxes = this.applyAnchorsToSignBoxes(this.signBoxes, anchors, this.signBoxes.length)
        }
      } catch (err) {
        console.error("Lỗi trộn tài liệu Word to PDF:", err)
      } finally {
        this.isGeneratingPreview = false
      }
    },

    evaluateComputedField(formula, values) {
      // Dùng helper chung WF_FORMULA (lhbs-esign/imports/wf-formula-js.js)
      if (typeof window !== 'undefined' && window.WF_FORMULA) {
        return window.WF_FORMULA.evaluate(formula, values)
      }
      return '0'
    },

    getChecklistOptions(options) {
      const raw = String(options || '').trim()
      if (!raw) return []
      try {
        const parsed = JSON.parse(raw)
        if (Array.isArray(parsed)) return parsed
      } catch (e) {}
      if (raw.indexOf(',') >= 0) return raw.split(',').map(s => s.trim())
      return [raw]
    },

    getChecklistState(fieldName) {
      const raw = this.editFieldValues[fieldName] || ""
      if (typeof raw === "object" && raw !== null) return raw
      try {
        const parsed = JSON.parse(raw)
        if (parsed && typeof parsed === "object") return parsed
      } catch (e) {}
      return {}
    },

    toggleChecklistItem(fieldName, item) {
      const state = this.getChecklistState(fieldName)
      state[item] = !state[item]
      this.$set ? this.$set(this.editFieldValues, fieldName, JSON.stringify(state)) : this.editFieldValues[fieldName] = JSON.stringify(state)
    },

    toggleSingleCheckbox(fieldName) {
      const val = Number(this.editFieldValues[fieldName]) === 1 || this.editFieldValues[fieldName] === true || this.editFieldValues[fieldName] === 'true' ? 0 : 1
      this.$set ? this.$set(this.editFieldValues, fieldName, val) : this.editFieldValues[fieldName] = val
    },

    getStatusColor(status) {
      const key = String(status || '').toUpperCase()
      if (key === 'COMPLETED') return '#2a9d5b'
      if (key === 'REJECTED' || key === 'CANCELLED') return '#e07a7a'
      if (key === 'RUNNING' || key === 'ACTIVE' || key === 'SIGNING') return '#5b8fd6'
      if (key === 'WAITING_ME' || key === 'PENDING') return '#d9a441'
      return '#9aa5b1'
    },

    getCurrentStepName() {
      if (!this.theChiTiet) return ''
      const status = String(this.theChiTiet.Status || '').toUpperCase();
      if (status === 'COMPLETED' || status === 'SUCCESS') {
        const successStep = this.dsCot.find(c => c.stepType === 'SUCCESS' || c.stepCode === 'STEP_SUCCESS');
        if (successStep) return successStep.tenCot;
        return 'Thành công';
      }
      if (status === 'CANCELLED' || status === 'REJECTED' || status === 'FAILURE') {
        const failureStep = this.dsCot.find(c => c.stepType === 'FAILURE' || c.stepCode === 'STEP_FAILURE');
        if (failureStep) return failureStep.tenCot;
        return 'Thất bại';
      }
      if (this.dsCot && this.dsCot.length > 0) {
        const match = this.dsCot.find(c => Number(c.id) === Number(this.theChiTiet.CurrentStepDefID))
        if (match) return match.tenCot
      }
      return this.theChiTiet.CurrentStepName || ('Bước ' + (this.theChiTiet.CurrentStepOrder || ''))
    },

    getTypeBadgeInfo(type) {
      switch (type) {
        case "text": return { icon: "mdi-text-short", label: "Văn bản", color: "blue" }
        case "textarea": return { icon: "mdi-text-long", label: "Đoạn văn", color: "blue-grey" }
        case "number": return { icon: "mdi-numeric", label: "Số", color: "indigo" }
        case "date": return { icon: "mdi-calendar", label: "Ngày", color: "teal" }
        case "select": return { icon: "mdi-form-select", label: "Lựa chọn", color: "purple" }
        case "file": return { icon: "mdi-file-outline", label: "Tải tệp", color: "orange" }
        case "image": return { icon: "mdi-image-outline", label: "Hình ảnh", color: "pink" }
        case "user": return { icon: "mdi-account-outline", label: "Thành viên", color: "cyan" }
        case "checkbox":return { icon: "mdi-checkbox-marked-outline", label: "Checkbox", color: "green" }
        case "rating": return { icon: "mdi-star-outline", label: "Đánh giá", color: "amber" }
        case "computed": return { icon: "mdi-calculator-variant", label: "Tính toán", color: "deep-orange" }
        case "signature": return { icon: "mdi-pencil-edit-outline", label: "Chữ kí", color: "red" }

        default: return { icon: "mdi-help-circle-outline", label: "Khác", color: "grey" }
      }
    },

    getFieldFileName(value) {
      if (!value) return ""
      try {
        const parsed = JSON.parse(value)
        if (parsed && parsed.FileName) return parsed.FileName
      } catch (e) {}
      return String(value)
    },

    getFieldFileUrl(value) {
      if (!value) return ""
      try {
        const parsed = JSON.parse(value)
        if (parsed && parsed.FileID) return "https://file.zentea.vn/iotdev/FileData/" + parsed.FileID
      } catch (e) {}
      const fileId = String(value).trim()
      if (fileId && fileId.indexOf("http") === -1 && fileId.length >= 10) {
        return "https://file.zentea.vn/iotdev/FileData/" + fileId
      }
      return fileId
    },

    clearFieldFile(fieldName, valuesObj) {
      this.$set ? this.$set(valuesObj, fieldName, "") : valuesObj[fieldName] = ""
      if (showToast && showToast.success) showToast.success('Đã xóa tệp đính kèm.')
      this.saveFieldValues()
    },

    isImageFile(value) {
      if (!value) return false
      const fileName = this.getFieldFileName(value)
      if (!fileName) return false
      return /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(fileName)
    },

    triggerFieldFileInput(fieldName, isCreateMode) {
      const refName = (isCreateMode ? 'create_file_input_' : 'detail_file_input_') + fieldName
      const ref = this.$refs[refName]
      const el = Array.isArray(ref) ? ref[0] : ref
      if (el) el.click()
    },

    onFieldFileSelected(event, fieldName, valuesObj) {
      const self = this
      const files = event && event.target ? event.target.files : null
      const file = files && files[0] ? files[0] : null
      if (!file) return

      const reader = new FileReader()
      reader.onload = function (evt) {
        const dataUrl = evt && evt.target ? evt.target.result : ""
        if (!dataUrl || String(dataUrl).indexOf(",") < 0) {
          if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không đọc được nội dung file.")
          return
        }
        const base64 = String(dataUrl).split(",")[1] || ""
        if (typeof apiCall === "function") {
          apiCall("UPLOAD_FileData_Base64", {
            FileBase64: base64,
            FileName: file.name || "field-document.pdf",
            FileContentType: file.type || "application/octet-stream"
          }, function (res) {
            const fileRow = self.extractFileRow(res)
            if (!fileRow || !fileRow.FileID) {
              if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không nhận được FileID từ API.")
              return
            }
            const valStr = JSON.stringify({
              FileID: fileRow.FileID,
              FileName: fileRow.FileName || file.name
            })
            self.$set ? self.$set(valuesObj, fieldName, valStr) : valuesObj[fieldName] = valStr
            if (typeof showToast !== "undefined" && showToast.success) showToast.success("Tải tệp lên thành công.")
            self.saveFieldValues()
          }, function (err) {
            const msg = err && err.message ? err.message : "Tải tệp lên thất bại."
            if (typeof showToast !== "undefined" && showToast.error) showToast.error(msg)
          })
        }
      }
      reader.readAsDataURL(file)
      if (event.target) event.target.value = ""
    },

    ensureMergedPreview: async function (forceMerge) {
      if (!this.theChiTiet) return false
      const runtimeDoc = this.resolveBestRuntimeDocument()
      const runtimeName = String(runtimeDoc.FileName || "").toLowerCase()
      const isRuntimePdf = runtimeName.indexOf(".pdf") >= 0 && runtimeDoc.FileID

      if (this.activeTemplate && !isRuntimePdf) {
        if (!this.activeTemplateBinary) {
          const fileUrl = this.activeTemplate.FileUrl || ""
          const fileId = this.extractFileIdFromUrl(fileUrl)
          if (fileId) {
            this.isGeneratingPreview = true
            this.activeTemplateFileName = this.activeTemplate.FileName || this.activeTemplate.TemplateName || "template.docx"
            try {
              const binary = await this.tryReadFileBinaryById(fileId)
              if (binary) {
                this.activeTemplateBinary = binary
              }
            } catch (err) {
              console.error("Không load được binary template:", err)
              if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không tải được tệp mẫu Word.")
              this.isGeneratingPreview = false
              return false
            }
          } else {
            if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không tìm thấy ID của tệp mẫu.")
            return false
          }
        }
        try {
          this.isGeneratingPreview = true
          await this.updateMergedPreviewPdf()
          return true
        } catch (err) {
          console.error("Lỗi khi merge PDF:", err)
          if (typeof showToast !== "undefined" && showToast.error) showToast.error("Lỗi khi trộn dữ liệu vào tệp mẫu.")
          return false
        } finally {
          this.isGeneratingPreview = false
        }
      } else {
        const docId = runtimeDoc.FileID || this.theChiTiet.CurrentDocumentFileID || this.theChiTiet.SourceFileID || null
        if (docId) {
          if (this.previewPdfUrl && !forceMerge) {
            return true
          }
          this.isGeneratingPreview = true
          try {
            const binary = await this.tryReadFileBinaryById(docId)
            if (binary) {
              if (this.previewPdfUrl && this.previewPdfUrl.indexOf("blob:") === 0) {
                URL.revokeObjectURL(this.previewPdfUrl)
              }
              this.previewPdfUrl = this.base64ToBlobUrl(binary, "application/pdf")
              this.lastMergedPdfBase64 = this.normalizeBase64Content(binary)
              return true
            }
          } catch (err) {
            console.error("Không load được binary tài liệu gốc:", err)
            if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không tải được tài liệu gốc.")
          } finally {
            this.isGeneratingPreview = false
          }
        } else {
          if (typeof showToast !== "undefined" && showToast.error) showToast.error("Không có mẫu in hoặc tài liệu gốc cho bước này.")
        }
        return false
      }
    },

    async mergeAndPreview() {
      const success = await this.ensureMergedPreview(true)
      if (success && this.previewPdfUrl) {
        this.dialog.previewPdf = true
      }
    },

    async mergeAndDownload() {
      const success = await this.ensureMergedPreview(true)
      if (success && this.previewPdfUrl) {
        const link = document.createElement("a")
        link.href = this.previewPdfUrl
        let fileName = this.activeTemplate ? (this.activeTemplate.TemplateName || "mau-in") : "tai-lieu"
        fileName = fileName.replace(/\.[^/.]+$/, "")
        link.download = fileName + ".pdf"
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
      }
    },

    // [MULTI-TEMPLATE] Merge/Preview per slot: tạm set activeTemplate = slot.template rồi call ensureMergedPreview
    async mergeAndPreviewSlot(slot) {
      if (!slot || !slot.template) {
        if (typeof showToast !== 'undefined' && showToast.error) showToast.error('Template slot này chưa có file mẫu.')
        return
      }
      // Lưu lại trạng thái trước merge để restore sau khi đóng dialog
      const prevTemplate = this.activeTemplate
      const prevBinary = this.activeTemplateBinary
      const prevLastPdf = this.lastMergedPdfBase64
      const prevPreviewUrl = this.previewPdfUrl
      this.activeTemplate = slot.template
      this.activeTemplateBinary = ''
      try {
        const success = await this.ensureMergedPreview(true)
        const slotPdfUrl = success ? this.previewPdfUrl : ''
        // Restore activeTemplate ngay (không để dirty)
        this.activeTemplate = prevTemplate
        this.activeTemplateBinary = prevBinary
        this.lastMergedPdfBase64 = prevLastPdf
        if (success && slotPdfUrl) {
          // previewPdfUrl = slotPdfUrl để dialog render đúng; watcher sẽ restore khi đóng
          this.previewPdfUrl = slotPdfUrl
          this._previewPdfUrlBackup = prevPreviewUrl
          this.dialog.previewPdf = true
        } else {
          this.previewPdfUrl = prevPreviewUrl
        }
      } catch (err) {
        this.activeTemplate = prevTemplate
        this.activeTemplateBinary = prevBinary
        this.lastMergedPdfBase64 = prevLastPdf
        this.previewPdfUrl = prevPreviewUrl
        console.error('[WF] mergeAndPreviewSlot error:', err)
      }
    },

    async mergeAndDownloadSlot(slot) {
      if (!slot || !slot.template) {
        if (typeof showToast !== 'undefined' && showToast.error) showToast.error('Template slot này chưa có file mẫu.')
        return
      }
      const prevTemplate = this.activeTemplate
      const prevBinary = this.activeTemplateBinary
      const prevLastPdf = this.lastMergedPdfBase64
      const prevPreviewUrl = this.previewPdfUrl
      this.activeTemplate = slot.template
      this.activeTemplateBinary = ''
      try {
        const success = await this.ensureMergedPreview(true)
        const slotPdfUrl = success ? this.previewPdfUrl : ''
        // Restore ngay sau khi lấy URL tải xuống
        this.activeTemplate = prevTemplate
        this.activeTemplateBinary = prevBinary
        this.lastMergedPdfBase64 = prevLastPdf
        this.previewPdfUrl = prevPreviewUrl
        if (success && slotPdfUrl) {
          const link = document.createElement('a')
          link.href = slotPdfUrl
          let fileName = (slot.template.TemplateName || slot.Label || 'mau-in').replace(/\.[^/.]+$/, '')
          link.download = fileName + '.pdf'
          document.body.appendChild(link)
          link.click()
          document.body.removeChild(link)
          // Revoke blob URL tạm sau khi download
          setTimeout(function () { if (slotPdfUrl.indexOf('blob:') === 0) URL.revokeObjectURL(slotPdfUrl) }, 1000)
        }
      } catch (err) {
        this.activeTemplate = prevTemplate
        this.activeTemplateBinary = prevBinary
        this.lastMergedPdfBase64 = prevLastPdf
        this.previewPdfUrl = prevPreviewUrl
        console.error('[WF] mergeAndDownloadSlot error:', err)
      }
    },

    // [MULTI-TEMPLATE] Switch slot tab trên canvas — load đúng PDF từ slotPdfMap
    switchCanvasSlot: function (slotIdx) {
      var idx = Number(slotIdx || 0)
      if (this.activeCanvasSlotIdx === idx) return
      this.activeCanvasSlotIdx = idx
      var pdfBase64 = this.slotPdfMap && this.slotPdfMap[String(idx)]
      if (pdfBase64) {
        if (this.previewPdfUrl && this.previewPdfUrl.indexOf('blob:') === 0) URL.revokeObjectURL(this.previewPdfUrl)
        this.lastMergedPdfBase64 = pdfBase64
        this.previewPdfUrl = this.base64ToBlobUrl(pdfBase64, 'application/pdf')
      }
    },

    formatDateShort: function (val) {
      if (!val) return '-'
      var d = new Date(val)
      return d.toLocaleDateString('vi-VN')
    },

    getNextStepTransitionLabel: function () {
      if (!this.theChiTiet || !this.dsCot || !this.dsCot.length) return 'Chuyển tiếp →'
      var currentOrder = Number(this.theChiTiet.CurrentStepOrder || 0)
      var nextSteps = this.dsCot.filter(function (c) {
        return typeof c.id === 'number' && Number(c.order) > currentOrder
      })
      nextSteps.sort(function (a, b) { return a.order - b.order })
      var next = nextSteps[0]
      if (!next) return 'Chuyển tiếp →'
      // Strip leading "N. " numbering from tenCot
      var nextName = String(next.tenCot || '').replace(/^\d+\.\s*/, '')
      return nextName + ' →'
    },

    formatDateTime(val) {
      if (!val) return '-'
      const d = new Date(val)
      return d.toLocaleString('vi-VN')
    },

    getStatusIcon(status) {
      const key = String(status || '').toUpperCase()
      if (key === 'COMPLETED') return 'mdi-check'
      if (key === 'REJECTED' || key === 'CANCELLED') return 'mdi-close'
      if (key === 'RUNNING' || key === 'ACTIVE' || key === 'SIGNING') return 'mdi-play'
      if (key === 'WAITING_ME' || key === 'PENDING') return 'mdi-clock-outline'
      return 'mdi-dots-horizontal'
    },

    getStatusColorLight(status) {
      const key = String(status || '').toUpperCase()
      if (key === 'COMPLETED') return 'rgba(42, 157, 91, 0.12)'
      if (key === 'REJECTED' || key === 'CANCELLED') return 'rgba(224, 122, 122, 0.12)'
      if (key === 'RUNNING' || key === 'ACTIVE' || key === 'SIGNING') return 'rgba(91, 143, 214, 0.12)'
      if (key === 'WAITING_ME' || key === 'PENDING') return 'rgba(217, 164, 65, 0.12)'
      return 'rgba(154, 165, 177, 0.12)'
    },

    getStatusTextFriendly(status) {
      const key = String(status || '').toUpperCase()
      if (key === 'COMPLETED') return 'Đã hoàn thành'
      if (key === 'REJECTED') return 'Đã từ chối'
      if (key === 'CANCELLED') return 'Đã hủy'
      if (key === 'RUNNING') return 'Đang thực hiện'
      if (key === 'ACTIVE') return 'Đang hoạt động'
      if (key === 'SIGNING') return 'Đang trình ký'
      if (key === 'WAITING_ME') return 'Chờ tôi xử lý'
      if (key === 'PENDING') return 'Đang chờ'
      return status || 'Khác'
    },

    getInitials(name) {
      if (!name) return '?'
      const parts = String(name).trim().split(' ')
      const lastWord = parts[parts.length - 1]
      return lastWord ? lastWord.charAt(0).toUpperCase() : '?'
    },

    getRandomPastelColor(name) {
      if (!name) return '#e2e8f0'
      let hash = 0
      const str = String(name)
      for (let i = 0; i < str.length; i++) {
        hash = str.charCodeAt(i) + ((hash << 5) - hash)
      }
      const h = Math.abs(hash % 360)
      return 'hsl(' + h + ', 60%, 85%)'
    },
     loadSignerProfiles: async function () {
      try {
        var rows = await apiCallAsync("WF_SignerProfile_GetList", {})
        var list = Array.isArray(rows) ? rows : (rows && Array.isArray(rows.data) ? rows.data : [])
        this.signerProfiles = list.filter(function (item) {
          var active = item.IsActive === true || Number(item.IsActive) === 1 || String(item.IsActive).toLowerCase() === "true"
          var certActive = item.CertIsActive === true || Number(item.CertIsActive) === 1 || String(item.CertIsActive).toLowerCase() === "true"
          return active && certActive
        })
      } catch (err) {
        this.signerProfiles = []
      }
    },

    loadMySignerProfile: async function () {
      try {
        var rows = await apiCallAsync("WF_SignerProfile_GetMyActiveCert", {})
        this.mySignerProfile = rows && rows[0] ? rows[0] : null
        this.smartcaSignatureBase64 = ""
        this.smartcaUploadedSignatureBase64 = ""
      } catch (err) {
        this.mySignerProfile = null
        this.smartcaSignatureBase64 = ""
        this.smartcaUploadedSignatureBase64 = ""
      }
    },

    applyDetailData: function (datasets) {
      this.overview = this.normalizeOverview(datasets && datasets[0] ? datasets[0][0] : null)
      this.steps = this.normalizeSteps(datasets && datasets[1] ? datasets[1] : [])
      this.signers = this.normalizeSigners(datasets && datasets[2] ? datasets[2] : [])
      this.fields = this.normalizeFields(datasets && datasets[3] ? datasets[3] : [])
      this.logs = this.normalizeLogs(datasets && datasets[4] ? datasets[4] : [])
      this.signBoxes = this.normalizeSignBoxes(datasets && datasets[5] ? datasets[5] : [])
      this.applyOverviewFallbacks()
      this.previewPageNo = 1
      this.selectedPreviewBoxId = 0
      this.revealedSignedBoxId = 0
      this.activeCanvasSlotIdx = 0
      this.slotPdfMap = {}
      this.showRejectBox = false
      this.rejectReason = ""
      this.resetActionForm()
      if (this.canSignCurrentAction) this.jumpToCurrentSignBox()
    },

    buildSignatureFieldNames: function () {
      // Xây dựng tập hợp field name cần bỏ qua khi merge (placeholder chữ ký)
      // Ưu tiên 1: signBoxes.LabelText → đây là nguồn chính xác nhất (###sig_1###, ...)
      // Ưu tiên 2: customFields.FieldType case-insensitive
      var self = this
      var result = {}
      // Bước 1: lấy tên field từ LabelText của signBoxes
      ;(self.signBoxes || []).forEach(function (box) {
        if (box.LabelText) {
          var m = box.LabelText.match(/^###(.+)###$/) || box.LabelText.match(/^\{\{(.+)\}\}$/)
          result[m ? m[1] : box.LabelText] = true
        }
      })
      // Bước 2: lấy từ customFields với FieldType chứa 'signature' (case-insensitive)
      // HOẶC field name đã có trong result từ bước 1 (cross-reference)
      ;(self.customFields || []).forEach(function (f) {
        var ft = String(f.FieldType || '').toLowerCase()
        if (ft === 'signature' || ft === 'sig' || result[f.FieldName]) {
          result[f.FieldName] = true
        }
      })
      return result
    },

    syncSignBoxesFromMergedAnchors: async function () {
      var self = this
      if (!this.overview || !(this.overview.CanCurrentUserSign === true || this.overview.CanCurrentUserSign === 1)) return
      if (!this.signBoxes || !this.signBoxes.length) return

      // [MULTI-TEMPLATE] Merge từng slot riêng, build slotPdfMap, áp anchor per-slot
      if (this.activeTemplates && this.activeTemplates.length) {
        try {
          var fields = []
          var signatureFieldNames = self.buildSignatureFieldNames()
          Object.keys(self.editFieldValues || {}).forEach(function (key) {
            if (signatureFieldNames[key]) return
            var val = self.editFieldValues[key] == null ? '' : String(self.editFieldValues[key])
            fields.push({ Key: key, Value: val })
            fields.push({ Key: '###' + key + '###', Value: val })
            fields.push({ Key: '{{' + key + '}}', Value: val })
          })

          var updatedBoxes = self.signBoxes.slice()
          var slotPdfMap = {}

          for (var si = 0; si < self.activeTemplates.length; si++) {
            var slot = self.activeTemplates[si]
            if (!slot.template) continue
            var slotFileUrl = slot.template.FileUrl || ''
            var slotFileId = self.extractFileIdFromUrl(slotFileUrl)
            if (!slotFileId) continue
            try {
              var slotBinary = await self.tryReadFileBinaryById(slotFileId)
              if (!slotBinary) continue
              var slotFileName = slot.template.FileName || slot.template.TemplateName || 'template.docx'
              var slotRes = await self.econtractRequest('POST', '/api/pdf/merge-docx-template-to-pdf', {
                FileBase64: slotBinary,
                FileName: slotFileName,
                Fields: fields
              }, '')
              var slotAnchors = (slotRes && (slotRes.signatureAnchors || slotRes.SignatureAnchors)) || []
              var slotPdfBase64 = slotRes.PdfBase64 || slotRes.pdfBase64 || slotRes.FileBase64 || slotRes.fileBase64 || ''
              if (slotPdfBase64) slotPdfMap[String(slot.SlotIdx)] = slotPdfBase64
              if (slotAnchors.length) {
                var currentSlotIdx = Number(slot.SlotIdx || 0)
                var slotBoxes = updatedBoxes.filter(function (b) { return Number(b.SlotIdx || 0) === currentSlotIdx })
                var otherBoxes = updatedBoxes.filter(function (b) { return Number(b.SlotIdx || 0) !== currentSlotIdx })
                var mergedSlot = self.applyAnchorsToSignBoxes(slotBoxes, slotAnchors, slotBoxes.length)
                updatedBoxes = otherBoxes.concat(mergedSlot)
              }
            } catch (slotErr) {
              console.warn('[WF] syncSignBoxesFromMergedAnchors: lỗi slot ' + slot.SlotIdx, slotErr)
            }
          }

          self.signBoxes = updatedBoxes
          self.slotPdfMap = slotPdfMap

          // Persist positions
          try {
            var boxesForPersist = updatedBoxes
              .filter(function (b) { return b.InstanceSignBoxID && b.PageNo != null && b.PosX != null && b.PosY != null })
              .map(function (b) { return { InstanceSignBoxID: b.InstanceSignBoxID, PageNo: b.PageNo, PosX: b.PosX, PosY: b.PosY, BoxWidth: b.BoxWidth, BoxHeight: b.BoxHeight } })
            if (boxesForPersist.length) {
              await apiCallAsync('WF_InstanceSignBox_UpdatePositions', { InstanceID: self.instanceId, SignBoxesJSON: JSON.stringify(boxesForPersist) })
            }
          } catch (persistErr) {
            console.warn('[WF] syncSignBoxesFromMergedAnchors: không thể persist positions:', persistErr)
          }

          // Set PDF cho slot đang active
          var activePdf = slotPdfMap[String(self.activeCanvasSlotIdx || 0)] || slotPdfMap['0'] || ''
          if (activePdf) {
            if (self.previewPdfUrl && self.previewPdfUrl.indexOf('blob:') === 0) URL.revokeObjectURL(self.previewPdfUrl)
            self.lastMergedPdfBase64 = activePdf
            self.previewPdfUrl = self.base64ToBlobUrl(activePdf, 'application/pdf')
          }
        } catch (err) {
          console.error('[WF] syncSignBoxesFromMergedAnchors multi-template error:', err)
        }
        return // [MULTI-TEMPLATE] xong, không chạy tiếp single-template
      }

      // [SINGLE-TEMPLATE]
      if (!this.activeTemplateBinary) {
        if (this.activeTemplate) {
          var fileUrl = this.activeTemplate.FileUrl || ''
          var fileId = this.extractFileIdFromUrl(fileUrl)
          if (fileId) {
            try {
              var binary = await this.tryReadFileBinaryById(fileId)
              if (binary) {
                this.activeTemplateBinary = binary
                this.activeTemplateFileName = this.activeTemplate.FileName || this.activeTemplate.TemplateName || 'template.docx'
              }
            } catch (e) { return }
          }
        } else {
          return
        }
      }
      if (!this.activeTemplateBinary) return
      try {
        var fields = []
        var signatureFieldNames = self.buildSignatureFieldNames()
        Object.keys(self.editFieldValues || {}).forEach(function (key) {
          if (signatureFieldNames[key]) return
          var val = self.editFieldValues[key] == null ? '' : String(self.editFieldValues[key])
          fields.push({ Key: key, Value: val })
          fields.push({ Key: '###' + key + '###', Value: val })
          fields.push({ Key: '{{' + key + '}}', Value: val })
        })
        var res = await self.econtractRequest('POST', '/api/pdf/merge-docx-template-to-pdf', {
          FileBase64: self.activeTemplateBinary,
          FileName: self.activeTemplateFileName || 'template.docx',
          Fields: fields
        }, '')
        var anchors = (res && (res.signatureAnchors || res.SignatureAnchors)) || []
        if (anchors.length) {
          self.signBoxes = self.applyAnchorsToSignBoxes(self.signBoxes, anchors, self.signBoxes.length)
          try {
            var signBoxesForPersist = (self.signBoxes || [])
              .filter(function (b) { return b.InstanceSignBoxID && b.PageNo != null && b.PosX != null && b.PosY != null })
              .map(function (b) { return { InstanceSignBoxID: b.InstanceSignBoxID, PageNo: b.PageNo, PosX: b.PosX, PosY: b.PosY, BoxWidth: b.BoxWidth, BoxHeight: b.BoxHeight } })
            if (signBoxesForPersist.length) {
              await apiCallAsync('WF_InstanceSignBox_UpdatePositions', { InstanceID: self.instanceId, SignBoxesJSON: JSON.stringify(signBoxesForPersist) })
            }
          } catch (persistErr) {
            console.warn('[WF] syncSignBoxesFromMergedAnchors: Không thể persist vị trí signBoxes:', persistErr)
          }
        }
        var pdfBase64 = res.PdfBase64 || res.pdfBase64 || res.FileBase64 || res.fileBase64 || ''
        if (pdfBase64) {
          if (self.previewPdfUrl && self.previewPdfUrl.indexOf('blob:') === 0) URL.revokeObjectURL(self.previewPdfUrl)
          self.lastMergedPdfBase64 = pdfBase64
          self.previewPdfUrl = self.base64ToBlobUrl(pdfBase64, 'application/pdf')
        }
      } catch (err) {
        console.error('[WF] syncSignBoxesFromMergedAnchors error:', err)
      }
    },

    normalizeOverview: function (row) {
      if (!row) return {}
      return {
        InstanceID: row.InstanceID,
        InstanceName: row.InstanceName || "",
        CreateMode: row.CreateMode || "TEMPLATE_FLOW",
        DefinitionID: row.DefinitionID,
        DefinitionCode: row.DefinitionCode || "",
        DefinitionName: row.DefinitionName || "",
        DefinitionDescription: row.DefinitionDescription || "",
        DefinitionVersion: row.DefinitionVersion || 1,
        CategoryID: row.CategoryID,
        CategoryCode: row.CategoryCode || "",
        CategoryName: row.CategoryName || "",
        ReferenceCode: row.ReferenceCode || "",
        Description: row.Description || "",
        ExecutionEngine: row.ExecutionEngine || "",
        ContractProvider: row.ContractProvider || "",
        SourceFileID: row.SourceFileID || null,
        SourceFileName: row.SourceFileName || "",
        Status: row.Status || "",
        CurrentStepOrder: row.CurrentStepOrder || 0,
        CurrentExecutionID: row.CurrentExecutionID || 0,
        CurrentStepDefID: row.CurrentStepDefID || 0,
        CurrentStepCode: row.CurrentStepCode || "",
        CurrentStepName: row.CurrentStepName || "",
        CurrentStepType: row.CurrentStepType || "",
        CurrentSignSystem: row.CurrentSignSystem || "",
        CurrentTemplateID: row.CurrentTemplateID || null,
        CurrentTemplateName: row.CurrentTemplateName || "",
        CurrentTemplateFileUrl: row.CurrentTemplateFileUrl || "",
        CurrentDocumentFileUrl: row.CurrentDocumentFileUrl || "",
        CurrentDocumentFileID: row.CurrentDocumentFileID || null,
        CurrentDocumentFileName: row.CurrentDocumentFileName || "",
        ExternalContractID: row.ExternalContractID || 0,
        ExternalContractStatusCode: row.ExternalContractStatusCode || "",
        ExternalContractStatusText: row.ExternalContractStatusText || "",
        ExternalSignStatusCode: row.ExternalSignStatusCode || "",
        ExternalSignStatusText: row.ExternalSignStatusText || "",
        ExternalDocumentUrl: row.ExternalDocumentUrl || "",
        ExternalDocumentName: row.ExternalDocumentName || "",
        ExternalLastSyncTime: row.ExternalLastSyncTime || "",
        CurrentSignerExecID: row.CurrentSignerExecID || 0,
        CurrentSignerPersonID: row.CurrentSignerPersonID || "",
        CurrentSignerPersonName: row.CurrentSignerPersonName || "",
        CurrentSignerMethod: row.CurrentSignerMethod || "",
        CanCurrentUserSign: row.CanCurrentUserSign === true || row.CanCurrentUserSign === 1,
        CanCurrentUserReject: row.CanCurrentUserReject === true || row.CanCurrentUserReject === 1,
        CanCurrentUserAct: row.CanCurrentUserAct === true || row.CanCurrentUserAct === 1,
        NextSigner: row.NextSigner || "",
        TotalSteps: row.TotalSteps || 0,
        CreateUser: row.CreateUser || "",
        CreateTime: row.CreateTime || "",
        UpdateUser: row.UpdateUser || "",
        UpdateTime: row.UpdateTime || "",
        RequireManualSendSign: row.RequireManualSendSign === true || row.RequireManualSendSign === 1,
        IsSentForSigning: row.IsSentForSigning === true || row.IsSentForSigning === 1
      }
    },

    normalizeSteps: function (rows) {
      return (rows || []).map(function (row) {
        return {
          ExecutionID: row.ExecutionID,
          StepDefID: row.StepDefID,
          StepOrder: row.StepOrder,
          StepCode: row.StepCode || "",
          StepName: row.StepName || "",
          StepType: row.StepType || "",
          SignSystem: row.SignSystem || "",
          TemplateID: row.TemplateID || null,
          TemplateName: row.TemplateName || "",
          Status: row.Status || "",
          DocumentFileUrl: row.DocumentFileUrl || "",
          DocumentFileID: row.DocumentFileID || null,
          DocumentFileName: row.DocumentFileName || "",
          StartedDate: row.StartedDate || "",
          CompletedDate: row.CompletedDate || "",
          RejectedDate: row.RejectedDate || "",
          TotalSignerCount: row.TotalSignerCount || 0,
          SignedCount: row.SignedCount || 0,
          WaitingCount: row.WaitingCount || 0,
          PendingCount: row.PendingCount || 0,
          CurrentUserCanAct: row.CurrentUserCanAct === true || row.CurrentUserCanAct === 1
        }
      })
    },

    normalizeSigners: function (rows) {
      return (rows || []).map(function (row) {
        return {
          SignerExecID: row.SignerExecID,
          ExecutionID: row.ExecutionID,
          StepOrder: row.StepOrder,
          StepName: row.StepName || "",
          StepType: row.StepType || "",
          SignerOrder: row.SignerOrder || 0,
          ResolvedPersonID: row.ResolvedPersonID || "",
          ResolvedPersonName: row.ResolvedPersonName || "",
          SignMethod: row.SignMethod || "",
          Status: row.Status || "",
          SignedDate: row.SignedDate || "",
          SignCertInfo: row.SignCertInfo || "",
          IsCurrentUser: row.IsCurrentUser === true || row.IsCurrentUser === 1,
          SignerValue: row.SignerValue || "",
          SignerType: row.SignerType || "",
          RoleCode: row.RoleCode || "",
          RoleName: row.RoleName || ""
        }
      })
    },

    normalizeFields: function (rows) {
      return (rows || []).map(function (row) {
        return {
          InstanceDataID: row.InstanceDataID,
          FieldName: row.FieldName || "",
          FieldLabel: row.FieldLabel || "",
          FieldType: row.FieldType || "",
          FieldOptions: row.FieldOptions || null,
          FieldValue: row.FieldValue || "",
          UpdatedAtStep: row.UpdatedAtStep || null
        }
      })
    },

    normalizeLogs: function (rows) {
      var list = (rows || []).map(function (row) {
        return {
          LogID: row.LogID,
          InstanceID: row.InstanceID,
          StepOrder: row.StepOrder || null,
          ActionCode: row.ActionCode || "",
          ActionDetail: row.ActionDetail || "",
          UserID: row.UserID || "",
          UserFullName: row.UserFullName || "",
          CreateTime: row.CreateTime || ""
        }
      })
      list.sort(function (a, b) {
        var tA = a.CreateTime ? new Date(a.CreateTime).getTime() : 0
        var tB = b.CreateTime ? new Date(b.CreateTime).getTime() : 0
        if (tA !== tB) return tA - tB
        return Number(a.LogID || 0) - Number(b.LogID || 0)
      })
      return list
    },

    getStepNameByOrder: function (stepOrder) {
      if (!stepOrder) {
        if (this.theChiTiet && this.theChiTiet.CurrentStepName) {
          return this.theChiTiet.CurrentStepName
        }
        return 'Chưa xác định'
      }
      var orderNum = Number(stepOrder)
      var found = (this.dsCot || []).find(function (c) { return Number(c.order) === orderNum })
      if (found) {
        return found.tenCot.replace(/^\d+\.\s*/, '')
      }
      return 'Giai đoạn ' + orderNum
    },

    getLogChipText: function (actionCode) {
      var code = String(actionCode || '').toUpperCase()
      if (code === 'INSTANCE_CREATED' || code === 'CREATE_INSTANCE') return 'Tạo mới'
      if (code === 'STAGE_CHANGED' || code === 'MOVE_STEP' || code === 'STEP_DONE' || code === 'STEP_ACTIVE') return 'Giai đoạn'
      if (code === 'UPDATE_TAG' || code === 'TAG_CHANGED' || code === 'SAVE_TAGS') return 'Nhãn'
      if (code === 'SIGNED' || code === 'SIGNED_FILE_UPLOADED' || code === 'SEND_FOR_SIGNING' || code === 'CANCEL_SIGNING' || code === 'INSTANCE_COMPLETED') return 'Ký số'
      return 'Hệ thống'
    },

    getLogChipColor: function (actionCode) {
      var code = String(actionCode || '').toUpperCase()
      if (code === 'INSTANCE_CREATED' || code === 'CREATE_INSTANCE') return 'blue'
      if (code === 'STAGE_CHANGED' || code === 'MOVE_STEP' || code === 'STEP_DONE' || code === 'STEP_ACTIVE') return 'indigo'
      if (code === 'UPDATE_TAG' || code === 'TAG_CHANGED' || code === 'SAVE_TAGS') return 'teal'
      if (code === 'SIGNED' || code === 'SIGNED_FILE_UPLOADED' || code === 'SEND_FOR_SIGNING' || code === 'CANCEL_SIGNING' || code === 'INSTANCE_COMPLETED') return 'warning'
      return 'grey'
    },

    getLogIcon: function (actionCode) {
      var code = String(actionCode || '').toUpperCase()
      if (code === 'INSTANCE_CREATED' || code === 'CREATE_INSTANCE') return 'mdi-plus-circle'
      if (code === 'STAGE_CHANGED' || code === 'MOVE_STEP' || code === 'STEP_DONE' || code === 'STEP_ACTIVE') return 'mdi-arrow-right-bold-circle-outline'
      if (code === 'UPDATE_TAG' || code === 'TAG_CHANGED' || code === 'SAVE_TAGS') return 'mdi-tag-outline'
      if (code === 'SIGNED' || code === 'SIGNED_FILE_UPLOADED') return 'mdi-check-decagram-outline'
      if (code === 'SEND_FOR_SIGNING') return 'mdi-send-circle-outline'
      if (code === 'CANCEL_SIGNING') return 'mdi-close-circle-outline'
      if (code === 'INSTANCE_COMPLETED') return 'mdi-flag-checkered'
      return 'mdi-circle-medium'
    },

    getLogStatusColor: function (actionCode) {
      var code = String(actionCode || '').toUpperCase()
      if (code === 'SIGNED' || code === 'INSTANCE_COMPLETED' || code === 'STEP_DONE') return '#28a745'
      if (code === 'CANCELLED' || code === 'CANCEL_SIGNING' || code === 'REJECTED') return '#dc3545'
      return '#2196f3'
    },

    getLogDescription: function (log) {
      var code = String(log.ActionCode || '').toUpperCase()
      var userText = log.UserID ? (log.UserID + (log.UserFullName ? ' - ' + log.UserFullName : '')) : 'Hệ thống'
      
      if (code === 'INSTANCE_CREATED') {
        var desc = 'đã tạo nhiệm vụ.'
        try {
          var parsed = JSON.parse(log.ActionDetail)
          if (parsed && parsed.Description) {
            desc = 'đã tạo nhiệm vụ "' + parsed.Description + '".'
          }
        } catch (e) {}
        return userText + ' ' + desc
      }

      if (code === 'CANCELLED') {
        return userText + ' đã hủy luồng công việc.'
      }
      if (code === 'STEP_DONE') {
        return userText + ' đã báo hoàn thành xử lý bước.'
      }
      if (code === 'STEP_ACTIVE') {
        return userText + ' đã thu hồi trạng thái hoàn thành bước.'
      }
      if (code === 'SEND_FOR_SIGNING') {
        return userText + ' đã gửi hồ sơ đi ký số.'
      }
      if (code === 'CANCEL_SIGNING') {
        return userText + ' đã hủy gửi ký số.'
      }
      if (code === 'SIGNED') {
        return userText + ' đã hoàn tất lượt ký số.'
      }
      if (code === 'SIGNED_FILE_UPLOADED') {
        return 'Hệ thống đã tự động lưu file PDF sau khi ký số.'
      }
      if (code === 'INSTANCE_COMPLETED') {
        return userText + ' đã hoàn tất toàn bộ yêu cầu ký.'
      }

      if (log.ActionDetail && log.ActionDetail.indexOf('{') !== 0) {
        var detailTrim = String(log.ActionDetail).trim()
        if (log.UserID && detailTrim.indexOf(log.UserID) === 0) {
          return log.ActionDetail
        }
        if (/^NV\d+/i.test(detailTrim)) {
          return log.ActionDetail
        }
        if (detailTrim.indexOf(userText) === 0) {
          return log.ActionDetail
        }
        return userText + ' ' + log.ActionDetail
      }


      return userText + ' đã thực hiện thao tác ' + log.ActionCode + '.'
    },


    parseJsonSafe: function (value) {
      var raw = String(value || "").trim()
      if (!raw) return null
      try {
        return JSON.parse(raw)
      } catch (e) {
        return null
      }
    },

    extractCreatedLogConfig: function () {
      var rows = this.logs || []
      var i = 0
      var row = null
      var parsed = null
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i] || {}
        if (String(row.ActionCode || "").toUpperCase() !== "INSTANCE_CREATED") continue
        parsed = this.parseJsonSafe(row.ActionDetail || "")
        if (parsed && typeof parsed === "object") return parsed
      }
      return null
    },

    applyOverviewFallbacks: function () {
      var boxRows = this.signBoxes || []
      var created = this.extractCreatedLogConfig() || {}
      var firstBox = boxRows.length ? (boxRows[0] || {}) : {}
      var hopDongId = 0
      if (!this.overview || typeof this.overview !== "object") this.overview = {}

      if (!this.overview.ExecutionEngine) {
        this.overview.ExecutionEngine = firstBox.ExecutionEngine || created.ExecutionEngine || ""
      }
      if (!this.overview.ContractProvider) {
        this.overview.ContractProvider = firstBox.ContractProvider || created.ContractProvider || ""
      }
      hopDongId = Number(this.overview.ExternalContractID || 0)
      if (!(hopDongId > 0)) {
        hopDongId = this.extractEcontractTaggedId(created.Description || "")
      }
      if (!(hopDongId > 0)) {
        hopDongId = this.extractEcontractTaggedId(created.ReferenceCode || "")
      }
      if (!(hopDongId > 0)) {
        hopDongId = this.extractEcontractTaggedId(this.overview.Description || "")
      }
      if (!(hopDongId > 0)) {
        hopDongId = this.extractEcontractTaggedId(this.overview.ReferenceCode || "")
      }
      if (hopDongId > 0 && !(Number(this.overview.ExternalContractID || 0) > 0)) {
        this.overview.ExternalContractID = hopDongId
      }
    },

    normalizeSignBoxes: function (rows) {
      return (rows || []).map(function (row) {
        return {
          InstanceSignBoxID: row.InstanceSignBoxID,
          SignerExecID: row.SignerExecID || 0,
          BoxOrder: row.BoxOrder || 0,
          PageNo: row.PageNo || 1,
          PosX: row.PosX || 0,
          PosY: row.PosY || 0,
          BoxWidth: row.BoxWidth || 0,
          BoxHeight: row.BoxHeight || 0,
          StepOrder: row.StepOrder || 0,
          SignerOrder: row.SignerOrder || 0,
          SignerType: row.SignerType || "ROLE",
          SignerValue: row.SignerValue || "",
          PersonName: row.PersonName || "",
          DepartmentName: row.DepartmentName || "",
          SignMethod: row.SignMethod || "",
          ExecutionEngine: row.ExecutionEngine || "",
          ContractProvider: row.ContractProvider || "",
          LabelText: row.LabelText || "",
          Status: row.Status || "",
          SlotIdx: row.TemplateSlotIdx != null ? Number(row.TemplateSlotIdx) : 0
        }
      })
    },

    resetActionForm: function () {
      this.actionForm = {
        signCertInfo: "",
        providerTransactionCode: "",
        providerNote: "",
        otpCode: ""
      }
    },

    isSignedRuntimeStatus: function (value) {
      var status = String(value || "").trim().toUpperCase()
      return status === "SIGNED"
        || status === "DONE"
        || status === "COMPLETED"
        || status === "APPROVED"
        || status === "PASSED"
        || status === "FINISHED"
        || status === "SUCCESS"
        || status === "SIGNED_SUCCESS"
        || status === "HOAN_TAT"
    },

    resolveSignBoxRuntimeStatus: function (box) {
      var boxStatus = String(box && box.Status || "").trim()
      var signerExecId = Number(box && box.SignerExecID || 0)
      var stepOrder = Number(box && box.StepOrder || 0)
      var signerOrder = Number(box && box.SignerOrder || 0)
      var signers = this.signers || []
      var i = 0
      var row = null
      if (signerExecId > 0) {
        for (i = 0; i < signers.length; i += 1) {
          row = signers[i] || {}
          if (Number(row.SignerExecID || 0) !== signerExecId) continue
          if (row.Status) return String(row.Status || "")
        }
      }
      for (i = 0; i < signers.length; i += 1) {
        row = signers[i] || {}
        if (stepOrder && Number(row.StepOrder || 0) !== stepOrder) continue
        if (signerOrder && Number(row.SignerOrder || 0) !== signerOrder) continue
        if (row.Status) return String(row.Status || "")
      }
      if (boxStatus) return boxStatus
      return ""
    },

    normalizeOtpCode: function (value) {
      return String(value || "").trim()
    },

    isOtpCodeValid: function (value) {
      var raw = this.normalizeOtpCode(value)
      if (!raw) return false
      return /^[0-9A-Za-z]{4,12}$/.test(raw)
    },

    buildActionDetail: function () {
      var parts = [this.actionPrimaryText + " từ wf-kanban-flow-detail"]
      var otpCode = this.normalizeOtpCode(this.actionForm.otpCode)
      if (this.actionForm.providerTransactionCode) parts.push("ProviderRef=" + this.actionForm.providerTransactionCode)
      if (otpCode) parts.push("OtpRef=" + this.maskOtpCode(otpCode))
      if (this.actionForm.providerNote) parts.push("Note=" + this.actionForm.providerNote)
      return parts.join(" | ")
    },

    maskOtpCode: function (value) {
      var raw = this.normalizeOtpCode(value)
      if (!raw) return ""
      if (raw.length <= 2) return "****"
      return "****" + raw.slice(-2)
    },

    normalizeRejectReason: function (value) {
      return String(value || "").trim()
    },

    sanitizeReasonForOtp: function (reason, otpCode) {
      var safeReason = String(reason || "")
      var rawOtp = this.normalizeOtpCode(otpCode)
      var escapedOtp = ""
      if (!safeReason || !rawOtp || !this.isOtpCodeValid(rawOtp)) return safeReason
      escapedOtp = rawOtp.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
      return safeReason.replace(new RegExp(escapedOtp, "g"), this.maskOtpCode(rawOtp))
    },

    resolveSignCertInfoPayload: function () {
      if (this.currentActionMode === "SMARTCA" && this.approvedSignerCertInfo) {
        return this.approvedSignerCertInfo
      }
      if (this.currentActionMode === "SMARTCA" && this.mySignerProfile && this.mySignerProfile.CertSerial) {
        return String(this.mySignerProfile.CertSerial || "").trim()
      }
      if (this.currentActionMode === "ECONTRACT") {
        return this.actionForm.providerTransactionCode || ""
      }
      return this.actionForm.signCertInfo || this.actionForm.providerTransactionCode || ""
    },

    resolvePdfPageSizeForSignBox: async function (box) {
      var pageNo = this.toSafeInt(box && box.PageNo || 1, 1)
      var canvasRef = this.$refs && this.$refs.signCanvasRef ? this.$refs.signCanvasRef : null
      if (!canvasRef || typeof canvasRef.getPdfPageSize !== "function") return null
      try {
        return await canvasRef.getPdfPageSize(pageNo)
      } catch (e) {
        return null
      }
    },

    buildSmartcaLocationSign: async function (box) {
      var x = Number(box && box.PosX || 0)
      var y = Number(box && box.PosY || 0)
      var w = Number(box && box.BoxWidth || 0)
      var h = Number(box && box.BoxHeight || 0)
      var pageSize = await this.resolvePdfPageSizeForSignBox(box)
      var pageWidth = Number(pageSize && pageSize.width || 0)
      var pageHeight = Number(pageSize && pageSize.height || 0)
      var isPercentBox = x >= 0 && y >= 0 && w > 0 && h > 0 && x <= 100 && y <= 100 && w <= 100 && h <= 100
      var left = 0
      var right = 0
      var bottom = 0
      var top = 0

      if (isPercentBox && pageWidth > 0 && pageHeight > 0) {
        var leftAbs = (x / 100) * pageWidth
        var widthAbs = (w / 100) * pageWidth
        var topAbsFromTop = (y / 100) * pageHeight
        var heightAbs = (h / 100) * pageHeight
        var bottomAbs = pageHeight - (topAbsFromTop + heightAbs)
        left = Math.round(Math.max(0, leftAbs))
        right = Math.round(Math.max(left + 1, leftAbs + widthAbs))
        bottom = Math.round(Math.max(0, bottomAbs))
        top = Math.round(Math.max(bottom + 1, bottomAbs + heightAbs))
      } else {
        left = Math.round(Math.max(0, x))
        bottom = Math.round(Math.max(0, y))
        right = Math.round(Math.max(left + 1, x + w))
        top = Math.round(Math.max(bottom + 1, y + h))
      }

      if (pageWidth > 0 && pageHeight > 0) {
        if (left > pageWidth - 1) left = Math.max(0, Math.round(pageWidth - 1))
        if (right > pageWidth) right = Math.max(left + 1, Math.round(pageWidth))
        if (bottom > pageHeight - 1) bottom = Math.max(0, Math.round(pageHeight - 1))
        if (top > pageHeight) top = Math.max(bottom + 1, Math.round(pageHeight))
      }

      return String(left) + "," + String(bottom) + "," + String(right) + "," + String(top)
    },

    buildSmartcaLocationSignLegacy: function (box) {
      var x = Number(box && box.PosX || 0)
      var y = Number(box && box.PosY || 0)
      var w = Number(box && (box.BoxWidth != null ? box.BoxWidth : box.Width) || 0)
      var h = Number(box && (box.BoxHeight != null ? box.BoxHeight : box.Height) || 0)
      return x + "," + y + "," + w + "," + h
    },

    normalizeBase64Content: function (raw) {
      var value = String(raw || "").trim()
      if (!value) return ""
      if (value.indexOf("base64,") >= 0) value = value.split("base64,").pop() || ""
      value = value.replace(/\s+/g, "")
      return value
    },

    convertBlobToBase64: function (blob) {
      return new Promise(function (resolve) {
        var reader = null
        if (typeof FileReader === "undefined") {
          resolve("")
          return
        }
        reader = new FileReader()
        reader.onloadend = function () {
          var dataUrl = String(reader.result || "")
          if (dataUrl.indexOf("base64,") < 0) {
            resolve("")
            return
          }
          resolve(dataUrl.split("base64,").pop() || "")
        }
        reader.onerror = function () {
          resolve("")
        }
        reader.readAsDataURL(blob)
      })
    },

    fetchFileBase64FromPublicUrl: async function (fileId) {
      var normalized = String(fileId || "").trim()
      var response = null
      var blob = null
      if (!normalized || typeof fetch === "undefined") return ""
      try {
        response = await fetch("https://file.zentea.vn/iotdev/FileData/" + normalized, {
          method: "GET",
          credentials: "omit"
        })
        if (!response || !response.ok) return ""
        blob = await response.blob()
        if (!blob || !blob.size) return ""
        return await this.convertBlobToBase64(blob)
      } catch (e) {
        return ""
      }
    },

    toSafeInt: function (value, fallback) {
      var n = Number(value)
      if (!Number.isFinite(n)) return Number(fallback || 0)
      return Math.trunc(n)
    },

    signRequest: async function () {
      var datasets
      var detail
      var otpCode = this.normalizeOtpCode(this.actionForm.otpCode)
      var signCertInfo = this.resolveSignCertInfoPayload()
      var pendingSignedFileId = ""
      var pendingSignedFileName = ""
      if (this.isActing || this.isSmartcaCalling || this.smartcaActionLock) return
      if (!this.canSignCurrentAction) {
        if (showToast && showToast.error) showToast.error("Không tìm thấy lượt ký hợp lệ của bạn để thực hiện thao tác.")
        return
      }
      if (this.currentActionMode === "SMARTCA" && !this.approvedSignerCertInfo) {
        if (!(this.mySignerProfile && this.mySignerProfile.CertSerial)) {
          if (showToast && showToast.error) showToast.error("Chưa có metadata chứng thư đã duyệt và cũng không có chứng thư active trong hồ sơ người ký.")
          return
        }
      }
      if (this.currentActionMode === "SMARTCA" && this.mySignerProfile && this.mySignerProfile.CertSerial) {
        if (!/^[0-9A-Za-z]{6,64}$/.test(String(this.mySignerProfile.CertSerial || "").trim())) {
          if (showToast && showToast.error) showToast.error("Serial chứng thư trong hồ sơ người ký không hợp lệ (6-64 ký tự chữ/số).")
          return
        }
      }
      if (this.currentActionMode === "SMARTCA") {
        this.smartcaActionLock = true
        this.jumpToCurrentSignBox()
        this.showSmartcaGuideDialog = true
        try {
          var smartcaResponse = await this.callSmartCAInternalSign()
          var signedFileId = smartcaResponse && (
            smartcaResponse.FileID || smartcaResponse.fileId ||
            smartcaResponse.FILE_ID || smartcaResponse.FileId ||
            smartcaResponse.SignedFileID || smartcaResponse.signedFileId
          )
          if (signedFileId && String(signedFileId).indexOf("merged") >= 0) {
            signedFileId = ""
          }
          var signedBase64 = smartcaResponse && (
            smartcaResponse.DocFileSigned || smartcaResponse.docFileSigned ||
            smartcaResponse.FileSigned || smartcaResponse.fileSigned ||
            smartcaResponse.SignedFile || smartcaResponse.signedFile
          )
          if (!signedFileId && signedBase64) {
            var normalizedBase64 = this.normalizeBase64Content ? this.normalizeBase64Content(signedBase64) : signedBase64
            try {
              var uploadRes = await apiCallAsync("UPLOAD_FileData_Base64", {
                FileBase64: normalizedBase64,
                FileName: "WF-" + this.instanceId + "-signed.pdf",
                FileContentType: "application/pdf"
              })
              var row = uploadRes && uploadRes[0] ? uploadRes[0] : null
              if (!row && uploadRes && uploadRes.data && uploadRes.data[0]) {
                row = uploadRes.data[0][0] || uploadRes.data[0]
              }
              if (row && row.FileID) {
                signedFileId = row.FileID
              }
            } catch (uploadErr) {
              console.error("Lỗi upload file sau khi ký SmartCA:", uploadErr)
            }
          }
          if (signedFileId) {
            pendingSignedFileId = String(signedFileId).trim()
            pendingSignedFileName = "WF-" + this.instanceId + "-signed.pdf"
            this.overview.CurrentDocumentFileUrl = "https://file.zentea.vn/iotdev/FileData/" + pendingSignedFileId
            this.overview.CurrentDocumentFileID = pendingSignedFileId
            if (signedBase64) {
              var normalized = this.normalizeBase64Content ? this.normalizeBase64Content(signedBase64) : signedBase64
              this.lastMergedPdfBase64 = normalized
              if (this.mergedPdfUrl && this.mergedPdfUrl.indexOf("blob:") === 0) {
                URL.revokeObjectURL(this.mergedPdfUrl)
              }
              this.mergedPdfUrl = this.base64ToBlobUrl(normalized, "application/pdf")
            }
          } else {
            if (signedBase64) {
              var normalized = this.normalizeBase64Content ? this.normalizeBase64Content(signedBase64) : signedBase64
              this.lastMergedPdfBase64 = normalized
              if (this.mergedPdfUrl && this.mergedPdfUrl.indexOf("blob:") === 0) {
                URL.revokeObjectURL(this.mergedPdfUrl)
              }
              this.mergedPdfUrl = this.base64ToBlobUrl(normalized, "application/pdf")
            }
          }
        } catch (smartErr) {
          this.showError(smartErr, "Gọi SmartCA nội bộ thất bại.")
          return
        } finally {
          this.isSmartcaCalling = false
          this.showSmartcaGuideDialog = false
          this.smartcaActionLock = false
        }
      }
      if (this.currentActionMode === "SMARTCA" && !this.approvedSignerCertInfo && this.mySignerProfile && this.mySignerProfile.CertSerial) {
        signCertInfo = String(this.mySignerProfile.CertSerial || "").trim()
      }
      if (this.currentActionMode === "SMARTCA" && !this.isApprovedSignerCertInfoValid && !(this.mySignerProfile && this.mySignerProfile.CertSerial)) {
        if (showToast && showToast.error) showToast.error("Metadata chứng thư đã duyệt không hợp lệ và không có fallback từ hồ sơ signer.")
        return
      }
      if (this.currentActionMode === "SMARTCA" && this.approvedSignerCertInfo && !this.isApprovedSignerCertInfoValid) {
        if (showToast && showToast.error) showToast.error("Metadata chứng thư đã duyệt không hợp lệ. Vui lòng liên hệ quản trị để đồng bộ lại.")
        return
      }
      if (this.currentActionMode === "OTP" && !this.isOtpCodeValid(otpCode)) {
        if (showToast && showToast.error) showToast.error("Bước OTP yêu cầu mã xác thực 4-12 ký tự chữ/số.")
        return
      }
      detail = this.buildActionDetail()
      this.isActing = true
      try {
        datasets = await apiCallAsync("WF_Request_SignComplete", {
          InstanceID: this.instanceId,
          SignerExecID: this.overview.CurrentSignerExecID || 0,
          ActionDetail: detail,
          SignCertInfo: signCertInfo,
          OtpCode: otpCode,
          SignedFileID: pendingSignedFileId || "",
          SignedFileName: pendingSignedFileName || ""
        })
        this.applyDetailData(datasets)
        await this.loadData(true)
        if (showToast && showToast.success) showToast.success(this.actionPrimaryText + " thành công.")
      } catch (err) {
        this.showError(err, "Không thể xử lý thao tác hiện tại.")
      } finally {
        this.isActing = false
      }
    },

    resolveSmartcaOptionSign: function () {
      var value = this.mySignerProfile && this.mySignerProfile.SmartCAOptionSign != null
        ? String(this.mySignerProfile.SmartCAOptionSign).trim()
        : ""
      if (value === "0" || value === "1") return value
      return "1"
    },

    rejectRequest: async function () {
      var datasets
      var reason = this.normalizeRejectReason(this.rejectReason)
      var otpCode = this.normalizeOtpCode(this.actionForm.otpCode)
      if (!this.canRejectCurrentAction) {
        if (showToast && showToast.error) showToast.error("Không tìm thấy lượt từ chối hợp lệ của bạn để thực hiện thao tác.")
        return
      }
      if (!reason) {
        if (showToast && showToast.error) showToast.error("Vui lòng nhập lý do từ chối.")
        return
      }
      if (this.currentActionMode === "OTP" && !this.isOtpCodeValid(otpCode)) {
        if (showToast && showToast.error) showToast.error("Bước OTP yêu cầu mã xác thực 4-12 ký tự chữ/số.")
        return
      }
      reason = this.sanitizeReasonForOtp(reason, otpCode)
      if (this.actionForm.providerNote) reason = reason + " | " + this.actionForm.providerNote
      this.isActing = true
      try {
        datasets = await apiCallAsync("WF_Request_Reject", {
          InstanceID: this.instanceId,
          SignerExecID: this.overview.CurrentSignerExecID || 0,
          RejectReason: reason,
          OtpCode: otpCode
        })
        this.applyDetailData(datasets)
        await this.loadData(true)
        if (showToast && showToast.success) showToast.success("Đã từ chối yêu cầu ký.")
      } catch (err) {
        this.showError(err, "Không thể từ chối yêu cầu ký.")
      } finally {
        this.isActing = false
      }
    },

    cancelReject: function () {
      this.showRejectBox = false
      this.rejectReason = ""
      this.actionForm.providerNote = ""
    },

    previewDocument: function () {
      if (this.overview.CurrentDocumentFileUrl) {
        window.open(this.overview.CurrentDocumentFileUrl, "_blank")
        return
      }
      if (this.documentViewUrl) {
        window.open(this.documentViewUrl, "_blank")
        return
      }
      if (showAlert) {
        showAlert("Xem file", "Chưa có file runtime.")
      }
    },

    downloadSignedExternalDocument: async function () {
      try {
        if (this.resolveOverviewContractProvider() !== "AMIS_WESIGN") return
        await this.loadWeSignSignedDocument(false)
        if (showToast && showToast.success) showToast.success("Đã tải file đã ký từ " + this.currentExternalProviderText + ".")
      } catch (err) {
        this.showError(err, "Không tải được file đã ký.")
      }
    },

    onCanvasActivePageChange: function (pageNo) {
      this.previewPageNo = Number(pageNo || 1) || 1
    },

    onCanvasSelectBox: function (box) {
      this.selectedPreviewBoxId = Number(box && box.InstanceSignBoxID ? box.InstanceSignBoxID : 0)
      this.previewPageNo = Number(box && box.PageNo ? box.PageNo : this.previewPageNo || 1) || 1
    },

    jumpToSignBox: function (box) {
      var pageNo = Number(box && box.PageNo ? box.PageNo : 1) || 1
      var boxId = Number(box && box.InstanceSignBoxID ? box.InstanceSignBoxID : 0)
      var isSigned = this.isSignedRuntimeStatus(this.resolveSignBoxRuntimeStatus(box))
      this.previewPageNo = pageNo
      this.selectedPreviewBoxId = boxId
      this.revealedSignedBoxId = isSigned ? boxId : 0
      this.$nextTick(function () {
        var canvas = this.$refs.signCanvasRef
        if (canvas && typeof canvas.focusBoxById === "function") {
          canvas.focusBoxById(boxId, pageNo)
          return
        }
        if (canvas && typeof canvas.scrollToPage === "function") {
          canvas.scrollToPage(pageNo, true)
        }
      })
    },

    jumpToCurrentSignBox: function () {
      var box = this.resolveCurrentSignBox()
      if (!box) return
      this.jumpToSignBox(box)
    },

    base64ToBlob: function (base64, mime) {
      var bytes = atob(base64)
      var len = bytes.length
      var arr = new Uint8Array(len)
      var i = 0
      for (i = 0; i < len; i += 1) arr[i] = bytes.charCodeAt(i)
      return new Blob([arr], { type: mime || "application/octet-stream" })
    },

    triggerBlobDownload: function (blob, fileName) {
      var url = ""
      var link = null
      if (!blob || typeof window === "undefined" || !window.URL || typeof document === "undefined" || !document.createElement) return
      url = window.URL.createObjectURL(blob)
      link = document.createElement("a")
      link.href = url
      link.download = fileName || "signed-document.pdf"
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.setTimeout(function () {
        window.URL.revokeObjectURL(url)
      }, 1000)
    },

    formatStatusText: function (value) {
      var map = {
        RUNNING: "Đang chạy",
        WAITING_ME: "Chờ tôi ký",
        COMPLETED: "Hoàn tất",
        CANCELLED: "Đã hủy",
        REJECTED: "Từ chối"
      }
      return map[value] || value || "-"
    },

    formatMethod: function (value) {
      var map = {
        smartca: "VNPT SmartCA",
        econtract: "VNPT eContract",
        otp_email: "OTP Email",
        otp_sms: "OTP SMS",
        image: "Ký ảnh"
      }
      return map[value] || value || "-"
    },

    formatEngine: function (value) {
      var engine = String(value || "").toUpperCase()
      if (engine === "ECONTRACT") return "eContract"
      if (engine === "SMARTCA") return "SmartCA nội bộ"
      return value || "-"
    },

    formatProvider: function (value, engine) {
      var provider = String(value || "").toUpperCase()
      var normalizedEngine = String(engine || "").toUpperCase()
      if (normalizedEngine !== "ECONTRACT") return "-"
      if (provider === "VNPT_ECONTRACT") return "VNPT eContract"
      if (provider === "AMIS_WESIGN") return "AMIS WeSign"
      return provider || "Chưa chọn"
    },

    resolveOverviewExecutionEngine: function () {
      var engine = String(this.overview.ExecutionEngine || "").toUpperCase()
      var rows = this.signBoxes || []
      var i = 0
      if (engine) return engine
      for (i = 0; i < rows.length; i += 1) {
        engine = String(rows[i] && rows[i].ExecutionEngine || "").toUpperCase()
        if (engine) return engine
      }
      return ""
    },

    resolveOverviewContractProvider: function () {
      var provider = String(this.overview.ContractProvider || "").toUpperCase()
      var rows = this.signBoxes || []
      var i = 0
      if (provider) return provider
      for (i = 0; i < rows.length; i += 1) {
        provider = String(rows[i] && rows[i].ContractProvider || "").toUpperCase()
        if (provider) return provider
      }
      return ""
    },

    resolveBestRuntimeDocument: function () {
      var rows = this.steps || []
      var i = 0
      var row = null
      var top = null
      var rank = 0
      var topRank = -1
      var timeScore = 0
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i] || {}
        if (!row.DocumentFileID && !row.DocumentFileUrl) continue
        timeScore = new Date(row.CompletedDate || row.StartedDate || "").getTime()
        if (!Number.isFinite(timeScore) || timeScore < 0) timeScore = 0
        rank = Number(row.StepOrder || 0) * 1000000000 + timeScore
        if (rank > topRank) {
          topRank = rank
          top = row
        }
      }
      if (top) {
        return {
          FileID: top.DocumentFileID || null,
          FileUrl: top.DocumentFileUrl || "",
          FileName: top.DocumentFileName || this.overview.CurrentDocumentFileName || this.overview.SourceFileName || ""
        }
      }
      return {
        FileID: this.overview.CurrentDocumentFileID || this.overview.SourceFileID || null,
        FileUrl: this.overview.CurrentDocumentFileUrl || "",
        FileName: this.overview.CurrentDocumentFileName || this.overview.SourceFileName || ""
      }
    },

    clickReviewAndSend: async function () {
      await this.saveFieldValues()
      this.dialog.reviewSendSign = true
      this.isGeneratingPreview = true
      try {
        await this.ensureMergedPreview(true)
      } catch (err) {
        console.error("Lỗi chuẩn bị file preview:", err)
      } finally {
        this.isGeneratingPreview = false
      }
    },

    sendDocumentForSigning: async function () {
      const self = this
      this.isSendingSign = true
      try {
        const instanceName = this.theChiTiet ? this.theChiTiet.InstanceName : 'tai-lieu-ky-so'

        // [MULTI-TEMPLATE] Upload từng slot, gửi lần lượt
        if (this.activeTemplates && this.activeTemplates.length && Object.keys(this.slotPdfMap || {}).length) {
          var slotKeys = Object.keys(this.slotPdfMap).sort(function (a, b) { return Number(a) - Number(b) })
          var lastSendSuccess = false
          for (var ki = 0; ki < slotKeys.length; ki++) {
            var slotKey = slotKeys[ki]
            var slotBase64 = self.slotPdfMap[slotKey]
            if (!slotBase64) continue
            var slotLabel = ''
            var slotObj = (self.activeTemplates || []).find(function (s) { return String(s.SlotIdx) === slotKey })
            slotLabel = slotObj ? (slotObj.Label || ('Mau-' + (Number(slotKey) + 1))) : ('Mau-' + (Number(slotKey) + 1))
            var slotFileName = instanceName + '-' + slotLabel + '.pdf'
            var slotUploadRes = await apiCallAsync('UPLOAD_FileData_Base64', {
              FileBase64: slotBase64,
              FileName: slotFileName,
              FileContentType: 'application/pdf'
            })
            var slotFileRow = self.extractFileRow(slotUploadRes)
            if (!slotFileRow || !slotFileRow.FileID) throw new Error('Không nhận được FileID khi upload slot ' + slotLabel)
            var slotSendRes = await apiCallAsync('WF_Request_SendForSigning', {
              ExecutionID: self.overview.CurrentExecutionID,
              DocumentFileID: slotFileRow.FileID,
              DocumentFileName: slotFileRow.FileName || slotFileName,
              DocumentFileUrl: 'https://file.zentea.vn/iotdev/FileData/' + slotFileRow.FileID
            })
            var slotSendRow = Array.isArray(slotSendRes) ? slotSendRes[0] : slotSendRes
            if (!slotSendRow || slotSendRow.Success === false) throw new Error(slotSendRow ? slotSendRow.Message : 'Lỗi gửi slot ' + slotLabel)
            lastSendSuccess = true
          }
          if (lastSendSuccess) {
            if (showToast && showToast.success) showToast.success('Đã gửi hồ sơ đi ký số thành công!')
            this.dialog.reviewSendSign = false
            await this.loadData(true)
          }
          return
        }

        // [SINGLE-TEMPLATE]
        if (!this.lastMergedPdfBase64) {
          if (showToast && showToast.error) showToast.error('Không tìm thấy dữ liệu PDF kết xuất.')
          return
        }
        const fileName = instanceName + '.pdf'
        const uploadRes = await apiCallAsync('UPLOAD_FileData_Base64', {
          FileBase64: this.lastMergedPdfBase64,
          FileName: fileName,
          FileContentType: 'application/pdf'
        })
        const fileRow = this.extractFileRow(uploadRes)
        if (!fileRow || !fileRow.FileID) throw new Error('Không nhận được FileID sau khi upload tài liệu.')

        const sendRes = await apiCallAsync('WF_Request_SendForSigning', {
          ExecutionID: this.overview.CurrentExecutionID,
          DocumentFileID: fileRow.FileID,
          DocumentFileName: fileRow.FileName,
          DocumentFileUrl: 'https://file.zentea.vn/iotdev/FileData/' + fileRow.FileID
        })
        const row = Array.isArray(sendRes) ? sendRes[0] : sendRes
        if (row && row.Success !== false) {
          if (showToast && showToast.success) showToast.success('Đã gửi hồ sơ đi ký số thành công!')
          this.dialog.reviewSendSign = false
          await this.loadData(true)
        } else {
          throw new Error(row ? row.Message : 'Lỗi không xác định khi gửi đi ký.')
        }
      } catch (err) {
        console.error('Lỗi gửi đi ký:', err)
        if (showToast && showToast.error) showToast.error(err.message || 'Không thể gửi hồ sơ đi ký.')
      } finally {
        this.isSendingSign = false
      }
    },

    cancelSentSigning: async function () {
      const self = this
      showConfirm(
        "Bạn có chắc chắn muốn hủy luồng ký số này không?\nCác người ký sẽ không thể thực hiện ký cho đến khi bạn gửi lại.",
        async function () {
          self.isCancelingSign = true
          try {
            const res = await apiCallAsync("WF_Request_CancelSigning", {
              ExecutionID: self.overview.CurrentExecutionID
            })
            const row = Array.isArray(res) ? res[0] : res
            if (row && row.Success !== false) {
              if (showToast && showToast.success) showToast.success("Đã hủy luồng ký số thành công!")
              await self.loadData(true)
            } else {
              throw new Error(row ? row.Message : "Lỗi không xác định khi hủy gửi ký.")
            }
          } catch (err) {
            console.error("Lỗi hủy gửi ký:", err)
            if (showToast && showToast.error) showToast.error(err.message || "Không thể hủy gửi ký.")
          } finally {
            self.isCancelingSign = false
          }
        },
        null
      )
    },

    showError: function (err, fallback) {
      var message = fallback || "Có lỗi xảy ra."
      if (err && err.responseJSON && err.responseJSON.Message) message = err.responseJSON.Message
      else if (err && err.responseText) message = err.responseText
      else if (err && err.message) message = err.message
      if (showToast && showToast.error) showToast.error(message)
    },

    // ─── Stub methods for mixin-provided functions ───────────────────────────
    // These are normally provided by __WF_REQUEST_DETAIL_EXTERNAL_MIXIN__ and
    // __WF_REQUEST_DETAIL_SMARTCA_MIXIN__. Stubs prevent crashes when the
    // mixins are not loaded (e.g. when opened as a modal from another module).

    extractEcontractTaggedId: function (text) {
      if (!text) return 0
      var m = String(text).match(/\[econtract:(\d+)\]/i)
      return m ? Number(m[1]) : 0
    },

    getSignatureFieldPerformerName: function (fieldName) {
      if (!fieldName || !this.signers || !this.signers.length) return ''
      var matched = this.signers.find(function (s) {
        return s.SignerValue === fieldName || s.RoleCode === fieldName
      })
      if (matched) return matched.ResolvedPersonName || matched.SignerValue || ''
      var val = this.editFieldValues && this.editFieldValues[fieldName]
      return val ? String(val) : ''
    },

    isSignatureFieldSigned: function (fieldName) {
      if (!fieldName || !this.signers || !this.signers.length) return false
      var self = this
      return this.signers.some(function (s) {
        return (s.SignerValue === fieldName || s.RoleCode === fieldName) &&
          self.isSignedRuntimeStatus(s.Status)
      })
    },

    resolveCurrentSignBox: function () {
      if (!this.signBoxes || !this.signBoxes.length) return null
      var self = this
      var execId = Number(this.overview && this.overview.CurrentSignerExecID || 0)
      if (execId > 0) {
        var byExec = this.signBoxes.find(function (b) { return Number(b.SignerExecID || 0) === execId })
        if (byExec) return byExec
      }
      return this.signBoxes.find(function (b) {
        return !self.isSignedRuntimeStatus(self.resolveSignBoxRuntimeStatus(b))
      }) || null
    },

    getStatusTheme: function (status) {
      var color = this.getStatusColor(status)
      return { soft: color + '1a', muted: color }
    },

    calculateDurationText: function (startDate, endDate) {
      if (!startDate || !endDate) return ''
      var ms = new Date(endDate).getTime() - new Date(startDate).getTime()
      if (ms < 0) return ''
      var mins = Math.floor(ms / 60000)
      if (mins < 60) return mins + ' phút'
      var hours = Math.floor(mins / 60)
      if (hours < 24) return hours + ' giờ'
      return Math.floor(hours / 24) + ' ngày'
    },

    getAttachmentUrl: function (value) {
      return this.getFieldFileUrl(value)
    },

    getAttachmentName: function (value) {
      return this.getFieldFileName(value)
    },

    previewFieldFile: function (value) {
      var url = this.getFieldFileUrl(value)
      if (url) window.open(url, '_blank')
    },

    canSyncCurrentEcontractProvider: function () {
      return false
    },

    resolveEcontractHopDongId: function () {
      return Number(this.overview && this.overview.ExternalContractID || 0)
    },

    resolveWeSignDocumentId: function () {
      return ''
    },

    isExternalDocumentCompleted: function () {
      return false
    },

    callSmartCAInternalSign: async function () {
      throw new Error('SmartCA mixin không được tải.')
    }
  },

  watch: {
    "activeTemplates": function (val) {
      this.activeFormIdx = 0
    },
    "activeTemplateGroups": function (val) {
      this.activeFormIdx = 0
    },
    // Restore previewPdfUrl sau khi đóng dialog xem slot (mergeAndPreviewSlot)
    "dialog.previewPdf": function (val) {
      if (!val && this._previewPdfUrlBackup !== undefined) {
        if (this.previewPdfUrl && this.previewPdfUrl.indexOf('blob:') === 0 && this.previewPdfUrl !== this._previewPdfUrlBackup) {
          URL.revokeObjectURL(this.previewPdfUrl)
        }
        this.previewPdfUrl = this._previewPdfUrlBackup || ''
        this._previewPdfUrlBackup = undefined
      }
    },
    "editFieldValues": {
      handler: function (nextValues) {
        const self = this
        if (!nextValues) return
        (this.customFieldsForCurrentStep || []).forEach(field => {
          if (field.FieldType === 'computed') {
            const formula = field.FieldOptions || ''
            const newVal = self.evaluateComputedField(formula, self.editFieldValues)
            if (String(self.editFieldValues[field.FieldName] || '') !== String(newVal)) {
              self.editFieldValues[field.FieldName] = newVal
            }
          }
        })

        if (this.checklistItems && this.checklistItems.length > 0) {
          this.checklistItems.forEach(chkItem => {
            const matchedField = self.findMatchedFieldForChecklist(chkItem)
            if (matchedField) {
              const val = nextValues[matchedField.FieldName]
              const isCompleted = val ? 1 : 0
              const attachmentUrl = val ? String(val) : null

              if (chkItem.IsCompleted !== isCompleted) {
                self.$set ? self.$set(chkItem, 'IsCompleted', isCompleted) : chkItem.IsCompleted = isCompleted
              }
              if (chkItem.AttachmentUrl !== attachmentUrl) {
                self.$set ? self.$set(chkItem, 'AttachmentUrl', attachmentUrl) : chkItem.AttachmentUrl = attachmentUrl
              }
              if (val && !chkItem.SubmitMethod) {
                self.$set ? self.$set(chkItem, 'SubmitMethod', 'SOFT_COPY') : chkItem.SubmitMethod = 'SOFT_COPY'
              }
            }
          })
        }
      },
      deep: true
    }
  }
	}
</script>