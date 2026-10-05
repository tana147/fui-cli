<template>
	<div>
        <div v-if="HoaDon?.ChiTietHoaDon?.length > 0 || KhachHang?.KhachHangID?.length > 0">
            <div class="tr-product bg-dark-green white--text pa-2 font-weight-bold">
                <span class="d-flex div-sum">
                    <p class="align-center">
                        <v-icon color="white">mdi-delete-variant</v-icon>
                        <b class="fs-15">{{ TongTien?.SumNuoc ?? 0 }}</b>
                    </p>
                    <p class="pl-1 align-center">
                        <v-icon color="white">mdi-dots-hexagon</v-icon>
                        <b class="fs-15">{{ TongTien?.SumTopping ?? 0 }}</b>
                    </p>
                    <p class="pl-1 align-center">
                        <v-icon color="white">mdi-hamburger</v-icon>
                        <b class="fs-15">{{ TongTien?.SumBanh ?? 0 }}</b>
                    </p>
                </span>
                <span v-if="KhachHang?.KhachHangID !== ''" class="div-zen">
                    <span>{{ KhachHang?.TenKhachHang }}</span>
                    <b>({{ parseInt(KhachHang.ZEN).toLocaleString("vi-vn") }} ZEN)</b>
                </span>
            </div>
            <div class="tr-product bg-dark-green white--text">
                <div class="td-product-name">Tên món</div>
                <div class="td-product-qty">SL</div>
                <div class="td-product-action" :style="{ visibility: KhachHang.KhachHangID ? 'unset' : 'hidden' }">ZEN</div>
                <div class="td-product-price">T.Tiền</div>
            </div>
            <div class="order-send-body scroll-shadows" :style="{ height: RenderContainer }">
                <uc-product v-for="(item, i) in ChiTietHoaDon" :key="item.SanPhamGuid" :product="item" :index="i">
            </uc-product></div>
            <v-divider class="line-3"></v-divider>
            <div class="footer-container">
                <!-- Hiển thị qrcode khi có hình thức chuyển khoản "2" -->
                <div v-if="TongTien?.HinhThucThanhToan?.indexOf('2') >= 0 &amp;&amp; TongTien?.KhachTra_CK > 0 &amp;&amp; TongTien?.MaHoaDon !== ''">
                    <f-qrcode v-model="QRCodeCK.convertToQrCode" logo="/_cdn/zen-eorder/logo-2025.png" size="200" class="d-flex qrcode-style"></f-qrcode>
                    <p class="font-weight-bold">
                        {{ QRCodeCK.TenSTK }}
                    </p>
                </div>
                <div class="footer-total">
                    <p>
                        Tạm tính (đ) <span class="pull-right">{{ TongTien?.TongTienHoaDon?.toLocaleString("vi-vn") }} </span>
                    </p>
                    <p>
                        ZEN đã dùng <span class="red--text pull-right">{{ TongTien?.TongZEN?.toLocaleString("vi-vn") }} </span>
                    </p>
                    <p v-if="KhachHang?.KhachHangID > 0">
                        ZEN còn lại <span class="red--text pull-right">{{ KhachHang?.TongZENConLai?.toLocaleString("vi-vn") }} </span>
                    </p>
                    <p v-if="TongTien?.HinhThucThanhToan?.indexOf('2') >= 0">
                        Chuyển khoản (đ) <span class="pull-right">{{ TongTien?.KhachTra_CK?.toLocaleString("vi-vn") }} </span>
                    </p>
                    <p class="font-weight-bold">
                        Thanh toán (đ) <span class="pull-right">{{ TongThanhToan.toLocaleString("vi-vn") }}</span>
                    </p>
                </div>
            </div>
            <v-divider class="line-3"></v-divider>
            <!-- Poster -->
            <div class="div-poster-carousel carousel-menu">
                <v-carousel cycle="" :interval="5000" touchless="" hide-delimiters="" :show-arrows="false" height="100%">
                    <v-carousel-item v-for="(item, i) in PosterImage" :key="i" :src="item.src" reverse-transition="fade-transition">
                </v-carousel-item></v-carousel>
            </div>
        </div>
        <div v-else="">
            <!-- Banner Slide -->
            <div class="div-banner-carousel carousel-menu" style="height: 1080px; width: 638px">
                <v-carousel cycle="" :interval="5000" touchless="" hide-delimiters="" :show-arrows="false" height="100%">
                    <v-carousel-item v-for="(item, i) in BannerImage" :key="i" :src="item.src" reverse-transition="fade-transition">
                </v-carousel-item></v-carousel>
            </div>
        </div>
    </div>
</template>

<script>
	export default {
		props: ["hoadon"],
    data: function () {
        const posters = [
            {
                src: "/_cdn/zen-eorder/poster/poster-1.jpg?v=092220250912",
            },
            {
                src: "/_cdn/zen-eorder/poster/poster-2.jpg?v=092220250912",
            },
            {
                src: "/_cdn/zen-eorder/poster/poster-3.jpg?v=092220250912",
            },
        ]
        const banners = [
            {
                src: "/_cdn/zen-eorder/banner/slide-1.jpg?v=092220250912",
            },
            {
                src: "/_cdn/zen-eorder/banner/slide-2.jpg?v=092220250912",
            },
            {
                src: "/_cdn/zen-eorder/banner/slide-3.jpg?v=092220250912",
            },
            {
                src: "/_cdn/zen-eorder/banner/slide-4.jpg?v=092220250912",
            },
            {
                src: "/_cdn/zen-eorder/banner/slide-5.jpg?v=092220250912",
            },
            {
                src: "/_cdn/zen-eorder/banner/slide-6.jpg?v=092220250912",
            },
            {
                src: "/_cdn/zen-eorder/banner/slide-7.jpg?v=092220250912",
            },
        ]
        return {
            BannerImage: _.shuffle(banners),
            PosterImage: _.shuffle(posters),
        }
    },
    computed: {
        HoaDon: function () {
            const $this = this
            return $this.hoadon && $this.hoadon !== "" ? JSON.parse($this.hoadon ?? []) : []
        },
        ChiTietHoaDon: function () {
            const $this = this
            return $this.HoaDon?.ChiTietHoaDon ?? []
        },
        TongTien: function () {
            const $this = this
            return (
                $this.HoaDon?.TongTien ?? {
                    CuaHangID: 0,
                    MaHoaDon: "",
                    TongTienHoaDon: 0,
                    TongVAT: 0,
                    TongZEN: 0,
                    GiamGia: 0,
                    HinhThucThanhToan: ["1"],
                    KhachTra_TienMat: 0,
                    KhachTra_CK: 0,
                    KhachTra_SPF: 0,
                    KhachTra_GRAB: 0,
                    KhachTra_XSM: 0,
                    KhachTra_HT1: 0,
                    KhachTra_HT2: 0,
                    KhachTra_HT3: 0,
                    KhachTra_QT: 0,
                    KhachPhaiTra: 0,
                    SumOrder: 0,
                    SumTopping: 0,
                    SumBanh: 0,
                    SumNuoc: 0,
                }
            )
        },
        KhachHang: function () {
            const $this = this
            return (
                $this.HoaDon?.KhachHang ?? {
                    KhachHangID: "",
                    TenKhachHang: "",
                    ZEN: 0,
                    TongZENConLai: 0,
                    DienThoai: "",
                }
            )
        },
        QRCodeCK: function () {
            const $this = this
            if ($this.HoaDon) {
                const TKNganHang = vueData.TKNganHang[0]
                let data = {
                    Amount: $this.TongTien.KhachTra_CK ?? 0,
                    CuaHangID: $this.TongTien.CuaHangID ?? 0,
                    MaKH: $this.KhachHang.DienThoai ?? "",
                    MaHoaDon: $this.TongTien?.MaHoaDon ?? "",
                }
                return {
                    convertToQrCode: renderQRCodePayment(data, TKNganHang),
                    STK: TKNganHang?.SoTaiKhoan ?? "",
                    TenSTK: TKNganHang?.TenTaiKhoan ?? "",
                    Text: TKNganHang?.TenCuaHang ?? "",
                }
            }
        },
        RenderContainer: function () {
            const $this = this
            //Bình thường: 764px
            let height = "calc(100vh - 688px)"
            if ($this.TongTien?.HinhThucThanhToan.includes("2")) {
                // Hiển thị dòng chuyển khoản: 799px
                height = "calc(100vh - 716px)"
            }
            if ($this.TongTien?.MaHoaDon && $this.TongTien?.MaHoaDon !== "") {
                //Hiển thị mã QR: 882px
                height = "calc(100vh - 796px)"
            }
            return height
        },
        TongThanhToan: function () {
            const $this = this
            return $this.TongTien.KhachPhaiTra - this.TongTien.KhachTra_CK
        },
    },
	}
</script>