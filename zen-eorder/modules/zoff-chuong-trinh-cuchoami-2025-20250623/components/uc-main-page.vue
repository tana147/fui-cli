<template>
    <div class="full-screen">
        <!-- TH 1.1, 1.2: Không đủ điều kiện -->
        <div v-if="isShowReject" class="h-100dvh d-flex flex-column align-center justify-center">
            <div class="card-white-trans text-title-name">
                VÒNG QUAY <br />
                CÚC HỌA MI
            </div>
            <div class="card-white-trans">
                <div class="card-warning">
                    Đơn hàng của bạn <br />
                    chưa đủ điều kiện mất rồi
                </div>
                <br />
                Cùng nhau tìm hiểu về thể lệ chương trình <br />
                ở thông tin bên dưới nha!
            </div>
            <div class="card-white-trans">
                <span class="text-title">Nội dung chương trình</span><br />
                ------------------------------<br />
                1/ Hoá đơn có từ<br />
                2 thức uống + 2 topping + 1 bánh,<br />
                thì tất cả các ly nước có trên hoá đơn đều được tham gia chương trình;<br /><br />
                2/ Nhập mã đơn hàng để bắt đầu quay thưởng<br /><br />
                3/ Phần thưởng<br />
                Bánh Flan <br />
                Trân Châu Tươi<br />
                Trà Sữa ZEN Size L<br />
                Bánh Rán Doraemon<br />
                Bông Kem Truyền Thống<br />
                Sương Sáo Thảo Mộc Lạng Sơn<br />
            </div>
        </div>

        <!-- TH 1.2: Đủ điều kiện và chưa quét lần nào (Nhập 4 số cuối) -->
        <div v-if="isShowInputPin" class="h-100dvh d-flex flex-column align-center justify-center">
            <div class="card-white-trans text-title-name">
                VÒNG QUAY <br />
                CÚC HỌA MI
            </div>
            <div class="card-white-trans">
                <span class="text-title">Ting ting!</span> <br />
                Hình như có bất ngờ đang chờ bạn khám phá... <br />
                đã sẵn sàng chưa nè? <br />
            </div>
            <div class="card-white-trans mt-3">
                <span class="text-pin">
                    Nhập mã <br />
                    <{{ vueData.CTQuaTang[0].MaPin }}> để bắt đầu! <br
                /></span>
                <div class="card-input">
                    <v-text-field type="number" maxlength="4" v-model="pinInput" class="pin-input" flat solo hide-details />
                </div>
            </div>
            <div @click="onSendPin" class="button-start">Quay số</div>
            <p class="text-note">
                Lưu ý: Tất cả các ly đều có thể tham gia <br />
                ({{ vueData.CTQuaTang[0].SoThuTuTem }})
            </p>
            <p class="text-note">
                Chào mừng bạn đến với khu vườn <br />
                rực rỡ sắc hoa - nơi mỗi khoảnh khắc <br />
                đều nở rộ yêu thương!
            </p>
        </div>

        <!-- TH 1.2.1:  Hiển thị vòng quay -->
        <template v-if="isShowChoose">
            <uc-lucky-wheel :pin="pinInput" />
        </template>

        <!-- TH 2.2, 2.3, 2.4: Cảnh báo đã quét QR -->
        <div v-if="isShowWarning_Scan" class="h-100dvh d-flex flex-column align-center justify-center">
            <div class="card-white-trans text-title-name">
                VÒNG QUAY <br />
                CÚC HỌA MI
            </div>
            <div class="card-white mt-80px text-title">CẢNH BÁO</div>
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
                <span>Mã QR đã được đổi</span>
                <br />
                <!-- Thời gian đổi -->
                <b>{{ vueData.CTQuaTang[0]?.DoiThuong_Gio }} {{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }}</b>
            </div>
            <p class="text-note mt-80px">
                Chào mừng bạn đến với khu vườn <br />
                rực rỡ sắc hoa - nơi mỗi khoảnh khắc <br />
                đều nở rộ yêu thương!
            </p>
        </div>
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
