<template>
    <div class="full-screen">
        <!-- TH 1.1, 1.2: Không đủ điều kiện -->
        <div v-if="isShowReject" class="h-100dvh d-flex flex-column justify-center">
            <div class="card-white-trans mt-80px">
                Đơn hàng của bạn chưa đủ điều kiện mất rồi <br /><br />
                Cùng nhau tìm hiểu về thể lệ chương trình <br />
                ở thông tin bên dưới nha!
            </div>
            <div class="card-white-trans mt-5">
                <span class="text-title">Nội dung chương trình</span><br />
                ------------------------------<br />
                1/ Hoá đơn có từ<br />
                2 thức uống + 2 topping + 1 bánh,<br />
                thì tất cả các ly nước có trên hoá đơn đều được tham gia chương trình;<br /><br />
                2/ Nhập mã đơn hàng để bắt đầu quay thưởng<br /><br />
                3/ Phần thưởng<br />
                Túi Tote<br />
                Điểm ZEN<br />
                ------------------------------<br />
                Một ngày đơn giản nhưng đầy niềm vui <br />
                đang chờ bạn phía trước!
            </div>
        </div>

        <!-- TH 1.2: Đủ điều kiện và chưa quét lần nào (Nhập 4 số cuối) -->
        <div v-if="isShowInputPin" class="h-100dvh d-flex flex-column justify-center">
            <div class="card-white-trans mt-80px">
                <span class="text-title">Ting ting!</span> <br />
                Hình như có bất ngờ đang chờ bạn khám phá... <br />
                đã sẵn sàng chưa nè? <br />
            </div>
            <div class="card-white-trans mt-3">
                Nhập mã <span class="text-pin"><{{ vueData.CTQuaTang[0].MaPin }}></span> <br />
                để bắt đầu! <br />
                <div class="card-input">
                    <v-text-field type="number" maxlength="4" v-model="pinInput" class="pin-input" flat solo hide-details />
                </div>
            </div>
            <div @click="onSendPin" class="button-start">Quay số</div>
            <p class="text-note">
                Lưu ý: Tất cả các ly đều có thể tham gia <br />
                ({{ vueData.CTQuaTang[0].SoThuTuTem }})
            </p>
        </div>

        <!-- TH 1.2.1:  Hiển thị vòng quay -->
        <template v-if="isShowChoose">
            <uc-lucky-wheel :pin="pinInput" />
        </template>

        <!-- TH 2.2, 2.3, 2.4: Cảnh báo đã quét QR -->
        <div v-if="isShowWarning_Scan" class="h-100dvh d-flex flex-column justify-center">
            <div class="card-white mt-10 text-title">CẢNH BÁO</div>
            <div class="card-white mt-3">
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
            </div>
            <!-- TH 2.4: Đã quét rồi & có trúng thưởng và đã đổi quà -->
            <div v-if="isShowWarning_GiftMessage" class="card-white mt-3">
                <span v-if="vueData.CTQuaTang[0]?.QrCode_TrungThuong !== 'CT08032025_TUITOTE'">Mã QR đã được cập nhật tích điểm</span>
                <span v-if="vueData.CTQuaTang[0]?.QrCode_TrungThuong === 'CT08032025_TUITOTE'">Mã QR đã được đổi</span>
                <br />
                <!-- Thời gian đổi -->
                <b>{{ vueData.CTQuaTang[0]?.DoiThuong_Gio }} {{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }}</b>
            </div>
        </div>

         <!-- Audio background -->
        <audio id="audio-bg" style="display: hidden">
            <source src="/_cdn/zen-eorder/08032025/music-bg.MP3" type="audio/mpeg" />
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
