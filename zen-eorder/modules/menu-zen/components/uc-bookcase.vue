<template>
	<div class="layout">
		<!-- Header -->
		<div class="header">
			<span class="title">Menu ZEN F&B</span>

			<!-- nhóm desktop/tablet -->
			<div class="select-center hidden-md-and-down">
				<v-select v-model="selectedTenPhanHieu" :items="phanHieuOptions" item-text="text" item-value="value"
					outlined dense hide-details class="category-select" @change="onPhanHieuChange" />
			</div>
			<div class="sort-group hidden-md-and-down">
				<v-btn class="sort-btn-name" @click="toggleSort('name')" :title="sortTitle('name')"
					style="font-size: 12px">
					<v-icon>mdi-text-short</v-icon>A-Z
				</v-btn>
				<v-btn class="sort-btn-date" @click="toggleSort('date')" :title="sortTitle('date')"
					style="font-size: 12px">THỜI GIAN</v-btn>
			</div>
		</div>

		<!-- nhóm mobile-only, nằm dưới title -->
		<div class="mobile-toolbar hidden-lg-and-up">
			<div class="mobile-toolbar__left">
				<v-select v-model="selectedTenPhanHieu" :items="phanHieuOptions" item-text="text" item-value="value"
					outlined dense hide-details class="category-select" @change="onPhanHieuChange" />
			</div>
			<div class="mobile-toolbar__right">
				<v-btn class="sort-btn-name" @click="toggleSort('name')" :title="sortTitle('name')"
					style="font-size: 12px">A-Z</v-btn>
				<v-btn class="sort-btn-date" @click="toggleSort('date')" :title="sortTitle('date')"
					style="font-size: 12px">THỜI GIAN</v-btn>
			</div>
		</div>

		<!-- ========== DIALOG: Chi tiết menu ========== -->
		<v-dialog v-model="dialog" max-width="600">
			<v-card>
				<v-card-title class="d-flex justify-space-between align-center"
					style="padding: 5px 12px; font-size: 20px; border-bottom: 1px solid #e0e0e0; min-height: 0;">
					<span class="detail">THÔNG TIN MENU</span>
					<v-btn icon @click="dialog = false" color="red" medium>
						<v-icon medium>mdi-close</v-icon>
					</v-btn>
				</v-card-title>

				<v-card-text class="pa-6">
					<v-row>
						<v-col cols="12" md="5" class="d-flex justify-center justify-md-start">
							<div>
								<img v-if="selectedItem && selectedItem.Thumbnail_FileID"
									:src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + selectedItem.Thumbnail_FileID"
									:alt="selectedItem.TenBook"
									style="width: 100%; max-width: 250px; height: auto; object-fit: cover; border-radius: 8px; box-shadow: rgba(0,0,0,0.1) 0px 2px 8px;" />
							</div>
						</v-col>

						<v-col cols="12" md="7">
							<div class="content-section">
								<h2 class="book-detail" style="color: #2c3e50;">
									{{ selectedItem ? selectedItem.TenBook : '' }}
								</h2>

								<div class="detailphanhieu" style="color:#34495e;">
									{{ selectedItem ? getPhanHieuNames(selectedItem) : '' }}
								</div>

								<div v-if="totalPagesFromSelectedItem !== null" style="color: #7f8c8d;">
									<div class="mb-3">
										<span>Pages: </span>
										<span style="color: #2c3e50; font-weight: 500;">
											{{ totalPagesFromSelectedItem }}
										</span>
									</div>

									<v-select v-if="hasSelectedPhanHieu" v-model="CuaHangID"
										:items="filteredCuaHangList" item-value="CuaHangID" item-text="TenCuaHang"
										label="Cửa hàng" outlined dense hide-details />
								</div>

								<div class="d-flex flex-wrap mt-6" style="gap: 12px;"
									v-if="selectedItem && selectedItem.MenuBookID">
									<v-btn color="success" variant="flat" size="large"
										@click.prevent="navigateToStore(selectedItem.MenuBookID, hasSelectedPhanHieu ? CuaHangID : 0)"
										style="text-transform: uppercase; font-weight: 600; min-width: 80px;">
										XEM MENU
									</v-btn>
								</div>
							</div>
						</v-col>
					</v-row>
				</v-card-text>
			</v-card>
		</v-dialog>

		<div class="menu-area shift-up-20">
			<!-- Kệ 1 (bìa lớn) -->
			<v-row class="case-row" no-gutters dense style="justify-content:center; column-gap:50px; row-gap:0;">
				<v-col v-for="item in displayList_Row_1" :key="item.MenuBookID || item.TenBook" cols="auto"
					class="d-flex justify-center align-end ma-0 pa-0">
					<v-card class="full-width-card" style="width:fit-content" @click="openItemModal(item)">
						<div class="item-image item-image--sm">
							<!-- Ribbon -->
							<div v-if="item.TagBook === 'NEW' || item.TagBook === 'HOT'" class="ribbon">
								<div class="ribbon__content"
									:style="{ backgroundColor: item.TagBook === 'NEW' ? '#52b700' : '#e88022' }">
									{{ item.TagBook }}
								</div>
							</div>

							<!-- Ảnh bìa -->
							<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + item.Thumbnail_FileID"
								:alt="item.TenBook" class="menu-cover" width="85" height="120" loading="lazy" />

							<!-- Spine trang trí cho kệ 1 -->
							<!-- <div class="book-border-container" style="right:-4px;width:5px;">
								<div style="position:absolute;width:1px;background:#ccc;height:120px;top:1px;left:1px;">
								</div>
								<div style="position:absolute;width:1px;background:#fff;height:118px;top:2px;left:2px;">
								</div>
								<div style="position:absolute;width:1px;background:#ccc;height:116px;top:3px;left:3px;">
								</div>
								<div style="position:absolute;width:1px;background:#fff;height:114px;top:4px;left:4px;">
								</div>
							</div> -->
						</div>

						<!-- Caption phân hiệu -->
						<div class="menu-caption" :title="item.TenBook">{{ item.TenBook }}</div>
					</v-card>
				</v-col>
			</v-row>

			<!-- Kệ 2 -->
			<v-row class="case-row" no-gutters dense style="justify-content:center; column-gap:50px; row-gap:0;">
				<v-col v-for="item in displayList_Row_2" :key="item.MenuBookID || item.TenBook" cols="auto"
					class="d-flex justify-center align-center ma-0 pa-0">
					<v-card class="full-width-card" style="width:fit-content" @click="openItemModal(item)">
						<div class="item-image item-image--sm">
							<!-- Ribbon -->
							<div v-if="item.TagBook === 'NEW' || item.TagBook === 'HOT'" class="ribbon">
								<div class="ribbon__content"
									:style="{ backgroundColor: item.TagBook === 'NEW' ? '#52b700' : '#e88022' }">
									{{ item.TagBook }}
								</div>
							</div>

							<!-- Ảnh bìa -->
							<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + item.Thumbnail_FileID"
								:alt="item.TenBook" class="menu-cover" width="85" height="120" loading="lazy" />
						</div>

						<!-- Caption phân hiệu -->
						<div class="menu-caption" :title="item.TenBook">{{ item.TenBook }}</div>
					</v-card>
				</v-col>
			</v-row>

			<!-- Kệ 3 -->
			<v-row class="case-row" no-gutters dense style="justify-content:center; column-gap:50px; row-gap:0;">
				<v-col v-for="item in displayList_Row_3" :key="item.MenuBookID || item.TenBook" cols="auto"
					class="d-flex justify-center align-center ma-0 pa-0">
					<v-card class="full-width-card" style="width:fit-content" @click="openItemModal(item)">
						<div class="item-image item-image--sm">
							<!-- Ribbon -->
							<div v-if="item.TagBook === 'NEW' || item.TagBook === 'HOT'" class="ribbon">
								<div class="ribbon__content"
									:style="{ backgroundColor: item.TagBook === 'NEW' ? '#52b700' : '#e88022' }">
									{{ item.TagBook }}
								</div>
							</div>

							<!-- Ảnh bìa -->
							<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + item.Thumbnail_FileID"
								:alt="item.TenBook" class="book-cover--sm" width="85" height="120" loading="lazy" />
						</div>

						<!-- Caption phân hiệu -->
						<div class="menu-caption" :title="item.TenBook">{{ item.TenBook }}</div>
					</v-card>
				</v-col>
			</v-row>

			<!-- Kệ 4 -->
			<v-row class="case-row" no-gutters dense style="justify-content:center; column-gap:50px; row-gap:0;">
				<v-col v-for="item in displayList_Row_4" :key="item.MenuBookID || item.TenBook" cols="auto"
					class="d-flex justify-center align-center ma-0 pa-0">
					<v-card class="full-width-card" style="width:fit-content" @click="openItemModal(item)">
						<div class="item-image item-image--sm">
							<!-- Ribbon -->
							<div v-if="item.TagBook === 'NEW' || item.TagBook === 'HOT'" class="ribbon">
								<div class="ribbon__content"
									:style="{ backgroundColor: item.TagBook === 'NEW' ? '#52b700' : '#e88022' }">
									{{ item.TagBook }}
								</div>
							</div>

							<!-- Ảnh bìa -->
							<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + item.Thumbnail_FileID"
								:alt="item.TenBook" class="book-cover--sm" width="85" height="120" loading="lazy" />
						</div>

						<!-- Caption phân hiệu -->
						<div class="menu-caption" :title="item.TenBook">{{ item.TenBook }}</div>
					</v-card>
				</v-col>
			</v-row>
			<!-- Kệ 5 -->
			<v-row class="case-row" no-gutters dense style="justify-content:center; column-gap:50px; row-gap:0;">
				<v-col v-for="item in displayList_Row_5" :key="item.MenuBookID || item.TenBook" cols="auto"
					class="d-flex justify-center align-center ma-0 pa-0">
					<v-card class="full-width-card" style="width:fit-content" @click="openItemModal(item)">
						<div class="item-image item-image--sm">
							<!-- Ribbon -->
							<div v-if="item.TagBook === 'NEW' || item.TagBook === 'HOT'" class="ribbon">
								<div class="ribbon__content"
									:style="{ backgroundColor: item.TagBook === 'NEW' ? '#52b700' : '#e88022' }">
									{{ item.TagBook }}
								</div>
							</div>

							<!-- Ảnh bìa -->
							<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + item.Thumbnail_FileID"
								:alt="item.TenBook" class="book-cover--sm" width="85" height="120" loading="lazy" />
						</div>

						<!-- Caption phân hiệu -->
						<div class="menu-caption" :title="item.TenBook">{{ item.TenBook }}</div>
					</v-card>
				</v-col>
			</v-row>
			<!-- Kệ 6 -->
			<v-row class="case-row" no-gutters dense style="justify-content:center; column-gap:50px; row-gap:0;">
				<v-col v-for="item in displayList_Row_6" :key="item.MenuBookID || item.TenBook" cols="auto"
					class="d-flex justify-center align-center ma-0 pa-0">
					<v-card class="full-width-card" style="width:fit-content" @click="openItemModal(item)">
						<div class="item-image item-image--sm">
							<!-- Ribbon -->
							<div v-if="item.TagBook === 'NEW' || item.TagBook === 'HOT'" class="ribbon">
								<div class="ribbon__content"
									:style="{ backgroundColor: item.TagBook === 'NEW' ? '#52b700' : '#e88022' }">
									{{ item.TagBook }}
								</div>
							</div>

							<!-- Ảnh bìa -->
							<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/' + item.Thumbnail_FileID"
								:alt="item.TenBook" class="book-cover--sm" width="85" height="120" loading="lazy" />
						</div>

						<!-- Caption phân hiệu -->
						<div class="menu-caption" :title="item.TenBook">{{ item.TenBook }}</div>
					</v-card>
				</v-col>
			</v-row>
		</div>

		<!-- Pagination -->
		<div class="pagination">
			<button class="control-button-pre" :disabled="Pag?.CurrentPage <= 1" @click="prevPage">
				<v-icon class="control-prev-button">mdi-chevron-left </v-icon>Trang trước
			</button>
			<span class="page-info" style="width: 71px;">{{ Pag?.CurrentPage }} / {{ Pag?.TotalPage }}</span>
			<button class="control-button-next" :disabled="Pag?.CurrentPage >= Pag?.TotalPage" @click="nextPage">
				Trang sau<v-icon class="control-next-button">mdi-chevron-right</v-icon>
			</button>
		</div>

		<!-- Footer -->
		<div class="footer">
			<div class="company-info">
				<h2>CÔNG TY TNHH MỘT THÀNH VIÊN SẢN XUẤT THƯƠNG MẠI DỊCH VỤ TÔ MINH</h2>
				<p>Địa chỉ: Tầng 1, số 328, đường 30/4, KP 1, Phường Trấn Biên, Đồng Nai, Việt Nam</p>
				<p>Mã số thuế: 3603411670 - Điện thoại: 0988446746</p>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: {
			phanhieu: {
				type: String,
				default: 'All'
			}
		},
		data() {
			return {
				localStoreMapping: [
					// Ví dụ: bạn tự sửa/điền name ở đây
					{ MenuBookID: 108, CuaHangID: 30, name: 'ZEN-GOT-PIZZA-Vo-Thi-Sau' },
					{ MenuBookID: 107, CuaHangID: 32, name: 'ZEN-FOOD-COURT' },
					{ MenuBookID: 106, CuaHangID: 38, name: 'ZEN-TEA-FOOD-COURT' },
					{ MenuBookID: 106, CuaHangID: 20, name: 'ZEN-TEA-Bien-Hung' },
					{ MenuBookID: 106, CuaHangID: 21, name: 'ZEN-TEA-Ngo-Quyen' },
					{ MenuBookID: 106, CuaHangID: 22, name: 'ZEN-TEA-Quang-Truong' },
					{ MenuBookID: 106, CuaHangID: 23, name: 'ZEN-TEA-Ho-Nai' },
					{ MenuBookID: 106, CuaHangID: 24, name: 'ZEN-TEA-Trang-Bom' },
					{ MenuBookID: 106, CuaHangID: 25, name: 'ZEN-TEA-Long-Thanh' },
					{ MenuBookID: 106, CuaHangID: 26, name: 'ZEN-TEA-Trang-Dai' },
					{ MenuBookID: 106, CuaHangID: 27, name: 'ZEN-TEA-Long-Khanh' },
					{ MenuBookID: 106, CuaHangID: 28, name: 'ZEN-TEA-Thich-Quang-Duc' },
					{ MenuBookID: 106, CuaHangID: 35, name: 'ZEN-TEA-Vo-Thi-Sau' },
					{ MenuBookID: 106, CuaHangID: 41, name: 'ZEN-TEA-3-2-Trang-Bom' },
					{ MenuBookID: 106, CuaHangID: 42, name: 'ZEN-TEA-Gia-Kiem' },
					{ MenuBookID: 106, CuaHangID: 43, name: 'ZEN-TEA-136-Nguyen-Thai-Hoc' },
					{ MenuBookID: 105, CuaHangID: 36, name: 'ZEN-HONGKONG-DIMSUM-Vo-Thi-Sau-Buoi-Toi' },
					{ MenuBookID: 102, CuaHangID: 36, name: 'ZEN-HONGKONG-DIMSUM-Vo-Thi-Sau-Buoi-Sang' },
					{ MenuBookID: 88, CuaHangID: 36, name: 'ZEN-Vo-Thi-Sau-Party-Decoration' },
					// ... bạn bổ sung các bản ghi khác
				],
				sortBy: null,          // 'name' | 'date'
				sortOrder: 'asc',      // 'asc' | 'desc'
				dialog: false,
				selectedItem: null,
				selectedTenPhanHieu: 'All',
	
				category_list_init: [],  // dữ liệu full sau khi sort/filter (không gán Page trực tiếp)
				category_list: [],       // dữ liệu trang hiện tại
	
				List_Row_1: [],
				List_Row_2: [],
				List_Row_3: [],
				List_Row_4: [],
				List_Row_5: [],
				List_Row_6: [],
	
	
				Desktop_Total_Col: 8,
				Tablet_Total_Col: 4,
				Mobile_Total_Col: 2,
	
				Pag: {
					CurrentPage: 0,
					TotalPage: null,
				},
	
				CuaHangID: null,
	
				_resizeHandler: null
			}
		},
	
		created() {
			this.initializeFromURL();
		},
	
		mounted() {
			this.loadMenuList();
	
			// Debounce resize
			const debounce = (fn, wait = 200) => {
				let t;
				return (...args) => {
					clearTimeout(t);
					t = setTimeout(() => fn.apply(this, args), wait);
				}
			};
			this._resizeHandler = debounce(() => {
				// Re-render trang hiện tại theo kích thước mới
				this.rebuildCurrentPage();
			}, 200);
	
			window.addEventListener('resize', this._resizeHandler);
		},
	
		beforeDestroy() {
			if (this._resizeHandler) window.removeEventListener('resize', this._resizeHandler);
		},
	
		computed: {
			phanHieuMap() {
				const map = new Map();
				const ds = this.DSPhanHieu || [];
				ds.forEach(p => map.set(Number(p.PhanHieuID), p.TenPhanHieu));
				return map;
			},
			hasSelectedPhanHieu() {
				return Array.isArray(this.selectedItem?._PhanHieuIDs) && this.selectedItem._PhanHieuIDs.length > 0;
			},
			filteredCuaHangList() {
				if (!this.selectedItem) return [];
				const allStores = this.DSCuaHang || [];
				const storeIds = Array.isArray(this.selectedItem._StoreIDs) ? this.selectedItem._StoreIDs : [];
	
				let list = allStores.filter(s => storeIds.includes(Number(s.CuaHangID)));
	
				if (this.selectedTenPhanHieu !== 'All') {
					const ph = (this.DSPhanHieu || []).find(p => p.TenPhanHieu === this.selectedTenPhanHieu);
					if (ph) {
						const targetId = Number(ph.PhanHieuID);
						const narrowed = list.filter(s => Number(s.PhanHieuID) === targetId);
						if (narrowed.length) list = narrowed;
					}
				}
				return list;
			},
			totalPagesFromSelectedItem() {
				if (!this.selectedItem) return null;
				let templateJson = '';
				if (this.selectedItem.TemplateDesktop) templateJson = this.selectedItem.TemplateDesktop;
				else if (this.selectedItem.TemplateIpad) templateJson = this.selectedItem.TemplateIpad;
				else if (this.selectedItem.TemplateMobile) templateJson = this.selectedItem.TemplateMobile;
				else return null;
	
				try {
					const parsed = JSON.parse(templateJson);
					return Array.isArray(parsed) ? parsed.length : 0;
				} catch {
					return 0;
				}
			},
			phanHieuOptions() {
				const ds = this.DSPhanHieu || [];
				return [
					{ text: 'Tất cả', value: 'All' }, // hiển thị VN, giữ value cũ
					...ds.map(p => ({ text: p.TenPhanHieu, value: p.TenPhanHieu }))
				];
			},
			DSPhanHieu() {
				return vueData?.DSPhanHieu || [];
			},
			DSCuaHang() {
				return vueData?.DSCuaHang || [];
			},
	
			// Các danh sách display sau khi lọc theo selectedTenPhanHieu
			displayList_Row_1() {
				return this.applyPhanHieuFilter(this.List_Row_1);
			},
			displayList_Row_2() {
				return this.applyPhanHieuFilter(this.List_Row_2);
			},
			displayList_Row_3() {
				return this.applyPhanHieuFilter(this.List_Row_3);
			},
			displayList_Row_4() {
				return this.applyPhanHieuFilter(this.List_Row_4);
			},
			displayList_Row_5() {
				return this.applyPhanHieuFilter(this.List_Row_5);
			},
			displayList_Row_6() {
				return this.applyPhanHieuFilter(this.List_Row_6);
			},
		},
	
		watch: {
			selectedTenPhanHieu(newVal) {
				const exists = this.phanHieuOptions.some(o => o.value === newVal);
				if (!exists) this.selectedTenPhanHieu = 'All';
				this.updateURLParameter('phanhieu', this.selectedTenPhanHieu);
				this.rebuildAllAndGoFirstPage();
			},
		},
	
		methods: {
			filterBySelectedPhanHieu(data) {
				if (this.selectedTenPhanHieu === 'All') return data;
				const ph = (this.DSPhanHieu || []).find(p => p.TenPhanHieu === this.selectedTenPhanHieu);
				if (!ph) return data;
				const targetId = Number(ph.PhanHieuID);
	
				return data.filter(it => {
					const arr = Array.isArray(it._PhanHieuIDs)
						? it._PhanHieuIDs
						: (Number.isFinite(it.PhanHieu_ID) ? [Number(it.PhanHieu_ID)] : []);
					return arr.includes(targetId);
				});
			},
			parseIdList(val) {
				if (!val) return [];
				return String(val)
					.split(",")
					.map(x => Number(x.trim()))
					.filter(Number.isFinite);
			},
			getPhanHieuNames(item) {
				const ids = Array.isArray(item?._PhanHieuIDs) ? item._PhanHieuIDs
					: (Number.isFinite(item?.PhanHieu_ID) ? [Number(item.PhanHieu_ID)] : []);
				const names = ids.map(id => this.phanHieuMap.get(id)).filter(Boolean);
				if (!names.length) return 'Không xác định';
				if (names.length <= 2) return names.join(' · ');
				return `${names[0]} · ${names[1]} +${names.length - 2}`;
			},
			// ====== TRA CỨU MAPPING & ĐIỀU HƯỚNG (KHÔNG SLUG) ======
			findStoreMapping(name) {
				const list = (this.localStoreMapping || []).filter(x => !!x && x.name != null);
				return list.find(x => x.name === name) || null;
			},
			findStoreMappingByIds(menuBookId, cuaHangId) {
				const mb = String(menuBookId), ch = String(cuaHangId);
				const list = (this.localStoreMapping || []);
				return list.find(x => String(x.MenuBookID) === mb && String(x.CuaHangID) === ch) || null;
			},
			navigateToStore(menuBookId, cuaHangId) {
				const BASE_MENU_URL = 'https://eorder.zentea.vn/menu-online';
				const hit = this.findStoreMappingByIds(menuBookId, cuaHangId);
				let url;
				if (hit && hit.name) {
					url = `${BASE_MENU_URL}?name=${encodeURIComponent(hit.name)}`;
				} else {
					url = `${BASE_MENU_URL}?MenuBookID=${Number(menuBookId) || 0}&CuaHangID=${Number(cuaHangId) || 0}`;
				}
				window.location.href = url;
			},
			// ===== URL param =====
			initializeFromURL() {
				const urlParams = new URLSearchParams(window.location.search);
				const phanHieuParam = urlParams.get('phanhieu'); // đã được decode sẵn
				if (phanHieuParam) {
					const exists = this.DSPhanHieu.find(p => p.TenPhanHieu === phanHieuParam);
					this.selectedTenPhanHieu = exists ? phanHieuParam : 'All';
				} else {
					this.selectedTenPhanHieu = 'All';
				}
			},
			updateURLParameter(paramName, paramValue) {
				const url = new URL(window.location);
				if (paramValue === 'All') url.searchParams.delete(paramName);
				else url.searchParams.set(paramName, paramValue); // để URLSearchParams tự encode
				window.history.pushState({}, '', url.toString());
			},
	
			// ===== Helpers =====
			sortTitle(field) {
				const isActive = this.sortBy === field;
				const dir = isActive ? (this.sortOrder === 'asc' ? '↑' : '↓') : '';
				return field === 'name' ? `Sort by Name ${dir}` : `Sort by Date ${dir}`;
			},
			applyPhanHieuFilter(list) {
				if (this.selectedTenPhanHieu === 'All') return list;
				const ph = (this.DSPhanHieu || []).find(p => p.TenPhanHieu === this.selectedTenPhanHieu);
				if (!ph) return list;
				const targetId = Number(ph.PhanHieuID);
	
				return list.filter(item => {
					const arr = Array.isArray(item._PhanHieuIDs) ? item._PhanHieuIDs : [];
					// fallback nếu item chưa enrich (hiếm)
					if (!arr.length && Number.isFinite(item.PhanHieu_ID)) return Number(item.PhanHieu_ID) === targetId;
					return arr.includes(targetId);
				});
			},
			currentCols() {
				if (window.innerWidth >= 1280) return this.Desktop_Total_Col;
				if (window.innerWidth >= 600) return this.Tablet_Total_Col;
				return this.Mobile_Total_Col;
			},
	
			// Tính Page trên mảng clone (không side-effect)
			renderPage_Items(data) {
				const cols = this.currentCols();
				const perPage = cols * 4; // 4 kệ / trang
				return data.map((item, i) => ({ ...item, Page: Math.floor(i / perPage) + 1 }));
			},
	
			// Cắt ra 4 hàng từ category_list (đã là trang hiện tại)
			fn_calcScreenSize(data) {
				if (!data || data.length === 0) {
					this.List_Row_1 = this.List_Row_2 = this.List_Row_3 = this.List_Row_4 = [];
					return;
				}
				const totalCol = this.currentCols();
				this.List_Row_1 = data.slice(0, totalCol);
				this.List_Row_2 = data.slice(totalCol, totalCol * 2);
				this.List_Row_3 = data.slice(totalCol * 2, totalCol * 3);
				this.List_Row_4 = data.slice(totalCol * 3, totalCol * 4);
			},
	
			// Build lại toàn bộ từ filter hiện tại (khi sort/filter/resize)
			rebuildAllAndGoFirstPage() {
				// 1) Lọc theo phân hiệu trước khi phân trang
				let filteredData = this.filterBySelectedPhanHieu(this.category_list_init);
				// if (this.selectedTenPhanHieu !== 'All') {
				// 	const selected = this.DSPhanHieu.find(p => p.TenPhanHieu === this.selectedTenPhanHieu);
				// 	if (selected) filteredData = this.category_list_init.filter(it => it.PhanHieu_ID === selected.PhanHieuID);
				// }
	
				// 2) Gán Page (trên clone)
				const withPage = this.renderPage_Items(filteredData);
	
				// 3) Tính tổng trang & set về trang 1
				const pages = withPage.map(x => x.Page);
				const total = pages.length ? Math.max(...pages) : 1;
				this.Pag = { CurrentPage: 1, TotalPage: total };
	
				// 4) Lấy trang 1 và cắt hàng
				this.category_list = withPage.filter(x => x.Page === 1);
				this.fn_calcScreenSize(this.category_list);
			},
	
			rebuildCurrentPage() {
				// Tương tự như trên nhưng giữ CurrentPage hiện tại (và clamp nếu vượt)
				let filteredData = this.filterBySelectedPhanHieu(this.category_list_init);
				// if (this.selectedTenPhanHieu !== 'All') {
				// 	const selected = this.DSPhanHieu.find(p => p.TenPhanHieu === this.selectedTenPhanHieu);
				// 	if (selected) filteredData = this.category_list_init.filter(it => it.PhanHieu_ID === selected.PhanHieuID);
				// }
	
				const withPage = this.renderPage_Items(filteredData);
				const pages = withPage.map(x => x.Page);
				const total = pages.length ? Math.max(...pages) : 1;
				const current = Math.min(this.Pag.CurrentPage || 1, total);
	
				this.Pag = { CurrentPage: current, TotalPage: total };
				this.category_list = withPage.filter(x => x.Page === current);
				this.fn_calcScreenSize(this.category_list);
			},
	
			// ===== Data flow =====
			loadMenuList() {
				ajaxCALL('/eorder/auth/MenuBook_Select', null, (res) => {
					const stores = this.DSCuaHang || [];
					const mapStoreToPh = new Map(stores.map(s => [Number(s.CuaHangID), Number(s.PhanHieuID)]));
	
					const raw = Array.isArray(res.data) ? res.data.map(x => ({ ...x })) : [];
					this.category_list_init = raw.map(item => {
						const storeIds = this.parseIdList(item.ApDung_CuaHangID); // chỉ dùng split
						const phanHieuIds = Array.from(new Set(
							storeIds.map(id => mapStoreToPh.get(Number(id))).filter(Number.isFinite)
						));
						return {
							...item,
							_StoreIDs: storeIds, // tất cả CuaHangID áp dụng
							_PhanHieuIDs: phanHieuIds // tất cả PhanHieuID suy ra
						};
					});
	
					this.initializeFromURL();
					this.rebuildAllAndGoFirstPage();
				});
			},
	
			onPhanHieuChange() {
				this.updateURLParameter('phanhieu', this.selectedTenPhanHieu);
				this.rebuildAllAndGoFirstPage();
			},
	
			// ===== Pagination =====
			prevPage() {
				if (this.Pag.CurrentPage <= 1) return;
				this.Pag = { ...this.Pag, CurrentPage: this.Pag.CurrentPage - 1 };
				this.rebuildCurrentPage();
			},
			nextPage() {
				if (this.Pag.CurrentPage >= this.Pag.TotalPage) return;
				this.Pag = { ...this.Pag, CurrentPage: this.Pag.CurrentPage + 1 };
				this.rebuildCurrentPage();
			},
	
			// ===== Sort =====
			sortCategoryList() {
				const key = this.sortBy === 'name' ? 'TenBook' : 'UpdateTime';
				const dir = this.sortOrder === 'asc' ? 1 : -1;
	
				// Sắp xếp trên mảng gốc (clone lại để an toàn nếu cần về sau)
				this.category_list_init.sort((a, b) => {
					let va, vb;
					if (key === 'TenBook') {
						va = (a[key] || '').toString().toLowerCase();
						vb = (b[key] || '').toString().toLowerCase();
					} else {
						va = new Date(a[key] || 0).getTime();
						vb = new Date(b[key] || 0).getTime();
					}
					return (va > vb ? 1 : va < vb ? -1 : 0) * dir;
				});
	
				// Sau khi sort, build lại trang 1
				this.rebuildAllAndGoFirstPage();
			},
	
			toggleSort(field) {
				if (this.sortBy === field) {
					this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
				} else {
					this.sortBy = field;
					this.sortOrder = 'asc';
				}
				this.sortCategoryList();
			},
	
			// ===== Modal =====
			openItemModal(item) {
				this.selectedItem = item;
				// Lấy danh sách cửa hàng áp dụng cho item
				const list = this.filteredCuaHangList;
				this.CuaHangID = list.length ? Number(list[0].CuaHangID) : null;
				this.dialog = true;
			},
			// ===== Misc =====
			badgeColor(type) {
				switch (type) {
					case 'green': return 'green'
					case 'red': return 'red'
					case 'orange': return 'orange darken-2'
					case 'gold': return 'yellow darken-3'
					default: return 'grey'
				}
			},
		},
	}
</script>