<template>
	<div class="wf-request-stepper" :class="{ 'wf-request-stepper--compact': compact }">
    <div class="wf-request-stepper__title">{{ compact ? 'Các bước' : 'Tạo yêu cầu ký' }}</div>
    <div v-for="(item, index) in wizardSteps" :key="item.key" class="wf-request-stepper__item"
      :class="{ active: currentStep === index, done: currentStep > index }" :title="item.title">
      <div class="wf-request-stepper__dot">
        <v-icon v-if="currentStep > index" size="14" color="white">mdi-check</v-icon>
        <span v-else>{{ index + 1 }}</span>
      </div>
      <div class="wf-request-stepper__body">
        <div class="wf-request-stepper__name">{{ item.title }}</div>
        <div class="wf-request-stepper__sub">{{ item.sub }}</div>
      </div>
    </div>

    <div v-if="!hideSummary" class="wf-request-sidecard">
      <div class="wf-request-sidecard__title">Tổng quan nhanh</div>
      <div class="wf-info-row">
        <span class="label">Workflow</span>
        <span class="value">{{ selectedDefinitionName || "Chưa chọn" }}</span>
      </div>
      <div class="wf-info-row">
        <span class="label">Template</span>
        <span class="value">{{ selectedTemplateName }}</span>
      </div>
      <div class="wf-info-row">
        <span class="label">Người ký</span>
        <span class="value">{{ signerCount }} người</span>
      </div>
      <div class="wf-info-row" style="border-bottom:none;">
        <span class="label">Dữ liệu form</span>
        <span class="value">{{ fieldCount }} trường</span>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-request-stepper",
  props: {
    wizardSteps: { type: Array, default: function () { return []; } },
    currentStep: { type: Number, default: 0 },
    selectedDefinitionName: { type: String, default: "" },
    selectedTemplateName: { type: String, default: "Chưa chọn" },
    signerCount: { type: Number, default: 0 },
    fieldCount: { type: Number, default: 0 },
    compact: { type: Boolean, default: false },
    hideSummary: { type: Boolean, default: false }
  }
	}
</script>