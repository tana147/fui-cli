<template>
	<Global upload-manager>
		<template #header>
			<v-card>
				<v-card-text class="header-content">
					<span class="page-title">Soạn thảo học liệu</span>
					<template v-if="selectedKhoi !== null">
						<v-icon size="small" class="text-medium-emphasis">mdi-chevron-right</v-icon>
						<span class="text-body-2 text-medium-emphasis">{{ getKhoiName(selectedKhoi) }}</span>
					</template>
					<template v-if="selectedMon">
						<v-icon size="small" class="text-medium-emphasis">mdi-chevron-right</v-icon>
						<v-chip size="small" color="primary" variant="tonal">{{ getMonName(selectedMon) }}</v-chip>
					</template>
					<template v-if="selectedHocLieu">
						<v-icon size="small" class="text-medium-emphasis">mdi-chevron-right</v-icon>
						<v-chip size="small" color="secondary" variant="tonal">{{ selectedHocLieu.TenHocLieu }}</v-chip>
					</template>
					<v-spacer />
					<div class="header-actions" v-if="selectedHocLieu">
						<v-btn color="success" variant="tonal" size="small" @click="addNewRootNode"
							class="add-root-btn">
							<v-icon start>mdi-plus-circle</v-icon>
							Thêm mục gốc
						</v-btn>
						<!-- Dùng cùng luồng import với empty state; null target để tạo node trực tiếp ở root.
						     Nút nằm ngoài cây node và dùng cùng style với nút thêm mục gốc. -->
						<v-btn color="success" variant="tonal" size="small" class="add-root-btn ml-2" @click="openImportContentForRoot">
							<v-icon start>mdi-database-import-outline</v-icon>
							Lấy từ Content Hub
						</v-btn>
					</div>
				</v-card-text>
			</v-card>
		</template>
		<v-divider />

		<!-- Main Content -->
		<div class="main-content">
			<!-- Filter & Book Selection -->
			<div class="filter-panel">
				<div class="filter-header pa-1">
					<v-row dense class="align-center flex-grow-1 ma-0">
						<v-col cols="12" md="4" class="pa-1">
							<v-select ref="bookSelect" label="Bộ sách" :items="DSBoSach" v-model="selectedBoSach" variant="outlined"
								density="compact" prepend-inner-icon="mdi-bookshelf"
								item-title="TenBoSach" item-value="BoSachID" />
						</v-col>
						<v-col cols="12" md="4" class="pa-1">
							<v-select ref="gradeSelect" v-model="selectedKhoi" label="Chọn khối" :items="DSKhoi" item-title="name"
								item-value="id" variant="outlined" density="compact" />
						</v-col>
						<v-col cols="12" md="4" class="pa-1">
							<v-select ref="subjectSelect" v-model="selectedMon" label="Chọn môn học" :items="DSMonHoc"
								item-title="MonHocName" item-value="MonHocID" variant="outlined" density="compact" />
						</v-col>
					</v-row>
				</div>

				<div class="book-selection" v-if="DSHocLieu.length >= 2">
					<div class="book-list-container" v-if="DSHocLieu.length >= 2">
						<div class="book-list-header">
							<span class="list-title">Sách trong bộ</span>
						</div>

						<div class="book-list" v-if="DSHocLieu.length > 0">
							<div v-for="sach in DSHocLieu" :key="sach.HocLieuID" class="book-item"
								:class="{ 'active': selectedHocLieu && selectedHocLieu.HocLieuID === sach.HocLieuID }"
								@click="selectHocLieu(sach)">
								<div class="book-icon">
									<v-icon color="primary">mdi-book</v-icon>
								</div>
								<div class="book-info">
									<h4 class="book-title">{{ sach.TenHocLieu }}</h4>
									<!-- <p class="book-meta">{{ selectedBoSach }}</p> -->
									<p class="book-meta">{{ sach.TenBoSach }}</p>
								</div>
								<div class="book-status"
									v-if="selectedHocLieu && selectedHocLieu.HocLieuID === sach.HocLieuID">
									<v-icon color="success">mdi-check-circle</v-icon>
								</div>
							</div>
						</div>

					</div>
				</div>
			</div>

			<!-- Main Editor -->
			<div class="editor-section">
				<!-- Tree Editor -->
				<div class="tree-editor">
					<div v-if="!selectedHocLieu" class="welcome-state">
						<div class="welcome-content">
							<v-icon size="80" color="primary" class="welcome-icon">mdi-file-tree</v-icon>
							<h3 class="welcome-title">Chào mừng đến với Trình soạn thảo</h3>
							<p class="welcome-description">
								Chọn một cuốn sách ở vùng phía trên để bắt đầu tạo và chỉnh sửa cấu trúc nội dung.
							</p>
							<v-btn color="primary" variant="outlined" size="large" @click="scrollToSidebar">
								<v-icon start>mdi-arrow-up</v-icon>
								Chọn học liệu
							</v-btn>
						</div>
					</div>

					<div v-else class="tree-content">
						<div class="tree-header">
							<div class="tree-stats">
								<span class="text-subtitle-2 font-weight-bold">Cấu trúc nội dung</span>
								<v-chip size="small" color="info" variant="flat">
									<v-icon start size="small">mdi-sitemap</v-icon>
									{{ getTreeStats() }} mục
								</v-chip>
							</div>
							<div class="tree-actions">
								<v-btn size="small" variant="text" color="info" @click="openThongKeDialog">
									<v-icon start>mdi-chart-box-outline</v-icon>
									Thống kê HS xem
								</v-btn>
								<v-btn size="small" variant="text" color="primary" @click="refreshTree"
									:loading="isLoadingTree">
									<v-icon start>mdi-refresh</v-icon>
									Tải lại
								</v-btn>
								<v-btn size="small" variant="text" @click="toggleExpandCollapse">
									<v-icon start>{{ isAllCollapsed ? 'mdi-expand-all' : 'mdi-collapse-all' }}</v-icon>
									{{ isAllCollapsed ? 'Mở rộng' : 'Thu gọn' }}
								</v-btn>
								<v-btn size="small" variant="text" color="error" @click="deleteSelectedNodes"
									:disabled="selectedCount === 0">
									<v-icon start>mdi-delete-outline</v-icon>
									Xóa {{ selectedCount > 0 ? `(${selectedCount})` : '' }}
								</v-btn>
							</div>
						</div>

						<div class="tree-container">
							<v-skeleton-loader v-if="isLoadingTree" type="list-item-two-line@5" class="tree-skeleton">
							</v-skeleton-loader>

							<uc-editable-treeview-v2 v-else :nodes="treeNoiDung"
								:hoc-lieu-id="selectedHocLieu.HocLieuID" :collapsed-node-ids="collapsedNodeIds"
								:selected-node-ids="selectedNodeIds"
								:drag-state="treeDragState" :key="treeKey" @update="onTreeUpdate"
								@add-new="onAddNewChild" @edit="onEditItem" @delete="onDeleteNode"
								@import-content="onImportContent"
								@toggle-select="onToggleSelectNode"
								@toggle-teacher-only="onToggleTeacherOnly" />

							<div v-if="!isLoadingTree && treeNoiDung.length === 0" class="empty-tree">
								<v-icon size="64" color="grey-lighten-2">mdi-file-tree-outline</v-icon>
								<h4>Chưa có nội dung</h4>
								<p>Hãy thêm chương hoặc bài học đầu tiên</p>
				<!-- Hai cách khởi tạo được gom cùng một hàng; chữ "hoặc" nối rõ lựa chọn tạo mới và lấy từ kho dùng chung. -->
				<div class="d-flex justify-center align-center flex-wrap ga-2 mt-4">
					<v-btn color="primary" @click="addNewRootNode">
						<v-icon start>mdi-plus</v-icon>
						Thêm mục đầu tiên
					</v-btn>
					<span class="text-caption text-medium-emphasis">hoặc</span>
					<v-btn color="primary" variant="outlined" @click="openImportContentForRoot">
						<v-icon start>mdi-database-import-outline</v-icon>
						Lấy từ Content Hub
					</v-btn>
				</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
		<!-- THÊM: Tích hợp Dialog vào đây -->
		<uc-noi-dung-dialog v-model:is-open="isDialogOpen" :item="editingItem"
			:resource-context="{ KhoiID: selectedKhoi, MonHocID: selectedMon, BoSachID: selectedBoSach }"
			@save="onSaveItem" @refresh-tree="fetchTreeNoiDung" @update-item="editingItem = $event" />
		<!-- Dùng component global để luồng import thống nhất; ảnh được lưu thành node IMAGE riêng. -->
		<uc-content-hub-import-dialog v-model="isImportContentDialogOpen"
			:resource="{ KhoiID: selectedKhoi, MonHocID: selectedMon }"
			:allowed-document-types="['DOCUMENT', 'VIDEO', 'AUDIO', 'IMAGE', 'HTML', 'ISPRING']"
			@import-document="onImportContentDocument" @import-question="onImportContentQuestion" />
		<uc-thong-ke-xem-hoc-lieu-dialog v-model="isThongKeDialogOpen"
			:hoc-lieu-id="selectedHocLieu ? selectedHocLieu.HocLieuID : null"
			:hoc-lieu-title="selectedHocLieu ? selectedHocLieu.TenHocLieu : ''"
			:khoi-id="selectedKhoi"
			:mon-hoc-id="selectedMon"
			:mon-hoc-name="getMonName(selectedMon)"
			:has-content="treeNoiDung && treeNoiDung.length > 0" />
	</Global>
</template>

<script>
	export default {
		name: 'uc-main-layout',
	inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
	props: ['khoiIdProp', 'monHocIdProp'],
	data() {
		return {
			vueData,
			selectedBoSach: null,
			DSHocLieu: [],
			selectedHocLieu: null,
			treeNoiDung: [],
			isLoadingTree: false,
			treeKey: 0,
			collapsedNodeIds: {},
			selectedNodeIds: {},
			treeDragState: {
				info: null
			},
			// THÊM: State để quản lý dialog
			isDialogOpen: false,
			isThongKeDialogOpen: false,
			editingItem: null,
			isImportContentDialogOpen: false,
			importContentTarget: null,
			selectedMon: null,
			selectedKhoi: null,
			isInitializingFromUrl: false,
			DSBoSach: [],
			DSMonHoc: [],
			DSKhoi: [
				{ id: 0, name: "Mầm non", CapID: 0 },
				{ id: 1, name: "Khối 1" , CapID: 1},
				{ id: 2, name: "Khối 2" , CapID: 1},
				{ id: 3, name: "Khối 3" , CapID: 1},
				{ id: 4, name: "Khối 4" , CapID: 1},
				{ id: 5, name: "Khối 5" , CapID: 1},

				{ id: 6, name: "Khối 6" , CapID: 2},
				{ id: 7, name: "Khối 7" , CapID: 2},
				{ id: 8, name: "Khối 8" , CapID: 2},
				{ id: 9, name: "Khối 9" , CapID: 2},

				{ id: 10, name: "Khối 10" , CapID: 3},
				{ id: 11, name: "Khối 11" , CapID: 3},
				{ id: 12, name: "Khối 12" , CapID: 3},
			]
		}
	},
	computed: {
		isAllCollapsed() {
			return Object.keys(this.collapsedNodeIds || {}).length > 0;
		},
		selectedCount() {
			return Object.keys(this.selectedNodeIds || {}).filter(id => this.selectedNodeIds[id]).length;
		}
	},
		async mounted() {
			await this.getDSBoSach();
			await this.initializeSelectionFromUrl();
		},
	watch: {
		selectedKhoi: function (selectedKhoi) {
			this.selectedMon = null
			this.selectedHocLieu = null
			this.DSHocLieu = []
			this.treeNoiDung = []
			// Đổi khối làm môn học cũ không còn hợp lệ; URL cũng phải phản ánh trạng thái này.
			if (!this.isInitializingFromUrl) this.syncSelectionToUrl(selectedKhoi, null)
			if (selectedKhoi !== null && selectedKhoi !== undefined && selectedKhoi !== '' && !this.isInitializingFromUrl) {
				this.getDSMonHoc()
			}
		},
		selectedMon: function (selectedMon) {
			this.selectedHocLieu = null
			this.DSHocLieu = []
			this.treeNoiDung = []
			if (!this.isInitializingFromUrl) {
				// Chỉ ghi cặp query hoàn chỉnh khi đã chọn đủ khối và môn để URL mở lại được đúng dữ liệu.
				this.syncSelectionToUrl(this.selectedKhoi, selectedMon)
				if (selectedMon !== null && selectedMon !== undefined && selectedMon !== '' && this.selectedKhoi !== null && this.selectedKhoi !== undefined && this.selectedKhoi !== '') {
					this.fetchHocLieu()
				}
			}
		}
	},
		methods: {
			getUrlSelectionId(paramName) {
				if (typeof window === 'undefined') return null;
				const params = new URLSearchParams(window.location.search || '');
				const rawValue = params.get(paramName) ?? params.get(paramName.toLowerCase());
				if (rawValue === null || rawValue === '') return null;
				const value = Number(rawValue);
				return Number.isFinite(value) && value >= 0 ? value : null;
			},
			getUrlSelection() {
				return {
					KhoiID: this.getUrlSelectionId('KhoiID'),
					MonHocID: this.getUrlSelectionId('MonHocID')
				};
			},
			hasSelectionValue(value) {
				return value !== null && value !== undefined && value !== '';
			},
			syncSelectionToUrl(khoiId, monHocId) {
				if (typeof window === 'undefined' || !window.history?.replaceState) return;
				const url = new URL(window.location.href);
				const hasKhoi = this.hasSelectionValue(khoiId);
				const hasMonHoc = hasKhoi && this.hasSelectionValue(monHocId);

				// Giữ nguyên các query khác của trang; chỉ thay đổi hai tham số lựa chọn của màn hình.
				url.searchParams.delete('khoiid');
				url.searchParams.delete('monhocid');
				if (hasKhoi) url.searchParams.set('KhoiID', String(khoiId));
				else url.searchParams.delete('KhoiID');
				if (hasMonHoc) url.searchParams.set('MonHocID', String(monHocId));
				else url.searchParams.delete('MonHocID');

				window.history.replaceState(window.history.state, document.title, `${url.pathname}${url.search}${url.hash}`);
			},
			async initializeSelectionFromUrl() {
				const requested = this.getUrlSelection();
				const khoiExists = this.DSKhoi.some(item => Number(item.id) === requested.KhoiID);
				if (!khoiExists) return;

				// Tạm khóa watcher để việc khôi phục query không làm mất MonHocID trước khi danh sách môn tải xong.
				this.isInitializingFromUrl = true;
				try {
					this.selectedKhoi = requested.KhoiID;
					await this.getDSMonHoc();
					const monHoc = this.DSMonHoc.find(item => Number(item.MonHocID) === requested.MonHocID);
					if (monHoc) this.selectedMon = monHoc.MonHocID;
				} finally {
					this.isInitializingFromUrl = false;
				}

				// Khi mở bằng URL có đủ hai ID, tự tải danh sách học liệu ngay sau khi hai select được khôi phục.
				if (this.hasSelectionValue(this.selectedKhoi) && this.hasSelectionValue(this.selectedMon)) {
					await this.fetchHocLieu();
				}
			},
			openThongKeDialog() {
				this.isThongKeDialogOpen = true;
			},
			notify(message, color = 'success') {
				this.snackbarRef?.value?.showSnackbar?.({ message, color });
			},
			async getDSBoSach() {
				const res = await fetchPromise('lms/FP_BoSach_GetList');
				this.DSBoSach = res ?? [];
				this.selectedBoSach = this.DSBoSach[0] ? this.DSBoSach[0].BoSachID : null;
			},
			async getDSMonHoc() {
				const capid = this.DSKhoi.find(x=> x.id == this.selectedKhoi)?.CapID
				const res = await fetchPromise('lms/MonHoc_Get_ByCapID', {CapID: capid});
				this.DSMonHoc = res ?? [];
		},
		getKhoiName(khoiId) {
			const khoi = this.DSKhoi.find(item => item.id === khoiId);
			return khoi ? khoi.name : '';
		},
		getMonName(monHocId) {
			const mon = this.DSMonHoc.find(item => item.MonHocID === monHocId);
			return mon ? (mon.MonHocName || mon.TenMonHoc_HienThi || mon.TenMonHoc || '') : '';
		},
			async fetchHocLieu() {
				const res = await fetchPromise('lms/FP_HocLieu_GetByLopMon', {
					KhoiID: this.selectedKhoi,
					MonHocID: this.selectedMon
				});
				this.DSHocLieu = res ?? [];
				if (this.DSHocLieu.length === 1) {
					this.selectHocLieu(this.DSHocLieu[0]);
				}
			},
		async selectHocLieu(sach) {
			this.selectedHocLieu = sach;
			this.isLoadingTree = true;
			this.collapsedNodeIds = {};
			this.selectedNodeIds = {};
			await this.fetchTreeNoiDung();
			this.isLoadingTree = false;
			console.log("Cây đã được xây dựng xong:", this.treeNoiDung);
		},
			async fetchTreeNoiDung() {
				if (!this.selectedHocLieu) {
					throw new Error("Chưa chọn học liệu");
				}
				const res = await fetchPromise('lms/FP_NoiDung_GetTreeByHocLieu', {
					HocLieuID: this.selectedHocLieu.HocLieuID
				}, { forceRefresh: true });
				const flatList = Array.isArray(res?.[1]) ? res[1] : [];
				this.buildTree(flatList);
				this.treeKey += 1;
			},
			async refreshTree() {
				if (!this.selectedHocLieu) return;
				this.isLoadingTree = true;
				this.selectedNodeIds = {};
				try {
					await this.fetchTreeNoiDung();
					this.notify("Tải lại cấu trúc thành công!");
				} catch (e) {
					console.error(e);
					this.notify("Tải lại thất bại!", "error");
				} finally {
					this.isLoadingTree = false;
				}
			},
		// HÀM MỚI: Mở dialog
		onOpenDialog(itemToEdit = null) {
				if (!this.selectedHocLieu) {
					this.notify("Vui lòng chọn một cuốn sách trước.", "warning");
					return;
				}

			if (itemToEdit) {
				// Trường hợp Sửa hoặc Thêm con
				// Nếu là thêm con, itemToEdit là node cha
				if (itemToEdit.parent) {
					this.editingItem = {
						HocLieuID: this.selectedHocLieu.HocLieuID,
						TenHocLieu: this.selectedHocLieu.TenHocLieu,
						ParentID: itemToEdit.parent.NoiDungID,
						LoaiNoiDung: 'BAI', // Mặc định
						ThuTu: itemToEdit.parent.children ? itemToEdit.parent.children.length + 1 : 1
					};
				} else { // Trường hợp sửa
					this.editingItem = itemToEdit;
				}
			} else {
				// Trường hợp Thêm mục gốc
				this.editingItem = {
					HocLieuID: this.selectedHocLieu.HocLieuID,
					TenHocLieu: this.selectedHocLieu.TenHocLieu,
					ParentID: null,
					LoaiNoiDung: 'CHUONG',
					ThuTu: this.treeNoiDung.length + 1
				};
			}
			this.isDialogOpen = true;
		},
		escapeHtml(unsafeString) {
			if (typeof unsafeString !== 'string') {
				return '';
			}
			const element = document.createElement('div');
			element.textContent = unsafeString;
			return element.innerHTML;
		},

		onEditItem(itemToEdit) {
			if (!itemToEdit) return;
			console.log("Chỉnh sửa node:", itemToEdit);
			this.editingItem = { ...itemToEdit, TenHocLieu: this.selectedHocLieu.TenHocLieu }; // Gán item cần sửa
			this.isDialogOpen = true;
		},

		// HÀM MỚI: Chỉ để mở dialog khi THÊM MỤC GỐC
		onAddNewRoot() {
			if (!this.selectedHocLieu) return;
			console.log("Thêm mục gốc mới...");
			this.editingItem = {
				HocLieuID: this.selectedHocLieu.HocLieuID,
				TenHocLieu: this.selectedHocLieu.TenHocLieu,
				ParentID: null,
				LoaiNoiDung: 'CHUONG',
				ThuTu: this.treeNoiDung.length + 1
			};
			this.isDialogOpen = true;
		},

		// HÀM MỚI: Chỉ để mở dialog khi THÊM MỤC CON
		onAddNewChild(parentNode) {
			if (!parentNode) return;
			console.log("Thêm node con cho:", parentNode);
			this.editingItem = {
				HocLieuID: this.selectedHocLieu.HocLieuID,
				TenHocLieu: this.selectedHocLieu.TenHocLieu,
				ParentID: parentNode.NoiDungID,
				LoaiNoiDung: 'BAI',
				ThuTu: parentNode.children ? parentNode.children.length + 1 : 1
			};
			this.isDialogOpen = true;
		},

		// HÀM MỚI: Xử lý sự kiện save từ dialog, hỗ trợ lưu nhiều câu một lần
			async onSaveItem(payload) {
				const itemsToSave = Array.isArray(payload) ? payload : [payload];
				if (!itemsToSave.length) return;
				console.log("Dữ liệu nhận từ dialog để lưu:", itemsToSave);
				this.isDialogOpen = false;
				let successCount = 0;

				for (const rawItem of itemsToSave) {
					const item = { ...rawItem };
					item.ParentID = item.ParentID ?? this.editingItem?.ParentID ?? 0;
					if (itemsToSave.length > 1 || !this.editingItem?.NoiDungID) {
						delete item.NoiDungID;
					}
					try {
						const res = await fetchPromise('lms/FP_NoiDung_Save', item, { cache: false });
						const saved = Array.isArray(res) ? res[0] : res;
						const apiError = saved && (
							saved.Success === false || saved.success === false ||
							saved.Error || saved.error || saved.Status === 'ERROR'
						);
						const savedId = saved?.NoiDungID ?? saved?.noidungid;
						// SP trả lại bản ghi vừa lưu; không coi object lỗi/rỗng là lưu thành công.
						if (apiError || !savedId) {
							throw new Error(saved?.Message || saved?.message || saved?.Error || saved?.error || 'API không trả về mục đã lưu.');
						}
						successCount++;
					} catch (error) {
						console.error('Lỗi khi lưu nội dung:', error);
					}
				}

				if (successCount === itemsToSave.length) {
					this.notify(itemsToSave.length > 1 ? `Đã lưu thành công ${successCount} câu!` : "Đã lưu thành công!");
				} else if (successCount > 0) {
					this.notify(`Đã lưu ${successCount}/${itemsToSave.length} câu.`, "warning");
				} else {
					this.notify("Lưu thất bại!", "error");
				}
				if (successCount > 0) await this.fetchTreeNoiDung();
			},

			// Chỉ mở dialog và giữ lại node đích; component global chịu trách nhiệm tải/chọn tài liệu.
			async onImportContent(targetNode) {
				if (!targetNode || !this.selectedHocLieu) return;
				this.importContentTarget = targetNode;
				this.isImportContentDialogOpen = true;
			},

			// Empty state không có node đích; null được hiểu là import trực tiếp vào root của học liệu.
			openImportContentForRoot() {
				if (!this.selectedHocLieu) return;
				this.importContentTarget = null;
				this.isImportContentDialogOpen = true;
			},

			// Component global chỉ chuẩn hóa dữ liệu tài liệu và phát event; module này lưu node vào học liệu hiện tại.
			async onImportContentDocument(document) {
				const targetNode = this.importContentTarget;
				if (!document || !this.selectedHocLieu) return;
				try {
					const parentId = targetNode?.NoiDungID || 0;
					const siblingCount = targetNode ? (targetNode.children || []).length : this.treeNoiDung.length;
					const contentType = this.getImportedContentType(document);
					// Content Hub lưu video tương tác theo nhóm mốc thời gian. Giữ timerMarkers làm nguồn chuẩn
					// và map thêm url để form VIDEO của soạn học liệu có thể mở lại đúng link khi edit node.
					const timerMarkers = this.normalizeImportedInteractiveMarkers(
						Array.isArray(document.timerMarkers) ? document.timerMarkers : (document.interactions || [])
					);
					const dataJson = {
						...document,
						// Audio/image dùng URL trực tiếp từ Content Hub; video/tài liệu vẫn giữ fallback viewer cũ.
						url: document.url || document.audioUrl || document.source || document.viewerSource || document.externalSource || '',
						audioUrl: document.audioUrl || '',
						slideType: document.slideType || '',
						interactions: timerMarkers,
						timerMarkers: timerMarkers,
						origin: 'CONTENT_HUB',
						sourceNoiDungID: document.sourceTracking?.nodeId || null,
						sourceHocLieuID: document.sourceTracking?.resourceId || null
					};
					// Import tạo node mới giống luồng Tạo tài liệu: bỏ NoiDungID để API tự tạo bản ghi mới.
					const saveResult = await fetchPromise('lms/FP_NoiDung_Save', {
						HocLieuID: this.selectedHocLieu.HocLieuID,
						ParentID: parentId,
						TenHocLieu: this.selectedHocLieu.TenHocLieu || '',
						TenNoiDung: document.name || 'Tài liệu Content Hub',
						LoaiNoiDung: contentType,
						NguonTaiNguyenCode: 'CONTENT_HUB',
						ThuTu: siblingCount + 1,
						User: this.vueData.user?.UserID,
						DataJson: JSON.stringify(dataJson)
					}, { cache: false });
					// Một số tAPI trả lỗi trong object thay vì reject Promise; không đóng giả thành công khi node chưa được tạo.
					const saved = Array.isArray(saveResult) ? saveResult[0] : saveResult;
					if (saved && (saved.Success === false || saved.success === false || saved.Error || saved.error)) {
						throw new Error(saved.Message || saved.message || saved.Error || saved.error || 'API không tạo được nội dung.');
					}
					await this.fetchTreeNoiDung();
					this.importContentTarget = null;
					this.notify('Đã import tài liệu từ Content Hub.');
				} catch (error) {
					this.notify(error?.message || 'Import tài liệu thất bại.', 'error');
				}
			},

			// Chuẩn hóa wrapper parseQuestion của Content Hub về schema prompt/options mà quiz editor đang dùng.
			normalizeImportedQuestion(question) {
				const rawType = String(question?.type || question?.config?.type || 'QUIZ_SINGLE_CHOICE').toUpperCase();
				const typeMap = { QUIZ_MULTIPLE_TRUE_FALSE: 'QUIZ_TRUE_FALSE' };
				const type = typeMap[rawType] || rawType;
				const sourceConfig = question?.config && typeof question.config === 'object' ? question.config : {};
				const questionContent = question?.content && typeof question.content === 'object' ? question.content : {};
				const nestedContent = sourceConfig.content && typeof sourceConfig.content === 'object' ? sourceConfig.content : {};
				// Content Hub có bản ghi phẳng và bản ghi bọc trong content/config; gom về schema mà editor và viewer cùng dùng.
				const data = { ...sourceConfig, ...questionContent, ...nestedContent };
				const getText = value => {
					if (typeof value === 'string') return value;
					return value?.html || value?.content || value?.text || value?.label || '';
				};
				const prompt = data.prompt || data.questionText || question.prompt || question.questionText || '';
				data.prompt = getText(prompt);
				data.questionText = data.questionText || data.prompt;
				const normalizeItems = (items, prefix, mapper = item => item) => (Array.isArray(items) ? items : []).map((item, index) => {
					// Một số bản ghi cũ lưu lựa chọn dạng chuỗi; chuyển thành object trước khi spread để không mất nội dung.
					const normalized = mapper(item && typeof item === 'object' ? item : { text: item });
					return { ...normalized, id: normalized.id || `${prefix}_${index + 1}`, text: getText(normalized.text ?? normalized.label ?? normalized.value ?? normalized.content) };
				});
				const optionSource = data.options || data.answers || data.choices || [];
				if (['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_TRUE_FALSE'].includes(type)) {
					data.options = normalizeItems(optionSource, type === 'QUIZ_TRUE_FALSE' ? 'tf' : 'opt');
				}
				if (type === 'QUIZ_SINGLE_CHOICE' && data.correctAnswer && typeof data.correctAnswer === 'object') data.correctAnswer = data.correctAnswer.id;
				if (type === 'QUIZ_MULTIPLE_CHOICE') {
					data.correctAnswers = (Array.isArray(data.correctAnswers) ? data.correctAnswers : []).map(answer => typeof answer === 'object' ? answer.id : answer).filter(Boolean);
				}
				if (type === 'QUIZ_MATCHING') {
					data.columnA = normalizeItems(data.columnA || data.leftItems, 'a');
					data.columnB = normalizeItems(data.columnB || data.rightItems, 'b');
				}
				if (type === 'QUIZ_ORDERING') data.items = normalizeItems(data.items || data.orderItems, 'item');
				if (type === 'QUIZ_DRAG_DROP_CATEGORIZE') {
					data.categories = (Array.isArray(data.categories) ? data.categories : []).map((category, index) => ({ ...category, id: category.id || `cat_${index + 1}`, name: getText(category.name || category.text || category.label) }));
					data.items = normalizeItems(data.items || data.draggableItems, 'item');
				}
				if (type === 'QUIZ_CONNECTION') {
					data.groups = normalizeItems(data.groups, 'group');
					data.items = normalizeItems(data.items, 'item');
				}
				if (type === 'QUIZ_FILL_IN_BLANK') {
					// Chuẩn hóa cả parts nằm ở wrapper cũ và đáp án nhiều biến thể để node lưu ra không bị rỗng khi viewer đọc.
					const sourceParts = [data.parts, questionContent.parts, sourceConfig.parts, question.parts]
						.find(candidate => Array.isArray(candidate)) || [];
					data.parts = sourceParts.map((part, index) => {
						const item = part && typeof part === 'object' ? part : { type: 'text', value: part };
						if (String(item.type || '').toLowerCase() !== 'blank' && item.isBlank !== true && item.kind !== 'blank') {
							return { ...item, type: 'text', value: getText(item.value ?? item.text ?? item.content ?? item.label) };
						}
						const acceptedAnswers = (Array.isArray(item.acceptedAnswers) ? item.acceptedAnswers : String(item.correctAnswer || item.answer || '').split('/'))
							.map(getText).map(answer => answer.trim()).filter(Boolean);
						const correctAnswer = getText(item.correctAnswer || item.answer || acceptedAnswers[0]).trim();
						return {
							...item,
							type: 'blank',
							id: item.id || `blank_${index + 1}`,
							correctAnswer,
							acceptedAnswers: acceptedAnswers.length ? acceptedAnswers : (correctAnswer ? [correctAnswer] : [])
						};
					});
				}
				if (rawType !== type) data.sourceOriginalType = rawType;
				return { type, data, originalType: rawType };
			},

			// Câu hỏi từ Content Hub được lưu thành schema phẳng để dialog Soạn học liệu mở lại đúng dạng và đáp án.
			async onImportContentQuestion(question) {
				if (!question || !this.selectedHocLieu) return;
				try {
					const targetNode = this.importContentTarget;
					const parentId = targetNode?.NoiDungID || 0;
					const siblingCount = targetNode ? (targetNode.children || []).length : this.treeNoiDung.length;
					const normalized = this.normalizeImportedQuestion(question);
					const questionText = normalized.data.prompt || 'Câu hỏi từ Content Hub';
					await fetchPromise('lms/FP_NoiDung_Save', {
						NoiDungID: 0,
						HocLieuID: this.selectedHocLieu.HocLieuID,
						ParentID: parentId,
						TenNoiDung: typeof questionText === 'string' ? questionText.replace(/<[^>]*>/g, '').trim().slice(0, 200) || 'Câu hỏi từ Content Hub' : 'Câu hỏi từ Content Hub',
						LoaiNoiDung: normalized.type || 'QUIZ_SINGLE_CHOICE',
						NguonTaiNguyenCode: 'CONTENT_HUB',
						ThuTu: siblingCount + 1,
						User: this.vueData.user?.UserID,
						DataJson: JSON.stringify({
							...normalized.data,
							origin: 'CONTENT_HUB',
							sourceTracking: question.sourceTracking || {},
							contentHubQuestionId: question.id || null,
							originalType: normalized.originalType
						})
					}, { cache: false });
					await this.fetchTreeNoiDung();
					this.notify('Đã import câu hỏi từ Content Hub.');
				} catch (error) {
					this.notify(error?.message || 'Import câu hỏi thất bại.', 'error');
				}
			},

			getImportedContentType(document) {
				// Một số bản ghi Content Hub có contentType là HTML nhưng sourceTracking vẫn xác nhận video tương tác.
				const sourceKind = String(document?.sourceTracking?.sourceKind || '').toUpperCase();
				const mediaType = String(document?.mediaType || '').toLowerCase();
				// Video tương tác vẫn là node VIDEO; interactions chỉ là metadata để mở player và chỉnh các mốc câu hỏi.
				if (document?.interactive === true || sourceKind === 'INTERACTIVE_VIDEO') return 'VIDEO';
				if (mediaType === 'audio') return 'AUDIO';
				if (mediaType === 'image' || mediaType === 'hình ảnh') return 'IMAGE';
				const type = `${document?.contentType || ''} ${document?.mediaType || ''} ${document?.url || ''} ${document?.audioUrl || ''} ${document?.source || ''}`.toLowerCase();
				if (/video|youtube|\.mp4|\.webm|\.mov/.test(type)) return 'VIDEO';
				if (/audio/.test(type)) return 'AUDIO';
				if (/image|\.png|\.jpe?g|\.gif|\.webp|\.svg/.test(type)) return 'IMAGE';
				// iSpring có URL kết thúc bằng index.html nên phải map trước HTML thường.
				if (document?.iSpringURL || /ispring|application\/x-ispring/.test(type)) return 'ISPRING_CONTENT';
				if (/html/.test(type)) return 'HTML';
				return 'TAILIEU';
			},
			normalizeImportedInteractiveMarkers(markers) {
					const supportedTypes = ['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_TRUE_FALSE',
						'QUIZ_MATCHING', 'QUIZ_ORDERING', 'QUIZ_DRAG_DROP_CATEGORIZE', 'QUIZ_FILL_IN_BLANK',
						'QUIZ_CONNECTION', 'SHORT_ANSWER', 'ESSAY'];
				return (Array.isArray(markers) ? markers : []).map(marker => {
					const questions = Array.isArray(marker?.questions) ? marker.questions : (marker?.question ? [marker.question] : []);
					return {
						...marker,
						questions: questions.map(question => {
							const type = String(question?.type || '').toUpperCase();
							const isSupported = supportedTypes.includes(type);
							return {
								...question,
								// Giữ câu không hỗ trợ trong metadata để truy vết, nhưng không kích hoạt trong học liệu.
								isActive: isSupported && question?.isActive !== false,
								...(isSupported ? {} : { inactiveReason: 'UNSUPPORTED_QUESTION_TYPE' })
							};
						})
					};
				});
			},

			parseNodeDataJson(node) {
				if (!node?.DataJson) return {};
				if (typeof node.DataJson === 'object') return node.DataJson;
				try {
					return JSON.parse(node.DataJson) || {};
				} catch (error) {
					throw new Error(`Dữ liệu tài nguyên của mục "${node.TenNoiDung || node.NoiDungID}" không hợp lệ.`);
				}
			},
			flattenNodeTree(nodes, result = []) {
				if (!Array.isArray(nodes)) return result;
				nodes.forEach(node => {
					if (!node) return;
					result.push(node);
					this.flattenNodeTree(node.children, result);
				});
				return result;
			},
			getYoutubeVideoId(url) {
				if (!url || typeof url !== 'string') return null;
				try {
					const parsed = new URL(url);
					if (parsed.hostname.includes('youtube.com')) {
						return parsed.searchParams.get('v')
							|| parsed.pathname.split('/embed/')[1]?.split('/')[0]
							|| parsed.pathname.split('/shorts/')[1]?.split('/')[0]
							|| null;
					}
					if (parsed.hostname.includes('youtu.be')) return parsed.pathname.slice(1).split('/')[0] || null;
				} catch (error) {}
				return null;
			},
			getGoogleDriveFileId(url) {
				if (!url || typeof url !== 'string') return null;
				const match = url.match(/\/d\/([^/]+)/);
				return match?.[1] || null;
			},
			isSharedLinkedNodeData(data) {
				const sourceType = String(data?.sourceTracking?.sourceType || '').toUpperCase();
				// Node import chỉ là liên kết tới kho dùng chung, không được dọn tài nguyên gốc khi xóa node.
				return sourceType === 'CONTENT_HUB' || sourceType === 'HOC_LIEU_SO';
			},
			getNodeExternalResources(node) {
				const data = this.parseNodeDataJson(node);
				const source = String(data.uploadSource || '').toLowerCase();
				const url = typeof data.url === 'string' ? data.url : '';
				const resources = [];
				if (this.isSharedLinkedNodeData(data)) return resources;

				// Video chỉ được lưu trên YouTube; phải xóa video YouTube trước khi xóa node.
				const videoId = data.videoId || this.getYoutubeVideoId(url);
				if (source === 'youtube' || videoId || /youtube\.com|youtu\.be/i.test(url)) {
					if (!videoId) throw new Error(`Không tìm thấy videoId YouTube của mục "${node.TenNoiDung || node.NoiDungID}".`);
					resources.push({ type: 'youtube', id: videoId, key: `youtube:${videoId}` });
				}

				// Canva chỉ là liên kết embed; driveFileId của Canva là design id, không phải file Google Drive.
				const driveId = data.driveFileId || this.getGoogleDriveFileId(url);
				if (source !== 'canva' && (source === 'ggdrive' || driveId || /drive\.google\.com|docs\.google\.com/i.test(url))) {
					if (!driveId) throw new Error(`Không tìm thấy Google Drive file id của mục "${node.TenNoiDung || node.NoiDungID}".`);
					resources.push({ type: 'google-drive', id: driveId, key: `google-drive:${driveId}` });
				}

				// iSpring được phát hành thành một thư mục riêng trên GitHub Pages; xóa cả thư mục
				// theo GUID để không để lại toàn bộ bộ tài liệu tĩnh sau khi xóa node.
				if (data.iSpringGUID) {
					const iSpringGuid = String(data.iSpringGUID);
					resources.push({ type: 'github-ispring', id: iSpringGuid, key: `github-ispring:${iSpringGuid}` });
				} else if (data.iSpringURL) {
					throw new Error(`Không tìm thấy iSpringGUID của mục "${node.TenNoiDung || node.NoiDungID}".`);
				}

				// File archive trong LMS (nếu có metadata fileId) cũng được dọn cùng node.
				const lmsFileIds = [data.fileId, data.archiveFileId].filter(Boolean);
				lmsFileIds.forEach(fileId => resources.push({ type: 'lms-file', id: fileId, key: `lms-file:${fileId}` }));
				return resources;
			},
			getExternalResourcesForNodes(nodes) {
				const resourceMap = new Map();
				this.flattenNodeTree(nodes).forEach(node => {
					this.getNodeExternalResources(node).forEach(resource => resourceMap.set(resource.key, resource));
				});
				return [...resourceMap.values()];
			},
			isResourceUsedOutsideNodes(resource, deletingNodeIds) {
				return this.flattenNodeTree(this.treeNoiDung).some(node => {
					if (!node?.NoiDungID || deletingNodeIds.has(String(node.NoiDungID))) return false;
					return this.getNodeExternalResources(node).some(item => item.key === resource.key);
				});
			},
			async deleteExternalResource(resource) {
				if (resource.type === 'lms-file') {
					if (!window.UploadManager?.deleteLmsFile) throw new Error('UploadManager chưa hỗ trợ xóa file LMS.');
					const result = await window.UploadManager.deleteLmsFile(resource.id);
					if (result === false) throw new Error(`Không thể xóa file LMS ${resource.id}.`);
					return;
				}
				if (resource.type === 'github-ispring') {
					const config = await fetchPromise('lms/FP_Github_Config_Get');
					const { token, owner, repo, branch } = config || {};
					if (!token || !owner || !repo || !branch) throw new Error('Thiếu cấu hình GitHub để xóa iSpring content.');
					await this.deleteGithubResource(`content/${resource.id}`, { token, owner, repo, branch });
					return;
				}

				const tokenResult = await fetchPromise('lms/FP_Youtube_Token_Get');
				const accessToken = tokenResult?.access_token;
				if (!accessToken) throw new Error('Không lấy được quyền truy cập tài nguyên bên thứ ba.');

				const endpoint = resource.type === 'youtube'
					? `https://www.googleapis.com/youtube/v3/videos?id=${encodeURIComponent(resource.id)}`
					: `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(resource.id)}`;
				const response = await fetch(endpoint, {
					method: 'DELETE',
					headers: { Authorization: `Bearer ${accessToken}` }
				});
				if (!response.ok && response.status !== 404) {
					throw new Error(`Không thể xóa tài nguyên ${resource.id} bên thứ ba: ${response.statusText}.`);
				}
			},
			async deleteGithubResource(path, config) {
				const encodedPath = path.split('/').map(part => encodeURIComponent(part)).join('/');
				const endpoint = `https://api.github.com/repos/${config.owner}/${config.repo}/contents/${encodedPath}?ref=${encodeURIComponent(config.branch)}`;
				const response = await fetch(endpoint, {
					headers: {
						Authorization: `token ${config.token}`,
						Accept: 'application/vnd.github.v3+json'
					}
				});
				if (response.status === 404) return;
				if (!response.ok) {
					const errorBody = await response.json().catch(() => ({}));
					throw new Error(errorBody.message || `Không thể đọc iSpring content: ${response.status}.`);
				}

				const content = await response.json();
				const items = Array.isArray(content) ? content : [content];
				for (const item of items) {
					if (item.type === 'dir') {
						await this.deleteGithubResource(item.path, config);
						continue;
					}
					const deleteResponse = await fetch(`https://api.github.com/repos/${config.owner}/${config.repo}/contents/${item.path.split('/').map(part => encodeURIComponent(part)).join('/')}`, {
						method: 'DELETE',
						headers: {
							Authorization: `token ${config.token}`,
							Accept: 'application/vnd.github.v3+json',
							'Content-Type': 'application/json'
						},
						body: JSON.stringify({ message: `Delete ${item.path}`, sha: item.sha, branch: config.branch })
					});
					if (!deleteResponse.ok && deleteResponse.status !== 404) {
						const errorBody = await deleteResponse.json().catch(() => ({}));
						throw new Error(errorBody.message || `Không thể xóa iSpring file: ${item.path}.`);
					}
				}
			},
			async cleanupExternalResources(nodes) {
				const nodesToDelete = this.flattenNodeTree(nodes);
				const deletingNodeIds = new Set(nodesToDelete.map(node => String(node.NoiDungID)).filter(Boolean));
				const resources = this.getExternalResourcesForNodes(nodesToDelete);
				let skippedSharedCount = 0;
				for (const resource of resources) {
					if (this.isResourceUsedOutsideNodes(resource, deletingNodeIds)) {
						skippedSharedCount++;
						continue;
					}
					await this.deleteExternalResource(resource);
				}
				return { resourceCount: resources.length, skippedSharedCount };
			},
			// Xóa tài nguyên bên ngoài thành công trước, sau đó mới xóa node trong DB.
			async deleteNodesAfterExternalCleanup(nodes) {
				const nodesToDelete = this.flattenNodeTree(nodes);
				await this.cleanupExternalResources(nodesToDelete);
				const rootIds = [...new Set(nodes.map(node => node?.NoiDungID).filter(Boolean))];
				for (const id of rootIds) {
					await fetchPromise('lms/FP_NoiDung_Delete', { NoiDungID: Number(id) }, { cache: false });
				}
			},
			// HÀM MỚI: Xử lý sự kiện delete từ cây
			async onDeleteNode(node) {
				const ok = await this.confirmRef.value.show({
					title: `Bạn có chắc chắn muốn xóa mục "${node.TenNoiDung}" và tất cả các mục con của nó?`
				});
				if (!ok) return;
				this.isLoadingTree = true;
				try {
					await this.deleteNodesAfterExternalCleanup([node]);
					this.notify("Đã xóa tài nguyên liên quan và nội dung thành công!");
					await this.fetchTreeNoiDung();
				} catch (error) {
					console.error('Không thể dọn tài nguyên trước khi xóa node:', error);
					this.notify(`Chưa xóa nội dung vì không dọn được tài nguyên liên quan: ${error.message}`, 'error');
				} finally {
					this.isLoadingTree = false;
				}
			},
		onToggleSelectNode({ node, isChecked }) {
			const newSelected = { ...(this.selectedNodeIds || {}) };
			const updateRecursive = (item, checked) => {
				if (item && item.NoiDungID) {
					if (checked) {
						newSelected[item.NoiDungID] = true;
					} else {
						delete newSelected[item.NoiDungID];
					}
				}
				if (item && item.children && Array.isArray(item.children)) {
					item.children.forEach(child => updateRecursive(child, checked));
				}
			};
			updateRecursive(node, isChecked);
			this.selectedNodeIds = newSelected;
		},
		async deleteSelectedNodes() {
			const selectedIds = Object.keys(this.selectedNodeIds || {}).filter(id => this.selectedNodeIds[id]);
			if (selectedIds.length === 0) {
				this.notify("Vui lòng chọn ít nhất một mục để xóa!", "warning");
				return;
			}
			const ok = await this.confirmRef.value.show({
				title: `Bạn có chắc chắn muốn xóa ${selectedIds.length} mục đã chọn (bao gồm tất cả các mục con)?`
			});
			if (!ok) return;
			this.isLoadingTree = true;
			try {
				const selectedSet = new Set(selectedIds.map(id => String(id)));
				const allNodes = this.flattenNodeTree(this.treeNoiDung);
				const nodeMap = new Map(allNodes.map(node => [String(node.NoiDungID), node]));
				const rootNodes = allNodes.filter(node => selectedSet.has(String(node.NoiDungID)) && !this.hasSelectedAncestor(node, nodeMap, selectedSet));
				await this.deleteNodesAfterExternalCleanup(rootNodes);
				this.selectedNodeIds = {};
				this.notify(`Đã dọn tài nguyên và xóa thành công ${rootNodes.length} mục!`);
				await this.fetchTreeNoiDung();
			} catch (e) {
				console.error(e);
				this.notify(`Chưa xóa nội dung vì không dọn được tài nguyên liên quan: ${e.message}`, "error");
			} finally {
				this.isLoadingTree = false;
			}
		},
		hasSelectedAncestor(node, nodeMap, selectedSet) {
			let parentId = node?.ParentID;
			while (parentId !== null && parentId !== undefined && String(parentId) !== '0') {
				if (selectedSet.has(String(parentId))) return true;
				parentId = nodeMap.get(String(parentId))?.ParentID;
			}
			return false;
		},
		async deleteAllNodes() {
			if (!this.selectedHocLieu || !this.treeNoiDung || this.treeNoiDung.length === 0) return;
			const ok = await this.confirmRef.value.show({
				title: `Bạn có chắc chắn muốn xóa toàn bộ cấu trúc nội dung của "${this.selectedHocLieu.TenHocLieu || 'học liệu'}"?`
			});
			if (!ok) return;
			this.isLoadingTree = true;
			try {
				await this.deleteNodesAfterExternalCleanup(this.treeNoiDung);
				this.selectedNodeIds = {};
				this.notify("Đã xóa toàn bộ nội dung thành công!");
				await this.fetchTreeNoiDung();
			} catch (e) {
				console.error(e);
				this.notify("Xóa thất bại!", "error");
			} finally {
				this.isLoadingTree = false;
			}
		},
		buildTree(flatList) {
			if (!flatList || flatList.length === 0) { this.treeNoiDung = []; return; }
			const nodeMap = {};
			const roots = [];
			flatList.forEach(item => {
				let parsedData = {};
				if (item.DataJson) {
					if (typeof item.DataJson === 'object') parsedData = item.DataJson;
					else {
						try { parsedData = JSON.parse(item.DataJson) || {}; } catch(e) {}
					}
				}
				const isTeacherOnly = Boolean(item.IsTeacherOnly || parsedData.isTeacherOnly || parsedData.IsTeacherOnly || parsedData.chiGiaoVien || parsedData.ChiGiaoVien);
				nodeMap[item.NoiDungID] = { ...item, IsTeacherOnly: isTeacherOnly, children: [] };
			});
			Object.values(nodeMap).forEach(node => {
				if (node.ParentID && nodeMap[node.ParentID]) {
					nodeMap[node.ParentID].children.push(node);
				} else { roots.push(node); }
			});
			const sortNodes = (nodes) => {
				if (!nodes) return;
				nodes.sort((a, b) => (a.ThuTu || 0) - (b.ThuTu || 0));
				nodes.forEach(node => { if (node.children.length > 0) sortNodes(node.children); });
			};
			sortNodes(roots);
			this.treeNoiDung = roots;
		},

		// Chuyển đổi quyền xem của node: Chỉ giáo viên xem (ẩn với học sinh) hoặc Hiển thị cho tất cả
		async onToggleTeacherOnly(node) {
			if (!node || !this.selectedHocLieu) return;
			let currentDataJson = {};
			if (node.DataJson) {
				if (typeof node.DataJson === 'object') {
					currentDataJson = { ...node.DataJson };
				} else {
					try {
						currentDataJson = JSON.parse(node.DataJson) || {};
					} catch (e) {
						currentDataJson = {};
					}
				}
			}
			const currentTeacherOnly = Boolean(node.IsTeacherOnly || currentDataJson.isTeacherOnly || currentDataJson.IsTeacherOnly || currentDataJson.chiGiaoVien || currentDataJson.ChiGiaoVien);
			const newTeacherOnly = !currentTeacherOnly;
			currentDataJson.isTeacherOnly = newTeacherOnly;
			node.IsTeacherOnly = newTeacherOnly;
			node.DataJson = JSON.stringify(currentDataJson);

			try {
				const payload = {
					NoiDungID: node.NoiDungID,
					HocLieuID: this.selectedHocLieu.HocLieuID,
					ParentID: node.ParentID || 0,
					TenNoiDung: node.TenNoiDung,
					LoaiNoiDung: node.LoaiNoiDung,
					ThuTu: node.ThuTu,
					DataJson: node.DataJson
				};
				await fetchPromise('lms/FP_NoiDung_Save', payload, { cache: false });
				this.notify(newTeacherOnly ? 'Đã bật: Chỉ giáo viên xem (Ẩn với học sinh)' : 'Đã tắt: Hiển thị cho cả giáo viên và học sinh', 'success');
				this.treeKey += 1;
			} catch (err) {
				console.error('Lỗi khi cập nhật quyền xem của node:', err);
				this.notify('Cập nhật quyền xem thất bại!', 'error');
				node.IsTeacherOnly = currentTeacherOnly;
				currentDataJson.isTeacherOnly = currentTeacherOnly;
				node.DataJson = JSON.stringify(currentDataJson);
			}
		},
		addNewRootNode() {
			console.log("Thêm mục gốc mới...");
			this.onOpenDialog();
		},
			async onTreeUpdate(newTree) {
			console.log("Cấu trúc cây mới:", newTree);
			this.treeNoiDung = newTree; // Fix: sử dụng newTree thay vì newNodes

			const dataToUpdate = [];
			const flatten = (nodes, parentId) => {
				nodes.forEach((node, index) => {
					dataToUpdate.push({
						id: node.NoiDungID,
						order: index,
						parent: parentId
					});
					if (node.children && node.children.length > 0) {
						flatten(node.children, node.NoiDungID);
					}
				});
			};
			flatten(newTree, null);

			console.log("Dữ liệu gửi lên API UpdateTreeStructure:", JSON.stringify(dataToUpdate));
				await fetchPromise('lms/FP_NoiDung_UpdateTreeStructure', { JsonData: JSON.stringify(dataToUpdate) }, { cache: false });
				console.log("Cập nhật thành công!");
		},
		getTreeStats() {
			const countNodes = (nodes) => nodes.reduce((count, node) => count + 1 + (node.children ? countNodes(node.children) : 0), 0);
			return countNodes(this.treeNoiDung);
		},
		scrollToSidebar() {
			const filterPanel = document.querySelector('.filter-panel');
			if (filterPanel) filterPanel.scrollIntoView({ behavior: 'smooth' });
			const firstEmpty = this.selectedBoSach == null ? 'bookSelect'
				: this.selectedKhoi == null ? 'gradeSelect'
					: this.selectedMon == null ? 'subjectSelect' : 'bookSelect';
			this.$nextTick(() => {
				const select = this.$refs[firstEmpty];
				if (!select) return;
				if (typeof select.focus === 'function') {
					select.focus();
				} else {
					select.$el?.querySelector('input')?.focus();
				}
				if ('menu' in select) select.menu = true;
				if ('isMenuActive' in select) select.isMenuActive = true;
				select.$el?.querySelector('.v-field__input, input')?.click();
			});
		},
		toggleExpandCollapse() {
			if (this.isAllCollapsed) {
				this.expandAll();
			} else {
				this.collapseAll();
			}
		},
		collapseAll() {
			const collapsed = {};
			const markNodesWithChildren = (nodes) => {
				nodes.forEach(node => {
					if (node.children && node.children.length > 0) {
						collapsed[node.NoiDungID] = true;
						markNodesWithChildren(node.children);
					}
				});
			};
			markNodesWithChildren(this.treeNoiDung);
			this.collapsedNodeIds = collapsed;
		},
		expandAll() {
			this.collapsedNodeIds = {};
		},
		addNewChildNode(node) {
			console.log("Thêm node con cho:", node);
			this.onOpenDialog(node);
		},
		editNode(node) {
			console.log("Chỉnh sửa node:", node);
			this.onOpenDialog(node);
		},
		deleteNode(node) {
			console.log("Xóa node:", node);
			this.onOpenDialog(node);
		}

	}
	}
</script>