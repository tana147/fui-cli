<template>
	<uc-llkh-muc title="I. Bài báo, báo cáo, sách" nguon="NCKH" anchor="congtrinh-I"
		note="Ấn phẩm đã gửi (bỏ bản lưu tạm và bản bị từ chối). Phân loại và điểm do Phòng KHCN duyệt."
		:actions="[{ label: 'Kê khai mới', icon: 'mdi-open-in-new' }, { label: 'Lịch sử', icon: 'mdi-history' }]">
		<div v-if="!nhom.length" class="text-body-2 text-error font-italic">Chưa có công trình nào</div>
		<v-expansion-panels v-else multiple variant="accordion" v-model="mo">
			<v-expansion-panel v-for="g in nhom" :key="g.ten" :value="g.ten">
				<v-expansion-panel-title>
					<span class="font-weight-medium">{{ g.ten }}</span>
					<v-chip size="x-small" class="ml-2" variant="tonal">{{ g.rows.length }}</v-chip>
				</v-expansion-panel-title>
				<v-expansion-panel-text>
					<f-table :items="g.rows" :headers="headers" :excel="false"></f-table>
				</v-expansion-panel-text>
			</v-expansion-panel>
		</v-expansion-panels>
		<template v-if="sach.length">
			<div class="text-subtitle-2 text-medium-emphasis mt-4 mb-1">Sách, giáo trình đã kê khai giờ NCKH</div>
			<f-table :items="sach" :headers="headersSach" :excel="false"></f-table>
		</template>
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
				headers: [
					{ title: "Tác giả", key: "TacGia" },
					{ title: "Tên công trình", key: "TenAnPham" },
					{ title: "Tạp chí / NXB", key: "TenTapChi" },
					{ title: "Năm", key: "NamDangBai" },
					{ title: "Tập, số, trang", key: "TapSoTrang" },
					{ title: "ISSN / ISBN", key: "ISSN" },
					{ title: "DOI", key: "DOI" },
					{ title: "Phân loại", key: "PhanLoai" },
					{ title: "Điểm", key: "Diem" },
					{ title: "Vai trò của tôi", key: "VaiTro" },
					{ title: "Tác giả liên hệ", key: "LienHe" },
					{ title: "Trạng thái", key: "TrangThai" }
				],
				headersSach: [
					{ title: "Tên sách", key: "Ten" },
					{ title: "Thể loại", key: "TheLoaiBienSoan" },
					{ title: "Nơi phát hành / ISBN", key: "NoiPhatHanh" },
					{ title: "Thời gian phát hành", key: "ThoiGianPhatHanh" },
					{ title: "Vai trò", key: "VaiTro" },
					{ title: "Trạng thái kê khai", key: "TrangThaiDuyet" }
				]
			}
		},
		computed: {
			nhom: function () {
				var L = window.LLKH, thuTu = ["Tạp chí quốc tế (WoS/Scopus)", "Hội thảo quốc tế", "Tạp chí trong nước", "Hội thảo trong nước", "Sách, giáo trình, chương sách", "Khác"]
				var groups = {}
				this.d.congTrinh.forEach(function (c) {
					var r = Object.assign({}, c, {
						TacGia: L.show(c.TacGia), TenTapChi: L.show(c.TenTapChi), ISSN: L.show(c.ISSN),
						TapSoTrang: L.CHUA_CO,
						DOI: L.isDoi(c.DuongDanBaiBao) ? c.DuongDanBaiBao : L.CHUA_CO,
						PhanLoai: L.show(c.TenLoaiSubAnPham || c.TenLoaiDanhMucTapChi),
						Diem: L.show(c.DiemHoiDong),
						VaiTro: c.Is_TacGiaChinh ? "Tác giả chính" : "Đồng tác giả",
						LienHe: L.CHUA_CO
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
		watch: {
			nhom: {
				immediate: true,
				handler: function (v) { this.mo = v.map(function (g) { return g.ten }) }
			}
		}
	}
</script>