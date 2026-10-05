<template>
	<div>
		<v-card>
			<v-card-title style="border-bottom: thin solid rgba(0, 0, 0, .12)">
				<span class="primary--text">Danh sách ấn phẩm của tôi</span>
				<v-spacer></v-spacer>
				<v-select v-model="NhomAnPhamID" style="max-width:400px" :items="DSBaiBaoChange" item-text="TenLoai"
				item-value="LoaiID" label="Nhóm ấn phẩm" class="me-3" outlined dense hide-details
				@change="filterNhomAnPham"></v-select>
				<v-text-field v-model="search" prepend-icon="mdi-filter-outline" label="Tìm kiếm" single-line
					style="max-width:400px;margin-right:10px"></v-text-field>
			</v-card-title>
			<v-card-text>
				<v-data-table :headers="headersArticlesObj" light :items="DSBaiBao" mobile-breakpoint="600"
					:search="search" hide-default-footer="true"
					:footer-props="{'items-per-page-options':[50, 100, 150, -1]}">
					<template v-slot:item.TrangThai={item}>
						<v-chip :color="getColorStatusAnPham(item.TrangThaiID)">
							{{item.TrangThai}}
						</v-chip>
					</template>
					<template v-slot:top>

						<v-dialog v-model="dialog" max-width="1500px">
							<v-card>
								<v-card-title>
									<span class="text-h5 primary--text">Chi tiết ấn phẩm</span>
									<v-spacer></v-spacer>
									<v-btn fab small icon @click="close">
										<v-icon>mdi-close</v-icon>
									</v-btn>
								</v-card-title>
								<v-card-text>
									<uc-an-pham ref="FormAnPham" class="mb-5" v-model="editedItem"
										:danhmuctapchiarr="DanhMucTapChiArr"
										:danhmucloaianphamarr="DanhMucLoaiAnPhamArr" :namarr="NamArr"
										:dshesochatluong="DSHeSoChatLuong" :editedindex="editedIndex">
									</uc-an-pham>
									<uc-table-tac-gia ref="checkTG" v-model="editedItem.AuthorsObjArr"
										:anphamid="editedItem.AnPhamObj.AnPhamID"
										:tongtacgialhu="editedItem.AnPhamObj.SoTacGia_LHU"
										:tongtacgia="editedItem.AnPhamObj.TongSoTacGia" :dsnganhang="DSNganHang"
										:anphamobj="editedItem.AnPhamObj"></uc-table-tac-gia>
								</v-card-text>

								<v-card-actions>
									<v-spacer></v-spacer>
									<v-btn @click="dialog = false">Đóng</v-btn>

								</v-card-actions>
							</v-card>
						</v-dialog>
					</template>
					<template v-slot:item.nhomanpham="{ item }">
					<v-chip outlined color="primary" v-if="item.NhomAnPham===1">Ấn phẩm khoa học</v-chip>
					<v-chip v-if="item.NhomAnPham===2" outlined color="success">Hỗ trợ Đầu vào Cao học</v-chip>
					<v-chip v-if="item.NhomAnPham===3" outlined color="orange">Có hướng dẫn Cao học</v-chip>
				</template>
					<template v-slot:item.actions="{ item }">
						<div class="d-flex flex-row ">
							<v-icon style="font-size:18px" color="green darken-2" small class="mr-2"
								@click="editItem(item)">
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
		props: ["dsbaibao", "dsdanhmuctapchi", "dsdanhmucloaianpham", "dsnam", "dscongthuckhenthuong", "dshesochatluong"],
		data: () => ({
			dialog: false,
			search: "",
			dialogDelete: false,
			isLoadingSave: false,
			headersArticlesObj: [
				{ text: 'STT', sortable: false, value: "STT" },
				{ text: 'Tên bài báo', sortable: false, value: "TenAnPham" },
				{ text: 'Tác giả', sortable: false, value: "TacGia", width: '200' },
				{ text: 'Đơn vị', value: "DonViDaiDien", width: '100' },
				{ text: 'Danh mục bài báo/ấn phẩm', sortable: false, value: 'TenLoaiAnPham', },
				{ text: 'Tên tạp chí', sortable: false, value: 'TenTapChi' },
				{ text: 'Loại tạp chí', sortable: false, value: "TenLoaiDanhMucTapChi", },
				{ text: 'Nơi đăng', sortable: false, value: "NoiDangBai", width: '150' },
				{ text: 'Năm đăng', sortable: false, value: "NamDangBai", width: '100', align: "center" },
				{ text: 'Nhóm ấn phẩm', value: "nhomanpham", sortable: false },
				{ text: 'Trạng thái', sortable: false, value: "TrangThai", width: '100', align: "center" },
				{ text: 'Thao tác', value: "actions", sortable: false },
			],
			fileRules: {
				"max_file_size": "100mb",
				"mime_types": [
					{
						"title": "All files",
						"extensions": "jpg,doc,png,pdf,docx,xlsx,xls,ppt,jpeg"
					}
				]
			},
			editedIndex: -1,
			editedItem: {
				AnPhamObj: {
					TenAnPham: '',
					LoaiAnPhamID: null,
					TenLoaiAnPham: "",
					TenTapChi: '',
					DanhMucLoaiTapChiID: null,
					TenLoaiDanhMucTapChi: "",
					LoaiSubAnPhamID: null,
					TenLoaiSubAnPham: "",
					NoiDangBai: 'Trong nước',
					NamDangBai: new Date().getFullYear(),
					DuongDanBaiBao: '',
					HeSo_IF: convertDiem(0),
					TrangThai: '',
					MaNhanVienDaiDien: "",
					TenNhanVienDaiDien: "",
					DonViDaiDien: "",
					SoTacGia_LHU: 0,
					DiemHoiDong: convertDiem(0),
					TenHeSoChatLuong: null,
					DiemHeSoChatLuong: 0,
					PhiThongBao: 0,
					PhiDangBai: 0,
					HoanPhiDangBai: 0,
					ISSN: "",
					Dieu: null,
					Khoan: null,
					Muc: null,
					TongSoTienThuong: 0,
					GhiChu: "",
					SoQuyetDinhKhenThuong: null,
					FileIDKhenThuong: null,
					TongSoTacGia: 0,
					HinhThucThanhToan: 2,
					NguonCapKinhPhi: null
				},
				AuthorsObjArr: [],
				ProofsObjArr: [
					{
						LoaiFile: 2,
						FileIDList: "",
						FileList: [],
						MoTa: ""
					}
				]
			},
			LoaiFileMinhChung: [],
			defaultItem: {
				AnPhamObj: {
					TenAnPham: '',
					LoaiAnPhamID: null,
					TenLoaiAnPham: "",
					TenTapChi: '',
					DanhMucLoaiTapChiID: null,
					TenLoaiDanhMucTapChi: "",
					LoaiSubAnPhamID: null,
					TenLoaiSubAnPham: "",
					NoiDangBai: 'Trong nước',
					NamDangBai: new Date().getFullYear(),
					DuongDanBaiBao: '',
					HeSo_IF: convertDiem(0),
					TrangThai: '',
					MaNhanVienDaiDien: "",
					TenNhanVienDaiDien: "",
					DonViDaiDien: "",
					SoTacGia_LHU: 0,
					DiemHoiDong: convertDiem(0),
					TenHeSoChatLuong: null,
					DiemHeSoChatLuong: 0,
					PhiThongBao: 0,
					PhiDangBai: 0,
					HoanPhiDangBai: 0,
					ISSN: "",
					Dieu: null,
					Khoan: null,
					Muc: null,
					TongSoTienThuong: 0,
					GhiChu: "",
					SoQuyetDinhKhenThuong: null,
					FileIDKhenThuong: null,
					TongSoTacGia: 0,
					HinhThucThanhToan: 2,
					NguonCapKinhPhi: null
				},
				AuthorsObjArr: [],
				ProofsObjArr: [
					{
						LoaiFile: 2,
						FileIDList: "",
						FileList: [],
						MoTa: ""
					}
				]
			},
			ID: null,
			DSNganHang: null,
			TrangThai: null,
			DMTC_Arr: [],
			TenDMTC_Arr: [],
			DSBaiBao:[],
			NhomAnPhamID:4,
			LoaiBaiBao: [
				{ TenLoai: "Ấn phẩm khoa học", LoaiID: 1 },
				{ TenLoai: "Hỗ trợ Đầu vào Cao học", LoaiID: 2 },
				{ TenLoai: "Có hướng dẫn Cao học", LoaiID: 3 }
			],
	
		}),
	
		computed: {
			formTitle() {
				return this.editedIndex === -1 ? 'Thêm mới bài báo' : 'Chi tiết bài báo'
			},
			DSBaiBaoChange() {
				let arrChange = this.LoaiBaiBao
				arrChange.push({ TenLoai: "Tất cả", LoaiID: 4 })
				return arrChange
			},
			DanhMucTapChiArr() {
	
				return this.dsdanhmuctapchi
			},
			DanhMucLoaiAnPhamArr() {
				return this.dsdanhmucloaianpham
			},
			NamArr() {
				return this.dsnam
			},
			DSHeSoChatLuong() {
				return this.dshesochatluong
			}
		},
		watch: {
			dsbaibao(val){
				this.DSBaiBao = val
			},
			dialog(val) {
				val || this.close()
			},
		},
		created() {
		},
		methods: {
			openDialog() {
				this.dialog = true
				this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj)
				this.editedItem.AuthorsObjArr = Object.assign([], this.defaultItem.AuthorsObjArr)
				this.editedItem.ProofsObjArr = Object.assign([], this.defaultItem.ProofsObjArr)
			},
			//Hàm xử lý chọn sửa bài báo
			editItem(item) {
				ajaxCALL("/AnPham_Get_ByAnPhamID", {
					"AnPhamID": item.AnPhamID
				}, (res) => {
					let anphamobj = res.data[0][0]
					let authorobjarr = res.data[1]
					let proofsobjarr = res.data[2]
					anphamobj.HeSo_IF = convertDiem(anphamobj.HeSo_IF)
					anphamobj.DiemHoiDong = convertDiem(anphamobj.DiemHoiDong)
					this.editedItem.AnPhamObj = anphamobj
					this.editedItem.AuthorsObjArr = authorobjarr
					//Kiểm tra xem file minh chứng có dữ liệu ko? thì mới đi parseString item.FileList
					if (proofsobjarr.length > 0) {
						this.editedItem.ProofsObjArr = proofsobjarr.map((item) => {
							if (item.FileList) {
								let jsonParse = JSON.parse(item.FileList)
								return { ...item, FileList: jsonParse }
							} else {
								return { ...item, FileList: [] }
							}
						})
					}
					this.editedIndex = this.DSBaiBao.indexOf(item)
					this.dialog = true
					this.getDM_By_LoaiAnPhamID_from_parent()
					this.getDM_By_LoaiSubAnPhamID_from_parent()
				}, (err) => {
					console.log(err)
				})
	
			},
	
			//Hàm đóng dialog khi mở chỉnh sửa bài báo
			close() {
				this.dialog = false
				this.$nextTick(() => {
					this.editedItem.AnPhamObj = Object.assign({}, this.defaultItem.AnPhamObj)
					this.editedItem.AuthorsObjArr = Object.assign([], this.defaultItem.AuthorsObjArr)
					this.editedItem.ProofsObjArr[0].FileList = []
					this.editedIndex = -1
					this.$refs.FormAnPham.TenDMTC_Arr = []
					this.$refs.FormAnPham.DMTC_Arr = []
	
				})
	
			},
			//Hàm gọi function từ component uc-an-pham
			getDM_By_LoaiAnPhamID_from_parent() {
				this.$nextTick(async () => {
					await this.$refs.FormAnPham.getDM_By_LoaiAnPhamID_Edit()
				})
	
			},
			//Hàm gọi function từ component uc-an-pham
			getDM_By_LoaiSubAnPhamID_from_parent() {
				if (this.editedItem.AnPhamObj.LoaiSubAnPhamID) {
					this.$nextTick(async () => {
						await this.$refs.FormAnPham.getTenDMTC_By_LoaiAnPhamID_Edit()
					})
				}
			},
			filterNhomAnPham() {
				if (this.NhomAnPhamID === 4) {
					this.DSBaiBao = this.dsbaibao
				} else {
					this.DSBaiBao = this.dsbaibao.filter(item => { return item.NhomAnPham === this.NhomAnPhamID })
				}
			}
		},
	}
</script>