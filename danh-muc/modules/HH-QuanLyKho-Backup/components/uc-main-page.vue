<template>
	<z-layout>
		<uc-stats @load-data="handleLoadData" :stats="stats" :DSDiaDiem="DSDiaDiem" :loading="loading"></uc-stats>
		<uc-table-kho v-if="filter.TinhTrangHangHoa === 'TRONG_KHO'" ref="table" :data="DSKho" :filter="filter" :loading="loading"
			@transfer="handleTransfer" @on-edit-ca-biet="handleEditCaBiet" @on-qr="handleOnQR"
			@on-quet-qr="handleOnQuetQR" @on-view-history="handleOnViewHistory"></uc-table-kho>

		<uc-table-yeu-cau v-if="filter.TinhTrangHangHoa === 'YEU_CAU_CHO_XAC_NHAN'" :DSYeuCau="DSYeuCau" :loading="loading"
			@emit-view-detail-phieu-nhap="handleDuyetPhieuNhap"
			@emit-view-detail-phieu-kiem-ke="handleDuyetPhieuKiemKe"></uc-table-yeu-cau>

		<uc-table-hang-sap-het v-if="filter.TinhTrangHangHoa === 'HANG_SAP_HET'"
			:DSHangSapHet="DSKho" :loading="loading"></uc-table-hang-sap-het>

		<uc-modal-transfer v-model:isShow="isShowDialogTransfer" :itemTransfer="itemTransfer"
			:selectedItem="selectedItem" :DSDiaDiem="DSDiaDiem"
			:DSKhuVuc="DSKhuVuc" @onReload="loadDSKho" />

		<uc-modal-update-ca-biet v-model:isShow="isShowDialogUpdateCaBiet" :selectedCaBiet="selectedCaBiet"
			:DSKhuVuc="DSKhuVuc" @onReload="handleCaBietUpdated" />

		<uc-modal-duyet-phieu-nhap v-model:isShow="isShowDialogDuyetPhieuNhap" :selectedItem="selectedItem"
			@onReload="handlePhieuApproved" />

		<uc-modal-duyet-phieu-kiem-ke v-model:isShow="isShowDialogDuyetPhieuKiemKe" :selectedItem="selectedItem"
			:DSDiaDiem="DSDiaDiem" :DSKhuVuc="DSKhuVuc" :DSDonViTinh="DSDonViTinh"
			@onReload="handlePhieuApproved" />

		<uc-modal-qr v-model:isShow="isShowDialogQR" :selectedCaBiet="selectedCaBiet"
			:DSDiaDiem="DSDiaDiem" @onReload="handleQrUpdated" />

		<uc-modal-quet-qr v-model:isShow="isShowDialogQuetQR" />

		<uc-modal-history v-model:isShow="isShowDialogHistory"
			:historyInfo="historyInfo" :type="historyType" />
	</z-layout>
</template>

<script>
export default {
	data() {
		return {
			filter: {
				TinhTrangHangHoa: 'TRONG_KHO',
				DiaDiem_Id: 0,
				LoaiHangHoa: 'TAT_CA'
			},

			isShowDialogTransfer: false,
			isShowDialogUpdateCaBiet: false,
			isShowDialogDuyetPhieuNhap: false,
			isShowDialogDuyetPhieuKiemKe: false,
			isShowDialogQR: false,
			isShowDialogQuetQR: false,
			isShowDialogHistory: false,
			loading: false,

			stats: {
				HangHoaTrongKho: 0,
				YeuCauChoXacNhan: 0,
				HangSapHet: 0,
				DangSuaChua: 0,
				TaiSanHetHan: 0,
				YeuCauThanhLy: 0
			},

			khoArray: ['TRONG_KHO', 'HANG_SAP_HET'],

			itemTransfer: {},
			selectedItem: {},
			selectedCaBiet: {},
			selectedSoLuong: {},

			DSKho: [],
			DataDetailHangHoa: [],
			DSDiaDiem: [],
			DSKhuVuc: [],
			DSYeuCau: [],
			DSDonViTinh: [],
			historyInfo: [],
			historyType: 'CA_BIET'
		}
	},

	mounted() {
		this.loadData()
	},

	methods: {
		async loadData() {
			this.loading = true
			try {
				await Promise.all([
					this.loadDSKho(),
					this.loadDSDiaDiem(),
					this.loadDSKhuVuc(),
					this.loadDSDonViTinh()
				])
			} finally {
				this.loading = false
			}
		},

		mapStatsData(stats) {
			return {
				HangHoaTrongKho: stats[0].HangHoaTrongKho ?? 0,
				TaiSanMoi: stats[0].TaiSanMoi ?? 0,
				DangSuDung: stats[0].DangSuDung ?? 0,
				YeuCauChoXacNhan: stats[0].YeuCauChoXacNhan ?? 0,
				HangSapHet: stats[0].HangSapHet ?? 0,
				DangSuaChua: stats[0].DangSuaChua ?? 0,
				TaiSanHetHan: stats[0].TaiSanHetHan ?? 0,
				YeuCauThanhLy: stats[0].YeuCauThanhLy ?? 0
			}
		},

		async loadDSKho() {
			const [stats, data] = await Promise.all([
				apiCallPromise('work/HH_Kho_Select_Stats', this.filter),
				apiCallPromise('work/HH_Kho_Select', this.filter)
			])

			let tempData = [...data] ?? []
			tempData.forEach((HangHoa) => {
				const DSCaBiet = JSON.parse(HangHoa?.DanhSachCaBiet || '[]')
				DSCaBiet.forEach((CaBiet) => {
					CaBiet.DonViTinh = HangHoa.TenDonVi
					CaBiet.SoLuong = 1
					CaBiet.Tong = 1
					CaBiet.Is_CaBiet = 1
				})
				HangHoa.DSCaBiet = DSCaBiet

				const DSSoLuong = JSON.parse(HangHoa?.DanhSachSoLuong || '[]')
				HangHoa.DSSoLuong = DSSoLuong
			})
			this.stats = this.mapStatsData(stats)
			this.DSKho = tempData
			this.itemTransfer = {}
		},

		async loadDSYeuCau() {
			const [stats, data] = await Promise.all([
				apiCallPromise('work/HH_Kho_Select_Stats', this.filter),
				apiCallPromise('work/HH_Kho_Select_YeuCau', this.filter)
			])
			this.stats = this.mapStatsData(stats)
			this.DSYeuCau = data
		},

		async loadDSDiaDiem() {
			const data = await apiCallPromise('work/HH_DiaDiem_Select')
			this.DSDiaDiem = data
		},

		async loadDSKhuVuc() {
			const data = await apiCallPromise('work/HH_KhuVuc_Select')
			this.DSKhuVuc = data
		},

		async loadDSDonViTinh() {
			const data = await apiCallPromise('work/HH_DonViTinh_Select')
			this.DSDonViTinh = data
		},

		async handleLoadData(params = {}) {
			this.loading = true
			try {
				if (this.khoArray.includes(params.TinhTrangHangHoa)) {
					this.DSKho = []
					this.filter = {
						TinhTrangHangHoa: params.TinhTrangHangHoa ?? 'TRONG_KHO',
						DiaDiem_Id: params.DiaDiem_Id ?? 0,
						LoaiHangHoa: params.LoaiHangHoa ?? 'TAT_CA'
					}
					await this.loadDSKho()
				} else {
					this.DSYeuCau = []
					this.filter = {
						TinhTrangHangHoa: params.TinhTrangHangHoa ?? 'TRONG_KHO',
						LoaiYeuCau: params.LoaiYeuCau,
						DiaDiem_Id: params.DiaDiem_Id ?? 0,
					}
					if (this.filter.LoaiYeuCau !== null) await this.loadDSYeuCau()
				}
			} finally {
				this.loading = false
			}
		},
		handleTransfer(item) {
			this.itemTransfer = { ...item }
			this.isShowDialogTransfer = true
		},

		handleEditCaBiet(item) {
			this.selectedCaBiet = { ...item }
			this.isShowDialogUpdateCaBiet = true
		},

		handleDuyetPhieuNhap(item) {
			this.isShowDialogDuyetPhieuNhap = true
			this.selectedItem = { ...item }
		},
		handleDuyetPhieuKiemKe(item) {
			this.isShowDialogDuyetPhieuKiemKe = true
			this.selectedItem = { ...item }
		},
		handleOnQR(CaBiet) {
			this.isShowDialogQR = true
			this.selectedCaBiet = { ...CaBiet }
		},
		handleOnQuetQR() {
			this.isShowDialogQuetQR = true
		},
		async handleOnViewHistory(item, Is_CaBiet) {
			const apiUrl = Is_CaBiet === true ? 'work/TS_CaBiet_Select_LichSu' : 'work/HH_HangHoa_Select_LichSu'
			const params = Is_CaBiet === true ? {
				CaBiet_Id: item.CaBiet_Id
			} : {
				HangHoa_Id: item.HangHoa_Id,
				DiaDiem_Id: item.DiaDiem_Id,
				KhuVuc_Id: item.KhuVuc_Id
			}
			const data = await apiCallPromise(apiUrl, params)
			this.historyInfo = data
			this.historyType = Is_CaBiet ? 'CA_BIET' : 'HANG_HOA'
			this.isShowDialogHistory = true
		},

		// --- Local patch methods (tránh reload toàn bộ danh sách) ---

		async refreshStats() {
			const stats = await apiCallPromise('work/HH_Kho_Select_Stats', this.filter)
			this.stats = this.mapStatsData(stats)
		},

		handleCaBietUpdated(updatedData) {
			for (var i = 0; i < this.DSKho.length; i++) {
				var hangHoa = this.DSKho[i]
				if (!hangHoa.DSCaBiet) continue
				var caBiet = hangHoa.DSCaBiet.find(function (cb) { return cb.CaBiet_Id === updatedData.CaBiet_Id })
				if (caBiet) {
					Object.assign(caBiet, updatedData)
					if (updatedData.KhuVuc_Id !== undefined) {
						var khuVuc = this.DSKhuVuc.find(function (kv) { return kv.KhuVuc_Id === updatedData.KhuVuc_Id })
						caBiet.TenKhuVuc = khuVuc ? khuVuc.TenKhuVuc : (updatedData.KhuVuc_Id === 0 ? 'Kho' : '')
					}
					var dangSuDung = 0
					for (var j = 0; j < hangHoa.DSCaBiet.length; j++) {
						if (hangHoa.DSCaBiet[j].TinhTrang === 'DANG_SU_DUNG') dangSuDung++
					}
					hangHoa.Tong = hangHoa.DSCaBiet.length
					hangHoa.DangSuDung = dangSuDung
					hangHoa.TrongKho = hangHoa.Tong - dangSuDung
					break
				}
			}
			this.refreshStats()
		},

		handleQrUpdated(data) {
			for (var i = 0; i < this.DSKho.length; i++) {
				var hangHoa = this.DSKho[i]
				if (!hangHoa.DSCaBiet) continue
				var caBiet = hangHoa.DSCaBiet.find(function (cb) { return cb.CaBiet_Id === data.CaBiet_Id })
				if (caBiet) {
					caBiet.MaVach = data.MaVach
					break
				}
			}
		},

		async handlePhieuApproved(data) {
			this.DSYeuCau = this.DSYeuCau.filter(function (item) { return item.Id !== data.Id })
			await this.refreshStats()
		},
	}

}
</script>