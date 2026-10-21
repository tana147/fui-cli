<template>
	<div>
		<v-data-table :headers="headers" :items="DS_TVDeTai" class="elevation-1">
			<template v-slot:top>
				<v-toolbar flat>
					<v-toolbar-title class="primary--text font-weight-medium">
						Danh sách thành viên
					</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-dialog v-model="dialog" max-width="1000px">
						<template v-slot:activator="{ on, attrs }">
							<v-btn color="success" fab x-small outlined class="mb-2" @click="newItem">
								<v-icon>mdi-plus</v-icon>
							</v-btn>
						</template>
						<v-card>
							<v-card-title>
								<span class="text-h5 primary--text">{{dialogTitle}}</span>
								<v-spacer></v-spacer>
								<v-btn fab small icon @click="closeDialog">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text>
								<v-form>
									<v-row dense>
										<v-col cols="2" class="mt-3">
											<v-checkbox label="Chủ nhiệm đề tài" @click="clickChuNhiem"
												v-model="TVDeTai_Obj.Is_ChuNhiem" hide-details dense
												@change="SelectNhanVien">
											</v-checkbox>
										</v-col>
										<v-col cols="4" class="d-flex mt-3 ">
											<v-checkbox label="Nhân viên" @click="clickNhanVien"
												v-model="TVDeTai_Obj.Is_NhanVien" hide-details dense>
											</v-checkbox>
											<v-checkbox class="ms-2" label="Sinh viên" @click="clickSinhVien"
												v-model="TVDeTai_Obj.Is_SinhVien" hide-details dense>
											</v-checkbox>
										</v-col>
										<v-col class="mt-3" cols="2">

										</v-col>
										<v-col cols="4" class="mb-2">
											<v-autocomplete v-model="model" :items="items" :item-text="NhanVienSearch"
												item-value="MaNV" placeholder="Tìm kiếm bằng tên nhân viên" hide-no-data
												:search-input.sync="keyword" @change="changeNhanVien"
												@keydown="handleEnterMaNhanVien" :loading="isLoading"
												prepend-inner-icon="mdi-account-search" return-object hide-details>
											</v-autocomplete>
										</v-col>
										<v-col cols="3" class="mt-3">
											<v-text-field v-model="TVDeTai_Obj.MaNhanVien" label="Mã thành viên"
												outlined hide-details dense @keydown="handleEnterMaNhanVien"
												@blur="blurMaNhanVien">
											</v-text-field>
										</v-col>
										<v-col cols="3" class="mt-3">
											<v-text-field hide-details v-model="TVDeTai_Obj.Ho" label="Họ thành viên"
												outlined dense>
											</v-text-field>
										</v-col>
										<v-col cols="3" class="mt-3">
											<v-text-field hide-details v-model="TVDeTai_Obj.Ten" label="Tên thành viên"
												outlined dense>
											</v-text-field>
										</v-col>
										<v-col cols="3" class="mt-3">
											<v-text-field v-model="TVDeTai_Obj.Email" label="Email" outlined
												hide-details dense>
											</v-text-field>
										</v-col>
										<v-col cols="4" class="mt-3">
											<v-text-field hide-details v-model="TVDeTai_Obj.SoTaiKhoan"
												label="Số tài khoản" outlined dense>
											</v-text-field>
										</v-col>
										<v-col cols="4" class="mt-3">
											<v-autocomplete v-model="TVDeTai_Obj.NganHang" label="Ngân hàng"
												:items="DSNganHang" :filter="customFilterDSNganHang" item-text="name"
												item-value="name" outlined dense hide-details clearable>
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
										<v-col cols="4" class="mt-3">
											<v-text-field v-model="TVDeTai_Obj.TenChuTaiKhoan" label="Tên chủ tài khoản"
												outlined dense hide-details>
											</v-text-field>
										</v-col>
										<v-col cols="12" class="mt-3">
											<v-text-field v-model="TVDeTai_Obj.TenPhongBan" label="Tên phòng ban"
												outlined dense hide-details>
											</v-text-field>
										</v-col>
									</v-row>
								</v-form>
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="closeDialog">
									Đóng
								</v-btn>
								<v-btn color="primary" @click="insert_TVDeTai">
									{{btn_save}}
								</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
					<v-dialog v-model="dialogConfirmDelete" max-width="500px">
						<v-card>
							<v-card-title class="primary--text font-weight-medium">
								Xác nhận xóa thành viên
							</v-card-title>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="closeDialogDeleteConfirm">Đóng</v-btn>
								<v-btn color="primary" @click="delete_TVDeTai_Confirm">Xác nhận</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
				</v-toolbar>
			</template>
			<template v-slot:item.chunhiemdetai="{ item }">
				<v-icon v-if="item.Is_ChuNhiem" color="success">mdi-check</v-icon>
			</template>
			<template v-slot:item.isnhanvien="{ item }">
				<v-icon v-if="item.Is_NhanVien" color="success">mdi-check</v-icon>
			</template>
			<template v-slot:item.issinhvien="{ item }">
				<v-icon v-if="item.Is_SinhVien" color="success">mdi-check</v-icon>
			</template>
			<template v-slot:item.thongtincanhan="{ item }">
				<p class="mb-0"><span class="blue--text">{{item.MaNhanVien}}</span> </p>
				<p class="mb-0"><span class="green--text"><b>{{item.Ho}} {{item.Ten}}</b></span></p>
				<p class="mb-0"><span class="gray--text"><i>{{item.Email}}</i></span></p>
			</template>
			<template v-slot:item.thongtinnganhang="{ item }">
				<p class="mb-0"><span class="blue--text">{{item.SoTaiKhoan}}</span></p>
				<p class="mb-0"><span class="green--text">{{item.NganHang}}</span></p>
				<p class="mb-0"><span class="gray--text">{{item.TenChuTaiKhoan}}</span></p>
			</template>
			<template v-slot:item.actions="{ item }">
				<div style="display:flex; justify-content:center">
					<v-icon style="font-size:18px" color="red darken-3" small class="mr-2"
						@click="delete_TVDeTai(item)">
						mdi-trash-can-outline
					</v-icon>
					<v-icon style="font-size:18px" color="green darken-2" small class="mr-2" @click="editedItem(item)">
						mdi-square-edit-outline
					</v-icon>
				</div>
			</template>

		</v-data-table>
	</div>
</template>

<script>
	export default {
		props: ["value", "iddetai", "dsnganhang"],
		data() {
			return {
				dialog: false,
				isLoading: false,
				dialogConfirmDelete: false,
				headers: [
					{ text: "Chủ nhiệm đề tài", value: "chunhiemdetai", sortable: false, align: "center", width: "100px" },
					{ text: "Nhân viên", value: "isnhanvien", sortable: false, align: "center", width: "100px" },
					{ text: "Sinh viên", value: "issinhvien", sortable: false, align: "center", width: "100px" },
					{ text: "Thông tin cá nhân", value: "thongtincanhan", sortable: false },
					{ text: "Thông tin ngân hàng", value: "thongtinnganhang", sortable: false },
					{ text: "Tên phòng ban", value: "TenPhongBan", sortable: false },
					{ text: "Thao tác", value: "actions", align: "center", sortable: false }
				],
	
				TVDeTai_Obj: {
					STT: null,
					MaNhanVien: "",
					Ten: "",
					Ho: "",
					Email: "",
					Is_ChuNhiem: null,
					Is_NhanVien: null,
					Is_SinhVien: null,
					TenPhongBan: "",
					SoTaiKhoan: "",
					NganHang: "",
					TenChuTaiKhoan: ""
				},
				TVDeTai_Obj_Default: {
					STT: null,
					MaNhanVien: "",
					Ten: "",
					Ho: "",
					Email: "",
					Is_ChuNhiem: null,
					Is_NhanVien: null,
					Is_SinhVien: null,
					TenPhongBan: "",
					SoTaiKhoan: "",
					NganHang: "",
					TenChuTaiKhoan: ""
				},
				editedIndex: -1,
				DSNganHang: [],
				keyword: null,
				DataSearch: [],
				model: null
			}
		},
		mounted() { },
		computed: {
			dialogTitle: function () {
				return this.editedIndex == -1 ? "Thêm mới thành viên" : "Cập nhật thành viên"
			},
			btn_save: function () {
				return this.editedIndex == -1 ? "Lưu" : "Cập nhật"
			},
			DS_TVDeTai() {
				return this.value
			},
			DeTaiKHCNID: function () {
				return this.iddetai
			},
			items: function () {
				return this.DataSearch.map(item => { return item })
			},
	
		},
		watch: {
			dialog: function (val) {
				val || this.closeDialog()
			},
			async keyword(val) {
				if (this.items.length > 0) return
				if (this.isLoading) return
				this.isLoading = true
				await this.API_Search_NhanVien(val)
				this.isLoading = false
			}
	
		},
		created() {
			this.DSNganHang_Get()
		},
		methods: {
			newItem() {
				this.dialog = true
				this.TVDeTai_Obj.Is_NhanVien = true
			},
			closeDialogDeleteConfirm() {
				this.dialogConfirmDelete = false
				this.TVDeTai_Obj = Object.assign({}, this.TVDeTai_Obj_Default)
				this.editedIndex = -1
			},
			closeDialog() {
				this.dialog = false
				this.TVDeTai_Obj = Object.assign({}, this.TVDeTai_Obj_Default)
				this.editedIndex = -1
				this.model = null
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
					this.TVDeTai_Obj.TenChuTaiKhoan = res.data[0].TenThe
					this.TVDeTai_Obj.SoTaiKhoan = res.data[0].TaiKhoan
					this.TVDeTai_Obj.NganHang = res.data[0].BankNameVietQR
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
							$this.TVDeTai_Obj.MaNhanVien = data[0].UserID
							$this.TVDeTai_Obj.Ho = data[0].LastName
							$this.TVDeTai_Obj.Ten = data[0].FirstName
							$this.TVDeTai_Obj.TenPhongBan = data[0].DepartmentID
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
			customFilterDSNganHang(item, queryText, itemText) {
				const name = item.name.toLowerCase()
				const shortName = item.shortName.toLowerCase()
				const searchText = queryText.toLowerCase()
				return name.indexOf(searchText) > -1 ||
					shortName.indexOf(searchText) > -1
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
			editedItem(item) {
				this.dialog = true
				this.editedIndex = this.value.indexOf(item)
				this.TVDeTai_Obj = Object.assign({}, item)
			},
			insert_TVDeTai() {
				if (this.editedIndex === -1) {
	
					this.API_Insert_ThanhVienKHCN()
				} else {
					this.API_Update_ThanhVienKHCN()
				}
				this.closeDialog()
			},
			delete_TVDeTai_Confirm() {
				this.API_Delete_ThanhVienKHCN()
				this.closeDialogDeleteConfirm()
			},
			delete_TVDeTai(item) {
				this.dialogConfirmDelete = true
				this.TVDeTai_Obj = Object.assign({}, item)
				this.editedIndex = this.value.indexOf(item)
				console.log("this.editedIndex", this.editedIndex)
				console.log("this.value[]", this.value[this.editedIndex])
			},
			SelectNhanVien() {
				if (this.TVDeTai_Obj.Is_ChuNhiem === true) {
					this.TVDeTai_Obj.Is_NhanVien = true
				}
			},
			API_Insert_ThanhVienKHCN() {
				if (this.TVDeTai_Obj.Is_NhanVien === true && this.TVDeTai_Obj.MaNhanVien === "") {
					this.TVDeTai_Obj.Is_NhanVien = false
				}
				if (!this.DeTaiKHCNID) {
					this.value.push(this.TVDeTai_Obj)
					Vue.$toast.success("Thêm thành viên thành công", { position: "top" })
				} else {
					ajaxCALL("/KHCN_ThanhVien_Ins_Obj", {
						DeTaiKHCNID: this.DeTaiKHCNID,
						ThanhVienKHCNObj: this.TVDeTai_Obj
					}, res => {
						this.API_Reload_ThanhVienKHCN()
						Vue.$toast.success("Thêm thành viên thành công", { position: "top" })
					}, err => {
						console.log("Thêm thành viên thất bại", err)
					})
				}
				this.TVDeTai_Obj = Object.assign({}, this.TVDeTai_Obj_Default)
			},
			API_Delete_ThanhVienKHCN() {
				if (!this.DeTaiKHCNID) {
					this.value.splice(this.editedIndex, 1)
				} else {
					ajaxCALL("/KHCN_ThanhVien_Del_Obj", {
						ThanhVienKHCNObj: this.TVDeTai_Obj
					}, res => {
						Vue.$toast.success("Xóa thành công", { position: "top" })
						this.API_Reload_ThanhVienKHCN()
					}, err => {
						Vue.$toast.error("Xóa thất bại", { position: "top" })
						console.log(err)
					})
				}
			},
			API_Update_ThanhVienKHCN() {
				if (this.TVDeTai_Obj.Is_NhanVien === true && this.TVDeTai_Obj.MaNhanVien === "") {
					this.TVDeTai_Obj.Is_NhanVien = false
				}
				if (!this.DeTaiKHCNID) {
					Object.assign(this.value[this.editedIndex], this.TVDeTai_Obj)
					Vue.$toast.success("Cập nhật thành công", { position: "top" })
				} else {
					ajaxCALL("/KHCN_ThanhVien_Upd_Obj", {
						ThanhVienKHCNObj: this.TVDeTai_Obj
					}, res => {
						Vue.$toast.success("Cập nhật thành công", { position: "top" })
						this.API_Reload_ThanhVienKHCN()
					}, err => {
						Vue.$toast.error("Cập nhật thất bại", { position: "top" })
						console.log(err)
					})
				}
				this.TVDeTai_Obj = Object.assign({}, this.TVDeTai_Obj_Default)
			},
			API_Reload_ThanhVienKHCN() {
				ajaxCALL("/KHCN_ThanhVien_Get_ByID", {
					DeTaiKHCNID: this.DeTaiKHCNID
				}, res => {
					this.$emit("input", res.data)
				}, err => {
					console.log(err)
				})
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
			//Xử lý checkbox
			clickNhanVien() {
				this.TVDeTai_Obj.Is_SinhVien = !this.TVDeTai_Obj.Is_NhanVien
			},
			//Xử lý checkbox
			clickSinhVien() {
				this.TVDeTai_Obj.Is_NhanVien = !this.TVDeTai_Obj.Is_SinhVien
			},
			//Xử lý checkbox
			clickChuNhiem() {
				this.TVDeTai_Obj.Is_SinhVien = false
			}
		},
	}
</script>