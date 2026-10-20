<template>
	<div>
		<v-dialog v-model="vueData.isInpCmtDialog" fullscreen transition="dialog-bottom-transition" max-width="900px"
			persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isInpCmtDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Nhận xét luận văn</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<v-container>
						<div class="text-center pt-3">
							<h2 class="black--text">NHẬN XÉT LUẬN VĂN THẠC SĨ</h2>
							<p class="black--text mt-2">(Dùng cho người phản biện)</p>
						</div>

						<div class="d-flex align-center mt-5">
							<p class=" black--text infoTxt">Về đề tài: <b>Các yếu tố ảnh hưởng đến quyết định gửi
									tiền của khác hàng doanh nghiệp tại Ngân hàng
									Thương mại cổ phần Ngoại thương Việt Nam chi nhánh Biên Hòa</b></p>
							<!-- replace -->
						</div>
						<div class="d-flex align-center">
							<p class=" black--text infoTxt">Học viên: <b>Lưu Ngọc Anh</b></p>
							<!-- replace -->
						</div>
						<div>
							<v-row>
								<v-col>
									<p class=" black--text infoTxt">Ngành: <b>Tài Chính - Ngân Hàng</b></p>
								</v-col>
								<v-col>
									<p class=" black--text infoTxt">Mã số: </p>
								</v-col>
							</v-row>
						</div>

						<div>
							<h2 class="black--text mb-2">NỘI DUNG NHẬN XÉT</h2>
							<div class="mt-3">
								<div>
									<p class="black--text infoTxt">
										<b>
											1) Phần kết quả thực hiện của đề tài có trùng với các công trùng khoa học
											khác
											đã công bố hay không; nếu trùng, mức độ trùng lắp như thế nào
										</b>
									</p>
									<v-textarea class="mt-2 mb-2" outlined name="input-7-1" rows="3" color="primary"
										flat="false" auto-grow dense hide-details />
								</div>
								<div>
									<p class="black--text infoTxt"><b>2) Nhận xét và đánh giá cụ thể về luận văn</b></p>
									<v-textarea class="mt-2 mb-2" outlined name="input-7-1" rows="3" color="primary"
										flat="false" auto-grow dense hide-details />
								</div>
								<div>
									<p class="black--text infoTxt"><b>3) Những đề nghị chỉnh sửa, bổ sung cả về hình
											thức và nội dung
											(nếu có)</b></p>
									<v-textarea class="mt-2 mb-2" outlined name="input-7-1" rows="3" color="primary"
										flat="false" auto-grow dense hide-details />
								</div>
								<div>
									<p class="black--text infoTxt"><b>4) Câu hỏi dành cho học viên</b></p>
									<v-textarea class="mt-2 mb-2" outlined name="input-7-1" rows="3" color="primary"
										flat="false" auto-grow dense hide-details />
								</div>
							</div>

							<div class="mt-3">
								<h2 class="black--text mb-2">Kết luận:</h2>
								<div class="d-flex align-center">
									<p class="black--text infoTxt">Đề tài có đáp ứng yêu cầu của một luận văn
										thạc sĩ Ngành Tài chính - Ngân hàng không:</p>
									<div class="selectData mb-4 ml-4">
										<v-select v-model="dataSelect_1" :items="selectDataArr_1" item-text="text"
											item-value="text" outlined dense hide-details />
									</div>
								</div>
								<div class="d-flex align-center">
									<p class="black--text infoTxt">Học viên có xứng đáng để nhận văn bằng thạc sĩ hay
										không:</p>
									<div class="selectData mb-4 ml-4">
										<v-select v-model="dataSelect_2" :items="selectDataArr_2" item-text="text"
											item-value="text" outlined dense hide-details />
									</div>
								</div>
							</div>
						</div>

						<div class="text-center pa-5">
							<v-btn color="warning" dark>
								<v-icon left>mdi-content-save-check</v-icon>Lưu nội dung đánh giá
							</v-btn>
							<v-btn class="ml-2" color="success" dark>
								<v-icon left>mdi-printer</v-icon>Lưu & In phiếu
							</v-btn>
						</div>
					</v-container>
				</v-card-text>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				dataSelect_1: '',
				dataSelect_2: '',
				selectDataArr_1: [
					{
						text: 'Đáp ứng'
					},
					{
						text: 'Không đáp ứng'
					}
				],
				selectDataArr_2: [
					{
						text: 'Xứng đáng'
					},
					{
						text: 'Không xứng đáng'
					}
				],
			}
		},
		mounted() { },
		computed: {},
		watch: {
			dataSelect_1: function (val) {
				console.log("val", val)
			}
		},
		methods: {},
	}
</script>