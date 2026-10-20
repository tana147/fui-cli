<template>
	<div>
		<v-data-table :items="DSQuyetDinh" :search="searchQD" :headers="headers" class="elevation-1">
			<template v-slot:top>
				<v-toolbar flat>
					<v-toolbar-title class="primary--text text-h5 font-weight-medium">
						Danh sách quyết định 
					</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-text-field class="me-5" v-model="searchQD" prepend-icon="mdi-magnify" label="Tìm kiếm" outlined
						dense hide-details style="max-width:400px"></v-text-field>
					<v-dialog v-model="dialog" max-width="1400px">
						<template v-slot:activator="{ on, attrs }">
							<v-btn color="success" fab x-small outlined class="mb-2" @click="newItem">
								<v-icon>mdi-plus</v-icon>
							</v-btn>
						</template>
						<v-card>
							<v-card-title>
								<span class="text-h5 primary--text font-weight-medium">Thêm mới</span>
								<v-spacer></v-spacer>
								<v-btn fab small icon @click="closeDialog">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text class="mt-3">
								<v-form>
									<v-row>
										<v-col cols="4">
											<v-text-field label="Số quyết định" v-model="QuyetDinh_Obj.MaSoQD" outlined
												dense hide-details></v-text-field>
										</v-col>
										<v-col cols="2">
											<v-select label="Đợt" v-model="QuyetDinh_Obj.Dot" :items="DotArr" outlined
												dense hide-details></v-select>
										</v-col>
										<v-col cols="2">
											<v-text-field label="Ngày quyết định" v-model="QuyetDinh_Obj.NgayQD"
												outlined dense hide-details></v-text-field>
										</v-col>
										<v-col cols="2">
											<v-text-field label="Tháng quyết định" v-model="QuyetDinh_Obj.ThangQD"
												outlined dense hide-details></v-text-field>
										</v-col>
										<v-col cols="2">
											<v-text-field label="Năm quyết định" v-model="QuyetDinh_Obj.NamQD" outlined
												dense hide-details></v-text-field>
										</v-col>
										<v-col cols="12">
											<v-textarea label="Mô tả quyết định" v-model="QuyetDinh_Obj.MoTaQD" rows="2"
												outlined dense hide-details></v-textarea>
										</v-col>
										<v-col cols="5">
											<f-file-upload label="Upload file" :filters="fileEX"
												:url="vueData.v_Set.apiFile" color="white"
												@input="(value)=> uploadFileQDCKP(value)"></f-file-upload>
											<v-chip class="ml-4" v-if="fileUpload.FileID" label outlined
												color="deep-purple accent-4"
												:href="vueData.v_Set.urlReturnFile + fileUpload.FileUrl" close
												@click:close="del_fileItem">
												<v-icon left>mdi-file-check-outline</v-icon>
												{{fileUpload.FileName}}
											</v-chip>
											<v-chip v-else class="ml-4" color="warning" label outlined>
												Chưa upload file
											</v-chip>
										</v-col>
									</v-row>
								</v-form>
								<v-data-table class="mt-3 elevation-1" :search="search"
								:items="DSDeTai" :headers="headersDeTai" item-key="DeTaiKHCNID">
									<template v-slot:top>
										<v-toolbar flat>
											<v-toolbar-title class="primary--text text-h5 font-weight-medium">
												Danh sách đề tài
											</v-toolbar-title>
											<v-spacer></v-spacer>
											<v-text-field class="me-5" v-model="search" prepend-icon="mdi-magnify"
												label="Tìm kiếm" outlined dense hide-details
												style="max-width:400px"></v-text-field>
										</v-toolbar>
									</template>
									<template v-slot:item.isCheck="{ item }">
										<v-simple-checkbox v-model="item.isCheck"  outlined dense hide-details></v-simple-checkbox>
									</template>
									<template v-slot:item.textfield="{ item }">
										<v-text-field v-model="item.KinhPhi" :disabled="!item.isCheck" outlined dense hide-details></v-text-field>
									</template>
								</v-data-table>
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="closeDialog">Đóng</v-btn>
								<v-btn color="primary" @click="save()">Lưu</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
					<v-dialog v-model="dialogConfirmDel">
						<v-card>
							<v-card-title>
								<span class="text-h5 primary--text font-weight-medium">Thêm mới</span>
								<v-spacer></v-spacer>
								<v-btn fab small icon @click="closeDialogDel">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text class="mt-3">
								<span>Bạn có chắc muốn xóa quyết định này?</span>
								
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="closeDialogDel">Đóng</v-btn>
								<v-btn color="primary" @click="confirmDelete">Lưu</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
				</v-toolbar>
			</template>
			<template v-slot:item.NgayQD="{ item }">
				<span>{{item.NgayQD}}/{{item.ThangQD}}/{{item.NamQD}}</span>
			</template>
			<template v-slot:item.SoGiaiThuong="{ item }">
				<v-chip color="primary">{{item.SoGiaiThuong}}</v-chip>
			</template>
			<template v-slot:item.SoTapTin="{ item }">
				<v-chip color="primary">{{item.SoTapTin}}</v-chip>
			</template>

			<template v-slot:item.actions="{ item }">
				<div>
					<v-icon style="font-size:18px" color="red darken-3" @click="openDialogDel(item)" small class="mr-2">
						mdi-trash-can-outline
					</v-icon>
					<v-icon style="font-size:18px" color="green darken-2" @click="editedItem(item)" small class="mr-2">
						mdi-square-edit-outline
					</v-icon>
				</div>
			</template>
		</v-data-table>
	</div>
</template>

<script>
	export default {
		props: ["dsquyetdinh", "dsdetai"],
		data() {
			return {
				dialogConfirmDel:false,
				searchQD: "",
				search: "",
				fileEX: {
					max_file_size: '15mb',
					mime_types: [{ title: "All files", extensions: "*" }]
				},
				dialog: false,
				DeTaiSelected: [],
				headers: [
					{
						text: "Số quyết định",
						value: "MaSoQD"
					},
					{
						text: "Mô tả",
						value: "MoTaQD"
					},
					{
						text: "Ngày, Tháng, Năm QĐ",
						value: "NgayQD",
						align: "center"
	
					},
					{
						text: "Đề tài",
						align: "center",
						value: "SoGiaiThuong"
	
					},
					{
						text: "Tập tin",
						align: "center",
						value: "SoTapTin"
	
					},
					{
						text: "Chức năng",
						value: "actions",
						align: "center"
					}
				],
				headersDeTai: [
					{
						text: "Chon",
						value: "isCheck"
					},
					{
						text: "Mã đề tài",
						value: "MaSoDeTai"
					},
					{
						text: "Tên đề tài",
						value: "TenDeTaiKHCN_Vi"
					},
					{
						text: "Kinh phí",
						value: "textfield",
						align: "center"
	
					}
				],
				DotArr: ["1", "2", "3"],
				fileUpload: {
					FileID: null,
					FileName: null,
					FileUrl: null
				},
				fileUpload_default: {
					FileID: null,
					FileName: null,
					FileUrl: null
				},
				TienDo_Obj: {
					SoTT: null,
					SoTien: null,
					NgayTienDo: null,
					GhiChu: null,
					SoQD: null,
					NgayQD: null,
					FileID: "",
					FileName: ""
				},
				TienDo_Obj_Default: {
					SoTT: null,
					SoTien: null,
					NgayTienDo: null,
					GhiChu: null,
					SoQD: null,
					NgayQD: null,
					FileID: "",
					FileName: ""
				},
				QuyetDinh_Obj_Default: {
					MaSoQD: null,
					Dot: null,
					NgayQD: null,
					ThangQD: null,
					NamQD: null,
					MoTaQD: "",
					TemplateQD: 2,
					LoaiQD: 2,
					DS_FileID: null
				},
				QuyetDinh_Obj: {
					MaSoQD: null,
					Dot: null,
					NgayQD: null,
					ThangQD: null,
					NamQD: null,
					MoTaQD: "",
					TemplateQD: 2,
					LoaiQD: 2,
					DS_FileID: null
				},
				editedIndex: -1,
				DSDeTai:this.dsdetai.map(item => ({...item,isCheck:false,KinhPhi:null})),
				IDQD:null
			}
		},
		mounted() { },
		computed: {
			DSQuyetDinh: function () {
				return this.dsquyetdinh
			},
		},
		watch: {
			dialog: function (val) {
				val || this.closeDialog()
			},
			dialogConfirmDel:function(val){
				val || this.closeDialogDel()
			}
		},
		methods: {
			closeDialogDel(){
				this.dialogConfirmDel= false
				this.IDQD= null
			},
			openDialogDel(item){
				this.dialogConfirmDel= true
				this.IDQD = item.QDID
			},
			confirmDelete(){
				this.API_Del_SQD(this.IDQD)
				this.closeDialogDel()
			},
			newItem() {
				this.dialog = true
			},
			closeDialog() {
				this.dialog = false
				this.editedIndex = -1
				this.QuyetDinh_Obj = Object.assign({}, this.QuyetDinh_Obj_Default)
				this.search = ""
				this.DeTaiSelected = []
				this.fileUpload = Object.assign({}, this.fileUpload_default)
			},
			uploadFileQDCKP(value) {
				let file = value.Files[0]
				this.fileUpload.FileID = file.FILE_ID
				this.fileUpload.FileUrl = file.FILE_URL
				this.fileUpload.FileName = file.FILE_NAME
			},
			del_fileItem() {
				this.fileUpload.FileID = null
				this.fileUpload.FileUrl = null
				this.fileUpload.FileName = null
			},
			editedItem(item) {
				this.dialog = true
				ajaxCALL("/GiaiThuong_QuyetDinh_Get_ByID", {
					QDID: item.QDID
				}, res => {
					this.QuyetDinh_Obj = res.data[0][0]
					this.fileUpload.FileID = res.data[1][0].FILE_ID
					this.fileUpload.FileName = res.data[1][0].FILE_NAME
				}, err => {
					console.log(err)
				}
				)
				this.editedIndex = this.DSQuyetDinh.indexOf(item)
			},
			async save() {
				if (this.editedIndex === -1) {
					await this.API_Ins_SQD()
					let DeTaiSelected = this.DSDeTai.filter(item => item.isCheck)
					await DeTaiSelected.forEach(async item => {
						this.TienDo_Obj.SoQD = this.QuyetDinh_Obj.MaSoQD
						this.TienDo_Obj.FileID = this.fileUpload.FileID
						this.TienDo_Obj.FileName = this.fileUpload.FileName
						this.TienDo_Obj.SoTien = item.KinhPhi
						this.TienDo_Obj.SoTT = this.QuyetDinh_Obj.Dot
						this.TienDo_Obj.NgayTienDo = this.QuyetDinh_Obj.NgayQD + "/" + this.QuyetDinh_Obj.ThangQD + "/" +
							this.QuyetDinh_Obj.NamQD
						await ajaxCALL("/KHCN_TienDo_Ins_Obj", {
							DeTaiKHCNID: item.DeTaiKHCNID,
							TienDoKHCNObj: this.TienDo_Obj
						}, res => {
	
						}, err => {
						})
						this.TienDo_Obj = Object.assign({}, this.TienDo_Obj_Default)
					})
					this.closeDialog()
				} else {
					this.API_Upd_SQD()
				}
			},
			API_Ins_SQD() {
				let item = this.QuyetDinh_Obj
				let file = this.fileUpload
				ajaxCALL("/QuyetDinh_Ins", {
					MaSoQD: item.MaSoQD,
					NgayQD: item.NgayQD ?? 0,
					ThangQD: item.ThangQD ?? 0,
					NamQD: item.NamQD ?? 0,
					MoTaQD: item.MoTaQD,
					TemplateQD: 2,
					LoaiQD: 2,
					DS_FileID: file.FileID
				}, res => {
					CALL("getQuyetDinh")
	
					Vue.$toast.success("Thêm quyết định thành công", { position: "top" })
				}, err => {
					Vue.$toast.success("Thêm định thất bại", { position: "top" })
				})
			},
			API_Upd_SQD() {
				let item = this.QuyetDinh_Obj
				ajaxCALL("/GiaiThuong_QuyetDinh_Upd", {
					QDID: item.QDID,
					MaSoQD: item.MaSoQD,
					NgayQD: item.NgayQD ?? 0,
					ThangQD: item.ThangQD ?? 0,
					NamQD: item.NamQD ?? 0,
					MoTaQD: item.MoTaQD
				}, res => {
					CALL("getQuyetDinh")
					this.closeDialog()
					Vue.$toast.success("Cập nhật quyết định thành công", { position: "top" })
				}, err => {
					Vue.$toast.success("Cập nhật quyết định thất bại", { position: "top" })
				})
			},
			API_Del_SQD(id) {
				ajaxCALL("/GiaiThuong_QuyetDinh_Del", {
					QDID: id
				}, res => {
					CALL("getQuyetDinh")
					Vue.$toast.success("Xóa quyết định thành công", { position: "top" })
				}, err => {
					Vue.$toast.success("Xóa quyết định thất bại", { position: "top" })
				})
			}
		},
	
	}
</script>