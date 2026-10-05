<template>
	<div>
		<uc-filter @filterEmit='onSearch' @doiSoatEmit='onDoiSoat' @exportEmit="onExport"
			@dongBoMultiEmit="onDongBoMultiEmit"></uc-filter>

		<uc-table :data="DataDoiSoat" :DataDSChuyenKhoanThucTe="DataDSChuyenKhoanThucTe"
			:DataDSChietKhauTienMat="DataDSChietKhauTienMat" :ngayDoiSoat="filter?.NgayDoiSoat"
			@chuyenKhoanEmit='onChuyenKhoanEmit' @chietKhauTienMatEmit='onChietKhauTienMatEmit'
			@phieuKetCaEmit="onPhieuKetCaEmit" @danhSachHoaDonEmit="onDanhSachHoaDonEmit"
			@dongBoDuLieuEmit="onDongBoDuLieuEmit" @capNhatChietKhauEmit='onCapNhatChietKhauEmit'
			@danhSachHoaDonTheoLoaiEmit='onDanhSachHoaDonTheoLoaiEmit'></uc-table>

		<uc-dialog-du-lieu-doi-soat :isShowDialogDataDoiSoat="isShowDialogDataDoiSoat"
			@update:isShowDialogDataDoiSoat="isShowDialogDataDoiSoat = $event"></uc-dialog-du-lieu-doi-soat>

		<uc-dialog-dong-bo-multi :isShowDialogDongBoMulti="isShowDialogDongBoMulti"
			@update:isShowDialogDongBoMulti="isShowDialogDongBoMulti = $event"></uc-dialog-dong-bo-multi>

		<uc-danh-sach-hoa-don v-if="isShowDialogDanhSachHoaDon" :isShowDialogDanhSachHoaDon="isShowDialogDanhSachHoaDon"
			@update:isShowDialogDanhSachHoaDon="isShowDialogDanhSachHoaDon = $event" :data="DataDSHoaDon"
			:ca="SelectedCa" :cuaHang="SelectedCuaHang" :loaiDuLieu="LoaiDuLieu">
		</uc-danh-sach-hoa-don>

		<uc-danh-sach-phieu-ket-ca :isShowDialogDanhSachPhieuKetCa="isShowDialogDanhSachPhieuKetCa"
			@update:isShowDialogDanhSachPhieuKetCa="isShowDialogDanhSachPhieuKetCa = $event" :data="DataDSPhieuKetCa">
		</uc-danh-sach-phieu-ket-ca>

		<uc-danh-sach-hoa-don-theo-hinh-thuc v-if="isShowDialogDanhSachHoaDonTheoLoai"
			:isShowDialogDanhSachHoaDonTheoLoai="isShowDialogDanhSachHoaDonTheoLoai"
			@update:isShowDialogDanhSachHoaDonTheoLoai="isShowDialogDanhSachHoaDonTheoLoai = $event"
			:data="DataDSHoaDonTheoLoai" :HinhThucThanhToan="HinhThucThanhToan" :ca="SelectedCa"
			:cuaHang="SelectedCuaHang" :loaiDuLieu="LoaiDuLieu"></uc-danh-sach-hoa-don-theo-hinh-thuc>

		<uc-dong-bo-du-lieu :isShowDialogDongBoDuLieu="isShowDialogDongBoDuLieu"
			@update:isShowDialogDongBoDuLieu="isShowDialogDongBoDuLieu = $event" :ca="SelectedCa"
			:cuaHang="SelectedCuaHang" :loadData="loadData"></uc-dong-bo-du-lieu>

		<uc-dialog-export :isShowDialogExport="isShowDialogExport"
			@update:isShowDialogExport="isShowDialogExport = $event"></uc-dialog-export>

		<uc-dialog-cap-nhat-chiet-khau v-if="isShowDialogCapNhatChietKhau"
			:isShowDialogCapNhatChietKhau="isShowDialogCapNhatChietKhau"
			@update:isShowDialogCapNhatChietKhau="isShowDialogCapNhatChietKhau = $event" :ca="SelectedCa"
			:cuaHang="SelectedCuaHang" :loadData="loadData"></uc-dialog-cap-nhat-chiet-khau>

		<uc-dialog-chuyen-khoan-thuc-te :isShowDialogChuyenKhoanThucTe="isShowDialogChuyenKhoanThucTe"
			@update:isShowDialogChuyenKhoanThucTe="isShowDialogChuyenKhoanThucTe = $event"
			:loadData="loadData"></uc-dialog-chuyen-khoan-thuc-te>

		<uc-dialog-chiet-khau-tien-mat :isShowDialogChietKhauTienMat="isShowDialogChietKhauTienMat"
			@update:isShowDialogChietKhauTienMat="isShowDialogChietKhauTienMat = $event" :loadData="loadData">
		</uc-dialog-chiet-khau-tien-mat>

	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				vueData,
	
				DataDoiSoat: [],
				DataDSPhieuKetCa: [],
				DataDSHoaDon: [],
				DataDSHoaDonTheoLoai: [],
				DataDSChuyenKhoanThucTe: [],
				DataDSChietKhauTienMat: [],
	
				isShowDialogDataDoiSoat: false,
				isShowDialogDanhSachHoaDon: false,
				isShowDialogDanhSachPhieuKetCa: false,
				isShowDialogDongBoDuLieu: false,
				isShowDialogCapNhatChietKhau: false,
				isShowDialogDanhSachHoaDonTheoLoai: false,
				isShowDialogExport: false,
				isShowDialogChuyenKhoanThucTe: false,
				isShowDialogChietKhauTienMat: false,
				isShowDialogDongBoMulti: false,
	
				filter: null,
				SelectedCa: null,
				SelectedCuaHang: null,
				HinhThucThanhToan: null,
				LoaiDuLieu: null,
				caMap: {
					'1': 'Sáng',
					'2': 'Tối',
					'3': 'Đêm'
				},
				trangThaiMap: {
					'NOT': 'Chưa đối soát',
					'WRONG': 'Có sai lệch',
					'COMPLETED': 'Đã đối soát'
				},
			}
		},
		mounted() { },
		computed: {},
		watch: {},
		methods: {
			onSearch(filter) {
				this.filter = filter
				this.loadData()
				this.loadChuyenKhoanThucTe()
				this.loadChietKhauTienMatThucTe()
			},
	
			async loadData() {
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_Select', this.filter)
	
				let DataCuaHang = data[0]
				let DataDoanhThu = data[1]
	
				DataCuaHang.map((CuaHang) => {
					CuaHang.Ca = []
	
					DataDoanhThu.map((data) => {
						if (data.CuaHangID === CuaHang.CuaHangID) CuaHang.Ca.push({ ...data, isEditing: false })
					})
	
					const grouped = CuaHang.Ca.reduce((acc, item) => {
						const key = item.NgayDoiSoat
						if (!acc[key]) acc[key] = []
						acc[key].push(item)
						return acc
					}, {})
	
					CuaHang.Ngay = grouped
				})
				this.DataDoiSoat = DataCuaHang
			},
	
			async loadChuyenKhoanThucTe() {
				const params = {
					TuNgay: this.filter.TuNgayDoiSoat,
					DenNgay: this.filter.DenNgayDoiSoat
				}
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatChuyenKhoan_Select', params)
				this.DataDSChuyenKhoanThucTe = data
			},
	
			async loadChietKhauTienMatThucTe() {
				const params = {
					TuNgay: this.filter.TuNgayDoiSoat,
					DenNgay: this.filter.DenNgayDoiSoat
				}
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatChietKhauTienMat_Select', params)
				this.DataDSChietKhauTienMat = data
			},
	
			onDoiSoat() {
				this.isShowDialogDataDoiSoat = true
			},
	
			async onPhieuKetCaEmit(item, ca, params) {
				this.SelectedCuaHang = item
				this.SelectedCa = ca
				this.isShowDialogDanhSachPhieuKetCa = true
				const data = await this.vueData.ajaxCALLPromise('/eorder/KetCa_Select_ByCa', params)
				this.DataDSPhieuKetCa = data
			},
	
			async onDanhSachHoaDonEmit(item, ca, params) {
				this.SelectedCuaHang = item
				this.SelectedCa = ca
				this.isShowDialogDanhSachHoaDon = true
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_Select_HoaDon', params)
				this.DataDSHoaDon = data
				this.LoaiDuLieu = params.LoaiDuLieu
			},
	
			async onDongBoDuLieuEmit(item, ca) {
				this.isShowDialogDongBoDuLieu = true
				this.SelectedCuaHang = item
				this.SelectedCa = ca
			},
	
			async onCapNhatChietKhauEmit(item, ca) {
				this.isShowDialogCapNhatChietKhau = true
				this.SelectedCuaHang = { ...item }
				this.SelectedCa = { ...ca }
			},
	
			async onDanhSachHoaDonTheoLoaiEmit(item, ca, params) {
				this.SelectedCuaHang = item
				this.SelectedCa = ca
				this.LoaiDuLieu = params.LoaiDuLieu
				this.isShowDialogDanhSachHoaDonTheoLoai = true
				const data = await this.vueData.ajaxCALLPromise('/eorder/DoiSoatDoanhThu_Select_HoaDon', params)
				this.DataDSHoaDonTheoLoai = data
				this.HinhThucThanhToan = params.HinhThucThanhToan
			},
	
			onExport() {
				this.isShowDialogExport = true
			},
	
			onChuyenKhoanEmit() {
				this.isShowDialogChuyenKhoanThucTe = true
			},
	
			onChietKhauTienMatEmit() {
				this.isShowDialogChietKhauTienMat = true
			},
			onDongBoMultiEmit() {
				this.isShowDialogDongBoMulti = true
			}
	
		},
	}
</script>