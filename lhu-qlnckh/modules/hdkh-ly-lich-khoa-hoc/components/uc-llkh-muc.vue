<template>
	<div class="mb-6" :id="anchor">
		<div class="d-flex align-center flex-wrap ga-2 mb-2">
			<h3 class="text-primary font-weight-bold">{{ title }}</h3>
			<v-chip v-if="nguon" size="small" variant="tonal" :color="nguon === 'HRM' ? 'teal' : 'indigo'">
				{{ nguon === 'HRM' ? 'Lưu tại HRM' : (nguon === 'NCKH' ? 'Lưu tại NCKH' : nguon) }}
			</v-chip>
			<v-spacer></v-spacer>
			<v-btn v-for="a in actions" :key="a.label" size="small" variant="text" color="primary" :prepend-icon="a.icon"
				disabled>{{ a.label }}</v-btn>
		</div>
		<div v-if="note" class="text-caption text-medium-emphasis mb-2">{{ note }}</div>
		<slot></slot>
	</div>
</template>

<script>
	export default {
		props: {
			title: { type: String, default: "" },
			nguon: { type: String, default: "" },
			note: { type: String, default: "" },
			anchor: { type: String, default: "" },
			actions: { type: Array, default: function () { return [] } }
		}
	}
</script>