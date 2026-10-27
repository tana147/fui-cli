<template>
	<div class="wf-tcard wf-request-detail-card">
    <div class="wf-tcard-toolbar">
      <h3>Luồng ký &amp; các bước xử lý</h3>
    </div>

    <div v-if="groupedSteps.length" class="wf-request-flow-list">
      <div v-for="step in groupedSteps" :key="'step-' + step.ExecutionID" class="wf-request-flow-step">
        <div class="wf-request-flow-step__head">
          <div class="wf-request-flow-step__badge" :class="'status-' + normalizeStatus(step.Status)">
            {{ step.StepOrder }}
          </div>
          <div class="wf-request-flow-step__content">
            <div class="wf-request-flow-step__title-row">
              <div class="wf-request-flow-step__title">{{ step.StepName }}</div>
              <v-chip size="x-small" variant="tonal" color="primary" class="wf-chip-rounded">
                {{ formatStepType(step.StepType) }}
              </v-chip>
              <v-chip size="x-small" variant="outlined" color="primary" class="wf-chip-rounded">
                {{ formatStepStatus(step.Status) }}
              </v-chip>
            </div>
            <div class="wf-request-flow-step__meta">
              <span>{{ step.StepCode }}</span>
              <span v-if="step.TemplateName">Template: {{ step.TemplateName }}</span>
              <span v-if="step.SignSystem">Hệ thống: {{ formatMethod(step.SignSystem) }}</span>
              <span>{{ step.SignedCount }}/{{ step.TotalSignerCount }} người hoàn tất</span>
            </div>
            <div class="wf-request-flow-step__time">
              <span v-if="step.StartedDate">Bắt đầu: {{ formatDateTime(step.StartedDate) }}</span>
              <span v-if="step.CompletedDate">Hoàn tất: {{ formatDateTime(step.CompletedDate) }}</span>
              <span v-if="step.RejectedDate" class="wf-request-flow-step__reject">Từ chối: {{ formatDateTime(step.RejectedDate) }}</span>
            </div>
          </div>
        </div>

        <div class="wf-request-flow-signers">
          <div v-for="signer in step.signers" :key="'signer-' + signer.SignerExecID" class="wf-request-flow-signer">
            <div class="wf-request-flow-signer__index" :class="'status-' + normalizeStatus(signer.Status)">{{ signer.SignerOrder }}</div>
            <div class="wf-request-flow-signer__content">
              <div class="wf-request-flow-signer__name-row">
                <div class="wf-request-flow-signer__name">{{ signer.ResolvedPersonName || 'Chưa xác định' }}</div>
                <v-chip size="x-small" variant="outlined" color="primary" class="wf-chip-rounded">
                  {{ formatSignerStatus(signer.Status) }}
                </v-chip>
              </div>
              <div class="wf-request-flow-signer__meta">
                <span>{{ signer.ResolvedPersonID || '-' }}</span>
                <span>{{ formatMethod(signer.SignMethod) }}</span>
                <span v-if="signer.IsCurrentUser" class="wf-request-flow-signer__me">Tôi</span>
              </div>
              <div v-if="signer.SignedDate" class="wf-request-flow-signer__time">Đã ký lúc {{ formatDateTime(signer.SignedDate) }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-else="" class="wf-empty-state">
      Chưa có dữ liệu luồng ký cho yêu cầu này.
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-request-detail-flow",
  props: {
    steps: { type: Array, default: function () { return []; } },
    signers: { type: Array, default: function () { return []; } }
  },
  computed: {
    groupedSteps: function () {
      var result = [];
      var i = 0;
      var j = 0;
      for (i = 0; i < this.steps.length; i += 1) {
        result.push({
          ExecutionID: this.steps[i].ExecutionID,
          StepOrder: this.steps[i].StepOrder,
          StepCode: this.steps[i].StepCode,
          StepName: this.steps[i].StepName,
          StepType: this.steps[i].StepType,
          SignSystem: this.steps[i].SignSystem,
          TemplateName: this.steps[i].TemplateName,
          Status: this.steps[i].Status,
          StartedDate: this.steps[i].StartedDate,
          CompletedDate: this.steps[i].CompletedDate,
          RejectedDate: this.steps[i].RejectedDate,
          TotalSignerCount: this.steps[i].TotalSignerCount || 0,
          SignedCount: this.steps[i].SignedCount || 0,
          signers: []
        });
      }
      for (i = 0; i < result.length; i += 1) {
        for (j = 0; j < this.signers.length; j += 1) {
          if (this.signers[j].ExecutionID === result[i].ExecutionID) {
            result[i].signers.push(this.signers[j]);
          }
        }
      }
      return result;
    }
  },
  methods: {
    normalizeStatus: function (status) {
      return String(status || "").toLowerCase().replace(/_/g, "-");
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
    formatStepType: function (value) {
      var map = {
        SIGN: "Ký số",
        ECONTRACT: "Hợp đồng ĐT",
        REVIEW: "Xem & duyệt",
        INPUT_ONLY: "Nhập dữ liệu"
      };
      return map[value] || value || "-";
    },
    formatStepStatus: function (value) {
      var map = {
        PENDING: "Chờ tới bước",
        ACTIVE: "Đang xử lý",
        SIGNING: "Đang ký",
        COMPLETED: "Hoàn tất",
        REJECTED: "Đã từ chối",
        CANCELLED: "Đã hủy"
      };
      return map[value] || value || "-";
    },
    formatSignerStatus: function (value) {
      var map = {
        PENDING: "Chưa tới lượt",
        WAITING: "Đang chờ ký",
        SIGNED: "Đã ký",
        REJECTED: "Từ chối",
        CANCELLED: "Đã hủy"
      };
      return map[value] || value || "-";
    },
    formatMethod: function (value) {
      var map = {
        smartca: "SmartCA",
        econtract: "eContract",
        otp_email: "OTP Email",
        otp_sms: "OTP SMS",
        image: "Ký ảnh"
      };
      return map[value] || value || "-";
    }
  }
	}
</script>