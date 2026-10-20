<template>
	<v-row style="margin: 0">
		<v-col cols="12" style="text-align:center" class="mt-5">
			<p class="text-h4 primary--text font-weight-bold" :class="vueData.mode ? 'white--text' : 'primary--text'">
				KHOA
				HỌC CÔNG NGHỆ TRƯỜNG ĐẠI HỌC LẠC HỒNG</p>
		</v-col>
		<v-col cols="12" class="py-0">
			<v-card class="elevation-0 rounded-sm pa-2" style="border: 0.8px solid #8080803d">
				<v-card-title class="d-flex ga-2 justify-space-between pa-0">
					<v-tabs v-model="tab">
						<v-tab v-for="year in ['2025', '2026']" :key="year" :href="'#' + year">
							{{ year }}
						</v-tab>
					</v-tabs>
					<v-tabs-items v-model="tab" style="width:100%">
						<v-tab-item v-for="year in ['2025', '2026']" :key="year" :value="year">
							<div class="d-flex flex-column ga-2" style="width:100%">
								<div class="d-flex ga-2 align-center" style="width:100%">
									<span class="primary--text" style="word-break: break-word;">CHỈ SỐ ẤN PHẨM ĐƯỢC ĐĂNG
										TRONG
										NĂM
										{{ year }}:</span>
								</div>
								<div style="width:100%">
									<v-row dense>
										<v-col cols="12" md="4">
										<uc-card-item title="Tổng số:"
											:description="((vueData && vueData.SoBaiDangQT && vueData.SoBaiDangQT[year]) ? vueData.SoBaiDangQT[year].length : 0) + (parseInt(HDGSNNFormula && HDGSNNFormula[year]) || 0)"
											trailingIcon="mdi-earth" styleDescription="font-size: 20px "
											styleTitle="font-size: 18px !important" :isCustom='true'
											style="background-color:rgb(228 240 245)"></uc-card-item>
										</v-col>
										<v-col cols="12" md="4">
											<uc-card-item title="WoS/Scopus:"
												:description="vueData.SoBaiDangQT[year]?.length"
												trailingIcon="mdi-earth"
												styleDescription="font-size: 20px ; color:white !important"
												styleTitle="font-size: 18px !important; color:white !important"
												:isCustom='true' style="background-color: rgb(241 2 2);"></uc-card-item>
										</v-col>
										<v-col cols="12" md="4">
											<uc-card-item title="Hội Đồng Giáo Sư Nhà Nước:"
												:description="HDGSNNFormula[year] ?? '-'" trailingIcon="mdi-earth"
												styleDescription="font-size: 20px ; color:white !important"
												styleTitle="font-size: 18px !important; color:white !important"
												:isCustom='true' style="background-color: rgb(241 2 2);"></uc-card-item>
										</v-col>
									</v-row>

								</div>

								<div class="d-flex ga-2">
									<v-chip color="primary" @click="onOpenModalPhanLoai(year)">Hội thảo: {{
										vueData.SoBaiDangKYHT[year]?.length
									}}</v-chip>
									<v-chip color="primary" @click="onOpenModalPhanLoai(year)">Sách: {{
										vueData.SoBaiDangSach[year]?.length
									}}</v-chip>
									<v-chip color="primary" @click="onOpenModalPhanLoai(year)">Tạp chí trong nước: {{
										vueData.TongSoBaiDang[year]?.filter(ap => ap.LoaiAnPhamID == 3 && ap.LoaiSubAnPhamID == 8)?.length
										}}</v-chip>
									<v-chip color="primary" @click="onOpenModalPhanLoai(year)">Tạp chí khoa học Lạc Hồng
										(HĐGSNN): {{
											vueData.SoBaiDangTapChiKHLH_GSNN[year]?.length
										}}</v-chip>
									<v-chip color="primary" @click="onOpenModalPhanLoai(year)">Tạp chí khoa học Lạc Hồng
										(Khác):
										{{ vueData.SoBaiDangTCLH[year]?.length }}</v-chip>
								</div>
							</div>
						</v-tab-item>
					</v-tabs-items>
				</v-card-title>
				<v-card-text style="height: 350px;">
					<uc-chart ref="chartLoaiAnPham" type="bar" v-if="!vueData.isLoadingChartLoaiAnPham"
						:data="DataLoaiAnPham" :options="optionLoaiAnPham" :key="vueData.keyComp"></uc-chart>
				</v-card-text>
			</v-card>
		</v-col>
		<!-- <v-col cols="12" class="py-0">
			<uc-hoat-dong-khoa-hoc />

		</v-col> -->
		<v-col cols="12" style="display: flex; justify-content:space-between; align-items:center" class="py-0">
			<p class="mb-0 text-h6 font-weight-bold " :class="vueData.mode ? 'white--text' : 'primary--text'">I. Chỉ số
				hoạt
				động Khoa học Công nghệ Trường Đại học Lạc Hồng.</p>
			<v-switch v-model="vueData.mode" label="Chế độ" color="black" inset></v-switch>
		</v-col>

		<v-col cols="12" class="box">
			<uc-card-item :title="this.SoLieu_KHCN[0].Ten" :description="this.SoLieu_KHCN[0].SL"
				trailingIcon="mdi-earth" styleDescription="font-size: 20px " styleTitle="font-size: 18px !important"
				style="background-color:rgb(228 240 245)" class="boxItem"></uc-card-item>
			<uc-card-item :title="this.SoLieu_KHCN[1].Ten" :description="this.SoLieu_KHCN[1].SL"
				trailingIcon="mdi-file-sign" styleDescription="font-size: 20px " styleTitle="font-size: 18px !important"
				style="background-color:rgb(228 240 245)" class="boxItem"></uc-card-item>
			<uc-card-item :title="this.SoLieu_KHCN[2].Ten" :description="this.SoLieu_KHCN[2].SL"
				trailingIcon="mdi-trophy" styleDescription="font-size: 20px" styleTitle="font-size: 18px !important"
				style="background-color:rgb(228 240 245)" class="boxItem"></uc-card-item>
			<uc-card-item :title="this.SoLieu_KHCN[3].Ten"
				:description="this.SoLieu_KHCN[3].SL_SV + this.SoLieu_KHCN[3].SL_CCS" trailingIcon="mdi-newspaper"
				styleDescription="font-size: 20px " styleTitle="font-size: 18px !important"
				style="background-color:rgb(228 240 245)" class="boxItem"></uc-card-item>
			<uc-card-item :title="this.SoLieu_KHCN[4].Ten" :description="this.SoLieu_KHCN[4].SL"
				trailingIcon="mdi-domain" styleDescription="font-size: 20px " styleTitle="font-size: 18px !important"
				style="background-color:rgb(228 240 245)" class="boxItem"></uc-card-item>
		</v-col>
		<v-col cols="12">
			<p class="mb-3 text-h6 font-weight-bold " :class="vueData.mode ? 'white--text' : 'primary--text'">II. Chỉ số
				hoạt động Khoa học Công nghệ Trường Đại học Lạc Hồng qua các năm.</p>
			<uc-anpham-khenthuong v-if="AnPhamSummary" ref="anpham" :mode="vueData.mode"
				:datachartpiesummary="AnPhamSummary" :datachartlinedetailsummary="AnPhamChartLineDetailSummary"
				:datachartcolumndetailsummary="anphamcolumndetailsummary"
				:datachartpietrongnuoc="AnPhamTrongNuocSummary" :datachartpiequocte="AnPhamQuocTeSummary"
				:optionSummary="optionSummary" :optionDetailSummary="optionDetailSummary"
				:optionTrongNuocSummary="optionTrongNuocSummary" :optionQuocTeSummary="optionQuocTeSummary"
				:plugin="pluginChartPIE"></uc-anpham-khenthuong>
		</v-col>
		<v-col cols="12">
			<uc-cgcn ref="cgcn" v-if="CGCNHopDong" :mode="vueData.mode" :datacharthopdong="CGCNHopDong"
				:datachartdonvitiepnhan="CGCNDonViTiepNhan" :optionHopDong="optionHopDong"
				:optionDonViTiepNhan="optionDonViTiepNhan" :plugin="pluginChartPIE"></uc-cgcn>
		</v-col>
		<v-col cols="12">
			<uc-giaithuong ref="giaithuong" v-if="GiaiThuongSummary" :mode="vueData.mode"
				:giaithuongsummary="GiaiThuongSummary" :giaithuongnamsummary="GiaiThuongNamSummary"
				:plugin="pluginChartPIE">
			</uc-giaithuong>
		</v-col>
		<v-col cols="12">
			<uc-de-tai-nckh @sumnckhsv="emitNCKHSV" @sumkhcn="emitNCKHCCS">
			</uc-de-tai-nckh>
		</v-col>
		<!--
	                <v-col cols="6">
	                    <v-card>
	                        <v-card-title>Vùng 4</v-card-title>
	                        <v-card-text></v-card-text>
	                    </v-card></v-card>
	                </v-col>
	            -->
		<v-col cols="12">
			<div class="d-flex align-center justify-center" style="background-color: #284F9E;padding: 25px 0;">
				<v-row class="d-flex align-center justify-center mobileColumn" style="width:1200px">
					<v-col cols="3">
						<div style="float:right">
							<a href="https://lhu.edu.vn">
								<img src="https://lhu.edu.vn/ViewPage/LHUVNB4/_default/image/Logo_white_Vi.png"
									style="height:130px;margin:auto" alt="Đại học Lạc Hồng">
							</a>
						</div>
					</v-col>
					<v-col cols="7">
						<div class="footerCopyright col-md" style="padding-top:20px;color:#fff;">
							<ul style="list-style-type: none; font-size:18px" class="mobileFontsize">
								<li class="mt-2">
									Trường Đại học Lạc Hồng, Biên Hòa, Đồng Nai, Việt Nam
								</li>
								<li class="mt-2">
									Địa chỉ: Số 10, Huỳnh Văn Nghệ, P. Bửu Long, Tp. Biên Hòa - Tỉnh Đồng Nai
								</li>
								<li class="mt-2">
									Email: <a href="mailto:jslhu@lhu.edu.vn"
										style="color:#fff;font-weight:300;">jslhu@lhu.edu.vn</a>
								</li>
								<li class="mt-2">
									Website: <a href="qlkh.lhu.edu.vn"
										style="color:#fff;font-weight:300;">qlkh.lhu.edu.vn</a>
								</li>
								<li class="mt-2">
									Điện thoại: <a href="tel:02513 952 778" style="color:#fff;font-weight:300;">0251
										3952
										778</a>
								</li>
							</ul>
						</div>
					</v-col>
					<v-col>
					</v-col>
				</v-row>
			</div>
		</v-col>
		<uc-phan-loai-an-pham v-model="isShowModalPhanLoai" v-if="isShowModalPhanLoai"
			:year="year"></uc-phan-loai-an-pham>

	</v-row>
</template>

<script>
	export default {
		props: ["anphamsummary", "sobaidangquocte", "anphamdetailsummary", "anphamcolumndetailsummary", "anphamtrongnuocdetailsummary", "anphamquoctedetailsummary", "cgcnhopdong", "cgcndonvitiepnhan", "giaithuongsummary", "giaithuongnamsummary", "mode", "anphamtheonam", "loaianphamtheonam", "anphamtheonamct1", "anphamtheonamct2"],
	computed: {
		AnPhamSummary: function () {
			this.SoLieu_KHCN[0].SL = this.anphamsummary?.SL_Tong
			return this.anphamsummary
		},
		AnPhamChartLineDetailSummary: function () {
			return this.anphamdetailsummary
		},
		AnPhamTrongNuocSummary: function () {
			return this.anphamtrongnuocdetailsummary
		},
		AnPhamQuocTeSummary: function () {
			return this.anphamquoctedetailsummary
		},
		CGCNHopDong: function () {
			this.SoLieu_KHCN[1].SL = this.cgcnhopdong?.reduce((init, current) => init += current.SL_HD, 0)
			return this.cgcnhopdong
		},
		CGCNDonViTiepNhan: function () {
			this.SoLieu_KHCN[4].SL = this.cgcndonvitiepnhan.length
			return this.cgcndonvitiepnhan
		},
		GiaiThuongSummary: function () {
			this.SoLieu_KHCN[2].SL = this.giaithuongsummary?.reduce((init, current) => init += current.SL_GT, 0)
			return this.giaithuongsummary
		},
		GiaiThuongNamSummary: function () {
			return this.giaithuongnamsummary
		},
		AnPhamTheoNam: function () {
			return this.anphamtheonam
		},
		LoaiAnPhamTheoNam: function () {
			return this.loaianphamtheonam
		},
		AnPhamTheoNamCT1: function () {
			return this.anphamtheonamct1
		},
		AnPhamTheoNamCT2: function () {
			return this.anphamtheonamct2
		},
		DataLoaiAnPham: function () {

			return {
				labels: ['WoS/Scopus', 'Hội Đồng Giáo Sư Nhà Nước','Tạp chí trong nước', 'Hội thảo', 'Sách', 'Tạp chí Khoa học Lạc Hồng (HĐGSNN)', 'Tạp chí Khoa học Lạc Hồng (Khác)'],
				datasets: [
					{
						label: '2025',
						data: [
							this.sobaidangquocte[2025]?.length ?? 0,
							this.HDGSNNFormula[2025] ?? 0,
							vueData.TongSoBaiDang[2025]?.filter(ap => ap.LoaiAnPhamID == 3 && ap.LoaiSubAnPhamID == 8)?.length,
							(vueData.SoBaiDangKYHTTN[2025]?.length ?? 0) + (vueData.SoBaiDangKYHTQT[2025]?.length ?? 0),
							vueData.SoBaiDangSach[2025]?.length ?? 0,
							vueData.SoBaiDangTapChiKHLH_GSNN[2025]?.length ?? 0,
							vueData.SoBaiDangTCLH[2025]?.length ?? 0
						],
						backgroundColor: ['rgba(54, 162, 235, 0.5)',
							'rgba(255, 99, 132, 0.5)',
							'rgba(75, 192, 192, 0.5)',
							'rgba(255, 159, 64, 0.5)',
							'rgba(255, 205, 86, 0.5)',
							'rgba(153, 102, 255, 0.5)']
					},
					{
						label: '2026',
						data: [
							this.sobaidangquocte[2026]?.length ?? 0,
							this.HDGSNNFormula[2026] ?? 0,
							vueData.TongSoBaiDang[2026]?.filter(ap => ap.LoaiAnPhamID == 3 && ap.LoaiSubAnPhamID == 8)?.length,
							(vueData.SoBaiDangKYHTTN[2026]?.length ?? 0) + (vueData.SoBaiDangKYHTQT[2026]?.length ?? 0),
							vueData.SoBaiDangSach[2026]?.length ?? 0,
							vueData.SoBaiDangTapChiKHLH_GSNN[2026]?.length ?? 0,
							vueData.SoBaiDangTCLH[2026]?.length ?? 0
						],
						backgroundColor: ['rgba(54, 162, 235, 0.5)',
							'rgba(255, 99, 132, 0.5)',
							'rgba(75, 192, 192, 0.5)',
							'rgba(255, 159, 64, 0.5)',
							'rgba(255, 205, 86, 0.5)',
							'rgba(153, 102, 255, 0.5)']
					}
				]
			}
		},
		HDGSNNFormula: function () {
			let sum2025 = this.sobaidangquocte[2025]?.length + vueData.SoBaiDangHDGSNN[2025]?.length + (vueData.SoBaiDangKYHTTN[2025]?.length ?? 0) + (vueData.SoBaiDangKYHTQT[2025]?.length ?? 0) + vueData.SoBaiDangTapChiKHLH_GSNN[2025]?.length + vueData.SoBaiDangSach[2025]?.length * 3
			let sum2026 = this.sobaidangquocte['2026']?.length + vueData.SoBaiDangHDGSNN['2026']?.length + (vueData.SoBaiDangKYHTTN['2026']?.length ?? 0) + (vueData.SoBaiDangKYHTQT['2026']?.length ?? 0) + vueData.SoBaiDangTapChiKHLH_GSNN['2026']?.length + vueData.SoBaiDangSach['2026']?.length * 3
			return { 2025: sum2025 ?? 0, 2026: sum2026 ?? 0 }
		}
	},
	watch: {
		mode: function (val) {
			localStorage.setItem('mode', val)
			const colorWhite = "#FFF"
			const colorGray = "#666"
			//Lấy tất cả các chart trong component
			const chartPieSummary_AnPham = this.$refs.anpham.$refs.chartPieSummary.myChart
			const chartPieTrongNuocSummary_AnPham = this.$refs.anpham.$refs.chartPieTrongNuoc.myChart
			const chartPieQuocTeSummary_AnPham = this.$refs.anpham.$refs.chartPieQuocTe.myChart
			const chartColumnQuocTeSummary_AnPham = this.$refs.anpham.$refs.chartColumn.myChart
			const chartColumnGTHDSummary_CGCN = this.$refs.cgcn.$refs.giatrihopdong.myChart
			const chartColumnSLHDSummary_CGCN = this.$refs.cgcn.$refs.soluonghopdong.myChart
			const chartColumnDonViTiepNhanSummary_CGCN = this.$refs.cgcn.$refs.donvitiepnhan.myChart
			//Chart trong giải thưởng
			const chartColumnGiaiThuong = this.$refs.giaithuong.$refs.chartSoLuongGT?.myChart
			// const chartColumnTableGiaiThuong = this.$refs?.giaithuong?.$refs?.chartTable?.myChart
			const chartColumnNamGiaiThuong = this.$refs.giaithuong.$refs.chartGiaiThuongNam.myChart
			if (val) {
				//Set theme dark
				chartPieSummary_AnPham.options.plugins.title.color = colorWhite
				chartPieSummary_AnPham.options.plugins.legend.labels.color = colorWhite
				chartPieTrongNuocSummary_AnPham.options.plugins.title.color = colorWhite
				chartPieTrongNuocSummary_AnPham.options.plugins.legend.labels.color = colorWhite
				chartPieQuocTeSummary_AnPham.options.plugins.legend.labels.color = colorWhite
				chartPieQuocTeSummary_AnPham.options.plugins.legend.labels.color = colorWhite
				chartColumnQuocTeSummary_AnPham.options.plugins.datalabels.color = colorWhite
				chartColumnQuocTeSummary_AnPham.options.plugins.title.color = colorWhite
				chartColumnQuocTeSummary_AnPham.options.plugins.legend.labels.color = colorWhite
				chartColumnQuocTeSummary_AnPham.options.scales.y.ticks.color = colorWhite
				chartColumnQuocTeSummary_AnPham.options.scales.x.ticks.color = colorWhite
				chartColumnGTHDSummary_CGCN.options.plugins.datalabels.color = colorWhite
				chartColumnGTHDSummary_CGCN.options.plugins.title.color = colorWhite
				chartColumnGTHDSummary_CGCN.options.plugins.legend.labels.color = colorWhite
				chartColumnGTHDSummary_CGCN.options.scales.y.ticks.color = colorWhite
				chartColumnGTHDSummary_CGCN.options.scales.x.ticks.color = colorWhite
				chartColumnSLHDSummary_CGCN.options.plugins.datalabels.color = colorWhite
				chartColumnSLHDSummary_CGCN.options.plugins.title.color = colorWhite
				chartColumnSLHDSummary_CGCN.options.plugins.legend.labels.color = colorWhite
				chartColumnSLHDSummary_CGCN.options.scales.y.ticks.color = colorWhite
				chartColumnSLHDSummary_CGCN.options.scales.x.ticks.color = colorWhite
				chartColumnDonViTiepNhanSummary_CGCN.options.plugins.datalabels.color = colorWhite
				chartColumnDonViTiepNhanSummary_CGCN.options.plugins.title.color = colorWhite
				chartColumnDonViTiepNhanSummary_CGCN.options.plugins.legend.labels.color = colorWhite
				chartColumnDonViTiepNhanSummary_CGCN.options.scales.y.ticks.color = colorWhite
				chartColumnDonViTiepNhanSummary_CGCN.options.scales.x.ticks.color = colorWhite
				//Giải thưởng
				chartColumnGiaiThuong.options.plugins.datalabels.color = colorWhite
				chartColumnGiaiThuong.options.plugins.title.color = colorWhite
				chartColumnGiaiThuong.options.plugins.legend.labels.color = colorWhite
				chartColumnGiaiThuong.options.scales.y.ticks.color = colorWhite
				chartColumnGiaiThuong.options.scales.x.ticks.color = colorWhite
				// if (chartColumnTableGiaiThuong) {
				//     chartColumnTableGiaiThuong.options.plugins.datalabels.color = colorWhite
				//     chartColumnTableGiaiThuong.options.plugins.title.color = colorWhite
				//     chartColumnTableGiaiThuong.options.plugins.legend.labels.color = colorWhite
				//     chartColumnTableGiaiThuong.options.scales.y.ticks.color = colorWhite
				//     chartColumnTableGiaiThuong.options.scales.x.ticks.color = colorWhite
				// }
				chartColumnNamGiaiThuong.options.plugins.datalabels.color = colorWhite
				chartColumnNamGiaiThuong.options.plugins.title.color = colorWhite
				chartColumnNamGiaiThuong.options.plugins.legend.labels.color = colorWhite
				chartColumnNamGiaiThuong.options.scales.y.ticks.color = colorWhite
				chartColumnNamGiaiThuong.options.scales.x.ticks.color = colorWhite
			} else {
				//Set theme light
				chartPieSummary_AnPham.options.plugins.title.color = colorGray
				chartPieSummary_AnPham.options.plugins.legend.labels.color = colorGray
				chartPieTrongNuocSummary_AnPham.options.plugins.title.color = colorGray
				chartPieTrongNuocSummary_AnPham.options.plugins.legend.labels.color = colorGray
				chartPieQuocTeSummary_AnPham.options.plugins.legend.labels.color = colorGray
				chartPieQuocTeSummary_AnPham.options.plugins.legend.labels.color = colorGray
				chartColumnQuocTeSummary_AnPham.options.plugins.datalabels.color = colorGray
				chartColumnQuocTeSummary_AnPham.options.plugins.title.color = colorGray
				chartColumnQuocTeSummary_AnPham.options.plugins.legend.labels.color = colorGray
				chartColumnQuocTeSummary_AnPham.options.scales.y.ticks.color = colorGray
				chartColumnQuocTeSummary_AnPham.options.scales.x.ticks.color = colorGray
				chartColumnGTHDSummary_CGCN.options.plugins.datalabels.color = colorGray
				chartColumnGTHDSummary_CGCN.options.plugins.title.color = colorGray
				chartColumnGTHDSummary_CGCN.options.plugins.legend.labels.color = colorGray
				chartColumnGTHDSummary_CGCN.options.scales.y.ticks.color = colorGray
				chartColumnGTHDSummary_CGCN.options.scales.x.ticks.color = colorGray
				chartColumnSLHDSummary_CGCN.options.plugins.datalabels.color = colorGray
				chartColumnSLHDSummary_CGCN.options.plugins.title.color = colorGray
				chartColumnSLHDSummary_CGCN.options.plugins.legend.labels.color = colorGray
				chartColumnSLHDSummary_CGCN.options.scales.y.ticks.color = colorGray
				chartColumnSLHDSummary_CGCN.options.scales.x.ticks.color = colorGray
				chartColumnDonViTiepNhanSummary_CGCN.options.plugins.datalabels.color = colorGray
				chartColumnDonViTiepNhanSummary_CGCN.options.plugins.title.color = colorGray
				chartColumnDonViTiepNhanSummary_CGCN.options.plugins.legend.labels.color = colorGray
				chartColumnDonViTiepNhanSummary_CGCN.options.scales.y.ticks.color = colorGray
				chartColumnDonViTiepNhanSummary_CGCN.options.scales.x.ticks.color = colorGray
				//Giải thưởng
				chartColumnGiaiThuong.options.plugins.datalabels.color = colorGray
				chartColumnGiaiThuong.options.plugins.title.color = colorGray
				chartColumnGiaiThuong.options.plugins.legend.labels.color = colorGray
				chartColumnGiaiThuong.options.scales.y.ticks.color = colorGray
				chartColumnGiaiThuong.options.scales.x.ticks.color = colorGray
				// if (chartColumnTableGiaiThuong) {
				//     chartColumnTableGiaiThuong.options.plugins.datalabels.color = colorGray
				//     chartColumnTableGiaiThuong.options.plugins.title.color = colorGray
				//     chartColumnTableGiaiThuong.options.plugins.legend.labels.color = colorGray
				//     chartColumnTableGiaiThuong.options.scales.y.ticks.color = colorGray
				//     chartColumnTableGiaiThuong.options.scales.x.ticks.color = colorGray
				// }
				chartColumnNamGiaiThuong.options.plugins.datalabels.color = colorGray
				chartColumnNamGiaiThuong.options.plugins.title.color = colorGray
				chartColumnNamGiaiThuong.options.plugins.legend.labels.color = colorGray
				chartColumnNamGiaiThuong.options.scales.y.ticks.color = colorGray
				chartColumnNamGiaiThuong.options.scales.x.ticks.color = colorGray
			}
			//Update chart
			chartPieSummary_AnPham.update()
			chartPieTrongNuocSummary_AnPham.update()
			chartPieQuocTeSummary_AnPham.update()
			chartColumnQuocTeSummary_AnPham.update()
			chartColumnGTHDSummary_CGCN.update()
			chartColumnSLHDSummary_CGCN.update()
			chartColumnDonViTiepNhanSummary_CGCN.update()
			chartColumnGiaiThuong.update()
			// if (chartColumnTableGiaiThuong) {
			// }
			// chartColumnTableGiaiThuong.update()
			chartColumnNamGiaiThuong.update()
		},
	},
	data() {
		return {
			year: 2025,
			optionSummary: {
				responsive: true,
				plugins: {
					title: {
						display: false,
						text: `Tổng bài báo trong nước và quốc tế `,
						font: {
							size: 16,
						}
					},
					legend: {
						position: 'bottom'
					},
					datalabels: {
						color: "#ffffff",
						font: {
							size: 18,
						},
					},
				},
			},
			optionDetailSummary: {
				responsive: true,
				plugins: {
					title: {
						display: false,
						text: 'Chi tiết tổng bài báo trong nước và quốc tế',
						font: {
							size: 16,
						}
					},
					legend: {
						display: false
						// position: 'right',
						// align: 'start',
					},
					datalabels: {
						align: 'top',
						anchor: "end",
						formatter: (value, context) => {
							if (value > 0) {
								return value
							} else {
								return ''
							}
						}
					}
				},
			},
			optionTrongNuocSummary: {
				responsive: true,
				plugins: {
					title: {
						display: false,
						text: `Tổng bài báo trong nước`,
						font: {
							size: 16,
						}
					},
					legend: {
					},
					datalabels: {
						color: "#ffffff",
						font: {
							size: 18,
						},
						formatter: (value, context) => {
							if (value > 5) {
								return value
							} else {
								return ''
							}
						}
					},
				},
			},
			optionQuocTeSummary: {
				responsive: true,
				plugins: {
					title: {
						display: false,
						text: `Tổng bài báo quốc tế`,
						font: {
							size: 16,
						}
					},
					legend: {
						display: true,
					},
					datalabels: {
						color: "#ffffff",
						font: {
							size: 18,
						},
						formatter: (value, context) => {
							if (value > 5) {
								return value
							} else {
								return ''
							}
						}
					},
				},
			},
			optionHopDong: {
				responsive: true,
				scales: {
					y: {
						beginAtZero: true,
						grace: '5%',
					},
				},
				layout: {
					// padding: 45
				},
				plugins: {
					title: {
						display: false,
						text: 'Hợp đồng',
						font: {
							size: 16,
						}
					},
					legend: {
						display: false,
						// position: 'right',
						// align: 'start',
					},
					datalabels: {
						align: 'top',
						anchor: "end",
						formatter: (value, context) => {
							if (value > 0) {
								return value.toLocaleString()
							} else {
								return ''
							}
						}
					}
				},
			},
			optionDonViTiepNhan: {
				responsive: true,
				indexAxis: 'y',
				maintainAspectRatio: false,
				scales: {
					x: {
						beginAtZero: true,
						grace: '100%',
					},
				},
				plugins: {
					title: {
						display: false,
						text: 'Đơn vị tiếp nhận',
						font: {
							size: 16,
						}
					},
					legend: {
						position: 'top',
					},
					datalabels: {
						align: 'right',
						anchor: "end",
						formatter: (value, context) => {
							if (value > 0) {
								return value.toLocaleString()
							} else {
								return ''
							}
						}
					}
				},
			},
			pluginChartPIE: [],
			SoLieu_KHCN: [
				{
					Ten: "Ấn phẩm khoa học công nghệ",
					SL: 0
				},
				{
					Ten: "Chuyển giao công nghệ",
					SL: 0
				}, {
					Ten: "Giải thưởng",
					SL: 0
				}, {
					Ten: "Đề tài nghiên cứu khoa học ",
					SinhVien: "sinh viên",
					CapCoSo: "cấp cơ sở",
					SL_SV: 0,
					SL_CCS: 0
				},
				{
					Ten: "Đối tác, hợp tác doanh nghiệp ",
					SL: 0
				},
			],

			optionLoaiAnPham: {
				responsive: true,
				maintainAspectRatio: false,
				plugins: {
					title: {
						display: false,
						text: `Tổng bài báo quốc tế`,
						font: {
							size: 16,
						}
					},
					legend: {
						display: false // không cần legend nữa
					},
					datalabels: {
						formatter: (value, ctx) => {
							return ctx.dataset?.label ?? value;
						},
						anchor: 'end',
						align: 'top'
					}
				},
			},
			isShowModalPhanLoai: false,
			tab: '2025'
		}
	},
	mounted() {
	},
	methods: {
		emitNCKHSV(val) {
			this.SoLieu_KHCN[3].SL_SV = val
		},
		emitNCKHCCS(val) {
			this.SoLieu_KHCN[3].SL_CCS = val
		},
		onOpenModalPhanLoai(year) {
			this.year = year
			console.log(this.isShowModalPhanLoai)
			this.isShowModalPhanLoai = true
			console.log(this.isShowModalPhanLoai)

		},
		TotalAnPham(year){
			return vueData.SoBaiDangQT[year]?.length + this.HDGSNNFormula[year]
		}
	},
	}
</script>