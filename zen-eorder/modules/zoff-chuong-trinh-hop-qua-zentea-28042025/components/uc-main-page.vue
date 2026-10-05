<template>
    <div class="coming-soon"></div>

    <!-- Đóng chương trình: 16:14 28/04/2025 -->
    <div v-if="false" class="full-screen">
        <!-- TH 1.1, 1.2: Không đủ điều kiện -->
        <div v-if="isShowReject" class="h-100dvh d-flex flex-column">
            <div class="card-white-trans">
                <div>
                    <img class="img-logo" src="/_cdn/zen-eorder/30042025/logo.png" />
                </div>
                <div class="text-title">
                    Cùng ZEN mừng 50 năm <br />
                    Ngày Giải phóng miền Nam, <br />
                    thống nhất đất nước!
                </div>
                <p class="border-bottom my-2 mx-5"></p>
                <p>
                    Trong không khí mừng đại lễ 30/4, <br />
                    bạn đã sẵn sàng đón nhận điều bất ngờ từ ZEN chưa?
                </p>
                <p class="border-bottom my-2 mx-5"></p>
                <p style="line-height: 1.3" class="mb-0">
                    Danh sách quà tặng - 50,000 phần quà <br /><br />
                    Bánh Flan <br />
                    Trân Châu Tươi<br />
                    Trà Sữa ZEN Size L<br />
                    Bánh Rán Doraemon<br />
                    Bông Kem Truyền Thống<br />
                    Sương Sáo Thảo Mộc Lạng Sơn<br />
                </p>
            </div>
            <div class="button-start">
                <span v-if="vueData.CTQuaTang[0]?.Is_ErrorQrCode">Mã QR không hợp lệ</span>
                <span v-else-if="vueData.CTQuaTang[0]?.Is_ErrorKhachHang">Mã khách hàng không hợp lệ</span>
            </div>
        </div>

        <!-- TH 1.2: Đủ điều kiện và chưa quét lần nào (Nhập 4 số cuối) -->
        <div v-if="isShowInputPin" class="h-100dvh d-flex flex-column">
            <div class="card-white-trans">
                <div>
                    <img class="img-logo" src="/_cdn/zen-eorder/30042025/logo.png" />
                </div>
                <div class="text-title">
                    Cùng ZEN mừng 50 năm <br />
                    Ngày Giải phóng miền Nam, <br />
                    thống nhất đất nước!
                </div>
                <p class="border-bottom my-2 mx-5"></p>
                <p>
                    Trong không khí mừng đại lễ 30/4, <br />
                    bạn đã sẵn sàng đón nhận điều bất ngờ từ ZEN chưa?
                </p>
                <p class="border-bottom my-2 mx-5"></p>
                <p style="line-height: 1.3" class="mb-0">
                    Danh sách quà tặng - 50,000 phần quà<br /><br />
                    Bánh Flan <br />
                    Trân Châu Tươi<br />
                    Trà Sữa ZEN Size L<br />
                    Bánh Rán Doraemon<br />
                    Bông Kem Truyền Thống<br />
                    Sương Sáo Thảo Mộc Lạng Sơn<br />
                </p>
            </div>
            <div @click="onSendPin" class="button-start">Tham Gia</div>
        </div>

        <!-- TH 1.2.1:  Hiển thị vòng quay -->
        <template v-if="isShowChoose">
            <uc-lucky-wheel />
        </template>

        <!-- TH 2.2, 2.3, 2.4: Cảnh báo đã quét QR -->
        <div v-if="isShowWarning_Scan" class="h-100dvh d-flex flex-column">
            <div>
                <img class="img-logo" src="/_cdn/zen-eorder/30042025/logo.png" />
            </div>
            <div class="card-white-trans text-title">
                Cùng ZEN mừng 50 năm <br />
                Ngày Giải phóng miền Nam, <br />
                thống nhất đất nước!
            </div>
            <div class="card-white mt-2 text-title">BẠN ĐÃ THAM GIA CHƯƠNG TRÌNH</div>
            <div class="card-white mt-3">
                <!-- TH 2.3: Đã quét rồi & có trúng thưởng nhưng chưa đổi quà -->
                <template v-if="isShowWarning_Gift || isShowWarning_GiftMessage">
                    <div class="d-flex flex-row align-center">
                        <img class="img-voucher" :src="vueData.CTQuaTang[0]?.AnhQuaTang" />
                        <div style="flex: 1">
                            Tài khoản đã quét <br />
                            có trúng thưởng <br />
                            <!-- Thời gian quét -->
                            <b>{{ vueData.CTQuaTang[0]?.GioQuet }} {{ vueData.CTQuaTang[0]?.NgayQuet }}</b>
                        </div>
                    </div>
                </template>
                <!-- TH 2.2: Đã quét rồi & Không trúng thưởng -->
                <div v-else-if="isShowWarnig_Miss">
                    Tài khoản đã quét<br />
                    không trúng thưởng<br />
                    <!-- Thời gian quét -->
                    <b>{{ vueData.CTQuaTang[0]?.GioQuet }} {{ vueData.CTQuaTang[0]?.NgayQuet }}</b>
                </div>
            </div>
            <!-- TH 2.4: Đã quét rồi & có trúng thưởng và đã đổi quà -->
            <div v-if="isShowWarning_GiftMessage" class="card-white mt-3">
                <span>Tài khoản đã đổi quà</span>
                <br />
                <!-- Thời gian đổi -->
                <b>{{ vueData.CTQuaTang[0]?.DoiThuong_Gio }} {{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }}</b>
            </div>
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
            $this.isShowChoose = true
        },
    },
}
</script>
