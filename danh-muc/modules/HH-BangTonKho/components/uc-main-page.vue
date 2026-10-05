<template>
	<z-layout>
		<uc-top-bar :DSDiaDiem="DSDiaDiem" :isLoading="isLoading" :dataTable="dataTable"
			@on-search="onSearch" @on-chot="onUpdateTinhTrang" @on-export="onExport"
			@on-quy-doi="onQuyDoi">
		</uc-top-bar>
		<uc-table ref="refTable" :data="displayData" :isLoading="isLoading" :hasSearched="hasSearched">
		</uc-table>
	</z-layout>
</template>

<script>
export default {
	data() {
		return {
			isLoading: false,
			hasSearched: false,
			dataTable: [],
			DSDiaDiem: [],
			filter: {
				DiaDiem_Id: null,
				Nam: null,
				Thang: null,
				LoaiHangHoa: null,
			},
			isQuyDoi: false,
			cachedQuyDoi: null,
		}
	},
	computed: {
		displayData() {
			if (!this.isQuyDoi) return this.dataTable
			if (!this.cachedQuyDoi) this.cachedQuyDoi = this.computeQuyDoi(this.dataTable)
			return this.cachedQuyDoi
		},
	},
	mounted() {
		this.loadDSDiaDiem()
	},
	methods: {
		async loadDSDiaDiem() {
			this.DSDiaDiem = await apiCallPromise('work/HH_DiaDiem_Select')
		},

		async onSearch(params) {
			this.filter = { ...params }
			if (!this.filter.DiaDiem_Id || !this.filter.Nam || !this.filter.Thang || !this.filter.LoaiHangHoa) return
			this.isLoading = true
			this.hasSearched = true
			try {
				const data = await apiCallPromise('work/HH_Kho_Select_BangTonKho', this.filter)
				data.forEach(function (item) {
					item.CongThucChiTiet = JSON.parse(item.CongThuc || '[]')
					item.DanhSachDonViQuyDoi = JSON.parse(item.DonViQuyDoi || '[]')
				})
				this.dataTable = data
				this.cachedQuyDoi = null
			} catch (e) {
				showToast.error('Lỗi khi tải dữ liệu')
				this.dataTable = []
			} finally {
				this.isLoading = false
			}
		},

		onQuyDoi(val) {
			this.isQuyDoi = val
			if (val) this.cachedQuyDoi = null
		},

		onUpdateTinhTrang(params) {
			const title = params.TinhTrang === 'DA_CHOT' ? 'Xác nhận chốt sổ' : 'Xác nhận mở khoá'
			const self = this
			showConfirm(title, function () {
				apiCall('work/HH_Kho_Update_BangTonKho_TinhTrang', params, function () {
					showToast.success('Thành công')
					self.onSearch(self.filter)
				})
			})
		},

		onExport() {
			const table = this.$refs.refTable
			if (table) table.exportExcel()
		},

		computeQuyDoi(data) {
			if (!data || data.length === 0) return []
			const DS_BTP_NL = data.filter(function (item) { return item.LoaiNguyenLieu !== 'TP' })
			const map_BTP_NL = {}
			DS_BTP_NL.forEach(function (item) {
				map_BTP_NL[item.HangHoa_Id] = Object.assign({}, item)
			})
			data.filter(function (item) { return item.LoaiNguyenLieu === 'TP' }).forEach(function (item) {
				const Ton_SoLuong = Number(item.Ton_SoLuong) || 0
				const Ton_KiemKe = Number(item.Ton_KiemKe) || 0
				;(item.CongThucChiTiet || []).forEach(function (ct) {
					const nvl = map_BTP_NL[ct.HangHoa_Id]
					if (!nvl) return
					nvl.Ton_SoLuong += Ton_SoLuong * ct.DinhLuong
					nvl.Ton_KiemKe += Ton_KiemKe * ct.DinhLuong
				})
			})
			const array_BTP_NVL = Object.values(map_BTP_NL)
			const DS_NL = array_BTP_NVL.filter(function (item) { return item.LoaiNguyenLieu === 'NL' })
			const map_NVL = {}
			DS_NL.forEach(function (item) {
				map_NVL[item.HangHoa_Id] = Object.assign({}, item)
			})
			array_BTP_NVL.filter(function (item) { return item.LoaiNguyenLieu === 'BTP' }).forEach(function (item) {
				const Ton_SoLuong = Number(item.Ton_SoLuong) || 0
				const Ton_KiemKe = Number(item.Ton_KiemKe) || 0
				;(item.CongThucChiTiet || []).forEach(function (ct) {
					const nvl = map_NVL[ct.HangHoa_Id]
					if (!nvl) return
					const found = nvl.DanhSachDonViQuyDoi.find(function (q) { return q.DonViTinh_Id === ct.DonViTinh_Id })
					const HeSo = found ? found.HeSo : 1
					nvl.Ton_SoLuong += (Ton_SoLuong * ct.DinhLuong) / HeSo
					nvl.Ton_KiemKe += (Ton_KiemKe * ct.DinhLuong) / HeSo
				})
			})
			return Object.values(map_NVL)
		},
	},
}
</script>