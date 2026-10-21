<template>
	<div>
		<div class="d-flex align-center flex-wrap ga-2 mb-2">
			<h2 class="text-primary font-weight-bold">LÝ LỊCH KHOA HỌC</h2>
			<v-spacer></v-spacer>
			<v-menu location="bottom end">
				<template v-slot:activator="{ props }">
					<v-btn v-bind="props" variant="flat" color="primary" prepend-icon="mdi-file-eye-outline"
						append-icon="mdi-menu-down" :disabled="!d">Xem lý lịch</v-btn>
				</template>
				<v-list density="compact">
					<v-list-subheader>Chọn mẫu lý lịch</v-list-subheader>
					<v-list-item v-for="m in dsMau" :key="m.ma" @click="moXem(m.ma)">
						<v-list-item-title>{{ m.ten }}</v-list-item-title>
						<template v-slot:append>
							<v-chip size="x-small" variant="tonal" :color="m.thieu ? 'warning' : 'success'">
								{{ m.thieu ? 'Thiếu ' + m.thieu : 'Đủ' }}
							</v-chip>
						</template>
					</v-list-item>
				</v-list>
			</v-menu>
		</div>
		<v-alert v-for="e in loi" :key="e" type="warning" variant="tonal" density="compact" class="mb-2">{{ e }}</v-alert>
		<v-progress-linear v-if="dangTai" indeterminate color="primary" class="mb-2"></v-progress-linear>

		<template v-if="d">
			<v-tabs v-model="tab" color="primary" class="mb-4" show-arrows>
				<v-tab value="coban" prepend-icon="mdi-account-details-outline">
					Thông tin cơ bản
				</v-tab>
				<v-tab value="nckh" prepend-icon="mdi-flask-outline">Nghiên cứu khoa học</v-tab>
				<v-tab value="congtrinh" prepend-icon="mdi-book-open-page-variant-outline">
					Công trình khoa học
					<v-chip size="x-small" variant="tonal" class="ml-2">{{ d.congTrinh.length }}</v-chip>
				</v-tab>
			</v-tabs>

			<v-window v-model="tab">
				<v-window-item value="coban">
					<uc-so-yeu-ly-lich :d="d"></uc-so-yeu-ly-lich>
					<uc-qua-trinh-dao-tao :d="d"></uc-qua-trinh-dao-tao>
					<uc-qua-trinh-cong-tac :d="d"></uc-qua-trinh-cong-tac>
					<uc-khen-thuong :d="d"></uc-khen-thuong>
					<uc-gia-dinh :d="d"></uc-gia-dinh>
				</v-window-item>

				<v-window-item value="nckh">
					<uc-llkh-muc title="I. Hướng nghiên cứu chính" nguon="NCKH" anchor="nckh-I"
						:actions="[{ label: 'Cập nhật', icon: 'mdi-pencil' }, { label: 'Lịch sử', icon: 'mdi-history' }]">
						<uc-llkh-info :items="[{ label: 'Hướng nghiên cứu chính hiện nay', value: d.huongNC, cols: 12 }]"></uc-llkh-info>
					</uc-llkh-muc>
					<uc-de-tai-da-tham-gia :d="d"></uc-de-tai-da-tham-gia>
					<uc-shtt :d="d"></uc-shtt>
					<uc-llkh-muc v-if="d.duLieuCu.length" title="Dữ liệu đã khai ở phiên bản cũ (tham khảo)"
						note="Thông tin bạn tự nhập trước đây trong module Lý lịch khoa học cũ, dùng để đối chiếu.">
						<f-table :items="d.duLieuCu" :headers="headersCu" :excel="false"></f-table>
					</uc-llkh-muc>
				</v-window-item>

				<v-window-item value="congtrinh">
					<uc-cong-trinh-khoa-hoc :d="d"></uc-cong-trinh-khoa-hoc>
				</v-window-item>

			</v-window>

			<v-dialog v-model="xem" fullscreen scrollable>
				<v-card variant="flat">
					<v-card-title class="d-flex align-center px-3 pt-2 pb-3 text-subtitle-1 font-weight-bold">
						Xem lý lịch — {{ kt.mau.ten }}
						<v-spacer></v-spacer>
						<v-btn icon="mdi-close" variant="text" @click="dongXem"></v-btn>
					</v-card-title>
					<v-card-text class="px-3 py-1">
						<div class="d-flex align-center ga-3 mb-2">
							<span class="text-body-2 text-no-wrap">Đủ <b>{{ kt.soDu }}/{{ kt.tong }}</b> trường bắt buộc</span>
							<v-progress-linear :model-value="phanTram" :color="kt.thieu.length ? 'warning' : 'success'" height="8" rounded></v-progress-linear>
						</div>
						<v-alert v-if="kt.thieu.length" type="warning" variant="tonal" density="compact" class="mb-3">
							Bản chính thức chỉ in khi đủ trường bắt buộc. Trong giai đoạn rà soát, bản nháp ghi "Chưa có" ở các ô thiếu. Bấm vào mục để đến chỗ cập nhật:
							<div class="d-flex flex-wrap ga-1 mt-2">
								<v-chip v-for="t in kt.thieu" :key="t.key" size="small" color="error" variant="outlined"
									prepend-icon="mdi-arrow-right" @click="denMuc(t)">{{ t.label }}</v-chip>
							</div>
						</v-alert>
						<v-expansion-panels variant="accordion" class="mb-3">
							<v-expansion-panel title="Bảng kiểm tra chi tiết theo mẫu">
								<v-expansion-panel-text>
									<f-table :items="dongKiemTra" :headers="headersKT" :excel="false"></f-table>
								</v-expansion-panel-text>
							</v-expansion-panel>
						</v-expansion-panels>
						<v-progress-linear v-if="!pdfUrl" indeterminate color="primary"></v-progress-linear>
						<iframe v-else :src="pdfUrl" width="100%" height="900" frameborder="0" title="Bản xem trước lý lịch"></iframe>
					</v-card-text>
					<v-card-actions class="pa-3">
						<v-spacer></v-spacer>
						<v-btn variant="text" @click="dongXem">Đóng</v-btn>
						<v-btn color="primary" variant="flat" prepend-icon="mdi-file-download-outline" @click="taiPDF">
							{{ kt.thieu.length ? 'Tải bản nháp PDF' : 'Tải PDF' }}
						</v-btn>
					</v-card-actions>
				</v-card>
			</v-dialog>
		</template>
	</div>
</template>

<script>
	export default {
		data: function () {
			return {
				vueData: vueData,
				tab: "coban",
				mau: "GV",
				dangTai: false,
				loi: [],
				raw: { hrm: null, nckh: null },
				d: null,
				xem: false,
				pdfUrl: "",
				headersCu: [
					{ title: "Loại", key: "Loai" },
					{ title: "Nội dung", key: "NoiDung" },
					{ title: "Thời gian", key: "ThoiGian" }
				],
				headersKT: [
					{ title: "Thông tin", key: "label" },
					{ title: "Bắt buộc", key: "BatBuoc" },
					{ title: "Tình trạng", key: "TinhTrang" },
					{ title: "Giá trị / lý do thiếu", key: "giaTri" },
					{ title: "Cập nhật tại", key: "ViTri" }
				]
			}
		},
		mounted: function () { this.tai() },
		computed: {
			kt: function () {
				if (!this.d) return { rows: [], thieu: [], soDu: 0, tong: 0 }
				return window.LLKH.kiemTra(this.mau, this.d)
			},
			phanTram: function () { return this.kt.tong ? Math.round(this.kt.soDu * 100 / this.kt.tong) : 0 },
			dsMau: function () {
				var d = this.d, L = window.LLKH
				return L.MAU.map(function (m) { return { ma: m.ma, ten: m.ten, thieu: d ? L.kiemTra(m.ma, d).thieu.length : 0 } })
			},
			dongKiemTra: function () {
				return this.kt.rows.map(function (r) {
					return Object.assign({}, r, {
						BatBuoc: r.batBuoc ? "Bắt buộc" : "In nếu có",
						TinhTrang: r.du ? "Đủ" : "Chưa có",
						ViTri: ({ coban: "Thông tin cơ bản", nckh: "Nghiên cứu khoa học", congtrinh: "Công trình khoa học" })[r.tab] + " › " + r.muc
					})
				})
			}
		},
		methods: {
			tai: function () {
				var self = this, L = window.LLKH, xong = 0
				self.dangTai = true
				self.loi = []
				var ket = function () {
					xong++
					if (xong < 2) return
					self.d = L.normalize(self.raw.hrm, self.raw.nckh)
					self.dangTai = false
				}
				ajaxCALL(L.API_HRM, {}, function (res) { self.raw.hrm = res; ket() }, function (xhr) {
					self.raw.hrm = null
					self.loi.push("Không tải được dữ liệu từ HRM: " + (xhr.responseJSON ? xhr.responseJSON.Message : xhr.statusText))
					ket()
				})
				ajaxCALL(L.API_NCKH, {}, function (res) { self.raw.nckh = res; ket() }, function (xhr) {
					self.raw.nckh = null
					self.loi.push("Không tải được dữ liệu NCKH: " + (xhr.responseJSON ? xhr.responseJSON.Message : xhr.statusText))
					ket()
				})
			},
			moXem: function (ma) {
				var self = this
				self.mau = ma
				self.xem = true
				self.taoXemTruoc()
			},
			taoXemTruoc: function () {
				var self = this
				self.thuHoiPdf()
				if (typeof pdfMake === "undefined") {
					showMessage({ title: "Chưa tải được thư viện in PDF", type: "red" })
					return
				}
				pdfMake.createPdf(window.LLKH.docDefinition(self.mau, self.d)).getBlob(function (blob) {
					self.pdfUrl = URL.createObjectURL(blob)
				})
			},
			thuHoiPdf: function () {
				if (this.pdfUrl) URL.revokeObjectURL(this.pdfUrl)
				this.pdfUrl = ""
			},
			dongXem: function () {
				this.xem = false
				this.thuHoiPdf()
			},
			taiPDF: function () {
				var ten = "ly-lich-" + this.mau.toLowerCase() + (this.kt.thieu.length ? "-ban-nhap" : "") + ".pdf"
				pdfMake.createPdf(window.LLKH.docDefinition(this.mau, this.d)).download(ten)
			},
			denMuc: function (t) {
				this.dongXem()
				this.tab = t.tab
				var id = t.tab + "-" + t.muc.split(".")[0]
				setTimeout(function () {
					var el = document.getElementById(id)
					if (el) el.scrollIntoView({ behavior: "smooth", block: "start" })
				}, 400)
			}
		}
	}
</script>