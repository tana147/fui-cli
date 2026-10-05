<template>
	<div class="container-page">
		<div :style="bgStyle" class="bg-case d-flex flex-column justify-center align-center">
			<!-- Hiển thị thông báo đã quét QR -->
			<div v-if="isShowWarning_Scan" :class="classWarning">
				<v-card class="card-block"><b class="card-block-title">Cảnh báo</b></v-card>
				<v-card class="card-block">
					<b class="card-block-title">Mã Qr đã được quét</b> <br>
					<span>{{ vueData.CTQuaTang[0]?.NgayQuet }} {{ vueData.CTQuaTang[0]?.GioQuet }}</span>
				</v-card>
			</div>

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
				<v-card class="card-block mb-150" @click="onConfirm"><b class="card-block-title">Quay số</b> </v-card>
				<div class="label-number-position">
					<b>Số thứ tự ly: {{ vueData.CTQuaTang[0]?.SoThuTuTem }}</b>
				</div>
			</div>

			<!-- Hiển thị thông báo đã đổi quà -->
			<div v-if="isShowWarning_Gift" class="mb-15">
				<v-card class="card-block"><b class="card-block-title">Cảnh báo</b></v-card>
				<v-card class="card-block">
					<b class="card-block-title">Mã Qr đã được đổi quà</b> <br>
					<span>{{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }} {{ vueData.CTQuaTang[0]?.DoiThuong_Gio }}</span>
				</v-card>
			</div>

			<!-- Hiển thị mã QR nhận thưởng -->
			<div v-if="isShowQrCode">
				<div id="divQrCode" class="qr-code-position"></div>
			</div>

			<div v-if="isShowLuckyWheel &amp;&amp; luckyNumber >= 0">
				<uc-lucky-wheel :num="luckyNumber">
			</uc-lucky-wheel></div>
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
	        }
	    },
	    mounted() {
	        const $this = this
	        $this.renderQr()
	    },
	    computed: {
	        bgStyle() {
	            const $this = this
	            return `background-image: url(https://cdn.zentea.vn/filedata/zen-eorder/labubu/${vueData.CTQuaTang[0]?.QrCode_Case}.jpg)`
	        },
	        classWarning() {
	            return vueData.CTQuaTang[0]?.QrCode_Case === "2_3" ? "warning-2-3" : ""
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
	        isShowQrCode() {
	            if ((vueData.CTQuaTang[0]?.QrCode_Case === "2_3" || vueData.CTQuaTang[0]?.QrCode_Case === "1_2_2") && vueData.CTQuaTang[0]?.QrCode_TrungThuong !== "") {
	                return true
	            } else {
	                return false
	            }
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
	        renderQr: function () {
	            setTimeout(() => {
	                if (vueData.CTQuaTang[0]?.QrCode_TrungThuong !== "") {
	                    const options = { render: "canvas", text: vueData.CTQuaTang[0]?.QrCode_TrungThuong, size: 150 }
	                    $("#divQrCode").qrcode(options)
	                }
	            }, 0)
	        },
	        onConfirm: function () {
	            const $this = this
	            const params = {
	                QRCode: vueData.QRCode,
	                MaPin: $this.pinInput_1 + $this.pinInput_2 + $this.pinInput_3 + $this.pinInput_4,
	            }
	            ajaxCALL(
	                "/eorder/auth/QuaTang_Scan_QrCode_XacNhan",
	                params,
	                (res) => {
	                    const data = res.data[0]
	                    $this.luckyNumber = data.QuaySo ?? 1
	                    $this.isShowLuckyWheel = true
	                    setTimeout(() => {
	                        $this.isShowLuckyWheel = false
	                        vueData.CTQuaTang[0].QrCode_Case = data.QrCode_Case ?? "1_2_1"
	                        if (data.QrCode_Case === "1_2_2") {
	                            vueData.CTQuaTang[0].Is_CoTrungThuong = data.Is_CoTrungThuong
	                            vueData.CTQuaTang[0].QrCode_TrungThuong = data.QrCode_TrungThuong
	                            $this.renderQr(data.QrCode_TrungThuong)
	                        }
	                    }, 8500) //8.5s
	                },
	                (err) => {
	                    $this.pinInput_1 = ""
	                    $this.pinInput_2 = ""
	                    $this.pinInput_3 = ""
	                    $this.pinInput_4 = ""
	                    $this.$refs.pinInput_1.focus()
	                    showMessage({
	                        type: "red",
	                        title: "Không chính xác",
	                        message: `Mã hóa đơn không hợp lệ, vui lòng kiểm tra lại`,
	                    })
	                },
	            )
        },
    },
	}
</script>