<template>
	<div class="kiem-ke-filter-bar" :class="{ 'kiem-ke-filter-sticky': isMobile }"
		:style="isMobile ? { paddingTop: '48px' } : {}">
		<v-alert v-if="isKiemKe" type="info" variant="tonal" density="compact"
			class="rounded-0 mb-0" icon="mdi-clipboard-edit-outline">
			Đang kiểm kê — <strong>{{ tenPhieuKiemKe }}</strong>
		</v-alert>

		<v-row v-if="!isMobile && hasData" dense class="px-3 pt-3">
			<v-col cols="6" md="3">
				<uc-stat-card title="Tổng mục" :value="totalItem"
					icon="mdi-package-variant-closed" coloricon="primary"
					bgicon="blue-lighten-4" colortitle="#1976D2" />
			</v-col>
			<v-col cols="6" md="3">
				<uc-stat-card title="Đã kiểm kê" :value="totalDaKiemKe"
					icon="mdi-check-circle" coloricon="green"
					bgicon="green-lighten-4" colortitle="#4CAF50" />
			</v-col>
			<v-col cols="6" md="3">
				<uc-stat-card title="Chưa kiểm kê" :value="totalItem - totalDaKiemKe"
					icon="mdi-clock-outline" coloricon="orange"
					bgicon="orange-lighten-4" colortitle="#FF9800" />
			</v-col>
			<v-col cols="6" md="3">
				<uc-stat-card title="Hoàn thành" :value="Math.ceil(PhanTramHoanThanh) + '%'"
					icon="mdi-chart-arc" :coloricon="progressColor"
					:bgicon="progressBgIconColor" :colortitle="progressTitleColor" />
			</v-col>
		</v-row>

		<div class="pa-2 border-b mt-1">
			<v-row dense align="center">
				<v-col cols="12" md="3">
					<v-autocomplete :model-value="DiaDiem_Id"
						@update:model-value="$emit('update:DiaDiem_Id', $event)"
						:items="DSDiaDiemTatCa" item-value="DiaDiem_Id" item-title="TenDiaDiem"
						label="Địa điểm kiểm kê" color="primary" density="compact"
						:disabled="isKiemKe" hide-details />
				</v-col>
				<v-col cols="12" md="3">
					<v-autocomplete :model-value="PhieuKiemKe_Id"
						@update:model-value="$emit('update:PhieuKiemKe_Id', $event)"
						:items="DSPhieuKiemKe" item-value="PhieuKiemKe_Id"
						item-title="TenPhieuKiemKe" label="Phiếu kiểm kê" color="primary"
						density="compact" :disabled="isKiemKe" hide-details />
				</v-col>
				<v-col cols="auto">
					<v-btn prepend-icon="mdi-magnify" variant="tonal"
						@click="$emit('search')" :disabled="isKiemKe">Tìm</v-btn>
				</v-col>
				<v-col cols="auto" v-if="isShowButtonKiemKe && !isMobile">
					<v-btn :prepend-icon="buttonKiemKe.icon"
						@click="$emit('kiem-ke-click')"
						:disabled="isDisabledKiemKe" color="primary" variant="flat">
						{{ buttonKiemKe.title }}
					</v-btn>
				</v-col>
			</v-row>

			<!-- Ô tìm kiếm nhanh trong danh sách -->
			<v-text-field v-if="hasData" :model-value="searchText"
				@update:model-value="onSearchInput"
				prepend-inner-icon="mdi-text-search" placeholder="Tìm nhanh hàng hoá..."
				density="compact" variant="outlined" hide-details clearable single-line
				class="mt-2" />

			<v-progress-linear v-if="hasData && isMobile" :model-value="PhanTramHoanThanh"
				:color="progressColor" height="24" rounded="lg" class="mt-2">
				<template #default="{ value }">
					<strong :class="textColor">{{ Math.ceil(value) }}%</strong>
				</template>
			</v-progress-linear>
		</div>
	</div>
</template>

<script>
export default {
	name: 'uc-filter-bar',
	props: {
		DiaDiem_Id: Number,
		PhieuKiemKe_Id: [Number, Object],
		DSDiaDiemTatCa: Array,
		DSPhieuKiemKe: Array,
		isKiemKe: Boolean,
		buttonKiemKe: Object,
		isShowButtonKiemKe: Boolean,
		isDisabledKiemKe: Boolean,
		PhanTramHoanThanh: Number,
		progressColor: String,
		textColor: String,
		hasData: Boolean,
		totalItem: Number,
		totalDaKiemKe: Number,
		tenPhieuKiemKe: String,
		isMobile: Boolean,
		searchText: { type: String, default: '' },
	},
	emits: ['update:DiaDiem_Id', 'update:PhieuKiemKe_Id', 'update:searchText', 'search', 'kiem-ke-click'],
	data() {
		return {
			debounceTimer: null,
		}
	},
	computed: {
		progressTitleColor() {
			const map = { red: '#F44336', orange: '#FF9800', green: '#4CAF50' }
			return map[this.progressColor] || '#9E9E9E'
		},
		progressBgIconColor() {
			const map = { red: 'red-lighten-4', orange: 'orange-lighten-4', green: 'green-lighten-4' }
			return map[this.progressColor] || 'grey-lighten-4'
		},
	},
	beforeUnmount() {
		clearTimeout(this.debounceTimer)
	},
	methods: {
		onSearchInput(val) {
			clearTimeout(this.debounceTimer)
			this.debounceTimer = setTimeout(() => {
				this.$emit('update:searchText', val || '')
			}, 300)
		},
	},
}
</script>
