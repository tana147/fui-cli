<template>
	<div>
		<v-dialog v-model="dialog" max-width="1400px" scrollable>
			<v-card>
				<v-card-title class="d-flex align-center px-3 pt-2 pb-3">
					<span class="subtitle-1 font-weight-bold primary--text me-3">{{ formTitle }}</span>
					<v-select v-model="editedItem.AnPhamObj.NhomAnPham" :items="LoaiBaiBao" item-text="TenLoai"
						item-value="LoaiID" label="Nhóm ấn phẩm" outlined dense hide-details style="max-width: 260px"
						@change="resetFileIDMinhChungHoTroCaoHoc">
					</v-select>
					<v-spacer></v-spacer>
					<v-btn small icon @click="close">
						<v-icon small>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="px-3 py-2" style="max-height: 70vh;">
					<uc-form-an-pham ref="FormAnPham" class="mb-3" v-model="editedItem"
						:danh-muc-tap-chi-arr="dsdanhmuctapchi" :danh-muc-loai-an-pham-arr="dsdanhmucloaianpham"
						:nam-arr="dsnam" :ds-he-so-chat-luong="dshesochatluong" :edited-index="editedIndex">
					</uc-form-an-pham>
					<uc-table-tac-gia v-if="dialog" v-model="editedItem" ref="tacgia"
						:anphamid="editedItem.AnPhamObj.AnPhamID" :dsnganhang="dsnganhang"
						:flagUpdateHSCL="flagUpdateHSCL" :anphamobj="editedItem.AnPhamObj"
						@onhandleflaghscl="onHandleFlagHSCL" :dskhenthuong="dscongthuckhenthuong">
					</uc-table-tac-gia>
				</v-card-text>
				<v-card-actions class="pa-3">
					<v-spacer></v-spacer>
					<v-btn small @click="close">Đóng</v-btn>
					<v-btn v-if="editedItem.AnPhamObj.DaGuiDashboard == 1" small @click="ThuHoiBaiBao" color="pink"
						style="color: white">Thu hồi</v-btn>
					<v-btn small class="ml-2" @click="reject" color="error" elevation="0" :loading="isLoadingSave">
						Từ chối</v-btn>
					<v-btn small class="ml-2" @click="onHandleUpdateInfo" color="primary" elevation="0"
						:loading="isLoadingSave">
						Cập nhật dữ liệu</v-btn>
					<v-select v-model="selectedDotDuyetID" :items="dotDuyetOptions" item-text="TenDotDuyet"
						item-value="AnPham_DotDuyetID" label="Đợt duyệt" no-data-text="Chưa có đợt duyệt nào đang mở"
						outlined dense hide-details style="max-width: 200px" class="ml-2" />
					<v-btn icon small class="ml-1" title="Thêm đợt duyệt mới" @click="$emit('on-manage-dotduyet')">
						<v-icon small>mdi-plus-circle-outline</v-icon>
					</v-btn>
					<v-btn small class="ml-2" @click="save" color="success" elevation="0" :loading="isLoadingSave"
						:disabled="!selectedDotDuyetID">
						Duyệt</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<v-dialog v-model="dialogReject" max-width="500px">
			<v-card>
				<v-card-title>
					<span class="text-h5 primary--text">Xác nhận từ chối bài báo?</span>
					<v-spacer></v-spacer>
					<v-btn fab small icon @click="closeReject">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-card-title>
				<v-card-text class="mt-3">
					<v-form ref="reject">
						<v-row>
							<v-col cols="12">
								<v-textarea :rules="validReject" v-model="RejectNotice" label="Lý do" outlined
									hide-details dense></v-textarea>
							</v-col>
						</v-row>
					</v-form>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn color="blue darken-1" text @click="closeReject">Đóng</v-btn>
					<v-btn color="blue darken-1" text @click="confirmReject">Xác nhận</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		name: 'uc-modal-edit',
	props: {
		value: { type: Boolean, default: false },
		editRow: { type: Object, default: () => ({}) },
		dsdanhmuctapchi: { type: Array, default: () => [] },
		dsdanhmucloaianpham: { type: Array, default: () => [] },
		dsnam: { type: Array, default: () => [] },
		dshesochatluong: { type: Array, default: () => [] },
		dsnganhang: { type: Array, default: () => [] },
		dscongthuckhenthuong: { type: Array, default: () => [] },
		dsdotduyet: { type: Array, default: () => [] },
	},
	emits: ['input', 'on-reload', 'on-manage-dotduyet'],
	data() {
		return {
			isLoadingSave: false,
			dialogReject: false,
			flagUpdateHSCL: false,
			editedIndex: -1,
			selectedDotDuyetID: null,
			RejectNotice: '',
			validReject: [
				(v) => (v && v.length > 0) || 'Vui lòng nhập lý do từ chối',
			],
			LoaiBaiBao: [
				{ TenLoai: 'Ấn phẩm khoa học', LoaiID: 1 },
				{ TenLoai: 'Hỗ trợ Đầu vào Cao học', LoaiID: 2 },
				{ TenLoai: 'Có tham gia đào tạo nghiên cứu sính', LoaiID: 3 },
			],
			editedItem: {
				AnPhamObj: {
					TenAnPham: '',
					LoaiAnPhamID: null,
					TenLoaiAnPham: null,
					TenTapChi: '',
					DanhMucLoaiTapChiID: '',
					TenLoaiDanhMucTapChi: '',
					LoaiSubAnPhamID: null,
					TenLoaiSubAnPham: '',
					NoiDangBai: '',
					NamDangBai: new Date().getFullYear(),
					DuongDanBaiBao: '',
					HeSo_IF: convertDiem(0),
					TrangThai: '',
					MaNhanVienDaiDien: '',
					TenNhanVienDaiDien: '',
					DonViDaiDien: '',
					SoTacGia_LHU: 0,
					DiemHoiDong: convertDiem(0),
					TenHeSoChatLuong: null,
					HeSoChatLuongID: null,
					PhiThongBao: null,
					PhiDangBai: null,
					HoanPhiDangBai: 0,
					ISSN: null,
					Dieu: null,
					Khoan: null,
					Muc: null,
					TongSoTienThuong: null,
					GhiChu: '',
					SoQuyetDinhKhenThuong: null,
					FileIDKhenThuong: null,
					HoanPhiDangBaiTamTinh: 0,
					CongThucKhenThuongID: null,
					HinhThucThanhToan: 2,
					NguonCapKinhPhi: null,
					NhomAnPham: 1,
					FileIDMinhChungHoTroCaoHoc: null,
					FileIDMinhChungLacHong: null,
					FileNameMinhChungLacHong: null,
					FileUrlMinhChungLacHong: null,
					FileIDMinhChungKhac: null,
					FileNameMinhChungKhac: null,
					FileUrlMinhChungKhac: null,
				},
				AuthorsObjArr: [],
				ProofsObjArr: [
					{ LoaiFile: 2, FileIDList: '', FileList: [], MoTa: '' },
				],
			},
			defaultItem: {
				AnPhamObj: {
					TenAnPham: '',
					LoaiAnPhamID: null,
					TenLoaiAnPham: null,
					TenTapChi: '',
					DanhMucLoaiTapChiID: '',
					TenLoaiDanhMucTapChi: '',
					LoaiSubAnPhamID: null,
					TenLoaiSubAnPham: '',
					NoiDangBai: '',
					NamDangBai: '',
					DuongDanBaiBao: '',
					HeSo_IF: 0.0,
					TrangThai: '',
					MaNhanVienDaiDien: '',
					TenNhanVienDaiDien: '',
					DonViDaiDien: '',
					SoTacGia_LHU: 0,
					DiemHoiDong: 0,
					TenHeSoChatLuong: null,
					HeSoChatLuongID: null,
					PhiThongBao: null,
					PhiDangBai: null,
					HoanPhiDangBai: 0,
					ISSN: null,
					Dieu: null,
					Khoan: null,
					Muc: null,
					TongSoTienThuong: null,
					GhiChu: '',
					SoQuyetDinhKhenThuong: null,
					FileIDKhenThuong: null,
					HoanPhiDangBaiTamTinh: 0,
					CongThucKhenThuongID: null,
					HinhThucThanhToan: 2,
					NguonCapKinhPhi: null,
					NhomAnPham: 1,
					FileIDMinhChungHoTroCaoHoc: null,
					FileIDMinhChungLacHong: null,
					FileNameMinhChungLacHong: null,
					FileUrlMinhChungLacHong: null,
					FileIDMinhChungKhac: null,
					FileNameMinhChungKhac: null,
					FileUrlMinhChungKhac: null,
				},
				AuthorsObjArr: [],
				ProofsObjArr: [
					{ LoaiFile: 2, FileIDList: '', FileList: [], MoTa: '' },
				],
			},
		}
	},
	computed: {
		dialog: {
			get() { return this.value },
			set(val) { this.$emit('input', val) },
		},
		formTitle() {
			return this.editedIndex === -1 ? 'Thêm mới' : 'Chi tiết bài báo chờ duyệt'
		},
		DanhMucLoaiAnPhamArr() {
			return [
				{ LoaiAnPhamID: -1, TenLoaiAnPham: 'Tất cả' },
				...this.dsdanhmucloaianpham.map(item => ({ ...item })),
			]
		},
		dotDuyetOptions() {
			const open = this.dsdotduyet.filter(item => item.TinhTrang === 1)
			if (this.selectedDotDuyetID && !open.some(item => item.AnPham_DotDuyetID === this.selectedDotDuyetID)) {
				const current = this.dsdotduyet.find(item => item.AnPham_DotDuyetID === this.selectedDotDuyetID)
				if (current) return [current, ...open]
			}
			return open
		},
	},
	watch: {
		async dialog(val) {
			if (val) {
				if (this.editRow && this.editRow.AnPhamID) {
					await this.loadEditItem(this.editRow)
				}
			} else {
				this.close()
			}
		},
		async 'editedItem.AnPhamObj.AnPhamID'(val) {
			if (val) {
				const data = await ajaxCALLPromise('/PhiDangBai_Cal', { AnPhamID: val })
				this.editedItem.AnPhamObj.HoanPhiDangBaiTamTinh = data[0].HoTroPhiDangBai
				if (
					this.editedItem.AnPhamObj.HoanPhiDangBai === 0 ||
					this.editedItem.AnPhamObj.HoanPhiDangBai === null
				) {
					this.editedItem.AnPhamObj.HoanPhiDangBai = this.editedItem.AnPhamObj.HoanPhiDangBaiTamTinh
				}
			}
		},
	},
	methods: {
		async loadEditItem(item) {
			this.editedIndex = 1
			const data = await ajaxCALLPromise('/AnPham_Get_ByAnPhamID', { AnPhamID: item.AnPhamID })
			let anphamobj = data[0][0]
			let authorobjarr = data[1]
			let proofsobjarr = data[2]
			anphamobj.HeSo_IF = convertDiem(anphamobj.HeSo_IF)
			anphamobj.DiemHoiDong = convertDiem(anphamobj.DiemHoiDong)
			anphamobj.HoanPhiDangBaiTamTinh = 0
			anphamobj.HoanPhiDangBai = anphamobj.HoanPhiDangBai ?? 0
			this.editedItem.AnPhamObj = anphamobj
			this.selectedDotDuyetID = anphamobj.DotDuyet || null
			this.editedItem.AuthorsObjArr = authorobjarr.map(i => ({
				...i,
				SoTienKhenThuongTamTinh: 0,
				checkboxHSCL: i.HeSoHoTroCaoHoc === 1.2,
			}))
			if (proofsobjarr.length > 0) {
				this.editedItem.ProofsObjArr = proofsobjarr.map(i => {
					if (i.FileList) {
						return { ...i, FileList: JSON.parse(i.FileList) }
					}
					return { ...i, FileList: [] }
				})
			}
			const khenThuongData = await this.PhiKhenThuong_Cal()
			if (khenThuongData && khenThuongData.length > 0) {
				this.editedItem.AuthorsObjArr = this.editedItem.AuthorsObjArr.map((i, index) => {
					if (i.SoTienKhenThuong === 0 || i.SoTienKhenThuong === null) {
						i.SoTienKhenThuong = khenThuongData[index].KhenThuong
					}
					return {
						...i,
						SoTienKhenThuongTamTinh: khenThuongData[index].KhenThuong,
						CongThucKhenThuongID: this.editedItem.AnPhamObj.CongThucKhenThuongID,
						NoiDungCongThucKhenThuong: '',
					}
				})
			}
		},
		resetFileIDMinhChungHoTroCaoHoc() {
			if (this.editedItem.AnPhamObj.NhomAnPham === 3) {
				this.editedItem.AnPhamObj.LoaiAnPhamID = 3
				this.editedItem.AnPhamObj.LoaiSubAnPhamID = 9
				this.editedItem.AnPhamObj.DanhMucLoaiTapChiID = 34
				this.editedItem.AnPhamObj.TenTapChi = 'Tạp chí Khoa học Lạc Hồng'
				this.editedItem.AnPhamObj.HinhThucThanhToan = 1
			}
			this.editedItem.AnPhamObj.FileIDMinhChungHoTroCaoHoc = null
			this.editedItem.AnPhamObj.FileNameMinhChungHoTroCaoHoc = null
			this.editedItem.AnPhamObj.FileUrlMinhChungHoTroCaoHoc = null
			this.editedItem.AnPhamObj.FileIDMinhChungLacHong = null
			this.editedItem.AnPhamObj.FileNameMinhChungLacHong = null
			this.editedItem.AnPhamObj.FileUrlMinhChungLacHong = null
		},
		save() {
			if (this.$refs.FormAnPham.$refs.ValidForm.validate() === false) {
				return
			}
			if (!this.selectedDotDuyetID) {
				Vue.$toast.error('Vui lòng chọn đợt duyệt trước khi duyệt', { position: 'top' })
				return
			}
			this.update_baiBao()
		},
		async update_baiBao() {
			let proofsObjArrAPI = this.editedItem.ProofsObjArr.map(item => {
				if (item.FileList) {
					const joinStringFileID = item.FileList.map(i => i.FileIDMinhChung).join(',')
					return { ...item, FileIDList: joinStringFileID }
				}
				return item
			})
			if (
				this.editedItem.AnPhamObj.HoanPhiDangBai === 0 ||
				this.editedItem.AnPhamObj.HoanPhiDangBai === null
			) {
				this.editedItem.AnPhamObj.HoanPhiDangBai = this.editedItem.AnPhamObj.HoanPhiDangBaiTamTinh
			}
			for (let i = 0; i < this.editedItem.AuthorsObjArr.length; i++) {
				if (
					this.editedItem.AuthorsObjArr[i].SoTienKhenThuong === null ||
					this.editedItem.AuthorsObjArr[i].SoTienKhenThuong === 0 ||
					[0.5, 1.2, 1.5].includes(this.editedItem.AuthorsObjArr[i].HeSoHoTroCaoHoc)
				) {
					this.editedItem.AuthorsObjArr[i].SoTienKhenThuong = this.editedItem.AuthorsObjArr[i].SoTienKhenThuongTamTinh
				}
			}
			let index = this.editedItem.AuthorsObjArr.findIndex(item => [0.5, 1.2, 1.5].includes(item.HeSoHoTroCaoHoc))
			if (index !== -1) {
				this.editedItem.AuthorsObjArr = this.editedItem.AuthorsObjArr.map(item => ({
					...item,
					SoTienKhenThuong: item.SoTienKhenThuongTamTinh,
				}))
			}
			this.isLoadingSave = true
			try {
				await ajaxCALLPromise('/AnPham_Udp_Obj', {
					AnPhamObj: this.editedItem.AnPhamObj,
					AuthorsObjArr: this.editedItem.AuthorsObjArr,
					ProofSObjArr: proofsObjArrAPI,
					TrangThai: 3,
					DotDuyetID: this.selectedDotDuyetID,
				})
				const formAnPham = this.$refs.FormAnPham
				if (formAnPham) {
					const pendingDeleteFileIDs = formAnPham.pendingDeleteFileIDs || []
					if (pendingDeleteFileIDs.length > 0) {
						ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: pendingDeleteFileIDs.join(',') }, () => { })
					}
					formAnPham.uploadedFileIDs = []
					formAnPham.resetFileStates()
				}
				Vue.$toast.success('Cập nhật chi phí thành công', { position: 'top' })
				this.$emit('on-reload')
				this.close()
			} finally {
				this.isLoadingSave = false
			}
		},
		async UpdateInfomation() {
			let proofsObjArrAPI = this.editedItem.ProofsObjArr.map(item => {
				if (item.FileList) {
					const joinStringFileID = item.FileList.map(i => i.FileIDMinhChung).join(',')
					return { ...item, FileIDList: joinStringFileID }
				}
				return item
			})
			if (
				this.editedItem.AnPhamObj.HoanPhiDangBai === 0 ||
				this.editedItem.AnPhamObj.HoanPhiDangBai === null
			) {
				this.editedItem.AnPhamObj.HoanPhiDangBai = this.editedItem.AnPhamObj.HoanPhiDangBaiTamTinh
			}
			for (let i = 0; i < this.editedItem.AuthorsObjArr.length; i++) {
				if (
					this.editedItem.AuthorsObjArr[i].SoTienKhenThuong === null ||
					this.editedItem.AuthorsObjArr[i].SoTienKhenThuong === 0 ||
					[0.5, 1.2, 1.5].includes(this.editedItem.AuthorsObjArr[i].HeSoHoTroCaoHoc)
				) {
					this.editedItem.AuthorsObjArr[i].SoTienKhenThuong = this.editedItem.AuthorsObjArr[i].SoTienKhenThuongTamTinh
				}
			}
			let index = this.editedItem.AuthorsObjArr.findIndex(item => [0.5, 1.2, 1.5].includes(item.HeSoHoTroCaoHoc))
			if (index !== -1) {
				this.editedItem.AuthorsObjArr = this.editedItem.AuthorsObjArr.map(item => ({
					...item,
					SoTienKhenThuong: item.SoTienKhenThuongTamTinh,
				}))
			}
			await ajaxCALLPromise('/AnPham_Udp_Obj', {
				AnPhamObj: this.editedItem.AnPhamObj,
				AuthorsObjArr: this.editedItem.AuthorsObjArr,
				ProofSObjArr: proofsObjArrAPI,
				TrangThai: 2,
				DotDuyetID: this.selectedDotDuyetID,
			})
			const formAnPham = this.$refs.FormAnPham
			if (formAnPham) {
				const pendingDeleteFileIDs = formAnPham.pendingDeleteFileIDs || []
				if (pendingDeleteFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: pendingDeleteFileIDs.join(',') }, () => { })
				}
				formAnPham.uploadedFileIDs = []
				formAnPham.resetFileStates()
			}
		},
		async onHandleUpdateInfo() {
			this.isLoadingSave = true
			try {
				if (this.flagUpdateHSCL) {
					await this.UpdateInfomation()
					const data = await this.PhiKhenThuong_Cal()
					if (data && data.length > 0) {
						this.editedItem.AuthorsObjArr = this.editedItem.AuthorsObjArr.map((item, index) => {
							if (item.SoTienKhenThuong === 0 || item.SoTienKhenThuong === null) {
								item.SoTienKhenThuong = data[index].KhenThuong
							}
							return {
								...item,
								SoTienKhenThuongTamTinh: data[index].KhenThuong,
								CongThucKhenThuongID: this.editedItem.AnPhamObj.CongThucKhenThuongID,
								NoiDungCongThucKhenThuong: '',
							}
						})
					}
					await this.UpdateInfomation()
				} else {
					await this.UpdateInfomation()
				}
				Vue.$toast.success('Cập nhật dữ liệu thành công', { position: 'top' })
				this.$emit('on-reload')
				this.close()
			} finally {
				this.isLoadingSave = false
			}
		},
		async PhiKhenThuong_Cal() {
			if (
				!this.editedItem.AnPhamObj.CongThucKhenThuongID ||
				!(this.editedItem.AnPhamObj.CongThucKhenThuongID > 0)
			) {
				return null
			}
			return await ajaxCALLPromise('/PhiKhenThuong_Cal', {
				AnPhamID: this.editedItem.AnPhamObj.AnPhamID,
				CongThucKhenThuongID: this.editedItem.AnPhamObj.CongThucKhenThuongID,
				DiemHoiDong: this.editedItem.AnPhamObj.DiemHoiDong ?? 0,
				HeSo_IF: this.editedItem.AnPhamObj.HeSo_IF,
				HeSoChatLuongID: this.editedItem.AnPhamObj.HeSoChatLuongID ?? 0,
			})
		},
		reject() {
			this.dialogReject = true
		},
		closeReject() {
			this.dialogReject = false
			this.RejectNotice = ''
		},
		confirmReject() {
			if (!this.$refs.reject.validate()) {
				return Vue.$toast.error('Vui lòng nhập lý do từ chối', { position: 'top' })
			}
			this.Update_TrangThai(this.editedItem.AnPhamObj.AnPhamID)
			this.closeReject()
		},
		async Update_TrangThai(AnPhamID) {
			await ajaxCALLPromise('/AnPham_Udp_TrangThai', {
				AnPhamID: AnPhamID,
				TrangThai: 5,
				LyDoReject: this.RejectNotice,
			})
			Vue.$toast.success('Từ chối thành công', { position: 'top' })
			this.close()
			this.$emit('on-reload')
		},

		ThuHoiBaiBao() {
			confirm({
				title: 'Xác nhận thu hồi',
				content: 'Xác nhận thu hồi bài báo từ dashboard',
				action: async () => {
					await ajaxCALLPromise('/AnPham_ThuHoi_RPT', { AnPhamID: this.editedItem.AnPhamObj.AnPhamID })
					this.close()
					this.$emit('on-reload')
					Vue.$toast.success('Đã thu hồi bài báo từ Dashboard', { position: 'top' })
				},
			})
		},
		onHandleFlagHSCL() {
			this.flagUpdateHSCL = true
		},
		close() {
			const formAnPham = this.$refs.FormAnPham
			if (formAnPham) {
				const uploadedFileIDs = formAnPham.uploadedFileIDs || []
				if (uploadedFileIDs.length > 0) {
					ajaxCALL('/FILE_FileDeleteMulti', { FileIDs: uploadedFileIDs.join(',') }, () => { })
				}
				formAnPham.resetFileStates()
			}
			this.dialog = false
			this.$nextTick(() => {
				this.editedItem = Object.assign({}, this.defaultItem)
				this.editedIndex = -1
				this.selectedDotDuyetID = null
				this.flagUpdateHSCL = false
				if (this.$refs.FormAnPham) {
					this.$refs.FormAnPham.danhMucSubAnPhamArr = []
				}
			})
		},
	},
	}
</script>