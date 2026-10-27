<template>
	<div class="wf-request-mode-grid">
    <div v-for="item in modeOptions" :key="item.value" class="wf-request-mode-card"
      :class="{ active: createMode === item.value }" @click="$emit('select-mode', item.value)">
      <div class="wf-request-mode-card__head">
        <div class="wf-request-mode-card__icon">
          <v-icon size="18">{{ item.icon }}</v-icon>
        </div>
        <div>
          <div class="wf-request-mode-card__name">{{ item.title }}</div>
          <div class="wf-request-mode-card__code">{{ item.value }}</div>
        </div>
      </div>
      <div class="wf-request-mode-card__desc">{{ item.description }}</div>
    </div>
  </div>
</template>

<script>
	export default {
		name: "uc-request-create-mode",
  props: {
    createMode: { type: String, default: "TEMPLATE_FLOW" },
    modeOptions: { type: Array, default: function () { return []; } }
  }
	}
</script>