<template>
	<div>
		<v-dialog v-model="vueData.isUpdateDialog" transition="dialog-bottom-transition" max-width="1300px" persistent>
			<v-card>
				<c-toolbar @onClose="vueData.isUpdateDialog = false">
					<template v-slot:title>
						<p class="title mb-0 primary--text">Cập nhật hội đồng HV:
							<span class="red--text">[{{HoiDong.Student_ID}}] {{HoiDong.Ho_SV}} {{HoiDong.Ten_SV}}
								[{{HoiDong.Lop_ID}}]
							</span>
						</p>
					</template>
				</c-toolbar>
				<v-card-text>
					<uc-table-hoi-dong :dshdgiangvien="DSHoiDongGiangVien" :dshedaotao="dshedaotao" :hoidong="HoiDong"
						:hearr="hearr" @onSelected="(ds)=>{DSGiangVienSeleted = ds}" />
				</v-card-text>
				<v-card-actions>
					<v-btn color="error" outlined @click="openCancelDialog">
						<v-icon left>mdi-calendar-remove-outline</v-icon>Hủy hội đồng
					</v-btn>
					<v-spacer></v-spacer>
					<div class="datePicker mr-3">
						<f-date v-model="HoiDong.ThoiGianBaoVe" color="success" label="Ngày bảo vệ luận văn"
							placeholder="Ngày bảo vệ luận văn" outlined dense hide-details />
					</div>
					<v-btn color="primary" @click="onSaveUpdate" dark>Cập nhật hội đồng</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog Xác nhận Hủy Hội Đồng -->
		<v-dialog v-model="isCancelDialogOpen" max-width="560px" persistent>
			<v-card>
				<v-card-title class="headline error--text pb-2">
					<v-icon left color="error">mdi-alert-circle-outline</v-icon>
					Xác nhận hủy hội đồng
				</v-card-title>
				<v-card-text class="pt-2">
					<p class="body-1 mb-2">
						Bạn có chắc chắn muốn hủy hội đồng của học viên
						<b>[{{HoiDong.Student_ID}}] {{HoiDong.Ho_SV}} {{HoiDong.Ten_SV}}</b>?
					</p>
					<v-alert dense outlined type="warning" class="caption mb-3">
						Hội đồng hiện tại sẽ được lưu trữ vào lịch sử để tra cứu. Tiến trình Bước 6 sẽ được reset về trạng thái chờ cấp hội đồng mới.
					</v-alert>
					<v-textarea
						v-model="cancelReason"
						label="Lý do hủy / hoãn bảo vệ"
						outlined
						rows="3"
						dense
						hide-details
						placeholder="Ví dụ: Có việc đột xuất xin hoãn sang đợt sau..."
					></v-textarea>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn text @click="isCancelDialogOpen = false" :disabled="isCancelling">Đóng</v-btn>
					<v-btn color="error" :loading="isCancelling" @click="handleCancelHoiDong">Xác nhận hủy</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["editedItem", "dshoidonggiangvien", "thongtinhocvien", "dshedaotao", "hearr"],
		data() {
			return {
				DSGiangVienSeleted: [],
				HoiDong: {},
				time: "",
				isCancelDialogOpen: false,
				cancelReason: "",
				isCancelling: false
			}
		},
		mounted() { },
		computed: {
			DSHoiDongGiangVien: function () {
				return this.dshoidonggiangvien
			},
			HocVien: function () {
				return this.thongtinhocvien
			},
			IsUpdateDialog: function () {
				return vueData.isUpdateDialog
			},
			EditItem: function () {
				return this.editedItem
			},
		},
		watch: {
			editedItem: function (val) {
				if (val) {
					val.ThoiGianBaoVe = val.ThoiGian
					console.log("ThoiGianBaoVe before", val.ThoiGianBaoVe)
					val.ThoiGianBaoVe = moment(val.ThoiGianBaoVe, 'DD/MM/YYYY').format('YYYY-MM-DD')
					console.log("val xxx", val)
					this.HoiDong = val
				}
			},
			IsUpdateDialog: function (val){
				if(val){
					console.log("EditItem xxxxxxxxx", this.EditItem)
				}
			}
		},
		methods: {
			openCancelDialog() {
				this.cancelReason = ""
				this.isCancelDialogOpen = true
			},
			async handleCancelHoiDong() {
				const hoiDongId = this.HocVien?.HoiDongID || this.HoiDong?.HoiDongID
				const studentId = this.HocVien?.StudentID || this.HoiDong?.Student_ID
				if (!hoiDongId) {
					Vue.$toast.error("Không tìm thấy mã hội đồng", { position: "top" })
					return
				}
				this.isCancelling = true
				try {
					await ajaxCALLPromise("/HoiDong_Cancel", {
						HoiDong_ID: hoiDongId,
						Student_ID: studentId,
						LyDoHuy: this.cancelReason ? this.cancelReason.trim() : ""
					})
					Vue.$toast.success("Hủy hội đồng và reset tiến trình thành công", { position: "top" })
					this.isCancelDialogOpen = false
					this.onCloseDialog()
					CALL("getHoiDongDeTai")
				} catch (error) {
					Vue.$toast.error(error?.responseJSON?.Message || "Lỗi khi hủy hội đồng", { position: "top" })
				} finally {
					this.isCancelling = false
				}
			},
			onSaveUpdate() {
				const $this = this
				const giaTriChucTrach = new Set();
				console.log("$this.DSGiangVienSeleted", $this.DSGiangVienSeleted)
				console.log("$this.HocVien", $this.editedItem)
	
				if ($this.editedItem.Process_ID === 4 ? $this.DSGiangVienSeleted.length < 3 : $this.DSGiangVienSeleted.length < 5) {
					Vue.$toast.error(`Chưa đủ thành viên hội đồng`, { position: 'top' })
				}
				else if ($this.HoiDong.ThoiGianBaoVe === "") {
					Vue.$toast.error(`Chưa thêm Thời gian bảo vệ`, { position: 'top' })
				}
				else {
					for (const giangVien of $this.DSGiangVienSeleted) {
						if (giangVien.ChucTrach === undefined) {
							Vue.$toast.error(`Có thành viên chưa được gán chức trách`, { position: 'top' });
							return;
						}
						else {
							if (giaTriChucTrach.has(giangVien.ChucTrach)) {
								const viTriTrungLap = $this.DSGiangVienSeleted.findIndex(item => item.ChucTrach === giangVien.ChucTrach);
								Vue.$toast.error(`Trùng lặp với giá trị "${giangVien.ChucTrach}"`, { position: 'top' });
								return; // Dừng xử lý nếu có phần tử trùng lặp
							}
							giaTriChucTrach.add(giangVien.ChucTrach);
						}
					}
					console.log("time", this.time)
					//Call API xong thì mới đóng dialog
					console.log("DSGiangVienSeleted", $this.DSGiangVienSeleted) // Đã lấy các giảng viên đã được chọn
					ajaxCALL("/HoiDong_Udp", {
						Student_ID: $this.HocVien?.StudentID,
						HoiDong_ID: $this.HocVien?.HoiDongID,
						HoiDongThanhVienObj_Arr: $this.DSGiangVienSeleted,
						ThoiGianBaoVe: $this.HoiDong.ThoiGianBaoVe,
					}, (res) => {
						Vue.$toast.success(`Cập nhật thành công`, { position: 'top' })
						console.log("Update complete", res)
						CALL('getHoiDongDeTai')
					}, (error) => {
						Vue.$toast.error(`${error.responseJSON.Message}`, { position: 'top' });
						console.log("Update failed", error)
					})
					vueData.isUpdateDialog = false
				}
	
			},
			onCloseDialog() {
				vueData.isUpdateDialog = false
			}
		},
	}
</script>