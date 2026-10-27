<template>
	<uc-wf-shell title="Ký số LHBS" subtitle="Cấu hình chữ ký cá nhân">
    <div class="wf-page-header">
      <div>
        <h1>Cấu hình chữ ký của tôi</h1>
        <p>Người dùng tự chọn kiểu ký SmartCA và cập nhật chữ ký hiển thị dùng cho lúc ký tài liệu.</p>
      </div>
      <div class="d-flex ga-2">
        <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isLoading" @click="loadConfig">
          <v-icon start="">mdi-refresh</v-icon>
          Làm mới
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSaving" @click="saveConfig">
          <v-icon start="">mdi-content-save-outline</v-icon>
          Lưu cấu hình
        </v-btn>
      </div>
    </div>

    <div v-if="!profileReady &amp;&amp; !isLoading" class="wf-empty-state">
      Chưa tìm thấy hồ sơ signer đang hoạt động của bạn. Vui lòng liên hệ quản trị để được gán hồ sơ ký.
    </div>

    <div v-if="profileReady" class="wf-user-sign-config">
      <div class="wf-tcard">
        <div class="wf-tcard-toolbar">
          <h3>Thông tin cá nhân</h3>
        </div>
        <div class="wf-user-sign-config__grid">
          <div class="wf-user-sign-config__info">
            <div class="wf-info-row"><span class="label">Mã nhân viên</span><span class="value">{{ form.EmployeeCode || '-' }}</span></div>
            <div class="wf-info-row"><span class="label">Họ tên</span><span class="value">{{ form.FullName || '-' }}</span></div>
            <div class="wf-info-row"><span class="label">Email</span><span class="value">{{ form.Email || '-' }}</span></div>
            <div class="wf-info-row"><span class="label">Chức vụ</span><span class="value">{{ form.JobTitle || '-' }}</span></div>
            <div class="wf-info-row"><span class="label">Đơn vị</span><span class="value">{{ form.DepartmentName || '-' }}</span></div>
          </div>
          <div class="wf-user-sign-config__info">
            <div class="wf-info-row"><span class="label">Số CCCD/CTS</span><span class="value">{{ form.CertSubject || form.CertSerial || '-' }}</span></div>
            <div class="wf-info-row"><span class="label">Issuer</span><span class="value">{{ form.CertIssuer || '-' }}</span></div>
            <div class="wf-info-row"><span class="label">Hiệu lực từ</span><span class="value">{{ formatDate(form.CertValidFrom) }}</span></div>
            <div class="wf-info-row"><span class="label">Hiệu lực đến</span><span class="value">{{ formatDate(form.CertValidTo) }}</span></div>
            <div class="wf-info-row"><span class="label">Trạng thái</span><span class="value" :class="{ 'wf-text-success': form.CertIsActive }">{{ form.CertIsActive ? 'VALID' : 'INACTIVE' }}</span></div>
          </div>
        </div>
      </div>

      <div class="wf-tcard">
        <div class="wf-tcard-toolbar">
          <h3>Tùy chọn ký SmartCA</h3>
        </div>
        <div class="wf-template-dialog-body">
          <v-row dense="">
            <v-col cols="12" md="7">
              <v-select v-model="form.SmartCAOptionSign" :items="optionSignItems" item-title="label" item-value="value" label="Kiểu ký SmartCA" variant="outlined" density="compact">
              <div class="wf-audit-sub">
                Hệ thống sẽ dùng lựa chọn này khi gọi SmartCA cho tài khoản của bạn. Nếu chọn ký ảnh mà chưa có ảnh chữ ký, runtime sẽ tự fallback sang ảnh chữ ký text sinh từ họ tên.
              </div>
            </v-select></v-col>
            <v-col cols="12" md="5">
              <div class="wf-user-sign-config__mode-card">
                <div class="wf-user-sign-config__mode-label">Kiểu ký đang chọn</div>
                <div class="wf-user-sign-config__mode-value">{{ form.SmartCAOptionSign === '0' ? 'Ký text' : 'Ký ảnh' }}</div>
                <div class="wf-user-sign-config__mode-note">SmartCA OptionSign = {{ form.SmartCAOptionSign === '0' ? '0' : '1' }}</div>
              </div>
            </v-col>
          </v-row>
        </div>
      </div>

      <div class="wf-tcard">
        <div class="wf-tcard-toolbar">
          <h3>Chữ ký hiển thị</h3>
        </div>
        <div class="wf-template-dialog-body">
          <v-row dense="">
            <v-col cols="12" md="6">
              <v-text-field v-model="form.SignatureDisplayName" label="Tên chữ ký hiển thị" variant="outlined" density="compact">
            </v-text-field></v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.SignatureFileID" label="Signature FileID" variant="outlined" density="compact">
            </v-text-field></v-col>
            <v-col cols="12" md="6">
              <div class="d-flex align-center ga-2">
                <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isUploadingSignature" @click="$refs.signatureUpload &amp;&amp; $refs.signatureUpload.click()">
                  <v-icon start="">mdi-upload</v-icon>
                  Upload ảnh chữ ký
                </v-btn>
                <input ref="signatureUpload" type="file" accept="image/*" class="d-none" @change="onSignatureSelected">
              </div>
              <div class="wf-audit-sub mt-2">Có thể nhập trực tiếp `FileID` hoặc upload ảnh để hệ thống tự lấy `tblFileData`.</div>
            </v-col>
            <v-col cols="12" md="6">
              <div class="wf-audit-sub">Preview</div>
              <div class="wf-signer-preview-box">
                <img v-if="signaturePreviewUrl" :src="signaturePreviewUrl" alt="signature-preview" class="wf-signer-preview-image">
                <span v-else="" class="wf-audit-sub">Chưa có ảnh chữ ký.</span>
              </div>
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.SignatureNote" rows="2" label="Ghi chú chữ ký" variant="outlined" density="compact">
            </v-textarea></v-col>
          </v-row>
        </div>
      </div>
    </div>
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
    return {
      isLoading: false,
      isSaving: false,
      isUploadingSignature: false,
      profileReady: false,
      form: this.getEmptyForm(),
      optionSignItems: [
        { label: "Ký ảnh", value: "1" },
        { label: "Ký text", value: "0" }
      ]
    };
  },
  computed: {
    signaturePreviewUrl: function () {
      var fileId = String(this.form.SignatureFileID || "").trim();
      if (!fileId) return "";
      return "https://file.zentea.vn/iotdev/FileData/" + fileId;
    }
  },
  mounted: function () {
    this.loadConfig();
  },
  methods: {
    getEmptyForm: function () {
      return {
        SignerProfileID: 0,
        FullName: "",
        Email: "",
        EmployeeCode: "",
        JobTitle: "",
        DepartmentName: "",
        CertSerial: "",
        CertSubject: "",
        CertIssuer: "",
        CertValidFrom: "",
        CertValidTo: "",
        CertIsActive: false,
        SmartCAOptionSign: "1",
        SignatureDisplayName: "",
        SignatureFileID: "",
        SignatureNote: ""
      };
    },
    loadConfig: async function () {
      this.isLoading = true;
      try {
        var rows = await apiCallAsync("WF_SignerProfile_GetMyConfig", {});
        var row = rows && rows[0] ? rows[0] : null;
        this.profileReady = !!row;
        this.form = Object.assign(this.getEmptyForm(), row || {});
        this.form.SmartCAOptionSign = String(this.form.SmartCAOptionSign || "1");
      } catch (err) {
        this.profileReady = false;
        this.form = this.getEmptyForm();
        this.showError(err, "Không tải được cấu hình chữ ký của bạn.");
      } finally {
        this.isLoading = false;
      }
    },
    saveConfig: async function () {
      if (!this.profileReady) {
        if (showToast && showToast.error) showToast.error("Chưa có hồ sơ signer hoạt động để lưu cấu hình.");
        return;
      }
      this.isSaving = true;
      try {
        var row = await apiCallAsync("WF_SignerProfile_SaveMyConfig", {
          SmartCAOptionSign: String(this.form.SmartCAOptionSign || "1"),
          SignatureDisplayName: (this.form.SignatureDisplayName || "").trim(),
          SignatureFileID: (this.form.SignatureFileID || "").trim(),
          SignatureNote: (this.form.SignatureNote || "").trim()
        });
        if (showToast && showToast.success) showToast.success((row && row.Message) || "Lưu cấu hình chữ ký thành công.");
        await this.loadConfig();
      } catch (err) {
        this.showError(err, "Không lưu được cấu hình chữ ký.");
      } finally {
        this.isSaving = false;
      }
    },
    onSignatureSelected: function (event) {
      var files = event && event.target ? event.target.files : null;
      if (!files || !files[0]) return;
      this.uploadSignatureImage(files[0]);
      if (event && event.target) event.target.value = "";
    },
    uploadSignatureImage: function (file) {
      var self = this;
      this.isUploadingSignature = true;
      var reader = new FileReader();
      reader.onload = function (evt) {
        var dataUrl = evt && evt.target ? String(evt.target.result || "") : "";
        var base64 = dataUrl.indexOf(",") >= 0 ? dataUrl.split(",")[1] : "";
        if (!base64) {
          self.isUploadingSignature = false;
          self.showError({ message: "Không đọc được ảnh chữ ký để upload." });
          return;
        }
        apiCall("UPLOAD_FileData_Base64", {
          FileBase64: base64,
          FileName: file.name || "signature.png",
          FileContentType: file.type || "image/png"
        }, function (res) {
          var row = self.pickUploadedFileRow(res);
          if (!row || !row.FileID) {
            self.isUploadingSignature = false;
            self.showError({ message: "Upload ảnh chữ ký không nhận được FileID." });
            return;
          }
          self.form.SignatureFileID = row.FileID;
          if (!self.form.SignatureDisplayName) self.form.SignatureDisplayName = self.form.FullName || row.FileName || "Chữ ký";
          self.isUploadingSignature = false;
          if (showToast && showToast.success) showToast.success("Upload ảnh chữ ký thành công.");
        }, function (err) {
          self.isUploadingSignature = false;
          self.showError(err, "Không upload được ảnh chữ ký.");
        });
      };
      reader.onerror = function () {
        self.isUploadingSignature = false;
        self.showError({ message: "Không đọc được ảnh chữ ký." });
      };
      reader.readAsDataURL(file);
    },
    pickUploadedFileRow: function (payload) {
      var row = null;
      if (payload && payload.Files && payload.Files[0]) row = payload.Files[0];
      else if (payload && payload.Result) row = payload.Result;
      else if (payload && payload.data && payload.data[0] && !Array.isArray(payload.data[0])) row = payload.data[0];
      else if (payload && payload.data && payload.data[0] && payload.data[0][0]) row = payload.data[0][0];
      else if (payload && payload.FileID) row = payload;
      if (!row) return null;
      return {
        FileID: row.FileID || row.FILE_ID || row.fileId || "",
        FileName: row.FileName || row.FILE_NAME || row.fileName || ""
      };
    },
    formatDate: function (value) {
      if (!value) return "-";
      var dt = new Date(value);
      if (Number.isNaN(dt.getTime())) return String(value);
      var dd = String(dt.getDate()).padStart(2, "0");
      var mm = String(dt.getMonth() + 1).padStart(2, "0");
      var yyyy = dt.getFullYear();
      return dd + "/" + mm + "/" + yyyy;
    },
    showError: function (err, fallback) {
      var message = "";
      if (err && err.responseJSON && err.responseJSON.Message) message = err.responseJSON.Message;
      else if (err && err.responseText) message = err.responseText;
      else if (err && err.message) message = err.message;
      else message = fallback || "Có lỗi xảy ra.";
      if (showToast && showToast.error) showToast.error(message);
    }
  }
	}
</script>