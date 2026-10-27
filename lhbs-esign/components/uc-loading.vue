<template>
	<div class="uc-loading" :style="containerStyle">
        <!-- Bar mode (ngang) -->
        <v-progress-linear v-if="type === 'bar'" indeterminate :color="color" :height="barHeight">
        </v-progress-linear>

        <!-- Circular mode (tròn, giữa trang) -->
        <div v-else class="uc-loading-center">
            <v-progress-circular indeterminate :color="color" :size="size" :width="width">
            </v-progress-circular>
            <div v-if="text" class="uc-loading-text">{{ text }}</div>
        </div>
    </div>
</template>

<script>
	export default {
		name: 'uc-loading',
  props: {
    type:      { type: String, default: 'circular' }, // circular | bar
    color:     { type: String, default: 'primary' },
    size:      { type: Number, default: 36 },
    width:     { type: Number, default: 3 },
    barHeight: { type: Number, default: 3 },
    text:      { type: String, default: '' },
    padding:   { type: String, default: '48px 16px' }
  },
  computed: {
    containerStyle: function () {
      if (this.type === 'bar') return {}
      return { padding: this.padding }
    }
  }
	}
</script>