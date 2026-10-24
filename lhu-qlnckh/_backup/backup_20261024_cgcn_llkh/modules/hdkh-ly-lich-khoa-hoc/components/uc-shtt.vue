<template>
	<uc-llkh-muc title="III. Sáng chế, giải pháp hữu ích" nguon="NCKH" anchor="nckh-III"
		note="Bấm icon chỉnh sửa trên mỗi dòng để cập nhật/bổ sung Số văn bằng, Năm cấp, Nơi cấp phục vụ bản in Lý lịch khoa học.">
		<f-table :items="rows" :headers="headers" :update-api="updateApi" :excel="false"></f-table>

		<!-- Dialog bổ sung / cập nhật thông tin chi tiết SHTT -->
		<v-dialog v-model="dialogSua" max-width="580px" persistent>
			<v-card>
				<v-card-title class="d-flex align-center text-subtitle-1 font-weight-bold">
					<v-icon color="green darken-2" class="mr-2">mdi-square-edit-outline</v-icon>
					Cập nhật thông tin Sở hữu trí tuệ
					<v-spacer></v-spacer>
					<v-btn icon="mdi-close" variant="text" size="small" @click="dialogSua = false"></v-btn>
				</v-card-title>
				<v-divider></v-divider>
				<v-card-text class="pt-4">
					<div class="text-subtitle-2 font-weight-bold text-primary mb-3">{{ form.Ten }}</div>
					<v-row dense>
						<v-col cols="12" sm="7">
							<v-text-field v-model="form.SoVanBang" label="Số văn bằng / Quyết định"
								placeholder="Ví dụ: 12345/QĐ-SHTT" variant="outlined" density="compact"
								hint="Dùng cho bản in Lý lịch khoa học" persistent-hint></v-text-field>
						</v-col>
						<v-col cols="12" sm="5">
							<v-text-field v-model="form.NamCap" label="Năm hoặc ngày cấp"
								placeholder="Ví dụ: 2024 hoặc 2024-05-12" variant="outlined" density="compact"
								hint="Năm hoặc ngày ban hành văn bằng" persistent-hint></v-text-field>
						</v-col>
						<v-col cols="12">
							<v-text-field v-model="form.NoiCapVanBang" label="Nơi cấp văn bằng"
								placeholder="Ví dụ: Cục Sở hữu trí tuệ / Cục Bản quyền tác giả" variant="outlined" density="compact"
								hint="Cơ quan có thẩm quyền cấp văn bằng" persistent-hint></v-text-field>
						</v-col>
					</v-row>
				</v-card-text>
				<v-divider></v-divider>
				<v-card-actions class="px-4 py-2">
					<v-spacer></v-spacer>
					<v-btn variant="text" @click="dialogSua = false">Đóng</v-btn>
					<v-btn color="primary" variant="flat" prepend-icon="mdi-content-save" :loading="dangLuu"
						@click="luuChiTiet">Lưu thông tin</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { shtt: [], shttKeKhai: [] } } }
		},
		data: function () {
			return {
				dialogSua: false,
				dangLuu: false,
				form: {
					Nguon: "",
					ID: null,
					Ten: "",
					SoVanBang: "",
					NamCap: "",
					NoiCapVanBang: ""
				},
				updateApi: {
					"edit-action": {
						FUN: "LLKH_moSuaSHTT",
						IN: {
							item: "item"
						}
					}
				},
				headers: [
					{ title: "Tên sáng chế / giải pháp", key: "Ten", value: "Ten" },
					{ title: "Loại", key: "Loai", value: "Loai" },
					{ title: "Số văn bằng", key: "SoVanBang", value: "SoVanBang" },
					{ title: "Năm cấp", key: "NamCap", value: "NamCap" },
					{ title: "Nơi cấp", key: "NoiCap", value: "NoiCap" },
					{ title: "Vai trò", key: "VaiTro", value: "VaiTro" },
					{ title: "Đầu ra đề tài", key: "DauRa", value: "DauRa" },
					{ title: "Minh chứng", key: "MinhChung", value: "MinhChung" },
					{ title: "Nguồn", key: "Nguon", value: "Nguon" },
					{ title: "Chức năng", key: "ctrl-update", value: "ctrl-update", align: "center", width: 80 }
				]
			}
		},
		created: function () {
			var self = this
			window.LLKH_shtt_instance = self
			window.LLKH_moSuaSHTT = function (arg) {
				var raw = arg && arg.item ? (arg.item.raw || arg.item) : (arg && arg.raw ? arg.raw : arg)
				if (!raw) return
				self.moSua(raw)
			}
			if (typeof vueData !== "undefined") {
				vueData.LLKH_moSuaSHTT = window.LLKH_moSuaSHTT
			}
		},
		mounted: function () {
			var self = this
			window.LLKH_shtt_instance = self
			window.LLKH_moSuaSHTT = function (arg) {
				var raw = arg && arg.item ? (arg.item.raw || arg.item) : (arg && arg.raw ? arg.raw : arg)
				if (!raw) return
				self.moSua(raw)
			}
			if (typeof vueData !== "undefined") {
				vueData.LLKH_moSuaSHTT = window.LLKH_moSuaSHTT
			}
		},
		beforeUnmount: function () {
			if (window.LLKH_shtt_instance === this) {
				delete window.LLKH_shtt_instance
				delete window.LLKH_moSuaSHTT
			}
		},
		computed: {
			rows: function () {
				var L = window.LLKH
				var a = this.d.shtt.map(function (s) {
					return {
						Ten: s.TenCuocThi_CongTrinh,
						Loai: L.show(s.LoaiSHTT),
						SoVanBang: L.show(s.SoQuyetDinh_VanBang),
						NamCap: L.show(L.year(s.NgayBanHanh)),
						NoiCap: L.show(s.NoiCapVanBang),
						VaiTro: L.show(s.VaiTro),
						DauRa: s.Is_DauRaDeTaiCoSo ? "Đề tài cấp cơ sở" : "",
						MinhChung: s.SoMinhChung ? s.SoMinhChung + " tệp" : L.CHUA_NHAP,
						Nguon: "Đề nghị khen thưởng KHCN",
						_nguon: "KHEN_THUONG",
						_id: s.KhenThuongID
					}
				})
				var b = this.d.shttKeKhai.map(function (k) {
					return {
						Ten: L.show(k.Ten),
						Loai: L.show(k.LoaiSHTT),
						SoVanBang: L.show(k.SoVanBang),
						NamCap: L.show(k.NamCap),
						NoiCap: L.show(k.NoiCapVanBang),
						VaiTro: L.show(k.VaiTro),
						DauRa: "",
						MinhChung: "",
						Nguon: "Kê khai giờ NCKH (" + k.TrangThaiDuyet + ")",
						_nguon: "KE_KHAI",
						_id: k.SubmissionID
					}
				})
				return a.concat(b)
			}
		},
		methods: {
			moSua: function (item) {
				var L = window.LLKH
				this.form = {
					Nguon: item._nguon,
					ID: item._id,
					Ten: item.Ten,
					SoVanBang: item.SoVanBang === L.CHUA_NHAP ? "" : item.SoVanBang,
					NamCap: item.NamCap === L.CHUA_NHAP ? "" : item.NamCap,
					NoiCapVanBang: item.NoiCap === L.CHUA_NHAP ? "" : item.NoiCap
				}
				this.dialogSua = true
			},
			luuChiTiet: function () {
				var self = this
				self.dangLuu = true
				ajaxCALL("/HDKH_LLKH_SHTT_ChiTiet_Save", {
					Nguon: self.form.Nguon,
					ID: self.form.ID,
					SoVanBang: self.form.SoVanBang,
					NamCap: self.form.NamCap,
					NoiCapVanBang: self.form.NoiCapVanBang
				}, function (res) {
					self.dangLuu = false
					self.dialogSua = false
					Vue.$toast.success((res.data && res.data[0] && res.data[0].Message) || "Cập nhật thông tin SHTT thành công", { position: "top" })
					self.$emit("reload")
				}, function (xhr) {
					self.dangLuu = false
					showMessage({ title: "Không lưu được", message: xhr.responseJSON ? xhr.responseJSON.Message : "", type: "red" })
				})
			}
		}
	}
</script>
