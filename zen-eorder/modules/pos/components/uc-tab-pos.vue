<template>
	<v-container fluid class="tab-mon">
		<v-row class="ma-0">
			<v-col cols="7" class="col-product-list hide-scroll">
				<uc-order-info :thanh_toan="ThanhToan" :socket_data="ParamSocket" />
				<uc-product-list v-model="ThanhToan" :order.sync="order" :Panel.sync="Panel"
					:DSNhomSanPhamFilter="DSNhomSanPhamFilter" :DSSanPhamFilter="DSSanPhamFilter"
					:NhomSanPhamID_Selected="NhomSanPhamID_Selected" :SumKhuyenMai="ThanhToan.SumKhuyenMai" />
			</v-col>
			<v-col cols="5" class="col-order">
				<v-row class="ma-0 bg-green white--text font-weight-bold">
					<v-col cols="12" class="d-flex align-center justify-space-between py-0">
						<div class="d-flex">
							<span class="icon-sum"><v-icon color="white">mdi-delete-variant</v-icon>{{
								roundSoLuong(ThanhToan.SumNuoc) }}</span>
							<span class="icon-sum"><v-icon color="white">mdi-dots-hexagon</v-icon>{{
								roundSoLuong(ThanhToan.SumTopping) }}</span>
							<span class="icon-sum"><v-icon color="white">mdi-hamburger</v-icon>{{
								roundSoLuong(ThanhToan.SumBanh) }}</span>
							<span class="icon-sum" v-if="ThanhToan.SumKhuyenMai > 0"><v-icon
									color="white">mdi-gift-outline</v-icon>{{ roundSoLuong(ThanhToan.SumKhuyenMai)
								}}</span>
						</div>
						<div v-if="!IsOldOrder && vueData.LoaiPhanHieuID === 1" class="d-flex">
							<span class="icon-sum cursor-pointer" @click="onCheckDaRieng">
								<v-icon color="white">{{ isDaRieng ? "mdi-checkbox-marked" :
									"mdi-checkbox-blank-outline" }}</v-icon>
								Đá riêng
							</span>
						</div>
						<span class="icon-sum" v-if="ThanhToan.HoaDonID > 0">{{ ThanhToan.MaHoaDon }}</span>
					</v-col>
				</v-row>
				<div class="order-title">
					<div class="td-product-name">Tên món</div>
					<div class="td-product-price">Tạm tính</div>
					<div class="td-product-qty">Số lượng</div>
					<div class="td-product-zen">
						<span @click="onCheckAllZEN" class="cursor-pointer">
							<v-icon small color="white" v-if="IsCheckAllZEN">mdi-checkbox-marked</v-icon>
							<v-icon small color="white" v-else>mdi-checkbox-blank-outline</v-icon>
							ZEN
						</span>
					</div>
					<div class="td-product-cancel"></div>
				</div>
				<div class="order-list">
					<v-expansion-panels v-model="Panel" focusable flat accordion class="hide-scroll">
						<uc-order-product v-model="ThanhToan" v-for="(SanPham, index) in order" :thu_tu="index"
							:order="order" :SanPham="SanPham" :id="'item-' + SanPham?.SanPhamGUID" />
					</v-expansion-panels>
				</div>
				<div class="order-summary">
					<uc-order-summary v-model="ThanhToan" :order="order" />
				</div>
			</v-col>
		</v-row>
		<v-footer padless class="bg-green">
			<div class="order-footer">
				<div class="d-flex algin-center gap-10px">
					<v-btn class="gap-10px" x-small fab elevation="0" color="white"
						v-for="(NhomSanPham, index) in vueData.DSNhomSanPham" @click="onClickNhomSanPham(NhomSanPham)">
						<v-icon :color="NhomSanPham.NhomSanPhamID === NhomSanPhamID_Selected ? 'error' : 'success'">
							{{ NhomSanPham.IconNhomSanPham === "" || !NhomSanPham.IconNhomSanPham ? "mdi-tag" :
							NhomSanPham.IconNhomSanPham }}
						</v-icon>
					</v-btn>
					<div style="width: 250px">
						<v-text-field ref="TuKhoaTimKiem_SanPham" v-model="TuKhoaTimKiem_SanPham"
							placeholder="F5 - Tìm kiếm" style="background: white" outlined dense clearable
							hide-details></v-text-field>
					</div>
				</div>
				<div class="d-flex algin-center gap-10px">
					<v-btn v-if="ThanhToan?.KhachHangID?.length === 9" class="bg-white" elevation="0" color="primary"
						@click="onClickGift" small outlined>F2 - Khuyến mãi</v-btn>
					<v-btn v-if="AdminUser.indexOf(vueData.user.UserID) >= 0" class="bg-white" elevation="0"
						color="primary" @click="onExportImage" small outlined>In thông tin hóa đơn</v-btn>
					<v-btn :loading="Loading.IsLoadingThanhToanKoIn"
						v-if="vueData.LoaiPhanHieuID !== EnumLoaiPhanHieu.NhaHang && !checkTrangThaiButtonFooter(ThanhToan.TrangThai)"
						small @click="onThanhToanKoIn" elevation="0" class="bg-white" color="success" outlined>F7 -
						Thanh toán không in</v-btn>
					<v-btn :loading="Loading.IsLoadingIn"
						v-if="ThanhToan.HoaDonID > 0 && !checkTrangThaiButtonFooter(ThanhToan.TrangThai) && vueData.LoaiPhanHieuID === EnumLoaiPhanHieu.NhaHang"
						:disabled="order.findIndex((item) => item.HoaDonChiTietID <= 0) >= 0" small
						@click="fn_Print(ThanhToan.TrangThai, EnumLoaiIn.InTamTinh, ThanhToan.HoaDonID, ThanhToan.GhiChu)"
						style="background-color: white" color="success" outlined>F8 - In tạm tính</v-btn>
					<v-btn :loading="Loading.IsLoadingThanhToan" v-if="!checkTrangThaiButtonFooter(ThanhToan.TrangThai)"
						small @click="onConfirmThanhToan(EnumHoaDon.DaThanhToan)" class="bg-white" elevation="0"
						color="success" outlined>F9 - Thanh toán</v-btn>
					<v-btn :loading="Loading.IsLoadingLuu"
						v-if="vueData.LoaiPhanHieuID === EnumLoaiPhanHieu.NhaHang && !checkTrangThaiButtonFooter(ThanhToan.TrangThai)"
						small @click="onLuu" class="bg-white" elevation="0" color="success" outlined>F6 - Lưu & Gửi bếp
						bar </v-btn>
					<v-btn :loading="Loading.IsLoadingChoThanhToan"
						v-if="vueData.LoaiPhanHieuID !== EnumLoaiPhanHieu.NhaHang && !checkTrangThaiButtonFooter(ThanhToan.TrangThai)"
						@click="onChoThanhToan" small class="bg-white" elevation="0" color="success" outlined>Chờ thanh
						toán</v-btn>
					<v-btn small @click="onTaoMoi" color="error" elevation="0"><v-icon left>mdi-plus</v-icon>Tạo
						mới</v-btn>
				</div>
			</div>
		</v-footer>
		<uc-modal-khuyen-mai :show_dialog="vueData.IsShowDialogKhuyenMai" :ds_spkm="vueData.DSSanPham_KhuyenMai"
			v-model="ThanhToan" :order="order" :Panel.sync="Panel" />
	</v-container>
</template>

<script>
	export default {
		props: ["order", "hoa_don", "message_hoa_don"],
	    data() {
	        return {
	            AdminUser: ["NV0000026", "NV0000008"],
	            DSSanPhamFilter: vueData.DSSanPham ?? [],
	            DSNhomSanPhamFilter: vueData.DSNhomSanPham ?? [],
	            isDaChung: false,
	            isDaRieng: false,
	            ThanhToan: {
	                HoaDonID: 0,
	                MaHoaDon: "",
	                TenTrangThai: null,
	                TrangThai: 0,
	                BanID: 0,
	                KhachHangID: 0,
	                KhachHang_QRCode: "",
	                KhachHang_HoTen: "",
	                KhachHang_DienThoai: "",
	                KhachHang_ZEN: 0,
	                KhachHang_LaTra: 0,
	                SoCho: "",
	                GhiChu: "",
	                KhachTra_TienMat: 0,
	                KhachTra_CK: 0,
	                KhachTra_SPF: 0,
	                KhachTra_XSM: 0,
	                KhachTra_GRAB: 0,
	                KhachTra_QT: 0,
	                KhachTra_HT1: 0,
	                KhachTra_HT2: 0,
	                KhachTra_HT3: 0,
	                HinhThucThanhToan: ["1"],
	                KhachTra_Zen: 0,
	                KhachTra_ZenQuyDoi: 0,
	                TongZENConLai: 0,
	                TongZEN: 0,
	                GiamGia: 0,
	                GiamGia_PhanTram: 0,
	                LoaiGiamGia: 0, //0: % - 1: VND
	                TongTienHoaDon: 0,
	                TongVAT: 0,
	                KhachPhaiTra: 0,
	                TraLai: 0,
	                TongMonChuaTra: 0,
	                SumTopping: 0,
	                SumOrder: 0,
	                SumBanh: 0,
	                SumNuoc: 0,
	                SumKhuyenMai: 0,
	                GiaoHang_TenKhachHang: null,
	                GiaoHang_DienThoai: null,
	                GiaoHang_DiaChi: null,
	                GiaoHang_BatDau: null,
	                GiaoHang_KetThuc: null,
	                GiaoHang_CuaHangID: null,
	                GiaoHang_Phi: 0,
	                Invoice_BuyerLegalName: "",
	                Invoice_BuyerTaxCode: "",
	                Invoice_BuyerPhoneNumber: "",
	                Invoice_BuyerAddressLine: "",
	                Invoice_IsXuatSau: true,
	                Invoice_IsXuatHoaDon: false,
	                Invoice_BuyerName: "",
	                Invoice_BuyerEmail: "",
	                Invoice_BuyerBankName: "",
	                Invoice_BuyerBankAccount: "",
	                Is_HoaDonThayThe: 0,
	                LoaiDonHang: vueData.HoaDon.BanID > 0 || vueData.LoaiPhanHieuID !== 2 ? 1 : 2, //Loại đơn hàng nếu có bàn và loại phân hiệu !=2 (Nhà hàng)
	            },
	            Loading: {
	                IsLoadingLuu: false,
	                IsLoadingThanhToan: false,
	                IsLoadingThanhToanKoIn: false,
	                IsLoadingIn: false,
	                IsLoadingHuyMon: false,
	                IsLoadingChoThanhToan: false,
	            },
	            Timeout: 300,
	            TuKhoaTimKiem_SanPham: "",
	            NhomSanPhamID_Selected: null,
	            IsCheckAllZEN: 0,
	            DisableSend: false,
	            ParamSocket: {
	                TongTien: {
	                    MaHoaDon: "",
	                    CuaHangID: 0,
	                    GiamGia: 0,
	                    TongZEN: 0,
	                    KhachPhaiTra: 0,
	                    KhachTra_TienMat: 0,
	                    KhachTra_CK: 0,
	                    KhachTra_SPF: 0,
	                    KhachTra_XSM: 0,
	                    KhachTra_GRAB: 0,
	                    KhachTra_QT: 0,
	                    KhachTra_HT1: 0,
	                    KhachTra_HT2: 0,
	                    KhachTra_HT3: 0,
	                    TongTienHoaDon: 0,
	                    HinhThucThanhToan: null,
	                    TraLai: 0,
	                    TongVAT: 0,
	                    SumOrder: 0,
	                    SumTopping: 0,
	                    SumBanh: 0,
	                    SumNuoc: 0,
	                    SumKhuyenMai: 0,
	                },
	                KhachHang: {
	                    HoaDonID: 0,
	                    KhachHangID: 0,
	                    TenKhachHang: "",
	                    ZEN: 0,
	                    TongZENConLai: 0,
	                    DienThoai: "",
	                },
	                ChiTietHoaDon: [],
	            },
	            Panel: null,
	            IsBeforeUnloadListenerAdded: false,
	        }
	    },
	    watch: {
	        TuKhoaTimKiem_SanPham: function (value) {
	            const $this = this
	            if (value === "" || value === null) {
	                $this.DSSanPhamFilter = vueData.DSSanPham
	            } else {
	                $this.DSSanPhamFilter = vueData.DSSanPham.filter((item) => {
	                    return toSlug(item.TenSanPham).includes(toSlug(value)) && ($this.NhomSanPhamID_Selected === null || item.NhomSanPhamID === $this.NhomSanPhamID_Selected)
	                })
	            }
	        },
	        NhomSanPhamID_Selected: function (value) {
	            const $this = this
	            if (value > 0) {
	                $this.DSSanPhamFilter = vueData.DSSanPham.filter((item) => item.NhomSanPhamID === value)
	                $this.DSNhomSanPhamFilter = vueData.DSNhomSanPham.filter((item) => item.NhomSanPhamID === $this.NhomSanPhamID_Selected)
	            } else {
	                $this.DSSanPhamFilter = vueData.DSSanPham
	                $this.DSNhomSanPhamFilter = vueData.DSNhomSanPham
	            }
	        },
	        "ThanhToan.KhachTra_CK": function (value) {
	            if (value === "") {
	                this.ThanhToan.KhachTra_CK = 0
	            } else {
	                this.$nextTick(() => {
	                    let arr = []
	                    this.order.forEach((item) => {
	                        const topping = item.ThuocTinh.filter((tt) => tt.SoLuong > 0).map((item) => {
	                            return {
	                                TenHienThi: item.TenHienThi,
	                                Is_ThanhToanZen: item.Is_ThanhToanZen,
	                                GiaBan_CuaHang: item.GiaBan_CuaHang,
	                                SoLuong: item.SoLuong,
	                                NhomLienKetChiTiet_ParentID: item.NhomLienKetChiTiet_ParentID,
	                                SanPhamID: item.SanPhamID,
	                                ThanhTien: item.ThanhTien,
	                                PhanTramVAT: item.PhanTramVAT,
	                                TienVAT: item.TienVAT,
	                                TienVAT_CuaHang_SanPham: item.TienVAT_CuaHang_SanPham,
	                            }
	                        })
	                        arr.push({
	                            CuaHangID: vueData.CuaHangID,
	                            SanPhamID: item.SanPhamID,
	                            TenSanPham: item.TenSanPham,
	                            SoLuong: item.SoLuong,
	                            Is_MangVe: item.Is_MangVe ? 1 : 0,
	                            Is_KhuyenMai: item.Is_KhuyenMai,
	                            Is_ThanhToanZen: item.Is_ThanhToanZen,
	                            GiaBan_CuaHang: item.GiaBan_CuaHang,
	                            GhiChu: item.GhiChu,
	                            ThanhTien: item.ThanhTien,
	                            PhanTramVAT: item.PhanTramVAT,
	                            TienVAT: item.TienVAT,
	                            TienVAT_CuaHang_SanPham: item.TienVAT_CuaHang_SanPham,
	                            ThuocTinh: topping,
	                        })
	                    })
	                    this.ParamSocket = {
	                        TongTien: {
	                            MaHoaDon: this.ThanhToan.MaHoaDon ?? "",
	                            CuaHangID: vueData.CuaHangID,
	                            GiamGia: 0,
	                            TongZEN: this.ThanhToan.TongZEN,
	                            KhachPhaiTra: this.ThanhToan.KhachPhaiTra,
	                            KhachTra_TienMat: this.ThanhToan.KhachTra_TienMat,
	                            KhachTra_CK: value,
	                            KhachTra_SPF: this.ThanhToan.KhachTra_SPF,
	                            KhachTra_XSM: this.ThanhToan.KhachTra_XSM,
	                            KhachTra_GRAB: this.ThanhToan.KhachTra_GRAB,
	                            KhachTra_QT: this.ThanhToan.KhachTra_QT,
	                            KhachTra_HT1: this.ThanhToan.KhachTra_HT1,
	                            KhachTra_HT2: this.ThanhToan.KhachTra_HT2,
	                            KhachTra_HT3: this.ThanhToan.KhachTra_HT3,
	                            TongTienHoaDon: this.ThanhToan.TongTienHoaDon,
	                            HinhThucThanhToan: this.ThanhToan.HinhThucThanhToan,
	                            TraLai: this.ThanhToan.TraLai,
	                            TongVAT: this.ThanhToan.TongVAT,
	                            SumOrder: this.ThanhToan.SumOrder,
	                            SumTopping: roundSoLuong(this.ThanhToan.SumTopping),
	                            SumBanh: roundSoLuong(this.ThanhToan.SumBanh),
	                            SumNuoc: roundSoLuong(this.ThanhToan.SumNuoc),
	                            SumKhuyenMai: roundSoLuong(this.ThanhToan.SumKhuyenMai),
	                        },
	                        KhachHang: {
	                            HoaDonID: this.ThanhToan.HoaDonID,
	                            KhachHangID: this.ThanhToan.KhachHangID === 0 || this.ThanhToan.KhachHangID === "" ? "" : this.ThanhToan.KhachHangID,
	                            TenKhachHang: this.ThanhToan.KhachHang_HoTen,
	                            ZEN: this.ThanhToan.KhachHang_ZEN,
	                            LaTra: this.ThanhToan.KhachHang_LaTra,
	                            TongZENConLai: this.ThanhToan.TongZENConLai,
	                            DienThoai: this.ThanhToan.DienThoai,
	                        },
	                        ChiTietHoaDon: arr,
	                    }
	                    setTimeout(() => {
	                        webSocket_Send({
	                            group: vueData.webSocket_Hub_Menu,
	                            data: JSON.stringify(this.ParamSocket),
	                        })
	                    }, 200)
	                })
	            }
	        },
	        order: {
	            handler: function (value) {
	                const $this = this
	                const { Nuoc, Banh, Topping, KhuyenMai, TraSuaM, TraSuaL } = CT_SoLuongOrder(value)
	                this.ThanhToan.SumNuoc = Nuoc
	                this.ThanhToan.SumTopping = Topping
	                this.ThanhToan.SumBanh = Banh
	                this.ThanhToan.SumKhuyenMai = KhuyenMai
	                this.ThanhToan.SumTraSuaM = TraSuaM
	                this.ThanhToan.SumTraSuaL = TraSuaL
	                //Do biến ThanhToan chưa kịp set TongTien
	                //Phải sử dụng nextTick để render ra DOM hết rồi mới gắn được giá trị
	                this.$nextTick(() => {
	                    if (this.ThanhToan.HinhThucThanhToan.length === 0) {
	                        $this.ThanhToan.KhachTra_TienMat = $this.ThanhToan.KhachPhaiTra
	                    }
	                    if (this.ThanhToan.HinhThucThanhToan.length === 1) {
	                        let inputMethod = this.ThanhToan.HinhThucThanhToan[0]
	                        if (this.ThanhToan.HinhThucThanhToan.length === 1) {
	                            switch (inputMethod) {
	                                case EnumHinhThucThanhToan.KhachTra_TienMat:
	                                    $this.ThanhToan.KhachTra_TienMat = $this.ThanhToan.KhachPhaiTra
	                                    break
	                                case EnumHinhThucThanhToan.KhachTra_CK:
	                                    $this.ThanhToan.KhachTra_CK = $this.ThanhToan.KhachPhaiTra
	                                    break
	                                case EnumHinhThucThanhToan.KhachTra_SPF:
	                                    $this.ThanhToan.KhachTra_SPF = $this.ThanhToan.KhachPhaiTra
	                                    break
	                                case EnumHinhThucThanhToan.KhachTra_XSM:
	                                    $this.ThanhToan.KhachTra_XSM = $this.ThanhToan.KhachPhaiTra
	                                    break
	                                case EnumHinhThucThanhToan.KhachTra_GRAB:
	                                    $this.ThanhToan.KhachTra_GRAB = $this.ThanhToan.KhachPhaiTra
	                                    break
	                                case EnumHinhThucThanhToan.KhachTra_QT:
	                                    $this.ThanhToan.KhachTra_QT = $this.ThanhToan.KhachPhaiTra
	                                    break
	                                case EnumHinhThucThanhToan.KhachTra_HT1:
	                                    $this.ThanhToan.KhachTra_HT1 = $this.ThanhToan.KhachPhaiTra
	                                    break
	                                case EnumHinhThucThanhToan.KhachTra_HT2:
	                                    $this.ThanhToan.KhachTra_HT2 = $this.ThanhToan.KhachPhaiTra
	                                    break
	                                case EnumHinhThucThanhToan.KhachTra_HT3:
	                                    $this.ThanhToan.KhachTra_HT3 = $this.ThanhToan.KhachPhaiTra
	                                    break
	                            }
	                        }
	                    }
	                    this.order = value
	                    let arr = []
	                    this.order.forEach((item) => {
	                        const topping = item.ThuocTinh.filter((tt) => tt.SoLuong > 0).map((item) => {
	                            return {
	                                TenHienThi: item.TenHienThi,
	                                Is_ThanhToanZen: item.Is_ThanhToanZen,
	                                GiaBan_CuaHang: item.GiaBan_CuaHang,
	                                SoLuong: item.SoLuong,
	                                NhomLienKetChiTiet_ParentID: item.NhomLienKetChiTiet_ParentID,
	                                SanPhamID: item.SanPhamID,
	                                ThanhTien: item.ThanhTien,
	                                PhanTramVAT: item.PhanTramVAT,
	                                TienVAT: item.TienVAT,
	                                TienVAT_CuaHang_SanPham: item.TienVAT_CuaHang_SanPham,
	                                TrangThai: item.TrangThai ?? 1,
	                            }
	                        })
	                        arr.push({
	                            CuaHangID: vueData.CuaHangID,
	                            SanPhamID: item.SanPhamID,
	                            TenSanPham: item.TenSanPham,
	                            SoLuong: item.SoLuong,
	                            Is_MangVe: item.Is_MangVe ? 1 : 0,
	                            Is_KhuyenMai: item.Is_KhuyenMai,
	                            Is_ThanhToanZen: item.Is_ThanhToanZen,
	                            GiaBan_CuaHang: item.GiaBan_CuaHang,
	                            GhiChu: item.GhiChu,
	                            TrangThai: item.TrangThai ?? 1,
	                            ThanhTien: item.ThanhTien,
	                            PhanTramVAT: item.PhanTramVAT,
	                            TienVAT: item.TienVAT,
	                            TienVAT_CuaHang_SanPham: item.TienVAT_CuaHang_SanPham,
	                            ThuocTinh: topping,
	                        })
	                    })
	                    this.ParamSocket = {
	                        TongTien: {
	                            MaHoaDon: this.ThanhToan.MaHoaDon ?? "",
	                            CuaHangID: vueData.CuaHangID,
	                            GiamGia: 0,
	                            TongZEN: this.ThanhToan.TongZEN,
	                            KhachPhaiTra: this.ThanhToan.KhachPhaiTra,
	                            KhachTra_TienMat: this.ThanhToan.KhachTra_TienMat,
	                            KhachTra_CK: this.ThanhToan.KhachTra_CK,
	                            KhachTra_SPF: this.ThanhToan.KhachTra_SPF,
	                            KhachTra_XSM: this.ThanhToan.KhachTra_XSM,
	                            KhachTra_GRAB: this.ThanhToan.KhachTra_GRAB,
	                            KhachTra_QT: this.ThanhToan.KhachTra_QT,
	                            KhachTra_HT1: this.ThanhToan.KhachTra_HT1,
	                            KhachTra_HT2: this.ThanhToan.KhachTra_HT2,
	                            KhachTra_HT3: this.ThanhToan.KhachTra_HT3,
	                            TongTienHoaDon: this.ThanhToan.TongTienHoaDon,
	                            HinhThucThanhToan: this.ThanhToan.HinhThucThanhToan,
	                            TraLai: this.ThanhToan.TraLai,
	                            TongVAT: this.ThanhToan.TongVAT,
	                            SumOrder: this.ThanhToan.SumOrder,
	                            SumTopping: roundSoLuong(this.ThanhToan.SumTopping),
	                            SumBanh: roundSoLuong(this.ThanhToan.SumBanh),
	                            SumNuoc: roundSoLuong(this.ThanhToan.SumNuoc),
	                            SumKhuyenMai: roundSoLuong(this.ThanhToan.SumKhuyenMai),
	                        },
	                        KhachHang: {
	                            HoaDonID: this.ThanhToan.HoaDonID,
	                            KhachHangID: this.ThanhToan.KhachHangID === 0 || this.ThanhToan.KhachHangID === "" ? "" : this.ThanhToan.KhachHangID,
	                            TenKhachHang: this.ThanhToan.KhachHang_HoTen,
	                            ZEN: this.ThanhToan.KhachHang_ZEN,
	                            LaTra: this.ThanhToan.KhachHang_LaTra,
	                            TongZENConLai: this.ThanhToan.TongZENConLai,
	                            DienThoai: this.ThanhToan.DienThoai,
	                        },
	                        ChiTietHoaDon: arr,
	                    }
	                    setTimeout(() => {
	                        webSocket_Send({
	                            group: vueData.webSocket_Hub_Menu,
	                            data: JSON.stringify(this.ParamSocket),
	                        })
	                    }, 200)
	                    //Trong danh sách order nếu có phần tử thì sẽ lắng nghe beforeunload
	                    //Còn không thì sẽ remove beforeunload
	                    if (value.length > 0 && !this.isBeforeUnloadListenerAdded) {
	                        window.addEventListener("beforeunload", this.handleBeforeUnload)
	                        this.isBeforeUnloadListenerAdded = true
	                    } else if (value.length === 0 && this.isBeforeUnloadListenerAdded) {
	                        window.removeEventListener("beforeunload", this.handleBeforeUnload)
	                        this.isBeforeUnloadListenerAdded = false
	                    }
	                })
	            },
	            deep: true,
	        },
	        hoa_don: {
	            handler: function (value) {
	                //Lấy BanID từ API HoaDon selectByBanID
	                if (value) {
	                    const $this = this
	                    $this.ThanhToan.HoaDonID = value.HoaDonID ?? 0
	                    $this.ThanhToan.BanID = value.BanID ?? 0
	                    $this.ThanhToan.MaHoaDon = value.MaHoaDon
	                    $this.ThanhToan.TenTrangThai = value.TenTrangThai
	                    $this.ThanhToan.TrangThai = value.TrangThai ?? 0
	                    $this.ThanhToan.KhachHangID = value.KhachHangID ?? 0
	                    $this.ThanhToan.KhachHang_QRCode = value.KhachHang_QRCode ?? ""
	                    $this.ThanhToan.KhachHang_HoTen = value.KhachHang_HoTen ?? ""
	                    $this.ThanhToan.KhachHang_DienThoai = value.KhachHang_DienThoai ?? ""
	                    $this.ThanhToan.KhachHang_ZEN = value.KhachHang_Diem ?? 0
	                    $this.ThanhToan.KhachHang_LaTra = value.KhachHang_LaTra ?? 0
	                    $this.ThanhToan.KhachTra_Zen = value.KhachTra_Zen
	                    $this.ThanhToan.KhachTra_ZenQuyDoi = value.KhachTra_ZenQuyDoi
	                    $this.ThanhToan.GhiChu = value.GhiChu ?? ""
	                    $this.ThanhToan.SoCho = value.SoCho ?? ""
	                    $this.ThanhToan.LoaiGiamGia = value.LoaiGiamGia ?? 0
	                    $this.ThanhToan.GiamGia = value.GiamGia ?? 0
	                    $this.ThanhToan.GiamGia_PhanTram = value.GiamGia_PhanTram ?? 0
	                    $this.ThanhToan.KhachTra_TienMat = value.KhachTra_TienMat ?? 0
	                    $this.ThanhToan.KhachTra_CK = value.KhachTra_CK ?? 0
	                    $this.ThanhToan.KhachTra_SPF = value.KhachTra_SPF ?? 0
	                    $this.ThanhToan.KhachTra_XSM = value.KhachTra_XSM ?? 0
	                    $this.ThanhToan.KhachTra_GRAB = value.KhachTra_GRAB ?? 0
	                    $this.ThanhToan.KhachTra_QT = value.KhachTra_QT ?? 0
	                    $this.ThanhToan.KhachTra_HT1 = value.KhachTra_HT1 ?? 0
	                    $this.ThanhToan.KhachTra_HT2 = value.KhachTra_HT2 ?? 0
	                    $this.ThanhToan.KhachTra_HT3 = value.KhachTra_HT3 ?? 0
	                    $this.ThanhToan.HinhThucThanhToan = getHinhThucThanhToan(value.KhachTra_TienMat, value.KhachTra_CK, value.KhachTra_SPF, value.KhachTra_GRAB, value.KhachTra_QT, value.KhachTra_XSM, value.KhachTra_HT1, value.KhachTra_HT2, value.KhachTra_HT3)
	                    $this.ThanhToan.Invoice_BuyerLegalName = value.Invoice_BuyerLegalName ?? ""
	                    $this.ThanhToan.Invoice_BuyerTaxCode = value.Invoice_BuyerTaxCode ?? ""
	                    $this.ThanhToan.Invoice_BuyerPhoneNumber = value.Invoice_BuyerPhoneNumber ?? ""
	                    $this.ThanhToan.Invoice_BuyerAddressLine = value.Invoice_BuyerAddressLine ?? ""
	                    $this.ThanhToan.Invoice_IsXuatSau = value.Invoice_IsXuatSau ?? true
	                    $this.ThanhToan.Invoice_IsXuatHoaDon = value.Is_XuatHoaDonDienTu ?? false
	                    $this.ThanhToan.Invoice_BuyerName = value.Invoice_BuyerName ?? ""
	                    $this.ThanhToan.Invoice_BuyerEmail = value.Invoice_BuyerEmail ?? ""
	                    $this.ThanhToan.Invoice_BuyerBankName = value.Invoice_BuyerBankName ?? ""
	                    $this.ThanhToan.Invoice_BuyerBankAccount = value.Invoice_BuyerBankAccount ?? ""
	                    $this.ThanhToan.Is_HoaDonThayThe = value.Is_HoaDonThayThe ?? 0
	                    //Lấy tiền hóa đơn
	                    $this.ThanhToan.TongTienHoaDon = value.TongTien ?? 0
	                    $this.ThanhToan.TraLai = value.TienThua ?? 0
	                    $this.ThanhToan.KhachPhaiTra = value.TienPhaiTra ?? 0
	                    $this.ThanhToan.TongMonChuaTra = value.TongMonChuaTra ?? 0 //Tổng món chưa trả
	                    $this.ThanhToan.GiaoHang_BatDau = value.GiaoHang_BatDau ?? "" //this.getCurrentTime()
	                    $this.ThanhToan.GiaoHang_KetThuc = value.GiaoHang_KetThuc ?? ""
	                    $this.ThanhToan.GiaoHang_CuaHangID = value.GiaoHang_CuaHangID ?? 0
	                    $this.ThanhToan.GiaoHang_Phi = value.GiaoHang_Phi ?? 0
	                    $this.ThanhToan.LoaiDonHang = value.LoaiDonHang ?? EnumLoaiDonHang.DungTaiCuaHang //LoaiDonHang: 1: Dùng tại cửa hàng; 2: Mang về; 3: Giao hàng
	                    $this.ThanhToan.GiaoHang_TenKhachHang = value.GiaoHang_TenKhachHang ?? ""
	                    $this.ThanhToan.GiaoHang_DienThoai = value.GiaoHang_DienThoai ?? ""
	                    $this.ThanhToan.GiaoHang_DiaChi = value.GiaoHang_DiaChi ?? ""
	                    const arrProductHasZEN = []
	                    for (var sanpham of this.order) {
	                        if (sanpham.Is_ThanhToanZen === 1) {
	                            arrProductHasZEN.push(sanpham)
	                        }
	                        for (var topping of sanpham.ThuocTinh) {
	                            if (topping.Is_ThanhToanZen === 1) {
	                                arrProductHasZEN.push(topping)
	                            }
	                        }
	                    }
	                    this.IsCheckAllZEN = arrProductHasZEN.length > 0 ? true : false
	                }
	            },
	            immediate: true,
	        },
	        message_hoa_don: function (objTime) {
	            const timeStamp = Date.now()
	            //Khi bằng null là sẽ hiện thông báo ở Màn hình user đang mở tab mới
	            if (objTime.time === null) {
	                window.removeEventListener("beforeunload", this.handleBeforeUnload)
	                this.isBeforeUnloadListenerAdded = false
	                confirm({
	                    title: `Hóa đơn đang được truy cập bởi ${objTime?.user ?? ""} .Vui lòng đóng lại màn hình POS để tránh thay đổi món trong hóa đơn ${this.ThanhToan.MaHoaDon}`,
	                    action: function () {
	                        redirect("/hoa-don")
	                    },
	                    cancel: function () {
	                        redirect("/hoa-don")
	                    },
	                })
	                webSocket_Send({ group: vueData.webSocket_Hub_HoaDon, data: { time: timeStamp } })
	                return
	            }
	            //Khi time khác nhau thì bắn thêm tín hiệu = null để tab khác nhận được
	            if (objTime.time !== vueData.TimeStartLoadHoaDon) {
	                webSocket_Send({ group: vueData.webSocket_Hub_HoaDon, data: { time: timeStamp } })
	            }
	        },
	        "ThanhToan.HinhThucThanhToan": function (val) {
	            if (val.indexOf("2") >= 0) {
	                //Nếu hình thức thanh toán thay đổi thì bắn socket sang màn hình khách
	                this.$nextTick(() => {
	                    let arr = []
	                    this.order.forEach((item) => {
	                        const topping = item.ThuocTinh.filter((tt) => tt.SoLuong > 0).map((item) => {
	                            return {
	                                TenHienThi: item.TenHienThi,
	                                Is_ThanhToanZen: item.Is_ThanhToanZen,
	                                GiaBan_CuaHang: item.GiaBan_CuaHang,
	                                SoLuong: item.SoLuong,
	                                NhomLienKetChiTiet_ParentID: item.NhomLienKetChiTiet_ParentID,
	                                SanPhamID: item.SanPhamID,
	                                ThanhTien: item.ThanhTien,
	                                PhanTramVAT: item.PhanTramVAT,
	                                TienVAT: item.TienVAT,
	                                TienVAT_CuaHang_SanPham: item.TienVAT_CuaHang_SanPham,
	                                TrangThai: item.TrangThai ?? 1,
	                            }
	                        })
	                        arr.push({
	                            CuaHangID: vueData.CuaHangID,
	                            SanPhamID: item.SanPhamID,
	                            TenSanPham: item.TenSanPham,
	                            SoLuong: item.SoLuong,
	                            Is_MangVe: item.Is_MangVe ? 1 : 0,
	                            Is_KhuyenMai: item.Is_KhuyenMai,
	                            Is_ThanhToanZen: item.Is_ThanhToanZen,
	                            GiaBan_CuaHang: item.GiaBan_CuaHang,
	                            TrangThai: item.TrangThai ?? 1,
	                            GhiChu: item.GhiChu,
	                            ThanhTien: item.ThanhTien,
	                            PhanTramVAT: item.PhanTramVAT,
	                            TienVAT: item.TienVAT,
	                            TienVAT_CuaHang_SanPham: item.TienVAT_CuaHang_SanPham,
	                            ThuocTinh: topping,
	                        })
	                    })
	                    this.ParamSocket = {
	                        TongTien: {
	                            MaHoaDon: this.ThanhToan.MaHoaDon ?? "",
	                            CuaHangID: vueData.CuaHangID,
	                            GiamGia: 0,
	                            TongZEN: this.ThanhToan.TongZEN,
	                            KhachPhaiTra: this.ThanhToan.KhachPhaiTra,
	                            KhachTra_TienMat: this.ThanhToan.KhachTra_TienMat,
	                            KhachTra_CK: this.ThanhToan.KhachTra_CK,
	                            KhachTra_SPF: this.ThanhToan.KhachTra_SPF,
	                            KhachTra_XSM: this.ThanhToan.KhachTra_XSM,
	                            KhachTra_GRAB: this.ThanhToan.KhachTra_GRAB,
	                            KhachTra_QT: this.ThanhToan.KhachTra_QT,
	                            KhachTra_HT1: this.ThanhToan.KhachTra_HT1,
	                            KhachTra_HT2: this.ThanhToan.KhachTra_HT2,
	                            KhachTra_HT3: this.ThanhToan.KhachTra_HT3,
	                            TongTienHoaDon: this.ThanhToan.TongTienHoaDon,
	                            HinhThucThanhToan: val,
	                            TraLai: this.ThanhToan.TraLai,
	                            TongVAT: this.ThanhToan.TongVAT,
	                            SumOrder: this.ThanhToan.SumOrder,
	                            SumTopping: roundSoLuong(this.ThanhToan.SumTopping),
	                            SumBanh: roundSoLuong(this.ThanhToan.SumBanh),
	                            SumNuoc: roundSoLuong(this.ThanhToan.SumNuoc),
	                            SumKhuyenMai: roundSoLuong(this.ThanhToan.SumKhuyenMai),
	                        },
	                        KhachHang: {
	                            HoaDonID: this.ThanhToan.HoaDonID,
	                            KhachHangID: this.ThanhToan.KhachHangID,
	                            TenKhachHang: this.ThanhToan.KhachHang_HoTen,
	                            ZEN: this.ThanhToan.KhachHang_ZEN,
	                            LaTra: this.ThanhToan.KhachHang_LaTra,
	                            TongZENConLai: this.ThanhToan.TongZENConLai,
	                            DienThoai: this.ThanhToan.DienThoai,
	                        },
	                        ChiTietHoaDon: arr,
	                    }
	                    setTimeout(() => {
	                        webSocket_Send({
	                            group: vueData.webSocket_Hub_Menu,
	                            data: JSON.stringify(this.ParamSocket),
	                        })
	                    }, 200)
	                })
	            }
	        },
	    },
	    mounted() {
	        //Lắng nghe sự kiện keyDown, sử dụng cho phím tắt
	        window.addEventListener("keydown", this.handleKeyDown)
	    },
	    beforeDestroy() {
	        //Hủy sự kiện keyDown khi component destroy
	        window.removeEventListener("keydown", this.handleKeyDown)
	    },
	    computed: {
	        IsOldOrder: function () {
	            const $this = this
	            return $this.ThanhToan.HoaDonID > 0 && checkTrangThaiButtonFooter($this.ThanhToan.TrangThai)
	        },
	    },
	    methods: {
	        handleBeforeUnload(event) {
	            const confirmationMessage = "Bạn có chắc muốn rời khỏi trang này?"
	            event.preventDefault()
	            event.returnValue = confirmationMessage
	            return confirmationMessage
	        },
	        onClickNhomSanPham(NhomSanPham) {
	            const $this = this
	            $this.TuKhoaTimKiem_SanPham = ""
	            $this.NhomSanPhamID_Selected = $this.NhomSanPhamID_Selected === NhomSanPham.NhomSanPhamID ? null : NhomSanPham.NhomSanPhamID
	        },
	        onCheckDaRieng() {
	            const $this = this
	            $this.isDaRieng = !$this.isDaRieng
	            const ghiChu = $this.isDaRieng ? "ĐR" : ""
	            $this.order.forEach((item) => {
	                item.GhiChu = item.GhiChu.replace("ĐR", "").trim()
	                item.GhiChu = ghiChu + " " + item.GhiChu
	            })
	        },
	        handleKeyDown(event) {
	            const $this = this
	            //"F2": Khuyến mãi
	            if (event.keyCode === 113) {
	                event.preventDefault() // Chặn ko cho đẩy page khác
	                //Chỉ hoạt động ở Tab Món
	                if (vueData.TabProduct === 0 && this.ThanhToan.KhachHangID.length === 9) {
	                    $this.onClickGift()
	                }
	            }
	            //"F5": Tìm kiếm sản phẩm
	            if (event.keyCode === 116) {
	                event.preventDefault() // Chặn ko cho Refresh page khi bấm F5
	                //Chỉ hoạt động ở Tab Món
	                if (vueData.TabProduct === 0) {
	                    //Khi Nhấn phím F5 thì Input tìm kiếm = null
	                    $this.TuKhoaTimKiem_SanPham = null
	                    $this.$refs.TuKhoaTimKiem_SanPham.focus()
	                }
	            }
	            //"F6": Lưu và gửi bếp bar (Chỉ có ở nhà hàng)
	            if (event.keyCode === 117) {
	                event.preventDefault() // Chặn ko cho đẩy page khác
	                //Loại phân hiệu ID = 2 là sẽ có Sơ đồ bàn
	                if (vueData.TabProduct === 0 && vueData.LoaiPhanHieuID === EnumLoaiPhanHieu.NhaHang) {
	                    //Lưu và gửi bếp bar
	                    if ($this.Loading.IsLoadingLuu === false) {
	                        $this.onLuu()
	                    }
	                }
	            }
	            //"F7": Thanh toán không in (Chỉ hoạt động ở Tab Món và TEA)
	            if (event.keyCode === 118) {
	                event.preventDefault() // Chặn ko cho đẩy page khác
	                if (vueData.TabProduct === 0 && vueData.LoaiPhanHieuID !== EnumLoaiPhanHieu.NhaHang) {
	                    if ($this.Loading.IsLoadingThanhToanKoIn === false) {
	                        $this.onThanhToanKoIn()
	                    }
	                }
	            }
	            //"F8": In tạm tính (Chỉ hoạt động ở Tab Món và đã có hóa đơn ID)
	            if (event.keyCode === 119) {
	                event.preventDefault() // Chặn ko cho đẩy page khác
	                if (vueData.TabProduct === 0 && this.ThanhToan.HoaDonID > 0 && !checkTrangThaiButtonFooter($this.ThanhToan.TrangThai) && vueData.LoaiPhanHieuID === EnumLoaiPhanHieu.NhaHang) {
	                    $this.fn_Print($this.ThanhToan.TrangThai, EnumLoaiIn.InTamTinh, $this.ThanhToan.HoaDonID, $this.ThanhToan.GhiChu)
	                }
	            }
	            //"F9": Thanh toán (Chỉ hoạt động ở Tab Món)
	            if (event.keyCode === 120) {
	                event.preventDefault() // Chặn ko cho đẩy page khác
	                if (vueData.TabProduct === 0) {
	                    //Thanh toán
	                    if ($this.Loading.IsLoadingThanhToan === false) {
	                        $this.onConfirmThanhToan(EnumHoaDon.DaThanhToan)
	                    }
	                }
	            }
	        },
	        /** FUNC Nút này chỉ xuất hiện bên ZEN TEA*/
	        onThanhToanKoIn() {
	            const $this = this
	            if ($this.validateOrder()) return //Validate trong DSOrder
	            if ($this.checkLoadingProcess()) return //Kiểm tra loading tiến trình
	            $this.Loading.IsLoadingThanhToanKoIn = true
	            $this.startAllLoading() //Bắt đầu loading tất cả các tiến trình
	
	            //Thanh toán và ko in hóa đơn
	            $this
	                .onSend()
	                .then(() => {
	                    setTimeout(() => {
	                        $this.Loading.IsLoadingThanhToanKoIn = false
	                        $this.clearLoading()
	                    }, $this.Timeout)
	                })
	                .catch(() => {
	                    $this.Loading.IsLoadingThanhToanKoIn = false
	                    $this.clearLoading()
	                })
	        },
	        onConfirmThanhToan(TrangThai) {
	            const $this = this
	            if ($this.validateOrder()) return
	            if ($this.checkLoadingProcess()) return //Kiểm tra loading tiến trình
	            //Cho thanh toán luôn, ko cần confirm cho ZEN TEA (2: là phân hiệu có sơ đồ bàn)
	            //Thanh toán và In Luôn
	            if (vueData.LoaiPhanHieuID !== EnumLoaiPhanHieu.NhaHang) {
	                $this.Loading.IsLoadingThanhToan = true
	                $this.startAllLoading()
	                //Is_InHoaDon trong onSend là do là TEA nên sẽ set sẵn = 2, Thanh Toán xong sẽ in hóa đơn luôn
	                $this
	                    .onSend()
	                    .then((data) => {
	                        $this.Loading.IsLoadingThanhToan = false
	                        $this.clearLoading()
	                        //Khi thực hiện onSend xong thì sẽ thực hiện fn_print để IN
	                        Promise.all([$this.fn_Print(TrangThai, EnumLoaiIn.InHoaDon, data.HoaDonID, data.GhiChu)]).catch(() => {
	                            $this.Loading.IsLoadingThanhToan = false
	                            $this.clearLoading()
	                        })
	                    })
	                    .catch(() => {
	                        $this.Loading.IsLoadingThanhToan = false
	                        $this.clearLoading()
	                    })
	                return
	            }
	            //Thông báo xác nhận thanh toán khi có món chưa hoàn thành
	            if ($this.ThanhToan.TongMonChuaTra > 0) {
	                confirm({
	                    title: "Xác nhận thanh toán",
	                    content: `Hóa đơn có ${$this.ThanhToan.TongMonChuaTra} món chưa hoàn thành. Bạn có muốn tiếp tục thanh toán?`,
	                    action: function () {
	                        $this.startAllLoading()
	                        $this.Loading.IsLoadingThanhToan = true
	                        //Gọi API thanh toán
	                        $this
	                            .onSend()
	                            .then((data) => {
	                                $this.Loading.IsLoadingThanhToan = false
	                                $this.clearLoading()
	                                //Sau khi thực hiện thanh toán xong thì sẽ thực hiện fn_print vì do là nhà hàng nên sẽ có thông báo có In hay ko?
	                                Promise.all([$this.fn_Print(TrangThai, EnumLoaiIn.InHoaDon, data.HoaDonID, data.GhiChu)]).catch(() => {
	                                    $this.Loading.IsLoadingThanhToan = false
	                                    $this.clearLoading()
	                                })
	                            })
	                            .catch(() => {
	                                $this.Loading.IsLoadingThanhToan = false
	                                $this.clearLoading()
	                            })
	                    },
	                })
	            } else {
	                //Trường hợp else xảy ra khi Tổng món chưa trả  = 0 thì sẽ ko hiển thị alert, cho phép thanh toán luôn
	                $this.Loading.IsLoadingThanhToan = true
	                $this.startAllLoading()
	                $this
	                    .onSend()
	                    .then((data) => {
	                        $this.Loading.IsLoadingThanhToan = false
	                        $this.clearLoading()
	                        Promise.all([$this.fn_Print(TrangThai, EnumLoaiIn.InHoaDon, data.HoaDonID, data.GhiChu)])
	                    })
	                    .catch(() => {
	                        $this.clearLoading()
	                    })
	            }
	        },
	        async onSend() {
	            const $this = this
	            if ($this.validateOrder()) return //Validate DS order
	            //Nếu khách có hình thức "chuyển khoản" thì phải gọi sang câu "Chờ thanh toán" và hiện thị popup
	            //Trong pop up này sẽ có xác nhận thanh toán thì lúc này mới gọi câu "Thanh toán"
	            if ($this.ThanhToan.HinhThucThanhToan.indexOf("2") >= 0 && $this.ThanhToan.KhachTra_CK > 0) {
	                return new Promise((resolve, reject) => {
	                    $this
	                        .fn_Luu(EnumHoaDon.ChoThanhToan)
	                        .then((dataLuu) => {
	                            setTimeout(() => {
	                                webSocket_Send({
	                                    group: vueData.webSocket_Hub_Menu,
	                                    data: JSON.stringify({
	                                        ...this.ParamSocket,
	                                        TongTien: {
	                                            ...this.ParamSocket.TongTien,
	                                            MaHoaDon: dataLuu.MaHoaDon,
	                                        },
	                                    }),
	                                })
	                            }, 200)
	                            var conf = {
	                                icon: "far fa-question-circle",
	                                title: "Chờ xác nhận chuyển khoản",
	                                content: `Hóa đơn có hình thức chuyển khoản: ${$this.ThanhToan.KhachTra_CK.toLocaleString("vi-vn")}`,
	                                type: "blue",
	                                buttons: {
	                                    ok: {
	                                        text: "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;OK&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;",
	                                        btnClass: "btn-blue",
	                                        action: function () {
	                                            $this
	                                                .fn_ThanhToanHoaDon()
	                                                .then(() => {
	                                                    $this.clearData() //Khi thanh toán có chuyển khoản thì sẽ clearData
	                                                    resolve(dataLuu)
	                                                })
	                                                .catch(() => reject())
	                                        },
	                                    },
	                                    cancel: function () {
	                                        $this.Loading.IsLoadingThanhToan = false
	                                        $this.Loading.IsLoadingThanhToanKoIn = false
	                                        $this.clearLoading()
	                                    },
	                                },
	                            }
	                            if ($isMobile) {
	                                conf.columnClass = "col-xs-6 col-xs-offset-6 col-sm-8 col-sm-offset-8 col-md-5 col-md-offset-8"
	                            } else {
	                                conf.boxWidth = "440px"
	                                conf.useBootstrap = false
	                            }
	                            $.confirm(conf)
	                        })
	                        .catch(() => {
	                            $this.Loading.IsLoadingThanhToan = false
	                            $this.Loading.IsLoadingThanhToanKoIn = false
	                            $this.clearLoading()
	                        })
	                })
	            }
	            //Thanh toán hóa đơn
	            return new Promise((resolve, reject) => {
	                $this
	                    .fn_ThanhToanHoaDon()
	                    .then((data) => {
	                        $this.clearData()
	                        resolve(data)
	                    })
	                    .catch(() => {
	                        reject()
	                    })
	            })
	        },
	        fn_ThanhToanHoaDon() {
	            //Xử lý thanh toán hóa đơn
	            const $this = this
	            if ($this.validateOrder()) return
	            const dataJson = this.convertDataJsonOrder($this.order)
	            const params = {
	                HoaDonID: $this.ThanhToan.HoaDonID ?? 0,
	                CuaHangID: vueData.CuaHangID,
	                KhachHangID: $this.ThanhToan.KhachHangID ?? 0,
	                BanID: vueData.HoaDon.BanID ?? 0,
	                KhachTra_TienMat: $this.ThanhToan.KhachTra_TienMat,
	                KhachTra_CK: $this.ThanhToan.KhachTra_CK,
	                KhachTra_SPF: $this.ThanhToan.KhachTra_SPF,
	                KhachTra_XSM: $this.ThanhToan.KhachTra_XSM,
	                KhachTra_GRAB: $this.ThanhToan.KhachTra_GRAB,
	                KhachTra_QT: $this.ThanhToan.KhachTra_QT,
	                KhachTra_HT1: $this.ThanhToan.KhachTra_HT1,
	                KhachTra_HT2: $this.ThanhToan.KhachTra_HT2,
	                KhachTra_HT3: $this.ThanhToan.KhachTra_HT3,
	                HinhThucThanhToan: $this.ThanhToan.HinhThucThanhToan.length === 0 ? "1" : $this.ThanhToan.HinhThucThanhToan.join(","), // '1,2,3,4,5,6'
	                GhiChu: $this.ThanhToan.GhiChu,
	                SoCho: $this.ThanhToan.SoCho,
	                GiaoHang_BatDau: $this.ThanhToan.GiaoHang_BatDau ?? "",
	                GiaoHang_KetThuc: $this.ThanhToan.GiaoHang_KetThuc ?? "",
	                GiaoHang_CuaHangID: $this.ThanhToan.GiaoHang_CuaHangID ?? 0,
	                GiaoHang_Phi: $this.ThanhToan.GiaoHang_Phi ?? 0,
	                GiaoHang_TenKhachHang: $this.ThanhToan.GiaoHang_TenKhachHang ?? "",
	                GiaoHang_DienThoai: $this.ThanhToan.GiaoHang_DienThoai ?? "",
	                GiaoHang_DiaChi: $this.ThanhToan.GiaoHang_DiaChi ?? "",
	                LoaiDonHang: $this.ThanhToan.LoaiDonHang ?? EnumLoaiDonHang.LoaiDonHangMacDinh,
	                Invoice_BuyerLegalName: $this.ThanhToan.Invoice_BuyerLegalName,
	                Invoice_BuyerTaxCode: $this.ThanhToan.Invoice_BuyerTaxCode,
	                Invoice_BuyerPhoneNumber: $this.ThanhToan.Invoice_BuyerPhoneNumber,
	                Invoice_BuyerAddressLine: $this.ThanhToan.Invoice_BuyerAddressLine,
	                Invoice_IsXuatSau: $this.ThanhToan.Invoice_IsXuatSau,
	                Invoice_IsXuatHoaDon: $this.ThanhToan.Invoice_IsXuatHoaDon,
	                Invoice_BuyerName: $this.ThanhToan.Invoice_BuyerName,
	                Invoice_BuyerEmail: $this.ThanhToan.Invoice_BuyerEmail,
	                Invoice_BuyerBankName: $this.ThanhToan.Invoice_BuyerBankName,
	                Invoice_BuyerBankAccount: $this.ThanhToan.Invoice_BuyerBankAccount,
	                ChiTietOrder_JSON: JSON.stringify(dataJson),
	            }
	            return new Promise((resolve, reject) => {
	                ajaxCALL(
	                    "/eorder/HoaDon_Pos_ThanhToan",
	                    params,
	                    (res) => {
	                        if (res.data) {
	                            const data = res.data[0]
	                            deleteRouterHDIDPos()
	                            Vue.$toast.success("Đã gửi thành công. ZEN cảm ơn quý khách", {
	                                position: "top",
	                            })
	                            let HoaDonID = data.HoaDonID
	                            let GhiChu = data.GhiChu ?? ""
	                            let MaHoaDon = data.MaHoaDon ?? ""
	                            $this.groupWebsocket() //Gửi socket
	                            resolve({
	                                HoaDonID: HoaDonID,
	                                MaHoaDon: MaHoaDon,
	                                GhiChu: GhiChu,
	                            })
	                        }
	                    },
	                    (error) => {
	                        showMessage({
	                            type: "red",
	                            title: "Thanh toán thất bại <br/>" + error.responseJSON.Message ?? "Đã có lổi xảy ra, vui lòng kiểm tra lại đường truyền",
	                        })
	                        reject()
	                    },
	                )
	            })
	        },
	        fn_Print(TrangThai, Is_InHoaDon, HoaDonID, GhiChu) {
	            const $this = this
	            if ($this.checkLoadingProcess()) return
	            //Nhà hàng sẽ hiển thị dialog confirm có in hóa đơn ko?
	            if (TrangThai === EnumHoaDon.DaThanhToan && vueData.LoaiPhanHieuID === EnumLoaiPhanHieu.NhaHang) {
	                confirm({
	                    title: "Thanh toán thành công",
	                    content: "Bạn có muốn in hóa đơn thanh toán?",
	                    action: function () {
	                        $this.onPrint(HoaDonID, EnumLoaiIn.InHoaDon, GhiChu)
	                    },
	                    cancel() {
	                        $this.clearData()
	                    },
	                })
	                return
	            }
	            //Ko phải nhà hàng thì in luôn
	            if (Is_InHoaDon === EnumLoaiIn.InHoaDon && vueData.LoaiPhanHieuID !== EnumLoaiPhanHieu.NhaHang) {
	                $this.onPrint(HoaDonID, EnumLoaiIn.InHoaDon, GhiChu)
	                return
	            }
	            //Trường hợp in tạm tính
	            if (Is_InHoaDon === EnumLoaiIn.InTamTinh) {
	                $this.onPrint(HoaDonID, EnumLoaiIn.InTamTinh, GhiChu)
	            }
	        },
	        async onPrint(HoaDonID, LoaiIn, GhiChu) {
	            const $this = this
	            $this.Loading.IsLoadingIn = true
	            $this.startAllLoading()
	            //1 - In tạm tính, 2 - In hóa đơn
	            new Promise((resolve, reject) => {
	                const params = { HoaDonID: HoaDonID, GhiChu: GhiChu, LoaiIn: LoaiIn }
	                ajaxCALL(
	                    "/eorder/HoaDon_In",
	                    params,
	                    (res) => {
	                        if (res.data) {
	                            Vue.$toast.success(`In ${LoaiIn == EnumLoaiIn.InTamTinh ? "tạm tính" : "hóa đơn"} thành công `, { position: "top" })
	                            if (LoaiIn === EnumLoaiIn.InHoaDon) {
	                                this.clearData()
	                            }
	                            $this.Loading.IsLoadingIn = false
	                            $this.clearLoading()
	                        }
	                    },
	                    (error) => {
	                        $this.Loading.IsLoadingIn = false
	                        $this.clearLoading()
	                        showMessage({
	                            type: "red",
	                            title: "In thất bại",
	                            message: error.responseJSON.Message ?? "Đã có lổi xảy ra, vui lòng kiểm tra lại đường truyền",
	                        })
	                    },
	                )
	            })
	        },
	        clearData() {
	            const $this = this
	            //Nếu hóa đơn bình thường thì clear data
	            vueData.HoaDon.ChiTietHoaDon = []
	            vueData.HoaDon.BanID = null
	            vueData.HoaDon.HoaDonID = 0
	            vueData.HoaDon.TrangThai = 0
	            vueData.HoaDon.MaHoaDon = ""
	            vueData.HoaDon.KhachHangID = null
	            vueData.HoaDon.KhachHang_HoTen = ""
	            vueData.HoaDon.KhachHang_Diem = 0
	            vueData.HoaDon.KhachHang_DienThoai = ""
	            vueData.HoaDon.KhachHang_QRCode = ""
	            vueData.HoaDon.KhachTra_TienMat = 0
	            vueData.HoaDon.KhachTra_CK = 0
	            vueData.HoaDon.KhachTra_SPF = 0
	            vueData.HoaDon.KhachTra_XSM = 0
	            vueData.HoaDon.KhachTra_GRAB = 0
	            vueData.HoaDon.KhachTra_QT = 0
	            vueData.HoaDon.KhachTra_HT1 = 0
	            vueData.HoaDon.KhachTra_HT2 = 0
	            vueData.HoaDon.KhachTra_HT3 = 0
	            vueData.HoaDon.GiamGia = 0
	            vueData.HoaDon.GiamGia_PhanTram = 0
	            vueData.HoaDon.LoaiGiamGia = 0
	            vueData.HoaDon.LoaiDonHang = vueData.HoaDon.BanID > 0 || vueData.LoaiPhanHieuID !== EnumLoaiPhanHieu.NhaHang ? EnumLoaiDonHang.DungTaiCuaHang : EnumLoaiDonHang.MangVe
	            vueData.HoaDon.SoCho = ""
	            vueData.HoaDon.GiaoHang_BatDau = ""
	            vueData.HoaDon.GiaoHang_KetThuc = ""
	            vueData.HoaDon.GiaoHang_CuaHangID = 0
	            vueData.HoaDon.GiaoHang_Phi = 0
	            vueData.HoaDon.GiaoHang_TenKhachHang = ""
	            vueData.HoaDon.GiaoHang_DienThoai = ""
	            vueData.HoaDon.GiaoHang_DiaChi = ""
	            vueData.HoaDon.Invoice_BuyerLegalName = ""
	            vueData.HoaDon.Invoice_BuyerTaxCode = ""
	            vueData.HoaDon.Invoice_BuyerPhoneNumber = ""
	            vueData.HoaDon.Invoice_BuyerAddressLine = ""
	            vueData.HoaDon.Invoice_IsXuatSau = true
	            vueData.HoaDon.Invoice_IsXuatHoaDon = false
	            vueData.HoaDon.Invoice_BuyerName = ""
	            vueData.HoaDon.Invoice_BuyerEmail = ""
	            vueData.HoaDon.Invoice_BuyerBankName = ""
	            vueData.HoaDon.Invoice_BuyerBankAccount = ""
	            vueData.HoaDon.Is_HoaDonThayThe = 0
	            vueData.HoaDon.GhiChu = ""
	            vueData.HoaDon.GhiChu_Huy = ""
	            vueData.HoaDon.TongTien = 0
	            vueData.HoaDon.PhanTramVAT = 0
	            vueData.HoaDon.TongVAT = 0
	            vueData.HoaDon.TienPhaiTra = 0
	            vueData.HoaDon.KhachTra_Zen = 0
	            vueData.HoaDon.KhachTra_ZenQuyDoi = 0
	            vueData.HoaDon.TienThua = 0
	            vueData.HoaDon.TenTrangThai = ""
	            vueData.HoaDon.TongMonChuaTra = 0
	            vueData.hdid = 0
	            $this.ThanhToan.HoaDonID = 0
	            $this.ThanhToan.MaHoaDon = null
	            $this.ThanhToan.TenTrangThai = null
	            $this.ThanhToan.TrangThai = 0
	            $this.ThanhToan.BanID = 0
	            $this.ThanhToan.GiamGia = 0
	            $this.ThanhToan.GiamGia_PhanTram = 0
	            $this.ThanhToan.KhachTra_TienMat = 0
	            $this.ThanhToan.KhachTra_CK = 0
	            $this.ThanhToan.KhachTra_SPF = 0
	            $this.ThanhToan.KhachTra_XSM = 0
	            $this.ThanhToan.KhachTra_GRAB = 0
	            $this.ThanhToan.KhachTra_HT1 = 0
	            $this.ThanhToan.KhachTra_HT2 = 0
	            $this.ThanhToan.KhachTra_HT3 = 0
	            $this.ThanhToan.HinhThucThanhToan = []
	            $this.ThanhToan.KhachHangID = null
	            $this.ThanhToan.KhachHang_QRCode = ""
	            $this.ThanhToan.KhachHang_HoTen = ""
	            $this.ThanhToan.DienThoai = ""
	            $this.ThanhToan.KhachHang_ZEN = 0
	            $this.ThanhToan.KhachHang_LaTra = 0
	            $this.ThanhToan.GhiChu = ""
	            $this.ThanhToan.SoCho = ""
	            $this.ThanhToan.LoaiDonHang = vueData.HoaDon.BanID > 0 || vueData.LoaiPhanHieuID !== EnumLoaiPhanHieu.NhaHang ? EnumLoaiDonHang.DungTaiCuaHang : EnumLoaiDonHang.MangVe
	            $this.ThanhToan.GiaoHang_BatDau = null
	            $this.ThanhToan.GiaoHang_KetThuc = null
	            $this.ThanhToan.GiaoHang_CuaHangID = null
	            $this.ThanhToan.GiaoHang_Phi = 0
	            $this.ThanhToan.GiaoHang_TenKhachHang = null
	            $this.ThanhToan.GiaoHang_DienThoai = null
	            $this.ThanhToan.GiaoHang_DiaChi = null
	            $this.ThanhToan.TongMonChuaTra = 0
	            $this.ThanhToan.Invoice_BuyerLegalName = "Khách hàng không lấy hóa đơn"
	            $this.ThanhToan.Invoice_BuyerTaxCode = ""
	            $this.ThanhToan.Invoice_BuyerPhoneNumber = ""
	            $this.ThanhToan.Invoice_BuyerAddressLine = ""
	            $this.ThanhToan.Invoice_IsXuatSau = true
	            $this.ThanhToan.Invoice_IsXuatHoaDon = vueData.ChiTietCuaHang.TrangThai_XuatHoaDon === 2 //Nếu cửa hàng luôn xuất
	            $this.ThanhToan.Invoice_BuyerName = ""
	            $this.ThanhToan.Invoice_BuyerEmail = ""
	            $this.ThanhToan.Invoice_BuyerBankName = ""
	            $this.ThanhToan.Invoice_BuyerBankAccount = ""
	            $this.ThanhToan.Is_HoaDonThayThe = 0
	            $this.TuKhoaTimKiem_SanPham = ""
	            $this.NhomSanPhamID_Selected = null
	        },
	        checkValidateLoaiDonHang(TrangThai) {
	            const $this = this
	            let flag = false
	            // Nếu Loại đơn hàng === 1 và ko có bàn thì show toast
	            if ($this.ThanhToan.LoaiDonHang === EnumLoaiDonHang.DungTaiCuaHang && vueData.HoaDon.BanID <= 0 && vueData.LoaiPhanHieuID === 2) {
	                Vue.$toast.warning("Đơn hàng dùng tại cửa hàng, bắt buộc phải chọn bàn", { position: "top" })
	                flag = true
	            }
	            return flag
	        },
	        onDelete() {
	            const $this = this
	            const index = $this.order.findIndex((item) => item.SanPhamGUID === $this.SanPham.SanPhamGUID)
	            if (index >= 0) {
	                $this.order.splice(index, 1) //Remove sản phẩm
	            }
	        },
	        onHuyHoaDon(HoaDonID) {
	            const $this = this
	            confirm({
	                title: `Hủy hóa đơn`,
	                content: `Bạn có chắc muốn hủy hóa đơn?`,
	                action: function () {
	                    const params = { HoaDonID: HoaDonID, IsThayThe: 0 }
	                    $this.Loading.IsLoadingHuyMon = true
	                    ajaxCALL(
	                        "/eorder/HoaDon_Huy",
	                        params,
	                        (res) => {
	                            if (res.data) {
	                                showMessage({
	                                    type: "green",
	                                    title: "Hủy hóa đơn thành công",
	                                    icon: "fa fa-check-circle",
	                                })
	                                $this.clearData()
	                                $this.Loading.IsLoadingHuyMon = false
	                                deleteRouterHDIDPos()
	                            }
	                        },
	                        (error) => {
	                            $this.Loading.IsLoadingHuyMon = false
	                            deleteRouterHDIDPos()
	                            return Vue.$toast.error(`${error.responseJSON.Message ?? "Đã có lỗi xảy ra, vui lòng thử lại"}`, { position: "top" })
	                        },
	                    )
	                },
	            })
	        },
	        onTaoMoi() {
	            const $this = this
	            const params = {
	                HoaDonID: $this.ThanhToan.HoaDonID ?? 0,
	                Invoice_BuyerLegalName: $this.ThanhToan.Invoice_BuyerLegalName,
	                Invoice_BuyerTaxCode: $this.ThanhToan.Invoice_BuyerTaxCode,
	                Invoice_BuyerPhoneNumber: $this.ThanhToan.Invoice_BuyerPhoneNumber,
	                Invoice_BuyerAddressLine: $this.ThanhToan.Invoice_BuyerAddressLine,
	                Invoice_IsXuatSau: $this.ThanhToan.Invoice_IsXuatSau,
	                Invoice_IsXuatHoaDon: $this.ThanhToan.Invoice_IsXuatHoaDon,
	                Invoice_BuyerName: $this.ThanhToan.Invoice_BuyerName,
	                Invoice_BuyerEmail: $this.ThanhToan.Invoice_BuyerEmail,
	                Invoice_BuyerBankName: $this.ThanhToan.Invoice_BuyerBankName,
	                Invoice_BuyerBankAccount: $this.ThanhToan.Invoice_BuyerBankAccount,
	            }
	            if ($this.order.length === 0) {
	                Vue.$toast.warning("Danh sách order đang trống, không thể tạo mới", {
	                    position: "top",
	                })
	                return
	            }
	            confirm({
	                title: `Cảnh báo`,
	                content: `Bạn có chắc muốn xóa hết dữ liệu trong đơn hàng?`,
	                action: function () {
	                    $this.clearData()
	                    deleteRouterHDIDPos()
	                },
	            })
	        },
	        onLuu() {
	            const $this = this
	            if ($this.validateOrder()) return
	            if ($this.checkLoadingProcess()) return //Kiểm tra loading tiến trình
	
	            $this.Loading.IsLoadingLuu = true
	            $this.startAllLoading()
	
	            $this
	                .fn_Luu(EnumHoaDon.TiepNhanDonHang)
	                .then(() => {
	                    setTimeout(() => {
	                        $this.Loading.IsLoadingLuu = false
	                        $this.clearLoading()
	                    }, $this.Timeout)
	                })
	                .catch(() => {
	                    $this.Loading.IsLoadingLuu = false
	                    $this.clearLoading()
	                })
	        },
	        fn_Luu(TrangThai) {
	            const $this = this
	            if ($this.validateOrder()) return
	            const dataJson = $this.convertDataJsonOrder($this.order)
	            const params = {
	                HoaDonID: $this.ThanhToan.HoaDonID ?? 0,
	                CuaHangID: vueData.CuaHangID,
	                KhachHangID: $this.ThanhToan.KhachHangID ?? 0,
	                BanID: vueData.HoaDon.BanID ?? 0,
	                KhachTra_TienMat: $this.ThanhToan.KhachTra_TienMat,
	                KhachTra_CK: $this.ThanhToan.KhachTra_CK,
	                KhachTra_SPF: $this.ThanhToan.KhachTra_SPF,
	                KhachTra_XSM: $this.ThanhToan.KhachTra_XSM,
	                KhachTra_GRAB: $this.ThanhToan.KhachTra_GRAB,
	                KhachTra_QT: $this.ThanhToan.KhachTra_QT,
	                KhachTra_HT1: $this.ThanhToan.KhachTra_HT1,
	                KhachTra_HT2: $this.ThanhToan.KhachTra_HT2,
	                KhachTra_HT3: $this.ThanhToan.KhachTra_HT3,
	                HinhThucThanhToan: $this.ThanhToan.HinhThucThanhToan.length === 0 ? "1" : $this.ThanhToan.HinhThucThanhToan.join(","), // '1,2,3,4,5'
	                TrangThai: TrangThai, //EnumHoaDon.TiepNhanDonHang,
	                GhiChu: $this.ThanhToan.GhiChu,
	                SoCho: $this.ThanhToan.SoCho,
	                GiaoHang_BatDau: $this.ThanhToan.GiaoHang_BatDau ?? "",
	                GiaoHang_KetThuc: $this.ThanhToan.GiaoHang_KetThuc ?? "",
	                GiaoHang_CuaHangID: $this.ThanhToan.GiaoHang_CuaHangID ?? 0,
	                GiaoHang_Phi: $this.ThanhToan.GiaoHang_Phi ?? 0,
	                GiaoHang_TenKhachHang: $this.ThanhToan.GiaoHang_TenKhachHang ?? "",
	                GiaoHang_DienThoai: $this.ThanhToan.GiaoHang_DienThoai ?? "",
	                GiaoHang_DiaChi: $this.ThanhToan.GiaoHang_DiaChi ?? "",
	                Invoice_BuyerLegalName: $this.ThanhToan.Invoice_BuyerLegalName,
	                Invoice_BuyerTaxCode: $this.ThanhToan.Invoice_BuyerTaxCode,
	                Invoice_BuyerPhoneNumber: $this.ThanhToan.Invoice_BuyerPhoneNumber,
	                Invoice_BuyerAddressLine: $this.ThanhToan.Invoice_BuyerAddressLine,
	                Invoice_IsXuatSau: $this.ThanhToan.Invoice_IsXuatSau,
	                Invoice_IsXuatHoaDon: $this.ThanhToan.Invoice_IsXuatHoaDon,
	                Invoice_BuyerName: $this.ThanhToan.Invoice_BuyerName,
	                Invoice_BuyerEmail: $this.ThanhToan.Invoice_BuyerEmail,
	                Invoice_BuyerBankName: $this.ThanhToan.Invoice_BuyerBankName,
	                Invoice_BuyerBankAccount: $this.ThanhToan.Invoice_BuyerBankAccount,
	                LoaiDonHang: $this.ThanhToan.LoaiDonHang ?? 0,
	                ChiTietOrder_JSON: JSON.stringify(dataJson),
	            }
	            return new Promise((resolve, reject) => {
	                ajaxCALL(
	                    "/eorder/HoaDon_Pos_Luu",
	                    params,
	                    (res) => {
	                        const data = res.data[0]
	                        const HoaDonID = data.HoaDonID ?? 0
	                        const BanID = data.BanID ?? 0
	                        const MaHoaDon = data.MaHoaDon ?? ""
	                        if (HoaDonID > 0) {
	                            Vue.$toast.success("Đã lưu thành công. ZEN cảm ơn quý khách", {
	                                position: "top",
	                            })
	                            vueData.HoaDon = {
	                                ...vueData.HoaDon,
	                                HoaDonID: HoaDonID,
	                                MaHoaDon: MaHoaDon,
	                                BanID: BanID,
	                            }
	                            pushRouterPos(HoaDonID)
	                            if (!!vueData.hdid) {
	                                //sẽ xảy ra nếu ko có hdìd
	                                loadHoaDon(BanID, HoaDonID).then(() => {
	                                    resolve({
	                                        HoaDonID: HoaDonID,
	                                        BanID: BanID,
	                                        MaHoaDon: MaHoaDon,
	                                    })
	                                })
	                            }
	                        }
	                    },
	                    (error) => {
	                        showMessage({
	                            type: "red",
	                            title: "Lưu thất bại",
	                            message: error.responseJSON.Message ?? "Đã có lổi xảy ra, vui lòng kiểm tra lại đường truyền",
	                        })
	                        reject()
	                    },
	                )
	            })
	        },
	        //Chờ thành toán
	        onChoThanhToan() {
	            const $this = this
	            if ($this.order.length <= 0) {
	                Vue.$toast.warning("Danh sách order đang trống, vui lòng order sản phẩm!", { position: "top" })
	                return
	            }
	            $this.Loading.IsLoadingChoThanhToan = true
	            $this.startAllLoading()
	
	            const dataJson = $this.convertDataJsonOrder($this.order)
	            const params = {
	                HoaDonID: $this.ThanhToan.HoaDonID ?? 0,
	                CuaHangID: vueData.CuaHangID,
	                KhachHangID: $this.ThanhToan.KhachHangID ?? 0,
	                BanID: vueData.HoaDon.BanID ?? 0,
	                KhachTra_TienMat: $this.ThanhToan.KhachTra_TienMat,
	                KhachTra_CK: $this.ThanhToan.KhachTra_CK,
	                KhachTra_SPF: $this.ThanhToan.KhachTra_SPF,
	                KhachTra_XSM: $this.ThanhToan.KhachTra_XSM,
	                KhachTra_GRAB: $this.ThanhToan.KhachTra_GRAB,
	                KhachTra_QT: $this.ThanhToan.KhachTra_QT,
	                KhachTra_HT1: $this.ThanhToan.KhachTra_HT1,
	                KhachTra_HT2: $this.ThanhToan.KhachTra_HT2,
	                KhachTra_HT3: $this.ThanhToan.KhachTra_HT3,
	                HinhThucThanhToan: $this.ThanhToan.HinhThucThanhToan.length === 0 ? "1" : $this.ThanhToan.HinhThucThanhToan.join(","), // '1,2,3,4,5'
	                TrangThai: EnumHoaDon.ChoThanhToan,
	                GhiChu: $this.ThanhToan.GhiChu,
	                SoCho: $this.ThanhToan.SoCho,
	                GiaoHang_BatDau: $this.ThanhToan.GiaoHang_BatDau ?? "",
	                GiaoHang_KetThuc: $this.ThanhToan.GiaoHang_KetThuc ?? "",
	                GiaoHang_CuaHangID: $this.ThanhToan.GiaoHang_CuaHangID ?? 0,
	                GiaoHang_Phi: $this.ThanhToan.GiaoHang_Phi ?? 0,
	                GiaoHang_TenKhachHang: $this.ThanhToan.GiaoHang_TenKhachHang ?? "",
	                GiaoHang_DienThoai: $this.ThanhToan.GiaoHang_DienThoai ?? "",
	                GiaoHang_DiaChi: $this.ThanhToan.GiaoHang_DiaChi ?? "",
	                Invoice_BuyerLegalName: $this.ThanhToan.Invoice_BuyerLegalName,
	                Invoice_BuyerTaxCode: $this.ThanhToan.Invoice_BuyerTaxCode,
	                Invoice_BuyerPhoneNumber: $this.ThanhToan.Invoice_BuyerPhoneNumber,
	                Invoice_BuyerAddressLine: $this.ThanhToan.Invoice_BuyerAddressLine,
	                Invoice_IsXuatSau: $this.ThanhToan.Invoice_IsXuatSau,
	                Invoice_IsXuatHoaDon: $this.ThanhToan.Invoice_IsXuatHoaDon,
	                Invoice_BuyerName: $this.ThanhToan.Invoice_BuyerName,
	                Invoice_BuyerEmail: $this.ThanhToan.Invoice_BuyerEmail,
	                Invoice_BuyerBankName: $this.ThanhToan.Invoice_BuyerBankName,
	                Invoice_BuyerBankAccount: $this.ThanhToan.Invoice_BuyerBankAccount,
	                LoaiDonHang: $this.ThanhToan.LoaiDonHang ?? 0,
	                ChiTietOrder_JSON: JSON.stringify(dataJson),
	            }
	            ajaxCALL(
	                "/eorder/HoaDon_Pos_Luu",
	                params,
	                (res) => {
	                    const hoadonid = res.data[0].HoaDonID
	                    if (hoadonid > 0) {
	                        Vue.$toast.success("Đã gửi thành công. ZEN cảm ơn quý khách", {
	                            position: "top",
	                        })
	                        $this.clearData()
	                        deleteRouterHDIDPos()
	                        setTimeout(() => {
	                            $this.Loading.IsLoadingChoThanhToan = false
	                            $this.clearLoading()
	                        }, $this.Timeout)
	                    }
	                },
	                (error) => {
	                    $this.Loading.IsLoadingChoThanhToan = false
	                    $this.clearLoading()
	                    return Vue.$toast.error(`${error.responseJSON.Message ?? "Đã có lỗi xảy ra, vui lòng thử lại"}`, { position: "top" })
	                },
	            )
	        },
	        convertDataJsonOrder(order) {
	            const dataJson = []
	            //Xử lý danh sách món
	            order.forEach((item) => {
	                const product = {
	                    SanPhamID: item.SanPhamID ? item.SanPhamID : 0,
	                    SanPhamGUID: item.SanPhamGUID,
	                    OrderGUID: item.OrderGUID ?? "",
	                    NhomSanPhamID: item.NhomSanPhamID,
	                    NhomLienKetID: item.NhomLienKetID ?? 0,
	                    NhomLienKetChiTietID: 0,
	                    NhomLienKetChiTiet_ParentID: 0,
	                    HoaDonChiTietID: item.HoaDonChiTietID ?? 0,
	                    LoaiLyID: item.LoaiLyID ?? 0,
	                    TenHienThi: item.TenSanPham,
	                    TenNoiBo: item.TenNgan,
	                    SoLuong: item.SoLuong,
	                    ThuTu: 0,
	                    GhiChu: item.GhiChu ?? "",
	                    Is_MangVe: item.Is_MangVe ? 1 : 0,
	                    Is_SanPham: 1,
	                    Is_ThuocTinh: 0,
	                    Is_ThanhToanZen: item.Is_ThanhToanZen ? 1 : 0,
	                    Is_KhuyenMai: item.Is_KhuyenMai,
	                    TrangThai: item.TrangThai ? item.TrangThai : 1,
	                }
	                dataJson.push(product)
	            })
	            order.forEach((itemSP) => {
	                //Xử lý danh sách topping
	                itemSP.ThuocTinh.forEach((itemTopping) => {
	                    if (itemTopping.SoLuong > 0) {
	                        const topping = {
	                            SanPhamID: itemTopping.SanPhamID ?? 0,
	                            SanPhamGUID: itemSP.SanPhamGUID,
	                            OrderGUID: itemSP.OrderGUID ?? "",
	                            NhomSanPhamID: itemTopping.NhomSanPhamID,
	                            NhomLienKetID: itemTopping.NhomLienKetID ?? 0,
	                            NhomLienKetChiTietID: itemTopping.NhomLienKetChiTietID,
	                            NhomLienKetChiTiet_ParentID: itemTopping.NhomLienKetChiTiet_ParentID,
	                            HoaDonChiTietID: itemTopping.HoaDonChiTietID ?? 0,
	                            TenHienThi: itemTopping.TenHienThi,
	                            TenNoiBo: itemTopping.TenNoiBo,
	                            SoLuong: itemTopping.SanPhamID > 0 ? itemTopping.SoLuong : itemSP.SoLuong,
	                            ThuTu: itemTopping.ThuTu,
	                            GhiChu: "",
	                            Is_MangVe: itemSP.Is_MangVe ? 1 : 0,
	                            Is_SanPham: 0,
	                            Is_ThuocTinh: 1,
	                            Is_ThanhToanZen: itemTopping.Is_ThanhToanZen,
	                            Is_KhuyenMai: 0, //Khuyến mãi = 0 do topping ko có khuyến mãi
	                            TrangThai: itemTopping.TrangThai ? itemTopping.TrangThai : 1,
	                        }
	                        dataJson.push(topping)
	                    }
	                })
	            })
	            return dataJson
	        },
	        onCheckAllZEN() {
	            const $this = this
	            //Nếu hóa đơn cũ thì không xử lý
	            //1: Chờ xử lý, 2: Chờ thanh toán, 3: Đã thanh toán, 4: Hoàn tất, 5: Đã hủy, 6: Đã thanh toán một phần, 7: Đã trả hàng, 8: Đặt trước, 9: Tiếp nhận đơn hàng
	            if ($this.IsOldOrder) {
	                return
	            }
	            //Nếu có Danh sách order > 0 và ZEN khách phải > 0
	            $this.IsCheckAllZEN = $this.IsCheckAllZEN === EnumCheckZEN.UnCheck ? EnumCheckZEN.Check : EnumCheckZEN.UnCheck
	            if ($this.order.length > 0 && $this.ThanhToan.KhachHang_ZEN > 0) {
	                let zen = this.ThanhToan.KhachHang_ZEN
	                let mergeTPToProduct = []
	                //Day Topping ra ngoai cung` cap voi san pham
	                $this.order.forEach((sp) => {
	                    mergeTPToProduct.push(sp)
	                    sp.ThuocTinh.forEach((tt) => {
	                        if (tt.SoLuong > 0) {
	                            mergeTPToProduct.push(tt)
	                        }
	                    })
	                })
	                if ($this.IsCheckAllZEN === EnumCheckZEN.Check) {
	                    const arrSelectedItems = this.findSubsetItems(zen, mergeTPToProduct)
	                    let newOrder = []
	                    $this.order.forEach((sp) => {
	                        const findSanPham = arrSelectedItems.find((selectedItem) => selectedItem.SanPhamGUID === sp.SanPhamGUID && selectedItem.SanPhamID === sp.SanPhamID && sp.Is_KhuyenMai === 0)
	                        if (findSanPham) {
	                            let newThuocTinh = []
	                            sp.ThuocTinh.forEach((tt) => {
	                                const findThuocTinh = arrSelectedItems.find((selectedItem) => selectedItem.SanPhamID === tt.SanPhamID && selectedItem.SanPhamGUID === tt.SanPhamGUID && selectedItem.NhomLienKetID === tt.NhomLienKetID && tt.Is_KhuyenMai === 0)
	                                if (findThuocTinh) {
	                                    newThuocTinh.push({ ...findThuocTinh, Is_ThanhToanZen: 1 })
	                                } else {
	                                    newThuocTinh.push(tt)
	                                }
	                            })
	                            newOrder.push({
	                                ...findSanPham,
	                                ThuocTinh: newThuocTinh,
	                                Is_ThanhToanZen: 1,
	                            })
	                        } else {
	                            let newThuocTinh = []
	                            sp.ThuocTinh.forEach((tt) => {
	                                const findThuocTinh = arrSelectedItems.find((selectedItem) => selectedItem.SanPhamID === tt.SanPhamID && selectedItem.SanPhamGUID === tt.SanPhamGUID && selectedItem.NhomLienKetID === tt.NhomLienKetID && tt.Is_KhuyenMai === 0)
	                                if (findThuocTinh) {
	                                    newThuocTinh.push({ ...findThuocTinh, Is_ThanhToanZen: 1 })
	                                } else {
	                                    newThuocTinh.push(tt)
	                                }
	                            })
	                            newOrder.push({ ...sp, ThuocTinh: newThuocTinh })
	                        }
	                    })
	                    $this.order = newOrder
	                } else if ($this.IsCheckAllZEN === EnumCheckZEN.UnCheck) {
	                    $this.order = $this.order.map((item) => {
	                        const topping = item.ThuocTinh.map((itemTP) => {
	                            if (itemTP.SoLuong > 0) {
	                                itemTP.Is_ThanhToanZen = $this.IsCheckAllZEN
	                                return itemTP
	                            }
	                            return itemTP
	                        })
	                        item.Is_ThanhToanZen = $this.IsCheckAllZEN
	                        item.ThuocTinh = topping
	                        return item
	                    })
	                }
	            }
	        },
	        /** Tìm ra các tổ hợp con*/
	        findSubsetItems(TongZEN, order) {
	            let maxVal = 0 // Giá trị tối đa có thể đạt được
	            let subset = [] // Tập con tốt nhất
	            // Hàm tìm tất cả các tổ hợp có thể của các món đồ
	            function findSubset(index, currentSubset, currentVal, currentCost) {
	                if (index === order.length) {
	                    // Nếu đã duyệt qua tất cả các món đồ, kiểm tra xem có phải tập con tốt nhất không
	                    if (currentVal > maxVal && currentCost <= TongZEN) {
	                        maxVal = currentVal
	                        subset = [...currentSubset]
	                    }
	                    return
	                }
	                // Thử bỏ đi món ở index hiện tại
	                findSubset(index + 1, currentSubset, currentVal, currentCost)
	                // Thử thêm món ở index hiện tại vào tập con
	                currentSubset.push(order[index])
	                const itemTongTienMon = order[index].SoLuong * order[index].GiaBan_CuaHang
	                findSubset(index + 1, currentSubset, currentVal + itemTongTienMon, currentCost + itemTongTienMon)
	                currentSubset.pop() // Quay lui
	            }
	            findSubset(0, [], 0, 0) // Bắt đầu từ index 0 và tập con rỗng
	            return subset
	        },
	        /**Paramater Trạng thái: Trạng thái của đơn hàng */
	        validateOrder(TrangThai) {
	            const MAX_LENGTH_PRICE = 15
	            const $this = this
	            let flag = false
	            if ($this.ThanhToan.TongZEN > $this.ThanhToan.KhachHang_ZEN) {
	                Vue.$toast.warning("Tổng ZEN đang vượt quá ZEN của khách", {
	                    position: "top",
	                })
	                flag = true
	            }
	            if ($this.order.length <= 0) {
	                Vue.$toast.warning("Danh sách order đang trống, vui lòng order sản phẩm!", { position: "top" })
	                flag = true
	            }
	            //Kiểm tra danh sách order có món nào hủy ko? -> Nếu Hủy thì return thông báo, không cho order
	            const indexCheckProductCancel = $this.order.findIndex((item) => item.TrangThai === 6 || item.TrangThai === 7) // Lấy vị trí index trong product có trạng thái 'hủy'
	            const arrCheckProdcutCancel = $this.order.filter((item) => item.TrangThai !== 6 && item.TrangThai !== 7) // Lấy mảng có element trong product có trạng thái khác 'hủy'
	            if ($this.ThanhToan.Is_HoaDonThayThe === 0 && indexCheckProductCancel !== -1 && arrCheckProdcutCancel.length === 0) {
	                Vue.$toast.warning("Bạn phải order trước khi thanh toán", {
	                    position: "top",
	                })
	                flag = true
	            }
	            if ($this.checkValidateLoaiDonHang(TrangThai)) {
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_TienMat.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán tiền mặt bị vượt quá 15 số", {
	                    position: "top",
	                })
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_CK.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán chuyển khoản bị vượt quá 15 số", { position: "top" })
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_QT.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán quẹt thẻ bị vượt quá 15 số", {
	                    position: "top",
	                })
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_SPF.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán ShopeeFood bị vượt quá 15 số", { position: "top" })
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_XSM.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán Xanh SM bị vượt quá 15 số", { position: "top" })
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_GRAB.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán Grab bị vượt quá 15 số", { position: "top" })
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_HT1.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán HT1 bị vượt quá 15 số", { position: "top" })
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_HT2.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán HT2 bị vượt quá 15 số", { position: "top" })
	                flag = true
	            }
	            if ($this.ThanhToan.KhachTra_HT3.toString().length >= MAX_LENGTH_PRICE) {
	                Vue.$toast.warning("Hình thức thanh toán HT3 bị vượt quá 15 số", { position: "top" })
	                flag = true
	            }
	            return flag
	        },
	        /** Kiểm tra thao tác khi đâng có 1 tiến tình đang chạy mà thực hiện 1 thao tác khác */
	        checkLoadingProcess() {
	            const $this = this
	            let textAlert = ""
	            if ($this.Loading.IsLoadingChoThanhToan) textAlert = "Chờ thanh toán"
	            if ($this.Loading.IsLoadingHuyMon) textAlert = "Hủy món"
	            if ($this.Loading.IsLoadingIn) textAlert = "In"
	            if ($this.Loading.IsLoadingLuu) textAlert = "Lưu hóa đơn"
	            if ($this.Loading.IsLoadingThanhToan) textAlert = "Thanh toán"
	            if ($this.Loading.IsLoadingThanhToanKoIn) textAlert = "Thanh toán không in"
	
	            if (textAlert !== "") {
	                // const message = `Thao tác ${textAlert} đang thực hiện, vui lòng chờ thực hiện xong`
	                const message = `Thao tác đang thực hiện, vui lòng chờ thực hiện xong`
	                Vue.$toast.error(message, { position: "top" })
	            }
	            return textAlert !== ""
	        },
	        /** Chuyển các Loading về false */
	        clearLoading() {
	            const $this = this
	            $this.Loading.IsLoadingChoThanhToan = false
	            $this.Loading.IsLoadingHuyMon = false
	            $this.Loading.IsLoadingIn = false
	            $this.Loading.IsLoadingLuu = false
	            $this.Loading.IsLoadingThanhToan = false
	            $this.Loading.IsLoadingThanhToanKoIn = false
	        },
	        /** Chuyển các Loading về true */
	        startAllLoading() {
	            const $this = this
	            $this.Loading.IsLoadingChoThanhToan = true
	            $this.Loading.IsLoadingHuyMon = true
	            $this.Loading.IsLoadingIn = true
	            $this.Loading.IsLoadingLuu = true
	            $this.Loading.IsLoadingThanhToan = true
	            $this.Loading.IsLoadingThanhToanKoIn = true
	        },
	        groupWebsocket() {
	            webSocket_Send({ group: vueData.webSocket_Hub_Bep, data: Date.now() })
	            webSocket_Send({ group: vueData.webSocket_Hub_Order, data: Date.now() })
	        },
	        onClickGift() {
	            const params = {
	                KhachHangID: this.ThanhToan.KhachHangID,
	                CuaHangID: vueData.CuaHangID,
	            }
	            ajaxCALL("/eorder/KhachHang_Select_KhuyenMai", params, (res) => {
	                if (res.data) {
                    vueData.IsShowDialogKhuyenMai = true
                    vueData.DSSanPham_KhuyenMai = res.data
                }
            })
        },
        onExportImage() {
            const $this = this
            const dataSocket = this.ParamSocket
            dataSocket.TongTien.GhiChu = $this.ThanhToan.GhiChu
            console.log('dataSocket', dataSocket)
            localStorage.setItem("DataInvoiceImage", JSON.stringify(dataSocket)) //Lưu local để xử lý xuất ảnh
            setTimeout(() => {
                openWindow({
                    title: "Thông tin chuyển khoản",
                    width: 600,
                    height: 500,
                    url: `/hoa-don-qrcode`,
                })
            }, 200)
        },
    },
	}
</script>