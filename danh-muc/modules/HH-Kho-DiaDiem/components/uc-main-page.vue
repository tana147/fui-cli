<template>
	<z-layout>
		<uc-top-bar :DSDiaDiem="DSDiaDiem" :YeuCauChoDuyet="YeuCauChoDuyet" :loading="loading"
			@load-data="handleLoadDataEmit" @on-view-cho-duyet="onViewChoDuyet"></uc-top-bar>
		<uc-table-hang-hoa :DSHangHoa="DSHangHoa" :loading="loading"
			@on-edit-ca-biet="handleEditCaBiet" @on-xuat-hang-hoa="handleXuatHangHoa"
			@on-luan-chuyen="handleLuanChuyen"></uc-table-hang-hoa>

		<uc-modal-update-ca-biet v-model:isShow="isShowDialogUpdateCaBiet" :selectedCaBiet="selectedCaBiet"
			:DSKhuVuc="DSKhuVuc" @onReload="handleCaBietUpdated"></uc-modal-update-ca-biet>

		<uc-modal-xuat-hang-hoa v-model:isShow="isShowDialogXuatHangHoa" :selectedItem="selectedItem"
			:DSKhuVuc="DSKhuVuc" @onReload="loadDSHangHoaDiaDiem"></uc-modal-xuat-hang-hoa>

		<uc-modal-luan-chuyen v-model:isShow="isShowDialogLuanChuyen" :selectedItem="selectedItem" :DSKhuVuc="DSKhuVuc"
			@onReload="loadDSHangHoaDiaDiem"></uc-modal-luan-chuyen>

		<uc-modal-cho-xac-nhan v-model:isShow="isShowDialogChoXacNhan" :DSChoXacNhan="DSChoXacNhan"
			@on-view-detail-yeu-cau="onViewDetailYeuCau" @load-data="handleLoadDataEmit"></uc-modal-cho-xac-nhan>

		<uc-modal-xem-chi-tiet-yeu-cau v-model:isShow="isShowDialogViewDetailYeuCau" :selectedItem="selectedItem"
			@on-load-danh-sach-cho-xac-nhan="loadDSChoXacNhan"></uc-modal-xem-chi-tiet-yeu-cau>
	</z-layout>
</template>

<script>
	export default {

		data() {
			return {
				isShowDialogUpdateCaBiet: false,
				isShowDialogXuatHangHoa: false,
				isShowDialogLuanChuyen: false,
				isShowDialogChoXacNhan: false,
				isShowDialogViewDetailYeuCau: false,
				loading: false,

				filter: {
					DiaDiem_Id: null,
				},

				DSHangHoa: {
					arrayHangHoa: [],
					expanded: []
				},
				DSDiaDiem: [],
				DSKhuVuc: [],
				selectedCaBiet: {},
				selectedItem: {},
				YeuCauChoDuyet: 0,
				DSChoXacNhan: []
			}
		},

		mounted() {
			this.loadData()
		},

		methods: {
			async loadData() {
				this.loading = true
				try {
					await Promise.all([this.loadDSDiaDiem(), this.loadDSKhuVuc()])
				} finally {
					this.loading = false
				}
			},
			async loadDSHangHoaDiaDiem() {
				if (this.filter.DiaDiem_Id === null) return
				this.loading = true
				const data = await apiCallPromise('work/HH_HangHoa_Select_ByDiaDiem_Id', this.filter)
				let tempData = [...data[0]] ?? []
				let res = []
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
					res.push(HangHoa.HangHoa_Id)
				})
				this.DSHangHoa.arrayHangHoa = tempData
				this.DSHangHoa.expanded = res
				this.DSHangHoa.openListGroup = res

				this.selectedCaBiet = {}
				this.selectedItem = {}
				this.YeuCauChoDuyet = data[1][0].YeuCauChoXacNhan ?? 0
				this.loading = false
			},
			async loadDSDiaDiem() {
				const data = await apiCallPromise('work/HH_DiaDiem_Select')
				this.DSDiaDiem = data
			},
			async loadDSKhuVuc() {
				const data = await apiCallPromise('work/HH_KhuVuc_Select')
				this.DSKhuVuc = data
			},

			async loadDSChoXacNhan() {
				if (this.filter.DiaDiem_Id === null || this.filter.DiaDiem_Id === undefined) return
				const params = {
					DiaDiem_Id: this.filter.DiaDiem_Id
				}
				const data = await apiCallPromise('work/HH_Kho_Select_YeuCau_By_DiaDiem_Id', params)
				this.DSChoXacNhan = data
			},

			handleLoadDataEmit(params = {}) {
				this.filter = {
					DiaDiem_Id: params.DiaDiem_Id ?? this.filter.DiaDiem_Id
				}
				this.loadDSHangHoaDiaDiem()
				this.loadDSChoXacNhan()
			},
			handleCaBietUpdated(updatedData) {
				for (var i = 0; i < this.DSHangHoa.arrayHangHoa.length; i++) {
					var hangHoa = this.DSHangHoa.arrayHangHoa[i]
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
			},
			handleEditCaBiet(item) {
				this.selectedCaBiet = { ...item }
				this.isShowDialogUpdateCaBiet = true
			},
			handleXuatHangHoa(item) {
				this.selectedItem = { ...item }
				this.isShowDialogXuatHangHoa = true
			},
			handleLuanChuyen(item) {
				this.selectedItem = { ...item }
				this.isShowDialogLuanChuyen = true
			},

			onViewChoDuyet() {
				this.loadDSChoXacNhan()
				this.isShowDialogChoXacNhan = true
			},

			async onViewDetailYeuCau(item) {
				const params = {
					Id: item.Id,
					LoaiYeuCau: 'PHIEU_NHAP'
				}
				item.Info = JSON.parse(item.PhieuInfo || '[]')
				const data = await apiCallPromise('work/HH_Kho_Select_YeuCau_By_Id', params)
				const arrayHangHoa = [...data[0], ...data[1]]
				this.selectedItem = { ...item, arrayHangHoa: arrayHangHoa }
				this.isShowDialogViewDetailYeuCau = true
			},
		}

	}
</script>