<template>
	<div class="container-page">
        <div :style="bgStyle" class="bg-case d-flex flex-column justify-center align-center" style="max-width: 500px">
            <!-- Hiển thị Input PIN -->
            <div v-if="isShowInput_Pin &amp;&amp; !isShowLuckyWheel" style="z-index: 10">
                <v-card class="card-block card-block-code">
                    Quý khách nhập <br>
                    <b class="text-pin">{{ vueData.CTQuaTang[0]?.MaPin }}</b> <br>
                    Để tham gia quay số
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
                <v-card class="card-block card-block-title text-button mt-1" @click="onConfirm">QUAY SỐ</v-card>
                <v-card class="card-block-content mb-150">
                    <p>
                        Tất cả các ly đều được tham gia quay số
                        <br>
                        Số thứ tự ly: <b>{{ vueData.CTQuaTang[0]?.SoThuTuTem }}</b>
                    </p>
                </v-card>
            </div>

            <!-- Hiển thị vòng quay -->
            <div v-if="isShowLuckyWheel &amp;&amp; luckyNumber >= 0">
                <uc-lucky-wheel :num="luckyNumber">
            </uc-lucky-wheel></div>

            <!--  Hiển thị quà tặng -->
            <div v-if="isShowInput_GiftInfo">
                <v-card class="card-block card-block-title">Chức Mừng Bạn</v-card>
                <v-card class="card-block card-block-content">
                    <p>
                        Bạn đã nhận được
                        <br>
                        <img :src="vueData.CTQuaTang[0]?.AnhQuaTang" class="img-voucher"> <br>
                        {{ vueData.CTQuaTang[0]?.TenQuaTang }}
                    </p>
                </v-card>
            </div>

            <!-- Hiển thị thông báo không trúng -->
            <div v-if="isShowInput_NotGiftMessage" class="mb-150">
                <v-card class="card-block card-block-title">Và Kết Quả Là</v-card>
                <v-card class="card-block card-block-content">
                    <p>
                        <b>{{ messageNotGift[vueData.CTQuaTang[0]?.ThongBaoKhongTrung]?.TieuDe }}</b> <br>
                        {{ messageNotGift[vueData.CTQuaTang[0]?.ThongBaoKhongTrung]?.NoiDung }}
                    </p>
                </v-card>
            </div>

            <!-- Hiển thị thông báo đã đổi quà -->
            <div v-if="isShowWarning_Gift" class="mb-150">
                <v-card class="card-block card-block-title">Mã QR đã được đổi quà</v-card>
                <v-card class="card-block card-block-content">
                    <p>{{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }} {{ vueData.CTQuaTang[0]?.DoiThuong_Gio }}</p>
                </v-card>
            </div>

            <!-- Hiển thị thông báo đã quét QR -->
            <div v-if="isShowWarning_Scan" class="mb-150">
                <v-card class="card-block card-block-title">Cảnh Báo</v-card>
                <v-card class="card-block card-block-content">
                    <p>
                        Mã Qr đã được quét
                        <br>
                        {{ vueData.CTQuaTang[0]?.NgayQuet }} {{ vueData.CTQuaTang[0]?.GioQuet }}
                    </p>
                </v-card>
                <v-card v-if="vueData.CTQuaTang[0]?.QrCode_Case === '2_2'" class="card-block-content">
                    <p>Mã QR không trúng thưởng</p>
                </v-card>
            </div>

            <!-- Cách thước đổi thưởng -->
            <div class="position-info" v-if="vueData.CTQuaTang[0]?.QrCode_Case !== '1_1_2_1'">
                <v-card class="card-block card-block-title">Cách Thức Đổi Thưởng</v-card>
                <v-card class="card-block card-block-content">
                    <p class="text-small">
                        • Nhanh chân đến cửa hàng gần nhất, quét mã QR khách hàng tại quầy thu ngân để được đổi quà nhé. <br>
                        • Đối với phần thưởng là voucher đồ ăn: <br>
                        - Sử dụng trực tiếp vào hóa đơn khi Quý khách dùng sản phẩm tại cửa hàng. <br>
                        - Không áp dụng đổi quà vào ngày lễ, Tết. <br>
                        - Để phục vụ quý khách hàng chu đáo nhất, ZEN xin phép chỉ áp dụng đổi tối đa 2 voucher món ăn trên mỗi tài khoản trong một ngày. Mong Quý khách hàng thông cảm ạ!
                    </p>
                </v-card>
            </div>

            <!-- Thông tin chương trình -->
            <div class="position-info" v-if="vueData.CTQuaTang[0]?.QrCode_Case === '1_1_2_1'">
                <v-card class="card-block card-block-title">Sorry</v-card>
                <v-card class="card-block card-block-content mb-150">
                    <p>Đơn hàng của bạn chưa đủ điều kiện để tham gia chương trình. Mình cùng tìm hiểu thêm về chương trình bên dưới nhé</p>
                </v-card>
                <v-card class="card-block card-block-title">Thông Tin Chương Trình</v-card>
                <v-card class="card-block card-block-content">
                    <p class="text-small">
                        1/ Điều kiện tham gia <br>
                        Hóa đơn có TỪ 2 thức uống + 2 topping + 1 bánh, thì tất cả các ly nước có trên hóa đơn đều được tham gia quay số trúng thưởng.<br>
                        2/ Quay số đề nhận thưởng. <br>
                        3/ Phần thưởng <br>
                        • Baby Three Lily In Town <br>
                        • Blind Box <br>
                        • Voucher Got Pizza, ZEN Hong Kong Dimsum, ZEN Foodcourt, ZEN Tea, ZEN Japanese Bakery<br>
                    </p>
                </v-card>
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
                {TieuDe: "ĐƯỢC LÀ TRỜI CHO - MẤT LÀ TRÒ CHƠI 🤷🏼‍♂️", NoiDung: "Trò này hình như hong dzui lắm, nhưng biết đâu lần sau lại quay trúng nên đừng từ bỏ nhaaaaa!!"},
                {TieuDe: "SỰ THẬT MẤT LÒNG MÀ LÒNG VÒNG THÌ MẤT THỜI GIAN 🤦🏼", NoiDung: "Khum từ bỏ, phải trà trộn bằng mọi cách để rinh quà dề 🤘🏼🤘🏼"},
                {TieuDe: "THÀ XUI MỘT LẦN RỒI THÔI - XUI THÊM LẦN NỮA LÀ LẦN THỨ HAI 😚😚", NoiDung: "Sau lần thứ N vẫn chưa tìm được con Bé Ba thì vẫn không từ bỏ, tới khi nào bắt ẻm về được mới thoaiii!!!"},
                {TieuDe: "ỦA ALO? MAY MẮN ƠI, ĐI LẠC RỒI À? 👀👀", NoiDung: "Chắc con bé Bấy Bì Tri trốn mất tiêu, lần sau phải bằng mọi giá tìm được ẻm nhoen 😤"},
                {TieuDe: "QUAY XONG NGỠ NGÀNG, NGƠ NGÁC - BẬT NGỬA 😊😊", NoiDung: "Ngỡ ngàng khi chưa trúng thì vẫn còn ly ZEN, thôi thì làm ngụm nước để lấy lại bình tĩnh nhen 😤😤"},
                {TieuDe: "MÉM XÍU LÀ TRÚNG ROÀIIII 😚😚", NoiDung: "Ái chà hình như may mắn tới roài, lần sau săn lại thôiii 🤨"},
                {TieuDe: "SAU VÀI LẦN QUAY TRẬT LẦN NÀY LẠI TRẬT TIẾP 😎😎", NoiDung: "Nay chưa săn được thì mình còn ngày mai, không tha cho ZEN ngày nào hết, tới pến luônnnn"},
            ],
        }
    },
    mounted() {
    },
    computed: {
        bgStyle() {
            const $this = this
            return `background-image: url(https://cdn.zentea.vn/filedata/zen-eorder/secret-in-zen/${vueData.CTQuaTang[0]?.QrCode_Case}.jpg?v=202410280948)`
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
                    }, 11000) //11s
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