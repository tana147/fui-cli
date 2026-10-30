<template>
	<div class="papers-reward-page">
		<!-- 1. Banner đợt nộp đề xuất -->
		<uc-reward-period-banner :dot-de-xuat="dotDeXuatKhenThuong" :file-base-url="urlReturnFile" />

		<!-- 2. Bảng dữ liệu chính (fixed-header, c-underline-search, jsonToExcel) -->
		<uc-main-view :table-rows="dsDeXuat" :is-table-ready="isTableReady" @on-add="openAddDialog"
			@on-edit="openEditDialog" @on-delete="handleDelete" />

		<!-- 4. Modal tạo / sửa hồ sơ đề xuất -->
		<uc-modal-article v-model="isModalOpen" :edited-item="editedItem" :edited-index="editedIndex"
			:is-loading-save="isLoadingSave" :ds-ngan-hang="dsNganHang" :api-file="apiFile"
			:url-return-file="urlReturnFile" @on-close="closeModal" @on-save="saveSubmit"
			@on-save-draft="saveDraft" />
	</div>
</template>

<script>
	export default {
		name: 'uc-main-page',
		data() {
			return {
				// 1. Controls
				isModalOpen: false,
				isTableReady: false,
				isLoadingSave: false,

				// 2. API Data
				dsDeXuat: [],
				dsDot: [],
				dsNganHang: [],

				// 3. Local state
				editedIndex: -1,
				editedItem: {
					KhenThuongObj: {
						DotID: null,
						LoaiKhenThuong: null,
						TenCuocThi_CongTrinh: '',
						CapDoCuocThi: null,
						LoaiHinhCuocThi: null,
						GiaiThuong: null,
						LoaiSHTT: null,
						PhamViSHTT: null,
						Is_DauRaDeTaiCoSo: false,
						NoiCapVanBang: '',
						MaSoDeTai: '',
						SoQuyetDinh_VanBang: '',
						NgayBanHanh: '',
						HinhThucThanhToan: null,
						GhiChu: '',
					},
					MembersObjArr: [],
					FilesObjArr: [],
				},
				defaultItem: {
					KhenThuongObj: {
						DotID: null,
						LoaiKhenThuong: null,
						TenCuocThi_CongTrinh: '',
						CapDoCuocThi: null,
						LoaiHinhCuocThi: null,
						GiaiThuong: null,
						LoaiSHTT: null,
						PhamViSHTT: null,
						Is_DauRaDeTaiCoSo: false,
						NoiCapVanBang: '',
						MaSoDeTai: '',
						SoQuyetDinh_VanBang: '',
						NgayBanHanh: '',
						HinhThucThanhToan: null,
						GhiChu: '',
					},
					MembersObjArr: [],
					FilesObjArr: [],
				},
			}
		},
		computed: {
			dotDeXuatKhenThuong() {
				if (!this.dsDot || this.dsDot.length === 0) return null
				// 1. Ưu tiên đợt đang mở và nằm trong thời hạn tiếp nhận
				const activeDot = this.dsDot.find(d => d.IsActive === 1 && d.TinhTrang === 1)
				if (activeDot) return activeDot
				// 2. Ưu tiên đợt đang mở (TinhTrang = 1) mới nhất
				const openDot = this.dsDot.find(d => d.TinhTrang === 1)
				if (openDot) return openDot
				// 3. Nếu tất cả đã đóng, lấy đợt gần nhất để giảng viên biết thông tin
				return this.dsDot[0]
			},
			apiFile() {
				return (window.vueData && window.vueData.v_Set && window.vueData.v_Set.apiFile) || ''
			},
			urlReturnFile() {
				return (window.vueData && window.vueData.v_Set && window.vueData.v_Set.urlReturnFile) || ''
			},
		},
		mounted() {
			this.initData()
		},
		methods: {
			async initData() {
				this.isTableReady = false
				await Promise.all([
					this.loadDeXuat(),
					this.loadDot(),
					this.loadNganHang(),
				])
				this.isTableReady = true
			},
			async loadDeXuat() {
				const data = await ajaxCALLPromise('/ThiKHCN_Get_ByNhanVienSubmit')
				this.dsDeXuat = data || []
			},
			async loadDot() {
				const data = await ajaxCALLPromise('/ThiKHCN_Dot_Get')
				this.dsDot = data || []
			},
			loadNganHang() {
				$.ajax({
					type: 'GET',
					url: 'https://api.vietqr.io/v2/banks',
					contentType: 'application/json; charset=utf-8',
					dataType: 'json',
					crossDomain: true,
					success: (res) => {
						if (res.code === '00') {
							this.dsNganHang = res.data
						}
					},
				})
			},
			openAddDialog() {
				this.editedIndex = -1
				this.editedItem = JSON.parse(JSON.stringify(this.defaultItem))
				if (this.dotDeXuatKhenThuong) {
					this.editedItem.KhenThuongObj.DotID = this.dotDeXuatKhenThuong.DotID
				}
				this.isModalOpen = true
			},
			async openEditDialog(item) {
				const res = await ajaxCALLPromise('/ThiKHCN_Get_ByID', { KhenThuongID: item.KhenThuongID })
				if (res && res.length >= 3) {
					const khenThuongObj = res[0][0] || {}
					if (khenThuongObj.NgayBanHanh) {
						if (typeof moment !== 'undefined') {
							let m = moment(khenThuongObj.NgayBanHanh, 'YYYY-MM-DD')
							if (!m.isValid()) m = moment(khenThuongObj.NgayBanHanh, 'DD/MM/YYYY')
							if (m.isValid()) khenThuongObj.NgayBanHanh = m.format('YYYY-MM-DD')
						}
					}
					this.editedItem = {
						KhenThuongObj: khenThuongObj,
						MembersObjArr: res[1] || [],
						FilesObjArr: res[2] || [],
					}
					this.editedIndex = item.KhenThuongID
					this.isModalOpen = true
				}
			},
			closeModal() {
				this.isModalOpen = false
			},
			handleDelete(item) {
				const $this = this
				confirm({
					title: 'Bạn có chắc chắn muốn xóa hồ sơ đề xuất này?',
					action: async function () {
						await ajaxCALLPromise('/ThiKHCN_Del_ByID', { KhenThuongID: item.KhenThuongID })
						Vue.$toast.success('Xóa hồ sơ đề xuất thành công', { position: 'top' })
						$this.loadDeXuat()
					},
				})
			},
			async saveSubmit(payload) {
				await this.executeSave(2, 'Nộp hồ sơ đề xuất khen thưởng thành công!', payload)
			},
			async saveDraft(payload) {
				await this.executeSave(1, 'Lưu hồ sơ dự thảo thành công!', payload)
			},
			async executeSave(trangThai, successMsg, payload) {
				this.isLoadingSave = true
				try {
					const isNew = this.editedIndex === -1
					const url = isNew ? '/ThiKHCN_INS_Obj' : '/ThiKHCN_Udp_Obj'

					const params = {
						KhenThuongObj: JSON.stringify(this.editedItem.KhenThuongObj),
						MembersObjArr: JSON.stringify(this.editedItem.MembersObjArr),
						FilesObjArr: JSON.stringify(this.editedItem.FilesObjArr),
						TrangThai: trangThai,
					}
					if (!isNew) {
						params.KhenThuongID = this.editedItem.KhenThuongObj.KhenThuongID
					}

					await ajaxCALLPromise(url, params)

					// Dọn dẹp các file cũ bị gỡ bỏ sau khi lưu DB thành công
					if (payload && payload.pendingDeleteFileIDs && payload.pendingDeleteFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: payload.pendingDeleteFileIDs.join(',') }, () => {})
					}

					Vue.$toast.success(successMsg, { position: 'top' })
					this.closeModal()
					await this.loadDeXuat()
				} finally {
					this.isLoadingSave = false
				}
			},
		},
	}
</script>