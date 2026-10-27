<template>
	<div class="wf-request-detail-container" style="background: #f8fafc; min-height: 100vh;">
    <div class="wf-page-header wf-request-detail-header">
      <div>
        <div class="wf-request-detail-back" @click="goBack">
          <v-icon size="16">mdi-arrow-left</v-icon>
          Quay lại chi tiết Kanban
        </div>
        <div class="wf-request-detail-title-row">
          <h1>{{ overview.InstanceName || 'Chi tiết yêu cầu ký' }}</h1>
          <v-chip size="x-small" color="primary" variant="tonal" class="wf-chip-rounded">
            {{ formatStatusText(overview.Status) }}
          </v-chip>
        </div>
        <p v-if="detailSubTitle">{{ detailSubTitle }}</p>
      </div>
      <div class="d-flex align-center" style="gap: 12px;">
        <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isLoading" @click="loadDetail">
          <v-icon start>mdi-refresh</v-icon>
          Làm mới
        </v-btn>
        <v-btn v-if="shouldSyncEcontract()" class="wf-btn" variant="outlined" color="primary"
          :loading="isEcontractSyncing" @click="syncEcontractRuntime(false)">
          <v-icon start>mdi-cloud-sync-outline</v-icon>
          {{ externalSyncButtonText }}
        </v-btn>
        <v-btn v-if="canDownloadSignedExternalDocument" class="wf-btn" variant="outlined" color="primary"
          @click="downloadSignedExternalDocument">
          <v-icon start>mdi-download</v-icon>
          Tải file đã ký
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="goCreateAnother">
          <v-icon start>mdi-plus</v-icon>
          Tạo yêu cầu mới
        </v-btn>
      </div>
    </div>

    <div v-if="isLoading" class="wf-empty-state">
      Đang tải chi tiết yêu cầu ký...
    </div>

    <div v-else-if="!overview.InstanceID" class="wf-empty-state">
      Không tìm thấy dữ liệu yêu cầu ký.
    </div>

    <div v-else>
      <div class="wf-request-sign-workspace">
        <div class="wf-tcard wf-request-sign-main-card">
          <div class="wf-request-sign-main-toolbar">
            <div class="wf-request-sign-main-title">
              <div class="wf-request-sign-main-title__name">{{ currentTemplateName }}</div>
              <div class="wf-request-sign-main-title__meta">Trang {{ previewPageNo }}</div>
            </div>
            <v-btn class="wf-btn" variant="outlined" color="primary" size="small" :disabled="!documentViewUrl"
              @click="previewDocument">
              <v-icon start size="14">mdi-open-in-new</v-icon>
              Mở toàn màn hình
            </v-btn>
          </div>
          <div class="wf-request-sign-main-body">
            <uc-request-sign-canvas ref="signCanvasRef" :file-url="documentViewUrl" :sign-boxes="canvasSignBoxes"
              :active-page="previewPageNo" :selected-box-id="selectedPreviewBoxId"
              @update-active-page="onCanvasActivePageChange" @select-box="onCanvasSelectBox"></uc-request-sign-canvas>
          </div>
        </div>

        <div class="wf-request-sign-side">
          <div class="wf-tcard wf-request-detail-card">
            <div class="wf-tcard-toolbar">
              <h3>Thao tác</h3>
            </div>

            <div class="wf-request-action-status">
              <div class="wf-request-action-status__title">{{ formatStatusText(overview.Status) }}</div>
              <div class="wf-request-action-status__sub">{{ currentActionSubText }}</div>
            </div>

            <div class="wf-request-action-meta">
              <div class="wf-info-row"><span class="label">Người xử lý</span><span class="value">{{
                  overview.CurrentSignerPersonName || '-' }}</span></div>
              <div class="wf-info-row"><span class="label">Phương thức</span><span class="value">{{
                  formatMethod(overview.CurrentSignerMethod || overview.CurrentSignSystem) }}</span></div>
              <div class="wf-info-row"><span class="label">Kênh ký</span><span class="value">{{ signingChannelDisplay
                  }}</span></div>
            </div>

            <div v-if="canShowActionPanel || showEcontractTrackingPanel" class="wf-request-action-panel">
              <div class="wf-request-action-mode-card">
                <div class="wf-request-action-mode-card__title">{{ actionModeCardTitle }}</div>
                <div v-if="currentActionMode === 'SMARTCA'" class="wf-request-form-grid">
                  <v-text-field :model-value="smartcaCertDisplayText" variant="outlined" density="compact"
                    label="Chứng thư đã duyệt" readonly />
                </div>
                <uc-request-external-tracking v-else-if="currentActionMode === 'ECONTRACT'"
                  :document-id-label="externalDocumentIdLabel" :document-id-value="econtractHopDongIdDisplay"
                  :contract-status-text="econtractContractStatusDisplay" :sign-status-text="econtractSignStatusDisplay"
                  :last-sync-text="econtractLastSyncDisplay" :provider-text="currentExternalProviderText"
                  :tracking-help-text="econtractTrackingHelpText" />
                <div v-else-if="currentActionMode === 'OTP'" class="wf-request-form-grid">
                  <v-text-field v-model="actionForm.otpCode" variant="outlined" density="compact" label="Mã OTP" />
                </div>
              </div>
              <div v-if="currentActionMode !== 'ECONTRACT'" class="wf-request-action-buttons">
                <v-btn v-if="canSignCurrentAction" class="wf-btn" variant="outlined" color="primary"
                  :loading="isActing || isSmartcaCalling || smartcaActionLock"
                  :disabled="isActing || isSmartcaCalling || smartcaActionLock || isSignActionBlocked"
                  @click="signRequest">
                  <v-icon start>{{ actionPrimaryIcon }}</v-icon>
                  {{ actionPrimaryText }}
                </v-btn>
                <v-btn v-if="canRejectCurrentAction" class="wf-btn" variant="outlined" color="error"
                  :disabled="isActing || isSmartcaCalling || smartcaActionLock || isRejectActionBlocked"
                  @click="showRejectBox = !showRejectBox">
                  <v-icon start>mdi-close-circle-outline</v-icon>
                  Từ chối
                </v-btn>
              </div>
            </div>

            <div v-if="showRejectBox && canRejectCurrentAction" class="wf-request-reject-box">
              <div class="wf-request-reject-box__title">Lý do từ chối</div>
              <v-textarea v-model="rejectReason" variant="outlined" density="compact" rows="3" hide-details
                placeholder="Nhập lý do từ chối..." />
              <div class="d-flex mt-3" style="gap: 10px;">
                <v-btn class="wf-btn" variant="outlined" color="grey" :disabled="isActing" @click="cancelReject">
                  <v-icon start>mdi-arrow-left</v-icon>
                  Hủy
                </v-btn>
                <v-btn class="wf-btn" variant="outlined" color="error" :loading="isActing"
                  :disabled="!normalizeRejectReason(rejectReason) || isActing || isRejectActionBlocked"
                  @click="rejectRequest">
                  <v-icon start>mdi-send</v-icon>
                  Gửi từ chối
                </v-btn>
              </div>
            </div>

            <div v-if="!canShowActionPanel && !showEcontractTrackingPanel" class="wf-empty-state">
              Bạn chưa có thao tác ký ở bước hiện tại.
            </div>
          </div>

          <div class="wf-tcard wf-request-detail-card">
            <div class="wf-tcard-toolbar">
              <h3>Thông tin cơ bản</h3>
            </div>
            <div class="wf-request-detail-doc-info wf-request-detail-doc-info--basic">
              <div class="wf-info-row"><span class="label">Workflow</span><span class="value">{{ overview.DefinitionName
                  || '-' }}</span></div>
              <div class="wf-info-row"><span class="label">Bước hiện tại</span><span class="value">{{
                  overview.CurrentStepName || '-' }}</span></div>
              <div class="wf-info-row"><span class="label">Người tạo</span><span class="value">{{ overview.CreateUser ||
                  '-' }}</span></div>
              <div class="wf-info-row"><span class="label">Ngày tạo</span><span class="value">{{
                  formatDateTime(overview.CreateTime) }}</span></div>
            </div>
          </div>

          <div v-if="displayFields.length" class="wf-tcard wf-request-detail-card">
            <div class="wf-tcard-toolbar">
              <h3>Biểu mẫu</h3>
              <v-spacer />
              <v-chip size="x-small" color="primary" variant="tonal">{{ displayFields.length }}</v-chip>
            </div>
            <div class="wf-request-fields-table">
              <div class="wf-trow wf-trow-header wf-request-fields-grid wf-request-fields-grid--compact">
                <div>Nhãn hiển thị</div>
                <div>Giá trị</div>
              </div>
              <div v-for="item in displayFields" :key="'side-field-' + item.InstanceDataID"
                class="wf-trow wf-request-fields-grid wf-request-fields-grid--compact">
                <div>{{ item.FieldLabel || '-' }}</div>
                <div>{{ item.FieldValue || '-' }}</div>
              </div>
            </div>
          </div>

          <div class="wf-tcard wf-request-detail-card">
            <div class="wf-tcard-toolbar">
              <h3>Vị trí ký</h3>
              <v-spacer />
              <v-chip size="x-small" color="primary" variant="tonal">{{ focusedSignBoxes.length }}</v-chip>
            </div>
            <div v-if="focusedSignBoxes.length" class="wf-request-box-list">
              <div v-for="item in focusedSignBoxes" :key="'focus-box-side-' + item.InstanceSignBoxID"
                class="wf-request-box-item"
                :class="{ active: Number(item.InstanceSignBoxID) === Number(selectedPreviewBoxId || 0) }">
                <div class="wf-request-box-item__head">
                  <div class="wf-request-box-item__title">Box #{{ item.BoxOrder }}</div>
                  <v-chip size="x-small" variant="outlined" color="primary" class="wf-chip-rounded">
                    Trang {{ item.PageNo || 1 }}
                  </v-chip>
                </div>
                <div class="wf-request-box-item__meta">
                  <span>{{ item.PersonName || item.SignerValue || 'Chưa gán người ký' }}</span>
                </div>
                <div class="d-flex mt-2">
                  <v-btn class="wf-btn" variant="outlined" color="primary" size="x-small" @click="jumpToSignBox(item)">
                    <v-icon start size="14">mdi-crosshairs-gps</v-icon>
                    Nhảy tới trang
                  </v-btn>
                </div>
              </div>
            </div>
            <div v-else class="wf-empty-state">Chưa có vị trí ký.</div>
          </div>

          <div class="wf-tcard wf-request-detail-card">
            <div class="wf-tcard-toolbar">
              <h3>Theo dõi xử lý</h3>
            </div>
            <uc-request-sign-activity compact :logs="logs" :signers="signers" :sign-boxes="signBoxes"
              :document-url="documentViewUrl" :instance-name="overview.InstanceName"
              :default-sign-system="overview.CurrentSignSystem" />
          </div>
        </div>
      </div>
    </div>

    <v-dialog v-model="showSmartcaGuideDialog" max-width="560" persistent>
      <v-card class="wf-smartca-guide">
        <div class="wf-smartca-guide__head">
          <div class="wf-smartca-guide__head-icon">
            <v-icon size="22">mdi-shield-key-outline</v-icon>
          </div>
          <div>
            <div class="wf-smartca-guide__title">Đang xử lý ký SmartCA</div>
            <div class="wf-smartca-guide__subtitle">Xác nhận ký trên ứng dụng VNPT SmartCA để tiếp tục</div>
          </div>
        </div>

        <div class="wf-smartca-guide__steps">
          <div class="wf-smartca-guide__step">
            <span class="index">1</span>
            <span>Mở ứng dụng SmartCA trên điện thoại</span>
          </div>
          <div class="wf-smartca-guide__step">
            <span class="index">2</span>
            <span>Kiểm tra thông tin văn bản và vị trí ký</span>
          </div>
          <div class="wf-smartca-guide__step">
            <span class="index">3</span>
            <span>Xác nhận OTP/PIN để hoàn tất ký số</span>
          </div>
        </div>

        <div class="wf-smartca-guide__status">
          <v-progress-circular indeterminate color="primary" size="18" width="2"></v-progress-circular>
          <span>{{ isSmartcaCalling ? 'Đang chờ phản hồi từ SmartCA...' : 'Đang chuẩn bị gửi yêu cầu ký...' }}</span>
        </div>

        <v-card-actions class="wf-smartca-guide__actions">
          <v-spacer />
          <v-btn class="wf-btn" variant="outlined" color="grey" :disabled="isSmartcaCalling"
            @click="showSmartcaGuideDialog = false">
            <v-icon start>mdi-close</v-icon>
            Đóng
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
	export default {
		mixins: [
    typeof window !== "undefined" && window.__WF_REQUEST_DETAIL_EXTERNAL_MIXIN__ ? window.__WF_REQUEST_DETAIL_EXTERNAL_MIXIN__ : {},
    typeof window !== "undefined" && window.__WF_REQUEST_DETAIL_SMARTCA_MIXIN__ ? window.__WF_REQUEST_DETAIL_SMARTCA_MIXIN__ : {}
  ],
  props: {
    propInstanceId: {
      type: Number,
      default: 0
    }
  },
  data: function () {
    return {
      instanceId: 0,
      overview: {},
      steps: [],
      signers: [],
      fields: [],
      logs: [],
      signBoxes: [],
      previewPageNo: 1,
      selectedPreviewBoxId: 0,
      revealedSignedBoxId: 0,
      isLoading: false,
      isActing: false,
      isSmartcaCalling: false,
      smartcaActionLock: false,
      showSmartcaGuideDialog: false,
      showRejectBox: false,
      rejectReason: "",
      mySignerProfile: null,
      smartcaSignatureBase64: "",
      smartcaUploadedSignatureBase64: "",
      isEcontractSyncing: false,
      mergedPdfUrl: "",
      lastMergedFileId: "",
      lastMergedPdfBase64: "",
      lastMergedFieldsHash: "",
      lastMergedSignersHash: "",
      isMergingPdf: false,
      hasAnySignatureSigned: false,
      econtractAuthCache: null,
      actionForm: {
        signCertInfo: "",
        providerTransactionCode: "",
        providerNote: "",
        otpCode: ""
      },
      eContractApiMap: {
        screen: "wf-user-request-detail",
        authLogin: "/api/econtract/auth/login",
        detail: "/api/econtract/contracts/{hopDongId}/detail",
        wesignDetail: "/api/econtract/wesign/documents/detail",
        wesignSyncRuntime: "/api/econtract/wesign/documents/{documentId}/sync-runtime",
        wesignDownloadSigned: "/api/econtract/wesign/documents/download-signed",
        syncRuntime: "/api/econtract/contracts/{hopDongId}/sync-runtime",
        downloadBase64: "/api/econtract/contracts/{hopDongId}/download-base64",
        downloadByUrl: "/api/econtract/contracts/download-by-url",
        updateSigners: "/api/econtract/contracts/update-signers",
        smartcaApp: "/econtract-integration-service/api/v1/tich-hop-ky/smartca/xac-thuc-app",
        smartcaAuto: "/econtract-integration-service/api/v1/tich-hop-ky/smartca/ky-tu-dong"
      }
    };
  },
  mounted: function () {
    if (typeof window !== "undefined") {
      window.__WF_ECONTRACT_SCREEN_MAP__ = window.__WF_ECONTRACT_SCREEN_MAP__ || {};
      window.__WF_ECONTRACT_SCREEN_MAP__["wf-user-request-detail"] = this.eContractApiMap;
      window.__WF_ECONTRACT_SCREEN_MAP__["wf-kanban-flow-detail"] = this.eContractApiMap;
    }
    this.instanceId = this.propInstanceId || this.parseInstanceId();
    this.loadDetail();
  },
  computed: {
    detailSubTitle: function () {
      var parts = [];
      if (this.overview.DefinitionName) parts.push(this.overview.DefinitionName);
      if (this.overview.CurrentStepName) parts.push("Bước: " + this.overview.CurrentStepName);
      return parts.join(" · ");
    },
    currentTemplateName: function () {
      if (this.overview.CurrentDocumentFileName && this.overview.CreateMode === "FREE_SIGN") return this.overview.CurrentDocumentFileName;
      if (this.overview.CurrentTemplateName) return this.overview.CurrentTemplateName;
      if (this.overview.CurrentStepName) return this.overview.CurrentStepName;
      return "Tài liệu ký";
    },
    documentViewUrl: function () {
      if (this.mergedPdfUrl) return this.mergedPdfUrl;
      var runtime = this.resolveBestRuntimeDocument();
      var name = String(runtime.FileName || "").toLowerCase();
      var isDoc = name.indexOf(".docx") >= 0 || name.indexOf(".doc") >= 0;
      if (isDoc) {
        return this.mergedPdfUrl || "";
      }
      if (runtime.FileUrl) {
        var rawUrl = runtime.FileUrl;
        if (rawUrl.indexOf("http") !== 0) {
          if (rawUrl.indexOf("FileData") < 0) {
            rawUrl = "/FileData/" + rawUrl;
          }
          return "https://file.zentea.vn/iotdev" + (rawUrl.indexOf("/") === 0 ? "" : "/") + rawUrl;
        }
        return rawUrl;
      }
      if (runtime.FileID) return "https://file.zentea.vn/iotdev/FileData/" + runtime.FileID;
      return "";
    },
    focusedSignBoxes: function () {
      var self = this;
      var rows = this.signBoxes || [];
      return rows.slice().sort(function (a, b) {
        var pageDiff = Number(a && a.PageNo || 1) - Number(b && b.PageNo || 1);
        if (pageDiff !== 0) return pageDiff;
        var boxDiff = Number(a && a.BoxOrder || 0) - Number(b && b.BoxOrder || 0);
        if (boxDiff !== 0) return boxDiff;
        return Number(a && a.InstanceSignBoxID || 0) - Number(b && b.InstanceSignBoxID || 0);
      }).map(function (box) {
        // Enrich box with resolved person name from signers if PersonName is empty
        if (!box.PersonName && !box.SignerValue) {
          // Ưu tiên 1: dùng LabelText → tìm field → FieldValue là mã NV được chọn (nguồn đáng tin nhất)
          // Vì DB có thể lưu người xử lý thay vì người ký thực sự
          if (box.LabelText) {
            var labelKey = box.LabelText;
            var mLabel = labelKey.match(/^###(.+)###$/) || labelKey.match(/^\{\{(.+)\}\}$/);
            var plainKey = mLabel ? mLabel[1] : labelKey;
            var fieldObj = (self.fields || []).find(function (f) {
              return String(f.FieldName || "").trim() === plainKey && f.FieldType === "signature";
            });
            if (fieldObj && fieldObj.FieldValue) {
              var empCode = String(fieldObj.FieldValue).trim().toUpperCase();
              var matchedByCert = (self.signers || []).find(function (s) {
                return String(s.ResolvedPersonID || "").trim().toUpperCase() === empCode;
              });
              if (matchedByCert && matchedByCert.ResolvedPersonName) {
                return Object.assign({}, box, { PersonName: matchedByCert.ResolvedPersonName });
              }
              // Nếu không tìm được tên thì hiển thị mã NV
              return Object.assign({}, box, { SignerValue: fieldObj.FieldValue });
            }
          }
          // Ưu tiên 2 (fallback): tìm từ signers theo SignerExecID trong DB
          var signerExecId = Number(box.SignerExecID || 0);
          if (signerExecId > 0) {
            var matched = (self.signers || []).find(function (s) {
              return Number(s.SignerExecID || 0) === signerExecId;
            });
            if (matched && (matched.ResolvedPersonName || matched.ResolvedPersonID)) {
              return Object.assign({}, box, {
                PersonName: matched.ResolvedPersonName || matched.ResolvedPersonID
              });
            }
          }
        }
        return box;
      });
    },
    canvasSignBoxes: function () {
      var rows = this.focusedSignBoxes || [];
      var revealedSignedBoxId = Number(this.revealedSignedBoxId || 0);
      return rows.filter(function (item) {
        var isSigned = this.isSignedRuntimeStatus(this.resolveSignBoxRuntimeStatus(item));
        var itemId = Number(item && item.InstanceSignBoxID || 0);
        if (!isSigned) return true;
        if (revealedSignedBoxId && itemId === revealedSignedBoxId) return true;
        return false;
      }, this);
    },
    currentActionSubText: function () {
      if (this.showEcontractTrackingPanel) {
        return "Tài liệu đã gửi sang " + this.currentExternalProviderText + " và đang chờ ký ngoài hệ thống.";
      }
      if (this.overview.CanCurrentUserSign) {
        return this.actionWaitingText;
      }
      if (this.overview.Status === "COMPLETED") return "Yêu cầu ký đã hoàn tất.";
      if (this.overview.Status === "REJECTED") return "Yêu cầu ký đã bị từ chối.";
      return "Theo dõi tiến độ xử lý.";
    },
    currentActionMode: function () {
      var method = String(this.overview.CurrentSignerMethod || this.overview.CurrentSignSystem || "").toLowerCase();
      var engine = this.resolveOverviewExecutionEngine();
      var stepType = String(this.overview.CurrentStepType || "").toUpperCase();
      if (engine === "ECONTRACT") return "ECONTRACT";
      if (method === "smartca") return "SMARTCA";
      if (method === "econtract") return "ECONTRACT";
      if (method === "otp_email" || method === "otp_sms") return "OTP";
      if (stepType === "REVIEW") return "REVIEW";
      if (stepType === "SIGN") return "SIGN";
      return "TRACKING";
    },
    actionPrimaryText: function () {
      var map = {
        SMARTCA: "Ký SmartCA",
        ECONTRACT: "Xác nhận eContract",
        OTP: "Xác nhận OTP",
        REVIEW: "Duyệt tài liệu",
        SIGN: "Ký hoàn tất",
        TRACKING: "Hoàn tất bước"
      };
      return map[this.currentActionMode] || "Ký hoàn tất";
    },
    actionPrimaryIcon: function () {
      var map = {
        SMARTCA: "mdi-shield-key-outline",
        ECONTRACT: "mdi-file-sign",
        OTP: "mdi-form-textbox-password",
        REVIEW: "mdi-eye-check-outline",
        SIGN: "mdi-draw-pen",
        TRACKING: "mdi-check-circle-outline"
      };
      return map[this.currentActionMode] || "mdi-draw-pen";
    },
    actionWaitingText: function () {
      var stepName = this.overview.CurrentStepName || "-";
      if (this.currentActionMode === "SMARTCA") {
        return "Đang chờ bạn ký SmartCA ở bước " + stepName + ".";
      }
      if (this.currentActionMode === "ECONTRACT") {
        return "Đang chờ người ký xử lý hợp đồng điện tử trên " + this.currentExternalProviderText + " ở bước " + stepName + ".";
      }
      if (this.currentActionMode === "OTP") {
        return "Đang chờ bạn xác thực OTP ở bước " + stepName + ".";
      }
      if (this.currentActionMode === "REVIEW") {
        return "Đang chờ bạn duyệt nội dung ở bước " + stepName + ".";
      }
      return "Đang chờ bạn ký ở bước " + stepName + ".";
    },
    actionModeCardTitle: function () {
      if (this.currentActionMode === "SMARTCA") return "SmartCA runtime";
      if (this.currentActionMode === "ECONTRACT") return "Theo dõi trạng thái ký";
      if (this.currentActionMode === "OTP") return "OTP runtime";
      if (this.currentActionMode === "REVIEW") return "Review runtime";
      return "Runtime action";
    },
    actionModeCardSubText: function () {
      if (this.currentActionMode === "SMARTCA") {
        if (this.approvedSignerCertInfo && !this.isApprovedSignerCertInfoValid) return "Metadata chứng thư đã duyệt không hợp lệ. Yêu cầu chuỗi 6-64 ký tự chữ/số.";
        if (!this.approvedSignerCertInfo && !(this.mySignerProfile && this.mySignerProfile.CertSerial)) return "Thiếu metadata chứng thư đã duyệt và chưa có chứng thư active trong hồ sơ signer.";
        return "Dùng metadata chứng thư số đã duyệt.";
      }
      if (this.currentActionMode === "ECONTRACT") return "Theo dõi trạng thái ký trên hệ thống " + this.currentExternalProviderText + ".";
      if (this.currentActionMode === "OTP") return "Nhập OTP để hoàn tất.";
      if (this.currentActionMode === "REVIEW") return "Xác nhận duyệt tài liệu.";
      return "Xử lý bước hiện tại.";
    },
    approvedSignerCertInfo: function () {
      var targetExecId = this.overview.CurrentSignerExecID || 0;
      var rows = this.signers || [];
      var i = 0;
      var row = null;
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i];
        if (row && row.SignerExecID === targetExecId) {
          return String(row.SignCertInfo || "").trim();
        }
      }
      return "";
    },
    isApprovedSignerCertInfoValid: function () {
      var raw = String(this.approvedSignerCertInfo || "").trim();
      if (!raw) return false;
      return /^[0-9A-Za-z]{6,64}$/.test(raw);
    },
    smartcaCertDisplayText: function () {
      if (this.approvedSignerCertInfo) return this.approvedSignerCertInfo;
      if (this.mySignerProfile && this.mySignerProfile.CertSerial) return String(this.mySignerProfile.CertSerial);
      return "Chưa có metadata chứng thư đã duyệt";
    },
    canSignCurrentAction: function () {
      return (this.overview.CanCurrentUserSign === true || this.overview.CanCurrentUserSign === 1)
        && Number(this.overview.CurrentSignerExecID || 0) > 0;
    },
    canRejectCurrentAction: function () {
      return (this.overview.CanCurrentUserReject === true || this.overview.CanCurrentUserReject === 1)
        && Number(this.overview.CurrentSignerExecID || 0) > 0;
    },
    canShowActionPanel: function () {
      if (this.showEcontractTrackingPanel) return false;
      return this.canSignCurrentAction || this.canRejectCurrentAction;
    },
    showEcontractTrackingPanel: function () {
      return this.resolveOverviewExecutionEngine() === "ECONTRACT"
        && this.canSyncCurrentEcontractProvider();
    },
    currentExternalProviderText: function () {
      return this.formatProvider(
        this.resolveOverviewContractProvider() || this.overview.CurrentSignSystem || this.overview.CurrentSignerMethod || "",
        this.resolveOverviewExecutionEngine()
      );
    },
    econtractTrackingHelpText: function () {
      if (this.canSyncCurrentEcontractProvider()) {
        return "Bấm nút Kiểm tra trạng thái ký để lấy tiến độ mới nhất từ " + this.currentExternalProviderText + ".";
      }
      return "Provider này chưa bật đồng bộ trạng thái tự động trong màn detail. Theo dõi kết quả trực tiếp trên " + this.currentExternalProviderText + ".";
    },
    externalSyncButtonText: function () {
      return "Kiểm tra trạng thái ký";
    },
    externalDocumentIdLabel: function () {
      if (this.resolveOverviewContractProvider() === "AMIS_WESIGN") return "Mã tài liệu";
      return "Mã hợp đồng";
    },
    econtractHopDongIdDisplay: function () {
      var documentId = "";
      if (this.resolveOverviewContractProvider() === "AMIS_WESIGN") {
        documentId = this.resolveWeSignDocumentId();
        return documentId || "-";
      }
      var id = Number(this.overview.ExternalContractID || 0) || this.resolveEcontractHopDongId();
      return id > 0 ? String(id) : "-";
    },
    econtractContractStatusDisplay: function () {
      if (this.overview.ExternalContractStatusText) return this.overview.ExternalContractStatusText;
      if (this.currentActionMode === "ECONTRACT") return "Đã gửi sang " + this.currentExternalProviderText;
      return "-";
    },
    econtractSignStatusDisplay: function () {
      if (this.overview.ExternalSignStatusText) return this.overview.ExternalSignStatusText;
      if (this.currentActionMode === "ECONTRACT") return "Đang chờ cập nhật";
      return "-";
    },
    econtractLastSyncDisplay: function () {
      var raw = this.overview.ExternalLastSyncTime || "";
      if (!raw) return "Chưa đồng bộ";
      return this.formatDateTime(raw);
    },
    canDownloadSignedExternalDocument: function () {
      var provider = this.resolveOverviewContractProvider();
      if (provider !== "AMIS_WESIGN") return false;
      return this.isExternalDocumentCompleted()
        || !!String(this.overview.ExternalDocumentUrl || "").trim()
        || !!String(this.overview.CurrentDocumentFileUrl || "").trim()
        || !!String(this.overview.CurrentDocumentFileID || "").trim();
    },
    signingChannelDisplay: function () {
      var engine = this.resolveOverviewExecutionEngine();
      var provider = this.resolveOverviewContractProvider();
      if (engine === "ECONTRACT") {
        if (provider === "VNPT_ECONTRACT") return "eContract VNPT";
        if (provider) return "eContract " + provider;
        return "eContract";
      }
      if (String(this.overview.CurrentSignerMethod || "").toLowerCase() === "smartca") return "SmartCA nội bộ";
      return "Ký nội bộ";
    },
    displayFields: function () {
      var rows = (this.fields || []).filter(function (item) {
        return !!String(item && item.FieldValue ? item.FieldValue : "").trim();
      });
      return rows.slice(0, 12);
    },
    isSignActionBlocked: function () {
      var profileCert = this.mySignerProfile && this.mySignerProfile.CertSerial ? String(this.mySignerProfile.CertSerial).trim() : "";
      if (!this.canSignCurrentAction) return true;
      if (this.currentActionMode === "SMARTCA") {
        if (this.approvedSignerCertInfo) return !this.isApprovedSignerCertInfoValid;
        return !/^[0-9A-Za-z]{6,64}$/.test(profileCert);
      }
      if (this.currentActionMode === "OTP") return !this.isOtpCodeValid(this.actionForm.otpCode);
      return false;
    },
    isRejectActionBlocked: function () {
      var otpCode = this.normalizeOtpCode(this.actionForm.otpCode);
      if (!this.canRejectCurrentAction) return true;
      if (this.currentActionMode !== "OTP") return false;
      return !this.isOtpCodeValid(otpCode);
    }
  },
  methods: {
    resolveBestRuntimeDocument: function () {
      var rows = this.steps || [];
      var i = 0;
      var row = null;
      var top = null;
      var rank = 0;
      var topRank = -1;
      var timeScore = 0;
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i] || {};
        if (row.Status === "SUPERSEDED") continue;
        if (!row.DocumentFileID && !row.DocumentFileUrl) continue;
        timeScore = new Date(row.CompletedDate || row.StartedDate || "").getTime();
        if (!Number.isFinite(timeScore) || timeScore < 0) timeScore = 0;
        rank = Number(row.StepOrder || 0) * 1000000000 + timeScore;
        if (rank > topRank || (rank === topRank && top && Number(row.ExecutionID || 0) > Number(top.ExecutionID || 0))) {
          topRank = rank;
          top = row;
        }
      }
      if (top) {
        var topFileName = top.DocumentFileName || "";
        // Nếu DocumentFileName rỗng nhưng FileID khác SourceFileID → đây là file đã ký (PDF), không phải template docx
        // Dùng tên synthetic .pdf để tránh checkAndMergeDocx nhận nhầm là docx và merge lại từ đầu
        if (!topFileName && top.DocumentFileID && top.DocumentFileID !== (this.overview && this.overview.SourceFileID)) {
          topFileName = "signed-" + top.DocumentFileID + ".pdf";
        }
        if (!topFileName) topFileName = this.overview.CurrentDocumentFileName || this.overview.SourceFileName || "";
        return {
          FileID: top.DocumentFileID || null,
          FileUrl: top.DocumentFileUrl || "",
          FileName: topFileName
        };
      }
      var ovFileName = this.overview.CurrentDocumentFileName || "";
      // Nếu CurrentDocumentFileID khác SourceFileID → đã có file ký, không fallback về SourceFileName
      if (!ovFileName && this.overview.CurrentDocumentFileID && this.overview.CurrentDocumentFileID !== this.overview.SourceFileID) {
        ovFileName = "signed-" + this.overview.CurrentDocumentFileID + ".pdf";
      }
      if (!ovFileName) ovFileName = this.overview.SourceFileName || "";
      return {
        FileID: this.overview.CurrentDocumentFileID || this.overview.SourceFileID || null,
        FileUrl: this.overview.CurrentDocumentFileUrl || "",
        FileName: ovFileName
      };
    },
    resolveOriginalTemplateFile: function () {
      if (this.overview.CreateMode === "TEMPLATE_FLOW") {
        var tempUrl = this.overview.CurrentTemplateFileUrl || ""
        var tempId = this.extractFileIdFromUrl(tempUrl)
        if (tempId) {
          var tempName = this.overview.CurrentTemplateName || "template"
          if (tempName.toLowerCase().indexOf(".doc") < 0) {
            tempName += ".docx"
          }
          return {
            FileID: tempId,
            FileName: tempName
          }
        }
      }
      if (this.overview.SourceFileID) {
        return {
          FileID: this.overview.SourceFileID,
          FileName: this.overview.SourceFileName || "template.docx"
        }
      }
      return null
    },
    parseInstanceId: function () {
      var params = new URLSearchParams(window.location.search || "");
      var raw = params.get("id") || "0";
      var parsed = parseInt(raw, 10);
      if (Number.isNaN(parsed)) return 0;
      return parsed;
    },
    loadDetail: async function () {
      var datasets;
      if (!this.instanceId) {
        if (showToast && showToast.error) showToast.error("Thiếu InstanceID để mở chi tiết yêu cầu ký.");
        return;
      }
      this.isLoading = true;
      try {
        datasets = await apiCallAsync("WF_Request_GetDetail", { InstanceID: this.instanceId });
        this.applyDetailData(datasets);
      } catch (err) {
        this.showError(err, "Không tải được chi tiết yêu cầu ký.");
      } finally {
        this.isLoading = false;
      }
      this.loadMySignerProfile();
    },
    loadMySignerProfile: async function () {
      try {
        var rows = await apiCallAsync("WF_SignerProfile_GetMyActiveCert", {});
        this.mySignerProfile = rows && rows[0] ? rows[0] : null;
        this.smartcaSignatureBase64 = "";
        this.smartcaUploadedSignatureBase64 = "";
      } catch (err) {
        this.mySignerProfile = null;
        this.smartcaSignatureBase64 = "";
        this.smartcaUploadedSignatureBase64 = "";
      }
    },
    applyDetailData: function (datasets) {
      this.overview = this.normalizeOverview(datasets && datasets[0] ? datasets[0][0] : null);
      this.steps = this.normalizeSteps(datasets && datasets[1] ? datasets[1] : []);
      // Chỉ lấy signers của execution hiện tại để tránh hiển thị sai khi có nhiều executions
      var currentExecId = Number(this.overview && this.overview.CurrentExecutionID || 0);
      var allSigners = datasets && datasets[2] ? datasets[2] : [];
      var self = this
      this.hasAnySignatureSigned = allSigners.some(function (s) {
        return self.isSignedRuntimeStatus(s.Status)
      })
      var filteredSigners = currentExecId > 0
        ? allSigners.filter(function (s) { return Number(s.ExecutionID || 0) === currentExecId; })
        : allSigners;
      // Fallback: nếu filter ra rỗng thì dùng tất cả
      if (!filteredSigners.length) filteredSigners = allSigners;
      this.signers = this.normalizeSigners(filteredSigners);
      this.fields = this.normalizeFields(datasets && datasets[3] ? datasets[3] : []);
      this.logs = this.normalizeLogs(datasets && datasets[4] ? datasets[4] : []);
      this.signBoxes = this.normalizeSignBoxes(datasets && datasets[5] ? datasets[5] : []);
      this.applyOverviewFallbacks();
      this.previewPageNo = 1;
      this.selectedPreviewBoxId = 0;
      this.revealedSignedBoxId = 0;
      this.showRejectBox = false;
      this.rejectReason = "";
      this.resetActionForm();
      if (this.canSignCurrentAction) this.jumpToCurrentSignBox();
      this.checkAndMergeDocx();
    },
    normalizeOverview: function (row) {
      if (!row) return {};
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
        NextSigner: row.NextSigner || "",
        TotalSteps: row.TotalSteps || 0,
        CreateUser: row.CreateUser || "",
        CreateTime: row.CreateTime || "",
        UpdateUser: row.UpdateUser || "",
        UpdateTime: row.UpdateTime || "",
        RequireManualSendSign: row.RequireManualSendSign === true || row.RequireManualSendSign === 1,
        IsSentForSigning: row.IsSentForSigning === true || row.IsSentForSigning === 1
      };
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
        };
      });
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
          IsCurrentUser: row.IsCurrentUser === true || row.IsCurrentUser === 1
        };
      });
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
        };
      });
    },
    normalizeLogs: function (rows) {
      return (rows || []).map(function (row) {
        return {
          LogID: row.LogID,
          InstanceID: row.InstanceID,
          StepOrder: row.StepOrder || null,
          ActionCode: row.ActionCode || "",
          ActionDetail: row.ActionDetail || "",
          UserID: row.UserID || "",
          CreateTime: row.CreateTime || ""
        };
      });
    },
    parseJsonSafe: function (value) {
      var raw = String(value || "").trim();
      if (!raw) return null;
      try {
        return JSON.parse(raw);
      } catch (e) {
        return null;
      }
    },
    extractCreatedLogConfig: function () {
      var rows = this.logs || [];
      var i = 0;
      var row = null;
      var parsed = null;
      for (i = 0; i < rows.length; i += 1) {
        row = rows[i] || {};
        if (String(row.ActionCode || "").toUpperCase() !== "INSTANCE_CREATED") continue;
        parsed = this.parseJsonSafe(row.ActionDetail || "");
        if (parsed && typeof parsed === "object") return parsed;
      }
      return null;
    },
    applyOverviewFallbacks: function () {
      var boxRows = this.signBoxes || [];
      var created = this.extractCreatedLogConfig() || {};
      var firstBox = boxRows.length ? (boxRows[0] || {}) : {};
      var hopDongId = 0;
      if (!this.overview || typeof this.overview !== "object") this.overview = {};

      if (!this.overview.ExecutionEngine) {
        this.overview.ExecutionEngine = firstBox.ExecutionEngine || created.ExecutionEngine || "";
      }
      if (!this.overview.ContractProvider) {
        this.overview.ContractProvider = firstBox.ContractProvider || created.ContractProvider || "";
      }
      hopDongId = Number(this.overview.ExternalContractID || 0);
      if (!(hopDongId > 0)) {
        hopDongId = this.extractEcontractTaggedId(created.Description || "");
      }
      if (!(hopDongId > 0)) {
        hopDongId = this.extractEcontractTaggedId(created.ReferenceCode || "");
      }
      if (!(hopDongId > 0)) {
        hopDongId = this.extractEcontractTaggedId(this.overview.Description || "");
      }
      if (!(hopDongId > 0)) {
        hopDongId = this.extractEcontractTaggedId(this.overview.ReferenceCode || "");
      }
      if (hopDongId > 0 && !(Number(this.overview.ExternalContractID || 0) > 0)) {
        this.overview.ExternalContractID = hopDongId;
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
          SignerValue: row.SignerValue || "",
          PersonName: row.PersonName || "",
          DepartmentName: row.DepartmentName || "",
          SignMethod: row.SignMethod || "",
          ExecutionEngine: row.ExecutionEngine || "",
          ContractProvider: row.ContractProvider || "",
          LabelText: row.LabelText || "",
          Status: row.Status || ""
        };
      });
    },
    resetActionForm: function () {
      this.actionForm = {
        signCertInfo: "",
        providerTransactionCode: "",
        providerNote: "",
        otpCode: ""
      };
    },
    isSignedRuntimeStatus: function (value) {
      var status = String(value || "").trim().toUpperCase();
      return status === "SIGNED"
        || status === "DONE"
        || status === "APPROVED"
        || status === "PASSED"
        || status === "FINISHED"
        || status === "SUCCESS"
        || status === "SIGNED_SUCCESS"
        || status === "HOAN_TAT";
    },
    resolveSignBoxRuntimeStatus: function (box) {
      var boxStatus = String(box && box.Status || "").trim();
      var signerExecId = Number(box && box.SignerExecID || 0);
      var stepOrder = Number(box && box.StepOrder || 0);
      var signerOrder = Number(box && box.SignerOrder || 0);
      var signers = this.signers || [];
      var i = 0;
      var row = null;
      if (signerExecId > 0) {
        for (i = 0; i < signers.length; i += 1) {
          row = signers[i] || {};
          if (Number(row.SignerExecID || 0) !== signerExecId) continue;
          if (row.Status) return String(row.Status || "");
        }
      }
      for (i = 0; i < signers.length; i += 1) {
        row = signers[i] || {};
        if (stepOrder && Number(row.StepOrder || 0) !== stepOrder) continue;
        if (signerOrder && Number(row.SignerOrder || 0) !== signerOrder) continue;
        if (row.Status) return String(row.Status || "");
      }
      if (boxStatus) return boxStatus;
      return "";
    },
    normalizeOtpCode: function (value) {
      return String(value || "").trim();
    },
    isOtpCodeValid: function (value) {
      var raw = this.normalizeOtpCode(value);
      if (!raw) return false;
      return /^[0-9A-Za-z]{4,12}$/.test(raw);
    },
    buildActionDetail: function () {
      var parts = [this.actionPrimaryText + " từ wf-kanban-flow-detail"];
      var otpCode = this.normalizeOtpCode(this.actionForm.otpCode);
      if (this.actionForm.providerTransactionCode) parts.push("ProviderRef=" + this.actionForm.providerTransactionCode);
      if (otpCode) parts.push("OtpRef=" + this.maskOtpCode(otpCode));
      if (this.actionForm.providerNote) parts.push("Note=" + this.actionForm.providerNote);
      return parts.join(" | ");
    },
    maskOtpCode: function (value) {
      var raw = this.normalizeOtpCode(value);
      if (!raw) return "";
      if (raw.length <= 2) return "****";
      return "****" + raw.slice(-2);
    },
    normalizeRejectReason: function (value) {
      return String(value || "").trim();
    },
    sanitizeReasonForOtp: function (reason, otpCode) {
      var safeReason = String(reason || "");
      var rawOtp = this.normalizeOtpCode(otpCode);
      var escapedOtp = "";
      if (!safeReason || !rawOtp || !this.isOtpCodeValid(rawOtp)) return safeReason;
      escapedOtp = rawOtp.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      return safeReason.replace(new RegExp(escapedOtp, "g"), this.maskOtpCode(rawOtp));
    },
    resolveSignCertInfoPayload: function () {
      if (this.currentActionMode === "SMARTCA" && this.approvedSignerCertInfo) {
        return this.approvedSignerCertInfo;
      }
      if (this.currentActionMode === "SMARTCA" && this.mySignerProfile && this.mySignerProfile.CertSerial) {
        return String(this.mySignerProfile.CertSerial || "").trim();
      }
      if (this.currentActionMode === "ECONTRACT") {
        return this.actionForm.providerTransactionCode || "";
      }
      return this.actionForm.signCertInfo || this.actionForm.providerTransactionCode || "";
    },
    resolvePdfPageSizeForSignBox: async function (box) {
      var pageNo = this.toSafeInt(box && box.PageNo || 1, 1);
      var canvasRef = this.$refs && this.$refs.signCanvasRef ? this.$refs.signCanvasRef : null;
      if (!canvasRef || typeof canvasRef.getPdfPageSize !== "function") return null;
      try {
        return await canvasRef.getPdfPageSize(pageNo);
      } catch (e) {
        return null;
      }
    },
    buildSmartcaLocationSign: async function (box) {
      var x = Number(box && box.PosX || 0);
      var y = Number(box && box.PosY || 0);
      var w = Number(box && box.BoxWidth || 0);
      var h = Number(box && box.BoxHeight || 0);
      var pageSize = await this.resolvePdfPageSizeForSignBox(box);
      var pageWidth = Number(pageSize && pageSize.width || 0);
      var pageHeight = Number(pageSize && pageSize.height || 0);
      var isPercentBox = x >= 0 && y >= 0 && w > 0 && h > 0 && x <= 100 && y <= 100 && w <= 100 && h <= 100;
      var left = 0;
      var right = 0;
      var bottom = 0;
      var top = 0;

      if (isPercentBox && pageWidth > 0 && pageHeight > 0) {
        var leftAbs = (x / 100) * pageWidth;
        var widthAbs = (w / 100) * pageWidth;
        var topAbsFromTop = (y / 100) * pageHeight;
        var heightAbs = (h / 100) * pageHeight;
        var bottomAbs = pageHeight - (topAbsFromTop + heightAbs);
        left = Math.round(Math.max(0, leftAbs));
        right = Math.round(Math.max(left + 1, leftAbs + widthAbs));
        bottom = Math.round(Math.max(0, bottomAbs));
        top = Math.round(Math.max(bottom + 1, bottomAbs + heightAbs));
      } else {
        left = Math.round(Math.max(0, x));
        bottom = Math.round(Math.max(0, y));
        right = Math.round(Math.max(left + 1, x + w));
        top = Math.round(Math.max(bottom + 1, y + h));
      }

      if (pageWidth > 0 && pageHeight > 0) {
        if (left > pageWidth - 1) left = Math.max(0, Math.round(pageWidth - 1));
        if (right > pageWidth) right = Math.max(left + 1, Math.round(pageWidth));
        if (bottom > pageHeight - 1) bottom = Math.max(0, Math.round(pageHeight - 1));
        if (top > pageHeight) top = Math.max(bottom + 1, Math.round(pageHeight));
      }

      return String(left) + "," + String(bottom) + "," + String(right) + "," + String(top);
    },
    buildSmartcaLocationSignLegacy: function (box) {
      var x = Number(box && box.PosX || 0);
      var y = Number(box && box.PosY || 0);
      var w = Number(box && (box.BoxWidth != null ? box.BoxWidth : box.Width) || 0);
      var h = Number(box && (box.BoxHeight != null ? box.BoxHeight : box.Height) || 0);
      return x + "," + y + "," + w + "," + h;
    },
    normalizeBase64Content: function (raw) {
      var value = String(raw || "").trim();
      if (!value) return "";
      if (value.indexOf("base64,") >= 0) value = value.split("base64,").pop() || "";
      value = value.replace(/\s+/g, "");
      return value;
    },
    convertBlobToBase64: function (blob) {
      return new Promise(function (resolve) {
        var reader = null;
        if (typeof FileReader === "undefined") {
          resolve("");
          return;
        }
        reader = new FileReader();
        reader.onloadend = function () {
          var dataUrl = String(reader.result || "");
          if (dataUrl.indexOf("base64,") < 0) {
            resolve("");
            return;
          }
          resolve(dataUrl.split("base64,").pop() || "");
        };
        reader.onerror = function () {
          resolve("");
        };
        reader.readAsDataURL(blob);
      });
    },
    fetchFileBase64FromPublicUrl: async function (fileId) {
      var normalized = String(fileId || "").trim();
      var response = null;
      var blob = null;
      if (!normalized || typeof fetch === "undefined") return "";
      try {
        response = await fetch("https://file.zentea.vn/iotdev/FileData/" + normalized, {
          method: "GET",
          credentials: "omit"
        });
        if (!response || !response.ok) return "";
        blob = await response.blob();
        if (!blob || !blob.size) return "";
        return await this.convertBlobToBase64(blob);
      } catch (e) {
        return "";
      }
    },
    toSafeInt: function (value, fallback) {
      var n = Number(value);
      if (!Number.isFinite(n)) return Number(fallback || 0);
      return Math.trunc(n);
    },
    formatDateTime: function (value) {
      var dt = value ? new Date(value) : null;
      if (!dt || Number.isNaN(dt.getTime())) return String(value || "");
      var dd = String(dt.getDate()).padStart(2, "0");
      var mm = String(dt.getMonth() + 1).padStart(2, "0");
      var yyyy = String(dt.getFullYear());
      var hh = String(dt.getHours()).padStart(2, "0");
      var mi = String(dt.getMinutes()).padStart(2, "0");
      return dd + "/" + mm + "/" + yyyy + " " + hh + ":" + mi;
    },
    signRequest: async function () {
      var datasets;
      var detail;
      var otpCode = this.normalizeOtpCode(this.actionForm.otpCode);
      var signCertInfo = this.resolveSignCertInfoPayload();
      if (this.isActing || this.isSmartcaCalling || this.smartcaActionLock) return;
      if (!this.canSignCurrentAction) {
        if (showToast && showToast.error) showToast.error("Không tìm thấy lượt ký hợp lệ của bạn để thực hiện thao tác.");
        return;
      }
      if (this.currentActionMode === "SMARTCA" && !this.approvedSignerCertInfo) {
        if (!(this.mySignerProfile && this.mySignerProfile.CertSerial)) {
          if (showToast && showToast.error) showToast.error("Chưa có metadata chứng thư đã duyệt và cũng không có chứng thư active trong hồ sơ người ký.");
          return;
        }
      }
      if (this.currentActionMode === "SMARTCA" && this.mySignerProfile && this.mySignerProfile.CertSerial) {
        if (!/^[0-9A-Za-z]{6,64}$/.test(String(this.mySignerProfile.CertSerial || "").trim())) {
          if (showToast && showToast.error) showToast.error("Serial chứng thư trong hồ sơ người ký không hợp lệ (6-64 ký tự chữ/số).");
          return;
        }
      }
      if (this.currentActionMode === "SMARTCA") {
        this.smartcaActionLock = true;
        this.jumpToCurrentSignBox();
        this.showSmartcaGuideDialog = true;
        try {
          var smartcaResponse = await this.callSmartCAInternalSign();
          var self = this;
          var signedFileId = smartcaResponse && (
            smartcaResponse.FileID      || smartcaResponse.fileId      ||
            smartcaResponse.FILE_ID     || smartcaResponse.FileId      ||
            smartcaResponse.SignedFileID || smartcaResponse.signedFileId
          );
          if (signedFileId && String(signedFileId).indexOf("merged") >= 0) {
            signedFileId = "";
          }
          var signedBase64 = smartcaResponse && (
            smartcaResponse.DocFileSigned || smartcaResponse.docFileSigned ||
            smartcaResponse.FileSigned    || smartcaResponse.fileSigned    ||
            smartcaResponse.SignedFile    || smartcaResponse.signedFile
          );
          // SmartCA trả về FileID của file PDF đã ký (đã được upload vào tblFileData qua webhook).
          // DocumentFileID đã propagate sang tất cả executions. Frontend chỉ cần fetch binary
          // từ DB để hiển thị canvas và chuẩn bị nội dung cho lần ký tiếp theo.
          if (signedFileId) {
            self._pendingSignedFileId   = String(signedFileId).trim();
            self._pendingSignedFileName = "WF-" + self.instanceId + "-signed.pdf";
            self.overview.CurrentDocumentFileUrl = "https://file.zentea.vn/iotdev/FileData/" + self._pendingSignedFileId;
            self.overview.CurrentDocumentFileID  = self._pendingSignedFileId;
            try {
              var signedBinary = await self.tryReadFileBinaryById(self._pendingSignedFileId);
              if (signedBinary) {
                var normSigned = self.normalizeBase64Content ? self.normalizeBase64Content(signedBinary) : String(signedBinary).replace(/\s+/g, "");
                if (normSigned) {
                  self.lastMergedPdfBase64 = normSigned;
                  self.lastMergedFileId = self._pendingSignedFileId;
                  if (self.mergedPdfUrl && self.mergedPdfUrl.indexOf("blob:") === 0) {
                    URL.revokeObjectURL(self.mergedPdfUrl);
                  }
                  self.mergedPdfUrl = self.base64ToBlobUrl(normSigned, "application/pdf");
                }
              }
            } catch (fetchErr) {
              console.warn("[WF] Không load được binary PDF đã ký:", fetchErr);
            }
          }
        } catch (smartErr) {
          this.showError(smartErr, "Gọi SmartCA nội bộ thất bại.");
          return;
        } finally {
          this.isSmartcaCalling = false;
          this.showSmartcaGuideDialog = false;
          this.smartcaActionLock = false;
        }
      }
      if (this.currentActionMode === "SMARTCA" && !this.approvedSignerCertInfo && this.mySignerProfile && this.mySignerProfile.CertSerial) {
        signCertInfo = String(this.mySignerProfile.CertSerial || "").trim();
      }
      if (this.currentActionMode === "SMARTCA" && !this.isApprovedSignerCertInfoValid && !(this.mySignerProfile && this.mySignerProfile.CertSerial)) {
        if (showToast && showToast.error) showToast.error("Metadata chứng thư đã duyệt không hợp lệ và không có fallback từ hồ sơ signer.");
        return;
      }
      if (this.currentActionMode === "SMARTCA" && this.approvedSignerCertInfo && !this.isApprovedSignerCertInfoValid) {
        if (showToast && showToast.error) showToast.error("Metadata chứng thư đã duyệt không hợp lệ. Vui lòng liên hệ quản trị để đồng bộ lại.");
        return;
      }
      if (this.currentActionMode === "OTP" && !this.isOtpCodeValid(otpCode)) {
        if (showToast && showToast.error) showToast.error("Bước OTP yêu cầu mã xác thực 4-12 ký tự chữ/số.");
        return;
      }
      detail = this.buildActionDetail();
      this.isActing = true;
      try {
        datasets = await apiCallAsync("WF_Request_SignComplete", {
          InstanceID: this.instanceId,
          SignerExecID: this.overview.CurrentSignerExecID || 0,
          ActionDetail: detail,
          SignCertInfo: signCertInfo,
          OtpCode: otpCode,
          SignedFileID:   this._pendingSignedFileId   || "",
          SignedFileName: this._pendingSignedFileName || ""
        });
        this._pendingSignedFileId   = "";
        this._pendingSignedFileName = "";
        this.applyDetailData(datasets);
        if (showToast && showToast.success) showToast.success(this.actionPrimaryText + " thành công.");
      } catch (err) {
        this.showError(err, "Không thể xử lý thao tác hiện tại.");
      } finally {
        this.isActing = false;
      }
    },
    resolveSmartcaOptionSign: function () {
      var value = this.mySignerProfile && this.mySignerProfile.SmartCAOptionSign != null
        ? String(this.mySignerProfile.SmartCAOptionSign).trim()
        : "";
      if (value === "0" || value === "1") return value;
      return "1";
    },
    rejectRequest: async function () {
      var datasets;
      var reason = this.normalizeRejectReason(this.rejectReason);
      var otpCode = this.normalizeOtpCode(this.actionForm.otpCode);
      if (!this.canRejectCurrentAction) {
        if (showToast && showToast.error) showToast.error("Không tìm thấy lượt từ chối hợp lệ của bạn để thực hiện thao tác.");
        return;
      }
      if (!reason) {
        if (showToast && showToast.error) showToast.error("Vui lòng nhập lý do từ chối.");
        return;
      }
      if (this.currentActionMode === "OTP" && !this.isOtpCodeValid(otpCode)) {
        if (showToast && showToast.error) showToast.error("Bước OTP yêu cầu mã xác thực 4-12 ký tự chữ/số.");
        return;
      }
      reason = this.sanitizeReasonForOtp(reason, otpCode);
      if (this.actionForm.providerNote) reason = reason + " | " + this.actionForm.providerNote;
      this.isActing = true;
      try {
        datasets = await apiCallAsync("WF_Request_Reject", {
          InstanceID: this.instanceId,
          SignerExecID: this.overview.CurrentSignerExecID || 0,
          RejectReason: reason,
          OtpCode: otpCode
        });
        this.applyDetailData(datasets);
        if (showToast && showToast.success) showToast.success("Đã từ chối yêu cầu ký.");
      } catch (err) {
        this.showError(err, "Không thể từ chối yêu cầu ký.");
      } finally {
        this.isActing = false;
      }
    },
    cancelReject: function () {
      this.showRejectBox = false;
      this.rejectReason = "";
      this.actionForm.providerNote = "";
    },
    previewDocument: function () {
      if (this.overview.CurrentDocumentFileUrl) {
        window.open(this.overview.CurrentDocumentFileUrl, "_blank");
        return;
      }
      if (this.documentViewUrl) {
        window.open(this.documentViewUrl, "_blank");
        return;
      }
      if (showAlert) {
        showAlert("Xem file", "Chưa có file runtime.");
      }
    },
    downloadSignedExternalDocument: async function () {
      try {
        if (this.resolveOverviewContractProvider() !== "AMIS_WESIGN") return;
        await this.loadWeSignSignedDocument(false);
        if (showToast && showToast.success) showToast.success("Đã tải file đã ký từ " + this.currentExternalProviderText + ".");
      } catch (err) {
        this.showError(err, "Không tải được file đã ký.");
      }
    },
    onCanvasActivePageChange: function (pageNo) {
      this.previewPageNo = Number(pageNo || 1) || 1;
    },
    onCanvasSelectBox: function (box) {
      this.selectedPreviewBoxId = Number(box && box.InstanceSignBoxID ? box.InstanceSignBoxID : 0);
      this.previewPageNo = Number(box && box.PageNo ? box.PageNo : this.previewPageNo || 1) || 1;
    },
    jumpToSignBox: function (box) {
      var pageNo = Number(box && box.PageNo ? box.PageNo : 1) || 1;
      var boxId = Number(box && box.InstanceSignBoxID ? box.InstanceSignBoxID : 0);
      var isSigned = this.isSignedRuntimeStatus(this.resolveSignBoxRuntimeStatus(box));
      this.previewPageNo = pageNo;
      this.selectedPreviewBoxId = boxId;
      this.revealedSignedBoxId = isSigned ? boxId : 0;
      this.$nextTick(function () {
        var canvas = this.$refs.signCanvasRef;
        if (canvas && typeof canvas.focusBoxById === "function") {
          canvas.focusBoxById(boxId, pageNo);
          return;
        }
        if (canvas && typeof canvas.scrollToPage === "function") {
          canvas.scrollToPage(pageNo, true);
        }
      });
    },
    jumpToCurrentSignBox: function () {
      var box = this.resolveCurrentSignBox();
      if (!box) return;
      this.jumpToSignBox(box);
    },
    base64ToBlob: function (base64, mime) {
      var bytes = atob(base64);
      var len = bytes.length;
      var arr = new Uint8Array(len);
      var i = 0;
      for (i = 0; i < len; i += 1) arr[i] = bytes.charCodeAt(i);
      return new Blob([arr], { type: mime || "application/octet-stream" });
    },
    triggerBlobDownload: function (blob, fileName) {
      var url = "";
      var link = null;
      if (!blob || typeof window === "undefined" || !window.URL || typeof document === "undefined" || !document.createElement) return;
      url = window.URL.createObjectURL(blob);
      link = document.createElement("a");
      link.href = url;
      link.download = fileName || "signed-document.pdf";
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.setTimeout(function () {
        window.URL.revokeObjectURL(url);
      }, 1000);
    },
    formatStatusText: function (value) {
      var map = {
        RUNNING: "Đang chạy",
        WAITING_ME: "Chờ tôi ký",
        COMPLETED: "Hoàn tất",
        CANCELLED: "Đã hủy",
        REJECTED: "Từ chối"
      };
      return map[value] || value || "-";
    },
    formatMethod: function (value) {
      var map = {
        smartca: "VNPT SmartCA",
        econtract: "VNPT eContract",
        otp_email: "OTP Email",
        otp_sms: "OTP SMS",
        image: "Ký ảnh"
      };
      return map[value] || value || "-";
    },
    formatEngine: function (value) {
      var engine = String(value || "").toUpperCase();
      if (engine === "ECONTRACT") return "eContract";
      if (engine === "SMARTCA") return "SmartCA nội bộ";
      return value || "-";
    },
    formatProvider: function (value, engine) {
      var provider = String(value || "").toUpperCase();
      var normalizedEngine = String(engine || "").toUpperCase();
      if (normalizedEngine !== "ECONTRACT") return "-";
      if (provider === "VNPT_ECONTRACT") return "VNPT eContract";
      if (provider === "AMIS_WESIGN") return "AMIS WeSign";
      return provider || "Chưa chọn";
    },
    formatDateTime: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (Number.isNaN(dt.getTime())) return value;
      var hh = String(dt.getHours()).padStart(2, "0");
      var mm = String(dt.getMinutes()).padStart(2, "0");
      var dd = String(dt.getDate()).padStart(2, "0");
      var mo = String(dt.getMonth() + 1).padStart(2, "0");
      var yyyy = dt.getFullYear();
      return hh + ":" + mm + " " + dd + "/" + mo + "/" + yyyy;
    },
    resolveOverviewExecutionEngine: function () {
      var engine = String(this.overview.ExecutionEngine || "").toUpperCase();
      var rows = this.signBoxes || [];
      var i = 0;
      if (engine) return engine;
      for (i = 0; i < rows.length; i += 1) {
        engine = String(rows[i] && rows[i].ExecutionEngine || "").toUpperCase();
        if (engine) return engine;
      }
      return "";
    },
    resolveOverviewContractProvider: function () {
      var provider = String(this.overview.ContractProvider || "").toUpperCase();
      var rows = this.signBoxes || [];
      var i = 0;
      if (provider) return provider;
      for (i = 0; i < rows.length; i += 1) {
        provider = String(rows[i] && rows[i].ContractProvider || "").toUpperCase();
        if (provider) return provider;
      }
      return "";
    },
    goBack: function () {
      this.$emit("back")
    },
    goCreateAnother: function () {
      window.location.href = "/wf-user-request-create";
    },
    showError: function (err, fallback) {
      var message = fallback || "Có lỗi xảy ra.";
      if (err && err.responseJSON && err.responseJSON.Message) message = err.responseJSON.Message;
      else if (err && err.responseText) message = err.responseText;
      else if (err && err.message) message = err.message;
      if (showToast && showToast.error) showToast.error(message);
    },
    extractFileIdFromUrl: function (url) {
      var raw = String(url || "");
      var match = raw.match(/\/FileData\/([A-Za-z0-9]+)/i);
      if (match && match[1]) return match[1];
      return "";
    },
    applyAnchorsToSignBoxes: function (signBoxes, anchors, totalBoxCount) {
      // Thứ tự ưu tiên: LabelText → BoxOrder → SignerOrder → index fallback
      return (signBoxes || []).map(function (box, boxIdx) {
        var anchor = null;
        // Ưu tiên 1: LabelText (placeholder docx – chính xác nhất)
        if (!anchor && box.LabelText) {
          anchor = anchors.find(function (a) {
            var token = a.token || a.Token || a.labelText || a.LabelText || '';
            return token && token === box.LabelText;
          });
          if (!anchor) {
            var m = box.LabelText.match(/^###(.+)###$/) || box.LabelText.match(/^\{\{(.+)\}\}$/);
            if (m) {
              var plainLabel = m[1];
              anchor = anchors.find(function (a) {
                var token = a.token || a.Token || a.labelText || a.LabelText || '';
                return token === plainLabel || token === '###' + plainLabel + '###' || token === '{{' + plainLabel + '}}';
              });
            }
          }
        }
        // Ưu tiên 2: BoxOrder
        if (!anchor && Number(box.BoxOrder) > 0) {
          anchor = anchors.find(function (a) {
            var bOrder = a.boxOrder != null ? a.boxOrder : a.BoxOrder;
            return Number(bOrder) === Number(box.BoxOrder);
          });
        }
        // Ưu tiên 3: SignerOrder
        if (!anchor && Number(box.SignerOrder) > 0) {
          anchor = anchors.find(function (a) {
            var order = a.signerOrder != null ? a.signerOrder : a.SignerOrder;
            return Number(order) === Number(box.SignerOrder);
          });
        }
        // Fallback: index
        if (!anchor && anchors.length === totalBoxCount) {
          anchor = anchors[boxIdx] || null;
        }
        if (!anchor) return box;
        return Object.assign({}, box, {
          PageNo:    anchor.pageNo    != null ? anchor.pageNo    : (anchor.PageNo    != null ? anchor.PageNo    : box.PageNo),
          PosX:      anchor.posX      != null ? anchor.posX      : (anchor.PosX      != null ? anchor.PosX      : box.PosX),
          PosY:      anchor.posY      != null ? anchor.posY      : (anchor.PosY      != null ? anchor.PosY      : box.PosY),
          BoxWidth:  anchor.boxWidth  != null ? anchor.boxWidth  : (anchor.BoxWidth  != null ? anchor.BoxWidth  : box.BoxWidth),
          BoxHeight: anchor.boxHeight != null ? anchor.boxHeight : (anchor.BoxHeight != null ? anchor.BoxHeight : box.BoxHeight)
        });
      });
    },
    tryReadFileBinaryById: async function (fileId) {
      if (!fileId) return "";
      try {
        var rows = await apiCallAsync("FileData_GetByID", { FileID: fileId });
        var row = rows && rows[0] ? rows[0] : null;
        var binary = row && (row.BinaryContent || row.FILE_CONTENT || row.File_Binary || row.FILE_BINARY || row.FileBinaryBase64 || row.FileBinary || "");
        return binary;
      } catch (err) {
        console.error("Không đọc được file binary:", err);
        return "";
      }
    },
    base64ToBlobUrl: function (base64, contentType) {
      contentType = contentType || 'application/pdf';
      var clean = String(base64 || "").trim();
      if (clean.indexOf("base64,") >= 0) {
        clean = clean.split("base64,").pop() || "";
      }
      clean = clean.replace(/\s+/g, "");
      if (!clean) return "";

      // Nếu là raw PDF text
      if (clean.indexOf("%PDF-") === 0) {
        var len = clean.length;
        var bytes = new Uint8Array(len);
        for (var i = 0; i < len; i += 1) {
          bytes[i] = clean.charCodeAt(i) & 0xff;
        }
        var blob = new Blob([bytes], { type: contentType });
        return URL.createObjectURL(blob);
      }

      var byteCharacters = atob(clean);
      var byteNumbers = new Array(byteCharacters.length);
      for (var i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      var byteArray = new Uint8Array(byteNumbers);
      var blob = new Blob([byteArray], { type: contentType });
      return URL.createObjectURL(blob);
    },
    checkAndMergeDocx: async function () {
      var runtime = this.resolveBestRuntimeDocument();
      var fileId = runtime.FileID || this.extractFileIdFromUrl(runtime.FileUrl || "");
      var name = String(runtime.FileName || "").toLowerCase();
      var isDoc = (name.indexOf(".docx") >= 0 || name.indexOf(".doc") >= 0) && !(this.overview && this.overview.RequireManualSendSign);

      // Force re-merge if fields data or signer configuration has changed
      var currentFieldsHash = (this.fields || []).map(function (f) {
        return String(f.FieldName || "") + ":" + String(f.FieldValue || "");
      }).join("|");

      var currentSignersHash = (this.signers || []).map(function (s) {
        return String(s.SignerOrder || "") + ":" + String(s.ResolvedPersonID || "") + ":" + String(s.Status || "");
      }).join("|");

      var hashChanged = (this.lastMergedFieldsHash !== currentFieldsHash) || (this.lastMergedSignersHash !== currentSignersHash);

      var self = this;
      var hasSigned = this.hasAnySignatureSigned || (this.signers || []).some(function (s) {
        return self.isSignedRuntimeStatus(s.Status);
      });

      // Nếu hồ sơ chưa được ký, thông tin có sự thay đổi, và có cấu hình template docx, ta ép dùng file mẫu để merge lại
      var originalTemplate = this.resolveOriginalTemplateFile()
      var forceUseTemplate = !hasSigned && hashChanged && originalTemplate && String(originalTemplate.FileName || "").toLowerCase().match(/\.docx?$/)
      if (forceUseTemplate) {
        fileId = originalTemplate.FileID
        name = originalTemplate.FileName
        isDoc = true
      }

      // File đã ký đang được giữ trong memory → không được đụng chạm gì cả
      if (!hashChanged && this.lastMergedFileId && this.lastMergedFileId === fileId && this.mergedPdfUrl) {
        return;
      }
 
      if (!fileId || !isDoc) {
        if (this.mergedPdfUrl && this.mergedPdfUrl.indexOf("blob:") === 0) {
          URL.revokeObjectURL(this.mergedPdfUrl);
        }
        this.mergedPdfUrl = "";
        this.lastMergedFileId = "";
        this.lastMergedPdfBase64 = "";
        this.lastMergedAnchors = [];
        this.lastMergedFieldsHash = "";
        this.lastMergedSignersHash = "";
        if (fileId) {
          try {
            var pdfBinary = await this.tryReadFileBinaryById(fileId);
            if (pdfBinary) {
              var normPdf = String(pdfBinary).indexOf("base64,") >= 0
                ? String(pdfBinary).split("base64,").pop().replace(/\s+/g, "")
                : String(pdfBinary).replace(/\s+/g, "");
              if (normPdf) {
                this.lastMergedPdfBase64 = normPdf;
                this.lastMergedFileId = fileId;
                this.lastMergedFieldsHash = currentFieldsHash;
                this.lastMergedSignersHash = currentSignersHash;
                this.mergedPdfUrl = this.base64ToBlobUrl(normPdf, "application/pdf");
              }
            }
          } catch (e) {
            console.warn("[WF] checkAndMergeDocx: Không thể load PDF binary:", e);
          }
        }
        return;
      }
      
      // Skip nếu đã merge cùng file và vẫn còn mergedPdfUrl và hash không đổi.
      // Nếu signBoxes đã bị reset (PosX=0) do applyDetailData reload, tái áp dụng anchors từ cache
      // thay vì re-merge lại toàn bộ (tránh xóa chữ ký cũ - Bug 2 fix).
      if (!hashChanged && this.lastMergedFileId === fileId && this.mergedPdfUrl) {
        var signBoxesSynced = (this.signBoxes || []).every(function (b) { return b.PosX > 0 || b.PosY > 0; });
        if (!signBoxesSynced && this.lastMergedAnchors && this.lastMergedAnchors.length) {
          this.signBoxes = this.applyAnchorsToSignBoxes(this.signBoxes, this.lastMergedAnchors, this.signBoxes.length);
        }
        return;
      }
      
      this.isMergingPdf = true;
      try {
        var binary = await this.tryReadFileBinaryById(fileId);
        if (binary.indexOf("base64,") >= 0) binary = binary.split("base64,").pop() || "";
        binary = binary.replace(/\s+/g, "");
 
        if (!binary) {
          throw new Error("Không lấy được binary của file word.");
        }

        // Safety net: dù extension là .docx nhưng nếu content thực tế là PDF (base64 của "%PDF-" = "JVBER")
        // → đây là file đã ký, dùng trực tiếp thay vì merge lại từ đầu (sẽ mất chữ ký cũ)
        if (binary.substring(0, 5).toUpperCase() === "JVBER") {
          this.lastMergedPdfBase64 = binary;
          if (this.mergedPdfUrl && this.mergedPdfUrl.indexOf("blob:") === 0) URL.revokeObjectURL(this.mergedPdfUrl);
          this.mergedPdfUrl = this.base64ToBlobUrl(binary, "application/pdf");
          this.isMergingPdf = false;
          return;
        }
        
        var fields = [];
        // Build a set of field names that are 'signature' type → skip them to preserve anchor placeholders
        var signatureFieldNames = {};
        (this.fields || []).forEach(function (f) {
          if (f.FieldType === "signature") signatureFieldNames[String(f.FieldName || "").trim()] = true;
        });
        // Also collect from signBoxes LabelText (fallback)
        (this.signBoxes || []).forEach(function (box) {
          if (box.LabelText) {
            var m = box.LabelText.match(/^###(.+)###$/) || box.LabelText.match(/^\{\{(.+)\}\}$/);
            signatureFieldNames[m ? m[1] : box.LabelText] = true;
          }
        });
        (this.fields || []).forEach(function (f) {
          var key = String(f.FieldName || "").trim();
          var val = f.FieldValue == null ? "" : String(f.FieldValue);
          if (!key) return;
          // Skip signature fields entirely to preserve anchor placeholders in docx
          if (signatureFieldNames[key]) return;
          fields.push({ Key: key, Value: val });
          fields.push({ Key: "###" + key + "###", Value: val });
          fields.push({ Key: "{{" + key + "}}", Value: val });
        });
        
        // Build SignBoxes payload để API trả về signatureAnchors (tọa độ chính xác trong PDF)
        var signBoxRows = (this.signBoxes || []).map(function (box) {
          return {
            BoxOrder: box.BoxOrder || 0,
            SignerOrder: box.SignerOrder || 0,
            LabelText: box.LabelText || "",
            PageNo: box.PageNo || 1,
            PosX: box.PosX || 0,
            PosY: box.PosY || 0,
            BoxWidth: box.BoxWidth || 0,
            BoxHeight: box.BoxHeight || 0
          };
        });

        var res = await this.econtractRequest("POST", "/api/pdf/merge-docx-template-to-pdf", {
          FileBase64: binary,
          FileName: name || "template.docx",
          Fields: fields,
          SignBoxes: signBoxRows.length ? signBoxRows : undefined
        }, "");

        var pdfBase64 = res.PdfBase64 || res.pdfBase64 || res.FileBase64 || res.fileBase64 || "";
        if (pdfBase64) {
          if (pdfBase64.indexOf("base64,") >= 0) pdfBase64 = pdfBase64.split("base64,").pop() || "";
          pdfBase64 = pdfBase64.replace(/\s+/g, "");

          var uploadRes = await apiCallAsync("UPLOAD_FileData_Base64", {
            FileBase64: pdfBase64,
            FileName: (name ? name.replace(/\.docx?$/i, "") : "document") + ".pdf",
            FileContentType: "application/pdf"
          });
          var uploadRow = uploadRes && uploadRes[0] ? uploadRes[0] : null;
          if (!uploadRow && uploadRes && uploadRes.data && uploadRes.data[0]) {
            uploadRow = uploadRes.data[0][0] || uploadRes.data[0];
          }

          if (uploadRow && uploadRow.FileID) {
            await apiCallAsync("WF_Execution_SaveDocument", {
              InstanceID: this.instanceId,
              ExecutionID: this.overview.CurrentExecutionID,
              FileID: uploadRow.FileID,
              FileName: uploadRow.FileName || ("WF-" + this.instanceId + ".pdf")
            });

            this.lastMergedPdfBase64 = pdfBase64;
            this.lastMergedFileId = fileId;
            this.lastMergedFieldsHash = currentFieldsHash;
            this.lastMergedSignersHash = currentSignersHash;
            this.overview.CurrentDocumentFileID = uploadRow.FileID;
            this.overview.CurrentDocumentFileUrl = "https://file.zentea.vn/iotdev/FileData/" + uploadRow.FileID;
            this.overview.CurrentDocumentFileName = uploadRow.FileName || this.overview.CurrentDocumentFileName;

            if (this.mergedPdfUrl && this.mergedPdfUrl.indexOf("blob:") === 0) {
              URL.revokeObjectURL(this.mergedPdfUrl);
            }
            this.mergedPdfUrl = this.base64ToBlobUrl(pdfBase64, "application/pdf");
          } else {
            throw new Error("Không upload được bản PDF merge lên hệ thống");
          }
        } else {
          throw new Error("API không trả về PdfBase64");
        }

        // Cập nhật tọa độ signBoxes từ signatureAnchors trả về
        var anchors = (res.signatureAnchors || res.SignatureAnchors) || [];
        // Cache anchors để tái dùng khi applyDetailData reset signBoxes về PosX=0 (Bug 1 fix)
        this.lastMergedAnchors = anchors.slice();
        if (anchors.length) {
          this.signBoxes = this.applyAnchorsToSignBoxes(this.signBoxes, anchors, signBoxRows.length);
          // Persist vị trí ký vào DB để signer tiếp theo dùng đúng tọa độ
          try {
            var signBoxesForPersist = (this.signBoxes || [])
              .filter(function (b) { return b.InstanceSignBoxID && b.PageNo != null && b.PosX != null && b.PosY != null; })
              .map(function (b) {
                return {
                  InstanceSignBoxID: b.InstanceSignBoxID,
                  PageNo: b.PageNo,
                  PosX: b.PosX,
                  PosY: b.PosY,
                  BoxWidth: b.BoxWidth,
                  BoxHeight: b.BoxHeight
                }
              });
            if (signBoxesForPersist.length) {
              await apiCallAsync("WF_InstanceSignBox_UpdatePositions", {
                InstanceID: this.instanceId,
                SignBoxesJSON: JSON.stringify(signBoxesForPersist)
              });
            }
          } catch (persistErr) {
            console.warn("[WF] checkAndMergeDocx: Không thể persist vị trí signBoxes:", persistErr);
          }
        }
      } catch (err) {
        console.error("Lỗi khi trộn tài liệu Word to PDF:", err);
        if (showToast && showToast.error) showToast.error("Lỗi khi trộn dữ liệu và tạo bản xem trước PDF từ Word.");
      } finally {
        this.isMergingPdf = false;
      }
    }
  }
	}
</script>