<template>
	<div>
		<v-data-table class="elevation-1" :items="DS_TienDo" :headers="headers">
			<template v-slot:top>
				<v-toolbar flat>
					<v-toolbar-title class="primary--text font-weight-medium">
						Tiến độ cấp kinh phí
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
								<span class="text-h5 primary--text">Tiến độ cấp chi phí</span>
								<v-spacer></v-spacer>
								<v-btn fab small icon @click="closeDialog">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text class="mt-3">
								<form>
									<v-row>
										<v-col cols="7">
											<v-text-field v-model="KinhPhi_Format" class="text-input-right" prefix="VNĐ"
												label="Số tiền cấp kinh phí" reverse dense hide-details
												outlined></v-text-field>
										</v-col>
										<v-col cols="5">
											<v-combobox v-model="TienDo_Obj.SoTT" hint="VD: 1" :items="[1,2,3,4,5]"
												label="Lần cấp kinh phí" dense hide-details outlined></v-combobox>
										</v-col>
										<v-col cols="12">
											<f-date v-model="TienDo_Obj.NgayTienDo" label="Ngày cấp kinh phí" dense
												hide-details outlined></f-date>

										</v-col>
										<v-col cols="12">
											<v-text-field v-model="TienDo_Obj.SoQD" label="Số quyết định" dense
												hide-details outlined></v-text-field>
										</v-col>
										<v-col cols="12">
											<f-file-upload label="Upload" v-model="TienDo_Obj.FileID"
												:url="vueData.v_Set.apiFile" color="white" :filters="fileEX"
												@input="(value)=> uploadFileQDCKP(value)"></f-file-upload>
											<v-chip class="ml-4" v-if="TienDo_Obj.FileID" label outlined
												color="deep-purple accent-4"
												:href="vueData.v_Set.urlReturnFile + /FileData/ + TienDo_Obj.FileID"
												close @click:close="del_fileItem">
												<v-icon left>mdi-file-check-outline</v-icon>
												<span 
													style="max-width: 190px; overflow: hidden;text-overflow: ellipsis;white-space: nowrap">
													{{TienDo_Obj.FileName.slice(0,TienDo_Obj.FileName.length-4)}}
												</span>
												<span>{{TienDo_Obj.FileName.slice(-4)}}</span>
												

											</v-chip>
											<v-chip v-else class="ml-4" color="warning" label outlined>
												Upload file (nếu có)
											</v-chip>
										</v-col>
										<v-col cols="12">
											<v-textarea v-model="TienDo_Obj.GhiChu" label="Ghi chú" dense hide-details
												outlined></v-textarea>
										</v-col>
									</v-row>
								</form>
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="closeDialog">Đóng</v-btn>
								<v-btn color="primary" @click="save()">Lưu</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
					<v-dialog v-model="dialogConfirmDelete" max-width="500px">
						<v-card>
							<v-card-title class="primary--text font-weight-medium">
								Xác nhận xóa lần cấp kinh phí này?
							</v-card-title>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="closeDialogDeleteConfirm">Đóng</v-btn>
								<v-btn color="primary" @click="delete_TienDo_Confirm">Xác nhận</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
				</v-toolbar>
			</template>

			<template v-slot:item.ngaytiendo="{item}">
				<span>{{formatDate(item.NgayTienDo)}}</span>
			</template>
			<template v-slot:item.sotien="{item}">
				<span>{{formatAsCurrency(item.SoTien)}} đ</span>
			</template>
			<template v-slot:item.actions="{ item }">
				<div style="display:flex; justify-content:center">
					<v-icon style="font-size:18px" color="red darken-3" small class="mr-2" @click="delete_TienDo(item)">
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
				fileEX: {
					max_file_size: '15mb',
					mime_types: [{ title: "All files", extensions: "*" }]
				},
				dialog: false,
				dialogConfirmDelete: false,
				headers: [
					{ text: "Lần cấp kinh phí", value: "SoTT", sortable: false, align: "center" },
					{ text: "Số tiền cấp kinh phí", value: "sotien", align: "center" },
					{ text: "Ngày cấp kinh phí", value: "ngaytiendo", align: "center" },
					{ text: "Ghi chú", value: "GhiChu", sortable: false },
					{ text: "Thao tác", value: "actions", sortable: false, align: "center" },
				],
				TienDo_Obj: {
					SoTT: null,
					SoTien: null,
					NgayTienDo: null,
					GhiChu: "",
					SoQD: null,
					NgayQD: null
				},
				TienDo_Obj_Default: {
					SoTT: null,
					SoTien: null,
					NgayTienDo: null,
					GhiChu: "",
					SoQD: null,
					NgayQD: null
				},
				editedIndex: -1
			}
		},
		mounted() {
			
		},
		computed: {
			DS_TienDo: function () {
				return this.value
			},
			DeTaiKHCNID: function () {
				return this.iddetai
			},
			KinhPhi_Format: {
				get: function () {
					return formatAsCurrency(this.TienDo_Obj.SoTien, 0)
				},
				set: function (newValue) {
					this.TienDo_Obj.SoTien = Number(newValue.replace(/[^0-9\.]/g, ''));
				}
			},
		},
		watch: {
			dialog: function (val) {
				val || this.closeDialog()
			},
			dialogConfirmDelete: function (val) {
				val || this.closeDialogDeleteConfirm()
			}
		},
		methods: {
			formatDate(date) {
	
				let item = date?.split("-")
				if (item.length === 3) {
					return item[2] + '/' + item[1] + '/' + item[0]
				} else {
					return date
				}
	
	
			},
			uploadFileQDCKP(value) {
				let file = value.Files[0]
				this.TienDo_Obj.FileID = file.FILE_ID
				this.TienDo_Obj.FileUrl = file.FILE_URL
				this.TienDo_Obj.FileName = file.FILE_NAME
			},
			del_fileItem() {
				this.TienDo_Obj.FileID = null
				this.TienDo_Obj.FileUrl = null
				this.TienDo_Obj.FileName = null
			},
			newItem() {
				this.dialog = true
			},
			closeDialog() {
				this.dialog = false
				this.TienDo_Obj = Object.assign({}, this.TienDo_Obj_Default)
				this.editedIndex = -1
			},
			closeDialogDeleteConfirm() {
				this.dialogConfirmDelete = false
				this.TienDo_Obj = Object.assign({}, this.TienDo_Obj_Default)
				this.editedIndex = -1
			},
			save() {
				if (this.editedIndex === -1) {
					this.API_Insert_TienDo()
				} else {
					this.API_Update_TienDo()
				}
			},
			editedItem(item) {
				this.dialog = true
				this.TienDo_Obj = Object.assign({}, item)
				this.editedIndex = this.DS_TienDo.indexOf(item)
			},
			delete_TienDo(item) {
				this.dialogConfirmDelete = true
				this.TienDo_Obj = Object.assign({}, item)
	
			},
			delete_TienDo_Confirm() {
				ajaxCALL("/KHCN_TienDo_Del_Obj", {
					TienDoKHCNObj: this.TienDo_Obj
				}, res => {
					this.API_Reload_TienDo()
					this.dialogConfirmDelete = false
					Vue.$toast.success("Xóa tiến độ thành công", { position: "top" })
				}, err => {
					Vue.$toast.error("Xóa tiến độ thất bại", { position: "top" })
				})
			},
			API_Insert_TienDo() {
				ajaxCALL("/KHCN_TienDo_Ins_Obj", {
					DeTaiKHCNID: this.DeTaiKHCNID,
					TienDoKHCNObj: this.TienDo_Obj
				}, res => {
					this.API_Reload_TienDo()
					this.closeDialog()
					Vue.$toast.success("Thêm tiến độ thành công", { position: "top" })
				}, err => {
					Vue.$toast.error("Thêm tiến độ thất bại", { position: "top" })
				})
			},
			API_Update_TienDo() {
				ajaxCALL("/KHCN_TienDo_Upd_Obj", {
					TienDoKHCNObj: this.TienDo_Obj
				}, res => {
					this.API_Reload_TienDo()
					this.closeDialog()
					Vue.$toast.success("Cập nhật tiến độ thành công", { position: "top" })
				}, err => {
					Vue.$toast.error("Cập nhật tiến độ thất bại", { position: "top" })
				})
			},
			API_Reload_TienDo() {
				ajaxCALL("/KHCN_TienDo_Get_ByID", {
					DeTaiKHCNID: this.DeTaiKHCNID
				}, res => {
					this.$emit("input", res.data)
				}, err => {
					console.log(err)
				})
			}
		},
	}
</script>
<style scoped>
	.text-input-right .v-label {
		right: auto;
		left: 0;
		transform: translateY(-50%) translateX(-100%);
	}
</style>