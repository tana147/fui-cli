<template>
	<v-card variant="outlined" class="rounded-sm w-100">
		<v-card-text class="pa-3">
			<div class="d-flex align-center">
				<v-avatar :color="bgColor" size="36" class="mr-2 flex-shrink-0">
					<v-icon :color="color" :icon="icon" size="20"></v-icon>
				</v-avatar>
				<div style="min-width: 0;">
					<div class="text-caption text-medium-emphasis text-truncate" :title="title"
						style="font-size: 0.72rem !important;">
						{{ title }}
					</div>
					<div class="text-h5 font-weight-bold text-no-wrap">
						{{ value }}<span v-if="suffix" class="text-caption font-weight-medium ml-1">{{ suffix }}</span>
					</div>
				</div>
			</div>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		name: 'c-stats',
		props: {
			title: { type: String, default: '' },
			value: { type: [String, Number], default: 0 },
			suffix: { type: String, default: '' },
			icon: { type: String, default: '' },
			color: { type: String, default: '' },
			bgColor: { type: String, default: '' }
		}
	}
</script>