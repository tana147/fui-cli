<template>
    <div class="order-body">
        <h3 class="mb-0 mt-5 px-5 font-weight-bold text-center">HÓA ĐƠN</h3>
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
        <div v-for="item in NhomSanPhamHoaDon" :key="item.NhomSanPham_HoaDonID">
            <p class="primary--text font-weight-bold my-1 text-underline">
                <v-icon color="primary" class="mx-1">{{ item.IconNhomSanPhamHoaDon }}</v-icon
                >{{ item.TenNhomSanPhamHoaDon }} ({{ item.SoLuong }})
            </p>
            <template v-for="(sp, i) in HoaDon.ChiTietHoaDon.filter((sp) => sp.NhomSanPham_HoaDonID === item.NhomSanPham_HoaDonID)" :key="item.HoaDonChiTietID">
                <uc-product :product="sp" :index="i" />
            </template>
        </div>
        <div class="order-footer pb-5">
            <div class="order-summary">
                <span>Tạm tính(đ): </span> <span class="float-right">{{ HoaDon?.TongTien?.toLocaleString("vi-vn") }}</span> <br />
                <span>
                    <span>ZEN đã dùng: </span> <span class="error--text float-right">{{ HoaDon?.KhachTra_Zen?.toLocaleString("vi-vn") }}</span>
                </span>
                <br />
                <span v-if="HoaDon?.LoaiPhanHieuID === 2">
                    <span>Tiền VAT: </span> <span class="float-right">{{ HoaDon?.TongVAT?.toLocaleString("vi-vn") }}</span>
                    <br />
                </span>
                <span style="text-decoration: underline"><b>Thanh toán(đ):</b> </span>
                <span class="float-right">
                    <b>{{ HoaDon?.TienPhaiTra?.toLocaleString("vi-vn") }}</b>
                </span>
                <br />
            </div>
            <div class="d-flex flex-row pa-1">
                <div style="flex: 1; padding-right: 3px">
                    <div class="d-flex flex-column justify-center algin-center">
                        <div class="text-center">
                            <img :src="HoaDon?.Logo_Url" width="80" height="80" />
                        </div>
                        <p class="mb-0 text-center" style="font-size: 10px">{{ HoaDon?.DiaChi }}</p>
                        <p class="mt-2 text-center" style="font-size: 12px"><b>Mong Quý Khách cho ZEN cơ hội cải thiện nếu dịch vụ có sai xót! <br/> ZEN chân thành cảm ơn <br/> Quý Khách!</b></p>
                    </div>
                </div>
                <div style="flex: 1; padding-left: 3px; border-left: 1px solid #258642">
                    <div class="d-flex">
                        <a class="a-link flex-1" href="https://zentea.vn/" target="_blank">Menu</a>
                        <a class="a-link flex-1" href="https://www.facebook.com/ZENTeaVN/" target="_blank">Facebook</a>
                    </div>
                    <div>
                        <a class="a-link" href="https://zalo.me/1805980836121562172" target="_blank">Zalo</a>
                    </div>
                    <div>
                        <a class="a-link mt-2" @click="goToCommunityActivity">Hoạt động cộng đồng</a>
                    </div>
                    <div>
                        <a class="a-link mt-2" href="https://tuyendung.zentea.vn/?4">Tuyển dụng</a>
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
            HoaDon: {},
            NhomSanPhamHoaDon: [],
        }
    },
    computed: {},
    mounted: function () {
        this.getData()
    },
    methods: {
        goToCommunityActivity() {
            window.open(`/hoat-dong-cong-dong?hdid=${vueData.HoaDonID}`, '_blank')
        },
        getData() {
            const $this = this
            const hoaDonID = vueData.HoaDonID
            if (hoaDonID && hoaDonID > 0) {
                const params = {
                    HoaDonID: hoaDonID,
                }
                ajaxCALL("/eorder/auth/HoaDon_ThanhToan_Select_ById", params, (res) => {
                    if (res.data) {
                        const resHoaDon = res.data[0][0] ?? {}
                        const resChiTietHoaDon = res.data[1] ?? []
                        const resNhomSanPhamHoaDon = res.data[2] ?? []
                        $this.NhomSanPhamHoaDon = resNhomSanPhamHoaDon
                        const productJsonData = []
                        const productFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 1)
                        const toppingFilter = resChiTietHoaDon.filter((item) => item.Is_SanPham === 0)
                        productFilter.forEach((item, index) => {
                            const topping = toppingFilter.filter((topping) => topping.SanPhamGUID === item.SanPhamGUID)
                            const product = {...item, SoThuTu: index + 1, ThuocTinh: topping}
                            productJsonData.push(product)
                        })
                        const dataJson = {...resHoaDon, ChiTietHoaDon: productJsonData}
                        $this.HoaDon = dataJson
                    }
                })
            }
        },
    },
}
</script>
