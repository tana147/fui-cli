<template>
	<div class="menu-viewer-app">
		<!-- RESPONSIVE HEADER BAR -->
		<div class="header-bar glass" v-if="isMobileTablet">
			<a class="logo" href="https://zentea.vn" rel="noopener noreferrer">
				<img src="/_cdn/zen-eorder/logo-2025-white.png" alt="Logo" class="logo-image">
				<span>ZEN Menu Viewer</span>
			</a>

			<div class="header-actions">
				<button class="header-btn" :class="{ active: showLeftPanel }" @click="togglePanel('left')"
					title="Danh sách trang">
					<i class="mdi mdi-format-list-bulleted"></i>
				</button>

				<button class="header-btn" :class="{ active: showRightPanel }" @click="togglePanel('right')"
					title="Danh sách menu">
					<i class="mdi mdi-book-open-page-variant"></i>
				</button>

			</div>
		</div>

		<!-- SEARCH RESULTS -->
		<div class="search-results glass" v-if="showSearchResults" ref="searchResults">
			<div v-for="result in searchResults" :key="result.id" class="search-result-item"
				@click.stop="goToPageFromSearch(result.page)" @touchend.stop>
				<div class="search-result-icon">{{ result.icon }}</div>
				<div class="search-result-content">
					<div class="search-result-title">{{ result.title }}</div>
					<div class="search-result-desc">Trang {{ result.page }} • {{ result.price }}</div>
				</div>
			</div>
		</div>

		<div class="menu-viewer">
			<!-- LEFT PANEL - ENHANCED THUMBNAILS -->
			<div class="left-panel glass" :class="{ 
				collapsed: leftPanelCollapsed, 
				show: showLeftPanel,
				'mobile-panel': isMobileTablet 
			}">
				<div class="panel-header">
					<div class="panel-title" v-if="!leftPanelCollapsed">
						<i class="mdi mdi-format-list-bulleted"></i>
						<span>Danh sách trang</span>
					</div>
					<button class="collapse-btn" @click="toggleLeftPanel" v-if="!isMobileTablet"
						:title="leftPanelCollapsed ? 'Mở rộng' : 'Thu gọn'">
						<i :class="leftPanelCollapsed ? 'mdi mdi-chevron-right' : 'mdi mdi-chevron-left'"></i>
					</button>
				</div>

				<div class="panel-content" v-if="isLeftPanelOpen && leftPanelLoadedOnce">
					<div class="page-stats">
						<div class="stat-item">
							<div class="stat-value">{{ totalPages }}</div>
							<div class="stat-label">Trang</div>
						</div>
					</div>

					<div class="page-thumbnails-container">
						<div class="page-thumbnails">
							<div v-for="(page, index) in filteredPages" :key="'page_' + index"
								class="page-thumbnail enhanced" :class="{ active: currentPage === index + 1 }"
								@click.stop="leftPanelGoTo(index + 1)" @touchend.stop>

								<!-- THAY THẾ TOÀN BỘ KHỐI DIV NÀY -->
								<div class="thumbnail-preview enhanced-preview">
									<div class="thumbnail-scaler-wrapper" :style="getThumbnailOuterStyle(page)">
										<!-- Lớp giống .page-scale ở main-content -->
										<div class="elements-overlay-improved" :style="getThumbnailInnerStyle(page)">
											<template v-for="el in page.elements">

												<!-- 1. Image standalone -->
												<div v-if="el.type === 'image-element'" :key="el.id + '-thumb'"
													class="canvas-element-improved" :style="{
														position: 'absolute',
														left: (el.x || 0) + 'px',
														top:  (el.y || 0) + 'px',
														width:  (el.width  || 0) + 'px',
														height: (el.height || 0) + 'px',
														zIndex: el.zIndex || 1
														}">
													<img :src="el.src" :style="{
														...(el.style || {}),
														width: '100%',
														height: '100%',
														objectFit: 'fill',
														objectPosition: 'center center',
														display: 'block',
														transform: 'rotate(' + (el.rotation || 0) + 'deg)'
													}" />
												</div>

												<!-- 2. Group -->
												<div v-else-if="el.type === 'group'" :key="el.id + '-thumb'"
													class="canvas-element-group-improved" :style="{
														position: 'absolute',
														left:  (el.x || 0) + 'px',
														top:   (el.y || 0) + 'px',
														width: (el.width  || 0) + 'px',
														height:(el.height || 0) + 'px'
														}">

													<div v-for="child in el.children" :key="child.id + '-thumb'"
														class="group-child-improved" :style="{
														position: 'absolute',
														left:  (child.relative_x || 0) + 'px',
														top:   (child.relative_y || 0) + 'px',
														zIndex: child.zIndex || 1
													}">

														<!-- 2a. Image con -->
														<img v-if="child.type === 'image-element'" :src="child.src"
															:style="{
																width:  (child.width  || 0) + 'px',
																height: (child.height || 0) + 'px',
																transform: 'rotate(' + (child.rotation || 0) + 'deg)',
																...(child.style || {})
																}" />

														<!-- 2b. Text con -->
														<div v-else-if="child.type === 'text-element'" :style="{
																whiteSpace: 'pre-line',
																display: 'inline-block',
																...(child.style || {})
																}">
															{{ child.content }}
														</div>
													</div>
												</div>

											</template>
										</div>
									</div>
								</div>

								<div class="thumbnail-overlay enhanced-overlay">
									<span class="page-number">{{ index + 1 }}</span>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>

			<!-- MAIN CONTENT - FULL SCREEN PRIORITY -->
			<div class="main-content glass" :class="{ 'full-screen': isMobileTablet, 'with-panels': !isMobileTablet }">
				<div class="page-container" :class="{ zoomed: isZoomed, 'pinch-lock': isPinchZooming }"
					ref="pageContainer">
					<div class="current-page" :style="getCurrentPageStyle()">
						<div class="page-scale" :style="getPageScaleStyle()">
							<div class="elements-overlay-improved" v-if="currentPageWithFilteredElements">
								<template v-for="el in currentPageWithFilteredElements.elements">
									<!-- image -->
									<div v-if="el.type==='image-element'" :key="el.id" class="canvas-element-improved"
										:style="{
													position:'absolute',
													left: el.x + 'px',
													top:  el.y + 'px',
													width:  (el.width  || 0) + 'px',
													height: (el.height || 0) + 'px',
													zIndex: el.zIndex || 1
												}">
										<img :src="el.src" :style="{
													...(el.style || {}),                
													width: '100%',                         
													height: '100%',
													objectFit: 'fill',   
													objectPosition: 'center center',
													display: 'block',
													transform: 'rotate(' + (el.rotation || 0) + 'deg)'
													}" />
									</div>


									<!-- group -->
									<div v-else-if="el.type==='group'" :key="el.id"
										class="canvas-element-group-improved" :style="{position:'absolute',left:el.x+'px',top:el.y+'px',
							                  width:(el.width||0)+'px',height:(el.height||0)+'px'}">
										<div v-for="child in el.children" :key="child.id" class="group-child-improved"
											:style="{position:'absolute',left:(child.relative_x||0)+'px',
							                    top:(child.relative_y||0)+'px',zIndex:child.zIndex||1}">
											<img v-if="child.type==='image-element'" :src="child.src" :style="{width:(child.width||0)+'px',height:(child.height||0)+'px',
							                      transform:'rotate('+(child.rotation||0)+'deg)',...(child.style||{})}" />
											<div v-else-if="child.type==='text-element'"
												:style="{whiteSpace:'pre-line',display:'inline-block',...(child.style||{})}">
												{{ child.content }}
											</div>
										</div>
									</div>
								</template>
							</div>

						</div>
					</div>
				</div>
			</div>

			<!-- RIGHT PANEL - TALLER MENU ITEMS -->
			<div class="right-panel glass" :class="{ 
				collapsed: rightPanelCollapsed, 
				show: showRightPanel,
				'mobile-panel': isMobileTablet 
			}">
				<div class="panel-header">
					<button class="collapse-btn" @click="toggleRightPanel" v-if="!isMobileTablet"
						:title="rightPanelCollapsed ? 'Mở rộng' : 'Thu gọn'">
						<i :class="rightPanelCollapsed ? 'mdi mdi-chevron-left' : 'mdi mdi-chevron-right'"></i>
					</button>
					<div class="panel-title" v-if="!rightPanelCollapsed">
						<a href="https://zentea.vn" rel="noopener noreferrer" style="color: black">
							<i class="mdi mdi-book-open-page-variant" style="color: black"></i>
							<span style="color: black">Danh sách menu</span>
						</a>

					</div>
				</div>

				<div class="panel-content" v-if="isRightPanelOpen && rightPanelLoadedOnce">
					<div class="menu-thumbnails enhanced-menu-list">
						<div v-for="menu in menuData" :key="menu.id" class="menu-thumbnail enhanced-menu-item"
							:class="{ active: currentMenu === menu.id }" @click="switchToMenu(menu.id)">

							<!-- ENHANCED MENU PREVIEW -->
							<div class="menu-thumbnail-preview enhanced-menu-preview"
								:style="getMenuThumbnailStyle(menu)">
								<span class="menu-icon enhanced-icon" v-if="!menu.thumbnail">{{ menu.icon }}</span>
								<div class="menu-overlay" v-if="menu.thumbnail"></div>
							</div>

							<div class="menu-thumbnail-overlay enhanced-menu-overlay">
								<span class="menu-pages-count">{{ menu.pages }} trang</span>
							</div>

							<div class="menu-thumbnail-info enhanced-menu-info">
								<div class="menu-name enhanced-menu-name">{{ menu.name }}</div>
								<div class="menu-description enhanced-menu-desc">{{ menu.description }}</div>
								<div class="menu-stats">
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
		<!-- FLOATING CONTROLS -->
		<div class="floating-controls glass-dark">
			<button class="control-btn" @click="prevByButton" :disabled="currentPage === 1" title="Trang trước">
				<i class="mdi mdi-chevron-left"></i>
			</button>

			<button v-if="showZoomButton" class="control-btn" @click="toggleZoom" title="Phóng to / Thu nhỏ">
				<i :class="isZoomed ? 'mdi mdi-magnify-minus' : 'mdi mdi-magnify-plus'"></i>
			</button>

			<div class="page-indicator">
				<span>{{ currentPage }}</span> / <span>{{ totalPages }}</span>
			</div>

			<button class="control-btn" @click="nextByButton" :disabled="currentPage === totalPages" title="Trang sau">
				<i class="mdi mdi-chevron-right"></i>
			</button>
		</div>

		<!-- OVERLAY FOR MOBILE PANELS -->
		<div class="panel-overlay" v-if="isMobileTablet && (showLeftPanel || showRightPanel)" @click="closeAllPanels">
		</div>
		<!-- Âm thanh lật trang -->
		<audio id="flip-sound" src="/_cdn/zen-eorder/menu-online/turnpage-99756.mp3" preload="auto"></audio>
		<!-- Modal Chọn cửa hàng -->
		<transition name="modal-fade">
			<div class="modal-overlay" v-if="isStoreModalVisible" @click.self="closeStoreModal">
				<div class="modal-content">
					<div class="modal-header">
						<h3 class="modal-title">Chọn Cửa Hàng</h3>
						<button class="close-btn" @click="closeStoreModal" title="Đóng">×</button>
					</div>
					<div class="modal-body">
						<p class="modal-subtitle">Vui lòng chọn một cửa hàng để xem menu:</p>
						<ul class="store-list">
							<li v-for="store in storesForSelectedMenu" :key="store.CuaHangID" class="store-item"
								@click="handleStoreSelection(store.CuaHangID)">
								<i class="mdi mdi-store-outline store-icon"></i>
								<span class="store-name">{{ store.TenCuaHang }}</span>
								<i class="mdi mdi-chevron-right select-icon"></i>
							</li>
						</ul>
					</div>
				</div>
			</div>
		</transition>
	</div>
</template>

<script>
	export default {
		props: {
			dsmenu: { type: Array, required: true },
			dsmon: { type: Array, required: true },
			dscuahang: { type: Array, required: true },
			dsmenubook: { type: Array, default: () => [] }
		},
	
		data() {
			return {
				leftPanelLoadedOnce: false,
				rightPanelLoadedOnce: false,
				thumbVisible: new Set(),
				showZoomButton: window.innerWidth >= 1366,
				lastOrientation: (window.matchMedia('(orientation: portrait)').matches ? 'portrait' : 'landscape'),
				lastReloadTs: 0,
				isPinchZooming: false,
				_pinchResetTimer: null,
				PINCH_RESET_DELAY: 250,
				isViewportZoomed: false,
				ZOOM_UNLOCK_EPS: 0.01,
	
				// 👇 2. THÊM DATA ĐỂ QUẢN LÝ MODAL
				isStoreModalVisible: false,
				storesForSelectedMenu: [],
				selectedMenuBookIdForModal: null,
	
				is_watchdata: false,
				pages: [],
				totalPages: 1,
				currentPage: 1,
				currentMenu: '',
	
				isZoomed: false,
				zoomFactor: 1.2,
	
				// Touch handling
				touchStartY: 0,
				touchStartX: 0,
				touchStartTime: 0,
				isTouchMoving: false,
				minSwipeDistance: 50,
	
				isTransitioning: false,
				isFromNavButton: false,
	
				// RESPONSIVE STATE
				leftPanelCollapsed: false,
				rightPanelCollapsed: false,
				showLeftPanel: false,
				showRightPanel: false,
				isMobileTablet: false,
	
				activeFilter: 'all',
				// bookmarkedPages: new Set(),
	
				showSearchResults: false,
				searchResults: [],
				searchTimeout: null,
	
				menuData: [],
	
				// ENHANCED THUMBNAILS
				pagePreviewReady: {},
				thumbnailSize: { width: 100, height: 140 },
	
				// SOUND CONTROL
				soundEnabled: true,
				flipSound: null,
	
				BREAKPOINTS: {
					MOBILE: 480,
					TABLET: 1024,
					// TABLET: 768,
					DESKTOP: 1024,
					LARGE: 1440
				},
	
				PANEL_SIZES: {
					LEFT_EXPANDED: 280,
					LEFT_COLLAPSED: 60,
					RIGHT_EXPANDED: 300,
					RIGHT_COLLAPSED: 60,
					HEADER_HEIGHT: 60,
					CONTROLS_HEIGHT: 40
				},
	
				// Page dimensions
				pageDimensions: {
					Desktop: { width: 529, height: 707 },
					Tablet: { width: 500, height: 417 },
					Mobile: { width: 214, height: 300 },
					Custom: { width: 500, height: 417 }
				},
				dsmonVersion: 0,
				filteredPageCache: new Map(),
			};
		},
	
		computed: {
			isLeftPanelOpen() {
				return this.isMobileTablet ? this.showLeftPanel : !this.leftPanelCollapsed;
			},
			isRightPanelOpen() {
				return this.isMobileTablet ? this.showRightPanel : !this.rightPanelCollapsed;
			},
			pageBox() {
				const page = this.getCurrentPage();
				return this.getPageSize(page);
			},
	
			// 🔑 HÀM 1: Tạo lookup map cho dsmon
			dsmonLookup() {
	
				// ✅ Kiểm tra dsmon ready
				if (!this.dsmon || !Array.isArray(this.dsmon) || this.dsmon.length === 0) {
					return {};
				}
	
				const lookup = {};
				this.dsmon.forEach(mon => {
					if (mon && mon.SanPhamID) {
						lookup[mon.SanPhamID] = mon;
					}
				});
				return lookup;
			},
	
			// 🔑 HÀM 2: Filter elements cho tất cả pages
			pagesWithFilteredElements() {
				if (!this.pages || this.pages.length === 0) {
					return [];
				}
	
				// ✅ Nếu dsmon chưa ready, trả về pages gốc
				if (!this.dsmon || !Array.isArray(this.dsmon) || this.dsmon.length === 0) {
					return this.pages;
				}
	
				return this.pages.map(page => {
					const filteredPage = JSON.parse(JSON.stringify(page));
	
					if (filteredPage.elements && Array.isArray(filteredPage.elements)) {
						const originalCount = filteredPage.elements.length;
						filteredPage.elements = this.filterElements(filteredPage.elements);
						const filteredCount = filteredPage.elements.length;
	
					}
	
					return filteredPage;
				});
			},
	
	
			// 🔑 HÀM 4: Get current page with filtered elements
			currentPageWithFilteredElements() {
				return this.getFilteredPageByIndex(this.currentPage - 1);
			},
	
			// filteredPages vẫn trả pages raw để list trang / đếm
			filteredPages() {
				let filtered = this.pages || [];
				switch (this.activeFilter) {
					case 'recent': filtered = filtered.slice(-3); break;
					default: break;
				}
				return filtered;
			},
	
			getAvgPrice() {
				return 65;
			},
	
			currentLeftPanelWidth() {
				if (this.isMobileTablet) return 0;
				return this.leftPanelCollapsed ? this.PANEL_SIZES.LEFT_COLLAPSED : this.PANEL_SIZES.LEFT_EXPANDED;
			},
	
			currentRightPanelWidth() {
				if (this.isMobileTablet) return 0;
				return this.rightPanelCollapsed ? this.PANEL_SIZES.RIGHT_COLLAPSED : this.PANEL_SIZES.RIGHT_EXPANDED;
			},
	
			availableContentWidth() {
				if (this.isMobileTablet) {
					const vv = window.visualViewport;
					const vw = vv ? vv.width : window.innerWidth;
					// trừ nhẹ 4px để tránh lỗi làm tròn của Safari
					return vw - 15;
				}
	
				const reservedWidth = this.currentLeftPanelWidth + this.currentRightPanelWidth + 40;
				return Math.max(300, window.innerWidth - reservedWidth);
			},
			availableContentHeight() {
				if (this.isMobileTablet) {
					const el = this.$refs.pageContainer;
					const h = (el && el.clientHeight) ? el.clientHeight : window.innerHeight;
					const header = this.PANEL_SIZES.HEADER_HEIGHT + this.PANEL_SIZES.CONTROLS_HEIGHT + 40;
					return Math.max(400, h - header);
				}
				const reservedHeight = this.PANEL_SIZES.CONTROLS_HEIGHT + 40;
				return Math.max(400, window.innerHeight - reservedHeight);
			},
		},
	
		mounted() {
	
			this._setupVisualViewportWatcher();
			this.setupEventListeners();
			this.setupResponsive();
			this.ensureLoadedPanels();
			this.generatePagePreviews();
			this.initializeSound();
			this.$nextTick(() => {
				const c = this.$refs.pageContainer;
				if (c) c.style.transform = ''; // đảm bảo không còn inline transform
			});
			this.initOrientationReload();
			window.addEventListener('resize', this.updateZoomButtonVisibility);
		},
	
		beforeDestroy() {
			this.teardownOrientationReload && this.teardownOrientationReload();
			this._teardownVisualViewportWatcher && this._teardownVisualViewportWatcher();
			window.removeEventListener('resize', this.updateZoomButtonVisibility);
		},
	
		methods: {
			ensureLoadedPanels() {
				// LEFT
				if (this.isLeftPanelOpen && !this.leftPanelLoadedOnce) {
					this.leftPanelLoadedOnce = true;
					this.$nextTick(() => this.generatePagePreviews());
				}
	
				// RIGHT
				if (this.isRightPanelOpen && !this.rightPanelLoadedOnce) {
					this.rightPanelLoadedOnce = true;
				}
			},
			getFilteredPageByIndex(index) {
				const page = this.pages?.[index];
				if (!page) return null;
	
				if (!this.dsmonLookup || Object.keys(this.dsmonLookup).length === 0) return page;
	
				const pageId = page.__cacheId || (page.__cacheId = `${index}_${page.type || ''}_${page.background || ''}`);
				const key = `${pageId}__v${this.dsmonVersion}`;
	
				if (this.filteredPageCache.has(key)) return this.filteredPageCache.get(key);
	
				const cloned = JSON.parse(JSON.stringify(page));
				if (Array.isArray(cloned.elements)) cloned.elements = this.filterElements(cloned.elements);
	
				this.filteredPageCache.set(key, cloned);
				return cloned;
			},
			/** Box cho thumbnail – giống concept pageBox của main-content */
			getThumbnailBox(page) {
				const pageType = page?.type || page?.TypePage || 'Desktop';
				const baseDimensions = this.pageDimensions[pageType] || this.pageDimensions.Desktop;
	
				// Kích thước khung thumbnail (theo design của bạn)
				const wrapperWidth = 240;
				const wrapperHeight = 140;
	
				// scale để fit vào khung
				const scaleByWidth = wrapperWidth / baseDimensions.width;
				const scaleByHeight = wrapperHeight / baseDimensions.height;
				const scale = Math.min(scaleByWidth, scaleByHeight);
	
				return {
					w: baseDimensions.width * scale, // kích thước thực tế (sau scale) hiển thị trong khung
					h: baseDimensions.height * scale,
					baseW: baseDimensions.width, // kích thước gốc của page (giống main)
					baseH: baseDimensions.height,
					scale
				};
			},
	
			/** style khung ngoài của thumbnail (tương đương .current-page ở main-content) */
			getThumbnailOuterStyle(page) {
				const { w, h } = this.getThumbnailBox(page);
				return {
					position: 'relative',
					width: w + 'px',
					height: h + 'px',
					overflow: 'hidden',
					borderRadius: '8px',
					backgroundColor: '#ffffff'
				};
			},
	
			/** style lớp scale bên trong (tương đương getPageScaleStyle ở main-content) */
			getThumbnailInnerStyle(page) {
				const box = this.getThumbnailBox(page);
				const bg = page?.background || page?.layer?.[0]?.background || null;
	
				return {
					position: 'absolute',
					left: '0px',
					top: '0px',
					width: box.baseW + 'px',
					height: box.baseH + 'px',
					transform: `scale(${Number(box.scale.toFixed(4))})`,
					transformOrigin: 'top left',
	
					backgroundImage: bg ? `url(${bg})` : 'none',
					backgroundColor: bg ? 'transparent' : '#ffffff',
					// dùng đúng baseW/baseH để khớp với overlay elements
					backgroundSize: bg ? `${box.baseW}px ${box.baseH}px` : 'auto',
					backgroundPosition: 'top left',
					backgroundRepeat: 'no-repeat',
	
					pointerEvents: 'none'
				};
			},
			updateZoomButtonVisibility() {
				this.showZoomButton = window.innerWidth >= 1366;
			},
			formatStt(raw) {
				if (raw === null || raw === undefined) return '';
				const s = String(raw).trim();
				// Không đụng vào mã có ký tự chữ
				if (!/^\d+$/.test(s)) return s;
				const n = Number(s);
				if (!Number.isFinite(n)) return s;
				// Một chữ số 0..9 -> thêm 0 phía trước (0 => 00)
				if (n >= 0 && n <= 9) return `0${n}`; //>= 10 thì giữ nguyên (nếu đã là '003' vẫn giữ '003')
				return s;
			},
			nextByButton() {
				this.isFromNavButton = true;
				this.playFlipSound();
				this.goToNext(true); // force = true
			},
			prevByButton() {
				this.isFromNavButton = true;
				this.playFlipSound();
				this.goToPrevious(true); // force = true
			},
			leftPanelGoTo(pageNumber) {
				// Cho phép chọn trang từ panel trái ngay cả khi đang zoom/pinch
				this.isFromNavButton = true; // tránh double sound
				this.playFlipSound();
				this.goToPage(pageNumber, true); // force = true
			},
			isZoomLocked() {
				return this.isPinchZooming || this.isViewportZoomed || this.isZoomed;
			},
	
			_setupVisualViewportWatcher() {
				const vv = window.visualViewport;
				if (!vv) return;
	
				const applyLockClass = (locked) => {
					const pageContainer = this.$refs.pageContainer;
					if (pageContainer) {
						pageContainer.classList.toggle('pinch-lock', locked);
					}
				};
	
				const update = () => {
					// ví dụ: scale 1.000 → coi như 1; >1 + epsilon mới tính là zoom
					const scaled = (vv.scale || 1);
					const locked = scaled > (1 + this.ZOOM_UNLOCK_EPS);
					this.isViewportZoomed = locked;
					// Nếu còn zoom → coi như đang pinch để tái sử dụng logic sẵn có
					this.isPinchZooming = locked ? true : this.isPinchZooming;
					applyLockClass(locked || this.isPinchZooming);
				};
	
				vv.addEventListener('resize', update, { passive: true });
				vv.addEventListener('scroll', update, { passive: true });
	
				// lưu để hủy
				this._vvHandlers = { update };
				this._vv = vv;
	
				// chạy lần đầu
				update();
			},
	
			_teardownVisualViewportWatcher() {
				if (this._vv && this._vvHandlers) {
					this._vv.removeEventListener('resize', this._vvHandlers.update);
					this._vv.removeEventListener('scroll', this._vvHandlers.update);
				}
				this._vv = null;
				this._vvHandlers = null;
			},
			_computePageSizeOnce(page) {
				// VERSION MỚI – KHÔNG CÒN CACHE
				return this.getPageSize(page);
			},
	
			_beginPinch() {
				this.isPinchZooming = true;
				this.isTouchMoving = false; // reset swipe
				this.touchStartTime = 0; // reset swipe
				if (this._pinchResetTimer) clearTimeout(this._pinchResetTimer);
	
				// Khi đang pinch, khóa lật bằng CSS touch-action (nếu muốn)
				const pageContainer = this.$refs.pageContainer;
				if (pageContainer) pageContainer.classList.add('pinch-lock');
			},
	
			_endPinchSoon() {
				if (this._pinchResetTimer) clearTimeout(this._pinchResetTimer);
				this._pinchResetTimer = setTimeout(() => {
					// Nếu visualViewport vẫn > 1 → tiếp tục khóa
					const vv = window.visualViewport;
					const stillZoomed = vv ? (vv.scale || 1) > (1 + this.ZOOM_UNLOCK_EPS) : false;
	
					this.isPinchZooming = stillZoomed ? true : false;
					const pageContainer = this.$refs.pageContainer;
					if (pageContainer) pageContainer.classList.toggle('pinch-lock', this.isPinchZooming || stillZoomed);
				}, this.PINCH_RESET_DELAY);
			},
	
			findStoreMapping(name) {
				return vueData.storeMapping.find(x => x.name === name)
			},
	
			formatPrice(price) {
				if (price === null || price === undefined) {
					return 'Liên hệ'; // Hoặc một giá trị mặc định nào đó
				}
				// Dùng Intl.NumberFormat để định dạng số theo chuẩn Việt Nam và thêm "đ"
				return new Intl.NumberFormat('vi-VN').format(price) + 'đ';
			},
			getImageUrl(fileId) {
				if (!fileId) {
					return null; // Trả về null nếu không có FileID
				}
				// Thay thế bằng cấu trúc URL thực tế của bạn
				return `https://file.zenfoodcourt.vn/eorder/auth/FileData/${fileId}`;
			},
	
	
			// 👇 THAY THẾ HOÀN TOÀN HÀM filterElements HIỆN TẠI
			filterElements(elements) {
				if (!elements || !Array.isArray(elements)) return [];
	
				const lookup = this.dsmonLookup;
				if (Object.keys(lookup).length === 0) {
					return elements; // Nếu chưa có dsmon, giữ nguyên template gốc
				}
	
				return elements.map(element => {
					// Chỉ xử lý các 'group' là món ăn
					if (element.type !== 'group' || !element.id_SanPham || !Array.isArray(element.children)) {
						return element; // Bỏ qua các element trang trí
					}
	
					const monData = lookup[element.id_SanPham];
					if (!monData) {
						return element;
					}
	
					// Tạo một bản sao của element để chỉnh sửa mà không ảnh hưởng đến prop
					const newElement = JSON.parse(JSON.stringify(element));
					// BƯỚC 1: CẬP NHẬT DỮ LIỆU CHO CÁC THÀNH PHẦN CON
					newElement.children.forEach(child => {
						// Cập nhật HÌNH ẢNH CHÍNH của món ăn
						// Giả sử hình ảnh chính không có 'role' hoặc có 'role' là 'main-image'
						if (child.type === 'image-element' && (!child.role || child.role === 'main-image')) {
							const newImageUrl = this.getImageUrl(monData.AnhSanPham_FileID);
							if (newImageUrl) {
								child.src = newImageUrl; // Ghi đè URL ảnh
							}
						}
	
						if (child.type === 'text-element' && (child.role === 'price') && (child.content ? child.content.includes('đ') : true)) { // Tìm element giá dựa vào nội dung
							child.content = this.formatPrice(monData.GiaBan_CuaHang); // Ghi đè giá
						}
	
						if (child.type === 'text-element' && (child.role === 'stt' || child.role === 'serial')) {
							// Ưu tiên lấy từ dsmon; nếu không có thì dùng content hiện tại
							const raw = (monData.MaSoSanPham ?? child.content);
							child.content = this.formatStt(raw);
						}
	
					});
	
	
					//BƯỚC 2: LỌC CÁC ICON TRẠNG THÁI (het-mon, best-seller...)
					newElement.children = newElement.children.filter(child => {
						if (!child.role) {
							return true; // Luôn giữ các element không có role
						}
	
						switch (child.role) {
							case 'het-mon':
								return monData.Is_HetMon === 1 || monData.Is_HetMon === true;
							case 'best-seller':
								return monData.Is_BestSeller === 1 || monData.Is_BestSeller === true;
							case 'signature':
								return monData.Is_Signature === 1 || monData.Is_Signature === true;
							// ... các role khác
							default:
								return true; // Giữ các role không xác định
						}
					});
	
					return newElement;
				});
			},
	
			//  getCurrentPageElements
			getCurrentPageElements() {
				const page = this.currentPageWithFilteredElements;
	
				if (!page) {
					return '<div style="padding: 50px; text-align: center; color: #999;">Không có dữ liệu trang</div>';
				}
	
				if (!page.elements || page.elements.length === 0) {
					return `<div style="padding: 50px; text-align: center; color: #666;">
																																																																																																																																</div>`;
				}
	
				// Render elements
				const renderedElements = page.elements.map((element, index) => {
					return this.renderElement(element, 0, 0);
				}).filter(html => html && html.trim() !== '').join('');
	
				return renderedElements || '<div style="padding: 20px; color: #999;">Không thể render elements</div>';
			},
	
			//Debug method
			debugDsmonFiltering() { },
			//Đếm số món trong từng page
			countMenuItems(page) {
				if (!page || !Array.isArray(page.elements)) {
					return 0;
				}
				const menuItems = page.elements.filter(element =>
					element.type === 'group' && element.id_SanPham
				);
				return menuItems.length;
			},
	
			// ============ SOUND MANAGEMENT ============
			initializeSound() {
				this.flipSound = document.getElementById('flip-sound');
				if (!this.flipSound) {
					return;
				}
	
				this.flipSound.volume = 0.3;
	
				this.flipSound.addEventListener('canplaythrough', () => {
				});
	
				this.flipSound.addEventListener('error', (e) => {
					this.soundEnabled = false;
				});
			},
	
			playFlipSound() {
				if (!this.soundEnabled || !this.flipSound) {
					return;
				}
	
				try {
					this.flipSound.currentTime = 0;
					const playPromise = this.flipSound.play();
	
					if (playPromise !== undefined) {
						playPromise.catch(error => {
							console.warn('🔊 Could not play flip sound:', error);
							this.soundEnabled = false;
						});
					}
				} catch (error) {
					console.warn('🔊 Flip sound error:', error);
				}
			},
	
			toggleSound() {
				this.soundEnabled = !this.soundEnabled;
				this.showNotification(
					this.soundEnabled ? 'Âm thanh đã bật' : 'Âm thanh đã tắt',
					'info'
				);
			},
	
			// ============ EVENT LISTENERS ============
			setupEventListeners() {
				const container = this.$refs.pageContainer;
				if (container) {
					container.addEventListener('wheel', this.handleWheel, { passive: false });
				}
	
				document.addEventListener('keydown', this.handleKeyDown);
				document.addEventListener('click', this.handleClickOutside);
	
				if (this.isMobileTablet) {
					this.setupMobileTouchEvents();
				} else {
					if (container) {
						container.addEventListener('touchstart', this.handleTouchStart, { passive: true });
						container.addEventListener('touchend', this.handleTouchEnd, { passive: true });
					}
				}
			},
	
			setupMobileTouchEvents() {
				this.$nextTick(() => {
					const mainContent = document.querySelector('.main-content');
					const pageContainer = this.$refs.pageContainer;
	
	
					if (mainContent) {
						mainContent.addEventListener('touchstart', this.handleMobileTouchStart, { passive: true });
						mainContent.addEventListener('touchmove', this.handleMobileTouchMove, { passive: false });
						mainContent.addEventListener('touchend', this.handleMobileTouchEnd, { passive: true });
					}
	
					if (pageContainer) {
	
						pageContainer.addEventListener('touchstart', this.handleMobileTouchStart, { passive: true });
						pageContainer.addEventListener('touchmove', this.handleMobileTouchMove, { passive: false });
						pageContainer.addEventListener('touchend', this.handleMobileTouchEnd, { passive: true });
					}
	
					const appContainer = document.querySelector('.menu-viewer-app');
					if (appContainer) {
						appContainer.addEventListener('touchstart', this.handleMobileTouchStart, { passive: true });
						appContainer.addEventListener('touchmove', this.handleMobileTouchMove, { passive: false });
						appContainer.addEventListener('touchend', this.handleMobileTouchEnd, { passive: true });
					}
				});
			},
	
			removeEventListeners() {
				const container = this.$refs.pageContainer;
				if (container) {
					container.removeEventListener('wheel', this.handleWheel);
					container.removeEventListener('touchstart', this.handleTouchStart);
					container.removeEventListener('touchend', this.handleTouchEnd);
					container.removeEventListener('touchstart', this.handleMobileTouchStart);
					container.removeEventListener('touchmove', this.handleMobileTouchMove);
					container.removeEventListener('touchend', this.handleMobileTouchEnd);
				}
	
				const mainContent = document.querySelector('.main-content');
				if (mainContent) {
					mainContent.removeEventListener('touchstart', this.handleMobileTouchStart);
					mainContent.removeEventListener('touchmove', this.handleMobileTouchMove);
					mainContent.removeEventListener('touchend', this.handleMobileTouchEnd);
				}
	
				const appContainer = document.querySelector('.menu-viewer-app');
				if (appContainer) {
					appContainer.removeEventListener('touchstart', this.handleMobileTouchStart);
					appContainer.removeEventListener('touchmove', this.handleMobileTouchMove);
					appContainer.removeEventListener('touchend', this.handleMobileTouchEnd);
				}
	
				document.removeEventListener('keydown', this.handleKeyDown);
				document.removeEventListener('click', this.handleClickOutside);
	
				if (this.resizeTimeout) {
					clearTimeout(this.resizeTimeout);
				}
			},
	
			// ============ MOBILE TOUCH HANDLERS ============
			handleMobileTouchStart(event) {
				if (this.showLeftPanel || this.showRightPanel) return;
				if (this.isZoomLocked()) return;
	
				// 👉 Nếu đặt 2 ngón trở lên: đang pinch
				if (event.touches && event.touches.length > 1) {
					this._beginPinch();
					return; // đừng ghi nhận swipe
				}
	
				if (event.touches.length !== 1 || this.isPinchZooming) return;
	
				this.touchStartY = event.touches[0].clientY;
				this.touchStartX = event.touches[0].clientX;
				this.touchStartTime = Date.now();
				this.isTouchMoving = false;
			},
	
			handleMobileTouchMove(event) {
				if (this.isZoomLocked()) return;
				if (this.isPinchZooming) return;
	
				if (!this.touchStartTime) return;
				if (this.isTouchMoving) {
					const dx = Math.abs(event.touches[0].clientX - this.touchStartX);
					const dy = Math.abs(event.touches[0].clientY - this.touchStartY);
					if (dx > dy && dx > 10) event.preventDefault();
				}
				this.isTouchMoving = true;
			},
	
			handleMobileTouchEnd(event) {
				if (this.isZoomLocked()) {
					this._endPinchSoon();
					return;
				}
				if (this.isPinchZooming) { this._endPinchSoon(); return; }
	
				if (this.showLeftPanel || this.showRightPanel) return;
				if (!this.touchStartTime) return;
	
				const touchEndY = event.changedTouches[0].clientY;
				const touchEndX = event.changedTouches[0].clientX;
				const deltaY = this.touchStartY - touchEndY;
				const deltaX = this.touchStartX - touchEndX;
				const minSwipeDistance = 30;
	
				if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > minSwipeDistance) {
					deltaX > 0 ? this.goToNext() : this.goToPrevious();
				} else if (Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > minSwipeDistance) {
					deltaY > 0 ? this.goToNext() : this.goToPrevious();
				}
				this.touchStartTime = 0;
			},
	
			// ============ DESKTOP TOUCH HANDLERS ============
			handleTouchStart(event) {
				if (this.isZoomLocked()) return;
				// 👉 Nếu có từ 2 ngón trở lên thì coi là pinch-zoom, khóa lật trang
				if (event.touches?.length > 1) {
					this._beginPinch();
					return; // không ghi nhận tọa độ để swipe
				}
	
				// Bình thường: ghi nhận điểm bắt đầu để tính swipe
				this.touchStartY = event.touches[0].clientY;
				this.touchStartX = event.touches[0].clientX;
			},
	
			handleTouchEnd(event) {
				if (this.isZoomLocked()) { // ⬅️ THÊM
					this._endPinchSoon();
					return;
				}
				// 👉 Nếu đang/ vừa pinch: bật hẹn giờ mở khóa và bỏ qua lật trang
				if (this.isPinchZooming) {
					this._endPinchSoon();
					return;
				}
	
				if (this.isTransitioning) return;
	
				const touchEndY = event.changedTouches[0].clientY;
				const touchEndX = event.changedTouches[0].clientX;
	
				const deltaY = this.touchStartY - touchEndY;
				const deltaX = this.touchStartX - touchEndX;
	
				if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > this.minSwipeDistance) {
					if (deltaX > 0) {
						this.goToNext();
					} else {
						this.goToPrevious();
					}
				}
			},
	
			// ============ RESPONSIVE SETUP ============
			setupResponsive() {
				let resizeTimeout;
	
				const updateLayout = () => {
					const width = window.innerWidth;
					const height = window.innerHeight;
					const oldIsMobileTablet = this.isMobileTablet;
	
					// ✅ Xác định loại thiết bị
					const isTabletLandscape =
						width >= 1024 && width <= 1366 && height <= 1024 && width > height;
	
					const isTablet =
						(Math.max(width, height) >= this.BREAKPOINTS.TABLET &&
							Math.max(width, height) < this.BREAKPOINTS.DESKTOP) || (Math.min(width, height) >= this.BREAKPOINTS.TABLET &&
								Math.max(width, height) < 1200); this.isMobileTablet = width < this.BREAKPOINTS.DESKTOP || isTablet ||
									isTabletLandscape; // ✅ Thiết lập lại listeners sau khi thay đổi layout this.removeEventListeners();
					this.$nextTick(() => {
						this.setupEventListeners();
					});
	
					// ✅ Tự động ẩn panel khi màn hình nhỏ
					if (width <= this.BREAKPOINTS.MOBILE) { this.leftPanelCollapsed = true; this.rightPanelCollapsed = true; } else
						if (this.isMobileTablet) {
							if (isTabletLandscape) {
								this.showLeftPanel = false; this.showRightPanel = false;
							}
						} else { this.showLeftPanel = false; this.showRightPanel = false; }
					requestAnimationFrame(() => {
						this.$nextTick(() => {
							this.$forceUpdate();
							// (tuỳ chọn) nếu cần thì:
							// this.generatePagePreviews();
							this.ensureLoadedPanels();
						});
					});
	
				};
	
				// ✅ Debounce resize để tránh gọi liên tục
				const debouncedUpdate = () => {
					clearTimeout(resizeTimeout);
					resizeTimeout = setTimeout(updateLayout, 150);
				};
	
				// ✅ Lắng nghe sự kiện resize & xoay
				window.addEventListener("resize", debouncedUpdate);
	
				// ✅ Lưu timeout và chạy lần đầu
				this.resizeTimeout = resizeTimeout;
				updateLayout();
			},
	
			initOrientationReload() {
				// Lưu orientation hiện tại lúc mounted
				this.lastOrientation = window.innerWidth > window.innerHeight ? 'landscape' : 'portrait';
	
				const handleOrientationChange = () => {
					const newOri = window.innerWidth > window.innerHeight ? 'landscape' : 'portrait';
					this._maybeReloadOnOrientation(newOri);
				};
	
				// Lưu reference để remove sau này
				this._onOrientationChange = handleOrientationChange;
	
				// Một số browser bắn cả orientationchange lẫn resize → nghe cả 2 nhưng cùng chui qua _maybeReloadOnOrientation
				window.addEventListener('orientationchange', handleOrientationChange, { passive: true });
				window.addEventListener('resize', handleOrientationChange, { passive: true });
	
				// Hàm teardown
				this.teardownOrientationReload = () => {
					window.removeEventListener('orientationchange', handleOrientationChange);
					window.removeEventListener('resize', handleOrientationChange);
				};
			},
	
			_maybeReloadOnOrientation(newOri) {
				if (!newOri || newOri === this.lastOrientation) return;
				if (this.isPinchZooming) return;
	
				const now = Date.now();
				if (now - (this.lastReloadTs || 0) < 1000) return; this.lastOrientation = newOri; this.lastReloadTs = now; clearTimeout(this._orientationReloadTimer);
				this._orientationReloadTimer = setTimeout(() => {
					try {
						this.isZoomed = false;
						this.isPinchZooming = false;
						this.isViewportZoomed = false;
	
						const pageContainer = this.$refs.pageContainer;
						if (pageContainer) {
							pageContainer.classList.remove('pinch-lock');
							pageContainer.style.transform = '';
						}
					} catch (e) {
					}
	
					window.location.reload();
				}, 500);
			},
	
			// ============ PANEL MANAGEMENT ============
			togglePanel(side) {
				if (!this.isMobileTablet) {
					if (side === 'left') {
						this.toggleLeftPanel();
					} else {
						this.toggleRightPanel();
					}
					return;
				}
	
				if (side === 'left') {
					this.showLeftPanel = !this.showLeftPanel;
					if (this.showLeftPanel) {
						this.showRightPanel = false;
					}
				} else {
					this.showRightPanel = !this.showRightPanel;
					if (this.showRightPanel) {
						this.showLeftPanel = false;
					}
				}
			},
	
			closeAllPanels() {
				this.showLeftPanel = false;
				this.showRightPanel = false;
			},
	
			// ============ THUMBNAIL GENERATION ============
			generatePagePreviews() {
				// Chỉ generate khi panel trái đang mở (vì preview dùng cho thumbnails bên trái)
				if (!this.isLeftPanelOpen) return;
	
				this.$nextTick(() => {
					this.pages.forEach((page, index) => {
						this.generatePagePreview(page, index);
					});
				});
			},
	
			generatePagePreview(page, index) {
				const canvasRef = this.$refs[`pageCanvas${index}`];
				if (!canvasRef || !canvasRef[0]) return;
	
				const canvas = canvasRef[0];
				const ctx = canvas.getContext('2d');
	
				ctx.clearRect(0, 0, canvas.width, canvas.height);
				ctx.fillStyle = '#ffffff';
				ctx.fillRect(0, 0, canvas.width, canvas.height);
	
				if (page.background) {
					const img = new Image();
					img.crossOrigin = 'anonymous';
					img.onload = () => {
						ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
						this.drawPageElements(ctx, page, canvas.width, canvas.height);
						this.$set(this.pagePreviewReady, index, true);
					};
					img.src = page.background;
				} else {
					this.drawPageElements(ctx, page, canvas.width, canvas.height);
					this.$set(this.pagePreviewReady, index, true);
				}
			},
	
			drawPageElements(ctx, page, canvasWidth, canvasHeight) {
				if (!page.elements || !Array.isArray(page.elements)) return;
	
				const pageType = page.type || 'Desktop';
				const pageDimension = this.pageDimensions[pageType];
				const scaleX = canvasWidth / pageDimension.width;
				const scaleY = canvasHeight / pageDimension.height;
	
				page.elements.forEach(element => {
					if (element.type === 'group') {
						ctx.fillStyle = this.getElementColor(element);
						ctx.fillRect(
							(element.x || 0) * scaleX,
							(element.y || 0) * scaleY,
							(element.width || 50) * scaleX,
							(element.height || 30) * scaleY
						);
					} else if (element.type === 'image-element') {
						ctx.fillStyle = '#e0e0e0';
						ctx.fillRect(
							(element.x || 0) * scaleX,
							(element.y || 0) * scaleY,
							(element.width || 40) * scaleX,
							(element.height || 40) * scaleY
						);
					} else if (element.type === 'text-element') {
						ctx.fillStyle = '#666666';
						ctx.fillRect(
							(element.x || 0) * scaleX,
							(element.y || 0) * scaleY,
							Math.max(20, (element.content?.length || 5) * 2) * scaleX,
							10 * scaleY
						);
					}
				});
			},
	
			getElementColor(element) {
				const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FECA57', '#FF9999'];
				const hash = String(element.id || element.name || 'default').split('').reduce((a, b) => {
					a = ((a << 5) - a) + b.charCodeAt(0); return a & a;
				}, 0);
				return colors[Math.abs(hash) % colors.length];
			},
	
			// Thay thế hàm cũ bằng hàm này
			getTotalItemsForMenu(menu) {
				if (!menu || !menu.originalData) {
					return 0;
				}
	
				// Ưu tiên TemplateDesktop, nếu không có thì dùng TemplateIpad
				const templateJson = menu.originalData.TemplateDesktop || menu.originalData.TemplateIpad || '[]';
	
				try {
					const pages = JSON.parse(templateJson);
	
					if (!Array.isArray(pages)) {
						return 0;
					}
	
					let totalItems = 0;
					// Lặp qua mỗi trang trong menu
					pages.forEach(page => {
						if (page && Array.isArray(page.elements)) {
							// Lọc ra các element là món ăn (có id_SanPham)
							const menuItemsOnPage = page.elements.filter(element =>
								element && element.type === 'group' && element.id_SanPham
							);
							totalItems += menuItemsOnPage.length;
						}
					});
	
					return totalItems;
	
				} catch (e) {
					return 0; // Trả về 0 nếu JSON bị lỗi
				}
			},
	
			getDeviceIcon(deviceType) {
				const icons = {
					Desktop: 'mdi mdi-monitor',
					Tablet: 'mdi mdi-tablet',
					Mobile: 'mdi mdi-cellphone',
					Custom: 'mdi mdi-cog'
				};
				return icons[deviceType] || 'mdi mdi-monitor';
			},
	
			// ============ EVENT HANDLERS ============
			handleClickOutside(event) {
				if (this.isMobileTablet) {
					const leftPanel = document.querySelector('.left-panel');
					const rightPanel = document.querySelector('.right-panel');
					const headerBtns = document.querySelectorAll('.header-btn');
	
					if (leftPanel && !leftPanel.contains(event.target) &&
						rightPanel && !rightPanel.contains(event.target) &&
						![...headerBtns].some(btn => btn.contains(event.target))) {
						this.closeAllPanels();
					}
				}
	
				if (this.$refs.searchResults && !this.$refs.searchResults.contains(event.target) &&
					!event.target.closest('.search-container')) {
					this.showSearchResults = false;
				}
			},
	
			handleWheel(event) {
				if (this.isZoomLocked()) return;
				if (this.isTransitioning) return;
	
				// 👉 Trên Chrome/Edge macOS/Windows, pinch = Ctrl + wheel
				if (event.ctrlKey) {
					// đừng ngăn trình duyệt zoom; cũng đừng lật trang
					return;
				}
	
				event.preventDefault();
				const delta = event.deltaY;
				const threshold = 50;
				if (Math.abs(delta) < threshold) return; delta > 0 ? this.goToNext() : this.goToPrevious();
			},
	
			handleKeyDown(event) {
				if (this.isZoomLocked()) return;
				if (this.isTransitioning) return;
	
				switch (event.key) {
					case 'ArrowUp':
					case 'ArrowLeft':
					case 'PageUp':
						event.preventDefault();
						this.goToPrevious();
						break;
					case 'ArrowDown':
					case 'ArrowRight':
					case 'PageDown':
					case ' ':
						event.preventDefault();
						this.goToNext();
						break;
					case 'Home':
						event.preventDefault();
						this.goToPage(1);
						break;
					case 'End':
						event.preventDefault();
						this.goToPage(this.totalPages);
						break;
					case 'Escape':
						this.showSearchResults = false;
						this.closeAllPanels();
						break;
				}
			},
	
			// ============ NAVIGATION ============
			goToNext(force = false) {
				if (!force && this.isZoomLocked()) return;
				if (this.currentPage < this.totalPages) {
					this.isFromNavButton = true; this.playFlipSound();
					this.goToPage(this.currentPage + 1, force);
				}
			}, goToPrevious(force = false) {
				if (!force && this.isZoomLocked())
					return; if (this.currentPage > 1) {
						this.isFromNavButton = true;
						this.playFlipSound();
						this.goToPage(this.currentPage - 1, force);
					}
			},
	
			goToPage(pageNumber, force = false) {
				if (!force && this.isZoomLocked()) return;
				if (this.isTransitioning || pageNumber < 1 || pageNumber > this.totalPages) return;
	
				const targetPage = Math.max(1, Math.min(pageNumber, this.totalPages));
				if (targetPage === this.currentPage) return;
	
				const isDirectNavigation = !this.isFromNavButton;
				if (isDirectNavigation) this.playFlipSound();
	
				this.isTransitioning = true;
				if (this.isMobileTablet) this.closeAllPanels();
	
				const container = this.$refs.pageContainer;
				if (container) {
					const pageEl = container.querySelector('.current-page');
					container.style.transform = '';
					if (pageEl) {
						pageEl.style.transition = 'transform 150ms ease, opacity 150ms ease';
						pageEl.style.transform = 'scale(0.95)';
						pageEl.style.opacity = '0.7';
						setTimeout(() => {
							this.currentPage = targetPage;
							pageEl.style.transform = '';
							pageEl.style.opacity = '1';
							setTimeout(() => {
								pageEl.style.transition = '';
								this.isTransitioning = false;
								this.isFromNavButton = false;
							}, 200);
						}, 150);
					} else {
						this.currentPage = targetPage;
						this.isTransitioning = false;
						this.isFromNavButton = false;
					}
				} else {
					this.currentPage = targetPage;
					this.isTransitioning = false;
					this.isFromNavButton = false;
				}
			},
	
			goToPageFromSearch(pageNumber) {
				this.goToPage(pageNumber);
				this.showSearchResults = false;
			},
	
			toggleLeftPanel() {
				this.leftPanelCollapsed = !this.leftPanelCollapsed;
				requestAnimationFrame(() => {
					this.$nextTick(() => {
						this.$forceUpdate();
					});
				});
			},
	
			toggleRightPanel() {
				this.rightPanelCollapsed = !this.rightPanelCollapsed;
				requestAnimationFrame(() => {
					this.$nextTick(() => {
						this.$forceUpdate();
					});
				});
			},
	
			toggleZoom() {
				this.isZoomed = !this.isZoomed;
				const container = this.$refs.pageContainer;
				if (container) {
					if (this.isZoomed) {
						container.style.transform = "scale(1.3)";
						container.style.transformOrigin = "center center";
					} else {
						container.style.transform = "scale(1)";
					}
				}
			},
	
	
			// ============ SEARCH ============
			handleSearch(event) {
				const query = event.target.value;
	
				clearTimeout(this.searchTimeout);
	
				if (query.length === 0) {
					this.showSearchResults = false;
					return;
				}
	
				this.searchTimeout = setTimeout(() => {
					if (query.length >= 2) {
						this.performSearch(query);
					}
				}, 200);
			},
	
			performSearch(query) {
				const searchData = [
					{ id: 1, title: 'Há cảo tôm thịt', page: 3, price: '58k', icon: '🥟' },
					{ id: 2, title: 'Siu mai hến', page: 4, price: '45k', icon: '🥢' },
					{ id: 3, title: 'Bánh cuốn tôm', page: 5, price: '52k', icon: '🍜' },
					{ id: 4, title: 'Chả tôm chiên', page: 6, price: '65k', icon: '🍤' }
				];
	
				this.searchResults = searchData.filter(item =>
					item.title.toLowerCase().includes(query.toLowerCase())
				);
	
				this.showSearchResults = true;
			},
	
			setFilter(filterType) {
				this.activeFilter = filterType;
			},
	
			switchToMenu(menuId) {
				this.currentMenu = menuId;
				const menu = this.menuData.find(m => m.id === menuId);
				if (menu) {
					this.showNotification(`Đã chuyển sang ${menu.name}`, 'success');
					this.goToPage(1);
					this.$emit('menu-changed', menuId);
				}
	
				if (this.isMobileTablet) {
					this.closeAllPanels();
				}
			},
	
			// ============ PAGE RENDERING ============
			getCurrentPage() {
				const page = this.pages[this.currentPage - 1] || null;
				return page;
			},
	
			getCurrentPageStyle() {
				const { w, h } = this.pageBox;
				const page = this.getCurrentPage();
				const bg = page?.background || page?.layer?.[0]?.background || null;
	
				return {
					width: `${w}px`,
					height: `${h}px`,
					position: 'relative',
					overflow: 'hidden',
					borderRadius: '10px',
					backgroundImage: bg ? `url(${bg})` : 'none',
					backgroundColor: bg ? 'transparent' : '#ffffff',
					// ❗ dùng chính w, h (không round) để khớp với transform float
					backgroundSize: bg ? `${w}px ${h}px` : 'auto',
					backgroundPosition: 'top left',
					backgroundRepeat: 'no-repeat',
					backfaceVisibility: 'hidden',
					willChange: 'transform',
				};
			},
	
			getPageScaleStyle() {
				const { baseW, baseH, scale } = this.pageBox;
				return {
					width: `${baseW}px`,
					height: `${baseH}px`,
					position: 'absolute',
					left: '0px',
					top: '0px',
					// 👇 bù sub-pixel cả X lẫn Y để overlay khớp nền
					transform: `translate3d(0, 2px, 0) scale(${Number(scale.toFixed(4))})`,
					transformOrigin: 'top left',
					background: 'none',
					willChange: 'transform',
				};
			},
	
			renderElement(el, offsetX = 0, offsetY = 0) {
				if (!el) {
					return '';
				}
	
				const element = JSON.parse(JSON.stringify(el));
	
				const page = this.getCurrentPage();
				const pageSize = this.getPageSize(page);
				const scale = pageSize.scale || 1;
	
				const left = (element.x ?? 0) + (element.relative_x || 0) + offsetX;
				const top = (element.y ?? 0) + (element.relative_y || 0) + offsetY;
	
				const scaledX = left * scale;
				const scaledY = top * scale;
				const scaledWidth = element.width ? (element.width * scale) : null;
				const scaledHeight = element.height ? (element.height * scale) : null;
	
				const CONTROL_AREA_HEIGHT = 30;
				const CONTROL_AREA_WIDTH = 30;
				const CONTROL_BUTTON_SIZE = 20;
	
				let html = '';
	
				if (element.type === 'image-element' || element.type === 'image') {
	
					if (element.groupId) {
						const imageStyleObj = {
							position: 'absolute',
							left: `${scaledX}px`,
							top: `${scaledY}px`,
							width: scaledWidth ? `${scaledWidth}px` : 'auto',
							height: scaledHeight ? `${scaledHeight}px` : 'auto',
							transform: `rotate(${element.rotation || 0}deg)`,
							zIndex: element.zIndex !== undefined ? element.zIndex : 1,
						};
	
						if (element.style) {
							const scaledCustomStyle = this.scaleElementStyle(element.style, scale);
							Object.assign(imageStyleObj, scaledCustomStyle);
						}
	
						const imageStyleStr = Object.entries(imageStyleObj)
							.map(([key, value]) => `${key.replace(/([A-Z])/g, '-$1').toLowerCase()}: ${value}`)
							.join('; ');
	
						html = `<img src="${element.src}" style="${imageStyleStr}" alt="${element.name || ''}" />`;
					} else {
						const boundaryWidth = Math.max(scaledWidth || 50, CONTROL_AREA_WIDTH * scale);
						const boundaryHeight = (scaledHeight || 10) + (CONTROL_AREA_HEIGHT * scale);
	
						const boundaryStyle = `position: absolute; left: ${scaledX}px; top: ${scaledY}px; width: ${boundaryWidth}px; height: ${boundaryHeight}px; border: 2px solid transparent; transition: border-color 0.2s ease; z-index: 1; cursor: move;`;
	
						const controlStyle = `position: absolute; top: ${-10 * scale}px; right: ${-10 * scale}px; width: ${CONTROL_BUTTON_SIZE * scale}px; height: ${CONTROL_BUTTON_SIZE * scale}px; background: #e74c3c; color: white; border: none; border-radius: 50%; display: none; align-items: center; justify-content: center; font-size: ${10 * scale}px; cursor: pointer; z-index: 15;`;
	
						const imageTop = CONTROL_AREA_HEIGHT * scale;
						const imageStyleObj = {
							position: 'absolute',
							left: '0px',
							top: `${imageTop}px`,
							width: scaledWidth ? `${scaledWidth}px` : 'auto',
							height: scaledHeight ? `${scaledHeight}px` : 'auto',
							transform: `rotate(${element.rotation || 0}deg)`,
							zIndex: element.zIndex !== undefined ? element.zIndex : 1,
						};
	
						if (element.style) {
							const scaledCustomStyle = this.scaleElementStyle(element.style, scale);
							Object.assign(imageStyleObj, scaledCustomStyle);
						}
	
						const imageStyleStr = Object.entries(imageStyleObj)
							.map(([key, value]) => `${key.replace(/([A-Z])/g, '-$1').toLowerCase()}: ${value}`)
							.join('; ');
	
						html = `<div class="canvas-element-improved menu-element" style="${boundaryStyle}" onmouseover="this.style.borderColor='#4caf50'" onmouseout="this.style.borderColor='transparent'"><button class="control-btn-improved" style="${controlStyle}" onclick="event.stopPropagation()">×</button><img src="${element.src}" style="${imageStyleStr}" alt="${element.name || ''}" /></div>`;
					}
				}
				else if (element.type === 'text-element') {
	
					if (element.groupId) {
						const textStyleObj = {
							position: 'absolute',
							left: `${scaledX}px`,
							top: `${scaledY}px`,
							whiteSpace: 'pre-line',
							fontSize: `${12 * scale}px`,
							color: '#333',
							zIndex: element.zIndex !== undefined ? element.zIndex : 1,
							pointerEvents: 'none'
						};
	
						if (scaledWidth) textStyleObj.width = `${scaledWidth}px`;
						if (scaledHeight) textStyleObj.height = `${scaledHeight}px`;
	
						if (element.style) {
							const scaledCustomStyle = this.scaleElementStyle(element.style, scale);
							Object.assign(textStyleObj, scaledCustomStyle);
						}
	
						const textStyleStr = Object.entries(textStyleObj)
							.map(([key, value]) => `${key.replace(/([A-Z])/g, '-$1').toLowerCase()}: ${value}`)
							.join('; ');
	
						html = `<div style="${textStyleStr}">${element.content || ''}</div>`;
					} else {
						const boundaryWidth = Math.max(scaledWidth || 100, CONTROL_AREA_WIDTH * scale);
						const boundaryHeight = (scaledHeight || 20) + (CONTROL_AREA_HEIGHT * scale);
	
						const boundaryStyle = `position: absolute; left: ${scaledX}px; top: ${scaledY}px; width: ${boundaryWidth}px; height: ${boundaryHeight}px; border: 2px solid transparent; transition: border-color 0.2s ease; z-index: 15; cursor: move;`;
	
						const controlStyle = `position: absolute; top: ${-10 * scale}px; right: ${-10 * scale}px; width: ${CONTROL_BUTTON_SIZE * scale}px; height: ${CONTROL_BUTTON_SIZE * scale}px; background: #e74c3c; color: white; border: none; border-radius: 50%; display: none; align-items: center; justify-content: center; font-size: ${10 * scale}px; cursor: pointer; z-index: 15;`;
	
						const textTop = CONTROL_AREA_HEIGHT * scale;
						const textStyleObj = {
							position: 'absolute',
							left: '0px',
							top: `${textTop}px`,
							whiteSpace: 'pre-line',
							fontSize: `${12 * scale}px`,
							color: '#333',
							pointerEvents: 'none'
						};
	
						if (scaledWidth) textStyleObj.width = `${scaledWidth}px`;
						if (scaledHeight) textStyleObj.height = `${scaledHeight}px`;
	
						if (element.style) {
							const scaledCustomStyle = this.scaleElementStyle(element.style, scale);
							Object.assign(textStyleObj, scaledCustomStyle);
						}
	
						const textStyleStr = Object.entries(textStyleObj)
							.map(([key, value]) => `${key.replace(/([A-Z])/g, '-$1').toLowerCase()}: ${value}`)
							.join('; ');
	
						html = `<div class="canvas-element-improved menu-element" style="${boundaryStyle}" onmouseover="this.style.borderColor='#4caf50'" onmouseout="this.style.borderColor='transparent'"><button class="control-btn-improved" style="${controlStyle}" onclick="event.stopPropagation()">×</button><div style="${textStyleStr}">${element.content || ''}</div></div>`;
					}
				}
				else if (element.type === 'group' && Array.isArray(element.children) && element.children.length > 0) {
					html = element.children.map(child => this.renderElement(child, left, top)).join('');
				}
				else if (element.type === 'group') {
	
					const groupWidth = scaledWidth || (280 * scale);
					const groupHeight = (scaledHeight || (140 * scale)) + (CONTROL_AREA_HEIGHT * scale);
	
					const boundaryStyle = `position: absolute; left: ${scaledX}px; top: ${scaledY}px; width: ${groupWidth}px; height: ${groupHeight}px; border: 1px solid transparent;`;
	
					const groupControlsStyle = `position: absolute; top: ${-11 * scale}px; left: ${-11 * scale}px; z-index: 100; display: none; gap: ${4 * scale}px;`;
	
					const dragHandleStyle = `background-color: rgba(76, 175, 80, 0.9); color: white; border: none; border-radius: 50%; width: ${CONTROL_BUTTON_SIZE * scale}px; height: ${CONTROL_BUTTON_SIZE * scale}px; display: flex; align-items: center; justify-content: center; font-size: ${10 * scale}px; cursor: move;`;
	
					const controlBtnStyle = `width: ${CONTROL_BUTTON_SIZE * scale}px; height: ${CONTROL_BUTTON_SIZE * scale}px; border: none; border-radius: 50%; background: #e74c3c; color: white; cursor: pointer; font-size: ${10 * scale}px; display: flex; align-items: center; justify-content: center;`;
	
					const contentTop = CONTROL_AREA_HEIGHT * scale;
					const contentHeight = scaledHeight || (140 * scale);
	
					const cardStyle = `position: absolute; left: 0px; top: ${contentTop}px; width: 100%; height: ${contentHeight}px; background: linear-gradient(135deg, #fff 0%, #f8f9fa 100%); border: 2px solid #e9ecef; border-radius: 12px; padding: 16px; display: flex; flex-direction: column; justify-content: center; align-items: center; text-align: center;`;
	
					const productName = element.name || element.MaSoSanPham || 'Menu Item';
	
					html = `<div class="canvas-element-group-improved menu-element" style="${boundaryStyle}"><div class="group-controls-improved" style="${groupControlsStyle}"><div class="drag-handle-improved" style="${dragHandleStyle}"><i class="mdi mdi-drag" style="font-size: ${8 * scale}px; visibility:hidden;"></i></div><button class="control-btn-improved" style="${controlBtnStyle}" onclick="event.stopPropagation()">×</button></div><div class="menu-item-card" style="${cardStyle}"><div style="font-weight: 700; font-size: ${16 * scale}px; color: #2c3e50;">${productName}</div></div></div>`;
				}
				else {
					html = `<div style="position: absolute; left: ${scaledX}px; top: ${scaledY}px; background: red; color: white; padding: 5px; font-size: 12px;">Unknown: ${element.type}</div>`;
				}
	
				return html;
			},
	
			scaleElementStyle(style, scale) {
				if (!style) return {};
	
				const scaledStyle = { ...style };
	
				const scaleableProps = [
					'width', 'height', 'minWidth', 'minHeight', 'maxWidth', 'maxHeight',
					'borderRadius', 'borderWidth', 'borderTopWidth', 'borderRightWidth', 'borderBottomWidth', 'borderLeftWidth',
					'padding', 'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft',
					'margin', 'marginTop', 'marginRight', 'marginBottom', 'marginLeft',
					'top', 'right', 'bottom', 'left',
					'letterSpacing', 'wordSpacing', 'textIndent',
					'textShadow', 'boxShadow', 'outlineWidth'
				];
	
				scaleableProps.forEach(prop => {
					if (scaledStyle[prop]) {
						const value = scaledStyle[prop];
	
						if (typeof value === 'string') {
							if (value.includes('px')) {
								const numValue = parseFloat(value);
								if (!isNaN(numValue)) {
									scaledStyle[prop] = (numValue * scale) + 'px';
								}
							}
							else if (value.includes('em') || value.includes('rem')) {
								const numValue = parseFloat(value);
								if (!isNaN(numValue)) {
									const unit = value.includes('em') ? 'em' : 'rem';
									scaledStyle[prop] = (numValue * scale) + unit;
								}
							}
							else if (prop === 'boxShadow' || prop === 'textShadow') {
								scaledStyle[prop] = value.replace(/(\d+(?:\.\d+)?)px/g, (match, num) => {
									return (parseFloat(num) * scale) + 'px';
								});
							}
						}
						else if (typeof value === 'number') {
							scaledStyle[prop] = (value * scale) + 'px';
						}
					}
				});
	
				if (scaledStyle.fontSize) {
					const fontSize = scaledStyle.fontSize;
					let scaledFontSize;
	
					if (typeof fontSize === 'string') {
						if (fontSize.includes('px')) {
							const numValue = parseFloat(fontSize);
							scaledFontSize = Math.max(8, numValue * scale) + 'px';
						} else if (fontSize.includes('em') || fontSize.includes('rem')) {
							const numValue = parseFloat(fontSize);
							const unit = fontSize.includes('em') ? 'em' : 'rem';
							scaledFontSize = Math.max(0.5, numValue * scale) + unit;
						} else {
							scaledFontSize = fontSize;
						}
					} else if (typeof fontSize === 'number') {
						scaledFontSize = Math.max(8, fontSize * scale) + 'px';
					}
	
					scaledStyle.fontSize = scaledFontSize;
				}
	
				return scaledStyle;
			},
	
			getPageSize(page) {
				const pageType = page?.type || 'Desktop';
				const baseDimensions = this.pageDimensions[pageType] || this.pageDimensions.Desktop;
	
				const availableWidth = this.availableContentWidth;
				const availableHeight = this.availableContentHeight;
	
				const scaleByWidth = availableWidth / baseDimensions.width;
				const scaleByHeight = availableHeight / baseDimensions.height;
	
				let scale = Math.min(scaleByWidth, scaleByHeight);
	
				const viewportWidth = window.innerWidth;
				let minScale, maxScale;
	
				if (viewportWidth <= this.BREAKPOINTS.MOBILE) {
					minScale = 0.3; maxScale = 1.0;
				} else if (viewportWidth <= this.BREAKPOINTS.TABLET) {
					minScale = 0.4; maxScale = 1.5;
				} else if (viewportWidth <= this.BREAKPOINTS.DESKTOP) {
					minScale = 0.5; maxScale = 2.0;
				} else {
					minScale = 0.6; maxScale = 2.5;
				}
	
				scale = Math.max(minScale, Math.min(maxScale, scale));
	
				return {
					w: baseDimensions.width * scale,
					h: baseDimensions.height * scale,
					scale: scale,
					baseW: baseDimensions.width,
					baseH: baseDimensions.height
				};
			},
	
			getPageName(page, index) {
				return page.name || `Trang ${index + 1}`;
			},
	
			getCategoryIcon(page) {
				const icons = {
					'intro': 'mdi mdi-home',
					'dimsum': 'mdi mdi-dumpling',
					'soup': 'mdi mdi-bowl-mix',
					'dessert': 'mdi mdi-cake-variant',
					'drink': 'mdi mdi-cup',
					'main': 'mdi mdi-silverware-fork-knife',
					'appetizer': 'mdi mdi-food-apple',
					'seafood': 'mdi mdi-fish',
					'vegetarian': 'mdi mdi-leaf',
					'meat': 'mdi mdi-food-steak'
				};
				return icons[page?.category] || 'mdi mdi-silverware-fork-knife';
			},
	
			// ============ MENU FUNCTIONS ============
			getMenuThumbnailStyle(menu) {
				if (menu.thumbnail) {
					return {
						backgroundImage: 'url(' + menu.thumbnail + ')',
						backgroundSize: 'cover',
						backgroundPosition: 'center',
						backgroundRepeat: 'no-repeat'
					};
				} else {
					return this.getMenuGradient(menu);
				}
			},
	
			getMenuGradient(menu) {
				if (menu && menu.color && Array.isArray(menu.color) && menu.color.length >= 2) {
					return {
						background: `linear-gradient(135deg, ${menu.color[0]}, ${menu.color[1]})`
					};
				}
				const gradients = [
					['#667eea', '#764ba2'],
					['#f093fb', '#f5576c'],
					['#4facfe', '#00f2fe'],
					['#43e97b', '#38f9d7'],
					['#fa709a', '#fee140'],
					['#a8edea', '#fed6e3'],
					['#ffecd2', '#fcb69f'],
					['#ff9a9e', '#fecfef']
				];
				const randomGradient = gradients[menu.MenuBookID % gradients.length];
				return {
					background: `linear-gradient(135deg, ${randomGradient[0]}, ${randomGradient[1]})`
				};
			},
	
			getMenuThumbnail(menu) {
				if (menu.Thumbnail_FileID) {
					return `https://file.zenfoodcourt.vn/eorder/auth/FileData/${menu.Thumbnail_FileID}`;
				}
				return null;
			},
	
			getMenuIcon(menu) {
				const name = menu.TenBook.toLowerCase();
				if (name.includes('dimsum') || name.includes('hong kong')) return '🥟';
				if (name.includes('bakery') || name.includes('bánh')) return '🍞';
				if (name.includes('coffee') || name.includes('cà phê')) return '☕';
				if (name.includes('tea') || name.includes('trà')) return '🍵';
				if (name.includes('japanese') || name.includes('nhật')) return '🍱';
				if (name.includes('korean') || name.includes('hàn')) return '🍲';
				if (name.includes('drink') || name.includes('nước')) return '🥤';
				if (name.includes('dessert') || name.includes('tráng miệng')) return '🍰';
				return '🍽️';
			},
	
			getMenuDescription(menu) {
				const name = menu.TenBook.toLowerCase();
				if (name.includes('dimsum')) return 'Dimsum, há cảo, sủi cảo...';
				if (name.includes('bakery')) return 'Bánh mì, bánh ngọt, bánh kem...';
				if (name.includes('coffee')) return 'Cà phê, cappuccino, latte...';
				if (name.includes('japanese')) return 'Sushi, ramen, tempura...';
				if (name.includes('korean')) return 'Kimchi, bulgogi, bibimbap...';
				return 'Đa dạng món ăn ngon...';
			},
	
			getMenuPageCount(menu) {
				if (menu.TemplateDesktop && menu.TemplateDesktop !== 'default') {
					try {
						const pages = JSON.parse(menu.TemplateDesktop);
						return Array.isArray(pages) ? pages.length : 1;
					} catch (e) {
						return 1;
					}
				} else if (menu.PhanHieu_ID === 2) {
					try {
						const pages = JSON.parse(menu.TemplateIpad);
						return Array.isArray(pages) ? pages.length : 1;
					} catch (e) {
						return 1;
					}
				}
				return 1;
			},
	
			generateMenuColors(menu) {
				const colorPairs = [
					['#FF6B6B', '#FF8E8E'],
					['#4ECDC4', '#6EE7DC'],
					['#45B7D1', '#6BC5D8'],
					['#96CEB4', '#B4D7C4'],
					['#FECA57', '#FED882'],
					['#A8E6CF', '#C8E6C9'],
					['#FFB3BA', '#FFCCCB'],
					['#C3B8E6', '#D1C4E9']
				];
				return colorPairs[menu.MenuBookID % colorPairs.length];
			},
	
			showNotification(message, type = 'info') {
			},
	
			onClose() {
				window.location.href = 'https://eorder.zenfoodcourt.vn/menu-khach';
			},
			// 👇 3. SỬA ĐỔI HOÀN TOÀN HÀM `switchToMenu`
			switchToMenu(menuId) {
				// Tìm menu đầy đủ từ menuData
				const menu = this.menuData.find(m => m.id === menuId);
				if (!menu || !menu.originalData) {
					return;
				}
	
				// Lấy PhanHieuID từ dữ liệu gốc của menu
	
				const phanHieuId = menu.originalData.PhanHieu_ID;
				if (!(phanHieuId >= 0)) {
					this.showNotification(`Menu '${menu.name}' không có thông tin thương hiệu.`, 'error');
					return;
				}
	
				// Lọc danh sách cửa hàng có cùng PhanHieuID
				const matchingStores = this.dscuahang.filter(c => c.PhanHieuID === phanHieuId);
	
				// Xử lý các trường hợp
				if (matchingStores.length === 0) {
					// Trường hợp 1: Không có cửa hàng nào cho thương hiệu này
					this.showNotification(`Hiện không có cửa hàng nào cho thương hiệu '${menu.name}'.`, 'warning');
					//Mẫn thêm this.selectedMenuBookIdForModal = menu.id;
					this.navigateToStore(menu.id, 0);
					return;
				}
	
				if (matchingStores.length === 1) {
					// Trường hợp 2: Chỉ có 1 cửa hàng -> tự động chọn và điều hướng
					this.showNotification(`Đang tải menu cho ${matchingStores[0].TenCuaHang}...`, 'info');
					this.navigateToStore(menu.id, matchingStores[0].CuaHangID);
				} else {
					// Trường hợp 3: Có nhiều cửa hàng -> mở modal để người dùng chọn
					this.storesForSelectedMenu = matchingStores;
					this.selectedMenuBookIdForModal = menu.id;
					this.isStoreModalVisible = true;
				}
			},
	
			// 👇 4. THÊM CÁC HÀM MỚI ĐỂ XỬ LÝ MODAL
			handleStoreSelection(cuaHangId) {
				// Đóng modal
				this.isStoreModalVisible = false;
				this.showNotification('Đang tải menu bạn đã chọn...', 'info');
				// Gọi hàm điều hướng
				this.navigateToStore(this.selectedMenuBookIdForModal, cuaHangId);
			},
			navigateToStore(menuBookId, cuaHangId) {
				let url = "https://eorder.zentea.vn/menu-online"
				const mapping = vueData.storeMapping.find(x =>
					x.MenuBookID == menuBookId &&
					x.CuaHangID == cuaHangId)
				if (mapping) {
					url += `?name=${mapping.name}`
				} else {
					url += `?MenuBookID=${menuBookId}&CuaHangID=${cuaHangId}`
				}
				window.location.href = url;
			},
	
			closeStoreModal() {
				this.isStoreModalVisible = false;
			},
			// Thêm hàm này vào trong methods của uc-e-menu-new
			applyScaleToStyle(originalStyle, scale) {
				if (!originalStyle) return {};
	
				const scaledStyle = { ...originalStyle };
	
				// Duyệt qua tất cả các key trong object style
				for (const prop in scaledStyle) {
					const value = scaledStyle[prop];
					// Chỉ xử lý các giá trị là string và chứa 'px'
					if (typeof value === 'string' && value.includes('px')) {
						// Thay thế tất cả các giá trị pixel bằng giá trị đã scale
						// Regex này tìm tất cả các số (có thể có dấu chấm) theo sau là 'px'
						const scaledValue = value.replace(/(-?\d*\.?\d+)px/g, (match, num) => {
							return (parseFloat(num) * scale).toFixed(2) + 'px';
						});
						scaledStyle[prop] = scaledValue;
					}
				}
	
				return scaledStyle;
			},
	
			getThumbnailContentStyle(page) {
				const pageType = page.type || page.TypePage || 'Desktop';
				const baseDimensions = this.pageDimensions[pageType] || this.pageDimensions.Desktop;
	
				const wrapperWidth = 240;
				const wrapperHeight = 140;
	
				// Tính scale để vừa với chiều cao
				const scale = wrapperHeight / baseDimensions.height;
	
				// Kích thước của nội dung sau khi đã scale
				const scaledWidth = baseDimensions.width * scale;
				const scaledHeight = baseDimensions.height * scale; // = wrapperHeight
	
				// Tính toán vị trí top và left để căn giữa
				const leftOffset = (wrapperWidth - scaledWidth) / 2;
				const topOffset = (wrapperHeight - scaledHeight) / 2; // Sẽ bằng 0 nếu scale theo chiều cao
	
				const backgroundUrl = page.background || (page.layer && page.layer[0] ? page.layer[0].background : null);
	
				return {
					position: 'absolute', // Đảm bảo position là absolute
					left: `${leftOffset}px`,
					top: `${topOffset}px`,
					width: `${baseDimensions.width}px`,
					height: `${baseDimensions.height}px`,
					transform: `scale(${scale})`,
					transformOrigin: 'top left',
	
					backgroundImage: backgroundUrl ? `url(${backgroundUrl})` : 'none',
					backgroundColor: backgroundUrl ? 'transparent' : '#ffffff',
					backgroundSize: 'cover',
					backgroundPosition: 'center center',
					backgroundRepeat: 'no-repeat',
	
					pointerEvents: 'none'
				};
			}
		},
	
		watch: {
			isLeftPanelOpen(open) {
				if (open && !this.leftPanelLoadedOnce) {
					this.leftPanelLoadedOnce = true;
					this.$nextTick(() => this.generatePagePreviews()); // chỉ chạy khi mở lần đầu
				}
				// nếu muốn đóng là "xóa cache/preview" thì làm ở else
				// else { this.pagePreviewReady = {}; }
			},
	
			isRightPanelOpen(open) {
				if (open && !this.rightPanelLoadedOnce) {
					this.rightPanelLoadedOnce = true;
					// nếu right panel có load riêng (ví dụ build menuData nặng) thì gọi ở đây
					// this.$nextTick(() => this.loadRightPanelData());
				}
			},
			// ✅ Update totalPages khi filteredPages thay đổi
			filteredPages: {
				immediate: true,
				handler(pages) {
					this.totalPages = pages.length;
				}
			},
			dscuahang: {
				immediate: true,
				handler(val) {
	
				}
			},
	
			dsmon: {
				immediate: true,
				handler(newVal) {
					this.dsmonVersion++;
					this.filteredPageCache.clear();
					// phần anh đang $forceUpdate có thể giữ/giảm tùy
				}
			},
	
			dsmenu: {
				immediate: true,
				handler(val) {
					this.pages = [];
	
					if (val && val.length > 0) {
						val.forEach((item, itemIndex) => {
							try {
								let templateData = null;
								let pageType = 'Desktop'; // Default
	
								console.groupCollapsed(
									'🧩 [Menu Template] MenuBookID:',
									item.MenuBookID,
									'| TenBook:',
									item.TenBook
								);
								console.log('PhanHieu_ID:', item.PhanHieu_ID);
								console.log('TemplateDesktop:', {
									isDefault: item.TemplateDesktop === 'default',
									isEmpty: !item.TemplateDesktop,
									length: item.TemplateDesktop ? item.TemplateDesktop.length : 0
								});
								console.log('TemplateIpad:', {
									isDefault: item.TemplateIpad === 'default',
									isEmpty: !item.TemplateIpad,
									length: item.TemplateIpad ? item.TemplateIpad.length : 0
								});
	
								if (item.PhanHieu_ID === 2) {
									if (item.TemplateIpad && item.TemplateIpad !== 'default') {
										templateData = item.TemplateIpad;
										pageType = 'Tablet';
									}
								} else {
									if (item.TemplateDesktop && item.TemplateDesktop !== 'default') {
										templateData = item.TemplateDesktop;
										pageType = 'Desktop';
									}
								}
	
								console.log('➡ Chọn template từ:',
									templateData === item.TemplateDesktop ? 'TemplateDesktop'
										: templateData === item.TemplateIpad ? 'TemplateIpad'
											: '❌ Không chọn được template (null/invalid)'
								);
								console.log('➡ pageType:', pageType);
	
								if (templateData) {
									console.log('Preview templateData:', templateData.substring(0, 80) + '...');
								}
	
								console.groupEnd();
	
								if (templateData) {
									const parsedPages = JSON.parse(templateData);
	
									if (Array.isArray(parsedPages)) {
										parsedPages.forEach((page, pageIndex) => {
											page.type = pageType;
											page.sourceMenu = item;
											this.pages.push(page);
										});
									} else if (parsedPages && typeof parsedPages === 'object') {
										parsedPages.type = pageType;
										parsedPages.sourceMenu = item;
										this.pages.push(parsedPages);
									}
								}
							} catch (e) {
								console.error(
									'❌ Error parsing template for MenuBookID:',
									item.MenuBookID,
									'| TenBook:',
									item.TenBook,
									e
								);
								console.groupEnd?.();
							}
						});
					}
	
					this.currentPage = 1;
	
					this.$nextTick(() => {
						this.$forceUpdate();
	
						// ✅ THÔNG BÁO SAU KHI LOAD XONG
						console.log('Đây là thông báo');
						// Nếu anh có implement showNotification thì gọi luôn:
						if (typeof this.showNotification === 'function') {
							this.showNotification('Đây là thông báo', 'info');
						}
					});
				}
			},
	
			dsmenubook: {
				immediate: true,
				handler(val) {
					this.menuData = [];
					if (val && val.length > 0) {
						val.forEach((menuBook, index) => {
							const menuItem = {
								id: menuBook.MenuBookID.toString(),
								MenuBookID: menuBook.MenuBookID,
								name: menuBook.TenBook,
								icon: this.getMenuIcon(menuBook),
								description: this.getMenuDescription(menuBook),
								pages: this.getMenuPageCount(menuBook),
								color: this.generateMenuColors(menuBook),
								thumbnail: this.getMenuThumbnail(menuBook),
								originalData: menuBook
							};
	
							this.menuData.push(menuItem);
						});
					}
	
					if (this.menuData.length > 0 && !this.currentMenu) {
						this.currentMenu = this.menuData[0].id;
					}
				}
			},
	
			currentPage() {
				if (!this.isLeftPanelOpen) return;
				this.$nextTick(() => this.generatePagePreviews());
			},
	
			leftPanelCollapsed() {
				this.$nextTick(() => {
					this.$forceUpdate();
				});
			},
	
			rightPanelCollapsed() {
				this.$nextTick(() => {
					this.$forceUpdate();
				});
			},
	
			pages: {
				handler(newPages) {
					if (!newPages?.length) return;
					if (!this.isLeftPanelOpen) return;
					this.$nextTick(() => this.generatePagePreviews());
				},
				deep: true
			}
		}
	}
</script>