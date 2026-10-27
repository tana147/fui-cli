<template>
	<uc-wf-shell :show-user-section="false">
    <div class="wf-page-header">
      <div>
        <h1>Hồ sơ người dùng</h1>
        <p>Lưu thông tin người dùng, chứng thư số SmartCA và chữ ký hiển thị dùng cho flow ký nội bộ.</p>
      </div>
      <div class="d-flex ga-2">
        <v-btn class="wf-btn" variant="outlined" color="primary" @click="goBack">
          <v-icon start="">mdi-arrow-left</v-icon>
          Quay lại
        </v-btn>
        <v-btn class="wf-btn" variant="outlined" color="primary" :loading="isSaving" @click="saveProfile">
          <v-icon start="">mdi-content-save-outline</v-icon>
          Lưu hồ sơ
        </v-btn>
      </div>
    </div>

    <div class="wf-tcard">
      <div class="wf-tcard-toolbar">
        <h3>Thông tin người dùng</h3>
      </div>
      <div class="wf-template-dialog-body">
        <v-row dense="">
          <v-col cols="12" md="3">
            <v-text-field v-model="form.LegacyUserID" label="NguoiDungID (tham chiếu)" type="number" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="5">
            <v-text-field v-model="form.FullName" label="Họ tên *" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.EmployeeCode" label="Mã nhân viên" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.Email" label="Email" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.JobTitle" label="Chức vụ" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.DepartmentName" label="Đơn vị" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="3">
            <v-switch v-model="form.IsInternalUser" color="primary" density="compact" hide-details="" label="Người dùng nội bộ">
          </v-switch></v-col>
          <v-col cols="12" md="3">
            <v-switch v-model="form.IsActive" color="primary" density="compact" hide-details="" label="Hồ sơ hoạt động">
          </v-switch></v-col>
        </v-row>
      </div>
    </div>

    <div class="wf-tcard" style="margin-top: 14px;">
      <div class="wf-tcard-toolbar">
        <h3>Chứng thư số SmartCA</h3>
      </div>
      <div class="wf-template-dialog-body">
        <v-row dense="">
          <v-col cols="12" md="4">
            <v-text-field v-model="form.CertSerial" label="CTS Serial" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="4">
            <v-text-field v-model="form.CertIssuer" label="CTS Issuer" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="4">
            <v-switch v-model="form.CertIsActive" color="primary" density="compact" hide-details="" label="CTS đang active">
          </v-switch></v-col>
          <v-col cols="12">
            <v-textarea v-model="form.CertSubject" rows="3" label="CTS Subject" variant="outlined" density="compact">
          </v-textarea></v-col>
          <v-col cols="12" md="6">
            <v-text-field :model-value="certValidFromInput" type="datetime-local" label="CTS Valid From" variant="outlined" density="compact" @update:model-value="onCertValidFromChanged">
          </v-text-field></v-col>
          <v-col cols="12" md="6">
            <v-text-field :model-value="certValidToInput" type="datetime-local" label="CTS Valid To" variant="outlined" density="compact" @update:model-value="onCertValidToChanged">
          </v-text-field></v-col>
        </v-row>
      </div>
    </div>

    <div class="wf-tcard" style="margin-top: 14px;">
      <div class="wf-tcard-toolbar">
        <h3>Thông tin chữ ký hiển thị</h3>
      </div>
      <div class="wf-template-dialog-body">
        <v-row dense="">
          <v-col cols="12" md="6">
            <v-text-field v-model="form.SignatureDisplayName" label="Nhãn chữ ký hiển thị" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.SignatureFileID" label="Signature FileID (tblFileData)" variant="outlined" density="compact">
          </v-text-field></v-col>
          <v-col cols="12" md="6">
            <div class="d-flex align-center ga-2">
              <v-btn class="wf-btn" variant="outlined" color="primary" @click="$refs.signatureUpload &amp;&amp; $refs.signatureUpload.click()">
                <v-icon start="">mdi-upload</v-icon>
                Upload ảnh chữ ký
              </v-btn>
              <input ref="signatureUpload" type="file" accept="image/*" class="d-none" @change="onSignatureSelected">
            </div>
            <div class="wf-audit-sub mt-1">Có thể nhập thẳng FileID hoặc upload để hệ thống tự lấy FileID từ
              tblFileData.</div>
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
  </uc-wf-shell>
</template>

<script>
	export default {
		data: function () {
    return {
      isSaving: false,
      isUploadingSignature: false,
      form: this.getEmptyForm(),
      certValidFromInput: "",
      certValidToInput: ""
    };
  },
  computed: {
    profileId: function () {
      var params = new URLSearchParams(window.location.search || "");
      return Number(params.get("id") || 0);
    },
    signaturePreviewUrl: function () {
      var fileId = String(this.form.SignatureFileID || "").trim();
      if (!fileId) return "";
      return "https://file.zentea.vn/iotdev/FileData/" + fileId;
    }
  },
  mounted: function () {
    this.loadDetail();
  },
  methods: {
    getEmptyForm: function () {
      return {
        UserID: 0,
        LegacyUserID: "",
        FullName: "",
        Email: "",
        EmployeeCode: "",
        IsInternalUser: true,
        JobTitle: "",
        DepartmentName: "",
        CertSerial: "",
        CertSubject: "",
        CertIssuer: "",
        CertValidFrom: "",
        CertValidTo: "",
        CertIsActive: true,
        SignatureDisplayName: "",
        SignatureFileID: "",
        SignatureNote: "",
        IsActive: true
      };
    },
    loadDetail: async function () {
      try {
        var rows = await apiCallAsync("WF_User_GetDetail", { UserID: this.profileId });
        var row = rows && rows[0] ? rows[0] : this.getEmptyForm();
        this.form = Object.assign(this.getEmptyForm(), row || {});
        this.certValidFromInput = this.toDatetimeLocal(this.form.CertValidFrom);
        this.certValidToInput = this.toDatetimeLocal(this.form.CertValidTo);
      } catch (err) {
        this.showError(err, "Không tải được hồ sơ người ký.");
      }
    },
    toDatetimeLocal: function (value) {
      if (!value) return "";
      var dt = new Date(value);
      if (Number.isNaN(dt.getTime())) return "";
      var yyyy = dt.getFullYear();
      var mm = String(dt.getMonth() + 1).padStart(2, "0");
      var dd = String(dt.getDate()).padStart(2, "0");
      var hh = String(dt.getHours()).padStart(2, "0");
      var mi = String(dt.getMinutes()).padStart(2, "0");
      return yyyy + "-" + mm + "-" + dd + "T" + hh + ":" + mi;
    },
    onCertValidFromChanged: function (value) {
      this.certValidFromInput = value || "";
      this.form.CertValidFrom = value ? new Date(value).toISOString() : "";
    },
    onCertValidToChanged: function (value) {
      this.certValidToInput = value || "";
      this.form.CertValidTo = value ? new Date(value).toISOString() : "";
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
          if (showToast && showToast.success) showToast.success("Upload ảnh chữ ký thành công.");
          self.isUploadingSignature = false;
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
    validateForm: function () {
      if (!(this.form.FullName || "").trim()) return "Họ tên người dùng không được để trống.";
      if (this.form.Email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.form.Email)) return "Email không hợp lệ.";
      if (this.form.CertValidFrom && this.form.CertValidTo) {
        var from = new Date(this.form.CertValidFrom).getTime();
        var to = new Date(this.form.CertValidTo).getTime();
        if (!Number.isNaN(from) && !Number.isNaN(to) && from > to) return "CTS Valid From phải nhỏ hơn hoặc bằng CTS Valid To.";
      }
      return "";
    },
    buildSavePayload: function () {
      return {
        UserID: Number(this.form.UserID || this.profileId || 0),
        LegacyUserID: this.form.LegacyUserID === "" || this.form.LegacyUserID === null ? null : Number(this.form.LegacyUserID),
        FullName: (this.form.FullName || "").trim(),
        Email: (this.form.Email || "").trim(),
        EmployeeCode: (this.form.EmployeeCode || "").trim(),
        IsInternalUser: this.form.IsInternalUser ? true : false,
        JobTitle: (this.form.JobTitle || "").trim(),
        DepartmentName: (this.form.DepartmentName || "").trim(),
        CertSerial: (this.form.CertSerial || "").trim(),
        CertSubject: (this.form.CertSubject || "").trim(),
        CertIssuer: (this.form.CertIssuer || "").trim(),
        CertValidFrom: this.form.CertValidFrom || null,
        CertValidTo: this.form.CertValidTo || null,
        CertIsActive: this.form.CertIsActive ? true : false,
        SignatureDisplayName: (this.form.SignatureDisplayName || "").trim(),
        SignatureFileID: (this.form.SignatureFileID || "").trim(),
        SignatureNote: (this.form.SignatureNote || "").trim(),
        IsActive: this.form.IsActive ? true : false
      };
    },
    saveProfile: function () {
      var self = this;
      var message = this.validateForm();
      if (message) {
        if (showToast && showToast.error) showToast.error(message);
        return;
      }
      this.isSaving = true;
      apiCall("WF_User_Save", this.buildSavePayload(), function (res) {
        var row = res && res.data && res.data[0] && res.data[0][0] ? res.data[0][0] : null;
        var nextId = row && row.UserID ? Number(row.UserID) : Number(self.profileId || 0);
        if (showToast && showToast.success) showToast.success(row && row.Message ? row.Message : "Lưu hồ sơ thành công.");
        self.isSaving = false;
        if (nextId > 0) window.location.href = "/wf-admin-signer-detail?id=" + nextId;
        else self.goBack();
      }, function (err) {
        self.isSaving = false;
        self.showError(err, "Không lưu được hồ sơ người ký.");
      });
    },
    goBack: function () {
      window.location.href = "/wf-admin-signer-directory";
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