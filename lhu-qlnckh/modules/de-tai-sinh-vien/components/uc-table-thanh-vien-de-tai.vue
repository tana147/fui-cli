<template>
	<div>
		<v-data-table :headers="headers" :items="DS_TVDeTai" class="elevation-1">
			<template v-slot:top>
				<v-toolbar flat>
					<v-toolbar-title class="primary--text font-weight-medium">
						Danh sách thành viên
					</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-dialog v-model="dialog" max-width="800px">
						<template v-slot:activator="{ on, attrs }">
							<v-btn color="success" fab x-small outlined class="mb-2" @click="newItem">
								<v-icon>mdi-plus</v-icon>
							</v-btn>
						</template>
						<v-card>
							<v-card-title>
								<span class="text-h5 primary--text">{{title}}</span>
								<v-spacer></v-spacer>
								<v-btn fab small icon @click="closeDialog">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text>
								<v-form>
									<v-row dense>
										<v-col cols="8" class="d-flex ">
											<v-checkbox label="Giảng viên hướng dẫn"
												v-model="ThanhVienNCKHObj.Is_ChuNhiem" @click="checkboxGV" hide-details
												dense></v-checkbox>
											<v-checkbox class="ms-2" label="Sinh viên" @click="checkboxSV"
												v-model="ThanhVienNCKHObj.Is_SinhVien" hide-details dense></v-checkbox>
										</v-col>
										<v-col cols="4">
										</v-col>
										<v-col cols="4" class="mt-3">
											<v-text-field v-if="ThanhVienNCKHObj.Is_SinhVien===true" label="Lớp"
												v-model="ThanhVienNCKHObj.LopID" outlined dense
												hide-details></v-text-field>
										</v-col>
										<v-col cols="8" class="mt-3">
										</v-col>
										<v-col cols="4" class="mt-3">
											<v-text-field label="Mã thành viên" @blur="blurMaNhanVien"
												@keydown="handleEnterMaNhanVien" v-model="ThanhVienNCKHObj.MaThanhVien"
												outlined dense hide-details></v-text-field>
										</v-col>
										<v-col cols="4" class="mt-3">
											<v-text-field label="Họ thành viên" v-model="ThanhVienNCKHObj.Ho" outlined
												dense hide-details></v-text-field>
										</v-col>
										<v-col cols="4" class="mt-3">
											<v-text-field label="Tên thành viên" v-model="ThanhVienNCKHObj.Ten" outlined
												dense hide-details></v-text-field>
										</v-col>
										<v-col cols="4" class="mt-3" v-if="ThanhVienNCKHObj.Is_ChuNhiem===true">
											<v-text-field label="Số tài khoản" v-model="ThanhVienNCKHObj.SoTaiKhoan"
												outlined dense hide-details></v-text-field>
										</v-col>
										<v-col cols="4" class="mt-3" v-if="ThanhVienNCKHObj.Is_ChuNhiem===true">
											<v-autocomplete label="Tên ngân hàng" v-model="ThanhVienNCKHObj.NganHang"
												outlined dense hide-details :items="DSNganHang"
												:filter="customFilterDSNganHang" item-text="name"
												item-value="name"></v-autocomplete>
										</v-col>
										<v-col cols="4" class="mt-3" v-if="ThanhVienNCKHObj.Is_ChuNhiem===true">
											<v-text-field label="Tên chủ tài khoản"
												v-model="ThanhVienNCKHObj.TenChuTaiKhoan" outlined dense
												hide-details></v-text-field>
										</v-col>
										<v-col cols="12" class="mt-3">
											<v-text-field label="Đơn vị" v-model="ThanhVienNCKHObj.PhongBanID" outlined
												dense hide-details></v-text-field>
										</v-col>

									</v-row>
								</v-form>
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="closeDialog">
									Đóng
								</v-btn>
								<v-btn color="primary" @click="insert_TVDeTai">{{editedIndex=== -1 ? "Thêm":"Cập nhật"}}
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
			<template v-slot:item.hovaten="{ item }">
				<span>{{item.Ho}} {{item.Ten}}</span>

			</template>
			<template v-slot:item.vaitro="{ item }">
				<span v-if="item.Is_NhanVien == true">Nhân viên</span>
				<span v-if="item.Is_ChuNhiem == true">Giảng viên hướng dẫn</span>
				<span v-if="item.Is_SinhVien == true">Sinh viên</span>
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
		props: ["value", "iddetai"],
		data() {
			return {
				dialog: false,
				dialogConfirmDelete: false,
				headers: [
					{ text: "Vai trò", value: "vaitro", sortable: false },
					{ text: "Mã thành viên", value: "MaThanhVien", sortable: false },
					{ text: "Họ và tên", value: "hovaten", sortable: false },
					{ text: "Lớp", value: "LopID", sortable: false },
					{ text: "Thao tác", value: "actions", align: "center", sortable: false }
				],
				editedIndex: -1,
				ThanhVienNCKHObj: {
					STT: null,
					Is_ChuNhiem: null,
					Is_SinhVien: true,
					Is_NhanVien: null,
					MaThanhVien: "",
					Ho: "",
					Ten: "",
					Email: "",
					PhongBanID: "",
					LopID: "",
					SoTaiKhoan: "",
					NganHang: "",
					TenChuTaiKhoan: ""
				},
				ThanhVienNCKHObj_Default: {
					STT: null,
					Is_ChuNhiem: null,
					Is_SinhVien: true,
					Is_NhanVien: null,
					MaThanhVien: "",
					Ho: "",
					Ten: "",
					Email: "",
					PhongBanID: "",
					LopID: "",
					SoTaiKhoan: "",
					NganHang: "",
					TenChuTaiKhoan: ""
				},
				DSNganHang: []
			}
		},
		created() {
			this.DSNganHang_Get()
		},
		mounted() { },
		computed: {
			DS_TVDeTai: function () {
				return this.value
			},
			DeTaiNCKHID: function () {
				return this.iddetai
			},
			title: function () {
				return this.editedIndex === -1 ? "Thêm mới thành viên" : "Cập nhật thành viên"
			}
		},
		watch: {
			dialog: function (val) {
				val || this.closeDialog()
			},
			"ThanhVienNCKHObj.Is_SinhVien": function (val) {
				val || this.clearLopID()
			},
			"ThanhVienNCKHObj.Is_ChuNhiem": function (val) {
				val || this.clearNganHang()
			}
		},
		methods: {
			handleEnterMaNhanVien(e) {
				let value = e.target.value.trim()
				if (e.code === "Enter" && value !== '') {
					this.NhanVien_Get(value)
					this.TaiKhoanNH_Get(value)
				}
			},
			blurMaNhanVien(e) {
				let value = e.target.value.trim()
				this.NhanVien_Get(value)
				this.TaiKhoanNH_Get(value)
			},
			TaiKhoanNH_Get(UserID) {
				ajaxCALL("/TaiKhoan_Get", {
					MaNV: UserID
				}, (res) => {
					this.ThanhVienNCKHObj.TenChuTaiKhoan = res.data[0]?.TenThe
					this.ThanhVienNCKHObj.SoTaiKhoan = res.data[0]?.TaiKhoan
					this.ThanhVienNCKHObj.NganHang = res.data[0]?.BankNameVietQR
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
							$this.ThanhVienNCKHObj.Ho = data[0].LastName
							$this.ThanhVienNCKHObj.Ten = data[0].FirstName
							$this.ThanhVienNCKHObj.PhongBanID = data[0].DepartmentID
							$this.ThanhVienNCKHObj.LopID = data[0].ClassID
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
									text: '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Close&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;',
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
			newItem() {
				this.dialog = true
			},
			closeDialogDeleteConfirm() {
				this.dialogConfirmDelete = false
				this.ThanhVienNCKHObj = Object.assign({}, this.ThanhVienNCKHObj_Default)
				this.editedIndex = -1
			},
			closeDialog() {
				this.dialog = false
				this.ThanhVienNCKHObj = Object.assign({}, this.ThanhVienNCKHObj_Default)
				this.editedIndex = -1
			},
			editedItem(item) {
				this.dialog = true
				this.editedIndex = this.value.indexOf(item)
				this.ThanhVienNCKHObj = Object.assign({}, item)
			},
			insert_TVDeTai() {
				if (this.editedIndex === -1) {
					if (!this.DeTaiNCKHID) {
						this.value.push(this.ThanhVienNCKHObj)
					} else {
						this.API_Insert_ThanhVienDeTai()
					}
					Vue.$toast.success("Thêm thành viên thành công!", { position: "top" })
				} else {
					if (!this.DeTaiNCKHID) {
						Object.assign(this.value[this.editedIndex], this.ThanhVienNCKHObj)
					} else {
						this.API_Update_ThanhVienDeTai()
					}
					Vue.$toast.success("Cập nhật thành viên thành công!", { position: "top" })
				}
				this.closeDialog()
			},
			delete_TVDeTai_Confirm() {
	
				if (!this.DeTaiNCKHID) {
					this.value.splice(this.editedIndex, 1)
				} else {
					this.API_Delete_ThanhVienDeTai()
				}
				this.closeDialogDeleteConfirm()
	
			},
			delete_TVDeTai(item) {
				this.dialogConfirmDelete = true
				this.ThanhVienNCKHObj = Object.assign({}, item)
				this.editedIndex = this.value.indexOf(item)
			},
			API_Insert_ThanhVienDeTai() {
				ajaxCALL("/NCKH_ThanhVien_Ins_Obj", {
					DeTaiNCKHID: this.DeTaiNCKHID,
					ThanhVienNCKHObj: this.ThanhVienNCKHObj
				}, res => {
					this.API_Reload_ThanhVienDeTai()
					console.log(res.data)
				}, err => {
					console.log(err)
				})
			},
			API_Delete_ThanhVienDeTai() {
				ajaxCALL("/NCKH_ThanhVien_Del_Obj", {
					ThanhVienNCKHObj: this.ThanhVienNCKHObj
				}, res => {
					this.API_Reload_ThanhVienDeTai()
					Vue.$toast.success("Xóa thành viên thành công!", { position: "top" })
					console.log(res.data)
				}, err => {
					console.log(err)
				})
			},
			API_Update_ThanhVienDeTai() {
				ajaxCALL("/NCKH_ThanhVien_Upd_Obj", {
					ThanhVienNCKHObj: this.ThanhVienNCKHObj
				}, res => {
					this.API_Reload_ThanhVienDeTai()
					console.log(res.data)
				}, err => {
					console.log(err)
				})
			},
			API_Reload_ThanhVienDeTai() {
				ajaxCALL("/NCKH_Get_ByID", {
					DeTaiNCKHID: this.DeTaiNCKHID
				}, (res) => {
					this.$emit("input", res.data[1])
				}, err => {
					console.log(err)
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
						Vue.$toast.error(error)
					},
					complete: function (data) {
						vueData.v_Loading = false;
					}
				});
			},
			checkboxGV() {
				this.ThanhVienNCKHObj.Is_SinhVien = !this.ThanhVienNCKHObj.Is_ChuNhiem
			},
			checkboxSV() {
				this.ThanhVienNCKHObj.Is_ChuNhiem = !this.ThanhVienNCKHObj.Is_SinhVien
			},
			clearLopID() {
				this.ThanhVienNCKHObj.LopID = ""
			},
			clearNganHang() {
				this.ThanhVienNCKHObj.NganHang = ""
				this.ThanhVienNCKHObj.SoTaiKhoan = ""
				this.ThanhVienNCKHObj.TenChuTaiKhoan = ""
			}
		},
	}
</script>