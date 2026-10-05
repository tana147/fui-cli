<template>
	<div :class="(isShowResult ? '' : 'bg-wheel') + ' d-flex flex-column h-100dvh'">
        <div>
            <img class="img-logo" src="/_cdn/zen-eorder/30042025/logo.png">
        </div>
        <div class="card-white-trans text-title">
            Cùng ZEN mừng 50 năm <br>
            Ngày Giải phóng miền Nam, <br>
            thống nhất đất nước!
        </div>
        <div v-if="!isShowResult" style="position: absolute; bottom: 60px; width: 100%; padding: 0 40px">
            <!-- Hiển thị vòng quay -->
            <div :class="isShowWheel ? '' : 'd-none'">
                <div class="lucky-wheel"></div>
            </div>
            <div style="height: 56px">
                <div v-if="!isWheel" @click="onWheel" class="button-start" style="margin: 0 10px;">Quay Thưởng</div>
            </div>
        </div>
        <!-- TH 1.2.4: Màn hình kết quả -->
        <template v-if="isShowResult">
            <!-- Không trúng -->
            <template v-if="dataQr.QrCode_Case === '1_2_1'">
                <div class="card-white text-title mt-2">Ting ting!!!</div>
                <div class="card-white mt-3">
                    Tuy chưa có quà <br>
                    nhưng bạn đã có một ngày không thể quên <br>
                    Cùng ZEN hòa mình vào không khí rộn ràng của 30/4 nha!
                </div>
            </template>
            <!-- Trúng -->
            <template v-if="dataQr.QrCode_Case === '1_2_2'">
                <div class="card-white text-title mt-2">CHÚC MỪNG!!!</div>
                <div class="card-white mt-3 d-flex flex-row align-center">
                    <img class="img-voucher" :src="dataQr.AnhQuaTang">
                    <div style="flex: 1">
                        Món quà của bạn là <br>
                        01 phần {{ giftTitle[dataQr.MaVoucher] }}
                    </div>
                </div>
                <p class="card-white-trans pt-3 text-desc">
                    Một ngày không thể quên <br>
                    Cùng ZEN hòa mình vào không khí rộn ràng của ngày 30/4 nha!
                </p>
            </template>
        </template>
    </div>
</template>

<script>
	export default {
		props: [],
    data() {
        const itemScale = 0.773 //0.775//0.773
        const itemRadius = 0.705 //0.72//0.69
        return {
            isWheel: false,
            isShowWheel: false,
            isShowResult: false,
            dataQr: null,
            wheel: null,
            optionWheel: {
                name: "Workout",
                itemBackgroundColors: ["#ffffff"],
                borderWidth: 0,
                lineWidth: 0,
                radius: 0.92,
                isInteractive: false,
                overlayImage: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/arrow-wheel.png",
                items: [
                    {
                        //0: GIFTZT2025_TSZL
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //1: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //2: GIFTZT2025_BRAN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //3: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //4: GIFTZT2025_TCT
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //5: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //6: GIFTZT2025_FLAN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //7: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //8: GIFTZT2025_SSTM
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //9: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //10: GIFTZT2025_BKTT
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //11: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/30042025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                ],
            },
            giftTitle: {
                GIFTZT2025_TSZL: "Trà Sữa ZEN size L",
                GIFTZT2025_BRAN: "Bánh Rán Doraemon",
                GIFTZT2025_TCT: "Trân Châu Tươi",
                GIFTZT2025_FLAN: "Bánh Flan",
                GIFTZT2025_SSTM: "Sương Sáo Thảo Mộc Lạng Sơn",
                GIFTZT2025_BKTT: "Bông Kem Truyền Thống",
            },
        }
    },
    async mounted() {
        const $this = this
        await $this.initLuckyWheel()
    },
    computed: {},
    watch: {},
    methods: {
        async initLuckyWheel() {
            const $this = this
            const container = document.querySelector(".lucky-wheel")
            $this.wheel = new spinWheel.Wheel(container, $this.optionWheel)
            setTimeout(() => {
                $this.isShowWheel = true
            }, 200)
        },
        onWheel() {
            //Gọi API lấy kết quả
            const $this = this
            ajaxCALL(
                "/eorder/auth/QuaTang_Check_QrCode_XacNhan_V3",
                {
                    QRCode: vueData.QRCode,
                    KhachHangID: vueData.KhachHangID,
                },
                (res) => {
                    //Set lại data quà tặng
                    vueData.CTQuaTang = res.data
                    $this.dataQr = res.data[0]
                    //Bắt đầu vòng quay
                    $this.isWheel = true
                    $this.wheel.spinToItem($this.dataQr.QuaySo, 8000, true, 10)
                    //Ẩn vòng quay -> Hiển thị kết quả
                    setTimeout(() => {
                        $this.isShowResult = true
                    }, 9000)
                },
            )
        },
    },
	}
</script>