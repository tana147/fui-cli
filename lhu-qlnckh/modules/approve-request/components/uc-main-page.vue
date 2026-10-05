<template>
	<div>
		<uc-main-view :dsbaibao="DSBaiBao" :dsdanhmucloaianpham="DSLoaiAnPham" :dsnganhang="DSNganHang"
			:dsdotduyet="DSDotDuyet" @on-reload="fetchDSBaiBao" @on-edit="openEditModal" @on-delete="handleDelete"
			@on-manage-dotduyet="isManageDotDuyetOpen = true" />
		<uc-modal-edit v-model="isEditModalOpen" :editRow="editRow" :dsdanhmuctapchi="DSLoaiTapChi"
			:dsdanhmucloaianpham="DSLoaiAnPham" :dsnam="DSNam" :dshesochatluong="DSHeSoChatLuong"
			:dsnganhang="DSNganHang" :dscongthuckhenthuong="DSCongThucKhenThuong" :dsdotduyet="DSDotDuyet"
			@on-reload="fetchDSBaiBao" @on-manage-dotduyet="isManageDotDuyetOpen = true" />
		<uc-dotduyet-manage v-model="isManageDotDuyetOpen" @on-reload="fetchDSDotDuyet" />
	</div>
</template>

<script>
	export default {
		name: 'uc-main-page',
	data() {
		return {
			isEditModalOpen: false,
			isManageDotDuyetOpen: false,
			editRow: {},
			DSBaiBao: [],
			DSLoaiTapChi: [],
			DSLoaiAnPham: [],
			DSNam: [],
			DSCongThucKhenThuong: [],
			DSHeSoChatLuong: [],
			DSNganHang: [],
			DSDotDuyet: [],
		}
	},
	mounted() {
		this.initData()
	},
	methods: {
		async fetchDSBaiBao() {
			const data = await ajaxCALLPromise('/AnPham_Get_ByTrangThai', { TrangThai: '2,3' })
			this.DSBaiBao = data || []
		},
		async initData() {
			const [loaiTapChi, loaiAnPham, nam, congThucKhenThuong, heSoChatLuong] = await Promise.all([
				ajaxCALLPromise('/LoaiDMTapChi_Get_All'),
				ajaxCALLPromise('/AnPham_LoaiAnPham_Get_All'),
				ajaxCALLPromise('/System_Get_Nam'),
				ajaxCALLPromise('/CongThucKhenThuong_Get'),
				ajaxCALLPromise('/HSCL_Get'),
			])
			this.DSLoaiTapChi = loaiTapChi || []
			this.DSLoaiAnPham = (loaiAnPham || []).map(item => {
				item.DSSubAnPham = JSON.parse(item.sub || '[]')
				return item
			})
			this.DSNam = nam || []
			this.DSCongThucKhenThuong = congThucKhenThuong || []
			this.DSHeSoChatLuong = heSoChatLuong || []
			await this.fetchDSBaiBao()
			this.fetchDSNganHang()
			this.fetchDSDotDuyet()
		},
		async fetchDSDotDuyet() {
			const data = await ajaxCALLPromise('/AnPham_DotDuyet_Get')
			this.DSDotDuyet = data || []
		},
		fetchDSNganHang() {
			const $this = this
			$.ajax({
				type: 'GET',
				url: 'https://api.vietqr.io/v2/banks',
				contentType: 'application/json; charset=utf-8',
				dataType: 'json',
				crossDomain: true,
				success: function (res) {
					if (res.code === '00') {
						$this.DSNganHang = res.data
					}
				},
			})
		},
		openEditModal(item) {
			this.editRow = item
			this.isEditModalOpen = true
		},
		handleDelete(item) {
			const $this = this
			confirm({
				title: 'Xác nhận xóa bài báo',
				action: async function () {
					await ajaxCALLPromise('/AnPham_Del_ByAnPhamID', { AnPhamID: item.AnPhamID })
					$this.fetchDSBaiBao()
				},
			})
		},
	},
	}
</script>