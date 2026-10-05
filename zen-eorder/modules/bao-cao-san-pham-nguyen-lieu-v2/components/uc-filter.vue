<template>
	<v-row>
		<v-col cols="2">
			<v-select label="Phân hiệu" outlined dense v-model="vueData.PhanHieuID" :items="vueData.DSPhanHieu"
				hide-details item-value="PhanHieuID" item-text="TenPhanHieu" />
		</v-col>
		<v-col cols="2">
			<v-select label="Khu vực" outlined dense v-model="vueData.KhuVucID" :items="vueData.DSKhuVuc" hide-details
				item-value="KhuVucID" item-text="TenKhuVuc" />
		</v-col>
		<v-col cols="3">
			<v-select label="Cửa hàng" outlined dense v-model="vueData.CuaHangID" :items="CuaHangFilter" hide-details
				item-value="CuaHangID" item-text="TenCuaHang" />
		</v-col>

		<v-col cols="3">
			<v-text-field label="Tên sản phẩm" outlined dense v-model="vueData.TenSanPham" hide-details/>
		</v-col>
		<v-col cols="3">
			<v-select label="Sở thích phục vụ" outlined dense v-model="vueData.NhomLienKetChiTietID" :items="vueData.DSNhomLienKetChiTiet" hide-details
				item-value="NhomLienKetChiTietID" item-text="TenNoiBo" />
		</v-col>
		<v-col cols="3">
			<v-select label="Loại nguyên liệu" outlined dense v-model="vueData.NguyenLieuID" :items="vueData.DSNguyenLieu" hide-details
				item-value="NguyenLieuID" item-text="TenNguyenLieu" />
		</v-col>
		
		<!-- Hình thức thời gian -->
		<v-col cols="3">
			<v-select label="Loại thời gian" outlined dense v-model="vueData.HinhThucThoiGian"
				:items="vueData.DSHinhThucThoiGian" hide-details />
		</v-col>
		<!-- 1: Theo giờ -->
		<v-col cols="2" v-if="vueData.HinhThucThoiGian === 1">
			<f-date label="Ngày" outlined dense v-model="vueData.Ngay" :date-add="0" hide-details />
		</v-col>
		<!-- 2: Theo ngày -->
		<v-col cols="2" v-if="vueData.HinhThucThoiGian === 2">
			<f-date label="Từ ngày" outlined dense v-model="vueData.TuNgay" :date-add="0" hide-details />
		</v-col>
		<v-col cols="2" v-if="vueData.HinhThucThoiGian === 2">
			<f-date label="Đến ngày" outlined dense v-model="vueData.DenNgay" :date-add="0" hide-details />
		</v-col>
		<!-- 3: Theo tuần -->
		<v-col cols="2" v-if="vueData.HinhThucThoiGian === 3">
			<v-select label="Năm" outlined dense v-model="vueData.Nam" :items="vueData.DSNam" hide-details />
		</v-col>
		<v-col cols="2" v-if="vueData.HinhThucThoiGian === 3">
			<v-select label="Tháng" outlined dense v-model="vueData.Thang" :items="vueData.DSThang" hide-details />
		</v-col>
		<!-- 4: Theo quý || 5: Theo tháng -->
		<v-col cols="2" v-if="vueData.HinhThucThoiGian === 4 || vueData.HinhThucThoiGian === 5">
			<v-select label="Năm" outlined dense v-model="vueData.Nam" :items="vueData.DSNam" hide-details />
		</v-col>
		<!-- 6: Theo năm -->
		<v-col cols="2" v-if="vueData.HinhThucThoiGian === 6">
			<v-select label="Từ năm" outlined dense v-model="vueData.TuNam" :items="vueData.DSNam" hide-details />
		</v-col>
		<v-col cols="2" v-if="vueData.HinhThucThoiGian === 6">
			<v-select label="Đến năm" outlined dense v-model="vueData.DenNam" :items="vueData.DSNam" hide-details />
		</v-col>
		<v-col cols="2">
			<v-btn color="primary" elevation="0" @click="GetBaoCao()">
				<v-icon left>mdi-filter</v-icon>Tìm
			</v-btn>
		</v-col>
	</v-row>
</template>

<script>
	export default {
		props: [],
		data() {
			return {
				vueData
			}
		},
		mounted() { },
		computed: {
			CuaHangFilter: function () {
				let CuaHangFilter = []
				CuaHangFilter = vueData.DSCuaHang.filter(item => (item.PhanHieuID == (vueData.PhanHieuID == 0 ? item.PhanHieuID : vueData.PhanHieuID)) && (item.KhuVucID == (vueData.KhuVucID == 0 ? item.KhuVucID : vueData.KhuVucID)))
				return CuaHangFilter
			}
		},
		watch: {},
		methods: {
			GetBaoCao() {
				if (vueData.CuaHangID) {
					CALL("getBaoCao")
				}
			}
		},
	}
</script>