<template>
	<div>
		<div v-for="(NhomSanPham, indexNhomSanPham) in DSNhomSanPhamFilter" :key="indexNhomSanPham" style="width: 100%"
			v-if="NhomSanPhamID_Selected || DSSanPhamFilter.filter((product) => product.NhomSanPhamID == NhomSanPham.NhomSanPhamID).length > 0">
			<v-card-text class="green--text d-flex" style="padding-bottom: 0px !important">
				<v-icon dense color="success">{{ NhomSanPham.IconNhomSanPham === "" || !NhomSanPham.IconNhomSanPham ?
					"mdi-help" : NhomSanPham.IconNhomSanPham }}</v-icon>
				<p class="title font-weight-bold ml-2 mb-0" style="text-transform: uppercase">{{
					NhomSanPham.TenNhomSanPham }}</p>
				<v-chip small color="success" style="margin-top: 2px" class="ml-3">
					{{DSSanPhamFilter.filter((product) => product.NhomSanPhamID == NhomSanPham.NhomSanPhamID).length}}
					sản phẩm
				</v-chip>
				<v-chip small color="error" style="margin-top: 2px" class="ml-3"
					v-if="DSSanPhamFilter.filter((product) => product.NhomSanPhamID == NhomSanPham.NhomSanPhamID && product.TinhTrang === 1).length > 0">{{
					DSSanPhamFilter.filter((product) => product.NhomSanPhamID == NhomSanPham.NhomSanPhamID &&
					product.TinhTrang === 1).length }} sản phẩm tạm hết</v-chip>
			</v-card-text>
			<v-card-text style="padding: 0px 5px"
				v-if="DSSanPhamFilter.filter((product) => product.NhomSanPhamID == NhomSanPham.NhomSanPhamID).length > 0">
				<v-row style="margin: 0px" dense>
					<v-col xs="12" sm="8" md="4" lg="2"
						:style="{cursor: SanPham.TinhTrang === 0 ? 'pointer' : 'no-drop', position: 'relative'}"
						@click="onAddProduct(SanPham)"
						v-for="(SanPham, indexSanPham) in DSSanPhamFilter.filter((product) => product.NhomSanPhamID == NhomSanPham.NhomSanPhamID)"
						:key="indexSanPham">
						<v-card style="height: 100%; border-width: 1px" :disabled="SanPham.TinhTrang === 1"
							:style="{'border-color': SanPham.TinhTrang === 0 ? '#4caf50' : '#ff5252'}" outlined>
							<v-img width="100%" min-height="120" max-height="120" contain :src="SanPham.AnhSanPham_Url"
								lazy-src="vueData.v_Set.defaultImg" v-on:error="onImgError(SanPham)">
								<template v-slot:placeholder>
									<v-row dense class="fill-height ma-0" align="center" justify="center">
										<v-progress-circular indeterminate color="grey lighten-5"></v-progress-circular>
									</v-row>
								</template>
							</v-img>
							<div
								style="display: flex; flex-direction: column; position: absolute; right: 5px; top: 5px; gap: 5px">
								<v-chip :color="SanPham.TinhTrang === 1 ? 'error' : 'success'" small> {{
									SanPham.GiaBan_CuaHang.toLocaleString("vi-vn") }} đ </v-chip>
								<v-chip v-if="SanPham.QuanLyTon === 1" color="success" small>Tồn: {{ SanPham.SoLuongTon
									}}</v-chip>
								<v-chip v-if="SanPham.Is_BestSeller === 1" color="success" small>Bán chạy</v-chip>
								<v-chip v-if="SanPham.Is_Signature === 1" color="success" small>Signature</v-chip>
							</div>
							<v-card-title
								style="flex-direction: column; word-break: normal; text-wrap: pretty; padding: 10px !important">
								<p class="text-center mb-0" style="font-size: 15px !important; line-height: normal">{{
									SanPham.TenNgan }}</p>
								<span v-if="SanPham.TinhTrang === 1" class="red--text" style="font-size: 20px">TẠM
									HẾT</span>
							</v-card-title>
						</v-card>
					</v-col>
				</v-row>
			</v-card-text>
		</div>
	</div>
</template>

<script>
	export default {
		props: ["value", "DSNhomSanPhamFilter", "DSSanPhamFilter", "order", "Panel", "NhomSanPhamID_Selected", "SumKhuyenMai"],
	    data() {
	        return {
	            SanPhamKhuyenMaiID: 3212, //Vịt Ngầu - TEA_KM_VITNGAU (09/06/2026)
	            DSSanPham: vueData.DSSanPham,
	        }
	    },
	    watch: {
	        SumKhuyenMai: function (SumKhuyenMai) {
	            /** XỬ LÝ TẶNG VỊT NGẦU - TEA_KM_VITNGAU (NẾU CÓ) **/
	            const indexGift = this.order.findIndex((x) => x.SanPhamID === this.SanPhamKhuyenMaiID)
	            // Kiểm tra Sản phẩm khuyến mãi có nằm trong order ko
	            if (indexGift === -1) {
	                const giftData = this.DSSanPham.find((x) => x.SanPhamID === this.SanPhamKhuyenMaiID)
	                if (giftData) {
	                    if (SumKhuyenMai > 0) {
	                        const defaultProduct = {
	                            SoLuong: SumKhuyenMai,
	                            SoLuongThucTe: 1,
	                            Is_KhuyenMai: 1
	                        }
	                        this.onAddProduct(giftData, defaultProduct)
	                    }
	                }
	            } else {
	                if (SumKhuyenMai === 0) {
	                    this.removeGift()
	                    return
	                }
	                this.order[indexGift].SoLuong = SumKhuyenMai
	            }
	        },
	    },
	    methods: {
	        removeGift() {
	            const _order = this.order.filter((x) => x.SanPhamID !== this.SanPhamKhuyenMaiID)
	            // this.order = _order
	            this.value.SumKhuyenMai = 0
	            this.$emit("update:order", _order)
	        },
	        onAddProduct(SanPham, defaultProduct = { SoLuong: 1, SoLuongThucTe: 1, Is_KhuyenMai: 0 }) {
	            const $this = this
	            const sanpham = SanPham
	            if (sanpham?.TinhTrang === 1) return
	
	            const { SoLuong, SoLuongThucTe, Is_KhuyenMai } = defaultProduct
	            //Khởi tạo tổng tiền món trước
	            let tongTienMon = 0
	            const uuid = uuidv4()
	            sanpham.SanPhamGUID = uuid
	            //Xử lý nhóm liên kết
	            const cloneTopping = JSON.parse(JSON.stringify(vueData.DSChiTietLienKet))
	            const listTopping = cloneTopping.filter((item) => {
	                if (item.NhomLienKetID === sanpham.NhomLienKetID) {
	                    item.Is_ThanhToanZen = item.Is_ThanhToanZen ?? 0
	                    //Phải clone tiền VAT ra để có được tiền VAT gốc, biến TienVAT đang được sử dụng tính toán, nếu TienVAT về = 0 thì sẽ ko hiển thị ra UI
	                    //Vì thế lúc TienVAT = 0 thì phải lấy TienVAT_CuaHang_SanPham để thay thế
	                    item.TienVAT_CuaHang_SanPham = item.TienVAT
	                    item.SanPhamGUID = uuid
	                    return item
	                }
	            })
	            sanpham.ThuocTinh = listTopping
	            //Xử lý nhóm loại ly
	            const cloneNhomLoaiLy = JSON.parse(JSON.stringify(vueData.DSNhomLoaiLy))
	            const listNhomLoaiLy = cloneNhomLoaiLy.filter((item) => {
	                if (item.NhomLoaiLyID === sanpham.NhomLoaiLyID) {
	                    item.SanPhamGUID = uuid
	                    return item
	                }
	            })
	            sanpham.NhomLoaiLy = listNhomLoaiLy
	            sanpham.SoLuong = SoLuong
	            $this.value.TongMonChuaTra += 1
	            // Tính TongTienMon
	            const thanhtien = sanpham.SoLuong * sanpham.GiaBan_CuaHang
	            tongTienMon = thanhtien + (sanpham.TienVAT ?? 0)
	            sanpham.TongTienMon = tongTienMon
	            //Kiểm tra lại nếu sản phẩm ko có TienVAT và PhanTramVAT
	            sanpham.TienVAT = sanpham.TienVAT ?? 0
	            sanpham.TienVAT_CuaHang_SanPham = sanpham.TienVAT
	            sanpham.VAT_CuaHang = sanpham.VAT_CuaHang ?? 0
	            //Thêm sản phẩm vào dsorder
	            $this.order.push({
	                ...sanpham,
	                SoLuongThucTe: SoLuongThucTe,
	                GhiChu: "",
	                Is_ThanhToanZen: 0,
	                Is_KhuyenMai: Is_KhuyenMai,
	                Is_MangVe: 0,
	                HoaDonID: 0,
	                HoaDonChiTietID: 0,
	            })
	            //Sort lại order theo Nước > Topping > Bánh
	            $this.order = sortOrder($this.order)
	            //Tự động mở topping khi thêm sản phẩm
	            if ($this.order.length > 0) {
	                let spuid = sanpham.SanPhamGUID
	                let indexSP = $this.order.findIndex((item) => item.SanPhamGUID === spuid)
	                $this.$emit("update:Panel", indexSP)
	            }
	            //Scroll tới sản phẩm khi vừa mới thêm vào dsorder
	            this.$nextTick(() => {
	                setTimeout(() => {
	                    const itemId = `item-${sanpham.SanPhamGUID}`
	                    const titleElement = document.getElementById(itemId)
	                    if (titleElement) {
	                        titleElement.scrollIntoView({
	                            behavior: "smooth",
	                            block: "nearest",
	                        })
	                    }
	                }, 0)
	            })
	            //Set tiền = 0 nếu thêm sản phẩm
	            if (this.value.HinhThucThanhToan.length === 2) {
	                $this.value.KhachTra_TienMat = 0
	                $this.value.KhachTra_CK = 0
	                $this.value.KhachTra_SPF = 0
	                $this.value.KhachTra_XSM = 0
	                $this.value.KhachTra_GRAB = 0
	                $this.value.KhachTra_QT = 0
	                $this.value.KhachTra_HT1 = 0
	                $this.value.KhachTra_HT2 = 0
	                $this.value.KhachTra_HT3 = 0
	            }
	            this.$emit("update:order", $this.order)
	        },
	        onImgError(SanPham) {
	            SanPham.AnhSanPham_Url = vueData.v_Set.defaultImg
	        },
	    },
	}
</script>