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
					<v-spacer></v-spacer>
					<div class="datePicker mr-3">
						<f-date v-model="HoiDong.ThoiGianBaoVe" color="success" label="Ngày bảo vệ luận văn"
							placeholder="Ngày bảo vệ luận văn" outlined dense hide-details />
					</div>
					<v-btn color="primary" @click="onSaveUpdate" dark>Cập nhật hội đồng</v-btn>
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