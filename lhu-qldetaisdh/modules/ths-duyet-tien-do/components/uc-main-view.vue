<template>
	<div style="height: 100%; display: flex; flex-direction: column; overflow: hidden; padding-right: 4px; padding-top: 12px;">
		<v-row class="mb-1 shrink">
			<v-col cols="7">
				<v-select :items="heArr" label="Lọc theo ngành" outlined dense v-model="major" multiple
					small-chips item-text="TenNganh" item-value="NganhID" hide-details />
			</v-col>
			<v-col cols="5">
				<v-autocomplete v-model="nienKhoa" :items="DsNienKhoa" item-text="TenNienKhoa" item-value="NienKhoa"
					outlined multiple small-chips dense hide-details placeholder="Chọn niên khóa"
					label="Niên khóa" />
			</v-col>
			<v-col cols="4">
				<v-autocomplete v-model="taskFilter" outlined dense hide-details label="Lọc theo bước"
					:items="rootList" item-text="Task_Name" item-value="Task_Name" />
			</v-col>
			<v-col cols="8">
				<div class="d-flex align-center justify-end flex-nowrap">
					<v-btn v-if="isXetTotNghiep" @click="onPrintTotalListExcel" :loading="isLoading" color="success"
						class="mr-2 text-no-wrap">
						<v-icon left>mdi-microsoft-excel</v-icon>
						Xuất file đăng ký tốt nghiệp
					</v-btn>

					<v-btn @click="applyFilters" color="primary" class="text-no-wrap">
						<v-icon left>mdi-filter</v-icon>
						Lọc
					</v-btn>
				</div>

				<div v-if="showExportProgress" class="mt-1">
					<div class="d-flex justify-space-between caption grey--text text--darken-2 mb-1"
						style="font-size: 12px; line-height: 1">
						<span>Đang trích xuất Excel...</span>
						<strong>{{ Math.ceil(exportProgress) }}%</strong>
					</div>
					<v-progress-linear v-model="exportProgress" color="success" height="6" rounded striped />
				</div>
			</v-col>
		</v-row>

		<v-data-table :headers="headerTable" :items="DSFlowStatusFilter" class="elevation-1 flex-grow-1" dense
			hide-default-footer fixed-header height="calc(100vh - 332px)"
			:footer-props="{ 'items-per-page-options': [50, 100, 150, -1] }" :items-per-page="-1"
			style="border: 1px solid #dbe7ee !important;">
			<template v-slot:top>
				<v-toolbar flat dense color="transparent" class="flex-nowrap">
					<v-toolbar-title class="subtitle-1 font-weight-bold text-no-wrap">{{ labelTable }}</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-text-field v-model="search" prepend-inner-icon="mdi-magnify" label="Tìm kiếm nhanh..."
						single-line hide-details dense class="c-underline-search" style="max-width: 250px;">
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
				<div class="py-1">
					<span class="primary--text font-weight-bold">{{ item.Student_Name }}</span>
					<br />
					<span class="font-weight-bold">{{ item.Student_ID }}</span>
					<span class="amber--text text--darken-3"> [{{ item.Class_ID }}]</span>
				</div>
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
			dsFlowStatus: { type: Array, default: () => [] },
			dsNotFinishFlowStatus: { type: Array, default: () => [] }
		},
		emits: ['on-select-student', 'on-reload'],
		data() {
			return {
				isLoading: false,
				showExportProgress: false,
				exportProgress: 0,
				heArr: [],
				major: [0],
				nienKhoa: ['0'],
				rootList: [],
				search: '',
				taskFilter: '',
				DsNienKhoa: [],
				appliedFilters: {
					major: [0],
					nienKhoa: ['0'],
					taskFilter: ''
				},
				headerTable: [
					{ text: 'STT', value: 'STT', align: 'center', width: 60, class: 'text-no-wrap' },
					{ text: 'Học viên', value: 'Student_Name', align: 'start', width: 170, class: 'text-no-wrap' },
					{ text: 'Niên khóa', value: 'Student_Year', align: 'center', width: 100, class: 'text-no-wrap' },
					{ text: 'Bước', value: 'Task_Name', align: 'start', width: 170, class: 'text-no-wrap' },
					{ text: 'Chọn', value: 'actions', align: 'center', sortable: false, width: 110, class: 'text-no-wrap' },
				],
			};
		},
		computed: {
			labelTable() {
				return `Danh sách học viên (${this.DSFlowStatusFilter.length})`;
			},
			isXetTotNghiep() {
				const task = (this.appliedFilters?.taskFilter || this.taskFilter || '').trim().toLowerCase();
				return task === 'xét tốt nghiệp' || task.includes('xét tốt nghiệp');
			},
			DSFlowStatusFilter() {
				const list = this.dsFlowStatus || [];
				const s = (this.search || '').trim().toLowerCase();
				const major = this.appliedFilters.major;
				const nienKhoa = this.appliedFilters.nienKhoa;
				const taskFilter = this.appliedFilters.taskFilter;
				const isAllMajor = !major || major.length === 0 || major.includes(0) || major.includes('0');
				const isAllNienKhoa = !nienKhoa || nienKhoa.length === 0 || nienKhoa.includes(0) || nienKhoa.includes('0');
				const isAllTask = !taskFilter || taskFilter === '- Tất cả -';

				const filtered = list.filter((item) => {
					if (!isAllMajor) {
						const itemNganhID = item.Nganh_ID !== undefined ? item.Nganh_ID : item.NganhID !== undefined ? item.NganhID : item.Student_Major;
						if (!major.some((m) => String(m) === String(itemNganhID))) {
							return false;
						}
					}

					if (!isAllNienKhoa) {
						const itemNienKhoa = item.NienKhoa !== undefined ? item.NienKhoa : item.Student_Year;
						if (!nienKhoa.some((n) => String(n) === String(itemNienKhoa))) {
							return false;
						}
					}

					if (!isAllTask) {
						if (taskFilter === 'Đăng ký bảo vệ Luận Văn Thạc sĩ') {
							if (item.Task_Name !== taskFilter && item.Task_Name !== 'Đăng ký bảo vệ Đồ án Thạc sĩ') {
								return false;
							}
						} else if (item.Task_Name !== taskFilter) {
							return false;
						}
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
		async mounted() {
			await Promise.all([
				this.getHeByID(),
				this.onLoadAdminFlow(),
				this.getNienKhoa()
			]);
		},
		watch: {
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
			resetSTT(arr) {
				return (arr || []).map((item, index) => ({
					...item,
					STT: index + 1
				}));
			},
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
				if (this.appliedFilters.taskFilter !== this.taskFilter) {
					this.applyFilters();
				}

				this.isLoading = true;
				this.showExportProgress = true;
				this.exportProgress = 0;

				if (this.DSFlowStatusFilter.length === 0) {
					this.showExportProgress = false;
					Vue.$toast.error('Không có dữ liệu học viên', { position: 'top' });
					this.isLoading = false;
					return;
				}

				try {
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
						GioiTinh: item.GioiTinh ?? '',
						NgaySinh: item.NgaySinh ?? '',
						Nganh: item.TenNganh ?? '',
						TenDeTai: item.ThesisName ?? '',
						GVHD_1: item.ThesisesProf1 ?? '',
						GVHD_2: item.ThesisesProf2 ?? '',
						NienKhoa: item.NienKhoa ?? '',
						LopID: item.LopID ?? '',
						DiemBaoVe: item.DiemHoiDong ? parseFloat(item.DiemHoiDong).toFixed(1) : '0.0',
						SoDT: item.SoDienThoai ?? '',
						Email: item.Email ?? '',
						DiaChiLienHe: item.DiaChiLienHe ?? '',
						ChucVu: item.ChucVu ?? '',
						DonViCongTac: item.DonViCongTac ?? '',
						LoaiNgoaiNgu: item.TenNgoaiNguDauRa ?? '',
						TenNgoaiNguDauRa: item.VanBangChungChiDauRa ?? '',
						ThoiGianCapDauRa: item.ThoiGianCapDauRa ? this.formatCustomDate(item.ThoiGianCapDauRa) : '',
					}));

					jsonToExcel({
						data: dataArr,
						filename: `Danh_sach_tot_nghiep_${moment().format('YYYYMMDD')}.xlsx`,
						worksheet: 'DS_TotNghiep'
					});
				} catch (error) {
					console.log('Error export excel', error);
					Vue.$toast.error('Lỗi xuất file Excel', { position: 'top' });
				} finally {
					this.isLoading = false;
					this.showExportProgress = false;
				}
			},
			formatCustomDate(dateString) {
				return dateString ? moment(dateString).format('DD/MM/YYYY') : '';
			},
			async getHeByID() {
				this.heArr = await getNganhCaoHocPromise({ hasAllOption: true });
			},
			async getNienKhoa() {
				const res = await ajaxGETCALLPromise('https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa');
				const list = (res && res.data) ? res.data : [];
				const obj = {
					TenNienKhoa: '- Tất cả -',
					NienKhoa: '0',
				};
				this.DsNienKhoa = list.map((item) => ({
					...item,
					TenNienKhoa: item.NienKhoa,
					NienKhoa: item.NienKhoa,
				}));
				this.DsNienKhoa.unshift(obj);
			},
			async onLoadAdminFlow() {
				try {
					const res = await ajaxCALLPromise('/Admin_Flow_Get', null);
					if (res && res[2]) {
						this.rootList = [...res[2]];
						this.rootList.splice(0, 1);
						const allListObj = { Task_Name: '- Tất cả -', Task_ID: 0 };
						this.rootList.unshift(allListObj);
					}
				} catch (error) {
					console.error('Error onLoadAdminFlow', error);
				}
			},
		},
	}
</script>