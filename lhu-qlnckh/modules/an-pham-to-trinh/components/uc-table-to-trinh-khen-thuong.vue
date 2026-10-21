<template>
	<v-data-table :headers="headers" class="elevation-1" :items="DSToTrinh">
		<template v-slot:top>
			<v-toolbar flat>
				<v-toolbar-title class="primary--text font-weight-medium">Danh sách tờ trình khen {{" "}}
					thưởng</v-toolbar-title>
				<v-spacer></v-spacer>
				<v-dialog v-model="dialog" max-width="1368px">
					<template v-slot:activator="{ on, attrs }">
						<v-btn color="success" fab x-small outlined class="mb-2" @click="newItem">
							<v-icon>mdi-plus</v-icon>
						</v-btn>
					</template>
					<v-card>
						<v-card-title class="mb-5">
							<span class="text-h5 primary--text font-weight-medium">{{modelTitle}}</span>
							<v-spacer></v-spacer>
							<v-btn fab small icon @click="close">
								<v-icon>mdi-close</v-icon>
							</v-btn>
						</v-card-title>
						<v-card-text>
							<v-row dense>
								<v-col cols="12" class="pb-0 pt-0">
									<v-text-field outlined dense v-model="editItem.ToTrinhObj.TieuDeQuyetDinh"
										label="Tiêu đề quyết định"></v-text-field>
								</v-col>
								<v-col cols="3" class="pb-0 pt-0">
									<c-text-field-sqd outlined dense :ngay.sync="editItem.ToTrinhObj.Ngay"
										:thang.sync="editItem.ToTrinhObj.Thang " :nam.sync="editItem.ToTrinhObj.Nam "
										label="Ngày số quyết định" hint="Ngày/Tháng/Năm" disabled></c-text-field-sqd>
								</v-col>
								<v-col cols="3" class="pb-0 pt-0">
									<v-text-field outlined dense v-model="editItem.ToTrinhObj.SoQD"
										label="Số quyết định" disabled></v-text-field>
								</v-col>
								<v-col cols="4" class="pb-0 pt-0">
									<v-text-field outlined dense v-model="editItem.ToTrinhObj.NamHocKhenThuong"
										label="Năm học khen thưởng"></v-text-field>
								</v-col>
								<v-col cols="2" class="pb-0 pt-0">
									<v-text-field outlined dense v-model="editItem.ToTrinhObj.DotKhenThuong"
										label="Đợt khen thưởng"></v-text-field>
								</v-col>
								<v-col cols="4" class="pb-0 pt-0 d-flex">
									<f-file-upload v-model="editItem.ToTrinhObj.ToTrinhFileID" :filters="fileEX" label="Upload"
										:url="vueData.v_Set.apiFile" color="white"
										@input="(value)=> uploadFileToTrinh(value)"></f-file-upload>
									<span v-if="editItem.ToTrinhObj.ToTrinhFileID">
										<v-chip class="ml-4 mt-1" close label outlined color="deep-purple accent-4"
											:href="vueData.v_Set.urlReturnFile + editItem.ToTrinhObj.ToTrinhFileUrl"
											@click:close="del_FileToTrinh" target="_blank">
											<v-icon left>mdi-file-check-outline</v-icon>
											{{editItem.ToTrinhObj.ToTrinhFileName}}
										</v-chip>
									</span>
									<v-chip class="ml-4 mt-1" v-else color="warning" label outlined>
										Upload file tờ trình (nếu có)
									</v-chip>
								</v-col>
							</v-row>
							<uc-table-an-pham-khen-thuong v-model="editItem.DSToTrinhAnPham" class="mt-5"
								:dsanphamchuakhenthuong="DSAnPham"
								:soqd="editItem.ToTrinhObj.SoQD"></uc-table-an-pham-khen-thuong>
						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="close">Đóng</v-btn>
							<v-btn class="ml-2" color="primary" @click="save">{{editedIndex===-1?"Lưu":"Cập
								nhật"}}</v-btn>
							<v-btn class="ml-2" color="success" v-if="editItem.ToTrinhObj.ToTrinhID"
								:href="URL_In_To_Trinh+editItem.ToTrinhObj.ToTrinhID" target="_blank">In tờ
								trình</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
				<v-dialog v-model="dialogUpdSQD">
					<v-card>
						<v-card-title class="mb-5">
							<span class="text-h5 primary--text font-weight-medium">Cập nhật số quyết định</span>
							<v-spacer></v-spacer>
							<v-btn fab small icon @click="closeUpdSQD">
								<v-icon>mdi-close</v-icon>
							</v-btn>
						</v-card-title>
						<v-card-text>
							<v-row dense>
								<v-col cols="12" class="pb-0 pt-0">
									<v-text-field outlined dense v-model="editItem.ToTrinhObj.TieuDeQuyetDinh"
										label="Tiêu đề quyết định"></v-text-field>
								</v-col>
								<v-col cols="3" class="pb-0 pt-0">
									<c-text-field-sqd outlined dense :ngay.sync="editItem.ToTrinhObj.Ngay"
										:thang.sync="editItem.ToTrinhObj.Thang" :nam.sync="editItem.ToTrinhObj.Nam"
										label="Ngày số quyết định" hint="Ngày/Tháng/Năm"></c-text-field-sqd>
								</v-col>
								<v-col cols="3" class="pb-0 pt-0">
									<v-text-field outlined dense v-model="editItem.ToTrinhObj.SoQD"
										label="Số quyết định"></v-text-field>
								</v-col>
								<v-col cols="2" class="pb-0 pt-0">
									<v-text-field outlined dense v-model="editItem.ToTrinhObj.NamHocKhenThuong"
										label="Năm học khen thưởng"></v-text-field>
								</v-col>
								<v-col cols="2" class="pb-0 pt-0">
									<v-text-field outlined dense v-model="editItem.ToTrinhObj.DotKhenThuong"
										label="Đợt khen thưởng"></v-text-field>
								</v-col>
								<v-col cols="4" class="pb-0 pt-0 d-flex">
									<f-file-upload v-model="editItem.ToTrinhObj.ToTrinhFileID" :filters="fileEX" label="Upload"
										:url="vueData.v_Set.apiFile" color="white"
										@input="(value)=> uploadFileToTrinh(value)"></f-file-upload>
									<span v-if="editItem.ToTrinhObj.ToTrinhFileID">
										<v-chip class="ml-4 mt-1" close label outlined color="deep-purple accent-4"
											:href="vueData.v_Set.urlReturnFile + editItem.ToTrinhObj.ToTrinhFileUrl"
											@click:close="del_FileToTrinh">
											<v-icon left>mdi-file-check-outline</v-icon>
											{{editItem.ToTrinhObj.ToTrinhFileName}}
										</v-chip>
									</span>
									<v-chip class="ml-4 mt-1" v-else color="warning" label outlined>
										Upload file tờ trình (nếu có)
									</v-chip>
								</v-col>
							</v-row>
							<uc-table-an-pham-khen-thuong v-model="editItem.DSToTrinhAnPham" class="mt-5"
								:dsanphamchuakhenthuong="DSAnPham"
								:soqd="editItem.ToTrinhObj.SoQD"></uc-table-an-pham-khen-thuong>
						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="closeUpdSQD">Đóng</v-btn>
							<v-btn class="ml-2" color="primary" @click="sqd_update">Cập nhật</v-btn>
							<v-btn class="ml-2" color="success" v-if="editItem.ToTrinhObj.ToTrinhID"
								:href="URL_In_To_Trinh+editItem.ToTrinhObj.ToTrinhID" target="_blank">In tờ
								trình</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
				<v-dialog v-model="dialogDelete" max-width="500px">
					<v-card>
						<v-card-title class="text-h5">Xác nhận xóa tờ trình khen thưởng?</v-card-title>
						<v-card-actions class="mt-5">
							<v-spacer></v-spacer>
							<v-btn color="blue darken-1" @click="closeDelete" text>Đóng</v-btn>
							<v-btn color="blue darken-1" text @click="deleteConfirm">Xác nhận</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
			</v-toolbar>
		</template>
		<template v-slot:item.ngaythangnam="{item}">
			<div v-if="item.Ngay&&item.Thang&&item.Nam">
				{{item.Ngay}}/{{item.Thang}}/{{item.Nam}}
			</div>
		</template>
		<template v-slot:item.updatesoquyetdinh="{item}" class="align-center">
			<v-btn color="success" text @click="btn_updateSQD(item)">Cập nhật SQĐ</v-btn>
		</template>
		<template v-slot:item.actions="{ item }">
			<div>
				<v-icon style="font-size:18px" @click="deleteItem(item)" color="red darken-3" small class="mr-2">
					mdi-trash-can-outline
				</v-icon>
				<v-icon style="font-size:18px" @click="editedItem(item)" color="green darken-2" small class="mr-2">
					mdi-square-edit-outline
				</v-icon>
			</div>
		</template>
	</v-data-table>
</template>

<script>
	export default {
		props: ["dstotrinh", "dsanpham"],
		data() {
			return {
				fileEX: {
				max_file_size: '15mb',
				mime_types: [{ title: "All files", extensions: "*" }]
				},
				dialog: false,
				dialogDelete: false,
				dialogUpdSQD: false,
				headers: [
					{ text: 'Ngày ra quyết định', sortable: false, value: "ngaythangnam", },
					{ text: 'Số quyết định', sortable: false, value: "SoQD" },
					{ text: 'Năm học khen thưởng', sortable: false, value: "NamHocKhenThuong", align: 'center' },
					{ text: 'Đợt khen thưởng', sortable: false, value: "DotKhenThuong", align: 'center' },
					{ text: 'Cập nhật số quyết định', sortable: false, value: "updatesoquyetdinh", align: 'center' },
					{ text: 'Thao tác', sortable: false, value: "actions", align: 'center' },
				],
				editItem: {
					ToTrinhObj: {
						DotKhenThuong: "",
						Nam: null,
						Ngay: null,
						Thang: null,
						NamHocKhenThuong: "",
						SoQD: null,
						TieuDeQuyetDinh: `Về việc hỗ trợ kinh phí và khen thưởng tác giả có ấn phẩm khoa học được công bố trên các tạp chí, kỷ yếu hội thảo, nhà xuất bản khoa học`,
						ToTrinhFileID: null,
						ToTrinhFileName: null,
						ToTrinhFileUrl: null
					},
					DSToTrinhAnPham: []
				},
				defaultItem: {
					ToTrinhObj: {
						DotKhenThuong: "",
						Nam: null,
						Ngay: null,
						Thang: null,
						NamHocKhenThuong: "",
						SoQD: null,
						TieuDeQuyetDinh: `Về việc hỗ trợ kinh phí và khen thưởng tác giả có ấn phẩm khoa học được công bố trên các tạp chí, kỷ yếu hội thảo, nhà xuất bản khoa học`,
						ToTrinhFileID: null,
						ToTrinhFileName: null,
						ToTrinhFileUrl: null
					},
					DSToTrinhAnPham: []
				},
				editedIndex: -1,
				ToTrinhID: null,
				URL_In_To_Trinh: "https://qlnckh.lhu.edu.vn/an-pham-in-to-trinh/?ToTrinhID="
	
			}
		},
		mounted() { },
		computed: {
			modelTitle: function () {
				return this.editedIndex === -1 ? 'Thêm mới tờ trình quyết định' : 'Chi tiết thông tin tờ trình'
			},
			DSToTrinh: function () {
				return this.dstotrinh
			},
			DSAnPham: function () {
				return this.dsanpham
			},
		},
		watch: {
			dialog(val) {
				val || this.close()
			}
		},
		methods: {
			newItem() {
				this.dialog = true
				this.editItem = {
					ToTrinhObj: {
						DotKhenThuong: "",
						Nam: null,
						Ngay: null,
						Thang: null,
						NamHocKhenThuong: "",
						SoQD: null,
						TieuDeQuyetDinh: `Về việc hỗ trợ kinh phí và khen thưởng tác giả có ấn phẩm khoa học được công bố trên các tạp chí, kỷ yếu hội thảo, nhà xuất bản khoa học`,
						ToTrinhFileID: null,
						ToTrinhFileName: null,
						ToTrinhFileUrl: null
					},
					DSToTrinhAnPham: []
				}
			},
			initBeforeEditView(data) {
				const $this = this
				data.isInitBeforeEditView = false
				ajaxCALL("/ToTrinh_Get_ByToTrinhID", {
					"ToTrinhID": data.editedItem.ToTrinhID
				}, (res) => {
					data.editedItem.ToTrinhObj = res.data[0][0]
					data.editedItem.DSToTrinhAnPham = res.data[2]
					console.log("API CALL ->", data.editedItem)
					data.isInitBeforeEditView = true
				}, (err) => {
					console.log(err)
				})
			},
			onFinishEdit() { },
			onFinishDelete() { },
			DuongDanURL() {
				this.URL_In_To_Trinh = this.URL_In_To_Trinh + editItem.ToTrinhObj.ToTrinhID
			},
			uploadFileToTrinh(value) {
				let file = value.Files[0]
				this.editItem.ToTrinhObj.ToTrinhFileID = file.FILE_ID
				this.editItem.ToTrinhObj.ToTrinhFileUrl = file.FILE_URL
				this.editItem.ToTrinhObj.ToTrinhFileName = file.FILE_NAME
			},
			editedItem(item) {
				this.editedIndex = this.DSToTrinh.indexOf(item)
				ajaxCALL("/ToTrinh_Get_ByToTrinhID", {
					ToTrinhID: item.ToTrinhID
				}, res => {
					this.editItem.ToTrinhObj = res.data[0][0]
					this.editItem.DSToTrinhAnPham = res.data[2]
					this.dialog = true
				}, err => {
					console.log(err)
				})
	
			},
			save() {
				if (this.editedIndex > -1) {
					this.ToTrinh_Upd()
				} else {
					this.ToTrinh_Ins()
				}
			},
			close() {
				this.dialog = false
				this.$nextTick(() => {
					this.editItem = Object.assign({}, this.defaultItem)
					this.editedIndex = -1
				})
			},
			closeUpdSQD() {
				this.dialogUpdSQD = false
				this.$nextTick(() => {
					this.editItem = Object.assign({}, this.defaultItem)
					this.editedIndex = -1
				})
			},
			closeDelete() {
				this.dialogDelete = false
				this.$nextTick(() => {
					this.editItem = Object.assign({}, this.defaultItem)
					this.editedIndex = -1
				})
			},
			del_FileToTrinh() {
				this.editItem.ToTrinhObj.ToTrinhFileID = null
				this.editItem.ToTrinhObj.ToTrinhFileUrl = null
				this.editItem.ToTrinhObj.ToTrinhFileName = null
			},
			deleteItem(item) {
				this.ToTrinhID = item.ToTrinhID
				this.dialogDelete = true
			},
			deleteConfirm() {
				ajaxCALL("/ToTrinh_Del", {
					ToTrinhID: this.ToTrinhID
				}, (res) => {
					this.closeDelete()
					CALL("ToTrinhGetAll")
					Vue.$toast.success("Xóa tờ trình thành công", { position: "top" })
				}, (err) => {
					Vue.$toast.warning("Xóa tờ trình thất bại", { position: "top" })
				})
	
			},
			//Hàm thêm tờ trình quyết định
			ToTrinh_Ins() {
				this.editItem.DSToTrinhAnPham = this.editItem.DSToTrinhAnPham.map(item => ({ AnPhamID: item.AnPhamID }))
				ajaxCALL("/ToTrinh_Ins", {
					ToTrinhObj: this.editItem.ToTrinhObj,
					AnPhamObjArr: this.editItem.DSToTrinhAnPham
				}, (res) => {
					CALL("ToTrinhGetAll")
					CALL("ToTrinhAnPhamGet")
					this.close()
					Vue.$toast.success("Thêm tờ trình thành công", { position: "top" })
				}, (err) => {
					console.log("ins", err)
					Vue.$toast.warning("Thêm tờ trình thất bại", { position: "top" })
				})
			},
			//Hàm cập nhật tờ trình quyết định
			ToTrinh_Upd() {
				this.editItem.DSToTrinhAnPham = this.editItem.DSToTrinhAnPham.map(item => ({ AnPhamID: item.AnPhamID }))
				ajaxCALL("/ToTrinh_Udp", {
					ToTrinhObj: this.editItem.ToTrinhObj,
					AnPhamObjArr: this.editItem.DSToTrinhAnPham
				}, (res) => {
					this.close()
					CALL("ToTrinhGetAll")
					CALL("ToTrinhAnPhamGet")
					Vue.$toast.success("Cập nhật tờ trình thành công", { position: "top" })
				}, (err) => {
					console.log("ins", err)
					Vue.$toast.warning("Cập nhật tờ trình thất bại", { position: "top" })
				})
			},
			//Hàm cập nhật số quyết định
			sqd_update() {
				this.editItem.DSToTrinhAnPham = this.editItem.DSToTrinhAnPham.map(item => ({ AnPhamID: item.AnPhamID }))
				ajaxCALL("/ToTrinh_Udp", {
					ToTrinhObj: this.editItem.ToTrinhObj,
					AnPhamObjArr: this.editItem.DSToTrinhAnPham
				}, (res) => {
					this.closeUpdSQD()
					CALL("ToTrinhGetAll")
					CALL("ToTrinhAnPhamGet")
					Vue.$toast.success("Cập nhật số quyết định thành công", { position: "top" })
				}, (err) => {
					console.log("ins", err)
					Vue.$toast.warning("Cập nhật số quyết định thất bại", { position: "top" })
				})
			},
			//Nút cập nhật số quyết định
			btn_updateSQD(item) {
				this.editedIndex = this.DSToTrinh.indexOf(item)
				ajaxCALL("/ToTrinh_Get_ByToTrinhID", {
					ToTrinhID: item.ToTrinhID
				}, res => {
					this.editItem.ToTrinhObj = res.data[0][0]
					this.editItem.DSToTrinhAnPham = res.data[2]
					this.dialogUpdSQD = true
				}, err => {
					console.log(err)
				})
			}
		},
	}
</script>