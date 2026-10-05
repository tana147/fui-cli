<template>
	<v-card>
		<v-card-title class="mb-10">
			<v-row class="flex align-center justify-center ms-2">
				<span class="primary--text font-weight-medium me-5">
					Kho lưu trữ nghiên cứu khoa học
				</span>

				<v-btn color="warning" class="ms-3" :disabled="isDisabledSendDashboard" @click="sendToStorage">Khôi phục dữ liệu</v-btn>
				<v-spacer></v-spacer>
				<v-btn class="mr-6" icon color="primary" @click="toExcel">
					<v-icon>mdi-microsoft-excel</v-icon>
				</v-btn>
				<v-text-field v-model="search" prepend-icon="mdi-filter-outline" label="Tìm kiếm" single-line
					style="max-width: 400px"></v-text-field>
			</v-row>
			<v-row class="ms-2">
				<v-col cols="12" class="pt-0 pb-0">
					<h5 class="primary--text">Lọc dữ liệu:</h5>
				</v-col>
				<v-col cols="12" class="d-flex align-center">
					<v-select v-model="NhomAnPhamID" style="max-width: 250px" :items="LoaiBaiBao" item-text="TenLoai"
						item-value="LoaiID" label="Nhóm ấn phẩm" class="me-3" outlined dense hide-details></v-select>
					<v-select v-model="TrangThaiID" style="max-width: 250px" :items="TrangThaiArr"
						item-text="TenTrangThai" item-value="TrangThaiID" label="Trạng thái" class="me-3" outlined dense
						hide-details></v-select>
					<v-select v-model="DMTC_Filter" style="max-width: 350px" :items="DanhMucLoaiAnPhamArr"
						item-text="TenLoaiAnPham" item-value="LoaiAnPhamID" label="Danh mục bài báo ấn phẩm"
						class="me-3" outlined dense hide-details @change="getDM_By_LoaiAnPhamID"></v-select>
					<v-select v-model="Thuoc_DMTC_Filter" style="max-width: 350px" :items="DMTC_Arr"
						item-text="TenLoaiSubAnPham" item-value="LoaiSubAnPhamID" label="Thuộc danh mục tạp chí"
						class="me-3" outlined dense hide-details @change="getTenDMTC_By_LoaiAnPhamID()"></v-select>
					<v-select v-model="Ten_DMTC_Filter" style="max-width: 350px" :items="Ten_DMTC_Arr"
						item-text="TenLoaiDanhMucTapChi" item-value="DanhMucLoaiTapChiID" label="Tên danh mục tạp chí"
						class="me-3" outlined dense hide-details></v-select>
				</v-col>

			</v-row>
		</v-card-title>

		<v-card-text>
			<v-data-table dense calculate-widths :headers="headersArticlesObj" v-model="isSelected" item-key="AnPhamID"
				show-select :items="DSBaiBaoFilter" :search="search" selectable-key="isSelectable"
				:footer-props="{ 'items-per-page-options': [100, 150, -1] }">
				<template v-slot:item.TrangThai="{ item }">
					<v-chip :color="getColorStatusAnPham(item.TrangThaiID)">
						{{ item.TrangThai }}
					</v-chip>
				</template>
				<template v-slot:top>
					<v-dialog v-model="dialog" max-width="1400px">
						<v-card>
							<v-card-title>
								<span class="text-h5 primary--text me-3">{{ formTitle }}</span>
								<v-select v-model="editedItem.AnPhamObj.NhomAnPham" :items="LoaiBaiBao"
									item-text="TenLoai" item-value="LoaiID" label="Nhóm ấn phẩm" outlined dense
									hide-details style="max-width: 300px" readonly
									@change="resetFileIDMinhChungHoTroCaoHoc">
								</v-select>
								<v-spacer></v-spacer>
								<v-btn fab small icon @click="close">
									<v-icon>mdi-close</v-icon>
								</v-btn>
							</v-card-title>
							<v-card-text>
								<uc-an-pham ref="FormAnPham" class="mb-10 mb-5" v-model="editedItem"
									:danhmuctapchiarr="DanhMucTapChiArr" :danhmucloaianphamarr="DanhMucLoaiAnPhamArr"
									:namarr="NamArr" :dshesochatluong="DSHeSoChatLuong" :editedindex="editedIndex">
								</uc-an-pham>
								<uc-table-tac-gia v-if="dialog" v-model="editedItem" ref="tacgia"
									:anphamid="editedItem.AnPhamObj.AnPhamID" :dsnganhang="DSNganHang"
									:flagUpdateHSCL="flagUpdateHSCL" :anphamobj="editedItem.AnPhamObj"
									@onhandleflaghscl="onHandleFlagHSCL"
									:dskhenthuong="DSCongThucKhenThuong"/>
							</v-card-text>
							<v-card-actions>
								<v-spacer></v-spacer>
								<v-btn @click="dialog = false">Đóng</v-btn>
								<v-btn class="ml-2"  color="success" :loading="isLoadingSave">
									Khôi phục</v-btn>
							</v-card-actions>
						</v-card>
					</v-dialog>
				</template>
				<template v-slot:item.nhomanpham="{ item }">
					<v-chip outlined color="primary" v-if="item.NhomAnPham === 1">Ấn phẩm khoa học</v-chip>
					<v-chip v-if="item.NhomAnPham === 2" outlined color="success">Hỗ trợ Đầu vào Cao học</v-chip>
					<v-chip v-if="item.NhomAnPham === 3" outlined color="orange">Có hướng dẫn Cao học</v-chip>
				</template>
				<template v-slot:item.actions="{ item }">
					<div style="display: flex">
						<v-icon style="font-size: 18px" color="green darken-2" small class="mr-2"
							@click="editItem(item)">
							mdi-square-edit-outline
						</v-icon>
					</div>
				</template>
				<template v-slot:item.daguidashboard="{ item }">
					<v-icon color="success" v-if="!item.isSelectable">mdi-check</v-icon>
				</template>
				<template v-slot:item.thongtintapchi="{ item }">
					<p class="mb-1"><span class="font-weight-medium">Tên tạp chí:</span>
						{{ item.TenTapChi.length > 0 ? item.TenTapChi : '-' }}</p>
					<p class="mb-0"><span class="font-weight-medium">Tên danh mục:</span>
						{{ item.TenLoaiDanhMucTapChi ? item.TenLoaiDanhMucTapChi : '-' }}</p>
				</template>
				<template v-slot:item.TenAnPham="{ item }">
					<span class="font-weight-medium">{{ item.TenAnPham }}</span>
				</template>
			</v-data-table>
		</v-card-text>
	</v-card>
</template>

<script>
export default {
	props: [
		"dsbaibao",
		"dsdanhmuctapchi",
		"dsdanhmucloaianpham",
		"dsnam",
		"dscongthuckhenthuong",
		"dshesochatluong",
	],

	data() {
		return {
			checkAll: null,
			dialogReject: false,
			NamHoc: "",
			search: "",
			menuDashboard: false,
			dialog: false,
			isLoadingSave: false,
			isSelected: [],
			isDisabledSendDashboard: true,
			LoaiBaiBao: [
				{ TenLoai: "Ấn phẩm khoa học", LoaiID: 1 },
				{ TenLoai: "Hỗ trợ Đầu vào Cao học", LoaiID: 2 },
				{ TenLoai: "Có hướng dẫn Cao học", LoaiID: 3 },
				{ TenLoai: "Tất cả", LoaiID: 4 },
			],
			headersArticlesObj: [
				{
					text: "Đã gửi dashboard",
					sortable: false,
					value: "daguidashboard",
					align: "center",
					width: "10",
				},
				{
					text: "STT",
					sortable: false,
					value: "STT",
					align: "center",
					width: "20",
				},
				{
					text: "Tên bài báo",
					sortable: false,
					value: "TenAnPham",
					width: "200",
				},
				{ text: "Tác giả", sortable: false, value: "TacGia", width: "150" },
				{ text: "Đơn vị", value: "DonViDaiDien", width: "100" },
				{
					text: "Danh mục bài báo/ấn phẩm",
					sortable: false,
					value: "TenLoaiAnPham",
					width: "150",
				},
				{
					text: "Thông tin tạp chí",
					sortable: false,
					width: "250",
					value: "thongtintapchi",
				},
				{
					text: "Nơi đăng",
					value: "NoiDangBai",
					sortable: true,
					width: "110",
				},
				{
					text: "Năm đăng",
					value: "NamDangBai",
					sortable: true,
					align: "center",
					width: "120",

				},
				{ text: "Nhóm ấn phẩm", value: "nhomanpham", sortable: false },
				{
					text: "Ngày nhập",
					sortable: true,
					value: "ThoiGianGui",
					width: "100",
					align: "center",
				},
				{
					text: "Trạng thái",
					sortable: true,
					value: "TrangThai",
					width: "100",
					align: "center",
				},
				{ text: "Thao tác", value: "actions", sortable: false },
			],
			fileRules: {
				max_file_size: "100mb",
				mime_types: [
					{
						title: "All files",
						extensions: "*",
					},
				],
			},
			editedIndex: -1,
			editedItem: {
				AnPhamObj: {
					TenAnPham: "",
					LoaiAnPhamID: null,
					TenLoaiAnPham: null,
					TenTapChi: "",
					DanhMucLoaiTapChiID: "",
					TenLoaiDanhMucTapChi: "",
					LoaiSubAnPhamID: null,
					TenLoaiSubAnPham: "",
					NoiDangBai: "",
					NamDangBai: new Date().getFullYear(),
					DuongDanBaiBao: "",
					HeSo_IF: convertDiem(0),
					TrangThai: "",
					MaNhanVienDaiDien: "",
					TenNhanVienDaiDien: "",
					DonViDaiDien: "",
					SoTacGia_LHU: 0,
					DiemHoiDong: convertDiem(0),
					TenHeSoChatLuong: null,
					HeSoChatLuongID: null,
					PhiThongBao: null,
					PhiDangBai: null,
					HoanPhiDangBai: 0,
					ISSN: null,
					Dieu: null,
					Khoan: null,
					Muc: null,
					TongSoTienThuong: null,
					GhiChu: "",
					SoQuyetDinhKhenThuong: null,
					FileIDKhenThuong: null,
					HoanPhiDangBaiTamTinh: 0,
					CongThucKhenThuongID: null,
					HinhThucThanhToan: 2,
					NguonCapKinhPhi: null,
					NhomAnPham: 1,
					FileIDMinhChungHoTroCaoHoc: null,
				},
				AuthorsObjArr: [],
				ProofsObjArr: [
					{
						LoaiFile: 2,
						FileIDList: "",
						FileList: [],
						MoTa: "",
					},
				],
			},
			LoaiFileMinhChung: [],
			defaultItem: {
				AnPhamObj: {
					TenAnPham: "",
					LoaiAnPhamID: null,
					TenLoaiAnPham: null,
					TenTapChi: "",
					DanhMucLoaiTapChiID: "",
					TenLoaiDanhMucTapChi: "",
					LoaiSubAnPhamID: null,
					TenLoaiSubAnPham: "",
					NoiDangBai: "",
					NamDangBai: "",
					DuongDanBaiBao: "",
					HeSo_IF: 0.0,
					TrangThai: "",
					MaNhanVienDaiDien: "",
					TenNhanVienDaiDien: "",
					DonViDaiDien: "",
					SoTacGia_LHU: 0,
					DiemHoiDong: 0,
					TenHeSoChatLuong: null,
					HeSoChatLuongID: null,
					PhiThongBao: null,
					PhiDangBai: null,
					HoanPhiDangBai: 0,
					ISSN: null,
					Dieu: null,
					Khoan: null,
					Muc: null,
					TongSoTienThuong: null,
					GhiChu: "",
					SoQuyetDinhKhenThuong: null,
					FileIDKhenThuong: null,
					HoanPhiDangBaiTamTinh: 0,
					CongThucKhenThuongID: null,
					HinhThucThanhToan: 2,
					NguonCapKinhPhi: null,
					NhomAnPham: 1,
					FileIDMinhChungHoTroCaoHoc: null,
				},

				AuthorsObjArr: [],
				ProofsObjArr: [
					{
						LoaiFile: 2,
						FileIDList: "",
						FileList: [],
						MoTa: "",
					},
				],
				ID: null,
			},
			DSNganHang: null,
			RejectNotice: "",
			validReject: [
				(v) => (v && v.length > 0) || "Vui lòng nhập lý do từ chối",
			],
			NhomAnPhamID: 4,
			TrangThaiID: 1,
			TrangThaiArr: [
				{ TenTrangThai: "Tất cả", TrangThaiID: 1 },
				{ TenTrangThai: "Chờ duyệt", TrangThaiID: 2 },
				{ TenTrangThai: "Đã duyệt", TrangThaiID: 3 }
			],
			DMTC_Filter: -1,
			Thuoc_DMTC_Filter: null,
			Ten_DMTC_Filter: null,
			DMTC_Arr: [],
			Ten_DMTC_Arr: [],
			DS_BaiBaoKhenThuong: [],
			flagUpdateHSCL: false
		};
	},
	mounted() {
	},
	computed: {
		DSBaiBaoFilter() {
			const $this = this
			let dsbaibao = []
			if (this.NhomAnPhamID === 2 && this.TrangThaiID === 2) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 2 && item.TrangThaiID === 2)
			} else if (this.NhomAnPhamID === 2 && this.TrangThaiID === 3) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 2 && item.TrangThaiID === 3)
			} else if (this.NhomAnPhamID === 1 && this.TrangThaiID === 2) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 1 && item.TrangThaiID === 2)
			} else if (this.NhomAnPhamID === 1 && this.TrangThaiID === 3) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 1 && item.TrangThaiID === 3)
			} else if (this.NhomAnPhamID === 3 && this.TrangThaiID === 2) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 3 && item.TrangThaiID === 2)
			} else if (this.NhomAnPhamID === 3 && this.TrangThaiID === 3) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 3 && item.TrangThaiID === 3)
			} else if (this.TrangThaiID === 3) {
				dsbaibao = this.DSBaiBao.filter(item => item.TrangThaiID === 3)
			} else if (this.NhomAnPhamID === 1) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 1)
			} else if (this.NhomAnPhamID === 2) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 2)
			} else if (this.NhomAnPhamID === 3) {
				dsbaibao = this.DSBaiBao.filter(item => item.NhomAnPham === 3)
			} else if (this.TrangThaiID === 2) {
				dsbaibao = this.DSBaiBao.filter(item => item.TrangThaiID === 2)
			}
			else {
				dsbaibao = this.DSBaiBao
			}

			return dsbaibao.filter(item => this.DMTC_Filter !== -1 ? item.LoaiAnPhamID == this.DMTC_Filter : item)
				.filter(item => this.Thuoc_DMTC_Filter ? item.LoaiSubAnPhamID == this.Thuoc_DMTC_Filter : item)
				.filter(item => this.Ten_DMTC_Filter ? item.DanhMucLoaiTapChiID == this.Ten_DMTC_Filter : item)

		},
		formTitle() {
			return this.editedIndex === -1
				? "Thêm mới"
				: "Chi tiết bài báo chờ duyệt";
		},
		DanhMucTapChiArr() {
			return this.dsdanhmuctapchi;
		},
		DanhMucLoaiAnPhamArr() {
			return [
				{ LoaiAnPhamID: -1, TenLoaiAnPham: "Tất cả" },
				...this.dsdanhmucloaianpham.map(item => {
					return { ...item };
				})
			];
		},
		NamArr() {
			return this.dsnam;
		},
		DSCongThucKhenThuong() {
			return this.dscongthuckhenthuong;
		},
		DSHeSoChatLuong() {
			return this.dshesochatluong;
		},
		DSBaiBao() {
			return this.dsbaibao
		}
	},
	watch: {
		dialog(val) {
			val || this.close();
		},
		dialogReject(val) {
			val || this.closeReject();
		},
		"editedItem.AnPhamObj.AnPhamID": function (val) {
			const $this = this;
			if (val) {
				ajaxCALL(
					"/PhiDangBai_Cal",
					{
						AnPhamID: val,
					},
					(res) => {
						$this.editedItem.AnPhamObj.HoanPhiDangBaiTamTinh =
							res.data[0].HoTroPhiDangBai;
						if (
							$this.editedItem.AnPhamObj.HoanPhiDangBai === 0 ||
							$this.editedItem.AnPhamObj.HoanPhiDangBai === null
						) {
							$this.editedItem.AnPhamObj.HoanPhiDangBai =
								$this.editedItem.AnPhamObj.HoanPhiDangBaiTamTinh;
						}
					},
					(error) => {
						Vue.$toast.error(error.responseJSON.Message, { position: "top" });
					}
				);
			}
		},
		"isSelected": function (val) {
			if (val.length > 0) {
				this.isDisabledSendDashboard = false
			} else {
				this.isDisabledSendDashboard = true
			}
		}
	},
	created() {
		this.LoaiFileMinhChung_Get();
		this.DSNganHang_Get();
	},
	methods: {
		resetFileIDMinhChungHoTroCaoHoc() {
			if (this.editedItem.AnPhamObj.NhomAnPham === 3) {
				this.editedItem.AnPhamObj.LoaiAnPhamID = 3;
				this.editedItem.AnPhamObj.LoaiSubAnPhamID = 9;
				this.editedItem.AnPhamObj.DanhMucLoaiTapChiID = 34;
				this.editedItem.AnPhamObj.TenTapChi = "Tạp chí Khoa học Lạc Hồng";
				this.editedItem.AnPhamObj.HinhThucThanhToan = 1;
				this.getDM_By_LoaiAnPhamID_from_parent();
				this.getDM_By_LoaiSubAnPhamID_from_parent();
			}
			this.editedItem.AnPhamObj.FileIDMinhChungHoTroCaoHoc = null;
			this.editedItem.AnPhamObj.FileNameMinhChungHoTroCaoHoc = null;
			this.editedItem.AnPhamObj.FileUrlMinhChungHoTroCaoHoc = null;
		},
		//Hàm xử lí gửi danh sách bài báo được chọn sang dashboard
		sendBaiBao() {
			const $this = this;
			if ($this.NamHoc.length === 0) {
				Vue.$toast.error("Vui lòng chọn năm học!", {
					position: "top",
				});
				return
			}
			confirm({
				title: "Xác nhận",
				content: "Xác nhận gửi bài báo sang dashboard",
				action: function () {
					let AnPhamIDArr = $this.isSelected.map((item) => ({ AnPhamID: item.AnPhamID }));
					if (AnPhamIDArr.length > 0) {
						ajaxCALL(
							"/AnPham_Ins_ToRPT",
							{
								AnPhamObjArr: AnPhamIDArr,
								NamHoc: $this.NamHoc
							},
							(res) => {
								$this.isSelected = [];
								$this.NamHoc = ""
								CALL("loadAnPhamByTrangThai");
								Vue.$toast.success("Gửi dữ liệu thành công", {
									position: "top",
								});
							},
							(err) => { }
						);
					} else {
						Vue.$toast.warning("Chưa chọn dữ liệu để gửi", { position: "top" });
					}
				},
			});
		},
		//Hàm xử lý chọn sửa bài báo
		async editItem(item) {
			this.ID = item.AnPhamID;
			this.editedIndex = this.DSBaiBao.indexOf(item);
			const $this = this;
			await ajaxCALL("/AnPham_Get_ByAnPhamID",
				{
					AnPhamID: item.AnPhamID,
				},
				(res) => {
					let anphamobj = res.data[0][0];
					let authorobjarr = res.data[1];
					let proofsobjarr = res.data[2];
					anphamobj.HeSo_IF = convertDiem(anphamobj.HeSo_IF);
					anphamobj.DiemHoiDong = convertDiem(anphamobj.DiemHoiDong);
					anphamobj.HoanPhiDangBaiTamTinh = 0;
					anphamobj.HoanPhiDangBai = anphamobj.HoanPhiDangBai ?? 0; //Kiểm tra HoanPhiDangBai có bị null ko?
					this.editedItem.AnPhamObj = anphamobj;
					this.editedItem.AuthorsObjArr = authorobjarr.map((item) => {
						return { ...item, SoTienKhenThuongTamTinh: 0 };
					});
					if (proofsobjarr.length > 0) {
						this.editedItem.ProofsObjArr = proofsobjarr.map((item) => {
							if (item.FileList) {
								let jsonParse = JSON.parse(item.FileList);
								return { ...item, FileList: jsonParse };
							} else {
								return { ...item, FileList: [] };
							}
						});
					}
					this.editedItem.AuthorsObjArr = this.editedItem.AuthorsObjArr.map(item => { return { ...item, checkboxHSCL: item.HeSoHoTroCaoHoc === 1.2 ? true : false } })
					$this.PhiKhenThuong_Cal()?.then((data) => {
						console.log("data[index].KhenThuong", data)
						if (data.length > 0) {
							this.editedItem.AuthorsObjArr = this.editedItem.AuthorsObjArr.map(
								(item, index) => {
									if (item.SoTienKhenThuong === 0 || item.SoTienKhenThuong === null) {
										item.SoTienKhenThuong = data[index].KhenThuong;
									}
									return {
										...item,
										SoTienKhenThuongTamTinh: data[index].KhenThuong,
										CongThucKhenThuongID: this.editedItem.AnPhamObj.CongThucKhenThuongID,
										NoiDungCongThucKhenThuong: "",
									};
								}
							);
						}
					});
					this.getDM_By_LoaiAnPhamID_from_parent();
					this.getDM_By_LoaiSubAnPhamID_from_parent();
					$this.dialog = true;
				},
				(err) => { }
			);
		},
		//Hàm xử lý chọn xóa bài báo
		deleteItem(item) {
			this.ID = item.AnPhamID;
			const $this = this;
			confirm({
				title: "Xác nhận",
				content: `Xác nhận xóa bài báo`,
				action: function () {
					$this.delete_baiBao();
				},
			});
		},
		//Hàm đóng dialog khi mở chỉnh sửa bài báo
		close() {
			this.dialog = false;
			this.$nextTick(() => {
				this.editedItem = Object.assign({}, this.defaultItem);
				this.editedIndex = -1;
				this.$refs.FormAnPham.TenDMTC_Arr = [];
				this.$refs.FormAnPham.DMTC_Arr = [];
			});
			this.ID = null;
		},
		//Hàm đóng dialog khi dialog xác nhận xóa bài báo
		closeDelete() {
			this.$nextTick(() => {
				this.editedItem = Object.assign({}, this.defaultItem);
				this.editedIndex = -1;
				this.ID = null;
			});
		},
		//Hàm get danh sách các loại file minh chứng
		LoaiFileMinhChung_Get() {
			ajaxCALL(
				"/LoaiFileMinhChung_Get",
				null,
				(res) => {
					this.LoaiFileMinhChung = res.data;
				},
				(error) => {
					Vue.$toast.error(error.responseJSON.Message, { position: "top" });
				}
			);
		},
		DSNganHang_Get() {
			vueData.v_Loading = true;
			const $this = this;
			$.ajax({
				type: "GET",
				url: "https://api.vietqr.io/v2/banks",
				contentType: "application/json; charset=utf-8",
				dataType: "json",
				crossDomain: true,
				success: function (res) {
					if (res.code === "00") {
						$this.DSNganHang = res.data;
					} else {
						Vue.$toast.warning(res.desc);
					}
				},
				error: function (error) {
					Vue.$toast.error(error);
				},
				complete: function (data) {
					vueData.v_Loading = false;
				},
			});
		},
		//Hàm update bài báo
		save() {
			if (this.$refs.FormAnPham.$refs.ValidForm.validate() === false) {
				return;
			}
			const $this = this;
			this.update_baiBao();
		},
		update_baiBao() {
			const $this = this;
			console.log($this.editedItem.AnPhamObj)
			confirm({
				title: "Xác nhận",
				content: `Xác nhận duyệt bài báo`,
				action: function () {
					$this.isLoadingSave = true;
					let proofsObjArrAPI = $this.editedItem.ProofsObjArr.map((item) => {
						if (item.FileList) {
							const joinStringFileID = item.FileList.map(
								(item) => item.FileIDMinhChung
							).join(",");
							return { ...item, FileIDList: joinStringFileID };
						}
						return item;
					});
					if (
						$this.editedItem.AnPhamObj.HoanPhiDangBai === 0 ||
						$this.editedItem.AnPhamObj.HoanPhiDangBai === null
					) {
						$this.editedItem.AnPhamObj.HoanPhiDangBai =
							$this.editedItem.AnPhamObj.HoanPhiDangBaiTamTinh;
					}
					for (var i = 0; i < $this.editedItem.AuthorsObjArr.length; i++) {
						if (
							$this.editedItem.AuthorsObjArr[i].SoTienKhenThuong === null || $this.editedItem.AuthorsObjArr[i].SoTienKhenThuong === 0 || $this.editedItem.AuthorsObjArr[i].HeSoHoTroCaoHoc === 1.2
						) {
							$this.editedItem.AuthorsObjArr[i].SoTienKhenThuong = $this.editedItem.AuthorsObjArr[i].SoTienKhenThuongTamTinh;
						}
					}
					let index = $this.editedItem.AuthorsObjArr.findIndex(item => item.HeSoHoTroCaoHoc === 1.2)
					if (index != -1) {
						$this.editedItem.AuthorsObjArr = $this.editedItem.AuthorsObjArr.map(item => {
							return { ...item, SoTienKhenThuong: item.SoTienKhenThuongTamTinh }
						})
					}
					ajaxCALL("/AnPham_Udp_Obj", {
						AnPhamObj: $this.editedItem.AnPhamObj,
						AuthorsObjArr: $this.editedItem.AuthorsObjArr,
						ProofSObjArr: proofsObjArrAPI,
						TrangThai: 3,
					}, (res) => {
						Vue.$toast.success("Cập nhật chi phí thành công", {
							position: "top",
						});
						CALL("loadAnPhamByTrangThai");
						$this.isLoadingSave = false;
						$this.close();
					},
						(error) => {
							$this.isLoadingSave = false;
							Vue.$toast.error(error.responseJSON.Message, { position: "top" });
						}
					);
				},
			});
		},
		delete_baiBao() {
			ajaxCALL(
				"/AnPham_Del_ByAnPhamID",
				{
					AnPhamID: this.ID,
				},
				(res) => {
					CALL("loadAnPhamByTrangThai");
					this.closeDelete();
				},
				(error) => {
					this.isLoadingSave = false;
					Vue.$toast.error(error.responseJSON.Message, { position: "top" });
				}
			);
		},
		PhiKhenThuong_Cal() {
			if (
				this.editedItem.AnPhamObj.CongThucKhenThuongID &&
				this.editedItem.AnPhamObj.CongThucKhenThuongID > 0
			) {
				return new Promise((resolve, reject) => {
					ajaxCALL(
						"/PhiKhenThuong_Cal",
						{
							AnPhamID: this.editedItem.AnPhamObj.AnPhamID,
							CongThucKhenThuongID: this.editedItem.AnPhamObj.CongThucKhenThuongID,
							DiemHoiDong: this.editedItem.AnPhamObj.DiemHoiDong ?? 0,
							HeSo_IF: this.editedItem.AnPhamObj.HeSo_IF,
							HeSoChatLuongID: this.editedItem.AnPhamObj.HeSoChatLuongID ?? 0,
						},
						(res) => {
							let data = res.data;
							resolve(data);
						},
						(error) => {
							reject(error);
							return Vue.$toast.warning(error.responseJSON.Message, {
								position: "top",
							});
						}
					);
				});
			}
		},
		reject() {
			this.dialogReject = true;
		},
		closeReject() {
			this.dialogReject = false;
			this.RejectNotice = "";
		},
		confirmReject() {
			if (!this.$refs.reject.validate()) {
				return Vue.$toast.error("Vui lòng nhập lý do từ chối", {
					position: "top",
				});
			}
			this.Update_TrangThai(this.ID);
			this.closeReject();
		},
		UpdateInfomation() {
			const $this = this;
			$this.isLoadingSave = true;
			let proofsObjArrAPI = $this.editedItem.ProofsObjArr.map((item) => {
				if (item.FileList) {
					const joinStringFileID = item.FileList.map(
						(item) => item.FileIDMinhChung
					).join(",");
					return { ...item, FileIDList: joinStringFileID };
				}
				return item;
			});
			if (
				$this.editedItem.AnPhamObj.HoanPhiDangBai === 0 || $this.editedItem.AnPhamObj.HoanPhiDangBai === null
			) {
				$this.editedItem.AnPhamObj.HoanPhiDangBai = $this.editedItem.AnPhamObj.HoanPhiDangBaiTamTinh;
			}
			for (var i = 0; i < $this.editedItem.AuthorsObjArr.length; i++) {
				if (
					$this.editedItem.AuthorsObjArr[i].SoTienKhenThuong === null || $this.editedItem.AuthorsObjArr[i].SoTienKhenThuong === 0 || $this.editedItem.AuthorsObjArr[i].HeSoHoTroCaoHoc === 1.2
				) {
					$this.editedItem.AuthorsObjArr[i].SoTienKhenThuong = $this.editedItem.AuthorsObjArr[i].SoTienKhenThuongTamTinh;
				}
			}
			//Tìm nếu trong danh sách tác giả có bất kỳ ai có HSCL = 1.2 thì khi lưu sẽ lưu bằng số tiền khen thưởng tạm tính,
			// ngược lại thì lưu bằng số tiền khen thưởng nhập liệu
			let index = $this.editedItem.AuthorsObjArr.findIndex(item => item.HeSoHoTroCaoHoc === 1.2)
			if (index != -1) {
				$this.editedItem.AuthorsObjArr = $this.editedItem.AuthorsObjArr.map(item => {
					return { ...item, SoTienKhenThuong: item.SoTienKhenThuongTamTinh }
				})
			}
			ajaxCALL(
				"/AnPham_Udp_Obj",
				{
					AnPhamObj: $this.editedItem.AnPhamObj,
					AuthorsObjArr: $this.editedItem.AuthorsObjArr,
					ProofSObjArr: proofsObjArrAPI,
					TrangThai: 2,
				},
				(res) => {
					// Vue.$toast.success("Cập nhật dữ liệu thành công", {
					// 	position: "top",
					// });
					// CALL("loadAnPhamByTrangThai");
					// $this.isLoadingSave = false;
					// $this.close();
				},
				(error) => {
					$this.isLoadingSave = false;
					Vue.$toast.error(error.responseJSON.Message, { position: "top" });
				}
			);
		},
		Update_TrangThai(AnPhamID) {
			const $this = this;
			ajaxCALL(
				"/AnPham_Udp_TrangThai",
				{
					AnPhamID: AnPhamID,
					TrangThai: 5,
					LyDoReject: this.RejectNotice,
				},
				(res) => {
					Vue.$toast.success("Từ chối thành công", { position: "top" });
					$this.close();
					CALL("loadAnPhamByTrangThai");
					this.ID = null;
				},
				(error) => {
					Vue.$toast.error(error.responseJSON.Message, { position: "top" });
				}
			);
		},
		getDM_By_LoaiAnPhamID_from_parent() {
			this.$nextTick(async () => {
				await this.$refs.FormAnPham.getDM_By_LoaiAnPhamID_Edit();
			});
		},
		getDM_By_LoaiSubAnPhamID_from_parent() {
			if (this.editedItem.AnPhamObj.LoaiSubAnPhamID) {
				this.$nextTick(async () => {
					await this.$refs.FormAnPham.getTenDMTC_By_LoaiAnPhamID_Edit();
				});
			}
		},
		ThuHoiBaiBao() {
			const $this = this
			confirm({
				title: "Xác nhận thu hồi",
				content: `Xác nhận thu hồi bài báo từ dashboard`,
				action: function () {
					ajaxCALL(
						"/AnPham_ThuHoi_RPT",
						{
							AnPhamID: $this.ID,
						},
						(res) => {
							$this.close();
							CALL("loadAnPhamByTrangThai");
							Vue.$toast.success("Đã thu hồi bài báo từ Dashboard", {
								position: "top",
							});
						},
						(err) => {
							console.log(err);
						}
					);
				},
			});

		},
		//Hàm lấy dữ liệu của field Thuộc danh mục tạp chí
		getDM_By_LoaiAnPhamID() {
			if (this.DMTC_Filter) {
				ajaxCALL("/AnPham_Loai_Sub_Get", {
					LoaiAnPhamID: this.DMTC_Filter
				}, res => {
					this.DMTC_Arr = res.data

				}, err => {
					console.log(err)
				})
			}

		},
		//Hàm lấy dữ liệu của field Tên danh mục tạp chí
		getTenDMTC_By_LoaiAnPhamID() {
			if (this.Thuoc_DMTC_Filter) {
				ajaxCALL("/LoaiDMTapChi_Get_ByLoaiSubAnPhamID", {
					LoaiSubAnPhamID: this.Thuoc_DMTC_Filter
				}, res => {
					this.Ten_DMTC_Arr = res.data

				}, err => {
					console.log(err)
				})
			}
		},

		toExcel() {
			ajaxCALL('/AnPham_KhenThuong_Get_ByTrangThai', {
				TrangThai: "2,3"
			}, (res) => {
				this.DS_BaiBaoKhenThuong = res.data
				let convertDSBaiBao = this.DS_BaiBaoKhenThuong.map(item => {
					return {
						STT: item.STT,
						AnPhamID: item.AnPhamID,
						"Mã nhân viên": item.MaNhanVien,
						"Tên tác giả được tính tiền": item.HoTenTacGia,
						"Tác giả bài báo": item.TacGia,
						"TGLH/TTG": item.SoTacGia_LHU + "/" + item.TongSoTacGia,
						"Đơn vị": item.TenKhoa,
						"Tên bài báo": item.TenAnPham,
						"Tên tạp chí": item.TenTapChi,
						"Năm đăng": item.NamDangBai,
						"Nơi đăng": item.NoiDangBai,
						"Thuộc danh mục tạp chí": item.TenNhomHienThiExcel,
						"Hoàn phí đăng": item.SoTienHoanPhiDangBai,
						"Khen thưởng": item.SoTienKhenThuong,
						"Khen thưởng sau hoàn phí": item.TongTienKhenThuong,
						"Số tài khoản": item.SoTaiKhoan,
						"Ngân hàng": item.NganHang,
						"Thời gian nhập dữ liệu": item.ThoiGianGui,
						"Ghi chú": item.GhiChu
					}
				})
				jsonToExcel({ data: convertDSBaiBao });
				Vue.$toast.success("Đã xuất Excel", { position: 'top' });
			}, err => { })
		},
		//Xuất excel thêm trạng thái chờ duyệt
		toExcel1() {
			ajaxCALL('/AnPham_Get_ByTrangThai', {
				TrangThai: "2,3"
			}, (res) => {
				let DS_BaiBao = res.data

				let convertDSBaiBao = DS_BaiBao.map(item => {
					let TenNhomAnPham = ''
					if (item.NhomAnPham === 1) {
						TenNhomAnPham = 'Ấn phẩm khoa học'
					} else if (item.NhomAnPham === 2) {
						TenNhomAnPham = 'Hỗ trợ Đầu vào Cao học'
					} else if (item.NhomAnPham === 3) {
						TenNhomAnPham = 'Có hướng dẫn Cao học'
					}
					return {
						STT: item.STT,
						"Tên bài báo": item.TenAnPham,
						"Tác giả": item.TacGia,
						"Đơn vị": item.DonViDaiDien,
						"Danh mục bài báo/ ấn phẩm": item.TenLoaiAnPham,
						"Tên tạp chí": item.TenTapChi,
						"Tên danh mục tạp chí": item.TenLoaiDanhMucTapChi,
						"Năm đăng": item.NamDangBai,
						"Nơi đăng": item.NoiDangBai,
						"Nhóm ấn phẩm": TenNhomAnPham,
						"Ngày nhập": item.ThoiGianGui,
						"Trạng thái": item.TrangThai,
					}
				})
				jsonToExcel({ data: convertDSBaiBao });
				Vue.$toast.success("Đã xuất Excel", { position: 'top' });
			}, err => { })
		},
		onHandleFlagHSCL() {
			this.flagUpdateHSCL = true
		},
		//Hàm nếu có thay đổi HSCL thì sẽ gọi 2 API cập nhật, lý do: cần API cập nhật lần 1 để cập nhật HSCL cho tác giả => lần 2 cập nhật số tiền sau khi gọi API tính lại tiền bằng HSCL vừa lưu
		async onHandleUpdateInfo() {
			const $this = this
			if (this.flagUpdateHSCL) {
				await this.UpdateInfomation()
				await $this.PhiKhenThuong_Cal()?.then((data) => {
					console.log("data[index].KhenThuong", data)
					if (data.length > 0) {
						this.editedItem.AuthorsObjArr = this.editedItem.AuthorsObjArr.map(
							(item, index) => {
								if (item.SoTienKhenThuong === 0 || item.SoTienKhenThuong === null) {
									item.SoTienKhenThuong = data[index].KhenThuong;
								}
								return {
									...item,
									SoTienKhenThuongTamTinh: data[index].KhenThuong,
									CongThucKhenThuongID: this.editedItem.AnPhamObj.CongThucKhenThuongID,
									NoiDungCongThucKhenThuong: "",
								};
							}
						);
					}
				});
				await this.UpdateInfomation()
				Vue.$toast.success("Cập nhật dữ liệu thành công", {
					position: "top",
				})
				CALL("loadAnPhamByTrangThai")
				this.isLoadingSave = false
				this.close()
			} else {
				await this.UpdateInfomation()
				Vue.$toast.success("Cập nhật dữ liệu thành công", {
					position: "top",
				});
				CALL("loadAnPhamByTrangThai");
				this.isLoadingSave = false;
				this.close();
			}
		},
		sendToStorage() {
			const $this = this;
			confirm({
				title: "Xác nhận",
				content: "Xác nhận khôi phục dữ liệu",
				action: function () {
					let AnPhamIDArr = $this.isSelected.map((item) => ({ AnPhamID: item.AnPhamID }));
					if (AnPhamIDArr.length > 0) {
						ajaxCALL(
							"/AnPham_Upd_LocalStorage",
							{
								AnPhamObjArr: AnPhamIDArr,
								Is_Store: 0
							},
							(res) => {
								$this.isSelected = [];
								CALL("loadAnPhamByTrangThai");
								Vue.$toast.success("Khôi phục dữ liệu thành công!", {
									position: "top",
								});
							},
							(err) => { }
						);
					} else {
						Vue.$toast.warning("Vui lòng chọn dữ liệu để khôi phục!", { position: "top" });
					}
				},
			});
		}

	},
}
</script>