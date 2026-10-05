<template>
	<div>
	<v-row >
		<v-col cols="4">
			<v-select label="Phân hiệu" outlined dense v-model="PhanHieuID" :items="vueData.DSPhanHieu"
				item-value="PhanHieuID" item-text="TenPhanHieu" hide-details />
		</v-col>
		<v-col cols="4">
			<v-select label="Khu vực" outlined dense v-model="KhuVucID" :items="vueData.DSKhuVuc" item-value="KhuVucID"
				item-text="TenKhuVuc" hide-details />
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
			<v-select label="Hình thức thanh toán" outlined dense v-model="HinhThucThanhToan"
				:items="DSHinhThucThanhToan" hide-details />
		</v-col>
		<v-col cols="2">
			<v-select label="Loại thời gian" outlined dense v-model="HinhThucThoiGian" :items="DSHinhThucThoiGian" hide-details />
		</v-col>
		<!-- 1: Theo giờ
		<v-col cols="2" v-if="HinhThucThoiGian === 1">
			<f-date label="Ngày" outlined dense v-model="Ngay" :date-add="0" hide-details />
		</v-col> -->
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
			<v-select label="Báo Cáo" outlined dense v-model="LoaiBaoCao" :items="DSLoaiBaoCao" hide-details />
		</v-col>
		<v-col cols="2">
			<v-btn color="primary" elevation="0" @click="getReport" :loading="isLoading"><v-icon left>mdi-filter</v-icon>Tìm</v-btn>
		</v-col>
	</v-row>

	<!-- Modal tiến trình lấy dữ liệu -->
	<v-dialog v-model="showProgressModal" persistent centered width="450">
		<v-card small elevation="0" outlined>
			<v-card-title>
				<div class="d-flex justify-space-between align-center" style="width: 100%;">
					<h5 class="primary--text">Tiến trình lấy dữ liệu báo cáo</h5>
				</div>
			</v-card-title>
			<v-card-text class="mx-auto">
				<div class="pr-2 pl-2">
					<v-progress-linear v-if="isLoading" :value="processNum"></v-progress-linear>

					<div v-if="progressItems && progressItems.length > 0" style="height: 600px; overflow-y: auto;">
						<div v-for="item in progressItems" :key="item.CuaHangID">
							<v-list-item :class="{ 'error-row': item.status === 3 }">
								<v-list-item-content>
									<div :style="{ color: item.status === 3 ? '#f44336' : 'inherit', fontWeight: item.status === 3 ? 'bold' : 'normal' }">
										{{ item.TenCuaHang || ('Cửa hàng #' + item.CuaHangID) }}
									</div>
									<div style="font-size: 11px; color: #999; margin-top: 4px;">
										<span v-if="storeStartTimes[item.CuaHangID]">Start: {{ storeStartTimes[item.CuaHangID] }}</span>
										<span v-if="storeEndTimes[item.CuaHangID]" class="ml-3">End: {{ storeEndTimes[item.CuaHangID] }}</span>
										<span v-if="requestTimes[item.CuaHangID] !== undefined" class="ml-3">
											{{ requestTimes[item.CuaHangID] }} ms
										</span>
									</div>
									<div v-if="item.status === 3 && storeErrors[item.CuaHangID]" style="font-size: 11px; color: #f44336; margin-top: 4px;">
										<v-icon x-small color="red" class="mr-1">mdi-alert-circle</v-icon>
										{{ storeErrors[item.CuaHangID] }}
									</div>
								</v-list-item-content>
								<v-list-item-action>
									<v-btn v-if="item.status === 1" elevation="0" icon :loading="true" small />
									<v-icon v-else-if="item.status === 2" color="primary" small>mdi-check</v-icon>
									<v-btn v-else-if="item.status === 3" icon small @click.stop="retryStore(item.CuaHangID)">
										<v-icon small>mdi-reload</v-icon>
									</v-btn>
								</v-list-item-action>
							</v-list-item>
							<v-divider />
						</div>
					</div>
					<div v-else style="height: 200px; display: flex; align-items: center; justify-content: center;">
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
			LoaiBaoCao: 0,
			DSLoaiBaoCao: [
				{ value: 0, text: "Doanh Thu" },
				{ value: 1, text: "Số Lượng" },
			],
			DSHinhThucThanhToan: [
				{ value: 0, text: "Tất cả" },
				{ value: 1, text: "Tiền mặt" },
				{ value: 2, text: "Chuyển khoản" },
				{ value: 4, text: "Quẹt thẻ" },
				{ value: 3, text: "Shopee Food" },
				{ value: 6, text: "Grab" },
				{ value: 5, text: "ZEN" },
				{ value: 7, text: "XSM" },
			],
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
					text: 'Sản phẩm',
					value: 'TenSanPham',
					width: '250px'
				},
				{
					text: 'Thương hiệu',
					value: 'TenPhanHieu',
					width: '200px',
					align: 'right'
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
			// Progress modal state
			showProgressModal: false,
			isLoading: false,
			localStatuses: Object.create(null),
			completedCount: 0,
			requestTimes: Object.create(null),
			storeStartTimes: Object.create(null),
			storeEndTimes: Object.create(null),
			storeErrors: Object.create(null),
			storeList: []
		}
	},
	computed: {
		isSomeSelected() {
			const selected = Array.isArray(this.CuaHangID) ? this.CuaHangID : [];
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

			return this.storeList.map((id) => ({
				CuaHangID: id,
				TenCuaHang: nameMap[id],
				status: this.localStatuses[id] ?? 0
			}));
		}
	},
	watch: {
		'vueData.DSCuaHang': {
			handler() {
				this.CuaHangID = [];
				this.toggleSelectAll(true);
			},
			deep: true
		},
		// Keep selected CuaHangIDs in sync with the filtered store list
		dsCuaHangFilter(newList) {
			const validIds = Array.isArray(newList) ? newList.map(ch => ch.CuaHangID) : [];
			const current = Array.isArray(this.CuaHangID) ? this.CuaHangID : (this.CuaHangID ? [this.CuaHangID] : []);
			const filtered = current.filter(id => validIds.includes(id));
			if (filtered.length !== current.length) {
				this.CuaHangID = filtered;
			}
		},
		"LoaiBaoCao": function (newVal) {
			this.getReport()
		}
	},
	methods: {
		toggleSelectAll(checked) {
			if (checked) {
				this.CuaHangID = this.dsCuaHangFilter.map(ch => ch.CuaHangID);
			} else {
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
			// Danh sách cửa hàng (luôn là array vì v-select multiple)
			const storeIds = Array.isArray(this.CuaHangID) ? this.CuaHangID.filter(s => s || s === 0) : (this.CuaHangID ?
				[this.CuaHangID] : []);
			if (!storeIds || storeIds.length === 0) {
				return showMessage({ type: "red", title: "Thông báo", message: "Vui lòng chọn ít nhất 1 cửa hàng!" });
			}

			// Reset data
			vueData.TableHeader = [];
			vueData.DataReport = [];
			this.localStatuses = Object.create(null);
			this.completedCount = 0;
			this.storeList = storeIds.slice();
			this.requestTimes = Object.create(null);
			this.storeStartTimes = Object.create(null);
			this.storeEndTimes = Object.create(null);
			this.storeErrors = Object.create(null);

			// Tạo filter chung
			const baseFilter = {
				PhanHieuID: this.PhanHieuID,
				KhuVucID: this.KhuVucID,
				HinhThucThanhToan: this.HinhThucThanhToan,
				HinhThucThoiGian: this.HinhThucThoiGian,
				IsSoluong: this.LoaiBaoCao, 
				Ngay: this.Ngay,
				TuNgay: this.TuNgay,
				DenNgay: this.DenNgay,
				Nam: this.Nam,
				TuNam: this.TuNam,
				DenNam: this.DenNam,
				Thang: this.Thang
			};

			// Nếu chỉ có 1 cửa hàng, không cần hiển thị modal
			if (storeIds.length === 1) {
				this.isLoading = true;
				const result = await this.fetchStore(storeIds[0], baseFilter);
				this.isLoading = false;

				if (!result || !result.ok) {
					showMessage({ type: "yellow", title: "Thông báo", message: "Không có dữ liệu từ cửa hàng!" });
					return;
				}

				vueData.DataRaw = [result.times, result.details];
				this.sanitizeReponse(vueData.DataRaw);
				vueData.FilterObject = { ...baseFilter, CuaHangIDs: storeIds };
				return;
			}

			// Nhiều cửa hàng - hiển thị modal progress
			// Set status loading cho tất cả
			for (let i = 0; i < storeIds.length; i++) {
				this.setStatus(storeIds[i], 1);
			}

			this.isLoading = true;
			this.showProgressModal = true;

			// Đợi modal render xong
			await this.$nextTick();

			// Tạo danh sách task để chạy song song
			const CONCURRENCY = 5;
			const tasks = storeIds.map(id => () => this.fetchStore(id, baseFilter));
			const results = await this.runWithConcurrency(tasks, CONCURRENCY);

			// Gom dữ liệu
			const validData = results.filter((r) => r && r.ok);

			// Lấy times từ phần tử đầu tiên (nếu có)
			const times = validData.length > 0 ? validData[0].times : [];

			// Gom toàn bộ details (flatten)
			const details = validData.flatMap(r => r.details || []);

			// Gán DataRaw
			vueData.DataRaw = [times, details];

			this.isLoading = false;

			if (validData.length === 0) {
				showMessage({ type: "yellow", title: "Thông báo", message: "Không có dữ liệu từ các cửa hàng!" });
				return;
			}

			this.sanitizeReponse(vueData.DataRaw);
			vueData.FilterObject = { ...baseFilter, CuaHangIDs: storeIds };
		},

		async fetchStore(CuaHangID, baseFilter) {
			const start = performance.now();
			const startTime = new Date().toLocaleTimeString('vi-VN');
			this.$set(this.storeStartTimes, CuaHangID, startTime);

			try {
				const filter = { ...baseFilter, CuaHangID: CuaHangID };
				const body = JSON.stringify(filter);

				const res = await fetch(vueData.v_Set?.apiDomain + "/eorder/BaoCao_DoanhThu_SanPham_v2", {
					method: "POST",
					headers: {
						"content-type": "application/json; charset=utf-8",
						"authorization": $awt
					},
					body
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
							times: data.data[0] || [],
							details: data.data[1] || []
						};
					} else {
						this.setStatus(CuaHangID, 2);
						this.completedCount += 1;
						return { ok: true, storeId: CuaHangID, times: [], details: [] };
					}
				} else {
					this.setStatus(CuaHangID, 3); // error
					this.$set(this.storeErrors, CuaHangID, `HTTP Error: ${res.status} ${res.statusText}`);
					this.completedCount += 1;
					return { ok: false, storeId: CuaHangID, times: [], details: [] };
				}
			} catch (error) {
				const endTime = new Date().toLocaleTimeString('vi-VN');
				this.$set(this.storeEndTimes, CuaHangID, endTime);
				this.setStatus(CuaHangID, 3); // error
				this.$set(this.storeErrors, CuaHangID, error.message || 'Unknown error');
				this.completedCount += 1;
				return { ok: false, storeId: CuaHangID, times: [], details: [], errMsg: error.message };
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
							.catch(e => { results[current] = { ok: false, storeId: null, errMsg: e?.message || 'error' }; })
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

		async retryStore(id) {
			if (this.isLoading && this.localStatuses[id] === 1) return;

			this.completedCount = Math.max(0, this.completedCount - (this.localStatuses[id] === 2 ? 1 : 0));
			this.setStatus(id, 1);

			const baseFilter = {
				PhanHieuID: this.PhanHieuID,
				KhuVucID: this.KhuVucID,
				HinhThucThanhToan: this.HinhThucThanhToan,
				HinhThucThoiGian: this.HinhThucThoiGian,
				IsSoluong: this.LoaiBaoCao,
				Ngay: this.Ngay,
				TuNgay: this.TuNgay,
				DenNgay: this.DenNgay,
				Nam: this.Nam,
				TuNam: this.TuNam,
				DenNam: this.DenNam,
				Thang: this.Thang
			};

			await this.fetchStore(id, baseFilter);
		},

		sanitizeReponse([dynamicVariables, dataRaw]) {
			vueData.DataExpanded = [];

			// Tạo groupItemReport từ dataRaw (unique theo SanPhamID + PhanHieuID)
			// Lưu ý: chúng ta gộp across CuaHang (tổng các cửa hàng)
			const groupItemReport = [];
			const seen = new Set();
			dataRaw.forEach(e => {
				const key = `sp${e.SanPhamID}_ph${e.PhanHieuID}`;
				if (!seen.has(key)) {
					groupItemReport.push({
						SanPhamID: e.SanPhamID,
						TenSanPham: e.TenSanPham,
						TenPhanHieu: e.TenPhanHieu,
						PhanHieuID: e.PhanHieuID,
						TenNhomSanPhamBaoCao: e.TenNhomSanPhamBaoCao
					});
					seen.add(key);
				}
			});

			const { headers, rows } = this.buildReportTable({ groupItemReport, dynamicVariables, dataRaw });

			vueData.TableHeader = headers;
			vueData.DataReport = rows;
		},

		buildReportTable({ groupItemReport, dynamicVariables, dataRaw }) {
			// Nếu không có cột thời gian
			if (!dynamicVariables || dynamicVariables.length === 0) {
				return { headers: this.headerDefault, rows: [] };
			}

			const [aliasKey] = Object.keys(dynamicVariables[0]) || [];
			if (!aliasKey) {
				return { headers: this.headerDefault, rows: [] };
			}

			const isDaily = aliasKey === 'Ngay';

			// B1: Đồng bộ dữ liệu: luôn có aliasKey
			const normalizedData = dataRaw.map(e => {
				let timeVal = e[aliasKey];
				if (timeVal === null || timeVal === undefined) {
					timeVal = e.HinhThucThoiGian; // fallback
				}
				return { ...e, [aliasKey]: timeVal };
			});

			// B2: Loại bỏ trùng lặp (sp + ph + ch + time) → tránh cộng dư
			const uniqueMap = new Map();
			normalizedData.forEach(e => {
				// Keep unique at granularity: SanPham + PhanHieu + CuaHang + time
				const keyUnique = `sp${e.SanPhamID}_ph${e.PhanHieuID}_ch${e.CuaHangID}_t${e[aliasKey]}`;
				const giaTriBaoCao = Number(e.GiaTriBaoCao) || 0;
				if (!uniqueMap.has(keyUnique)) {
					uniqueMap.set(keyUnique, { ...e, GiaTriBaoCao: giaTriBaoCao });
				} else {
					const old = uniqueMap.get(keyUnique);
					old.GiaTriBaoCao = (old.GiaTriBaoCao || 0) + giaTriBaoCao;
					uniqueMap.set(keyUnique, old);
				}
			});

			// B3: Gom dữ liệu — **aggregate across CuaHang**: keyAggreg = sp + ph + time (no ch)
			const aggregated = {}; // keyAggreg -> { GiaTriBaoCao: sum }
			for (const val of uniqueMap.values()) {
				const aggKey = `sp${val.SanPhamID}_ph${val.PhanHieuID}_t${val[aliasKey]}`; // NOTE: no ch part -> sum across stores
				if (!aggregated[aggKey]) aggregated[aggKey] = { GiaTriBaoCao: 0 };
				aggregated[aggKey].GiaTriBaoCao += Number(val.GiaTriBaoCao) || 0;
			}

			// B4: Xây dựng header động
			const suffix = this.suffixColumn(aliasKey);
			const prefix = this.preflixColumn(aliasKey);

			vueData.dynamicHeaders = dynamicVariables.map(variable => {
				const value = variable[aliasKey];
				const columnTitle = isDaily ? this.formatDaily(value) : `${prefix} ${value}${suffix}`;
				const columnValue = `${aliasKey}_${value}`;
				return {
					...variable,
					text: columnTitle,
					value: columnValue,
					align: 'right'
				};
			});

			// B5: Chuẩn hóa dữ liệu từng dòng sản phẩm (gộp across stores)
			const dataTable = groupItemReport.map(item => {
				const row = { ...item, sumRevenueCol: 0 };

				vueData.dynamicHeaders.forEach(head => {
					const timeVal = head[aliasKey];
					const keyAgg = `sp${row.SanPhamID}_ph${row.PhanHieuID}_t${timeVal}`; // match aggregated key
					const GiaTriBaoCao = aggregated[keyAgg]?.GiaTriBaoCao || 0;

					row[head.value] = GiaTriBaoCao.toLocaleString("vi-vn");
					row[head.value + '_value'] = GiaTriBaoCao;
					row.sumRevenueCol += GiaTriBaoCao;
				});

				row.sumRevenueFormatted = row.sumRevenueCol.toLocaleString("vi-vn");
				return row;
			});

			// B6: Tổng cộng cuối bảng
			const totalRow = { TenSanPham: 'Tổng', sumRevenueCol: 0 };
			totalRow.sumRevenueCol = dataTable.reduce((sum, r) => sum + (r.sumRevenueCol || 0), 0);
			totalRow.sumRevenueFormatted = totalRow.sumRevenueCol.toLocaleString("vi-vn");

			vueData.dynamicHeaders.forEach(head => {
				const total = dataTable.reduce((sum, row) => sum + (row[head.value + '_value'] || 0), 0);
				totalRow[head.value + '_value'] = total;
				totalRow[head.value] = total.toLocaleString("vi-vn");
			});

			dataTable.push(totalRow);

			// Debug logs
			let debugSum = 0;
			for (const k in aggregated) {
				debugSum += aggregated[k].GiaTriBaoCao || 0;
			}
			console.log("DEBUG Tổng từ aggregated =", debugSum);
			console.log("DEBUG Tổng cuối bảng =", totalRow.sumRevenueCol);

			return {
				headers: [...this.headerDefault, ...vueData.dynamicHeaders],
				rows: dataTable
			};
		},

		suffixColumn(col) {
			if (col === 'Gio') return 'H';
			return '';
		},
		preflixColumn(col) {
			switch (col) {
				case 'Tuan': return 'Tuần';
				case 'Thang': return 'Tháng';
				case 'Quy': return 'Quý';
				default: return '';
			}
		},
		formatDaily(str) {
			return moment(str).format("D/M");
		},
		formatString(str) {
			if (!str) return;

			return str
				.normalize("NFD")
				.replace(/[\u0300-\u036f]/g, "")
				.replace(/[^a-zA-Z0-9 ]/g, "")
				.trim()
				.replace(/\s+/g, "_");
		}
	}
}
</script>