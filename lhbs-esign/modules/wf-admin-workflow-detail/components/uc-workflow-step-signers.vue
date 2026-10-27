<template>
	<div v-if="['SIGN', 'ECONTRACT'].includes(activeStep.StepType)" class="wf-editor-section">
    <div class="d-flex align-center justify-space-between wf-editor-section__label-row">
      <div class="wf-editor-section__label">
        <v-icon size="12" class="mr-1" color="primary">mdi-draw-pen</v-icon>
        Danh sách người ký (Riêng bước Ký)
      </div>
      <v-btn variant="text" color="primary" size="x-small" class="font-weight-bold" @click="$emit('add-signer')">
        <v-icon start size="13">mdi-plus</v-icon> Thêm người ký
      </v-btn>
    </div>

    <!-- Signer cards -->
    <div v-if="activeStep.signers && activeStep.signers.length" class="mt-2">
      <div v-for="(signer, signerIdx) in activeStep.signers" :key="signerIdx" class="wf-signer-card">
        <!-- Index badge -->
        <div class="wf-signer-card__index">{{ signerIdx + 1 }}</div>

        <!-- Fields body -->
        <div class="wf-signer-card__body">
          <!-- Loại -->
          <div class="wf-signer-card__field wf-signer-card--type">
            <span class="wf-signer-card__label">Loại</span>
            <v-select v-model="signer.SignerType" :items="signerTypeOptions" item-title="label" item-value="value"
              density="compact" variant="plain" hide-details class="wf-compact-select"
              @update:modelValue="signer.SignerValue = ''" />
          </div>

          <!-- Divider -->
          <v-divider vertical class="wf-signer-card__divider" />

          <!-- Người phụ trách -->
          <div class="wf-signer-card__field wf-signer-card--person">
            <span class="wf-signer-card__label">Người phụ trách</span>
            <v-select v-if="signer.SignerType === 'ROLE'" v-model="signer.SignerValue" :items="roleOptions"
              item-title="title" item-value="value" density="compact" variant="plain" hide-details
              class="wf-compact-select" />
            <uc-select-user v-else v-model="signer.SignerValue" density="compact" variant="plain" hide-details
              class="wf-compact-select" placeholder="Chọn nhân viên..." />
          </div>

          <!-- Divider -->
          <v-divider v-if="stepRequiresSigner(activeStep.StepType)" vertical class="wf-signer-card__divider" />

          <!-- Cách ký -->
          <div v-if="stepRequiresSigner(activeStep.StepType)" class="wf-signer-card__field wf-signer-card--method">
            <span class="wf-signer-card__label">Cách ký</span>
            <v-select v-model="signer.SignMethod" :items="signMethodOptions" item-title="label" item-value="value"
              density="compact" variant="plain" hide-details class="wf-compact-select" />
          </div>
        </div>

        <!-- Remove btn -->
        <v-btn icon size="x-small" variant="text" color="error" @click="$emit('remove-signer', signerIdx)">
          <v-icon size="14">mdi-close</v-icon>
        </v-btn>
      </div>
    </div>

    <div v-else class="wf-empty-box mt-2" style="font-size: 11px;">
      Chưa có người ký. Bấm "Thêm" để cấu hình danh sách ký.
    </div>
  </div>
</template>

<script>
	export default {
		props: {
    activeStep: { type: Object, required: true },
    roleOptions: { type: Array, required: true },
    signerTypeOptions: { type: Array, required: true },
    signMethodOptions: { type: Array, required: true }
  },
  methods: {
    stepRequiresSigner: function (type) {
      return ["SIGN", "ECONTRACT"].includes(type);
    }
  }
	}
</script>