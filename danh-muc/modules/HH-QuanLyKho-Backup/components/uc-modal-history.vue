<template>
	<v-dialog v-model="isShow" width="500">
		<v-card>
			<v-toolbar density="compact" :elevation="0">
				<v-toolbar-title>Lịch sử</v-toolbar-title>
				<v-spacer />
				<v-btn size="small" icon="mdi-close" variant="text" @click="close" />
			</v-toolbar>
			<v-divider />
			<v-card-text class="pt-3 custom-scroll" style="max-height: 520px; overflow-y: auto;">
				<template v-if="historyInfo && historyInfo.length > 0">
					<v-timeline density="compact" side="end" line-thickness="2">
						<v-timeline-item
							v-for="(item, index) in historyInfo"
							:key="index"
							:dot-color="getLoaiPhieuInfo(item).color"
							size="small"
						>
							<div class="d-flex align-center ga-2 mb-1">
								<v-chip :color="getLoaiPhieuInfo(item).color" size="small" label variant="tonal">
									{{ getLoaiPhieuInfo(item).text }}
								</v-chip>
								<v-chip v-if="type === 'HANG_HOA'"
									:color="getQuantityInfo(item.SoLuong).color"
									variant="tonal" size="small" class="font-weight-medium">
									<v-icon start size="14">{{ getQuantityInfo(item.SoLuong).icon }}</v-icon>
									{{ getQuantityInfo(item.SoLuong).text }}
								</v-chip>
							</div>
							<div class="text-caption text-medium-emphasis">
								{{ formatDate(item.NgayPhatSinh) }}
							</div>
						</v-timeline-item>
					</v-timeline>
				</template>
				<uc-empty v-else text="Chưa có thông tin" />
			</v-card-text>
		</v-card>
	</v-dialog>
</template>

<script>
export default {
	name: 'uc-modal-history',

	props: {
		isShow: Boolean,
		historyInfo: Array,
		type: {
			type: String,
			default: 'CA_BIET'
		}
	},

	emits: ['update:isShow'],

	data() {
		return {
			mapLoaiPhieuCaBiet: {
				'NHAP': { text: 'Nhập', color: 'success' },
				'XUAT': { text: 'Xuất', color: 'error' },
				'LUAN_CHUYEN': { text: 'Luân chuyển', color: 'info' }
			},
			mapLoaiPhieuHangHoa: {
				'NHAP': { text: 'Nhập', color: 'success' },
				'XUAT': { text: 'Xuất', color: 'error' },
				'LUAN_CHUYEN_DI': { text: 'Luân chuyển đi', color: 'warning' },
				'LUAN_CHUYEN_DEN': { text: 'Luân chuyển đến', color: 'info' }
			}
		}
	},

	methods: {
		formatDate: window.formatDate,

		close() {
			this.$emit('update:isShow', false)
		},

		getLoaiPhieuKey(item) {
			if (this.type === 'CA_BIET') return item.LoaiPhieu
			if (item.PhieuLuanChuyen_Id != null && item.SoLuong < 0) return 'LUAN_CHUYEN_DI'
			if (item.PhieuLuanChuyen_Id != null && item.SoLuong > 0) return 'LUAN_CHUYEN_DEN'
			return item.LoaiPhieu
		},

		getLoaiPhieuInfo(item) {
			const key = this.getLoaiPhieuKey(item)
			const map = this.type === 'CA_BIET' ? this.mapLoaiPhieuCaBiet : this.mapLoaiPhieuHangHoa
			return map[key] || { text: key, color: 'grey' }
		},

		getQuantityInfo(soLuong) {
			if (soLuong > 0) return { color: 'success', icon: 'mdi-arrow-up', text: `${Math.abs(soLuong)}` }
			if (soLuong < 0) return { color: 'error', icon: 'mdi-arrow-down', text: `${Math.abs(soLuong)}` }
			return { color: 'grey', icon: 'mdi-check', text: `${Math.abs(soLuong)}` }
		}
	}
}
</script>
