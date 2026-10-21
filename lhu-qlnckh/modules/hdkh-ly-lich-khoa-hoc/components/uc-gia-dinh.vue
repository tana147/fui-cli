<template>
	<uc-llkh-muc title="V. Gia đình, người báo tin" nguon="HRM" anchor="coban-V"
		note="Dùng cho mẫu Sơ yếu lý lịch."
		:actions="[{ label: 'Thêm', icon: 'mdi-plus' }, { label: 'Lịch sử', icon: 'mdi-history' }]">
		<f-table :items="rows" :headers="headers" :excel="false"></f-table>
		<div class="text-subtitle-2 text-medium-emphasis mt-4 mb-1">Khi cần báo tin cho ai</div>
		<uc-llkh-info :items="[{ label: 'Người báo tin (quan hệ, họ tên, điện thoại, địa chỉ)', value: null, ns: true, why: lyDo, cols: 12 }]"></uc-llkh-info>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { giaDinh: [] } } }
		},
		data: function () {
			return {
				lyDo: window.LLKH.LY_DO.noStore,
				headers: [
					{ title: "Quan hệ", key: "TenLoaiQH" },
					{ title: "Họ và tên", key: "HoTen" },
					{ title: "Năm sinh", key: "NamSinhHT" },
					{ title: "Nghề nghiệp", key: "NgheNghiep" },
					{ title: "Nơi công tác / học tập", key: "NoiCongTac" },
					{ title: "Chỗ ở hiện nay", key: "ChoOHienNay" },
					{ title: "Điện thoại", key: "DienThoai" }
				]
			}
		},
		computed: {
			rows: function () {
				var L = window.LLKH
				return this.d.giaDinh.map(function (g) {
					return Object.assign({}, g, {
						NamSinhHT: L.show(g.NgaySinh ? L.dmy(g.NgaySinh) : g.NamSinh),
						NgheNghiep: L.show(g.NgheNghiep), NoiCongTac: L.show(g.NoiCongTac),
						ChoOHienNay: L.show(g.ChoOHienNay || g.DiaChiLienHe), DienThoai: L.KHONG_LUU
					})
				})
			}
		}
	}
</script>