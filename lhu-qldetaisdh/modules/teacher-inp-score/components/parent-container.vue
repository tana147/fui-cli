<template>
	<div>
		<input-score-dialog />
		<input-comment-dialog />
		<input-report-dialog />

		<v-dialog v-model="isInpPasscode" transition="dialog-bottom-transition" max-width="600px" persistent>
			<v-card>
				<v-card-title>
					<p class="mb-0 primary--text">Chọn tài khoản</p>
				</v-card-title>
				<v-card-text>
					<v-row>
						<v-col cols="12">
							<v-autocomplete :items="GetAllGV" item-text="GVHD" item-value="GVHD" label="Tên giảng viên"
								placeholder="Nhập hoặc chọn tên giảng viên" outlined dense hide-details
								color="primary" />
						</v-col>
						<v-col cols="12">
							<v-text-field type="number" label="Passcode" placeholder="Nhập passcode" outlined dense
								hide-details />
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn @click="checkingAccount" color="success">Xác nhận</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<div class="d-flex align-center mt-3 mb-3">
			<div class="dateOfMeeting"> 
				<v-autocomplete label="Lọc đề tài" dense outlined hide-details />
			</div>

			<v-btn class="ml-auto" color="primary">Tải bộ tài liệu</v-btn>
		</div>

		<f-table label="Danh sách học viên" :headers="headerTable" :items="itemList" show-search="true" dense="true"
			excel="true" :footer-props="{'items-per-page-options':[50, 100, 150, -1]}" itemsPerPage="-1" />

		<!-- <v-text-field label="test" outlined class="centered-input"/> -->
	</div>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				isInpPasscode: false,
				GetAllGV: [],
	
				headerTable: [
					{
						text: "STT",
						value: "stt",
						sortable: false,
						align: "center",
						width: "50"
					},
					{
						text: "Họ tên",
						value: "Hoten",
						width: "150"
					},
					{
						text: "Ngành",
						value: "Nganh",
						width: "200"
					},
					{
						text: "Đề tài",
						value: "Detai"
					},
					// {
					// 	text: "Chức năng",
					// 	value: "InpCtrl",
					// 	el: "div",
					// 	sortable: false,
					// 	align: "center",
					// 	innerHTML: `<v-btn @click="vueData.isInpScoreDialog = true" dense hide-details text color="success">Nhập điểm</v-btn>
					// 				<v-btn color="primary" dense hide-details text>Nhận xét luận văn</v-btn>
					// 				<v-btn color="primary" dense hide-details text>Biên bản cuộc họp</v-btn>
					// 								`
					// },
					{
						value: "NhapDiem",
						el: "div",
						sortable: false,
						align: "center",
						innerHTML: `<v-btn @click="vueData.isInpScoreDialog = true" dense hide-details text color="success">Nhập điểm</v-btn>`
					},
					{
						value: "NhanXet",
						el: "div",
						sortable: false,
						align: "center",
						innerHTML: `<v-btn @click="vueData.isInpCmtDialog = true" color="primary" dense hide-details text>Nhận xét luận văn</v-btn>`
					},
					{
						value: "BienBan",
						el: "div",
						sortable: false,
						align: "center",
						innerHTML: `<v-btn @click="vueData.isInpReportDialog = true" color="warning" dense hide-details text>Biên bản cuộc họp</v-btn>`
					},
				],
				itemList: [
					{
						stt: "1",
						Hoten: "Lưu Ngọc Anh",
						Nganh: "TÀI CHÍNH – NGÂN HÀNG",
						Detai: "Các yếu tố ảnh hưởng đến quyết định gửi tiền của khách hàng doanh nghiệp tại Ngân hàng Thương mại cổ phần Ngoại thương Việt Nam chi nhánh Biên Hòa"
					}
				],
				giangVienList: [
					{
						name: "Trần Văn A",
						giangVienID: 1
					},
					{
						name: "Phạm Văn B",
						giangVienID: 2
					},
					{
						name: "Nguyễn Thị C",
						giangVienID: 3
					},
				]
			}
		},
		mounted() {
			this.onLoadGVHD()
		},
		computed: {},
		watch: {},
		methods: {
			checkingAccount() {
				this.isInpPasscode = false
			},
			onLoadGVHD() {
				ajaxCALL("/GetALLGiangVienHuongDan", null,
					(res) => {
						this.GetAllGV = res.data
						console.log("this.GetAllGV", this.GetAllGV)
					}, (error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
						console.log("Fail to load task regist", error)
					})
			},
		},
	}
</script>