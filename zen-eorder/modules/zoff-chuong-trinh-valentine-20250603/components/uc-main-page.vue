<template>
    <div class="full-screen" style="background-color: #fff8ea">
        <!-- TH 1.1, 1.2: Không đủ điều kiện -->
        <div v-if="isShowReject" class="full-screen flex-center">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x1.png" class="img-heart-1" />
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x2.png" class="img-heart-2" />
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x3.png" class="img-heart-3-center" />
            <div class="bg-paper" style="flex: 1">
                <p class="fs-18 mb-1 mt-4">HAPPY<br /></p>
                <p class="text-banner mb-1">VALENTINE'S DAY</p>
                <br />
                <p class="text-subbanner mb-1">
                    "DÙ CHO TẬN THẾ VẪN YÊU NHAU, <br />
                    LUÔN BÊN NHAU.." <br />
                </p>
                <p class="text-subbanner mb-3 mt-3">------------------------------</p>
                <p class="text-content mb-2">
                    Đơn hàng của bạn <br />
                    chưa đủ điều kiện mất rồi.
                </p>
                <p class="text-content">
                    Cùng nhau tìm hiểu về "bí quyết" <br />
                    Mở Khóa Yêu Thương <br />
                    ở thông tin bên dưới nha!
                </p>
                <div class="card-white mt-30px">
                    <span class="fs-18">Nội dung chương trình</span><br />
                    <p class="text-subbanner mb-1 mt-1">------------------------------</p>
                    1/ Hoá đơn có từ<br />
                    2 thức uống + 2 topping + 1 bánh,<br />
                    thì tất cả các ly nước có trên hoá đơn đều được tham gia chương trình;<br />
                    2/ Nhập mã đơn hàng để bắt đầu mở khóa<br />
                    3/ Phần thưởng:<br />
                    Điểm ZEN <br />
                    Baby Three <br />
                    <p class="text-subbanner mb-1 mt-1">------------------------------</p>
                    <b>Chúc bạn một Valentine ngọt ngào!</b>
                </div>
            </div>
        </div>

        <!-- TH 1.2: Đủ điều kiện và chưa quét lần nào (Nhập 4 số cuối) -->
        <div v-if="isShowInputPin" class="full-screen flex-center">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x1.png" class="img-heart-1" />
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x2.png" class="img-heart-2" />
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x3.png" class="img-heart-3" />
            <div class="bg-paper" style="flex: 1">
                <p class="fs-18 mb-1 mt-4">HAPPY<br /></p>
                <p class="text-banner mb-1">VALENTINE'S DAY</p>
                <br />
                <p class="text-subbanner mb-1">
                    "DÙ CHO TẬN THẾ VẪN YÊU NHAU, <br />
                    LUÔN BÊN NHAU.." <br />
                </p>
                <div class="card-white mt-5">
                    Lẹttt gôô! Để xem Valentine này bạn Va-lung-tung vào những phần quà hay sẽ có thêm một câu chuyện để kể với bạn bè nha!
                    <div class="arrow"></div>
                </div>
                <div class="card-white mt-30px">
                    Nhập mã <span class="text-pin"><{{ vueData.CTQuaTang[0].MaPin }}></span><br />
                    để xem mình va-lung-tung vào đâu nào!
                    <div class="arrow"></div>
                </div>
                <div class="card-white mt-30px">
                    <div class="card-input d-flex flex-row justify-center">
                        <v-text-field type="number" maxlength="4" v-model="pinInput" class="pin-input" flat solo hide-details />
                    </div>
                    <div class="arrow-right"></div>
                </div>
                <div @click="onSendPin" class="btn-style mt-10 mb-3">Quay số</div>
                <small>Lưu ý: Tất cả các ly đều có thể tham gia ({{ vueData.CTQuaTang[0].SoThuTuTem }})</small>
            </div>
            <div class="d-flex justify-center align-center pa-3">
                <div class="text-desc" style="padding-left: 100px">
                    Valentine's Day không chỉ dành cho <br />
                    tình nhân - khi yêu thương không <br />
                    chỉ là lời nói, mà là những hành <br />
                    động chân thành chạm đến trái tim <br />
                    những người ta trân quý!
                </div>
            </div>
        </div>

        <!-- TH 1.2.1:  Hiển thị vòng quay -->
        <div v-if="isShowChoose">
            <div class="flex-center justify-end align-end">
                <uc-lucky-wheel :pin="pinInput" />
            </div>
        </div>

        <!-- TH 2.2, 2.3, 2.4: Cảnh báo đã quét QR -->
        <div v-if="isShowWarning_Scan" class="full-screen flex-center">
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x1.png" class="img-heart-1" />
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x2.png" class="img-heart-2" />
            <img src="/_cdn/zen-eorder/valentine-2025/heart-x3.png" class="img-heart-3-center" />
            <div class="bg-paper" style="flex: 1">
                <p class="fs-18 mb-1 mt-4">HAPPY<br /></p>
                <p class="text-banner mb-1">VALENTINE'S DAY</p>
                <br />
                <p class="text-subbanner mb-1">
                    "DÙ CHO TẬN THẾ VẪN YÊU NHAU, <br />
                    LUÔN BÊN NHAU.." <br />
                </p>
                <div class="card-white mt-10 fs-30">
                    CẢNH BÁO
                    <div class="arrow"></div>
                </div>
                <div class="card-white mt-30px">
                    <!-- TH 2.3: Đã quét rồi & có trúng thưởng nhưng chưa đổi quà -->
                    <template v-if="isShowWarning_Gift || isShowWarning_GiftMessage">
                        <div class="d-flex flex-row justify-center">
                            <img class="img-voucher" :src="vueData.CTQuaTang[0]?.AnhQuaTang" />
                            <div>
                                Mã QR có trúng thưởng <br />
                                đã được quét <br />
                                <!-- Thời gian quét -->
                                <b>{{ vueData.CTQuaTang[0]?.GioQuet }} {{ vueData.CTQuaTang[0]?.NgayQuet }}</b>
                            </div>
                        </div>
                    </template>
                    <!-- TH 2.2: Đã quét rồi & Không trúng thưởng -->
                    <div v-else-if="isShowWarnig_Miss">
                        Mã QR không trúng thưởng <br />
                        đã được quét <br />
                        <!-- Thời gian quét -->
                        <b>{{ vueData.CTQuaTang[0]?.GioQuet }} {{ vueData.CTQuaTang[0]?.NgayQuet }}</b>
                    </div>
                    <div class="arrow"></div>
                </div>
                <!-- TH 2.4: Đã quét rồi & có trúng thưởng và đã đổi quà -->
                <div v-if="isShowWarning_GiftMessage" class="card-white mt-30px">
                    <span v-if="vueData.CTQuaTang[0]?.QrCode_TrungThuong !== 'VLT2025_BBTHREE'">Mã QR đã được cập nhật tích điểm</span>
                    <span v-if="vueData.CTQuaTang[0]?.QrCode_TrungThuong === 'VLT2025_BBTHREE'">Mã QR đã được đổi</span>
                    <br />
                    <!-- Thời gian đổi -->
                    <b>{{ vueData.CTQuaTang[0]?.DoiThuong_Gio }} {{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }}</b>
                    <div class="arrow"></div>
                </div>
            </div>
            <p>Chúc bạn một Valentine ngọt ngào</p>
        </div>

        <!-- Audio background -->
        <audio id="audio-bg" style="display: hidden">
            <source src="/_cdn/zen-eorder/valentine-2025/music-bg.MP3" type="audio/mpeg" />
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
            isShowChoose: false, //Màn hình chọn xí ngầu
            isShowResult: false, //Màn hình kết quả
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
    },
    watch: {},
    methods: {
        onSendPin() {
            const $this = this
            const pinCode = $this.pinInput
            if (vueData.CTQuaTang[0].MaPin === pinCode) {
                $this.isShowChoose = true
            } else {
                showMessage({type: "red", title: "Thông báo", message: "Mã hóa đơn không đúng, vui lòng kiểm tra lại"})
            }
        },
    },
}
</script>
