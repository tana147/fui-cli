<template>
	<v-card>
		<v-card-title>
			<span class="primary--text font-weight-medium me-5">Danh sách tác giả </span>
			<v-select v-model="anphamobj.HinhThucThanhToan" hide-details="" dense="" outlined="" class="me-3" :items="HinhThucThanhToan" item-text="TenHinhThuc" item-value="HinhThucID" label="Hình thức thanh toán" style="max-width:300px" @change="resetNguoiDaiDien"></v-select>
			<v-spacer></v-spacer>
			<v-btn @click="openDialog" color="success" fab="" x-small="" outlined="" class="mb-2">
				<v-icon>mdi-plus</v-icon>
			</v-btn>
		</v-card-title>

		<div class="div-mobile div-window">
			<div class="ms-5 d-flex flex-column mt-0 mb-5">
				<span class="font-weight-medium text-h7">Tổng số tác giả:
					{{TongTacGia===null?0:TongTacGia}}</span>
				<span class="font-weight-medium text-h7">Tổng số tác giả LHU: {{TongTacGiaLHU}}</span>
			</div>
			<v-spacer></v-spacer>
			<div class="me-5 ms-5">
				<p class="mb-0">
					<b class="primary--text">Phí hỗ trợ đăng bài:</b>
					<span class="success--text font-weight-bold text-title">
						{{AnPhamObj.HoanPhiDangBai.toLocaleString('vi-vn')}}
					</span>
				</p>
				<p class="mb-0">
					<b class="primary--text">Tổng tiền khen thưởng của tác giả:</b>
					<span class="success--text font-weight-bold text-title">
						{{TongTienTacGia.toLocaleString('vi-vn')}}
					</span>
				</p>
				<p class="mb-0">
					<b class="primary--text">Tổng tiền khen thưởng của bài báo:</b>
					<span class="success--text font-weight-bold text-title">
						{{(TongTienTacGia + AnPhamObj.HoanPhiDangBai).toLocaleString('vi-vn') }}
					</span>
				</p>
			</div>

		</div>
		<v-card-text>
			<v-data-table :headers="computedHeaders" :items="AuthorsObjArr" mobile-breakpoint="600">
				<template v-slot:top="">
					<v-dialog v-model="dialog" max-width="1024px">
						<v-card>
							<v-card-title>
								<span class="text-h5 primary--text me-5">{{ formTitle }}
									<span v-if="editedIndex !== -1">
										<span class="primary--text"> ({{(editedIndex +
											1).toString().padStart(2,0)}})</span>
									</span>
								</span>

								<v-spacer></v-spacer>
								<v-btn fab="" small="" icon="" @click="close">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text>
								<v-form>
									<v-row dense="">
										<v-col cols="12" sm="12" md="4" style="display:flex; align-items: center;">
											<v-select v-model="editedItem.TacGiaGroupID" hide-details="" dense="" outlined="" :items="VaiTroArr" item-text="ten" item-value="id" label="Vai trò" @change="resetField(editedItem.TacGiaGroupID)"></v-select>
										</v-col>
										<v-col cols="12" sm="12" md="4" style="display:flex; align-items: center;">
											<v-checkbox class="mt-5 ms-5" v-model="editedItem.Is_TacGiaChinh" label="Tác giả liên hệ">
											</v-checkbox>
										</v-col>
										<v-col cols="12" sm="12" md="4">
											<v-autocomplete v-model="model" :items="items" :item-text="NhanVienSearch" item-value="MaNV" placeholder="Tìm kiếm bằng tên nhân viên" hide-no-data="" :search-input.sync="keyword" @change="changeNhanVien" @keydown="handleEnterMaNhanVien" :loading="isLoading" prepend-inner-icon="mdi-account-search" return-object=""></v-autocomplete>
										</v-col>
										<v-col cols="12" sm="6" md="2" v-if="editedItem.TacGiaGroupID == 1 ||editedItem.TacGiaGroupID == 2 ">
											<v-text-field ref="MaNhanVien" v-model="editedItem.MaNhanVien" label="Mã thành viên" outlined="" @keydown="handleEnterMaNhanVien" @blur="blurMaNhanVien" dense="">
											</v-text-field>
										</v-col>
										<v-col cols="12" sm="6" md="3">
											<v-text-field v-model="editedItem.HoTacGia" label="Họ tác giả" outlined="" dense="">
											</v-text-field>
										</v-col>
										<v-col cols="12" sm="6" md="3">
											<v-text-field v-model="editedItem.TenTacGia" label="Tên tác giả" outlined="" dense="">
											</v-text-field>
										</v-col>
										<v-col cols="12" sm="6" md="4">
											<v-text-field v-model="editedItem.EmailTacGia" label="Email" outlined="" dense="">
											</v-text-field>
										</v-col>
										<v-col cols="12" sm="6" md="4">
											<v-select outlined="" dense="" v-model="editedItem.AP_Index" :items="HeSoAP" label="AP Index">
											</v-select>
										</v-col>
										<v-col cols="12" sm="6" md="8">
											<v-text-field v-model="editedItem.TenPhongBan" label="Đơn vị" outlined="" dense="">
											</v-text-field>
										</v-col>
										<v-col cols="12" sm="6" md="4">
											<v-text-field outlined="" dense="" v-model="editedItem.SoTaiKhoan" label="Số tài khoản" v-if="editedItem.TacGiaGroupID == 1 ||editedItem.TacGiaGroupID == 2 ">
											</v-text-field>
										</v-col>
										<v-col cols="12" sm="6" md="4">
											<v-autocomplete v-if="editedItem.TacGiaGroupID == 1 ||editedItem.TacGiaGroupID == 2 " v-model="editedItem.NganHang" label="Ngân hàng" :items="DSNganHang" :filter="customFilterDSNganHang" item-text="name" item-value="name" outlined="" dense="" clearable="">
												<template v-slot:item="data">
													<template v-if="typeof data.item !== 'object'">
														<v-list-item-content v-text="data.item"></v-list-item-content>
													</template>
													<template v-else="">
														<v-list-item-avatar style="width:100px">
															<img :src="data.item.logo">
														</v-list-item-avatar>
														<v-list-item-content>
															<v-list-item-title v-html="data.item.name">
															</v-list-item-title>
														</v-list-item-content>
													</template>
												</template>
											</v-autocomplete>
										</v-col>
										<v-col cols="12" sm="6" md="4">
											<v-text-field outlined="" dense="" v-model="editedItem.TenChuTaiKhoan" label="Tên chủ tài khoản" v-if="editedItem.TacGiaGroupID == 1 ||editedItem.TacGiaGroupID == 2 ">
											</v-text-field>
										</v-col>
										<v-col cols="12" sm="6" md="4">
											<v-autocomplete v-model="editedItem.NguonCapKinhPhi" :items="KhoaNCKH" :item-text="display_DonVi" item-value="DepartmentID" hide-details="" dense="" outlined="" label="Nguồn cấp kinh phí" style="max-width:350px">
											</v-autocomplete>
										</v-col>


									</v-row>
								</v-form>
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="close">
									Đóng
								</v-btn>
								<v-btn color="primary" @click="save" v-if="AnPhamObj.TrangThaiID!==3">
									{{editedIndex === -1 ? "Thêm": "Cập nhật"}}
								</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
					<v-dialog v-model="dialogDelete" max-width="500px">
						<v-card>
							<v-card-title class="text-h5">Bạn có chắc chắn muốn xóa tác giả?</v-card-title>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn color="blue darken-1" text="" @click="closeDelete">Đóng</v-btn>
								<v-btn color="blue darken-1" text="" @click="deleteItemConfirm">Xác nhận</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>

				</template>
				<template v-slot:item.thongtincanhan="{ item }">
					<p class="mb-0"><span class="blue--text">{{item.MaNhanVien}}</span> </p>
					<p class="mb-0"><span class="green--text"><b>{{item.HoTacGia}} {{item.TenTacGia}}</b></span></p>
					<p class="mb-0"><span class="gray--text"><i>{{item.EmailTacGia}}</i></span></p>
				</template>
				<template v-slot:item.thongtinnganhang="{ item }">
					<p class="mb-0"><span class="blue--text">{{item.SoTaiKhoan}}</span></p>
					<p class="mb-0"><span class="green--text">{{item.NganHang}}</span></p>
					<p class="mb-0"><span class="gray--text">{{item.TenChuTaiKhoan}}</span></p>
				</template>

				<template v-slot:item.is_nhanvien="{ item }">
					<v-chip outlined="" v-if="item.Is_TacGiaChinh" small="" class="font-weight-bold mb-2" color="warning">Tác giả liên hệ
					</v-chip>
					
					<v-chip outlined="" v-if="item.TacGiaGroupID===1" small="" class="font-weight-bold" color="primary">
						Giảng viên/Nhân viên LHU</v-chip>
					<v-chip outlined="" v-if="item.TacGiaGroupID===2" small="" class="font-weight-bold" color="primary">
						Học viên LHU</v-chip>
					<v-chip outlined="" v-if="item.TacGiaGroupID===3" small="" class="font-weight-bold" color="primary">
						Tác giả bên ngoài LHU</v-chip>
				</template>
				<template v-slot:item.is_tacgiachinh="{ item }">
					<v-icon v-if="item.Is_TacGiaChinh " color="success">mdi-check</v-icon>
				</template>
				<template v-slot:item.sotienkhenthuong="{ item }">
					<span>{{item.SoTienKhenThuong?formatAsCurrency(item.SoTienKhenThuong): 0 }}</span>
				</template>
				<template v-slot:item.sotienhoanphidangbai="{ item }">
					<span>{{item.SoTienHoanPhiDangBai?formatAsCurrency(item.SoTienHoanPhiDangBai): 0 }}</span>
				</template>
				<template v-slot:item.checkbox="{ item }">
					<div class="d-flex justify-center align-center">
						<v-checkbox class="mt-4" v-model="item.NguoiDaiDienQuyetToan" @click="NguoiDaiDien(item)">
						</v-checkbox>
					</div>
				</template>
				<template v-slot:item.actions="{ item }">
					<div style="display:flex; justify-content:center">
						<v-icon style="font-size:18px" color="red darken-3" v-if="AnPhamObj.TrangThaiID!==3" small="" class="mr-2" @click="deleteItem(item)">
							mdi-trash-can-outline
						</v-icon>
						<v-icon style="font-size:18px" color="green darken-2" small="" class="mr-2" @click="editItem(item)">
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
		props: ["value", "anphamid", "dsnganhang", "tongtacgia", "tongtacgialhu", "anphamobj", "loaianphamid"],
		data: () => ({
	
			dialog: false,
			isLoading: false,
			dialogDelete: false,
			headersAuthorsObj: [
				{ text: 'Vị trí', sortable: false, value: "STT", align: "center" },
				{ text: 'AP Index', sortable: false, value: "AP_Index", align: "center" },
				{ text: 'Vai trò', sortable: false, value: "is_nhanvien", align: "center" ,width:'200'},
				{ text: 'Thông tin cá nhân', sortable: false, value: 'thongtincanhan' },
				{ text: 'Thông tin ngân hàng', sortable: false, value: 'thongtinnganhang' },
				{ text: 'Đơn vị', sortable: false, value: "TenPhongBan" },
				{ text: 'Tiền khen thưởng (VNĐ)', sortable: false, value: 'sotienkhenthuong', align: "right" },
				{ text: 'Hoàn phí đăng (VNĐ)', sortable: false, value: "sotienhoanphidangbai", align: "right" },
				{ text: 'Thao tác', value: "actions", align: "center", sortable: false }
			],
			VaiTroArr: [
				{ ten: "Giảng viên/Nhân viên LHU", id: 1 },
				{ ten: "Học viên LHU", id: 2 },
				{ ten: "Tác giả bên ngoài LHU", id: 3 }
			],
			editedIndex: -1,
			editedItem: {
				STT: null,
				TacGiaGroupID: 1,
				AP_Index: null,
				AnPhamID: null,
				AnPhamTacGiaID: null,
				EmailTacGia: "",
				HoTacGia: "",
				TenTacGia: "",
				Is_NhanVien: true,
				Is_TacGiaChinh: false,
				Is_Xoa: false,
				MaNhanVien: "",
				NganHang: "",
				NhanVienCapNhat: "",
				SoTaiKhoan: "",
				TenChuTaiKhoan: "",
				TenPhongBan: "",
				ThoiGianCapNhat: "",
				TrangThai: null,
				NguoiDaiDienQuyetToan: false,
				NguonCapKinhPhi: null
			},
			defaultItem: {
				STT: null,
				TacGiaGroupID: 1,
				AP_Index: null,
				AnPhamID: null,
				AnPhamTacGiaID: null,
				EmailTacGia: "",
				HoTacGia: "",
				TenTacGia: "",
				Is_NhanVien: true,
				Is_TacGiaChinh: false,
				Is_Xoa: false,
				MaNhanVien: "",
				NganHang: "",
				NhanVienCapNhat: "",
				SoTaiKhoan: "",
				TenChuTaiKhoan: "",
				TenPhongBan: "",
				ThoiGianCapNhat: "",
				TrangThai: null,
				NguoiDaiDienQuyetToan: false,
				NguonCapKinhPhi: null
			},
			MaNhanVien_rules: [
				input => (input !== "") || "Vui lòng nhập mã nhân viên",
				input => /^(nv|NV)\d{7}$/.test(input) || "Mã nhân viên không hợp lệ"
			],
			keyword: '',
			DataSearch: [],
			model: null,
			KhoaNCKH: [],
			HinhThucThanhToan: [
				{ TenHinhThuc: "Cá nhân đại diện", HinhThucID: 1 },
				{ TenHinhThuc: "Phân bổ cho từng thành viên", HinhThucID: 2 }
			],
			isSelectedAuthor: [],
			HeSoAP: [1, 0.9, 0.7, 0.5, 0.3, 0]
		}),
		computed: {
	
			computedHeaders() {
				return this.anphamobj.HinhThucThanhToan === 1 ? [{ text: 'Đại diện nhận tiền', value: 'checkbox', sortable: false, align: 'center' }, ...this.headersAuthorsObj] : this.headersAuthorsObj
			},
			formTitle() {
				return this.editedIndex === -1 ? 'Thêm mới tác giả' : `Cập nhật thông tin tác giả`
			},
			AuthorsObjArr() {
				return this.value
			},
			NganHangArr: function () {
				return this.nganhangarr
			},
			DSNganHang: function () {
				return this.dsnganhang
			},
			TongTacGia: function () {
				return this.tongtacgia
			},
			TongTacGiaLHU: function () {
				return this.tongtacgialhu
			},
			items: function () {
				return this.DataSearch.map(item => { return item })
			},
			AnPhamObj: function () {
				return this.anphamobj
			},
			TongTienTacGia: function () {
				let sum = 0
				let authors = this.value
				if (authors) {
					authors.forEach(item => {
						item.SoTienKhenThuong = item.SoTienKhenThuong ?? 0
						sum += item.SoTienKhenThuong
					})
				}
				return sum
			}
		},
		watch: {
			dialog(val) {
				if (!val) {
					this.close();
				}
			},
			dialogDelete(val) {
				val || this.closeDelete()
			},
	
			async keyword(val) {
				if (this.items.length > 0) return
				if (this.isLoading) return
				this.isLoading = true
				await this.API_Search_NhanVien(val)
				this.isLoading = false
			},
			"editedItem.Is_TacGiaChinh": function (val) {
				if (val === true) {
					this.editedItem.AP_Index = 1
				} else {
					this.editedItem.AP_Index = null
				}
			}
		},
		created() {
			this.getKhoaNCKH()
		},
		methods: {
			display_DonVi(item) {
				let text = item.DepartmentID + " - " + item.DepartmentName
				return text
			},
			openDialog() {
				if (this.loaianphamid === 6) {
					this.editedItem.AP_Index = 1
				}
				if (this.AnPhamObj.NhomAnPham === 2) {
					this.editedItem.AP_Index = 1
				}
				this.dialog = true
			},
			handleEnterMaNhanVien(e) {
				let value = e.target.value.trim()
				if (e.code === "Enter" && value !== '') {
					this.NhanVien_Get(value)
					this.TaiKhoanNH_Get(value)
				}
			},
			handleEnterSearchByName(e) {
				let value = e.target.value.trim()
				if (e.code === "Enter" && value !== '') {
					this.API_Search_NhanVien(value)
				}
			},
			blurMaNhanVien(e) {
				let value = e.target.value.trim()
				this.NhanVien_Get(value)
				this.TaiKhoanNH_Get(value)
			},
			changeNhanVien() {
				this.NhanVien_Get(this.model.MaNV)
				this.TaiKhoanNH_Get(this.model.MaNV)
			},
			TaiKhoanNH_Get(UserID) {
				ajaxCALL("/TaiKhoan_Get", {
					MaNV: UserID
				}, (res) => {
					this.editedItem.TenChuTaiKhoan = res.data[0]?.TenThe
					this.editedItem.SoTaiKhoan = res.data[0]?.TaiKhoan
					this.editedItem.NganHang = res.data[0]?.BankNameVietQR
				}, (err) => {
				}
				)
			},
			NhanVien_Get(UserID) {
				const $this = this
				vueData.v_Loading = true;
				$.ajax({
					type: "GET",
					headers: {
						authorization: $awt
					},
					url: `https://tapi.lhu.edu.vn/acc/UserInfo_ByID?UserID=${UserID}`,
					contentType: "application/json; charset=utf-8",
					dataType: "json",
					crossDomain: true,
					success: function (res) {
						let data = res.data
						if (data.length > 0) {
							$this.editedItem.MaNhanVien = data[0].UserID
							$this.editedItem.HoTacGia = data[0].LastName
							$this.editedItem.TenTacGia = data[0].FirstName
							$this.editedItem.TenPhongBan = data[0].DepartmentID
							$this.editedItem.NguonCapKinhPhi = data[0].DepartmentID
						}
						vueData.v_Loading = false;
					},
					error: function (xhr, ajaxOptions, thrownError) {
						$.dialog({
							icon: 'fas fa-exclamation',
							title: 'Error',
							content: (xhr.responseJSON ? xhr.responseJSON.Message : (xhr.responseText ? xhr.responseText : "")),
							type: 'red',
							columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
							closeIcon: true,
							buttons: {
								ok: {
									text: 'ĐÓNG;',
									btnClass: 'btn-blue',
								}
							}
						});
					},
					complete: function (data) {
						vueData.v_Loading = false;
					}
				});
			},
			//Hàm xử lí click chỉnh sửa tác giả
			editItem(item) {
				this.editedIndex = this.AuthorsObjArr.indexOf(item)
				this.editedItem = Object.assign({}, item)
				this.dialog = true
			},
			//Hàm xử lí click xóa tác giả
			deleteItem(item) {
				this.editedIndex = this.AuthorsObjArr.indexOf(item)
				this.editedItem = Object.assign({}, item)
				this.dialogDelete = true
			},
			//Hàm xác nhận xóa tác giả
			deleteItemConfirm() {
				if (!this.anphamid) {
					this.value.splice(this.editedIndex, 1)
					Vue.$toast.success("Xóa tác giả thành công!", { position: "top" })
				} else {
					this.delete_tacGia()
				}
				this.closeDelete()
			},
			// Hàm đóng dialog thêm, chỉnh sửa tác giả
			close() {
				this.dialog = false
				this.$nextTick(() => {
					this.editedItem = Object.assign({}, this.defaultItem)
					this.editedIndex = -1
				})
				this.model = null
			},
			// Hàm đóng dialog xóa tác giả
			closeDelete() {
				this.dialogDelete = false
				this.$nextTick(() => {
					this.editedItem = Object.assign({}, this.defaultItem)
					this.editedIndex = -1
				})
			},
			save() {
				if (this.editedItem.AP_Index === "" || this.editedItem.AP_Index === null) {
					this.editedItem.AP_Index = 0
				}
	
				//Update tác giả
				if (this.editedIndex > -1) {
					//Chỉnh sửa  trong lúc tạo mới bài báo
					if (!this.anphamid) {
						//Vòng lặp kiểm tra trùng lặp mã nhân viên
						for (let i = 0; i < this.value.length; i++) {
							if (i === this.editedIndex || this.editedIndex === -1) {
								continue;
							}
							if (this.editedItem.MaNhanVien === this.value[i].MaNhanVien && this.editedItem.MaNhanVien !== "") {
								return Vue.$toast.warning("Đã có tác giả này", { position: "top" })
							}
						}
						//reset dữ liệu khi chọn vai trò có id =3
						if (this.editedItem.TacGiaGroupID == 1 || this.editedItem.TacGiaGroupID == 2) {
	
						} else {
							this.editedItem.MaNhanVien = ""
							this.editedItem.TenChuTaiKhoan = ""
							this.editedItem.SoTaiKhoan = ""
							this.editedItem.NganHang = ""
						}
						Object.assign(this.value[this.editedIndex], this.editedItem)
					}//Chỉnh sửa  bài báo đã được tạo 
					else {
						//Vòng lặp kiểm tra duy nhất 1 tác giả liên hệ và trùng lặp mã nhân viên
						for (let i = 0; i < this.value.length; i++) {
							if (i === this.editedIndex || this.editedIndex === -1) {
								continue;
							}
							if (this.editedItem.MaNhanVien === this.value[i].MaNhanVien && this.editedItem.MaNhanVien !== "") {
								return Vue.$toast.warning("Đã có tác giả này", { position: "top" })
							}
						}
						//reset dữ liệu khi chọn vai trò có id =3
						if (this.editedItem.TacGiaGroupID == 1 || this.editedItem.TacGiaGroupID == 2) {
	
						} else {
							this.editedItem.MaNhanVien = ""
							this.editedItem.TenChuTaiKhoan = ""
							this.editedItem.SoTaiKhoan = ""
							this.editedItem.NganHang = ""
						}
						this.update_tacGia()
					}
					this.close()
					//Thêm tác giả
				} else {
					//Thêm tác giả  trong lúc tạo mới bài báo
					if (!this.anphamid) {
						this.anphamobj.NguonCapKinhPhi = this.value[0]?.TenPhongBan
						//Vòng lặp kiểm tra duy nhất 1 tác giả liên hệ và trùng lặp mã nhân viên
						for (let i = 0; i < this.value.length; i++) {
							if (this.editedItem.MaNhanVien === this.value[i].MaNhanVien && this.editedItem.MaNhanVien !== "") {
								return Vue.$toast.warning("Đã có tác giả này", { position: "top" })
							}
						}
						//reset dữ liệu khi chọn vai trò có id =3
						if (this.editedItem.TacGiaGroupID == 1 || this.editedItem.TacGiaGroupID == 2) {
	
						} else {
							this.editedItem.MaNhanVien = ""
							this.editedItem.TenChuTaiKhoan = ""
							this.editedItem.SoTaiKhoan = ""
							this.editedItem.NganHang = ""
						}
						this.editedItem.STT = this.value.length + 1
						this.value.push(this.editedItem)
					}
					//Thêm tác giả trong bài báo đã tạo
					else {
						//Vòng lặp kiểm tra duy nhất 1 tác giả liên hệ và trùng lặp mã nhân viên
						for (let i = 0; i < this.value.length; i++) {
							if (this.editedItem.MaNhanVien === this.value[i].MaNhanVien && this.editedItem.MaNhanVien !== "") {
								return Vue.$toast.warning("Đã có tác giả này", { position: "top" })
							}
						}
						//reset dữ liệu khi chọn vai trò có id =3
						if (this.editedItem.TacGiaGroupID == 1 || this.editedItem.TacGiaGroupID == 2) {
	
						} else {
							this.editedItem.MaNhanVien = ""
							this.editedItem.TenChuTaiKhoan = ""
							this.editedItem.SoTaiKhoan = ""
							this.editedItem.NganHang = ""
						}
						this.insert_tacGia()
					}
					this.close()
				}
			},
			customFilterDSNganHang(item, queryText, itemText) {
				const name = item.name.toLowerCase()
				const shortName = item.shortName.toLowerCase()
				const searchText = queryText.toLowerCase()
				return name.indexOf(searchText) > -1 ||
					shortName.indexOf(searchText) > -1
			},
			get_TG_byAnPhamID(AnPhamID) {
				ajaxCALL("/AnPhamTacGia_Get_ByAnPhamID", {
					AnPhamID: AnPhamID
				}, (res) => {
					this.value = res.data
					this.$emit("input", this.value)
				}, (err) => {
				}
				)
			},
			update_tacGia() {
				ajaxCALL("/AnPhamTacGia_Udp", {
					AnPhamID: this.anphamid,
					AuthorsObjArr: this.editedItem
				}, (res) => {
					Vue.$toast.success("Chỉnh sửa tác giả thành công!", { position: "top" })
					//CAllAPI Load data tac gia
					this.get_TG_byAnPhamID(this.anphamid)
				}, (error) => {
					Vue.$toast.warning("Chỉnh sửa tác giả thất bại!", { position: "top" })
				})
			},
			insert_tacGia() {
				this.editedItem.AnPhamID = this.anphamid
				ajaxCALL("/AnPhamTacGia_INS", {
					AnPhamID: this.anphamid,
					AuthorsObjArr: this.editedItem
				}, (res) => {
					Vue.$toast.success("Thêm tác giả thành công!", { position: "top" })
					//CAllAPI Load data tac gia
					this.get_TG_byAnPhamID(this.anphamid)
				}, (error) => {
					Vue.$toast.warning("Thêm tác giả thất bại!", { position: "top" })
				})
			},
			delete_tacGia() {
				ajaxCALL("/AnPhamTacGia_Del", {
					AnPhamID: this.anphamid,
					"AnPhamTacGiaID": this.editedItem.AnPhamTacGiaID
				}, (res) => {
					Vue.$toast.success("Xóa tác giả thành công!", { position: "top" })
					this.get_TG_byAnPhamID(this.anphamid)
				}, (error) => {
					Vue.$toast.warning("Xóa tác giả thất bại!", { position: "top" })
				})
			},
			validate_DuLieuTacGia() {
				let valid = false
				let MaNhanVien_Valid = this.MaNhanVien_rules.every(rules => rules(this.editedItem.MaNhanVien) === true)
				if (MaNhanVien_Valid) {
					valid = true
				}
				return valid
			},
			API_Search_NhanVien(val) {
				ajaxCALL("/TaiKhoan_Seach", {
					Keyword: val
				}, (res) => {
					this.DataSearch = res.data
				}, (error) => {
				})
			},
			NhanVienSearch(item) {
				let text = item.MaNV + " - " + item.HoNV + " " + item.TenNV
				return text
			},
			resetField(id) {
				if (this.editedIndex === -1) {
					this.editedItem = Object.assign({}, this.defaultItem)
					this.editedItem.TacGiaGroupID = id
				}
	
			},
			getKhoaNCKH() {
				ajaxCALL("https://tapi.lhu.edu.vn/hoso/Public_SelectPhongBan", null, (res) => {
					this.KhoaNCKH = res.data
				}, (err) => {
				})
			},
			NguoiDaiDien(item) {
				this.value.map(obj => {
					if (obj !== item) {
						obj.NguoiDaiDienQuyetToan = false
					} else {
						obj.NguoiDaiDienQuyetToan = item.NguoiDaiDienQuyetToan
					}
				})
			},
			resetNguoiDaiDien() {
				this.value.map(obj => {
					obj.NguoiDaiDienQuyetToan = false
				})
			}
	
		},
	}
</script>