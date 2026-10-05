<template>
	<div class="kho-mobile-container">
		<v-virtual-scroll v-if="items.length > 0" :items="items" :item-height="76"
			class="kho-mobile-scroll" style="height: calc(100dvh - 260px)">
			<template v-slot:default="{ item, index }">
				<div class="kho-mobile-item px-3" @click="openDetail(index)">
					<v-avatar color="default" variant="tonal" size="40" class="mr-3">
						<v-icon>{{ getMdiIcon(item) }}</v-icon>
					</v-avatar>
					<div class="flex-grow-1 overflow-hidden">
						<div class="text-body-2 font-weight-medium text-truncate">{{ item.TenHangHoa }}</div>
						<div class="text-caption text-medium-emphasis">
							SL: <b class="text-primary">{{ item.Tong }}</b> {{ item.TenDonVi }}
							<span v-if="item.Is_CaBiet" class="badge-tai-san ml-1">Tài sản</span>
							<span v-else-if="item.LoaiHangHoa === 'CCDC'" class="badge-ccdc ml-1">CCDC</span>
							<span v-else class="badge-nvl ml-1">NVL</span>
						</div>
					</div>
					<v-icon size="small" color="grey">mdi-chevron-right</v-icon>
				</div>
			</template>
		</v-virtual-scroll>
		<uc-empty v-else text="Chưa có hàng hoá để hiển thị" />

		<!-- Bottom sheet chi tiết -->
		<v-bottom-sheet v-model="sheetOpen" inset>
			<v-card v-if="selected" class="kho-detail-sheet">
				<!-- Header -->
				<v-card-title class="d-flex align-center pa-3 border-b">
					<div class="flex-grow-1 text-body-1 font-weight-medium text-truncate pr-2">
						{{ selected.TenHangHoa }}
					</div>
					<v-btn icon="mdi-close" variant="text" size="small" @click="sheetOpen = false" />
				</v-card-title>

				<!-- Summary -->
				<div class="d-flex ga-3 pa-3 border-b text-caption">
					<span>Tổng: <b class="text-primary">{{ selected.Tong }}</b></span>
					<span>Trong kho: <b>{{ selected.TrongKho }}</b></span>
					<span>Đang SD: <b>{{ selected.DangSuDung }}</b></span>
				</div>

				<!-- Body -->
				<div class="kho-detail-body pa-2">
					<!-- CaBiet -->
					<template v-if="selected.Is_CaBiet && selected.DSCaBiet?.length">
						<div v-for="cb in selected.DSCaBiet" :key="cb.CaBiet_Id" class="kho-drawer-card">
							<div class="d-flex align-center justify-space-between">
								<div class="text-body-2 font-weight-medium">{{ cb.SoSeries }}</div>
								<div class="d-flex align-center ga-1">
									<v-chip :color="mapTinhTrangHangHoaCaBiet[cb.TinhTrang]?.color"
										size="x-small" variant="tonal">
										{{ mapTinhTrangHangHoaCaBiet[cb.TinhTrang]?.text }}
									</v-chip>
									<v-menu location="bottom end">
										<template v-slot:activator="{ props }">
											<v-btn icon="mdi-dots-vertical" variant="text" size="x-small"
												color="grey" v-bind="props" />
										</template>
										<v-list density="compact">
											<v-list-item @click.stop="$emit('on-edit-ca-biet', cb)"
												prepend-icon="mdi-square-edit-outline" title="Cập nhật" />
										</v-list>
									</v-menu>
								</div>
							</div>
							<div class="text-caption text-medium-emphasis mt-1">
								{{ cb.TenKhuVuc || 'Chưa rõ' }}
							</div>
						</div>
					</template>

					<!-- SoLuong -->
					<template v-if="!selected.Is_CaBiet && selected.DSSoLuong?.length">
						<div v-for="(sl, idx) in selected.DSSoLuong" :key="idx" class="kho-drawer-card">
							<div class="d-flex align-center justify-space-between">
								<div class="text-body-2">
									Khu vực: {{ sl.TenKhuVuc }} —
									SL: <b class="text-primary">{{ sl.SoLuong }}</b>
								</div>
								<v-menu location="bottom end">
									<template v-slot:activator="{ props }">
										<v-btn icon="mdi-dots-vertical" variant="text" size="x-small"
											color="grey" v-bind="props" />
									</template>
									<v-list density="compact">
										<v-list-item @click.stop="$emit('on-luan-chuyen', sl, selected)"
											prepend-icon="mdi-swap-horizontal" title="Luân chuyển" />
									</v-list>
								</v-menu>
							</div>
						</div>
					</template>
				</div>

				<!-- Footer navigation -->
				<div class="border-t pa-2 d-flex align-center justify-space-between flex-shrink-0">
					<v-btn size="small" variant="text" prepend-icon="mdi-chevron-left"
						:disabled="selectedIndex <= 0" @click="navigate(-1)">Trước</v-btn>
					<span class="text-caption text-medium-emphasis">
						{{ selectedIndex + 1 }} / {{ items.length }}
					</span>
					<v-btn size="small" variant="text" append-icon="mdi-chevron-right"
						:disabled="selectedIndex >= items.length - 1" @click="navigate(1)">Sau</v-btn>
				</div>
			</v-card>
		</v-bottom-sheet>
	</div>
</template>

<script>
export default {
	props: {
		items: { type: Array, default: function () { return [] } },
	},
	emits: ['on-edit-ca-biet', 'on-luan-chuyen'],
	data: function () {
		return {
			mapTinhTrangHangHoaCaBiet,
			sheetOpen: false,
			selected: null,
			selectedIndex: -1,
		}
	},
	methods: {
		getMdiIcon: function (item) {
			if (!item) return 'mdi-help-circle-outline'
			if (item.Is_CaBiet === 1) return 'mdi-devices'
			if (item.LoaiNguyenLieu === 'TP') return 'mdi-food-apple-outline'
			if (item.LoaiNguyenLieu === 'BTP') return 'mdi-package-variant-closed'
			if (item.LoaiNguyenLieu === 'NVL') return 'mdi-flask-outline'
			if (item.LoaiHangHoa === 'CCDC') return 'mdi-tools'
			if (item.LoaiHangHoa === 'NVL') return 'mdi-flask-outline'
			return 'mdi-help-circle-outline'
		},

		openDetail: function (index) {
			this.selectedIndex = index
			this.selected = this.items[index]
			this.sheetOpen = true
		},

		navigate: function (direction) {
			var newIdx = this.selectedIndex + direction
			if (newIdx < 0 || newIdx >= this.items.length) return
			this.selectedIndex = newIdx
			this.selected = this.items[newIdx]
		},
	},
}
</script>
