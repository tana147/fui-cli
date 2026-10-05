<template>
	<div class="d-flex flex-column justify-center h-100dvh">
        <template v-if="!isShowResult">
            <!-- Hiển thị vòng quay -->
            <div :class="isShowWheel ? 'mt-80px' : 'd-none'">
                <div class="lucky-wheel"></div>
            </div>
            <div style="height: 56px">
                <div v-if="!isWheel" @click="onWheel" class="button-start">Bắt đầu</div>
            </div>
        </template>
        <!-- TH 1.2.4: Màn hình kết quả -->
        <template v-if="isShowResult">
            <!-- Không trúng -->
            <template v-if="dataQr.QrCode_Case === '1_2_1'">
                <div class="card-white mt-10">
                    {{ messageResult[dataQr.ThongBaoKhongTrung].TieuDe }}
                </div>
                <div class="card-white mt-3">
                    {{ messageResult[dataQr.ThongBaoKhongTrung].NoiDung }}
                </div>
            </template>
            <!-- Trúng -->
            <template v-if="dataQr.QrCode_Case === '1_2_2'">
                <div class="card-white mt-10">
                    Ơ động đất à? Không phải, đó là quà ZEN gửi tới!
                </div>
                <div class="card-white mt-3 d-flex flex-row align-center">
                    <img class="img-voucher" :src="dataQr.AnhQuaTang">
                    <div>
                        <p class="mb-2">
                            Món quà của bạn là <br>
                            {{ giftTitle[dataQr.MaVoucher] }}
                        </p>
                        <p class="mb-0">
                            {{ giftMessage[dataQr.MaVoucher] }}
                        </p>
                    </div>
                </div>
            </template>
        </template>
    </div>
</template>

<script>
	export default {
		props: ["pin"],
    data() {
        const itemScale = 0.773
        const itemRadius = 0.69
        return {
            isWheel: false,
            isShowWheel: false,
            isShowResult: false,
            dataQr: null,
            wheel: null,
            optionWheel: {
                name: "Workout",
                itemBackgroundColors: ["transparent"],
                borderWidth: 0,
                lineWidth: 0,
                radius: 0.92,
                isInteractive: false,
                overlayImage: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/arrow-wheel.png",
                items: [
                    {
                        //0: Babythree
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //1: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //2: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //3: Điểm ZEN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //4: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //5: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //6: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //7: Điểm ZEN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //8: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //9: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/08032025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                ],
            },
            messageResult: [
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Sự thật mất lòng: Quà có hạn, mà nhan sắc bạn thì vô hạn... Nên có lẽ vũ trụ ưu tiên cho người cần hơn!"},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Quà thì chưa thấy, nhưng thấy rõ một điều: May mắn đang tạm mất sóng, chờ chút sẽ quay lại nha!"},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Quay số cũng giống như chọn playlist hay ho, thử vài bài mới tìm được bài 'chân ái' đó!"},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Người khác có quà, bạn có gì? Có thần thái vững vàng và sắc đẹp không thể lay chuyển, thế là đủ 'ăn điểm' rồi còn gì!"},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Không trúng quà cũng giống như selfie cả buổi mà quên post, tiếc đó… nhưng mà bạn vẫn xịn lắm nha!"},
            ],
            giftTitle: {
                CT08032025_ZEN5678: "5678 điểm ZEN",
                CT08032025_ZEN6286: "6286 điểm ZEN",
                CT08032025_ZEN7288: "7288 điểm ZEN",
                CT08032025_ZEN8300: "8300 điểm ZEN",
                CT08032025_ZEN9696: "9696 điểm ZEN",
                CT08032025_TUITOTE: "Túi Tote ZEN",
            },
            giftMessage: {
                CT08032025_ZEN5678: "Cứ vững vàng mỗi ngày nha, hành trình này là của bạn mà!",
                CT08032025_ZEN6286: "Giữ nhịp cân bằng, rồi tận hưởng những điều hay ho đang tới nhé!",
                CT08032025_ZEN7288: "May mắn ở ngay đây thôi, sẵn sàng là có liền nha!",
                CT08032025_ZEN8300: "Thoải mái bứt phá, cứ toả sáng theo cách riêng của bạn đi!",
                CT08032025_ZEN9696: "Năng lượng tốt, ngày nào cũng tốt!",
                CT08032025_TUITOTE: "Mang theo tinh thần tích cực, sẵn sàng cho mọi hành trình phía trước!",
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
                "/eordertest/auth/QuaTang_Check_QrCode_XacNhan_V2",
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