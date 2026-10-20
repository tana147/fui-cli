<template>
	<div>
		<div class="d-flex pt-2" style="gap:10px">
			<v-select outlined="" dense="" persistent-hint="" v-model="AnPhamObj.CongThucKhenThuongID" label="Công thức khen thưởng" :items="DSCongThucKhenThuong" item-text="DieuKhoanApDung" item-value="CongThucKhenThuongID" @change="PhiKhenThuong_Cal" :hint="detailCTKhenThuong(AnPhamObj.CongThucKhenThuongID)"></v-select>
			<v-btn @click="PhiKhenThuong_Cal" outlined="" color="primary"> Tính tiền</v-btn>
		</div>
		<v-card>
			<v-card-title>
				<span class="primary--text me-5">Danh sách tác giả</span>
				<v-select v-model="anphamobj.HinhThucThanhToan" hide-details="" dense="" outlined="" class="me-3" :items="HinhThucThanhToan" item-text="TenHinhThuc" item-value="HinhThucID" label="Hình thức thanh toán" style="max-width:300px" readonly=""></v-select>
			</v-card-title>
			<div class="div-mobile div-window">
				<div class="ms-5">
					<p class="mb-0">
						<span class="font-weight-bold text-title primary--text">Tổng số tác giả:
							<span class="success--text">{{ AnPhamObj.TongSoTacGia === null ? 0 : AnPhamObj.TongSoTacGia
								}}</span></span>
					</p>
					<p class="mb-0">
						<span class="font-weight-bold text-title primary--text">Tổng số tác giả LHU: <span class="success--text">{{ AnPhamObj.SoTacGia_LHU }}</span></span>
					</p>
					<p class="mb-0">
						<span v-if="NguoiDaiDien" class="font-weight-bold text-title primary--text">Người đại diện nhận
							tiền:
							<span class="success--text">{{ NguoiDaiDien.HoTacGia }}
								{{ NguoiDaiDien.TenTacGia }}</span></span>
					</p>
				</div>
				<v-spacer></v-spacer>
				<div class="me-5 ms-5" style="width:400px">
					<v-row>
						<v-col cols="9" class="d-flex flex-column ">
							<b class="primary--text text-right">Phí hỗ trợ đăng bài (HTĐB):</b>
							<b class="primary--text text-right">Tiền khen thưởng bài báo (KTBB):</b>
							<b class="primary--text text-right">Tổng tiền bài báo (Phí HTĐB + Tiền KTBB):</b>
							<!-- <v-text-field v-model="value.AuthorsObjArr[0].TenTacGia"></v-text-field><p>{{value.AuthorsObjArr[0].TenTacGia}}</p> -->
						</v-col>
						<v-col cols="3" class="d-flex flex-column ">
							<span class="success--text font-weight-bold text-title text-right">
								{{ formatAsCurrency(TongHoanPhiDangBai, 0) }}
							</span>
							<span class="success--text font-weight-bold text-title text-right">
								{{ formatAsCurrency(TongTienTacGia, 0) }}
							</span>
							<span class="success--text font-weight-bold text-title text-right">
								{{ formatAsCurrency((TongTienTacGia + TongHoanPhiDangBai), 0) }}
							</span>
						</v-col>
					</v-row>
				</div>
			</div>
			<v-card-text>
				<v-data-table :headers="computedHeaders" :items="value.AuthorsObjArr">
					<template v-slot:item.thongtincanhan="{ item }">
						<p class="mb-0"><span class="blue--text">{{ item.MaNhanVien }}</span> </p>
						<p class="mb-0"><span class="green--text"><b>
									{{ item.HoTacGia }}
									{{ item.TenTacGia }}</b></span></p>
						<p class="mb-0"><span class="gray--text"><i>{{ item.EmailTacGia }}</i></span></p>
					</template>
					<template v-slot:item.thongtinnganhang="{ item }">
						<p class="mb-0"><span class="blue--text">{{ item.SoTaiKhoan }}</span></p>
						<p class="mb-0"><span class="green--text">{{ item.NganHang }}</span></p>
						<p class="mb-0"><span class="gray--text">{{ item.TenChuTaiKhoan }}</span></p>
					</template>
					<template v-slot:item.checkboxx="{ item }">
						<div class="d-flex justify-center align-center">
							<v-checkbox v-model="item.checkboxHSCL" color="primary" class="align-center" @click="isSelectCheckbox(item)"></v-checkbox>
						</div>
					</template>
					<template v-slot:item.sotienkhenthuongtamtinh="{ item }">
						<uc-format-price-tac-gia v-model="item.SoTienKhenThuongTamTinh" :readonly="true" :style="{ background: '#E0F7FA' }" :ct_khenthuongid="AnPhamObj.CongThucKhenThuongID">
						</uc-format-price-tac-gia>
					</template>
					<template v-slot:item.sotienkhenthuong="{ item }">
						<uc-format-price-tac-gia v-model="item.SoTienKhenThuong" :style="{ background: '#fffbe9' }" :ct_khenthuongid="AnPhamObj.CongThucKhenThuongID"></uc-format-price-tac-gia>
					</template>
					<template v-slot:item.hoanphidangbai="{ item }">
						<uc-format-price-tac-gia v-model="item.SoTienHoanPhiDangBai" :style="{ background: '#fffbe9' }" :ct_khenthuongid="AnPhamObj.CongThucKhenThuongID"></uc-format-price-tac-gia>
					</template>
					<template v-slot:item.checkbox="{ item }">
						<div class="d-flex justify-center align-center">
							<v-checkbox class="mt-4" v-model="item.NguoiDaiDienQuyetToan" readonly=""></v-checkbox>
						</div>
					</template>
					<template v-slot:item.is_nhanvien="{ item }">
						<v-chip outlined="" v-if="item.Is_TacGiaChinh" small="" class="font-weight-bold mb-2" color="warning">
							Tác giả liên hệ</v-chip>
						<v-chip outlined="" v-if="item.TacGiaGroupID === 1" small="" class="font-weight-bold" color="primary">
							Giảng viên LHU</v-chip>
						<v-chip outlined="" v-if="item.TacGiaGroupID === 2" small="" class="font-weight-bold" color="primary">
							Học viên LHU</v-chip>
						<v-chip outlined="" v-if="item.TacGiaGroupID === 3" small="" class="font-weight-bold" color="warning">
							Tác giả bên ngoài LHU</v-chip>
					</template>
					<template v-slot:item.is_tacgiachinh="{ item }">
						<v-icon v-if="item.Is_TacGiaChinh" color="success">mdi-check</v-icon>
					</template>
				</v-data-table>
			</v-card-text>
		</v-card>
	</div>
</template>

<script>
	export default {
		props: ["value", "anphamid", "dsnganhang", "anphamobj", "dskhenthuong",'flagUpdateHSCL'],
		emits:['onhandleflaghscl'],
		data: () => ({
			headersAuthorsObj: [
				{ text: 'Vị trí', sortable: false, value: "STT", align: "center" },
				{ text: 'AP Index', sortable: false, value: "AP_Index", align: "center" },
				{ text: 'Vai trò', sortable: false, value: "is_nhanvien", align: "center", width: '200' },
				{ text: 'Thông tin cá nhân', sortable: false, value: "thongtincanhan" },
				{ text: 'Thông tin ngân hàng', sortable: false, value: "thongtinnganhang" },
				{ text: 'Đơn vị', sortable: false, value: "TenPhongBan" },
				{ text: 'Nguồn cấp kinh phí', sortable: false, value: "NguonCapKinhPhi" },
				{ text: 'Tiền khen thưởng(Tạm tính)', value: "sotienkhenthuongtamtinh", sortable: false },
				{ text: 'Tiền khen thưởng(Đã lưu)', value: 'sotienkhenthuong', sortable: false },
				{ text: 'Hoàn phí đăng bài', value: 'hoanphidangbai', sortable: false },
			],
			KhoaNCKH: [],
			HinhThucThanhToan: [
				{ TenHinhThuc: "Cá nhân đại diện", HinhThucID: 1 },
				{ TenHinhThuc: "Phân bổ cho từng thành viên", HinhThucID: 2 }
			],
		}),
		computed: {
			computedHeaders() {
				let head = this.headersAuthorsObj
				let customHeaders = []
				if (this.anphamobj.HinhThucThanhToan === 1) {
					customHeaders.push({
						text: 'Đại diện nhận tiền', value: 'checkbox', sortable: false,
						align: 'center'
					})
				}
				if (this.AnPhamObj.NhomAnPham === 3) {
					customHeaders.push({ text: '*HSCL (=1.2)', sortable: false, value: "checkboxx", align: "center" })
				}
				return [...customHeaders, ...head]
			},
			NguoiDaiDien() {
				return this.value.AuthorsObjArr?.find(item => item.NguoiDaiDienQuyetToan === true)
			},
			AuthorsObjArr() {
				return this.value.AuthorsObjArr
			},
			AnPhamObj: function () {
				return this.anphamobj
			},
			DSCongThucKhenThuong: function () {
				return this.dskhenthuong
			},
			TongTienTacGia: function () {
				let sum = 0
				let authors = this.value.AuthorsObjArr
				if (authors) {
					authors.forEach(item => {
						item.SoTienKhenThuong = item.SoTienKhenThuong ?? 0
						sum += item.SoTienKhenThuong
					})
				}
				return sum
			}, TongHoanPhiDangBai: function () {
				let sum = 0
				let authors = this.value.AuthorsObjArr
				if (authors) {
					authors.forEach(item => {
						item.SoTienHoanPhiDangBai = item.SoTienHoanPhiDangBai ?? 0
						sum += item.SoTienHoanPhiDangBai
					})
				}
				return sum
			}
		},
		watch: {
			"AnPhamObj.HoanPhiDangBai": function (val) {
				let AuthorsIsNhanVienLHU = this.value.AuthorsObjArr.filter(item => {
					return item.TacGiaGroupID === 1 || item.TacGiaGroupID === 2
				})
				let AuthorHoanPhiDangBai = []
				//Nếu bài báo được chọn là có người đại diện nhận tiền 
				if (this.value.AnPhamObj.HinhThucThanhToan === 1) {
					AuthorHoanPhiDangBai = this.AuthorsObjArr.map(item => {
						//TacGiaGroupID(1: Giảng viên LHU, 2: Học viên LHU, 3: Tác giả ngoài LHU)
						if (item.TacGiaGroupID === 1 && item.NguoiDaiDienQuyetToan === true || item.TacGiaGroupID === 2 && item.NguoiDaiDienQuyetToan === true) {
							item.SoTienHoanPhiDangBai = val
						} else {
							item.SoTienHoanPhiDangBai = 0
						}
						return { ...item }
					})
				}
				//Nếu bài báo được chọn là phân bổ cho các thành viên
				else {
					let HoanPhiDangBaiAuthor = val / AuthorsIsNhanVienLHU.length
					AuthorHoanPhiDangBai = this.AuthorsObjArr.map(item => {
						//Điều kiện để chia tiền cho các thành viên: Giảng viên/ nhân viên LHU (TacGiaGroupID = 1),Học viên LHU (TacGiaGroupID = 2)
						if (item.TacGiaGroupID === 1 || item.TacGiaGroupID === 2) {
							item.SoTienHoanPhiDangBai = HoanPhiDangBaiAuthor
						}
						item.SoTienHoanPhiDangBai = item.SoTienHoanPhiDangBai > item.SoTienKhenThuongTamTinh ? item.SoTienKhenThuongTamTinh : item.SoTienHoanPhiDangBai
						return item
					})
				}
				this.$emit("input", {
					...this.value,
					AuthorsObjArr: AuthorHoanPhiDangBai
				})
			}
		},
		created() {
			this.getKhoaNCKH()
		},
		mounted() {
		},
		methods: {
			//Hàm xử lý checkbox nhân hệ số 
			isSelectCheckbox(item) {
				// this.$emit('onhandleflaghscl',true)
				this.$emit('onhandleflaghscl')
				// console.log('thiss.flagUpdateHSCL',this.flagUpdateHSCL)
				if (item.checkboxHSCL) {
					this.SoTienNhanHSCl(item)
				} else {
					this.SoTienChiaHSCl(item)
				}
			},
			//Hàm nếu bỏ chọn nhân hệ số cho 1
			SoTienChiaHSCl(item) {
				this.value.AuthorsObjArr.map(i => {
					if (i.AnPhamTacGiaID == item.AnPhamTacGiaID) {
						i.HeSoHoTroCaoHoc = 1
					}
				})
			},
			//Hàm nếu chọn nhân hệ số cho 1.2
			SoTienNhanHSCl(item) {
				this.value.AuthorsObjArr.map(i => {
					if (i.AnPhamTacGiaID == item.AnPhamTacGiaID) {
						i.HeSoHoTroCaoHoc = 1.2
					}
				})
			},
			display_DonVi(item) {
				let text = item.DepartmentID + " - " + item.DepartmentName
				return text
			},
			getKhoaNCKH() {
				ajaxCALL("https://tapi.lhu.edu.vn/hoso/Public_SelectPhongBan", null, (res) => {
					this.KhoaNCKH = res.data
				}, (err) => {
				})
			},
			detailCTKhenThuong(CTID) {
				let text = ""
				if (CTID) {
					text = this.DSCongThucKhenThuong.find(item => item.CongThucKhenThuongID === CTID).CongThucHTML
				}
				return text
			},
			PhiKhenThuong_Cal() {
				let anpham = this.AnPhamObj
				//Gọi API tính tiền đăng bài mỗi lần gọi API khen thưởng
				ajaxCALL("/PhiDangBai_Cal", {
					AnPhamID: this.AnPhamObj.AnPhamID
				}, (res) => {
					this.value.AnPhamObj.HoanPhiDangBaiTamTinh = res.data[0].HoTroPhiDangBai
					this.value.AnPhamObj.HoanPhiDangBai = this.value.AnPhamObj.HoanPhiDangBaiTamTinh
					let AuthorsIsNhanVienLHU = this.value.AuthorsObjArr.filter(item => {
						return item.TacGiaGroupID === 1 || item.TacGiaGroupID === 2
					})
					//Nếu bài báo được chọn là có người đại diện nhận tiền 
					if (this.value.AnPhamObj.HinhThucThanhToan === 1) {
						this.value.AuthorsObjArr = this.value.AuthorsObjArr.map(item => {
							//TacGiaGroupID(1: Giảng viên LHU, 2: Học viên LHU, 3: Tác giả ngoài LHU)
							if (item.TacGiaGroupID === 1 && item.NguoiDaiDienQuyetToan === true || item.TacGiaGroupID === 2 && item.NguoiDaiDienQuyetToan === true) {
								item.SoTienHoanPhiDangBai = this.value.AnPhamObj.HoanPhiDangBai
							} else {
								item.SoTienHoanPhiDangBai = 0
							}
							return { ...item }
						})
					}
					//Nếu bài báo được chọn là phân bổ cho các thành viên
					else {
						let TienDangBai = this.value.AnPhamObj.HoanPhiDangBai / AuthorsIsNhanVienLHU.length
						this.value.AuthorsObjArr = this.value.AuthorsObjArr.map(item => {
							//Điều kiện để chia tiền cho các thành viên: Giảng viên/ nhân viên LHU (TacGiaGroupID = 1),Học viên LHU (TacGiaGroupID = 2)
							if (item.TacGiaGroupID === 1 || item.TacGiaGroupID === 2) {
								item.SoTienHoanPhiDangBai = TienDangBai
								return { ...item }
							} else {
								return { ...item }
							}
						})
					}
				}, (error) => {
					Vue.$toast.error(error.responseJSON.Message, { position: "top" })
				})
				//API tính tiền khen thưởng cho tác giả
				if (anpham.CongThucKhenThuongID && anpham.CongThucKhenThuongID > 0) {
					return new Promise((resolve, reject) => {
						ajaxCALL("/PhiKhenThuong_Cal", {
							AnPhamID: this.AnPhamObj.AnPhamID,
							CongThucKhenThuongID: this.AnPhamObj.CongThucKhenThuongID,
							DiemHoiDong: this.AnPhamObj.DiemHoiDong ?? 0,
							HeSo_IF: this.AnPhamObj.HeSo_IF,
							HeSoChatLuongID: this.AnPhamObj.HeSoChatLuongID ?? 0
						}, (res) => {
							let data = res.data
							resolve(data)
							if (data.length > 0) {
								let AuthorArr = this.AuthorsObjArr.map((item, index) => {
									item.SoTienKhenThuong = data[index].KhenThuong
									return {
										...item,
										SoTienKhenThuongTamTinh: data[index].KhenThuong,
										CongThucKhenThuongID: anpham.CongThucKhenThuongID,
										NoiDungCongThucKhenThuong: ""
									}
								})
								//Kiểm tra nếu số tiền đăng bài không được vượt quá số tiền khen thưởng
								AuthorArr.map(item => {
									if (item.SoTienHoanPhiDangBai > item.SoTienKhenThuongTamTinh) {
										item.SoTienHoanPhiDangBai = item.SoTienKhenThuongTamTinh
									}
									return item
								})
								this.value.AuthorsObjArr = AuthorArr
								this.$emit("input", {
									...this.value,
									AuthorsObjArr: AuthorArr
								})
							}
						}, (error) => {
							reject(error)
							return Vue.$toast.warning(error.responseJSON.Message, { position: "top" })
						})
					})
				}
			}
		},
	}
</script>