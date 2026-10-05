<template>
	<div>
		<v-card class="elevation-0">
			<v-card-title>
				<span class="primary--text font-weight-medium">
					Kết quả hội đồng đánh giá
				</span>
				<v-select v-model="SelectedDotID" class="ms-3" label="Hội đồng" :items="DSDot" :item-text="displayText"
					item-value="DotId" @change="API_GetNCKH_ByDotID" outlined dense hide-details
					style="max-width:500px">
					<template v-slot:append-outer>
						<div class="mt-0">
							<v-icon color="green darken-2" title="Quản lý đợt Hội đồng" @click="onEditHoiDong()">
								mdi-cog-outline
							</v-icon>
						</div>
					</template>
				</v-select>
				<uc-hoidong-manage v-model="hoiDongManageDialog" @on-dot-changed="$emit('on-dot-changed')" />
				<v-spacer></v-spacer>
				<v-text-field class="me-5" v-model="search" style="max-width:400px" prepend-icon="mdi-magnify"
					label="Search" single-line dense hide-details>
				</v-text-field>
				<v-btn color="success" fab x-small outlined class="mb-2" @click="openDialog()">
					<v-icon>mdi-plus</v-icon>
				</v-btn>
				<v-dialog v-model="dialog" max-width="1300px">
					<template v-slot:activator="{ on, attrs }">

					</template>
					<v-card>
						<v-card-title>
							<span class="text-h5 primary--text font-weight-medium">{{ dialogTitle }}</span>
							<v-spacer></v-spacer>
							<v-btn fab small icon @click="closeDialog">
								<v-icon>mdi-close</v-icon>
							</v-btn>
						</v-card-title>
						<v-card-text class="mt-3">
							<v-form ref="formRef">
								<v-row dense>
									<v-col cols="3">
										<v-select label="Khoa" :items="DSKhoaNCKH" v-model="DeTaiNCKHObj.KhoaID"
											:item-text="displayTextKhoa" outlined dense hide-details
											item-value="KhoaID">
										</v-select>
									</v-col>
									<v-col cols="9">
										<v-text-field label="Tên đề tài" v-model="DeTaiNCKHObj.TenDeTaiNCKH" outlined
											hide-details dense></v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Tiểu ban" v-model="DeTaiNCKHObj.TieuBan" outlined
											hide-details dense>
										</v-text-field>
									</v-col>
									<v-col cols="4" class="mt-3">
										<v-text-field label="Sản phẩm dự kiến" v-model="DeTaiNCKHObj.MoTa_SanPham"
											outlined hide-details dense></v-text-field>
									</v-col>
									<v-col cols="5" class="mt-3"></v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Điểm TV1" v-model="DeTaiNCKHObj.DiemDG1" outlined
											hide-details dense>
										</v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Điểm TV2" v-model="DeTaiNCKHObj.DiemDG2" outlined
											hide-details dense>
										</v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Điểm TV3" v-model="DeTaiNCKHObj.DiemDG3" outlined
											hide-details dense>
										</v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Điểm TV4" v-model="DeTaiNCKHObj.DiemDG4" outlined
											hide-details dense>
										</v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Điểm TV5" v-model="DeTaiNCKHObj.DiemDG5" outlined
											hide-details dense>
										</v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Điểm PB" v-model="DeTaiNCKHObj.DiemPB1" outlined
											hide-details dense>
										</v-text-field>
									</v-col>
									<v-col cols="3" class="mt-3">
										<v-text-field label="Điểm DGTB" v-model="DeTaiNCKHObj.DiemDGTB" outlined
											hide-details dense>
										</v-text-field>
									</v-col>
								</v-row>
							</v-form>
							<uc-table-thanh-vien-de-tai v-model="ThanhVienNCKHObj" class="mt-5"
								:iddetai="DeTaiNCKHObj.DeTaiNCKHID">
							</uc-table-thanh-vien-de-tai>
						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="closeDialog">Đóng</v-btn>
							<v-btn v-if="editedIndex === -1" color="primary" @click="Insert_DeTaiObj">Thêm mới</v-btn>
							<v-btn v-else color="primary" @click="Insert_DeTaiObj">Cập nhật</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
				<v-dialog v-model="dialogDelete" max-width="500px">
					<v-card>
						<v-card-title>
							<span class="text-h5 primary--text">Bạn có chắc chắc muốn xóa đề tài?</span>
						</v-card-title>
						<v-card-text class="mt-3">

						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="closeDialogDelete">Đóng</v-btn>
							<v-btn color="primary" @click="deleteItemConfirm">Xác nhận</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
			</v-card-title>
			<v-card-text>
				<v-data-table class="elevation-1" :items="DSDeTai" :search="search" :headers="headers"
					:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }">
					<!-- <template v-slot:header.diemdanhgia={ header }>
						<span>Điểm đánh giá</span>
						<v-row>
							<v-col cols="3">TV1</v-col>
							<v-col cols="3">TV2</v-col>
							<v-col cols="3">TV3</v-col>
							<v-col cols="3">PB</v-col>
						</v-row>
					</template>  -->

					<template v-slot:item.diemdanhgia="{ item }">
						<v-row>
							<v-col cols="3">{{ convertDiem(item.DiemDG1) }}</v-col>
							<v-col cols="3">{{ convertDiem(item.DiemDG2) }}</v-col>
							<v-col cols="3">{{ convertDiem(item.DiemDG3) }}</v-col>
							<v-col cols="3">{{ convertDiem(item.DiemPB1) }}</v-col>
						</v-row>
					</template>
					<template v-slot:item.diemtbbc="{ item }">
						<span>{{ convertDiem(item.DiemDGTB) }}</span>
					</template>
					<template v-slot:item.actions="{ item }">
						<div style="display:flex; justify-content:center">
							<v-icon style="font-size:18px" color="red darken-3" small class="mr-2"
								@click="openDialogDelete(item)">
								mdi-trash-can-outline
							</v-icon>
							<v-icon style="font-size:18px" color="green darken-2" small class="mr-2"
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
		props: ["dsdot", "dsloaihoidong", "dsdetai", "dskhoanckh"],
	emits: ['on-dot-changed'],
	data() {
		return {
			optionItemPerPage: [50, 100, 150, -1],
			search: '',
			dialog: false,
			dialogDelete: false,
			hoiDongManageDialog: false,
			Khoa_Arr: ["TC-KT", "QT-KTQT"],
			headers: [
				{ text: "Tên đề tài", value: "TenDeTaiNCKH", sortable: false, width: "400" },
				{ text: "Khoa", value: "KhoaID", sortable: false },
				{ text: "Tên sinh viên NCKH", value: "SinhVien", sortable: false, width: "400" },
				{ text: "Tên GVHD", value: "GiaoVien", sortable: false, },
				{ text: "Điểm TBBC", value: "diemtbbc", align: "center", sortable: false },
				{ text: "Sản phẩm ", value: "MoTa_SanPham", align: "center", sortable: false },
				{ text: "Thao tác", value: "actions", align: "center", sortable: false }
			],
			DeTaiNCKHObj: {
				DotID: null,
				KhoaID: "",
				TenDeTaiNCKH: "",
				DiemDG1: null,
				DiemDG2: null,
				DiemDG3: null,
				DiemDG4: null,
				DiemDG5: null,
				DiemDG6: null,
				DiemPB1: null,
				DiemPB2: null,
				DiemDGTB: convertDiem(0),
				TieuBan: "",
				MoTa_SanPham: ""

			},
			DeTaiNCKHObj_Default: {
				DotID: null,
				KhoaID: "",
				TenDeTaiNCKH: "",
				DiemDG1: null,
				DiemDG2: null,
				DiemDG3: null,
				DiemDG4: null,
				DiemDG5: null,
				DiemDG6: null,
				DiemPB1: null,
				DiemPB2: null,
				DiemDGTB: convertDiem(0),
				TieuBan: "",
				MoTa_SanPham: ""
			},
			ThanhVienNCKHObj: [],
			ThanhVienNCKHObj_Default: [],
			editedIndex: -1,
			DeTaiID: null,
			DSDeTai: [],
			SelectedDotID: null
		}
	},
	mounted() { },
	computed: {
		DSDot: function () {
			return this.dsdot
		},
		DSLoaiHoiDong: function () {
			return this.dsloaihoidong
		},

		dialogTitle: function () {
			return this.editedIndex === -1 ? "Thêm đề tài nghiên cứu khoa học" : "Chi tiết đề tài nghiên cứu khoa học"
		},
		DSKhoaNCKH: function () {
			return this.dskhoanckh
		}

	},
	watch: {
		dialog: function (val) {
			val || this.closeDialog()
		},
		dialogDelete: function (val) {
			val || this.closeDialogDelete()
		}


	},
	methods: {
		displayTextKhoa: function (item) {
			let text = item.KhoaID + " - " + item.TenKhoa
			return text
		},
		displayText: function (item) {
			let text = item.TenDot + " (NH " + item.NamHoc + ")"
			return text
		},
		openDialog() {
			if (this.SelectedDotID === null) {
				return Vue.$toast.warning("Vui lòng chọn đợt hội đồng", { position: "top" })
			}
			this.GetDiemDGTB()
			this.dialog = true

		},
		openDialogDelete(item) {
			this.dialogDelete = true
			this.DeTaiID = item.DeTaiNCKHID
		},
		closeDialog() {
			this.dialog = false
			// this.DeTaiNCKHObj = Object.assign({}, this.DeTaiNCKHObj_Default)
			// this.ThanhVienNCKHObj = Object.assign([], this.ThanhVienNCKHObj_Default)
			this.$refs.formRef.reset()
			this.editedIndex = -1
		},
		editedItem(item) {
			this.dialog = true
			this.API_Get_CTDeTai_By_DeTaiID(item.DeTaiNCKHID)
			this.editedIndex = this.DSDeTai.indexOf(item)
		},

		deleteItemConfirm() {
			this.API_Delete_DeTaiKhenThuong()
			this.closeDialogDelete()
		},
		closeDialogDelete() {
			this.dialogDelete = false
			this.DeTaiNCKHObj = Object.assign({}, this.DeTaiNCKHObj_Default)
			this.ThanhVienNCKHObj = Object.assign([], this.ThanhVienNCKHObj_Default)
			this.editedIndex = -1
			this.DeTaiID = null
		},
		Insert_DeTaiObj() {
			this.DeTaiNCKHObj.DotID = this.SelectedDotID

			if (this.editedIndex === -1) {
				if (this.ThanhVienNCKHObj.length === 0) {
					return Vue.$toast.warning("Vui lòng thêm ít nhất 1 thành viên", { position: "top" })
				}
				this.API_Insert_DeTaiKhenThuong()
			} else {
				if (this.ThanhVienNCKHObj.length === 0) {
					return Vue.$toast.warning("Vui lòng thêm ít nhất 1 thành viên", { position: "top" })
				}
				this.API_Update_DeTaiKhenThuong()

			}
		},
		API_Insert_DeTaiKhenThuong() {
			ajaxCALL("/NCKH_Ins_Obj", {
				DeTaiNCKHObj: this.DeTaiNCKHObj,
				ThanhVienNCKHObj: this.ThanhVienNCKHObj
			}, res => {
				this.closeDialog()
				this.API_GetNCKH_ByDotID()
				Vue.$toast.success("Thêm mới thành công!", { position: "top" })
			}, err => {
				Vue.$toast.error(err.responseJSON.Message, { position: "top" })
			})
		},
		API_Update_DeTaiKhenThuong() {
			ajaxCALL("/NCKH_Udp_Obj", {
				DeTaiNCKHID: this.DeTaiNCKHObj.DeTaiNCKHID,
				DeTaiNCKHObj: this.DeTaiNCKHObj,
				ThanhVienNCKHObj: this.ThanhVienNCKHObj
			}, res => {
				this.closeDialog()
				this.API_GetNCKH_ByDotID()
				Vue.$toast.success("Cập nhật thành công!", { position: "top" })
			}, err => {
				Vue.$toast.error(err.responseJSON.Message, { position: "top" })
			})
		},
		API_Delete_DeTaiKhenThuong() {
			ajaxCALL("/NCKH_Del", {
				DeTaiNCKHID: this.DeTaiID
			}, res => {
				this.closeDialogDelete()
				this.API_GetNCKH_ByDotID()
				Vue.$toast.success("Xóa thành công!", { position: "top" })
			}, err => {
				Vue.$toast.error(err.responseJSON.Message, { position: "top" })
			})
		},
		API_Get_CTDeTai_By_DeTaiID(id) {
			ajaxCALL("/NCKH_Get_ByID", {
				DeTaiNCKHID: id
			}, (res) => {
				this.DeTaiNCKHObj = res.data[0][0]
				this.ThanhVienNCKHObj = res.data[1]
				this.DeTaiNCKHObj.DiemDG1 = convertDiem(this.DeTaiNCKHObj.DiemDG1)
				this.DeTaiNCKHObj.DiemDG2 = convertDiem(this.DeTaiNCKHObj.DiemDG2)
				this.DeTaiNCKHObj.DiemDG3 = convertDiem(this.DeTaiNCKHObj.DiemDG3)
				this.DeTaiNCKHObj.DiemPB1 = convertDiem(this.DeTaiNCKHObj.DiemPB1)
				this.DeTaiNCKHObj.DiemDGTB = convertDiem(this.DeTaiNCKHObj.DiemDGTB)
			}, err => {
				console.log(err)
			})
		},
		GetDiemDGTB() {
			if (this.DeTaiNCKHObj.DiemDG1 === null || this.DeTaiNCKHObj.DiemDG1 === "") {
				this.DeTaiNCKHObj.DiemDG1 = convertDiem(0)
			} if (this.DeTaiNCKHObj.DiemDG2 === null || this.DeTaiNCKHObj.DiemDG2 === "") {
				this.DeTaiNCKHObj.DiemDG2 = convertDiem(0)
			} if (this.DeTaiNCKHObj.DiemDG3 === null || this.DeTaiNCKHObj.DiemDG3 === "") {
				this.DeTaiNCKHObj.DiemDG3 = convertDiem(0)
			} if (this.DeTaiNCKHObj.DiemPB1 === null || this.DeTaiNCKHObj.DiemPB1 === "") {
				this.DeTaiNCKHObj.DiemPB1 = convertDiem(0)
			} if (this.DeTaiNCKHObj.DiemDG4 === null || this.DeTaiNCKHObj.DiemDG4 === "") {
				this.DeTaiNCKHObj.DiemDG4 = convertDiem(0)
			} if (this.DeTaiNCKHObj.DiemDG5 === null || this.DeTaiNCKHObj.DiemDG5 === "") {
				this.DeTaiNCKHObj.DiemDG5 = convertDiem(0)
			}
			if (this.DeTaiNCKHObj.DiemDG1 && this.DeTaiNCKHObj.DiemDG2 && this.DeTaiNCKHObj.DiemDG3 && this.DeTaiNCKHObj.DiemPB1 !== null || this.DeTaiNCKHObj.DiemDG1 && this.DeTaiNCKHObj.DiemDG2 && this.DeTaiNCKHObj.DiemDG3 && this.DeTaiNCKHObj.DiemPB1 !==
				convertDiem(0)) {
				this.DeTaiNCKHObj.DiemDGTB = (+this.DeTaiNCKHObj.DiemDG1 + +this.DeTaiNCKHObj.DiemDG2 + +this.DeTaiNCKHObj.DiemDG3 + +this.DeTaiNCKHObj.DiemPB1) / 4
				this.DeTaiNCKHObj.DiemDGTB = convertDiem(this.DeTaiNCKHObj.DiemDGTB)
			} else {
				this.DeTaiNCKHObj.DiemDGTB = convertDiem(0)
			}
		},
		API_GetNCKH_ByDotID() {
			if (!this.SelectedDotID) {
				this.DSDeTai = []
				return
			}
			ajaxCALL("/NCKH_Get_ByDotID", {
				DotID: this.SelectedDotID
			}, res => {
				this.DSDeTai = res.data
			}, err => {
				console.log(err)
			})
		},
		onEditHoiDong() {
			this.hoiDongManageDialog = true
		}
	},
	created() {
		this.API_GetNCKH_ByDotID()
	}
	}
</script>