<template>
	<uc-llkh-muc title="II. Đề tài, dự án" nguon="NCKH" anchor="nckh-II"
		note="Bao gồm đề tài KHCN cấp cơ sở, hội đồng NCKH và đề tài cấp Bộ / ngoài trường tự khai.">
		<template #actions>
			<v-btn size="small" variant="flat" color="primary" prepend-icon="mdi-plus" @click="moThem">
				Thêm đề tài ngoài trường
			</v-btn>
		</template>

		<f-table :items="rows" :headers="headers" :update-api="updateApi" :excel="false"></f-table>

		<!-- Dialog thêm / chỉnh sửa đề tài ngoài trường -->
		<v-dialog v-model="dialog" max-width="580px" persistent>
			<v-card>
				<v-card-title class="d-flex align-center text-subtitle-1 font-weight-bold">
					<v-icon color="primary" class="mr-2">mdi-flask-plus-outline</v-icon>
					{{ form.DeTaiID ? 'Chỉnh sửa đề tài ngoài trường' : 'Thêm đề tài ngoài trường tự khai' }}
					<v-spacer></v-spacer>
					<v-btn icon="mdi-close" variant="text" size="small" @click="dialog = false"></v-btn>
				</v-card-title>
				<v-divider></v-divider>
				<v-card-text class="pt-4">
					<v-row dense>
						<v-col cols="12">
							<v-text-field v-model="form.TenDeTai" label="Tên đề tài / dự án *"
								placeholder="Nhập đầy đủ tên đề tài..." variant="outlined" density="compact"
								:rules="[v => !!v || 'Bắt buộc nhập tên đề tài']"></v-text-field>
						</v-col>
						<v-col cols="12" sm="6">
							<v-combobox v-model="form.CoQuanTaiTro" :items="dsCapDeTai" label="Cấp đề tài / Cơ quan tài trợ *"
								placeholder="Chọn hoặc nhập cấp..." variant="outlined" density="compact"></v-combobox>
						</v-col>
						<v-col cols="12" sm="6">
							<v-text-field v-model="form.ThoiGianThucHien" label="Thời gian thực hiện *"
								placeholder="Ví dụ: 2021 – 2023" variant="outlined" density="compact"
								hint="Năm hoặc tháng/năm bắt đầu - kết thúc" persistent-hint></v-text-field>
						</v-col>
						<v-col cols="12">
							<v-select v-model="form.VaiTro" :items="dsVaiTro" label="Trách nhiệm / Vai trò tham gia *"
								variant="outlined" density="compact"></v-select>
						</v-col>
					</v-row>
				</v-card-text>
				<v-divider></v-divider>
				<v-card-actions class="px-4 py-2">
					<v-btn v-if="form.DeTaiID" color="error" variant="text" prepend-icon="mdi-delete-outline"
						:loading="dangXoa" @click="xoaDeTai">Xóa đề tài</v-btn>
					<v-spacer></v-spacer>
					<v-btn variant="text" @click="dialog = false">Đóng</v-btn>
					<v-btn color="primary" variant="flat" prepend-icon="mdi-content-save" :loading="dangLuu"
						@click="luuDeTai">Lưu đề tài</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { deTai: [] } } }
		},
		emits: ["reload"],
		data: function () {
			return {
				dialog: false,
				dangLuu: false,
				dangXoa: false,
				form: {
					DeTaiID: 0,
					TenDeTai: "",
					CoQuanTaiTro: "Đề tài cấp Bộ GD&ĐT",
					ThoiGianThucHien: "",
					VaiTro: "Chủ nhiệm"
				},
				dsCapDeTai: [
					"Đề tài cấp Nhà nước",
					"Đề tài cấp Bộ GD&ĐT",
					"Đề tài cấp Bộ KH&CN",
					"Đề tài Quỹ NAFOSTED",
					"Đề tài cấp Tỉnh / Thành phố",
					"Dự án tài trợ quốc tế",
					"Đề tài hợp tác doanh nghiệp"
				],
				dsVaiTro: [
					"Chủ nhiệm",
					"Phó chủ nhiệm",
					"Thành viên chính",
					"Thư ký khoa học",
					"Thành viên nghiên cứu"
				],
				updateApi: {
					"edit-action": {
						FUN: "LLKH_moSuaDeTai",
						IN: { item: "item" }
					}
				},
				headers: [
					{ title: "Tên đề tài", key: "TenDeTai" },
					{ title: "Mã số", key: "MaSoDeTai" },
					{ title: "Cấp", key: "Cap" },
					{ title: "Lĩnh vực", key: "LinhVuc" },
					{ title: "Thời gian", key: "ThoiGianHT" },
					{ title: "Vai trò", key: "VaiTro" },
					{ title: "Nguồn", key: "Nguon" },
					{ title: "Tác vụ", key: "ctrl-update", value: "ctrl-update", align: "center", width: 70 }
				]
			}
		},
		created: function () {
			var self = this
			window.LLKH_instanceDeTai = self
			window.LLKH_moSuaDeTai = function (arg) {
				var raw = arg && arg.item ? (arg.item.raw || arg.item) : (arg && arg.raw ? arg.raw : arg)
				if (!raw) return
				if (!raw.IsTuKhai) {
					if (typeof Vue !== "undefined" && Vue.$toast) {
						Vue.$toast.info("Đề tài cấp trường được quản lý tập trung, không thể chỉnh sửa tại đây.", { position: "top" })
					}
					return
				}
				self.moSua(raw)
			}
			if (typeof vueData !== "undefined") {
				vueData.LLKH_moSuaDeTai = window.LLKH_moSuaDeTai
			}
		},
		computed: {
			rows: function () {
				var L = window.LLKH
				return this.d.deTai.map(function (t) {
					return Object.assign({}, t, {
						MaSoDeTai: L.show(t.MaSoDeTai), Cap: L.show(t.Cap), LinhVuc: L.show(t.LinhVuc),
						ThoiGianHT: L.show(t.ThoiGian || t.Nam), VaiTro: L.show(t.VaiTro),
						"ctrl-update": t.IsTuKhai ? 1 : null
					})
				})
			}
		},
		methods: {
			moThem: function () {
				this.form = {
					DeTaiID: 0,
					TenDeTai: "",
					CoQuanTaiTro: "Đề tài cấp Bộ GD&ĐT",
					ThoiGianThucHien: "",
					VaiTro: "Chủ nhiệm"
				}
				this.dialog = true
			},
			moSua: function (raw) {
				this.form = {
					DeTaiID: raw.DeTaiID || 0,
					TenDeTai: raw.TenDeTai || "",
					CoQuanTaiTro: raw.Cap || "Ngoài trường",
					ThoiGianThucHien: raw.ThoiGian || raw.Nam || "",
					VaiTro: raw.VaiTro || "Chủ nhiệm"
				}
				this.dialog = true
			},
			luuDeTai: function () {
				var self = this
				if (!self.form.TenDeTai || !self.form.TenDeTai.trim()) {
					if (typeof Vue !== "undefined" && Vue.$toast) Vue.$toast.warning("Vui lòng nhập tên đề tài", { position: "top" })
					return
				}
				self.dangLuu = true
				ajaxCALL("/HDKH_LLKH_DeTaiNgoai_Save", self.form, function () {
					self.dangLuu = false
					self.dialog = false
					if (typeof Vue !== "undefined" && Vue.$toast) {
						Vue.$toast.success("Đã lưu đề tài ngoài trường", { position: "top" })
					}
					self.$emit("reload")
				}, function (xhr) {
					self.dangLuu = false
					var msg = xhr.responseJSON ? xhr.responseJSON.Message : (xhr.statusText || "Lỗi lưu dữ liệu")
					if (typeof showMessage === "function") {
						showMessage({ title: "Không lưu được", message: msg, type: "red" })
					} else {
						alert(msg)
					}
				})
			},
			xoaDeTai: function () {
				var self = this
				if (!self.form.DeTaiID) return
				self.dangXoa = true
				ajaxCALL("/HDKH_LLKH_DeTaiNgoai_Del", { DeTaiID: self.form.DeTaiID }, function () {
					self.dangXoa = false
					self.dialog = false
					if (typeof Vue !== "undefined" && Vue.$toast) {
						Vue.$toast.success("Đã xóa đề tài ngoài trường", { position: "top" })
					}
					self.$emit("reload")
				}, function (xhr) {
					self.dangXoa = false
					var msg = xhr.responseJSON ? xhr.responseJSON.Message : (xhr.statusText || "Lỗi xóa dữ liệu")
					if (typeof showMessage === "function") {
						showMessage({ title: "Không xóa được", message: msg, type: "red" })
					} else {
						alert(msg)
					}
				})
			}
		}
	}
</script>