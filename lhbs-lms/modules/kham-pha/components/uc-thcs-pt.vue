<template>
	<div class="kham-pha-container pa-0">
		<!-- Header Toolbar Gradient Box -->
		<v-card class="pa-4 mb-3 rounded-xl elevation-2 text-white overflow-hidden position-relative" style="background: linear-gradient(135deg, #047857 0%, #10b981 100%);">
			<div class="d-flex flex-wrap align-center justify-space-between ga-3 mb-3">
				<div class="d-flex align-center">
					<!-- Nút Quay lại dành cho Giáo viên / Xem từ Kho học liệu số (/hoc-lieu-so) -->
					<v-btn
						v-if="!isStudentView"
						icon
						variant="tonal"
						color="white"
						size="small"
						class="mr-3 elevation-1"
						@click="goBackToKhoHocLieu"
					>
						<v-icon size="medium">mdi-arrow-left</v-icon>
						<v-tooltip activator="parent" location="bottom">Quay lại Kho học liệu</v-tooltip>
					</v-btn>

					<v-avatar color="white" size="44" class="mr-3 elevation-1">
						<v-icon color="success" size="28">mdi-school</v-icon>
					</v-avatar>
					<div>
						<div class="d-flex align-center ga-2">
							<h2 class="text-h6 font-weight-bold text-white mb-0">Học Liệu Số - {{ displayTitle }}</h2>
							<v-chip color="white" variant="flat" size="x-small" class="text-success font-weight-bold">
								{{ filteredDSHocLieu.length }} học liệu
							</v-chip>
						</div>
						<p class="text-caption text-white opacity-90 mb-0">
							{{ isStudentView ? 'Danh sách sách giáo khoa và học liệu dành cho học sinh' : 'Tổng quan kho sách giáo khoa và học liệu số dành cho giáo viên' }}
						</p>
					</div>
				</div>

				<!-- Live Search Bar -->
				<div style="min-width: 260px; max-width: 360px; width: 100%;">
					<v-text-field
						v-model="searchQuery"
						placeholder="Tìm kiếm sách, môn học..."
						prepend-inner-icon="mdi-magnify"
						clearable
						hide-details
						density="compact"
						variant="solo"
						bg-color="white"
						color="primary"
						class="rounded-pill border-0 shadow-sm"
					></v-text-field>
				</div>
			</div>

			<!-- Quick Grade Filter Pills (Dành cho Giáo viên / Tổng quan) -->
			<div v-if="!isStudentView" class="d-flex align-center flex-wrap ga-2 pt-2 border-top border-opacity-25 mb-2">
				<span class="text-caption font-weight-bold text-white mr-1">
					<v-icon size="x-small" class="mr-1">mdi-school-outline</v-icon> Chọn khối lớp:
				</span>
				<v-chip-group v-model="selectedKhoiId" selected-class="bg-white text-success font-weight-bold" mandatory>
					<v-chip
						v-for="khoi in availableKhoiOptions"
						:key="khoi.id"
						:value="khoi.id"
						variant="flat"
						size="small"
						class="text-caption font-weight-medium"
						style="border: 1px solid rgba(255,255,255,0.4);"
					>
						{{ khoi.name }} ({{ khoi.count }})
					</v-chip>
				</v-chip-group>
			</div>

			<!-- Quick Category Filter Pills -->
			<div class="d-flex align-center flex-wrap ga-2 pt-2 border-top border-opacity-25">
				<span class="text-caption font-weight-bold text-white mr-1">
					<v-icon size="x-small" class="mr-1">mdi-filter-variant</v-icon> Danh mục môn:
				</span>
				<v-chip-group v-model="selectedCategoryFilter" selected-class="bg-white text-success font-weight-bold" mandatory>
					<v-chip
						v-for="cat in categoryOptions"
						:key="cat.id"
						:value="cat.id"
						variant="flat"
						size="small"
						class="text-caption font-weight-medium"
						style="border: 1px solid rgba(255,255,255,0.4);"
					>
						{{ cat.name }} ({{ cat.count }})
					</v-chip>
				</v-chip-group>
			</div>
		</v-card>

		<!-- No Results Empty State -->
		<v-card v-if="filteredDSHocLieu.length === 0" class="pa-12 text-center rounded-xl my-4 elevation-1">
			<v-icon size="64" color="grey-lighten-1" class="mb-3">mdi-book-search-outline</v-icon>
			<h3 class="text-h6 font-weight-bold text-grey-darken-2 mb-1">Không tìm thấy học liệu phù hợp</h3>
			<p class="text-body-2 text-grey">Thử thay đổi từ khóa tìm kiếm hoặc chọn khối lớp khác.</p>
			<v-btn color="success" variant="tonal" rounded="pill" class="mt-3 font-weight-bold" @click="resetFilters">
				<v-icon start>mdi-refresh</v-icon> Xem lại tất cả sách
			</v-btn>
		</v-card>

		<!-- Grid Book Catalog -->
		<div v-else>
			<!-- CHẾ ĐỘ XEM TỔNG QUAN TẤT CẢ CÁC KHỐI DÀNH CHO GIÁO VIÊN (RÕ KHỐI - RÕ MÔN) -->
			<template v-if="selectedKhoiId === 0 && selectedCategoryFilter === 0">
				<v-card v-for="grade in groupedDisplay" :key="grade.khoiId" class="mb-5 pa-4 rounded-xl border border-slate-200 elevation-1 bg-white">
					<!-- Grade Section Header -->
					<div class="d-flex align-center justify-space-between mb-4 pb-3 border-b border-slate-100">
						<div class="d-flex align-center">
							<v-avatar color="emerald-lighten-5" size="40" class="mr-3">
								<v-icon color="success" size="24">mdi-school</v-icon>
							</v-avatar>
							<div>
								<h3 class="text-h6 font-weight-bold text-success mb-0">HỌC LIỆU SỐ - {{ grade.khoiName.toUpperCase() }}</h3>
								<span class="text-caption text-grey-darken-1 font-weight-medium">Tổng số {{ grade.totalBooks }} học liệu chia theo môn</span>
							</div>
						</div>
						<v-btn size="small" variant="tonal" color="success" class="font-weight-bold rounded-pill" @click="selectedKhoiId = grade.khoiId">
							<v-icon start size="small">mdi-filter-variant</v-icon> Chỉ xem {{ grade.khoiName }}
						</v-btn>
					</div>

					<!-- Phân nhóm môn học bên trong từng Khối -->
					<div v-for="subGroup in grade.subGroups" :key="subGroup.id" class="mb-5">
						<div class="d-flex align-center mb-2 px-1">
							<v-icon color="teal" size="small" class="mr-2">mdi-bookmark-check-outline</v-icon>
							<h4 class="text-subtitle-2 font-weight-bold text-slate-800" style="color: #1e293b;">
								{{ subGroup.name }}
							</h4>
							<v-chip size="x-small" color="grey-lighten-3" class="ml-2 font-weight-bold text-grey-darken-3">
								{{ subGroup.items.length }} sách
							</v-chip>
						</div>

						<!-- Grid hiển thị sách -->
						<v-row dense class="match-height">
							<v-col
								v-for="sach in subGroup.items"
								:key="sach.HocLieuID"
								cols="6" sm="4" md="3" lg="2" xl="2"
								class="pa-2"
							>
								<uc-sach-card :item="sach" />
							</v-col>
						</v-row>
					</div>
				</v-card>
			</template>

			<!-- CHẾ ĐỘ XEM THEO 1 KHỐI CỤ THỂ HOẶC LỌC DANH MỤC MÔN -->
			<template v-else>
				<div v-for="group in groupedDisplay" :key="group.id" class="mb-6">
					<div class="d-flex align-center justify-space-between mb-3 px-1">
						<div class="d-flex align-center">
							<v-icon color="success" class="mr-2">mdi-bookmark-check-outline</v-icon>
							<h3 class="text-subtitle-1 font-weight-bold text-slate-800" style="color: #0f172a;">
								{{ group.name }}
							</h3>
							<v-chip size="x-small" color="grey-lighten-2" class="ml-2 font-weight-bold text-grey-darken-3">
								{{ group.items.length }} sách
							</v-chip>
						</div>
					</div>

					<v-row dense class="match-height">
						<v-col
							v-for="sach in group.items"
							:key="sach.HocLieuID"
							cols="6" sm="4" md="3" lg="2" xl="2"
							class="pa-2"
						>
							<uc-sach-card :item="sach" />
						</v-col>
					</v-row>
				</div>
			</template>
		</div>
	</div>
</template>

<script>
	export default {
		data() {
			const config = {
				2: {
					batBuoc: [73, 74],
					xh: [60, 53, 52],
					tn: [61, 57, 67],
					ta: [46]
				},
				3: {
					batBuoc: [103, 104],
					xh: [100, 79, 82],
					tn: [91, 88, 97],
					ta: [76]
				}
			};

			const capCfg = config[vueData.CapID] || {};

			const detectStudentContext = () => {
				try {
					const urlParams = new URLSearchParams(window.location.search);
					const kParam = urlParams.get('khoiid') || urlParams.get('KhoiID');
					if (kParam && !isNaN(parseInt(kParam)) && parseInt(kParam) > 0) {
						return { isStudent: true, khoiId: parseInt(kParam) };
					}
					if (typeof vueData !== 'undefined') {
						if (vueData.KhoiID && !isNaN(parseInt(vueData.KhoiID)) && parseInt(vueData.KhoiID) > 0) {
							return { isStudent: true, khoiId: parseInt(vueData.KhoiID) };
						}
						if (vueData.khoiid && !isNaN(parseInt(vueData.khoiid)) && parseInt(vueData.khoiid) > 0) {
							return { isStudent: true, khoiId: parseInt(vueData.khoiid) };
						}
					}
				} catch(e) {}

				// Nếu không có khoiid trong URL -> Đây là giao diện Giáo viên (Xem tất cả các khối)
				return { isStudent: false, khoiId: 0 };
			};

			const context = detectStudentContext();

			return {
				DSHocLieu: [],
				DSMonHoc: [],
				canGoBack: false,
				searchQuery: '',
				selectedKhoiId: context.khoiId, // 0 = Tất cả khối (Giáo viên), > 0 = Khối cụ thể (Học sinh)
				isStudentView: context.isStudent,
				selectedCategoryFilter: 0, // 0 = Tất cả môn

				DSToHop: [
					{ id: 1, name: "Môn học bắt buộc", List_MonHocID: capCfg.batBuoc || [] },
					{ id: 2, name: "Khoa học xã hội", List_MonHocID: capCfg.xh || [] },
					{ id: 3, name: "Khoa học tự nhiên", List_MonHocID: capCfg.tn || [] },
					{ id: 4, name: "Tiếng Anh", List_MonHocID: capCfg.ta || [] },
					{ id: 5, name: "Các môn còn lại", List_MonHocID: null }
				]
			};
		},

		mounted() {
			this.canGoBack = window.history.length > 1;
			this.getDSMonHoc();
			this.getDSHocLieu();
		},

		computed: {
			TenCap() {
				return {
					1: "Tiểu học",
					2: "Trung học cơ sở",
					3: "Trung học phổ thông"
				}[vueData.CapID] || "";
			},

			displayTitle() {
				if (this.selectedKhoiId && this.selectedKhoiId > 0) {
					return `Khối ${this.selectedKhoiId}`;
				}
				return `${this.TenCap} (Tất cả các khối)`;
			},

			/** Danh sách nút chọn khối dành cho Giáo viên / Xem tổng quan */
			availableKhoiOptions() {
				const capId = vueData.CapID;
				let khoiList = [];
				if (capId === 2) khoiList = [6, 7, 8, 9];
				else if (capId === 3) khoiList = [10, 11, 12];
				else khoiList = [1, 2, 3, 4, 5];

				const allCount = (this.DSHocLieu || []).length;
				const options = [{ id: 0, name: "Tất cả các khối", count: allCount }];

				for (const k of khoiList) {
					const count = (this.DSHocLieu || []).filter(sach => parseInt(sach.KhoiID) === k).length;
					options.push({ id: k, name: `Khối ${k}`, count });
				}
				return options;
			},

			/** 1) Lọc danh sách học liệu theo Khối & Từ khóa tìm kiếm */
			filteredDSHocLieu() {
				let list = this.DSHocLieu || [];

				// Nếu chọn Khối cụ thể (> 0) -> Lọc theo khối đó, nếu = 0 -> Lấy tất cả các khối
				if (this.selectedKhoiId && this.selectedKhoiId > 0) {
					list = list.filter(sach => parseInt(sach.KhoiID) === parseInt(this.selectedKhoiId));
				}

				// Lọc theo Từ khóa tìm kiếm
				if (this.searchQuery && this.searchQuery.trim() !== '') {
					const q = this.searchQuery.trim().toLowerCase();
					list = list.filter(sach => {
						const tenHocLieu = (sach.TenHocLieu || '').toLowerCase();
						const tenBoSach = (sach.TenBoSach || '').toLowerCase();
						const tenMonHoc = (sach.TenMonHoc || '').toLowerCase();
						return tenHocLieu.includes(q) || tenBoSach.includes(q) || tenMonHoc.includes(q);
					});
				}

				return list;
			},

			/** 2) Các nhóm môn (Tổ hợp) và số lượng sách tương ứng */
			categoryOptions() {
				const allCount = this.filteredDSHocLieu.length;
				const options = [{ id: 0, name: "Tất cả môn", count: allCount }];

				for (const toHop of this.DSToHop) {
					const count = this.getItemsForToHop(toHop.id, this.filteredDSHocLieu).length;
					if (count > 0) {
						options.push({
							id: toHop.id,
							name: toHop.name,
							count
						});
					}
				}
				return options;
			},

			/** 3) Cấu trúc gom nhóm danh mục 2 tầng (Khối -> Môn) dành cho Giáo viên */
			groupedDisplay() {
				// 1) Nếu ở Chế độ Giáo viên (Tất cả các khối & Chưa chọn lọc danh mục môn cụ thể)
				// -> Phân nhóm 2 tầng: Tầng 1 theo KHỐI LỚP, Tầng 2 theo TỔ HỢP MÔN
				if (this.selectedKhoiId === 0 && this.selectedCategoryFilter === 0) {
					const result = [];
					const capId = vueData.CapID;
					const khoiList = capId === 2 ? [6, 7, 8, 9] : (capId === 3 ? [10, 11, 12] : [1, 2, 3, 4, 5]);

					for (const k of khoiList) {
						const khoiBooks = (this.filteredDSHocLieu || []).filter(sach => parseInt(sach.KhoiID) === k);
						if (khoiBooks.length > 0) {
							const subGroups = this.getGroupsForBooks(khoiBooks);
							result.push({
								khoiId: k,
								khoiName: `Khối ${k}`,
								totalBooks: khoiBooks.length,
								subGroups
							});
						}
					}
					return result;
				}

				// 2) Nếu người dùng chọn lọc Danh mục môn cụ thể
				if (this.selectedCategoryFilter && this.selectedCategoryFilter > 0) {
					const toHop = this.DSToHop.find(t => t.id === this.selectedCategoryFilter);
					if (!toHop) return [];
					const items = this.getItemsForToHop(toHop.id, this.filteredDSHocLieu);
					return items.length > 0 ? [{ id: toHop.id, name: toHop.name, items }] : [];
				}

				// 3) Ngược lại (Đang xem 1 khối cụ thể + Tất cả môn) -> Phân nhóm theo Tổ hợp môn
				return this.getGroupsForBooks(this.filteredDSHocLieu);
			}
		},

		methods: {
			goBackToKhoHocLieu() {
				// Nút này luôn quay về danh mục Kho học liệu; không dùng history.back() vì lịch sử trước đó có thể là trang chi tiết học liệu.
				redirect('/hoc-lieu-so');
			},
			goBack() {
				window.history.back();
			},
			resetFilters() {
				this.searchQuery = '';
				this.selectedCategoryFilter = 0;
				if (!this.isStudentView) {
					this.selectedKhoiId = 0;
				}
			},
			getGroupsForBooks(books) {
				const result = [];
				for (const toHop of this.DSToHop) {
					const items = this.getItemsForToHop(toHop.id, books);
					if (items.length > 0) {
						result.push({
							id: toHop.id,
							name: toHop.name,
							items
						});
					}
				}
				return result;
			},
			getItemsForToHop(toHopId, sourceList) {
				const list = sourceList || this.filteredDSHocLieu;
				const toHop = this.DSToHop.find(t => t.id === toHopId);
				if (!toHop) return [];

				const usedMon = this.DSToHop
					.filter(t => t.List_MonHocID)
					.flatMap(t => t.List_MonHocID);

				if (toHopId === 5) { // Các môn còn lại
					return list.filter(sach => !usedMon.includes(sach.MonHocID));
				}
				if (!toHop.List_MonHocID) return [];
				return list.filter(sach => toHop.List_MonHocID.includes(sach.MonHocID));
			},
			getDSHocLieu() {
				ajaxCALL("lms/FP_HocLieu_GetAll", {
					PageNumber: 1,
					PageSize: 1000,
					KhoiID: 0,
					MonHocID: 0,
					BoSachID: 0,
					Loai: 'HOC_LIEU'
				}, res => {
					this.DSHocLieu = res.data || [];
				});
			},
			getDSMonHoc() {
				ajaxCALL("lms/MonHoc_Get_ByCapID", {
					CapID: vueData.CapID
				}, res => {
					this.DSMonHoc = res.data || [];
				});
			}
		}
	}
</script>