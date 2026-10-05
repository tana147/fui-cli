<template>
    <v-dialog v-model="vueData.IsShowBanner" fullscreen hide-overlay>
        <div class="div-banner-carousel">
            <v-row justify="space-between" class="position-carousel-icon">
                <v-icon color="success" x-large @click="onChange('PREV')">mdi-arrow-left-bold-circle</v-icon>
                <v-icon color="success" x-large @click="onChange('NEXT')">mdi-arrow-right-bold-circle</v-icon>
            </v-row>
            <v-carousel v-model="CarouselNumber" cycle :interval="8000" touchless hide-delimiters :next-icon="false" :prev-icon="false" height="100%">
                <v-carousel-item v-for="(item, i) in BannerImage" :key="i" :src="item.src" reverse-transition="fade-transition" />
            </v-carousel>
            <v-btn @click="vueData.IsShowBanner = false" large color="primary" class="btn-close-banner">Xem hóa đơn</v-btn>
        </div>
    </v-dialog>
</template>

<script>
export default {
    props: [],
    data() {
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
            CarouselNumber: 0,
            StopTimeOut: null,
        }
    },
    mounted() {
        const $this = this
        //Gọi API lưu log
        $this.insertLog(0, 0)
        //Lưu log xem lâu (trên 3s)
        setTimeout(() => {
            $this.insertLog(0, 1)
        }, 2000)
    },
    methods: {
        insertLog(isXemTiep = 0, isXemLau = 0) {
            ajaxCALL("/eorder/auth/QrCodeTem_Insert_Log", {QrCode: vueData.QrCode, Is_XemTiep: isXemTiep, Is_XemLau: isXemLau})
        },
        onChange(type) {
            const $this = this
            //Clear timeout nếu người dùng chuyển slide
            if ($this.StopTimeOut) {
                clearTimeout($this.StopTimeOut)
            }
            const totalBanner = $this.BannerImage.length - 1
            if (type === "NEXT") {
                if ($this.CarouselNumber === totalBanner) {
                    $this.CarouselNumber = 0
                } else {
                    $this.CarouselNumber++
                }
            } else {
                if ($this.CarouselNumber === 0) {
                    $this.CarouselNumber = totalBanner
                } else {
                    $this.CarouselNumber--
                }
            }
            // Đặt timeoput mới 2.5 giây
            $this.StopTimeOut = setTimeout(() => {
                $this.insertLog(1, 0)
            }, 2500)
        },
    },
    beforeDestroy() {
        const $this = this
        if ($this.StopTimeOut) {
            clearTimeout($this.StopTimeOut)
        }
    },
}
</script>
