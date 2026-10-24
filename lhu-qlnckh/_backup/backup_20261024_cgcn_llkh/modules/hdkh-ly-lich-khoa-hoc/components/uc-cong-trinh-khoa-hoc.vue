<template>
	<uc-llkh-muc title="I. Bài báo, báo cáo, sách" nguon="NCKH" anchor="congtrinh-I"
		note="Ấn phẩm đã gửi (bỏ bản lưu tạm và bản bị từ chối). Bấm vào icon sửa trên mỗi bài báo để bổ sung nhanh: Tập-số-trang, tháng đăng, vai trò, tác giả liên hệ, thể loại sách, DOI. Dữ liệu này chỉ phục vụ Lý lịch khoa học, không ảnh hưởng đến phân hệ khen thưởng.">
		<div v-if="!nhom.length" class="text-body-2 text-error font-italic">Chưa có công trình nào</div>
		<v-expansion-panels v-else multiple variant="accordion" v-model="mo">
			<v-expansion-panel v-for="g in nhom" :key="g.ten" :value="g.ten">
				<v-expansion-panel-title>
					<span class="font-weight-medium">{{ g.ten }}</span>
					<v-chip size="x-small" class="ml-2" variant="tonal">{{ g.rows.length }}</v-chip>
				</v-expansion-panel-title>
				<v-expansion-panel-text>
					<f-table :items="g.rows" :headers="headers" :update-api="updateApi" :excel="false"></f-table>
				</v-expansion-panel-text>
			</v-expansion-panel>
		</v-expansion-panels>
		<template v-if="sach.length">
			<div class="text-subtitle-2 text-medium-emphasis mt-4 mb-1">Sách, giáo trình đã kê khai giờ NCKH</div>
			<f-table :items="sach" :headers="headersSach" :excel="false"></f-table>
		</template>

		<!-- Dialog bổ sung thông tin chi tiết bài báo -->
		<v-dialog v-model="dialogSua" max-width="680px" persistent>
			<v-card>
				<v-card-title class="d-flex align-center text-subtitle-1 font-weight-bold">
					<v-icon color="green darken-2" class="mr-2">mdi-square-edit-outline</v-icon>
					Bổ sung thông tin bài báo / công trình
					<v-spacer></v-spacer>
					<v-btn icon="mdi-close" variant="text" size="small" @click="dialogSua = false"></v-btn>
				</v-card-title>
				<v-divider></v-divider>
				<v-card-text class="pt-4">
					<div class="text-subtitle-2 font-weight-bold text-primary mb-1">{{ form.TenAnPham }}</div>
					<div class="text-caption text-medium-emphasis mb-3">{{ form.TenTapChi }} (Năm {{ form.NamDangBai }})</div>

					<v-row dense>
						<v-col cols="12" sm="8">
							<v-text-field v-model="form.TapSoTrang" label="Tập, số, trang"
								placeholder="Ví dụ: Vol. 15, No. 2, pp. 45-52" variant="outlined" density="compact"
								hint="Dùng cho bản in trích dẫn chuẩn học thuật" persistent-hint></v-text-field>
						</v-col>
						<v-col cols="12" sm="4">
							<v-select v-model="form.ThangDang" :items="dsThang" item-title="label" item-value="val"
								label="Tháng đăng" variant="outlined" density="compact" clearable></v-select>
						</v-col>

						<v-col cols="12" sm="7">
							<v-select v-model="form.VaiTroID" :items="dsVaiTroLoc" item-title="TenVaiTro" item-value="ID"
								label="Vai trò của tôi đối với công trình" variant="outlined" density="compact" clearable
								hint="Thứ tự/vai trò tác giả của bạn trong công trình" persistent-hint></v-select>
						</v-col>
						<v-col cols="12" sm="5" class="d-flex align-center">
							<v-checkbox v-model="form.Is_TacGiaLienHe" label="Tác giả liên hệ (Corresponding)"
								color="primary" density="compact" hide-details></v-checkbox>
						</v-col>

						<v-col v-if="form.LoaiAnPhamID === 6" cols="12">
							<v-select v-model="form.TheLoaiBienSoanID" :items="dsTheLoaiBienSoan" item-title="TenTheLoai"
								item-value="ID" label="Thể loại sách" variant="outlined" density="compact" clearable></v-select>
						</v-col>

						<v-col v-if="form.LoaiAnPhamID === 6 && form.TheLoaiBienSoanID === 6" cols="12">
							<v-text-field v-model="form.TenSachChuaChuong" label="Tên cuốn sách chứa chương sách"
								placeholder="Ví dụ: Advances in Intelligent Systems and Computing, Vol. 12"
								variant="outlined" density="compact" hint="Dùng cho bản in trích dẫn đào tạo tiến sĩ (SĐH)" persistent-hint></v-text-field>
						</v-col>

						<v-col cols="12">
							<v-text-field v-model="form.DoiLink" label="Đường link DOI chuẩn"
								placeholder="https://doi.org/10.xxxx/..." variant="outlined" density="compact"
								hint="Hệ thống tự nhận diện nếu link chứa https://doi.org/ hoặc 10.xxxx" persistent-hint></v-text-field>
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
			d: { type: Object, default: function () { return { congTrinh: [], sachKeKhai: [] } } }
		},
		data: function () {
			return {
				mo: [],
				dialogSua: false,
				dangLuu: false,
				form: {
					AnPhamID: null,
					TenAnPham: "",
					TenTapChi: "",
					NamDangBai: "",
					LoaiAnPhamID: null,
					TapSoTrang: "",
					ThangDang: null,
					VaiTroID: null,
					Is_TacGiaLienHe: false,
					TheLoaiBienSoanID: null,
					DoiLink: "",
					TenSachChuaChuong: ""
				},
				dsThang: [
					{ label: "Tháng 1", val: 1 }, { label: "Tháng 2", val: 2 }, { label: "Tháng 3", val: 3 },
					{ label: "Tháng 4", val: 4 }, { label: "Tháng 5", val: 5 }, { label: "Tháng 6", val: 6 },
					{ label: "Tháng 7", val: 7 }, { label: "Tháng 8", val: 8 }, { label: "Tháng 9", val: 9 },
					{ label: "Tháng 10", val: 10 }, { label: "Tháng 11", val: 11 }, { label: "Tháng 12", val: 12 }
				],
				dsVaiTro: [
					{ ID: 7, TenVaiTro: "Tác giả chính (First author)", loai: "baibao" },
					{ ID: 8, TenVaiTro: "Tác giả liên hệ (Corresponding author)", loai: "baibao" },
					{ ID: 9, TenVaiTro: "Tác giả thứ 2", loai: "baibao" },
					{ ID: 10, TenVaiTro: "Tác giả thứ 3", loai: "baibao" },
					{ ID: 11, TenVaiTro: "Tác giả thứ 4", loai: "baibao" },
					{ ID: 12, TenVaiTro: "Tác giả từ vị trí thứ 5", loai: "baibao" },
					{ ID: 5, TenVaiTro: "Chủ biên sách/giáo trình", loai: "sach" },
					{ ID: 6, TenVaiTro: "Tác giả (sách/giáo trình)", loai: "sach" }
				],
				dsTheLoaiBienSoan: [
					{ ID: 1, TenTheLoai: "Sách chuyên khảo" },
					{ ID: 2, TenTheLoai: "Sách tham khảo" },
					{ ID: 3, TenTheLoai: "Giáo trình" },
					{ ID: 4, TenTheLoai: "Giáo trình (dạng song ngữ)" },
					{ ID: 5, TenTheLoai: "Tái bản sách (có bổ sung)" },
					{ ID: 6, TenTheLoai: "Chương sách quốc tế (có ISBN)" },
					{ ID: 7, TenTheLoai: "Từ điển chuyên ngành" },
					{ ID: 8, TenTheLoai: "Biên dịch sách" }
				],
				updateApi: {
					"edit-action": {
						FUN: "LLKH_moSuaAnPham",
						IN: {
							item: "item"
						}
					}
				},
				headers: [
					{ title: "Tác giả", key: "TacGia", value: "TacGia" },
					{ title: "Tên công trình", key: "TenAnPham", value: "TenAnPham" },
					{ title: "Tạp chí / NXB", key: "TenTapChi", value: "TenTapChi" },
					{ title: "Tháng/năm", key: "ThangNam", value: "ThangNam" },
					{ title: "Tập, số, trang", key: "TapSoTrang", value: "TapSoTrang" },
					{ title: "ISSN / ISBN", key: "ISSN", value: "ISSN" },
					{ title: "DOI", key: "DOI", value: "DOI" },
					{ title: "Phân loại", key: "PhanLoai", value: "PhanLoai" },
					{ title: "Điểm", key: "Diem", value: "Diem" },
					{ title: "Vai trò của tôi", key: "VaiTro", value: "VaiTro" },
					{ title: "Tác giả liên hệ", key: "LienHe", value: "LienHe", align: "center", width: 110 },
					{ title: "Trạng thái", key: "TrangThai", value: "TrangThai" },
					{ title: "Chức năng", key: "ctrl-update", value: "ctrl-update", align: "center", width: 80 }
				],
				headersSach: [
					{ title: "Tên sách", key: "Ten", value: "Ten" },
					{ title: "Thể loại", key: "TheLoaiBienSoan", value: "TheLoaiBienSoan" },
					{ title: "Nơi phát hành / ISBN", key: "NoiPhatHanh", value: "NoiPhatHanh" },
					{ title: "Thời gian phát hành", key: "ThoiGianPhatHanh", value: "ThoiGianPhatHanh" },
					{ title: "Vai trò", key: "VaiTro", value: "VaiTro" },
					{ title: "Trạng thái kê khai", key: "TrangThaiDuyet", value: "TrangThaiDuyet" }
				]
			}
		},
		created: function () {
			var self = this
			window.LLKH_instance = self
			window.LLKH_moSuaAnPham = function (arg) {
				var raw = arg && arg.item ? (arg.item.raw || arg.item) : (arg && arg.raw ? arg.raw : arg)
				if (!raw) return
				self.moSua(null, { item: raw })
			}
			if (typeof vueData !== "undefined") {
				vueData.LLKH_moSuaAnPham = window.LLKH_moSuaAnPham
			}
		},
		mounted: function () {
			var self = this
			window.LLKH_instance = self
			window.LLKH_moSuaAnPham = function (arg) {
				var raw = arg && arg.item ? (arg.item.raw || arg.item) : (arg && arg.raw ? arg.raw : arg)
				if (!raw) return
				self.moSua(null, { item: raw })
			}
			if (typeof vueData !== "undefined") {
				vueData.LLKH_moSuaAnPham = window.LLKH_moSuaAnPham
			}
		},
		beforeUnmount: function () {
			if (window.LLKH_instance === this) {
				delete window.LLKH_instance
				delete window.LLKH_moSuaAnPham
			}
		},
		computed: {
			dsVaiTroLoc: function () {
				var loai = this.form.LoaiAnPhamID === 6 ? "sach" : "baibao"
				return this.dsVaiTro.filter(function (v) { return v.loai === loai })
			},
			nhom: function () {
				var L = window.LLKH, thuTu = ["Tạp chí quốc tế (WoS/Scopus)", "Hội thảo quốc tế", "Tạp chí trong nước", "Hội thảo trong nước", "Sách, giáo trình, chương sách", "Khác"]
				var groups = {}
				this.d.congTrinh.forEach(function (c) {
					var r = Object.assign({}, c, {
						TacGia: L.show(c.TacGia),
						TenTapChi: c.TenSachChuaChuong ? (c.TenSachChuaChuong + (c.TenTapChi ? " (NXB: " + c.TenTapChi + ")" : "")) : L.show(c.TenTapChi),
						ISSN: L.show(c.ISSN),
						TapSoTrang: L.show(c.TapSoTrang),
						ThangNam: c.ThangDang ? (c.ThangDang < 10 ? "0" : "") + c.ThangDang + "/" + c.NamDangBai : c.NamDangBai,
						DOI: L.isDoi(c.DuongDanBaiBao) ? c.DuongDanBaiBao : L.CHUA_NHAP,
						PhanLoai: L.show(c.LoaiAnPhamID === 6 ? (c.TheLoaiSach || c.TenLoaiSubAnPham) : (c.TenLoaiSubAnPham || c.TenLoaiDanhMucTapChi)),
						Diem: L.show(c.DiemHoiDong),
						VaiTro: c.TenVaiTro || L.CHUA_NHAP,
						LienHe: c.Is_TacGiaLienHe === true ? "✅" : "",
						"ctrl-update": 1
					})
					;(groups[c.NhomHienThi] = groups[c.NhomHienThi] || []).push(r)
				})
				return thuTu.filter(function (t) { return groups[t] }).map(function (t) { return { ten: t, rows: groups[t] } })
			},
			sach: function () {
				var L = window.LLKH
				return this.d.sachKeKhai.map(function (s) {
					return Object.assign({}, s, {
						TheLoaiBienSoan: L.show(s.TheLoaiBienSoan), NoiPhatHanh: L.show(s.NoiPhatHanh),
						ThoiGianPhatHanh: L.show(s.ThoiGianPhatHanh), VaiTro: L.show(s.VaiTro)
					})
				})
			}
		},
		methods: {
			moSua: function (evt, row) {
				var raw = row && row.item ? (row.item.raw || row.item) : (evt && evt.item ? (evt.item.raw || evt.item) : (evt && evt.raw ? evt.raw : (evt && evt.AnPhamID ? evt : (row && row.AnPhamID ? row : null))))
				if (!raw) return
				var L = window.LLKH
				this.form = {
					AnPhamID: raw.AnPhamID,
					TenAnPham: raw.TenAnPham,
					TenTapChi: raw.TenTapChi,
					NamDangBai: raw.NamDangBai,
					LoaiAnPhamID: raw.LoaiAnPhamID,
					TapSoTrang: raw.TapSoTrang && raw.TapSoTrang !== L.CHUA_NHAP ? raw.TapSoTrang : "",
					ThangDang: raw.ThangDang || null,
					VaiTroID: raw.VaiTroID || null,
					Is_TacGiaLienHe: raw.Is_TacGiaLienHe === true,
					TheLoaiBienSoanID: raw.TheLoaiBienSoanID || null,
					DoiLink: raw.DuongDanBaiBao && raw.DuongDanBaiBao !== L.CHUA_NHAP ? raw.DuongDanBaiBao : "",
					TenSachChuaChuong: raw.TenSachChuaChuong || ""
				}
				this.dialogSua = true
			},
			luuChiTiet: function () {
				var self = this
				self.dangLuu = true
				var payload = {
					AnPhamID: self.form.AnPhamID,
					TapSoTrang: self.form.TapSoTrang || null,
					ThangDang: self.form.ThangDang || null,
					VaiTroID: self.form.VaiTroID || null,
					Is_TacGiaLienHe: self.form.Is_TacGiaLienHe ? 1 : 0,
					TheLoaiBienSoanID: self.form.LoaiAnPhamID === 6 ? (self.form.TheLoaiBienSoanID || null) : null,
					DoiLink: self.form.DoiLink || null,
					TenSachChuaChuong: self.form.LoaiAnPhamID === 6 && self.form.TheLoaiBienSoanID === 6 ? (self.form.TenSachChuaChuong || null) : null
				}
				ajaxCALL("/HDKH_LLKH_AnPham_ChiTiet_Save", payload, function (res) {
					self.dangLuu = false
					self.dialogSua = false
					if (typeof Vue !== "undefined" && Vue.$toast) {
						Vue.$toast.success("Đã lưu thông tin chi tiết bài báo", { position: "top" })
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
			}
		},
		watch: {
			nhom: {
				immediate: true,
				handler: function (v) { this.mo = v.map(function (g) { return g.ten }) }
			}
		}
	}
</script>