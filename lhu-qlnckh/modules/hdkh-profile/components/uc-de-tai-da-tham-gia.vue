<template>
	<uc-llkh-muc title="II. Đề tài, dự án" nguon="NCKH" anchor="nckh-II"
		note="Lấy từ đề tài KHCN cấp cơ sở, hội đồng NCKH giảng viên và kê khai giờ NCKH. Đề tài mới khai tại chức năng kê khai."
		:actions="[{ label: 'Kê khai mới', icon: 'mdi-open-in-new' }]">
		<f-table :items="rows" :headers="headers" :excel="false"></f-table>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { deTai: [] } } }
		},
		data: function () {
			return {
				headers: [
					{ title: "Tên đề tài", key: "TenDeTai" },
					{ title: "Mã số", key: "MaSoDeTai" },
					{ title: "Cấp", key: "Cap" },
					{ title: "Lĩnh vực", key: "LinhVuc" },
					{ title: "Thời gian", key: "ThoiGianHT" },
					{ title: "Vai trò", key: "VaiTro" },
					{ title: "Nguồn", key: "Nguon" }
				]
			}
		},
		computed: {
			rows: function () {
				var L = window.LLKH
				return this.d.deTai.map(function (t) {
					return Object.assign({}, t, {
						MaSoDeTai: L.show(t.MaSoDeTai), Cap: L.show(t.Cap), LinhVuc: L.show(t.LinhVuc),
						ThoiGianHT: L.show(t.ThoiGian || t.Nam), VaiTro: L.show(t.VaiTro)
					})
				})
			}
		}
	}
</script>