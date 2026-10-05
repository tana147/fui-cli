<template>
	<div>
		<v-dialog v-model="vueData.isInpScoreDialog" fullscreen transition="dialog-bottom-transition" max-width="900px"
			persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isInpScoreDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Đánh giá luận văn thạc sĩ</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<!-- <v-row>
						<v-col>
							<v-data-table class="custom-border-table" :headers="headerTable" :items="scoreList" dense hide-default-footer>
								<template v-slot:item.inpScore="{ item }">
									<v-text-field v-model="item.inpScore" type="number" dense hide-details  />
								</template>
							</v-data-table>
						</v-col>
					</v-row> -->
					<v-container>
						<div class="text-center pt-3">
							<h2 class="black--text">PHIẾU ĐÁNH GIÁ LUẬN VĂN THẠC SĨ</h2>
							<h2 class="black--text mt-2">NGÀNH TÀI CHÍNH - NGÂN HÀNG</h2>
							<!-- replace -->
						</div>

						<div class="infoWrap d-flex align-center justify-center mt-5">
							<div>
								<v-text-field v-model="InfoDataList.SQD" class="mr-4" label="Số quyết định"
									placeholder="Nhập số quyết định" outlined dense hide-details />
							</div>
							<div>
								<!-- <f-date v-model="InfoDataList.NgayQD" label="Thời gian lập SQĐ"
									placeholder="Thời gian lập SQĐ" outlined dense hide-details /> -->
								<v-text-field v-model="InfoDataList.NgayQD" label="Thời gian lập SQĐ"
									placeholder="Thời gian lập SQĐ" outlined dense hide-details />
							</div>
							<div class="dateOfMeeting ml-4">
								<!-- <f-date v-model="InfoDataList.NgayHop" label="Thời gian họp" placeholder="Thời gian họp"
									outlined dense hide-details /> -->
								<v-text-field v-model="InfoDataList.NgayHop" label="Thời gian họp" placeholder="Thời gian họp"
									outlined dense hide-details />
							</div>
						</div>

						<div class="infoWrap">
							<div class="d-flex align-center mt-5">
								<p class=" black--text infoTxt">Học viên: <b>Lưu Ngọc Anh</b></p>
								<!-- replace -->
							</div>
							<div class="d-flex align-center">
								<p class=" black--text infoTxt">Với luận văn: <b>
										Các yếu tố ảnh hưởng đến quyết định gửi
										tiền của khác hàng doanh nghiệp tại Ngân hàng
										Thương mại cổ phần Ngoại thương Việt Nam chi nhánh Biên Hòa</b></p>
								<!-- replace -->
							</div>
						</div>

						<div>
							<div class="text-center">
								<h2 class="black--text">Ý KIẾN ĐÁNH GIÁ</h2>
								<P class="black--text"><i>(Cho điểm vào ô trống, tối đa là một số lẻ)</i></P>
							</div>
							<div class="d-flex justify-center align-center">
								<table class="table table-bordered tableWidth">
									<thead>
										<tr>
											<th class="tieuChi black--text tableTxt">Tiêu chí đánh giá</th>
											<th class="diemToiDa black--text tableTxt">Điểm tối đa</th>
											<th class="danhGia black--text tableTxt">Điểm đánh giá</th>
										</tr>
									</thead>
									<tbody>
										<tr v-for="(item, index) in InfoDataList.DanhSach" :key="index">
											<td
												:class="index === scoreList.length - 1 ? 'bold-right-align black--text pr-2 tableTxt mb-2 mt-2' : 'black--text pl-2 tableTxt'">
												{{item.TieuChi}}</td>
											<td
												:class="index === scoreList.length - 1 ? 'maxScoreRight black--text tableTxt mb-2 mt-2' : 'black--text text-center tableTxt'">
												{{item.DiemToiDa}}</td>
											<td>
												<!-- <v-text-field class="inpField" v-model="item.inpScore" type="number"
													dense hide-details reverse
													:rules="[validateScoreNotNull, validateScoreRange]" /> -->
												<v-text-field v-if="index !== scoreList.length - 1" class="inpField"
													v-model="item.DiemDanhGia" type="number" dense hide-details reverse
													:disabled="index === scoreList.length - 1" />
												<p v-else class="resultCol black--text tableTxt mb-2 mt-2 pr-3">
													{{sumResult}}</p>
											</td>
										</tr>
									</tbody>
								</table>
							</div>

							<div class="infoWrap d-flex align-center justify-end mt-5">
								<div class="text-center">
									<p class="black--text infoTxt"><b>THÀNH VIÊN HỘI ĐỒNG</b></p>
									<p class="black--text infoTxt"><b>LỮ PHI NGA</b></p>
								</div>
							</div>
						</div>

						<div class="text-center pa-5">
							<v-btn text @click="onSave" color="warning" dark>
								<v-icon left>mdi-content-save-check</v-icon>Lưu điểm đánh giá
							</v-btn>
							<v-btn class="ml-2" color='orange darken-4' dark>
								<v-icon left>mdi-file-pdf-box</v-icon>Lưu & In phiếu PDF
							</v-btn>
							<v-btn @click="onPrintWord" class="ml-2" color='light-blue darken-3' dark>
								<v-icon left>mdi-file-word-box</v-icon>Lưu & In phiếu Word
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
				validateScoreNotNull: value => !!value || 'Vui lòng nhập giá trị',
				validateScoreRange: value => (value !== null && !isNaN(value) && value >= 0 && value <= 10)
					|| 'Giá trị phải nằm trong khoảng từ 0 đến 10',
				sumResult: "0",
	
				headerTable: [
					{
						text: "Tiêu chí đánh giá",
						value: "name",
						width: 10,
					},
					{
						text: "Điểm tối đa",
						value: "maxScore",
						width: 10,
					},
					{
						text: "Điểm đánh giá",
						value: "inpScore",
						width: 10,
					}
				],
				InfoDataList: {
					Nganh: "",
					SQD: "            /DHLH",
					NgayQD: "",
					NgayHop: "",
					DeTai: "Các yếu tố ảnh hưởng đến quyết định gửi tiền của khách hàng doanh nghiệp tại Ngân hàng Thương mại cổ phần Ngoại thương Việt Nam chi nhánh Biên Hòa",
					GiangVien: "Lữ Phi Nga",
					DanhSach: [
						{
							TieuChi: "Bài báo, công trình khoa học",
							DiemToiDa: "1.0",
							DiemDanhGia: null
						},
						{
							TieuChi: "Trích nguồn tham khảo",
							DiemToiDa: "0.5",
							DiemDanhGia: null
						},
						{
							TieuChi: "Hình thức, kết cấu luận văn",
							DiemToiDa: "1.0",
							DiemDanhGia: null
						},
						{
							TieuChi: "Nội dung và kết quả nghiên cứu",
							DiemToiDa: "5.0",
							DiemDanhGia: null
						},
						{
							TieuChi: "Năng lực của học viên (trình bày và trả lời)",
							DiemToiDa: "2.5",
							DiemDanhGia: null
						},
						{
							TieuChi: "Điểm tổng cộng (lẻ đến 0.5)",
							DiemToiDa: "10",
							DiemDanhGia: null,
						},
					]
				},
				scoreList: [
					{
						name: "Bài báo, công trình khoa học",
						maxScore: "1.0",
						inpScore: null
					},
					{
						name: "Trích nguồn tham khảo",
						maxScore: "0.5",
						inpScore: null
					},
					{
						name: "Hình thức, kết cấu luận văn",
						maxScore: "1.0",
						inpScore: null
					},
					{
						name: "Nội dung và kết quả nghiên cứu",
						maxScore: "5.0",
						inpScore: null
					},
					{
						name: "Năng lực của học viên (trình bày và trả lời)",
						maxScore: "2.5",
						inpScore: null
					},
					{
						name: "Điểm tổng cộng (lẻ đến 0.5)",
						maxScore: "10",
						align: "justify-end",
						inpScore: null
					},
				]
			}
		},
		mounted() { },
		computed: {
			// Tính tổng của các giá trị inpScore
			// totalScore() {
			// 	// Tính tổng
			// 	const total = this.scoreList.slice(0, -1).reduce((accumulator, currentItem) => {
			// 		return accumulator + parseFloat(currentItem.inpScore || 0); // Nếu giá trị là null hoặc "", thì tính như 0
			// 	}, 0);
	
			// 	return total;
			// }
			totalScore() {
				// Tính tổng
				const total = this.InfoDataList.DanhSach.slice(0, -1).reduce((accumulator, currentItem) => {
					return accumulator + parseFloat(currentItem.DiemDanhGia || 0); // Nếu giá trị là null hoặc "", thì tính như 0
				}, 0);
	
				return total;
			}
		},
		watch: {
			// Watcher để kiểm tra và sửa giá trị nhập vào
			// 'scoreList': {
			// 	deep: true,
			// 	handler(newVal, oldVal) {
			// 		newVal.forEach(item => {
			// 			// Kiểm tra nếu giá trị nhập vào nhỏ hơn 0 thì sửa lại thành 0
			// 			if (item.inpScore !== null && item.inpScore < 0) {
			// 				item.inpScore = 0;
			// 			}
			// 			// Kiểm tra nếu giá trị nhập vào lớn hơn điểm tối đa thì sửa lại thành điểm tối đa
			// 			if (item.inpScore !== null && item.inpScore > parseFloat(item.maxScore)) {
			// 				item.inpScore = parseFloat(item.maxScore).toFixed(1);
			// 			}
			// 		});
	
	
			// 		// if (this.allScoresEntered()) {
			// 		// 	console.log("success");
	
			// 		// }
	
			// 		if (this.allScoresEntered()) {
			// 			this.sumResult = this.totalScore
			// 		}
			// 	},
			// },
			'InfoDataList.DanhSach': {
				deep: true,
				handler(newVal, oldVal) {
					newVal.forEach(item => {
						// Kiểm tra nếu giá trị nhập vào nhỏ hơn 0 thì sửa lại thành 0
						if (item.DiemDanhGia !== null && item.DiemDanhGia < 0) { item.DiemDanhGia = 0; } // Kiểm tra nếu giá trị nhập vào lớn hơn điểm tốiđa thì sửa lại thành điểm tối đa 
						if (item.DiemDanhGia !== null && item.DiemDanhGia > parseFloat(item.DiemToiDa)) {
							item.DiemDanhGia = parseFloat(item.DiemToiDa).toFixed(1);
						}
					});
	
	
					// if (this.allScoresEntered()) {
					// console.log("success");
	
					// }
	
					if (this.allScoresEntered()) {
						this.sumResult = this.totalScore.toString()
						console.log("this.sumResult", this.sumResult)
					}
				},
			},
			// 'sumResult': {
			// 	deep: true,
			// 	handler(newVal, oldVal) {
			// 		this.scoreList[this.scoreList.length - 1].inpScore = newVal
			// 		console.log("this.scoreList[length - 1]", this.scoreList[this.scoreList.length - 1])
			// 	}
			// },
			'sumResult': {
				deep: true,
				handler(newVal, oldVal) {
					this.InfoDataList.DanhSach[this.InfoDataList.DanhSach.length - 1].DiemDanhGia = newVal
					console.log("this.InfoDataList.DanhSach[length - 1]", this.InfoDataList.DanhSach[this.InfoDataList.DanhSach.length - 1])
				}
			}
		},
		methods: {
			onPrintWord() {
				let CustomDs = JSON.parse(JSON.stringify(this.InfoDataList.DanhSach))
				const BaiBao = 0;
				const TrichNguon = 1;
	
				CustomDs[BaiBao].TieuChi = CustomDs[BaiBao].TieuChi + "1";
				CustomDs[TrichNguon].TieuChi = CustomDs[TrichNguon].TieuChi + "2";
	
				const testObj = {
					Nganh: "Tài chính - Ngân hàng",
					SQD: this.InfoDataList.SQD,
					NgayQD: this.InfoDataList.NgayQD,
					NgayHop: this.InfoDataList.NgayHop,
					TenHV: "Lưu Vân Anh",
					DeTai: "Các yếu tố ảnh hưởng đến quyết định gửi tiền của khách hàng doanh nghiệp tại Ngân hàng Thương mại cổ phần Ngoại thương Việt Nam chi nhánh Biên Hòa",
					GiangVien: "Lữ Phi Nga",
					DanhSach: CustomDs
				}
	
				const myHeaders = new Headers();
				myHeaders.append("Content-Type", "application/json");
				const requestOptions = {
					method: "POST",
					headers: myHeaders,
					body: JSON.stringify(testObj),
					redirect: "follow"
				};
	
				console.log("score list", testObj)

				//https://gendocx.iotsoftvn.com
				fetch("https://gendocx.iotsoftvn.com/api/generate-docx/phieu-diem", requestOptions)
					.then((response) => response.blob())
					.then(blob => {
						var url = window.URL.createObjectURL(blob);
						var a = document.createElement('a');
						a.href = url;
						a.download = "PhieuDiem.docx";
						document.body.appendChild(a); // we need to append the element to the dom -> otherwise it will not work in firefox
						a.click();
						a.remove(); //afterwards we remove the element again
					})
					.catch((error) => console.error(error));
			},
			// allScoresEntered() {
			// 	const arr = this.scoreList.slice(0, -1);
			// 	return arr.every(item => item.inpScore !== null && item.inpScore !== "" && item.inpScore !== undefined);
			// },
			allScoresEntered() {
				const arr = this.InfoDataList.DanhSach.slice(0, -1);
				return arr.every(item => item.DiemDanhGia !== null && item.DiemDanhGia !== "" && item.DiemDanhGia !== undefined);
			},
			onSave() {
				console.log("scoreList", this.InfoDataList)
			}
		},
	}
</script>