<template>
	<uc-wf-shell>
    <div class="wf-page-header">
      <div>
        <h1>Quản lý văn bản mẫu</h1>
        <p>Upload file Word/PDF mẫu, đánh dấu placeholder và tái sử dụng cho quy trình.</p>
      </div>
      <v-btn class="wf-btn" variant="outlined" color="primary" @click="openCreateDialog">
        <v-icon start="">mdi-plus</v-icon>
        Thêm mới
      </v-btn>
    </div>

    <uc-table title="Danh sách mẫu" :show-count="true" :headers="templateHeaders" :items="filteredTemplates"
      item-value="TemplateID" searchable search-placeholder="Tìm template..." max-height="calc(100vh - 163px)" :rounded="false">
      <template #item.template="{ item }">
        <div class="d-flex align-center wf-template-title" style="cursor: pointer;" @click.stop="openEditDialog(item)">
          <v-icon color="primary" size="18">
            {{ item.FileType === 'docx' ? 'mdi-file-word-box' : 'mdi-file-pdf-box' }}
          </v-icon>
          <div>
            <div class="wf-audit-title">{{ item.TemplateName }}</div>
            <div class="wf-audit-sub">{{ item.Description || 'Không có mô tả' }}</div>
            <div class="wf-audit-sub">v{{ item.VersionNo || 1 }} · {{ formatDateTime(item.UpdateTime || item.CreateTime)
              }}</div>
          </div>
        </div>
      </template>
      <template #item.fileType="{ item }">
        <v-chip size="x-small" variant="outlined" color="primary">{{ String(item.FileType || '').toUpperCase() }}
        </v-chip>
      </template>
      <template #item.placeholders="{ item }">
        <div class="d-flex flex-wrap wf-template-placeholders">
          <span v-for="placeholder in getPreviewPlaceholders(item)" :key="placeholder" class="wf-ph-chip">{{ placeholder
            }}</span>
          <span v-if="item.Placeholders && item.Placeholders.length > 3" class="wf-template-more">+{{
            item.Placeholders.length - 3 }}</span>
        </div>
      </template>
      <template #item.usage="{ item }">
        <span class="wf-audit-meta">{{ item.WorkflowCount }} luồng</span>
      </template>
      <template #item.actions="{ item }">
        <div class="d-flex ga-1">
          <v-btn icon size="x-small" variant="text" color="primary" :disabled="!item.FileUrl"
            @click.stop="openTemplateFile(item)">
            <v-icon size="14">mdi-open-in-new</v-icon>
          </v-btn>
          <v-btn icon size="x-small" variant="text" color="primary" :disabled="isDeleting"
            @click.stop="removeTemplate(item)">
            <v-icon size="14" class="wf-icon-danger">mdi-delete-outline</v-icon>
          </v-btn>
        </div>
      </template>
    </uc-table>

    <v-dialog v-model="showDialog" max-width="760">
      <v-card>
        <v-card-title class="wf-template-dialog-title">{{ dialogTitle }}</v-card-title>
        <v-card-text class="wf-template-dialog-body">
          <uc-file-upload accept=".docx,.pdf" title="Bấm để chọn hoặc kéo file .docx/.pdf vào đây"
            hint="Hệ thống sẽ gọi API đọc trường dữ liệu từ template." :disabled="extractingPlaceholders"
            :is-uploading="extractingPlaceholders || uploadingTemplateFile"
            :uploading-text="extractingPlaceholders ? 'Đang đọc trường dữ liệu...' : 'Đang upload file...'"
            :file-name="pickedFileName" :read-base64="true" @file-selected="onUploadFileSelected"
            @error="onUploadError">
          </uc-file-upload>
          <v-row dense="" class="wf-template-form">
            <v-col cols="12" md="8">
              <v-text-field v-model="draft.TemplateName" label="Tên template" variant="outlined" density="compact">
              </v-text-field>
            </v-col>
            <v-col cols="12" md="4">
              <v-select v-model="draft.FileType" :items="['docx', 'pdf']" label="Loại file" variant="outlined"
                density="compact">
              </v-select>
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="draft.FileName" label="Tên file" variant="outlined" density="compact"
                @update:model-value="onFileNameInput">
              </v-text-field>
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="draft.FileUrl" label="Đường dẫn file" variant="outlined" density="compact"
                @update:model-value="onFileUrlInput">
              </v-text-field>
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="draft.Description" label="Mô tả" variant="outlined" density="compact" rows="3"
                auto-grow="">
              </v-textarea>
            </v-col>
          </v-row>
          <div class="wf-section-title">Placeholder dự kiến</div>
          <div class="d-flex flex-wrap ga-2">
            <span v-for="placeholder in samplePlaceholders" :key="placeholder" class="wf-ph-chip">
              <v-icon size="12">mdi-code-braces</v-icon>
              {{ placeholder }}
            </span>
          </div>
        </v-card-text>
        <v-card-actions>
          <v-spacer>
            <v-btn variant="text" @click="showDialog = false">Hủy</v-btn>
            <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSaving"
              :disabled="isSaving || extractingPlaceholders || uploadingTemplateFile" @click="saveTemplate">
              <v-icon start="">mdi-content-save-outline</v-icon>
              Lưu
            </v-btn>
          </v-spacer>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
    return {
      templates: [],
      searchQuery: "",
      showDialog: false,
      isSaving: false,
      isDeleting: false,
      dialogMode: "create",
      extractingPlaceholders: false,
      uploadingTemplateFile: false,
      pickedFileName: "",
      pickedFileBase64: "",
      fileUrlTouchedByUser: false,
      autoGeneratedFileUrl: "",
      templateHeaders: [
        { title: 'Template', key: 'template' },
        { title: 'Loại file', key: 'fileType', width: '100px' },
        { title: 'Trường dữ liệu', key: 'placeholders', width: '160px' },
        { title: 'Sử dụng bởi', key: 'usage', width: '100px' },
        { title: '', key: 'actions', width: '60px' }
      ],
      draft: {
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
      samplePlaceholders: ["HoTenUV", "ViTriTuyen", "NgaySinh", "Email"],
      // extractPlaceholders: "https://ca-uat.iotsoftvn.com/api/pdf/extract-placeholders",
      // a-uat.iotsoftvn.com http://192.168.1.241/
      eContractApiMap: {
        screen: "wf-admin-templates",
        extractPlaceholders: "http://192.168.1.241:5000/api/pdf/extract-placeholders",
        mergeDocxTemplate: "/api/pdf/merge-docx-template",
        uploadTemplateFile: "UPLOAD_FileData_Base64",
        readTemplateFile: "APIFILE_FileData"
      }
    };
  },
  mounted: function () {
    if (typeof window !== "undefined") {
      window.__WF_ECONTRACT_SCREEN_MAP__ = window.__WF_ECONTRACT_SCREEN_MAP__ || {};
      window.__WF_ECONTRACT_SCREEN_MAP__["wf-admin-templates"] = this.eContractApiMap;
    }
    this.loadTemplates()
  },
  computed: {
    dialogTitle: function () {
      return this.dialogMode === "edit" ? "Cập nhật template" : "Upload template mới";
    },
    filteredTemplates: function () {
      var keyword = (this.searchQuery || "").toLowerCase().trim();
      return this.templates.filter(function (item) {
        var name = ((item && item.TemplateName) || "").toLowerCase();
        var desc = ((item && item.Description) || "").toLowerCase();
        var fileName = ((item && item.FileName) || "").toLowerCase();
        return !keyword || name.includes(keyword) || desc.includes(keyword) || fileName.includes(keyword);
      });
    }
  },
  methods: {
    formatDateTime: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (Number.isNaN(dt.getTime())) return value;
      var dd = String(dt.getDate()).padStart(2, "0");
      var mm = String(dt.getMonth() + 1).padStart(2, "0");
      var yyyy = dt.getFullYear();
      var hh = String(dt.getHours()).padStart(2, "0");
      var mi = String(dt.getMinutes()).padStart(2, "0");
      return dd + "/" + mm + "/" + yyyy + " " + hh + ":" + mi;
    },
    getEmptyDraft: function () {
      return {
        TemplateID: 0,
        TemplateName: "",
        FileName: "",
        FileUrl: "",
        FileType: "docx",
        Description: "",
        Placeholders: this.samplePlaceholders.slice(),
        SignatureSlots: [],
        IsActive: true
      };
    },
    normalizeTemplate: function (item) {
      var placeholders = []
      var placeholderSource = item.PlaceholderJSON || item.Placeholders || item.MergeFields || null
      if (Array.isArray(placeholderSource)) placeholders = placeholderSource
      if (typeof placeholderSource === "string") {
        try {
          var parsed = JSON.parse(placeholderSource)
          if (Array.isArray(parsed)) placeholders = parsed
        } catch (e) {
          placeholders = placeholderSource.split(",").map(function (s) { return s.trim(); }).filter(Boolean)
        }
      }
      var signatureSlots = []
      var signatureSource = item.SignatureSlotsJSON || item.SignatureSlots || null
      if (Array.isArray(signatureSource)) signatureSlots = signatureSource
      if (typeof signatureSource === "string" && signatureSource) {
        try {
          var parsedSlots = JSON.parse(signatureSource)
          if (Array.isArray(parsedSlots)) signatureSlots = parsedSlots
        } catch (e) {
          signatureSlots = signatureSource.split(",").map(function (s) { return s.trim(); }).filter(Boolean)
        }
      }
      return Object.assign({}, item, {
        Placeholders: placeholders,
        SignatureSlots: signatureSlots,
        Description: item.Description || "",
        WorkflowCount: item.WorkflowCount || 0,
        IsActive: item.IsActive === false ? false : true
      })
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
    getPreviewPlaceholders: function (template) {
      return (template.Placeholders || []).slice(0, 3);
    },
    openTemplateFile: function (template) {
      debugger
      if (!template || !template.FileUrl) return;
      window.open('https://file.zentea.vn/iotdev/' + template.FileUrl, "_blank");
    },
    openCreateDialog: function () {
      this.dialogMode = "create";
      this.draft = this.getEmptyDraft();
      this.pickedFileName = "";
      this.pickedFileBase64 = "";
      this.fileUrlTouchedByUser = false;
      this.autoGeneratedFileUrl = "";
      this.showDialog = true;
    },
    openEditDialog: function (template) {
      this.dialogMode = "edit";
      this.draft = {
        TemplateID: template.TemplateID || 0,
        TemplateName: template.TemplateName || "",
        FileName: template.FileName || "",
        FileUrl: template.FileUrl || "",
        FileType: template.FileType || "docx",
        Description: template.Description || "",
        Placeholders: (template.Placeholders || []).slice(),
        SignatureSlots: (template.SignatureSlots || []).slice(),
        IsActive: template.IsActive === false ? false : true
      };
      this.pickedFileName = this.draft.FileName || "";
      this.pickedFileBase64 = "";
      this.autoGeneratedFileUrl = this.buildTemplatePathFromFileName(this.draft.FileName || "");
      this.fileUrlTouchedByUser = !!(this.draft.FileUrl || "") && this.draft.FileUrl !== this.autoGeneratedFileUrl;
      this.showDialog = true;
    },
    buildTemplatePathFromFileName: function (fileName) {
      var raw = String(fileName || "").trim();
      if (!raw) return "";
      var normalized = raw;
      try {
        normalized = normalized.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
      } catch (e) {}
      var safeName = normalized
        .replace(/[^A-Za-z0-9._-]+/g, "_")
        .replace(/_+/g, "_")
        .replace(/^_+|_+$/g, "");
      if (!safeName) safeName = "template_" + Date.now();
      return "/templates/" + safeName;
    },
    applySelectedFileMeta: function (fileName, fileType, forceUpdatePath) {
      this.draft.FileName = fileName;
      this.draft.FileType = fileType;
      if (!(this.draft.TemplateName || "").trim()) {
        this.draft.TemplateName = fileName.replace(/\.[^/.]+$/, "");
      }
      var generatedPath = this.buildTemplatePathFromFileName(fileName);
      var shouldUpdatePath = !!forceUpdatePath || !this.draft.FileUrl || !this.fileUrlTouchedByUser || this.draft.FileUrl === this.autoGeneratedFileUrl;
      this.autoGeneratedFileUrl = generatedPath;
      if (shouldUpdatePath) {
        this.draft.FileUrl = generatedPath;
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
        res = await apiCallAsync(eContractApiMap.uploadTemplateFile, params);
        fileRow = this.pickUploadedFileRow(res);
      } catch (errTemplateApi) {}
      if (!fileRow || !fileRow.FileID) {
        res = await apiCallAsync("UPLOAD_FileData_Base64", params);
        fileRow = this.pickUploadedFileRow(res);
      }
      if (!fileRow || !fileRow.FileID) {
        throw new Error("Không nhận được FileID sau khi upload template.");
      }
      return fileRow;
    },
    resolveExtractPlaceholderEndpoint: function () {
      var override = "";
      try {
        if (typeof window !== "undefined" && window && window.__WF_TEMPLATE_EXTRACT_ENDPOINT__) {
          override = String(window.__WF_TEMPLATE_EXTRACT_ENDPOINT__).trim();
        }
      } catch (e) {}
      if (!override) {
        try {
          if (typeof localStorage !== "undefined" && localStorage) {
            override = String(localStorage.getItem("WF_TEMPLATE_EXTRACT_ENDPOINT") || "").trim();
          }
        } catch (e2) {}
      }
      if (override) return override;
      return "http://192.168.1.241:5000/api/pdf/extract-placeholders";
    },
    resolveSignApiKey: function () {
      var override = "";
      try {
        if (typeof window !== "undefined" && window && window.__WF_SMARTCA_APIKEY__) {
          override = String(window.__WF_SMARTCA_APIKEY__).trim();
        }
      } catch (e) {}
      if (!override) {
        try {
          if (typeof localStorage !== "undefined" && localStorage) {
            override = String(localStorage.getItem("WF_SMARTCA_APIKEY") || "").trim();
          }
        } catch (e2) {}
      }
      if (override) return override;
      return "eGFjLXRodWMtdHUtbGh1LWVkdS12bkAyMDI1QGZ1aS52bg==";
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
    onUploadFileSelected: function (payload) {
      if (!payload || !payload.file) return;
      this.processTemplateFile(payload.file);
    },
    onUploadError: function (err) {
      if (typeof showToast !== 'undefined' && showToast.error) {
        showToast.error(err && err.message ? err.message : 'Lỗi chọn file.');
      }
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
        this.draft.Placeholders = placeholders;
        this.samplePlaceholders = placeholders.length ? placeholders : this.samplePlaceholders;
        this.uploadingTemplateFile = true;
        uploaded = await this.uploadTemplateToFileData(base64, fileName, fileType);
        this.autoGeneratedFileUrl = "/FileData/" + uploaded.FileID;
        this.draft.FileUrl = this.autoGeneratedFileUrl;
        this.fileUrlTouchedByUser = false;
        if (showToast && showToast.success) {
          showToast.success("Đã đọc " + placeholders.length + " trường dữ liệu và upload file thành công.");
        }
      } catch (err) {
        if (showToast && showToast.error) {
          var msg = err && err.message ? err.message : "Không đọc được trường dữ liệu từ file.";
          showToast.error(msg);
        }
      } finally {
        this.uploadingTemplateFile = false;
        this.extractingPlaceholders = false;
      }
    },
    validateDraft: function () {
      if (!(this.draft.TemplateName || "").trim()) return "Tên template không được để trống.";
      if (!(this.draft.FileType || "").trim()) return "Loại file không được để trống.";
      if (!(this.draft.FileName || "").trim()) return "Tên file không được để trống.";
      return "";
    },
    buildSaveParams: function () {
      return {
        TemplateID: Number(this.draft.TemplateID || 0),
        TemplateName: (this.draft.TemplateName || "").trim(),
        FileName: (this.draft.FileName || "").trim(),
        FileUrl: (this.draft.FileUrl || "").trim(),
        FileType: (this.draft.FileType || "").trim(),
        Placeholders: this.draft.Placeholders || [],
        SignatureSlots: this.draft.SignatureSlots || [],
        Description: (this.draft.Description || "").trim(),
        IsActive: this.draft.IsActive ? true : false
      };
    },
    saveTemplate: function () {
      var $this = this;
      var validateMessage = this.validateDraft();
      if (validateMessage) {
        if (showToast && showToast.error) showToast.error(validateMessage);
        return;
      }
      this.isSaving = true;
      apiCall(
        "WF_Template_Save",
        this.buildSaveParams(),
        function (res) {
          var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null;
          if (showToast && showToast.success) {
            showToast.success(row && row.Message ? row.Message : "Lưu template thành công.");
          }
          $this.showDialog = false;
          $this.draft = $this.getEmptyDraft();
          $this.loadTemplates().then(function () {
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
    removeTemplate: function (template) {
      var $this = this;
      if (!template || !template.TemplateID) return;
      showConfirm(
        template.TemplateName ? 'Xóa template "' + template.TemplateName + '"?' : "Xóa template?",
        function () {
          $this.isDeleting = true;
          apiCall(
            "WF_Template_Delete",
            { TemplateID: template.TemplateID },
            function (res) {
              var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null;
              if (showToast && showToast.success) {
                showToast.success(row && row.Message ? row.Message : "Đã xóa template.");
              }
              $this.loadTemplates().then(function () {
                $this.isDeleting = false;
              }).catch(function () {
                $this.isDeleting = false;
              });
            },
            function (err) {
              if (showToast && showToast.error) {
                showToast.error(`${err.responseJSON ? err.responseJSON.Message : err.responseText ? err.responseText : ""}`);
              }
              $this.isDeleting = false;
            }
          );
        }
      );
    }
  }
	}
</script>