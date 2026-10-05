<template>
	<v-card class="dashboard-panel dashboard-panel-fill dashboard-panel-scroll" elevation="0">
		<v-card-text class="pa-4">
			<div class="d-flex justify-space-between align-center mb-4">
				<div class="dashboard-section-title">Cảnh báo cần xử lý</div>
				<div class="dashboard-section-caption">
					{{ alertRows.length }} mục hiển thị
				</div>
			</div>

			<div v-if="alertRows.length === 0" class="dashboard-empty-state">
				Không có cảnh báo cho bộ lọc hiện tại
			</div>

			<v-row v-else dense>
				<v-col v-for="item in alertRows" :key="item.Id" cols="12" md="6">
					<v-card class="dashboard-alert-card" :class="'dashboard-alert-card-' + item.Severity" elevation="0"
						@click="emitSelectAlert(item)">
						<v-card-text class="pa-4">
							<div class="d-flex justify-space-between align-center mb-2">
								<v-chip size="small" :color="getSeverityColor(item.Severity)" variant="tonal">{{
									item.Level }}</v-chip>
								<v-icon color="grey-darken-1">mdi-chevron-right</v-icon>
							</div>
							<div class="dashboard-alert-title">{{ item.Title }}</div>
							<div class="dashboard-alert-description mt-2">{{ item.Description }}</div>
							<div class="dashboard-alert-meta mt-3">
								<div class="dashboard-alert-meta-item">
									<v-icon size="16">mdi-clock-outline</v-icon>
									<span>{{ item.DueText }}</span>
								</div>
								<div class="dashboard-alert-meta-item">
									<v-icon size="16">mdi-map-marker-outline</v-icon>
									<span>{{ item.LocationText }}</span>
								</div>
								<div class="dashboard-alert-meta-item">
									<v-icon size="16">mdi-pulse</v-icon>
									<span>{{ item.ImpactText }}</span>
								</div>
							</div>
							<div class="dashboard-alert-action mt-3">{{ item.ActionText }}</div>
						</v-card-text>
					</v-card>
				</v-col>
			</v-row>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
	name: 'uc-dashboard-alerts',
	props: {
		alertRows: { type: Array, default: () => [] },
		loading: { type: Boolean, default: false },
	},
	emits: ['select-alert'],
	methods: {
		getSeverityColor(severity) {
			if (severity === 'danger') return 'red-darken-1'
			if (severity === 'warning') return 'orange-darken-2'
			return 'blue-darken-1'
		},
		emitSelectAlert(item) {
			if (this.loading) return
			this.$emit('select-alert', item)
		},
	},
}
</script>