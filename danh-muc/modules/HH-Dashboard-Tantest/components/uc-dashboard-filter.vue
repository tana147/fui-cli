<template>
	<v-card class="dashboard-panel dashboard-filter-panel" elevation="0">
		<v-card-text class="pa-4">
			<div class="dashboard-section-title">Bộ lọc điều hành</div>
			<v-row dense class="mt-1">
				<v-col cols="12" md="4">
					<v-select v-model="localDateRange" :items="dateRangeOptions" item-title="title" item-value="value"
						label="Khoảng thời gian" density="compact" variant="outlined" hide-details
						:disabled="loading" />
				</v-col>
				<v-col cols="12" md="4">
					<v-autocomplete v-model="localDiaDiemId" :items="locationOptions" item-title="TenDiaDiem"
						item-value="DiaDiem_Id" label="Địa điểm" density="compact" variant="outlined" hide-details
						:disabled="loading" />
				</v-col>
				<v-col cols="12" md="4" class="d-flex align-center justify-end">
					<v-btn color="primary" variant="outlined" prepend-icon="mdi-refresh" :loading="loading"
						@click="emitReload()">
						Tải lại
					</v-btn>
				</v-col>
			</v-row>

			<div class="dashboard-filter-chip-row mt-4">
				<v-chip size="small" color="primary" variant="tonal">
					{{ currentDateRangeText }}
				</v-chip>
				<v-chip size="small" color="secondary" variant="tonal">
					{{ currentLocationText }}
				</v-chip>
				<v-chip size="small" color="grey-darken-1" variant="outlined">
					Preview theo mock data
				</v-chip>
			</div>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
	name: 'uc-dashboard-filter',
	props: {
		filter: { type: Object, default: () => ({}) },
		locationOptions: { type: Array, default: () => [] },
		loading: { type: Boolean, default: false },
	},
	emits: ['change-filter', 'reload'],
	data() {
		return {
			localDateRange: 'THANG_NAY',
			localDiaDiemId: 0,
			dateRangeOptions: [
				{ title: 'Hôm nay', value: 'HOM_NAY' },
				{ title: '7 ngày gần nhất', value: '7_NGAY' },
				{ title: 'Tháng này', value: 'THANG_NAY' },
			],
		}
	},
	computed: {
		currentDateRangeText() {
			const item = this.dateRangeOptions.find((option) => option.value === this.localDateRange)
			return item ? item.title : 'Tháng này'
		},
		currentLocationText() {
			const item = this.locationOptions.find((option) => option.DiaDiem_Id === this.localDiaDiemId)
			return item ? item.TenDiaDiem : 'Tất cả kho'
		},
	},
	watch: {
		filter: {
			handler: function (value) {
				this.localDateRange = value?.DateRange ?? 'THANG_NAY'
				this.localDiaDiemId = value?.DiaDiem_Id ?? 0
			},
			immediate: true,
			deep: true,
		},
		localDateRange: function () {
			if (this.filter?.DateRange === this.localDateRange && this.filter?.DiaDiem_Id === this.localDiaDiemId) return
			this.emitChangeFilter()
		},
		localDiaDiemId: function () {
			if (this.filter?.DateRange === this.localDateRange && this.filter?.DiaDiem_Id === this.localDiaDiemId) return
			this.emitChangeFilter()
		},
	},
	methods: {
		emitChangeFilter() {
			this.$emit('change-filter', {
				DateRange: this.localDateRange,
				DiaDiem_Id: this.localDiaDiemId,
			})
		},
		emitReload() {
			this.$emit('reload')
		},
	},
}
</script>