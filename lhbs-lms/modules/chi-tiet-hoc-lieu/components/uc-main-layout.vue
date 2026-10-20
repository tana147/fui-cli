<template>
	<div class="uc-main-layout">
		<!-- Header / Toolbar: Cố định phía trên cùng của giao diện, trải dài 100% chiều ngang -->
		<header class="uc-main-layout__header">
			<v-toolbar color="primary" density="compact" class="uc-main-layout__toolbar">
				<!-- Nút quay lại danh mục học liệu -->
				<v-btn
					icon="mdi-arrow-left"
					variant="text"
					aria-label="Quay lại danh mục"
					@click="handleBack"
				></v-btn>

				<!-- Tiêu đề học liệu và mô tả bộ sách -->
				<v-toolbar-title class="ml-1 text-left">
					<div class="text-subtitle-1 font-weight-bold text-truncate line-height-1">
						{{ bannerInfo && bannerInfo.TenHocLieu ? bannerInfo.TenHocLieu : 'Chi tiết học liệu' }}
					</div>
					<div
						v-if="bannerInfo && bannerInfo.MoTaBoSach"
						class="text-caption text-truncate opacity-80"
					>
						{{ bannerInfo.MoTaBoSach }}
					</div>
				</v-toolbar-title>

				<v-spacer></v-spacer>

				<!-- Nút mở Drawer Mục lục học liệu trên Mobile -->
				<v-btn
					v-if="isMobile"
					icon="mdi-format-list-bulleted"
					variant="text"
					aria-label="Mở mục lục học liệu"
					@click="toggleDrawer"
				></v-btn>
			</v-toolbar>
		</header>

		<!-- Khung thân chính: Chia 2 cột Sidebar Mục lục bên trái và Nội dung bài học bên phải -->
		<div class="uc-main-layout__body">
			<!-- Overlay bóng mờ khi mở Drawer Mục lục trên màn hình Mobile -->
			<div
				v-if="isMobile && drawerOpen"
				class="uc-main-layout__scrim"
				@click="closeDrawer"
			></div>

			<!-- Sidebar Mục lục học liệu: Cố định 340px trên Desktop, dạng Drawer trượt trên Mobile -->
			<aside
				class="uc-main-layout__sidebar"
				:class="{
					'uc-main-layout__sidebar--mobile': isMobile,
					'uc-main-layout__sidebar--open': drawerOpen
				}"
			>
				<div class="uc-main-layout__sidebar-header d-flex align-center px-3 py-2">
					<v-icon color="primary" size="small" class="mr-2">mdi-file-tree-outline</v-icon>
					<strong class="text-subtitle-2 font-weight-bold">Mục lục học liệu</strong>
					<v-spacer></v-spacer>
					<!-- Nút đóng mục lục khi ở Mobile -->
					<v-btn
						v-if="isMobile"
						icon="mdi-close"
						variant="text"
						size="small"
						aria-label="Đóng mục lục"
						@click="closeDrawer"
					></v-btn>
				</div>
				<v-divider></v-divider>

				<!-- Loading skeleton hoặc Cây mục lục học liệu -->
				<div class="uc-main-layout__tree">
					<div v-if="isLoading" class="d-flex align-center justify-center py-8">
						<v-progress-circular indeterminate color="primary" size="32"></v-progress-circular>
					</div>
					<uc-mucluc-treeview
						v-else
						:items="treeMucLuc"
						:selected-id="selectedId"
						:on-node-click="handleNodeClick"
						:on-hoat-dong-click="handleActivityClick"
					></uc-mucluc-treeview>
				</div>
			</aside>

			<!-- Vùng nội dung chi tiết bài học bên phải: Chiếm toàn bộ phần chiều rộng còn lại -->
			<main class="uc-main-layout__content">
				<div class="uc-main-layout__content-inner pa-3">
					<!-- Trường hợp đang tải dữ liệu -->
					<div v-if="isLoading" class="d-flex align-center justify-center fill-height py-12">
						<v-progress-circular indeterminate color="primary" size="40"></v-progress-circular>
					</div>

					<!-- Trường hợp đã chọn một bài học cụ thể -->
					<v-card v-else-if="selectedBai" class="pa-4 fill-height" elevation="1">
						<!-- Breadcrumb định vị phân cấp: giúp người học luôn biết bài đang xem thuộc Chủ đề/Chương nào -->
						<div v-if="breadcrumbPath && breadcrumbPath.length > 1" class="d-flex align-center flex-wrap ga-1 mb-3 py-1 px-2.5 rounded-lg bg-slate-50 border text-caption">
							<template v-for="(bNode, bIdx) in breadcrumbPath" :key="bNode.NoiDungID || bIdx">
								<span
									class="d-flex align-center cursor-pointer transition-colors"
									:class="bIdx === breadcrumbPath.length - 1 ? 'font-weight-bold text-teal-darken-3' : 'text-slate-600 hover:text-teal-darken-2'"
									@click="handleNodeClick(bNode)"
								>
									<v-icon size="14" class="mr-1" :color="bIdx === breadcrumbPath.length - 1 ? 'teal-darken-2' : 'slate-500'">
										{{ bIdx === 0 ? 'mdi-folder-outline' : (bIdx === breadcrumbPath.length - 1 ? 'mdi-file-document-outline' : 'mdi-notebook-outline') }}
									</v-icon>
									<span>{{ bNode.TenNoiDung }}</span>
								</span>
								<v-icon v-if="bIdx < breadcrumbPath.length - 1" size="14" color="grey-lighten-1" class="mx-0.5">
									mdi-chevron-right
								</v-icon>
							</template>
						</div>

						<uc-baihoc-content
							:item="selectedBai"
							:on-hoat-dong-click="handleActivityClick"
						></uc-baihoc-content>
					</v-card>

					<!-- Trường hợp học liệu chưa có bất kỳ bài học/mục lục nào -->
					<v-card
						v-else-if="!treeMucLuc || treeMucLuc.length === 0"
						class="d-flex flex-column align-center justify-center text-center fill-height pa-8 border rounded-xl bg-white"
						elevation="0"
					>
						<div class="empty-hoclieu-icon-wrap mb-4 d-flex align-center justify-center rounded-circle bg-teal-lighten-5" style="width: 72px; height: 72px;">
							<v-icon size="36" color="teal-darken-2">mdi-book-open-page-variant-outline</v-icon>
						</div>
						<h3 class="text-h6 font-weight-bold text-slate-800 mb-2">
							Học liệu chưa có nội dung bài học
						</h3>
						<p class="text-body-2 text-grey-darken-1 mb-5" style="max-width: 460px;">
							Học liệu này hiện đang trong quá trình biên soạn và chưa được tạo bài học hoặc mục lục nội dung.
						</p>
						<v-btn
							color="primary"
							variant="tonal"
							rounded="pill"
							prepend-icon="mdi-arrow-left"
							class="px-5 font-weight-bold"
							@click="handleBack"
						>
							Quay lại danh mục học liệu
						</v-btn>
					</v-card>

					<!-- Trường hợp có mục lục nhưng chưa chọn mục nào -->
					<v-card v-else class="d-flex flex-column align-center justify-center text-center fill-height pa-6" elevation="0">
						<v-icon size="40" color="grey-lighten-1" class="mb-2">mdi-cursor-default-click-outline</v-icon>
						<div class="text-subtitle-2 text-grey-darken-1">
							Vui lòng chọn một mục từ mục lục học liệu bên trái để xem nội dung.
						</div>
					</v-card>
				</div>
			</main>
		</div>
	</div>
</template>

<script>
	export default {
		data() {
			return {
				hocLieuID: null,
				bannerInfo: {},
				dshocLieuFlat: [],
				treeMucLuc: [],
				selectedBai: null,
				activeActivityId: null,
				isLoading: true,
				isMobile: false,
				drawerOpen: true
			};
		},
		computed: {
			selectedId() {
				return this.selectedBai ? this.selectedBai.NoiDungID : null;
			},
			// Tính toán chuỗi phân cấp tổ tiên (Breadcrumb path) từ Gốc -> Chương -> Bài -> Hoạt động
			breadcrumbPath() {
				if (!this.selectedBai || !this.treeMucLuc || this.treeMucLuc.length === 0) return [];
				const findPath = (nodes, targetId, currentPath = []) => {
					for (const node of nodes) {
						const nextPath = [...currentPath, node];
						if (String(node.NoiDungID) === String(targetId)) {
							return nextPath;
						}
						if (node.children && node.children.length > 0) {
							const res = findPath(node.children, targetId, nextPath);
							if (res) return res;
						}
					}
					return null;
				};
				return findPath(this.treeMucLuc, this.selectedBai.NoiDungID) || [this.selectedBai];
			}
		},
		mounted() {
			// Lưu vết referrer danh mục ban đầu để nút Quay lại hoạt động chính xác
			if (document.referrer && !document.referrer.includes('hoc-lieu-view-v2') && !document.referrer.includes('chi-tiet-hoc-lieu')) {
				try {
					sessionStorage.setItem('lhbs_catalog_referrer', document.referrer);
				} catch (e) {}
			}

			this.updateViewport();
			window.addEventListener('resize', this.updateViewport);

			// Đọc tham số Học liệu từ URL và gọi API tải cây mục lục
			const urlParams = new URLSearchParams(window.location.search);
			this.hocLieuID = urlParams.get('id') || urlParams.get('hoclieuid');
			if (this.hocLieuID) {
				this.loadTreeData();
			} else {
				this.isLoading = false;
			}
		},
		beforeUnmount() {
			window.removeEventListener('resize', this.updateViewport);
		},
		methods: {
			// Tải dữ liệu cây mục lục học liệu trực tiếp qua fetchPromise / ajaxAPI
			async loadTreeData() {
				this.isLoading = true;
				try {
					let result = null;
					if (typeof fetchPromise === 'function') {
						result = await fetchPromise('lms/FP_NoiDung_GetTreeByHocLieu', { HocLieuID: this.hocLieuID });
					} else if (typeof ajaxAPI === 'function') {
						result = await new Promise((resolve) => {
							ajaxAPI('lms/FP_NoiDung_GetTreeByHocLieu', { HocLieuID: this.hocLieuID }, resolve, () => resolve(null));
						});
					}

					if (result && Array.isArray(result) && result.length > 1) {
						this.bannerInfo = result[0] && result[0][0] ? result[0][0] : {};
						this.dshocLieuFlat = result[1] || [];
						this.buildTree();

						// Tự động chọn bài hoặc mục theo tham số URL hoặc phiên lưu trữ trước đó
						if (this.treeMucLuc && this.treeMucLuc.length > 0) {
							const urlParams = new URLSearchParams(window.location.search);
							const savedId = urlParams.get('noidungid') || urlParams.get('baiid') || sessionStorage.getItem('lhbs_selected_noidung_' + this.hocLieuID);
							let selectedLessonNode = null;
							let activeActivityId = null;

							if (savedId && this.dshocLieuFlat) {
								const flatItem = this.dshocLieuFlat.find(x => String(x.NoiDungID) === String(savedId));
								const findInTree = (nodes, idToFind) => {
									if (!nodes || !Array.isArray(nodes)) return null;
									for (const n of nodes) {
										if (String(n.NoiDungID) === String(idToFind)) return n;
										if (n.children && n.children.length > 0) {
											const match = findInTree(n.children, idToFind);
											if (match) return match;
										}
									}
									return null;
								};

								if (flatItem) {
									activeActivityId = flatItem.NoiDungID;
									selectedLessonNode = findInTree(this.treeMucLuc, flatItem.NoiDungID) || flatItem;
								}
							}

							if (!selectedLessonNode && this.treeMucLuc.length > 0) {
								selectedLessonNode = this.treeMucLuc[0];
							}

							this.activeActivityId = activeActivityId || (selectedLessonNode ? selectedLessonNode.NoiDungID : null);
							this.handleNodeClick(selectedLessonNode);
						}
					}
				} catch (err) {
					console.error('Lỗi khi tải cây mục lục học liệu:', err);
				} finally {
					this.isLoading = false;
				}
			},

			// Xác định người dùng hiện tại là Giáo viên/Admin hay Học sinh
			isUserTeacher() {
				const user = (typeof vueData !== 'undefined' && vueData?.user) || window.user || {};
				// 1. Kiểm tra các cờ vai trò Giáo viên / Admin trực tiếp
				if (user.IsGiaoVien === true || user.isTeacher === true || user.IsTeacher === true || user.IsAdmin === true || user.isAdmin === true) {
					return true;
				}
				// 2. Kiểm tra vai trò hoặc mã cán bộ / giáo viên / nhân viên
				if (user.Role === 'GiaoVien' || user.Role === 'Admin' || user.Role === 'GV' || !!user.NhanVienID || !!user.GiaoVienID || !!user.MaNhanVien) {
					return true;
				}
				// 3. Tài khoản có quyền hệ thống (SystemRight > 0)
				if (user.SystemRight !== undefined && user.SystemRight !== null && Number(user.SystemRight) > 0) {
					return true;
				}
				// 4. Nếu không phải Học sinh/Phụ huynh (không có HocSinhID và mã UserID không bắt đầu bằng HS hoặc PH)
				if (user.UserID) {
					const uId = String(user.UserID).toUpperCase();
					if (!user.HocSinhID && !uId.startsWith('HS') && !uId.startsWith('PH')) {
						return true;
					}
				}
				return false;
			},

			// Xây dựng cấu trúc cây đa tầng từ danh sách phẳng DSHocLieu_Flat
			buildTree() {
				const flatList = this.dshocLieuFlat;
				if (!flatList || flatList.length === 0) {
					this.treeMucLuc = [];
					return;
				}
				const isTeacher = this.isUserTeacher();
				const nodeMap = {};
				const roots = [];

				flatList.forEach(item => {
					let dataObj = {};
					if (item.DataJson) {
						if (typeof item.DataJson === 'object') dataObj = item.DataJson;
						else {
							try { dataObj = JSON.parse(item.DataJson) || {}; } catch(e) {}
						}
					}
					const isTeacherOnly = Boolean(item.IsTeacherOnly || dataObj.isTeacherOnly || dataObj.IsTeacherOnly || dataObj.chiGiaoVien || dataObj.ChiGiaoVien);

					// Nếu là Học sinh: Bỏ qua không hiển thị các node Chỉ giáo viên xem
					if (!isTeacher && isTeacherOnly) {
						return;
					}

					nodeMap[item.NoiDungID] = { ...item, IsTeacherOnly: isTeacherOnly, children: [] };
				});

				Object.values(nodeMap).forEach(node => {
					if (node.ParentID && nodeMap[node.ParentID]) {
						nodeMap[node.ParentID].children.push(node);
					} else if (!node.ParentID || !nodeMap[node.ParentID]) {
						if (!node.ParentID) {
							roots.push(node);
						}
					}
				});

				const sortNodes = (nodes) => {
					if (!nodes) return;
					nodes.sort((a, b) => (a.ThuTu || 0) - (b.ThuTu || 0));
					nodes.forEach(node => {
						if (node.children.length > 0) sortNodes(node.children);
					});
				};
				sortNodes(roots);
				this.treeMucLuc = roots;
			},

			// Xử lý sự kiện quay lại trang trước
			handleBack() {
				// Khi mở trực tiếp hoặc đi từ viewer, referrer có thể không còn là danh mục; chọn đích theo nhóm người dùng và quyền admin.
				const khoiId = this.bannerInfo?.KhoiID || this.bannerInfo?.KhoiHocID || this.bannerInfo?.khoiid;
				const catalogUrl = khoiId ? `/kham-pha?khoiid=${encodeURIComponent(khoiId)}` : '/kham-pha';
				const user = (typeof vueData !== 'undefined' && vueData?.user) || window.user || {};
				const groupId = Number(user.GroupID ?? user.GroupId ?? user.groupid ?? user.groupID);
				const systemRight = Number(user.SystemRight ?? user.systemRight ?? 0);
				const editorParams = new URLSearchParams();
				if (khoiId) editorParams.set('KhoiID', khoiId);
				const monHocId = this.bannerInfo?.MonHocID || this.bannerInfo?.MonhocID || this.bannerInfo?.monhocid;
				if (monHocId) editorParams.set('MonHocID', monHocId);
				const editorUrl = `/soan-hoc-lieu-v2${editorParams.toString() ? `?${editorParams.toString()}` : ''}`;
				const fallbackUrl = groupId === 1 && systemRight === 9
					? editorUrl
					: (groupId === 1 ? catalogUrl : '/lms-student-dashboard');
				let savedReferrer = null;
				try {
					savedReferrer = sessionStorage.getItem('lhbs_catalog_referrer');
				} catch (e) {}
				if (savedReferrer && !savedReferrer.includes('hoc-lieu-view-v2') && !savedReferrer.includes('chi-tiet-hoc-lieu')) {
					window.location.href = savedReferrer;
				} else if (document.referrer && !document.referrer.includes('hoc-lieu-view-v2') && !document.referrer.includes('chi-tiet-hoc-lieu')) {
					window.location.href = document.referrer;
				} else if (typeof redirect === 'function') {
					redirect(fallbackUrl);
				} else {
					window.location.href = fallbackUrl;
				}
			},

			// Tự động cập nhật chế độ hiển thị responsive
			updateViewport() {
				const nextIsMobile = window.innerWidth <= 768;
				if (nextIsMobile !== this.isMobile) {
					this.isMobile = nextIsMobile;
					this.drawerOpen = !nextIsMobile;
				}
			},

			toggleDrawer() {
				this.drawerOpen = !this.drawerOpen;
			},

			closeDrawer() {
				if (this.isMobile) {
					this.drawerOpen = false;
				}
			},

			// Khi bấm chọn một mục trên cây mục lục: hiển thị nội dung xem trước
			handleNodeClick(node) {
				if (node) {
					this.selectedBai = node;
					if (this.hocLieuID && node.NoiDungID) {
						try {
							sessionStorage.setItem('lhbs_selected_noidung_' + this.hocLieuID, node.NoiDungID);
						} catch (e) {}
					}
				}
				if (this.isMobile) {
					this.closeDrawer();
				}
			},

			// Kiểm tra node có nội dung xem trực tiếp
			hasDirectPlayableContent(node) {
				if (!node) return false;
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (loai === 'CHUONG') return false;
				const dataJson = node.DataJson == null ? '' : String(node.DataJson).trim();
				const hasValidData = dataJson !== '' && dataJson !== 'null' && dataJson !== '{}';
				return hasValidData || ['VIDEO', 'HTML', 'TAILIEU', 'TAI_LIEU', 'SLIDE', 'INTERACTIVE', 'QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_ORDERING', 'QUIZ_MATCHING', 'QUIZ_DRAG_DROP_CATEGORIZE', 'QUIZ_FILL_IN_BLANK', 'QUIZ_CONNECTION', 'QUIZ_COMPOSITE'].includes(loai);
			},

			// Tìm phần tử con đầu tiên có nội dung để mở khi bấm vào thư mục/chủ đề cha
			findFirstPlayableLeaf(node) {
				if (!node) return null;
				if (this.hasDirectPlayableContent(node)) return node;
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				let children = node.children;
				if ((!children || children.length === 0) && this.dshocLieuFlat) {
					children = this.dshocLieuFlat.filter(x => String(x.ParentID) === String(node.NoiDungID));
					children.sort((a, b) => (a.ThuTu || 0) - (b.ThuTu || 0));
				}
				const isContainer = !this.hasDirectPlayableContent(node) && (['CHUONG', 'BAI', 'NHOM_KY_NANG', 'NHOM', 'TOHOP', 'FOLDER'].includes(loai) || (children && children.length > 0));
				if (!isContainer) {
					return node;
				}
				if (children && children.length > 0) {
					for (const child of children) {
						const leaf = this.findFirstPlayableLeaf(child);
						if (leaf) return leaf;
					}
				}
				return null;
			},

			// Khi bấm vào nút Xem hoạt động: chuyển hướng sang module trình xem học liệu /hoc-lieu-view-v2
			handleActivityClick(hoatDong) {
				if (!hoatDong || !hoatDong.NoiDungID) return;
				let targetNode = hoatDong;
				const loai = (hoatDong.LoaiNoiDung || '').toUpperCase();
				let children = hoatDong.children;
				if ((!children || children.length === 0) && this.dshocLieuFlat) {
					children = this.dshocLieuFlat.filter(x => String(x.ParentID) === String(hoatDong.NoiDungID));
				}
				const isContainer = !this.hasDirectPlayableContent(hoatDong) && (['CHUONG', 'BAI', 'NHOM_KY_NANG', 'NHOM', 'TOHOP', 'FOLDER'].includes(loai) || (children && children.length > 0));
				if (isContainer) {
					targetNode = this.findFirstPlayableLeaf(hoatDong);
					if (!targetNode || !targetNode.NoiDungID) return;
				}
				if (this.hocLieuID && this.selectedBai) {
					try {
						sessionStorage.setItem('lhbs_selected_noidung_' + this.hocLieuID, this.selectedBai.NoiDungID);
					} catch (e) {}
				}
				const hocLieuId = this.hocLieuID;
				const hsId = window.vueData?.HocSinhID || window.vueData?.user?.HocSinhID || window.vueData?.user?.UserID || (window.vueData?.HocSinhSelected?.HocSinhID) || '';
				const redirectUrl = `/hoc-lieu-view-v2?hoclieuid=${hocLieuId}&noidungid=${targetNode.NoiDungID}${hsId ? '&HocSinhID=' + hsId : ''}`;
				if (typeof redirect === 'function') {
					redirect(redirectUrl);
				} else {
					window.location.href = redirectUrl;
				}
			}
		}
	}
</script>