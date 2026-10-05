<template>
	<div class="full-screen" style="background-color: #fff8ea">
		<!--  GIỚI THIỆU CHƯƠNG TRÌNH -->
		<!-- <div class="full-screen flex-center">
                        <div class="bg-home" style="flex: 1">
                            <div class="bg-line"></div>
                        </div>
                        <div class="bg-paper" style="flex: 1">
                            <span class="text-banner">KHAI LỘC ĐẦU XUÂN</span><br />
                            <div class="img-line"></div>
                            <br />
                            <span class="text-title">Cách Thức Gọi Lộc Xuân</span><br />
                            1/ Hoá đơn có từ<br />
                            2 thức uống + 2 topping + 1 bánh,<br />
                            thì tất cả các ly nước có trên hoá đơn đều được tham gia Gọi Lộc Xuân;<br />
                            2/ Nhập mã may mắn để bắt đầu Gọi Lộc<br />
                            3/ Phần thưởng:<br />
                            Điểm ZEN <br />
                            Thú Nhồi Bông Lộc Mã <br />
                            Trà Sữa ZEN Size L <br />
                            Topping Trân Châu Tươi <br />
                            Bánh Su Singapore <br />
                            Bánh Rán Vị Tuỳ Chọn <br /><br />
                            <b>Chúc bạn năm mới mã đáo thành công <br/> Khởi đầu thuận lợi – gặt trọn thành quả!</b><br />
                        </div>
                    </div> -->

		<!-- TH 1.1, 1.2: Không đủ điều kiện -->
		<div v-if="isShowReject" class="full-screen flex-center">
			<div class="bg-miss" style="flex: 1">
				<div class="bg-line"></div>
			</div>
			<div class="bg-paper" style="flex: 1">
				<span class="text-banner">KHAI LỘC ĐẦU XUÂN</span><br />
				<div class="img-line"></div>
				<br />
				<span class="text-title">Đơn hàng chưa đủ điều kiện</span><br />
				Rất tiếc đơn hàng của bạn chưa đủ điều kiện. Vui lòng tìm hiểu thêm về cách thức Gọi Lộc ở thông
				tin bên
				dưới nhé! <br />
				<div class="img-line mt-5"></div>
				<br />
				<span class="text-title">Cách Thức Gọi Lộc Xuân</span><br />
				1/ Hoá đơn có từ<br />
				2 món nước Size L + 2 topping + 1 bánh,<br />
				thì tất cả các ly nước có trên hoá đơn đều được tham gia Gọi Lộc Xuân;<br />
				2/ Nhập mã may mắn để bắt đầu Gọi Lộc<br />
				3/ Phần thưởng:<br />
				Điểm ZEN <br />
				Thú Nhồi Bông Lộc Mã <br />
				Trà Sữa ZEN Size L <br />
				Topping Trân Châu Tươi <br />
				Bánh Su Singapore <br />
				Bánh Rán Vị Tuỳ Chọn <br /><br />
				<b>Chúc bạn năm mới mã đáo thành công <br /> khởi đầu thuận lợi – gặt trọn thành quả!</b><br />
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
						để Gọi Lộc Xuân nào!
				</div>
				<div class="div-input d-flex flex-row justify-center">
					<div class="card-input">
						<v-text-field placeholder="Nhập mã" type="number" maxlength="4" @focus="onOpenInput(true)"
							@blur="onOpenInput(false)" v-model="pinInput" class="pin-input" flat solo hide-details />
					</div>
				</div>
				<b>Lưu ý: Tất cả các ly đều có thể Gọi Lộc ({{ vueData.CTQuaTang[0].SoThuTuTem }})</b>
				<div @click="onSendPin" class="btn-style my-3">GỌI LỘC</div>
				<span style="font-style: italic;">Mỗi độ Tết đến - Xuân về, Bầu Cua Tôm Cá lại xuất hiện như một
					lời nhắn
					gửi từ mùa xuân, rằng may mắn có thể ghé đến khi chúng ta sẵn sàng thử vận may và tận hưởng
					trọn vẹn
					niềm vui.</span>
			</div>
		</div>

		<!-- TH 1.2.1: Chọn vật phẩm -->
		<template v-if="isShowChoose">
			<div class="full-screen bg-pick flex-center justify-end align-end">
				<div class="bg-game">
					<div class="d-flex">
						<div @click="coinPick('nai')" class="mask-pick pick-1"><img v-if="coinSelected === 'nai'"
								class="img-coin pos-1" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
						<div @click="coinPick('bau')" class="mask-pick pick-2"><img v-if="coinSelected === 'bau'"
								class="img-coin pos-2" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
						<div @click="coinPick('ga')" class="mask-pick pick-3"><img v-if="coinSelected === 'ga'"
								class="img-coin pos-3" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
					</div>
					<div class="d-flex">
						<div @click="coinPick('ca')" class="mask-pick pick-4"><img v-if="coinSelected === 'ca'"
								class="img-coin pos-4" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
						<div @click="coinPick('cua')" class="mask-pick pick-5"><img v-if="coinSelected === 'cua'"
								class="img-coin pos-5" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
						<div @click="coinPick('tom')" class="mask-pick pick-6"><img v-if="coinSelected === 'tom'"
								class="img-coin pos-6" src="/_cdn/zen-eorder/tet-2025/coin.png" /></div>
					</div>
				</div>
				<div v-if="coinSelected === ''" class="bg-desc ma-2">Chọn 1 vật phẩm bạn thích, để xem vận may
					chuyến này
					mỉm cười tới đâu nhaa!!!</div>
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
				<div v-if="vueData.CTQuaTang[0].QrCode_Case === '1_2_1'" class="div-mail">{{
					messageResult[indexMessageMiss].NoiDung }}</div>
				<!-- Trúng -->
				<div v-if="vueData.CTQuaTang[0].QrCode_Case === '1_2_2'" class="div-gift">
					<div @click="item.IsTuiMu = 0" v-for="item in vueData.CTQuaTang"
						class="item-gift d-flex flex-row mt-2">
						<img v-if="item.IsTuiMu === 0" class="img-voucher" :src="item.AnhQuaTang" />
						<img v-else class="img-blind" src="/_cdn/zen-eorder/tet-2025/blind-gift.png" />
						<div v-if="item.IsTuiMu === 0" class="text-voucher">
							<p class="mb-1">{{ giftTitle[item.MaVoucher] }}</p>
							<p class="mb-0">
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
					<span class="text-banner">KHAI LỘC ĐẦU XUÂN</span><br />
					<div class="img-line"></div>
				</div>
				<div class="bg-warning fw-100">CẢNH BÁO</div>
				<div class="div-gift">
					<div class="item-warning">
						<!-- TH 2.3: Đã quét rồi & có trúng thưởng nhưng chưa đổi quà -->
						<div v-if="isShowWarning_Gift" class="fw-100 fs-18">
							Mã QR có trúng thưởng <br />
							đã được quét
						</div>
						<!-- TH 2.2: Đã quét rồi & Không trúng thưởng -->
						<div v-else-if="isShowWarnig_Miss" class="fw-100 fs-18">
							Mã QR không trúng thưởng <br />
							đã được quét
						</div>
						<div v-else class="fw-100 fs-18">
							Mã QR đã được quét
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
				<span class="text-help-warning">Chúc bạn năm mới mã đáo thành công <br /> khởi đầu thuận lợi –
					gặt trọn
					thành quả!</span>
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
	                TET2026_ZEN6868: "Phát Tài Phát Lộc",
	                TET2026_ZEN7979: "Tài Lộc Dồi Dào",
	                TET2026_ZEN8686: "Phúc Lộc Vẹn Toàn",
	                TET2026_ZEN9999: "Tứ Mùa An Khang",
	                TET2026_SU: "Đầu năm mở lộc ngọt ngào, cả năm gặp nhiều niềm vui!",
	                TET2026_RAN: "Đầu xuân có chút ngọt lành, mong niềm vui theo bạn suốt năm nay!",
	                TET2026_LOCMA: "Lộc Mã khai xuân – Thành công nối dài!",
					TET2026_LOCMA2: "Lộc Mã khai xuân – Thành công nối dài!",
	                TET2026_TRANCHAU: "Có khi những điều bé xíu lại mang theo cả vận may!",
	                TET2026_TSZL: "Ngọt ngào mở đầu năm mới – mong mọi chuyện phía trước đều êm ả!",
	            },
	            giftMessage: {
	                TET2026_ZEN6868: "Lộc Xuân bạn nhận được là 6868 ĐIỂM ZEN",
	                TET2026_ZEN7979: "Lộc Xuân bạn nhận được là 7979 ĐIỂM ZEN",
	                TET2026_ZEN8686: "Lộc Xuân bạn nhận được là 8686 ĐIỂM ZEN",
	                TET2026_ZEN9999: "Lộc Xuân bạn nhận được là 9999 ĐIỂM ZEN",
	                TET2026_SU: "Bạn đã nhận được Bánh Su Singapore tại ZEN Tea hoặc ZEN Bakery",
	                TET2026_RAN: "Bạn đã nhận được Bánh Rán Vị Tuỳ chọn tại ZEN Tea và ZEN Bakery",
	                TET2026_LOCMA: "Bạn đã nhận được Thú Nhồi Bông Lộc Mã tại ZEN Tea",
					TET2026_LOCMA2: "Bạn đã nhận được Thú Nhồi Bông Lộc Mã tại ZEN Tea",
	                TET2026_TRANCHAU: "Bạn đã nhận được Topping Trân Châu Tươi tại ZEN Tea",
	                TET2026_TSZL: "Bạn đã nhận được Trà Sữa ZEN Size L tại ZEN Tea",
	            },
	            messageResult: [
	                { TieuDe: "", NoiDung: "Hôm nay vận may đi lạc chút xíu thôi. Chúc bạn năm mới luôn giữ được tinh thần tích cực và nhiều niềm vui phía trước!" },
	                { TieuDe: "", NoiDung: "Lộc chưa kịp ghé, nhưng không khí Tết thì vẫn còn nguyên. Chúc bạn khởi đầu năm mới thật nhẹ nhàng và nhiều điều hay ho đang chờ phía trước!" },
	                { TieuDe: "", NoiDung: "Lần này chưa trúng, nhưng trải nghiệm đầu năm vẫn là điều đáng giữ lại. Chúc bạn một năm mới thật nhiều khoảnh khắc vui vẻ ✨" },
	                { TieuDe: "", NoiDung: "Vận may tạm nghỉ một nhịp, biết đâu sẽ ghé đúng lúc bạn không ngờ tới. Chúc bạn năm mới nhiều năng lượng và những ngày thật tròn đầy. 💚" },
	                { TieuDe: "", NoiDung: "Vận may đang lấy đà cho lần xuất hiện thật rực rỡ, Chúc bạn năm mới thật nhiều điều để mỉm cười 😊" },
	                { TieuDe: "", NoiDung: "Hôm nay vận may đi lạc chút xíu thôi. Chúc bạn năm mới luôn giữ được tinh thần tích cực và nhiều niềm vui phía trước!" },
	            ],
	        }
	    },
	    mounted() { },
	    computed: {
	        // isAllowTest() {
	        //     const memberTest = [
	        //         'Z00052468', // IOT - Mr. Nhựt
	        //         'Z00042821', // IOT - Mr. Việt
	        //         'Z00042822', // IOT - Mr. Tâm
	        //         //'Z00048370', // IOT - Mr. Nhựt 2
	        //         'Z00000001', // ZEN - Mr. Quốc
	        //         'Z00020290', // ZEN - Mr. Hiếu
	        //         'Z00021812', // ZEN - Mr. Bin
	        //         'Z00070107' // ZEN - NoName
	        //     ]
	        //     return memberTest.indexOf(vueData.KhachHangID) >= 0
	        // },
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
	                showMessage({ type: "red", title: "Thông báo", message: "Mã hóa đơn không đúng, vui lòng kiểm tra lại" })
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
	                const { cmd, value } = json
	                if (cmd === "ON-SHAKE") {
	                    $this.execute("VIBRATE", 3000)
	                    $this.onShake()
	                }
	            })
	        },
	    },
	}
</script>