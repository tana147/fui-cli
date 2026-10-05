<template>
	<z-layout>
		<v-app-bar density="compact" :elevation="0" title="Quản lý phiếu nhập" class="border-b">
			<template v-slot:append>
				<v-btn color="primary" prepend-icon="mdi-plus" variant="flat" @click="isShowDialogAdd = true">Thêm mới
				</v-btn>
			</template>
		</v-app-bar>
		<uc-table-phieu-nhap ref="refTablePhieuNhap" :DSPhieuNhap="DSPhieuNhap" :StatsInfo="StatsInfo"
			:DSDiaDiem="DSDiaDiem" @view-detail-emit="onViewDetailEmit" @edit-emit="onEditEmit"
			@load-data="handleLoadData" @view-detail-danh-sach="handleViewDetailDanhSach"
			@on-finish-phieu-dat-hang="onFinishPhieuDatHang"></uc-table-phieu-nhap>
		<uc-drawer-view-detail v-model:isShow="isShowDialogViewDetail" :selectedItem="selectedItem"
			@edit-emit="onDrawerEdit" @print-emit="onDrawerPrint"></uc-drawer-view-detail>
		<uc-modal-add v-model:isShow="isShowDialogAdd" :loadDSPhieuNhap="loadDSPhieuNhap" :DSNhanVien="DSNhanVien"
			:DSNhaCungCap="DSNhaCungCap" :DSDiaDiem="DSDiaDiem" :DSDonViTinh="DSDonViTinh"></uc-modal-add>
		<uc-modal-edit v-model:isShow="isShowDialogEdit" :loadDSPhieuNhap="loadDSPhieuNhap" :DSNhanVien="DSNhanVien"
			:DSNhaCungCap="DSNhaCungCap" :DSDiaDiem="DSDiaDiem" :selectedItem="selectedItem"></uc-modal-edit>
		<uc-modal-view-danh-sach v-model:isShow="isShowDialogViewDetailDanhSach" :DanhSach='dataViewDanhSach'
			:TinhTrang="TinhTrangHoaDon"></uc-modal-view-danh-sach>

		<uc-modal-hoan-thanh-phieu-dat-hang v-model:isShow="isShowDialogFinishPhieuDatHang" :DSNhaCungCap="DSNhaCungCap"
			:DSDiaDiem="DSDiaDiem" :DSNhanVien="DSNhanVien" :DSDonViTinh="DSDonViTinh" :selectedItem="selectedItem"
			@load-danh-sach-phieu-dat-hang='handleLoadData'></uc-modal-hoan-thanh-phieu-dat-hang>
	</z-layout>
</template>

<script>
	export default {
		data() {
			return {
				isShowDialogAdd: null,
				isShowDialogEdit: null,
				isShowDialogViewDetail: null,
				isShowDialogViewDetailDanhSach: null,
				isShowDialogFinishPhieuDatHang: false,
	
				filter: {
					DiaDiem_Id: 0,
					Nam: 2026,
					Thang: new Date().getMonth() + 1
				},
				StatsInfo: {},
				DSPhieuNhap: [],
				DSCoHoaDon: [],
				DSKhongCoHoaDon: [],
				dataViewDanhSach: [],
				DSNhanVien: [],
				DSNhaCungCap: [],
				DSDiaDiem: [],
				DSDonViTinh: [],
				selectedItem: {},
				TinhTrangHoaDon: null,
			}
		},
		mounted() {
			this.loadData()
		},
		computed: {},
		watch: {},
		methods: {
			async loadData() {
				try {
					await Promise.all([
						this.loadDSNhanVien(),
						this.loadDSNhaCungCap(),
						this.loadDSDiaDiem(),
						this.loadDSDonViTinh(),
					])
					await this.loadDSPhieuNhap()
				} catch (error) {
					console.error('Lỗi khi tải dữ liệu:', error)
				}
			},
	
			async loadDSNhanVien() {
				const data = await apiCallPromise('work/HH_NhanVien_Select')
				this.DSNhanVien = data
			},
	
			async loadDSNhaCungCap() {
				const data = await apiCallPromise('work/HH_NhaCungCap_Select_Dropdown')
				this.DSNhaCungCap = data
			},
	
			async loadDSDiaDiem() {
				const data = await apiCallPromise('work/HH_DiaDiem_Select')
				this.DSDiaDiem = data
			},
	
			async loadDSDonViTinh() {
				const data = await apiCallPromise('work/HH_DonViTinh_Select')
				this.DSDonViTinh = data
			},
	
			async loadDSPhieuNhap(params = {}) {
				this.filter = {
					DiaDiem_Id: params.DiaDiem_Id ?? this.filter.DiaDiem_Id,
					Nam: params.Nam ?? this.filter.Nam,
					Thang: params.Thang ?? this.filter.Thang,
				}
				let data = await apiCallPromise('work/HH_PhieuNhap_Select', this.filter)
				data[1].forEach((PhieuNhap) => {
					const DSFile = JSON.parse(PhieuNhap.DanhSachFile ?? '[]')
					PhieuNhap.DSFile = DSFile
				})
				this.StatsInfo = {
					TongSoPhieu: data[0][0].TongSoPhieu,
					CoHoaDon: data[0][0].CoHoaDon,
					KhongCoHoaDon: data[0][0].KhongCoHoaDon
				}
				let tempData = [...data[2], ...data[1]]
				tempData.forEach((item, index) => {
					item.STT = index + 1
				})
				this.DSPhieuNhap = tempData
				this.DSCoHoaDon = data[3]
				this.DSKhongCoHoaDon = data[4]
			},
	
			async onViewDetailEmit(item) {
				if (item.LoaiPhieu === 'PHIEU_NHAP' || item.LoaiPhieu === 'LUAN_CHUYEN') {
					const data = await apiCallPromise('work/HH_PhieuNhap_Select_ById', {
						PhieuNhap_Id: item.PhieuNhap_Id
					})
					const arrayHangHoa = [...data[0], ...data[1]]
					this.selectedItem = { ...item, arrayHangHoa: arrayHangHoa }
					this.isShowDialogViewDetail = true
				}
				else {
					const data = await apiCallPromise('work/HH_PhieuDatHang_Select_By_Id', {
						PhieuDatHang_Id: item.PhieuDatHang_Id
					})
					const arrayHangHoa = [...data]
					this.selectedItem = { ...item, arrayHangHoa: arrayHangHoa }
					this.isShowDialogViewDetail = true
				}
			},
	
			handleLoadData(params) {
				this.loadDSPhieuNhap(params)
			},
	
			async onEditEmit(item) {
				const data = await apiCallPromise('work/HH_PhieuNhap_Select_ById', {
					PhieuNhap_Id: item.PhieuNhap_Id
				})
				const arrayHangHoa = [...data[0]]
				this.isShowDialogEdit = true
				this.selectedItem = { ...item, NgayMua: item.NgayNhap, arrayHangHoa: arrayHangHoa }
			},
	
			handleViewDetailDanhSach(TinhTrang) {
				this.TinhTrangHoaDon = TinhTrang
				this.dataViewDanhSach = TinhTrang === 'KHONG_CO_HOA_DON' ? this.DSKhongCoHoaDon : this.DSCoHoaDon
				this.isShowDialogViewDetailDanhSach = true
			},
	
			onFinishPhieuDatHang(item) {
				this.selectedItem = { ...item }
				this.loadDetailPhieuDatHang()
				this.isShowDialogFinishPhieuDatHang = true
			},
	
			async loadDetailPhieuDatHang() {
				if (this.selectedItem.PhieuDatHang_Id === null) return
				const params = {
					PhieuDatHang_Id: this.selectedItem.PhieuDatHang_Id
				}
				const data = await apiCallPromise('work/HH_PhieuDatHang_Select_By_Id', params)
				this.selectedItem = { ...this.selectedItem, arrayHangHoa: [...data] }
			},

			onDrawerEdit(item) {
				this.isShowDialogViewDetail = false
				this.onEditEmit(item)
			},

			onDrawerPrint(item) {
				this.isShowDialogViewDetail = false
				this.$refs.refTablePhieuNhap?.onPrint?.(item)
			},
		},
	}
</script>