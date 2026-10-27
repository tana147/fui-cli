<template>
	<div>
    <input v-if="createMode === 'FREE_SIGN'" ref="fileInput" type="file" style="display:none;" :accept="fileAccept"
      @change="onFileSelected">
    <div class="wf-request-panel__header">
      <div>
        <h3>{{ createMode === 'FREE_SIGN' ? 'Tài liệu ký tự do' : 'Thông tin tài liệu' }}</h3>
        <p>{{ createMode === 'FREE_SIGN' ? 'Tải tài liệu PDF, đặt vị trí ký trực tiếp trên văn bản và cấu hình người ký
          ở panel bên phải.' : 'Đặt tên tài liệu, chọn nguồn file và điền dữ liệu đầu vào theo workflow đã chọn.' }}</p>
      </div>
    </div>
    <div v-if="createMode !== 'FREE_SIGN'" class="wf-request-form-grid wf-request-form-grid--2">
      <v-select v-model="form.categoryId" :items="categories" item-title="Name" item-value="CategoryID"
        label="Nhóm văn bản" variant="outlined" density="compact" />
      <v-text-field v-model="form.title" label="Tên văn bản / yêu cầu *" variant="outlined" density="compact" />
      <v-text-field v-model="form.code" label="Mã tham chiếu" variant="outlined" density="compact" />
      <v-textarea v-model="form.description" label="Mô tả / ghi chú" variant="outlined" density="compact" rows="3"
        class="wf-request-span-2" />
      <v-select v-model="form.fileMethod" :items="fileMethodOptions" item-title="title" item-value="value"
        label="Nguồn tài liệu" variant="outlined" density="compact" :disabled="createMode === 'FREE_SIGN'" />
      <v-select v-model="form.templateId" :items="templateOptions" item-title="TemplateName" item-value="TemplateID"
        label="Template" variant="outlined" density="compact"
        :disabled="createMode === 'FREE_SIGN' || form.fileMethod !== 'TEMPLATE'" />
      <v-text-field v-model="form.dueDate" type="date" label="Hạn xử lý" variant="outlined" density="compact" />
      <v-select v-model="form.priority" :items="priorityOptions" item-title="title" item-value="value"
        label="Mức ưu tiên" variant="outlined" density="compact" />
    </div>
    <div v-if="createMode !== 'FREE_SIGN'" class="wf-request-section-title">
      <span>Phương thức ký runtime</span>
    </div>
    <div v-if="createMode !== 'FREE_SIGN'" class="wf-request-form-grid wf-request-form-grid--2">
      <v-select v-model="form.executionEngine" :items="executionEngineOptions" item-title="title" item-value="value"
        label="Engine ký" variant="outlined" density="compact" />
      <v-select v-model="form.contractProvider" :items="contractProviderOptions" item-title="title" item-value="value"
        label="Nhà cung cấp eContract" variant="outlined" density="compact"
        :disabled="effectiveEngine !== 'ECONTRACT'" />
    </div>
    <div v-if="isUploadMode && createMode !== 'FREE_SIGN'" class="wf-request-dropzone" @click="openFileDialog">
      <input ref="fileInput" type="file" style="display:none;" :accept="fileAccept" @change="onFileSelected">
      <v-icon size="30" color="grey-lighten-1">mdi-cloud-upload-outline</v-icon>
      <div class="wf-request-dropzone__text">{{ uploadLabel }}</div>
      <div class="wf-request-dropzone__sub">{{ uploadSubLabel }}</div>
    </div>
    <uc-request-free-sign-composer v-if="createMode === 'FREE_SIGN'" :form="form" :preview-file-url="previewFileUrl"
      :signer-profiles="signerProfiles" :role-options="roleOptions" :sign-method-options="signMethodOptions"
      :categories="categories" :execution-engine-options="executionEngineOptions"
      :contract-provider-options="contractProviderOptions" :priority-options="priorityOptions"
      :effective-engine="effectiveEngine" :upload-label="uploadLabel" :upload-sub-label="uploadSubLabel"
      @open-file-dialog="openFileDialog" />
    <div v-if="selectedTemplate && createMode === 'TEMPLATE_FLOW'" class="wf-request-preview-card">
      <div class="d-flex align-center" style="gap: 10px;">
        <v-icon size="18" color="primary">mdi-file-document-outline</v-icon>
        <div style="flex:1;">
          <div class="wf-request-preview-card__title">{{ selectedTemplate.TemplateName }}</div>
          <div class="wf-request-preview-card__sub">{{ selectedTemplate.FileName }} · {{ selectedTemplate.FileType }}
          </div>
        </div>
        <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="$emit('preview-template')">
          <v-icon start size="16">mdi-eye-outline</v-icon>
          Xem mẫu
        </v-btn>
      </div>
      <div class="wf-request-placeholder-wrap">
        <span v-for="placeholder in selectedTemplatePlaceholders" :key="placeholder" class="wf-ph-chip">
          <v-icon size="11">mdi-code-braces</v-icon>{{ placeholder }}
        </span>
      </div>
    </div>
    <div v-if="createMode === 'TEMPLATE_FLOW'" class="wf-request-section-title">
      <span>Dữ liệu biểu mẫu</span>
      <v-chip size="x-small" color="primary" variant="tonal">{{ dynamicFields.length }} trường</v-chip>
    </div>
    <div v-if="createMode === 'TEMPLATE_FLOW' && dynamicFields.length === 0" class="wf-empty-state">
      Workflow hiện tại chưa có trường dữ liệu đầu vào. Bạn vẫn có thể tạo yêu cầu với metadata tài liệu.
    </div>
    <div v-else-if="createMode === 'TEMPLATE_FLOW'" class="wf-request-form-grid wf-request-form-grid--2">
      <template v-for="field in dynamicFields" :key="field.FieldName">
        <!-- File Upload -->
        <div v-if="field.FieldType === 'file'"
          class="wf-request-field border rounded pa-3 bg-white d-flex flex-column justify-center align-center border-dashed"
          style="border-color: #bdbdbd !important; min-height: 100px; cursor: pointer; position: relative;"
          @click="triggerFieldFileInput(field.FieldName)">
          <input :ref="'file_input_' + field.FieldName" type="file" style="display:none;"
            @change="onFieldFileSelected($event, field.FieldName)">

          <v-icon color="primary" class="mb-1" size="24">mdi-cloud-upload-outline</v-icon>
          <div class="text-caption text-grey-darken-1 font-weight-medium text-center">
            {{ field.FieldLabel }} <span v-if="field.IsRequired" class="text-error font-weight-bold">*</span>
          </div>

          <!-- Render uploaded file info if exists -->
          <div v-if="form.fieldValues[field.FieldName]"
            class="mt-2 d-flex align-center border rounded px-2 py-1 bg-blue-lighten-5 text-blue-darken-3"
            style="font-size: 11px; gap: 6px;" @click.stop>
            <v-icon size="14">mdi-paperclip</v-icon>
            <span class="text-truncate" style="max-width: 180px;">{{ getFieldFileName(form.fieldValues[field.FieldName])
              }}</span>
            <v-btn icon size="x-small" variant="text" color="error" class="ml-1"
              @click="clearFieldFile(field.FieldName)">
              <v-icon size="12">mdi-close</v-icon>
            </v-btn>
          </div>
          <div v-else class="text-caption text-grey" style="font-size: 10px;">Bấm để chọn file tài liệu</div>
        </div>

        <!-- Checklist -->
        <div v-else-if="field.FieldType === 'checklist'"
          class="wf-request-field wf-request-span-2 border rounded pa-3 bg-white">
          <div class="text-caption font-weight-medium text-grey-darken-2 mb-2">
            {{ field.FieldLabel }} <span v-if="field.IsRequired" class="text-error font-weight-bold">*</span>
          </div>
          <div class="d-flex flex-column" style="gap: 4px;">
            <div v-for="(item, idx) in getChecklistOptions(field.FieldOptions)" :key="idx" class="d-flex align-center">
              <v-checkbox :label="item" :model-value="getChecklistState(field.FieldName)[item] === true"
                density="compact" color="primary" hide-details
                @update:model-value="toggleChecklistItem(field.FieldName, item)" />
            </div>
          </div>
        </div>

        <!-- Rating Stars -->
        <div v-else-if="field.FieldType === 'rating'" class="wf-request-field border rounded pa-3 bg-white">
          <div class="text-caption font-weight-medium text-grey-darken-2 mb-1">
            {{ field.FieldLabel }} <span v-if="field.IsRequired" class="text-error font-weight-bold">*</span>
          </div>
          <div class="d-flex align-center" style="gap: 8px;">
            <v-rating v-model="form.fieldValues[field.FieldName]" color="amber" density="compact" size="small"
              :readonly="field.IsPlaceholderOnly" />
            <span class="text-caption font-weight-bold text-amber-darken-2">
              {{ Number(form.fieldValues[field.FieldName] || 0).toFixed(1) }} / 5.0
            </span>
          </div>
        </div>

        <!-- Computed formula field -->
        <div v-else-if="field.FieldType === 'computed'" class="wf-request-field">
          <v-text-field v-model="form.fieldValues[field.FieldName]" :label="field.FieldLabel + ' (Tự động tính toán)'"
            variant="outlined" density="compact" readonly bg-color="grey-lighten-4"
            prepend-inner-icon="mdi-calculator-variant" />
        </div>

        <!-- Standard text field types -->
        <div v-else class="wf-request-field">
          <v-textarea v-if="field.FieldType === 'textarea'" v-model="form.fieldValues[field.FieldName]"
            :label="field.FieldLabel + (field.IsRequired ? ' *' : '')" variant="outlined" density="compact" rows="3" />
          <v-text-field v-else v-model="form.fieldValues[field.FieldName]"
            :label="field.FieldLabel + (field.IsRequired ? ' *' : '')" variant="outlined" density="compact"
            :type="field.FieldType === 'number' ? 'number' : 'text'" />
        </div>
      </template>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-request-document-config",
  props: {
    createMode: { type: String, default: "TEMPLATE_FLOW" },
    form: { type: Object, default: function () { return {}; } },
    categories: { type: Array, default: function () { return []; } },
    executionEngineOptions: { type: Array, default: function () { return []; } },
    contractProviderOptions: { type: Array, default: function () { return []; } },
    roleOptions: { type: Array, default: function () { return []; } },
    signerProfiles: { type: Array, default: function () { return []; } },
    signMethodOptions: { type: Array, default: function () { return []; } },
    fileMethodOptions: { type: Array, default: function () { return []; } },
    templateOptions: { type: Array, default: function () { return []; } },
    priorityOptions: { type: Array, default: function () { return []; } },
    selectedTemplate: { type: Object, default: null },
    selectedTemplatePlaceholders: { type: Array, default: function () { return []; } },
    dynamicFields: { type: Array, default: function () { return []; } },
    isUploadMode: { type: Boolean, default: false },
    fileAccept: { type: String, default: ".pdf" },
    uploadLabel: { type: String, default: "" },
    uploadSubLabel: { type: String, default: "" }
  },
  data: function () {
    return {
      previewFileUrl: "",
      previewSourceType: "",
      previewLoadKey: "",
      previewLoadTimer: null
    };
  },
  computed: {
    effectiveEngine: function () {
      var engine = String(this.form.executionEngine || "SMARTCA").toUpperCase();
      if (engine !== "ECONTRACT") engine = "SMARTCA";
      return engine;
    }
  },
  mounted: function () {
    if (this.createMode !== "FREE_SIGN") return;
    if (this.previewSourceType === "local") return;
    this.scheduleLoadPreviewByFileId(this.form.fileId || this.extractFileIdFromUrl(this.form.fileUrl || ""));
  },
  beforeUnmount: function () {
    if (this.previewLoadTimer) {
      window.clearTimeout(this.previewLoadTimer);
      this.previewLoadTimer = null;
    }
    this.clearPreviewUrl();
  },
  methods: {
    openFileDialog: function () {
      if (this.$refs.fileInput) this.$refs.fileInput.click();
    },
    onFileSelected: function (event) {
      var files = event && event.target ? event.target.files : null;
      var file = files && files[0] ? files[0] : null;
      this.clearPreviewUrl();
      if (file && this.createMode === "FREE_SIGN" && String(file.type || "").indexOf("pdf") >= 0) {
        this.previewFileUrl = URL.createObjectURL(file);
        this.previewSourceType = "local";
      }
      this.$emit("file-selected", event);
    },
    clearPreviewUrl: function () {
      if (this.previewFileUrl && String(this.previewSourceType || "") === "local") URL.revokeObjectURL(this.previewFileUrl);
      this.previewFileUrl = "";
      this.previewSourceType = "";
      this.previewLoadKey = "";
    },
    buildPreviewLoadKey: function (fileId) {
      var normalizedFileId = String(fileId || "").trim();
      var fileUrl = String(this.form && this.form.fileUrl ? this.form.fileUrl : "").trim();
      var binaryLen = String(this.form && this.form.fileBinaryBase64 ? this.form.fileBinaryBase64 : "").trim().length;
      return normalizedFileId + "|" + fileUrl + "|" + String(binaryLen);
    },
    scheduleLoadPreviewByFileId: function (fileId) {
      var self = this;
      if (this.previewSourceType === "local") return;
      if (this.previewLoadTimer) {
        window.clearTimeout(this.previewLoadTimer);
        this.previewLoadTimer = null;
      }
      this.previewLoadTimer = window.setTimeout(function () {
        self.previewLoadTimer = null;
        self.loadPreviewByFileId(fileId);
      }, 40);
    },
    resolveServerFileUrl: function (fileId, fileUrl) {
      var normalized = fileUrl ? String(fileUrl) : "";
      if (normalized) {
        if (normalized.indexOf("http://") === 0 || normalized.indexOf("https://") === 0 || normalized.indexOf("blob:") === 0) return normalized;
      }
      if (!fileId) return "";
      return "https://file.zentea.vn/iotdev/FileData/" + fileId;
    },
    extractFileIdFromUrl: function (url) {
      var raw = String(url || "");
      var match = raw.match(/\/FileData\/([A-Za-z0-9]+)/i);
      if (match && match[1]) return match[1];
      return "";
    },
    loadPreviewByFileId: function (fileId) {
      var self = this;
      var normalizedFileId = String(fileId || this.form.fileId || "").trim();
      var normalizedFromUrl = this.extractFileIdFromUrl(this.form.fileUrl || "");
      var effectiveFileId = normalizedFileId || normalizedFromUrl;
      var directUrl = "";
      var blob = null;
      var normalizedBinary = "";
      var nextKey = "";
      if (this.previewSourceType === "local") return;
      if (!effectiveFileId && !this.form.fileUrl && !this.form.fileBinaryBase64) {
        this.clearPreviewUrl();
        return;
      }
      nextKey = this.buildPreviewLoadKey(effectiveFileId);
      if (this.previewLoadKey === nextKey && this.previewFileUrl) return;
      this.previewLoadKey = nextKey;
      normalizedBinary = this.normalizeBase64(this.form.fileBinaryBase64 || "");
      if (normalizedBinary) {
        try {
          this.clearPreviewUrl();
          this.previewFileUrl = URL.createObjectURL(this.base64ToBlob(normalizedBinary, "application/pdf"));
          this.previewSourceType = "server-binary";
          return;
        } catch (e) {
        }
      }
      this.readFileBinaryById(effectiveFileId, function (binary) {
        blob = self.parsePdfContentToBlob(binary);
        if (blob) {
          self.clearPreviewUrl();
          self.previewFileUrl = URL.createObjectURL(blob);
          self.previewSourceType = "server-binary";
          return;
        }
        directUrl = self.resolveServerFileUrl(effectiveFileId, self.form.fileUrl);
        if (!directUrl) return;
        self.clearPreviewUrl();
        self.previewFileUrl = directUrl;
        self.previewSourceType = "server-url";
      }, function () {
        directUrl = self.resolveServerFileUrl(effectiveFileId, self.form.fileUrl);
        if (!directUrl) return;
        self.clearPreviewUrl();
        self.previewFileUrl = directUrl;
        self.previewSourceType = "server-url";
      });
    },
    readFileBinaryById: function (fileId, onSuccess, onError) {
      var normalized = String(fileId || "").trim();
      var handled = false;
      var finishSuccess = function (binary) {
        if (handled) return;
        handled = true;
        if (typeof onSuccess === "function") onSuccess(binary || "");
      };
      var finishError = function (err) {
        if (handled) return;
        handled = true;
        if (typeof onError === "function") onError(err || new Error("READ_FILE_FAILED"));
      };
      var pickBinary = function (res) {
        var row = null;
        if (res && res.data && res.data[0] && res.data[0][0]) row = res.data[0][0];
        else if (res && res[0]) row = res[0];
        else if (res && res.FileID) row = res;
        return row ? (row.BinaryContent || row.FILE_CONTENT || row.FileBinaryBase64 || row.FILE_BINARY || row.FileBinary || "") : "";
      };
      var readWithApiCallAsync = async function (apiName, payload) {
        if (typeof apiCallAsync !== "function") throw new Error("apiCallAsync unavailable");
        return apiCallAsync(apiName, payload || {});
      };
      if (!normalized) {
        finishError(new Error("MISSING_FILE_ID"));
        return;
      }
      (async function () {
        var res = null;
        var binary = "";
        try {
          res = await readWithApiCallAsync("FileData_GetByID", { FileID: normalized, ID: normalized });
          binary = pickBinary(res);
          finishSuccess(binary);
          return;
        } catch (e1) {
          finishError(e1);
          return;
        }
      })();
    },
    base64ToBlob: function (base64, mime) {
      var normalized = this.normalizeBase64(base64);
      var bytes = atob(normalized);
      var len = bytes.length;
      var arr = new Uint8Array(len);
      var i = 0;
      for (i = 0; i < len; i += 1) arr[i] = bytes.charCodeAt(i);
      return new Blob([arr], { type: mime || "application/octet-stream" });
    },
    normalizeBase64: function (value) {
      var raw = String(value || "").trim();
      if (!raw) return "";
      if (raw.indexOf("base64,") >= 0) raw = raw.split("base64,").pop() || "";
      return raw.replace(/\s+/g, "");
    },
    rawBinaryStringToBlob: function (raw, mime) {
      var text = String(raw || "");
      var len = text.length;
      var bytes = new Uint8Array(len);
      var i = 0;
      for (i = 0; i < len; i += 1) bytes[i] = text.charCodeAt(i) & 0xff;
      return new Blob([bytes], { type: mime || "application/pdf" });
    },
    hexStringToBlob: function (hex, mime) {
      var normalized = String(hex || "").trim();
      var clean = "";
      var len = 0;
      var bytes = null;
      var i = 0;
      if (!normalized) return null;
      clean = normalized.indexOf("0x") === 0 || normalized.indexOf("0X") === 0 ? normalized.slice(2) : normalized;
      if (!/^[0-9a-fA-F]+$/.test(clean) || clean.length % 2 !== 0) return null;
      len = clean.length / 2;
      bytes = new Uint8Array(len);
      for (i = 0; i < len; i += 1) bytes[i] = parseInt(clean.substr(i * 2, 2), 16);
      return new Blob([bytes], { type: mime || "application/pdf" });
    },
    parsePdfContentToBlob: function (value) {
      var raw = String(value || "");
      var normalized = this.normalizeBase64(raw);
      if (!raw) return null;
      if (raw.indexOf("%PDF-") === 0) return this.rawBinaryStringToBlob(raw, "application/pdf");
      if (raw.indexOf("0x") === 0 || raw.indexOf("0X") === 0) return this.hexStringToBlob(raw, "application/pdf");
      try {
        if (/^[A-Za-z0-9+/=]+$/.test(normalized)) return this.base64ToBlob(normalized, "application/pdf");
      } catch (e) {
      }
      if (raw.indexOf("%PDF-") > 0) return this.rawBinaryStringToBlob(raw.slice(raw.indexOf("%PDF-")), "application/pdf");
      return null;
    },
    getChecklistOptions: function (options) {
      var raw = String(options || '').trim();
      if (!raw) return [];
      try {
        var parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) return parsed;
      } catch (e) {}
      if (raw.indexOf(',') >= 0) return raw.split(',').map(function (s) { return s.trim(); });
      return [raw];
    },
    getChecklistState: function (fieldName) {
      var raw = this.form.fieldValues[fieldName] || "";
      if (typeof raw === "object" && raw !== null) return raw;
      try {
        var parsed = JSON.parse(raw);
        if (parsed && typeof parsed === "object") return parsed;
      } catch (e) {}
      return {};
    },
    toggleChecklistItem: function (fieldName, item) {
      var state = this.getChecklistState(fieldName);
      state[item] = !state[item];
      this.form.fieldValues[fieldName] = JSON.stringify(state);
    },
    triggerFieldFileInput: function (fieldName) {
      var ref = this.$refs['file_input_' + fieldName];
      var el = Array.isArray(ref) ? ref[0] : ref;
      if (el) el.click();
    },
    onFieldFileSelected: async function (event, fieldName) {
      var self = this;
      var files = event && event.target ? event.target.files : null;
      var file = files && files[0] ? files[0] : null;
      if (!file) return;
      
      var reader = new FileReader();
      reader.onload = function (evt) {
        var dataUrl = evt && evt.target ? evt.target.result : "";
        var base64 = "";
        if (!dataUrl || String(dataUrl).indexOf(",") < 0) {
          if (showToast && showToast.error) showToast.error("Không đọc được nội dung file.");
          return;
        }
        base64 = String(dataUrl).split(",")[1] || "";
        if (typeof apiCall === "function") {
          apiCall("UPLOAD_FileData_Base64", {
            FileBase64: base64,
            FileName: file.name || "field-document.pdf",
            FileContentType: file.type || "application/octet-stream"
          }, function (res) {
            var fileRow = null;
            if (res && res.data && res.data[0] && res.data[0][0]) fileRow = res.data[0][0];
            else if (res && res[0]) fileRow = res[0];
            else if (res && res.FileID) fileRow = res;
            
            if (!fileRow || !fileRow.FileID) {
              if (showToast && showToast.error) showToast.error("Không nhận được FileID.");
              return;
            }
            self.form.fieldValues[fieldName] = JSON.stringify({
              FileID: fileRow.FileID,
              FileName: fileRow.FileName || file.name
            });
            if (showToast && showToast.success) showToast.success("Tải tệp lên thành công.");
          }, function (err) {
            var msg = err && err.message ? err.message : "Tải tệp lên thất bại.";
            if (showToast && showToast.error) showToast.error(msg);
          });
        }
      };
      reader.readAsDataURL(file);
      if (event.target) event.target.value = "";
    },
    getFieldFileName: function (value) {
      if (!value) return "";
      try {
        var parsed = JSON.parse(value);
        if (parsed && parsed.FileName) return parsed.FileName;
      } catch (e) {}
      return String(value);
    },
    clearFieldFile: function (fieldName) {
      this.form.fieldValues[fieldName] = "";
    },
    evaluateComputedField: function (formula) {
      if (!formula) return '0';
      var self = this;
      var expr = String(formula).trim();
      
      // Replace [FieldName] first
      expr = expr.replace(/\[([^\]]+)\]/g, function (match, fieldName) {
        var key = fieldName.trim();
        var val = Number(self.form.fieldValues[key]);
        return Number.isFinite(val) ? String(val) : '0';
      });
      
      // Replace alphanumeric FieldNames
      Object.keys(self.form.fieldValues || {}).forEach(function (key) {
        var val = Number(self.form.fieldValues[key]);
        if (!Number.isFinite(val)) val = 0;
        var re = new RegExp('\\b' + key + '\\b', 'g');
        expr = expr.replace(re, String(val));
      });
      
      try {
        var sanitized = expr.replace(/[^0-9\+\-\*\/\(\)\.\s]/g, '');
        if (!sanitized.trim()) return '0';
        
        var result = Function('"use strict"; return (' + sanitized + ')')();
        if (Number.isFinite(result)) {
          return result % 1 === 0 ? String(result) : result.toFixed(1);
        }
        return '0';
      } catch (e) {
        return '0';
      }
    }
  },
  watch: {
    "form.executionEngine": function (value) {
      var normalized = String(value || "SMARTCA").toUpperCase();
      if (normalized !== "ECONTRACT") {
        this.form.executionEngine = "SMARTCA";
        this.form.contractProvider = "";
      }
    },
    "form.fieldValues": {
      handler: function (nextValues) {
        var self = this;
        if (!nextValues) return;
        var hasChanged = false;
        (this.dynamicFields || []).forEach(function (field) {
          if (field.FieldType === 'computed') {
            var formula = field.FieldOptions || '';
            var newVal = self.evaluateComputedField(formula);
            if (String(self.form.fieldValues[field.FieldName] || '') !== String(newVal)) {
              self.form.fieldValues[field.FieldName] = newVal;
              hasChanged = true;
            }
          }
        });
      },
      deep: true
    },
    "form.fileId": function (value) {
      if (!value) {
        this.clearPreviewUrl();
        return;
      }
      this.scheduleLoadPreviewByFileId(value);
    },
    "form.fileUrl": function (value) {
      if (this.previewSourceType === "local") return;
      if (!this.form.fileId && !value) {
        this.clearPreviewUrl();
        return;
      }
      this.scheduleLoadPreviewByFileId(this.form.fileId || this.extractFileIdFromUrl(value || ""));
    },
    "form.fileBinaryBase64": function (value) {
      if (this.previewSourceType === "local") return;
      if (!value && !this.form.fileId && !this.form.fileUrl) {
        this.clearPreviewUrl();
        return;
      }
      this.scheduleLoadPreviewByFileId(this.form.fileId);
    }
  }
	}
</script>