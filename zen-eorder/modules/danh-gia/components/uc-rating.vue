<template>
	<div class="img-bg">
		<div class="v-toolbar__title white--text">
			<div class="d-flex align-center back-home">
				<v-icon @click="" class="float-left px-3 custom-back-icon"> mdi-arrow-left </v-icon>
			</div>
		</div>
		<div v-if="vueData.HoaDonID && vueData.HoaDonID > 0" class="d-flex justify-center align-center"
			style="height: 100dvh">
			<v-card v-if="MucDanhGia && MucDanhGia.length === 0" class="pa-4 mx-auto text-center" outlined>
				<v-card-title class="text-h6 font-weight-bold primary--text justify-center pb-4">
					Hiện tại mục đánh giá chưa được mở. Chúng tôi sẽ sớm cập nhật để bạn chia sẻ cảm nhận!
				</v-card-title>
				<v-card-text>
					<v-icon color="#218541" size="50">mdi-alert-circle-outline</v-icon>
					<p class="mt-3 text-h6 primary--text">Cảm ơn bạn đã đồng hành cùng Zen Tea.</p>
				</v-card-text>
			</v-card>
			<v-card class="pa-4 mx-auto" outlined v-else-if="!submitted">
				<v-card-title
					class="text-h4 font-weight-bold primary--text headline text-center d-flex justify-center pb-4"> Chia
					sẻ trải nghiệm </v-card-title>
				<v-card-text>
					<v-row class="custom-1" justify="center" v-for="(item, index) in MucDanhGia" :key="index">
						<v-col cols="12" class="d-flex align-center justify-space-between pb-0">
							<span class="primary--text text-h6 font-weight-bold">
								{{ item.TenLoaiDanhGia }}
							</span>
							<v-btn-toggle v-model="item.DiemDanhGia" dense group borderless>
								<v-btn v-for="n in item.ThangDiem" :key="n" :value="n" class="no-bg"
									@click="updateDiemDanhGia(index, n)">
									<v-icon :color="item.DiemDanhGia === n ? 'yellow darken-3' : 'grey'"
										:class="{'selected-icon': item.DiemDanhGia === n}">
										{{ n === 1 ? icons[0] : n === item.ThangDiem ? icons[2] : icons[1] }}
									</v-icon>
								</v-btn>
							</v-btn-toggle>
						</v-col>
						<v-col cols="12" class="pt-0">
							<v-chip-group multiple v-model="item.NhungLyDo" column>
								<v-chip v-for="(lydo, ldindex) in LyDo(item.DanhGia_LoaiID, item.DiemDanhGia)"
									:key="ldindex" :value="lydo.DanhGia_NoiDungID" filter>
									{{ lydo.NoiDung }}
								</v-chip>
							</v-chip-group>
						</v-col>
					</v-row>
				</v-card-text>
				<div class="d-flex justify-center mt-4">
					<v-btn color="primary" class="text-h6 custom-button-submit" large @click="submitRating()"> Gửi
						<v-icon class="xoay">mdi-send</v-icon>
					</v-btn>
				</div>
			</v-card>
			<v-card v-else class="pa-4 mx-auto text-center" outlined>
				<v-card-title class="text-h5 font-weight-bold primary--text justify-center pb-4"> Cảm ơn bạn đã đánh
					giá! </v-card-title>
				<v-card-text>
					<v-icon color="green" size="50">mdi-check-circle</v-icon>
					<p class="mt-3 text-h6">Đánh giá của bạn đã được ghi nhận. Chúng tôi sẽ sử dụng phản hồi này để cải
						thiện chất lượng dịch vụ.</p>
				</v-card-text>
			</v-card>
		</div>
		<div v-else class="d-flex justify-center align-center" style="height: 100dvh">
			<v-card class="pa-4 mx-auto text-center" outlined>
				<v-card-title class="text-h5 font-weight-bold primary--text justify-center pb-4"> Chia sẻ trải nghiệm
				</v-card-title>
				<v-card-text>
					<v-icon color="green" size="50">mdi-account-edit</v-icon>
					<p class="mt-3 text-h6">Hệ thống không tìm thấy hóa đơn của bạn. Vui lòng thử lại sau.</p>
				</v-card-text>
			</v-card>
		</div>
	</div>
</template>

<script>
	export default {
		props: ["ds_danhgia"],
		data() {
			return {
				ratings: {},
				MucDanhGia: null,
				icons: ["mdi-emoticon-sad", "mdi-emoticon-neutral", "mdi-emoticon-happy"],
				submitted: false, // Trạng thái sau khi gửi đánh giá
			}
		},
		watch: {
			ds_danhgia(newVal) {
				if (newVal && this.MucDanhGia == null) {
					this.MucDanhGia = newVal[0].map((e) => {
						const maxDiem = e.ThangDiem // Lấy điểm cao nhất từ thang điểm
						const firstReason = this.LyDo(e.DanhGia_LoaiID, maxDiem)[0]?.DanhGia_NoiDungID || null
						return {
							...e,
							NhungLyDo: firstReason ? [firstReason] : [],
							DiemDanhGia: maxDiem, // Gán điểm cao nhất mặc định
						}
					})
				}
			},
		},
		methods: {
			
			// // Cập nhật điểm đánh giá
			updateDiemDanhGia(index, diem) {
				this.$set(this.MucDanhGia[index], "DiemDanhGia", diem)
				this.$set(this.MucDanhGia[index], "NhungLyDo", [])
			},
			// Lấy lý do dựa trên ID và điểm đánh giá
			LyDo(dg_id, diem) {
				if (!this.ds_danhgia || !this.ds_danhgia[1]) return []
				return this.ds_danhgia[1].filter((ld) => ld.DanhGia_LoaiID === dg_id && ld.DiemDanhGia === diem)
			},
			// Xử lý khi gửi đánh giá
			submitRating() {
				const isMissingLyDo = this.MucDanhGia.every(item => !item.NhungLyDo || item.NhungLyDo.length === 0)
				if (isMissingLyDo) {
					this.$toast.error("Vui lòng chọn lý do cho ít nhất một tiêu chí để đánh giá!", {
						position: "top"
					});
					return;
				}
				const $this = this
				const feedbackData = {
					HoaDonID: vueData.HoaDonID,
					DanhGia_NoiDungID_List: this.LyDoList(),
				}
				const result = []
				const danhGiaNoiDungArr = this.MucDanhGia.flatMap((item) => item.NhungLyDo)
				danhGiaNoiDungArr.forEach((item) => {
					const objNoiDung = vueData.DSDanhGia[1].filter((nd) => {
						return nd.DanhGia_NoiDungID === item
					})
					result.push(objNoiDung)
				})
				let title = `<div class="confirm-scroll"><h3>Bạn có chắc muốn đánh giá các tiêu chí này?</h3>`
				vueData.DSDanhGia[0].forEach((item) => {
					// title += "<br /><p><b>" + item.TenLoaiDanhGia + "</b></p>"
					title += "<div class='confirm-group'>" + "<div class='confirm-title'>" + item.TenLoaiDanhGia + "</div>";
					result.flat().forEach((kq) => {
						if (item.DanhGia_LoaiID === kq.DanhGia_LoaiID) {
							title += "<div class='confirm-detail'>" + kq.NoiDung + " (" + kq.DiemDanhGia + ")</div>";
						}
					});
					title += "</div>";
				})
				title += `</div>`;
				confirm({
					title: title,
					action: function () {
						ajaxCALL("/eorder/auth/DanhGia_Insert", feedbackData, (res) => {
							Vue.$toast.success("Gửi đánh giá thành công", { position: "top" })
						})
						localStorage.setItem("userFeedback", JSON.stringify(feedbackData))
						$this.submitted = true
					},
	
				})
			},
			LyDoList() {
				// Lấy tất cả NhungLyDo từ MucDanhGia và nối thành chuỗi
				const LyDoList = this.MucDanhGia.flatMap((item) => item.NhungLyDo) // Lấy tất cả ID từ mảng NhungLyDo
					.join(",") // Nối bằng dấu ","
	
				return LyDoList
			},
	
			showData() { },
		},
	}
	// window.location.href = '/'
</script>