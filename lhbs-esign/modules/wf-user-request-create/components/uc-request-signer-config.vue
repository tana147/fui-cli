<template>
	<div>
    <div class="wf-request-panel__header">
      <div>
        <h3>Người ký và thứ tự xử lý</h3>
        <p>{{ createMode === 'FREE_SIGN' ? 'Thiết lập trực tiếp danh sách người ký cho văn bản này.' : 'Danh sách này
          đang được suy ra từ workflow đã chọn. Bạn có thể tinh chỉnh role và phương thức ký cho Phase 2.' }}</p>
      </div>
      <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="$emit('add-signer')">
        <v-icon start size="16">mdi-account-plus</v-icon>
        Thêm người ký
      </v-btn>
    </div>
    <div v-if="form.signers.length === 0" class="wf-empty-state">
      Workflow này chưa có người ký mặc định. Bấm “Thêm người ký” để bổ sung flow ký.
    </div>
    <div v-else>
      <div v-for="(signer, index) in form.signers" :key="signer.localId" class="wf-request-signer-card">
        <v-icon size="16" color="grey-lighten-1">mdi-drag-vertical</v-icon>
        <div class="wf-request-signer-card__order">{{ index + 1 }}</div>
        <div class="wf-request-signer-card__body">
          <div class="wf-request-form-grid wf-request-form-grid--3">
            <v-select v-model="signer.roleCode" :items="roleOptions" item-title="RoleName" item-value="RoleCode"
              label="Role" variant="outlined" density="compact"
              @update:modelValue="$emit('update-signer-role', signer)" />
            <v-autocomplete :model-value="resolveSignerPersonCode(signer)" :items="signerProfileOptions"
              item-title="title" item-value="value" label="Người ký" variant="outlined" density="compact" clearable
              @update:modelValue="onSignerPersonChanged(signer, $event)" />
            <v-select v-model="signer.method" :items="signMethodOptions" label="Phương thức ký" variant="outlined"
              density="compact" @update:modelValue="$emit('signer-method-changed', signer)" />
          </div>
          <div class="wf-request-signer-card__meta">
            <span>Bước: {{ signer.stepName || "Ad-hoc" }}</span>
            <span>Bộ phận: {{ signer.departmentName || "Chưa rõ" }}</span>
            <span v-if="signer.system">Hệ thống: {{ signer.system }}</span>
          </div>
        </div>
        <v-btn icon size="x-small" variant="text" color="error" @click="$emit('remove-signer', index)">
          <v-icon size="16">mdi-close</v-icon>
        </v-btn>
      </div>
    </div>
    <div class="wf-request-switch-row">
      <v-switch v-model="form.sequential" label="Ký tuần tự" density="compact" hide-details color="primary" />
      <v-switch v-model="form.notifyEmail" label="Gửi email thông báo" density="compact" hide-details color="primary" />
      <v-switch v-model="form.requireOtpConfirm" label="Yêu cầu xác nhận OTP ở bước ngoài trường" density="compact"
        hide-details color="primary" />
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-request-signer-config",
  props: {
    createMode: { type: String, default: "TEMPLATE_FLOW" },
    form: { type: Object, default: function () { return { signers: [] }; } },
    roleOptions: { type: Array, default: function () { return []; } },
    signMethodOptions: { type: Array, default: function () { return []; } },
    signerProfiles: { type: Array, default: function () { return []; } },
    requireCertForSmartca: { type: Boolean, default: false }
  },
  computed: {
    signerProfileOptions: function () {
      var self = this;
      return (this.signerProfiles || []).map(function (item) {
        var name = String(item.FullName || item.EmployeeCode || item.Email || "Người ký").trim();
        var code = String(item.EmployeeCode || "").trim();
        var cert = String(item.CertSerial || "").trim();
        var certUsable = self.isCertUsable(item);
        var title = name;
        if (code) title += " (" + code + ")";
        if (cert) title += " · CTS " + cert + (certUsable ? " (active)" : " (không hợp lệ)");
        return {
          title: title,
          value: code || String(item.Email || "").trim(),
          personName: name,
          certUsable: certUsable
        };
      }).filter(function (item) {
        if (!item.value) return false;
        if (self.requireCertForSmartca && !item.certUsable) return false;
        return true;
      });
    }
  },
  methods: {
    isCertUsable: function (profile) {
      var now = Date.now();
      var validFrom = null;
      var validTo = null;
      if (!profile) return false;
      if (!Number(profile.IsActive || 0) || !Number(profile.CertIsActive || 0)) return false;
      if (!String(profile.CertSerial || "").trim()) return false;
      validFrom = profile.CertValidFrom ? new Date(profile.CertValidFrom).getTime() : null;
      validTo = profile.CertValidTo ? new Date(profile.CertValidTo).getTime() : null;
      if (validFrom && !Number.isNaN(validFrom) && now < validFrom) return false;
      if (validTo && !Number.isNaN(validTo) && now > validTo) return false;
      return true;
    },
    resolveSignerPersonCode: function (signer) {
      if (signer && signer.personCode) return signer.personCode;
      if (signer && signer.signerType === "USER" && signer.roleCode) return signer.roleCode;
      return "";
    },
    onSignerPersonChanged: function (signer, personCode) {
      this.$emit("update-signer-person", { signer: signer, personCode: personCode || "" });
    }
  }
	}
</script>