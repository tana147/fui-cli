<template>
	<div
		style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding-right: 4px; padding-top: 12px;">
		<v-row class="mb-1">
			<v-col cols="6">
				<v-select :items="heArr" label="Lọc theo ngành" outlined dense v-model="major" multiple
					small-chips item-text="TenNganh" item-value="NganhID" hide-details />
			</v-col>
			<v-col cols="6">
				<v-autocomplete v-model="nienKhoa" :items="DsNienKhoa" item-text="TenNienKhoa" item-value="NienKhoa"
					outlined multiple small-chips dense hide-details placeholder="Chọn niên khóa"
					label="Niên khóa" />
			</v-col>
			<v-col cols="5">
				<v-autocomplete v-model="taskFilter" outlined dense hide-details label="Lọc theo bước"
					:items="filteredTasks" item-text="Display_Name" item-value="Task_Name" />
			</v-col>
			<v-col cols="7">
				<div class="d-flex align-start">
					<div class="ml-3 flex-grow-1">
						<v-btn v-if="isXetTotNghiep" @click="onPrintTotalListExcel" :loading="isLoading" color="success"
							class="mb-1">
							<v-icon left>mdi-microsoft-excel</v-icon>
							Xuất file đăng ký tốt nghiệp
						</v-btn>

						<div v-if="showExportProgress" class="mt-1">
							<div class="d-flex justify-space-between caption grey--text text--darken-2 mb-1"
								style="font-size: 12px; line-height: 1">
								<span>Đang trích xuất Excel...</span>
								<strong>{{ Math.ceil(exportProgress) }}%</strong>
							</div>
							<v-progress-linear v-model="exportProgress" color="success" height="6" rounded striped />
						</div>
					</div>

					<div class="d-flex ml-auto">
						<v-btn @click="applyFilters" color="primary">
							<v-icon left>mdi-filter</v-icon>
							Lọc
						</v-btn>
					</div>
				</div>
			</v-col>
		</v-row>
		<v-data-table :headers="headerTable" :items="DSFlowStatusFilter" class="elevation-1 flex-grow-1" dense
			hide-default-footer fixed-header height="calc(100vh - 332px)"
			:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" :items-per-page="-1"
			style="border: 1px solid #dbe7ee !important;">
			<template v-slot:top>
				<v-toolbar flat dense color="transparent">
					<v-toolbar-title class="subtitle-1 font-weight-bold">{{ labelTable }}</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm nhanh..."
						single-line hide-details dense class="uc-ar-underline-search" style="max-width: 300px;">
					</v-text-field>
				</v-toolbar>
			</template>
			<template v-slot:no-data>
				<c-empty-state text="Chưa có dữ liệu" />
			</template>
			<template v-slot:no-results>
				<c-empty-state text="Không tìm thấy kết quả phù hợp" />
			</template>
			<template v-slot:item.Student_Name="{ item }">
				<div>
					<span class="primary--text"><b>{{ item.Student_Name }}</b></span>
					<br />
					<b>{{ item.Student_ID }}</b> <span class="amber--text text--darken-3">[{{ item.Class_ID }}]</span>
				</div>
			</template>
			<template v-slot:item.Task_Name="{ item }">
				<span class="font-weight-medium">{{ getTaskDisplayName(item) }}</span>
			</template>
			<template v-slot:item.actions="{ item }">
				<v-btn color="success" text small @click="SelectStu(item)">
					Xem chi tiết
				</v-btn>
			</template>
		</v-data-table>
	</div>
</template>

<script>
	export default {
		name: "uc-main-view",
		props: {
			dsFlowStatus: { type: Array, default: () => [] }
		},
		data() {
			return {
				isLoading: false,
				showExportProgress: false,
				exportProgress: 0,
				student: null,
				heArr: [],
				major: [0],
				nienKhoa: ['0'],
				NienKhoaValue: null,
				search: '',
				taskFilter: '- Tất cả -',
				DsNienKhoa: [],
				phdTasksRaw: [],
				appliedFilters: {
					major: [0],
					nienKhoa: ['0'],
					taskFilter: '- Tất cả -',
				},
				headerTable: [
					{ text: 'STT', value: 'STT', align: 'center', width: 70 },
					{ text: 'Học viên', value: 'Student_Name', width: 180 },
					{ text: 'Niên khóa', value: 'Student_Year', align: 'center', width: 100 },
					{ text: 'Bước', value: 'Task_Name', width: 200 },
					{ text: 'Chọn', value: 'actions', align: 'center', sortable: false, width: 110 },
				],
			};
		},
		computed: {
			labelTable() {
				return `Danh sách học viên (${this.DSFlowStatusFilter.length})`;
			},
			isXetTotNghiep() {
				return this.appliedFilters.taskFilter === 'Xét tốt nghiệp';
			},
			filteredTasks() {
				const allOption = { Task_Name: '- Tất cả -', Task_ID: 0, Display_Name: '- Tất cả -' };
				const phdTasksForSelect = this.phdTasksRaw.slice(1).map((t, idx) => ({
					...t,
					Display_Name: `${idx + 1}./ ${t.Task_Name}`
				}));
				return [allOption, ...phdTasksForSelect];
			},
			DSFlowStatusFilter() {
				const dsFlow = this.dsFlowStatus || [];
				const all = '- Tất cả -';
				const { major, nienKhoa, taskFilter } = this.appliedFilters;

				const isAllMajor = major.includes(0) || major.includes('0');
				const majorSet = new Set(major.map(String));

				const isAllNienKhoa = nienKhoa.length === 0 || nienKhoa.includes(0) || nienKhoa.includes('0');
				const nienKhoaSet = new Set(nienKhoa.map(String));

				const isAllTask = !taskFilter || taskFilter === all;
				const s = this.search ? this.search.toLowerCase() : '';

				const filtered = dsFlow.filter((item) => {
					if (!isAllMajor) {
						const itemNganhID = String(item.Nganh_ID !== undefined ? item.Nganh_ID : item.NganhID !== undefined ? item.NganhID : item.Student_Major || '');
						if (!majorSet.has(itemNganhID)) return false;
					}

					if (!isAllNienKhoa) {
						const itemNienKhoa = String(item.NienKhoa !== undefined ? item.NienKhoa : item.Student_Year || '');
						if (!nienKhoaSet.has(itemNienKhoa)) return false;
					}

					if (!isAllTask && item.Task_Name !== taskFilter) {
						return false;
					}

					if (s) {
						const name = String(item.Student_Name || '').toLowerCase();
						const id = String(item.Student_ID || '').toLowerCase();
						const cls = String(item.Class_ID || item.LopID || '').toLowerCase();
						if (!name.includes(s) && !id.includes(s) && !cls.includes(s)) {
							return false;
						}
					}

					return true;
				});

				return this.resetSTT(filtered);
			},
		},
		mounted() {
			this.getHeByID();
			this.onLoadAdminFlow();
			this.getNienKhoa();
		},
		watch: {
			DSFlowStatusFilter: {
				handler() {
					this.$emit('on-select-student', null);
				},
				immediate: true
			},
			major(newVal, oldVal) {
				if (!newVal || newVal.length === 0) {
					this.major = [0];
					return;
				}

				const hadZero = oldVal?.includes(0) || oldVal?.includes('0');
				const hasZero = newVal.includes(0) || newVal.includes('0');

				if (!hadZero && hasZero) {
					this.major = [0];
				} else if (hadZero && hasZero && newVal.length > 1) {
					this.major = newVal.filter((x) => x !== 0 && x !== '0');
				}
			},
			nienKhoa(newVal, oldVal) {
				if (!newVal || newVal.length === 0) {
					this.nienKhoa = ['0'];
					return;
				}

				const hadAll = oldVal?.includes('0') || oldVal?.includes(0);
				const hasAll = newVal.includes('0') || newVal.includes(0);

				if (!hadAll && hasAll) {
					this.nienKhoa = ['0'];
				} else if (hadAll && hasAll && newVal.length > 1) {
					this.nienKhoa = newVal.filter((x) => x !== '0' && x !== 0);
				}
			},
		},
		methods: {
			SelectStu(item) {
				this.$emit('on-select-student', item);
			},
			applyFilters() {
				this.appliedFilters = {
					major: [...this.major],
					nienKhoa: [...this.nienKhoa],
					taskFilter: this.taskFilter
				};
				const nganhId = (this.major.includes(0) || this.major.includes('0') || this.major.length !== 1) ? 0 : this.major[0];
				const nienKhoa = (this.nienKhoa.includes(0) || this.nienKhoa.includes('0') || this.nienKhoa.length !== 1) ? "0" : this.nienKhoa[0];
				this.$emit('on-reload', nganhId, nienKhoa);
			},
			async onLoadDetail(arr) {
				return await ajaxCALLPromise('/Student_Detail_Get', { StudentObjArr: JSON.stringify(arr) });
			},
			async onPrintTotalListExcel() {
				this.isLoading = true;
				this.showExportProgress = true;
				this.exportProgress = 0;

				if (this.DSFlowStatusFilter.length === 0) {
					this.showExportProgress = false;
					Vue.$toast.error('Không có dữ liệu học viên', { position: 'top' });
					this.isLoading = false;
					return;
				}

				const detailData = await this.onLoadDetail(
					this.DSFlowStatusFilter.map(({ Student_ID }) => ({
						StudentID: Student_ID
					}))
				);

				const dataArr = detailData.map((item, index) => ({
					STT: index + 1,
					MSHV: item.StudentID ?? '',
					HoHV: item.HoSV ?? '',
					TenHV: item.TenSV ?? '',
					NgaySinh: this.formatCustomDate(item.NgaySinh),
					NoiSinh: item.NoiSinh ?? '',
					Lop: item.LopID ?? '',
					Nganh: item.TenNganh ?? '',
					DeTai: item.DeTaiTotNghiep ?? '',
					GVHD1: item.CanBoHuongDan1 ?? '',
					GVHD2: item.CanBoHuongDan2 ?? '',
				}));

				try {
					jsonToExcel({
						data: dataArr,
						filename: "Danh_Sach_Tot_Nghiep_Tien_Si.xlsx",
						worksheet: "DanhSach",
					});
				} catch (e) {
					Vue.$toast.error('Lỗi xuất file Excel', { position: 'top' });
				} finally {
					this.isLoading = false;
					this.showExportProgress = false;
				}
			},
			formatCustomDate(dateStr) {
				if (!dateStr) return '';
				if (typeof moment !== 'undefined') {
					const date = moment(dateStr, ['YYYY-MM-DD', 'DD/MM/YYYY', moment.ISO_8601], true);
					if (date.isValid()) return date.format('DD/MM/YYYY');
				}
				return dateStr;
			},
			async getNienKhoa() {
				try {
					const res = await ajaxGETCALLPromise(`https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa`);
					if (res && res.data) {
						const obj = {
							TenNienKhoa: '- Tất cả -',
							NienKhoa: '0',
						};
						this.DsNienKhoa = res.data.map((item) => ({
							...item,
							TenNienKhoa: item.NienKhoa,
							NienKhoa: item.NienKhoa,
						}));
						this.DsNienKhoa.unshift(obj);
						this.NienKhoaValue = this.DsNienKhoa[0]?.NienKhoa;
					}
				} catch (error) {
					Vue.$toast.error('Lỗi tải niên khóa', { position: 'top' });
				}
			},
			resetSTT(ds) {
				ds.forEach((item, index) => {
					item.STT = index + 1;
				});
				return ds;
			},
			async getHeByID() {
				try {
					const res = await ajaxCALLPromise('/Nganh_Get_ByHeID', { HeID: 'N' });
					const allListObj = {
						NganhID: 0,
						TenNganh: '- Tất cả -',
					};
					const mapped = (res || []).map((item) => ({
						...item,
						NganhID: item.Nganh_ID,
						TenNganh: item.Ten_Nganh_HienThi || item.Ten_Nganh,
					}));
					mapped.unshift(allListObj);
					this.heArr = mapped;
				} catch (error) {
					Vue.$toast.error('Lỗi tải ngành đào tạo Tiến sĩ', { position: 'top' });
				}
			},
			async onLoadAdminFlow() {
				try {
					const res = await ajaxCALLPromise('/Admin_Flow_Get');
					this.phdTasksRaw = res[4] ? [...res[4]] : [];
				} catch (error) {
					console.error('fail to load list', error);
				}
			},
			getTaskDisplayName(item) {
				if (!item || !item.Task_Name) return '';
				const idx = this.phdTasksRaw.slice(1).findIndex(t => t.Task_ID === item.Task_ID || t.Task_Name === item.Task_Name);
				if (idx !== -1) {
					return `${idx + 1}./ ${item.Task_Name}`;
				}
				if (item.Seq) {
					return `${Math.floor(item.Seq / 10)}./ ${item.Task_Name}`;
				}
				return item.Task_Name;
			},
		},
	}
</script>