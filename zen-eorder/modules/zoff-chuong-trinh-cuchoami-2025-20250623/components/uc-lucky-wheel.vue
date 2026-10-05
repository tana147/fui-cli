<template>
	<div :class="(isShowResult ? 'full-screen' : 'bg-tree') + ' d-flex flex-column justify-center h-100dvh'">
        <div class="card-white-trans text-title-name">
            VÒNG QUAY <br>
            CÚC HỌA MI
        </div>
        <template v-if="!isShowResult">
            <!-- Hiển thị vòng quay -->
            <div :class="isShowWheel ? '' : 'd-none'">
                <div class="lucky-wheel"></div>
            </div>
            <div style="height: 56px">
                <div v-if="!isWheel" @click="onWheel" class="button-whell">Quay số</div>
            </div>
        </template>
        <!-- TH 1.2.4: Màn hình kết quả -->
        <template v-if="isShowResult">
            <!-- Không trúng -->
            <div v-if="dataQr.QrCode_Case === '1_2_1'" style="margin-left: 5%;" class="mt-80px mb-80px">
                <div class="card-white mt-10">
                    {{ messageResult[dataQr.ThongBaoKhongTrung].TieuDe }}
                </div>
                <div class="card-white mt-3">
                    {{ messageResult[dataQr.ThongBaoKhongTrung].NoiDung }}
                </div>
            </div>
            <!-- Trúng -->
            <div v-if="dataQr.QrCode_Case === '1_2_2'" style="margin-left: 5%;" class="mt-80px mb-80px">
                <div class="card-white mt-10">Chúc mừng</div>
                <div class="card-white mt-3 d-flex flex-row align-center">
                    <img class="img-voucher" :src="dataQr.AnhQuaTang">
                    <div>
                        <p class="mb-2">
                            Món quà của bạn là<br>
                            01 phần {{ giftTitle[dataQr.MaVoucher] }}
                        </p>
                    </div>
                </div>
            </div>
        </template>
    </div>
</template>

<script>
	export default {
		props: ["pin"],
    data() {
        const itemScale = 0.773
        const itemRadius = 0.67
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
                overlayImage: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/arrow-wheel.png",
                items: [
                    {
                        //0: CHM2025_TSZL, CHM2025_BRAN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-0.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //1: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //2: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //3: CHM2025_TCT, CHM2025_OLNHAN
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //4: Trống
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-3.png?v=202506111620",
                        imageScale: 0.773,
                        imageRadius: 0.69,
                    },
                    {
                        //5: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //6: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //7: CHM2025_CUCPHOMAI, CHM2025_YUZU
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-1.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //8: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                    {
                        //9: Không trúng
                        image: "https://cdn.zentea.vn/filedata/zen-eorder/cuc-hoa-mi-2025/item-wheel-2.png",
                        imageScale: itemScale,
                        imageRadius: itemRadius,
                    },
                ],
            },
            messageResult: [
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Có những bông hoa nở muộn, nhưng vẫn khiến cả vườn hoa phải ngoảnh nhìn – Nên dù bây giờ chưa trúng thì cũng đâu có sao!"},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Một lần lỡ nhịp chẳng nói lên điều gì – như hoa nở muộn, biết đâu ngày mai sẽ rực rỡ toả hương?"},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Sự may mắn có thể đến muộn, nhưng nụ cười thì luôn hiện diện – như Cúc Tana, âm thầm mà bền bỉ, đợi ngày nắng lên"},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Hoa đẹp nhất khi nở đúng mùa. Và bạn cũng sẽ toả sáng vào khoảnh khắc dành riêng cho mình."},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Có loài hoa đợi đúng mùa mới khoe sắc. Có những người, đợi đúng lúc mới rực rỡ như ánh dương. Bạn là một trong số đó."},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Đừng vội lo nếu hôm nay chưa rực rỡ – đôi khi điều đẹp nhất cần thêm một chút thời gian"},
                {TieuDe: "Tèn...Ten...Ten...", NoiDung: "Không có bông hoa nào bị lãng quên – chỉ có những bông hoa đợi ngày khoe sắc"}
            ],
            giftTitle: {
                CHM2025_TSZL: "Trà Sữa ZEN size L",
                CHM2025_BRAN: "Bánh Rán Doraemon",
                CHM2025_TCT: "Trân Châu Tươi",
                CHM2025_OLNHAN: "Khúc Bạch Ô Long Nhãn",
                CHM2025_CUCPHOMAI: "Hoa Cúc Phô Mai",
                CHM2025_YUZU: "Trân Châu Giòn Quýt Yuzu",
            }
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
                        $this.wheel.remove()
                        $this.isShowWheel = false
                        $this.isShowResult = true
                    }, 9000)
                },
            )
        },
    },
	}
</script>