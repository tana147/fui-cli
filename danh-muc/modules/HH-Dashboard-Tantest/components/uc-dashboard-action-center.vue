<template>
	<v-card class="dashboard-action-center" elevation="0">
		<v-card-text class="pa-4">
			<div class="d-flex justify-space-between align-center mb-4">
				<div>
					<div class="dashboard-hero-title">Action Center</div>
					<div class="dashboard-hero-subtitle">3 việc nên xử lý trước để giữ nhịp vận hành</div>
				</div>
				<v-chip size="small" color="white" variant="outlined">Mock preview</v-chip>
			</div>

			<v-row dense>
				<v-col v-for="item in actionItems" :key="item.Id" cols="12" md="4">
					<v-card class="dashboard-action-card"
						:class="['dashboard-action-card-' + item.Tone, { 'dashboard-action-card-active': focusKey === item.Key }]"
						elevation="0" @click="emitSelectAction(item.Key)">
						<v-card-text class="pa-4">
							<div class="d-flex justify-space-between align-start">
								<div>
									<div class="dashboard-action-label">{{ item.Title }}</div>
									<div class="dashboard-action-value">{{ item.Value }} <span>{{ item.Unit }}</span>
									</div>
								</div>
								<v-avatar size="46" color="white" variant="tonal">
									<v-icon>{{ item.Icon }}</v-icon>
								</v-avatar>
							</div>
							<div class="dashboard-action-description mt-3">{{ item.Description }}</div>
							<div class="dashboard-action-link mt-4">{{ item.ActionText }}</div>
						</v-card-text>
					</v-card>
				</v-col>
			</v-row>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
	name: 'uc-dashboard-action-center',
	props: {
		actionItems: { type: Array, default: () => [] },
		focusKey: { type: String, default: 'ALL' },
		loading: { type: Boolean, default: false },
	},
	emits: ['select-action'],
	methods: {
		emitSelectAction(key) {
			if (this.loading) return
			this.$emit('select-action', this.focusKey === key ? 'ALL' : key)
		},
	},
}
</script>