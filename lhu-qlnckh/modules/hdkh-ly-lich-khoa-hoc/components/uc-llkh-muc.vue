<template>
	<div class="mb-6" :id="anchor">
		<div class="d-flex align-center flex-wrap ga-2 mb-2">
			<h3 class="text-primary font-weight-bold">{{ title }}</h3>
			<v-spacer></v-spacer>
			<slot name="actions">
				<v-btn v-for="a in actions" :key="a.label" size="small" variant="text" color="primary" :prepend-icon="a.icon"
					:disabled="a.disabled !== false" :title="a.tooltip || 'Chức năng chưa khả dụng / do Phòng TCNS quản lý'"
					@click="$emit('action', a)">{{ a.label }}</v-btn>
			</slot>
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