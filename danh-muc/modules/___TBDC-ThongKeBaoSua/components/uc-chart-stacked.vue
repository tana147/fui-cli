<template>
	<div id="chart"></div>
</template>

<script>
	export default {
	
		props: {
			/*
			  Dữ liệu dạng (ví dụ):
			  [
				{ "Danh Mục": "Máy lạnh", "6-2025": 2, "7-2025": 5, ..., "5-2026": 3, "Tổng": 41 },
				...
			  ]
			*/
			raw: { type: Array, default: () => [] },
			autoFetch: { type: Boolean, default: false },
			year: { type: Number, default: new Date().getFullYear() }, // năm BẮT ĐẦU năm học (vd 2025)
			// Khoảng theo vị trí trong năm học: 1..12 (1=Th6, 12=Th5 năm sau)
			monthFrom: { type: Number, default: 1 },
			monthTo: { type: Number, default: 12 }
		},
	
		data() {
			return {
				chart: null,
				palette: [
					'#e86a8e', '#4d8cf6', '#67c1bc', '#f0a34a', '#7a6ee6',
					'#00a950', '#b15928', '#33a02c', '#1f78b4', '#6a3d9a',
					'#fb9a99', '#ff7f00', '#cab2d6', '#a6cee3', '#b2df8a'
				],
				colorByName: Object.create(null),
				colorIdx: 0,
				_rawLocal: []
			}
		},
	
		async mounted() {
			await this.load();
			this.renderChart(this._rawLocal);
		},
	
		beforeUnmount() {
			this.chart?.destroy();
			this.chart = null;
		},
	
		watch: {
			raw: { handler() { if (!this.autoFetch) this.updateChart(this.raw) }, deep: true },
			monthFrom() { this.updateChart(this.autoFetch ? this._rawLocal : this.raw) },
			monthTo() { this.updateChart(this.autoFetch ? this._rawLocal : this.raw) },
			async year(nv, ov) {
				if (this.autoFetch && nv !== ov) {
					await this.load();
					this.updateChart(this._rawLocal, true);
				} else if (!this.autoFetch && nv !== ov) {
					// chỉ đổi label khi không fetch tự động
					this.updateChart(this.raw, true);
				}
			}
		},
	
		methods: {
			async load() {
				try {
					console.log('1')
					// if (!this.autoFetch) return;
					const res = await axios.post('/TS_ThongKe_BaoSua_DanhMuc_NamHoc', { NamHocStart: this.year });
					// const res = await axios.post('/ThongKe_BaoSua_DanhMuc_NamHoc', { NamHocStart: 2025})
					console.log('da goi api')
					let rows = res?.data?.data ?? res?.data ?? [];
					console.log('2')
					if (typeof rows === 'string') {
					try { rows = JSON.parse(rows) } catch { rows = [] }
					}
					console.log('3')
					if (!Array.isArray(rows)) rows = [];
					// nhiều SP trả thêm dòng tổng cuối cùng -> bỏ
					if (rows.length && rows[rows.length - 1] && rows[rows.length - 1]['Danh Mục'] === 'Tổng') {
					rows = rows.slice(0, -1);
					}
					this._rawLocal = rows;
						console.log('4')
					console.log(this._rawLocal)
				} catch (error) {
					console.log(error)
				}
				
			},
	
			// Danh sách khóa tháng theo năm học, dạng "m-yyyy"
			academicMonthKeys(startYear) {
				const keys = [];
				for (let m = 6; m <= 12; m++) keys.push(`${m}-${startYear}`);
				for (let m = 1; m <= 5; m++) keys.push(`${m}-${startYear + 1}`);
				return keys; // length = 12
			},
	
			// Nhãn trục X tương ứng
			categories() {
				const keys = this.academicMonthKeys(this.year);
				const from = Math.max(1, Math.min(12, this.monthFrom));
				const to = Math.max(from, Math.min(12, this.monthTo));
				const slice = keys.slice(from - 1, to);
				// Ví dụ: "6-2025" -> "Th6-2025"
				return slice.map(k => `${k.replace('-', '-')}`);
			},
	
			// Màu ổn định theo tên danh mục
			getColor(name) {
				if (!this.colorByName[name]) {
					this.colorByName[name] = this.palette[this.colorIdx++ % this.palette.length];
				}
				return this.colorByName[name];
			},
	
			// Xây series theo dữ liệu trả về (cột "Danh Mục" + các cột "m-yyyy")
			buildSeries(rawSource) {
				if (!Array.isArray(rawSource)) return [];
				const keys = this.academicMonthKeys(this.year);
				const from = Math.max(1, Math.min(12, this.monthFrom));
				const to = Math.max(from, Math.min(12, this.monthTo));
				const rangeKeys = keys.slice(from - 1, to);
	
				// map -> sort theo tổng giảm dần
				const tmp = rawSource.map(row => {
					const name = row['Danh Mục'] ?? row['TenDanhMuc'] ?? '';
					let total = 0;
					const data = rangeKeys.map(k => {
						const v = Number(row[k] ?? 0);
						total += v;
						return v;
					});
					return { name, data, total };
				}).sort((a, b) => b.total - a.total);
	
				return tmp.map(s => ({ name: s.name, data: s.data }));
			},
	
			buildColors(series) {
				return series.map(s => this.getColor(s.name));
			},
	
			renderChart(rawSource) {
				const series = this.buildSeries(rawSource);
				const options = {
					chart: {
						type: 'bar',
						height: 430,
						stacked: true,
						toolbar: { show: true }
					},
					series,
					colors: this.buildColors(series),
					plotOptions: {
						bar: {
							horizontal: false,
							borderRadius: 4,
							dataLabels: {
								total: { enabled: true, style: { fontSize: '13px', fontWeight: 900 } }
							}
						}
					},
					dataLabels: { enabled: false },
					stroke: { show: true, width: 1 },
					xaxis: { categories: this.categories() },
					yaxis: { min: 0, forceNiceScale: true, title: { text: '' } },
					legend: { position: 'top' },
					tooltip: { shared: false, intersect: true },
					title: {
						text: `Danh mục báo sửa theo tháng (${this.year}-${this.year + 1})`,
						align: 'center',
						style: { fontFamily: 'Roboto, Arial, sans-serif' }
					}
				};
	
				this.chart?.destroy();
				this.chart = new ApexCharts(document.querySelector('#chart'), options);
				this.chart.render();
			},
	
			updateChart(rawSource, force = false) {
				if (!this.chart) { this.renderChart(rawSource); return; }
				const series = this.buildSeries(rawSource);
				this.chart.updateOptions({
					colors: this.buildColors(series),
					xaxis: { categories: this.categories() },
					title: { text: `Danh mục báo sửa theo tháng (${this.year}-${this.year + 1})` }
				}, false, true);
				this.chart.updateSeries(series, true);
	
				if (force) {
					this.chart.updateOptions({ chart: { redrawOnWindowResize: true } }, false, true);
				}
			}
		}
	}
</script>