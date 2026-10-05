<template>
	<div class="full-screen">
		<!-- TH 1.1, 1.2: Không đủ điều kiện -->
		<div v-if="isShowReject" class="full-screen bg-logo flex-center">
			<div class="bg-paper">
				<span class="text-title">📣 THÔNG BÁO TỪ BƯU CỤC ZEN 📣</span><br />
				Rất tiếc khi thông báo đến bạn rằng bưu kiện của bạn chưa đủ điều kiện để gửi đến ông già Noel. Vui lòng
				tìm hiểu thêm về cách thức gửi bưu kiện ở thông tin bên dưới nhé!<br />
				______________________________________________ <br />
				<span class="text-title">Cách thức gửi bưu kiện</span><br />
				1/ Hoá đơn có từ<br />
				2 thức uống + 2 topping + 1 bánh,<br />
				thì tất cả các ly nước có trên hoá đơn đều được quay số trúng thưởng;<br />
				2/ Nhập số và chọn nhà để được ông già Noel<br />
				giao quà đến tận nhà nhé!<br />
				3/ Phần thưởng:<br />
				- Labubu; <br />
				- Blind Box;<br />
				- Topping đồ uống; <br />
				- Trà sữa; <br />
				- Gà lắc phô mai;<br />
				- Chocolate Dream Cake;<br />
				- Há cảo tôm thủy tinh;<br />
				- Pizza chảo cá<br />
				________________________________________<br />
				<span class="text-title">Chúc bạn sẽ có một mùa Giáng Sinh thật an lành và hạnh phúc!</span><br />
			</div>
		</div>

		<!-- TH 1.2: Đủ điều kiện và chưa quét lần nào (Nhập 4 số cuối) -->
		<div v-if="isShowInputPin" class="full-screen bg-logo flex-center">
			<div class="bg-paper">
				<span class="text-title">
					Nhập số nhà <span class="text-input">
						< {{ vueData.CTQuaTang[0].MaPin }}>
					</span> để ông già Noel gửi quà đến tận nhà nhé
				</span>
				<br />
				Từ: ZENNIE.
				<br /> Địa chỉ số:
				<span class="text-input">
					< </span>
						<v-text-field class="input-pin" v-model="pinCode" dense hide-details
							type="number"></v-text-field>
						<span class="text-input"> > </span>, khu đô thị ZEN, VIETNAM <br />
						Đến: Santa Claus, 123 Elf Road, North Pole 8888 <br />
						-------------------------<br />
						Xin chào ÔNG GIÀ NOEL,<br />
						Con là ZENNIE ^^<br />
						Năm nay, con đã rất nỗ lực để học tập và làm việc.<br />
						Dưới đây là danh sách món quà Giáng Sinh con mong sẽ nhận được từ Ông Già Noel<br />
						- Labubu; Blind Box; Topping đồ uống, Trà sữa; Gà lắc phô mai; Chocolate Dream Cake; Há cảo tôm
						thủy tinh; Pizza chảo cá<br />
						- Hay chỉ cần một lời chúc mừng Giáng Sinh từ ông, con vẫn rất vui ạ ^^<br />
						Chúc Ông mùa Giáng Sinh Vui Vẻ và đem thật nhiều niềm vui tới cho mọi người. Cảm ơn Ông rất
						nhiều.<br />
						<div class="sign">
							<p class="text-center">Ký tên</p>
							<img src="/_cdn/zen-eorder/noel/sign.png" width="60" height="30" />
						</div>
			</div>
			<span class="text-number"> Lưu ý: Tất cả các ly đều có thể tham gia nhận quà ({{
				vueData.CTQuaTang[0].SoThuTuTem }})</span>
			<div @click="onSendPin" class="btn-style mt-3">GỬI THƯ</div>
		</div>

		<!-- TH 1.2.1: Chọn nhà -->
		<template v-if="isShowChooseHouse">
			<video class="video-effect" muted autoplay loop :key="replayVideo" playsinline webkit-playsinline>
				<source src="/_cdn/zen-eorder/noel/choose-house.mp4" type="video/mp4" />
			</video>
			<div class="mask-house">
				<div class="text-house">"Hãy chạm vào một ngôi nhà để bật ánh đèn sáng lung linh, Ông Già Noel sẽ theo
					ánh sáng đó và tìm đến nhé, HOHOHO"</div>
				<div class="full-screen">
					<div v-for="group in dataHouseImage" :key="group.house_group" class="house-group">
						<img class="tree-layer"
							:src="'/_cdn/zen-eorder/noel/home/tree-layer-' + group.house_group + '.png'" />
						<img class="tree-layer"
							:src="'/_cdn/zen-eorder/noel/home/pine-' + group.house_group + '.png'" />
						<template v-for="item in group.house_item" :key="item.home">
							<img :class="'house-image house-image-' + item.align"
								:src="'/_cdn/zen-eorder/noel/home/' + (houseSelected === item.home ? 'active-' : '') + 'home-' + item.home + '.png'" />
						</template>
						<img class="grass-layer"
							:src="'/_cdn/zen-eorder/noel/home/grass-' + group.house_group + '.png'" />
						<template v-for="item in group.house_item" :key="item.home">
							<div @click="onClickHouse(item.home)"
								:class="'mask-choose-house house-image-' + item.align"></div>
						</template>
					</div>
					<div class="d-flex justify-center mt-5">
						<div v-if="houseSelected > 0" @click="onSendHouse" class="btn-style">XÁC NHẬN</div>
					</div>
				</div>
			</div>
		</template>

		<!-- TH 1.2.2: Clip chờ quà -->
		<template v-if="isShowGiftWaiting">
			<video class="video-effect" muted autoplay :key="replayVideo" playsinline>
				<source src="/_cdn/zen-eorder/noel/waiting-gift.mp4" type="video/mp4" />
			</video>
		</template>

		<!-- TH 1.2.3: Clip thả quà -->
		<template v-if="isShowGiftResult">
			<video class="video-effect" muted autoplay :key="replayVideo" playsinline>
				<source :src="videoResult" type="video/mp4" />
			</video>

			<!-- TH 1.2.4: Popup kết quả không trúng -->
			<div v-if="isShowInput_NotGiftMessage && isShowResult" class="full-screen bg-result flex-center">
				<div class="bg-result-h">
					<div class="text-gift">
						{{ messageNotGift[vueData.CTQuaTang[0]?.ThongBaoKhongTrung]?.TieuDe }} <br />
						{{ messageNotGift[vueData.CTQuaTang[0]?.ThongBaoKhongTrung]?.NoiDung }}
					</div>
				</div>
			</div>

			<!-- TH 1.2.4: Popup kết quả trúng -->
			<div v-if="isShowInput_GiftInfo && isShowResult" class="full-screen bg-result flex-center">
				<div class="bg-result-t">
					<div class="text-gift">
						Xin Chào ZENNIE. <br />
						Món quà Giáng Sinh năm nay của ZENNIE sẽ là: <br />
						<span class="text-title">{{ vueData.CTQuaTang[0]?.TenQuaTang }}</span> <br />
						<img :src="vueData.CTQuaTang[0]?.AnhQuaTang" class="img-voucher" /> <br />
						<span style="font-size: 12px">Giáng Sinh An Lành và Hạnh Phúc nhé!</span>
					</div>
				</div>
			</div>
		</template>

		<!-- TH 2.3: Đã quét rồi & có trúng thưởng nhưng chưa đổi quà -->
		<div v-if="isShowWarning_Scan" class="full-screen bg-logo flex-center">
			<div class="bg-warning">
				<div v-if="isShowInput_GiftInfo" class="mb-4">
					Xin Chào ZENNIE. <br />
					Món quà Giáng Sinh năm nay của ZENNIE sẽ là: <br />
					<span class="text-title">{{ vueData.CTQuaTang[0]?.TenQuaTang }}</span> <br />
					<img :src="vueData.CTQuaTang[0]?.AnhQuaTang" class="img-voucher" /> <br />
					<span>Giáng Sinh An Lành và Hạnh Phúc nhé!</span>
				</div>
				<span class="text-title">Cảnh Báo</span> <br />
				Mã QR đã được quét
				<br />
				{{ vueData.CTQuaTang[0]?.NgayQuet }} {{ vueData.CTQuaTang[0]?.GioQuet }} <br />
				<div v-if="vueData.CTQuaTang[0]?.QrCode_Case === '2_2'" class="mt-3">Mã QR không trúng thưởng</div>
			</div>
		</div>

		<!-- TH 2.4: Đã quét rồi & có trúng thưởng và đã đổi quà -->
		<div v-if="isShowWarning_Gift" class="full-screen bg-logo flex-center">
			<div class="bg-warning">
				<span class="text-title">Mã QR đã được đổi quà</span> <br />
				<p>{{ vueData.CTQuaTang[0]?.DoiThuong_Ngay }} {{ vueData.CTQuaTang[0]?.DoiThuong_Gio }}</p>
			</div>
		</div>

		<!-- Audio background -->
		<audio id="audio-bg" style="display: hidden">
			<source src="/_cdn/zen-eorder/noel/christmas.mp3" type="audio/mpeg" />
		</audio>

		<!-- Audio effect -->
		<audio id="audio-ef" style="display: hidden">
			<source src="/_cdn/zen-eorder/noel/result.mp3" type="audio/mpeg" />
		</audio>
	</div>
</template>

<script>
	export default {
	    props: [],
	    data() {
	        return {
	            dataHouseImage: [
	                {
	                    house_group: 1,
	                    house_item: [
	                        { home: 1, align: "left" },
	                        { home: 2, align: "center" },
	                        { home: 3, align: "right" },
	                    ],
	                },
	                {
	                    house_group: 2,
	                    house_item: [
	                        { home: 4, align: "left" },
	                        { home: 5, align: "center" },
	                        { home: 6, align: "right" },
	                    ],
	                },
	                {
	                    house_group: 3,
	                    house_item: [
	                        { home: 7, align: "left" },
	                        { home: 8, align: "center" },
	                        { home: 9, align: "right" },
	                    ],
	                },
	            ],
	            isShowChooseHouse: false,
	            isShowGiftWaiting: false,
	            isShowGiftResult: false,
	            isShowResult: false,
	            houseSelected: 0,
	            videoResult: "",
	            pinCode: "",
	            replayVideo: 0,
	            messageNotGift: [
	                { TieuDe: "Ho...Ho...Ho!!!", NoiDung: "Đây đúng là một lá thư thú vị!! Ánh sáng của Noel sẽ thắp sáng trái tim và mang đến những điều tuyệt vời đến người đang đọc lá thư này🎄🎄🎄" },
	                { TieuDe: "Ho...Ho...Ho!!!", NoiDung: "Ta đã xem được bức thư và Ta rất vui. Cùng chào đón mùa Giáng Sinh thật ngọt ngào và vui vẻ nhé! 🎁🎁🎁" },
	                { TieuDe: "Ho...Ho...Ho!!!", NoiDung: "Hy vọng người nhận lời chúc này từ ông Già Noel sẽ có một mùa lễ thật hạnh phúc và sự an lành!  ❤❤❤" },
	                { TieuDe: "Ho...Ho...Ho!!!", NoiDung: "Thật vui khi Ta đã nhận được bức thư này. Chúc người đang đọc lá thư này sẽ có một mùa lễ ấm áp, bình yên và đầy ắp tình yêu  💌💌💌" },
	                { TieuDe: "Ho...Ho...Ho!!!", NoiDung: "Ta chúc cho người  đọc lá thư này thật nhiều niềm vui Hãy chào đón một mùa lễ tràn ngập yêu thương và những điều kỳ diệu! ✨ 🎄✨ " },
	            ],
	        }
	    },
	    mounted() { },
	    computed: {
	        isShowReject() {
	            return vueData.CTQuaTang[0]?.QrCode_Case === "1_1_2_1"
	        },
	        isShowWarning_Scan() {
	            return vueData.CTQuaTang[0]?.QrCode_Case === "2_2" || vueData.CTQuaTang[0]?.QrCode_Case === "2_3" || vueData.CTQuaTang[0]?.QrCode_Case === "2_4"
	        },
	        isShowWarning_Gift() {
	            return vueData.CTQuaTang[0]?.QrCode_Case === "2_4"
	        },
	        isShowInputPin() {
	            const $this = this
	            return !$this.isShowChooseHouse && vueData.CTQuaTang[0]?.QrCode_Case === "1_2"
	        },
	        isShowInput_GiftInfo() {
	            const $this = this
	            return (!$this.isShowChooseHouse && !$this.isShowGiftWaiting && vueData.CTQuaTang[0]?.QrCode_Case === "1_2_2") || vueData.CTQuaTang[0]?.QrCode_Case === "2_3"
	        },
	        isShowInput_NotGiftMessage() {
	            const $this = this
	            return !$this.isShowChooseHouse && !$this.isShowGiftWaiting && vueData.CTQuaTang[0]?.QrCode_Case === "1_2_1"
	        },
	    },
	    watch: {},
	    methods: {
	        onSendPin() {
	            const $this = this
	            if (vueData.CTQuaTang[0].MaPin === $this.pinCode) {
	                $this.replayVideo++
	                $this.isShowChooseHouse = true
	            } else {
	                showMessage({
	                    type: "red",
	                    title: "Thông báo",
	                    message: "Mã hóa đơn không đúng, vui lòng kiểm tra lại",
	                })
	            }
	        },
	        onClickHouse(house) {
	            const $this = this
	            $this.houseSelected = house
	        },
	        onSendHouse() {
	            const $this = this
	
	            //Stop audio bg
	            const audioBg = document.getElementById("audio-bg")
	            audioBg.loop = false
	            audioBg.pause()
	
	            //Play audio effect
	            const audio = document.getElementById("audio-ef")
	            audio.loop = true
	            audio.play()
	
	            ajaxCALL(
	                "/eorder/auth/QuaTang_Check_QrCode_XacNhan",
	                {
	                    QRCode: vueData.QRCode,
	                    KhachHangID: vueData.KhachHangID,
	                    MaPin: $this.pinCode,
	                },
	                (res) => {
	                    const data = res.data[0]
	                    vueData.CTQuaTang[0].Ma_Trung = data.Is_CoTrungThuong === 1 ? "T" : "H"
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
	
	                    if ($this.houseSelected > 0) {
	                        $this.replayVideo++
	                        $this.isShowGiftWaiting = true //Hiển thị video waiting
	                        $this.isShowChooseHouse = false
	
	                        //Chạy video kết quả sau 7.5s (khi video waiting kết thúc)
	                        setTimeout(() => {
	                            $this.replayVideo++
	                            $this.isShowGiftWaiting = false
	                            $this.videoResult = `/_cdn/zen-eorder/noel/results/${$this.houseSelected}${vueData.CTQuaTang[0]?.Ma_Trung}.mp4`
                            $this.isShowGiftResult = true
                        }, 7500)

                        //Đóng video kết quả -> Hiển thị popup kết quả (Khi tất cả đã kết thúc sau 14s)
                        setTimeout(() => {
                            $this.isShowResult = true
                        }, 15500)
                    }
                },
            )
        },
    },
}
</script>