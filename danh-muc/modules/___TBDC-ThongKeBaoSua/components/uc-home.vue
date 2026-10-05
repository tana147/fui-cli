<template>
	<v-row>
		<v-col cols="12" md="6" class="pr-3">
			<v-card>
				<v-toolbar>

					<v-select max-width="200" class="ma-3" label="Chọn năm" item-value="NamBatDau" item-title="NamHoc"
						:items="dsNamHoc" v-model="nam" density="compact" />
					<v-spacer></v-spacer>
				</v-toolbar>

				<uc-chart-stacked></uc-chart-stacked>
			</v-card>

		</v-col>
		<v-col cols="12" md="6">
			<v-card>
				<v-card-actions>
					<v-row>
						<v-col cols="12" sm="10">
							<h4 style="" class=" mx-2 text-primary">Thống kê danh mục theo tháng</h4>
						</v-col>
					</v-row>
				</v-card-actions>
				<v-data-table style="white-space: nowrap;" fixed-header class="striped-table" hide-default-footer
					items-per-page="-1" :items="raw"></v-data-table>
			</v-card>
		</v-col>
	</v-row>
	<v-divider></v-divider>
	<v-row>
		<v-col cols="6" md="12">
			<div elevation="0">
				<v-toolbar>
					<h4 style="" class=" mx-2 text-primary">Thống kê theo khu</h4>
					<v-select return-object max-width="150" item-title="ThangNam" item-value="ThangNam" class="ma-3"
						label="Chọn tháng" :items="dsThangNamHoc" v-model="thangNamSelected"></v-select>
					<v-spacer></v-spacer>
				</v-toolbar>
				<v-row>
					<v-col cols="12" md="6">
						<v-card>
							<v-toolbar>
								<v-toolbar-title class="text-primary text-subtitle-1">Báo sửa trong tháng theo Khu (Top
									10)</v-toolbar-title>
							</v-toolbar>
							<v-data-table class="striped-table" hide-default-footer items-per-page="-1"
								:items="dsBaoSuaKhu.slice(0, 10)" :headers="headersKhu">
							</v-data-table>
						</v-card>

						<v-card class="my-3">
							<v-toolbar>
								<v-toolbar-title class="text-primary text-subtitle-1">Số lượng hư hỏng không thể sửa
									chữa trong tháng</v-toolbar-title>
							</v-toolbar>
							<v-data-table class="striped-table" hide-default-footer items-per-page="-1"
								:items="dsBaoSuaKhuKhongSuaDuoc" :headers="headersKhu"></v-data-table>
						</v-card>
					</v-col>
					<v-col cols="12" md="6">
						<v-card>

							<uc-chart-khu v-if="dsBaoSuaKhu.length > 0" :rows="dsBaoSuaKhu" :stacked="true" />
							<h5 v-else>Không có dữ liệu</h5>
						</v-card>
					</v-col>
				</v-row>




			</div>
		</v-col>
	</v-row>
	<v-divider></v-divider>
	<v-row>
		<v-col cols="12" md="6">
			<v-card class="px-3">
				<uc-chart-nhanvien :rows="dsNhanVienXuLy"></uc-chart-nhanvien>
			</v-card>
		</v-col>
		<v-col cols="12" md="6">
			<v-card>
				<v-toolbar>
					<h4 class="text-primary ma-3">Thống kê theo nhân viên xử lý</h4>
					<v-spacer>

					</v-spacer>
					<!-- <v-btn color="primary" @click="isOpenChiTietPhong = true">Xem chi tiết</v-btn> -->
				</v-toolbar>

				<!-- Bảng dữ liệu -->
				<v-data-table style="white-space: nowrap;" class="striped-table" :items="dsNhanVienXuLyEdit"
					hide-default-footer items-per-page="-1" density="compact" :loading="loadingNhanVienXuLy">

				</v-data-table>
			</v-card>
		</v-col>
	</v-row>
	<v-divider></v-divider>
	<v-row>
		<v-col cols="6" md="12">
			<v-card>
				<v-toolbar>
					<h4 class="text-primary ma-3">Thống kê theo phòng học</h4>
					<v-spacer>

					</v-spacer>
					<v-btn color="primary" @click="isOpenChiTietPhong = true">Xem chi tiết</v-btn>
				</v-toolbar>

				<!-- Bảng dữ liệu -->
				<v-data-table class="striped-table" :headers="headersPhong" :items="dsBaoSuaPhongTop"
					:search="searchPhong" hide-default-footer items-per-page="-1" density="compact"
					:loading="loadingPhongTop">
					<!-- Vẽ toàn bộ hàng -->
					<template #item="{ item }">
						<tr>
							<!-- Cột Vị trí phòng -->
							<td class="td-cell font-weight-medium">
								{{ item['Vị trí phòng'] }}
							</td>

							<!-- 12 cột Tháng-Năm -->
							<td v-for="month in monthKeys" :key="'m-'+month" class="td-cell text-center">
								<v-tooltip location="top">
									<template #activator="{ props }">
										<div v-bind="props">
											{{ item[month] ? item[month] : 0 }}
										</div>
									</template>
									<template #default>
										<div style="max-height:300px; overflow-y:auto;">
											<div class="font-weight-medium mb-1">Chi tiết {{ month }}</div>
											<div v-if="parseDetail(item['ChiTiet ' + month]).length">
												<div v-for="(dm, i) in parseDetail(item['ChiTiet ' + month])" :key="i">
													<p>{{ dm.TenDanhMuc }} - [{{ dm.SoLuong }}]</p>
													<v-divider />
												</div>
											</div>
											<div v-else class="text-grey text-caption">Không có dữ liệu chi tiết</div>
										</div>
									</template>
								</v-tooltip>
							</td>

							<!-- Cột Tổng -->
							<td class="td-cell td-total text-center">
								<v-tooltip location="top">
									<template #activator="{ props }">
										<div v-bind="props">
											{{ item['Tổng'] ?? 0 }}
										</div>
									</template>
									<template #default>
										<div style="max-height:300px; overflow-y:auto;">
											<div class="font-weight-medium mb-1">Chi tiết lũy kế</div>
											<div v-if="parseDetail(item['ChiTiet Tổng']).length">
												<div v-for="(dm, i) in parseDetail(item['ChiTiet Tổng'])" :key="i">
													<p>{{ dm.TenDanhMuc }} - [{{ dm.SoLuong }}]</p>
													<v-divider />
												</div>
											</div>
											<div v-else class="text-grey text-caption">Không có dữ liệu chi tiết</div>
										</div>
									</template>
								</v-tooltip>
							</td>
						</tr>
					</template>
				</v-data-table>
			</v-card>
		</v-col>

	</v-row>



	<v-dialog v-model="isOpenChiTietPhong">
		<v-card>
			<v-card-actions>
				<v-row>
					<v-col cols="12" sm="8">
						<h4 style="" class=" mx-2 text-primary">Thống kê theo phòng học</h4>
					</v-col>

					<v-col cols="12" md="2">
						<v-text-field class="" v-model="searchPhong" density="compact" label="Search"
							prepend-inner-icon="mdi-magnify" variant="solo-filled" flat hide-details
							single-line></v-text-field>
					</v-col>
					<v-spacer></v-spacer>

					<v-btn size="small" icon="mdi-close" @click="isOpenChiTietPhong = false"></v-btn>

				</v-row>
			</v-card-actions>
			<v-data-table class="striped-table" :headers="headersPhong" :items="dsBaoSuaPhong" :search="searchPhong"
				items-per-page="30" :loading="loadingPhongAll">
				<!-- 12 cột tháng -->
				<!-- Tháng 1 -->
				<template #item="{ item }">
					<tr>
						<!-- Cột Vị trí phòng -->
						<td class="td-cell font-weight-medium">
							{{ item['Vị trí phòng'] }}
						</td>

						<!-- 12 cột Tháng-Năm -->
						<td v-for="month in monthKeys" :key="'m-'+month" class="td-cell text-center">
							<v-tooltip location="top">
								<template #activator="{ props }">
									<div v-bind="props">
										{{ item[month] ?? 0 }}
									</div>
								</template>
								<template #default>
									<div style="max-height:300px; overflow-y:auto;">
										<div class="font-weight-medium mb-1">Chi tiết {{ month }}</div>
										<div v-if="parseDetail(item['ChiTiet ' + month]).length">
											<div v-for="(dm, i) in parseDetail(item['ChiTiet ' + month])" :key="i">
												<p>{{ dm.TenDanhMuc }} - [{{ dm.SoLuong }}]</p>
												<v-divider />
											</div>
										</div>
										<div v-else class="text-grey text-caption">Không có dữ liệu chi tiết</div>
									</div>
								</template>
							</v-tooltip>
						</td>

						<!-- Cột Tổng -->
						<td class="td-cell td-total text-center">
							<v-tooltip location="top">
								<template #activator="{ props }">
									<div v-bind="props">
										{{ item['Tổng'] ?? 0 }}
									</div>
								</template>
								<template #default>
									<div style="max-height:300px; overflow-y:auto;">
										<div class="font-weight-medium mb-1">Chi tiết lũy kế</div>
										<div v-if="parseDetail(item['ChiTiet Tổng']).length">
											<div v-for="(dm, i) in parseDetail(item['ChiTiet Tổng'])" :key="i">
												<p>{{ dm.TenDanhMuc }} - [{{ dm.SoLuong }}]</p>
												<v-divider />
											</div>
										</div>
										<div v-else class="text-grey text-caption">Không có dữ liệu chi tiết</div>
									</div>
								</template>
							</v-tooltip>
						</td>
					</tr>
				</template>
			</v-data-table>
		</v-card>
	</v-dialog>

</template>

<script>
	export default {
		name: 'StackedByCategory',
		data() {
			let y = new Date().getFullYear()
			let m = new Date().getMonth()
			return {
				isOpenChiTietPhong: false,
				chart: null,
				nam: y,
				searchPhong: null,
				year: y,
				month: m + 1,
				years: Array.from({ length: 6 }, (_, i) => y - i),
				monthFrom: 1,
				monthTo: 12,
				thangNamSelected: null,
				dsNamHoc: [],
				namHocHienTai: null,
				dsNhanVienXuLyEdit: [],
				loadingPhongAll: false,
				loadingNhanVienXuLy: false,
				loadingPhongTop: false,
				dsNhanVienXuLy: [],
				dsThangNamHoc: [],
				dsBaoSuaPhong: [],
				dsBaoSuaPhongTop: [],
				dsBaoSuaKhu: [],
				dsBaoSuaKhuKhongSuaDuoc: [],
				raw: [], // [{TenDanhMuc:'Máy lạnh','1':2,'2':-5,...,'12':3, LuyKeNam:41}, ...],
				// headersPhong: [
				// 	{ "title": "Phòng", value: "TenViTriPhong", nowrap: true },
				// 	{ "title": "Th1", value: "1" },
				// 	{ "title": "Th2", value: "2" },
				// 	{ "title": "Th3", value: "3" },
				// 	{ "title": "Th4", value: "4" },
				// 	{ "title": "Th5", value: "5" },
				// 	{ "title": "Th6", value: "6" },
				// 	{ "title": "Th7", value: "7" },
				// 	{ "title": "Th8", value: "8" },
				// 	{ "title": "Th9", value: "9" },
				// 	{ "title": "Th10", value: "10" },
				// 	{ "title": "Th11", value: "11" },
				// 	{ "title": "Th12", value: "12" },
	
				// 	{ "title": "Lũy kế", value: "Tong" },
				// ],
				headers: [
					{ "title": "Danh mục", value: "TenDanhMuc", nowrap: true },
					{ "title": "1", value: "1" },
					{ "title": "2", value: "2" },
					{ "title": "3", value: "3" },
					{ "title": "4", value: "4" },
					{ "title": "5", value: "5" },
					{ "title": "6", value: "6" },
					{ "title": "7", value: "7" },
					{ "title": "8", value: "8" },
					{ "title": "9", value: "9" },
					{ "title": "10", value: "10" },
					{ "title": "11", value: "11" },
					{ "title": "12", value: "12" },
	
					{ "title": "Tổng", value: "Tong" },
				],
				headersKhu: [
					{ "title": "Danh mục", value: "TenDanhMuc", nowrap: true },
					{ "title": "Khu A", value: "Khu A" },
					{ "title": "Khu B", value: "Khu B" },
					{ "title": "Khu C", value: "Khu C" },
					{ "title": "Khu D", value: "Khu D" },
					{ "title": "Khu E", value: "Khu E" },
					{ "title": "Cơ sở 2", value: "Cơ sở 02" },
					{ "title": "Cơ sở Long Khánh", value: "Cơ sở Long Khánh" },
					{ "title": "Tổng", value: "Tong" },
				]
			}
		},
		computed: {
			// labels() {
			// 	// labels theo khoảng tháng đang chọn
			// 	const arr = []
			// 	for (let m = this.monthFrom; m <= this.monthTo; m++) arr.push(this.mm(m))
			// 	return arr
			// }
			labels() {
				return [
					'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
					'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
				]
			},
			monthKeys() {
				const y = this.year
				const ks = []
				for (let m = 6; m <= 12; m++) ks.push(`${m}-${y}`)
				for (let m = 1; m <= 5; m++)  ks.push(`${m}-${y + 1}`)
				return ks
			},
			headersPhong() {
				const h = [{ title: 'Vị trí phòng', key: 'Vị trí phòng', align: 'start' }]
				this.monthKeys.forEach(k => h.push({ title: k, key: k, align: 'center' }))
				h.push({ title: 'Tổng', key: 'Tổng', align: 'center' })
				return h
			}
		},
		watch: {
			year() {
				this.load();
				this.getBaoSuaTheoPhongTop();
				this.getBaoSuaKhongSuaDuocTheoKhu();
				this.getBaoSuaTheoKhu();
				this.getNhanVienXuLy();
			},
			monthFrom() { this.draw() },
			monthTo() { this.draw() },
			isOpenChiTietPhong() {
				if (this.isOpenChiTietPhong) {
					this.getBaoSuaTheoPhong();
				}
			},
			thangNamSelected() {
				console.log(this.thangNamSelected)
				this.month = this.thangNamSelected.Thang;
				this.getBaoSuaKhongSuaDuocTheoKhu();
				this.getBaoSuaTheoKhu();
			}
		},
		async mounted() {
			await this.getThangNamHoc();
			await this.getNamHoc();
			await this.getNamHocHienTai();
			this.load();
			this.getBaoSuaTheoPhongTop();
			this.getBaoSuaKhongSuaDuocTheoKhu();
			this.getBaoSuaTheoKhu();
			this.getNhanVienXuLy();
		},
		beforeUnmount() { this.chart?.destroy() },
	
		methods: {
			// parseDetail(jsonStr) {
			// 	if (!jsonStr) return []
			// 	try {
			// 		const arr = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr
			// 		return Array.isArray(arr)
			// 			? arr
			// 				.map(x => ({
			// 					TenDanhMuc: x?.TenDanhMuc ?? x?.tenDanhMuc ?? '',
			// 					SoLuong: Number(x?.SoLuong ?? x?.soLuong ?? 0)
			// 				}))
			// 				.filter(x => x.TenDanhMuc && x.SoLuong > 0)
			// 				.sort((a, b) => b.SoLuong - a.SoLuong) // 🔹 sắp giảm dần theo SoLuong
			// 			: []
			// 	} catch {
			// 		return []
			// 	}
			// },
	
			parseDetail(jsonStr) {
				if (!jsonStr) return []
				try {
					const arr = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr
					return Array.isArray(arr) ? arr : []
				} catch { return [] }
			},
			mm(m) {
				return new Date(2000, m - 1, 1).toLocaleString('en', { month: 'long' }) // January...
			},
			async getBaoSuaTheoPhong() {
				this.loadingPhongAll = true;
				const res = await axios.post('TS_ThongKe_BaoSua_ViTriPhong_NamHoc_All', { NamHocStart: this.year })
				let rows = res.data?.data ?? res.data ?? []
	
				this.dsBaoSuaPhong = rows;
				this.loadingPhongAll = false;
			},
			async getBaoSuaTheoPhongTop() {
				this.loadingPhongTop = true;
				const res = await axios.post('TS_ThongKe_BaoSua_ViTriPhong_NamHoc', { NamHocStart: this.year })
				let rows = res.data?.data ?? res.data ?? []
				this.dsBaoSuaPhongTop = rows.slice(0, -1);
	
				this.loadingPhongTop = false;
	
			},
			async getBaoSuaTheoKhu() {
				const res = await axios.post('TS_ThongKe_BaoSua_TheoToa_ThangNam', { Nam: this.thangNamSelected.Nam, Thang: this.thangNamSelected.Thang })
				let rows = res.data?.data ?? res.data ?? []
				this.dsBaoSuaKhu = rows;
			},
			async getBaoSuaKhongSuaDuocTheoKhu() {
				const res = await axios.post('TS_ThongKe_BaoSua_KhongSuaDuoc_TheoToa_ThangNam', { Nam: this.thangNamSelected.Nam, Thang: this.thangNamSelected.Thang })
				let rows = res.data?.data ?? res.data ?? []
				this.dsBaoSuaKhuKhongSuaDuoc = rows;
			},
			async getThangNamHoc() {
				try {
					const res = await axios.post('TS_NamHoc_SelectByNam', { NamHocStart: this.year })
					let rows = res.data?.data ?? res.data ?? []
					this.dsThangNamHoc = rows;
					this.thangNamSelected = this.dsThangNamHoc.find(v => v.Thang == this.month && v.Nam == this.year)
				} catch (error) {
					console.log(error)
				}
			},
	
			async getNhanVienXuLy() {
				try {
					this.loadingNhanVienXuLy = true;
					const res = await axios.post('TS_ThongKe_BaoSua_TongTheoNhanVien', { NamHocStart: this.year })
					let rows = res.data?.data ?? res.data ?? []
					this.dsNhanVienXuLy = rows;
	
	
	
					this.dsNhanVienXuLyEdit = rows.map(item => {
						const newItem = {}
						for (const [key, value] of Object.entries(item)) {
							if (key === 'MaPhongBan') continue // bỏ cột này
							switch (key) {
								case 'HoTen':
									newItem['Họ Tên'] = value
									break
								case 'TenPhongBan':
									newItem['Phòng ban'] = value
									break
								case 'Tong':
									newItem['Tổng'] = value
									break
								default:
									newItem[key] = value // giữ nguyên các cột tháng
							}
						}
						return newItem
					})
	
					
	
				} catch (error) {
					console.log(error)
				} finally {
					this.loadingNhanVienXuLy = false;
				}
			},
	
	
			async getNamHoc() {
				try {
					const res = await axios.post('TS_NamHoc_SelectAll')
					let rows = res.data?.data ?? res.data ?? []
					this.dsNamHoc = rows
	
				} catch (error) {
					console.log(error)
				}
			},
			async getNamHocHienTai() {
				try {
					const res = await axios.post('https://api.zentea.vn/work/obj/TS_NamHoc_SelectHienTai')
					let rows = res.data?.data ?? res.data ?? []
					this.namHocHienTai = rows
	
					this.nam = this.namHocHienTai.NamBatDau
					console.log(this.namHocHienTai)
	
				} catch (error) {
					console.log(error)
				}
			},
	
	
	
			async load() {
				// Gọi SP bạn vừa tạo (đã gom Top10 + “Khác”)
				const res = await axios.post('TS_ThongKe_BaoSua_DanhMuc_NamHoc', { NamHocStart: this.year })
				let rows = res.data?.data ?? res.data ?? []
				if (typeof rows === 'string') rows = JSON.parse(rows)
				if (!Array.isArray(rows)) rows = []
				this.raw = rows
				console.log(this.raw)
				this.draw()
	
			},
	
			buildDatasets() {
				// Giữ màu ổn định theo tên danh mục (để đổi năm vẫn không nhảy màu)
				const palette = [
					'#e86a8e', '#4d8cf6', '#67c1bc', '#f0a34a', '#7a6ee6',
					'#00a950', '#b15928', '#33a02c', '#1f78b4', '#6a3d9a',
					'#fb9a99', '#ff7f00', '#cab2d6', '#a6cee3', '#b2df8a'
				]
				const colorByName = Object.create(null)
				let colorIdx = 0
				const getColor = (name) => {
					if (!colorByName[name]) colorByName[name] = palette[colorIdx++ % palette.length]
					return colorByName[name]
				}
	
				// 1) Tạo mảng tạm có kèm tổng trong khoảng tháng đang chọn
				const tmp = this.raw.map(row => {
					const data = []
					let total = 0
					for (let m = this.monthFrom; m <= this.monthTo; m++) {
						const v = Number(row[String(m)] ?? 0)
						data.push(v)
						total += v
					}
					return {
						name: row.TenDanhMuc,
						data,
						total
					}
				})
	
				// 2) Sắp xếp: nhiều nhất ở dưới (desc). Muốn “Khác” luôn ở trên cùng? đưa vào sort ưu tiên.
				tmp.sort((a, b) => {
					// Ưu tiên: nếu muốn "Khác" luôn ở TRÊN cùng:
					// if (a.name === 'Khác') return 1
					// if (b.name === 'Khác') return -1
					return b.total - a.total
				})
	
				// 3) Trả về datasets theo thứ tự đã sắp
				return tmp.map(x => {
					const c = getColor(x.name)
					return {
						label: x.name,
						data: x.data,
						backgroundColor: c,
						borderColor: c,
						borderWidth: 1
						// order: 0 // (không cần, vì thứ tự trong mảng đã quyết định vị trí trong stack)
					}
				})
			},
	
	
			draw() {
				const ctx = this.$refs.chartDanhMuc.getContext('2d')
				const datasets = this.buildDatasets().map(ds => ({
					...ds,
					fill: false, // không tô nền dưới đường
					tension: 0.3, // bo tròn nhẹ
					pointRadius: 4, // kích thước điểm
					borderWidth: 2 // độ dày đường
				}))
	
				if (this.chart) {
					this.chart.destroy()
					this.chart = null
				}
	
				this.chart = new Chart(ctx, {
					type: 'line', // hoặc 'bar', 'horizontalBar'...
					data: { labels: this.labels, datasets },
					options: {
						responsive: false,
						plugins: {
							legend: {
								position: 'top',
								onClick: (e, legendItem, legend) => {
									const ci = legend.chart
									const index = legendItem.datasetIndex
									const meta = ci.getDatasetMeta(index)
									const allVisible = ci.data.datasets.every((ds, i) => !ci.getDatasetMeta(i).hidden)
	
									if (allVisible) {
										// Nếu tất cả đang hiển thị → chỉ giữ dataset được click
										ci.data.datasets.forEach((ds, i) => {
											ci.getDatasetMeta(i).hidden = i !== index
										})
									} else if (meta.hidden) {
										// Nếu dataset này đang ẩn → bật nó lên và ẩn cái khác
										ci.data.datasets.forEach((ds, i) => {
											ci.getDatasetMeta(i).hidden = i !== index
										})
									} else {
										// Nếu đang là dataset duy nhất hiển thị → bật lại tất cả
										ci.data.datasets.forEach((ds, i) => {
											ci.getDatasetMeta(i).hidden = null
										})
									}
	
									ci.update()
								}
							},
							tooltip: {
								callbacks: {
									title: items => this.labels[items[0].dataIndex]
								}
							}
						},
						scales: {
							x: { title: { display: false, text: 'Tháng' } },
							y: { beginAtZero: true, title: { display: true, text: 'Số lượng báo sửa' } }
						}
					}
				})
			}
		}
	}
</script>