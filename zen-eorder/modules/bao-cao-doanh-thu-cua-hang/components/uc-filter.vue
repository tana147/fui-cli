<template>
	<div>
		<v-row>
			<v-col cols="4">
				<v-select label="Phân hiệu" outlined dense v-model="PhanHieuID" :items="vueData.DSPhanHieu"
					item-value="PhanHieuID" item-text="TenPhanHieu" hide-details />
			</v-col>
			<v-col cols="4">
				<v-select label="Khu vực" outlined dense v-model="KhuVucID" :items="vueData.DSKhuVuc"
					item-value="KhuVucID" item-text="TenKhuVuc" hide-details />
			</v-col>
			<v-col cols="4">
				<v-select label="Cửa hàng" multiple outlined dense v-model="CuaHangID" :items="dsCuaHangFilter"
					item-value="CuaHangID" item-text="TenCuaHang"
					:menu-props="{ closeOnContentClick: false, maxHeight: 420 }">
					<!-- Nút Chọn tất cả -->
					<template v-slot:prepend-item>
						<v-list-item ripple @click.stop>
							<v-list-item-action>
								<v-checkbox v-model="selectAllModel" :indeterminate="isSomeSelected" color="primary" />
							</v-list-item-action>
							<v-list-item-content>
								<v-list-item-title>Chọn tất cả</v-list-item-title>
							</v-list-item-content>
						</v-list-item>
						<v-divider class="mt-2" />
					</template>


					<!-- Hiển thị lựa chọn gọn -->
					<template v-slot:selection="{ item, index }">
						<span v-if="index < 1">{{ item.TenCuaHang }}</span>
						<span v-if="index === 1" class="primary--text text-caption align-self-center">
							(+{{ CuaHangID.length - 1 }} cửa hàng khác)
						</span>
					</template>
				</v-select>
			</v-col>
			<v-col cols="2">
				<v-select label="Báo cáo" outlined dense v-model="isReportGiaTriBaoCao"
					:items="[{ value: 0, text: 'Doanh Thu' }, { value: 1, text: 'Số Lượng' }]" hide-details />
			</v-col>
			<v-col cols="2">
				<v-select label="Loại thời gian" outlined dense v-model="HinhThucThoiGian" :items="DSHinhThucThoiGian"
					hide-details />
			</v-col>
			<!-- 2: Theo ngày -->
			<v-col cols="2" v-if="HinhThucThoiGian === 2 || HinhThucThoiGian === 1">
				<f-date label="Từ ngày" outlined dense v-model="TuNgay" :date-add="0" hide-details />
			</v-col>
			<v-col cols="2" v-if="HinhThucThoiGian === 2 || HinhThucThoiGian === 1">
				<f-date label="Đến ngày" outlined dense v-model="DenNgay" :date-add="0" hide-details />
			</v-col>
			<!-- 3: Theo tuần -->
			<v-col cols="2" v-if="HinhThucThoiGian === 3">
				<v-select label="Năm" outlined dense v-model="Nam" :items="DSNam" hide-details />
			</v-col>
			<v-col cols="2" v-if="HinhThucThoiGian === 3">
				<v-select label="Tháng" outlined dense v-model="Thang" :items="DSThang" hide-details />
			</v-col>
			<!-- 4: Theo quý || 5: Theo tháng -->
			<v-col cols="2" v-if="HinhThucThoiGian === 4 || HinhThucThoiGian === 5">
				<v-select label="Năm" outlined dense v-model="Nam" :items="DSNam" hide-details />
			</v-col>
			<!-- 6: Theo năm -->
			<v-col cols="2" v-if="HinhThucThoiGian === 6">
				<v-select label="Từ năm" outlined dense v-model="TuNam" :items="DSNam" hide-details />
			</v-col>
			<v-col cols="2" v-if="HinhThucThoiGian === 6">
				<v-select label="Đến năm" outlined dense v-model="DenNam" :items="DSNam" hide-details />
			</v-col>
			<v-col cols="2">
				<v-btn color="primary" elevation="0" @click="getReport" :loading="isLoading"><v-icon
						left>mdi-filter</v-icon>Tìm</v-btn>
			</v-col>
		</v-row>

		<!-- Modal tiến trình lấy dữ liệu -->
		<v-dialog v-model="showProgressModal" persistent centered width="500">
			<v-card small elevation="0" outlined>
			<v-card-title>
				<div class="d-flex justify-space-between align-center" style="width: 100%;">
					<h5 class="primary--text">Tiến trình lấy dữ liệu báo cáo</h5>
				</div>
			</v-card-title>				<v-card-text class="mx-auto">
					<div class="pr-2 pl-2">
						<v-progress-linear v-if="isLoading" :value="processNum"></v-progress-linear>

						<div v-if="progressItems && progressItems.length > 0" style="height: 600px; overflow-y: auto;">
							<div v-for="item in progressItems" :key="item.CuaHangID">
								<v-list-item :class="{ 'error-row': item.status === 3 }">
									<v-list-item-content>
										<div>{{ item.TenCuaHang || ('Cửa hàng #' + item.CuaHangID) }}</div>
										<div style="font-size: 11px; color: #999; margin-top: 4px;">
											<span v-if="storeStartTimes[item.CuaHangID]">Start: {{ storeStartTimes[item.CuaHangID] }}</span>
											<span v-if="storeEndTimes[item.CuaHangID]" class="ml-3">End: {{ storeEndTimes[item.CuaHangID] }}</span>
											<span v-if="requestTimes[item.CuaHangID] !== undefined" class="ml-3">
												{{ requestTimes[item.CuaHangID] }} ms
											</span>
										</div>
									</v-list-item-content>
									<v-list-item-action>
										<v-btn v-if="item.status === 1" elevation="0" icon :loading="true" small />
										<v-icon v-else-if="item.status === 2" color="primary" small>mdi-check</v-icon>
										<v-btn v-else-if="item.status === 3" icon small
											@click.stop="retryStore(item.CuaHangID)">
											<v-icon small>mdi-reload</v-icon>
										</v-btn>
									</v-list-item-action>
								</v-list-item>
								<v-divider />
							</div>
						</div>
						<div v-else style="height: 400px; display: flex; align-items: center; justify-content: center;">
							<span style="color: #999;">Đang chuẩn bị dữ liệu...</span>
						</div>
					</div>
				</v-card-text>

				<v-card-actions>
					<v-spacer />
					<v-btn color="red" text @click="closeProgressModal" :disabled="isLoading">Đóng</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
export default {
	props: [],
	data: function () {
		//Lấy danh sách năm
		const yearNow = moment().year()
		let dsYear = []
		for (let y = yearNow; y >= 2024; y--) {
			dsYear.push(y)
		}
		return {
			isReportGiaTriBaoCao: 0,
			CuaHangID: [],
			PhanHieuID: 0,
			KhuVucID: 0,
			HinhThucThanhToan: 0,
			HinhThucThoiGian: 1, //Mặc định theo giờ
			Ngay: moment().format("YYYY-MM-DD"),
			TuNgay: moment().format("YYYY-MM-DD"),
			DenNgay: moment().format("YYYY-MM-DD"),
			Nam: yearNow,
			TuNam: yearNow,
			DenNam: yearNow,
			Thang: moment().month() + 1,
			DSNam: dsYear,
			DSThang: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
			DSHinhThucThoiGian: [
				{ value: 1, text: "Theo giờ" },
				{ value: 2, text: "Theo ngày" },
				{ value: 3, text: "Theo tuần" },
				{ value: 4, text: "Theo quý" },
				{ value: 5, text: "Theo tháng" },
				{ value: 6, text: "Theo năm" },
			],
			headerDefault: [
				{
					text: 'Cửa hàng',
					value: 'CuaHang',
					width: 300
				},
				{
					text: 'Tổng',
					value: 'sumRevenueFormatted',
					width: '100px',
					align: 'right',
					cellClass: "highlight-total"
				}
			],
			vueData,
			showProgressModal: false,
			isLoading: false,
			localStatuses: Object.create(null),
			completedCount: 0,
			requestTimes: Object.create(null),
			storeStartTimes: Object.create(null),
			storeEndTimes: Object.create(null),
			storeErrors: Object.create(null),
			delayPerRequest: 1000,
			storeList: [],
			startTime: null,
			endTime: null
		}
	},
	mounted() {

	},
	computed: {
		isSomeSelected() {
			const selected = Array.isArray(this.CuaHangID) ? this.CuaHangID : [];
			console.log("selected", selected);
			const total = this.dsCuaHangFilter.length;
			return selected.length > 0 && selected.length < total;
		},
		dsCuaHangFilter() {
			return vueData.DSCuaHang.filter(ch => {
				return (this.PhanHieuID === 0 || ch.PhanHieuID === this.PhanHieuID) &&
					(this.KhuVucID === 0 || ch.KhuVucID === this.KhuVucID)
			})
		},
		selectAllModel: {
			get() {
				const selected = Array.isArray(this.CuaHangID) ? this.CuaHangID : [];
				const total = this.dsCuaHangFilter.length;
				return total > 0 && selected.length === total;
			},
			set(checked) {
				this.toggleSelectAll(checked);
			}
		},
		processNum() {
			const total = this.storeList.length || 0;
			return total ? (this.completedCount / total) * 100 : 0;
		},
		progressItems() {
			const nameMap = Object.create(null);
			const ds = Array.isArray(vueData.DSCuaHang) ? vueData.DSCuaHang : [];
			for (let i = 0; i < ds.length; i++) nameMap[ds[i].CuaHangID] = ds[i].TenCuaHang;

			const arr = this.storeList.map((id) => ({
				CuaHangID: id,
				TenCuaHang: nameMap[id],
				status: this.localStatuses[id] ?? 0
			}));

			return arr;
		}
	},
	watch: {
		'vueData.DSCuaHang': {
			handler() {
				this.CuaHangID = [];
				this.toggleSelectAll(true);
			},
			deep: true
		}
	},
	methods: {
		toggleSelectAll(checked) {
			if (checked) {
				// chọn tất cả theo danh sách đang lọc
				this.CuaHangID = this.dsCuaHangFilter.map(ch => ch.CuaHangID);
			} else {
				// bỏ chọn hết
				this.CuaHangID = [];
			}
		},
		setStatus(id, st) {
			this.$set(this.localStatuses, id, st);
		},
		closeProgressModal() {
			this.showProgressModal = false;
		},
		async getReport() {

			// Danh sách cửa hàng
			const storeIds = Array.isArray(this.CuaHangID) ? this.CuaHangID : [this.CuaHangID];
			if (!storeIds || storeIds.length === 0 || !storeIds[0])
				return showMessage({ type: "red", title: "Thông báo", message: "Vui lòng chọn ít nhất 1 cửa hàng!" })

			// Reset data
			vueData.TableHeader = []
			vueData.DataReport = []
			this.localStatuses = Object.create(null);
			this.completedCount = 0;
			this.storeList = storeIds.slice();
			this.requestTimes = Object.create(null);
			this.storeStartTimes = Object.create(null);
			this.storeEndTimes = Object.create(null);
			this.storeErrors = Object.create(null);

			// Set status loading cho tất cả
			for (let i = 0; i < storeIds.length; i++) {
				this.setStatus(storeIds[i], 1);
			}

			this.isLoading = true;
			this.showProgressModal = true;
			this.startTime = new Date().toLocaleTimeString('vi-VN');
			this.endTime = null;

			console.log("showProcess", this.showProgressModal)

			// Đợi modal render xong
			await this.$nextTick();

			// Tạo filter chung
			const baseFilter = {
				PhanHieuID: this.PhanHieuID,
				KhuVucID: this.KhuVucID,
				HinhThucThanhToan: this.HinhThucThanhToan,
				HinhThucThoiGian: this.HinhThucThoiGian,
				Ngay: this.Ngay,
				TuNgay: this.TuNgay,
				DenNgay: this.DenNgay,
				Nam: this.Nam,
				TuNam: this.TuNam,
				DenNam: this.DenNam,
				Thang: this.Thang,
				IsSoLuong: this.isReportGiaTriBaoCao
			}

			// Tạo danh sách task để chạy song song
			const CONCURRENCY = 5; // chạy tối đa 5 request cùng lúc
			const tasks = storeIds.map(id => () => this.fetchStore(id, baseFilter));
			const results = await this.runWithConcurrency(tasks, CONCURRENCY);

			// Gom dữ liệu
			const validData = results
				.filter((r) => r && r.ok && r.rows && r.rows.length > 0)

			// Lấy rows từ tất cả stores
			const rows = validData.flatMap(r => r.rows)

			// Lấy times từ phần tử đầu tiên (cấu trúc thời gian giống nhau)
			const times = validData.length > 0 ? validData[0].times : []

			// Gom toàn bộ details từ tất cả stores
			const details = validData.flatMap(r => r.details)

			// Gán DataRaw
			vueData.DataRaw = [rows, times, details]

			this.isLoading = false;
			this.endTime = new Date().toLocaleTimeString('vi-VN');

			if (validData.length === 0) {
				showMessage({ type: "yellow", title: "Thông báo", message: "Không có dữ liệu từ các cửa hàng!" })
				return
			}

			this.sanitizeReponse(vueData.DataRaw)
		},

		async fetchStore(CuaHangID, baseFilter) {
			const start = performance.now();
			const startTime = new Date().toLocaleTimeString('vi-VN');
			this.$set(this.storeStartTimes, CuaHangID, startTime);
			
			try {
				const filter = { ...baseFilter, CuaHangID: CuaHangID };
				const body = JSON.stringify(filter);
				const controller = new AbortController();
				
				const res = await fetch(vueData.v_Set?.apiDomain + "/eorder/BaoCao_DoanhThu_CuaHang", {
					method: "POST",
					headers: {
						"content-type": "application/json; charset=utf-8",
						"authorization": $awt
					},
					body,
					signal: controller.signal
				});

				const end = performance.now();
				const endTime = new Date().toLocaleTimeString('vi-VN');
				this.$set(this.requestTimes, CuaHangID, Math.round(end - start));
				this.$set(this.storeEndTimes, CuaHangID, endTime);

				if (res.ok) {
					const data = await res.json();
					if (data && data.data) {
						this.setStatus(CuaHangID, 2); // done
						this.completedCount += 1;
						return {
							ok: true,
							storeId: CuaHangID,
							rows: data.data[0] || [],
							times: data.data[1] || [],
							details: data.data[2] || []
						};
					} else {
						console.warn(`No data for store ${CuaHangID}`);
						this.setStatus(CuaHangID, 2); // done
						this.completedCount += 1;
						return {
							ok: true,
							storeId: CuaHangID,
							rows: [],
							times: [],
							details: []
						};
					}
				} else {
					console.error(`Failed to fetch store ${CuaHangID}: ${res.status}`);
					this.setStatus(CuaHangID, 3); // error
					this.$set(this.storeErrors, CuaHangID, `HTTP Error: ${res.status} ${res.statusText}`);
					this.completedCount += 1;
					return {
						ok: false,
						storeId: CuaHangID,
						rows: [],
						times: [],
						details: []
					};
				}
			} catch (error) {
				console.error(`Error fetching store ${CuaHangID}:`, error);
				const endTime = new Date().toLocaleTimeString('vi-VN');
				this.$set(this.storeEndTimes, CuaHangID, endTime);
				this.setStatus(CuaHangID, 3); // error
				this.$set(this.storeErrors, CuaHangID, error.message || 'Unknown error');
				this.completedCount += 1;
				return {
					ok: false,
					storeId: CuaHangID,
					rows: [],
					times: [],
					details: [],
					errMsg: error.message
				};
			}
		},

		async runWithConcurrency(tasks, limit) {
			const results = new Array(tasks.length);
			let idx = 0, running = 0;
			return new Promise((resolve) => {
				const launchNext = () => {
					while (running < limit && idx < tasks.length) {
						const current = idx++;
						running++;
						tasks[current]()
							.then(r => { results[current] = r; })
							.catch(e => {
								results[current] = {
									ok: false,
									storeId: null,
									errMsg: e?.message || 'error'
								};
							})
							.finally(() => {
								running--;
								if (idx >= tasks.length && running === 0) resolve(results);
								else launchNext();
							});
					}
				};
				launchNext();
			});
		},

		sanitizeReponse([stores, dynamicVariables, dataRaw]) {
			if (!stores || stores.length === 0) {
				vueData.TableHeader = []
				vueData.DataReport = []
				return
			}

			const [aliasKey] = Object.keys(dynamicVariables[0])
			const isDaily = aliasKey === 'Ngay'

			const dataRefactor = dataRaw.map(e => ({
				...e,
				[aliasKey]: e.HinhThucThoiGian
			}))

			const dataMap = this.buildDataMap(dataRefactor, aliasKey)
			const headerTemp = this.generateHeader(dynamicVariables, aliasKey, isDaily)
			const dataTable = this.generateDataTable(stores, headerTemp, dataMap, aliasKey)
			const rowTotal = this.generateTotalRow(dataTable, headerTemp)

			dataTable.push(rowTotal)

			vueData.TableHeader = [...this.headerDefault, ...headerTemp]
			vueData.DataReport = [...dataTable]
		},

		buildDataMap(dataRaw, aliasKey) {
			const map = new Map()
			dataRaw.forEach(item => {
				const key = `chID${item.CuaHangID}_${item[aliasKey]}`
				map.set(key, item)
			})
			return map
		},

		generateHeader(variables, key, isDaily) {
			const suffix = this.suffixColumn(key)
			const prefix = this.preflixColumn(key)

			return variables.map(variable => {
				const value = variable[key]
				const columnTitle = isDaily ? this.formatDaily(value) : `${prefix} ${value}${suffix}`
				const columnValue = `${key}_${value}`
				return {
					...variable,
					text: columnTitle,
					value: columnValue,
					align: 'right'
				}
			})
		},

		generateDataTable(brands, headers, dataMap, aliasKey) {
			return brands.map(brand => {
				const row = { ...brand, sumRevenueCol: 0 }
				headers.forEach(head => {
					const key = `chID${row.CuaHangID}_${head[aliasKey]}`
					const data = dataMap.get(key)
					const price = data ? data.GiaTriBaoCao : 0

					row[head.value] = price.toLocaleString("vi-vn")  //formatPrice(price)
					row[head.value + '_value'] = price
					row.sumRevenueCol += price
				})

				row.sumRevenueFormatted = row.sumRevenueCol.toLocaleString("vi-vn")  //formatPrice(row.sumRevenueCol)
				return row
			})
		},

		generateTotalRow(dataTable, headers) {
			const totalRow = { CuaHang: 'Tổng', sumRevenueCol: 0 }

			totalRow.sumRevenueCol = dataTable.reduce((sum, row) => sum + (row.sumRevenueCol || 0), 0)
			totalRow.sumRevenueFormatted = totalRow.sumRevenueCol.toLocaleString("vi-vn")  // formatPrice(totalRow.sumRevenueCol)

			headers.forEach(head => {
				const total = dataTable.reduce((sum, row) => sum + (row[head.value + '_value'] || 0), 0)
				totalRow[head.value + '_value'] = total
				totalRow[head.value] = total.toLocaleString("vi-vn") //formatPrice(total)
			})

			return totalRow
		},

		suffixColumn(col) {
			if (col === 'Gio') return 'H'
			return ''
		},

		preflixColumn(col) {
			switch (col) {
				case 'Tuan': return 'Tuần'
				case 'Thang': return 'Tháng'
				case 'Quy': return 'Quý'
				default: return ''
			}
		},

		formatDaily(str) {
			return moment(str).format("D/M")
		},

		async retryStore(id) {
			if (this.isLoading && this.localStatuses[id] === 1) return;

			this.completedCount = Math.max(0, this.completedCount - (this.localStatuses[id] === 2 ? 1 : 0));
			this.setStatus(id, 1); // loading

			const baseFilter = {
				PhanHieuID: this.PhanHieuID,
				KhuVucID: this.KhuVucID,
				HinhThucThanhToan: this.HinhThucThanhToan,
				HinhThucThoiGian: this.HinhThucThoiGian,
				Ngay: this.Ngay,
				TuNgay: this.TuNgay,
				DenNgay: this.DenNgay,
				Nam: this.Nam,
				TuNam: this.TuNam,
				DenNam: this.DenNam,
				Thang: this.Thang,
				IsSoLuong: this.isReportGiaTriBaoCao
			};

			await this.fetchStore(id, baseFilter);
		}
	}
}
</script>