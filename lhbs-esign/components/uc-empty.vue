<template>
	<div class="uc-empty" :style="{ padding: padding }">
        <v-icon :size="iconSize" :color="iconColor" class="uc-empty-icon">{{ icon }}</v-icon>
        <div v-if="title" class="uc-empty-title">{{ title }}</div>
        <div v-if="text" class="uc-empty-text">{{ text }}</div>
        <div v-if="$slots.default" class="uc-empty-action">
            <slot></slot>
        </div>
    </div>
</template>

<script>
	export default {
		name: 'uc-empty',
  props: {
    icon:      { type: String, default: 'mdi-tray-remove' },
    iconSize:  { type: Number, default: 48 },
    iconColor: { type: String, default: 'grey-lighten-1' },
    title:     { type: String, default: '' },
    text:      { type: String, default: 'Không có dữ liệu' },
    padding:   { type: String, default: '48px 16px' }
  }
	}
</script>