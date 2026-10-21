<template>
	<uc-llkh-muc title="II. Quá trình đào tạo" nguon="HRM" anchor="coban-II"
		note="Gồm cả học hàm GS/PGS. Năm tốt nghiệp lấy theo ngày cập nhật bằng trong HRM (cần TCNS xác nhận)."
		:actions="[{ label: 'Thêm', icon: 'mdi-plus', disabled: true, tooltip: 'Do Phòng TCNS quản lý' }, { label: 'Lịch sử', icon: 'mdi-history', disabled: true, tooltip: 'Do Phòng TCNS quản lý' }]">
		<f-table :items="rows" :headers="headers" :excel="false"></f-table>
		<div class="text-subtitle-2 text-medium-emphasis mt-4 mb-1">Ngoại ngữ – Tin học – Chứng chỉ</div>
		<f-table :items="rowsCC" :headers="headersCC" :excel="false"></f-table>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { daoTao: [], hocHam: [], chungChi: [] } } }
		},
		data: function () {
			return {
				headers: [
					{ title: "Bậc", key: "TenBac" },
					{ title: "Trình độ", key: "TenTrinhDo" },
					{ title: "Ngành / chuyên ngành", key: "TenChuyenNganh" },
					{ title: "Cơ sở đào tạo", key: "TenTruongDH" },
					{ title: "Nước", key: "NuocDaoTao" },
					{ title: "Hình thức", key: "TenLHDT" },
					{ title: "Ngày bắt đầu", key: "NgayBatDau" },
					{ title: "Ngày cấp bằng", key: "NgayCap" },
					{ title: "Học lực", key: "XepLoai" },
					{ title: "Tên luận văn / luận án", key: "LuanAn" }
				],
				headersCC: [
					{ title: "Loại", key: "TenLoaiChungChi" },
					{ title: "Chứng chỉ", key: "TenChungChi" },
					{ title: "Điểm / mức độ", key: "Diem" },
					{ title: "Số hiệu", key: "SoHieuBang" },
					{ title: "Nơi cấp", key: "NoiCap" },
					{ title: "Ngày cấp", key: "NgayCapCC" }
				]
			}
		},
		computed: {
			rows: function () {
				var L = window.LLKH
				return this.d.hocHam.concat(this.d.daoTao).map(function (r) {
					var coLuanAn = r.Bac === "ThS" || r.Bac === "TS"
					return Object.assign({}, r, {
						TenChuyenNganh: L.show(r.TenChuyenNganh),
						TenTruongDH: L.show(r.TenTruongDH),
						NuocDaoTao: L.show(r.NuocDaoTao),
						TenLHDT: L.show(r.TenLHDT),
						XepLoai: r.XepLoai && r.XepLoai !== "Không XĐ" ? r.XepLoai : L.CHUA_NHAP,
						NgayCap: L.show(L.dmy(r.NgayCapBang)),
						NgayBatDau: L.KHONG_LUU,
						LuanAn: coLuanAn ? L.KHONG_LUU : ""
					})
				})
			},
			rowsCC: function () {
				var L = window.LLKH
				return this.d.chungChi.map(function (c) {
					return Object.assign({}, c, {
						Diem: L.show(c.Diem), SoHieuBang: L.show(c.SoHieuBang), NoiCap: L.show(c.NoiCap),
						NgayCapCC: L.show(L.dmy(c.NgayCap))
					})
				})
			}
		}
	}
</script>