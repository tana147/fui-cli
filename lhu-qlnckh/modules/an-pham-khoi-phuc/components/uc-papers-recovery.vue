<template>
	<v-card>
		<v-card-title>
			<span class="primary--text font-weight-medium me-5">Danh sách bài báo đề nghị {{ ' ' }}
				khen thưởng phục hồi</span>
			<v-btn color="primary" class="mt-3 mb-3 mr-3" @click="sendBaiBao">Gửi dữ liệu sang dashboard </v-btn>
			<v-select label="Năm học" v-model="NamHoc" :items="['2022-2023','2023-2024','2025-2026']" dense outlined hide-details style="max-width:200px"></v-select>
			
			<v-spacer></v-spacer>
			<v-btn class="mr-6" icon color="primary" @click="toExcel">
				<v-icon>mdi-microsoft-excel</v-icon>
			</v-btn>
			<v-text-field class="me-5" v-model="search" prepend-icon="mdi-filter-outline" label="Tìm kiếm" single-line
				style="max-width:400px"></v-text-field>
			<v-btn color="success" fab x-small outlined class="mb-2" @click="openDialog">
				<v-icon>mdi-plus</v-icon>
			</v-btn>
		</v-card-title>
		<v-card-text>
			<v-data-table v-model="isSelected" :headers="headersArticlesObj" :items="DSBaiBao" :search="search"
				:footer-props="{ 'items-per-page-options': [100, 150, -1] }" show-select item-key="AnPhamID"
				selectable-key="isSelectable">
				<template v-slot:top>
					<v-dialog v-model="dialog" max-width="1500px">
						<v-card>
							<v-card-title class="mt-2">
								<span class="text-h5 primary--text me-5">{{ formTitle }}</span>
								<v-select v-model="editedItem.AnPhamObj.NhomAnPham" :items="LoaiBaiBao"
									item-text="TenLoai" item-value="LoaiID" label="Nhóm ấn phẩm" outlined dense
									hide-details style="max-width:300px" @change="resetFileIDMinhChungHoTroCaoHoc">
								</v-select>
								<v-spacer></v-spacer>
								<v-btn fab small icon @click="close">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text>
								<uc-an-pham ref="FormAnPham" class="mb-5" v-model="editedItem"
									:danhmuctapchiarr="DanhMucTapChiArr" :danhmucloaianphamarr="DanhMucLoaiAnPhamArr"
									:namarr="NamArr" :dshesochatluong="DSHeSoChatLuong" :editedindex="editedIndex">
								</uc-an-pham>
								<uc-table-tac-gia ref="checkTG" v-model="editedItem.AuthorsObjArr"
									:anphamid="editedItem.AnPhamObj.AnPhamID"
									:tongtacgialhu="editedItem.AnPhamObj.SoTacGia_LHU"
									:loaianphamid="editedItem.AnPhamObj.LoaiAnPhamID"
									:tongtacgia="editedItem.AnPhamObj.TongSoTacGia" :dsnganhang="DSNganHang"
									:anphamobj="editedItem.AnPhamObj"></uc-table-tac-gia>
							</v-card-text>

							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="dialog = false">Đóng</v-btn>
								<v-btn v-if="editedItem.AnPhamObj.DaGuiDashboard == 1" @click="ThuHoiBaiBao"
									color="pink" style="color: white">Thu hồi</v-btn>
								<v-btn class="ml-2" v-if="editedIndex === -1" @click="saveTemp" color="primary" outlined>
									Lưu</v-btn>
									<v-btn v-else class="ml-2" @click="saveTemp" color="primary" outlined>
									Cập nhật</v-btn>

							</v-card-actions>
						</v-card>
					</v-dialog>
				</template>
				<template v-slot:item.nhomanpham="{ item }">
					<v-chip outlined color="primary" v-if="item.NhomAnPham===1">Ấn phẩm khoa học</v-chip>
					<v-chip v-if="item.NhomAnPham===2" outlined color="success">Hỗ trợ Đầu vào Cao học</v-chip>
					<v-chip v-if="item.NhomAnPham===3" outlined color="orange">Có hướng dẫn Cao học</v-chip>
				</template>
				<template v-slot:item.TrangThai="{ item }">
					<v-chip :color="getColorStatusAnPham(item.TrangThaiID)">
						{{ item.TrangThai }}
					</v-chip>
				</template>
				<template v-slot:item.actions="{ item }">
					<div class="d-flex flex-row justify-center align-center">
						<v-icon style="font-size:18px" color="red darken-3" small class="mr-2"
							@click="deleteItem(item)">
							mdi-trash-can-outline
						</v-icon>
						<v-icon style="font-size:18px" color="green darken-2" small class="mr-2"
							@click="editItem(item)">
							mdi-square-edit-outline
						</v-icon>
					</div>
				</template>
			</v-data-table>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: ["dsbaibao", "dsdanhmuctapchi", "dsdanhmucloaianpham", "dsnam", "dscongthuckhenthuong", "dshesochatluong"],
		data: () => ({
			dialog: false,
			search: "",
			dialogDelete: false,
			isLoadingSave: false,
			NamHoc:"",
			headersArticlesObj: [
				{ text: 'STT', sortable: false, value: "STT", align: "center", width: '20' },
				{ text: 'Tên bài báo', sortable: false, value: "TenAnPham" },
				{ text: 'Tác giả', sortable: false, value: "TacGia", width: '200' },
				{ text: 'Đơn vị', value: "DonViDaiDien", width: '100' },
				{ text: 'Danh mục bài báo/ấn phẩm', sortable: false, value: 'TenLoaiAnPham', width: '150' },
				{ text: 'Tên tạp chí', sortable: false, value: 'TenTapChi', width: '200' },
				{ text: 'Tên danh mục tạp chí', sortable: false, value: "TenLoaiDanhMucTapChi",width: '200' },
				{ text: 'Nơi đăng', sortable: false, value: "NoiDangBai", width: '120' },
				{ text: 'Năm đăng', sortable: true, value: "NamDangBai", width: '120', align: "center" },
				{ text: 'Nhóm ấn phẩm', value: "nhomanpham", sortable: false },
				{ text: 'Trạng thái', sortable: true, value: "TrangThai", width: '100', align: "center" },
				{ text: 'Thao tác', value: "actions", sortable: false, align: "center" },
			],
			editedIndex: -1,
			editedItem: {
				AnPhamObj: {
					TenAnPham: '',
					LoaiAnPhamID: null,
					TenLoaiAnPham: "",
					TenTapChi: '',
					DanhMucLoaiTapChiID: null,
					TenLoaiDanhMucTapChi: "",
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
					FileIDMinhChungHoTroCaoHoc: null
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
					TenLoaiDanhMucTapChi: "",
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
					FileIDMinhChungHoTroCaoHoc: null
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
			ID: null,
			DSNganHang: null,
			TrangThai: null,
			DMTC_Arr: [],
			TenDMTC_Arr: [],
			LoaiBaiBao: [
				{ TenLoai: "Ấn phẩm khoa học", LoaiID: 1 },
				{ TenLoai: "Hỗ trợ Đầu vào Cao học", LoaiID: 2 },
				{ TenLoai: "Có hướng dẫn Cao học", LoaiID: 3 }
			],
			isSelected: [],
	
		}),
	
		computed: {
			
			formTitle() {
				return this.editedIndex === -1 ? 'Thêm mới bài báo' : 'Chi tiết bài báo'
			},
			DSBaiBao() {
				return this.dsbaibao
			},
			DanhMucTapChiArr() {
	
				return this.dsdanhmuctapchi
			},
			DanhMucLoaiAnPhamArr() {
				return this.dsdanhmucloaianpham
			},
			NamArr() {
				return this.dsnam
			},
			DSHeSoChatLuong() {
				return this.dshesochatluong
			},
		},
		watch: {
			dialog(val) {
				val || this.close()
			},
			dialogDelete(val) {
				val || this.closeDelete()
			},
	
		},
		created() {
			this.DSNganHang_Get()
		},
		methods: {
			openDialog() {
				this.dialog = true
				this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj)
				this.editedItem.AuthorsObjArr = Object.assign([], this.defaultItem.AuthorsObjArr)
				this.editedItem.ProofsObjArr = Object.assign([], this.defaultItem.ProofsObjArr)
			},
			//Hàm xử lý chọn sửa bài báo
			editItem(item) {
				this.editedIndex = this.DSBaiBao.indexOf(item)
				this.ID = item.AnPhamID
				ajaxCALL("/AnPham_Get_ByAnPhamID", {
					"AnPhamID": item.AnPhamID
				}, (res) => {
					let anphamobj = res.data[0][0]
					let authorobjarr = res.data[1]
					let proofsobjarr = res.data[2]
					anphamobj.HeSo_IF = convertDiem(anphamobj.HeSo_IF)
					anphamobj.DiemHoiDong = convertDiem(anphamobj.DiemHoiDong)
					this.editedItem.AnPhamObj = anphamobj
					this.editedItem.AuthorsObjArr = authorobjarr
					//Kiểm tra xem file minh chứng có dữ liệu ko? thì mới đi parseString item.FileList
					if (proofsobjarr.length > 0) {
						this.editedItem.ProofsObjArr = proofsobjarr.map((item) => {
							if (item.FileList) {
								let jsonParse = JSON.parse(item.FileList)
								return { ...item, FileList: jsonParse }
							} else {
								return { ...item, FileList: [] }
							}
						})
					}
					this.dialog = true
					this.getDM_By_LoaiAnPhamID_from_parent()
					this.getDM_By_LoaiSubAnPhamID_from_parent()
				}, (err) => {
					console.log(err)
				})
	
			},
			//Hàm xử lý chọn xóa bài báo
			deleteItem(item) {
				this.ID = item.AnPhamID
				const $this = this
				confirm({
					title: "Xác nhận",
					content: `Xác nhận xóa bài báo`,
					action: function () {
						$this.delete_baiBao()
					}
				});
			},
			//Hàm đóng dialog khi mở chỉnh sửa bài báo
			close() {
				this.$nextTick(() => {
					this.dialog = false
					this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj)
					this.editedItem.AuthorsObjArr = Object.assign([], this.defaultItem.AuthorsObjArr)
					this.editedItem.ProofsObjArr[0].FileList = []
					this.editedIndex = -1
					this.TrangThai = null
					this.ID = null
					this.$refs.FormAnPham.TenDMTC_Arr = []
					this.$refs.FormAnPham.DMTC_Arr = []
				})
			},
			//Hàm đóng dialog khi dialog xác nhận xóa bài báo
			closeDelete() {
				this.dialogDelete = false
				this.$nextTick(() => {
					this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj)
					this.editedItem.AuthorsObjArr = Object.assign([], this.defaultItem.AuthorsObjArr)
					this.editedItem.ProofsObjArr = Object.assign([], this.defaultItem.ProofsObjArr)
					this.editedIndex = -1
					this.ID = null
				})
			},
	
			DSNganHang_Get() {
				vueData.v_Loading = true;
				const $this = this
				$.ajax({
					type: "GET",
					url: "https://api.vietqr.io/v2/banks",
					contentType: "application/json; charset=utf-8",
					dataType: "json",
					crossDomain: true,
					success: function (res) {
						if (res.code === "00") {
							$this.DSNganHang = res.data
						} else {
							Vue.$toast.warning(res.desc)
						}
					},
					error: function (error) {
						console.log("Lỗi API ngân hàng: ", error)
					},
					complete: function (data) {
						vueData.v_Loading = false;
					}
				});
			},
			//Hàm thêm mới bài báo hoặc update bài báo
			save() {
				if (this.$refs.FormAnPham?.$refs.ValidForm.validate() === false) {
					return
				}
				let flag = false
				for (let i = 0; i < this.editedItem.AuthorsObjArr.length; i++) {
					if (this.editedItem.AuthorsObjArr[i].NguoiDaiDienQuyetToan === true) {
						flag = true
						break;
					}
				}
				if (flag === false && this.editedItem.AnPhamObj.HinhThucThanhToan === 1) {
					return Vue.$toast.warning("Chưa chọn người đại diện", { position: "top" })
				}
				const $this = this
				//Hàm validate bắt buộc chọn danh mục bài báo/ ấn phẩm
				if (this.editedItem.AnPhamObj.LoaiAnPhamID === null || this.editedItem.AnPhamObj.LoaiAnPhamID === "") {
					return Vue.$toast.warning("Vui lòng chọn danh mục bài báo/ ấn phẩm", { position: "top" })
				}
				//Hàm validate bỏ trống thêm tác giảeditedIndex
				if ($this.editedItem.AuthorsObjArr.length === 0) {
					return Vue.$toast.warning("Vui lòng thêm ít nhất 1 tác giả", { position: "top" })
				}
				//Hàm update bài báo 
				if ($this.editedIndex > -1) {
					confirm({
						title: "Cập nhật bài báo",
						content: "Bạn có muốn cập nhật bài báo không?",
						action: function () {
							$this.update_baiBao()
						}
					})
				} else {
	
					//Hàm Thêm mới bài báo
					this.TrangThai = 2
					confirm({
						title: "Lưu và gửi đề xuất",
						content: "Bạn có muốn Lưu và gửi đề xuất bài báo không?",
						action: function () {
							$this.insert_baiBao().then((res) => {
							}).finally(() => {
								$this.close()
								CALL("loadAnPhamByTrangThai")
							})
						}
					})
				}
			},
			saveTemp() {
				if (this.$refs.FormAnPham?.$refs.ValidForm.validate() === false) {
					return
				}
				const $this = this
				//Hàm validate bắt buộc chọn danh mục bài báo/ ấn phẩm
				if (this.editedItem.AnPhamObj.LoaiAnPhamID === null || this.editedItem.AnPhamObj.LoaiAnPhamID === "") {
					return Vue.$toast.warning("Vui lòng chọn danh mục bài báo/ ấn phẩm", { position: "top" })
				}
				//Hàm validate bỏ trống thêm tác giả
				if ($this.editedItem.AuthorsObjArr.length === 0) {
					return Vue.$toast.warning("Vui lòng thêm ít nhất 1 tác giả", { position: "top" })
				}
				//Hàm Thêm mới bài báo
				if ($this.editedIndex === -1) {
					confirm({
						title: "Lưu bài báo",
						content: "Bạn có muốn lưu bài báo không?",
						action: function () {
							$this.insert_baiBao().then(() => {
								$this.close()
								CALL("loadAnPhamByTrangThai")
							})
						}
					})
				} else {
					confirm({
						title: "Cập nhật bài báo",
						content: "Bạn có muốn cập nhật bài báo không?",
						action: function () {
							$this.update_baiBao().then(() => {
								$this.close()
								CALL("loadAnPhamByTrangThai")
							})
						}
					})
				}
	
			},
			// Gửi đề xuất
			saveDeXuat_baiBao(AnPhamID) {
				const $this = this
				confirm({
					title: "Gửi đề xuất bài báo",
					content: 'Bạn có muốn gửi đề xuất bài báo không?',
					action: function () {
						$this.AnPhamUpdate_TrangThai(AnPhamID)
						CALL("loadAnPhamByTrangThai")
					}
				})
			},
			//API cập nhật trạng thái chờ duyệt
			AnPhamUpdate_TrangThai(AnPhamID) {
				if (this.$refs.FormAnPham?.$refs.ValidForm.validate() === false) {
					return
				}
				let flag = false
				for (let i = 0; i < this.editedItem.AuthorsObjArr.length; i++) {
					if (this.editedItem.AuthorsObjArr[i].NguoiDaiDienQuyetToan === true) {
						flag = true
						break;
					}
				} if (flag === false && this.editedItem.AnPhamObj.HinhThucThanhToan === 1) {
					return Vue.$toast.warning("Chưa chọn người đại diện", { position: "top" })
				}
				const $this = this
				//Hàm validate bắt buộc chọn danh mục bài báo/ ấn phẩm 
				if (this.editedItem.AnPhamObj.LoaiAnPhamID === null || this.editedItem.AnPhamObj.LoaiAnPhamID === "") {
					return Vue.$toast.warning("Vui lòng chọn danh mục bài báo/ ấn phẩm", { position: "top" })
				}
				//Hàm validate bỏ trống thêm tác giả 
				if ($this.editedItem.AuthorsObjArr.length === 0) {
					return Vue.$toast.warning("Vui lòng thêm ít nhất 1 tác giả", { position: "top" })
				}
				let proofsObjArrAPI = $this.editedItem.ProofsObjArr.map(item => {
					if (item.FileList) {
						const joinStringFileID = item.FileList.map(item => item.FileIDMinhChung).join(',')
						return { ...item, FileIDList: joinStringFileID }
					}
					return item
				})
				ajaxCALL("/AnPham_Udp_Obj", {
					AnPhamObj: $this.editedItem.AnPhamObj,
					AuthorsObjArr: $this.editedItem.AuthorsObjArr,
					ProofSObjArr: proofsObjArrAPI,
					TrangThai: 2
				}, (res) => {
					Vue.$toast.success("Cập nhật và gửi đề xuất thành công", { position: "top" })
					CALL("loadAnPhamByTrangThai")
					this.close()
				}, (error) => {
					Vue.$toast.error(error.responseJSON.Message, { position: "top" })
					console.log("Cập nhật và gửi đề xuất thất bại", error.data)
				}
				)
			},
			//Cập nhật bài báo
			update_baiBao() {
				const $this = this
				$this.isLoadingSave = true
				let proofsObjArrAPI = $this.editedItem.ProofsObjArr.map(item => {
					const joinStringFileID = item.FileList.map(item => item.FileIDMinhChung).join(',')
					return { ...item, FileIDList: joinStringFileID }
				})
				return new Promise((resolve, reject) => {
					ajaxCALL("/AnPham_Udp_Obj", {
						AnPhamObj: $this.editedItem.AnPhamObj,
						AuthorsObjArr: $this.editedItem.AuthorsObjArr,
						ProofSObjArr: proofsObjArrAPI,
						TrangThai: 6
					}, (res) => {
						Vue.$toast.success("Chỉnh sửa thành công", { position: "top" })
						CALL("loadAnPhamByTrangThai")
						this.isLoadingSave = false
						this.close()
					}, (error) => {
						this.isLoadingSave = false
						Vue.$toast.error(error.responseJSON.Message, { position: "top" })
						console.log("Chỉnh sửa bài báo thất bại", error.data)
					}
					)
				})
			},
			//Thêm bài báo
			insert_baiBao() {
				const $this = this
				$this.isLoadingSave = true
				let proofsObjArrAPI = $this.editedItem.ProofsObjArr.map(item => {
					const joinStringFileID = item.FileList.map(item => item.FileIDMinhChung).join(',')
					return { ...item, FileIDList: joinStringFileID }
				})
				return new Promise((resolve, reject) => {
					ajaxCALL("/AnPham_INS_Obj", {
						AnPhamObj: $this.editedItem.AnPhamObj,
						AuthorsObjArr: $this.editedItem.AuthorsObjArr,
						ProofSObjArr: proofsObjArrAPI,
						TrangThai: 6
					}, (res) => {
						resolve(res)
						Vue.$toast.success("Thêm mới bài báo thành công", { position: "top" })
						$this.isLoadingSave = false
						$this.close()
					}, (error) => {
						$this.isLoadingSave = false
						Vue.$toast.error(error.responseJSON.Message, { position: "top" })
					})
				})
			},
			//Xóa bài báo
			delete_baiBao() {
				ajaxCALL("/AnPham_Del_ByAnPhamID", {
					"AnPhamID": this.ID
				}, (res) => {
					CALL("loadAnPhamByTrangThai")
					this.closeDelete()
				}, (error) => {
					this.isLoadingSave = false
					Vue.$toast.error(error.responseJSON.Message, { position: "top" })
				})
			},
			//Hàm gọi function từ component uc-an-pham
			getDM_By_LoaiAnPhamID_from_parent() {
				this.$nextTick(async () => {
					await this.$refs.FormAnPham.getDM_By_LoaiAnPhamID_Edit()
				})
	
			},
			//Hàm gọi function từ component uc-an-pham
			getDM_By_LoaiSubAnPhamID_from_parent() {
				if (this.editedItem.AnPhamObj.LoaiSubAnPhamID) {
					this.$nextTick(async () => {
						await this.$refs.FormAnPham.getTenDMTC_By_LoaiAnPhamID_Edit()
					})
				}
			},
			resetFileIDMinhChungHoTroCaoHoc() {
				if (this.editedItem.AnPhamObj.NhomAnPham === 3) {
					this.editedItem.AnPhamObj.LoaiAnPhamID = 3
					this.editedItem.AnPhamObj.LoaiSubAnPhamID = 9
					this.editedItem.AnPhamObj.DanhMucLoaiTapChiID = 34
					this.editedItem.AnPhamObj.TenTapChi = "Tạp chí Khoa học Lạc Hồng"
					this.editedItem.AnPhamObj.HinhThucThanhToan = 1
					this.getDM_By_LoaiAnPhamID_from_parent()
					this.getDM_By_LoaiSubAnPhamID_from_parent()
				}
				this.editedItem.AnPhamObj.FileIDMinhChungHoTroCaoHoc = null
				this.editedItem.AnPhamObj.FileNameMinhChungHoTroCaoHoc = null
				this.editedItem.AnPhamObj.FileUrlMinhChungHoTroCaoHoc = null
			},
			sendBaiBao() {
				const $this = this
				confirm({
					title: "Xác nhận",
					content: `Xác nhận gửi bài báo sang dashboard`,
					action: function () {
						let AnPhamIDArr = $this.isSelected.map(item => ({ AnPhamID: item.AnPhamID }))
						if (AnPhamIDArr.length > 0) {
							ajaxCALL("/AnPham_Ins_ToRPT", {
								AnPhamObjArr: AnPhamIDArr,
								NamHoc: $this.NamHoc
							}, res => {
								$this.isSelected = []
								$this.NamHoc=""
								CALL("loadAnPhamByTrangThai")
								Vue.$toast.success("Gửi dữ liệu thành công", { position: "top" })
							}, err => {
	
							})
						} else {
							Vue.$toast.warning("Chưa chọn dữ liệu để gửi", { position: "top" })
						}
					}
				});
	
	
			},
			ThuHoiBaiBao() {
				ajaxCALL(
					"/AnPham_ThuHoi_RPT",
					{
						AnPhamID: this.ID,
					},
					(res) => {
						this.close();
						CALL("loadAnPhamByTrangThai");
						Vue.$toast.success("Đã thu hồi bài báo từ Dashboard", {
							position: "top",
						});
					},
					(err) => {
						console.log(err);
					}
				);
			},
			toExcel() {
				let convertDSBaiBao = this.DSBaiBao.map(item => {
					return {
						STT: item.STT,
						TenBaiBao: item.TenAnPham,
						TacGia: item.TacGia,
						DonViDaiDien: item.DonViDaiDien,
						DanhMucBaiBaoAnPham: item.TenLoaiAnPham,
						TenTapChi: item.TenTapChi,
						LoaiTapChi: item.TenLoaiDanhMucTapChi,
						NoiDangBai: item.NoiDangBai,
						NamDangBai: item.NamDangBai,
						HeSoIF: item.HeSo_IF,
						DiemHeSoChatLuong: item.DiemHeSoChatLuong,
						ISSN: item.ISSN,
						LinkDOI: item.DuongDanBaiBao,
						TrangThai: item.TrangThai,
					}
				}
				)
				jsonToExcel({ data: convertDSBaiBao });
				Vue.$toast.success("Đã xuất Excel", { position: 'top' });
			},
		},
	}
</script>
<style scoped></style>