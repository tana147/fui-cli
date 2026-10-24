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
							<v-chip size="x-small" variant="tonal" :color="m.chuaNhap ? 'error' : 'success'">
								{{ m.chuaNhap ? 'Cần bổ sung ' + m.chuaNhap : 'Đủ' }}</v-chip>
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
					<uc-so-yeu-ly-lich :d="d" @reload="tai"></uc-so-yeu-ly-lich>
					<uc-qua-trinh-dao-tao :d="d"></uc-qua-trinh-dao-tao>
					<uc-qua-trinh-cong-tac :d="d"></uc-qua-trinh-cong-tac>
					<uc-khen-thuong :d="d"></uc-khen-thuong>
					<uc-gia-dinh :d="d"></uc-gia-dinh>
				</v-window-item>

				<v-window-item value="nckh">
					<uc-llkh-muc title="I. Hướng nghiên cứu chính" nguon="NCKH" anchor="nckh-I">
						<v-textarea v-model="huongNC" label="Hướng nghiên cứu chính hiện nay" rows="2" auto-grow
							variant="outlined" density="compact" counter="4000" hide-details="auto"></v-textarea>
						<div class="d-flex justify-end mt-2">
							<v-btn size="small" variant="flat" color="primary" prepend-icon="mdi-content-save"
								:loading="dangLuuHNC" :disabled="huongNC === d.huongNC" @click="luuHuongNC">Lưu</v-btn>
						</div>
					</uc-llkh-muc>
					<uc-de-tai-da-tham-gia :d="d" @reload="tai"></uc-de-tai-da-tham-gia>
					<uc-shtt :d="d" @reload="tai"></uc-shtt>
					<uc-llkh-muc v-if="d.duLieuCu.length" title="Dữ liệu đã khai ở phiên bản cũ (tham khảo)"
						note="Thông tin bạn tự nhập trước đây trong module Lý lịch khoa học cũ, dùng để đối chiếu.">
						<f-table :items="d.duLieuCu" :headers="headersCu" :excel="false"></f-table>
					</uc-llkh-muc>
				</v-window-item>

				<v-window-item value="congtrinh">
					<uc-cong-trinh-khoa-hoc :d="d" @reload="tai"></uc-cong-trinh-khoa-hoc>
				</v-window-item>

			</v-window>

			<v-dialog v-model="xem" fullscreen>
				<v-card variant="flat" class="d-flex flex-column h-100">
					<v-card-title class="d-flex align-center px-3 pt-2 pb-2 text-subtitle-1 font-weight-bold flex-grow-0">
						Xem lý lịch — {{ kt.mau.ten }}
						<v-spacer></v-spacer>
						<v-btn icon="mdi-close" variant="text" @click="dongXem"></v-btn>
					</v-card-title>
					<v-divider></v-divider>
					<div class="d-flex flex-column flex-md-row flex-grow-1 overflow-hidden">
						<div class="d-flex flex-grow-1 bg-grey-lighten-3">
							<v-progress-linear v-if="!pdfUrl" indeterminate color="primary"></v-progress-linear>
							<iframe v-else :src="pdfUrl" width="100%" height="100%" frameborder="0" title="Bản xem trước lý lịch"></iframe>
						</div>
						<v-divider :vertical="$vuetify.display.mdAndUp"></v-divider>
						<div class="d-flex flex-column pa-3 ga-3 overflow-y-auto flex-shrink-0" :style="cotThongTin">
							<div v-if="kt.chuaNhap.length">
								<div class="text-subtitle-2 font-weight-bold text-error mb-2">
									<v-icon size="small" color="error">mdi-alert-circle-outline</v-icon> Cần bổ sung
								</div>
								<div class="d-flex flex-column align-start ga-1">
									<v-chip v-for="t in kt.chuaNhap" :key="t.key" size="small" color="error" variant="outlined"
										prepend-icon="mdi-arrow-right" @click="denMuc(t)">{{ t.label }}</v-chip>
								</div>
							</div>
							<v-alert v-else type="success" variant="tonal" density="compact">Đã đủ thông tin cần khai cho mẫu này.</v-alert>
							<div v-if="nhomKhongLuu.length">
								<div class="text-subtitle-2 font-weight-bold text-medium-emphasis">
									<v-icon size="small">mdi-database-off-outline</v-icon> Chưa có nơi lưu
								</div>
								<div class="text-caption text-medium-emphasis mb-2">Bàn giao phát triển — người dùng chưa thể khai</div>
								<div v-for="g in nhomKhongLuu" :key="g.he" class="mb-2">
									<div class="text-caption font-weight-bold">{{ g.ten }}</div>
									<ul class="text-caption ps-4">
										<li v-for="t in g.items" :key="t.key">{{ t.label }}<span v-if="t.giaTri !== lyDoMacDinh"
												class="font-italic"> ({{ t.giaTri }})</span></li>
									</ul>
								</div>
							</div>
							<v-spacer></v-spacer>
							<div class="d-flex ga-2">
								<v-btn color="primary" variant="flat" prepend-icon="mdi-file-download-outline" :disabled="!pdfUrl"
									@click="taiPDF">Tải PDF</v-btn>
								<v-btn variant="text" @click="dongXem">Đóng</v-btn>
							</div>
						</div>
					</div>
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
				huongNC: "",
				dangLuuHNC: false,
				pdfUrl: "",
				lyDoMacDinh: window.LLKH.LY_DO.noStore,
				headersCu: [
					{ title: "Loại", key: "Loai" },
					{ title: "Nội dung", key: "NoiDung" },
					{ title: "Thời gian", key: "ThoiGian" }
				]

			}
		},
		mounted: function () { this.tai() },
		computed: {
			kt: function () {
				if (!this.d) return { rows: [], thieu: [], chuaNhap: [], khongLuu: [], soDu: 0, tong: 0, mau: {} }
				return window.LLKH.kiemTra(this.mau, this.d)
			},
			nhomKhongLuu: function () {
				var ds = this.kt.khongLuu
				return [{ he: "HRM", ten: "Hệ thống Nhân sự (HRM)" }, { he: "NCKH", ten: "Hệ thống NCKH" }]
					.map(function (g) { return Object.assign({}, g, { items: ds.filter(function (r) { return r.he === g.he }) }) })
					.filter(function (g) { return g.items.length })
			},
			cotThongTin: function () { return this.$vuetify.display.mdAndUp ? "width: 25%" : "" },
			dsMau: function () {
				var d = this.d, L = window.LLKH
				return L.MAU.map(function (m) {
					var k = d ? L.kiemTra(m.ma, d) : { chuaNhap: [], khongLuu: [] }
					return { ma: m.ma, ten: m.ten, chuaNhap: k.chuaNhap.length, khongLuu: k.khongLuu.length }
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
					self.huongNC = self.d.huongNC
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
			luuHuongNC: function () {
				var self = this
				self.dangLuuHNC = true
				ajaxCALL("/HDKH_LLKH_HuongNC_Save", { HuongNghienCuuChinh: self.huongNC }, function () {
					self.d.huongNC = self.huongNC
					self.dangLuuHNC = false
					Vue.$toast.success("Đã lưu hướng nghiên cứu", { position: "top" })
				}, function (xhr) {
					self.dangLuuHNC = false
					showMessage({ title: "Không lưu được", message: xhr.responseJSON ? xhr.responseJSON.Message : "", type: "red" })
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
				var ten = "ly-lich-" + this.mau.toLowerCase() + ".pdf"
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