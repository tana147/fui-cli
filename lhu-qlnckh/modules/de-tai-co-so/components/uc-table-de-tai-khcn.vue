<template>
	<div>
		<v-card>
			<v-card-title>
				<span class="primary--text text-h5 font-weight-medium">
					Danh sách đề tài KHCN cấp cơ sở
				</span>
				<v-spacer></v-spacer>
				<v-text-field class="me-5" v-model="search" prepend-icon="mdi-magnify" label="Tìm kiếm" single-line
					dense hide-details style="max-width:400px"></v-text-field>
				<v-btn color="success" fab x-small outlined class="mb-2" @click="newItem">
					<v-icon>mdi-plus</v-icon>
				</v-btn>
				<v-dialog v-model="dialog" max-width="1400px">
					<v-card>
						<v-card-title>
							<span class="text-h5 primary--text font-weight-medium">{{ TitleDialog }}</span>
							<v-spacer></v-spacer>
							<v-btn fab small icon @click="closeDialog">
								<v-icon>mdi-close</v-icon>
							</v-btn>
						</v-card-title>
						<v-card-text class="mt-3">
							<form>
								<v-row dense>
									<v-col cols="3">
										<v-autocomplete :items="DM_KHCN" label="Nhóm đề tài" :item-text="BindingText"
											item-value="NhomKHCNID" v-model="DeTai_Obj.NhomKHCNID" outlined dense
											hide-details></v-autocomplete>
									</v-col>
									<v-col cols="2">
										<v-text-field label="Mã số" v-model="DeTai_Obj.MaSoDeTai" outlined dense
											hide-details></v-text-field>
									</v-col>
									<v-col cols="3">
										<v-autocomplete label="Đơn vị" v-model="DeTai_Obj.DonVi" :items="Don_Vi"
											outlined dense hide-details>
										</v-autocomplete>
									</v-col>
									<v-col cols="4"></v-col>
									<v-col cols="6" class="mt-3">
										<v-text-field label="Tên đề tài (Tiếng Việt)"
											v-model="DeTai_Obj.TenDeTaiKHCN_Vi" outlined dense
											hide-details></v-text-field>
									</v-col>
									<v-col cols="6" class="mt-3">
										<v-text-field label="Tên đề tài (Tiếng Anh)" v-model="DeTai_Obj.TenDeTaiKHCN_En"
											outlined dense hide-details>
										</v-text-field>
									</v-col>
									<v-col cols="2" class="mt-3">
										<v-combobox label="Năm đăng ký" :items="Nam" v-model="DeTai_Obj.NamDangKy"
											outlined dense hide-details></v-combobox>
									</v-col>
									<v-col cols="2" class="mt-3">
										<v-combobox label="Năm thực hiện" :items="Nam" v-model="DeTai_Obj.NamThucHien"
											outlined dense hide-details>
										</v-combobox>
									</v-col>
									<v-col cols="2" class="mt-3">
										<v-text-field label="Tháng bắt đầu" v-model="DeTai_Obj.ThangBatDau" outlined
											dense hide-details></v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-combobox :items="Thang" label="Số tháng thực hiện (dự tính)"
											v-model="DeTai_Obj.SoThangThucHien" outlined dense
											hide-details></v-combobox>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Tháng kết thúc (dự tính)" v-model="DeTai_Obj.ThangKetThuc"
											outlined dense hide-details>
										</v-text-field>
									</v-col>

									<v-col cols="3" class="mt-3">
										<v-text-field label="Ngày nghiệm thu (dự tính)"
											v-model="DeTai_Obj.NgayNghiemThu" outlined dense
											hide-details></v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Số tiền" class="text-input-right" prefix="VNĐ" reverse
											v-model="KinhPhi_Format" outlined dense hide-details>
										</v-text-field>
									</v-col>
									<v-col cols="6" class="mt-3">
										<v-text-field outlined label="Ghi chú" v-model="DeTai_Obj.GhiChu" dense
											hide-details>
										</v-text-field>
									</v-col>
									<v-col cols="12" class="mt-3">
										<h3 class="primary--text font-weight-medium">
											Sản phẩm khoa học dự kiến
										</h3>
									</v-col>
									<v-col cols="6" class="mt-3">
										<v-data-table class="elevation-2 ps-5 pe-5" hide-default-footer
											:headers="headers_LoaiBaiBao" :items="DS_LoaiBaiBao_Table">
											<template v-slot:top>
												<v-toolbar flat height="100px">
													<v-row dense class="mt-2">
														<v-col cols="6" dense>
															<v-select v-model="LoaiBaiBao_Obj.TenSanPhamDuKien"
																:items="DS_LoaiBaiBao" label="Sản phẩm khoa học dự kiến"
																outlined dense hide-details></v-select>
														</v-col>
														<v-col cols="3" dense>
															<v-text-field label="Số bài báo"
																v-model="LoaiBaiBao_Obj.SoLuong" outlined dense
																hide-details></v-text-field>
														</v-col>
														<v-col cols="3" dense>
															<v-btn color="primary" @click="add_LoaiBaiBao"
																outlined>Thêm</v-btn>
														</v-col>
														<v-col cols="6"
															v-if="LoaiBaiBao_Obj.TenSanPhamDuKien === 'Khác'" dense>
															<v-text-field v-model="SanPhamDuKienKhac"
																label="Sản phẩm khác" outlined dense
																hide-details></v-text-field>
														</v-col>
													</v-row>
												</v-toolbar>
											</template>
											<template v-slot:item.actions="{ item }">
												<div style="display:flex; justify-content:center">
													<v-icon style="font-size:18px" color="red darken-3" small
														class="mr-2" @click="delete_LoaiBaiBao(item)">
														mdi-trash-can-outline
													</v-icon>
												</div>
											</template>
										</v-data-table>
									</v-col>

								</v-row>
							</form>
							<uc-table-chu-nhiem-de-tai v-model="ThanhVienKHCN_Obj" class="mt-4"
								:iddetai="DeTai_Obj.DeTaiKHCNID"></uc-table-chu-nhiem-de-tai>
						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="closeDialog">Đóng</v-btn>
							<v-btn color="primary" @click="insert_DeTai">{{ editedIndex === -1 ? "Thêm mới" :
								"Cập nhật" }}</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
				<v-dialog v-model="dialogTienDo" max-width="800px" max-height="400px">
					<v-card>
						<v-card-title class="primary--text font-weight-medium">
							Tiến độ xét duyệt kinh phí
							<v-spacer></v-spacer>
							<v-btn fab small icon @click="closeDialogTienDo">
								<v-icon>mdi-close</v-icon>
							</v-btn>
						</v-card-title>

						<v-card-text class="mt-5">
							<uc-table-tien-do-kinh-phi v-model="DS_TienDo"
								:iddetai="DeTaiKHCNID"></uc-table-tien-do-kinh-phi>
						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="closeDialogTienDo">Đóng</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>

				<v-dialog v-model="dialogSQD" max-width="1200px">
					<v-card>
						<v-card-title>
							<span class="text-h5 primary--text font-weight-medium">Quản lý số quyết định cấp kinh
								phí</span>
							<v-spacer></v-spacer>
							<v-btn fab small icon @click="closeDialogSQD">
								<v-icon>mdi-close</v-icon>
							</v-btn>
						</v-card-title>
						<v-card-text class="mt-3">
							<uc-table-so-quyet-dinh></uc-table-so-quyet-dinh>
						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="closeDialogSQD">Đóng</v-btn>
							<v-btn color="primary">Lưu</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
			</v-card-title>
			<v-card-text>
				<v-data-table :items="DS_DeTai" :search="search" :headers="headers"
					:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" class="custom-table">
					<template v-slot:item.tiendoxetduyetkinhphi="{ item }">
						<v-btn color="green" @click="btn_TienDo(item)" text>Xem tiến độ</v-btn>
					</template>
					<template v-slot:item.thoigianthuchien="{ item }">
						<div class="d-flex flex-column align-center ">
							<p>{{ item.ThangThucHien }} tháng</p>
							<p>{{ item.NgayBatDauNC }} - {{ item.NgayHoanThanhNC }}</p>
						</div>
					</template>
					<template v-slot:item.spkhdukien="{ item }">
						<p>{{ item.SPKHDuKien }}</p>
					</template>
					<template class="d-flex" v-slot:item.sotien="{ item }">
						<p style="text-align: right;">{{ formatAsCurrency(item.SoTien) }} VNĐ</p>
					</template>
					<template v-slot:item.actions="{ item }">
						<div style="display:flex; justify-content:center">
							<v-icon style="font-size:18px" color="red darken-3" small class="mr-2"
								@click="delete_DeTai(item)">
								mdi-trash-can-outline
							</v-icon>
							<v-icon style="font-size:18px;" color="green darken-2" small class="mr-2"
								@click="editedItem(item)">
								mdi-square-edit-outline
							</v-icon>
						</div>
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>

	</div>
</template>

<script>
export default {
	props: ["dsdanhmuckhoahoccongnghe", "dsdetai"],
	data() {
		return {
			dialogSQD: false,
			SanPhamDuKienKhac: '',
			dialogTienDo: false,
			dialog: false,
			search: "",
			dialogConfirmDelete: false,
			editedIndex: -1,
			headers: [
				{ text: "Nhóm đề tài", value: "TenNhomKHCN", sortable: false, width: "170" },
				{ text: "Mã số", value: "MaSoDeTai", sortable: false, width: "170" },
				{ text: "Tên đề tài", value: "TenDeTaiKHCN_Vi", sortable: false, width: '300' },
				{ text: "Tác giả/ nhóm tác giả", value: "TacGia", sortable: true, width: "300" },
				{ text: "Đơn vị", value: "DonVi", sortable: true, width: "150" },
				{ text: "Số tiền", value: "sotien", sortable: false, width: "150" },
				{ text: "Tiến độ duyệt kinh phí", value: "tiendoxetduyetkinhphi", sortable: false, width: "100" },
				{ text: "Năm đăng ký", value: "NamDangKy", sortable: true, align: "center", width: "150" },
				{ text: "Năm thực hiện", value: "NamThucHien", sortable: true, align: "center", width: "150" },
				{ text: "Tháng bắt đầu", value: "ThangBatDau", sortable: false, align: "center", width: "150" },
				{ text: "Tháng kết thúc", value: "ThangKetThuc", sortable: false, align: "center", width: "150" },
				{ text: "Thao tác", value: "actions", sortable: false, align: "center" },
			],
			headers_LoaiBaiBao: [
				{ text: "Loại bài báo", value: "TenSanPhamDuKien", sortable: false },
				{ text: "Số lượng bài báo", value: "SoLuong", align: "center", sortable: false },
				{ text: "Thao tác", value: "actions", sortable: false, align: "center" },
			],

			DeTai_Obj: {
				NhomKHCNID: null,
				TenDeTaiKHCN_Vi: "",
				TenDeTaiKHCN_En: "",
				MaSoDeTai: "LHU-",
				DonVi: "",
				NamDangKy: null,
				SoThangThucHien: null,
				GhiChu: "",
				ThangBatDau: null,
				ThangKetThuc: null,
				NamThucHien: null,
				NgayNghiemThu: null,
				SoTien: null,
			},
			DeTai_Obj_default: {
				NhomKHCNID: null,
				TenDeTaiKHCN_Vi: "",
				TenDeTaiKHCN_En: "",
				MaSoDeTai: "LHU-",
				DonVi: "",
				NamDangKy: null,
				SoThangThucHien: null,
				GhiChu: "",
				ThangBatDau: null,
				ThangKetThuc: null,
				NamThucHien: null,
				NgayNghiemThu: null,
				SoTien: null,
			},
			TienDoKHCH_obj: {
				TienDoID: 1,
				SoTT: 1,
				SoTien: 500000,
				GhiChu: "Chưa xác định UI"
			},
			LoaiBaiBao_Obj: {
				TenSanPhamDuKien: "",
				SoLuong: null
			},
			LoaiBaiBao_Obj_default: {
				TenSanPhamDuKien: "",
				SoLuong: null
			},
			DS_LoaiBaiBao_Table: [],
			DS_LoaiBaiBao_Table_default: [],
			ThanhVienKHCN_Obj: [],
			ThanhVienKHCN_Obj_default: [],
			DS_LoaiBaiBao: ["Tạp chí Lạc Hồng", "Quốc tế", "Hội đồng Giáo sư Nhà nước",
				"Hội thảo", "Tạp chí Quốc tế", "Quốc tế (ISI/Scopus)", "Quốc tế (Hội thảo)", "Khác"
			],
			Nam: [2020, 2021, 2022, 2023, 2024],
			Thang: [6, 8, 12, 24],
			Don_Vi: [
				"Công nghệ thông tin", "Cơ điện - Điện tử", "Kỹ thuật công trình", "Quản trị - Kinh tế quốc tế",
				"Kế toán", "Ngôn ngữ Anh", "Dược", "Đông phương học",
				"Trung tâm Thông tin tư liệu", "Sau đại học", "Phòng Quan hệ quốc tế", "TT NCKH&ƯD",
				"Khoa học và Công nghệ Thực phẩm", "Phòng Khảo thí và Đảm bảo chất lượng",
				"Trung tâm tin học và ngoại ngữ", "Trung tâm Tuyển sinh và Quan hệ công chúng", "Phòng Hành chính - Tổ chức"
			],
			DS_TienDo: [],
			DS_TienDo_Default: [],
			DeTaiKHCNID: null,


		}
	},
	mounted() { },
	computed: {
		TitleDialog: function () {
			return this.editedIndex === -1 ? "Thêm mới đề tài KHCN" : "Chỉnh sửa đề tài KHCN " + this.DeTai_Obj.MaSoDeTai ?? ''
		},
		DM_KHCN() {
			return this.dsdanhmuckhoahoccongnghe
		},
		DS_DeTai() {
			return this.dsdetai
		},
		KinhPhi_Format: {
			get: function () {
				return formatAsCurrency(this.DeTai_Obj.SoTien, 0)
			},
			set: function (newValue) {
				this.DeTai_Obj.SoTien = Number(newValue.replace(/[^0-9\.]/g, ''));
			}
		},
	},
	watch: {
		dialog: function (val) {
			val || this.closeDialog();
		}
	},
	methods: {
		BindingText(item) {
			let text = item.MaNhomKHCN + " - " + item.TenNhomKHCN
			return text
		},
		btn_TienDo(item) {
			this.dialogTienDo = true
			this.DeTaiKHCNID = item.DeTaiKHCNID
			ajaxCALL("/KHCN_TienDo_Get_ByID", {
				DeTaiKHCNID: item.DeTaiKHCNID
			}, res => {
				this.DS_TienDo = res.data
			}, err => {
				console.log(err)
			})
		},
		closeDialogDeleteConfirm() {
			this.dialogConfirmDelete = false
		},
		closeDialogTienDo() {
			this.dialogTienDo = false
		},
		closeDialog() {
			this.dialog = false
			this.DeTai_Obj = Object.assign({}, this.DeTai_Obj_default)
			this.ThanhVienKHCN_Obj = Object.assign([], this.ThanhVienKHCN_Obj_default)
			this.DS_LoaiBaiBao_Table = Object.assign([], this.DS_LoaiBaiBao_Table_default)
			this.DS_TienDo = Object.assign([], this.DS_TienDo_Default)
			this.editedIndex = -1
		},
		openDialogSQD() {
			this.dialogSQD = true
		},
		closeDialogSQD() {
			this.dialogSQD = false
		},
		newItem() {
			this.dialog = true
		},
		editedItem(item) {
			this.dialog = true
			this.editedIndex = this.DS_DeTai.indexOf(item)
			ajaxCALL("/KHCN_Get_ByID", {
				DeTaiKHCNID: item.DeTaiKHCNID
			}, res => {
				this.DeTai_Obj = res.data[0][0]
				this.DS_LoaiBaiBao_Table = res.data[3]
				this.ThanhVienKHCN_Obj = res.data[1]
			}, err => {
				console.log("Lỗi", err)
			})
		},
		insert_DeTai() {
			if (this.editedIndex === -1) {
				if (this.ThanhVienKHCN_Obj.length === 0) {
					return Vue.$toast.warning("Vui lòng thêm ít nhất 1 thành viên", { position: "top" })
				} else if (this.DeTai_Obj.NhomKHCNID === null || this.DeTai_Obj.NhomKHCNID === "") {
					return Vue.$toast.warning("Vui lòng chọn nhóm đề tài", { position: "top" })
				}
				this.API_Insert_DeTai()
			} else {
				if (this.ThanhVienKHCN_Obj.length === 0) {
					return Vue.$toast.warning("Vui lòng thêm ít nhất 1 thành viên", { position: "top" })
				}
				this.API_Update_DeTai()
			}
		},
		delete_DeTai(item) {
			this.DeTai_Obj = Object.assign({}, item)
			const $this = this
			confirm({
				title: "Xác nhận",
				content: `Xác nhận xóa bài báo`,
				action: function () {
					ajaxCALL("/KHCN_Del", {
						DeTaiKHCNID: $this.DeTai_Obj.DeTaiKHCNID
					}, res => {
						CALL("LoadKHCNGet")
						Vue.$toast.success("Xóa đề tài thành công!", { position: "top" })
					}, err => {
						console.log("Lỗi xóa đề tài", err)
					})
					$this.DeTai_Obj = Object.assign({}, $this.DeTai_Obj_default)
					$this.dialogConfirmDelete = false
				}
			});
		},
		add_LoaiBaiBao() {
			if (this.LoaiBaiBao_Obj.TenSanPhamDuKien === 'Khác') {
				this.LoaiBaiBao_Obj.TenSanPhamDuKien = this.SanPhamDuKienKhac
			}
			if (!this.DeTai_Obj.DeTaiKHCNID) {
				this.DS_LoaiBaiBao_Table.push(this.LoaiBaiBao_Obj)
			} else {
				ajaxCALL("/KHCN_SanPham_Ins_Obj", {
					DeTaiKHCNID: this.DeTai_Obj.DeTaiKHCNID,
					SanPhamKHCNObj: this.LoaiBaiBao_Obj
				}, res => {
					this.API_Reload_CTDeTai()
				}, err => {
				})
			}
			this.SanPhamDuKienKhac = ''
			this.LoaiBaiBao_Obj = Object.assign({}, this.LoaiBaiBao_Obj_default)
		},
		delete_LoaiBaiBao(item) {
			if (!this.DeTai_Obj.DeTaiKHCNID) {
				this.DS_LoaiBaiBao_Table.splice(this.editedIndex, 1)
			} else {
				ajaxCALL("/KHCN_SanPham_Del_Obj", {
					SanPhamKHCNObj: item
				}, res => {
					Vue.$toast.success("Xóa thành công", { position: "top" })
					this.API_Reload_CTDeTai()
				}, err => {
				})
			}
		},
		API_Insert_DeTai() {
			ajaxCALL("/KHCN_Ins_Obj", {
				DeTaiKHCNObj: this.DeTai_Obj,
				ThanhVienKHCNObj: this.ThanhVienKHCN_Obj,
				SanPhamKHCNObj: this.DS_LoaiBaiBao_Table,
				TienDoKHCNObj: this.DS_TienDo,
			}, (res) => {
				this.closeDialog()
				Vue.$toast.success("Thêm thành công", { position: "top" })
				CALL("LoadKHCNGet")
			}, (err) => {
				Vue.$toast.warning("Thêm thất bại", { position: "top" })
			})
		},
		API_Update_DeTai() {
			ajaxCALL("/KHCN_Upd_Obj", {
				DeTaiKHCNID: this.DeTai_Obj.DeTaiKHCNID,
				DeTaiKHCNObj: this.DeTai_Obj,
				ThanhVienKHCNObj: this.ThanhVienKHCN_Obj,
				SanPhamKHCNObj: this.DS_LoaiBaiBao_Table,
				TienDoKHCNObj: this.TienDoKHCH_obj,
			}, (res) => {
				this.closeDialog()
				Vue.$toast.success("Cập nhật thành công", { position: "top" })
				CALL("LoadKHCNGet")
			}, (err) => {
				Vue.$toast.warning("Cập nhật thất bại", { position: "top" })
			})
		},
		API_Reload_CTDeTai() {
			ajaxCALL("/KHCN_SanPham_Get_ByID", {
				DeTaiKHCNID: this.DeTai_Obj.DeTaiKHCNID
			}, (res) => {
				this.DS_LoaiBaiBao_Table = res.data
			}, (err) => {
				console.log("err", err)
			})
		}
	},
}
</script>
<style scoped></style>