<template>
	<uc-llkh-muc title="III. Sáng chế, giải pháp hữu ích" nguon="NCKH" anchor="nckh-III"
		note="Nơi cấp văn bằng bổ sung tại Cá nhân › Đề nghị khen thưởng cuộc thi & SHTT.">
		<f-table :items="rows" :headers="headers" :excel="false"></f-table>
	</uc-llkh-muc>
</template>

<script>
	export default {
		props: {
			d: { type: Object, default: function () { return { shtt: [], shttKeKhai: [] } } }
		},
		data: function () {
			return {
				headers: [
					{ title: "Tên sáng chế / giải pháp", key: "Ten" },
					{ title: "Loại", key: "Loai" },
					{ title: "Số văn bằng", key: "SoVanBang" },
					{ title: "Năm cấp", key: "NamCap" },
					{ title: "Nơi cấp", key: "NoiCap" },
					{ title: "Vai trò", key: "VaiTro" },
					{ title: "Đầu ra đề tài", key: "DauRa" },
					{ title: "Minh chứng", key: "MinhChung" },
					{ title: "Nguồn", key: "Nguon" }
				]
			}
		},
		computed: {
			rows: function () {
				var L = window.LLKH
				var a = this.d.shtt.map(function (s) {
					return {
						Ten: s.TenCuocThi_CongTrinh, Loai: L.show(s.LoaiSHTT), SoVanBang: L.show(s.SoQuyetDinh_VanBang),
						NamCap: L.show(L.year(s.NgayBanHanh)), NoiCap: L.show(s.NoiCapVanBang), VaiTro: L.show(s.VaiTro),
						DauRa: s.Is_DauRaDeTaiCoSo ? "Đề tài cấp cơ sở" : "Không đánh dấu",
						MinhChung: s.SoMinhChung ? s.SoMinhChung + " tệp" : L.CHUA_NHAP, Nguon: "Đề nghị khen thưởng KHCN"
					}
				})
				var b = this.d.shttKeKhai.map(function (k) {
					return {
						Ten: L.show(k.Ten), Loai: L.show(k.LoaiSHTT), SoVanBang: L.KHONG_LUU, NamCap: L.KHONG_LUU,
						NoiCap: L.KHONG_LUU, VaiTro: L.show(k.VaiTro), DauRa: "", MinhChung: "", Nguon: "Kê khai giờ NCKH (" + k.TrangThaiDuyet + ")"
					}
				})
				return a.concat(b)
			}
		}
	}
</script>