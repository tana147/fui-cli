<template>
	<div class="container-wheel">
        <!-- Hiển thị vòng quay -->
        <div v-if="!isShowResult" class="full-screen flex-center">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x1.png" class="img-heart-1">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x2.png" class="img-heart-2">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x3.png" class="img-heart-3-wheel">
            <img src="/_cdn/zen-eorder/valentine-2025/arrow-wheel.png" class="bg-wheel-center">

            <div class="bg-paper" style="flex: 1">
                <p class="fs-18 mb-1 mt-4">HAPPY<br></p>
                <p class="text-banner mb-1">VALENTINE'S DAY</p>
                <br>
                <p class="text-subbanner mb-1">
                    "DÙ CHO TẬN THẾ VẪN YÊU NHAU, <br>
                    LUÔN BÊN NHAU.." <br>
                </p>
                <div class="lucky-wheel mb-150" :style="isShowWheel ? '' : 'display: none'"></div>
                <div v-if="!isWheel" @click="onWheel" class="btn-style btn-wheel">BẮN TIM</div>
            </div>
        </div>

        <!-- TH 1.2.4: Màn hình kết quả -->
        <div v-if="isShowResult" class="full-screen flex-center">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x1.png" class="img-heart-1">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x2.png" class="img-heart-2">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x3.png" class="img-heart-3-center">
            <div class="bg-paper" style="flex: 1">
                <p class="fs-18 mb-1 mt-4">HAPPY<br></p>
                <p class="text-banner mb-1">VALENTINE'S DAY</p>
                <br>
                <p class="text-subbanner mb-1">
                    "DÙ CHO TẬN THẾ VẪN YÊU NHAU, <br>
                    LUÔN BÊN NHAU.." <br>
                </p>
                <!-- Không trúng -->
                <div v-if="dataQr.QrCode_Case === '1_2_1'">
                    <div class="card-white mt-30px">
                        {{ messageResult[dataQr.ThongBaoKhongTrung].TieuDe }}
                        <div class="arrow"></div>
                    </div>
                    <div class="card-white mt-30px">
                        {{ messageResult[dataQr.ThongBaoKhongTrung].NoiDung }}
                        <div class="arrow"></div>
                    </div>
                </div>
                <!-- Trúng -->
                <div v-if="dataQr.QrCode_Case === '1_2_2'">
                    <div class="card-white mt-30px">
                        Hết hồn chưa? <br> Tưởng không có quà Valentine hả? <br>
                        Xí! ZEN đã tặng rồi nè! 🎁
                        <div class="arrow"></div>
                    </div>
                    <div class="card-white d-flex flex-row mt-30px align-center">
                        <img class="img-voucher" :src="dataQr.AnhQuaTang">
                        <div class="text-voucher">
                            <p class="mb-2">Món quà của bạn là <br> {{ giftTitle[dataQr.MaVoucher] }}</p>
                            <p class="mb-0 fs-14">
                                {{ giftMessage[dataQr.MaVoucher] }}
                            </p>
                        </div>
                        <div class="arrow"></div>
                    </div>
                </div>
            </div>
            <p>Chúc bạn một Valentine ngọt ngào</p>
        </div>
    </div>
</template>

<script>
	export default {
		props: ["pin"],
    data() {
        const itemScale = 0.85
        const itemRadius = 0.5
        return {
            isWheel: false,
            isShowWheel: false,
            isShowResult: false,
            dataQr: null,
            wheel: null,
            optionWheel: {
                name: "Workout",
                radius: 0.85,
                borderWidth: 0,
                lineWidth: 1,
                isInteractive: false,
                lineColor: "#b60a0a",
                overlayImage: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/arrow-wheel-only-2.png",
                items: [
                    {
                        //0: Babythree
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //1: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //2: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //3: Điểm ZEN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //4: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //5: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //6: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //7: Điểm ZEN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //8: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //9: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/valentine-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                ],
            },
            messageResult: [
                {TieuDe: "Ha...Ha...Ha...", NoiDung: "Hành trình săn quà của bạn đã kết thúc… mà chưa có món quà nào hết, chắc do may mắn bận đi chơi Valentine rồi hả ta?"},
                {TieuDe: "Ha...Ha...Ha...", NoiDung: "Gần trúng rồi đóo! Thêm một vòng nữa biết đâu lại thành 'người có quà' á nha!"},
                {TieuDe: "Ha...Ha...Ha...", NoiDung: "Valentine này quà còn chưa có, nói chi đến người yêu…Nhưng biết đâu lần sau sẽ khác, bất ngờ luôn đến lúc không ngờ nhất!"},
                {TieuDe: "Ha...Ha...Ha...", NoiDung: "Quay số cũng như tình yêu, có khi phải thử vài lần mới gặp đúng định mệnh của mình!"},
                {TieuDe: "Ha...Ha...Ha...", NoiDung: "Lần này chưa trúng quà nhưng biết đâu được lại 'trúng tiếng iu' của ai đó!"},
                {TieuDe: "Ha...Ha...Ha...", NoiDung: "Cảm giác không trúng quà như là đi biển mà không có sóng, chỉ có gió...P/s: 'Trúng gió!'"},
            ],
            giftTitle: {
                VLT2025_ZEN5129: "5129 điểm ZEN",
                VLT2025_ZEN6789: "6789 điểm ZEN",
                VLT2025_ZEN7890: "7890 điểm ZEN",
                VLT2025_ZEN8752: "8752 điểm ZEN",
                VLT2025_ZEN9213: "9213 điểm ZEN",
                VLT2025_BBTHREE: "BABYTHREE",
            },
            giftMessage: {
                VLT2025_ZEN5129: "'5' phần ngọt ngào, '1' ánh mắt, '2' trái tim, '9' khoảnh khắc đáng nhớ!",
                VLT2025_ZEN6789: "'6' phần vui tươi, '7' phần rộn ràng, '8' phần ngọt lịm, '9' phần năng lượng!",
                VLT2025_ZEN7890: "'7' phần rạng rỡ, '8' phần bình yên, '9' phần ấm áp, '0' chút muộn phiền!",
                VLT2025_ZEN8752: "'8' phần vui vẻ, '7' phần ấm áp, '5' phần rộn ràng, '2' tay không thể thiếu ZEN!",
                VLT2025_ZEN9213: "'9' phần tấu hài, '2' phần ngọt ngào, '1' trái tim vui, '3' ly ZEN uống mãi không chán!",
                VLT2025_BBTHREE: "Valentine đừng lo chưa có người thương vì đã có 'Pé Ba' từ ZEN yêu thương rồi nè!",
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
            const pinCode = $this.pin
            ajaxCALL(
                "/eorder/auth/QuaTang_Check_QrCode_XacNhan_V2",
                {
                    QRCode: vueData.QRCode,
                    KhachHangID: vueData.KhachHangID,
                    MaPin: pinCode,
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