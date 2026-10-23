<template>
	<v-card>
		<v-card-title>
			<span class="primary--text me-5">Danh sách tác giả</span>
			<v-select v-model="anphamobj.HinhThucThanhToan" hide-details="" dense="" outlined="" class="me-3" :items="HinhThucThanhToan" item-text="TenHinhThuc" item-value="HinhThucID" label="Hình thức thanh toán" style="max-width:300px" readonly=""></v-select>
			<v-select v-model="anphamobj.NguonCapKinhPhi" :items="KhoaNCKH" :item-text="display_DonVi" item-value="DepartmentID" hide-details="" dense="" outlined="" label="Nguồn cấp kinh phí" readonly="" style="max-width:350px"></v-select>
		</v-card-title>
		<div class="div-mobile div-window">
			<div class="ms-5">
				<p class="mb-0">
					<span class="font-weight-bold text-title">Tổng số tác giả:
						{{AnPhamObj.TongSoTacGia===null?0:AnPhamObj.TongSoTacGia}}</span>
				</p>
				<p class="mb-0">
					<span class="font-weight-bold text-title">Tổng số tác giả LHU: {{AnPhamObj.SoTacGia_LHU}}</span>
				</p>
				<p class="mb-0">
					<span v-if="NguoiDaiDien" class="font-weight-bold text-title">Người đại diện nhận tiền:
						{{NguoiDaiDien.HoTacGia}} {{NguoiDaiDien.TenTacGia}}</span>
				</p>
			</div>
			<v-spacer></v-spacer>
			<div class="me-5 ms-5" style="width:400px">
				<v-row>
					<v-col cols="9" class="d-flex flex-column ">
						<b class="primary--text text-right">Phí hỗ trợ đăng bài (HTĐB):</b>
						<b class="primary--text text-right">Tiền khen thưởng bài báo (KTBB):</b>
						<b class="primary--text text-right">Tổng tiền bài báo (Phí HTĐB + Tiền KTBB):</b>
					</v-col>
					<v-col cols="3" class="d-flex flex-column ">
						<span class="success--text font-weight-bold text-title text-right">
							{{formatAsCurrency(TongHoanPhiDangBai,0)}}
						</span>
						<span class="success--text font-weight-bold text-title text-right">
							{{formatAsCurrency(TongTienTacGia,0)}}
						</span>
						<span class="success--text font-weight-bold text-title text-right">
							{{formatAsCurrency((TongTienTacGia + TongHoanPhiDangBai),0)}}
						</span>
					</v-col>
				</v-row>

			</div>
		</div>
		<v-card-text>
			<v-data-table :headers="computedHeaders" :items="AuthorsObjArr" mobile-breakpoint="600" height="auto">
				<template v-slot:item.thongtincanhan="{ item }">
					<p class="mb-0"><span class="blue--text">{{item.MaNhanVien}}</span> </p>
					<p class="mb-0"><span class="green--text"><b>{{item.HoTacGia}} {{item.TenTacGia}}</b></span></p>
					<p class="mb-0"><span class="gray--text"><i>{{item.EmailTacGia}}</i></span></p>
				</template>
				<template v-slot:item.checkbox="{ item }">
					<div class="d-flex justify-center align-center">
						<v-checkbox class="mt-4" v-model="item.NguoiDaiDienQuyetToan" readonly=""></v-checkbox>
					</div>
				</template>
				<template v-slot:item.thongtinnganhang="{ item }" id="height-mb">
					<p class="mb-0"><span class="blue--text">{{item.SoTaiKhoan}}</span></p>
					<p class="mb-0"><span class="green--text">{{item.NganHang}}</span></p>
					<p class="mb-0"><span class="gray--text">{{item.TenChuTaiKhoan}}</span></p>
				</template>
				<template v-slot:item.is_nhanvien="{ item }">
					<div class="d-flex flex-wrap" style="gap: 4px;">
						<v-chip outlined v-if="item.Is_TacGiaChinh" small class="font-weight-bold" color="warning">Tác giả chính</v-chip>
						<v-chip outlined v-if="item.Is_TacGiaPhu" small class="font-weight-bold" color="info">Tác giả phụ</v-chip>
						<v-chip outlined v-if="item.Is_TacGiaLienHe" small class="font-weight-bold" color="purple">Tác giả liên hệ</v-chip>
						<v-chip outlined v-if="item.TacGiaGroupID===1" small class="font-weight-bold" color="primary">GV/NV LHU</v-chip>
						<v-chip outlined v-if="item.TacGiaGroupID===2" small class="font-weight-bold" color="primary">Học viên LHU</v-chip>
						<v-chip outlined v-if="item.TacGiaGroupID===3" small class="font-weight-bold" color="grey darken-1">Ngoài LHU</v-chip>
					</div>
				</template>
				<template v-slot:item.is_tacgiachinh="{ item }">
					<v-icon v-if="item.Is_TacGiaChinh " color="success">mdi-check</v-icon>
				</template>
				<template v-slot:item.sotienkhenthuong="{ item }">
					<span>{{item.SoTienKhenThuong?formatAsCurrency(item.SoTienKhenThuong): 0 }}</span>
				</template>
				<template v-slot:item.sotienhoanphidangbai="{ item }">
					<span>{{item.SoTienHoanPhiDangBai?formatAsCurrency(item.SoTienHoanPhiDangBai): 0 }}</span>
				</template>

			</v-data-table>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		props: ["value", "anphamid", "dsnganhang", "tongtacgia", "tongtacgialhu", "anphamobj"],
		data: () => ({
			headersAuthorsObj: [
				{ text: 'Vị trí', sortable: false, value: "STT", align: "center" },
				{ text: 'AP Index', sortable: false, value: "AP_Index", align: "center" },
				{ text: 'Vai trò', sortable: false, value: "is_nhanvien", align: "center", width: '200' },
				{ text: 'Thông tin cá nhân', sortable: false, value: 'thongtincanhan' },
				{ text: 'Thông tin ngân hàng', sortable: false, value: 'thongtinnganhang' },
				{ text: 'Đơn vị', sortable: false, value: "TenPhongBan" },
				{ text: 'Tiền khen thưởng (VNĐ)', sortable: false, value: 'sotienkhenthuong', align: "right" },
				{ text: 'Hoàn phí đăng (VNĐ)', sortable: false, value: 'sotienhoanphidangbai', align: "right" }
			],
			KhoaNCKH: [],
			HinhThucThanhToan: [
				{ TenHinhThuc: "Cá nhân đại diện", HinhThucID: 1 },
				{ TenHinhThuc: "Phân bổ cho từng thành viên", HinhThucID: 2 }
			],
	
		}),
		computed: {
			computedHeaders() {
				return this.anphamobj.HinhThucThanhToan === 1 ? [{
					text: 'Đại diện nhận tiền', value: 'checkbox', sortable: false,
					align: 'center'
				}, ...this.headersAuthorsObj] : this.headersAuthorsObj
			},
			NguoiDaiDien() {
				return this.value.find(item => item.NguoiDaiDienQuyetToan === true)
			},
			AuthorsObjArr() {
				return this.value
			},
			NganHangArr: function () {
				return this.nganhangarr
			},
			DSNganHang: function () {
				return this.dsnganhang
			},
			TongTacGia: function () {
				return this.tongtacgia
			},
			TongTacGiaLHU: function () {
				return this.tongtacgialhu
			},
			AnPhamObj: function () {
				return this.anphamobj
			},
			TongTienTacGia: function () {
				let sum = 0
				let authors = this.value
				if (authors) {
					authors.forEach(item => {
						item.SoTienKhenThuong = item.SoTienKhenThuong ?? 0
						sum += item.SoTienKhenThuong
					})
				}
				return sum
			}, TongHoanPhiDangBai: function () {
				let sum = 0
				let authors = this.value
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
		},
		created() {
			this.getKhoaNCKH()
		},
		methods: {
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
		}
	}
</script>