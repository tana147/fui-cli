<template>
	<div class="kiem-ke-mobile-container">
		<!-- Virtual scroll list -->
		<v-virtual-scroll v-if="DSHangHoa.length > 0" :items="DSHangHoa" :item-height="72" :height="listHeight"
			class="kiem-ke-mobile-scroll">
			<template v-slot:default="{ item, index }">
				<div class="kiem-ke-mobile-item" :class="{ 'bg-green-lighten-5': isItemDone(item) }"
					@click="openDetail(item, index)">
					<div class="d-flex align-center pa-3">
						<v-avatar :color="getKKStatusColor(item)" variant="tonal" size="40" class="mr-3 flex-shrink-0">
							<v-icon size="20">{{ getMdiIcon(item) }}</v-icon>
						</v-avatar>
						<div class="flex-grow-1 overflow-hidden mr-2">
							<div class="text-body-2 font-weight-medium text-truncate">
								{{ item.TenHangHoa }}
							</div>
							<div class="text-caption text-medium-emphasis">
								{{ item.Is_CaBiet ? 'Cá biệt' : 'Tổng' }}:
								<b class="text-primary">{{ item.Tong }}</b>
								{{ item.TenDonVi }}
							</div>
						</div>
						<v-chip class="kk-chip" :color="getKKStatusColor(item)" variant="tonal" size='x-small'>
							{{ getKKStatusText(item) }}
						</v-chip>
						<v-icon size="18" class="ml-1 text-medium-emphasis">mdi-chevron-right</v-icon>
					</div>
					<v-divider />
				</div>
			</template>
		</v-virtual-scroll>
		<uc-empty v-else text="Chưa có hàng hoá để hiển thị" />

		<!-- Bottom sheet chi tiết -->
		<v-bottom-sheet v-model="showDetail" scrollable>
			<v-card v-if="selectedItem" class="kiem-ke-detail-sheet">
				<!-- Header -->
				<v-card-title class="d-flex align-center pa-3 border-b">
					<v-avatar :color="getKKStatusColor(selectedItem)" variant="tonal" size="36" class="mr-3">
						<v-icon size="18">{{ getMdiIcon(selectedItem) }}</v-icon>
					</v-avatar>
					<div class="flex-grow-1 overflow-hidden">
						<div class="text-body-1 font-weight-medium text-truncate">
							{{ selectedItem.TenHangHoa }}
						</div>
						<div class="text-caption text-medium-emphasis">
							{{ selectedItem.Is_CaBiet ? 'Cá biệt' : 'Tổng' }}:
							{{ selectedItem.Tong }} {{ selectedItem.TenDonVi }}
						</div>
					</div>
					<v-btn icon="mdi-close" size="small" variant="text" @click="closeDetail" />
				</v-card-title>

				<!-- Nội dung chi tiết -->
				<v-card-text class="pa-0 kiem-ke-detail-body">
					<!-- Hàng hoá thường (DSSoLuong) -->
					<template v-if="!selectedItem.Is_CaBiet">
						<div v-for="(ItemHangHoa, idx) in selectedItem.DSSoLuong" :key="idx" class="pa-3" :class="{ 'border-b': idx !== selectedItem.DSSoLuong.length - 1,
								'bg-green-lighten-5': ItemHangHoa.TinhTrangKiemKe && !isKiemKe }">
							<div class="d-flex align-center justify-space-between mb-2">
								<div class="text-body-2 font-weight-medium">
									<v-icon size="16" class="mr-1">mdi-map-marker-outline</v-icon>
									{{ ItemHangHoa.TenKhuVuc }}
								</div>
								<template v-if="!isKiemKe">
									<v-chip size="small" :color="ItemHangHoa.TinhTrangKiemKe ? 'green' : 'orange'"
										variant="tonal">
										{{ ItemHangHoa.TinhTrangKiemKe ? 'Đã kiểm kê' : 'Chưa kiểm kê' }}
									</v-chip>
								</template>
								<template v-else>
									<v-checkbox v-model="ItemHangHoa.TinhTrangKiemKe" dense
										@update:model-value="$emit('check-kiem-ke', ItemHangHoa)" color="primary"
										hide-details class="flex-grow-0" />
								</template>
							</div>
							<div class="mb-2">
								<div class="text-caption text-medium-emphasis mb-1">Đơn vị kiểm kê</div>
								<div v-if="!isKiemKe" class="text-body-2 font-weight-medium">
									{{ getTenDonViTinh(ItemHangHoa.DonViKiemKe_Id) }}
								</div>
								<v-select v-else v-model="ItemHangHoa.DonViKiemKe_Id" class="mobile-input"
									:items="ItemHangHoa.DSDonViTinh" item-title="TenDonViQuyDoi"
									@update:model-value="$emit('select-don-vi-tinh', ItemHangHoa)"
									item-value="DonViTinh_Id" variant="underlined" density="compact" hide-details />
							</div>
							<v-row dense class="mb-2">
								<v-col cols="6">
									<div class="text-caption text-medium-emphasis">Thực tế</div>
									<div v-if="!isKiemKe" class="text-body-2 font-weight-medium">
										{{ ItemHangHoa.SoLuongThucTe }}
									</div>
									<v-text-field v-else v-model="ItemHangHoa.SoLuongThucTe"
										:rules="[rules.greaterThanZero]" class="mobile-input" type="number" step="0.01"
										@blur="ItemHangHoa.SoLuongThucTe = format2(ItemHangHoa.SoLuongThucTe)"
										variant="underlined" density="compact" hide-details
										:disabled="!ItemHangHoa.DonViKiemKe_Id" />
								</v-col>
								<v-col cols="6">
									<div class="text-caption text-medium-emphasis">Hệ thống</div>
									<div v-if="!isKiemKe" class="text-body-2 font-weight-medium">
										{{ ItemHangHoa.TongSauQuyDoi }}
									</div>
									<v-text-field v-else v-model="ItemHangHoa.TongSauQuyDoi" type="number"
										variant="plain" density="compact" hide-details readonly />
								</v-col>
							</v-row>
							<div>
								<div class="text-caption text-medium-emphasis mb-1">Ghi chú</div>
								<div v-if="!isKiemKe" class="text-body-2">
									{{ ItemHangHoa.GhiChu || '—' }}
								</div>
								<v-textarea v-else v-model="ItemHangHoa.GhiChu" class="mobile-input"
									variant="underlined" density="compact" rows="1" auto-grow hide-details />
							</div>
						</div>
					</template>

					<!-- Hàng hoá cá biệt (DSCaBiet) -->
					<template v-else>
						<div v-for="(CaBiet, idx) in selectedItem.DSCaBiet" :key="CaBiet.Id" class="pa-3" :class="{ 'border-b': idx !== selectedItem.DSCaBiet.length - 1,
								'bg-green-lighten-5': CaBiet.TinhTrangKiemKe && !isKiemKe }">
							<div class="d-flex align-center justify-space-between mb-2">
								<div class="text-body-2 font-weight-medium">{{ CaBiet.SoSeries }}</div>
								<template v-if="!isKiemKe">
									<v-chip size="small" :color="CaBiet.TinhTrangKiemKe ? 'green' : 'orange'"
										variant="tonal">
										{{ CaBiet.TinhTrangKiemKe ? 'Đã KK' : 'Chưa KK' }}
									</v-chip>
								</template>
								<template v-else>
									<v-checkbox v-model="CaBiet.TinhTrangKiemKe" dense color="primary" hide-details
										class="flex-grow-0" />
								</template>
							</div>
							<div class="text-caption text-medium-emphasis mb-1">Hiện tại</div>
							<div class="text-body-2 mb-2">
								{{ getTenDiaDiem(CaBiet.DiaDiemHienTai_Id) + ' / ' +
								getTenKhuVuc(CaBiet.KhuVucHienTai_Id) + ' / ' }}
								<v-chip :color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangHienTai]?.color ?? ''"
									size="small">
									{{ mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangHienTai]?.text ?? 'Chưa rõ' }}
								</v-chip>
							</div>
							<template v-if="!isKiemKe">
								<div class="text-caption text-medium-emphasis mb-1">Thực tế</div>
								<div class="text-body-2 mb-2">
									{{ getTenDiaDiem(CaBiet.DiaDiemThucTe_Id) + ' / ' +
									getTenKhuVuc(CaBiet.KhuVucThucTe_Id) + ' / ' }}
									<v-chip :color="mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangThucTe]?.color ?? ''"
										size="small">
										{{ mapTinhTrangHangHoaCaBiet[CaBiet.TinhTrangThucTe]?.text ?? 'Chưa rõ' }}
									</v-chip>
								</div>
							</template>
							<template v-else>
								<v-select class="mobile-input mt-1 mb-2" v-model="CaBiet.DiaDiemThucTe_Id"
									:items="DSDiaDiem" item-value="DiaDiem_Id" item-title="TenDiaDiem"
									label="Địa điểm thực tế" color="primary" density="compact" hide-details />
								<v-select class="mobile-input mt-1 mb-2" v-model="CaBiet.KhuVucThucTe_Id"
									:items="DSKhuVucKho" clearable item-value="KhuVuc_Id" item-title="TenKhuVuc"
									label="Khu vực thực tế" color="primary" density="compact" hide-details />
								<v-select class="mobile-input mt-1 mb-2" v-model="CaBiet.TinhTrangThucTe"
									:items="DSTinhTrangCaBiet" item-value="value" item-title="title"
									label="Tình trạng thực tế" color="primary" density="compact" hide-details />
							</template>
							<div>
								<div class="text-caption text-medium-emphasis mb-1">Ghi chú</div>
								<div v-if="!isKiemKe" class="text-body-2">
									{{ CaBiet.GhiChu || '—' }}
								</div>
								<v-textarea v-else v-model="CaBiet.GhiChu" class="mobile-input" variant="underlined"
									density="compact" rows="1" auto-grow hide-details />
							</div>
						</div>
					</template>
				</v-card-text>

				<!-- Điều hướng trước/sau -->
				<v-card-actions class="border-t pa-2 justify-space-between">
					<v-btn variant="text" :disabled="selectedIndex <= 0" @click="navigateItem(-1)"
						prepend-icon="mdi-chevron-left">
						Trước
					</v-btn>
					<span class="text-caption text-medium-emphasis">
						{{ selectedIndex + 1 }} / {{ DSHangHoa.length }}
					</span>
					<v-btn variant="text" :disabled="selectedIndex >= DSHangHoa.length - 1" @click="navigateItem(1)"
						append-icon="mdi-chevron-right">
						Sau
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-bottom-sheet>
	</div>
</template>

<script>
	export default {
		name: 'uc-kiem-ke-mobile',
		props: {
			DSHangHoa: Array,
			isKiemKe: Boolean,
			DSDiaDiem: Array,
			DSKhuVucKho: Array,
			DSDonViTinh: Array,
			mapDiaDiem: Object,
			mapKhuVuc: Object,
			mapDonViTinh: Object,
			listHeight: { type: String, default: 'calc(100dvh - 260px)' },
		},
		emits: ['select-don-vi-tinh', 'check-kiem-ke'],
		data() {
			return {
				mapTinhTrangHangHoaCaBiet,
				DSTinhTrangCaBiet,
				showDetail: false,
				selectedItem: null,
				selectedIndex: -1,
				rules: {
					greaterThanZero: v => v >= 0 || 'Giá trị phải lớn hơn 0',
				},
			}
		},
		methods: {
			openDetail(item, index) {
				this.selectedItem = item
				this.selectedIndex = index
				this.showDetail = true
			},
			validateCurrentItem() {
				if (!this.isKiemKe || !this.selectedItem) return true
				if (!this.selectedItem.Is_CaBiet) {
					const invalid = (this.selectedItem.DSSoLuong || []).find(
						x => x.TinhTrangKiemKe && Number(x.SoLuongThucTe) < 0
					)
					if (invalid) {
						showToast.error('Số lượng thực tế không được âm (' + invalid.TenKhuVuc + ')')
						return false
					}
				}
				return true
			},
			closeDetail() {
				if (!this.validateCurrentItem()) return
				this.showDetail = false
			},
			navigateItem(direction) {
				if (!this.validateCurrentItem()) return
				const newIndex = this.selectedIndex + direction
				if (newIndex < 0 || newIndex >= this.DSHangHoa.length) return
				this.selectedIndex = newIndex
				this.selectedItem = this.DSHangHoa[newIndex]
			},
			isItemDone(item) {
				const { done, total } = this.getKKCount(item)
				return total > 0 && done === total
			},
			format2(v) {
				const n = parseFloat(v)
				if (isNaN(n)) return ''
				return (Math.round(n * 100) / 100).toFixed(2)
			},
			getTenDiaDiem(DiaDiem_Id) {
				return this.mapDiaDiem[DiaDiem_Id] ?? 'Chưa rõ'
			},
			getTenKhuVuc(KhuVuc_Id) {
				return this.mapKhuVuc[KhuVuc_Id] ?? 'Chưa rõ'
			},
			getTenDonViTinh(DonViTinh_Id) {
				return this.mapDonViTinh[DonViTinh_Id] ?? ''
			},
			getMdiIcon(item) {
				if (!item) return "mdi-help-circle-outline"
				const { Is_CaBiet, LoaiNguyenLieu, LoaiHangHoa } = item
				if (Is_CaBiet === 1) return "mdi-devices"
				if (LoaiNguyenLieu === "TP") return "mdi-food-apple-outline"
				if (LoaiNguyenLieu === "BTP") return "mdi-package-variant-closed"
				if (LoaiNguyenLieu === "NVL") return "mdi-flask-outline"
				if (LoaiHangHoa === "CCDC") return "mdi-tools"
				if (LoaiHangHoa === "NVL") return "mdi-flask-outline"
				return "mdi-help-circle-outline"
			},
			getKKCount(item) {
				if (item.Is_CaBiet) {
					const arr = item.DSCaBiet || []
					return { done: arr.filter(x => x.TinhTrangKiemKe).length, total: arr.length }
				}
				const arr = item.DSSoLuong || []
				return { done: arr.filter(x => x.TinhTrangKiemKe).length, total: arr.length }
			},
			getKKStatusText(item) {
				const { done, total } = this.getKKCount(item)
				if (total === 0) return 'Chưa có'
				if (done === total) return 'Hoàn thành'
				return done + '/' + total
			},
			getKKStatusColor(item) {
				const { done, total } = this.getKKCount(item)
				if (total === 0) return 'grey'
				if (done === total) return 'green'
				if (done > 0) return 'orange'
				return 'red'
			},
		}
	}
</script>