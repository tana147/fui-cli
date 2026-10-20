<template>
	<div>
		<v-data-table class="elevation-1" :items="DS_CBGVNV" :headers="headers">
			<template v-slot:top>
				<v-toolbar flat>
					<v-toolbar-title class="primary--text font-weight-medium">
						Danh sách CBGVNV sử dụng thẻ ngân hàng SHB
					</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-dialog v-model="dialog" max-width="500px">
						<template v-slot:activator="{ on, attrs }">
							<v-btn color="success" fab x-small outlined class="mb-2" @click="newItem">
								<v-icon>mdi-plus</v-icon>
							</v-btn>
						</template>
						<v-card>
							<v-card-title>
								<h4 class="primary--text">Tạo mới thông tin</h4>
							</v-card-title>
							<v-card-text>
								<form class="mt-3">
									<v-row dense>
										<v-col cols="12">
											<v-text-field label="Mã nhân viên" v-model="emp_obj.MaNV" outlined dense
												hide-details></v-text-field>
										</v-col>
										<v-col cols="6" class="mt-3">
											<v-text-field label="Họ nhân viên" v-model="emp_obj.HoNV" outlined dense
												hide-details></v-text-field>
										</v-col>
										<v-col cols="6" class="mt-3">
											<v-text-field label="Tên nhân viên" v-model="emp_obj.TenNV" outlined dense
												hide-details></v-text-field>
										</v-col>
										<v-col cols="6" class="mt-3">
											<v-text-field label="Tên thẻ ngân hàng" v-model="emp_obj.TenThe" outlined
												dense hide-details></v-text-field>
										</v-col>
										<v-col cols="6" class="mt-3">
											<v-text-field label="Số tài khoản" v-model="emp_obj.SoTaiKhoan" outlined
												dense hide-details></v-text-field>
										</v-col>
										<v-col cols="12" class="mt-3">
											<v-checkbox color="green" v-model="emp_obj.Is_register"
												label="Đã đăng ký thành công dịch vụ miễn phí chuyển khoản"></v-checkbox>
										</v-col>
										<v-col cols="4" class="mt-3" v-show="emp_obj.Is_register === true">
											<v-text-field label="Tháng đăng ký" v-model="emp_obj.ThangDangKy" outlined
												dense hide-details></v-text-field>
										</v-col>
										<v-col cols="4" class="mt-3" v-show="emp_obj.Is_register === true">
											<v-text-field label="Năm đăng ký" v-model="emp_obj.NamDangKy" outlined dense
												hide-details></v-text-field>
										</v-col>
									</v-row>
								</form>
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn color="warning" @click="closeDialog">Đóng</v-btn>
								<v-btn color="success" @click="insert_emp">Lưu</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
				</v-toolbar>
			</template>
			<template v-slot:item.Is_register="{item}">
				<div class="d-flex justify-center">
					<v-icon v-if="item.Is_register" color="success">mdi-check</v-icon>
				</div>
			</template>
			<template v-slot:item.actions="{ item }">
				<div style="display:flex; justify-content:center">
					<v-icon style="font-size:18px" color="red darken-3" small class="mr-2" @click="delete_emp(item)">
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
		props: [],
		data() {
			return {
				dialog: false,
				headers: [
					{ text: "Mã nhân viên", value: "MaNV" },
					{ text: "Họ", value: "HoNV" },
					{ text: "Tên", value: "TenNV" },
					{ text: "Tên thẻ", value: "TenThe" },
					{ text: "Tài khoản", value: "SoTaiKhoan" },
					{ text: "Đã đăng ký thành công dịch vụ miễn phí chuyển khoản", value: "Is_register", align: "center" },
					{ text: "Tháng", value: "ThangDangKy" },
					{ text: "Năm", value: "NamDangKy" },
					{ text: "Thao tác", value: "actions", align: "center" },
				],
				DS_CBGVNV: [
					{
						MaNV: "NV0001098",
						HoNV: "Au Chí",
						TenNV: "Cang",
						TenThe: "AU CHI CANG",
						SoTaiKhoan: 1019720697,
						Is_register: null,
						ThangDangKy: 8,
						NamDangKy: 2022
					}
				],
				emp_obj: {
					MaNV: "",
					HoNV: "",
					TenNV: "",
					TenThe: "",
					SoTaiKhoan: null,
					Is_register: null,
					ThangDangKy: null,
					NamDangKy: null
				},
				default_emp_obj: {
					MaNV: "",
					HoNV: "",
					TenNV: "",
					TenThe: "",
					SoTaiKhoan: null,
					Is_register: null,
					ThangDangKy: null,
					NamDangKy: null
				},
				editedIndex: -1,
			}
		},
		mounted() { },
		computed: {},
		watch: {
			dialog: function (val) {
				val || this.closeDialog()
			}
		},
		methods: {
			newItem() {
				this.dialog = true
			},
			closeDialog() {
				this.dialog = false
				this.emp_obj = Object.assign({}, this.default_emp_obj)
				this.editedIndex = -1
				console.log("value", this.emp_obj)
			},
			insert_emp() {
				if(this.editedIndex !== -1){
					Object.assign(this.DS_CBGVNV[this.editedIndex], this.emp_obj)
				}else{
					this.DS_CBGVNV.push(this.emp_obj)
				}
				this.closeDialog()
			},
			delete_emp(item) {
				this.editedIndex = this.DS_CBGVNV.indexOf(item)
				this.DS_CBGVNV.splice(this.editedIndex, 1)
			},
			editedItem(item){
				this.dialog=true
				this.editedIndex = this.DS_CBGVNV.indexOf(item)
				this.emp_obj = Object.assign({}, item)
				console.log("value 1", item)
			}
		}
	}
</script>