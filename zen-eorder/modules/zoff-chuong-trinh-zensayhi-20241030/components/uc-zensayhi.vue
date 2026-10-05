<template>
	<div class="container-page">
        <div :style="bgStyle" class="bg-case d-flex flex-column justify-center align-center">
            <!-- Hiển thị Input PIN -->
            <div v-if="isShowInput_Pin &amp;&amp; !isShowLuckyWheel">
                <v-card class="card-block">
                    <div class="card-block-content">
                        Quý khách nhập <br>
                        <b class="card-block-pin primary--text">{{ vueData.CTQuaTang[0]?.MaPin }}</b> <br>
                        để tham gia quay số
                    </div>
                </v-card>
                <div class="d-flex flex-row justify-center">
                    <v-card class="card-input">
                        <v-text-field type="number" @keydown="onFocusInput('pinInput_2')" ref="pinInput_1" v-model="pinInput_1" class="pin-input" flat="" solo="" hide-details="">
                    </v-text-field></v-card>
                    <v-card class="card-input">
                        <v-text-field type="number" @keydown="onFocusInput('pinInput_3')" ref="pinInput_2" v-model="pinInput_2" class="pin-input" flat="" solo="" hide-details="">
                    </v-text-field></v-card>
                    <v-card class="card-input">
                        <v-text-field type="number" @keydown="onFocusInput('pinInput_4')" ref="pinInput_3" v-model="pinInput_3" class="pin-input" flat="" solo="" hide-details="">
                    </v-text-field></v-card>
                    <v-card class="card-input">
                        <v-text-field type="number" ref="pinInput_4" v-model="pinInput_4" class="pin-input" flat="" solo="" hide-details="">
                    </v-text-field></v-card>
                </div>
                <v-card class="card-block mb-100" @click="onConfirm"><b class="card-block-title">Quay số</b> </v-card>
                <div class="label-number-position">
                    <b>Số thứ tự ly: {{ vueData.CTQuaTang[0]?.SoThuTuTem }}</b>
                </div>
            </div>

            <!-- Hiển thị vòng quay -->
            <div v-if="isShowLuckyWheel &amp;&amp; luckyNumber >= 0">
                <uc-lucky-wheel :num="luckyNumber">
            </uc-lucky-wheel></div>

            <!--  Hiển thị quà tặng -->
            <div v-if="isShowInput_GiftInfo">
                <v-card class="card-block" style="margin-top: 80px"> <b class="card-block-title">Chúc mừng bạn</b> <br> </v-card>
                <v-card class="card-block">
                    <p><b>Bạn đã nhận được</b></p>
                    <img :src="vueData.CTQuaTang[0]?.AnhQuaTang" class="img-voucher">
                    <p class="card-block-title">{{ vueData.CTQuaTang[0]?.TenQuaTang }}</p>
                </v-card>
            </div>

            <!-- Hiển thị thông báo không trúng -->
            <div v-if="isShowInput_NotGiftMessage" style="width: 90%" class="text-message">
                <v-card class="card-block ma-0 pa-2">
                    <p class="card-block-title">{{ messageNotGift[vueData.CTQuaTang[0]?.ThongBaoKhongTrung]?.TieuDe }}</p>
                    <span>{{ messageNotGift[vueData.CTQuaTang[0]?.ThongBaoKhongTrung]?.NoiDung }}</span>
                </v-card>
            </div>

            <!-- Hiển thị thông báo đã đổi quà -->
            <div v-if="isShowWarning_Gift" class="mb-15">
                <v-card class="card-block">
                    <b class="card-block-title">Mã Qr đã được đổi quà</b> <br>
                    <span>{{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }} {{ vueData.CTQuaTang[0]?.DoiThuong_Gio }}</span>
                </v-card>
            </div>

            <!-- Hiển thị thông báo đã quét QR -->
            <div v-if="isShowWarning_Scan">
                <v-card class="card-block"><b class="card-block-title">Cảnh báo</b></v-card>
                <v-card class="card-block">
                    <b class="card-block-title">Mã Qr đã được quét</b> <br>
                    <span>{{ vueData.CTQuaTang[0]?.NgayQuet }} {{ vueData.CTQuaTang[0]?.GioQuet }}</span>
                </v-card>
                <v-card v-if="vueData.CTQuaTang[0]?.QrCode_Case === '2_2'" class="card-block"><b class="card-block-title">Mã QR không trúng thưởng</b></v-card>
            </div>
        </div>
    </div>
</template>

<script>
	export default {
		props: [],
    data() {
        return {
            isShowLuckyWheel: false,
            luckyNumber: 1,
            pinInput_1: "",
            pinInput_2: "",
            pinInput_3: "",
            pinInput_4: "",
            messageNotGift: [
                {TieuDe: "ZEN CHÚC BẠN MỘT NGÀY THẬT TUYỆT VỜI DÙ MAY MẮN CHƯA ĐẾN", NoiDung: "Hãy cùng nhau hưởng ứng ngày lễ Phụ Nữ Việt Nam 20/10 ngập tràn niềm vui và hạnh phúc ❤❤"},
                {TieuDe: "HÃY TÌM CƠ HỘI VÀO LẦN QUAY SAU NHA 🤗", NoiDung: "ZEN xin chúc tất cả các phụ nữ trên thế giới này mãi xinh đẹp, luôn là bông hoa thơm trong vườn hoa ngát hương 🌹🌹"},
                {TieuDe: "Ù UÔIIIII", NoiDung: "Chốn xa hoa tiêu tiền không tiếc. Săn Labubu thua hoài lại trách ZEN gian nan 😔😔"},
                {TieuDe: "KHÓ CHỆU VÔ CÙNGGGG", NoiDung: "Hoa còn mọc được trên khe đá. Không lẽ bạn lại gục ngã trước ba cái Labubu ?"},
                {TieuDe: "Ù UÔIIIII", NoiDung: "Chốn xa hoa tiêu tiền không tiếc. Săn Labubu thua hoài lại trách ZEN gian nan 😔😔"},
                {TieuDe: "HÃY TÌM CƠ HỘI VÀO LẦN QUAY SAU NHA 🤗", NoiDung: "ZEN xin chúc tất cả các phụ nữ trên thế giới này mãi xinh đẹp, luôn là bông hoa thơm trong vườn hoa ngát hương 🌹🌹"},
                {TieuDe: "ZEN CHÚC BẠN MỘT NGÀY THẬT TUYỆT VỜI DÙ MAY MẮN CHƯA ĐẾN", NoiDung: "Hãy cùng nhau hưởng ứng ngày lễ Phụ Nữ Việt Nam 20/10 ngập tràn niềm vui và hạnh phúc ❤❤"},
            ],
        }
    },
    mounted() {},
    computed: {
        bgStyle() {
            const $this = this
            return `background-image: url(https://cdn.zentea.vn/filedata/zen-eorder/zensayhi/${vueData.CTQuaTang[0]?.QrCode_Case}.jpg?v=202409261426)`
        },
        isShowWarning_Scan() {
            if (vueData.CTQuaTang[0]?.QrCode_Case === "2_2" || vueData.CTQuaTang[0]?.QrCode_Case === "2_3" || vueData.CTQuaTang[0]?.QrCode_Case === "2_4") {
                return true
            } else {
                return false
            }
        },
        isShowWarning_Gift() {
            return vueData.CTQuaTang[0]?.QrCode_Case === "2_4"
        },
        isShowInput_Pin() {
            return vueData.CTQuaTang[0]?.QrCode_Case === "1_2"
        },
        isShowInput_GiftInfo() {
            return vueData.CTQuaTang[0]?.QrCode_Case === "1_2_2" || vueData.CTQuaTang[0]?.QrCode_Case === "2_3"
        },
        isShowInput_NotGiftMessage() {
            return vueData.CTQuaTang[0]?.QrCode_Case === "1_2_1"
        },
    },
    watch: {},
    methods: {
        onFocusInput: function (refName) {
            const $this = this
            setTimeout(() => {
                $this.$refs[refName].focus()
            }, 100)
        },
        onConfirm: function () {
            const $this = this
            const params = {
                KhachHangID: vueData.KhachHangID,
                QRCode: vueData.QRCode,
                MaPin: $this.pinInput_1 + $this.pinInput_2 + $this.pinInput_3 + $this.pinInput_4,
            }
            ajaxCALL(
                "/eorder/auth/QuaTang_Check_QrCode_XacNhan",
                params,
                (res) => {
                    const data = res.data[0]
                    $this.luckyNumber = data.QuaySo ?? 1
                    $this.isShowLuckyWheel = true
                    setTimeout(() => {
                        $this.isShowLuckyWheel = false
                        vueData.CTQuaTang[0].Is_CoTrungThuong = data.Is_CoTrungThuong
                        vueData.CTQuaTang[0].QrCode_Case = data.QrCode_Case ?? "1_2_1"
                        vueData.CTQuaTang[0].QuaySo = data.QuaySo
                        //Trúng
                        if (data.QrCode_Case === "1_2_2") {
                            vueData.CTQuaTang[0].AnhQuaTang = data.AnhQuaTang
                            vueData.CTQuaTang[0].TenQuaTang = data.TenQuaTang
                        } else {
                            //Không trúng
                            vueData.CTQuaTang[0].ThongBaoKhongTrung = data.ThongBaoKhongTrung
                        }
                    }, 9500) //9.5s
                },
                (err) => {
                    $this.pinInput_1 = ""
                    $this.pinInput_2 = ""
                    $this.pinInput_3 = ""
                    $this.pinInput_4 = ""
                    $this.$refs.pinInput_1.focus()
                    showMessage({
                        type: "red",
                        title: "Mã hóa đơn không hợp lệ, vui lòng kiểm tra lại",
                    })
                },
            )
        },
    },
	}
</script>