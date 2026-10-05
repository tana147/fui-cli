<template>
	<v-row dense class="dashboard-stats-row">
		<v-col v-for="item in statsData" :key="item.Key" cols="12" sm="6" lg="3">
			<v-card class="dashboard-panel dashboard-stat-card"
				:class="{ 'dashboard-stat-card-active': focusKey === item.Key }" elevation="0"
				@click="emitSelectSection(item.Key)">
				<v-card-text class="pa-4">
					<div class="d-flex justify-space-between align-start">
						<div>
							<div class="dashboard-stat-title">{{ item.Title }}</div>
							<div class="dashboard-stat-value">
								{{ item.Value }}
							</div>
						</div>
						<v-avatar size="44" :color="item.Color" variant="tonal">
							<v-icon>{{ item.Icon }}</v-icon>
						</v-avatar>
					</div>
					<div class="dashboard-stat-subtext mt-3">
						{{ item.SubText }}
					</div>
					<div class="dashboard-stat-action mt-4">
						{{ focusKey === item.Key ? 'Đang xem chi tiết' : 'Bấm để lọc chi tiết' }}
					</div>
				</v-card-text>
			</v-card>
		</v-col>
	</v-row>
</template>

<script>
	export default {
	name: 'uc-dashboard-stats',
	props: {
		statsData: { type: Array, default: () => [] },
		focusKey: { type: String, default: 'ALL' },
		loading: { type: Boolean, default: false },
	},
	emits: ['select-section'],
	methods: {
		emitSelectSection(key) {
			if (this.loading) return
			this.$emit('select-section', this.focusKey === key ? 'ALL' : key)
		},
	},
}
</script>