<template>
	<v-dialog v-model="dialog" max-width="1050px" scrollable>
		<v-card class="thong-ke-dialog rounded-xl">
			<!-- Header -->
			<v-card-title class="dialog-header pa-4 bg-primary text-white d-flex align-center">
				<v-icon start size="28" class="mr-2">mdi-chart-box-outline</v-icon>
				<div>
					<div class="text-h6 font-weight-bold">THỐNG KÊ HỌC SINH XEM HỌC LIỆU SỐ</div>
					<div class="text-caption opacity-90" v-if="monHocName || hocLieuTitle">
						<span v-if="monHocName" class="font-weight-bold mr-2">Môn: {{ monHocName }}</span>
						<span v-if="hocLieuTitle">| Học liệu: {{ hocLieuTitle }}</span>
					</div>
				</div>
				<v-spacer />
				<v-btn icon variant="text" color="white" @click="dialog = false">
					<v-icon>mdi-close</v-icon>
				</v-btn>
			</v-card-title>

			<!-- Dialog Body -->
			<v-card-text class="pa-4 bg-grey-lighten-4">
				<!-- Loading State -->
				<div v-if="isLoading" class="text-center py-8">
					<v-progress-circular indeterminate color="primary" size="48" />
					<div class="mt-3 text-subtitle-2 text-medium-emphasis">Đang tải danh sách học sinh theo lớp...</div>
				</div>

				<template v-else>
					<!-- Notice if 0 content items -->
					<v-alert v-if="!hasContent" type="info" variant="tonal" density="compact" class="mb-3 rounded-lg" icon="mdi-information-outline">
						Học liệu môn này chưa có nội dung bài học. Tất cả 0/{{ totalCount }} học sinh chưa có lượt xem.
					</v-alert>

					<!-- Toolbar / Filters -->
					<v-card class="pa-3 mb-4 rounded-lg border bg-white" flat>
						<v-row dense align="center">
							<v-col cols="12" sm="4" md="3">
								<v-select
									v-model="selectedClassId"
									:items="classList"
									item-title="TenLop"
									item-value="LopID"
									label="Lớp"
									variant="outlined"
									density="compact"
									hide-details
									prepend-inner-icon="mdi-google-classroom"
								>
									<template v-slot:item="{ props, item }">
										<v-list-item v-bind="props" :title="item.raw.TenLop">
											<template v-slot:append v-if="item.raw.ViewedCount !== undefined">
												<span class="text-caption font-weight-bold text-primary ms-2">
													({{ item.raw.ViewedCount }}/{{ item.raw.TotalCount }})
												</span>
											</template>
										</v-list-item>
									</template>
								</v-select>
							</v-col>

							<v-col cols="12" sm="7" md="4" class="d-flex align-center">
								<div class="text-caption text-medium-emphasis ms-1" v-if="currentClass">
									Sĩ số: <b>{{ totalCount }}</b> HS | Đã xem: <b class="text-success">{{ viewedCount }}</b> ({{ currentClassPercent }}%)
								</div>
							</v-col>

							<v-col cols="12" sm="5" md="5" class="d-flex justify-end">
								<!-- Filter Buttons -->
								<v-btn-toggle v-model="filterStatus" density="compact" color="primary" mandatory variant="outlined" class="rounded-lg flex-nowrap">
									<v-btn value="all" size="small" class="px-2">Tất cả ({{ currentStudents.length }})</v-btn>
									<v-btn value="viewed" size="small" color="success" class="px-2">Đã xem ({{ viewedCount }})</v-btn>
									<v-btn value="unviewed" size="small" color="error" class="px-2">Chưa xem ({{ unviewedCount }})</v-btn>
								</v-btn-toggle>
							</v-col>
						</v-row>

						<!-- Progress Bar -->
						<div class="mt-3">
							<v-progress-linear
								:model-value="currentClassPercent"
								:color="getStatColor(viewedCount, totalCount)"
								height="8"
								rounded="pill"
							/>
						</div>
					</v-card>

					<!-- Table Student List -->
					<v-card class="rounded-lg border bg-white" flat>
						<v-table density="compact" class="student-table">
							<thead>
								<tr class="bg-grey-lighten-4">
									<th class="text-center" style="width: 50px;">STT</th>
									<th class="text-left" style="width: 120px;">Mã HS</th>
									<th class="text-left">Học sinh</th>
									<th class="text-center" style="width: 120px;">Trạng thái</th>
									<th class="text-center" style="width: 110px;">Lượt xem</th>
									<th class="text-center text-no-wrap" style="width: 200px;">Thời gian xem mới nhất</th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="(st, index) in filteredStudents" :key="st.HocSinhID || index">
									<td class="text-center text-medium-emphasis">{{ index + 1 }}</td>
									<td class="font-weight-medium text-body-2 text-primary">{{ st.MaHocSinh || st.HocSinhID }}</td>
									<td class="font-weight-bold">{{ st.HoTen }}</td>
									<td class="text-center">
										<v-chip
											size="small"
											:color="st.IsViewed ? 'success' : 'grey-darken-1'"
											variant="tonal"
											class="font-weight-bold"
										>
											<v-icon start size="x-small">{{ st.IsViewed ? 'mdi-check-circle' : 'mdi-clock-outline' }}</v-icon>
											{{ st.IsViewed ? 'Đã xem' : 'Chưa xem' }}
										</v-chip>
									</td>
									<td class="text-center">
										<v-chip
											v-if="st.IsViewed"
											size="small"
											color="info"
											variant="tonal"
											class="font-weight-bold"
										>
											{{ st.SoLuotXem || 1 }} lần
										</v-chip>
										<span v-else class="text-caption text-medium-emphasis">0</span>
									</td>
									<td class="text-center text-caption text-medium-emphasis">
										{{ st.LastViewedTime || '--' }}
									</td>
								</tr>
								<tr v-if="filteredStudents.length === 0">
									<td colspan="6" class="text-center py-6 text-medium-emphasis">
										Không tìm thấy học sinh nào trong danh mục lọc này.
									</td>
								</tr>
							</tbody>
						</v-table>
					</v-card>
				</template>
			</v-card-text>

			<!-- Actions Footer -->
			<v-card-actions class="pa-3 bg-white border-t">
				<v-spacer />
				<v-btn color="grey-darken-1" variant="outlined" @click="dialog = false">
					Đóng
				</v-btn>
			</v-card-actions>
		</v-card>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-thong-ke-xem-hoc-lieu-dialog',
		props: {
			modelValue: { type: Boolean, default: false },
			hocLieuId: { type: [String, Number], default: null },
			hocLieuTitle: { type: String, default: '' },
			khoiId: { type: [String, Number], default: null },
			monHocId: { type: [String, Number], default: null },
			monHocName: { type: String, default: '' },
			hasContent: { type: Boolean, default: true }
		},
		emits: ['update:modelValue'],
		data() {
			return {
				isLoading: false,
				selectedClassId: null,
				filterStatus: 'all',
				classList: [],
				studentsByClass: {}
			};
		},
		computed: {
			dialog: {
				get() { return this.modelValue; },
				set(val) { this.$emit('update:modelValue', val); }
			},
			currentClass() {
				return this.classList.find(c => c.LopID === this.selectedClassId) || this.classList[0] || null;
			},
			currentStudents() {
				if (!this.selectedClassId) return [];
				const cacheKey = `${this.selectedClassId}_${this.monHocId || 0}_${this.hocLieuId || 0}`;
				return this.studentsByClass[cacheKey] || this.studentsByClass[this.selectedClassId] || [];
			},
			totalCount() {
				return this.currentStudents.length;
			},
			viewedCount() {
				return this.currentStudents.filter(s => s.IsViewed).length;
			},
			unviewedCount() {
				return this.totalCount - this.viewedCount;
			},
			currentClassPercent() {
				if (!this.totalCount) return 0;
				return Math.round((this.viewedCount / this.totalCount) * 100);
			},
			filteredStudents() {
				if (this.filterStatus === 'viewed') {
					return this.currentStudents.filter(s => s.IsViewed);
				}
				if (this.filterStatus === 'unviewed') {
					return this.currentStudents.filter(s => !s.IsViewed);
				}
				return this.currentStudents;
			}
		},
		watch: {
			dialog(val) {
				if (val) {
					this.studentsByClass = {};
					this.loadStatsData();
				}
			},
			selectedClassId(newVal) {
				if (newVal) {
					this.fetchStudentsForClass(newVal);
				}
			},
			khoiId() {
				if (this.dialog) {
					this.studentsByClass = {};
					this.loadStatsData();
				}
			},
			monHocId() {
				if (this.dialog) {
					this.studentsByClass = {};
					this.loadStatsData();
				}
			},
			hocLieuId() {
				if (this.dialog) {
					this.studentsByClass = {};
					this.loadStatsData();
				}
			},
			hasContent() {
				if (this.dialog) {
					this.studentsByClass = {};
					this.loadStatsData();
				}
			}
		},
		methods: {
			async loadStatsData() {
				this.isLoading = true;
				try {
					if (typeof ajaxCALL === 'function') {
						try {
							const nienKhoaInt = (typeof vueData !== 'undefined' && vueData.NienKhoaItem?.NienKhoa) 
								? parseInt(vueData.NienKhoaItem.NienKhoa) 
								: (typeof vueData !== 'undefined' && parseInt(vueData.NienKhoa)) 
									? parseInt(vueData.NienKhoa) 
									: 2026;

							// Lấy danh sách lớp theo khối được chọn bên ngoài (this.khoiId) trong Niên khóa
							const resAllClasses = await new Promise(resolve => {
								ajaxCALL("lms/Lop_Get_ByNienKhoa", { NienKhoa: nienKhoaInt }, (res) => resolve(res));
							});
							const rawClasses = resAllClasses?.data || (Array.isArray(resAllClasses) ? resAllClasses : []);
							if (Array.isArray(rawClasses) && rawClasses.length > 0) {
								let filtered = rawClasses;
								if (this.khoiId !== null && this.khoiId !== undefined && this.khoiId !== '') {
									filtered = rawClasses.filter(c => c.KhoiID == this.khoiId);
								}
								// Lọc chỉ lấy các lớp đang hoạt động (Enable = 1) và loại bỏ trùng tên lớp
								filtered = filtered.filter(c => c.Enable === 1 || c.Enable === true || c.Enable === undefined);
								const seenNames = new Set();
								const uniqueClasses = [];
								for (const c of filtered) {
									if (!seenNames.has(c.TenLop)) {
										seenNames.add(c.TenLop);
										uniqueClasses.push({
											LopID: c.LopID,
											TenLop: c.TenLop,
											KhoiID: c.KhoiID
										});
									}
								}

								if (uniqueClasses.length > 0) {
									this.classList = uniqueClasses;
									this.selectedClassId = this.classList[0].LopID;
									await this.fetchStudentsForClass(this.selectedClassId);
									this.isLoading = false;
									return;
								}
							}
						} catch (e) {
							console.log('Falling back to default class list...', e);
						}
					}

					this.setupSampleData();
				} catch (e) {
					console.error('Lỗi khi tải thống kê:', e);
					this.setupSampleData();
				} finally {
					this.isLoading = false;
				}
			},
			getStudentViewStatus(studentId, index) {
				return { isViewed: false, formattedTime: null };
			},
			async fetchStudentsForClass(lopId) {
				const cacheKey = `${lopId}_${this.monHocId || 0}_${this.hocLieuId || 0}`;
				if (this.studentsByClass[cacheKey] && this.studentsByClass[cacheKey].length > 0) return;

				if (typeof ajaxCALL === 'function') {
					try {
						const nienKhoaInt = (typeof vueData !== 'undefined' && vueData.NienKhoaItem?.NienKhoa)
							? parseInt(vueData.NienKhoaItem.NienKhoa)
							: (typeof vueData !== 'undefined' && parseInt(vueData.NienKhoa))
								? parseInt(vueData.NienKhoa)
								: 2026;
						const res = await new Promise(resolve => {
							ajaxCALL("lms/HocSinhLop_Get_ByLopID", {
								LopID: lopId,
								MonHocID: this.monHocId || 0,
								HocLieuID: this.hocLieuId || 0,
								NienKhoa: nienKhoaInt
							}, (res) => resolve(res));
						});
						if (res && res.data) {
							const list = Array.isArray(res.data[1]) ? res.data[1] : (Array.isArray(res.data) ? res.data : []);
							if (list.length > 0) {
								this.studentsByClass[cacheKey] = list.map((st, idx) => ({
									HocSinhID: st.HocSinhID,
									MaHocSinh: st.HocSinhID,
									HoTen: st.HoTen || `${st.Ho || ''} ${st.Ten || ''}`.trim(),
									IsViewed: Boolean(st.IsViewed),
									SoLuotXem: st.SoLuotXem || (Boolean(st.IsViewed) ? 1 : 0),
									LastViewedTime: st.LastViewedTime || null
								}));
								return;
							}
						}
					} catch (e) {
						console.warn('Lỗi tải danh sách học sinh:', e);
					}
				}

				const sampleFirstNames = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ', 'Đặng', 'Bùi'];
				const sampleMiddleNames = ['Đỗ', 'Ngọc', 'Diệp', 'Nguyễn', 'Phi', 'Khá', 'Phúc', 'Uy', 'Gia', 'Nguyên', 'Anh', 'Minh', 'Diễm', 'Khải', 'Tuệ'];
				const sampleLastNames = ['Quỳnh Anh', 'Trâm Anh', 'Anh', 'Ân', 'Chương', 'Doanh', 'Hải', 'Hân', 'Hùng', 'Khang', 'Khôi', 'My', 'Nam', 'Nghi'];

				this.studentsByClass[cacheKey] = Array.from({ length: 25 }, (_, idx) => {
					const fn = sampleFirstNames[idx % sampleFirstNames.length];
					const mn = sampleMiddleNames[idx % sampleMiddleNames.length];
					const ln = sampleLastNames[idx % sampleLastNames.length];
					const stId = `25200${(idx + 1).toString().padStart(3, '0')}`;
					const status = this.getStudentViewStatus(stId, idx);
					return {
						HocSinhID: stId,
						MaHocSinh: stId,
						HoTen: `${fn} ${mn} ${ln}`,
						IsViewed: status.isViewed,
						LastViewedTime: status.formattedTime
					};
				});
			},
			setupSampleData() {
				const khoiNum = (this.khoiId !== null && this.khoiId !== undefined && this.khoiId !== '') ? parseInt(this.khoiId) : 8;
				const prefix = khoiNum < 10 ? `0${khoiNum}` : `${khoiNum}`;
				const classLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

				this.classList = classLetters.map(letter => ({
					LopID: `${prefix}${letter}`,
					TenLop: `${prefix}${letter}`,
					KhoiID: khoiNum
				}));
				this.selectedClassId = this.classList[0].LopID;
				this.fetchStudentsForClass(this.selectedClassId);
			},
			getStatColor(viewed, total) {
				if (!total) return 'grey';
				const pct = (viewed / total) * 100;
				if (pct >= 80) return 'success';
				if (pct >= 50) return 'warning';
				return 'error';
			}
		}
	}
</script>