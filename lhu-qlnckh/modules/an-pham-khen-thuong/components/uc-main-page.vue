<template>
	<div class="papers-reward-page">
		<uc-reward-period-banner :dot-de-xuat="dotDeXuatKhenThuong" />
		<uc-main-view :table-rows="dsBaiBao" @on-add="openDialog" @on-edit="editItem" @on-delete="deleteItem" />
		<uc-modal-article ref="ArticleModal" v-model="isArticleModalOpen" :edited-item="editedItem"
			:edited-index="editedIndex" :danh-muc-tap-chi-arr="dsDanhMucTapChi"
			:danh-muc-loai-an-pham-arr="dsDanhMucLoaiAnPham" :nam-arr="dsNam" :ds-ngan-hang="dsNganHang"
			:is-loading-save="isLoadingSave" @on-close="close" @on-save="save" @on-save-temp="saveTemp"
			@on-submit-proposal="saveDeXuat_baiBao" @on-change-nhom-an-pham="resetFileIDMinhChungHoTroCaoHoc" />
	</div>
</template>

<script>
	export default {
		name: 'uc-main-page',
	data() {
		return {
			// 1. Controls
			isArticleModalOpen: false,
			isDeleteModalOpen: false,

			// 2. API / Static arrays
			dsBaiBao: [],
			dsDotDeXuat: [],
			dsDanhMucTapChi: [],
			dsDanhMucLoaiAnPham: [],
			dsNam: [],
			dsNganHang: [],
			dsHeSoChatLuong: [],

			// 3. Local state
			isLoadingSave: false,
			editedIndex: -1,
			deleteId: null,
			trangThai: null,
			editedItem: {
				AnPhamObj: {
					TenAnPham: '',
					LoaiAnPhamID: null,
					TenLoaiAnPham: "",
					TenTapChi: '',
					DanhMucLoaiTapChiID: null,
					TenLoaiDanhMucTapChi: null,
					LoaiSubAnPhamID: null,
					TenLoaiSubAnPham: "",
					NoiDangBai: 'Trong nước',
					NamDangBai: new Date().getFullYear(),
					DuongDanBaiBao: '',
					HeSo_IF: convertDiem(0),
					TrangThai: '',
					MaNhanVienDaiDien: "",
					TenNhanVienDaiDien: "",
					DonViDaiDien: "",
					SoTacGia_LHU: 0,
					DiemHoiDong: convertDiem(0),
					TenHeSoChatLuong: null,
					HeSoChatLuongID: 0,
					PhiThongBao: 0,
					PhiDangBai: 0,
					HoanPhiDangBai: 0,
					ISSN: "",
					Dieu: null,
					Khoan: null,
					Muc: null,
					TongSoTienThuong: 0,
					GhiChu: "",
					SoQuyetDinhKhenThuong: null,
					FileIDKhenThuong: null,
					TongSoTacGia: 0,
					HinhThucThanhToan: 2,
					NguonCapKinhPhi: null,
					NhomAnPham: 1,
					FileIDMinhChungHoTroCaoHoc: null,
					FileIDMinhChungWos: null,
					FileIDMinhChungScopus: null,
					FileIDMinhChungHDCDGSNN: null,
					FileIDMinhChungLacHong: null,
					FileNameMinhChungLacHong: null,
					FileUrlMinhChungLacHong: null,
					FileIDMinhChungKhac: null,
					FileNameMinhChungKhac: null,
					FileUrlMinhChungKhac: null,
					Is_DeNghiXetThuong: true,
					TapSoTrang: '',
					ThangDang: null,
					TheLoaiBienSoanID: null,
					DoiLink: '',
				},
				AuthorsObjArr: [],
				ProofsObjArr: [
					{
						LoaiFile: 2,
						FileIDList: "",
						FileList: [],
						MoTa: ""
					}
				]
			},
			defaultItem: {
				AnPhamObj: {
					TenAnPham: '',
					LoaiAnPhamID: null,
					TenLoaiAnPham: "",
					TenTapChi: '',
					DanhMucLoaiTapChiID: null,
					TenLoaiDanhMucTapChi: null,
					LoaiSubAnPhamID: null,
					TenLoaiSubAnPham: "",
					NoiDangBai: 'Trong nước',
					NamDangBai: new Date().getFullYear(),
					DuongDanBaiBao: '',
					HeSo_IF: convertDiem(0),
					TrangThai: '',
					MaNhanVienDaiDien: "",
					TenNhanVienDaiDien: "",
					DonViDaiDien: "",
					SoTacGia_LHU: 0,
					DiemHoiDong: convertDiem(0),
					TenHeSoChatLuong: null,
					HeSoChatLuongID: 0,
					PhiThongBao: 0,
					PhiDangBai: 0,
					HoanPhiDangBai: 0,
					ISSN: "",
					Dieu: null,
					Khoan: null,
					Muc: null,
					TongSoTienThuong: 0,
					GhiChu: "",
					SoQuyetDinhKhenThuong: null,
					FileIDKhenThuong: null,
					TongSoTacGia: 0,
					HinhThucThanhToan: 2,
					NguonCapKinhPhi: null,
					NhomAnPham: 1,
					FileIDMinhChungHoTroCaoHoc: null,
					FileIDMinhChungWos: null,
					FileIDMinhChungScopus: null,
					FileIDMinhChungHDCDGSNN: null,
					FileIDMinhChungLacHong: null,
					FileNameMinhChungLacHong: null,
					FileUrlMinhChungLacHong: null,
					FileIDMinhChungKhac: null,
					FileNameMinhChungKhac: null,
					FileUrlMinhChungKhac: null,
					Is_DeNghiXetThuong: true,
					TapSoTrang: '',
					ThangDang: null,
					TheLoaiBienSoanID: null,
					DoiLink: '',
				},
				AuthorsObjArr: [],
				ProofsObjArr: [
					{
						LoaiFile: 2,
						FileIDList: "",
						FileList: [],
						MoTa: ""
					}
				]
			}
		}
	},
	computed: {
		dotDeXuatKhenThuong() {
			return (this.dsDotDeXuat || []).find(item => item.TinhTrang === 1)
		}
	},
	watch: {
		isArticleModalOpen(val) {
			val || this.close()
		},
		isDeleteModalOpen(val) {
			val || this.closeDelete()
		}
	},
	mounted() {
		this.initData()
	},
	methods: {
		resetArticleFormState() {
			this.$refs.ArticleModal?.resetFormState()
		},
		validateArticleForm() {
			return this.$refs.ArticleModal?.validateForm()
		},
		buildAuthorsObjArrAPI(authorsObjArr) {
			const isNhomAnPham1 = this.editedItem.AnPhamObj && this.editedItem.AnPhamObj.NhomAnPham === 1
			return (authorsObjArr || []).map(item => {
				let updatedItem = { ...item }
				if (isNhomAnPham1) {
					updatedItem.HeSoHoTroCaoHoc = 1
				}
				if (updatedItem.Is_TacGiaChinh === true) {
					updatedItem.Is_TacGiaPhu = false
				}
				return updatedItem
			})
		},
		buildProofsObjArrAPI() {
			return this.editedItem.ProofsObjArr.map(item => {
				if (item.FileList) {
					const joinStringFileID = item.FileList.map(item => item.FileIDMinhChung).join(',')
					return { ...item, FileIDList: joinStringFileID }
				}
				return item
			})
		},
		getErrorMessage(error) {
			return error?.responseJSON?.Message || "Thao tác thất bại"
		},
		async initData() {
			await Promise.all([
				this.loadAnPhamByMaNV(),
				this.loadDotDeXuat(),
				this.loadDanhMucTapChi(),
				this.loadDanhMucLoaiAnPham(),
				this.loadNam(),
				this.loadNganHang(),
			])
		},

		async loadAnPhamByMaNV() {
			const data = await ajaxCALLPromise('/AnPham_Get_ByNhanVienSubmit')
			this.dsBaiBao = data || []
		},
		async loadDotDeXuat() {
			const data = await ajaxCALLPromise('/AnPham_Dot_Get')
			this.dsDotDeXuat = data || []
		},
		async loadDanhMucTapChi() {
			const data = await ajaxCALLPromise('/LoaiDMTapChi_Get_All')
			this.dsDanhMucTapChi = data || []
		},
		async loadDanhMucLoaiAnPham() {
			const data = await ajaxCALLPromise('/AnPham_LoaiAnPham_Get_All')
			this.dsDanhMucLoaiAnPham = (data || []).map(item => {
				item.DSSubAnPham = JSON.parse(item.sub || '[]')
				return item
			})
		},
		async loadNam() {
			const data = await ajaxCALLPromise('/System_Get_Nam')
			this.dsNam = data || []
		},
		async loadNganHang() {
			vueData.v_Loading = true
			$.ajax({
				type: "GET",
				url: "https://api.vietqr.io/v2/banks",
				contentType: "application/json; charset=utf-8",
				dataType: "json",
				crossDomain: true,
				success: (res) => {
					if (res.code === "00") {
						this.dsNganHang = res.data
					} else {
						Vue.$toast.warning(res.desc)
					}
				},
				error: (error) => {
					console.log("Lỗi API ngân hàng: ", error)
				},
				complete: () => {
					vueData.v_Loading = false
				}
			})
		},
		async fetchAnPhamDetail(item) {
			const params = { AnPhamID: item.AnPhamID }
			return await ajaxCALLPromise('/AnPham_Get_ByAnPhamID', params)
		},
		async saveArticle(payload) {
			const url = payload.AnPhamID ? '/AnPham_Udp_Obj' : '/AnPham_INS_Obj'
			payload.params.AuthorsObjArr = this.buildAuthorsObjArrAPI(payload.params.AuthorsObjArr)
			const data = await ajaxCALLPromise(url, payload.params)
			await this.loadAnPhamByMaNV()
			return data
		},
		async updateArticleStatus(params) {
			params.AuthorsObjArr = this.buildAuthorsObjArrAPI(params.AuthorsObjArr)
			const data = await ajaxCALLPromise('/AnPham_Udp_Obj', params)
			await this.loadAnPhamByMaNV()
			return data
		},
		async deleteArticle(AnPhamID) {
			const params = { AnPhamID }
			const data = await ajaxCALLPromise('/AnPham_Del_ByAnPhamID', params)
			await this.loadAnPhamByMaNV()
			return data
		},
		openDialog() {
			this.isArticleModalOpen = true
			this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj)
			this.editedItem.AuthorsObjArr = Object.assign([], this.defaultItem.AuthorsObjArr)
			this.editedItem.ProofsObjArr = Object.assign([], this.defaultItem.ProofsObjArr)
		},
		editItem(item) {
			this.fetchAnPhamDetail(item).then((data) => {
				let anPhamObj = data[0][0]
				let authorObjArr = data[1]
				let proofsObjArr = data[2]
				anPhamObj.HeSo_IF = convertDiem(anPhamObj.HeSo_IF)
				anPhamObj.DiemHoiDong = convertDiem(anPhamObj.DiemHoiDong)
				this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj, anPhamObj)
				this.editedItem.AuthorsObjArr = authorObjArr
				if (proofsObjArr.length > 0) {
					this.editedItem.ProofsObjArr = proofsObjArr.map((item) => {
						if (item.FileList) {
							let jsonParse = JSON.parse(item.FileList)
							return { ...item, FileList: jsonParse }
						} else {
							return { ...item, FileList: [] }
						}
					})
				}
				this.editedIndex = this.dsBaiBao.indexOf(item)
				this.isArticleModalOpen = true
				this.getDM_By_LoaiAnPhamID_from_parent()
				this.getDM_By_LoaiSubAnPhamID_from_parent()
			}).catch((err) => console.log(err))
		},
		deleteItem(item) {
			this.deleteId = item.AnPhamID
			confirm({
				title: "Xác nhận",
				content: `Xác nhận xóa bài báo`,
				action: () => {
					this.delete_baiBao()
				}
			})
		},
		close() {
			const formAnPham = this.$refs.ArticleModal?.$refs.FormAnPham
			if (formAnPham) {
				const uploadedFileIDs = formAnPham.uploadedFileIDs || []
				if (uploadedFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: uploadedFileIDs.join(',') }, () => { })
				}
				formAnPham.resetFileStates()
			}
			this.$nextTick(() => {
				this.isArticleModalOpen = false
				this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj)
				this.editedItem.AuthorsObjArr = Object.assign([], this.defaultItem.AuthorsObjArr)
				this.editedItem.ProofsObjArr = Object.assign([], this.defaultItem.ProofsObjArr)
				this.editedIndex = -1
				this.trangThai = null
				this.resetArticleFormState()
			})
		},
		closeDelete() {
			this.isDeleteModalOpen = false
			this.$nextTick(() => {
				this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj)
				this.editedItem.AuthorsObjArr = Object.assign([], this.defaultItem.AuthorsObjArr)
				this.editedItem.ProofsObjArr = Object.assign([], this.defaultItem.ProofsObjArr)
				this.editedIndex = -1
				this.deleteId = null
			})
		},
		save() {
			if (this.validateArticleForm() === false) {
				return
			}
			let flag = false
			for (let i = 0; i < this.editedItem.AuthorsObjArr.length; i++) {
				if (this.editedItem.AuthorsObjArr[i].NguoiDaiDienQuyetToan === true) {
					flag = true
					break
				}
			}
			if (flag === false && this.editedItem.AnPhamObj.HinhThucThanhToan === 1 && this.editedItem.AnPhamObj.Is_DeNghiXetThuong !== false) {
				return Vue.$toast.warning("Chưa chọn người đại diện", { position: "top" })
			}
			if (this.editedItem.AnPhamObj.LoaiAnPhamID === null || this.editedItem.AnPhamObj.LoaiAnPhamID === "") {
				return Vue.$toast.warning("Vui lòng chọn danh mục bài báo/ ấn phẩm", { position: "top" })
			}
			if (this.editedItem.AuthorsObjArr.length === 0) {
				return Vue.$toast.warning("Vui lòng thêm ít nhất 1 tác giả", { position: "top" })
			}
			const isKhongXetThuong = this.editedItem.AnPhamObj.Is_DeNghiXetThuong === false || this.editedItem.AnPhamObj.Is_DeNghiXetThuong === 0
			if (this.editedIndex > -1) {
				confirm({
					title: isKhongXetThuong ? "Cập nhật bài báo vào LLKH" : "Cập nhật bài báo",
					content: isKhongXetThuong ? "Bạn có muốn cập nhật thông tin bài báo vào LLKH không?" : "Bạn có muốn cập nhật bài báo không?",
					action: () => {
						this.update_baiBao()
					}
				})
			} else {
				this.trangThai = isKhongXetThuong ? 3 : 2
				confirm({
					title: isKhongXetThuong ? "Lưu vào LLKH" : "Lưu và gửi đề xuất",
					content: isKhongXetThuong ? "Bạn có muốn lưu bài báo vào LLKH không?" : "Bạn có muốn Lưu và gửi đề xuất bài báo không?",
					action: () => {
						this.insert_baiBao()
					}
				})
			}
		},
		saveTemp() {
			if (this.validateArticleForm() === false) {
				return
			}
			if (this.editedItem.AnPhamObj.LoaiAnPhamID === null || this.editedItem.AnPhamObj.LoaiAnPhamID === "") {
				return Vue.$toast.warning("Vui lòng chọn danh mục bài báo/ ấn phẩm", { position: "top" })
			}
			if (this.editedItem.AuthorsObjArr.length === 0) {
				return Vue.$toast.warning("Vui lòng thêm ít nhất 1 tác giả", { position: "top" })
			}
			this.trangThai = 1
			confirm({
				title: "Lưu tạm bài báo",
				content: "Bạn có muốn lưu tạm bài báo không?",
				action: () => {
					this.insert_baiBao()
				}
			})
		},
		saveDeXuat_baiBao() {
			confirm({
				title: "Gửi đề xuất bài báo",
				content: 'Bạn có muốn gửi đề xuất bài báo không?',
				action: async () => {
					await this.AnPhamUpdate_TrangThai()
				}
			})
		},
		async AnPhamUpdate_TrangThai() {
			if (this.validateArticleForm() === false) {
				return
			}
			let flag = false
			for (let i = 0; i < this.editedItem.AuthorsObjArr.length; i++) {
				if (this.editedItem.AuthorsObjArr[i].NguoiDaiDienQuyetToan === true) {
					flag = true
					break
				}
			}
			if (flag === false && this.editedItem.AnPhamObj.HinhThucThanhToan === 1 && this.editedItem.AnPhamObj.Is_DeNghiXetThuong !== false) {
				return Vue.$toast.warning("Chưa chọn người đại diện", { position: "top" })
			}
			if (this.editedItem.AnPhamObj.LoaiAnPhamID === null || this.editedItem.AnPhamObj.LoaiAnPhamID === "") {
				return Vue.$toast.warning("Vui lòng chọn danh mục bài báo/ ấn phẩm", { position: "top" })
			}
			if (this.editedItem.AuthorsObjArr.length === 0) {
				return Vue.$toast.warning("Vui lòng thêm ít nhất 1 tác giả", { position: "top" })
			}
			const isKhongXetThuong = this.editedItem.AnPhamObj.Is_DeNghiXetThuong === false || this.editedItem.AnPhamObj.Is_DeNghiXetThuong === 0
			const params = {
				AnPhamObj: this.editedItem.AnPhamObj,
				AuthorsObjArr: this.editedItem.AuthorsObjArr,
				ProofSObjArr: this.buildProofsObjArrAPI(),
				TrangThai: isKhongXetThuong ? 3 : 2
			}
			await this.updateArticleStatus(params)
			const formAnPham = this.$refs.ArticleModal?.$refs.FormAnPham
			if (formAnPham) {
				const pendingDeleteFileIDs = formAnPham.pendingDeleteFileIDs || []
				if (pendingDeleteFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: pendingDeleteFileIDs.join(',') }, () => { })
				}
				formAnPham.uploadedFileIDs = []
				formAnPham.resetFileStates()
			}
			Vue.$toast.success(isKhongXetThuong ? "Lưu vào LLKH thành công" : "Cập nhật và gửi đề xuất thành công", { position: "top" })
			this.close()
		},
		async update_baiBao() {
			this.isLoadingSave = true
			const isKhongXetThuong = this.editedItem.AnPhamObj.Is_DeNghiXetThuong === false || this.editedItem.AnPhamObj.Is_DeNghiXetThuong === 0
			let targetTrangThai = 1
			if (isKhongXetThuong) {
				targetTrangThai = 3
			} else {
				targetTrangThai = this.editedItem.AnPhamObj.TrangThaiID === 3 ? 2 : (this.editedItem.AnPhamObj.TrangThaiID || 1)
			}
			const params = {
				AnPhamObj: this.editedItem.AnPhamObj,
				AuthorsObjArr: this.editedItem.AuthorsObjArr,
				ProofSObjArr: this.buildProofsObjArrAPI(),
				TrangThai: targetTrangThai
			}
			try {
				await this.saveArticle({ AnPhamID: this.editedItem.AnPhamObj.AnPhamID, params })
				const formAnPham = this.$refs.ArticleModal?.$refs.FormAnPham
				if (formAnPham) {
					const pendingDeleteFileIDs = formAnPham.pendingDeleteFileIDs || []
					if (pendingDeleteFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: pendingDeleteFileIDs.join(',') }, () => { })
					}
					formAnPham.uploadedFileIDs = []
					formAnPham.resetFileStates()
				}
				Vue.$toast.success(isKhongXetThuong ? "Lưu vào LLKH thành công" : "Chỉnh sửa thành công", { position: "top" })
				this.close()
			} finally {
				this.isLoadingSave = false
			}
		},
		async insert_baiBao() {
			this.isLoadingSave = true
			const isKhongXetThuong = this.editedItem.AnPhamObj.Is_DeNghiXetThuong === false || this.editedItem.AnPhamObj.Is_DeNghiXetThuong === 0
			const params = {
				AnPhamObj: this.editedItem.AnPhamObj,
				AuthorsObjArr: this.editedItem.AuthorsObjArr,
				ProofSObjArr: this.buildProofsObjArrAPI(),
				TrangThai: isKhongXetThuong ? 3 : this.trangThai
			}
			try {
				const res = await this.saveArticle({ params })
				const formAnPham = this.$refs.ArticleModal?.$refs.FormAnPham
				if (formAnPham) {
					const pendingDeleteFileIDs = formAnPham.pendingDeleteFileIDs || []
					if (pendingDeleteFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: pendingDeleteFileIDs.join(',') }, () => { })
					}
					formAnPham.uploadedFileIDs = []
					formAnPham.resetFileStates()
				}
				Vue.$toast.success(isKhongXetThuong ? "Lưu vào LLKH thành công" : "Thêm mới bài báo thành công", { position: "top" })
				this.close()
				return res
			} finally {
				this.isLoadingSave = false
			}
		},
		async delete_baiBao() {
			await this.deleteArticle(this.deleteId)
			this.closeDelete()
		},
		getDM_By_LoaiAnPhamID_from_parent() {
			this.$nextTick(async () => {
				await this.$refs.ArticleModal?.getDM_By_LoaiAnPhamID_Edit()
			})
		},
		getDM_By_LoaiSubAnPhamID_from_parent() {
			if (this.editedItem.AnPhamObj.LoaiSubAnPhamID) {
				this.$nextTick(async () => {
					await this.$refs.ArticleModal?.getTenDMTC_By_LoaiAnPhamID_Edit()
				})
			}
		},
		resetFileIDMinhChungHoTroCaoHoc() {
			if (this.editedItem.AnPhamObj.NhomAnPham === 3) {
				this.editedItem.AnPhamObj.LoaiAnPhamID = 3
				this.editedItem.AnPhamObj.LoaiSubAnPhamID = 3
				this.editedItem.AnPhamObj.DanhMucLoaiTapChiID = null
				this.editedItem.AnPhamObj.TenLoaiDanhMucTapChi = null
				this.editedItem.AnPhamObj.TenTapChi = "Tạp chí Khoa học Lạc Hồng"
				this.editedItem.AnPhamObj.HinhThucThanhToan = 1
				this.getDM_By_LoaiAnPhamID_from_parent()
			}
			if (this.editedItem.AnPhamObj.NhomAnPham === 2) {
				this.editedItem.AnPhamObj.HinhThucThanhToan = 1
			}
			this.editedItem.AnPhamObj.FileIDMinhChungHoTroCaoHoc = null
			this.editedItem.AnPhamObj.FileNameMinhChungHoTroCaoHoc = null
			this.editedItem.AnPhamObj.FileUrlMinhChungHoTroCaoHoc = null
			this.editedItem.AnPhamObj.FileIDMinhChungLacHong = null
			this.editedItem.AnPhamObj.FileNameMinhChungLacHong = null
			this.editedItem.AnPhamObj.FileUrlMinhChungLacHong = null
		}
	}
	}
</script>