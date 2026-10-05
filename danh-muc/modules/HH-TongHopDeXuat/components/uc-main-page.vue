<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Tổng hợp đề xuất" class="border-b" />

		<div class="thde-content">
			<div class="thde-filter-bar">
				<uc-date-picker label="Từ ngày" v-model="filter.TuNgay" :max="filter.DenNgay" :rules="[]"
					:maxWidth="'150px'"></uc-date-picker>
				<uc-date-picker label="Đến ngày" v-model="filter.DenNgay" :min="filter.TuNgay" :rules="[]"
					:maxWidth="'150px'"></uc-date-picker>
				<v-autocomplete v-model="filter.DiaDiem_Id" :items="DSDiaDiem" item-value="DiaDiem_Id"
					item-title="TenDiaDiem" label="Địa điểm" density="compact" hide-details clearable variant="outlined"
					style="max-width: 260px;" />
				<v-btn variant="flat" color="primary" prepend-icon="mdi-magnify" size="small"
					@click="applyFilter">Lọc</v-btn>
				<v-btn variant="text" prepend-icon="mdi-refresh" size="small" @click="resetFilter">Đặt lại</v-btn>
			</div>

			<v-tabs v-model="activeTab" color="primary" density="compact" class="thde-tabs border-b">
				<v-tab value="CHUA_XU_LY" prepend-icon="mdi-timer-sand">
					Chưa xử lý
					<v-chip v-if="counts.ChuaXuLy > 0" size="x-small" color="error" variant="flat" class="ml-2">{{
						counts.ChuaXuLy }}</v-chip>
				</v-tab>
				<v-tab value="DA_XU_LY" prepend-icon="mdi-check-circle-outline">
					Đã xử lý
					<v-chip v-if="counts.DaXuLy > 0" size="x-small" color="success" variant="flat" class="ml-2">{{
						counts.DaXuLy }}</v-chip>
				</v-tab>
				<v-tab value="TONG_HOP_NCC" prepend-icon="mdi-domain">
					Tổng hợp theo NCC
					<v-chip v-if="counts.TongHopNCC > 0" size="x-small" color="info" variant="flat" class="ml-2">{{
						counts.TongHopNCC }}</v-chip>
				</v-tab>
				<v-tab value="DA_DAT_HANG" prepend-icon="mdi-package-variant">
					Phiếu đặt hàng
					<v-chip v-if="counts.PhieuDatHang > 0" size="x-small" color="warning" variant="flat" class="ml-2">{{
						counts.PhieuDatHang }}</v-chip>
				</v-tab>
			</v-tabs>

			<v-tabs-window v-model="activeTab" class="thde-tab-content">
				<v-tabs-window-item value="CHUA_XU_LY">
					<uc-table-chua-xu-ly :items="dataChuaXuLy.items" :initialExpanded="dataChuaXuLy.expanded"
						:loading="dataChuaXuLy.loading" @open-luan-chuyen="onOpenLuanChuyen"
						@open-mua-hang="onOpenMuaHang" />
				</v-tabs-window-item>

				<v-tabs-window-item value="DA_XU_LY">
					<uc-table-da-xu-ly :items="dataDaXuLy.items" :loading="dataDaXuLy.loading" />
				</v-tabs-window-item>

				<v-tabs-window-item value="TONG_HOP_NCC">
					<uc-table-tong-hop-theo-ncc :items="dataTongHopNCC.items" :initialExpanded="dataTongHopNCC.expanded"
						:loading="dataTongHopNCC.loading" @open-dat-hang="onOpenDatHang" />
				</v-tabs-window-item>

				<v-tabs-window-item value="DA_DAT_HANG">
					<uc-table-phieu-dat-hang :items="dataPhieuDatHang.items" :loading="dataPhieuDatHang.loading"
						@on-view-detail="onViewDetailPhieuDatHang" />
				</v-tabs-window-item>
			</v-tabs-window>
		</div>

		<uc-modal-mua-hang v-model="isShowMuaHang" :items="muaHangItems" @onReload="onReloadChuaXuLy" />

		<uc-modal-dat-hang v-model="isShowDatHang" :items="datHangItems" :DSNhaCungCap="DSNhaCungCap"
			:DSDiaDiem="DSDiaDiem" @onReload="onReloadTongHopNCC" />

		<uc-modal-transfer v-model:isShow="isShowLuanChuyen" :DSDiaDiem="DSDiaDiem" :DSKhuVuc="DSKhuVuc"
			:itemTransfer="itemTransfer" @load-data-chua-xu-ly="onReloadChuaXuLy" />

		<uc-modal-view-detail-phieu-dat-hang v-model:isShow="isShowViewDetail" :selectedItem="selectedPhieuDatHang" />
	</z-layout>
</template>

<script>
export default {
	data() {
		return {
			activeTab: 'CHUA_XU_LY',
			counts: { ChuaXuLy: 0, DaXuLy: 0, TongHopNCC: 0, PhieuDatHang: 0 },
			filter: { TuNgay: this.getDefaultTuNgay(), DenNgay: this.getDefaultDenNgay(), DiaDiem_Id: 0 },

			dataChuaXuLy: { items: [], expanded: [], loading: false },
			dataDaXuLy: { items: [], loading: false },
			dataTongHopNCC: { items: [], expanded: [], loading: false },
			dataPhieuDatHang: { items: [], loading: false },

			DSNhaCungCap: [],
			DSDiaDiem: [],
			DSKhuVuc: [],

			isShowMuaHang: false,
			muaHangItems: [],
			isShowDatHang: false,
			datHangItems: [],
			isShowLuanChuyen: false,
			itemTransfer: {},
			isShowViewDetail: false,
			selectedPhieuDatHang: {},
		}
	},
	mounted() {
		this.loadCounts()
		this.loadChuaXuLy()
		this.loadDSNhaCungCap()
		this.loadDSDiaDiem()
		this.loadDSKhuVuc()
	},
	watch: {
		activeTab(value) {
			switch (value) {
				case 'CHUA_XU_LY': this.loadChuaXuLy(); break
				case 'DA_XU_LY': this.loadDaXuLy(); break
				case 'TONG_HOP_NCC': this.loadTongHopNCC(); break
				case 'DA_DAT_HANG': this.loadPhieuDatHang(); break
			}
		}
	},
	methods: {
		getDefaultTuNgay() {
			const d = new Date()
			d.setMonth(d.getMonth() - 3)
			return d.toISOString().split('T')[0]
		},
		getDefaultDenNgay() {
			return new Date().toISOString().split('T')[0]
		},

		getFilterParams() {
			const p = {}
			if (this.filter.TuNgay) p.TuNgay = this.filter.TuNgay
			if (this.filter.DenNgay) p.DenNgay = this.filter.DenNgay
			if (this.filter.DiaDiem_Id !== null) p.DiaDiem_Id = this.filter.DiaDiem_Id
			return p
		},

		applyFilter() {
			this.loadCounts()
			switch (this.activeTab) {
				case 'CHUA_XU_LY': this.loadChuaXuLy(); break
				case 'DA_XU_LY': this.loadDaXuLy(); break
				case 'TONG_HOP_NCC': this.loadTongHopNCC(); break
				case 'DA_DAT_HANG': this.loadPhieuDatHang(); break
			}
		},

		resetFilter() {
			this.filter = { TuNgay: this.getDefaultTuNgay(), DenNgay: this.getDefaultDenNgay(), DiaDiem_Id: 0 }
			this.applyFilter()
		},

		async loadCounts() {
			const data = await apiCallPromise('work/HH_DeXuat_MuaHang_Stats', this.getFilterParams())
			if (data && data[0]) {
				this.counts = {
					ChuaXuLy: data[0].ChuaXuLy ?? 0,
					DaXuLy: data[0].DaXuLy ?? 0,
					TongHopNCC: data[0].TongHopNCC ?? 0,
					PhieuDatHang: data[0].PhieuDatHang ?? 0,
				}
			}
		},

		async loadDSNhaCungCap() {
			this.DSNhaCungCap = await apiCallPromise('work/HH_NhaCungCap_Select_Dropdown')
		},
		async loadDSDiaDiem() {
			const data = await apiCallPromise('work/HH_DiaDiem_Select')
			this.DSDiaDiem = [{ DiaDiem_Id: 0, TenDiaDiem: 'Tất cả' }, ...data]
		},
		async loadDSKhuVuc() {
			this.DSKhuVuc = await apiCallPromise('work/HH_KhuVuc_Select')
		},

		async loadChuaXuLy() {
			this.dataChuaXuLy.loading = true
			const data = await apiCallPromise('work/HH_DeXuat_MuaHang_Select_DaDuyet_ChuaXuLy', this.getFilterParams())
			const expanded = []
			data.forEach(function (item) {
				item.ChiTiet = JSON.parse(item.DeXuatChiTiet ?? '[]')
				expanded.push(item.DeXuat_MuaHang_Id)
			})
			this.dataChuaXuLy.items = data
			this.dataChuaXuLy.expanded = expanded
			this.dataChuaXuLy.loading = false
		},

		async loadDaXuLy() {
			this.dataDaXuLy.loading = true
			const data = await apiCallPromise('work/HH_DeXuat_MuaHang_Select_DaDuyet_DaXuLy', this.getFilterParams())
			data.forEach(function (item) {
				item.ChiTiet = JSON.parse(item.DeXuatChiTiet ?? '[]')
			})
			this.dataDaXuLy.items = data
			this.dataDaXuLy.loading = false
		},

		async loadTongHopNCC() {
			this.dataTongHopNCC.loading = true
			const data = await apiCallPromise('work/HH_DeXuat_MuaHang_Select_DaDuyet_TongHopNCC', this.getFilterParams())
			const expanded = []
			const grouped = Object.values(
				data.reduce(function (acc, item) {
					const key = item.GoiY_NhaCungCap_Id
					if (!acc[key]) {
						acc[key] = {
							GoiY_NhaCungCap_Id: key,
							TenNhaCungCap: item.TenNhaCungCap,
							Children: []
						}
					}
					acc[key].Children.push(item)
					if (!expanded.includes(key)) expanded.push(key)
					return acc
				}, {})
			)
			this.dataTongHopNCC.items = grouped
			this.dataTongHopNCC.expanded = expanded
			this.dataTongHopNCC.loading = false
		},

		async loadPhieuDatHang() {
			this.dataPhieuDatHang.loading = true
			this.dataPhieuDatHang.items = await apiCallPromise('work/HH_PhieuDatHang_Select', this.getFilterParams())
			this.dataPhieuDatHang.loading = false
		},

		onOpenMuaHang(selectedItems) {
			this.muaHangItems = selectedItems
			this.isShowMuaHang = true
		},

		onOpenLuanChuyen(transferData) {
			this.itemTransfer = transferData
			this.isShowLuanChuyen = true
		},

		onOpenDatHang(selectedItems) {
			this.datHangItems = selectedItems
			this.isShowDatHang = true
		},

		onReloadChuaXuLy() {
			this.loadChuaXuLy()
			this.loadCounts()
		},

		onReloadTongHopNCC() {
			this.loadTongHopNCC()
			this.loadCounts()
		},

		async onViewDetailPhieuDatHang(item) {
			this.selectedPhieuDatHang = { ...item }
			const data = await apiCallPromise('work/HH_PhieuDatHang_Select_By_Id', {
				PhieuDatHang_Id: item.PhieuDatHang_Id
			})
			this.selectedPhieuDatHang = { ...this.selectedPhieuDatHang, arrayHangHoa: [...data] }
			this.isShowViewDetail = true
		},
	},
}
</script>