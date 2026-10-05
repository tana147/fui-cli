<template>
	<div>
		<v-dialog v-model="vueData.isInpReportDialog" fullscreen transition="dialog-bottom-transition" max-width="900px"
			persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isInpReportDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Biên bản cuộc họp</p>
					</template>
				</c-toolbar>

				<v-card-text>
					<v-container>
						<div class="text-center pt-3">
							<h2 class="black--text">BIÊN BẢN CUỘC HỌP HỘI ĐỒNG CHẤM LUẬN VĂN THẠC SĨ</h2>
							<h2 class="black--text mt-2">NGÀNH TÀI CHÍNH - NGÂN HÀNG</h2>
							<!-- replace -->
						</div>

						<div class="d-flex align-center mt-5">
							<p class=" black--text infoTxt">của học viên: <b>Lưu Ngọc Anh</b></p>
							<!-- replace -->
						</div>
						<div class="d-flex align-center">
							<p class=" black--text infoTxt">Với luận văn: <b>Các yếu tố ảnh hưởng đến quyết định gửi
									tiền của khác hàng doanh nghiệp tại Ngân hàng
									Thương mại cổ phần Ngoại thương Việt Nam chi nhánh Biên Hòa</b></p>
							<!-- replace -->
						</div>
						<div class="d-flex align-center">
							<p class=" black--text infoTxt">tại trường Đại học Lạc Hồng</p>
							<!-- replace -->
						</div>
						<div class="d-flex align-center">
							<p class="black--text infoTxt">Vào ngày </p>
							<div class="dateTimeInp">
								<v-text-field v-model="ReportData.Date" class="mb-7 centered-input" dense hide-details
									color="primary" />
							</div>
							<p class="black--text infoTxt">tháng</p>
							<div class="dateTimeInp">
								<v-text-field v-model="ReportData.Month" class="mb-7 centered-input" dense hide-details
									color="primary" />
							</div>
							<p class="black--text infoTxt">năm</p>
							<div class="yearInp">
								<v-text-field v-model="ReportData.Year" class="mb-7 centered-input" dense hide-details
									color="primary" />

							</div>
						</div>

						<div>
							<p class=" black--text infoTxt">Một số ý kiến trao đổi của hội đồng:</p>
							<v-textarea class="mt-2 mb-2" outlined name="input-7-1" rows="3" color="primary"
								flat="false" auto-grow dense hide-details />
							<!-- replace -->
						</div>

						<div>
							<p class=" black--text infoTxt">Sau khi nghe tác giả trả lời và người hướng dẫn khoa học
								nhận xét luận văn. Hội đồng họp riêng và thông qua kết luận,
								Hội đồng bầu Ban kiểm phiếu gồm:
							</p>
							<div>
								<div class="d-flex align-center">
									<div class="mb-4 councilMemInp">
										<v-text-field label="Thành viên hội đồng"
											placeholder="Nhập tên thành viên hội đồng" outlined dense hide-details />
									</div>
									<p class="ml-6 black--text infoTxt">
										Trưởng ban
									</p>
								</div>
								<div class="d-flex align-center">
									<div class="mb-4 councilMemInp">
										<v-text-field label="Thành viên hội đồng"
											placeholder="Nhập tên thành viên hội đồng" outlined dense hide-details />
									</div>
									<p class="ml-6 black--text infoTxt">
										Ủy viên
									</p>
								</div>
								<div class="d-flex align-center">
									<div class="mb-4 councilMemInp">
										<v-text-field label="Thành viên hội đồng"
											placeholder="Nhập tên thành viên hội đồng" outlined dense hide-details />
									</div>
									<p class="ml-6 black--text infoTxt">
										Ủy viên
									</p>
								</div>
							</div>
							<!-- replace -->
						</div>

						<div>
							<p class="mb-0 black--text infoTxt">Căn cứ vào kết quả bỏ phiếu của Hội đồng chấm luận văn
								là:
							</p>

							<div class="d-flex align-center">
								<p class=" black--text infoTxt mb-0 pb-0">
									- Số thành viên hội đồng tham gia bỏ phiếu:
								</p>
								<div>
									<v-text-field class="inpNumber centered-input" dense hide-details color="primary"
										type="number" />
								</div>
							</div>

							<div class="d-flex align-center">
								<p class=" black--text infoTxt mb-0 pb-0">
									- Tổng số điểm chấm luận văn của Hội đồng:
								</p>
								<div>
									<v-text-field class="inpNumber centered-input" dense hide-details color="primary"
										type="number" />
								</div>
							</div>

							<div class="d-flex align-center">
								<p class=" black--text infoTxt mb-0 pb-0">
									- Điểm bình quân:
								</p>
								<div>
									<v-text-field class="inpNumber centered-input" dense hide-details color="primary"
										type="number" />
								</div>
							</div>

							<div class="mt-1">
								<p class=" black--text infoTxt mb-0 pb-0">
									Hội đồng kết luận:
								</p>
								<div class="d-flex align-center mt-5">
									<p class=" black--text infoTxt">1) Bản luận văn của học viên: <b>Lưu Ngọc Anh</b>
										đáp ứng yêu cầu của luận văn Thạc sĩ <b>Tài Chính - Ngân Hàng</b></p>
									<!-- replace -->
								</div>
								<div>
									<p class=" black--text infoTxt">Một số khuyến cáo của hội đồng như sau (nếu có)</p>
									<!-- replace -->
									<v-textarea class="mt-2 mb-2" outlined name="input-7-1" rows="3" color="primary"
										flat="false" auto-grow dense hide-details />
								</div>
								<div class="mt-2">
									<p class=" black--text infoTxt">
										2) Đề nghị công nhận học vị Thạc sĩ <b>Tài Chính -
											Ngân Hàng</b> cho học viên <b>Lưu Ngọc Anh</b>
									</p>
									<!-- replace -->
								</div>
								<div>
									<p class=" black--text infoTxt">
										3) Đề nghị cho phép học viên <b>Lưu Ngọc Anh</b> được chuyển tiếp nghiên cứu
										sinh
									</p>
									<!-- replace -->
								</div>
							</div>
						</div>

						<div class="text-center pa-5">
							<v-btn color="warning" dark>
								<v-icon left>mdi-content-save-check</v-icon>Lưu nội dung biên bản
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
				ReportData: {
					Date: null,
					Month: null,
					Year: null,
				}
			}
		},
		mounted() {
			this.getCurrentDate()
		},
		computed: {},
		watch: {},
		methods: {
			getCurrentDate() {
				const today = new Date();
				this.ReportData.Date = today.getDate();
				this.ReportData.Month = today.getMonth() + 1; // Tháng bắt đầu từ 0 nên cần cộng 1
				this.ReportData.Year = today.getFullYear();
			}
		},
	}
</script>