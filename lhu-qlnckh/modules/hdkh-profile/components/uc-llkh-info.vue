<template>
	<v-row dense>
		<v-col v-for="it in items" :key="it.label" cols="12" sm="6" :md="it.cols || 4">
			<div class="text-caption text-medium-emphasis">
				{{ it.label }}
				<v-icon v-if="it.lock" size="x-small" v-tooltip="it.lock">mdi-lock-outline</v-icon>
			</div>
			<div v-if="!isEmpty(it.value)" class="text-body-2 font-weight-medium">{{ it.value }}</div>
			<div v-else class="text-body-2 text-error font-italic">
				Chưa có<span v-if="it.why" class="text-caption"> — {{ it.why }}</span>
			</div>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		props: {
			items: { type: Array, default: function () { return [] } }
		},
		methods: {
			isEmpty: function (v) { return window.LLKH.isEmpty(v) }
		}
	}
</script>