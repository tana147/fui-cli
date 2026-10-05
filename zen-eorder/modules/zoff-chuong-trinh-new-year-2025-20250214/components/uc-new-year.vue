<template>
    <div class="full-screen" style="background-color: #fff8ea">
        <!--  GIỚI THIỆU CHƯƠNG TRÌNH -->
        <!-- <div class="full-screen flex-center">
            <div class="bg-home" style="flex: 1">
                <div class="bg-line"></div>
            </div>
            <div class="bg-paper" style="flex: 1">
                <span class="text-banner">GỌI LỘC KHAI XUÂN</span><br />
                <div class="img-line"></div>
                <br />
                <span class="text-title">Cách Thức Rước Lộc Xuân</span><br />
                1/ Hoá đơn có từ<br />
                2 thức uống + 2 topping + 1 bánh,<br />
                thì tất cả các ly nước có trên hoá đơn đều được tham gia Rước Lộc Xuân;<br />
                2/ Nhập mã may mắn để bắt đầu Rước Lộc<br />
                3/ Phần thưởng:<br />
                *Cập nhật sau... <br /><br />
                <b>Chúc bạn đầu năm có lộc, cả năm sẽ ngập tràn may mắn!</b><br />
            </div>
        </div> -->

        <!-- TH 1.1, 1.2: Không đủ điều kiện -->
        <div v-if="isShowReject" class="full-screen flex-center">
            <div class="bg-miss" style="flex: 1">
                <div class="bg-line"></div>
            </div>
            <div class="bg-paper" style="flex: 1">
                <span class="text-banner">GỌI LỘC KHAI XUÂN</span><br />
                <div class="img-line"></div>
                <br />
                <span class="text-title">Đơn hàng chưa đủ điều kiện</span><br />
                Rất tiếc đơn hàng của bạn chưa đủ điều kiện. Vui lòng tìm hiểu thêm về cách thức Rước Lộc ở thông tin bên dưới nhé! <br />
                <div class="img-line mt-5"></div>
                <br />
                <span class="text-title">Cách Thức Rước Lộc Xuân</span><br />
                1/ Hoá đơn có từ<br />
                2 thức uống + 2 topping + 1 bánh,<br />
                thì tất cả các ly nước có trên hoá đơn đều được tham gia Rước Lộc Xuân;<br />
                2/ Nhập mã may mắn để bắt đầu Rước Lộc<br />
                3/ Phần thưởng:<br />
                Điểm ZEN <br />
                Baby Three <br />
                Bánh Dứa Tài Lộc <br />
                Miếng Vàng 9999 <br />
                Set Tết - Phát Tài Phát Lộc "8386" <br /><br />
                <b>Chúc bạn đầu năm có lộc, cả năm sẽ ngập tràn may mắn!</b><br />
            </div>
        </div>

        <!-- TH 1.2: Đủ điều kiện và chưa quét lần nào (Nhập 4 số cuối) -->
        <div v-if="isShowInputPin" class="full-screen flex-center" :style="styleKeyboarOpen">
            <div class="bg-input" style="flex: 1">
                <div class="bg-line"></div>
            </div>
            <div class="bg-paper pa-3" style="flex: 1">
                <div class="bg-title mt-3" style="line-height: 1.2">
                    Nhập mã <{{ vueData.CTQuaTang[0].MaPin }}> <br />
                    để Rước Lộc Xuân nào!
                </div>
                <div class="div-input d-flex flex-row justify-center">
                    <div class="card-input">
                        <v-text-field placeholder="Nhập mã" type="number" maxlength="4" @focus="onOpenInput(true)" @blur="onOpenInput(false)" v-model="pinInput" class="pin-input" flat solo hide-details />
                    </div>
                </div>
                <b>Lưu ý: Tất cả các ly đều có thể Rước Lộc Xuân ({{ vueData.CTQuaTang[0].SoThuTuTem }})</b>
                <div @click="onSendPin" class="btn-style my-3">RƯỚC LỘC</div>
                <span style="font-style: italic;">Cùng ZEN tham gia trò chơi dân gian Bầu Cua Tôm Cá với sự <b>mong cầu tài lộc, may mắn</b> trong năm mới. Ngoài mang tính giải trí, ZEN hy vọng đây còn là cơ hội để gia đình và bạn bè tụ họp cùng chia sẻ niềm vui trong không khí đoàn viên.</span>
            </div>
        </div>

        <!-- TH 1.2.1: Chọn vật phẩm -->
        <template v-if="isShowChoose">
            <div class="full-screen bg-pick flex-center justify-end align-end">
                <div class="bg-game">
                    <div class="d-flex">
                        <div @click="coinPick('nai')" class="mask-pick pick-1"><img v-if="coinSelected === 'nai'" class="img-coin pos-1" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
                        <div @click="coinPick('bau')" class="mask-pick pick-2"><img v-if="coinSelected === 'bau'" class="img-coin pos-2" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
                        <div @click="coinPick('ga')" class="mask-pick pick-3"><img v-if="coinSelected === 'ga'" class="img-coin pos-3" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
                    </div>
                    <div class="d-flex">
                        <div @click="coinPick('ca')" class="mask-pick pick-4"><img v-if="coinSelected === 'ca'" class="img-coin pos-4" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
                        <div @click="coinPick('cua')" class="mask-pick pick-5"><img v-if="coinSelected === 'cua'" class="img-coin pos-5" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
                        <div @click="coinPick('tom')" class="mask-pick pick-6"><img v-if="coinSelected === 'tom'" class="img-coin pos-6" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
                    </div>
                </div>
                <div v-if="coinSelected === ''" class="bg-desc ma-2">Chọn 1 vật phẩm yêu thích, để xem mình có thắng đậm chuyến này hong nho!!!</div>
                <div v-if="coinSelected !== ''" class="w-100">
                    <div @click="onStart" class="btn-style my-2">LẮC XÍ NGẦU</div>
                </div>
            </div>
        </template>

        <!-- TH 1.2.2: Chờ lắc xí ngầu -->
        <template v-if="isShowWaiting">
            <div class="full-screen bg-result justify-space-between flex-center">
                <div class="w-100">
                    <div class="btn-style my-3">LẮC XÍ NGẦU</div>
                </div>
                <img class="img-game" src="/_cdn/zen-eorder/tet-2025/img-game-2.png" />
                <div class="w-100 text-center">
                    <img @click="onShake" class="icon-phone" src="/_cdn/zen-eorder/tet-2025/icon-phone.png" />
                    <span class="text-help">Lắc điện thoại thật mạnh để đảo Xí Ngầu nào!!!</span>
                </div>
            </div>
        </template>

        <!-- TH 1.2.3: Clip lắc xí ngầu -->
        <template v-if="isShowVideo">
            <video class="video-effect" muted autoplay :key="replayVideo" playsinline>
                <source src="/_cdn/zen-eorder/tet-2025/video-game-2.mp4" type="video/mp4" />
            </video>
        </template>

        <!-- TH 1.2.4: Màn hình kết quả -->
        <template v-if="isShowResult">
            <div class="full-screen bg-result-2 flex-center" style="gap: 20px">
                <div class="w-100">
                    <div class="btn-style my-3">KẾT QUẢ</div>
                </div>
                <div class="div-pick">
                    <img class="img-pick" :src="'/_cdn/zen-eorder/tet-2025/pick/pick-' + coinSelected + '.png'" />
                    <span class="text-choose">Đã chọn</span>
                </div>
                <div class="div-result">
                    <img class="img-result" :src="resultCase_Url" />
                    <img class="img-plate" src="/_cdn/zen-eorder/tet-2025/bg-plate-2.png?v=20250109161400" />
                </div>
                <!-- Không trúng -->
                <div v-if="vueData.CTQuaTang[0].QrCode_Case === '1_2_1'" class="div-mail">{{ messageResult[indexMessageMiss].NoiDung }}</div>
                <!-- Trúng -->
                <div v-if="vueData.CTQuaTang[0].QrCode_Case === '1_2_2'" class="div-gift">
                    <div @click="item.IsTuiMu = 0" v-for="item in vueData.CTQuaTang" class="item-gift d-flex flex-row mt-2">
                        <img v-if="item.IsTuiMu === 0" class="img-voucher" :src="item.AnhQuaTang" />
                        <img v-else class="img-blind" src="/_cdn/zen-eorder/tet-2025/blind-gift.png" />
                        <div v-if="item.IsTuiMu === 0" class="text-voucher">
                            <p class="mb-1">{{ giftTitle[item.MaVoucher] }}</p>
                            <p class="mb-0">
                                Lộc Xuân bạn đã nhận được là
                                <br />
                                {{ giftMessage[item.MaVoucher] }}
                            </p>
                        </div>
                        <div v-else class="text-voucher">
                            <p class="mb-1">Túi mù</p>
                            <p class="mb-0">Bấm vào để "Xé túi mù"</p>
                        </div>
                    </div>
                </div>
            </div>
        </template>

        <!-- TH 2.2, 2.3, 2.4: Cảnh báo đã quét QR -->
        <div v-if="isShowWarning_Scan" class="full-screen flex-center">
            <div class="bg-miss" style="flex: 1">
                <div class="bg-line"></div>
            </div>
            <div style="flex: 1; width: 100%; background-color: #fff8ea">
                <div class="text-center pa-2">
                    <span class="text-banner">GỌI LỘC KHAI XUÂN</span><br />
                    <div class="img-line"></div>
                </div>
                <div class="bg-warning fw-100">CẢNH BÁO</div>
                <div class="div-gift">
                    <div class="item-warning">
                        <!-- TH 2.3: Đã quét rồi & có trúng thưởng nhưng chưa đổi quà -->
                        <div v-if="isShowWarning_GiftMessage" class="fw-100 fs-18">
                            Mã QR có trúng thưởng <br />
                            đã được quét
                        </div>
                        <!-- TH 2.2: Đã quét rồi & Không trúng thưởng -->
                        <div v-else-if="isShowWarnig_Miss" class="fw-100 fs-18">
                            Mã QR không trúng thưởng <br />
                            đã được quét
                        </div>
                        <!-- Thời gian quét -->
                        {{ vueData.CTQuaTang[0]?.GioQuet }} {{ vueData.CTQuaTang[0]?.NgayQuet }}
                    </div>
                </div>
                <!-- TH 2.4: Đã quét rồi & có trúng thưởng và đã đổi quà -->
                <div v-if="isShowWarning_GiftMessage" class="div-gift">
                    <div class="item-warning">
                        <div class="fw-100 fs-18">Mã QR đã được cập nhật tích điểm</div>
                        <!-- Thời gian đổi -->
                        {{ vueData.CTQuaTang[0]?.DoiThuong_Gio }} {{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }}
                    </div>
                </div>
                <span class="text-help-warning">Chúc bạn đầu năm có lộc, cả năm sẽ ngập tràn may mắn!</span>
            </div>
        </div>

        <!-- Audio background -->
        <audio id="audio-bg" style="display: hidden">
            <source src="/_cdn/zen-eorder/tet-2025/music-bg.MP3" type="audio/mpeg" />
        </audio>

        <!-- Audio effect -->
        <audio id="audio-ef" style="display: hidden">
            <source src="/_cdn/zen-eorder/tet-2025/music-lac.MP3" type="audio/mpeg" />
        </audio>
    </div>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            pinInput: "",
            isOpenInput: false,
            coinSelected: "", //Ô đã chọn: nai, bau, ga, ca, cua, tom
            replayVideo: 0,
            isShowChoose: false, //Màn hình chọn xí ngầu
            isShowWaiting: false, //Màn hình chờ lắc
            isShowVideo: false, //Video lắc xí ngầu
            isShowResult: false, //Màn hình kết quả
            indexMessageMiss: 0, //Thông báo không trúng
            resultCase_Url: "", //Ảnh kết quả xí ngầu
            isShaked: false,
            giftTitle: {
                TET2025_ZEN6868: "Phát Tài Phát Lộc",
                TET2025_ZEN7979: "Tài Lộc Dồi Dào",
                TET2025_ZEN8686: "Phúc Lộc Vẹn Toàn",
                TET2025_ZEN9999: "Tứ Mùa An Khang",
                TET2025_BANHDUA: "Xuân về phú quý, Lộc phát cả năm",
                TET2025_SET: "Tân xuân vạn phúc, xuân ấm tình thân",
                TET2025_BBTHREE_1: "Xuân hỷ khởi đầu, nhà nhà hạnh phúc",
                TET2025_BBTHREE_2: "Xuân hỷ khởi đầu, nhà nhà hạnh phúc",
                TET2025_VANG9999: "Lộc xuân rực rỡ, phú quý ngập tràn",
            },
            giftMessage: {
                TET2025_ZEN6868: "6868 ĐIỂM ZEN",
                TET2025_ZEN7979: "7979 ĐIỂM ZEN",
                TET2025_ZEN8686: "8686 ĐIỂM ZEN",
                TET2025_ZEN9999: "9999 ĐIỂM ZEN",
                TET2025_BANHDUA: "Bánh Dứa Tài Lộc",
                TET2025_SET: "Set Tết Phát Tài Phát Lộc '8386'",
                TET2025_BBTHREE_1: "Baby Three",
                TET2025_BBTHREE_2: "Baby Three",
                TET2025_VANG9999: "Miếng Vàng PNJ 9999",
            },
            messageResult: [
                {TieuDe: "", NoiDung: "Trượt nữa rồi, nhưng Tết là dịp để chill! Chúc bạn năm mới chơi gì cũng thắng, bắt trend nào cũng đỉnh! 💖💖💖"},
                {TieuDe: "", NoiDung: "Lần này chưa có lộc nhưng cứ 'chơi tới nóc', Tài Lộc sẽ tự động về. Chúc bạn năm mới gặp thật nhiều điều tốt đẹp 🎇🎇🎇"},
                {TieuDe: "", NoiDung: "Tuy chưa có phần thưởng, nhưng phần quà lớn nhất vẫn là sức khỏe và hạnh phúc. Chúc bạn một năm mới may mắn ngập tràn, gia đình hạnh phúc! 🎊🎊🎊"},
                {TieuDe: "", NoiDung: "Dù chưa may mắn, nhưng ZEN tin may mắn sẽ đến sớm với bạn. Chúc bạn năm mới An Khang Thịnh Vượng, 💝💝💝"},
                {TieuDe: "", NoiDung: "Hơi tiếc, vận may lạc đường chút xíu. Chúc bạn năm mới rộn ràng, sung túc phú quý!🎆🎆🎆"},
                {TieuDe: "", NoiDung: "Chưa có lộc, nhưng Tết này cứ 'chơi tới nóc', tài lộc sẽ tự động về! Chúc bạn năm mới 'trendy', tiền tài thăng hạng!"},
            ],
        }
    },
    mounted() {},
    computed: {
        isShowReject() {
            //TH 1.1 & 2.1: Không đủ điều kiện
            return vueData.CTQuaTang[0]?.QrCode_Case === "1_1_2_1"
        },
        isShowInputPin() {
            //TH 1.2: Đủ điều kiện và chưa xác nhận lần nào (Nhập 4 số cuối)
            const $this = this
            return !$this.isShowChoose && !$this.isShowWaiting && !$this.isShowVideo && !$this.isShowResult && vueData.CTQuaTang[0]?.QrCode_Case === "1_2"
        },
        isShowWarning_Scan() {
            //TH 2.2: Đã quét rồi & Không trúng thưởng
            //TH 2.3: Đã quét rồi & có trúng thưởng nhưng chưa đổi quà
            //TH 2.4: Đã quét rồi & có trúng thưởng và đã đổi quà
            return vueData.CTQuaTang[0]?.QrCode_Case === "2_2" || vueData.CTQuaTang[0]?.QrCode_Case === "2_3" || vueData.CTQuaTang[0]?.QrCode_Case === "2_4"
        },
        isShowWarnig_Miss() {
            //TH 2.2: Đã quét rồi & Không trúng thưởng
            return vueData.CTQuaTang[0]?.QrCode_Case === "2_2"
        },
        isShowWarning_Gift() {
            //TH 2.3: Đã quét rồi & có trúng thưởng nhưng chưa đổi quà
            return vueData.CTQuaTang[0]?.QrCode_Case === "2_3"
        },
        isShowWarning_GiftMessage() {
            //TH 2.4: Đã quét rồi & có trúng thưởng và đã đổi quà
            return vueData.CTQuaTang[0]?.QrCode_Case === "2_4"
        },
        styleKeyboarOpen() {
            const $this = this
            if ($this.isOpenInput && vueData.OS_Device === "android") {
                return "bottom: 45%; position: absolute;"
            } else {
                return ""
            }
        },
    },
    watch: {},
    methods: {
        onOpenInput(status) {
            const $this = this
            $this.isOpenInput = status
        },
        onSendPin() {
            const $this = this
            const pinCode = $this.pinInput
            if (vueData.CTQuaTang[0].MaPin === pinCode) {
                $this.isShowChoose = true
            } else {
                showMessage({type: "red", title: "Thông báo", message: "Mã hóa đơn không đúng, vui lòng kiểm tra lại"})
            }
        },
        coinPick(pick) {
            const $this = this
            $this.coinSelected = pick
        },
        onStart() {
            const $this = this
            //Kiểm tra xí ngầu đã được chọn
            if ($this.coinSelected !== "") {
                $this.replayVideo++
                $this.isShowChoose = false //Ẩn màn hình chọn xí ngầu
                $this.isShowWaiting = true //Hiển thị màn hình chờ lắc
                $this.onVibrate() //Lắng nghe sự kiện lắc điện thoại
            }
        },
        onShake() {
            const $this = this
            if ($this.isShaked === false) {
                $this.isShaked = true
                //Gọi API lấy kết quả
                const pinCode = $this.pinInput
                ajaxCALL(
                    "/eorder/auth/QuaTang_Check_QrCode_XacNhan_V2",
                    {
                        QRCode: vueData.QRCode,
                        KhachHangID: vueData.KhachHangID,
                        MaPin: pinCode,
                    },
                    (res) => {
                        $this.isShowWaiting = false //Ẩn màn hình chờ lắc
                        $this.isShowVideo = true //Chạy video hiệu ứng lắc (3s)

                        //Stop audio bg
                        const audioBg = document.getElementById("audio-bg")
                        audioBg.loop = false
                        audioBg.pause()

                        //Play audio effect
                        const audio = document.getElementById("audio-ef")
                        audio.loop = true
                        audio.play()

                        //Set lại data quà tặng
                        vueData.CTQuaTang = res.data
                        const data = res.data[0]

                        //Không Trúng -> Lấy thứ tự thông báo không trúng, Xử lý xí ngầu
                        if (data.QrCode_Case === "1_2_1") {
                            $this.indexMessageMiss = vueData.CTQuaTang[0].ThongBaoKhongTrung
                            $this.resultCase_Url = `/_cdn/zen-eorder/tet-2025/miss/miss-${$this.coinSelected}-${data.QuaySo}.png?v=20250109161400`
                        }
                        //Trúng -> Xử lý kết quả xí ngầu
                        else if (data.QrCode_Case === "1_2_2") {
                            const sumVoucher = vueData.CTQuaTang.length //Số lượng voucher trúng
                            //Nếu trúng 3 voucher
                            if (sumVoucher === 3) {
                                $this.resultCase_Url = `/_cdn/zen-eorder/tet-2025/gift-${sumVoucher}/gift-${$this.coinSelected}.png?v=20250109161400`
                            } else {
                                //Trúng 1 hoặc 2 voucher
                                $this.resultCase_Url = `/_cdn/zen-eorder/tet-2025/gift-${sumVoucher}/gift-${$this.coinSelected}-${data.QuaySo}.png?v=20250109161400`
                            }
                        }

                        //Tắt video hiệu ứng sau 3s
                        setTimeout(() => {
                            $this.isShowWaiting = false //Tắt video hiệu ứng
                            $this.isShowVideo = false
                            $this.isShowResult = true //Hiển thị màn hình kết quả

                            //Stop audio effect
                            const audio = document.getElementById("audio-ef")
                            audio.loop = false
                            audio.pause()
                            //Play audio bg
                            const audioBg = document.getElementById("audio-bg")
                            audioBg.loop = true
                            audioBg.play()
                        }, 4000)
                    },
                )
            }
        },
        execute: function (cmd, value = "") {
            const native = window.ReactNativeWebView
            if (!native) return
            native.postMessage(
                JSON.stringify({
                    cmd: cmd,
                    value: value,
                }),
            )
        },
        onVibrate: function () {
            const $this = this
            const queryString = window.location.search
            const urlvalues = new URLSearchParams(queryString)
            const os = urlvalues.get("os")
            let container = document
            if (os === "ios") {
                container = window
            }
            container.addEventListener("message", (nativeEvent) => {
                if (!nativeEvent) return
                const data = nativeEvent.data
                const json = JSON.parse(data)
                const {cmd, value} = json
                if (cmd === "ON-SHAKE") {
                    $this.execute("VIBRATE", 3000)
                    $this.onShake()
                }
            })
        },
    },
}
</script>
