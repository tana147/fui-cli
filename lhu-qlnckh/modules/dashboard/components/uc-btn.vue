<template>
	<v-btn v-if="label" small outlined color="primary" class="rounded-xs text-none font-weight-medium"
		@click="(e) => $emit('click', e)">
		<v-icon left small>{{ resolvedIcon }}</v-icon>
		{{ label }}
	</v-btn>
	<v-btn v-else icon small color="primary" title="Xem số liệu chi tiết" @click="(e) => $emit('click', e)">
		<v-icon small>{{ resolvedIcon }}</v-icon>
	</v-btn>
</template>

<script>
	export default {
		props: ["icon", "label", "click"],
	computed: {
		resolvedIcon() {
			if (!this.icon || this.icon === "mdi-help") {
				return "mdi-table-eye"
			}
			return this.icon
		}
	}
	}
</script>