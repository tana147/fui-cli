<template>
	<div class="pa-2 d-flex flex-column" style="height: calc(100vh - 40px); min-height: 0; width: 100%;">
		<v-card class="pa-2 mb-2 flex-shrink-0" elevation="0">
			<div class="text-h6 mb-2">Thống kê xếp loại theo môn học</div>
			<v-row dense align="center">
				<v-col cols="12" sm="6" md="2">
					<v-select
						v-model="SelectedNienKhoa"
						:items="yearItems"
						item-title="title"
						item-value="value"
						label="Niên khóa"
						variant="outlined"
						density="compact"
						hide-details
					/>
				</v-col>
				<v-col cols="12" sm="6" md="3">
					<v-select
						v-model="SelectedMonHocID"
						:items="subjectSelectItems"
						item-title="title"
						item-value="value"
						label="Môn học"
						variant="outlined"
						density="compact"
						hide-details
						:disabled="isLoading || !DSMonHoc.length"
					>
		<!-- Vuetify 3.5 exposes the source option as item.raw; props carries the list's selection and keyboard handlers. -->
		<template v-slot:item="{ props, item }">
			<v-list-item
				v-bind="props"
				:title="item.raw.name || item.title"
				:subtitle="item.raw.levelTitle"
				density="compact"
			/>
						</template>
					</v-select>
				</v-col>
				<v-col cols="12" sm="6" md="2">
					<v-select
						v-model="SelectedKhoiID"
						:items="gradeItems"
						item-title="title"
						item-value="value"
						label="Khối"
						:disabled="isLoading"
						variant="outlined"
						density="compact"
						hide-details
					/>
				</v-col>
				<v-col cols="12" sm="6" md="2">
					<v-select
						v-model="MaCotDiem"
						:items="DSCotDiem"
						item-title="title"
						item-value="value"
						label="Học kì"
						variant="outlined"
						density="compact"
						hide-details
					/>
				</v-col>
				<v-col cols="12" md="3" class="d-flex align-center flex-wrap">
					<v-btn color="primary" variant="outlined" prepend-icon="mdi-magnify" :loading="isLoading" @click="onSearch">
						Xem báo cáo
					</v-btn>
					<v-btn
						class="ml-2"
						color="primary"
						variant="text"
						prepend-icon="mdi-microsoft-excel"
						:disabled="isLoading || !DataBaoCao.length"
						@click="onExportExcel"
					>
						Xuất Excel
					</v-btn>
				</v-col>
			</v-row>
			<div class="text-caption mt-2">
				<v-icon icon="mdi-information-outline" />
				Giỏi ≥ 8; Khá từ 6,5 đến dưới 8; Trung bình từ 5 đến dưới 6,5; Yếu từ 3,5 đến dưới 5; Kém dưới 3,5. Tỉ lệ tính trên học sinh đã có điểm; môn chưa cấu hình cột điểm số sẽ không xếp loại được.
			</div>
		</v-card>

		<v-alert v-if="errorMessage" class="mb-2" type="error" variant="tonal" density="compact">
			{{ errorMessage }}
		</v-alert>

		<template v-if="!errorMessage && DataBaoCao.length">
			<v-card class="flex-grow-1 d-flex flex-column" style="min-height: 0; overflow: hidden;" elevation="0">
				<div class="d-flex align-center flex-wrap pa-2 flex-shrink-0">
					<div class="font-weight-medium">
						{{ selectedSubjectTitle }} · {{ selectedScoreTitle }} · {{ selectedKhoiTitle }} · Niên khóa {{ SelectedNienKhoa }}-{{ SelectedNienKhoa + 1 }}
					</div>
				</div>

				<v-tabs v-model="currentTab" color="primary" density="compact" class="flex-shrink-0">
					<v-tab v-for="scope in visibleScopes" :key="scope.value" :value="scope.value">{{ scope.title }}</v-tab>
				</v-tabs>
				<v-divider />

				<v-tabs-window v-model="currentTab" class="flex-grow-1" style="min-height: 0; overflow: hidden;">
					<v-tabs-window-item v-for="scope in visibleScopes" :key="scope.value" :value="scope.value" class="d-flex flex-column" style="height: 100%; min-height: 0;">
						<div class="text-caption pa-2 flex-shrink-0">{{ scope.description }}</div>
						<div class="overflow-x-auto flex-grow-1" style="min-height: 0;">
							<!-- Grouped score bands follow the spreadsheet columns; each band is split into count and percentage. -->
							<!-- A concrete viewport height lets the fixed-header table scroll its own body. -->
							<v-table density="compact" fixed-header height="calc(100vh - 300px)" class="w-100 text-no-wrap" style="height: calc(100vh - 300px);">
								<thead>
									<tr>
										<th rowspan="2" class="text-center">STT</th>
										<!-- Scope 3 maps tblNhom.TenNhom to TenDoiTuong; class scopes map tblLop.TenLop to the same API field. -->
										<th rowspan="2">{{ scope.value === 3 ? 'Tên nhóm môn học' : 'Lớp' }}</th>
										<th rowspan="2" class="text-center">Khối</th>
										<th rowspan="2" class="text-center">Sĩ số</th>
										<th rowspan="2" class="text-center">Đã có điểm</th>
										<th rowspan="2" class="text-center">Chưa có điểm</th>
										<th rowspan="2" class="text-center">Điểm TB</th>
										<th v-for="category in visibleCategoriesByScope[scope.value]" :key="category.key" colspan="2" class="text-center">
											{{ category.title }}
										</th>
									</tr>
									<tr>
										<template v-for="category in visibleCategoriesByScope[scope.value]" :key="category.key">
											<th class="text-center">SL</th>
											<th class="text-center">TL</th>
										</template>
									</tr>
								</thead>
							<tbody>
									<!-- Show a subtotal after each grade before the scope-wide grand total. -->
									<template v-for="gradeGroup in gradeGroupsByScope(scope.value)" :key="scope.value + '-grade-' + gradeGroup.KhoiID">
										<tr v-for="(row, rowIndex) in gradeGroup.rows" :key="`${scope.value}-${row.DoiTuongID}`">
											<td class="text-center">{{ gradeGroup.startIndex + rowIndex + 1 }}</td>
											<td>{{ row.TenDoiTuong }}</td>
											<td class="text-center">{{ row.KhoiID || '—' }}</td>
											<td class="text-center">{{ asNumber(row.SiSo) }}</td>
											<td class="text-center">{{ asNumber(row.DaCoDiem) }}</td>
											<td class="text-center">{{ Math.max(0, asNumber(row.SiSo) - asNumber(row.DaCoDiem)) }}</td>
											<td class="text-center">{{ formatAverage(row.DiemTrungBinh) }}</td>
											<template v-for="category in visibleCategoriesByScope[scope.value]" :key="category.key">
												<td class="text-center">{{ asNumber(row[category.countField]) }}</td>
												<td class="text-center">{{ formatPercent(row[category.countField], row.DaCoDiem) }}</td>
											</template>
										</tr>
										<tr class="font-weight-bold">
											<td colspan="3">TỔNG KHỐI {{ gradeGroup.KhoiID || '—' }}</td>
											<td class="text-center">{{ gradeGroup.summary.SiSo }}</td>
											<td class="text-center">{{ gradeGroup.summary.DaCoDiem }}</td>
											<td class="text-center">{{ gradeGroup.summary.ChuaCoDiem }}</td>
											<td class="text-center">{{ formatAverage(gradeGroup.summary.DiemTrungBinh) }}</td>
											<template v-for="category in visibleCategoriesByScope[scope.value]" :key="category.key">
												<td class="text-center">{{ gradeGroup.summary[category.key] }}</td>
												<td class="text-center">{{ formatPercent(gradeGroup.summary[category.key], gradeGroup.summary.DaCoDiem) }}</td>
											</template>
										</tr>
									</template>
									<tr v-if="rowsByScope(scope.value).length" class="font-weight-bold">
										<td colspan="3">TỔNG CỘNG</td>
										<td class="text-center">{{ scopeSummary(scope.value).SiSo }}</td>
										<td class="text-center">{{ scopeSummary(scope.value).DaCoDiem }}</td>
										<td class="text-center">{{ scopeSummary(scope.value).ChuaCoDiem }}</td>
										<td class="text-center">{{ formatAverage(scopeSummary(scope.value).DiemTrungBinh) }}</td>
										<template v-for="category in visibleCategoriesByScope[scope.value]" :key="category.key">
											<td class="text-center">{{ scopeSummary(scope.value)[category.key] }}</td>
											<td class="text-center">{{ formatPercent(scopeSummary(scope.value)[category.key], scopeSummary(scope.value).DaCoDiem) }}</td>
										</template>
									</tr>
									<tr v-if="!rowsByScope(scope.value).length">
										<td class="text-center" :colspan="7 + visibleCategoriesByScope[scope.value].length * 2">Chưa có dữ liệu cho phạm vi này trong học kì đã chọn.</td>
									</tr>
								</tbody>
							</v-table>
						</div>
					</v-tabs-window-item>
				</v-tabs-window>
			</v-card>
		</template>

		<v-alert v-else-if="!isLoading && !errorMessage" class="mt-2" type="info" variant="tonal" density="compact">
				Chưa có dữ liệu báo cáo. Chọn niên khóa, khối, môn học và học kì, sau đó bấm “Xem báo cáo”.
		</v-alert>
		<v-progress-linear v-if="isLoading" color="primary" indeterminate />
	</div>
</template>

<script>
	export default {
		props: {
		dsNienKhoa: { type: Array, default: () => [] },
		nienKhoa: { type: [Number, String], default: null }
	},
	data() {
		const scoreItems = [
			{ title: "Giữa kì 1", value: "DiemGK_HK1" },
			{ title: "Cuối kì 1", value: "DiemCK_HK1" },
			{ title: "Giữa kì 2", value: "DiemGK_HK2" },
			{ title: "Cuối kì 2", value: "DiemCK_HK2" }
		]
		const scoreCodes = new Set(scoreItems.map(item => item.value))
		// Tổng hợp báo cáo dùng cùng mã kì với HocKi; đổi GK_HK1 thành tên cột API DiemGK_HK1.
		const requestedPeriod = String(vueData.hk ?? "").replace(/^Diem/i, "").toUpperCase()
		const scoreColumnFromPeriod = `Diem${requestedPeriod}`
		// Vẫn nhận cotdiem để các link cũ tiếp tục mở được trong thời gian chuyển đổi.
		const legacyScoreColumn = String(vueData.cotdiem ?? vueData.maCotDiem ?? "")
		const selectedScoreColumn = scoreCodes.has(scoreColumnFromPeriod)
			? scoreColumnFromPeriod
			: scoreCodes.has(legacyScoreColumn) ? legacyScoreColumn : scoreItems[0].value
		return {
			SelectedNienKhoa: parseInt(this.nienKhoa || vueData.NienKhoa || 0) || null,
			// Mặc định khối 6 để lượt tải đầu chỉ truy vấn một khối; vẫn có thể chọn tất cả khi cần.
			SelectedKhoiID: 6,
			DSKhoi: [
				{ title: "Khối 6", value: 6 },
				{ title: "Khối 7", value: 7 },
				{ title: "Khối 8", value: 8 },
				{ title: "Khối 9", value: 9 },
				{ title: "Khối 10", value: 10 },
				{ title: "Khối 11", value: 11 },
				{ title: "Khối 12", value: 12 },
				{ title: "Tất cả khối", value: 0 }
			],
			SelectedMonHocID: null,
			DSMonHoc: [],
			MaCotDiem: selectedScoreColumn,
			DataBaoCao: [],
			currentTab: 1,
			isLoading: false,
			loadSequence: 0,
			SubjectCache: {},
			SubjectLoadPromises: {},
			errorMessage: "",
			DSCotDiem: scoreItems,
			Scopes: [
				{ value: 1, title: "THCS · Lớp", description: "Điểm được tổng hợp theo lớp hành chính ở cấp THCS." },
				{ value: 2, title: "THPT · Lớp gốc", description: "Điểm từ các nhóm môn học được gom về lớp hành chính của học sinh." },
				{ value: 3, title: "Nhóm môn học", description: "Điểm và sĩ số được tổng hợp theo các nhóm của môn học đã chọn." }
			],
			Categories: [
				{ key: "Kem", title: "Kém · <3,5", countField: "Kem", className: "category-poor" },
				{ key: "Yeu", title: "Yếu · 3,5–<5", countField: "Yeu", className: "category-low" },
				{ key: "TrungBinh", title: "Trung bình · 5–<6,5", countField: "TrungBinh", className: "category-average" },
				{ key: "Kha", title: "Khá · 6,5–<8", countField: "Kha", className: "category-good" },
				{ key: "Gioi", title: "Giỏi · ≥ 8", countField: "Gioi", className: "category-excellent" },
			]
		}
	},
	computed: {
		yearItems() {
			return this.dsNienKhoa.map(item => ({
				title: item.TenNienKhoa || `${item.NienKhoa}-${item.NienKhoa + 1}`,
				value: parseInt(item.NienKhoa)
			})).filter(item => Number.isFinite(item.value));
		},
		// Keep subject levels contiguous and show each item's level as a subtitle; DSMonHoc remains canonical for report logic.
		subjectSelectItems() {
			const groups = [
				{ title: "CẤP THCS", matches: item => parseInt(item.capId) !== 3 },
				{ title: "CẤP THPT", matches: item => parseInt(item.capId) === 3 }
			];
			const items = [];
			groups.forEach(group => {
				const subjects = this.DSMonHoc
					.filter(group.matches)
					.sort((a, b) => String(a.name || a.title).localeCompare(String(b.name || b.title), "vi"));
				items.push(...subjects.map(item => ({ ...item, levelTitle: group.title })));
			});
			return items;
		},
		selectedScoreTitle() {
			return (this.DSCotDiem.find(item => item.value === this.MaCotDiem) || {}).title || "";
		},
		selectedKhoiTitle() {
			return (this.DSKhoi.find(item => item.value === this.SelectedKhoiID) || {}).title || "Tất cả khối";
		},
		// Keep the grade selector within the selected subject's level while allowing an explicit all-grade report.
		gradeItems() {
			const capId = parseInt(this.selectedSubject?.capId || 0);
			if (capId !== 2 && capId !== 3) return this.DSKhoi;
			const minGrade = capId === 3 ? 10 : 6;
			const maxGrade = capId === 3 ? 12 : 9;
			return this.DSKhoi.filter(item => item.value === 0 || (item.value >= minGrade && item.value <= maxGrade));
		},
		selectedSubject() {
			return this.DSMonHoc.find(item => item.value === parseInt(this.SelectedMonHocID)) || null;
		},
		selectedSubjectTitle() {
			return this.selectedSubject?.title || "Chưa chọn môn học";
		},
		visibleScopes() {
			const capId = parseInt(this.selectedSubject?.capId || 0);
			const classScope = capId === 3 ? 2 : 1;
			// Show the group tab only when this subject and score period returned group rows.
			const hasSubjectGroups = this.DataBaoCao.some(row => parseInt(row.PhamViID) === 3);
			return this.Scopes.filter(scope => scope.value === classScope || (scope.value === 3 && hasSubjectGroups));
		},
		// Keep only score bands with non-zero counts on screen; Excel continues to export every band.
		visibleCategoriesByScope() {
			const result = {};
			this.Scopes.forEach(scope => {
				const rows = this.DataBaoCao.filter(row => parseInt(row.PhamViID) === scope.value);
				result[scope.value] = this.Categories.filter(category =>
					rows.some(row => this.asNumber(row[category.countField]) > 0)
				);
			});
			return result;
		},
		currentRows() {
			return this.rowsByScope(this.currentTab);
		},
		activeSummary() {
			return this.scopeSummary(this.currentTab);
		},
		summaryCards() {
			const summary = this.activeSummary;
			return [
				{ key: "groups", label: "Lớp / nhóm", value: this.formatInteger(summary.SoDoiTuong), hint: "Trong phạm vi đang chọn" },
				{ key: "students", label: "Sĩ số", value: this.formatInteger(summary.SiSo), hint: "Học sinh thuộc các lớp / nhóm" },
				{ key: "tested", label: "Đã có điểm", value: this.formatInteger(summary.DaCoDiem), hint: `${this.formatPercent(summary.DaCoDiem, summary.SiSo)} trên sĩ số` },
				{ key: "average", label: "Điểm trung bình", value: this.formatAverage(summary.DiemTrungBinh), hint: "Tính trên các điểm hợp lệ đã nhập" }
			]
		}
	},
	watch: {
		SelectedKhoiID() {
			if (this.SelectedNienKhoa && !this.isLoading) this.onSearch();
		},
		SelectedMonHocID() {
			this.alignGradeToSelectedSubject();
		},
		nienKhoa(value) {
			const year = parseInt(value || 0);
			if (year && year !== this.SelectedNienKhoa) {
				this.SelectedNienKhoa = year;
				this.onSearch();
			}
		},
		dsNienKhoa() {
			if (!this.SelectedNienKhoa && this.yearItems.length) {
				const active = this.dsNienKhoa.find(item => item.IsActive == true);
				this.SelectedNienKhoa = parseInt((active || this.dsNienKhoa[0]).NienKhoa);
				this.onSearch();
			}
		}
	},
	mounted() {
		if (!this.SelectedNienKhoa && this.yearItems.length) {
			const active = this.dsNienKhoa.find(item => item.IsActive == true);
			this.SelectedNienKhoa = parseInt((active || this.dsNienKhoa[0]).NienKhoa);
		}
		if (this.SelectedNienKhoa) this.onSearch();
	},
	methods: {
		alignGradeToSelectedSubject() {
			const subject = this.selectedSubject;
			const capId = parseInt(subject?.capId || 0);
			const khoiId = parseInt(this.SelectedKhoiID) || 0;
			if (!subject || !khoiId || (capId !== 2 && capId !== 3)) return;
			const matchesLevel = capId === 3 ? khoiId >= 10 && khoiId <= 12 : khoiId >= 6 && khoiId <= 9;
			if (!matchesLevel) this.SelectedKhoiID = capId === 3 ? 10 : 6;
		},
		async onSearch() {
			if (!this.SelectedNienKhoa || !this.MaCotDiem) {
				this.errorMessage = "Vui lòng chọn niên khóa và học kì.";
				return;
			}
			const sequence = ++this.loadSequence;
			this.isLoading = true;
			this.errorMessage = "";
			this.DataBaoCao = [];
			try {
				const hocKi = /_HK1$/.test(String(this.MaCotDiem)) ? 1 : 2;
				// Load one combined subject list so users can choose a subject before narrowing the report by grade.
				this.DSMonHoc = await this.loadAssignedSubjects(this.SelectedNienKhoa, hocKi);
				if (sequence !== this.loadSequence) return;
				if (!this.DSMonHoc.length) {
					this.SelectedMonHocID = null;
					this.DataBaoCao = [];
					return;
				}
				if (!this.DSMonHoc.some(item => item.value === parseInt(this.SelectedMonHocID))) {
					// Pick a default subject from the selected grade's level so the first report request is valid.
					const selectedGrade = parseInt(this.SelectedKhoiID) || 0;
					const preferredCapId = selectedGrade === 0 ? 0 : selectedGrade >= 10 ? 3 : 2;
					const sameLevelSubjects = preferredCapId
						? this.DSMonHoc.filter(item => item.capId === preferredCapId)
						: this.DSMonHoc;
					const defaultSubjects = sameLevelSubjects.length ? sameLevelSubjects : this.DSMonHoc;
					const tinDefault = defaultSubjects.find(item => /tin/i.test(item.name));
					this.SelectedMonHocID = (tinDefault || defaultSubjects[0]).value;
				}
				// Align before making the request; the report endpoint rejects a grade outside the subject's level.
				this.alignGradeToSelectedSubject();
				const khoiId = parseInt(this.SelectedKhoiID) || 0;
				this.currentTab = this.selectedSubject?.capId === 3 ? 2 : 1;
				const rows = await ajaxCALLPromise("lms/BaoCao_ThongKe_XepLoai_MonHoc_TheoKhoi", {
					NienKhoa: this.SelectedNienKhoa,
					MaCotDiem: this.MaCotDiem,
					MonHocID: this.SelectedMonHocID,
					KhoiID: khoiId
				});
				// API dùng tên cột chuẩn; chỉ nhận object/array để tránh chuỗi lỗi thành [object Object] trên bảng.
				if (sequence === this.loadSequence) {
					const validRows = Array.isArray(rows) ? rows.filter(row => row && typeof row === "object" && !Array.isArray(row)) : [];
					// API lọc ngay trong SQL; lọc lại ở đây để không hiện nhầm dòng nếu response vượt phạm vi.
					this.DataBaoCao = khoiId ? validRows.filter(row => parseInt(row.KhoiID) === khoiId) : validRows;
				}
			} catch (error) {
				console.error("Không tải được thống kê xếp loại môn học:", error);
				if (sequence === this.loadSequence) {
					this.DataBaoCao = [];
					this.errorMessage = error?.message || "Không tải được dữ liệu báo cáo. Vui lòng thử lại.";
				}
			} finally {
				if (sequence === this.loadSequence) this.isLoading = false;
			}
		},
		async loadAssignedSubjects(nienKhoa, hocKi) {
			const userContext = vueData.user || {};
			const userId = String(userContext.UserID || vueData.UserID || "");
			const systemRight = String(userContext.SystemRight ?? vueData.SystemRight ?? "");
			const canPersistCache = Boolean(userId);
			const cacheKey = "lhbs-lms:bc-thong-ke-xep-loai:subjects:" + (userId || "component") + ":" + systemRight + ":" + nienKhoa + ":HK" + hocKi + ":K0:v3";
			const cacheTtlMs = 5 * 60 * 1000;
			const now = Date.now();
			const memoryCache = this.SubjectCache[cacheKey];
			if (memoryCache && now - memoryCache.savedAt < cacheTtlMs && Array.isArray(memoryCache.items)) {
				return memoryCache.items;
			}

			// Cache này tách theo người dùng/quyền vì danh sách môn giáo viên khác danh sách quản trị.
			try {
				if (canPersistCache && typeof window !== "undefined" && window.localStorage) {
					const cachedText = window.localStorage.getItem(cacheKey);
					const cached = cachedText ? JSON.parse(cachedText) : null;
					const validItems = cached && Array.isArray(cached.items) && cached.items.every(item =>
						item && Number.isFinite(parseInt(item.value)) && typeof item.name === "string"
					);
					if (validItems && Number.isFinite(cached.savedAt) && now - cached.savedAt < cacheTtlMs) {
						this.SubjectCache[cacheKey] = cached;
						return cached.items;
					}
					if (cachedText) window.localStorage.removeItem(cacheKey);
				}
			} catch (error) {
				// Storage có thể bị khóa trong iframe; vẫn tiếp tục tải bằng một request API.
			}

			if (this.SubjectLoadPromises[cacheKey]) return this.SubjectLoadPromises[cacheKey];
			// One API call returns assigned subjects across grades; the report query still uses the selected grade.
			const request = ajaxCALLPromise("lms/MonHoc_GetByKhoiID", {
				KhoiID: 0,
				NienKhoa: nienKhoa,
				HocKi: hocKi
			}).then(rows => {
				const subjectsById = new Map();
				(Array.isArray(rows) ? rows : []).forEach(item => {
					if (!item || typeof item !== "object" || Array.isArray(item)) return;
					const value = parseInt(item.MonHocID);
					const itemKhoiId = parseInt(item.KhoiID) || 0;
					if (!Number.isFinite(value) || subjectsById.has(value)) return;
					const capId = parseInt(item.CapID) || (itemKhoiId >= 10 ? 3 : 2);
					const name = item.TenMonHoc_HienThi || item.MonHocName || "Môn học";
					subjectsById.set(value, {
						title: name + " · " + (capId === 3 ? "THPT" : "THCS"),
						value,
						capId,
						name
					});
				});
				const items = Array.from(subjectsById.values());
				if (items.length) {
					const cacheEntry = { savedAt: Date.now(), items };
					this.SubjectCache[cacheKey] = cacheEntry;
					try {
						if (canPersistCache && typeof window !== "undefined" && window.localStorage) {
							window.localStorage.setItem(cacheKey, JSON.stringify(cacheEntry));
						}
					} catch (error) {
						// Keep the in-memory copy if browser storage is full or unavailable.
					}
				}
				return items;
			}).finally(() => {
				delete this.SubjectLoadPromises[cacheKey];
			});
			this.SubjectLoadPromises[cacheKey] = request;
			return request;
		},
		rowsByScope(scopeId) {
			return this.DataBaoCao
				.filter(row => parseInt(row.PhamViID) === scopeId)
				.sort((a, b) => (parseInt(a.KhoiID) || 0) - (parseInt(b.KhoiID) || 0) || String(a.TenDoiTuong || "").localeCompare(String(b.TenDoiTuong || ""), "vi"));
		},
		// Groups use the same sorted rows on screen and in Excel so each grade subtotal stays beside its classes.
		gradeGroupsByScope(scopeId) {
			const groups = new Map();
			this.rowsByScope(scopeId).forEach((row, index) => {
				const khoiID = parseInt(row.KhoiID) || 0;
				let group = groups.get(khoiID);
				if (!group) {
					group = { KhoiID: khoiID, startIndex: index, rows: [] };
					groups.set(khoiID, group);
				}
				group.rows.push(row);
			});
			return Array.from(groups.values()).map(group => ({
				...group,
				summary: this.summaryForRows(group.rows)
			}));
		},
		// A shared weighted average keeps grade subtotals and the overall total consistent.
		scopeSummary(scopeId) {
			return this.summaryForRows(this.rowsByScope(scopeId));
		},
		summaryForRows(rows) {
			const summary = { SoDoiTuong: rows.length, SiSo: 0, DaCoDiem: 0, ChuaCoDiem: 0, DiemTrungBinh: null, Gioi: 0, Kha: 0, TrungBinh: 0, Yeu: 0, Kem: 0 };
			let weightedScore = 0;
			rows.forEach(row => {
				const tested = this.asNumber(row.DaCoDiem);
				summary.SiSo += this.asNumber(row.SiSo);
				summary.DaCoDiem += tested;
				summary.ChuaCoDiem += Math.max(0, this.asNumber(row.SiSo) - tested);
				const average = Number(row.DiemTrungBinh);
				if (Number.isFinite(average) && tested > 0) weightedScore += average * tested;
				this.Categories.forEach(category => { summary[category.key] += this.asNumber(row[category.countField]); });
			});
			summary.DiemTrungBinh = summary.DaCoDiem ? weightedScore / summary.DaCoDiem : null;
			return summary;
		},
		asNumber(value) {
			const number = Number(value);
			return Number.isFinite(number) ? number : 0;
		},
		formatInteger(value) {
			return new Intl.NumberFormat("vi-VN").format(this.asNumber(value));
		},
		formatAverage(value) {
			if (value === null || value === undefined || value === "") return "—";
			const number = Number(value);
			return Number.isFinite(number) ? number.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : "—";
		},
		// Tỉ lệ xếp loại dùng số học sinh đã có điểm làm mẫu số, nên các mức luôn phản ánh cơ cấu điểm đã nhập.
		formatPercent(count, testedCount) {
			const tested = this.asNumber(testedCount);
			if (!tested) return "0.00%";
			return `${((this.asNumber(count) / tested) * 100).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}%`;
		},
		async onExportExcel() {
			try {
				const XLSX = window.XLSX || await import("https://cdn.sheetjs.com/xlsx-0.20.0/package/xlsx.mjs");
				const workbook = XLSX.utils.book_new();
				const baseHeaders = ["STT", "Lớp / nhóm môn học", "Khối", "Sĩ số", "Đã có điểm", "Chưa có điểm", "Điểm TB"];
				const excelAverage = value => {
					if (value === null || value === undefined || value === "" || !Number.isFinite(Number(value))) return "—";
					return Number(value);
				};
				this.visibleScopes.forEach(scope => {
					const groups = this.gradeGroupsByScope(scope.value);
					const summary = this.scopeSummary(scope.value);
					const columnCount = baseHeaders.length + this.Categories.length * 2;
					// Keep all score bands in Excel as requested; merge each band over its SL/TL columns to mirror the table header.
					const groupedHeader = [
						[...baseHeaders, ...this.Categories.flatMap(category => [category.title, ""])],
						[...baseHeaders.map(() => ""), ...this.Categories.flatMap(() => ["SL", "TL"])]
					];
					const dataRows = [];
					// Excel mirrors the screen: class rows, grade subtotal, then one overall total.
					groups.forEach(gradeGroup => {
						gradeGroup.rows.forEach((row, rowIndex) => dataRows.push([
							gradeGroup.startIndex + rowIndex + 1, row.TenDoiTuong, row.KhoiID, this.asNumber(row.SiSo), this.asNumber(row.DaCoDiem),
							Math.max(0, this.asNumber(row.SiSo) - this.asNumber(row.DaCoDiem)), excelAverage(row.DiemTrungBinh),
							...this.Categories.flatMap(category => [this.asNumber(row[category.countField]), this.asNumber(row.DaCoDiem) ? this.asNumber(row[category.countField]) / this.asNumber(row.DaCoDiem) : 0])
						]));
						const subtotal = gradeGroup.summary;
						dataRows.push(["", `TỔNG KHỐI ${gradeGroup.KhoiID || "—"}`, "", subtotal.SiSo, subtotal.DaCoDiem, subtotal.ChuaCoDiem, excelAverage(subtotal.DiemTrungBinh),
							...this.Categories.flatMap(category => [subtotal[category.key], subtotal.DaCoDiem ? subtotal[category.key] / subtotal.DaCoDiem : 0])
						]);
					});
					if (groups.length) {
						dataRows.push(["", "TỔNG CỘNG", "", summary.SiSo, summary.DaCoDiem, summary.ChuaCoDiem, excelAverage(summary.DiemTrungBinh),
							...this.Categories.flatMap(category => [summary[category.key], summary.DaCoDiem ? summary[category.key] / summary.DaCoDiem : 0])
						]);
					} else {
						dataRows.push(["Chưa có dữ liệu cho phạm vi này trong học kì đã chọn.", ...Array(columnCount - 1).fill("")]);
					}
					const aoa = [
						["THỐNG KÊ XẾP LOẠI THEO MÔN HỌC"],
						[`Môn: ${this.selectedSubject?.name || ""} · ${scope.title} · Khối: ${this.selectedKhoiTitle} · Niên khóa: ${this.SelectedNienKhoa}-${this.SelectedNienKhoa + 1} · Học kì: ${this.selectedScoreTitle} · Tỉ lệ tính trên số học sinh đã có điểm`],
						...groupedHeader,
						...dataRows
					];
					const worksheet = XLSX.utils.aoa_to_sheet(aoa);
					const merges = [
						{ s: { r: 0, c: 0 }, e: { r: 0, c: columnCount - 1 } },
						{ s: { r: 1, c: 0 }, e: { r: 1, c: columnCount - 1 } }
					];
					baseHeaders.forEach((_, columnIndex) => {
						merges.push({ s: { r: 2, c: columnIndex }, e: { r: 3, c: columnIndex } });
					});
					this.Categories.forEach((_, categoryIndex) => {
						const firstColumn = baseHeaders.length + categoryIndex * 2;
						merges.push({ s: { r: 2, c: firstColumn }, e: { r: 2, c: firstColumn + 1 } });
					});
					if (!groups.length) merges.push({ s: { r: 4, c: 0 }, e: { r: 4, c: columnCount - 1 } });
					worksheet["!merges"] = merges;
					worksheet["!cols"] = [
						{ wch: 8 }, { wch: 28 }, { wch: 9 }, { wch: 12 }, { wch: 14 }, { wch: 14 }, { wch: 12 },
						...this.Categories.flatMap(() => [{ wch: 9 }, { wch: 12 }])
					];
					for (let rowIndex = 4; rowIndex < aoa.length; rowIndex += 1) {
						const averageCell = XLSX.utils.encode_cell({ r: rowIndex, c: 6 });
						if (worksheet[averageCell] && typeof worksheet[averageCell].v === "number") worksheet[averageCell].z = "0.00";
						this.Categories.forEach((_, categoryIndex) => {
							const percentColumn = baseHeaders.length + categoryIndex * 2 + 1;
							const cell = XLSX.utils.encode_cell({ r: rowIndex, c: percentColumn });
							if (worksheet[cell]) worksheet[cell].z = "0.00%";
						});
					}
					const sheetName = scope.title.replace(" · ", "-").slice(0, 31);
					XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);
				});
				// Include the subject and its level so similarly named subjects in THCS and THPT remain distinguishable in downloads.
				const subjectFilePart = String(this.selectedSubject?.title || this.selectedSubject?.name || `MonHoc_${this.SelectedMonHocID || ""}`)
					.replace(/[·]/g, " ")
					.replace(/[\\/:*?"<>|]/g, " ")
					.trim()
					.replace(/\s+/g, "_");
				XLSX.writeFile(workbook, `ThongKe_XepLoai_${subjectFilePart}_${this.MaCotDiem}_${this.SelectedNienKhoa}.xlsx`);
			} catch (error) {
				console.error("Không xuất được Excel:", error);
				this.errorMessage = "Không xuất được file Excel. Vui lòng thử lại hoặc tải lại trang.";
			}
		}
	}
	}
</script>