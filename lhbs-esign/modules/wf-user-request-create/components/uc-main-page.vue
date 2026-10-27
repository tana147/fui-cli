<template>
	<uc-wf-shell active-key="wf-user-request-create" title="Workflow Portal" subtitle="Khởi tạo yêu cầu ký số">
    <div class="wf-page-header" :class="{ 'wf-page-header--compact': isFreeSignWorkspaceFocus }">
      <div>
        <div class="wf-request-breadcrumb" @click="goDashboard">
          <v-icon size="16">mdi-arrow-left</v-icon>
          <span>Dashboard người dùng</span>
        </div>
        <h1>{{ pageTitle }}</h1>
        <p v-if="!isFreeSignWorkspaceFocus">Tạo yêu cầu ký theo workflow đã cấu hình, bám theo prototype ký số và dữ liệu thực tế từ hệ thống.</p>
      </div>
      <div class="d-flex align-center" :style="{ gap: isFreeSignWorkspaceFocus ? '8px' : '12px' }">
        <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isLoading" @click="initPage">
          <v-icon start>mdi-refresh</v-icon>
          Làm mới
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="grey" @click="resetWizard">
          <v-icon start>mdi-refresh-circle</v-icon>
          Khởi tạo lại
        </v-btn>
      </div>
    </div>
    <div class="wf-request-layout" :class="{ 'wf-request-layout--focus': isFreeSignWorkspaceFocus }">
      <uc-request-stepper
        v-if="!isFreeSignWorkspaceFocus"
        :wizard-steps="wizardSteps"
        :current-step="currentStep"
        :selected-definition-name="selectedDefinition ? selectedDefinition.Name : ''"
        :selected-template-name="selectedTemplateName"
        :signer-count="form.signers.length"
        :field-count="dynamicFields.length"
        :compact="isFreeSignWorkspaceFocus"
        :hide-summary="isFreeSignWorkspaceFocus"
      />
      <div class="wf-request-main">
        <div v-if="currentStep === 0" class="wf-request-panel" :class="{ 'wf-request-panel--focus': isFreeSignWorkspaceFocus }">
          <div class="wf-request-panel__header">
            <div>
              <h3>Chọn kiểu khởi tạo</h3>
              <p>Hỗ trợ cả luồng theo workflow chuẩn lẫn ký tự do cho văn bản nội bộ phát sinh ngoài quy trình.</p>
            </div>
          </div>
          <uc-request-create-mode
            :create-mode="form.createMode"
            :mode-options="createModeOptions"
            @select-mode="selectCreateMode"
          />
          <div v-if="form.createMode === 'TEMPLATE_FLOW'" class="wf-request-section-title">
            <span>Chọn loại văn bản và workflow</span>
          </div>
          <uc-request-select-workflow
            v-if="form.createMode === 'TEMPLATE_FLOW'"
            :categories="categories"
            :filtered-definitions="filteredDefinitions"
            :category-id="form.categoryId"
            :definition-id="form.definitionId"
            :is-definition-loading="isDefinitionLoading"
            @select-category="selectCategory"
            @select-definition="selectDefinition"
          />
          <div v-else class="wf-empty-state">
            Bạn đang ở chế độ ký tự do. Bước tiếp theo sẽ nhập thông tin văn bản PDF và tự thiết lập danh sách người ký.
          </div>
        </div>
        <div v-if="currentStep === 1" class="wf-request-panel" :class="{ 'wf-request-panel--focus': isFreeSignWorkspaceFocus }">
          <uc-request-document-config
            :create-mode="form.createMode"
            :form="form"
            :categories="categories"
            :signer-profiles="signerProfiles"
            :execution-engine-options="executionEngineOptions"
            :contract-provider-options="contractProviderOptions"
            :role-options="roleOptions"
            :sign-method-options="availableSignMethodOptions"
            :file-method-options="fileMethodOptions"
            :template-options="templateOptions"
            :priority-options="priorityOptions"
            :selected-template="selectedTemplate"
            :selected-template-placeholders="selectedTemplatePlaceholders"
            :dynamic-fields="dynamicFields"
            :is-upload-mode="isUploadMode"
            :file-accept="fileAccept"
            :upload-label="uploadLabel"
            :upload-sub-label="uploadSubLabel"
            @file-selected="onFileSelected"
            @preview-template="previewTemplate"
          />
        </div>
        <div v-if="currentStep === 2" class="wf-request-panel" :class="{ 'wf-request-panel--focus': isFreeSignWorkspaceFocus }">
          <uc-request-signer-config
            :create-mode="form.createMode"
            :form="form"
            :role-options="roleOptions"
            :sign-method-options="availableSignMethodOptions"
            :signer-profiles="signerProfiles"
            :require-cert-for-smartca="getEffectiveExecutionEngine() === 'SMARTCA'"
            @add-signer="addSigner"
            @remove-signer="removeSigner"
            @update-signer-role="updateSignerRole"
            @update-signer-person="updateSignerPerson"
            @signer-method-changed="onSignerMethodChanged"
          />
        </div>
        <div v-if="currentStep === 3" class="wf-request-panel" :class="{ 'wf-request-panel--focus': isFreeSignWorkspaceFocus }">
          <div class="wf-request-panel__header">
            <div>
              <h3>Xác nhận và gửi yêu cầu</h3>
              <p>Kiểm tra toàn bộ payload trước khi submit sang backend runtime của Phase 2.</p>
            </div>
          </div>
          <uc-request-summary
            :create-mode="form.createMode"
            :selected-category-name="selectedCategoryName"
            :selected-definition-name="selectedDefinition ? selectedDefinition.Name : ''"
            :selected-template-name="selectedTemplateName"
            :file-method-label="fileMethodLabel"
            :submit-payload-text="submitPayloadText"
            :form="form"
          />
        </div>
        <div class="wf-request-footer">
          <v-btn v-if="currentStep > 0" class="wf-btn" variant="outlined" color="grey" @click="prevStep">
            <v-icon start>mdi-arrow-left</v-icon>
            Quay lại
          </v-btn>
          <v-spacer />
          <v-btn v-if="currentStep > 0" class="wf-btn" variant="outlined" color="warning" :loading="isSavingDraft" @click="saveDraft">
            <v-icon start>mdi-content-save-outline</v-icon>
            Lưu tạm
          </v-btn>
          <v-btn v-if="currentStep < wizardSteps.length - 1" class="wf-btn" variant="outlined" color="primary" :disabled="!canGoNext" @click="nextStep">
            <v-icon start>mdi-arrow-right</v-icon>
            Tiếp theo
          </v-btn>
          <v-btn v-else class="wf-btn" variant="outlined" color="primary" :loading="isSubmitting" @click="submitRequest">
            <v-icon start>mdi-send</v-icon>
            Gửi yêu cầu ký
          </v-btn>
        </div>
      </div>
    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		mixins: [
    typeof window !== "undefined" && window.__WF_REQUEST_CREATE_ECONTRACT_MIXIN__ ? window.__WF_REQUEST_CREATE_ECONTRACT_MIXIN__ : {}
  ],
  data: function () {
    return {
      isLoading: false,
      isSubmitting: false,
      isSavingDraft: false,
      isDefinitionLoading: false,
      currentStep: 0,
      wizardSteps: [{ key: "category", title: "Loại văn bản", sub: "Chọn category và workflow" }, { key: "info", title: "Thông tin", sub: "Tên tài liệu và dữ liệu đầu vào" }, { key: "signer", title: "Người ký", sub: "Thứ tự và phương thức ký" }, { key: "confirm", title: "Xác nhận", sub: "Kiểm tra trước khi submit" }],
      createModeOptions: [{ value: "TEMPLATE_FLOW", title: "Theo quy trình chuẩn", icon: "mdi-sitemap-outline", description: "Dùng workflow, template, field mapping và signer mặc định đã cấu hình." }, { value: "FREE_SIGN", title: "Ký tự do", icon: "mdi-draw-pen", description: "Upload PDF trực tiếp, tự chọn người ký, phù hợp với tờ trình và biên bản nội bộ." }],
      categories: [],
      definitions: [],
      roleOptions: [],
      signerProfiles: [],
      templateOptions: [],
      selectedDefinitionDetail: null,
      executionEngineOptions: [{ title: "SmartCA nội bộ", value: "SMARTCA" }, { title: "eContract", value: "ECONTRACT" }],
      contractProviderOptions: [{ title: "VNPT eContract", value: "VNPT_ECONTRACT" }, { title: "AMIS WeSign", value: "AMIS_WESIGN" }],
      form: {
        createMode: "TEMPLATE_FLOW",
        categoryId: null,
        definitionId: null,
        title: "",
        code: "",
        description: "",
        executionEngine: "SMARTCA",
        contractProvider: "",
        fileMethod: "TEMPLATE",
        templateId: null,
        fileId: null,
        fileUrl: "",
        fileBinaryBase64: "",
        uploadedFileName: "",
        uploadedFileMime: "",
        dueDate: "",
        priority: "NORMAL",
        sequential: true,
        notifyEmail: true,
        requireOtpConfirm: false,
        signers: [],
        fieldValues: {},
        signBoxes: [],
        draftId: 0
      },
      fileMethodOptions: [{ title: "Chọn từ template có sẵn", value: "TEMPLATE" }, { title: "Tải file lên", value: "UPLOAD" }],
      priorityOptions: [{ title: "Thường", value: "NORMAL" }, { title: "Cao", value: "HIGH" }, { title: "Khẩn", value: "URGENT" }],
      signMethodOptions: ["SmartCA (Ký số)", "eContract - OTP Email", "eContract - OTP SMS", "eContract - Ký ảnh", "eContract - SmartCA App"],
      signerSeed: 0,
      econtractAuthCache: { token: "", expiredAt: 0 },
      eContractApiMap: {
        screen: "wf-user-request-create",
        authLogin: "/api/econtract/auth/login",
        createFromTemplate: "/api/econtract/contracts/create-from-template",
        createFromFile: "/api/econtract/contracts/create-from-file",
        updateSigners: "/api/econtract/contracts/update-signers",
        wesignCreateFromFile: "/api/econtract/wesign/contracts/create-from-file",
        detail: "/api/econtract/contracts/{hopDongId}/detail",
        downloadBase64: "/api/econtract/contracts/{hopDongId}/download-base64",
        mergeTemplateToPdf: "/api/pdf/merge-docx-template-to-pdf"
      }
    };
  },
  mounted: function () {
    if (typeof window !== "undefined") {
      window.__WF_ECONTRACT_SCREEN_MAP__ = window.__WF_ECONTRACT_SCREEN_MAP__ || {};
      window.__WF_ECONTRACT_SCREEN_MAP__["wf-user-request-create"] = this.eContractApiMap;
    }
    this.initPage();
  },
  computed: {
    pageTitle: function () {
      if (!this.selectedDefinition) return "Tạo yêu cầu ký mới";
      return "Tạo yêu cầu ký - " + this.selectedDefinition.Name;
    },
    filteredDefinitions: function () {
      var categoryId = this.form.categoryId;
      var rows = this.definitions.filter(function (item) {
        return !!item.IsActive;
      });
      if (!categoryId) return rows;
      return rows.filter(function (item) {
        return String(item.CategoryID) === String(categoryId);
      });
    },
    selectedDefinition: function () {
      var definitionId = this.form.definitionId;
      if (!definitionId) return null;
      for (var i = 0; i < this.definitions.length; i += 1) {
        if (String(this.definitions[i].DefinitionID) === String(definitionId)) return this.definitions[i];
      }
      return null;
    },
    selectedTemplate: function () {
      var templateId = this.form.templateId;
      if (!templateId) return null;
      for (var i = 0; i < this.templateOptions.length; i += 1) {
        if (String(this.templateOptions[i].TemplateID) === String(templateId)) return this.templateOptions[i];
      }
      return null;
    },
    selectedTemplateName: function () {
      if (this.isUploadMode) return this.form.uploadedFileName || "File upload runtime";
      if (this.form.createMode === "FREE_SIGN") return "PDF upload runtime";
      if (!this.selectedTemplate) return "Chưa chọn";
      return this.selectedTemplate.TemplateName;
    },
    selectedTemplatePlaceholders: function () {
      if (!this.selectedTemplate || !this.selectedTemplate.Placeholders) return [];
      return this.selectedTemplate.Placeholders;
    },
    selectedCategoryName: function () {
      for (var i = 0; i < this.categories.length; i += 1) {
        if (String(this.categories[i].CategoryID) === String(this.form.categoryId)) return this.categories[i].Name;
      }
      return "Chưa chọn";
    },
    dynamicFields: function () {
      return this.buildDynamicFields();
    },
    isUploadMode: function () {
      return this.form.createMode === "FREE_SIGN" || this.form.fileMethod === "UPLOAD";
    },
    fileAccept: function () {
      return this.form.createMode === "FREE_SIGN" ? ".pdf" : ".pdf,.doc,.docx,.xls,.xlsx";
    },
    uploadLabel: function () {
      if (this.form.uploadedFileName) return this.form.uploadedFileName + (this.form.fileId ? " · FileID " + this.form.fileId : "");
      return "Bấm để chọn file hoặc kéo thả vào đây";
    },
    uploadSubLabel: function () {
      if (this.form.createMode === "FREE_SIGN") return "Upload PDF vào tblFileData, hệ thống sẽ lưu FileID runtime để ký tự do.";
      return "Hỗ trợ PDF, DOCX, XLSX. Upload lên tblFileData và chỉ lưu FileID trong runtime.";
    },
    availableSignMethodOptions: function () {
      var self = this;
      if (this.getEffectiveExecutionEngine() === "ECONTRACT") {
        return this.signMethodOptions.filter(function (item) {
          return self.isEContractMethod(item);
        });
      }
      return this.signMethodOptions.filter(function (item) {
        return self.isSmartCAMethod(item);
      });
    },
    canGoNext: function () {
      if (this.currentStep === 0) return this.form.createMode === "FREE_SIGN" ? true : (!!this.form.categoryId && !!this.form.definitionId);
      if (this.currentStep === 1) {
        if (!this.form.title) return false;
        if (this.isUploadMode && !this.form.fileId) return false;
        if (this.form.createMode === "TEMPLATE_FLOW" && this.form.fileMethod === "TEMPLATE" && !this.form.templateId) return false;
        if (this.getEffectiveExecutionEngine() === "ECONTRACT" && !this.getEffectiveContractProvider()) return false;
        return true;
      }
      if (this.currentStep === 2) {
        if (this.form.createMode === "FREE_SIGN") {
          if (!this.form.signBoxes || this.form.signBoxes.length <= 0) return false;
          if ((this.buildFreeSignSignerRows() || []).length <= 0) return false;
          return true;
        }
        if (this.form.signers.length <= 0) return false;
        for (var i = 0; i < this.form.signers.length; i += 1) {
          var signer = this.form.signers[i] || {};
          var signerMethod = this.normalizeSignerMethodByEngine(signer.method, this.getEffectiveExecutionEngine());
          var profile = this.resolveSignerProfileFromSigner(signer);
          if (!String(signer.personCode || signer.roleCode || "").trim()) return false;
          if (!String(signerMethod || "").trim()) return false;
          if (this.isSmartCAMethod(signerMethod) && !this.isSignerProfileCertUsable(profile)) return false;
        }
        return true;
      }
      return true;
    },
    fileMethodLabel: function () {
      return this.form.fileMethod === "UPLOAD" ? "Tải file lên" : "Template có sẵn";
    },
    submitPayload: function () {
      return this.buildSubmitPayload();
    },
    submitPayloadText: function () {
      return JSON.stringify(this.submitPayload, null, 2);
    },
    isFreeSignWorkspaceFocus: function () {
      return this.form.createMode === "FREE_SIGN" && this.currentStep === 1;
    }
  },
  methods: {
    initPage: async function () {
      this.isLoading = true;
      try {
        this.resetWizard();
        await Promise.all([
          this.loadCategories(),
          this.loadDefinitions(),
          this.loadRoles(),
          this.loadSignerProfiles(),
          this.loadTemplates()
        ]);
        var hasLoadedDraft = await this.tryLoadDraftFromUrl();
        if (!hasLoadedDraft) await this.tryLoadDefinitionFromUrl();
      } catch (err) {
        this.showError(err);
      } finally {
        this.isLoading = false;
      }
    },
    resetWizard: function () {
      this.currentStep = 0;
      this.selectedDefinitionDetail = null;
      this.form = {
        createMode: "TEMPLATE_FLOW", categoryId: null, definitionId: null, title: "", code: "", description: "",
        executionEngine: "SMARTCA", contractProvider: "",
        fileMethod: "TEMPLATE", templateId: null, fileId: null, fileUrl: "", fileBinaryBase64: "", uploadedFileName: "", uploadedFileMime: "", dueDate: "",
        priority: "NORMAL", sequential: true, notifyEmail: true, requireOtpConfirm: false,
        signers: [], fieldValues: {}, signBoxes: [], draftId: 0
      };
    },
    loadCategories: async function () {
      var rows = await apiCallAsync("WF_Category_GetList", {});
      this.categories = this.normalizeCategories(rows);
    },
    loadDefinitions: async function () {
      var rows = await apiCallAsync("WF_Definition_GetList", { Status: "ACTIVE" });
      this.definitions = this.normalizeDefinitions(rows);
    },
    loadRoles: async function () {
      var rows = await apiCallAsync("WF_RoleMapping_GetList", {});
      this.roleOptions = this.normalizeRoles(rows);
    },
    loadSignerProfiles: async function () {
      var rows = await apiCallAsync("WF_SignerProfile_GetList", {});
      this.signerProfiles = (rows || []).filter(function (item) {
        return Number(item.IsActive || 0) === 1 && Number(item.CertIsActive || 0) === 1;
      });
    },
    loadTemplates: async function () {
      var rows = await apiCallAsync("WF_Template_GetList", {});
      this.templateOptions = this.normalizeTemplates(rows).filter(function (item) {
        return item.IsActive !== false;
      });
    },
    selectCategory: function (categoryId) {
      this.form.categoryId = categoryId;
      if (this.form.createMode !== "TEMPLATE_FLOW") return;
      if (this.selectedDefinition && String(this.selectedDefinition.CategoryID) !== String(categoryId)) {
        this.form.definitionId = null;
        this.selectedDefinitionDetail = null;
        this.form.signers = [];
        this.form.fieldValues = {};
      }
    },
    selectDefinition: async function (item) {
      if (!item) return;
      this.form.createMode = "TEMPLATE_FLOW";
      if (String(this.form.definitionId || "") !== String(item.DefinitionID || "")) {
        this.form.templateId = null;
        this.form.signers = [];
        this.form.fieldValues = {};
        this.form.signBoxes = [];
      }
      this.form.definitionId = item.DefinitionID;
      this.form.categoryId = item.CategoryID;
      this.form.title = this.form.title || item.Name;
      this.form.description = this.form.description || item.Description || "";
      this.form.code = this.form.code || item.Code;
      await this.loadDefinitionDetail(item.DefinitionID);
    },
    loadDefinitionDetail: async function (definitionId) {
      this.isDefinitionLoading = true;
      try {
        var data = await apiCallAsync("WF_Definition_GetDetail", { DefinitionID: definitionId });
        this.selectedDefinitionDetail = this.normalizeDefinitionDetail(data, definitionId);
      } catch (err) {
        this.selectedDefinitionDetail = { DefinitionID: definitionId, Version: 1, Steps: [], Fields: [] };
      } finally {
        this.isDefinitionLoading = false;
      }
      this.applyDefinitionDetail();
    },
    tryLoadDraftFromUrl: async function () {
      var draftId = this.getDraftIdFromUrl();
      if (!draftId || draftId <= 0) return false;
      await this.loadDraftDetail(draftId);
      return true;
    },
    tryLoadDefinitionFromUrl: async function () {
      var definitionId = this.getDefinitionIdFromUrl();
      var selected = null;
      if (!definitionId || definitionId <= 0) return;
      selected = (this.definitions || []).filter(function (item) {
        return Number(item && item.DefinitionID ? item.DefinitionID : 0) === Number(definitionId);
      })[0] || null;
      if (!selected) return;
      this.form.createMode = "TEMPLATE_FLOW";
      this.form.categoryId = selected.CategoryID || null;
      await this.selectDefinition(selected);
    },
    getDraftIdFromUrl: function () {
      var query = window.location.search || "";
      var match = query.match(/[?&]draftId=(\d+)/i);
      if (!match || !match[1]) return 0;
      return Number(match[1]) || 0;
    },
    getDefinitionIdFromUrl: function () {
      var query = window.location.search || "";
      var match = query.match(/[?&]definitionId=(\d+)/i);
      if (!match || !match[1]) return 0;
      return Number(match[1]) || 0;
    },
    loadDraftDetail: async function (draftId) {
      var data = await apiCallAsync("WF_RequestDraft_GetDetail", { DraftID: draftId });
      this.applyDraftDetail(data, draftId);
      if (showToast && showToast.success) showToast.success("Đã tải draft #" + draftId + " thành công.");
    },
    applyDraftDetail: function (data, draftId) {
      var header = data && data[0] && data[0][0] ? data[0][0] : null;
      var fields = data && data[1] ? data[1] : [];
      var signers = data && data[2] ? data[2] : [];
      var boxes = data && data[3] ? data[3] : [];
      var i = 0;
      var values = {};
      if (!header) return;
      this.form.createMode = header.CreateMode || "FREE_SIGN";
      this.form.categoryId = header.CategoryID || null;
      this.form.definitionId = header.DefinitionID || null;
      this.form.title = header.DraftName || "";
      this.form.code = header.ReferenceCode || "";
      this.form.description = header.Description || "";
      this.form.executionEngine = header.ExecutionEngine || "SMARTCA";
      this.form.contractProvider = this.normalizeContractProvider(header.ContractProvider);
      this.form.fileMethod = header.FileMethod || "UPLOAD";
      this.form.templateId = header.TemplateID || null;
      this.form.fileId = header.SourceFileID || null;
      this.form.fileUrl = header.SourceFileUrl || header.FileUrl || "";
      this.form.fileBinaryBase64 = "";
      this.form.uploadedFileName = header.SourceFileName || "";
      this.form.uploadedFileMime = header.SourceFileMime || header.SourceContentType || "";
      this.form.dueDate = header.DueDate || "";
      this.form.priority = header.Priority || "NORMAL";
      this.form.sequential = header.Sequential === 1 || header.Sequential === true;
      this.form.notifyEmail = header.NotifyEmail === 1 || header.NotifyEmail === true;
      this.form.requireOtpConfirm = header.RequireOtpConfirm === 1 || header.RequireOtpConfirm === true;
      this.form.draftId = draftId;
      for (i = 0; i < fields.length; i += 1) values[fields[i].FieldName] = fields[i].FieldValue || "";
      this.form.fieldValues = values;
      this.form.signers = this.normalizeDraftSigners(signers);
      this.form.signBoxes = this.normalizeDraftBoxes(boxes);
      this.syncExecutionEngineFromSigners();
      this.syncSignBoxesWithSigners();
      this.currentStep = this.form.createMode === "FREE_SIGN" ? 1 : 3;
    },
    ensureDraftFileBinaryLoaded: async function () {
      var fileId = String(this.form.fileId || "").trim();
      var binary = "";
      if (!fileId) return;
      if (String(this.form.fileBinaryBase64 || "").trim()) return;
      binary = await this.tryReadFileBinaryById(fileId);
      if (!binary) return;
      this.form.fileBinaryBase64 = binary;
      if (!this.form.fileUrl) this.form.fileUrl = "https://file.zentea.vn/iotdev/FileData/" + fileId;
    },
    tryReadFileBinaryById: async function (fileId) {
      var normalized = String(fileId || "").trim();
      var pickBinary = function (res) {
        var row = null;
        if (res && res.data && res.data[0] && res.data[0][0]) row = res.data[0][0];
        else if (res && res[0]) row = res[0];
        else if (res && res.FileID) row = res;
        if (!row) return "";
        return row.BinaryContent || row.FILE_CONTENT || row.File_Binary || row.FILE_BINARY || row.FileBinaryBase64 || row.FileBinary || "";
      };
      if (!normalized) return "";
      try {
        return pickBinary(await apiCallAsync("FileData_GetByID", { FileID: normalized, ID: normalized }));
      } catch (err1) {
      }
      return "";
    },
    normalizeDraftSigners: function (rows) {
      var output = [];
      var i = 0;
      var role = null;
      var profile = null;
      var signerValue = "";
      for (i = 0; i < rows.length; i += 1) {
        signerValue = String(rows[i].SignerValue || "").trim();
        role = this.findRoleByCode(signerValue);
        profile = this.resolveSignerProfileBySignerValue(signerValue) || this.resolveSignerProfileByPersonName(rows[i].PersonName || "");
        output.push({
          localId: "draft-signer-" + (rows[i].DraftSignerID || (i + 1)),
          stepOrder: rows[i].StepOrder || null,
          stepName: rows[i].StepName || "Ký tự do",
          roleCode: role ? role.RoleCode : signerValue,
          roleName: role ? role.RoleName : signerValue,
          personName: rows[i].PersonName || (profile ? (profile.FullName || "") : "") || (role ? role.DefaultPersonName : ""),
          personCode: profile ? (profile.EmployeeCode || profile.Email || signerValue) : (rows[i].SignerType === "USER" ? signerValue : ""),
          departmentName: rows[i].DepartmentName || (profile ? (profile.DepartmentName || "") : "") || (role ? role.DepartmentName : ""),
          method: this.formatSignMethod(rows[i].SignMethod),
          system: rows[i].ExecutionEngine || "smartca",
          signerType: rows[i].SignerType || "ROLE"
        });
      }
      return output;
    },
    normalizeDraftBoxes: function (rows) {
      var output = [];
      var i = 0;
      for (i = 0; i < rows.length; i += 1) {
        output.push({
          BoxOrder: rows[i].BoxOrder || (i + 1),
          PageNo: rows[i].PageNo || 1,
          PosX: Number(rows[i].PosX || 0),
          PosY: Number(rows[i].PosY || 0),
          Width: Number(rows[i].BoxWidth || rows[i].Width || 18),
          Height: Number(rows[i].BoxHeight || rows[i].Height || 8),
          StepOrder: rows[i].StepOrder || null,
          SignerOrder: rows[i].SignerOrder || null,
          SignerType: rows[i].SignerType || "ROLE",
          SignerValue: rows[i].SignerValue || "",
          PersonName: rows[i].PersonName || "",
          DepartmentName: rows[i].DepartmentName || "",
          SignMethod: this.formatSignMethod(rows[i].SignMethod),
          ExecutionEngine: rows[i].ExecutionEngine || this.form.executionEngine || "SMARTCA",
          ContractProvider: rows[i].ContractProvider || this.form.contractProvider || "",
          LabelText: rows[i].LabelText || ""
        });
      }
      return output;
    },
    applyDefinitionDetail: function () {
      var detail = this.selectedDefinitionDetail;
      var firstTemplateId = null;
      if (!detail) return;
      if (detail.Steps && detail.Steps.length > 0) {
        for (var i = 0; i < detail.Steps.length; i += 1) {
          if (detail.Steps[i].TemplateID && !firstTemplateId) firstTemplateId = detail.Steps[i].TemplateID;
        }
      }
      if (!this.form.templateId && firstTemplateId) this.form.templateId = firstTemplateId;
      this.form.signers = this.buildSignersFromDetail(detail);
      this.form.fieldValues = this.buildFieldValues(detail.Fields || []);
      this.syncExecutionEngineFromSigners();
      this.syncSignBoxesWithSigners();
    },
    selectCreateMode: function (value) {
      this.form.createMode = value || "TEMPLATE_FLOW";
      this.form.fileMethod = value === "FREE_SIGN" ? "UPLOAD" : "TEMPLATE";
      this.form.fileId = null;
      this.form.uploadedFileName = "";
      this.form.uploadedFileMime = "";
      this.form.templateId = null;
      this.form.signers = [];
      this.form.fieldValues = {};
      this.form.signBoxes = [];
      if (value === "FREE_SIGN") {
        this.form.definitionId = null;
        this.selectedDefinitionDetail = null;
        this.form.title = this.form.title || "Văn bản ký tự do";
      }
      this.syncExecutionEngineFromSigners();
      this.syncSignBoxesWithSigners();
    },
    buildFieldValues: function (fields) {
      var values = {};
      var i = 0;
      for (i = 0; i < fields.length; i += 1) {
        values[fields[i].FieldName] = fields[i].DefaultValue || "";
      }
      return values;
    },
    normalizePlaceholderToken: function (value) {
      var token = String(value || "").trim();
      if (!token) return "";
      token = token.replace(/^#{3}\s*/g, "").replace(/\s*#{3}$/g, "");
      token = token.replace(/^\{\s*\}\s*/g, "").trim();
      token = token.replace(/^#+/g, "").replace(/#+$/g, "").trim();
      token = token.replace(/^\{\{+\s*/g, "").replace(/\s*\}\}+$/g, "").trim();
      token = token.replace(/^:+/g, "").replace(/:+$/g, "").trim();
      return token;
    },
    toFieldLabelFromName: function (fieldName) {
      var text = String(fieldName || "").replace(/[_\-]+/g, " ").trim();
      if (!text) return "Trường dữ liệu";
      return text.replace(/\b\w/g, function (c) { return c.toUpperCase(); });
    },
    buildDynamicFields: function () {
      var detailFields = this.selectedDefinitionDetail && this.selectedDefinitionDetail.Fields ? this.selectedDefinitionDetail.Fields : [];
      var placeholders = this.selectedTemplatePlaceholders || [];
      var map = {};
      var rows = [];
      var i = 0;
      var name = "";
      var row = null;
      for (i = 0; i < detailFields.length; i += 1) {
        name = String(detailFields[i].FieldName || "").trim();
        if (!name) continue;
        if (this.parseTemplateSignaturePlaceholder(name)) continue;
        map[name] = true;
        rows.push({
          FieldName: name,
          FieldLabel: detailFields[i].FieldLabel || this.toFieldLabelFromName(name),
          FieldType: detailFields[i].FieldType || "text",
          DefaultValue: detailFields[i].DefaultValue || "",
          IsRequired: detailFields[i].IsRequired === true || detailFields[i].IsRequired === 1
        });
      }
      for (i = 0; i < placeholders.length; i += 1) {
        name = this.normalizePlaceholderToken(placeholders[i]);
        if (!name || map[name]) continue;
        if (this.parseTemplateSignaturePlaceholder(name)) continue;
        map[name] = true;
        row = {
          FieldName: name,
          FieldLabel: this.toFieldLabelFromName(name),
          FieldType: "text",
          DefaultValue: "",
          IsRequired: false,
          IsPlaceholderOnly: true
        };
        rows.push(row);
      }
      return rows;
    },
    syncFieldValuesByDynamicFields: function () {
      var source = this.form && this.form.fieldValues ? this.form.fieldValues : {};
      var next = {};
      var i = 0;
      var field = null;
      var key = "";
      for (i = 0; i < this.dynamicFields.length; i += 1) {
        field = this.dynamicFields[i] || {};
        key = String(field.FieldName || "").trim();
        if (!key) continue;
        if (Object.prototype.hasOwnProperty.call(source, key)) next[key] = source[key];
        else next[key] = field.DefaultValue || "";
      }
      this.form.fieldValues = next;
    },
    buildSignersFromDetail: function (detail) {
      var rows = [];
      var i = 0;
      var j = 0;
      var role = null;
      var profile = null;
      var personName = "";
      if (!detail || !detail.Steps) return rows;
      for (i = 0; i < detail.Steps.length; i += 1) {
        if (!detail.Steps[i].Signers || detail.Steps[i].Signers.length === 0) continue;
        for (j = 0; j < detail.Steps[i].Signers.length; j += 1) {
          role = this.findRoleByCode(detail.Steps[i].Signers[j].SignerValue);
          personName = role ? role.DefaultPersonName : detail.Steps[i].Signers[j].SignerValue;
          profile = this.resolveSignerProfileByPersonName(personName);
          rows.push({
            localId: "seed-" + detail.Steps[i].StepOrder + "-" + j,
            stepOrder: detail.Steps[i].StepOrder,
            stepName: detail.Steps[i].StepName,
            roleCode: detail.Steps[i].Signers[j].SignerValue,
            roleName: role ? role.RoleName : detail.Steps[i].Signers[j].SignerValue,
            personName: personName || "",
            personCode: profile ? (profile.EmployeeCode || profile.Email || "") : "",
            departmentName: role ? role.DepartmentName : (profile ? (profile.DepartmentName || "") : ""),
            method: this.formatSignMethod(detail.Steps[i].Signers[j].SignMethod),
            system: detail.Steps[i].SignSystem || "",
            signerType: detail.Steps[i].Signers[j].SignerType || "ROLE"
          });
        }
      }
      return rows;
    },
    buildSubmitPayload: function () {
      var detail = this.selectedDefinitionDetail;
      var fieldRows = [];
      var signerRows = this.form.createMode === "FREE_SIGN" ? this.buildFreeSignSignerRows() : [];
      var signBoxRows = [];
      var signerMetaRows = [];
      var engine = this.getEffectiveExecutionEngine();
      var provider = this.getEffectiveContractProvider();
      var i = 0;
      var signer = null;
      var signerMethod = "";
      var isSmartCA = false;
      var profile = null;
      var signerValue = "";
      for (i = 0; i < this.dynamicFields.length; i += 1) {
        fieldRows.push({
          FieldName: this.dynamicFields[i].FieldName,
          FieldLabel: this.dynamicFields[i].FieldLabel,
          Value: this.form.fieldValues[this.dynamicFields[i].FieldName] || ""
        });
      }
      if (this.form.createMode !== "FREE_SIGN") {
        for (i = 0; i < this.form.signers.length; i += 1) {
          signer = this.form.signers[i] || {};
          signerMethod = this.normalizeSignerMethodByEngine(signer.method, engine);
          isSmartCA = this.isSmartCAMethod(signerMethod);
          profile = this.resolveSignerProfileFromSigner(signer);
          signerValue = isSmartCA
            ? this.resolveSmartCASignerValue(profile, signer)
            : (String(signer.roleCode || signer.personCode || "").trim());
          signerMetaRows.push({
            SignOrder: i + 1,
            IsSmartCA: isSmartCA,
            ProfileFound: !!profile,
            Profile: profile || null,
            PersonName: signer.personName || "",
            RoleCode: signer.roleCode || "",
            SignMethod: signerMethod,
            SignerValue: signerValue
          });
          signerRows.push({
            SignOrder: i + 1,
            StepOrder: signer.stepOrder || null,
            StepName: signer.stepName || "",
            SignerType: isSmartCA ? "USER" : (signer.signerType || "ROLE"),
            SignerValue: signerValue,
            PersonName: (profile && profile.FullName) || signer.personName || "",
            SignMethod: signerMethod,
            DepartmentName: (profile && profile.DepartmentName) || signer.departmentName || ""
          });
        }
      }
      signBoxRows = this.normalizeSignBoxesForPayload(signerRows);
      if (this.form.createMode === "FREE_SIGN") {
        signBoxRows = this.alignFreeSignBoxSignerOrders(signBoxRows, signerRows);
      } else if (this.form.createMode === "TEMPLATE_FLOW") {
        if (!signBoxRows || signBoxRows.length <= 0) {
          signBoxRows = this.buildTemplateSignBoxesFromPlaceholders(signerRows);
        }
      }
      return {
        CreateMode: this.form.createMode,
        DefinitionID: this.form.definitionId || 0,
        CategoryID: this.form.categoryId || null,
        InstanceName: this.form.title,
        ReferenceCode: this.form.code,
        Description: this.form.description,
        ExecutionEngine: engine,
        ContractProvider: provider,
        FileMethod: this.form.fileMethod,
        TemplateID: this.form.templateId || null,
        FileID: this.form.fileId || null,
        UploadFileName: this.form.uploadedFileName || "",
        DueDate: this.form.dueDate || null,
        Priority: this.form.priority,
        Sequential: this.form.sequential,
        NotifyEmail: this.form.notifyEmail,
        RequireOtpConfirm: this.form.requireOtpConfirm,
        DefinitionVersion: detail ? detail.Version : null,
        FieldValues: fieldRows,
        Signers: signerRows,
        SignBoxes: signBoxRows,
        SignerMeta: signerMetaRows
      };
    },
    nextStep: function () {
      if (!this.canGoNext) {
        if (showToast && showToast.error) showToast.error("Vui lòng hoàn thiện thông tin trước khi sang bước tiếp theo.");
        return;
      }
      if (this.currentStep === 2 && this.form.createMode === "FREE_SIGN" && (!this.form.signBoxes || this.form.signBoxes.length <= 0)) {
        if (showToast && showToast.error) showToast.error("Ký tự do cần tối thiểu một box ký trước khi xác nhận.");
        return;
      }
      this.currentStep += 1;
    },
    prevStep: function () {
      if (this.currentStep === 0) return;
      this.currentStep -= 1;
    },
    addSigner: function () {
      var role = this.findFirstAvailableRole();
      var method = this.resolveDefaultSignerMethodByEngine(this.getEffectiveExecutionEngine());
      var profile = this.resolveSignerProfileByPersonName(role ? role.DefaultPersonName : "");
      this.signerSeed += 1;
      this.form.signers.push({
        localId: "manual-" + this.signerSeed,
        stepOrder: null,
        stepName: this.form.createMode === "FREE_SIGN" ? "Ký tự do" : "Ad-hoc",
        roleCode: role ? role.RoleCode : "",
        roleName: role ? role.RoleName : "",
        personName: role ? role.DefaultPersonName : "",
        personCode: profile ? (profile.EmployeeCode || profile.Email || "") : "",
        departmentName: role ? role.DepartmentName : (profile ? (profile.DepartmentName || "") : ""),
        method: method,
        system: this.isEContractMethod(method) ? "econtract" : "smartca",
        signerType: "ROLE"
      });
      this.syncExecutionEngineFromSigners();
      this.syncSignBoxesWithSigners();
    },
    removeSigner: function (index) {
      this.form.signers.splice(index, 1);
      this.syncExecutionEngineFromSigners();
      this.syncSignBoxesWithSigners();
    },
    updateSignerRole: function (signer) {
      var role = this.findRoleByCode(signer.roleCode);
      var profile = null;
      if (!role) return;
      signer.roleName = role.RoleName;
      if (!String(signer.personName || "").trim()) signer.personName = role.DefaultPersonName;
      profile = this.resolveSignerProfileByPersonName(signer.personName || role.DefaultPersonName || "");
      if (profile) {
        signer.personName = profile.FullName || signer.personName || role.DefaultPersonName;
        signer.personCode = profile.EmployeeCode || profile.Email || "";
        signer.departmentName = profile.DepartmentName || role.DepartmentName || "";
      } else {
        signer.departmentName = role.DepartmentName;
      }
      this.syncSignBoxesWithSigners();
    },
    updateSignerPerson: function (payload) {
      var signer = payload && payload.signer ? payload.signer : null;
      var personCode = payload && payload.personCode ? String(payload.personCode).trim() : "";
      var profile = null;
      if (!signer) return;
      if (!personCode) {
        signer.personCode = "";
        this.syncSignBoxesWithSigners();
        return;
      }
      profile = this.resolveSignerProfileBySignerValue(personCode);
      if (!profile) {
        signer.personCode = personCode;
        this.syncSignBoxesWithSigners();
        return;
      }
      signer.personCode = profile.EmployeeCode || profile.Email || personCode;
      signer.personName = profile.FullName || signer.personName || "";
      if (!signer.departmentName) signer.departmentName = profile.DepartmentName || "";
      if (this.getEffectiveExecutionEngine() === "SMARTCA") {
        if (this.isSignerProfileCertUsable(profile)) {
          signer.method = this.resolveDefaultSignerMethodByEngine("SMARTCA");
        } else {
          signer.method = "";
          if (showToast && showToast.error) {
            showToast.error("Người ký chưa có chứng thư số SmartCA hợp lệ.");
          }
        }
      }
      this.syncSignBoxesWithSigners();
    },
    onSignerMethodChanged: function () {
      this.syncExecutionEngineFromSigners();
      this.syncSignBoxesWithSigners();
    },
    onFileSelected: async function (event) {
      var files = event && event.target ? event.target.files : null;
      if (!files || !files[0]) return;
      await this.uploadSelectedFile(files[0]);
      if (event.target) event.target.value = "";
    },
    uploadSelectedFile: function (file) {
      var self = this;
      var previousUploadedName = this.form.uploadedFileName || "";
      return new Promise(function (resolve, reject) {
        var reader = new FileReader();
        reader.onload = function (evt) {
          var dataUrl = evt && evt.target ? evt.target.result : "";
          var base64 = "";
          var payload = null;
          if (!dataUrl || String(dataUrl).indexOf(",") < 0) {
            self.showError({ message: "Không đọc được nội dung file để upload." });
            reject(new Error("READ_FILE_FAILED"));
            return;
          }
          base64 = String(dataUrl).split(",")[1] || "";
          apiCall("UPLOAD_FileData_Base64", {
            FileBase64: base64,
            FileName: file.name || "document.pdf",
            FileContentType: file.type || "application/pdf"
          }, function (res) {
            var fileRow = self.pickUploadedFileRow(res);
            if (!fileRow || !fileRow.FileID) {
              self.showError({ message: "Không nhận được FileID sau khi upload." });
              reject(new Error("MISSING_FILE_ID"));
              return;
            }
            self.form.fileId = fileRow.FileID;
            self.form.fileUrl = "https://file.zentea.vn/iotdev/FileData/" + fileRow.FileID;
            self.form.fileBinaryBase64 = fileRow.FileBinaryBase64 || "";
            self.form.uploadedFileName = fileRow.FileName || file.name;
            self.form.uploadedFileMime = file.type || "";
            self.syncTitleFromUploadedFile(self.form.uploadedFileName, previousUploadedName);
            if (showToast && showToast.success) showToast.success("Upload file thành công. FileID: " + fileRow.FileID);
            resolve(fileRow);
          }, function (err) {
            self.showError(err);
            reject(err);
          });
        };
        reader.onerror = function () {
          self.showError({ message: "Không đọc được file PDF từ máy người dùng." });
          reject(new Error("READ_FILE_FAILED"));
        };
        reader.readAsDataURL(file);
      });
    },
    pickUploadedFileRow: function (payload) {
      var queue = [];
      var visited = [];
      var row = null;
      var node = null;
      var i = 0;
      var key = "";
      var fileId = "";
      var matchedKey = "";
      if (!payload || typeof payload !== "object") return null;
      queue.push(payload);
      while (queue.length > 0) {
        node = queue.shift();
        if (typeof node === "string") {
          try {
            node = JSON.parse(node);
          } catch (ignoreParseErr) {
            node = null;
          }
        }
        if (!node || typeof node !== "object") continue;
        if (visited.indexOf(node) >= 0) continue;
        visited.push(node);
        fileId = String(node.FileID || node.FILE_ID || node.fileId || "").trim();
        if (!fileId && !Array.isArray(node)) {
          for (matchedKey in node) {
            if (!Object.prototype.hasOwnProperty.call(node, matchedKey)) continue;
            if (/^file[_-]?id$/i.test(matchedKey)) {
              fileId = String(node[matchedKey] || "").trim();
              if (fileId) break;
            }
          }
        }
        if (fileId) {
          row = node;
          if (!row.FileID && !row.fileId && !row.FILE_ID) row.FileID = fileId;
          break;
        }
        if (Array.isArray(node)) {
          for (i = 0; i < node.length; i += 1) {
            if (node[i] && typeof node[i] === "object") queue.push(node[i]);
          }
        } else {
          if (node.Files && Array.isArray(node.Files)) {
            for (i = 0; i < node.Files.length; i += 1) {
              if (node.Files[i] && typeof node.Files[i] === "object") queue.push(node.Files[i]);
            }
          }
          if (node.Result && typeof node.Result === "object") queue.push(node.Result);
          for (key in node) {
            if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
            if (node[key] && typeof node[key] === "object") queue.push(node[key]);
          }
        }
      }
      if (!row) return null;
      return {
        FileID: row.FileID || row.FILE_ID || row.fileId || 0,
        FileName: row.FileName || row.FILE_NAME || row.fileName || "",
        FileUrl: row.FileUrl || row.FILE_URL || row.fileUrl || "",
        FileBinaryBase64: row.File_Binary || row.FILE_BINARY || row.FileBinary || row.fileBinary || row.BinaryContent || row.FILE_CONTENT || ""
      };
    },
    extractFirstFileIdFromAnyObject: function (payload) {
      var queue = [];
      var visited = [];
      var node = null;
      var i = 0;
      var key = "";
      var value = "";
      var id = "";
      if (payload == null) return "";
      queue.push(payload);
      while (queue.length > 0) {
        node = queue.shift();
        if (typeof node === "string") {
          id = this.extractFileIdFromUrl(node);
          if (id) return id;
          try {
            node = JSON.parse(node);
          } catch (ignoreErr) {
            node = null;
          }
        }
        if (!node || typeof node !== "object") continue;
        if (visited.indexOf(node) >= 0) continue;
        visited.push(node);
        if (Array.isArray(node)) {
          for (i = 0; i < node.length; i += 1) queue.push(node[i]);
          continue;
        }
        for (key in node) {
          if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
          value = node[key];
          if (/^file[_-]?id$/i.test(key)) {
            id = String(value || "").trim();
            if (id) return id;
          }
          if (/^file(url|_url)$/i.test(key)) {
            id = this.extractFileIdFromUrl(value);
            if (id) return id;
          }
          if (value && typeof value === "object") queue.push(value);
          else if (typeof value === "string" && value.indexOf("/FileData/") >= 0) {
            id = this.extractFileIdFromUrl(value);
            if (id) return id;
          }
        }
      }
      return "";
    },
    syncTitleFromUploadedFile: function (fileName, previousUploadedName) {
      var normalizedTitle = this.deriveTitleFromFileName(fileName);
      var currentTitle = String(this.form.title || "").trim();
      var fallbackTitle = this.deriveTitleFromFileName(previousUploadedName);
      if (!normalizedTitle) return;
      if (!currentTitle || currentTitle === "Văn bản ký tự do" || (fallbackTitle && currentTitle === fallbackTitle)) {
        this.form.title = normalizedTitle;
      }
    },
    deriveTitleFromFileName: function (fileName) {
      var name = String(fileName || "").trim();
      if (!name) return "";
      name = name.replace(/\.[^.]+$/, "");
      name = name.replace(/[_-]+/g, " ");
      name = name.replace(/\s+/g, " ").trim();
      if (!name) return "";
      return name.replace(/\b([a-zA-ZÀ-ỹ])([^\s]*)/g, function (match, first, rest) {
        return first.toUpperCase() + rest;
      });
    },
    normalizeSignBoxesForPayload: function (signerRows) {
      var rows = this.form.signBoxes || [];
      var output = [];
      var i = 0;
      var normalized = null;
      this.syncSignBoxesWithSigners(signerRows || []);
      for (i = 0; i < rows.length; i += 1) {
        normalized = this.normalizeSingleSignBox(rows[i], i);
        output.push(normalized);
      }
      return output;
    },
    buildFreeSignSignerRows: function () {
      var rows = this.normalizeSignBoxesForPayload([]);
      var map = {};
      var result = [];
      var i = 0;
      var key = "";
      for (i = 0; i < rows.length; i += 1) {
        key = String(rows[i].SignerValue || "").trim().toUpperCase();
        if (!key) continue;
        if (map[key]) continue;
        map[key] = true;
        result.push({
          SignOrder: result.length + 1,
          StepOrder: 1,
          StepName: "Ký tự do",
          SignerType: rows[i].SignerType || "USER",
          SignerValue: rows[i].SignerValue || "",
          PersonName: rows[i].PersonName || "",
          SignMethod: rows[i].SignMethod || "SmartCA (Ký số)",
          DepartmentName: rows[i].DepartmentName || ""
        });
      }
      return result;
    },
    alignFreeSignBoxSignerOrders: function (boxes, signers) {
      var map = {};
      var output = (boxes || []).map(function (item) { return Object.assign({}, item); });
      var i = 0;
      var key = "";
      for (i = 0; i < (signers || []).length; i += 1) {
        key = String(signers[i].SignerValue || "").trim().toUpperCase();
        if (!key) continue;
        map[key] = i + 1;
      }
      for (i = 0; i < output.length; i += 1) {
        key = String(output[i].SignerValue || "").trim().toUpperCase();
        output[i].SignerOrder = map[key] || output[i].SignerOrder || null;
        output[i].StepOrder = 1;
      }
      return output;
    },
    normalizeSingleSignBox: function (row, index) {
      var signerIndex = Number(row && row.SignerOrder ? row.SignerOrder : 0) - 1;
      var signer = signerIndex >= 0 && signerIndex < this.form.signers.length ? this.form.signers[signerIndex] : null;
      var width = row && row.BoxWidth != null ? row.BoxWidth : row && row.Width != null ? row.Width : 18;
      var height = row && row.BoxHeight != null ? row.BoxHeight : row && row.Height != null ? row.Height : 8;
      var engine = this.getEffectiveExecutionEngine();
      var provider = this.getEffectiveContractProvider();
      return {
        BoxOrder: index + 1,
        PageNo: Number(row && row.PageNo ? row.PageNo : 1) || 1,
        PosX: Number(row && row.PosX != null ? row.PosX : 0) || 0,
        PosY: Number(row && row.PosY != null ? row.PosY : 0) || 0,
        BoxWidth: Number(width) || 18,
        BoxHeight: Number(height) || 8,
        Width: Number(width) || 18,
        Height: Number(height) || 8,
        StepOrder: row && row.StepOrder ? row.StepOrder : signer ? (signer.stepOrder || (signerIndex + 1)) : null,
        SignerOrder: row && row.SignerOrder ? row.SignerOrder : signer ? (signerIndex + 1) : null,
        SignerType: row && row.SignerType ? row.SignerType : signer ? (signer.signerType || "ROLE") : "ROLE",
        SignerValue: row && row.SignerValue ? row.SignerValue : signer ? (signer.roleCode || "") : "",
        PersonName: row && row.PersonName ? row.PersonName : signer ? (signer.personName || signer.roleName || "") : "",
        DepartmentName: row && row.DepartmentName ? row.DepartmentName : signer ? (signer.departmentName || "") : "",
        SignMethod: row && row.SignMethod ? row.SignMethod : signer ? (signer.method || "SmartCA (Ký số)") : "SmartCA (Ký số)",
        ExecutionEngine: engine,
        ContractProvider: provider,
        LabelText: row && row.LabelText ? row.LabelText : ""
      };
    },
    syncSignBoxesWithSigners: function (signerRows) {
      var rows = this.form.signBoxes || [];
      var sourceSigners = signerRows && signerRows.length ? signerRows : (this.form.signers || []);
      var templateRows = [];
      var currentLabels = {};
      var needsTemplateRefresh = false;
      var i = 0;
      var signerIndex = -1;
      var signer = null;
      var engine = this.getEffectiveExecutionEngine();
      var provider = this.getEffectiveContractProvider();
      if (this.form.createMode === "FREE_SIGN") {
        for (i = 0; i < rows.length; i += 1) {
          rows[i].BoxOrder = i + 1;
          rows[i].Width = rows[i].BoxWidth != null ? rows[i].BoxWidth : rows[i].Width;
          rows[i].Height = rows[i].BoxHeight != null ? rows[i].BoxHeight : rows[i].Height;
          rows[i].ExecutionEngine = engine || rows[i].ExecutionEngine || "SMARTCA";
          rows[i].ContractProvider = provider || "";
          if (!rows[i].StepOrder) rows[i].StepOrder = 1;
        }
        return;
      }
      if (this.form.createMode === "TEMPLATE_FLOW") {
        templateRows = this.buildTemplateSignBoxesFromPlaceholders(null, sourceSigners);
        if (templateRows.length > 0) {
          if (rows.length !== templateRows.length) {
            needsTemplateRefresh = true;
          } else {
            for (i = 0; i < rows.length; i += 1) {
              currentLabels[String(rows[i] && rows[i].LabelText || "").trim().toLowerCase()] = true;
            }
            for (i = 0; i < templateRows.length; i += 1) {
              if (!currentLabels[String(templateRows[i] && templateRows[i].LabelText || "").trim().toLowerCase()]) {
                needsTemplateRefresh = true;
                break;
              }
            }
          }
        }
        if ((rows.length <= 0 || needsTemplateRefresh) && templateRows.length > 0) {
          rows = templateRows;
          this.form.signBoxes = rows;
        }
      }
      for (i = 0; i < rows.length; i += 1) {
        rows[i].BoxOrder = i + 1;
        rows[i].Width = rows[i].BoxWidth != null ? rows[i].BoxWidth : rows[i].Width;
        rows[i].Height = rows[i].BoxHeight != null ? rows[i].BoxHeight : rows[i].Height;
        signerIndex = Number(rows[i].SignerOrder || 0) - 1;
        if (sourceSigners.length <= 0) {
          rows[i].SignerOrder = null;
          rows[i].StepOrder = null;
          rows[i].SignerValue = "";
          rows[i].PersonName = "";
          rows[i].DepartmentName = "";
          continue;
        }
        if (signerIndex < 0 || signerIndex >= sourceSigners.length) signerIndex = 0;
        signer = sourceSigners[signerIndex];
        rows[i].SignerOrder = signerIndex + 1;
        rows[i].StepOrder = signer.StepOrder || signer.stepOrder || (signerIndex + 1);
        rows[i].SignerType = signer.SignerType || signer.signerType || rows[i].SignerType || "ROLE";
        rows[i].SignerValue = signer.SignerValue || signer.roleCode || signer.personCode || "";
        rows[i].PersonName = signer.PersonName || signer.personName || signer.roleName || "";
        rows[i].DepartmentName = signer.DepartmentName || signer.departmentName || "";
        rows[i].SignMethod = signer.SignMethod || signer.method || rows[i].SignMethod || "SmartCA (Ký số)";
        rows[i].ExecutionEngine = engine || rows[i].ExecutionEngine || "SMARTCA";
        rows[i].ContractProvider = provider || "";
      }
    },
    getTemplateSignaturePlaceholderDefs: function () {
      var placeholders = this.selectedTemplatePlaceholders || [];
      var result = [];
      var i = 0;
      var parsed = null;
      for (i = 0; i < placeholders.length; i += 1) {
        parsed = this.parseTemplateSignaturePlaceholder(placeholders[i]);
        if (parsed) result.push(parsed);
      }
      result.sort(function (a, b) {
        if (a.signerOrder !== b.signerOrder) return a.signerOrder - b.signerOrder;
        return (a.pageNo || 1) - (b.pageNo || 1);
      });
      return result;
    },
    parseTemplateSignaturePlaceholder: function (value) {
      var token = this.normalizePlaceholderToken(value);
      var lower = token.toLowerCase();
      var orderMatch = null;
      var pageMatch = null;
      var xMatch = null;
      var yMatch = null;
      var wMatch = null;
      var hMatch = null;
      if (!lower) return null;
      if (!/^sig(n|nature)?(?:[_-]|\d)/.test(lower) && !/^ky(?:[_-]|\d)/.test(lower)) return null;

      orderMatch = lower.match(/(?:^|[_-])(sig(?:n|nature)?|ky)[_-]?(\d+)/);
      var order = 0;
      if (orderMatch && orderMatch[2]) {
        order = Number(orderMatch[2]);
      } else {
        var digitsMatch = lower.match(/\d+/);
        if (digitsMatch) {
          order = Number(digitsMatch[0]);
        } else if (lower.indexOf("hieu_truong") >= 0 || lower.indexOf("principal") >= 0 || lower.indexOf("gd") >= 0 || lower.indexOf("giam_doc") >= 0) {
          order = 1;
        } else {
          order = 1;
        }
      }
      if (!order) return null;

      pageMatch = lower.match(/(?:^|[_-])p(?:age)?[_-]?(\d+)/);
      xMatch = lower.match(/(?:^|[_-])x[_-]?(\d+(?:\.\d+)?)/);
      yMatch = lower.match(/(?:^|[_-])y[_-]?(\d+(?:\.\d+)?)/);
      wMatch = lower.match(/(?:^|[_-])w[_-]?(\d+(?:\.\d+)?)/);
      hMatch = lower.match(/(?:^|[_-])h[_-]?(\d+(?:\.\d+)?)/);
      return {
        token: token,
        signerOrder: order,
        pageNo: pageMatch && pageMatch[1] ? (Number(pageMatch[1]) || 1) : 1,
        posX: xMatch && xMatch[1] ? Number(xMatch[1]) : null,
        posY: yMatch && yMatch[1] ? Number(yMatch[1]) : null,
        width: wMatch && wMatch[1] ? Number(wMatch[1]) : null,
        height: hMatch && hMatch[1] ? Number(hMatch[1]) : null
      };
    },
    buildDefaultTemplateSignBoxLayout: function (signerOrder) {
      var order = Number(signerOrder || 1);
      var index = order > 0 ? (order - 1) : 0;
      var col = index % 2;
      var row = Math.floor(index / 2);
      var width = 32;
      var height = 9;
      var gapX = 9;
      var gapY = 11;
      var startX = 14;
      var startY = 68;
      return {
        pageNo: 1,
        posX: startX + (col * (width + gapX)),
        posY: startY + (row * gapY),
        width: width,
        height: height
      };
    },
    resolveTemplateSignBoxStepOrder: function (signer, signerIndex) {
      var stepOrder = Number(signer && (signer.StepOrder != null ? signer.StepOrder : signer.stepOrder));
      if (Number.isFinite(stepOrder) && stepOrder > 0) return stepOrder;
      return 1;
    },
    buildTemplateSignBoxesFromPlaceholders: function (payloadSigners, sourceSigners) {
      var defs = this.getTemplateSignaturePlaceholderDefs();
      var signers = payloadSigners && payloadSigners.length ? payloadSigners : (sourceSigners || []);
      var rows = [];
      var i = 0;
      var def = null;
      var signerIndex = 0;
      var signer = null;
      var layout = null;
      if (!defs.length || !signers.length) return rows;
      for (i = 0; i < defs.length; i += 1) {
        def = defs[i];
        signerIndex = Number(def.signerOrder || 0) - 1;
        if (signerIndex < 0 || signerIndex >= signers.length) continue;
        signer = signers[signerIndex];
        layout = this.buildDefaultTemplateSignBoxLayout(def.signerOrder);
        rows.push({
          BoxOrder: rows.length + 1,
          PageNo: Number(def.pageNo || layout.pageNo || 1),
          PosX: def.posX != null ? Number(def.posX) : Number(layout.posX),
          PosY: def.posY != null ? Number(def.posY) : Number(layout.posY),
          BoxWidth: def.width != null ? Number(def.width) : Number(layout.width),
          BoxHeight: def.height != null ? Number(def.height) : Number(layout.height),
          Width: def.width != null ? Number(def.width) : Number(layout.width),
          Height: def.height != null ? Number(def.height) : Number(layout.height),
          StepOrder: this.resolveTemplateSignBoxStepOrder(signer, signerIndex),
          SignerOrder: signer.signerOrder || signer.SignOrder || (signerIndex + 1),
          SignerType: signer.SignerType || signer.signerType || "USER",
          SignerValue: signer.SignerValue || signer.personCode || signer.roleCode || "",
          PersonName: signer.PersonName || signer.personName || signer.roleName || "",
          DepartmentName: signer.DepartmentName || signer.departmentName || "",
          SignMethod: signer.SignMethod || signer.method || "SmartCA (Ký số)",
          ExecutionEngine: this.getEffectiveExecutionEngine(),
          ContractProvider: this.getEffectiveContractProvider(),
          LabelText: def.token
        });
      }
      return rows;
    },
    previewTemplate: function () {
      var template = this.selectedTemplate;
      if (!template) {
        if (showToast && showToast.error) showToast.error("Chưa chọn template để xem.");
        return;
      }
      if (template.FileUrl) {
        window.open(template.FileUrl, "_blank");
        return;
      }
      if (showToast && showToast.error) showToast.error("Template chưa có đường dẫn file để xem.");
    },
    validateTemplateFlowSigners: function (signers, signerMeta) {
      var rows = signers || [];
      var metaRows = signerMeta || [];
      var i = 0;
      var missingCertSigners = [];
      var certMessage = "";
      for (i = 0; i < rows.length; i += 1) {
        if (!String(rows[i].SignerValue || "").trim()) return "Danh sách người ký có dòng chưa chọn role/người ký.";
        if (!String(rows[i].SignMethod || "").trim()) return "Danh sách người ký có dòng chưa chọn phương thức ký.";
        if (!this.isSmartCAMethod(rows[i].SignMethod)) continue;
        if (!metaRows[i] || !metaRows[i].ProfileFound || !this.isSignerProfileCertUsable(metaRows[i].Profile)) {
          missingCertSigners.push((rows[i].PersonName || rows[i].SignerValue || ("dòng " + (i + 1))));
        }
      }
      if (missingCertSigners.length > 0) {
        certMessage = "Signer SmartCA chưa có CTS hợp lệ: " + missingCertSigners.join(", ");
        certMessage += ". Vui lòng chọn người ký có CertSerial active và còn hạn.";
        return certMessage;
      }
      if ((this.getTemplateSignaturePlaceholderDefs() || []).length <= 0) {
        return "Template chưa có placeholder chữ ký. Thêm token dạng sig_1, sig_2 ... (có thể mở rộng sig_1_p1_x14_y68_w32_h9).";
      }
      return "";
    },
    saveDraft: function () {
      var self = this;
      var payload = this.buildSubmitPayload();
      delete payload.SignerMeta;
      payload.DraftID = this.form.draftId || 0;
      this.isSavingDraft = true;
      apiCall("WF_RequestDraft_Save", payload, function (res) {
        var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null;
        self.isSavingDraft = false;
        if (row && row.DraftID) {
          self.form.draftId = row.DraftID;
          self.syncDraftUrl(row.DraftID);
        }
        if (showToast && showToast.success) showToast.success(row && row.Message ? row.Message : "Lưu draft thành công.");
      }, function (err) {
        self.isSavingDraft = false;
        self.showError(err);
      });
    },
    submitWorkflowRequest: function (payload) {
      return new Promise(function (resolve, reject) {
        apiCall("WF_Request_Create", payload, function (res) { resolve(res); }, function (err) { reject(err); });
      });
    },
    extractFileIdFromUrl: function (value) {
      var raw = String(value || "").trim();
      var match = null;
      if (!raw) return "";
      match = raw.match(/\/FileData\/([A-Za-z0-9-]+)/i);
      if (match && match[1]) return String(match[1]).trim();
      if (/^[A-Za-z0-9-]{24,40}$/.test(raw)) return raw;
      return "";
    },
    isDocxFileType: function (fileName, fileType) {
      var lowerType = String(fileType || "").toLowerCase();
      var lowerName = String(fileName || "").toLowerCase();
      if (lowerType.indexOf("docx") >= 0 || lowerType.indexOf("word") >= 0 || lowerType === "doc") return true;
      return /\.docx?$/.test(lowerName);
    },
    buildTemplateMergeFields: function (payload) {
      var rows = payload && payload.FieldValues ? payload.FieldValues : [];
      var fields = [];
      var i = 0;
      for (i = 0; i < rows.length; i += 1) {
        fields.push({
          Key: String(rows[i].FieldName || "").trim(),
          Value: rows[i].Value == null ? "" : String(rows[i].Value)
        });
      }
      return fields.filter(function (item) { return !!item.Key; });
    },
    pickMergeTemplatePdfRow: function (payload) {
      var queue = [];
      var visited = [];
      var node = null;
      var i = 0;
      var key = "";
      var value = "";
      if (!payload || typeof payload !== "object") return null;
      queue.push(payload);
      while (queue.length > 0) {
        node = queue.shift();
        if (!node || typeof node !== "object") continue;
        if (visited.indexOf(node) >= 0) continue;
        visited.push(node);
        value = String(node.PdfBase64 || node.pdfBase64 || node.FileBase64 || node.fileBase64 || "").trim();
        if (value) {
          return {
            FileName: node.FileName || node.fileName || node.OutputFileName || node.outputFileName || "runtime-template.pdf",
            PdfBase64: value,
            SignatureAnchors: this.extractSignatureAnchorsFromAnyObject(node)
          };
        }
        if (Array.isArray(node)) {
          for (i = 0; i < node.length; i += 1) {
            if (node[i] && typeof node[i] === "object") queue.push(node[i]);
          }
        } else {
          for (key in node) {
            if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
            if (node[key] && typeof node[key] === "object") queue.push(node[key]);
          }
        }
      }
      return null;
    },
    extractSignatureAnchorsFromAnyObject: function (payload) {
      var queue = [];
      var visited = [];
      var node = null;
      var i = 0;
      var key = "";
      var anchors = [];
      if (!payload || typeof payload !== "object") return anchors;
      queue.push(payload);
      while (queue.length > 0) {
        node = queue.shift();
        if (!node || typeof node !== "object") continue;
        if (visited.indexOf(node) >= 0) continue;
        visited.push(node);
        if (Array.isArray(node)) {
          for (i = 0; i < node.length; i += 1) {
            if (node[i] && typeof node[i] === "object") queue.push(node[i]);
          }
          continue;
        }
        if (Array.isArray(node.SignatureAnchors)) {
          anchors = anchors.concat(node.SignatureAnchors);
        }
        if (Array.isArray(node.signatureAnchors)) {
          anchors = anchors.concat(node.signatureAnchors);
        }
        for (key in node) {
          if (!Object.prototype.hasOwnProperty.call(node, key)) continue;
          if (node[key] && typeof node[key] === "object") queue.push(node[key]);
        }
      }
      return anchors;
    },
    buildTemplateSignBoxesFromMergeAnchors: function (anchors, payloadSigners) {
      var rows = [];
      var signers = payloadSigners || [];
      var i = 0;
      var anchor = null;
      var signerIndex = -1;
      var signer = null;
      var posX = 0;
      var posY = 0;
      var width = 32;
      var height = 9;
      if (!anchors || !anchors.length || !signers.length) return rows;
      for (i = 0; i < anchors.length; i += 1) {
        anchor = anchors[i] || {};
        signerIndex = Number(anchor.SignerOrder || anchor.signerOrder || 0) - 1;
        if (signerIndex < 0 || signerIndex >= signers.length) continue;
        signer = signers[signerIndex];
        posX = Number(anchor.PosX != null ? anchor.PosX : anchor.posX);
        posY = Number(anchor.PosY != null ? anchor.PosY : anchor.posY);
        width = Number(anchor.BoxWidth != null ? anchor.BoxWidth : anchor.boxWidth);
        height = Number(anchor.BoxHeight != null ? anchor.BoxHeight : anchor.boxHeight);
        if (!Number.isFinite(posX)) posX = 0;
        if (!Number.isFinite(posY)) posY = 0;
        if (!Number.isFinite(width) || width <= 0) width = 32;
        if (!Number.isFinite(height) || height <= 0) height = 9;
        rows.push({
          BoxOrder: rows.length + 1,
          PageNo: Number(anchor.PageNo || anchor.pageNo || 1) || 1,
          PosX: posX,
          PosY: posY,
          BoxWidth: width,
          BoxHeight: height,
          Width: width,
          Height: height,
          StepOrder: this.resolveTemplateSignBoxStepOrder(signer, signerIndex),
          SignerOrder: signer.signerOrder || signer.SignOrder || (signerIndex + 1),
          SignerType: signer.SignerType || signer.signerType || "USER",
          SignerValue: signer.SignerValue || signer.personCode || signer.roleCode || "",
          PersonName: signer.PersonName || signer.personName || signer.roleName || "",
          DepartmentName: signer.DepartmentName || signer.departmentName || "",
          SignMethod: signer.SignMethod || signer.method || "SmartCA (Ký số)",
          ExecutionEngine: this.getEffectiveExecutionEngine(),
          ContractProvider: this.getEffectiveContractProvider(),
          LabelText: anchor.Token || anchor.token || ""
        });
      }
      rows.sort(function (a, b) {
        if (a.SignerOrder !== b.SignerOrder) return a.SignerOrder - b.SignerOrder;
        return a.BoxOrder - b.BoxOrder;
      });
      for (i = 0; i < rows.length; i += 1) rows[i].BoxOrder = i + 1;
      return rows;
    },
    resolveTemplateSourceFileId: function (template) {
      var id = "";
      if (!template) return "";
      id = String(template.FileID || template.SourceFileID || template.FileId || "").trim();
      if (id) return id;
      id = this.extractFileIdFromUrl(template.FileUrl || template.FilePath || template.Path || "");
      return id;
    },
    prepareRuntimeTemplateFile: async function (payload) {
      var template = this.selectedTemplate;
      var sourceFileId = "";
      var sourceFileName = "";
      var sourceFileBinary = "";
      var uploadRes = null;
      var uploadRow = null;
      var mergeRes = null;
      var mergeRow = null;
      var runtimeFileName = "";
      if (!payload || payload.CreateMode !== "TEMPLATE_FLOW" || payload.FileMethod !== "TEMPLATE") return payload;
      if (!template) throw new Error("Chưa chọn template runtime.");
      sourceFileId = this.resolveTemplateSourceFileId(template);
      if (!sourceFileId) throw new Error("Template chưa có FileID nguồn để tạo runtime.");
      sourceFileName = String(template.FileName || template.TemplateName || "template.docx").trim();
      if (this.isDocxFileType(sourceFileName, template.FileType)) {
        sourceFileBinary = String(await this.tryReadFileBinaryById(sourceFileId) || "").trim();
        if (!sourceFileBinary) throw new Error("Không đọc được binary template DOCX để merge dữ liệu runtime.");
        mergeRes = await this.econtractRequest("POST", this.eContractApiMap.mergeTemplateToPdf, {
          FileBase64: sourceFileBinary,
          FileName: sourceFileName,
          Fields: this.buildTemplateMergeFields(payload)
        }, "");
        mergeRow = this.pickMergeTemplatePdfRow(mergeRes);
        if (!mergeRow || !String(mergeRow.PdfBase64 || "").trim()) {
          throw new Error("Merge template DOCX sang PDF chưa trả dữ liệu file.");
        }
        if ((!mergeRow.SignatureAnchors || mergeRow.SignatureAnchors.length <= 0) && mergeRes) {
          mergeRow.SignatureAnchors = this.extractSignatureAnchorsFromAnyObject(mergeRes);
        }
        if (mergeRow.SignatureAnchors && mergeRow.SignatureAnchors.length > 0) {
          payload.SignBoxes = this.buildTemplateSignBoxesFromMergeAnchors(mergeRow.SignatureAnchors, payload.Signers || []);
          this.form.signBoxes = payload.SignBoxes.slice();
        }
        runtimeFileName = String(mergeRow.FileName || sourceFileName || "runtime-template.pdf").trim();
        uploadRes = await apiCallAsync("UPLOAD_FileData_Base64", {
          FileBase64: String(mergeRow.PdfBase64 || "").trim(),
          FileName: runtimeFileName,
          FileContentType: "application/pdf"
        });
        uploadRow = this.pickUploadedFileRow(uploadRes);
        if ((!uploadRow || !uploadRow.FileID) && uploadRes) {
          uploadRow = this.pickUploadedFileRow({ data: uploadRes }) || uploadRow;
        }
        if ((!uploadRow || !uploadRow.FileID) && mergeRes) {
          uploadRow = this.pickUploadedFileRow(mergeRes) || uploadRow;
        }
        if (!uploadRow || !uploadRow.FileID) {
          var fallbackFileId = this.extractFirstFileIdFromAnyObject(uploadRes) || this.extractFirstFileIdFromAnyObject(mergeRes);
          if (fallbackFileId) {
            uploadRow = {
              FileID: fallbackFileId,
              FileName: runtimeFileName,
              FileUrl: "https://file.zentea.vn/iotdev/FileData/" + fallbackFileId,
              FileBinaryBase64: ""
            };
          }
        }
        if (!uploadRow || !uploadRow.FileID) throw new Error("Không nhận được FileID runtime sau khi upload PDF merge. [parser-v2]");
        payload.FileMethod = "UPLOAD";
        payload.FileID = uploadRow.FileID;
        payload.UploadFileName = uploadRow.FileName || runtimeFileName;
        this.form.fileMethod = "UPLOAD";
        this.form.fileId = uploadRow.FileID;
        this.form.fileUrl = "https://file.zentea.vn/iotdev/FileData/" + uploadRow.FileID;
        this.form.uploadedFileName = uploadRow.FileName || runtimeFileName;
        this.form.uploadedFileMime = "application/pdf";
        this.form.fileBinaryBase64 = "";
        return payload;
      }
      payload.FileMethod = "UPLOAD";
      payload.FileID = sourceFileId;
      payload.UploadFileName = sourceFileName || "runtime-template.pdf";
      this.form.fileMethod = "UPLOAD";
      this.form.fileId = sourceFileId;
      if (!this.form.fileUrl) this.form.fileUrl = "https://file.zentea.vn/iotdev/FileData/" + sourceFileId;
      if (!this.form.uploadedFileName) this.form.uploadedFileName = payload.UploadFileName;
      if (!this.form.uploadedFileMime) this.form.uploadedFileMime = "application/pdf";
      return payload;
    },
    submitRequest: async function () {
      var payload = this.buildSubmitPayload();
      var self = this;
      var econtractResult = null;
      if (!payload.InstanceName) {
        if (showToast && showToast.error) showToast.error("Tên yêu cầu ký không được để trống.");
        this.currentStep = 1;
        return;
      }
      if (payload.CreateMode === "TEMPLATE_FLOW" && !payload.DefinitionID) {
        if (showToast && showToast.error) showToast.error("Vui lòng chọn workflow trước khi gửi yêu cầu ký.");
        this.currentStep = 0;
        return;
      }
      if (payload.CreateMode === "TEMPLATE_FLOW" && payload.FileMethod === "TEMPLATE" && !payload.TemplateID) {
        if (showToast && showToast.error) showToast.error("Vui lòng chọn template trước khi gửi yêu cầu ký.");
        this.currentStep = 1;
        return;
      }
      if (this.isUploadMode && !payload.FileID) {
        if (showToast && showToast.error) showToast.error("Vui lòng upload file trước khi gửi yêu cầu ký.");
        this.currentStep = 1;
        return;
      }
      if (payload.CreateMode === "FREE_SIGN" && (!payload.SignBoxes || payload.SignBoxes.length <= 0)) {
        if (showToast && showToast.error) showToast.error("Ký tự do cần tối thiểu một box ký trước khi gửi yêu cầu.");
        this.currentStep = 1;
        return;
      }
      if (payload.CreateMode === "FREE_SIGN" && payload.ExecutionEngine === "SMARTCA") {
        if (!payload.Signers || payload.Signers.length <= 0) {
          if (showToast && showToast.error) showToast.error("Vui lòng gán người ký cho từng box trước khi gửi.");
          this.currentStep = 1;
          return;
        }
        if ((payload.SignBoxes || []).some(function (box) { return !box.SignerValue || String(box.SignerType || "").toUpperCase() !== "USER"; })) {
          if (showToast && showToast.error) showToast.error("Mỗi box ký nội bộ phải gắn 1 người dùng cụ thể có chứng thư số.");
          this.currentStep = 1;
          return;
        }
      }
      if (payload.CreateMode === "TEMPLATE_FLOW") {
        var signerValidateMessage = this.validateTemplateFlowSigners(payload.Signers, payload.SignerMeta);
        if (signerValidateMessage) {
          if (showToast && showToast.error) showToast.error(signerValidateMessage);
          this.currentStep = 2;
          return;
        }
      }
      if (payload.ExecutionEngine === "ECONTRACT" && !payload.ContractProvider) {
        if (showToast && showToast.error) showToast.error("Yêu cầu dùng eContract phải chọn nhà cung cấp trước khi gửi.");
        this.currentStep = 1;
        return;
      }
      this.isSubmitting = true;
      try {
        delete payload.SignerMeta;
        payload = await this.prepareRuntimeTemplateFile(payload);
        if (payload.ExecutionEngine === "ECONTRACT") {
          econtractResult = await this.submitToEcontract(payload);
          if (econtractResult && Number(econtractResult.hopDongId || 0) > 0) {
            if (!String(payload.ReferenceCode || "").trim()) payload.ReferenceCode = "ECONTRACT-" + econtractResult.hopDongId;
            payload.Description = (payload.Description ? payload.Description + "\n" : "") + "[eContractHopDongID:" + econtractResult.hopDongId + "]";
          } else if (econtractResult && econtractResult.provider === "AMIS_WESIGN" && String(econtractResult.documentId || "").trim()) {
            payload.Description = (payload.Description ? payload.Description + "\n" : "") + "[eContractDocumentID:" + String(econtractResult.documentId || "").trim() + "]";
          }
        }
        var res = await this.submitWorkflowRequest(payload);
        var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null;
        self.isSubmitting = false;
        if (showToast && showToast.success) showToast.success(row && row.Message ? row.Message : "Tạo yêu cầu ký thành công.");
        if (showAlert) showAlert("Đã tạo yêu cầu ký", "InstanceID: " + (row && row.InstanceID ? row.InstanceID : "N/A") + "\n" + "Trạng thái: " + (row && row.Status ? row.Status : "RUNNING") + "\n" + "Bước hiện tại: " + (row && row.CurrentStepOrder ? row.CurrentStepOrder : "-"));
        self.resetWizard();
        if (row && row.InstanceID) window.location.href = "/wf-user-request-detail?id=" + row.InstanceID;
        else window.location.href = "/wf-dashboard";
      } catch (err) {
        self.isSubmitting = false;
        self.showError(err);
      }
    },
    goDashboard: function () {
      window.location.href = "/wf-dashboard";
    },
    syncDraftUrl: function (draftId) {
      var url = null;
      if (!draftId || !window || !window.history || !window.location) return;
      url = new URL(window.location.href);
      url.searchParams.set("draftId", String(draftId));
      window.history.replaceState({}, "", url.pathname + url.search + url.hash);
    },
    findRoleByCode: function (roleCode) {
      var i = 0;
      for (i = 0; i < this.roleOptions.length; i += 1) {
        if (this.roleOptions[i].RoleCode === roleCode) return this.roleOptions[i];
      }
      return null;
    },
    findFirstAvailableRole: function () {
      var i = 0;
      var used = {};
      for (i = 0; i < this.form.signers.length; i += 1) used[this.form.signers[i].roleCode] = true;
      for (i = 0; i < this.roleOptions.length; i += 1) {
        if (!used[this.roleOptions[i].RoleCode]) return this.roleOptions[i];
      }
      if (this.roleOptions.length > 0) return this.roleOptions[0];
      return null;
    },
    normalizeCategories: function (rows) {
      return (rows || []).map(function (item, index) {
        return {
          CategoryID: item.CategoryID,
          Code: item.Code || ("CAT_" + (index + 1)),
          Name: item.Name || item.CategoryName || "Khác",
          Icon: item.Icon || "mdi-shape-outline",
          Color: item.Color || "var(--wf-primary)",
          Description: item.Description || ""
        };
      });
    },
    normalizeDefinitions: function (rows) {
      return (rows || []).map(function (item) {
        return {
          DefinitionID: item.DefinitionID,
          Code: item.Code,
          Name: item.Name,
          Description: item.Description || "",
          CategoryID: item.CategoryID,
          CategoryName: item.CategoryName || "",
          CategoryColor: item.CategoryColor || "",
          Version: item.Version || 1,
          IsActive: item.IsActive === true || item.IsActive === 1,
          StepCount: item.StepCount || 0,
          ActiveInstances: item.ActiveInstances || 0,
          NotifyEmail: item.NotifyEmail === true || item.NotifyEmail === 1
        };
      });
    },
    normalizeRoles: function (rows) {
      return (rows || []).map(function (item) {
        return {
          RoleCode: item.RoleCode,
          RoleName: item.RoleName,
          DefaultPersonName: item.DefaultPersonName || "",
          DepartmentName: item.DepartmentName || "",
          IsActive: item.IsActive === true || item.IsActive === 1
        };
      }).filter(function (item) {
        return item.IsActive;
      });
    },
    normalizeTemplates: function (rows) {
      return (rows || []).map(function (item) {
        var placeholders = [];
        if (item.Placeholders && Array.isArray(item.Placeholders)) placeholders = item.Placeholders;
        else if (item.PlaceholderJSON) {
          try {
            placeholders = JSON.parse(item.PlaceholderJSON);
          } catch (err) {
            placeholders = [];
          }
        }
        return {
          TemplateID: item.TemplateID,
          TemplateName: item.TemplateName,
          FileName: item.FileName || "",
          FileType: item.FileType || "",
          FileID: item.FileID || item.SourceFileID || "",
          FileUrl: item.FileUrl || item.SourceFileUrl || item.Path || "",
          Placeholders: placeholders
        };
      });
    },
    normalizeDefinitionDetail: function (data, definitionId) {
      var definitionRows = data && data[0] ? data[0] : [];
      var stepRows = data && data[1] ? data[1] : [];
      var fieldRows = data && data[2] ? data[2] : [];
      var definition = definitionRows.length > 0 ? definitionRows[0] : {};
      var stepMap = {};
      var i = 0;
      for (i = 0; i < stepRows.length; i += 1) {
        stepRows[i].Signers = [];
        stepMap[stepRows[i].StepDefID] = stepRows[i];
      }
      if (data && data[3]) {
        for (i = 0; i < data[3].length; i += 1) {
          if (stepMap[data[3][i].StepDefID]) stepMap[data[3][i].StepDefID].Signers.push(data[3][i]);
        }
      }
      return {
        DefinitionID: definitionId,
        Version: definition.Version || 1,
        Steps: stepRows,
        Fields: fieldRows
      };
    },
    formatSignMethod: function (value) {
      var map = {
        smartca: "SmartCA (Ký số)",
        otp_email: "eContract - OTP Email",
        otp_sms: "eContract - OTP SMS",
        image: "eContract - Ký ảnh"
      };
      return map[value] || value || "SmartCA (Ký số)";
    },
    isEContractMethod: function (value) {
      var method = String(value || "").toLowerCase();
      if (!method) return false;
      if (method.indexOf("econtract") >= 0) return true;
      if (method.indexOf("otp") >= 0) return true;
      if (method.indexOf("ký ảnh") >= 0) return true;
      if (method.indexOf("image") >= 0) return true;
      return false;
    },
    isSmartCAMethod: function (value) {
      var method = String(value || "").toLowerCase();
      if (!method) return false;
      return method.indexOf("smartca") >= 0 && method.indexOf("econtract") < 0;
    },
    resolveDefaultSignerMethodByEngine: function (engine) {
      var normalized = this.normalizeEngineValue(engine);
      var i = 0;
      if (normalized === "ECONTRACT") {
        for (i = 0; i < this.signMethodOptions.length; i += 1) {
          if (this.isEContractMethod(this.signMethodOptions[i])) return this.signMethodOptions[i];
        }
        return "eContract - OTP Email";
      }
      for (i = 0; i < this.signMethodOptions.length; i += 1) {
        if (this.isSmartCAMethod(this.signMethodOptions[i])) return this.signMethodOptions[i];
      }
      return "SmartCA (Ký số)";
    },
    normalizeSignerMethodByEngine: function (method, engine) {
      var normalized = this.normalizeEngineValue(engine);
      var current = String(method || "").trim();
      if (normalized === "ECONTRACT") {
        if (this.isEContractMethod(current)) return current;
        return this.resolveDefaultSignerMethodByEngine("ECONTRACT");
      }
      if (this.isSmartCAMethod(current)) return current;
      return this.resolveDefaultSignerMethodByEngine("SMARTCA");
    },
    enforceSignerMethodsByEngine: function (engine) {
      var normalized = this.normalizeEngineValue(engine);
      var i = 0;
      var nextMethod = "";
      for (i = 0; i < this.form.signers.length; i += 1) {
        nextMethod = this.normalizeSignerMethodByEngine(this.form.signers[i].method, normalized);
        this.form.signers[i].method = nextMethod;
        this.form.signers[i].system = this.isEContractMethod(nextMethod) ? "econtract" : "smartca";
      }
    },
    normalizeEngineValue: function (value) {
      var engine = String(value || "SMARTCA").toUpperCase();
      if (engine !== "ECONTRACT") engine = "SMARTCA";
      return engine;
    },
    detectEngineFromSigners: function () {
      var i = 0;
      for (i = 0; i < this.form.signers.length; i += 1) {
        if (this.isEContractMethod(this.form.signers[i].method)) return "ECONTRACT";
      }
      return "SMARTCA";
    },
    syncExecutionEngineFromSigners: function () {
      var detected = this.detectEngineFromSigners();
      if (detected === "ECONTRACT") {
        this.form.executionEngine = "ECONTRACT";
      } else {
        this.form.executionEngine = this.normalizeEngineValue(this.form.executionEngine);
      }
      if (this.form.executionEngine !== "ECONTRACT") this.form.contractProvider = "";
    },
    getEffectiveExecutionEngine: function () {
      var detected = this.detectEngineFromSigners();
      var selected = this.normalizeEngineValue(this.form.executionEngine);
      if (detected === "ECONTRACT") return "ECONTRACT";
      return selected;
    },
    getEffectiveContractProvider: function () {
      var engine = this.getEffectiveExecutionEngine();
      if (engine !== "ECONTRACT") return "";
      return this.normalizeContractProvider(this.form.contractProvider);
    },
    normalizeContractProvider: function (value) {
      var provider = String(value || "").trim().toUpperCase();
      if (!provider) return "";
      if (provider === "VNPT") return "VNPT_ECONTRACT";
      if (provider === "AMIS" || provider === "WESIGN") return "AMIS_WESIGN";
      if (provider !== "VNPT_ECONTRACT" && provider !== "AMIS_WESIGN") return "";
      return provider;
    },
    showError: function (err) {
      var message = "";
      if (err && err.responseJSON && err.responseJSON.Message) message = err.responseJSON.Message;
      else if (err && err.responseText) message = err.responseText;
      else if (err && err.message) message = err.message;
      else message = "Không tải được dữ liệu khởi tạo yêu cầu ký.";
      if (showToast && showToast.error) showToast.error(message);
    }
  },
  watch: {
    "form.executionEngine": function (value) {
      this.enforceSignerMethodsByEngine(value);
      this.syncExecutionEngineFromSigners();
      this.syncSignBoxesWithSigners();
    },
    "form.templateId": function () {
      if (this.form.createMode !== "TEMPLATE_FLOW") return;
      this.form.signBoxes = [];
      this.syncSignBoxesWithSigners();
    },
    dynamicFields: {
      handler: function () {
        this.syncFieldValuesByDynamicFields();
      },
      deep: true
    }
  }
	}
</script>