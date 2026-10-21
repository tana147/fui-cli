<template>
	<v-card>
		<v-card-title>
			<span class="primary--text font-weight-medium me-5">Danh sách tác giả </span>
			<v-select v-model="anPhamObj.HinhThucThanhToan" hide-details dense outlined class="me-3"
				:items="hinhThucThanhToan" item-text="TenHinhThuc" item-value="HinhThucID" label="Hình thức thanh toán"
				style="max-width:300px" @change="resetNguoiDaiDien" :readonly="anPhamObj.NhomAnPham===2"></v-select>
			<v-spacer></v-spacer>
			<v-btn @click="openDialog" color="success" fab x-small outlined class="mb-2">
				<v-icon>mdi-plus</v-icon>
			</v-btn>
		</v-card-title>

		<div class="div-mobile div-window">
			<div class="ms-5 d-flex flex-column mt-0 mb-5">
				<span class="font-weight-medium text-h7">Tổng số tác giả:
					{{ tongTacGiaValue === null ? 0 : tongTacGiaValue }}</span>
				<span class="font-weight-medium text-h7">Tổng số tác giả LHU: {{ tongTacGiaLhuValue }}</span>
			</div>
			<v-spacer></v-spacer>
			<div class="me-5 ms-5" style="width:400px">
				<v-row>
					<v-col cols="9" class="d-flex flex-column ">
						<b class="primary--text text-right">Phí hỗ trợ đăng bài (HTĐB):</b>
						<b class="primary--text text-right">Tiền khen thưởng bài báo (KTBB):</b>
						<b class="primary--text text-right">Tổng tiền bài báo (Phí HTĐB + Tiền KTBB):</b>
					</v-col>
					<v-col cols="3" class="d-flex flex-column ">
						<span class="success--text font-weight-bold text-title text-right">
							{{ formatAsCurrency(tongHoanPhiDangBai, 0) }}
						</span>
						<span class="success--text font-weight-bold text-title text-right">
							{{ formatAsCurrency(tongTienTacGia, 0) }}
						</span>
						<span class="success--text font-weight-bold text-title text-right">
							{{ formatAsCurrency((tongTienTacGia + tongHoanPhiDangBai), 0) }}
						</span>
					</v-col>
				</v-row>
			</div>
		</div>

		<v-card-text>
			<v-dialog v-model="isAuthorModalOpen" max-width="1024px">
				<v-card>
					<v-card-title>
						<span class="text-h5 primary--text me-5">{{ formTitle }}
							<span v-if="editedIndex !== -1">
								<span class="primary--text"> ({{ (editedIndex + 1).toString().padStart(2, 0) }})</span>
							</span>
						</span>

						<v-spacer></v-spacer>
						<v-btn fab small icon @click="close">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</v-card-title>
					<v-card-text>
						<v-form>
							<v-row dense>
								<v-col cols="12" sm="12" md="3" style="display:flex; align-items: center;">
									<v-select v-model="editedItem.TacGiaGroupID" hide-details dense outlined
										:items="vaiTroArr" item-text="ten" item-value="id" label="Vai trò"></v-select>
								</v-col>
								<v-col cols="12" sm="12" md="3" style="display:flex; align-items: center;">
									<v-checkbox class="mt-5 ms-5" v-model="editedItem.Is_TacGiaChinh"
										label="Tác giả chính">
									</v-checkbox>
								</v-col>
								<v-col cols="12" sm="12" md="3" style="display:flex; align-items: center;">
									<v-checkbox class="mt-5 ms-5" v-model="editedItem.Is_TacGiaPhu" label="Tác giả phụ">
									</v-checkbox>
								</v-col>
								<v-col cols="12" sm="12" md="3">
									<v-autocomplete v-model="model" :items="items" :item-text="NhanVienSearch"
										item-value="MaNV" placeholder="Tìm kiếm bằng tên nhân viên" hide-no-data
										:search-input.sync="keyword" @change="changeNhanVien"
										@keydown="handleEnterMaNhanVien" :loading="isLoading"
										prepend-inner-icon="mdi-account-search" return-object></v-autocomplete>
								</v-col>
								<v-col cols="12" sm="6" md="2"
									v-if="editedItem.TacGiaGroupID == 1 || editedItem.TacGiaGroupID == 2">
									<v-text-field ref="MaNhanVien" v-model="editedItem.MaNhanVien" label="Mã thành viên"
										outlined @keydown="handleEnterMaNhanVien" @blur="blurMaNhanVien" dense>
									</v-text-field>
								</v-col>
								<v-col cols="12" sm="6" md="3">
									<v-text-field v-model="editedItem.HoTacGia" label="Họ tác giả" outlined dense>
									</v-text-field>
								</v-col>
								<v-col cols="12" sm="6" md="3">
									<v-text-field v-model="editedItem.TenTacGia" label="Tên tác giả" outlined dense>
									</v-text-field>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<v-text-field v-model="editedItem.EmailTacGia" label="Email" outlined dense>
									</v-text-field>
								</v-col>
								<v-col cols="12" sm="6" md="8">
									<v-text-field v-model="editedItem.TenPhongBan" label="Đơn vị" outlined dense>
									</v-text-field>
								</v-col>
								<v-col cols="12" sm="6" md="4"
									v-if="editedItem.TacGiaGroupID == 1 || editedItem.TacGiaGroupID == 2">
									<v-text-field outlined dense v-model="editedItem.SoTaiKhoan" label="Số tài khoản">
									</v-text-field>
								</v-col>
								<v-col cols="12" sm="6" md="4"
									v-if="editedItem.TacGiaGroupID == 1 || editedItem.TacGiaGroupID == 2">
									<v-autocomplete v-model="editedItem.NganHang" label="Ngân hàng" :items="dsNganHang"
										:filter="customFilterDSNganHang" item-text="name" item-value="name" outlined
										dense clearable>
										<template v-slot:item="data">
											<template v-if="typeof data.item !== 'object'">
												<v-list-item-content v-text="data.item"></v-list-item-content>
											</template>
											<template v-else>
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
								<v-col cols="12" sm="6" md="4"
									v-if="editedItem.TacGiaGroupID == 1 || editedItem.TacGiaGroupID == 2">
									<v-text-field outlined dense v-model="editedItem.TenChuTaiKhoan"
										label="Tên chủ tài khoản">
									</v-text-field>
								</v-col>
								<v-col cols="12" sm="6" md="4">
									<v-autocomplete v-model="editedItem.NguonCapKinhPhi" :items="khoaNckh"
										:item-text="display_DonVi" item-value="DepartmentID" hide-details dense outlined
										label="Nguồn cấp kinh phí" style="max-width:350px">
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
						<v-btn color="primary" @click="save" v-if="anPhamObj.TrangThaiID !== 3">
							{{ editedIndex === -1 ? "Thêm" : "Cập nhật" }}
						</v-btn>
					</v-card-actions>
				</v-card>
			</v-dialog>

			<v-dialog v-model="isDeleteModalOpen" max-width="500px">
				<v-card>
					<v-card-title class="text-h5">Bạn có chắc chắn muốn xóa tác giả?</v-card-title>
					<v-card-actions>
						<v-spacer></v-spacer>
						<v-btn color="blue darken-1" text @click="closeDelete">Đóng</v-btn>
						<v-btn color="blue darken-1" text @click="deleteItemConfirm">Xác nhận</v-btn>
					</v-card-actions>
				</v-card>
			</v-dialog>

			<v-data-table :headers="computedHeaders" :items="authorsObjArr" mobile-breakpoint="600">
				<template v-slot:item.thongtincanhan="{ item }">
					<p class="mb-0"><span class="blue--text">{{ item.MaNhanVien }}</span> </p>
					<p class="mb-0"><span class="green--text"><b>{{ item.HoTacGia }} {{ item.TenTacGia }}</b></span></p>
					<p class="mb-0"><span class="gray--text"><i>{{ item.EmailTacGia }}</i></span></p>
				</template>
				<template v-slot:item.thongtinnganhang="{ item }">
					<p class="mb-0"><span class="blue--text">{{ item.SoTaiKhoan }}</span></p>
					<p class="mb-0"><span class="green--text">{{ item.NganHang }}</span></p>
					<p class="mb-0"><span class="gray--text">{{ item.TenChuTaiKhoan }}</span></p>
				</template>

				<template v-slot:item.is_nhanvien="{ item }">
					<v-chip outlined v-if="item.Is_TacGiaChinh" small class="font-weight-bold mb-2" color="warning">Tác
						giả chính</v-chip>
					<v-chip outlined v-if="item.Is_TacGiaPhu" small class="font-weight-bold mb-2" color="info">Tác
						giả phụ</v-chip>

					<v-chip outlined v-if="item.TacGiaGroupID===1" small class="font-weight-bold" color="primary">
						Giảng viên/Nhân viên LHU</v-chip>
					<v-chip outlined v-if="item.TacGiaGroupID===2" small class="font-weight-bold" color="primary">
						Học viên LHU</v-chip>
					<v-chip outlined v-if="item.TacGiaGroupID===3" small class="font-weight-bold" color="warning">
						Tác giả bên ngoài LHU</v-chip>
				</template>
				<template v-slot:item.sotienkhenthuong="{ item }">
					<span>{{ item.SoTienKhenThuong ? formatAsCurrency(item.SoTienKhenThuong) : 0 }}</span>
				</template>
				<template v-slot:item.sotienhoanphidangbai="{ item }">
					<span>{{ item.SoTienHoanPhiDangBai ? formatAsCurrency(item.SoTienHoanPhiDangBai) : 0 }}</span>
				</template>
				<template v-slot:item.checkbox="{ item }">
					<div class="d-flex justify-center align-center">
						<v-checkbox class="mt-4" v-model="item.NguoiDaiDienQuyetToan" @click="NguoiDaiDien(item)"
							:disabled="item.TacGiaGroupID===3"></v-checkbox>
					</div>
				</template>
				<template v-slot:item.actions="{ item }">
					<div style="display:flex; justify-content:center">
						<v-icon style="font-size:18px" color="red darken-3" v-if="anPhamObj.TrangThaiID !== 3" small
							class="mr-2" @click="deleteItem(item)">
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
		name: 'uc-table-tac-gia',
	props: {
		value: { type: Array, default: () => [] },
		anPhamId: { default: null },
		dsNganHang: { type: Array, default: () => [] },
		tongTacGia: { default: 0 },
		tongTacGiaLhu: { default: 0 },
		anPhamObj: { type: Object, default: () => ({}) },
		loaiAnPhamId: { default: null }
	},
	emits: ['input'],
	data() {
		return {
			// 1. Controls
			isAuthorModalOpen: false,
			isDeleteModalOpen: false,

			// 2. API / Static arrays
			headersAuthorsObj: [
				{ text: 'Vị trí', sortable: false, value: "STT", align: "center" },
				{ text: 'Vai trò', sortable: false, value: "is_nhanvien", align: "center", width: '200' },
				{ text: 'Thông tin cá nhân', sortable: false, value: 'thongtincanhan' },
				{ text: 'Thông tin ngân hàng', sortable: false, value: 'thongtinnganhang' },
				{ text: 'Đơn vị', sortable: false, value: "TenPhongBan" },
				{ text: 'Tiền khen thưởng (VNĐ)', sortable: false, value: 'sotienkhenthuong', align: "right" },
				{ text: 'Hoàn phí đăng (VNĐ)', sortable: false, value: "sotienhoanphidangbai", align: "right" },
				{ text: 'Thao tác', value: "actions", align: "center", sortable: false }
			],
			vaiTroArr: [
				{ ten: "Giảng viên/Nhân viên LHU", id: 1 },
				{ ten: "Học viên LHU", id: 2 },
				{ ten: "Tác giả bên ngoài LHU", id: 3 }
			],
			hinhThucThanhToan: [
				{ TenHinhThuc: "Cá nhân đại diện", HinhThucID: 1 },
				{ TenHinhThuc: "Phân bổ cho từng thành viên", HinhThucID: 2 }
			],
			khoaNckh: [],
			heSoAp: [1, 0.9, 0.7, 0.5, 0.3, 0],
			dataSearch: [],
			maNhanVienRules: [
				input => (input !== "") || "Vui lòng nhập mã nhân viên",
				input => /^(nv|NV)\d{7}$/.test(input) || "Mã nhân viên không hợp lệ"
			],
			defaultItem: {
				STT: null,
				TacGiaGroupID: 1,
				AnPhamID: null,
				AnPhamTacGiaID: null,
				EmailTacGia: "",
				HoTacGia: "",
				TenTacGia: "",
				Is_NhanVien: true,
				Is_TacGiaChinh: false,
				Is_TacGiaPhu: false,
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
				NguonCapKinhPhi: null,
				HeSoHoTroCaoHoc: 1
			},

			// 3. Local state
			isLoading: false,
			editedIndex: -1,
			editedItem: {
				STT: null,
				TacGiaGroupID: 1,
				AnPhamID: null,
				AnPhamTacGiaID: null,
				EmailTacGia: "",
				HoTacGia: "",
				TenTacGia: "",
				Is_NhanVien: true,
				Is_TacGiaChinh: false,
				Is_TacGiaPhu: false,
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
				NguonCapKinhPhi: null,
				HeSoHoTroCaoHoc: 1
			},
			keyword: '',
			model: null,
			isSelectedAuthor: []
		}
	},
	computed: {
		computedHeaders() {
			return this.anPhamObj.HinhThucThanhToan === 1 
				? [{ text: 'Đại diện nhận tiền', value: 'checkbox', sortable: false, align: 'center' }, ...this.headersAuthorsObj] 
				: this.headersAuthorsObj
		},
		formTitle() {
			return this.editedIndex === -1 ? 'Thêm mới tác giả' : `Cập nhật thông tin tác giả`
		},
		authorsObjArr() {
			return this.value
		},
		tongTacGiaValue() {
			return this.tongTacGia
		},
		tongTacGiaLhuValue() {
			return this.tongTacGiaLhu
		},
		items() {
			return this.dataSearch.map(item => item)
		},
		tongTienTacGia() {
			let sum = 0
			let authors = this.value || []
			authors.forEach(item => {
				sum += item.SoTienKhenThuong || 0
			})
			return sum
		},
		tongHoanPhiDangBai() {
			let sum = 0
			let authors = this.value || []
			authors.forEach(item => {
				sum += item.SoTienHoanPhiDangBai || 0
			})
			return sum
		}
	},
	watch: {
		isAuthorModalOpen(val) {
			if (!val) {
				this.close()
			}
		},
		isDeleteModalOpen(val) {
			val || this.closeDelete()
		},
		async keyword(val) {
			if (!val) {
				this.dataSearch = []
				return
			}
			if (this.isLoading) return
			this.isLoading = true
			await this.API_Search_NhanVien(val)
			this.isLoading = false
		},
		"editedItem.Is_TacGiaPhu"(val) {
			if (val === true) {
				this.editedItem.Is_TacGiaChinh = false
			}
		},
		"editedItem.Is_TacGiaChinh"(val) {
			if (val === true) {
				this.editedItem.Is_TacGiaPhu = false
			}
		}
	},
	created() {
		this.getKhoaNCKH()
	},
	methods: {
		getDefaultItem() {
			return Object.assign({}, this.defaultItem)
		},
		isTacGiaLHU(item) {
			return item.TacGiaGroupID == 1 || item.TacGiaGroupID == 2
		},
		resetThongTinLHU(item) {
			if (this.isTacGiaLHU(item)) {
				return
			}
			item.MaNhanVien = ""
			item.TenChuTaiKhoan = ""
			item.SoTaiKhoan = ""
			item.NganHang = ""
		},
		isDuplicateMaNhanVien() {
			if (!this.editedItem.MaNhanVien) {
				return false
			}
			return this.value.some((item, index) => {
				if (index === this.editedIndex) {
					return false
				}
				return item.MaNhanVien === this.editedItem.MaNhanVien
			})
		},
		display_DonVi(item) {
			if (!item) {
				return ""
			}
			return item.DepartmentID + " - " + item.DepartmentName
		},
		openDialog() {
			this.isAuthorModalOpen = true
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
			if (!this.model || !this.model.MaNV) {
				return
			}
			this.NhanVien_Get(this.model.MaNV)
			this.TaiKhoanNH_Get(this.model.MaNV)
		},
		async TaiKhoanNH_Get(UserID) {
			const params = { MaNV: UserID }
			const data = await ajaxCALLPromise("/TaiKhoan_Get", params)
			if (data && data[0]) {
				this.editedItem.TenChuTaiKhoan = data[0].TenThe
				this.editedItem.SoTaiKhoan = data[0].TaiKhoan
				this.editedItem.NganHang = data[0].BankNameVietQR
			}
		},
		NhanVien_Get(UserID) {
			$.ajax({
				type: "GET",
				headers: {
					authorization: $awt
				},
				url: `https://tapi.lhu.edu.vn/acc/UserInfo_ByID?UserID=${UserID}`,
				contentType: "application/json; charset=utf-8",
				dataType: "json",
				crossDomain: true,
				success: (res) => {
					let data = res.data
					if (data && data.length > 0) {
						this.editedItem.MaNhanVien = data[0].UserID
						this.editedItem.HoTacGia = data[0].LastName
						this.editedItem.TenTacGia = data[0].FirstName
						this.editedItem.TenPhongBan = data[0].DepartmentID
						this.editedItem.NguonCapKinhPhi = data[0].DepartmentID
					}
				},
				error: (xhr) => {
					$.dialog({
						icon: 'fas fa-exclamation',
						title: 'Error',
						content: (xhr.responseJSON ? xhr.responseJSON.Message : (xhr.responseText ? xhr.responseText : "")),
						type: 'red',
						columnClass: 'col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8',
						closeIcon: true,
						buttons: {
							ok: {
								text: 'ĐÓNG',
								btnClass: 'btn-blue',
							}
						}
					});
				},
			});
		},
		editItem(item) {
			this.editedIndex = this.authorsObjArr.indexOf(item)
			this.editedItem = Object.assign({}, item)
			this.isAuthorModalOpen = true
		},
		deleteItem(item) {
			this.editedIndex = this.authorsObjArr.indexOf(item)
			this.editedItem = Object.assign({}, item)
			this.isDeleteModalOpen = true
		},
		deleteItemConfirm() {
			if (!this.anPhamId) {
				this.value.splice(this.editedIndex, 1)
				Vue.$toast.success("Xóa tác giả thành công!", { position: "top" })
			} else {
				this.delete_tacGia()
			}
			this.closeDelete()
		},
		close() {
			this.isAuthorModalOpen = false
			this.$nextTick(() => {
				this.editedItem = this.getDefaultItem()
				this.editedIndex = -1
			})
			this.model = null
		},
		closeDelete() {
			this.isDeleteModalOpen = false
			this.$nextTick(() => {
				this.editedItem = this.getDefaultItem()
				this.editedIndex = -1
			})
		},
		save() {
			if (this.editedItem.TacGiaGroupID == 1 || this.editedItem.TacGiaGroupID == 2) {
				if (!this.editedItem.Is_TacGiaChinh && !this.editedItem.Is_TacGiaPhu) {
					return Vue.$toast.warning("Vui lòng chọn vai trò Tác giả chính hoặc Tác giả phụ", { position: "top" })
				}
			}
			if (this.editedItem.TacGiaGroupID === 3 ) {this.editedItem.Is_NhanVien = false }
			else {this.editedItem.Is_NhanVien = true}
			if (this.isDuplicateMaNhanVien()) {
				return Vue.$toast.warning("Đã có tác giả này", { position: "top" })
			}
			this.resetThongTinLHU(this.editedItem)
			if (this.anPhamObj && this.anPhamObj.NhomAnPham === 1) {
				this.editedItem.HeSoHoTroCaoHoc = 1
			}
			if (this.editedIndex > -1) {
				if (!this.anPhamId) {
					Object.assign(this.value[this.editedIndex], this.editedItem)
				} else {
					this.update_tacGia()
				}
				this.close()
			} else {
				if (!this.anPhamId) {
					this.anPhamObj.NguonCapKinhPhi = this.value[0]?.TenPhongBan
					this.editedItem.STT = this.value.length + 1
					this.value.push(this.editedItem)
				} else {
					this.insert_tacGia()
				}
				this.close()
			}
		},
		customFilterDSNganHang(item, queryText) {
			const name = (item.name || "").toLowerCase()
			const shortName = (item.shortName || "").toLowerCase()
			const searchText = (queryText || "").toLowerCase()
			return name.indexOf(searchText) > -1 || shortName.indexOf(searchText) > -1
		},
		async get_TG_byAnPhamID(AnPhamID) {
			const params = { AnPhamID }
			const data = await ajaxCALLPromise("/AnPhamTacGia_Get_ByAnPhamID", params)
			this.$emit("input", data || [])
		},
		async update_tacGia() {
			const params = {
				AnPhamID: this.anPhamId,
				AuthorsObjArr: this.editedItem
			}
			await ajaxCALLPromise("/AnPhamTacGia_Udp", params)
			Vue.$toast.success("Chỉnh sửa tác giả thành công!", { position: "top" })
			this.get_TG_byAnPhamID(this.anPhamId)
		},
		async insert_tacGia() {
			this.editedItem.AnPhamID = this.anPhamId
			const params = {
				AnPhamID: this.anPhamId,
				AuthorsObjArr: this.editedItem
			}
			await ajaxCALLPromise("/AnPhamTacGia_INS", params)
			Vue.$toast.success("Thêm tác giả thành công!", { position: "top" })
			this.get_TG_byAnPhamID(this.anPhamId)
		},
		async delete_tacGia() {
			const params = {
				AnPhamID: this.anPhamId,
				AnPhamTacGiaID: this.editedItem.AnPhamTacGiaID
			}
			await ajaxCALLPromise("/AnPhamTacGia_Del", params)
			Vue.$toast.success("Xóa tác giả thành công!", { position: "top" })
			this.get_TG_byAnPhamID(this.anPhamId)
		},
		validate_DuLieuTacGia() {
			let valid = false
			let MaNhanVien_Valid = this.maNhanVienRules.every(rules => rules(this.editedItem.MaNhanVien) === true)
			if (MaNhanVien_Valid) {
				valid = true
			}
			return valid
		},
		async API_Search_NhanVien(val) {
			const params = { Keyword: val }
			this.dataSearch = await ajaxCALLPromise("/TaiKhoan_Seach", params) || []
		},
		NhanVienSearch(item) {
			return item.MaNV + " - " + item.HoNV + " " + item.TenNV
		},
		async getKhoaNCKH() {
			this.khoaNckh = await ajaxCALLPromise("https://tapi.lhu.edu.vn/hoso/Public_SelectPhongBan") || []
		},
		NguoiDaiDien(item) {
			this.value.forEach(obj => {
				if (obj !== item) {
					obj.NguoiDaiDienQuyetToan = false
				} else {
					obj.NguoiDaiDienQuyetToan = item.NguoiDaiDienQuyetToan
				}
			})
		},
		resetNguoiDaiDien() {
			this.value.forEach(obj => {
				obj.NguoiDaiDienQuyetToan = false
			})
		}
	}
	}
</script>