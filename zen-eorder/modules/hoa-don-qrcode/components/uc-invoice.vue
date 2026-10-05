<template>
	<div>
		<div class="d-flex flex-row justify-center algin-center" style="gap: 10px">
			<v-btn color="primary" elevation="0" @click="copyImageInvoice">
				<v-icon left>mdi-image-size-select-large</v-icon>Sao chép ảnh
			</v-btn>
			<v-btn color="primary" elevation="0" @click="exportImageInvoice">
				<v-icon left>mdi-image-move</v-icon>Tải ảnh
			</v-btn>
		</div>
		<div id="invoiceContainer" class="order-body">
			<h3 class="mb-0 mt-5 px-5 font-weight-bold text-center">{{vueData.HoaDonID &gt; 0 ? 'HÓA ĐƠN' : 'HÓA ĐƠN TẠM
				TÍNH'}}</h3>
			<div class="tr-product primary--text pa-2 font-weight-bold">
				<span class="d-flex div-sum">
					<p class="align-center">
						<v-icon color="primary">mdi-delete-variant</v-icon>
						<b class="fs-15">{{ HoaDon?.SumNuoc ?? 0 }}</b>
					</p>
					<p class="pl-1 align-center">
						<v-icon color="primary">mdi-dots-hexagon</v-icon>
						<b class="fs-15">{{ HoaDon?.SumTopping ?? 0 }}</b>
					</p>
					<p class="pl-1 align-center">
						<v-icon color="primary">mdi-hamburger</v-icon>
						<b class="fs-15">{{ HoaDon?.SumBanh ?? 0 }}</b>
					</p>
				</span>
			</div>
			<p class="text-center">
				<span>{{ HoaDon?.MaHoaDon }}</span>
				<span>{{ HoaDon?.GioThemMoi }} {{ HoaDon?.NgayThemMoi }}</span>
			</p>
			<p class="mb-0 px-1">Quý Khách: {{ HoaDon?.KhachHang_HoTen }}</p>
			<p class="mb-0 px-1">Ghi chú: {{ HoaDon?.GhiChu }}</p>
			<div class="tr-product">
				<div class="font-weight-bold th-product-name">Sản phẩm</div>
				<div class="font-weight-bold th-product-signature">Signature</div>
				<div class="font-weight-bold td-product-qty">SL</div>
				<div class="font-weight-bold td-product-unit">ĐG(đ)</div>
				<div class="font-weight-bold td-product-zen">ZEN</div>
				<div class="font-weight-bold td-product-price pr-1">TT(đ)</div>
			</div>
			<template v-for="(sp, i) in HoaDon.ChiTietHoaDon.filter((sp) => sp?.TrangThai == null || sp.TrangThai <= 5)" :key="item.HoaDonChiTietID">
				<uc-product :product="sp" :index="i">
			</uc-product></template>
			<div class="order-summary">
				<span>Tạm tính(đ): </span> <span class="float-right">{{
					HoaDon?.TongTien?.toLocaleString("vi-vn") }}</span> <br>
				<span>
					<span>ZEN đã dùng: </span> <span class="error--text float-right">{{
						HoaDon?.KhachTra_Zen?.toLocaleString("vi-vn") }}</span>
				</span>
				<br>
				<span v-if="HoaDon?.LoaiPhanHieuID === 2">
					<span>Tiền VAT: </span> <span class="float-right">{{
						HoaDon?.TongVAT?.toLocaleString("vi-vn") }}</span>
					<br>
				</span>
				<span style="text-decoration: underline"><b>Thanh toán(đ):</b> </span>
				<span class="float-right">
					<b>{{ HoaDon?.TienPhaiTra?.toLocaleString("vi-vn") }}</b>
				</span>
				<br>
			</div>
			<div v-if="Is_OpenPaymentQr">
				<div class="text-center pt-4">
					<f-qrcode v-model="QrCode_Payment_Content" logo="/_cdn/zen-eorder/logo-2025.png" size="240">
					</f-qrcode>
					<p class="mb-4">
						<b>{{ QrCode_Payment_Ten }}</b> <br>
						{{ QrCode_Payment_Stk }} <br>
						{{QrCode_Payment_Text}}
					</p>
				</div>
			</div>
			<div class="order-footer pb-5">
				<div class="d-flex flex-row pa-1">
					<div style="flex: 1; padding-right: 3px">
						<div class="d-flex flex-column justify-center algin-center">
							<div class="text-center">
								<img :src="HoaDon?.Logo_Url" width="80" height="80">
							</div>
							<p class="mb-0 text-center" style="font-size: 10px">{{ HoaDon?.DiaChi }}</p>
							<p class="mt-2 text-center" style="font-size: 12px">
								<b>Mong Quý Khách cho ZEN cơ hội cải thiện nếu dịch vụ có sai xót! <br>
									ZEN chân thành cảm ơn <br>
									Quý Khách!</b>
							</p>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: [],
		data: function () {
			return {
				HoaDon: { ChiTietHoaDon: [] },
				Is_OpenPaymentQr: false,
				QrCode_Payment_Ten: "",
				QrCode_Payment_Stk: "",
				QrCode_Payment_Content: "",
				QrCode_Payment_Text: ""
			}
		},
		computed: {},
		mounted: function () {
			this.getData()
		},
		methods: {
			getData() {
				const $this = this
				const hoaDonID = vueData.HoaDonID
				if (hoaDonID && hoaDonID > 0) {
					const params = {
						HoaDonID: hoaDonID,
					}
					ajaxCALL("/eorder/auth/HoaDon_ThanhToan_Select_ById", params, (res) => {
						if (res.data) {
							$this.dataFormat(res)
						}
					})
				} else if (localStorage.getItem('DataInvoiceImage')) {
					const dataLocal = JSON.parse(localStorage.getItem('DataInvoiceImage'))
					const resLocal = $this.normalizeInvoiceLocal(dataLocal)
					$this.dataFormat(resLocal)
				}
			},
			normalizeInvoiceLocal(dataLocal) {
				const { TongTien, KhachHang, ChiTietHoaDon } = dataLocal
				// 1 HoaDon
				const hoaDon = [{
					HoaDonID: 0,
					CuaHangID: TongTien.CuaHangID,
					MaHoaDon: '',
					TongTien: TongTien.TongTienHoaDon,
					GiamGia: TongTien.GiamGia,
					TongVAT: TongTien.TongVAT,
					TienPhaiTra: TongTien.KhachPhaiTra,
					KhachTra_TienMat: TongTien.KhachTra_TienMat,
					KhachTra_CK: TongTien.KhachTra_CK,
					KhachTra_SPF: TongTien.KhachTra_SPF,
					KhachTra_XSM: TongTien.KhachTra_XSM,
					KhachTra_GRAB: TongTien.KhachTra_GRAB,
					KhachTra_QT: TongTien.KhachTra_QT,
					KhachTra_HT1: TongTien.KhachTra_HT1,
					KhachTra_HT2: TongTien.KhachTra_HT2,
					KhachTra_HT3: TongTien.KhachTra_HT3,
					TienThua: TongTien.TraLai,
					KhachHangID: 0,
					GhiChu: TongTien.GhiChu,
					SumBanh: TongTien.SumBanh,
					SumNuoc: TongTien.SumNuoc,
					SumTopping: TongTien.SumTopping
				}]
				//2 chi tiết
				const chiTiet = []
				ChiTietHoaDon.forEach(sp => {
					const sanPhamGUID = crypto.randomUUID().replace(/-/g, '').substring(0, 10)
					// sản phẩm
					chiTiet.push({
						HoaDonID: 0,
						SanPhamID: sp.SanPhamID,
						SanPhamGUID: sanPhamGUID,
						OrderGUID: sanPhamGUID,
						TenHienThi: sp.TenSanPham,
						SoLuong: sp.SoLuong,
						DonGia: sp.GiaBan_CuaHang,
						ThanhTien: sp.ThanhTien,
						GhiChu: sp.GhiChu,
						Is_SanPham: 1,
						Is_ThuocTinh: 0,
						Is_MangVe: sp.Is_MangVe,
						Is_KhuyenMai: sp.Is_KhuyenMai,
						Is_ThanhToanZen: sp.Is_ThanhToanZen,
						TrangThai: sp.TrangThai,
					})
					// topping
					sp.ThuocTinh?.forEach(tt => {
						chiTiet.push({
							HoaDonID: 0,
							SanPhamID: tt.SanPhamID || 0,
							SanPhamGUID: sanPhamGUID,
							OrderGUID: sanPhamGUID,
							TenHienThi: tt.TenHienThi,
							SoLuong: tt.SoLuong,
							DonGia: tt.GiaBan_CuaHang,
							ThanhTien: tt.GiaBan_CuaHang * tt.SoLuong,
							NhomLienKetChiTiet_ParentID: tt.NhomLienKetChiTiet_ParentID,
							Is_SanPham: 0,
							Is_ThuocTinh: 1,
							Is_ThanhToanZen: tt.Is_ThanhToanZen,
							TrangThai: tt.TrangThai,
						})
	
					})
				})
				return {
					data: [
						hoaDon,
						chiTiet
					]
				}
			},
			dataFormat(res) {
				const $this = this
				const resHoaDon = res.data?.[0]?.[0] ?? {}
				const resChiTietHoaDon = res.data?.[1] ?? []
				const productJsonData = []
				const productFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 1)
				const toppingFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 0)
				productFilter.forEach((item, index) => {
					const topping = toppingFilter.filter((topping) => topping.SanPhamGUID === item.SanPhamGUID)
					const product = { ...item, SoThuTu: index + 1, ThuocTinh: topping }
					productJsonData.push(product)
				})
				//Nếu hoá đơn load từ API thì xử lý Sum (còn load từ danh sách local thì không cần)
				const hoaDonID = vueData.HoaDonID
				if (hoaDonID && hoaDonID > 0) {
					const { Nuoc, Banh, Topping, KhuyenMai, TraSuaM, TraSuaL } = CT_SoLuongOrder(productJsonData)
					resHoaDon.SumNuoc = Nuoc
					resHoaDon.SumTopping = Topping
					resHoaDon.SumBanh = Banh
				}
				const dataJson = { ...resHoaDon, Logo_Url: '/_cdn/zen-eorder/logo-2025.png', ChiTietHoaDon: productJsonData }
				$this.HoaDon = dataJson
				//Xử lý QR Code Banking
				if (resHoaDon.KhachTra_CK > 0) {
					//const TKNganHang = res.data[3][0] ?? []
					const TKNganHang = {
						MaNganHang: '970418',
						SoTaiKhoan: '6790347175',
						TenTaiKhoan: 'CTY TNHH MTV SX TM DV TO MINH',
						TenNganHang: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam'
					}
					const data = {
						Amount: resHoaDon.KhachTra_CK ?? 0,
						CuaHangID: resHoaDon.CuaHangID,
						MaKH: resHoaDon.KhachHang_DienThoai,
						MaHoaDon: resHoaDon.MaHoaDon,
					}
					$this.QrCode_Payment_Content = renderQRCodePayment(data, TKNganHang)
					$this.QrCode_Payment_Ten = TKNganHang?.SoTaiKhoan ?? ""
					$this.QrCode_Payment_Stk = TKNganHang?.TenTaiKhoan ?? ""
					$this.QrCode_Payment_Text = TKNganHang?.TenNganHang ?? ""
					$this.Is_OpenPaymentQr = true
				}
			},
			exportImageInvoice() {
				const imageName = this.HoaDon.MaHoaDon + '.png'
				const element = document.getElementById('invoiceContainer')
				html2canvas(element, {
					scale: 2,           // tăng độ nét
					useCORS: true
				}).then(canvas => {
					const link = document.createElement('a')
					link.download = imageName
					link.href = canvas.toDataURL('image/png')
					link.click()
				})
			},
			copyImageInvoice() {
				const element = document.getElementById("invoiceContainer");
				html2canvas(element, {
					scale: 2, // tăng độ nét
					useCORS: true
				}).then(canvas => {
					canvas.toBlob(async (blob) => {
						try {
							await navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);
							Vue.$toast.success("Đã sao chép ảnh", { position: "top" })
						} catch (err) {
							Vue.$toast.error("Trình duyệt không hỗ trợ tính năng này", { position: "top" })
						}
					});
				})
			}
		},
	}
</script>