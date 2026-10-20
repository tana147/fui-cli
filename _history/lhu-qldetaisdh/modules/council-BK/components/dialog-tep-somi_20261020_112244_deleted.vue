<template>
	<div>
		<v-dialog v-model="vueData.isDialogTepSomi" transition="dialog-bottom-transition" max-width="1680px" persistent>
			<v-card>
				<c-toolbar @onClose="closeDialog">
					<template v-slot:title>
						<p class="title mb-0 primary--text">In tệp sơ mi HDDGLV</p>
					</template>
				</c-toolbar>

				<v-card-text>
					<div>
						<p>Thông tin học viên</p>
						<div class="d-flex align-center">
							<p>Học viên:</p>
							<p class="ml-1">{{deTaiInfo.HoSV}} {{deTaiInfo.TenSV}} [{{deTaiInfo.StudentID}}]</p>
						</div>
						
					</div>
					<v-row>
						<v-col>
							<p>Số quyết định thành lập hội đồng</p>
						</v-col>
						<v-col>
							<p>Ngày quyết định thành lập hội đồng</p>
						</v-col>
						<v-col>
							<p>Ngày đánh giá luận văn</p>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["hoidongid"],
		data() {
			return {
				deTaiInfo: [],
				hoiDong: []
			}
		},
		mounted() { },
		computed: {
			IsDialogTepSomi: function () {
				return vueData.isDialogTepSomi
			}
		},
		watch: {
			hoidongid: function (val) {
				if (val && this.IsDialogTepSomi) {
					this.getHoiDongByID(val)
				}
			}
		},
		methods: {
			getHoiDongByID(hoiDongID) {
				ajaxCALL("/HoiDong_Get_ByHoiDongID", {
					HoiDong_ID: hoiDongID
				}, (res) => {
					this.deTaiInfo = res.data[0][0]
					this.hoiDong = res.data[1]
	
					console.log("deTaiInfo", this.deTaiInfo)
					console.log("hoiDong", this.hoiDong)
				}, (error) => {
					Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
					console.log("Fail get goi dong by ID", error)
				})
			},
			closeDialog() {
				vueData.isDialogTepSomi = false
			}
		},
	}
</script>