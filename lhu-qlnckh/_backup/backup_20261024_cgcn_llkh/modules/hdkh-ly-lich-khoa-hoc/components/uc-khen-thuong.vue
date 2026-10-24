<template>
	<uc-llkh-muc title="IV. Giải thưởng & khen thưởng" nguon="HRM" anchor="coban-IV"
		note="Theo thiết kế, người dùng tự khai giải thưởng và khen thưởng bên HRM. Hiện HRM chưa có nơi lưu phần tự khai."
		:actions="[{ label: 'Thêm', icon: 'mdi-plus', disabled: true, tooltip: 'Chức năng đang hoàn thiện trên HRM' }, { label: 'Lịch sử', icon: 'mdi-history', disabled: true, tooltip: 'Do Phòng TCNS quản lý' }]">
		<uc-llkh-info :items="items"></uc-llkh-info>
		<div class="text-subtitle-2 text-medium-emphasis mt-4 mb-1">
			Tham khảo: cuộc thi KH&CN đã đề nghị khen thưởng tại hệ thống NCKH
		</div>
		<f-table :items="rows" :headers="headers" :excel="false"></f-table>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { cuocThi: [] } } }
		},
		data: function () {
			var L = window.LLKH
			return {
				items: [
					{ label: "Danh hiệu thi đua (TCNS công nhận)", value: null, ns: true, why: L.LY_DO.hrmMigrating, cols: 6 },
					{ label: "Giải thưởng, khen thưởng tự khai", value: null, ns: true, why: L.LY_DO.noStore, cols: 6 }
				],
				headers: [
					{ title: "Tên công trình / giải pháp", key: "TenCuocThi_CongTrinh" },
					{ title: "Cấp cuộc thi", key: "CapDo" },
					{ title: "Đạt giải", key: "Giai" },
					{ title: "Nhóm tác giả", key: "NhomTacGia" },
					{ title: "Vai trò", key: "VaiTro" },
					{ title: "Số QĐ", key: "SoQuyetDinh_VanBang" },
					{ title: "Ngày", key: "Ngay" }
				]
			}
		},
		computed: {
			rows: function () {
				var L = window.LLKH
				return this.d.cuocThi.map(function (c) {
					return Object.assign({}, c, { SoQuyetDinh_VanBang: L.show(c.SoQuyetDinh_VanBang), Ngay: L.show(L.dmy(c.NgayBanHanh)) })
				})
			}
		}
	}
</script>