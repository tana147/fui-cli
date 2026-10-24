<template>
	<uc-llkh-muc title="III. Quá trình công tác" nguon="HRM" anchor="coban-III"
		:actions="[{ label: 'Thêm công tác ngoài LHU', icon: 'mdi-plus', disabled: true, tooltip: 'Chức năng đang hoàn thiện trên HRM' }, { label: 'Lịch sử', icon: 'mdi-history', disabled: true, tooltip: 'Do Phòng TCNS quản lý' }]">
		<div class="text-subtitle-2 text-medium-emphasis mb-1">
			Tại Trường Đại học Lạc Hồng
			<v-icon size="x-small" v-tooltip="'Do Phòng TCNS quản lý'">mdi-lock-outline</v-icon>
		</div>
		<f-table :items="rows" :headers="headers" :excel="false"></f-table>
		<div class="text-subtitle-2 text-medium-emphasis mt-4 mb-1">Trước khi về LHU</div>
		<uc-llkh-info :items="[{ label: 'Quá trình công tác ngoài LHU', value: null, ns: true, why: lyDo, cols: 12 }]"></uc-llkh-info>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { congTac: [] } } }
		},
		data: function () {
			return {
				lyDo: window.LLKH.LY_DO.noStore,
				headers: [
					{ title: "Thời gian", key: "ThoiGian" },
					{ title: "Đơn vị", key: "TenPB" },
					{ title: "Chức vụ", key: "TenChucVu" },
					{ title: "Hình thức", key: "TenTrangThaiNVPB" },
					{ title: "Công việc đảm nhiệm", key: "CongViec" }
				]
			}
		},
		computed: {
			rows: function () {
				var L = window.LLKH
				return this.d.congTac.map(function (c) {
					return Object.assign({}, c, {
						ThoiGian: L.my(c.NgayLamViec) + " – " + (c.NgayNghiViec ? L.my(c.NgayNghiViec) : "nay"),
						TenChucVu: L.show(c.TenChucVu),
						CongViec: L.KHONG_LUU
					})
				})
			}
		}
	}
</script>