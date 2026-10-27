<template>
	<div class="wf-detail-step-list">
    <div class="d-flex align-center justify-space-between wf-detail-step-header">
      <div class="wf-section-title wf-detail-section-title">Danh sách bước</div>
      <v-btn class="wf-btn" variant="outlined" color="primary" size="small" @click="$emit('add-step')">
        <v-icon start size="14">mdi-plus</v-icon>
        Thêm bước
      </v-btn>
    </div>

    <div class="wf-detail-step-scroll-container">
      <transition-group name="wf-list" tag="div">
        <div v-for="(step, stepIdx) in steps" :key="step._id || stepIdx" class="wf-step-stack">
          <div v-if="isFirstTerminalStep(step, stepIdx)" class="wf-terminal-divider"></div>
          <div class="wf-step-card wf-step-card--builder" :class="{
              active: activeStepIdx === stepIdx,
              'wf-dragging': draggingStepIdx === stepIdx,
              'wf-drag-over-top': dragOverIdx === stepIdx && dragPos === 'top',
              'wf-drag-over-bottom': dragOverIdx === stepIdx && dragPos === 'bottom',
              'wf-step-card--success': step.StepType === 'SUCCESS',
              'wf-step-card--failure': step.StepType === 'FAILURE'
            }" @click="$emit('update:activeStepIdx', stepIdx)"
            :draggable="step.StepType !== 'SUCCESS' && step.StepType !== 'FAILURE'"
            @dragstart="onDragStart($event, stepIdx)" @dragover.prevent="onDragOver($event, stepIdx)"
            @drop="onDrop($event, stepIdx)" @dragend="onDragEnd" @dragleave="onDragLeave($event, stepIdx)">
            <div class="d-flex align-center wf-detail-step-row">
              <v-icon size="14" color="primary" class="wf-drag-handle">mdi-drag-vertical</v-icon>
              <div class="wf-step-badge" :class="getStepBadgeClass(step)">{{ stepIdx + 1 }}</div>
              <div class="wf-detail-step-content">
                <div class="wf-detail-step-name text-truncate" style="max-width: 150px;">{{ step.StepName }}
                </div>
                <div class="d-flex align-center wf-detail-step-meta">
                  <v-chip size="x-small" color="primary" variant="tonal" class="wf-chip-rounded wf-step-type-chip">{{
                    getStepTypeLabel(step.StepType) }}</v-chip>
                  <v-icon v-if="step.TemplateID" size="14" class="ml-1.5" color="primary"
                    title="Có đính kèm mẫu văn bản">mdi-file-document-outline</v-icon>
                </div>
              </div>
              <v-btn v-if="step.StepType !== 'SUCCESS' && step.StepType !== 'FAILURE'" icon size="x-small"
                variant="text" color="primary" @click.stop="$emit('remove-step', stepIdx)">
                <v-icon size="14" class="wf-icon-danger">mdi-close</v-icon>
              </v-btn>
            </div>
          </div>
          <div v-if="stepIdx < steps.length - 1" class="wf-builder-connector"></div>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script>
	export default {
		props: {
    steps: { type: Array, required: true },
    activeStepIdx: { type: Number, required: true },
    roles: { type: Array, default: () => [] }
  },
  data: function () {
    return {
      draggingStepIdx: null,
      dragOverIdx: null,
      dragPos: null
    }
  },
  methods: {
    getStepBadgeClass: function (step) {
      if (!step) return "";
      switch (step.StepType) {
        case "SIGN": return "wf-step-badge--sign";
        case "ECONTRACT": return "wf-step-badge--econtract";
        case "REVIEW": return "wf-step-badge--review";
        case "INPUT_ONLY": return "wf-step-badge--input";
        case "SUCCESS": return "wf-step-badge--success";
        case "FAILURE": return "wf-step-badge--failure";
        default: return "";
      }
    },
    getStepTypeLabel: function (type) {
      switch (type) {
        case "SIGN": return "Ký số";
        case "ECONTRACT": return "HĐ điện tử";
        case "REVIEW": return "Xem & duyệt";
        case "INPUT_ONLY": return "Nhập dữ liệu";
        case "SUCCESS": return "Thành công";
        case "FAILURE": return "Thất bại";
        default: return type;
      }
    },
    isFirstTerminalStep: function (step, idx) {
      if (step.StepType !== 'SUCCESS' && step.StepType !== 'FAILURE') return false
      var prev = this.steps[idx - 1]
      return !prev || (prev.StepType !== 'SUCCESS' && prev.StepType !== 'FAILURE')
    },
    getSignerSummary: function (step) {
      if (!step) return "";
      if (step.StepType === 'SUCCESS' || step.StepType === 'FAILURE') return "";
      if (!step.signers || !step.signers.length) return "";
      const $this = this;
      var labels = step.signers.map(function (s) {
        if (s.SignerType === 'ROLE') {
          var role = $this.roles.find(function (r) { return r.RoleCode === s.SignerValue });
          return role ? role.RoleName : s.SignerValue;
        }
        return s.SignerValue || "Chưa chọn";
      });
      return labels.join(", ");
    },
    onDragStart: function (ev, idx) {
      var step = this.steps[idx]
      if (step && (step.StepType === 'SUCCESS' || step.StepType === 'FAILURE')) {
        ev.preventDefault()
        return
      }
      this.draggingStepIdx = idx;
      ev.dataTransfer.effectAllowed = 'move';
      ev.dataTransfer.setData('text/plain', idx);
    },
    onDragOver: function (ev, idx) {
      if (this.draggingStepIdx === idx) return;
      this.dragOverIdx = idx;
      const rect = ev.currentTarget.getBoundingClientRect();
      const midpoint = rect.top + rect.height / 2;
      this.dragPos = ev.clientY < midpoint ? 'top' : 'bottom';
    },
    onDragLeave: function (ev, idx) {
      if (this.dragOverIdx === idx) {
        this.dragOverIdx = null;
        this.dragPos = null;
      }
    },
    onDrop: function (ev, idx) {
      if (this.draggingStepIdx === null || this.draggingStepIdx === idx) return;
      this.$emit('reorder-steps', { from: this.draggingStepIdx, to: idx, pos: this.dragPos });
      this.onDragEnd();
    },
    onDragEnd: function () {
      this.draggingStepIdx = null;
      this.dragOverIdx = null;
      this.dragPos = null;
    }
  }
	}
</script>