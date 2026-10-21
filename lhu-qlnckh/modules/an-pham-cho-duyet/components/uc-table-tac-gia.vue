<template>
	<div>
		<div class="d-flex pt-2" style="gap:10px">
			<v-select outlined="" dense="" persistent-hint="" v-model="AnPhamObj.CongThucKhenThuongID"
				label="Công thức khen thưởng" :items="DSCongThucKhenThuong" item-text="DieuKhoanApDung"
				item-value="CongThucKhenThuongID" @change="PhiKhenThuong_Cal"
				:hint="detailCTKhenThuong(AnPhamObj.CongThucKhenThuongID)"></v-select>
			<v-btn @click="PhiKhenThuong_Cal" outlined="" color="primary"> Tính tiền</v-btn>
		</div>
		<v-card outlined>
			<v-card-title class="px-3 py-2">
				<span class="primary--text subtitle-2 font-weight-bold me-5">Danh sách tác giả</span>
				<v-select v-model="anphamobj.HinhThucThanhToan" hide-details="" dense="" outlined="" class="me-3"
					:items="hinhThucThanhToan" item-text="TenHinhThuc" item-value="HinhThucID"
					label="Hình thức thanh toán" style="max-width:300px"
					:readonly="![1, 2, 9].includes(vueData.user.SystemRight)"></v-select>

			</v-card-title>
			<div class="div-mobile div-window">
				<div class="ms-5">
					<p class="mb-0">
						<span class="font-weight-bold text-title primary--text">Tổng số tác giả:
							<span class="success--text">{{ AnPhamObj.TongSoTacGia === null ? 0 : AnPhamObj.TongSoTacGia
								}}</span></span>
					</p>
					<p class="mb-0">
						<span class="font-weight-bold text-title primary--text">Tổng số tác giả LHU: <span
								class="success--text">{{ AnPhamObj.SoTacGia_LHU }}</span></span>
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
							<v-checkbox v-model="item.checkboxHSCL" color="primary" class="align-center"
								@click="isSelectCheckbox(item)"></v-checkbox>
						</div>
					</template>
					<template v-slot:item.hscl_05="{ item }">
						<div class="d-flex justify-center align-center">
							<v-checkbox v-model="item._hscl05" color="primary" class="mt-4"
								@click.stop="onToggleHSCL05(item)"></v-checkbox>
						</div>
					</template>
					<template v-slot:item.hscl_12="{ item }">
						<div class="d-flex justify-center align-center">
							<v-checkbox v-model="item._hscl12" color="primary" class="mt-4"
								@click.stop="onToggleHSCL12(item)"></v-checkbox>
						</div>
					</template>

					<template v-slot:item.hscl_15="{ item }">
						<div class="d-flex justify-center align-center">
							<v-checkbox v-model="item._hscl15" color="primary" class="mt-4"
								@click.stop="onToggleHSCL15(item)"></v-checkbox>
						</div>
					</template>
					<template v-slot:item.sotienkhenthuongtamtinh="{ item }">
						<uc-format-price-tac-gia v-model="item.SoTienKhenThuongTamTinh" :readonly="true"
							:style="{ background: '#E0F7FA' }" :ct_khenthuongid="AnPhamObj.CongThucKhenThuongID">
						</uc-format-price-tac-gia>
					</template>
					<template v-slot:item.sotienkhenthuong="{ item }">
						<uc-format-price-tac-gia v-model="item.SoTienKhenThuong" :style="{ background: '#fffbe9' }"
							:ct_khenthuongid="AnPhamObj.CongThucKhenThuongID"></uc-format-price-tac-gia>
					</template>
					<template v-slot:item.hoanphidangbai="{ item }">
						<uc-format-price-tac-gia v-model="item.SoTienHoanPhiDangBai" :style="{ background: '#fffbe9' }"
							:ct_khenthuongid="AnPhamObj.CongThucKhenThuongID"></uc-format-price-tac-gia>
					</template>
					<template v-slot:item.checkbox="{ item }">
						<div class="d-flex justify-center align-center">
							<v-checkbox class="mt-4" v-model="item.NguoiDaiDienQuyetToan"
								:readonly="![1, 2, 9].includes(vueData.user.SystemRight)" :multiple="false"
								@change="onCheckboxChange(item)"></v-checkbox>
						</div>
					</template>
					<template v-slot:item.is_nhanvien="{ item }">
						<v-chip outlined="" v-if="item.Is_TacGiaChinh" small="" class="font-weight-bold mb-2"
							color="warning">
							Tác giả chính</v-chip>
						<v-chip outlined="" v-if="item.Is_TacGiaPhu" small="" class="font-weight-bold mb-2"
							color="info">Tác
							giả phụ</v-chip>
						<v-chip outlined="" v-if="item.TacGiaGroupID === 1" small="" class="font-weight-bold"
							color="primary">
							Giảng viên LHU</v-chip>
						<v-chip outlined="" v-if="item.TacGiaGroupID === 2" small="" class="font-weight-bold"
							color="primary">
							Học viên LHU</v-chip>
						<v-chip outlined="" v-if="item.TacGiaGroupID === 3" small="" class="font-weight-bold"
							color="warning">
							Tác giả bên ngoài LHU</v-chip>
					</template>
					<template v-slot:item.is_tacgiachinh="{ item }">
						<v-icon v-if="item.Is_TacGiaChinh" color="success">mdi-check</v-icon>
					</template>
					<template v-slot:item.actions="{ item }">
						<div style="display:flex; justify-content:center">
							<!-- <v-icon style="font-size:18px" color="red darken-3" v-if="AnPhamObj.TrangThaiID!==3" small class="mr-2"
								@click="deleteItem(item)">
								mdi-trash-can-outline
							</v-icon> -->
							<v-icon style="font-size:18px" color="green darken-2" small="" class="mr-2"
								@click="editItem(item)">
								mdi-square-edit-outline
							</v-icon>
						</div>
					</template>
				</v-data-table>
				<v-dialog v-model="isAuthorModalOpen" max-width="1024px">
					<v-card>
						<v-card-title class="d-flex align-center px-3 pt-2 pb-3">
							<span class="subtitle-1 font-weight-bold primary--text me-5">{{ formTitle }}
								<span v-if="editedIndex !== -1">
									<span class="primary--text"> ({{ (editedIndex + 1).toString().padStart(2, 0)
										}})</span>
								</span>
							</span>

							<v-spacer></v-spacer>
							<v-btn small icon @click="close">
								<v-icon small>mdi-close</v-icon>
							</v-btn>
						</v-card-title>
						<v-card-text class="px-3 py-2">
							<v-form>
								<v-row dense>
									<v-col cols="12" sm="12" md="3" style="display:flex; align-items: center;">
										<v-select v-model="editedItem.TacGiaGroupID" hide-details dense outlined
											:items="vaiTroArr" item-text="ten" item-value="id" label="Vai trò"
											@change="resetField(editedItem.TacGiaGroupID)"></v-select>
									</v-col>
									<v-col cols="12" sm="12" md="3" style="display:flex; align-items: center;">
										<v-checkbox class="mt-5 ms-5" v-model="editedItem.Is_TacGiaChinh"
											label="Tác giả chính">
										</v-checkbox>
									</v-col>
									<v-col cols="12" sm="12" md="3" style="display:flex; align-items: center;">
										<v-checkbox class="mt-5 ms-5" v-model="editedItem.Is_TacGiaPhu"
											label="Tác giả phụ">
										</v-checkbox>
									</v-col>
									<v-col cols="12" sm="12" md="3">
										<v-autocomplete v-model="model" :items="items" :item-text="NhanVienSearch"
											item-value="MaNV" placeholder="Tìm kiếm bằng tên nhân viên" hide-no-data
											:search-input.sync="keyword" @change="changeNhanVien"
											@keydown="handleEnterMaNhanVien" :loading="isLoading"
											prepend-inner-icon="mdi-account-search" return-object></v-autocomplete>
									</v-col>
									<v-col cols="12" sm="6" md="2"
										v-if="editedItem.TacGiaGroupID == 1 || editedItem.TacGiaGroupID == 2">
										<v-text-field ref="MaNhanVien" v-model="editedItem.MaNhanVien"
											label="Mã thành viên" outlined @keydown="handleEnterMaNhanVien"
											@blur="blurMaNhanVien" dense>
										</v-text-field>
									</v-col>
									<v-col cols="12" sm="6" md="3">
										<v-text-field v-model="editedItem.HoTacGia" label="Họ tác giả" outlined dense>
										</v-text-field>
									</v-col>
									<v-col cols="12" sm="6" md="3">
										<v-text-field v-model="editedItem.TenTacGia" label="Tên tác giả" outlined dense>
										</v-text-field>
									</v-col>
									<v-col cols="12" sm="6" md="4">
										<v-text-field v-model="editedItem.EmailTacGia" label="Email" outlined dense>
										</v-text-field>
									</v-col>
									<v-col cols="12" sm="6" md="8">
										<v-text-field v-model="editedItem.TenPhongBan" label="Don vị" outlined dense>
										</v-text-field>
									</v-col>
									<v-col cols="12" sm="6" md="4">
										<v-text-field outlined dense v-model="editedItem.SoTaiKhoan"
											label="Số tài khoản"
											v-if="editedItem.TacGiaGroupID == 1 || editedItem.TacGiaGroupID == 2">
										</v-text-field>
									</v-col>
									<v-col cols="12" sm="6" md="4">
										<v-autocomplete
											v-if="editedItem.TacGiaGroupID == 1 || editedItem.TacGiaGroupID == 2"
											v-model="editedItem.NganHang" label="Ngân hàng" :items="dsNganHang"
											:filter="customFilterDSNganHang" item-text="name" item-value="name" outlined
											dense clearable>
											<template v-slot:item="data">
												<template v-if="typeof data.item !== 'object'">
													<v-list-item-content v-text="data.item"></v-list-item-content>
												</template>
												<template v-else>
													<v-list-item-avatar style="width:100px">
														<img :src="data.item.logo">
													</v-list-item-avatar>
													<v-list-item-content>
														<v-list-item-title v-html="data.item.name">
														</v-list-item-title>
													</v-list-item-content>
												</template>
											</template>
										</v-autocomplete>
									</v-col>
									<v-col cols="12" sm="6" md="4">
										<v-text-field outlined dense v-model="editedItem.TenChuTaiKhoan"
											label="Tên chủ tài khoản"
											v-if="editedItem.TacGiaGroupID == 1 || editedItem.TacGiaGroupID == 2">
										</v-text-field>
									</v-col>
									<v-col cols="12" sm="6" md="4">
										<v-autocomplete v-model="editedItem.NguonCapKinhPhi" :items="khoaNckh"
											:item-text="display_DonVi" item-value="DepartmentID" hide-details dense
											outlined label="Nguồn cấp kinh phí" style="max-width:350px">
										</v-autocomplete>
									</v-col>
								</v-row>
							</v-form>
						</v-card-text>
						<v-card-actions>
							<v-spacer></v-spacer>
							<v-btn @click="close">
								Đóng
							</v-btn>
							<v-btn color="primary" @click="save">
								Cập nhật
							</v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
			</v-card-text>
		</v-card>
	</div>
</template>

<script>
	export default {
		props: {
		value: { type: Object, default: () => ({}) },
		anphamid: { type: [Number, String], default: null },
		dsnganhang: { type: Array, default: () => [] },
		anphamobj: { type: Object, default: () => ({}) },
		dskhenthuong: { type: Array, default: () => [] },
		flagUpdateHSCL: { type: Boolean, default: false },
	},
	emits: ['onhandleflaghscl'],
	data: () => ({
		headersAuthorsObj: [
			{ text: 'Vị trí', sortable: false, value: "STT", align: "center" },
			{ text: 'Vai trò', sortable: false, value: "is_nhanvien", align: "center", width: '200' },
			{ text: 'Thông tin cá nhân', sortable: false, value: "thongtincanhan" },
			{ text: 'Thông tin ngân hàng', sortable: false, value: "thongtinnganhang" },
			{ text: 'Đơn vị', sortable: false, value: "TenPhongBan" },
			{ text: 'Nguồn cấp kinh phí', sortable: false, value: "NguonCapKinhPhi" },
			{ text: 'Tiền khen thưởng(Tạm tính)', value: "sotienkhenthuongtamtinh", sortable: false },
			{ text: 'Tiền khen thưởng(Đã lưu)', value: 'sotienkhenthuong', sortable: false },
			{ text: 'Hoàn phí đăng bài', value: 'hoanphidangbai', sortable: false },
			{ text: '', value: 'actions', sortable: false },
		],
		khoaNckh: [],
		hinhThucThanhToan: [
			{ TenHinhThuc: "Cá nhân đại diện", HinhThucID: 1 },
			{ TenHinhThuc: "Phân bổ cho từng thành viên", HinhThucID: 2 }
		],
		vueData,
		editedItem: {},
		editedIndex: null,
		isAuthorModalOpen: false,
		vaiTroArr: [
			{ ten: "Giảng viên/Nhân viên LHU", id: 1 },
			{ ten: "Học viên LHU", id: 2 },
			{ ten: "Tác giả bên ngoài LHU", id: 3 }
		],
		dataSearch: [],
		isLoading: false,
		keyword: '',
		model: null,
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
			if (this.AnPhamObj.NhomAnPham === 1 || this.AnPhamObj.NhomAnPham === 3) {
				customHeaders.push({ text: '2 đơn vị', sortable: false, value: "hscl_05", align: "center" })
			}
			if (this.AnPhamObj.NhomAnPham === 3) {
				customHeaders.push({ text: '*HSCL (=1.2)', sortable: false, value: "checkboxx", align: "center" })
			}
			if (this.AnPhamObj.NhomAnPham === 2) {
				// Thêm 2 cột 1.2 và 1.5 cho nhóm 2
				customHeaders.push(
					{ text: '*HSCL (=1.2)', sortable: false, value: "hscl_12", align: "center" },
					{ text: '*HSCL (=1.5)', sortable: false, value: "hscl_15", align: "center" },
				)
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
		},
		dsNganHang() {
			return this.dsnganhang
		},
		formTitle() {
			return 'Cập nhật tác giả ' + this.editedItem.HoTacGia + ' ' + this.editedItem.TenTacGia
		},
		items() {
			return this.dataSearch.map(item => item)
		},
	},
	watch: {
		"value.AuthorsObjArr": {
			handler(val) {
				this.syncHSCLFlags()
			},
			immediate: true
		},
		isAuthorModalOpen(val) {
			if (!val) {
				this.close()
			}
		},
		async keyword(val) {
			if (!val) {
				this.dataSearch = []
				return
			}
			if (this.isLoading) return
			this.isLoading = true
			await this.API_Search_NhanVien(val)
			this.isLoading = false
		},
		"editedItem.Is_TacGiaChinh": function (val) {
			if (val === true) {
				this.editedItem.Is_TacGiaPhu = false
			}
		},
		"editedItem.Is_TacGiaPhu": function (val) {
			if (val === true) {
				this.editedItem.Is_TacGiaChinh = false
			}
		},
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
		this.syncHSCLFlags()
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
		syncHSCLFlags() {
			if (!Array.isArray(this.value?.AuthorsObjArr)) return
			this.value.AuthorsObjArr.forEach(i => {
				const h = Number(i.HeSoHoTroCaoHoc) || 1
				i._hscl05 = (h === 0.5)
				i._hscl12 = (h === 1.2)
				i._hscl15 = (h === 1.5)
				i.checkboxHSCL = (h === 1.2)
			})
		},
		onToggleHSCL05(item) {
			this.$emit('onhandleflaghscl')
			if (item._hscl05) {
				item._hscl12 = false
				item._hscl15 = false
				item.HeSoHoTroCaoHoc = 0.5
			} else {
				item.HeSoHoTroCaoHoc = 1
			}
		},
		onToggleHSCL12(item) {
			this.$emit('onhandleflaghscl') // báo cho parent biết có đổi HSCL
			// Sau khi v-model toggle, đảm bảo loại trừ lẫn nhau
			if (item._hscl12) {
				item._hscl05 = false
				item._hscl15 = false
				item.HeSoHoTroCaoHoc = 1.2
			} else {
				// Bỏ chọn => về 1.0
				item.HeSoHoTroCaoHoc = 1
			}
		},

		onToggleHSCL15(item) {
			this.$emit('onhandleflaghscl')
			if (item._hscl15) {
				item._hscl05 = false
				item._hscl12 = false
				item.HeSoHoTroCaoHoc = 1.5
			} else {
				item.HeSoHoTroCaoHoc = 1
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
		async getKhoaNCKH() {
			this.khoaNckh = await ajaxCALLPromise('https://tapi.lhu.edu.vn/hoso/Public_SelectPhongBan') || []
		},
		detailCTKhenThuong(CTID) {
			let text = ""
			if (CTID) {
				text = this.DSCongThucKhenThuong.find(item => item.CongThucKhenThuongID === CTID).CongThucHTML
			}
			return text
		},
		async PhiKhenThuong_Cal() {
			const phiDangBaiData = await ajaxCALLPromise('/PhiDangBai_Cal', { AnPhamID: this.AnPhamObj.AnPhamID })
			if (phiDangBaiData && phiDangBaiData.length > 0) {
				this.value.AnPhamObj.HoanPhiDangBaiTamTinh = phiDangBaiData[0].HoTroPhiDangBai
				this.value.AnPhamObj.HoanPhiDangBai = this.value.AnPhamObj.HoanPhiDangBaiTamTinh
				let AuthorsIsNhanVienLHU = this.value.AuthorsObjArr.filter(item => item.TacGiaGroupID === 1 || item.TacGiaGroupID === 2)
				if (this.value.AnPhamObj.HinhThucThanhToan === 1) {
					this.value.AuthorsObjArr = this.value.AuthorsObjArr.map(item => {
						if ((item.TacGiaGroupID === 1 || item.TacGiaGroupID === 2) && item.NguoiDaiDienQuyetToan === true) {
							item.SoTienHoanPhiDangBai = this.value.AnPhamObj.HoanPhiDangBai
						} else { item.SoTienHoanPhiDangBai = 0 }
						return { ...item }
					})
				} else {
					let TienDangBai = this.value.AnPhamObj.HoanPhiDangBai / AuthorsIsNhanVienLHU.length
					this.value.AuthorsObjArr = this.value.AuthorsObjArr.map(item => {
						if (item.TacGiaGroupID === 1 || item.TacGiaGroupID === 2) { item.SoTienHoanPhiDangBai = TienDangBai }
						return { ...item }
					})
				}
			}
			const anpham = this.AnPhamObj
			if (!anpham.CongThucKhenThuongID || !(anpham.CongThucKhenThuongID > 0)) { return null }
			const khenThuongData = await ajaxCALLPromise('/PhiKhenThuong_Cal', {
				AnPhamID: this.AnPhamObj.AnPhamID,
				CongThucKhenThuongID: this.AnPhamObj.CongThucKhenThuongID,
				DiemHoiDong: this.AnPhamObj.DiemHoiDong ?? 0,
				HeSo_IF: this.AnPhamObj.HeSo_IF,
				HeSoChatLuongID: this.AnPhamObj.HeSoChatLuongID ?? 0,
			})
			if (khenThuongData && khenThuongData.length > 0) {
				let AuthorArr = this.AuthorsObjArr.map((item, index) => {
					item.SoTienKhenThuong = khenThuongData[index].KhenThuong
					return { ...item, SoTienKhenThuongTamTinh: khenThuongData[index].KhenThuong, CongThucKhenThuongID: anpham.CongThucKhenThuongID, NoiDungCongThucKhenThuong: '' }
				})
				AuthorArr = AuthorArr.map(item => { if (item.SoTienHoanPhiDangBai > item.SoTienKhenThuongTamTinh) { item.SoTienHoanPhiDangBai = item.SoTienKhenThuongTamTinh } return item })
				this.value.AuthorsObjArr = AuthorArr
				this.$emit('input', { ...this.value, AuthorsObjArr: AuthorArr })
			}
			return khenThuongData
		},
		editItem(item) {
			this.editedIndex = this.AuthorsObjArr.indexOf(item)
			this.editedItem = Object.assign({}, item)
			this.isAuthorModalOpen = true
		},
		close() {
			this.isAuthorModalOpen = false
			this.editedItem = {}
			this.editedIndex = null
			this.model = null
		},
		save() {
			if (this.editedItem.TacGiaGroupID == 1 || this.editedItem.TacGiaGroupID == 3) {
				if (!this.editedItem.Is_TacGiaChinh && !this.editedItem.Is_TacGiaPhu) {
					return Vue.$toast.warning("Vui lòng chọn vai trò Tác giả chính hoặc Tác giả phụ", { position: "top" })
				}
			}
			if (this.editedItem.TacGiaGroupID === 3 ) {this.editedItem.Is_NhanVien = false }
			else {this.editedItem.Is_NhanVien = true}
			this.update_tacGia()
		},
		async update_tacGia() {
			await ajaxCALLPromise('/AnPhamTacGia_Udp', { AnPhamID: this.anphamid, AuthorsObjArr: this.editedItem })
			Vue.$toast.success('Chỉnh sửa tác giả thành công!', { position: 'top' })
			await this.get_TG_byAnPhamID(this.anphamid)
			this.close()
		},
		async get_TG_byAnPhamID(AnPhamID) {
			const data = await ajaxCALLPromise('/AnPhamTacGia_Get_ByAnPhamID', { AnPhamID: AnPhamID })
			this.value.AuthorsObjArr = data
			this.$emit('input', this.value)
		},
		resetField(id) {
			// Điều kiện chỉ khi thêm mới tác gỉa thì mới reset dữ liệu
			if (this.editedIndex === -1) {
				this.editedItem = {}
				this.editedItem.TacGiaGroupID = id
			}
		},
		async API_Search_NhanVien(val) {
			this.dataSearch = await ajaxCALLPromise('/TaiKhoan_Seach', { Keyword: val }) || []
		},
		NhanVienSearch(item) {
			let text = item.MaNV + " - " + item.HoNV + " " + item.TenNV
			return text
		},
		openDialog() {
			this.editedItem = { TacGiaGroupID: 1, Is_TacGiaPhu: false, Is_TacGiaChinh: false }
			this.editedIndex = -1
			this.isAuthorModalOpen = true
		},
		changeNhanVien() {
			if (!this.model || !this.model.MaNV) { return }
			this.NhanVien_Get(this.model.MaNV)
			this.TaiKhoanNH_Get(this.model.MaNV)
		},
		async TaiKhoanNH_Get(UserID) {
			const data = await ajaxCALLPromise('/TaiKhoan_Get', { MaNV: UserID })
			this.editedItem.TenChuTaiKhoan = data[0]?.TenThe
			this.editedItem.SoTaiKhoan = data[0]?.TaiKhoan
			this.editedItem.NganHang = data[0]?.BankNameVietQR
		},
		NhanVien_Get(UserID) {
			$.ajax({
				type: "GET",
				headers: { authorization: $awt },
				url: `https://tapi.lhu.edu.vn/acc/UserInfo_ByID?UserID=${UserID}`,
				contentType: "application/json; charset=utf-8",
				dataType: "json",
				crossDomain: true,
				success: (res) => {
					let data = res.data
					if (data.length > 0) {
						this.editedItem.MaNhanVien = data[0].UserID
						this.editedItem.HoTacGia = data[0].LastName
						this.editedItem.TenTacGia = data[0].FirstName
						this.editedItem.TenPhongBan = data[0].DepartmentID
						this.editedItem.NguonCapKinhPhi = data[0].DepartmentID
					}
				},
				error: (xhr) => {
					Vue.$toast.error(xhr.responseJSON?.Message || 'Lỗi tải thông tin nhân viên', { position: 'top' })
				},
			})
		},
		handleEnterMaNhanVien(e) {
			let value = e.target.value.trim()
			if (e.code === "Enter" && value !== '') {
				this.NhanVien_Get(value)
				this.TaiKhoanNH_Get(value)
			}
		},
		customFilterDSNganHang(item, queryText, itemText) {
			const name = item.name.toLowerCase()
			const shortName = item.shortName.toLowerCase()
			const searchText = queryText.toLowerCase()
			return name.indexOf(searchText) > -1 ||
				shortName.indexOf(searchText) > -1
		},
		blurMaNhanVien(e) {
			let value = e.target.value.trim()
			this.NhanVien_Get(value)
			this.TaiKhoanNH_Get(value)
		},
		onCheckboxChange(itemSelected) {
			// Nếu checkbox được chọn (true)
			if (itemSelected.NguoiDaiDienQuyetToan) {
				// Lặp qua tất cả các items và set checkbox = false cho các item khác
				this.value.AuthorsObjArr.forEach(item => {
					if (itemSelected !== item) {
						item.NguoiDaiDienQuyetToan = false;
					}
				});
			}
		}
	},
	}
</script>