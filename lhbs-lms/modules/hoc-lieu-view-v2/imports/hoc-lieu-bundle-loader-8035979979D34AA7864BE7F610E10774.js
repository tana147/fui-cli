// Import FUI có thể chạy trước khi Vue/Vuetify được khởi tạo; chờ runtime sẵn sàng
// rồi mới đăng ký các component để DOC/DOCX viewer không bị lỗi do sai thứ tự load.
;(function waitForHocLieuRuntime() {
	if (typeof window === 'undefined') return;
	if (!window.Vue || typeof window.Vue.component !== 'function') {
		window.setTimeout(waitForHocLieuRuntime, 0);
		return;
	}

;(function() {
  const compDef = {
    template: `<div class="lh-main-layout">
    <div class="lh-lesson-layout">
      
      <!-- 1. Header Toolbar (Cố định chiều cao 48px, không bị wrap vỡ dòng) -->
      <header class="lh-app-header">
        <div class="lh-header-left">
          <!-- Back button: Quay lại danh mục học liệu và giữ nguyên HocSinhID -->
          <v-btn
            :icon="true"
            variant="text"
            density="comfortable"
            class="lh-btn-back flex-shrink-0"
            title="Quay lại danh mục học liệu"
            @click="goBack"
          >
            <v-icon>mdi-arrow-left</v-icon>
          </v-btn>

          <!-- Brand logo LHBS: Nhãn nhận diện tĩnh, không chuyển trang -->
          <div class="lh-brand-tag flex-shrink-0">
            <img src="/_cdn/lhbs-lms/logo_lhbs_2.jpg" alt="LHBS" class="lh-brand-logo" />
            <span class="lh-brand-title d-none d-sm-inline font-weight-bold">LHBS</span>
          </div>

          <!-- Luồng Breadcrumbs phân cấp theo Chương / Bài / Hoạt động (Có LaTeX và chống vỡ khi tên quá dài) -->
          <div class="lh-breadcrumbs-flow">
            <template v-if="breadcrumbs && breadcrumbs.length">
              <template v-for="(bc, idx) in breadcrumbs" :key="idx">
                <span
                  class="lh-bc-item"
                  :class="{ 'lh-bc-current font-weight-bold text-primary': bc.isCurrent, 'd-none d-md-inline-flex text-medium-emphasis': !bc.isCurrent }"
                  :title="bc.title"
                >
                  <v-icon v-if="bc.icon" size="14" class="mr-1 opacity-70 flex-shrink-0">{{ bc.icon }}</v-icon>
                  <span class="lh-bc-text text-truncate">
                    <uc-latex-view :content="bc.title" class="d-inline"></uc-latex-view>
                  </span>
                </span>
                <v-icon v-if="idx !== breadcrumbs.length - 1" size="12" class="lh-bc-sep d-none d-md-inline-flex mx-1 text-medium-emphasis flex-shrink-0">mdi-chevron-right</v-icon>
              </template>
            </template>
            <span v-else class="lh-bc-item lh-bc-current font-weight-bold text-primary text-truncate" :title="lessonTitle">
              <uc-latex-view :content="lessonTitle || 'Đang tải bài học...'" class="d-inline text-truncate"></uc-latex-view>
            </span>
          </div>
        </div>

        <!-- Header Right: Bộ đếm slide & Nút toàn màn hình TV (Luôn cố định bên phải) -->
        <div class="lh-header-right">
          <v-chip size="small" variant="tonal" color="primary" class="font-weight-bold flex-shrink-0">
            <v-icon :start="true" size="14">mdi-file-document-outline</v-icon>
            {{ lenCurrentNoiDung + 1 }} / {{ lenDetailNoiDung }}
          </v-chip>

          <v-btn
            :icon="true"
            variant="text"
            density="comfortable"
            class="lh-btn-fullscreen ml-1 flex-shrink-0"
            title="Trình chiếu toàn màn hình (Phím F)"
            @click="togglePresentationFullscreen"
          >
            <v-icon size="20" :color="isPresentationFullscreen ? 'primary' : 'default'">
              {{ isPresentationFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}
            </v-icon>
          </v-btn>
        </div>
      </header>

      <!-- 2. Vùng hiển thị nội dung chính (Flex row 2 cột chiếm toàn bộ chiều cao còn lại) -->
      <main class="lh-content-main position-relative">
        <!-- Backdrop cho Drawer mục lục trên Mobile & Tablet (ẩn từ 960px trở lên qua CSS) -->
        <div v-if="showMucLucDrawer" class="lh-mobile-toc-backdrop" @click="showMucLucDrawer = false"></div>

        <div class="lh-content-container" :class="{ 'has-toc-open': showMucLucDrawer }">
          
          <!-- Cột Sidebar Mục lục học liệu bên trái (Desktop: Sidebar, Mobile: Overlay Drawer) -->
          <aside v-if="showMucLucDrawer" class="lh-toc-sidebar-card">
            <!-- Tiêu đề sidebar mục lục -->
            <div class="lh-toc-sidebar-header d-flex align-center justify-space-between px-3 py-2 border-b bg-slate-50 flex-shrink-0">
              <div class="d-flex align-center font-weight-bold text-subtitle-2 text-slate-800">
                <v-icon :start="true" color="primary" size="20">mdi-format-list-bulleted-square</v-icon>
                Mục lục học liệu
              </div>
              <v-btn
                :icon="true"
                variant="text"
                density="compact"
                size="small"
                class="lh-toc-close-btn"
                title="Đóng mục lục (Phím M / Esc)"
                @click="showMucLucDrawer = false"
              >
                <v-icon size="18">mdi-close</v-icon>
              </v-btn>
            </div>

            <!-- Ô tìm kiếm bài học nhanh -->
            <div class="px-3 pt-2 pb-2 bg-white border-b flex-shrink-0">
              <v-text-field
                v-model="treeSearch"
                density="compact"
                variant="outlined"
                :hide-details="true"
                placeholder="Tìm kiếm bài học, hoạt động..."
                prepend-inner-icon="mdi-magnify"
                :clearable="true"
                class="text-body-2"
              ></v-text-field>
            </div>

            <!-- Danh sách cây mục lục học liệu chuẩn Treeview -->
            <div class="lh-toc-sidebar-body pa-2 flex-grow-1 overflow-y-auto">
              <div v-if="displayTreeList && displayTreeList.length" class="lh-tree-item-list">
                <div
                  v-for="item in displayTreeList"
                  :key="item.node.NoiDungID"
                  class="lh-tree-item px-2 d-flex align-center cursor-pointer transition-all"
                  :class="{
                    'lh-tree-item-active': item.isCurrent,
                    'lh-tree-root-node': item.depth === 0,
                    'lh-tree-section-node': String(item.node.LoaiNoiDung || '').toUpperCase() === 'CHUONG',
                    'lh-tree-lesson-node': String(item.node.LoaiNoiDung || '').toUpperCase() === 'BAI',
                    'lh-tree-branch-node': item.hasChildren,
                    'lh-tree-leaf-node': !item.hasChildren,
                    'lh-tree-has-children': item.hasChildren,
                    'lh-tree-is-open': item.hasChildren && isNodeOpen(item.node)
                  }"
                  :title="item.node.TenNoiDung"
                  @click="handleTreeNodeClick(item.node)"
                >
                  <!-- Mỗi slot đại diện cho một depth thực tế, nên cây tự hỗ trợ thêm cấp mà không cần thêm class level mới. -->
                  <span
                    v-for="level in item.depth"
                    :key="\`indent-\${item.node.NoiDungID}-\${level}\`"
                    class="lh-tree-indent-slot"
                    aria-hidden="true"
                  ></span>

                  <!-- Nút toggle đóng mở cho node có con -->
                  <span
                    v-if="item.hasChildren"
                    class="lh-tree-chevron mr-1 flex-shrink-0 d-inline-flex align-center justify-center"
                    @click.stop="toggleNodeCollapse(item.node)"
                    :title="isNodeOpen(item.node) ? 'Thu gọn' : 'Mở rộng'"
                  >
                    <v-icon size="16" :color="item.depth === 0 ? 'primary' : 'medium-emphasis'">
                      {{ isNodeOpen(item.node) ? 'mdi-chevron-down' : 'mdi-chevron-right' }}
                    </v-icon>
                  </span>
                  
                  <!-- Spacer hoặc branch guide icon cho node con không có children -->
                  <span v-else-if="item.depth !== 0" class="lh-tree-branch-indicator mr-1 flex-shrink-0 d-inline-flex align-center justify-center">
                    <v-icon size="14" color="medium-emphasis" class="opacity-60">mdi-subdirectory-arrow-right</v-icon>
                  </span>
                  <span v-else class="lh-tree-chevron-spacer mr-1 flex-shrink-0"></span>

                  <!-- Icon phân loại nội dung -->
                  <v-icon
                    :size="item.depth === 0 ? 18 : 16"
                    class="mr-2 flex-shrink-0"
                    :color="item.isCurrent ? 'primary' : (item.depth === 0 ? 'primary' : (item.hasChildren ? 'secondary' : 'medium-emphasis'))"
                  >
                    {{ item.icon }}
                  </v-icon>

                  <!-- Tên đề mục hiển thị qua uc-latex-view & text-truncate chống vỡ khi tên dài -->
                  <div
                    class="lh-tree-item-text-wrapper text-body-2 flex-grow-1 overflow-hidden"
                    :class="{
                      'font-weight-bold text-primary': item.isCurrent,
                      'font-weight-bold text-slate-800': !item.isCurrent && item.depth === 0,
                      'font-weight-medium text-slate-700': !item.isCurrent && item.hasChildren && item.depth !== 0,
                      'text-slate-600': !item.isCurrent && !item.hasChildren
                    }"
                  >
                    <uc-latex-view :content="item.node.TenNoiDung" class="lh-tree-latex-content text-truncate d-block"></uc-latex-view>
                  </div>

                  <!-- Badge Chỉ giáo viên xem -->
                  <v-chip
                    v-if="item.node.IsTeacherOnly"
                    size="x-small"
                    color="warning"
                    variant="flat"
                    class="lh-tree-teacher-chip ml-1 font-weight-bold flex-shrink-0"
                    label
                  >
                    <v-icon start size="10">mdi-account-tie</v-icon>
                    Chỉ GV
                  </v-chip>

                  <!-- Badge số lượng con trực tiếp -->
                  <v-chip
                    v-if="item.childCount !== 0"
                    size="x-small"
                    variant="tonal"
                    :color="item.depth === 0 ? 'primary' : 'secondary'"
                    class="lh-tree-child-count-chip ml-1 font-weight-bold flex-shrink-0"
                  >
                    {{ item.childCount }}
                  </v-chip>

                  <!-- Icon đang phát bài hiện tại -->
                  <v-icon v-if="item.isCurrent" size="16" color="primary" class="ml-1 flex-shrink-0">
                    mdi-play-circle
                  </v-icon>
                </div>
              </div>
              <div v-else class="pa-4 text-center text-caption text-medium-emphasis">
                Không tìm thấy nội dung phù hợp.
              </div>
            </div>
          </aside>

          <!-- Vùng trình xem nội dung bài học bên phải -->
          <div class="lh-slide-container" ref="slideContainer">
            <!-- Giữ một nút mở mục lục duy nhất trong vùng trình xem để tránh lặp nút ở header. -->
            <div v-if="!showMucLucDrawer" class="lh-floating-left-controls">
              <button
                class="lh-btn-floating-toc"
                @click="toggleMucLucDrawer"
                title="Mở mục lục danh sách bài học (Phím M)"
              >
                <v-icon size="16">mdi-format-list-bulleted-square</v-icon>
                <span class="lh-floating-toc-text d-none d-sm-inline font-weight-medium">Mục lục</span>
                <v-icon size="14" class="ml-0.5">mdi-chevron-right</v-icon>
              </button>
            </div>

            <!-- Slide Core Viewer -->
            <div v-if="slides && slides.length && currentSlideIndex !== -1" class="lh-slide-wrapper">
              <uc-slide-viewer-v3
                id="slide_viewer"
                :slide-data="slides[currentSlideIndex]"
                :is-last-lesson="(lenCurrentNoiDung + 1) === lenDetailNoiDung"
                :is-toc-open="showMucLucDrawer"
                @next="increasePage"
                @open-toc="toggleMucLucDrawer"
                class="lh-slide-viewer-core"
              ></uc-slide-viewer-v3>
            </div>
            <div v-else class="lh-loading-container">
              <div class="lh-loading-content">
                <v-progress-circular :indeterminate="true" color="primary" size="36" width="3"></v-progress-circular>
                <div class="lh-loading-text mt-3 text-medium-emphasis text-body-2">
                  <uc-latex-view :content="lessonTitle" class="d-inline"></uc-latex-view>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>

      <!-- 3. Thanh điều hướng chân trang -->
      <footer class="lh-navigation-footer">
        <div class="lh-nav-container">
          <v-btn
            class="lh-nav-btn"
            variant="outlined"
            color="secondary"
            density="comfortable"
            :disabled="(lenCurrentNoiDung + 1) === 1"
            @click="decreasePage"
          >
            <v-icon :start="true">mdi-chevron-left</v-icon>
            Bài trước
          </v-btn>

          <div class="lh-nav-progress">
            <v-progress-linear
              color="primary"
              height="6"
              :rounded="true"
              :model-value="((lenCurrentNoiDung + 1) / (lenDetailNoiDung || 1)) * 100"
              class="lh-nav-progress-bar"
            ></v-progress-linear>
            <span class="lh-nav-progress-label text-caption text-medium-emphasis">
              Tiến độ: {{ lenCurrentNoiDung + 1 }}/{{ lenDetailNoiDung }}
            </span>
          </div>

          <v-btn
            class="lh-nav-btn"
            variant="flat"
            color="primary"
            density="comfortable"
            :disabled="(lenCurrentNoiDung + 1) === lenDetailNoiDung"
            @click="increasePage"
          >
            Bài tiếp theo
            <v-icon :end="true">mdi-chevron-right</v-icon>
          </v-btn>
        </div>
      </footer>
    </div>
  </div>`,
    name: 'uc-main-layout',
  data() {
    return {
      HocLieuID: 0,
      NoiDungID: 0,
      lessonId: null,
      lessonTitle: 'Đang tải bài giảng...',
      slides: [],
      currentSlideIndex: -1,
      isLoading: true,
      DetailHocLieu: {},
      DetailNoiDung: [],
      lenDetailNoiDung: 0,
      lenCurrentNoiDung: 0,
      currentBaiGiang: null,
      isPresentationFullscreen: false,
      showMucLucDrawer: false,
      treeSearch: '',
      treeMucLuc: [],
      openedNodeIds: [],
      displayTreeList: [],
      breadcrumbs: [],
      touchStartX: 0,
      touchStartY: 0,
      touchStartTarget: null,
      isNavigatingKey: false
    };
  },
  watch: {
    treeSearch() {
      this.updateDisplayTreeList();
    }
  },
  mounted() {
    // 1. Phân tích tham số từ URL
    const urlParams = new URLSearchParams(window.location.search);
    const paramHocLieuId = urlParams.get('hoclieuid') || urlParams.get('id');
    const paramNoiDungId = urlParams.get('noidungid');

    this.HocLieuID = paramHocLieuId ? parseInt(paramHocLieuId) : 0;
    this.NoiDungID = paramNoiDungId ? parseInt(paramNoiDungId) : 0;
    this.lessonId = this.NoiDungID;

    // 2. Đăng ký sự kiện toàn màn hình và phím bấm điều khiển trình chiếu
    document.addEventListener('fullscreenchange', this.onFullscreenChange);
    window.addEventListener('keydown', this.handleKeyDown);

    // 3. Khởi tạo cử chỉ vuốt chạm touch gestures
    this.initTouchGestures();

    // 4. Tải cây mục lục và chi tiết bài học
    if (this.HocLieuID) {
      this.loadTreeData();
    } else if (this.lessonId) {
      this.loadLessonDetail(this.lessonId);
    } else {
      this.isLoading = false;
      this.lessonTitle = 'Không tìm thấy ID bài giảng.';
    }
  },
  beforeUnmount() {
    document.removeEventListener('fullscreenchange', this.onFullscreenChange);
    window.removeEventListener('keydown', this.handleKeyDown);
  },
  methods: {
    // === 1. TẢI DỮ LIỆU CÂY HỌC LIỆU & CHI TIẾT ===
    async loadTreeData() {
      this.isLoading = true;
      try {
        let result = null;
        if (typeof fetchPromise === 'function') {
          result = await fetchPromise('lms/FP_NoiDung_GetTreeByHocLieu', { HocLieuID: this.HocLieuID });
        } else if (typeof ajaxAPI === 'function') {
          result = await new Promise((resolve) => {
            ajaxAPI('lms/FP_NoiDung_GetTreeByHocLieu', { HocLieuID: this.HocLieuID }, resolve, () => resolve(null));
          });
        }

        if (result && Array.isArray(result) && result.length > 1) {
          this.DetailHocLieu = result[0] && result[0][0] ? result[0][0] : {};
          this.DetailNoiDung = result[1] || [];

          // Xây dựng cây và danh sách bài học có nội dung/câu hỏi thực tế
          this.treeMucLuc = this.buildTreeStructure(this.DetailNoiDung);
          const validActivities = this.getValidActivities();

          if (validActivities.length > 0) {
            const currentTreeNode = this.findTreeNode(this.treeMucLuc, this.NoiDungID);
            const isCategoryGroup = currentTreeNode && this.isNavigationGroup(currentTreeNode);

            // Nếu chưa có NoiDungID từ URL hoặc NoiDungID đang trỏ vào nhóm danh mục cha -> Tự động chuyển đến bài học cụ thể
            if (!this.NoiDungID || isCategoryGroup) {
              const firstPlayable = isCategoryGroup
                ? this.getFirstActivityInGroup(this.NoiDungID)
                : validActivities[0];
              if (firstPlayable) {
                this.NoiDungID = firstPlayable.NoiDungID;
                this.lessonId = firstPlayable.NoiDungID;
                this.pushState('noidungid', this.NoiDungID);
              }
            }
          }

          this.renderDataPage();
          if (this.lessonId) {
            await this.loadLessonDetail(this.lessonId);
          }
        }
      } catch (err) {
        console.error('Lỗi khi tải cây học liệu:', err);
      } finally {
        this.isLoading = false;
      }
    },

    async loadLessonDetail(noiDungId) {
      this.isLoading = true;
      try {
        let res = null;
        if (typeof fetchPromise === 'function') {
          res = await fetchPromise('lms/FP_NoiDung_GetDetail', { NoiDungID: noiDungId });
        } else if (typeof ajaxAPI === 'function') {
          res = await new Promise((resolve) => {
            ajaxAPI('lms/FP_NoiDung_GetDetail', { NoiDungID: noiDungId }, resolve, () => resolve(null));
          });
        }

        this.handleApiResponse(res);
        this.saveLog();
      } catch (err) {
        console.error('Lỗi khi tải chi tiết bài giảng:', err);
        this.lessonTitle = 'Lỗi tải dữ liệu bài giảng.';
        this.slides = [];
        this.currentSlideIndex = -1;
      } finally {
        this.isLoading = false;
      }
    },

    // Ghi nhận nhật ký học sinh xem bài học vào hệ thống LMS (Chỉ áp dụng khi người học là Học sinh)
    saveLog() {
      const user = (typeof vueData !== 'undefined' && vueData.user) || window.user || {};
      const urlParams = new URLSearchParams(window.location.search);

      // 1. Kiểm tra nếu người dùng hiện tại là Giáo viên / Quản trị viên / Ban giám hiệu
      const isTeacher = this.isUserTeacher();

      // Nếu là Giáo viên xem duyệt hoặc trình chiếu học liệu trên lớp -> KHÔNG ghi log vào bảng học sinh
      if (isTeacher) {
        return;
      }

      // 2. Xác định mã Học sinh thực tế của phiên học
      const hocSinhId = (user && user.HocSinhID)
        || (typeof vueData !== 'undefined' && vueData.HocSinhID)
        || (typeof vueData !== 'undefined' && vueData.HocSinhSelected && vueData.HocSinhSelected.HocSinhID)
        || (user.UserID && (String(user.UserID).toUpperCase().startsWith('NA') || String(user.UserID).toUpperCase().startsWith('HS')) ? user.UserID : null)
        || urlParams.get('HocSinhID')
        || urlParams.get('hocSinhId')
        || null;

      if (!hocSinhId || !this.lessonId) return;

      const payload = {
        HocSinhID: String(hocSinhId),
        MonHocID: parseInt(urlParams.get('monhocid') || (this.DetailHocLieu && this.DetailHocLieu.MonHocID) || 0) || 0,
        HocLieuID: parseInt(this.HocLieuID) || 0,
        NoiDungID: parseInt(this.lessonId) || 0
      };

      if (typeof fetchPromise === 'function') {
        fetchPromise('lms/EL_Log_XemHocLieu_Save', payload).catch(() => {});
      } else if (typeof ajaxAPI === 'function') {
        ajaxAPI('lms/EL_Log_XemHocLieu_Save', payload, () => {}, () => {});
      }
    },

    // DataJson được tạo từ nhiều nguồn, nên các trường URL đôi khi là object lồng nhau.
    // Chuẩn hóa ngay tại biên API để component không nhận giá trị "[object Object]".
    cleanMediaValue(value, fallbackKeys = []) {
      if (typeof value === 'string') return value.trim();
      if (typeof value === 'number') return String(value);
      if (!value || typeof value !== 'object') return '';

      const keys = [...fallbackKeys, 'url', 'source', 'viewerSource', 'externalSource', 'audioUrl',
        'FILE_URL', 'fileUrl', 'FileURL', 'href', 'src'];
      for (const key of keys) {
        const nested = this.cleanMediaValue(value[key]);
        if (nested) return nested;
      }
      return '';
    },

    // Giữ một schema URL thống nhất cho viewer, đồng thời hỗ trợ bản ghi cũ chỉ lưu videoId.
    normalizeLessonContent(content, title = '') {
      if (!content || typeof content !== 'object' || Array.isArray(content)) return content;

      const normalized = { ...content };
      const mediaKeys = ['url', 'source', 'viewerSource', 'externalSource', 'audioUrl',
        'FILE_URL', 'fileUrl', 'FileURL'];
      mediaKeys.forEach((key) => {
        if (Object.prototype.hasOwnProperty.call(normalized, key)) {
          const value = this.cleanMediaValue(normalized[key], [key]);
          if (value) normalized[key] = value;
        }
      });

      const videoId = this.cleanMediaValue(normalized.videoId);
      if (!normalized.url && videoId) normalized.url = `https://www.youtube.com/watch?v=${videoId}`;
      if (!normalized.title && title) normalized.title = title;
      return normalized;
    },

    // Một số node file cũ trả reference ở cấp bản ghi thay vì trong DataJson. Nếu không
    // khôi phục metadata này, uc-main-layout sẽ biến DOC/DOCX thành EMPTY_STATE trước viewer.
    extractLessonFileContent(item) {
      if (!item || typeof item !== 'object') return null;

      const readValue = keys => {
        for (const key of keys) {
          const value = item[key];
          if (value !== undefined && value !== null && String(value).trim()) return value;
        }
        return '';
      };

      const fileId = readValue([
        'fileId', 'FILE_ID', 'FileID', 'FileId', 'fileID', 'archiveFileId', 'ArchiveFileID',
        'resourceFileId', 'resourceFileID', 'LmsFileID', 'LmsFileId', 'FileDataID', 'FileDataId'
      ]);
      const fileName = readValue([
        'fileName', 'FILE_NAME', 'FileName', 'TenFile', 'archiveFileName',
        'ArchiveFileName', 'TenTep', 'TenNoiDung'
      ]);
      const fileUrl = readValue([
        'url', 'source', 'FILE_URL', 'fileUrl', 'FileURL', 'FileUrl',
        'dbUrl', 'DB_URL', 'viewerSource'
      ]);
      const contentType = readValue([
        'contentType', 'FILE_CONTENTTYPE', 'FileContentType', 'MimeType',
        'MIME_TYPE', 'fileMimeType'
      ]);
      const rawType = readValue(['slideType', 'fileType', 'FileType', 'LoaiFile', 'LoaiNoiDung']);
      const value = `${rawType} ${contentType} ${fileName} ${fileUrl}`.toLowerCase();
      const hasReference = Boolean(fileId || fileUrl) ||
        /\.(?:pdf|docx?|xlsx?|pptx?)(?:$|[?#\s])/i.test(String(fileName));
      if (!hasReference) return null;

      let slideType = '';
      if (/pdf|application\/pdf/.test(value)) slideType = 'PDF';
      else if (/pptx?|powerpoint|presentation/.test(value)) slideType = 'PPT';
      else if (/xlsx?|excel|spreadsheet/.test(value)) slideType = 'XLSX';
      else if (/wordprocessingml|\bdocx\b/.test(value)) slideType = 'DOCX';
      else if (/msword|(?:^|[\s._/?#-])doc(?:$|[\s._/?#-])/.test(value)) slideType = 'DOC';

      const resolvedUrl = fileUrl || (fileId ? `/FileData/${fileId}` : '');
      const resolvedName = fileName || (fileId ? `file-${fileId}` : '');
      return {
        title: resolvedName || item.TenNoiDung || '',
        fileName: resolvedName,
        fileId,
        contentType,
        url: resolvedUrl,
        uploadSource: fileId || /(?:^|\/)FileData\//i.test(resolvedUrl) ? 'db' : '',
        slideType: slideType || String(rawType || '').toUpperCase()
      };
    },

    // LoaiNoiDung cũ đôi lúc là AUDIO/TAILIEU dù DataJson thực tế là video.
    // Ưu tiên tín hiệu media trong metadata để không render nhầm audio player.
    normalizeLessonType(rawType, content) {
      const type = String(rawType || '').trim().toUpperCase();
      if (type === 'VIDEO') return 'VIDEO';

      const mediaFields = ['mediaType', 'contentType', 'slideType', 'fileType', 'uploadSource',
        'fileName', 'url', 'source', 'viewerSource', 'externalSource', 'videoId', 'audioUrl'];
      const mediaHint = mediaFields
        .map((key) => this.cleanMediaValue(content?.[key], [key]))
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      const looksLikeVideo = /youtube|youtu\.be|video|\.mp4(?:$|[?#])|\.webm(?:$|[?#])|\.mov(?:$|[?#])|\.m3u8(?:$|[?#])|\.avi(?:$|[?#])/.test(mediaHint);
      const looksLikeAudio = /audio|\.mp3(?:$|[?#])|\.wav(?:$|[?#])|\.ogg(?:$|[?#])|\.m4a(?:$|[?#])/.test(mediaHint);

      if (looksLikeVideo && !type.startsWith('QUIZ_')) return 'VIDEO';
      if (type === 'AUDIO' || (!type && looksLikeAudio)) return 'AUDIO';
      // Các loại slide không phải media có nhánh render riêng và có thể dùng camelCase,
      // vì vậy phải giữ nguyên giá trị gốc thay vì biến toàn bộ thành chữ hoa.
      return String(rawType || '').trim() || 'EMPTY_STATE';
    },

    // Xử lý dữ liệu trả về từ API và chuyển thành định dạng slide chuẩn
    handleApiResponse(res) {
      if (res && Array.isArray(res) && res[0]) {
        const lessonData = res[0];
        this.lessonTitle = lessonData.TenNoiDung;
        let slide = {
          id: lessonData.NoiDungID,
          type: lessonData.LoaiNoiDung,
          content: null
        };

        let hasValidContent = false;
        try {
          const rawDataJson = lessonData.DataJson;
          const dataJsonText = typeof rawDataJson === 'string' ? rawDataJson.trim() : '';
          const isEmptyObject = rawDataJson && typeof rawDataJson === 'object' && !Array.isArray(rawDataJson)
            && Object.keys(rawDataJson).length === 0;
          if (rawDataJson && !isEmptyObject && (typeof rawDataJson === 'object' || (dataJsonText !== '' && dataJsonText !== 'null' && dataJsonText !== '{}' && dataJsonText !== '""'))) {
            if (typeof rawDataJson === 'string' && this.isPureHTMLString(rawDataJson)) {
              slide.content = { htmlContent: rawDataJson, textContent: rawDataJson, title: lessonData.TenNoiDung };
              hasValidContent = true;
            } else if (typeof rawDataJson === 'object') {
              slide.content = rawDataJson;
              hasValidContent = true;
            } else {
              const jsonParse = JSON.parse(rawDataJson);
              if (typeof jsonParse === 'object' && jsonParse !== null) {
                slide.content = jsonParse;
                if (!slide.content.htmlContent && slide.content.textContent) {
                  slide.content.htmlContent = slide.content.textContent;
                }
                if (!slide.content.textContent && slide.content.htmlContent) {
                  slide.content.textContent = slide.content.htmlContent;
                }
                hasValidContent = true;
              } else {
                slide.content = { htmlContent: String(jsonParse), textContent: String(jsonParse), title: lessonData.TenNoiDung };
                hasValidContent = true;
              }
            }
          }
        } catch (e) {
          console.warn('⚠️ Lỗi parse nội dung bài giảng:', e);
          if (lessonData.DataJson) {
            slide.type = 'RawHTML';
            slide.content = lessonData.DataJson;
            hasValidContent = true;
          }
        }

        // DataJson rỗng/placeholder không đủ để dựng viewer; dùng reference file cấp item
        // nếu API trả kèm FILE_ID/FILE_URL hoặc metadata tương đương của bản ghi cũ.
        const itemFileContent = this.extractLessonFileContent(lessonData);
        const hasDbFileReference = itemFileContent && (
          !!itemFileContent.fileId
          || itemFileContent.uploadSource === 'db'
          || /(?:^|\/)FileData\//i.test(String(itemFileContent.url || ''))
        );
        // File DB LMS là nguồn chuẩn như PDF: nếu bản ghi có FileID, metadata cấp item
        // phải được merge đè lên URL Drive cũ trong DataJson để viewer dùng FileData nội bộ.
        if (itemFileContent && (!hasValidContent || hasDbFileReference)) {
          slide.content = hasValidContent && hasDbFileReference && slide.content && typeof slide.content === 'object'
            ? { ...slide.content, ...itemFileContent }
            : itemFileContent;
          hasValidContent = true;
        }

        if (hasValidContent) {
          slide.content = this.normalizeLessonContent(slide.content, lessonData.TenNoiDung);
          slide.type = this.normalizeLessonType(slide.type, slide.content);
        }

        // Nếu node không có dữ liệu nội dung (ví dụ node Chương/Bài hoặc chưa nhập DataJson) -> Chuyển thành EMPTY_STATE
        if (!hasValidContent) {
          slide.type = 'EMPTY_STATE';
          slide.content = {
            title: lessonData.TenNoiDung,
            loaiNoiDung: lessonData.LoaiNoiDung,
            message: 'Nội dung bài học đang được cập nhật hoặc chưa có nội dung bài giảng.',
            description: 'Vui lòng chọn bài học khác từ mục lục hoặc bấm "Bài tiếp theo" để tiếp tục học tập.'
          };
        }

        if (String(slide.type || '').toUpperCase().startsWith('QUIZ_') && slide.type !== 'QUIZ_COMPOSITE') {
          slide.content = this.normalizeQuizSlideContent(slide.content, lessonData.TenNoiDung, slide.type);
        }

        const slideContent = slide.content && typeof slide.content === 'object' ? slide.content : {};
        if (slide.type !== 'ISPRING_CONTENT' && (slideContent.iSpringURL || /ispring|application\/x-ispring/.test(`${slide.type || ''} ${slideContent.contentType || ''} ${slideContent.url || ''}`))) {
          slide.type = 'ISPRING_CONTENT';
        }

        this.slides = [slide];
        this.currentSlideIndex = 0;
      } else {
        this.lessonTitle = 'Lỗi tải dữ liệu bài giảng.';
        this.slides = [];
        this.currentSlideIndex = -1;
      }
    },

    // === 2. XÂY DỰNG CẤY MỤC LỤC TREEVIEW (PARENT - CHILD) ===
    renderDataPage() {
      const flatList = this.DetailNoiDung;
      if (!flatList || flatList.length === 0) return;

      const nodeMap = new Map();
      flatList.forEach(item => {
        nodeMap.set(item.NoiDungID, { ...item });
      });

      const objCurrent = nodeMap.get(this.NoiDungID);
      let currentBai = null;
      let currentNhomKyNang = null;
      if (objCurrent && objCurrent.ParentID && nodeMap.has(objCurrent.ParentID)) {
        const parentNode = nodeMap.get(objCurrent.ParentID);
        if (parentNode.LoaiNoiDung === 'BAI' || parentNode.LoaiNoiDung === 'NHOM_KY_NANG') {
          currentBai = parentNode;
        }
      }

      this.currentBaiGiang = {
        ...objCurrent,
        currentNhomKyNang,
        currentBai
      };

      // Xây dựng breadcrumbs phân cấp
      this.buildBreadcrumbs(nodeMap, objCurrent);

      // Xây dựng cấu trúc cây đa tầng và tự động mở các nhánh cha của bài hiện tại
      this.treeMucLuc = this.buildTreeStructure(flatList);
      if (this.NoiDungID && this.treeMucLuc.length > 0) {
        this.expandToSelected(this.treeMucLuc, this.NoiDungID);
      } else if (this.treeMucLuc.length > 0 && this.openedNodeIds.length === 0) {
        this.expandFirstChapter(this.treeMucLuc);
      }

      // Cập nhật vị trí trang hiện tại dựa trên danh sách tất cả các bài học/câu hỏi/tài liệu có nội dung thực tế
      const allActivities = this.getValidActivities();
      const currentIndex = allActivities.findIndex(x => String(x.NoiDungID) === String(this.NoiDungID));
      const firstGroupActivity = currentIndex < 0 ? this.getFirstActivityInGroup(this.NoiDungID) : null;
      const fallbackIndex = firstGroupActivity
        ? allActivities.findIndex(x => String(x.NoiDungID) === String(firstGroupActivity.NoiDungID))
        : -1;
      this.lenCurrentNoiDung = currentIndex >= 0 ? currentIndex : (fallbackIndex >= 0 ? fallbackIndex : 0);
      this.lenDetailNoiDung = allActivities.length;

      this.updateDisplayTreeList();
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

    buildTreeStructure(flatList) {
      if (!flatList || !Array.isArray(flatList)) return [];
      const isTeacher = this.isUserTeacher();
      const nodeMap = new Map();
      const roots = [];

      flatList.forEach(item => {
        let dataObj = {};
        if (item.DataJson) {
          if (typeof item.DataJson === 'object') dataObj = item.DataJson;
          else {
            try { dataObj = JSON.parse(item.DataJson) || {}; } catch (e) {}
          }
        }
        const isTeacherOnly = Boolean(item.IsTeacherOnly || dataObj.isTeacherOnly || dataObj.IsTeacherOnly || dataObj.chiGiaoVien || dataObj.ChiGiaoVien);

        // Nếu là Học sinh: Bỏ qua không đưa node Chỉ giáo viên vào cây học liệu
        if (!isTeacher && isTeacherOnly) {
          return;
        }

        nodeMap.set(item.NoiDungID, { ...item, IsTeacherOnly: isTeacherOnly, children: [] });
      });

      nodeMap.forEach(node => {
        if (node.ParentID && nodeMap.has(node.ParentID)) {
          nodeMap.get(node.ParentID).children.push(node);
        } else if (!node.ParentID || !nodeMap.has(node.ParentID)) {
          if (!node.ParentID) {
            roots.push(node);
          }
        }
      });

      const sortNodes = (nodes) => {
        if (!nodes) return;
        nodes.sort((a, b) => (a.ThuTu || 0) - (b.ThuTu || 0));
        nodes.forEach(node => {
          if (node.children && node.children.length > 0) {
            sortNodes(node.children);
          }
        });
      };
      sortNodes(roots);
      return roots;
    },

    isNodeOpen(node) {
      if (!node || !Array.isArray(this.openedNodeIds)) return false;
      return this.openedNodeIds.some(id => String(id) === String(node.NoiDungID));
    },

    toggleNodeCollapse(node) {
      if (!node) return;
      const nodeId = String(node.NoiDungID);
      if (this.isNodeOpen(node)) {
        this.openedNodeIds = this.openedNodeIds.filter(id => String(id) !== nodeId);
      } else {
        this.openedNodeIds = [...this.openedNodeIds, node.NoiDungID];
      }
      this.updateDisplayTreeList();
    },

    expandToSelected(nodes, targetId) {
      if (!nodes || !targetId) return;
      const findPath = (currentNodes, target, path = []) => {
        for (const n of currentNodes) {
          const newPath = [...path, n.NoiDungID];
          if (String(n.NoiDungID) === String(target)) {
            return newPath;
          }
          if (n.children && n.children.length > 0) {
            const found = findPath(n.children, target, newPath);
            if (found) return found;
          }
        }
        return null;
      };

      const path = findPath(nodes, targetId);
      if (path && path.length > 0) {
        const setIds = new Set(this.openedNodeIds);
        path.forEach(id => setIds.add(id));
        this.openedNodeIds = Array.from(setIds);
      } else {
        this.expandFirstChapter(nodes);
      }
    },

    expandFirstChapter(nodes) {
      if (!nodes || nodes.length === 0) return;
      const first = nodes[0];
      const opened = [first.NoiDungID];
      if (first.children && first.children.length > 0) {
        first.children.forEach(c => {
          if (c.children && c.children.length > 0) opened.push(c.NoiDungID);
        });
      }
      this.openedNodeIds = opened;
    },

    getNodeIcon(loai, isOpen = false) {
      const type = String(loai || '').toUpperCase();
      if (type === 'CHUONG') {
        return isOpen ? 'mdi-folder-open' : 'mdi-folder';
      }
      if (type === 'BAI') {
        return isOpen ? 'mdi-book-open-page-variant' : 'mdi-book-outline';
      }
      if (type === 'NHOM_KY_NANG') {
        return isOpen ? 'mdi-bookmark-box-multiple' : 'mdi-bookmark-outline';
      }
      switch (type) {
        case 'VIDEO': return 'mdi-video';
        case 'ISPRING_CONTENT': return 'mdi-presentation-play';
        case 'HTML':
        case 'READING': return 'mdi-file-document-outline';
        default:
          if (type.startsWith('QUIZ')) return 'mdi-help-circle-outline';
          return 'mdi-file-outline';
      }
    },

    updateDisplayTreeList() {
      const search = (this.treeSearch || '').trim().toLowerCase();
      const roots = this.treeMucLuc || [];

      const result = [];
      const traverse = (nodes, depth) => {
        for (const node of nodes) {
          const hasChildren = Array.isArray(node.children) && node.children.length > 0;
          const isCurrent = String(node.NoiDungID) === String(this.NoiDungID);
          const isOpen = this.isNodeOpen(node);
          const icon = this.getNodeIcon(node.LoaiNoiDung, isOpen);

          result.push({
            node: node,
            depth: depth,
            icon: icon,
            hasChildren: hasChildren,
            isCurrent: isCurrent,
            childCount: hasChildren ? node.children.length : 0
          });

          // Nếu có con và nhánh đang được mở (hoặc đang tìm kiếm) -> duyệt tiếp các cấp con
          if (hasChildren && (isOpen || search !== '')) {
            traverse(node.children, depth + 1);
          }
        }
      };

      traverse(roots, 0);

      if (search) {
        this.displayTreeList = result.filter(item => item.node.TenNoiDung && item.node.TenNoiDung.toLowerCase().includes(search));
      } else {
        this.displayTreeList = result;
      }
    },

    handleTreeNodeClick(node) {
      if (!node || !node.NoiDungID) return;

      // Nếu node là mục cha có con (Chương/Bài không có dữ liệu trực tiếp) -> toggle đóng/mở nhánh
      const hasChildren = Array.isArray(node.children) && node.children.length > 0;
      if (hasChildren && this.isNavigationGroup(node)) {
        this.toggleNodeCollapse(node);
        // Luôn mở hoạt động đầu tiên bên trong nhóm, kể cả khi node cha có DataJson rỗng/null.
        const target = this.getFirstActivityInGroup(node.NoiDungID);
        if (target && target.NoiDungID && String(target.NoiDungID) !== String(this.NoiDungID)) {
          this.NoiDungID = target.NoiDungID;
          this.lessonId = target.NoiDungID;
          this.pushState('noidungid', target.NoiDungID);
          this.renderDataPage();
          this.loadLessonDetail(target.NoiDungID);
          // Đóng drawer trên mobile & tablet (< 960px = Vuetify md breakpoint) để không che nội dung
          if (typeof window !== 'undefined' && window.innerWidth < 960) {
            this.showMucLucDrawer = false;
          }
        }
        return;
      }

      // Nếu node là bài/hoạt động xem được -> chuyển sang bài đó
      this.NoiDungID = node.NoiDungID;
      this.lessonId = node.NoiDungID;
      this.pushState('noidungid', node.NoiDungID);
      this.renderDataPage();
      this.loadLessonDetail(node.NoiDungID);

      // Trên mobile & tablet (< 960px): tự động đóng Drawer để xem nội dung
      if (typeof window !== 'undefined' && window.innerWidth < 960) {
        this.showMucLucDrawer = false;
      }
    },

    buildBreadcrumbs(nodeMap, currentObj) {
      if (!currentObj) {
        this.breadcrumbs = [];
        return;
      }
      const crumbs = [];
      let curr = currentObj;
      while (curr) {
        let icon = 'mdi-file-document-outline';
        if (curr.LoaiNoiDung === 'CHUONG') icon = 'mdi-folder-outline';
        else if (curr.LoaiNoiDung === 'BAI') icon = 'mdi-book-outline';
        else if (curr.LoaiNoiDung === 'NHOM_KY_NANG') icon = 'mdi-bookmark-outline';

        crumbs.unshift({
          id: curr.NoiDungID,
          title: curr.TenNoiDung,
          icon: icon,
          isCurrent: String(curr.NoiDungID) === String(this.NoiDungID)
        });

        if (curr.ParentID && nodeMap.has(curr.ParentID)) {
          curr = nodeMap.get(curr.ParentID);
        } else {
          curr = null;
        }
      }
      this.breadcrumbs = crumbs;
    },

    getValidActivities() {
      const flatList = this.DetailNoiDung;
      if (!flatList || !Array.isArray(flatList)) return [];

      const tree = (this.treeMucLuc && this.treeMucLuc.length > 0)
        ? this.treeMucLuc
        : this.buildTreeStructure(flatList);

      const result = [];
      const traverse = (nodes) => {
        for (const node of nodes) {
          const hasChildren = Array.isArray(node.children) && node.children.length > 0;
          // Loại bỏ các nhóm tạo mục phân cấp để progress và nút chuyển bài chỉ tính hoạt động thực tế.
          const isCategoryGroup = this.isNavigationGroup(node);

          if (!isCategoryGroup) {
            // Chỉ lấy các node bài học/hoạt động/câu hỏi/tài liệu thực tế
            result.push(node);
          }

          if (hasChildren) {
            traverse(node.children);
          }
        }
      };

      traverse(tree);
      return result;
    },

    isNavigationGroup(node) {
      if (!node || !Array.isArray(node.children) || node.children.length === 0) return false;
      return ['CHUONG', 'NHOM_KY_NANG', 'BAI'].includes(String(node.LoaiNoiDung || '').toUpperCase());
    },

    findTreeNode(nodes, targetId) {
      for (const node of nodes || []) {
        if (String(node.NoiDungID) === String(targetId)) return node;
        const found = this.findTreeNode(node.children, targetId);
        if (found) return found;
      }
      return null;
    },

    getFirstActivityInGroup(groupId) {
      const flatList = Array.isArray(this.DetailNoiDung) ? this.DetailNoiDung : [];
      const descendantIds = new Set();
      const collectDescendants = (parentId) => {
        flatList
          .filter(item => String(item.ParentID) === String(parentId))
          .forEach(child => {
            descendantIds.add(String(child.NoiDungID));
            collectDescendants(child.NoiDungID);
          });
      };

      collectDescendants(groupId);
      return this.getValidActivities().find(item => descendantIds.has(String(item.NoiDungID))) || null;
    },

    // === 3. ĐIỀU HƯỚNG & CÁC CHỨC NĂNG TƯƠNG TÁC ===
    increasePage() {
      const activities = this.getValidActivities();
      if (!activities || activities.length === 0) return;

      const currentIndex = activities.findIndex(x => String(x.NoiDungID) === String(this.NoiDungID));
      let nextIndex = 0;
      if (currentIndex >= 0) {
        if (currentIndex + 1 >= activities.length) return; // Đã ở bài cuối cùng của học liệu
        nextIndex = currentIndex + 1;
      } else {
        // Nếu đang đứng ở node nhóm, đi vào hoạt động đầu tiên của chính nhóm đó thay vì quay về đầu học liệu.
        const firstGroupActivity = this.getFirstActivityInGroup(this.NoiDungID);
        const groupIndex = firstGroupActivity
          ? activities.findIndex(x => String(x.NoiDungID) === String(firstGroupActivity.NoiDungID))
          : -1;
        nextIndex = groupIndex >= 0 ? groupIndex : 0;
      }

      const nextObj = activities[nextIndex];
      if (!nextObj) return;

      this.NoiDungID = nextObj.NoiDungID;
      this.lessonId = nextObj.NoiDungID;
      this.pushState('noidungid', nextObj.NoiDungID);
      this.renderDataPage();
      this.loadLessonDetail(nextObj.NoiDungID);
    },

    decreasePage() {
      const activities = this.getValidActivities();
      if (!activities || activities.length === 0) return;

      const currentIndex = activities.findIndex(x => String(x.NoiDungID) === String(this.NoiDungID));
      const firstGroupActivity = currentIndex < 0 ? this.getFirstActivityInGroup(this.NoiDungID) : null;
      const effectiveCurrentIndex = currentIndex >= 0
        ? currentIndex
        : activities.findIndex(x => String(x.NoiDungID) === String(firstGroupActivity?.NoiDungID));
      if (effectiveCurrentIndex <= 0) return; // Đã ở bài đầu tiên của học liệu

      const prevObj = activities[effectiveCurrentIndex - 1];
      if (!prevObj) return;

      this.NoiDungID = prevObj.NoiDungID;
      this.lessonId = prevObj.NoiDungID;
      this.pushState('noidungid', prevObj.NoiDungID);
      this.renderDataPage();
      this.loadLessonDetail(prevObj.NoiDungID);
    },

    toggleMucLucDrawer() {
      this.showMucLucDrawer = !this.showMucLucDrawer;
      if (this.showMucLucDrawer && this.DetailNoiDung) {
        this.updateDisplayTreeList();
      }
    },

    togglePresentationFullscreen() {
      if (!document.fullscreenElement) {
        const rootEl = document.documentElement;
        const rfs = rootEl.requestFullscreen || rootEl.webkitRequestFullscreen || rootEl.msRequestFullscreen;
        if (rfs) {
          rfs.call(rootEl).then(() => {
            this.isPresentationFullscreen = true;
          }).catch(err => {
            console.warn('Fullscreen request error:', err);
          });
        }
      } else {
        const efs = document.exitFullscreen || document.webkitExitFullscreen || document.msExitFullscreen;
        if (efs) {
          efs.call(document).then(() => {
            this.isPresentationFullscreen = false;
          }).catch(err => {
            console.warn('Exit fullscreen error:', err);
          });
        }
      }
    },

    onFullscreenChange() {
      this.isPresentationFullscreen = !!document.fullscreenElement;
    },

    handleKeyDown(e) {
      const tag = (e.target && e.target.tagName) ? e.target.tagName.toUpperCase() : '';
      if (tag === 'INPUT' || tag === 'TEXTAREA' || (e.target && e.target.isContentEditable)) {
        return;
      }

      if (e.key === 'ArrowRight' || e.key === 'PageDown' || e.code === 'Space') {
        this.increasePage();
        e.preventDefault();
      } else if (e.key === 'ArrowLeft' || e.key === 'PageUp') {
        this.decreasePage();
        e.preventDefault();
      } else if (e.key === 'f' || e.key === 'F') {
        this.togglePresentationFullscreen();
        e.preventDefault();
      } else if (e.key === 'm' || e.key === 'M') {
        this.toggleMucLucDrawer();
        e.preventDefault();
      }
    },

    initTouchGestures() {
      const container = this.$refs.slideContainer || document.querySelector('.lh-slide-container');
      if (!container) return;

      container.addEventListener('touchstart', (e) => {
        if (e.touches && e.touches[0]) {
          this.touchStartX = e.touches[0].clientX;
          this.touchStartY = e.touches[0].clientY;
          this.touchStartTarget = e.target;
        }
      }, { passive: true });

      container.addEventListener('touchend', (e) => {
        if (!this.touchStartX || !this.touchStartY) return;
        if (this.touchStartTarget && this.touchStartTarget.closest('.lh-matching, .lh-ordering, .lh-quiz-content-single, .lh-matching-item-b, .lh-matching-dropzone, button, input, textarea')) {
          this.touchStartX = 0;
          this.touchStartY = 0;
          this.touchStartTarget = null;
          return;
        }
        const endX = e.changedTouches && e.changedTouches[0] ? e.changedTouches[0].clientX : this.touchStartX;
        const endY = e.changedTouches && e.changedTouches[0] ? e.changedTouches[0].clientY : this.touchStartY;
        const diffX = this.touchStartX - endX;
        const diffY = this.touchStartY - endY;

        if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 80) {
          if (diffX > 0) {
            this.increasePage();
          } else {
            this.decreasePage();
          }
        }
        this.touchStartX = 0;
        this.touchStartY = 0;
        this.touchStartTarget = null;
      }, { passive: true });
    },

    goBack() {
      const urlParams = new URLSearchParams(window.location.search);
      const hocSinhId = urlParams.get('HocSinhID') || urlParams.get('hocSinhId') || '';
      let targetUrl = `/chi-tiet-hoc-lieu?id=${this.HocLieuID || ''}&noidungid=${this.NoiDungID || ''}`;
      if (hocSinhId) {
        targetUrl += `&HocSinhID=${encodeURIComponent(hocSinhId)}`;
      }
      if (typeof redirect === 'function') {
        redirect(targetUrl);
      } else {
        window.location.href = targetUrl;
      }
    },

    pushState(key, value) {
      const currentUrl = window.location.href;
      const url = new URL(currentUrl);
      url.searchParams.set(key, value);
      window.history.replaceState({}, '', url.href);
    },

    isPureHTMLString(str) {
      try {
        JSON.parse(str);
        return false;
      } catch {
        const el = document.createElement('div');
        el.innerHTML = str.trim();
        return el.childNodes.length > 0 && [...el.childNodes].some(n => n.nodeType === 1);
      }
    },

    normalizeQuizSlideContent(rawContent, lessonTitle, slideType) {
      const value = rawContent && typeof rawContent === 'object' ? rawContent : {};
      const config = value.config && typeof value.config === 'object' ? value.config : {};
      const directContent = value.content && typeof value.content === 'object' ? value.content : {};
      const nestedContent = config.content && typeof config.content === 'object' ? config.content : {};
      const question = value.question && typeof value.question === 'object' ? value.question : {};
      const questionContent = question.content && typeof question.content === 'object' ? question.content : {};
      const content = { ...config, ...value, ...directContent, ...questionContent, ...nestedContent };

      const firstVal = [content.prompt, content.questionText, question.prompt, question.questionText, config.prompt, lessonTitle].find(v => v !== null && v !== undefined && String(v).trim() !== '') || '';
      content.prompt = typeof firstVal === 'object' ? (firstVal.html || firstVal.content || firstVal.text || '') : String(firstVal);
      content.questionText = content.questionText || content.prompt;

      if (String(slideType || '').toUpperCase() === 'QUIZ_FILL_IN_BLANK') {
        const parts = [content.parts, directContent.parts, nestedContent.parts, config.parts, questionContent.parts, question.parts].find(c => Array.isArray(c)) || [];
        content.parts = parts.map((part, index) => {
          const item = part && typeof part === 'object' ? part : { type: 'text', value: part };
          const isBlank = String(item.type || '').toLowerCase() === 'blank' || item.isBlank === true;
          if (!isBlank) {
            return { ...item, type: 'text', value: String(item.value || item.text || item.content || '') };
          }
          const acceptedAnswers = Array.isArray(item.acceptedAnswers) ? item.acceptedAnswers : String(item.correctAnswer || item.answer || '').split('/').filter(Boolean);
          const correctAnswer = String(item.correctAnswer || item.answer || acceptedAnswers[0] || '').trim();
          return {
            ...item,
            type: 'blank',
            id: item.id || `blank_${index + 1}`,
            correctAnswer,
            acceptedAnswers: acceptedAnswers.length ? acceptedAnswers : (correctAnswer ? [correctAnswer] : [])
          };
        });
      }
      return content;
    }
  }
  };
  Vue.component("uc-main-layout", compDef);
})();

;(function() {
  const compDef = {
    template: `<div v-if="slideData && slideData.content" class="lh-slide-viewer">

		<!-- ==================== QUIZ_COMPOSITE (Bài kiểm tra tổng hợp) ==================== -->
		<uc-quiz-composite v-if="slideData.type === 'QUIZ_COMPOSITE' && slideData.content" :slide-data="slideData"
			@quiz-result="$emit('quiz-result', $event)"
			@quiz-completed="$emit('quiz-result', $event)" />

		<!-- ==================== CÁC LOẠI SLIDE ĐƠN LẺ KHÁC ==================== -->
		<div v-else class="lh-single-slide">

			<!--
				Một số học liệu lưu URL Canva/Google trong DataJson nhưng vẫn gắn LoaiNoiDung là
				READING hoặc HTML. Phải ưu tiên viewer ngoài trước nhánh HTML, nếu không URL sẽ bị
				xem như text và render nguyên chuỗi link ở giữa màn hình.
			-->
			<div v-if="externalDocumentUrl" class="lh-external-document-viewer fill-height pa-0 ma-0 w-100">
				<uc-office-reader :file-url="externalDocumentUrl" ></uc-office-reader>
			</div>

			<!-- Reading / HTML Content với Fullscreen Button & Full Viewport Optimization -->
			<div v-else-if="['HTML', 'READING', 'ReadingWithImage'].includes(slideData.type)" class="lh-reading-slide fill-height pa-0 ma-0">
				<!-- Chỉ hiện header phụ nếu là bài đọc dạng văn bản thuần không có khung canvas riêng -->
				<div class="lh-slide-header px-3 pt-2" v-if="slideData.content && slideData.content.title && slideData.type === 'READING' && !slideData.content.htmlContent">
					<h1 class="lh-slide-title">{{ slideData.content.title }}</h1>
					<p v-if="slideData.content.author" class="lh-slide-author">{{ slideData.content.author }}</p>
				</div>

				<div class="lh-reading-content fill-height pa-0 ma-0">
					<!-- Iframe Container với Fullscreen Button & Zoom Controls -->
					<div class="lh-iframe-container fill-height pa-0 ma-0 position-relative" v-if="getDisplayHtmlContent">
						<div v-if="slideData.content && (slideData.content.isType === 'rich' || (!slideData.content.htmlContent && getDisplayHtmlContent))" class="lh-reading-iframe fill-height pa-0 ma-0"
							:style="contentZoomStyle"
							v-html="cleanHtml(getDisplayHtmlContent)" />
						<iframe v-else :srcdoc="cleanIframeHtml(getDisplayHtmlContent)"
							sandbox="allow-scripts allow-popups allow-forms allow-same-origin allow-downloads" class="lh-reading-iframe fill-height"
							ref="htmlContentIframe"
							@load="applyZoomToIframe">
						</iframe>

						<!-- Floating Tools: Zoom -, Zoom %, Zoom +, Fullscreen -->
						<div class="lh-floating-controls" :class="{ 'lh-controls-fullscreen': isFullscreen }">
							<button class="lh-tool-btn" @click="zoomOut" title="Thu nhỏ (Zoom - / Phím -)" :disabled="zoomLevel <= 0.5">
								<v-icon size="16">mdi-magnify-minus-outline</v-icon>
							</button>
							<button class="lh-tool-btn lh-zoom-badge" @click="resetZoom" title="Đặt lại kích thước chuẩn (100% / Phím 0)">
								{{ Math.round(zoomLevel * 100) }}%
							</button>
							<button class="lh-tool-btn" @click="zoomIn" title="Phóng to (Zoom + / Phím +)" :disabled="zoomLevel >= 2.5">
								<v-icon size="16">mdi-magnify-plus-outline</v-icon>
							</button>
							<div class="lh-tool-divider"></div>
							<button class="lh-tool-btn lh-fullscreen-toggle-btn" @click="toggleFullscreen"
								:title="isFullscreen ? 'Thoát toàn màn hình (Esc)' : 'Toàn màn hình'">
								<v-icon size="18">{{ isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
							</button>
						</div>
					</div>

					<!-- Empty HTML State (khi nội dung HTML rỗng) -->
					<div v-else class="lh-empty-state-card pa-8 my-auto text-center">
						<div class="lh-empty-state-icon-wrapper">
							<v-icon size="44" color="primary">mdi-text-box-remove-outline</v-icon>
						</div>
						<h3 class="lh-empty-state-title mt-3">{{ (slideData.content && slideData.content.title) || 'Chưa có nội dung văn bản' }}</h3>
						<p class="lh-empty-state-desc mt-2">Nội dung bài đọc đang được cập nhật hoặc chưa có dữ liệu hiển thị.</p>
						<div class="lh-empty-state-actions mt-4 d-flex justify-center gap-2">
							<v-btn color="primary" variant="flat" size="small" prepend-icon="mdi-format-list-bulleted-square" @click="$emit('open-toc')">
								Mở mục lục
							</v-btn>
							<v-btn color="secondary" variant="tonal" size="small" append-icon="mdi-chevron-right" @click="$emit('next')">
								Bài tiếp theo
							</v-btn>
						</div>
					</div>

					<img v-if="slideData.content && slideData.content.image" :src="slideData.content.image" class="lh-reading-image" :style="contentZoomStyle" />
				</div>
			</div>

			<div v-else-if="slideData.type === 'ISPRING_CONTENT'" class="lh-ispring-slide">
				<div class="lh-slide-header" v-if="slideData.content.title">
					<h1 class="lh-slide-title">
						<v-icon size="20" class="mr-1 text-primary">mdi-book-open-page-variant</v-icon>
						{{ slideData.content.title }}
					</h1>
					<p v-if="slideData.content.description" class="lh-slide-description">{{
						slideData.content.description }}</p>
				</div>

				<div class="lh-ispring-content">
					<!-- iSpring Iframe Container -->
					<div class="lh-iframe-container" v-if="slideData.content.iSpringURL">
						<iframe :src="slideData.content.iSpringURL" class="lh-ispring-iframe" ref="iSpringContentIframe"
							:style="contentZoomStyle"
							frameborder="0" allowfullscreen
							sandbox="allow-scripts  allow-forms allow-popups allow-modals" @load="oniSpringLoad"
							@error="oniSpringError">
						</iframe>

						<!-- Floating Tools: Zoom -, Zoom %, Zoom +, Fullscreen -->
						<div class="lh-floating-controls" :class="{ 'lh-controls-fullscreen': isiSpringFullscreen }">
							<button class="lh-tool-btn" @click="zoomOut" title="Thu nhỏ (Zoom - / Phím -)" :disabled="zoomLevel <= 0.5">
								<v-icon size="16">mdi-magnify-minus-outline</v-icon>
							</button>
							<button class="lh-tool-btn lh-zoom-badge" @click="resetZoom" title="Đặt lại kích thước chuẩn (100% / Phím 0)">
								{{ Math.round(zoomLevel * 100) }}%
							</button>
							<button class="lh-tool-btn" @click="zoomIn" title="Phóng to (Zoom + / Phím +)" :disabled="zoomLevel >= 2.5">
								<v-icon size="16">mdi-magnify-plus-outline</v-icon>
							</button>
							<div class="lh-tool-divider"></div>
							<button class="lh-tool-btn lh-fullscreen-toggle-btn" @click="toggleiSpringFullscreen"
								:title="isiSpringFullscreen ? 'Thoát toàn màn hình (Esc)' : 'Toàn màn hình'">
								<v-icon size="18">{{ isiSpringFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
							</button>
						</div>
					</div>

					<!-- Error State -->
					<div v-else-if="slideData.content.error" class="lh-ispring-error">
						<div class="lh-error-icon">
							<v-icon size="36" color="error">mdi-alert-circle-outline</v-icon>
						</div>
						<h3>Không thể tải nội dung iSpring</h3>
						<p>{{ slideData.content.error }}</p>
						<v-btn color="primary" variant="tonal" size="small" @click="retryiSpringLoad">
							<v-icon start>mdi-refresh</v-icon> Thử lại
						</v-btn>
					</div>

					<!-- No Content State -->
					<div v-else class="lh-ispring-placeholder">
						<div class="lh-placeholder-icon">
							<v-icon size="36" class="text-medium-emphasis">mdi-file-document-outline</v-icon>
						</div>
						<h3>iSpring Content</h3>
						<p>Nội dung iSpring chưa được thiết lập</p>
					</div>
				</div>
			</div>

			<!-- VIDEO -->
			<div v-else-if="isVideoSlide" class="lh-video-slide">
				<!-- Data cũ có thể gắn AUDIO nhưng metadata/url là video; dùng source đã chuẩn hóa để vào đúng player. -->
				<uc-media-player :url="mediaSourceUrl"
					:title="slideData.content.title" :interactions="slideData.content.timerMarkers || slideData.content.interactions || []" />
			</div>

			<!-- IMAGE -->
			<div v-else-if="slideData.type === 'IMAGE'" class="lh-image-slide-wrapper fill-height w-100 pa-0 ma-0">
				<div class="lh-image-slide-content fill-height w-100 d-flex align-center justify-center position-relative pa-3">
					<div class="lh-floating-controls" v-if="imageSourceUrl" :class="{ 'lh-controls-fullscreen': isFullscreen }">
						<button class="lh-tool-btn" @click="zoomOut" title="Thu nhỏ (Zoom - / Phím -)" :disabled="zoomLevel <= 0.5">
							<v-icon size="16">mdi-magnify-minus-outline</v-icon>
						</button>
						<button class="lh-tool-btn lh-zoom-badge" @click="resetZoom" title="Đặt lại kích thước chuẩn (100% / Phím 0)">
							{{ Math.round(zoomLevel * 100) }}%
						</button>
						<button class="lh-tool-btn" @click="zoomIn" title="Phóng to (Zoom + / Phím +)" :disabled="zoomLevel >= 2.5">
							<v-icon size="16">mdi-magnify-plus-outline</v-icon>
						</button>
						<div class="lh-tool-divider"></div>
						<button class="lh-tool-btn lh-fullscreen-toggle-btn" @click="toggleFullscreen"
							:title="isFullscreen ? 'Thoát toàn màn hình (Esc)' : 'Toàn màn hình'">
							<v-icon size="18">{{ isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
						</button>
					</div>
					<img v-if="imageSourceUrl" :src="imageSourceUrl" :alt="slideData.content.title || 'Hình ảnh học liệu'" class="lh-reading-image" :style="contentZoomStyle" />
					<div v-else class="lh-unsupported">Chưa có URL hình ảnh.</div>
				</div>
			</div>

			<!-- ==================== AUDIO ==================== -->
			<div v-else-if="isAudioSlide">
				<!-- Audio phải dùng URL file trực tiếp; Office Reader không phát được link mp3 từ Content Hub. -->
				<audio v-if="audioSourceUrl" :src="audioSourceUrl" controls class="w-100" />
				<div v-else class="lh-unsupported">Chưa có URL audio.</div>
			</div>

			<!-- Single Quiz Types -->
			<div v-else-if="slideData.type.startsWith('QUIZ')" class="lh-quiz-single"
				:class="'lh-quiz-' + slideData.type.toLowerCase().replace('quiz_', '')">

				<!-- Quiz Header -->
				<div class="lh-quiz-header">
					<div class="lh-quiz-type-badge">{{ getQuestionTypeLabel(slideData.type) }}</div>
					<div v-if="isQuiz && slideData.type !== 'QUIZ_COMPOSITE'" class="lh-header-actions">
						<button class="lh-header-btn lh-btn-hint" @click="showHint" title="Gợi ý">
							<v-icon size="16" class="mr-1">mdi-lightbulb-outline</v-icon>
							<span>Gợi ý</span>
						</button>
						<button class="lh-header-btn lh-btn-check" @click="checkAnswer" title="Kiểm tra">
							<v-icon size="16" class="mr-1 text-white">mdi-check-circle-outline</v-icon>
							<span>Nộp bài</span>
						</button>
					</div>
				</div>

				<!-- Quiz Content -->
				<div class="lh-quiz-content-single">

					<!-- SingleChoice -->
					<div v-if="slideData.type === 'QUIZ_SINGLE_CHOICE'" class="lh-single-choice">
						<uc-latex-view class="lh-question-prompt" :content="slideData.content.prompt" ></uc-latex-view>
						<div class="lh-options-grid">
							<label v-for="option in slideData.content.options" :key="option.id" class="lh-option-card"
								:class="[getOptionClass(option.id), { 'lh-selected': userAnswers.singleChoice === option.id }]">
								<input type="radio" :value="option.id" v-model="userAnswers.singleChoice"
									class="lh-option-input">
								<div class="lh-option-content">
									<div class="lh-option-indicator"></div>
									<uc-latex-view class="lh-option-text" :content="option.text" ></uc-latex-view>
								</div>
							</label>
						</div>
					</div>

					<!-- MultipleChoice -->
					<div v-else-if="slideData.type === 'QUIZ_MULTIPLE_CHOICE'" class="lh-multiple-choice">
						<uc-latex-view class="lh-question-prompt" :content="slideData.content.prompt" ></uc-latex-view>
						<div class="lh-options-grid">
							<label v-for="option in slideData.content.options" :key="option.id"
								class="lh-option-card lh-checkbox-card"
								:class="[getOptionClass(option.id), { 'lh-selected': userAnswers.multipleChoice.includes(option.id) }]">
								<input type="checkbox" :value="option.id" v-model="userAnswers.multipleChoice"
									class="lh-option-input">
								<div class="lh-option-content">
									<div class="lh-checkbox-indicator">
										<v-icon size="13" color="white" class="lh-checkmark">mdi-check</v-icon>
									</div>
									<uc-latex-view class="lh-option-text" :content="option.text" ></uc-latex-view>
								</div>
							</label>
						</div>
					</div>

					<!-- Ordering -->
					<div v-else-if="slideData.type === 'QUIZ_ORDERING'" class="lh-ordering">
						<uc-latex-view class="lh-question-prompt" :content="slideData.content.prompt" ></uc-latex-view>
						<div class="lh-ordering-hint">
							<v-icon size="16" class="mr-1 text-primary">mdi-information-outline</v-icon>
							<span>Kéo thả để sắp xếp theo thứ tự đúng</span>
						</div>
						<div class="lh-ordering-container" ref="orderingContainer">
							<div v-for="(item, index) in userAnswers.ordering" :key="item.id" class="lh-ordering-item"
								:data-id="item.id">
								<div class="lh-ordering-handle">
									<span class="lh-ordering-number">{{ index + 1 }}</span>
									<span class="lh-drag-icon">⋮⋮</span>
								</div>
								<uc-latex-view class="lh-ordering-text" :content="item.text" ></uc-latex-view>
							</div>
						</div>
					</div>

					<!-- Matching (Ghép nối) -->
					<div v-else-if="slideData.type === 'QUIZ_MATCHING'" class="lh-matching">
						<uc-latex-view class="lh-question-prompt" :content="slideData.content.prompt || 'Nối các mục ở cột A với cột B cho phù hợp:'" ></uc-latex-view>
						<div class="lh-matching-container">
							<div class="lh-matching-column lh-column-a">
								<div class="lh-column-title">Cột A</div>
								<div
									v-for="itemA in slideData.content.columnA"
									:key="itemA.id"
									class="lh-matching-pair-row"
								>
									<div class="lh-matching-item-a">
										<uc-latex-view :content="itemA.text" ></uc-latex-view>
									</div>
									<div class="lh-matching-dropzone" :data-item-a-id="itemA.id" ref="matchingDropzones">
										<div class="lh-dropzone-placeholder">Thả Cột B vào đây</div>
									</div>
								</div>
							</div>
							<div class="lh-matching-column lh-column-b">
								<div class="lh-column-title">Cột B</div>
								<div class="lh-matching-list" ref="matchingBContainer">
									<div
										v-for="itemB in userAnswers.matching"
										:key="itemB.id"
										class="lh-matching-item-b"
										:data-id="itemB.id"
										@pointerdown="startMatchingPointerDrag($event, itemB)"
									>
										<span class="lh-drag-icon">⋮⋮</span>
										<uc-latex-view class="lh-matching-text" :content="itemB.text" ></uc-latex-view>
									</div>
								</div>
								<div v-if="remainingBCount === 0" class="lh-column-b-empty">
									<v-icon size="16" color="success" class="mr-1">mdi-check-circle</v-icon> Đã ghép hết
								</div>
							</div>
						</div>
					</div>

					<!-- Categorize (Kéo-thả Phân loại) -->
					<div v-else-if="slideData.type === 'QUIZ_DRAG_DROP_CATEGORIZE'" class="lh-categorize">
						<uc-latex-view class="lh-question-prompt" :content="slideData.content.prompt" ></uc-latex-view>
						<div class="lh-source-pool">
							<div class="lh-pool-title">
								<v-icon size="16" class="mr-1 text-primary">mdi-package-variant-closed</v-icon>
								<span>Kéo từ đây:</span>
							</div>
							<div class="lh-items-container" ref="sourceContainer">
								<div v-for="item in unclassifiedItems" :key="item.id" class="lh-draggable-item"
									:data-id="item.id">
									<span class="lh-item-text">{{ item.text }}</span>
								</div>
							</div>
						</div>

						<div class="lh-categories-grid">
							<div v-for="category in slideData.content.categories" :key="category.id"
								class="lh-category-box">
								<div class="lh-category-header">
									<img v-if="isImage(category.name)" :src="category.name" alt="Category"
										class="lh-category-image">
									<span v-else class="lh-category-name">{{ category.name }}</span>
								</div>
								<div class="lh-category-dropzone" :data-category-id="category.id"
									ref="categoryContainers">
									<div class="lh-dropzone-hint">Thả vào đây</div>
								</div>
							</div>
						</div>
					</div>

					<!-- Fill in Blank -->
					<div v-else-if="slideData.type === 'QUIZ_FILL_IN_BLANK'" class="lh-fill-blank">
						<uc-latex-view class="lh-question-prompt" :content="slideData.content.prompt" ></uc-latex-view>
						<div class="lh-fill-container">
							<template v-for="(part, index) in slideData.content.parts" :key="index">
								<span v-if="part.type === 'text'" class="lh-fill-text">{{ part.value }}</span>
								<div v-if="part.type === 'blank'" class="lh-fill-input-wrapper">
									<input type="text" v-model="userAnswers.fillInTheBlank[part.id]"
										class="lh-fill-input"
										:style="{ width: Math.max((part.size || 10) * 12, 80) + 'px' }"
										:placeholder="'___'">
								</div>
							</template>
						</div>
					</div>

					<!-- Connection (Nối đường thẳng) -->
					<div v-else-if="slideData.type === 'QUIZ_CONNECTION'" class="lh-connection">
						<uc-latex-view class="lh-question-prompt" :content="slideData.content.prompt" ></uc-latex-view>
						<div class="lh-connection-instructions">
							<v-icon size="16" class="mr-1 text-primary">mdi-information-outline</v-icon>
							<span>Bước 1: Chọn nhóm bên trái → Bước 2: Chọn mục bên phải để nối</span>
						</div>

						<div class="lh-connection-parent-container" ref="connectionParent">
							<div class="lh-connection-container" ref="connectionContainer"
								style="position: relative;"
								@pointermove="userAnswers.connection.activeGroup ? onContainerPointerMove($event) : null">
								<svg class="lh-connection-lines-svg" ref="svgContainer"
									style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 2;">
									<line v-for="(line, index) in lines" :key="'line-' + index" :x1="line.x1" :y1="line.y1"
										:x2="line.x2" :y2="line.y2" :stroke="line.color" stroke-width="4"
										stroke-linecap="round" class="lh-connection-line" />
									<line v-if="tempLine"
										:x1="tempLine.x1" :y1="tempLine.y1" :x2="tempLine.x2" :y2="tempLine.y2"
										:stroke="tempLine.color" stroke-width="4" stroke-linecap="round" stroke-dasharray="6,6"
										class="lh-connection-line lh-temp-line" />
								</svg>
								<div class="lh-connection-column lh-groups-column">
									<div class="lh-connection-header">
										<v-icon size="16" class="mr-1 text-primary">mdi-tag-outline</v-icon>
										<span>Nhóm</span>
									</div>
									<div class="lh-connection-items">
										<div v-for="group in slideData.content.groups" :key="'group-' + group.id"
											:id="'connect-group-' + group.id" class="lh-connection-item lh-connection-group"
											:class="getGroupClass(group.id)"
											:style="{ backgroundColor: groupColors[group.id] }"
											@click="selectGroup(group.id)">
											<div class="lh-group-content">
												<span class="lh-group-text">{{ group.text }}</span>
												<span v-if="userAnswers.connection.activeGroup === group.id"
													class="lh-active-indicator">👆</span>
											</div>
										</div>
									</div>
								</div>

								<div class="lh-connection-column lh-items-column">
									<div class="lh-connection-header">
										<span class="lh-connection-icon">📝</span>
										<span>Mục</span>
									</div>
									<div class="lh-connection-items">
										<div v-for="item in slideData.content.items" :key="'item-' + item.id"
											:id="'connect-item-' + item.id"
											class="lh-connection-item lh-connection-item-target"
											:class="getItemClass(item.id)" @click="selectItem(item.id)">
											<div class="lh-item-content">
												<span class="lh-item-text">{{ item.text }}</span>
												<span v-if="getConnectionForItem(item.id)"
													class="lh-connected-indicator">🔗</span>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>

						<div v-if="userAnswers.connection.activeGroup" class="lh-connection-status">
							<span class="lh-status-icon">👉</span>
							<span>Đã chọn nhóm: <strong>{{ getGroupText(userAnswers.connection.activeGroup) }}</strong>
								- Giờ hãy chọn mục để nối!</span>
						</div>
					</div>

					<!-- QUIZ_TRUE_FALSE -->
					<div v-else-if="slideData.type === 'QUIZ_TRUE_FALSE'" class="lh-single-choice">
						<uc-latex-view class="lh-question-prompt" :content="slideData.content.prompt" ></uc-latex-view>
						<div class="lh-options-grid"
							style="grid-template-columns: repeat(auto-fit, minmax(700px, 1fr));">
							<label v-for="option in slideData.content.options" :key="option.id" class="lh-option-card"
								:class="[getOptionClass(option.id), { 'lh-selected': userAnswers.singleChoice === option.id }]">
								<v-select placeholder="Đúng/Sai..."
									:items="[{title: '✅ Đúng', value : true}, {title: '❌ Sai', value: false}]"
									item-title='title' item-value='value'
									@update:modelValue="(val) => {if(val) {option._correctAnswer = true; option._inCorrectAnswer = false }else{option._correctAnswer = false; option._inCorrectAnswer = true}}"
									:bg-color="option._correctAnswer == true ? 'success' : (option._correctAnswer === false ? 'error': 'white' )"
									style="min-width:150px" />
								<div class="lh-option-content">
									<uc-latex-view class="lh-option-text" :content="option.text" ></uc-latex-view>
								</div>
							</label>
						</div>
					</div>
				</div>
			</div>

			<!-- ==================== SLIDE VIEWER (PDF, Office, etc.) ==================== -->
			<!-- Đảm bảo chiếm trọn 100% chiều cao và chiều rộng khung nhìn, triệt tiêu khoảng trắng thừa ở dưới -->
			<div v-else-if="slideData.type === 'SLIDE'" class="lh-slide-viewer-container fill-height pa-0 ma-0 w-100">

				<!--
					File có nguồn LMS phải đi qua viewer nội bộ giống Content Hub để giữ đúng
					cách đọc FileData, toolbar và khả năng xử lý PDF/Office của hệ thống.
					File Drive/nguồn ngoài không có URL FileData sẽ tiếp tục dùng flow cũ.
				-->
				<div v-if="lmsDocumentViewerUrl" class="lh-lms-file-viewer-container fill-height pa-0 ma-0 w-100">
					<iframe
						:src="lmsDocumentViewerUrl"
						:title="slideData.content.title || slideData.content.fileName || 'Xem tài liệu LMS'"
						class="lh-lms-file-viewer"
						frameborder="0"
						allow="fullscreen"
						allowfullscreen
					></iframe>
				</div>

				<!-- 1. Render PDF Reader cho nguồn không phải LMS -->
				<div v-else-if="slideContentType === 'PDF'" class="lh-pdf-book-container fill-height pa-0 ma-0 w-100">
					<uc-office-reader :file-url="slideData.content.url" ></uc-office-reader>
				</div>
				<!-- 2. Render Office Reader cho nguồn không phải LMS -->
				<!-- DOC và DOCX đều phải đi qua Office viewer; không fallback về trạng thái chưa hỗ trợ. -->
				<div v-else-if="['DOC', 'DOCX', 'XLSX'].includes(slideContentType)" class="lh-pdf-book-container fill-height pa-0 ma-0 w-100">
					<uc-office-reader :file-url="slideData.content.url" :file-type="slideContentType" ></uc-office-reader>
				</div>
				<div v-else-if="slideContentType === 'PPT'" class="lh-pdf-book-container fill-height pa-0 ma-0 w-100">
					<uc-office-reader :file-url="slideData.content.url" file-type="PPT" ></uc-office-reader>
				</div>

				<!-- 3. Fallback cho loại slide chưa được hỗ trợ -->
				<div v-else class="unsupported-slide pa-6 text-center">
					<p>Loại tài liệu <strong>"{{ slideContentType || 'không xác định' }}"</strong> chưa được hỗ trợ xem trước.</p>
				</div>

			</div>

			<!-- Other content types -->
			<div v-else-if="slideData.type === 'RawHTML'" class="lh-raw-html" v-html="cleanHtml(slideData.content)"></div>

			<!-- ==================== EMPTY STATE / NỘI DUNG ĐANG CẬP NHẬT ==================== -->
			<!-- Hiển thị khi bài học/chương chưa có dữ liệu DataJson hoặc đang được biên tập -->
			<div v-else-if="slideData.type === 'EMPTY_STATE' || ['CHUONG', 'BAI', 'NHOM_KY_NANG'].includes(slideData.type)" class="lh-empty-state-view pa-6 d-flex align-center justify-center h-100">
				<div class="lh-empty-state-card text-center pa-8">
					<div class="lh-empty-state-icon-wrapper mb-3">
						<v-icon size="56" color="primary">mdi-book-open-blank-variant-outline</v-icon>
					</div>
					<div class="lh-empty-state-badge mb-2">
						<v-chip size="small" color="primary" variant="tonal" class="font-weight-bold">
							{{ getEmptyStateBadge(slideData) }}
						</v-chip>
					</div>
					<h2 class="lh-empty-state-title mt-1 text-h6 font-weight-bold text-slate-800">
						{{ (slideData.content && slideData.content.title) || 'Nội dung bài học' }}
					</h2>
					<p class="lh-empty-state-desc mt-2 text-body-2 text-slate-600" style="max-width: 480px; margin: 0 auto;">
						{{ (slideData.content && slideData.content.message) || 'Nội dung bài học đang được cập nhật hoặc chưa có nội dung bài giảng.' }}
					</p>
					<p class="lh-empty-state-subdesc mt-1 text-caption text-medium-emphasis">
						{{ isLastLesson ? 'Bạn đã đến bài cuối cùng của học liệu. Vui lòng chọn bài học khác từ danh sách mục lục.' : ((slideData.content && slideData.content.description) || 'Vui lòng chọn bài học khác từ mục lục hoặc bấm nút bên dưới để chuyển tiếp.') }}
					</p>
					<div class="lh-empty-state-actions mt-6 d-flex justify-center flex-wrap gap-2">
						<v-btn
							v-if="!isTocOpen"
							color="primary"
							variant="flat"
							class="lh-empty-btn-toc"
							prepend-icon="mdi-format-list-bulleted-square"
							@click="$emit('open-toc')"
						>
							Mở mục lục học liệu
						</v-btn>
						<v-btn
							v-if="!isLastLesson"
							color="secondary"
							variant="tonal"
							class="lh-empty-btn-next"
							append-icon="mdi-chevron-right"
							@click="$emit('next')"
						>
							Bài tiếp theo
						</v-btn>
					</div>
				</div>
			</div>

			<!-- Unsupported type -->
			<div v-else class="lh-unsupported">
				<div class="lh-unsupported-icon">❓</div>
				<p class="lh-unsupported-text">Loại hoạt động <strong>{{ slideData.type }}</strong> chưa được hỗ trợ.
				</p>
			</div>

			<!-- Explanation Block -->
			<div v-if="showExplanation && slideData.content.explanation" class="lh-explanation-block">
				<div class="lh-explanation-header">
					<span class="lh-explanation-icon">💡</span>
					<span class="lh-explanation-title">Hướng dẫn</span>
				</div>
				<div class="lh-explanation-content" v-html="cleanHtml(slideData.content.explanation)"></div>
			</div>



			<!-- Footer Controls for Single Slides - Simplified -->
			<div v-if="!isQuiz && isSubmitted && feedbackMessage" class="lh-slide-footer">
				<div class="lh-feedback-container">
					<div v-if="isSubmitted && feedbackMessage" class="lh-feedback-block" :class="feedbackType">
						{{ feedbackMessage }}
					</div>
				</div>
			</div>
		</div>
	</div>`,
    name: 'uc-slide-viewer-v3',
	
		props: {
			slideData: { type: Object, default: () => null },
			userAnswer: { default: null },
			isLastLesson: { type: Boolean, default: false },
			isTocOpen: { type: Boolean, default: false }
		},
		emits: ['next', 'update:userAnswer', 'pdf-progress', 'quiz-result', 'open-toc'], // ✅ Thêm open-toc emit
	
		data() {
			return {
				// Single quiz states
				unclassifiedItems: [],
				isSubmitted: false,
				feedbackMessage: '',
				feedbackType: '',
				showExplanation: false,
				selectedMatchingBId: null,
				activeDragItem: null,
				activeDragEl: null,
				dragAvatarEl: null,
	
				// ✅ CLEANED User answers - chỉ cho single quiz
				userAnswers: {
					singleChoice: null,
					multipleChoice: [],
					ordering: [],
					matching: [],
					fillInTheBlank: {},
					connection: {
						activeGroup: null,
						selections: []
					}
					// ❌ REMOVED: composite: {}
					// ❌ REMOVED: trueFalse: []
				},
	
				// Connection quiz specific
				lines: [],
				groupColors: {},
	
				// Sortable instances management
				sortableInstances: [],
	
				// Enhanced features
				soundEnabled: true,
				animationsEnabled: true,
				showHints: true,
	
				// Question type labels for display
				questionTypeLabels: {
					'QUIZ_SINGLE_CHOICE': '🎯 Chọn một đáp án',
					'QUIZ_MULTIPLE_CHOICE': '☑️ Chọn nhiều đáp án',
					'QUIZ_FILL_IN_BLANK': '✏️ Điền vào chỗ trống',
					'QUIZ_ORDERING': '📝 Sắp xếp thứ tự',
					'QUIZ_MATCHING': '🔗 Ghép nối',
					'QUIZ_DRAG_DROP_CATEGORIZE': '📦 Phân loại',
					'QUIZ_CONNECTION': '🔗 Nối đường thẳng',
					'QUIZ_COMPOSITE': '📝 Nhiều câu hỏi',
					'QUIZ_TRUE_FALSE': '🎯 Chọn đáp án đúng sai',
				},
				zoomLevel: 1.0,
				isFullscreen: false,
				fullscreenContainer: null,
				originalParent: null,
				originalNextSibling: null,
	
				// ✅ Anti-recursive properties
				pdfProgressTimeout: null,
				lastProgressUpdate: 0,
				progressUpdateThrottle: 2000,
	
				iSpringLoading: true,
				isiSpringFullscreen: false,
				remainingBCount: -1
			}
		},
	
		computed: {
			isVideoSlide() {
				const type = String(this.slideData?.type || '').toUpperCase();
				if (type === 'VIDEO') return true;
				const content = this.slideData?.content || {};
				if (content.videoId) return true;
				const hint = ['mediaType', 'contentType', 'slideType', 'fileType', 'uploadSource',
					'fileName', 'url', 'source', 'viewerSource', 'externalSource', 'videoId', 'audioUrl']
					.map((key) => this.mediaValue(content?.[key], [key]))
					.filter(Boolean)
					.join(' ')
					.toLowerCase();
				return /youtube|youtu\.be|video|\.mp4(?:$|[?#])|\.webm(?:$|[?#])|\.mov(?:$|[?#])|\.m3u8(?:$|[?#])|\.avi(?:$|[?#])/.test(hint);
			},
			isAudioSlide() {
				if (this.isVideoSlide) return false;
				const type = String(this.slideData?.type || '').toUpperCase();
				if (type === 'AUDIO') return true;
				const content = this.slideData?.content || {};
				const hint = ['mediaType', 'contentType', 'slideType', 'fileType', 'uploadSource',
					'fileName', 'url', 'source', 'viewerSource', 'externalSource', 'audioUrl']
					.map((key) => this.mediaValue(content?.[key], [key]))
					.filter(Boolean)
					.join(' ')
					.toLowerCase();
				return /audio|\.mp3(?:$|[?#])|\.wav(?:$|[?#])|\.ogg(?:$|[?#])|\.m4a(?:$|[?#])/.test(hint);
			},
			mediaSourceUrl() {
				const content = this.slideData?.content || {};
				// Bản ghi cũ có thể đồng thời chứa audioUrl và URL video; chọn theo loại đã nhận diện.
				const rawSource = this.isVideoSlide
					? (content.url || content.source || content.viewerSource || content.externalSource || content.audioUrl)
					: (content.audioUrl || content.url || content.source || content.viewerSource || content.externalSource);
				const source = rawSource
					? this.mediaValue(rawSource, ['url'])
					: (content.videoId ? `https://www.youtube.com/watch?v=${this.mediaValue(content.videoId)}` : '');
				return source ? this.resolveContentUrl(source) : '';
			},
			externalDocumentUrl() {
				if (!this.slideData || !this.slideData.content) return '';
				const content = this.slideData.content;
				const candidates = typeof content === 'string'
					? [content]
					: [content.url, content.source, content.viewerSource, content.externalSource,
						content.textContent, content.htmlContent, content.content];

				return candidates.find(value => this.isExternalDocumentUrl(value)) || '';
			},
			contentZoomStyle() {
				if (this.zoomLevel === 1) {
					return {
						width: '100%',
						height: '100%'
					};
				}
				return {
					zoom: this.zoomLevel,
					width: '100%',
					minHeight: '100%',
					transformOrigin: 'top center',
					transition: 'zoom 0.15s ease'
				};
			},
			getDisplayHtmlContent() {
				if (!this.slideData || !this.slideData.content) return '';
				const c = this.slideData.content;
				if (typeof c === 'string') return c;
				return c.htmlContent || c.textContent || c.content || '';
			},
			embedVideoUrl() {
				if (!this.slideData || this.slideData.type !== 'VIDEO' || !this.slideData.content.url) return '';
				const urlStr = this.slideData.content.url;
				try {
					const url = new URL(urlStr);
					if (url.hostname.includes('youtube.com')) {
						const videoId = url.searchParams.get('v');
						return `https://www.youtube.com/embed/${videoId}?rel=0&modestbranding=1`;
					}
					if (url.hostname === 'youtu.be') {
						const videoId = url.pathname.slice(1);
						return `https://www.youtube.com/embed/${videoId}?rel=0&modestbranding=1`;
					}
				} catch (e) {
					console.warn('Invalid video URL:', urlStr);
				}
				return urlStr;
			},
	
			isQuiz() {
				return this.slideData && this.slideData.type.startsWith('QUIZ') && this.slideData.type !== 'QUIZ_COMPOSITE';
			},

			audioSourceUrl() {
				return this.mediaSourceUrl;
			},

			imageSourceUrl() {
				const content = this.slideData?.content || {};
				return this.resolveContentUrl(content.url || content.source || content.externalSource || '');
			},

			slideContentType() {
				const content = this.slideData?.content || {};
				const value = `${content.slideType || content.fileType || ''} ${content.contentType || ''} ${content.fileName || content.title || ''} ${content.url || ''}`.toLowerCase();
				// Import từ Content Hub có thể chưa có slideType; suy luận lại từ MIME/tên file để không khóa viewer ở PPT.
				if (/pdf|application\/pdf/.test(value)) return 'PDF';
				if (/pptx?|powerpoint|presentation/.test(value)) return 'PPT';
				if (/xlsx?|excel|spreadsheet/.test(value)) return 'XLSX';
				// Phân biệt rõ DOC và DOCX để viewer LMS tạo đúng phần mở rộng trong URL FileData.
				if (/(?:^|[\s._/?#-])docx(?:$|[\s._/?#-])|wordprocessingml/.test(value)) return 'DOCX';
				if (/(?:^|[\s._/?#-])doc(?:$|[\s._/?#-])|msword/.test(value)) return 'DOC';
				return String(content.slideType || '').toUpperCase();
			},

			// Đồng bộ điều kiện nhận diện với Content Hub: URL FileData, uploadSource 'db' hoặc archiveFileId của LMS sẽ dùng viewer nội bộ.
			// Nhờ vậy tài liệu Office/PDF trong LMS được hiển thị trực tiếp mượt mà qua LMS Viewer chuẩn.
			lmsDocumentViewerUrl() {
				if (!['PDF', 'DOC', 'DOCX', 'XLSX', 'PPT'].includes(this.slideContentType)) return '';
				const content = this.slideData?.content || {};
				const rawFileDataUrl = String(
					content.dbUrl || content.DB_URL || content.FILE_URL || content.fileUrl ||
					content.FileURL || content.FileUrl || content.url || ''
				);
				const sourceId = rawFileDataUrl.match(/\/FileData\/([^/?#]+)/i)?.[1] || '';
					// FileData LMS là nguồn chuẩn như PDF: ưu tiên mọi biến thể FileID của DB,
					// kể cả khi DataJson còn sót URL Google Drive từ phiên bản cũ.
					const fileId = content.fileId || content.FILE_ID || content.FileID || content.fileID ||
						content.FileDataID || content.FileDataId || content.LmsFileID || content.LmsFileId ||
						content.archiveFileId || sourceId;
				const storageCode = String(content.storage || content.Storage || content.storageCode || content.storageType || '');
					const isLmsFileData = !!fileId
						|| /(?:file\.lhbs\.vn|lms\.lhbs\.vn)\/lms\/(?:viewer\/)?FileData\//i.test(rawFileDataUrl)
					|| /(?:^|\/)FileData\//i.test(rawFileDataUrl)
					|| !!content.archiveFileId
					|| content.uploadSource === 'db';
				// Một số response chỉ trả FILE_ID + mã kho, không trả FILE_URL; mã storage vẫn đủ
				// để xác định đây là file DB LMS mà không ảnh hưởng tới file Drive/nguồn thứ ba.
				const isLmsFileStorage = /LMS_.*FILEDATA/i.test(storageCode);
				if (!isLmsFileData && !isLmsFileStorage) return '';

				const extensionByType = { PDF: '.pdf', DOC: '.doc', DOCX: '.docx', XLSX: '.xlsx', PPT: '.pptx' };
				const rawFileName = content.fileName || content.FILE_NAME || content.FileName || content.TenFile ||
					content.archiveFileName || content.title || `file-${fileId}${extensionByType[this.slideContentType] || ''}`;
				if (!fileId || !rawFileName) return '';

				// Viewer LMS nhận tên file trên path; làm sạch các ký tự có thể bị IIS Request Filtering chặn.
				const lastDotIndex = rawFileName.lastIndexOf('.');
				const baseName = lastDotIndex !== -1 ? rawFileName.substring(0, lastDotIndex) : rawFileName;
				const extension = lastDotIndex !== -1 ? rawFileName.substring(lastDotIndex) : '';
				const cleanBaseName = baseName.replace(/[&+%#?:/\\*"<>|]/g, '_').trim() || 'file';
				const fileName = `${cleanBaseName}${extension}`;
				return `https://file.lhbs.vn/lms/viewer/FileData/${encodeURIComponent(fileId)}/${encodeURIComponent(fileName)}`;
			},
	
			isPDFBookReader() {
				return this.slideData &&
					this.slideData.type === 'SLIDE' &&
					this.slideContentType === 'PDF';
			},
	
			isRegularSlide() {
				return this.slideData &&
					this.slideData.type === 'SLIDE' &&
					this.slideContentType !== 'PDF';
			},
	
			shouldShowControls() {
				// Ẩn controls mặc định khi dùng PDF Book Reader
				return !this.isPDFBookReader;
			}
		},
	
		watch: {
			slideData: {
				handler(newSlide) {
					if (newSlide && !this.isInitializing) {
						this.initializeSlide(newSlide);
					}
				},
				immediate: true,
				deep: false // ✅ Turn off deep watching to prevent loops
			},
	
			// Watch connection selections for line drawing  
			'userAnswers.connection.selections': {
				handler(newSelections, oldSelections) {
					console.log('Watch triggered:', newSelections);
					if (this.slideData?.type === 'QUIZ_CONNECTION') {
						this.drawLines();
					}
				},
				deep: true,
				immediate: false
			},

			// Tự động cập nhật tỷ lệ Zoom vào tài liệu bên trong iframe khi zoom thay đổi
			zoomLevel(newVal) {
				this.applyZoomToIframe();
			}
		},
	
		methods: {
			// URL từ API có thể là chuỗi, số hoặc object lồng; không nối object thành [object Object].
			mediaValue(value, fallbackKeys = []) {
				if (typeof value === 'string') return value.trim();
				if (typeof value === 'number') return String(value);
				if (!value || typeof value !== 'object') return '';
				const keys = [...fallbackKeys, 'url', 'source', 'viewerSource', 'externalSource', 'audioUrl',
					'FILE_URL', 'fileUrl', 'FileURL', 'href', 'src'];
				for (const key of keys) {
					const nested = this.mediaValue(value[key]);
					if (nested) return nested;
				}
				const videoId = this.mediaValue(value.videoId);
				return videoId ? `https://www.youtube.com/watch?v=${videoId}` : '';
			},

			isExternalDocumentUrl(value) {
				if (typeof value !== 'string' || !/^https?:\/\//i.test(value.trim())) return false;

				try {
					const hostname = new URL(value.trim()).hostname;
					return /(?:^|\.)canva\.com$/i.test(hostname)
						|| /(?:^|\.)docs\.google\.com$/i.test(hostname)
						|| /(?:^|\.)drive\.google\.com$/i.test(hostname)
						|| /(?:^|\.)office\.com$/i.test(hostname)
						|| /(?:^|\.)onedrive\.live\.com$/i.test(hostname)
						|| /(?:^|\.)sharepoint\.com$/i.test(hostname);
				} catch (error) {
					return false;
				}
			},
			applyZoomToIframe() {
				this.$nextTick(() => {
					try {
						const iframe = this.$refs.htmlContentIframe;
						if (iframe && iframe.contentDocument) {
							const doc = iframe.contentDocument;
							if (doc.body) {
								doc.body.style.zoom = this.zoomLevel;
								doc.body.style.transformOrigin = 'top center';
							}
						}
					} catch(e) {}
				});
			},

			getEmptyStateBadge(slide) {
				const loai = (slide && (slide.type === 'EMPTY_STATE' ? (slide.content?.loaiNoiDung || '') : slide.type)) || '';
				switch (String(loai).toUpperCase()) {
					case 'CHUONG': return 'Chương học';
					case 'BAI': return 'Bài học';
					case 'NHOM_KY_NANG': return 'Nhóm kỹ năng';
					default: return 'Thông báo học liệu';
				}
			},

			// Relative FileData URL cần ghép với endpoint đọc file của LMS khi import từ Content Hub.
			resolveContentUrl(value) {
				value = this.mediaValue(value);
				if (!value) return '';
				if (/^(https?:|blob:|data:)/i.test(value)) return value;
				const baseUrl = typeof vueData !== 'undefined' ? (vueData?.v_Set?.urlReadFile || '') : '';
				return baseUrl ? baseUrl.replace(/\/$/, '') + '/' + value.replace(/^\//, '') : value;
			},

			// ==================== INITIALIZATION ====================
			initializeSlide(slide) {
				// ✅ Prevent recursive calls
				if (this.isInitializing) return;
				this.isInitializing = true;
				try {
					// Reset component states
					this.resetStates();

					if (!slide || !slide.content) {
						return;
					}

					// Handle PDF Book Reader
					if (slide.type === 'SLIDE' && this.slideContentType === 'PDF') {
						this.initializePDFBookSafe(slide);
						return;
					}

					// Initialize regular quiz answers
					this.initializeUserAnswers();
	
					// Setup specific quiz types
					this.setupQuizType(slide);
					this.updateBCount();
				} finally {
					// ✅ Reset flag after initialization
					setTimeout(() => {
						this.isInitializing = false;
					}, 100);
				}
			},
	
			// ==================== ZOOM METHODS ====================
			zoomIn() {
				if (this.zoomLevel < 2.5) {
					this.zoomLevel = Math.min(2.5, Math.round((this.zoomLevel + 0.15) * 100) / 100);
					this.playSound('click');
				}
			},
			zoomOut() {
				if (this.zoomLevel > 0.5) {
					this.zoomLevel = Math.max(0.5, Math.round((this.zoomLevel - 0.15) * 100) / 100);
					this.playSound('click');
				}
			},
			resetZoom() {
				this.zoomLevel = 1.0;
				this.playSound('click');
			},

			resetStates() {
				this.zoomLevel = 1.0;
				this.isSubmitted = false;
				this.feedbackMessage = '';
				this.feedbackType = '';
				this.showExplanation = false;
				this.lines = [];
				this.unclassifiedItems = [];
	
				// Clear PDF progress timeout
				if (this.pdfProgressTimeout) {
					clearTimeout(this.pdfProgressTimeout);
					this.pdfProgressTimeout = null;
				}
	
				// Destroy sortable instances
				this.destroySortableInstances();
			},

			// Chuẩn hóa HTML cho thẻ iframe để đảm bảo hiển thị đúng font, hình ảnh responsive và sự kiện load
			cleanIframeHtml(str) {
				if (!str) return '';
				let clean = String(str).trim();

				const patchHead = "<style>" +
					"html {" +
					" margin: 0 !important;" +
					" padding: 0 !important;" +
					" width: 100% !important;" +
					" height: 100% !important;" +
					" box-sizing: border-box !important;" +
					" overflow-y: auto !important;" +
					" overflow-x: auto !important;" +
					" scrollbar-width: thin !important;" +
					" scrollbar-color: #cbd5e1 #f8fafc !important;" +
					"}" +
					"body {" +
					" margin: 0 !important;" +
					" padding: 16px !important;" +
					" width: 100% !important;" +
					" min-height: 100% !important;" +
					" box-sizing: border-box !important;" +
					" font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif !important;" +
					" color: #1e293b !important;" +
					" line-height: 1.65 !important;" +
					"}" +
					"::-webkit-scrollbar { width: 8px !important; height: 8px !important; }" +
					"::-webkit-scrollbar-track { background: #f8fafc !important; }" +
					"::-webkit-scrollbar-thumb { background: #cbd5e1 !important; border-radius: 4px !important; }" +
					"::-webkit-scrollbar-thumb:hover { background: #94a3b8 !important; }" +
					"img { max-width: 100% !important; max-height: calc(100vh - 40px) !important; height: auto !important; width: auto !important; object-fit: contain !important; display: block !important; margin: auto !important; border-radius: 8px !important; }" +
					"video, audio, table { max-width: 100% !important; height: auto !important; margin-left: auto !important; margin-right: auto !important; }" +
					"</style>" +
					"<" + "script>" +
					"(function() {" +
					" var triggerLoad = function() {" +
					"  try { window.dispatchEvent(new Event('DOMContentLoaded')); window.dispatchEvent(new Event('load')); } catch(e) {}" +
					" };" +
					" if (document.readyState === 'interactive' || document.readyState === 'complete') { setTimeout(triggerLoad, 50); }" +
					" else { document.addEventListener('readystatechange', function() { if (document.readyState === 'interactive' || document.readyState === 'complete') { setTimeout(triggerLoad, 50); } }); }" +
					"})();" +
					"<" + "/script>";

				if (clean.includes('<head>')) {
					return clean.replace('<head>', '<head>' + patchHead);
				} else if (clean.includes('<html>')) {
					return clean.replace('<html>', '<html><head>' + patchHead + '</head>');
				} else if (clean.includes('<body')) {
					return '<!DOCTYPE html><html><head>' + patchHead + '</head>' + clean + '</html>';
				}
				return '<!DOCTYPE html><html><head>' + patchHead + '</head><body>' + clean + '</body></html>';
			},

			// Làm sạch HTML khi render trực tiếp trong DOM thông qua v-html (tránh lồng thẻ html/body làm vỡ layout LMS)
			cleanHtml(str) {
				if (!str) return '';
				let clean = String(str);
				if (clean.includes('<body') && clean.includes('</body>')) {
					const match = clean.match(/<body[^>]*>([\s\S]*)<\/body>/i);
					if (match && match[1]) {
						return match[1].trim();
					}
				}
				return clean;
			},
			// ✅ CLEANED: Only for single quiz
			initializeUserAnswers() {
				this.userAnswers = {
					singleChoice: null,
					multipleChoice: [],
					ordering: [],
					matching: [],
					fillInTheBlank: {},
					connection: {
						activeGroup: null,
						selections: []
					}
					// ❌ REMOVED: composite: {}
					// ❌ REMOVED: trueFalse: []
				};
			},
	
			setupQuizType(slide) {
				if (slide.type === 'QUIZ_ORDERING' && slide.content?.items) {
					this.userAnswers.ordering = this.shuffleArray([...slide.content.items]);
					Vue.nextTick(() => this.initSortableOrdering());
				}
				else if (slide.type === 'QUIZ_DRAG_DROP_CATEGORIZE' && slide.content?.items) {
					this.unclassifiedItems = this.shuffleArray([...slide.content.items]);
					Vue.nextTick(() => this.initSortableCategorize());
				}
				else if (slide.type === 'QUIZ_MATCHING' && slide.content?.columnB) {
					this.userAnswers.matching = this.shuffleArray([...slide.content.columnB]);
					Vue.nextTick(() => this.initSortableMatching());
				}
				else if (slide.type === 'QUIZ_FILL_IN_BLANK' && slide.content?.parts) {
					slide.content.parts.forEach(part => {
						if (part.type === 'blank') {
							this.userAnswers.fillInTheBlank[part.id] = '';
						}
					});
				}
				else if (slide.type === 'QUIZ_CONNECTION' && slide.content?.groups) {
					this.generateGroupColors(slide.content.groups);
					// Setup initial drawing after DOM is ready
					Vue.nextTick(() => {
						setTimeout(() => {
							this.drawLines();
						}, 200);
					});
				}
			},
	
			// ==================== PDF BOOK METHODS (SAFE VERSION) ====================
			initializePDFBookSafe(slide) {
				console.log('Initializing PDF Book:', slide.content?.title || 'Unknown');
	
				// ✅ Initialize progress WITHOUT reactive assignment to prevent loops
				if (!slide.content.progress) {
					// Use Object.defineProperty to make it non-reactive
					Object.defineProperty(slide.content, 'progress', {
						value: {
							currentPage: 1,
							totalPages: 0,
							viewedPages: [],
							lastViewed: new Date().toISOString()
						},
						writable: true,
						enumerable: true,
						configurable: true
					});
				}
	
				// Load saved progress ONCE without triggering watchers
				this.loadPDFProgressOnce(slide);
			},
	
			loadPDFProgressOnce(slide) {
				if (!slide?.id) return;
	
				try {
					const progressKey = `pdf_progress_${slide.id}`;
					const saved = localStorage.getItem(progressKey);
	
					if (saved) {
						const progress = JSON.parse(saved);
	
						// ✅ Use direct assignment without Vue reactivity
						Object.assign(slide.content.progress, progress);
					}
				} catch (error) {
					console.warn('Cannot load PDF progress from localStorage:', error);
				}
			},
	
			onPDFPageChanged(pageData) {
				console.log(`PDF Book page changed: ${pageData.page}/${pageData.total}`);
	
				// ✅ Throttle updates to prevent recursive loops
				const now = Date.now();
				if (now - this.lastProgressUpdate < this.progressUpdateThrottle) {
					console.log('Progress update throttled');
					return;
				}
	
				this.lastProgressUpdate = now;
	
				// ✅ Use timeout to defer the update
				if (this.pdfProgressTimeout) {
					clearTimeout(this.pdfProgressTimeout);
				}
	
				this.pdfProgressTimeout = setTimeout(() => {
					this.updatePDFProgressSafe(pageData);
					this.emitPDFProgressSafe(pageData);
					this.playSound('navigate');
				}, 100);
			},
	
			updatePDFProgressSafe(pageData) {
				if (!this.slideData?.content?.progress) return;
	
				try {
					// ✅ Direct property updates to avoid Vue reactivity
					this.slideData.content.progress.currentPage = pageData.page;
					this.slideData.content.progress.totalPages = pageData.total;
					this.slideData.content.progress.lastViewed = new Date().toISOString();
	
					// Update viewed pages array safely
					const viewedPages = this.slideData.content.progress.viewedPages || [];
					if (!viewedPages.includes(pageData.page)) {
						viewedPages.push(pageData.page);
					}
	
					// Save to localStorage
					this.savePDFProgressSafe(pageData, viewedPages);
	
				} catch (error) {
					console.warn('Error updating PDF progress:', error);
				}
			},
	
			emitPDFProgressSafe(pageData) {
				try {
					this.$emit('pdf-progress', {
						slideId: this.slideData?.id,
						currentPage: pageData.page,
						totalPages: pageData.total,
						timestamp: new Date().toISOString(),
						completionPercentage: Math.round((pageData.page / pageData.total) * 100)
					});
				} catch (error) {
					console.warn('Error emitting PDF progress:', error);
				}
			},
	
			savePDFProgressSafe(pageData, viewedPages) {
				if (!this.slideData?.id) return;
	
				try {
					const progressKey = `pdf_progress_${this.slideData.id}`;
					const progress = {
						currentPage: pageData.page,
						totalPages: pageData.total,
						lastViewed: new Date().toISOString(),
						completionPercentage: Math.round((pageData.page / pageData.total) * 100),
						viewedPages: viewedPages || []
					};
	
					localStorage.setItem(progressKey, JSON.stringify(progress));
				} catch (error) {
					console.warn('Cannot save PDF progress to localStorage:', error);
				}
			},
	
			onSlidePageChanged(pageData) {
				console.log(`Regular slide page changed: ${pageData.page}/${pageData.total}`);
				this.trackSlideProgressSafe(pageData);
				this.$emit('slide-progress', pageData);
				this.playSound('navigate');
			},
	
			trackSlideProgressSafe(pageData) {
				if (this.slideData?.content) {
					if (!this.slideData.content.progress) {
						this.slideData.content.progress = {};
					}
	
					// Direct assignment without reactive triggering
					this.slideData.content.progress.currentPage = pageData.page;
					this.slideData.content.progress.lastViewed = new Date().toISOString();
				}
			},
	
			isPDFBookSlide() {
				return this.slideData &&
					this.slideData.type === 'SLIDE' &&
					this.slideContentType === 'PDF';
			},
	
			// ==================== SORTABLE METHODS FOR SINGLE QUIZ ====================
			// ✅ GIỮ LẠI: Cần cho composite quiz (với questionId parameter)
			initOrderingSortable(questionId) {
				const refName = 'orderingContainer_' + questionId;
				const container = this.$refs[refName];
				if (container) {
					const instance = new Sortable(container, {
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						chosenClass: 'lh-sortable-chosen',
						dragClass: 'lh-sortable-drag',
						onEnd: () => this.playSound('drop')
					});
					this.sortableInstances.push(instance);
				}
			},
	
			// ✅ GIỮ LẠI: Cần cho composite quiz (với questionId parameter)
			initMatchingSortable(questionId) {
				const refName = 'matchingBContainer_' + questionId;
				const container = this.$refs[refName];
				if (container) {
					const instance = new Sortable(container, {
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						chosenClass: 'lh-sortable-chosen',
						dragClass: 'lh-sortable-drag',
						onEnd: () => this.playSound('drop')
					});
					this.sortableInstances.push(instance);
				}
			},
	
			// ✅ FIXED: Sử dụng slideData.content thay vì this.currentQuestion
			initCategorizeSortable(questionId) {
				// Source container
				const sourceRefName = 'sourceContainer_' + questionId;
				const sourceContainer = this.$refs[sourceRefName];
				if (sourceContainer) {
					const sourceInstance = new Sortable(sourceContainer, {
						group: 'categorize-group-' + questionId,
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						chosenClass: 'lh-sortable-chosen',
						dragClass: 'lh-sortable-drag',
						onEnd: () => this.playSound('drop')
					});
					this.sortableInstances.push(sourceInstance);
				}
	
				// ✅ FIXED: Lấy categories từ slideData.content
				if (this.slideData?.content?.categories) {
					this.slideData.content.categories.forEach(category => {
						const categoryRefName = 'categoryContainer_' + questionId + '_' + category.id;
						const categoryContainer = this.$refs[categoryRefName];
						if (categoryContainer) {
							const categoryInstance = new Sortable(categoryContainer, {
								group: 'categorize-group-' + questionId,
								animation: 200,
								ghostClass: 'lh-sortable-ghost',
								chosenClass: 'lh-sortable-chosen',
								dragClass: 'lh-sortable-drag',
								onEnd: () => this.playSound('drop')
							});
							this.sortableInstances.push(categoryInstance);
						}
					});
				}
			},
	
			destroySortableInstances() {
				this.sortableInstances.forEach(instance => {
					try {
						instance.destroy();
					} catch (e) {
						console.warn('Error destroying sortable instance:', e);
					}
				});
				this.sortableInstances = [];
			},
	
			// ==================== SINGLE QUIZ SORTABLE METHODS ====================
			shuffleArray(array) {
				const newArray = [...array];
				for (let i = newArray.length - 1; i > 0; i--) {
					const j = Math.floor(Math.random() * (i + 1));
					[newArray[i], newArray[j]] = [newArray[j], newArray[i]];
				}
				return newArray;
			},
	
			initSortableOrdering() {
				this.destroySortableInstances();
				if (this.$refs.orderingContainer) {
					const instance = new Sortable(this.$refs.orderingContainer, {
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						chosenClass: 'lh-sortable-chosen',
						dragClass: 'lh-sortable-drag',
						onEnd: () => this.playSound('drop')
					});
					this.sortableInstances.push(instance);
				}
			},
	
			initSortableCategorize() {
				this.destroySortableInstances();
				if (this.$refs.sourceContainer) {
					const sourceInstance = new Sortable(this.$refs.sourceContainer, {
						group: 'categorize-group',
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						onEnd: () => this.playSound('drop')
					});
					this.sortableInstances.push(sourceInstance);
				}
				if (this.$refs.categoryContainers) {
					this.$refs.categoryContainers.forEach(container => {
						const instance = new Sortable(container, {
							group: 'categorize-group',
							animation: 200,
							ghostClass: 'lh-sortable-ghost',
							onEnd: () => this.playSound('drop')
						});
						this.sortableInstances.push(instance);
					});
				}
			},
	
			initSortableMatching() {
				// Hủy toàn bộ SortableJS cho phần Ghép Nối
				// Sử dụng 100% Native Pointer Engine (startMatchingPointerDrag) để kéo thả mượt mà không bị bóng mờ lề
				this.destroySortableInstances();
			},

			handleMatchingDragEnd(evt) {
				const itemEl = evt.item;
				const toContainer = evt.to;

				// Nếu kéo thả ra ngoài Cột A (ví dụ kéo ra ngoài lề hoặc nhả tay ở vùng trống) -> Tự nhảy về Cột B!
				if (!toContainer || (!toContainer.classList.contains('lh-matching-dropzone') && toContainer !== this.$refs.matchingBContainer)) {
					if (this.$refs.matchingBContainer && itemEl) {
						this.$refs.matchingBContainer.appendChild(itemEl);
						this.playSound('drop');
					}
				}
			},
	
			// ==================== SINGLE QUIZ CHECKING ====================
			checkAnswer() {
				if (!this.isQuiz || !this.slideData.content) return;
	
				let isCorrect = false;
				const content = this.slideData.content;
				const userAnswers = this.userAnswers;
	
				console.log('Checking answer for quiz type:', this.slideData.type);
				console.log('User answers:', userAnswers);
				console.log('Correct data:', content);
	
				if (this.slideData.type === 'QUIZ_SINGLE_CHOICE') {
					if (userAnswers.singleChoice === null || userAnswers.singleChoice === undefined) {
						this.showToast('⚠️ Em hãy chọn một đáp án nhé!', 'warning');
						return;
					}
					const userChoice = String(userAnswers.singleChoice);
					const correctChoice = String(content.correctAnswer);
					isCorrect = userChoice === correctChoice;
					console.log('Single Choice - User:', userChoice, 'Correct:', correctChoice, 'Result:', isCorrect);
	
				} else if (this.slideData.type === 'QUIZ_MULTIPLE_CHOICE') {
					const userAnswer = userAnswers.multipleChoice;
	
					if (!Array.isArray(userAnswer) || userAnswer.length === 0) {
						this.showToast('⚠️ Em hãy chọn ít nhất một đáp án nhé!', 'warning');
						return;
					}
	
					const correctAnswers = Array.isArray(content.correctAnswers) ? content.correctAnswers : [];
					const userAnswerSorted = [...userAnswer].map(String).sort();
					const correctAnswerSorted = [...correctAnswers].map(String).sort();
					isCorrect = JSON.stringify(userAnswerSorted) === JSON.stringify(correctAnswerSorted);
					console.log('Multiple Choice - User:', userAnswerSorted, 'Correct:', correctAnswerSorted, 'Result:', isCorrect);
	
				} else if (this.slideData.type === 'QUIZ_ORDERING') {
					if (!this.$refs.orderingContainer) {
						console.warn('Ordering container not found');
						return;
					}
					const userOrderIds = Array.from(this.$refs.orderingContainer.children).map(el => String(el.dataset.id));
					const correctOrderIds = content.items.map(item => String(item.id));
					isCorrect = JSON.stringify(userOrderIds) === JSON.stringify(correctOrderIds);
					console.log('Ordering - User:', userOrderIds, 'Correct:', correctOrderIds, 'Result:', isCorrect);
	
				} else if (this.slideData.type === 'QUIZ_DRAG_DROP_CATEGORIZE') {
					console.log('=== CATEGORIZE DEBUG START ===');
	
					// Kiểm tra refs
					if (!this.$refs.sourceContainer || !this.$refs.categoryContainers) {
						console.warn('Categorize containers not found');
						console.log('sourceContainer:', this.$refs.sourceContainer);
						console.log('categoryContainers:', this.$refs.categoryContainers);
						return;
					}
	
					let allCorrect = true;
	
					// 1. Kiểm tra không còn item nào trong source
					const unclassifiedItems = Array.from(this.$refs.sourceContainer.children);
					console.log('Items still in source:', unclassifiedItems.length);
	
					if (unclassifiedItems.length > 0) {
						this.showToast('⚠️ Em hãy phân loại hết tất cả các từ nhé!', 'warning');
						return;
					}
	
					// 2. Kiểm tra từng category
					const categoryResults = {};
	
					this.$refs.categoryContainers.forEach(container => {
						const categoryId = String(container.dataset.categoryId);
						const droppedItemIds = Array.from(container.children)
							.filter(child => !child.classList.contains('lh-dropzone-hint')) // Loại bỏ hint element
							.map(el => String(el.dataset.id))
							.filter(id => id && id !== 'undefined'); // Loại bỏ undefined
	
						const correctItemIds = this.slideData.content.items
							.filter(item => String(item.categoryId) === categoryId)
							.map(item => String(item.id));
	
						// Sort để so sánh chính xác
						const droppedSorted = [...droppedItemIds].sort();
						const correctSorted = [...correctItemIds].sort();
	
						const isMatch = JSON.stringify(droppedSorted) === JSON.stringify(correctSorted);
	
						categoryResults[categoryId] = {
							dropped: droppedSorted,
							correct: correctSorted,
							isMatch: isMatch
						};
	
						console.log(`Category ${categoryId}:`, categoryResults[categoryId]);
	
						if (!isMatch) {
							allCorrect = false;
						}
					});
	
					console.log('=== FINAL RESULT ===');
					console.log('All categories correct:', allCorrect);
					console.log('Category details:', categoryResults);
					console.log('=== CATEGORIZE DEBUG END ===');
	
					isCorrect = allCorrect;
	
				} else if (this.slideData.type === 'QUIZ_MATCHING') {
					const content = this.slideData.content || {};
					const columnA = content.columnA || [];
					const columnB = content.columnB || [];
					const correctPairs = content.correctPairs || [];
					const totalPairsCount = columnA.length;

					if (!this.$refs.matchingDropzones) {
						this.showToast('⚠️ Em hãy kéo các mục ở Cột B nối vào Cột A nhé!', 'warning');
						return;
					}

					const dropzones = Array.isArray(this.$refs.matchingDropzones)
						? this.$refs.matchingDropzones
						: [this.$refs.matchingDropzones];

					// 1. Kiểm tra trước số lượng mục đã thả vào Cột A
					let totalDropped = 0;
					dropzones.forEach(dz => {
						const droppedItems = Array.from(dz.children).filter(c => !c.classList.contains('lh-dropzone-placeholder'));
						totalDropped += droppedItems.length;
					});

					// 2. Nếu chưa ghép mục nào hoặc chưa ghép đủ 100% -> Nhắc nhở & RETURN NGAY (CHƯA ĐẮP BADGE TÍCH ĐÚNG/SAI)
					if (totalDropped === 0) {
						this.showToast('⚠️ Em hãy kéo các mục ở Cột B nối vào Cột A nhé!', 'warning');
						return;
					}

					if (totalPairsCount > 0 && totalDropped < totalPairsCount) {
						this.showToast('⚠️ Em hãy ghép hết tất cả các mục nhé!', 'warning');
						return;
					}

					// 3. Sau khi đã ghép đủ 100% tất cả các mục -> Mới tiến hành chấm điểm và đắp badge ✅ / ❌ !
					let allCorrect = true;
					dropzones.forEach(dz => {
						dz.classList.remove('lh-drop-correct', 'lh-drop-wrong');
						const itemA_Id = String(dz.dataset.itemAId);
						const itemA = columnA.find(a => String(a.id) === itemA_Id) || { id: itemA_Id };
						const droppedItems = Array.from(dz.children).filter(c => !c.classList.contains('lh-dropzone-placeholder'));

						if (droppedItems.length > 0) {
							const itemEl = droppedItems[0];
							const droppedId = String(itemEl.dataset.id);
							const itemB = (this.userAnswers.matching || []).find(b => String(b.id) === droppedId) || { id: droppedId };

							itemEl.classList.remove('lh-item-correct', 'lh-item-wrong');
							const existingBadge = itemEl.querySelector('.lh-match-badge');
							if (existingBadge) existingBadge.remove();

							const isPairCorrect = this.isMatchingPair(itemA, itemB, correctPairs, columnA, columnB);

							if (isPairCorrect) {
								dz.classList.add('lh-drop-correct');
								itemEl.classList.add('lh-item-correct');
								const badge = document.createElement('span');
								badge.className = 'lh-match-badge correct';
								badge.innerHTML = ' ✅';
								itemEl.appendChild(badge);
							} else {
								dz.classList.add('lh-drop-wrong');
								itemEl.classList.add('lh-item-wrong');
								const badge = document.createElement('span');
								badge.className = 'lh-match-badge wrong';
								badge.innerHTML = ' ❌';
								itemEl.appendChild(badge);
								allCorrect = false;
							}
						}
					});

					isCorrect = allCorrect;
					console.log('Matching - Result:', isCorrect);

				} else if (this.slideData.type === 'QUIZ_FILL_IN_BLANK') {
					let allCorrect = true;
					content.parts.forEach(part => {
						if (part.type === 'blank') {
							const userAnswer = (userAnswers.fillInTheBlank[part.id] || '').toLowerCase().trim();
							const correctAnswer = (part.correctAnswer || '').toLowerCase().trim();
							console.log(`Fill blank ${part.id} - User: "${userAnswer}", Correct: "${correctAnswer}"`);
							if (userAnswer !== correctAnswer) {
								allCorrect = false;
							}
						}
					});
					isCorrect = allCorrect;

				} else if (this.slideData.type === 'QUIZ_CONNECTION') {
					let correctCount = 0;
					const userSelectionsMap = new Map(this.userAnswers.connection.selections.map(s => [String(s.to), String(s.from)]));

					this.slideData.content.items.forEach(item => {
						const userGroup = userSelectionsMap.get(String(item.id));
						const correctGroup = String(item.groupId);
						console.log(`Connection item ${item.id} - User group: ${userGroup}, Correct group: ${correctGroup}`);
						if (userGroup === correctGroup) {
							correctCount++;
						}
					});
					isCorrect = correctCount === this.slideData.content.items.length;
					console.log('Connection - Correct count:', correctCount, 'Total items:', this.slideData.content.items.length, 'Result:', isCorrect);

				} else if (this.slideData.type === 'QUIZ_TRUE_FALSE' || this.slideData.type === 'QUIZ_TRUE_FALSE_LIST' || this.slideData.type === 'TRUE_FALSE' || this.slideData.type === 'MATCHING_TF') {
					const options = this.slideData.content?.options || this.slideData.content?.items || [];
					
					// 1. Check if user answered all options
					const hasUnanswered = options.some(item => item._correctAnswer === undefined || item._correctAnswer === null);
					if (hasUnanswered) {
						this.showToast('⚠️ Em hãy chọn đáp án Đúng/Sai cho tất cả các ý nhé!', 'warning');
						return;
					}

					let flag = true;
					for (var item of options) {
						let expected = null;
						if (typeof item.isCorrect === 'boolean') expected = item.isCorrect;
						else if (typeof item.correctAnswer === 'boolean') expected = item.correctAnswer;
						else if (typeof item.isTrue === 'boolean') expected = item.isTrue;
						else if (item.correctAnswer !== undefined) {
							const str = String(item.correctAnswer).trim().toLowerCase();
							expected = (str === 'true' || str === '1' || str === 'đúng' || str === 'dung');
						} else if (item.isCorrect !== undefined) {
							const str = String(item.isCorrect).trim().toLowerCase();
							expected = (str === 'true' || str === '1' || str === 'đúng' || str === 'dung');
						}
						
						const userChoice = item._correctAnswer;
						if (expected !== null && Boolean(userChoice) !== Boolean(expected)) {
							flag = false;
							break;
						}
					}
					isCorrect = flag;
				}

				if (this.slideData.content.explanation) {
					this.showExplanation = true;
				}

				this.playSound(isCorrect ? 'correct' : 'wrong');

				if (isCorrect) {
					this.showToast('🎉 Chính xác rồi! Em làm rất tốt!', 'success');
				} else {
					this.showToast('😅 Chưa đúng rồi. Em hãy xem lại nhé!', 'error');
				}

				this.isSubmitted = true;
				this.$emit('quiz-result', {
					isCorrect: isCorrect,
					result: isCorrect,
					slideId: this.slideData?.id
				});
			},

			isMatchingPair(itemA, itemB, correctPairs, columnA, columnB) {
				if (!itemA || !itemB) return false;
				const itemA_Id = String(itemA.id || '');
				const itemB_Id = String(itemB.id || '');

				// 1. Check correctPairs array
				if (correctPairs && Array.isArray(correctPairs) && correctPairs.length > 0) {
					const pair = correctPairs.find(p => 
						String(p.from) === itemA_Id || 
						String(p.id) === itemA_Id || 
						String(p.itemAId) === itemA_Id
					);
					if (pair) {
						const expectedB = String(pair.to || pair.itemBId || pair.correctBId);
						if (expectedB === itemB_Id) return true;
					}
				}

				// 2. Check itemA properties: correctBId, to, targetId
				if (itemA.correctBId !== undefined && itemA.correctBId !== null) {
					if (String(itemA.correctBId) === itemB_Id) return true;
				}
				if (itemA.to !== undefined && itemA.to !== null) {
					if (String(itemA.to) === itemB_Id) return true;
				}
				if (itemA.targetId !== undefined && itemA.targetId !== null) {
					if (String(itemA.targetId) === itemB_Id) return true;
				}

				// 3. Check pairId matching
				if (itemA.pairId !== undefined && itemA.pairId !== null) {
					if (String(itemA.pairId) === String(itemB.pairId || itemB.id)) return true;
				}
				if (itemB.pairId !== undefined && itemB.pairId !== null) {
					if (String(itemB.pairId) === itemA_Id) return true;
				}

				// 4. Fallback: ID matching
				if (itemA_Id && itemB_Id && itemA_Id === itemB_Id) return true;

				// 5. Fallback: Trailing number matching in text (e.g. "Mục A1" <-> "Mục B1")
				const textA = (itemA.text || itemA.title || '').toString();
				const textB = (itemB.text || itemB.title || '').toString();
				const numA = textA.match(/\d+/);
				const numB = textB.match(/\d+/);
				if (numA && numB && numA[0] === numB[0]) return true;

				// 6. Fallback: Index matching in columnA and columnB
				if (Array.isArray(columnA) && Array.isArray(columnB)) {
					const idxA = columnA.findIndex(a => String(a.id) === itemA_Id);
					const idxB = columnB.findIndex(b => String(b.id) === itemB_Id);
					if (idxA !== -1 && idxB !== -1 && idxA === idxB) return true;
				}

				return false;
			},

			showHint() {
				if (this.slideData.content.explanation) {
					this.showExplanation = true;
					this.showToast('💡 Xem phần hướng dẫn bên dưới nhé!', 'info');
				} else {
					this.showToast('❓ Câu hỏi này không có gợi ý.', 'info');
				}
			},

			showSolution() {
				if (this.slideData?.type === 'QUIZ_MATCHING') {
					const content = this.slideData.content || {};
					const columnA = content.columnA || [];
					const columnB = content.columnB || [];
					const correctPairs = content.correctPairs || [];

					if (this.$refs.matchingDropzones && columnA.length > 0) {
						const dropzones = Array.isArray(this.$refs.matchingDropzones)
							? this.$refs.matchingDropzones
							: [this.$refs.matchingDropzones];

						columnA.forEach(itemA => {
							const itemA_Id = String(itemA.id);
							const matchingB = columnB.find(itemB => this.isMatchingPair(itemA, itemB, correctPairs, columnA, columnB));

							if (matchingB) {
								const itemB_Id = String(matchingB.id);
								const targetDz = dropzones.find(dz => String(dz.dataset.itemAId) === itemA_Id);
								const itemB_El = document.querySelector(`.lh-matching-item-b[data-id="${itemB_Id}"]`);

								if (targetDz && itemB_El) {
									targetDz.appendChild(itemB_El);
									targetDz.classList.remove('lh-drop-wrong');
									targetDz.classList.add('lh-drop-correct');
									itemB_El.classList.remove('lh-item-wrong');
									itemB_El.classList.add('lh-item-correct');

									const existingBadge = itemB_El.querySelector('.lh-match-badge');
									if (existingBadge) existingBadge.remove();
									const badge = document.createElement('span');
									badge.className = 'lh-match-badge correct';
									badge.innerHTML = ' ✅';
									itemB_El.appendChild(badge);
								}
							}
						});
						this.updateBCount();
						this.showToast('🔑 Đã hiển thị đáp án ghép đôi chính xác!', 'success');
						return;
					}
				}
				if (this.slideData?.content?.explanation) {
					this.showExplanation = true;
					this.showToast('💡 Xem phần giải thích đáp án bên dưới nhé!', 'info');
				} else {
					this.showToast('🔑 Đang xem đáp án bài học.', 'info');
				}
			},
	
			getOptionClass(optionId) {
				if (!this.isSubmitted || !this.slideData || !this.slideData.content) {
					return '';
				}

				const content = this.slideData.content;

				if (this.slideData.type === 'QUIZ_SINGLE_CHOICE') {
					const isCorrectAnswer = String(optionId) === String(content.correctAnswer);
					const isSelectedAnswer = String(optionId) === String(this.userAnswers.singleChoice);
					if (isSelectedAnswer) {
						return isCorrectAnswer ? 'lh-correct-answer' : 'lh-wrong-answer';
					}
					return 'lh-not-selected';
				}
				else if (this.slideData.type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = Array.isArray(content.correctAnswers) ? content.correctAnswers : [];
					const isCorrect = correctAnswers.map(String).includes(String(optionId));
					const isSelected = this.userAnswers.multipleChoice.map(String).includes(String(optionId));
					if (isSelected) {
						return isCorrect ? 'lh-correct-answer' : 'lh-wrong-answer';
					}
					return 'lh-not-selected';
				}
	
				return 'lh-not-selected';
			},

			// ==================== MATCHING TAP METHODS ====================
			resetMatchingGradingState() {
				this.isSubmitted = false;
				this.feedbackMessage = '';
				this.feedbackType = '';
				if (this.$refs.matchingDropzones) {
					const dropzones = Array.isArray(this.$refs.matchingDropzones)
						? this.$refs.matchingDropzones
						: [this.$refs.matchingDropzones];
					dropzones.forEach(dz => {
						dz.classList.remove('lh-drop-correct', 'lh-drop-wrong');
						Array.from(dz.children).forEach(itemEl => {
							itemEl.classList.remove('lh-item-correct', 'lh-item-wrong');
							const badge = itemEl.querySelector('.lh-match-badge');
							if (badge) badge.remove();
						});
					});
				}
			},

			toggleSelectMatchingB(itemBId) {
				if (this.isSubmitted) {
					this.resetMatchingGradingState();
				}
				if (String(this.selectedMatchingBId) === String(itemBId)) {
					this.selectedMatchingBId = null;
				} else {
					this.selectedMatchingBId = itemBId;
					this.playSound('navigate');
				}
			},

			startMatchingPointerDrag(event, itemB) {
				if (this.isSubmitted) {
					this.resetMatchingGradingState();
				}
				if (event.cancelable) event.preventDefault();

				const pointer = event.touches ? event.touches[0] : event;
				const itemEl = event.currentTarget || event.target.closest('.lh-matching-item-b');
				if (!itemEl) return;

				this.activeDragItem = itemB;
				this.activeDragEl = itemEl;

				const rect = itemEl.getBoundingClientRect();
				const targetDz = document.querySelector('.lh-matching-dropzone');
				const dzWidth = targetDz ? targetDz.getBoundingClientRect().width : 0;
				const avatarWidth = (dzWidth && dzWidth > 40) ? dzWidth : Math.min(rect.width, 180);
				const avatarHeight = rect.height;
				const avatar = itemEl.cloneNode(true);
				avatar.id = 'matching-drag-avatar';
				avatar.className = 'lh-drag-avatar-clone';
				avatar.style.position = 'fixed';
				avatar.style.left = (pointer.clientX - avatarWidth / 2) + 'px';
				avatar.style.top = (pointer.clientY - avatarHeight / 2) + 'px';
				avatar.style.width = avatarWidth + 'px';
				avatar.style.maxWidth = avatarWidth + 'px';
				avatar.style.height = avatarHeight + 'px';
				avatar.style.zIndex = '999999';
				avatar.style.pointerEvents = 'none';
				avatar.style.boxShadow = '0 12px 28px rgba(0,0,0,0.3)';
				avatar.style.transform = 'scale(1.05) rotate(2deg)';
				avatar.style.opacity = '0.92';
				avatar.style.transition = 'none';
				avatar.style.border = '2px solid #10b981';
				avatar.style.background = '#ffffff';
				avatar.style.borderRadius = '10px';
				avatar.style.touchAction = 'none';

				document.body.appendChild(avatar);
				this.dragAvatarEl = avatar;

				// Ẩn hoàn toàn thẻ nguồn khi bốc kéo
				itemEl.style.visibility = 'hidden';

				const onPointerMove = (e) => {
					if (e.cancelable) e.preventDefault();
					const p = e.touches ? e.touches[0] : e;
					if (this.dragAvatarEl) {
						this.dragAvatarEl.style.left = (p.clientX - avatarWidth / 2) + 'px';
						this.dragAvatarEl.style.top = (p.clientY - avatarHeight / 2) + 'px';
					}

					const elemBelow = document.elementFromPoint(p.clientX, p.clientY);
					if (elemBelow) {
						const dz = elemBelow.closest('.lh-matching-dropzone') || elemBelow.closest('.lh-matching-pair-row');
						if (this.$refs.matchingDropzones) {
							const dropzones = Array.isArray(this.$refs.matchingDropzones)
								? this.$refs.matchingDropzones
								: [this.$refs.matchingDropzones];
							dropzones.forEach(d => d.classList.remove('lh-dropzone-hover'));
						}
						if (dz) {
							const targetDz = dz.classList.contains('lh-matching-dropzone') ? dz : dz.querySelector('.lh-matching-dropzone');
							if (targetDz) targetDz.classList.add('lh-dropzone-hover');
						}
					}
				};

				const onPointerUp = (e) => {
					window.removeEventListener('mousemove', onPointerMove);
					window.removeEventListener('mouseup', onPointerUp);
					window.removeEventListener('pointermove', onPointerMove);
					window.removeEventListener('pointerup', onPointerUp);
					window.removeEventListener('touchmove', onPointerMove);
					window.removeEventListener('touchend', onPointerUp);

					if (this.dragAvatarEl) {
						this.dragAvatarEl.remove();
						this.dragAvatarEl = null;
					}

					if (this.activeDragEl) {
						this.activeDragEl.style.visibility = 'visible';
						this.activeDragEl.style.display = '';
						this.activeDragEl.style.opacity = '1';
					}

					if (this.$refs.matchingDropzones) {
						const dropzones = Array.isArray(this.$refs.matchingDropzones)
							? this.$refs.matchingDropzones
							: [this.$refs.matchingDropzones];
						dropzones.forEach(d => d.classList.remove('lh-dropzone-hover'));
					}

					const p = e.changedTouches ? e.changedTouches[0] : (e.touches ? e.touches[0] : e);
					const elemBelow = document.elementFromPoint(p.clientX, p.clientY);

					if (elemBelow) {
						const dz = elemBelow.closest('.lh-matching-dropzone') || elemBelow.closest('.lh-matching-pair-row');
						if (dz) {
							const targetDz = dz.classList.contains('lh-matching-dropzone') ? dz : dz.querySelector('.lh-matching-dropzone');
							if (targetDz) {
								const itemA_Id = targetDz.dataset.itemAId;
								this.assignMatchingPair(itemA_Id, itemB.id);
								this.playSound('drop');
								this.activeDragItem = null;
								this.activeDragEl = null;
								this.updateBCount();
								return;
							}
						}
					}

					if (this.$refs.matchingBContainer && this.activeDragEl) {
						this.$refs.matchingBContainer.appendChild(this.activeDragEl);
						this.playSound('drop');
					}

					this.activeDragItem = null;
					this.activeDragEl = null;
					this.updateBCount();
				};

				window.addEventListener('mousemove', onPointerMove, { passive: false });
				window.addEventListener('mouseup', onPointerUp, { passive: false });
				window.addEventListener('pointermove', onPointerMove, { passive: false });
				window.addEventListener('pointerup', onPointerUp, { passive: false });
				window.addEventListener('touchmove', onPointerMove, { passive: false });
				window.addEventListener('touchend', onPointerUp, { passive: false });
			},

			updateBCount() {
				this.$nextTick(() => {
					if (this.$refs.matchingBContainer) {
						const items = this.$refs.matchingBContainer.querySelectorAll('.lh-matching-item-b');
						this.remainingBCount = items.length;
					}
				});
			},

			handleMatchingRowClick(itemAId) {
				if (this.isSubmitted) return;

				// Chế độ chạm gán: Nếu đang chọn 1 mục từ Cột B
				if (this.selectedMatchingBId) {
					const itemBId = this.selectedMatchingBId;
					this.assignMatchingPair(itemAId, itemBId);
					this.selectedMatchingBId = null;
					this.playSound('drop');
					return;
				}

				// Nếu chạm vào dòng ở Cột A đã có mục B gán rồi -> Trả mục B đó quay lại Cột B
				if (this.$refs.matchingDropzones) {
					const dropzones = Array.isArray(this.$refs.matchingDropzones)
						? this.$refs.matchingDropzones
						: [this.$refs.matchingDropzones];
					const dz = dropzones.find(d => String(d.dataset.itemAId) === String(itemAId));
					if (dz) {
						const itemBEl = Array.from(dz.children).find(c => c.classList.contains('lh-matching-item-b'));
						if (itemBEl && this.$refs.matchingBContainer) {
							this.$refs.matchingBContainer.appendChild(itemBEl);
							this.playSound('navigate');
							this.updateBCount();
						}
					}
				}
			},

			assignMatchingPair(itemAId, itemBId) {
				if (this.isSubmitted) {
					this.resetMatchingGradingState();
				}
				if (!this.$refs.matchingDropzones || !this.$refs.matchingBContainer) return;
				const dropzones = Array.isArray(this.$refs.matchingDropzones)
					? this.$refs.matchingDropzones
					: [this.$refs.matchingDropzones];
				const targetDz = dropzones.find(d => String(d.dataset.itemAId) === String(itemAId));
				const itemBEl = document.querySelector(`.lh-matching-item-b[data-id="${itemBId}"]`);

				if (targetDz && itemBEl) {
					const sourceDz = itemBEl.closest('.lh-matching-dropzone');
					const oldItemBEl = Array.from(targetDz.children).find(c => c.classList.contains('lh-matching-item-b'));

					// HOÁN ĐỔI TRỰC TIẾP (SWAP) GIỮA 2 ĐÁP ÁN Ở CỘT A:
					if (oldItemBEl && sourceDz && sourceDz !== targetDz) {
						// Chuyển đáp án B cũ ở ô target sang ô source gốc!
						sourceDz.appendChild(oldItemBEl);
					} else if (oldItemBEl) {
						// Nếu kéo từ Cột B sang -> Trả đáp án B cũ về Cột B
						this.$refs.matchingBContainer.appendChild(oldItemBEl);
					}
					targetDz.appendChild(itemBEl);
					this.updateBCount();
				}
			},

			getMatchingBText(itemBId) {
				if (!this.slideData?.content?.columnB) return '';
				const match = this.slideData.content.columnB.find(b => String(b.id) === String(itemBId));
				return match ? match.text : '';
			},
	
			// ==================== CONNECTION QUIZ METHODS ====================
			generateGroupColors(groups) {
				const presetColors = [
					'#FF6B6B', '#4DD0E1', '#FFD93D',
					'#6BCB77', '#FF9F1C', '#C084FC',
					'#38BDF8', '#F472B6', '#FBBF24', '#34D399'
				];
				let i = 0;
				groups.forEach(group => {
					this.groupColors[group.id] = presetColors[i % presetColors.length];
					i++;
				});
			},
	
			drawLines() {
				if (this.slideData?.type !== 'QUIZ_CONNECTION') return;
				const selections = this.userAnswers?.connection?.selections;
				if (!selections || !selections.length) {
					this.lines = [];
					return;
				}

				this.$nextTick(() => {
					const container = this.$refs.connectionContainer || this.$refs.connectionParent;
					if (!container) return;

					const newLines = [];
					selections.forEach(selection => {
						const fromEl = document.getElementById('connect-group-' + selection.from);
						const toEl = document.getElementById('connect-item-' + selection.to);

						if (fromEl && toEl) {
							const fromPos = this.getOffsetPos(fromEl, container);
							const toPos = this.getOffsetPos(toEl, container);

							newLines.push({
								x1: Math.round(fromPos.left + fromPos.width),
								y1: Math.round(fromPos.top + (fromPos.height / 2)),
								x2: Math.round(toPos.left),
								y2: Math.round(toPos.top + (toPos.height / 2)),
								color: this.groupColors[selection.from] || '#4CAF50'
							});
						}
					});

					this.lines = newLines;
				});
			},
	
			getOffsetPos(el, container) {
				const rect = el.getBoundingClientRect();
				const containerRect = container.getBoundingClientRect();
				return {
					left: rect.left - containerRect.left,
					top: rect.top - containerRect.top,
					width: rect.width,
					height: rect.height
				};
			},
	
			selectGroup(groupId) {
				this.userAnswers.connection.activeGroup = groupId;
				this.playSound('navigate');
			},
	
			selectItem(itemId) {
				const activeGroup = this.userAnswers.connection.activeGroup;
				const existingSelIndex = this.userAnswers.connection.selections.findIndex(sel => sel.to === itemId);

				if (!activeGroup) {
					if (existingSelIndex !== -1) {
						this.selectGroup(this.userAnswers.connection.selections[existingSelIndex].from);
					} else {
						this.showToast("Vui lòng chọn một Nhóm ở cột trái trước.", 'warning');
					}
					return;
				}

				if (existingSelIndex !== -1 && this.userAnswers.connection.selections[existingSelIndex].from === activeGroup) {
					this.userAnswers.connection.selections.splice(existingSelIndex, 1);
					this.userAnswers.connection.activeGroup = null;
					this.tempLine = null;
					this.activeStartPos = null;
					this.playSound('navigate');
				} else {
					if (existingSelIndex !== -1) {
						this.userAnswers.connection.selections.splice(existingSelIndex, 1);
					}
					this.userAnswers.connection.selections.push({ from: activeGroup, to: itemId });
					this.userAnswers.connection.activeGroup = null;
					this.tempLine = null;
					this.activeStartPos = null;
					this.playSound('drop');
				}

				this.userAnswers.connection.selections = [...this.userAnswers.connection.selections];
				this.drawLines();
			},
	
			getItemClass(itemId) {
				const matches = this.userAnswers.connection.selections.filter(s => s.to === itemId);
				return matches.length > 0 ? 'lh-connected' : '';
			},
	
			getGroupClass(groupId) {
				const isActive = this.userAnswers.connection.activeGroup === groupId;
				const hasConnection = this.userAnswers.connection.selections.find(s => s.from === groupId);
				return {
					'lh-active': isActive,
					'lh-connected': hasConnection
				};
			},
	
			getConnectionForItem(itemId) {
				return this.userAnswers.connection.selections.find(s => s.to === itemId);
			},
	
			getGroupText(groupId) {
				const group = this.slideData?.content?.groups?.find(g => g.id === groupId);
				return group ? group.text : '';
			},
	
			// ==================== UTILITY METHODS ====================
			getQuestionTypeLabel(type) {
				return this.questionTypeLabels[type] || type;
			},
	
			isImage(value) {
				if (!value) return false;
				const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
				return /^https?:\/\//.test(value) && imageExtensions.some(ext => value.toLowerCase().endsWith(ext));
			},
	
			playSound(type) {
				if (!this.soundEnabled) return;
	
				const sounds = {
					start: '/_cdn/lhbs-lms/sounds/start.mp3',
					correct: '/_cdn/lhbs-lms/sounds/correct.mp3',
					wrong: '/_cdn/lhbs-lms/sounds/wrong.mp3',
					success: '/_cdn/lhbs-lms/sounds/success.mp3',
					'try-again': '/_cdn/lhbs-lms/sounds/try-again.mp3',
					navigate: '/_cdn/lhbs-lms/sounds/click.mp3',
					drop: '/_cdn/lhbs-lms/sounds/drop.mp3',
					'fullscreen-enter': '/_cdn/lhbs-lms/sounds/fullscreen-enter.mp3',
					'fullscreen-exit': '/_cdn/lhbs-lms/sounds/fullscreen-exit.mp3'
				};
	
				if (sounds[type]) {
					const audio = new Audio(sounds[type]);
					audio.volume = 0.3;
					audio.play().catch(() => { }); // Ignore audio errors
				}
			},
	
			showToast(message, type = 'info') {
				// Use Vue toast if available, otherwise fallback to console
				if (this.$toast) {
					this.$toast[type](message);
				} else if (Vue.$toast) {
					Vue.$toast[type](message);
				} else {
					console.log(`[${type.toUpperCase()}] ${message}`);
				}
			},
	
			// ==================== FULLSCREEN METHODS ====================
			toggleFullscreen() {
				if (this.isFullscreen) {
					this.exitFullscreen();
				} else {
					this.enterFullscreen();
				}
			},
	
			enterFullscreen() {
				const container = this.$el.querySelector('.lh-iframe-container');
				if (!container) return;
	
				// Lưu vị trí gốc
				this.originalParent = container.parentNode;
				this.originalNextSibling = container.nextSibling;
	
				// Thêm class fullscreen
				container.classList.add('lh-fullscreen');
	
				// Di chuyển container ra body
				document.body.appendChild(container);
	
				// Update state
				this.isFullscreen = true;
				this.fullscreenContainer = container;
	
				// Add keyboard listener
				document.addEventListener('keydown', this.handleFullscreenKeydown);
	
				// Prevent body scroll
				document.body.style.overflow = 'hidden';
	
				// Optional: Add overlay
				this.addFullscreenOverlay();
	
				// Play sound
				this.playSound('fullscreen-enter');
	
				// Announce to screen readers
				this.announceFullscreen('Đã vào chế độ toàn màn hình');
			},
	
			exitFullscreen() {
				if (!this.fullscreenContainer || !this.isFullscreen) return;
	
				const container = this.fullscreenContainer;
	
				// Add exit animation
				container.classList.add('lh-fullscreen-exit');
	
				setTimeout(() => {
					// Remove fullscreen classes
					container.classList.remove('lh-fullscreen', 'lh-fullscreen-exit');
	
					// Move back to original position
					if (this.originalNextSibling) {
						this.originalParent.insertBefore(container, this.originalNextSibling);
					} else {
						this.originalParent.appendChild(container);
					}
	
					// Update state
					this.isFullscreen = false;
					this.fullscreenContainer = null;
	
					// Remove keyboard listener
					document.removeEventListener('keydown', this.handleFullscreenKeydown);
	
					// Restore body scroll
					document.body.style.overflow = '';
	
					// Remove overlay
					this.removeFullscreenOverlay();
	
					// Play sound
					this.playSound('fullscreen-exit');
	
					// Announce to screen readers
					this.announceFullscreen('Đã thoát chế độ toàn màn hình');
				}, 100);
			},
	
			handleFullscreenKeydown(event) {
				if (event.key === 'Escape') {
					event.preventDefault();
					this.exitFullscreen();
				} else if (event.key === '+' || event.key === '=') {
					event.preventDefault();
					this.zoomIn();
				} else if (event.key === '-' || event.key === '_') {
					event.preventDefault();
					this.zoomOut();
				} else if (event.key === '0') {
					event.preventDefault();
					this.resetZoom();
				} else if (event.key === 'F11') {
					event.preventDefault();
					this.toggleBrowserFullscreen();
				}
			},

			addFullscreenOverlay() {
				const overlay = document.createElement('div');
				overlay.className = 'lh-fullscreen-overlay';
				overlay.id = 'lh-fullscreen-overlay';
	
				// Click overlay to exit
				overlay.addEventListener('click', this.exitFullscreen);
	
				document.body.appendChild(overlay);
			},
	
			removeFullscreenOverlay() {
				const overlay = document.getElementById('lh-fullscreen-overlay');
				if (overlay) {
					overlay.remove();
				}
			},
	
			async toggleBrowserFullscreen() {
				try {
					if (!document.fullscreenElement) {
						await this.fullscreenContainer.requestFullscreen();
					} else {
						await document.exitFullscreen();
					}
				} catch (error) {
					console.warn('Fullscreen API not supported:', error);
				}
			},
	
			announceFullscreen(message) {
				const announcer = document.createElement('div');
				announcer.setAttribute('aria-live', 'polite');
				announcer.setAttribute('aria-atomic', 'true');
				announcer.style.position = 'absolute';
				announcer.style.left = '-10000px';
				announcer.textContent = message;
	
				document.body.appendChild(announcer);
	
				setTimeout(() => {
					announcer.remove();
				}, 1000);
			},
	
			// ==================== ISPRING METHODS ====================
			oniSpringLoad() {
				console.log('✅ iSpring content loaded');
				this.iSpringLoading = false;
				this.playSound('success');
			},
	
			oniSpringError() {
				console.error('❌ iSpring content failed to load');
				this.iSpringLoading = false;
				this.showToast('Không thể tải nội dung iSpring', 'error');
			},
	
			retryiSpringLoad() {
				this.iSpringLoading = true;
				const iframe = this.$refs.iSpringContentIframe;
				if (iframe) {
					iframe.src = iframe.src; // Force reload
				}
			},
	
			openiSpringExternal() {
				if (this.slideData?.content?.iSpringURL) {
					window.open(this.slideData.content.iSpringURL, '_blank');
					this.playSound('navigate');
				}
			},
	
			toggleiSpringFullscreen() {
				const container = this.$refs.iSpringContentIframe?.parentElement;
				if (!container) return;
	
				if (this.isiSpringFullscreen) {
					this.exitiSpringFullscreen();
				} else {
					this.enteriSpringFullscreen();
				}
			},
	
			enteriSpringFullscreen() {
				const container = this.$refs.iSpringContentIframe?.parentElement;
				if (!container) return;
	
				container.classList.add('lh-fullscreen');
				this.isiSpringFullscreen = true;
				document.body.style.overflow = 'hidden';
	
				// ESC key listener
				document.addEventListener('keydown', this.handleiSpringEscape);
				this.playSound('fullscreen-enter');
			},
	
			exitiSpringFullscreen() {
				const container = this.$refs.iSpringContentIframe?.parentElement;
				if (!container) return;
	
				container.classList.remove('lh-fullscreen');
				this.isiSpringFullscreen = false;
				document.body.style.overflow = '';
	
				document.removeEventListener('keydown', this.handleiSpringEscape);
				this.playSound('fullscreen-exit');
			},
	
			handleiSpringEscape(event) {
				if (event.key === 'Escape') {
					event.preventDefault();
					this.exitiSpringFullscreen();
				} else if (event.key === '+' || event.key === '=') {
					event.preventDefault();
					this.zoomIn();
				} else if (event.key === '-' || event.key === '_') {
					event.preventDefault();
					this.zoomOut();
				} else if (event.key === '0') {
					event.preventDefault();
					this.resetZoom();
				}
			},
	
			// ==================== QUIZ COMPOSITE EVENT HANDLER ====================
			onQuizCompleted(result) {
				console.log('Quiz completed:', result);
				this.$emit('quiz-result', {
					slideId: this.slideData?.id,
					result: result,
					timestamp: new Date().toISOString()
				});
			},
			onNext() {
				this.$emit('next');
			},
			onPrev() {
				this.$emit('prev');
			}
		},

		mounted() {
			this.resizeHandler = () => {
				if (this.slideData?.type === 'QUIZ_CONNECTION') {
					setTimeout(() => {
						this.drawLines();
					}, 100);
				}
			};
			window.addEventListener('resize', this.resizeHandler);

			document.addEventListener('fullscreenchange', () => {
				if (!document.fullscreenElement && this.isFullscreen) {
					this.exitFullscreen();
				}
			});

			document.addEventListener('visibilitychange', () => {
				if (document.hidden && this.isFullscreen) {
					this.exitFullscreen();
				}
			});
		},
		beforeDestroy() {
			if (this.pdfProgressTimeout) {
				clearTimeout(this.pdfProgressTimeout);
			}
			this.destroySortableInstances();
			if (this.resizeHandler) {
				window.removeEventListener('resize', this.resizeHandler);
			}
			if (this.isFullscreen) {
				this.exitFullscreen();
			}
			document.removeEventListener('keydown', this.handleFullscreenKeydown);
			document.removeEventListener('keydown', this.handleiSpringEscape);
			this.removeFullscreenOverlay();
			document.body.style.overflow = '';
		}
  };
  Vue.component("uc-slide-viewer-v3", compDef);
})();

;(function() {
  const compDef = {
    template: `<div class="media-player-container">
		<!-- Trạng thái Loading -->
		<div v-if="isLoading" class="loading-overlay">
			<v-progress-circular indeterminate color="primary"></v-progress-circular>
		</div>

		<!-- Trạng thái Lỗi -->
		<div v-else-if="error" class="error-overlay">
			<v-icon color="error" size="x-large">mdi-alert-circle-outline</v-icon>
			<p class="mt-2">{{ error }}</p>
		</div>

		<!-- Giao diện khi phát video (YouTube/HTML5 Video) -->
		<v-row v-else-if="mediaType === 'youtube' || mediaType === 'video'" class="ma-0 w-100" :no-gutters="!hasQuestions">
			<!-- Cột trái: Trình phát; video tương tác chiếm 9 cột để chừa sidebar các mốc câu hỏi. -->
			<v-col cols="12" :md="hasQuestions ? 9 : 12" class="pa-0" :class="{ 'pr-md-3': hasQuestions }">
				<div class="video-preview-box position-relative w-100">
					<div v-if="mediaType === 'youtube'" key="yt-preview-box" ref="ytWrapper" class="lh-youtube-wrapper w-100 h-100 position-absolute">
						<div :id="playerId" class="w-100 h-100"></div>
						<!-- Video thường để YouTube tự hiển thị controls; chỉ chặn lớp native khi có tương tác. -->
						<div v-if="hasQuestions" class="player-overlay" @click="togglePlay"></div>
					</div>
					<video v-else key="html-preview-box" ref="htmlVideoPlayer" :controls="!hasQuestions" class="w-100 h-100"
						@play="startTimeCheck" @pause="stopTimeCheck" @timeupdate="onHtmlVideoTimeUpdate"
						@loadedmetadata="onHtmlVideoMetadata">
						<source :src="mediaUrl" type="video/mp4">
						Trình duyệt không hỗ trợ xem video trực tiếp.
					</video>
				</div>

				<!-- Chỉ video tương tác dùng timeline riêng; video thường giữ nguyên controls/time mặc định của YouTube/HTML5. -->
				<div v-if="hasQuestions" class="lh-video-timeline w-100 d-flex flex-column mt-3 mb-4">
					<div ref="timelineTrack" class="position-relative w-100 px-1 mb-2 d-flex align-center" style="height: 20px;"
						@mousedown="onTimelineTrackMouseDown"
						@touchstart="onTimelineTrackMouseDown">
						<v-slider v-model="videoCurrentTime" :max="videoDuration || 100" min="0" step="1"
							:hide-details="true" density="compact" color="success" track-color="grey-lighten-2"
							:track-size="4" :thumb-size="12"
							@update:model-value="onVideoSliderEnd"
							@change="onVideoSliderEnd"
							class="w-100">
						</v-slider>
						
					</div>
					
					<div class="d-flex align-center justify-space-between w-100 pt-1">
						<div class="d-flex align-center" style="gap: 10px;">
							<v-btn :icon="true" size="small" variant="flat" color="success" class="elevation-1" @click="togglePlay" :title="videoPlaying ? 'Tạm dừng (Space)' : 'Phát video (Space)'">
								<v-icon size="20" color="white">{{ videoPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon>
							</v-btn>
							<span class="text-caption font-weight-bold text-slate-800" style="color: #1e293b !important; font-size: 0.85rem;">
								{{ formatTime(videoCurrentTime) }} / {{ formatTime(videoDuration) }}
							</span>
						</div>
					</div>
				</div>
			</v-col>

			<!-- Cột phải: Sidebar Sự kiện Video (chỉ render khi có câu hỏi tương tác) -->
			<v-col v-if="hasQuestions" cols="12" md="3" class="pa-0 pl-md-2">
				<v-card variant="outlined" class="pa-4 h-100 d-flex flex-column" style="min-height: 350px; overflow: hidden !important;">
					<v-card-title class="text-subtitle-1 font-weight-bold pa-0 mb-3 d-flex align-center">
						<v-icon color="primary" class="mr-2">mdi-format-list-bulleted</v-icon>
						Mốc câu hỏi
						<v-chip size="x-small" color="primary" variant="tonal" class="ml-auto">
							{{ unlockedInteractionCount }}/{{ normalizedInteractions.length }} mốc
						</v-chip>
					</v-card-title>
					<v-divider class="mb-4"></v-divider>
					
					<!-- Timeline dọc (Vertical Timeline) -->
					<div class="video-events-list flex-grow-1 pr-1">
						<div v-for="(item, idx) in sortedInteractions" :key="item.id" class="event-timeline-item d-flex align-start mb-4">
							<!-- Cột mốc trạng thái (Chấm tròn và đường kẻ nối) -->
							<div class="timeline-indicator-col d-flex flex-column align-center mr-3" style="height: 100%;">
								<div class="timeline-dot"
									:class="{ 'is-completed': completedInteractions.includes(item.id), 'is-active': activeInteraction && activeInteraction.id === item.id, 'is-locked': !isInteractionUnlocked(item) }">
									<v-icon v-if="completedInteractions.includes(item.id)" size="x-small" color="white">mdi-check</v-icon>
									<v-icon v-else-if="!isInteractionUnlocked(item)" size="x-small" color="white">mdi-lock-outline</v-icon>
								</div>
								<div v-if="idx < sortedInteractions.length - 1" class="timeline-line"></div>
							</div>
							
							<!-- Cột thông tin chi tiết (không clickable, text màu đậm dễ nhìn) -->
							<div class="event-details flex-grow-1" style="cursor: default;">
								<div class="text-caption font-weight-bold d-flex justify-space-between align-center">
									<span class="font-weight-bold" style="color: #1a252f !important; font-size: 0.85rem;">
										{{ formatTime(item.time) }}
									</span>
									<v-chip size="x-small" :color="completedInteractions.includes(item.id) ? 'success' : getTypeBadgeColor(getInteractionType(item))" variant="flat" style="color: #ffffff !important; font-weight: 700;">
										{{ item.questions.length }} câu
									</v-chip>
								</div>
								<!-- Không render đề bài trước mốc; chỉ hiển thị nội dung sau khi video đã đi tới marker. -->
								<div v-if="isInteractionUnlocked(item)" class="text-body-2 mt-1" style="color: #2c3e50 !important; font-weight: 500;">
									<div v-for="(question, questionIndex) in item.questions" :key="question.id || questionIndex" class="mb-1">
										<span class="font-weight-bold">Câu {{ questionIndex + 1 }}:</span>
										{{ stripHtml(getQuestionPrompt(question)) }}
									</div>
								</div>
								<div v-else class="text-caption text-medium-emphasis mt-2">
									<v-icon size="12" class="mr-1">mdi-lock-outline</v-icon>
									Câu hỏi sẽ mở khi video tới mốc {{ formatTime(item.time) }}
								</div>
							</div>
						</div>
						<div v-if="normalizedInteractions.length === 0" class="text-center text-grey py-8">
							Video này không có câu hỏi tương tác.
						</div>
					</div>
				</v-card>
			</v-col>
		</v-row>

		<!-- Trình phát Audio (thẻ <audio> của HTML5) -->
		<div v-else-if="mediaType === 'audio'" class="audio-wrapper">
			<audio controls :src="mediaUrl" class="w-100">
				Trình duyệt của bạn không hỗ trợ thẻ audio.
			</audio>
		</div>

		<!-- Trường hợp URL không được hỗ trợ -->
		<div v-else class="unsupported-wrapper">
			<p>Loại media không được hỗ trợ hoặc đường dẫn không hợp lệ.</p>
			<a :href="url" target="_blank" v-if="url">Mở link trực tiếp</a>
		</div>

		<!-- Overlay câu hỏi tương tác dành cho học sinh (Hỗ trợ đầy đủ cả 8 dạng câu hỏi) -->
		<v-dialog v-model="showInteractionOverlay" persistent max-width="850">
			<v-card v-if="activeInteraction" style="border-radius: 16px; overflow: hidden; box-shadow: 0 12px 36px rgba(0,0,0,0.25) !important;">
				<v-card-title class="d-flex align-center pa-4 style-header" style="background: linear-gradient(135deg, #059669 0%, #10b981 100%) !important; color: #ffffff !important;">
					<v-icon class="mr-2" style="color: #ffffff !important;">mdi-help-circle-outline</v-icon>
					<span class="text-subtitle-1 font-weight-bold" style="color: #ffffff !important;">
						❓ Câu hỏi tương tác ({{ getTypeName(getInteractionType(activeInteraction)) }})
					</span>
				</v-card-title>
				<v-card-text class="pa-4 pt-4" style="max-height: 70vh; overflow-y: auto;">
					<!-- Nhúng uc-slide-viewer-v3 để hiển thị trọn vẹn cả 8 dạng câu hỏi với đầy đủ tính năng drag-drop, latex... -->
					<uc-slide-viewer-v3 
						v-if="activeInteractionSlideData" 
						:key="activeInteraction.id"
						:slide-data="activeInteractionSlideData" 
						@quiz-result="onInteractionQuizResult" />
				</v-card-text>
				<v-card-actions class="lh-dialog-actions border-t d-flex align-center ga-2 bg-slate-50">
					<button type="button" class="lh-custom-btn lh-btn-rewind flex-grow-1" @click="watchAgain">
						<v-icon size="small" class="mr-1">mdi-rewind-10</v-icon>
						<span>Xem lại (10s)</span>
					</button>
					<button type="button" class="lh-custom-btn lh-btn-continue flex-grow-1" :disabled="!isAnswerCorrect" @click="continueVideo">
						<span>Tiếp tục video</span>
						<v-icon size="small" class="ml-1">mdi-play</v-icon>
					</button>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>`,
    name: 'uc-media-player',
		inject: {
			snackbarRef: { default: null }
		},
		props: {
			url: {
				type: [String, Object],
				required: true
			},
			title: {
				type: String,
				default: ''
			},
			interactions: {
				type: [Array, String],
				default: () => []
			}
		},
		data() {
			return {
				playerId: 'yt-player-' + Math.random().toString(36).substring(2, 9),
				ytPlayer: null,
				mediaType: null, // 'youtube', 'video', 'audio', 'unknown'
				mediaUrl: '',
				currentProcessedUrl: '',
				currentVideoId: '',
				isLoading: true,
				error: null,
				
				// Trạng thái tương tác
				completedInteractions: [],
				// Chỉ marker đã thực sự được video đi tới mới được phép lộ nội dung câu hỏi.
				unlockedInteractionIds: [],
				activeInteraction: null,
				showInteractionOverlay: false,
				
				// Câu trả lời của học sinh
				studentSingleChoiceAnswer: null,
				studentMultipleChoiceAnswers: [],
				studentTrueFalseAnswers: {},
				studentBlankAnswers: {},
				
				videoPlaying: false,
				videoDuration: 0,
				videoCurrentTime: 0,
				
				lastWarningTime: 0,
				lastConfirmedTime: 0,
				dragStartTime: 0,
				isAnswered: false,
				isAnswerCorrect: false,
				timeCheckInterval: null,
				isDraggingSlider: false,
				lastTriggeredInteractionId: null
			}
		},
		watch: {
			url: {
				handler(newUrl) {
					this.processUrl(newUrl);
				},
				immediate: true
			}
		},
		computed: {
			hasQuestions() {
			return this.normalizedInteractions.length > 0;
		},
			unlockedInteractionCount() {
			return this.normalizedInteractions.filter(item => this.isInteractionUnlocked(item)).length;
		},
							normalizedInteractions() {
								let list = this.interactions;
				if (typeof list === 'string') {
					try {
						list = JSON.parse(list);
					} catch(e) {
						list = [];
					}
				}
								if (!Array.isArray(list)) list = [];
								return this.normalizeInteractionMarkers(list);
			},
			sortedInteractions() {
				return [...this.normalizedInteractions].sort((a, b) => a.time - b.time);
			},
			activeInteractionSlideData() {
				if (!this.activeInteraction) return null;
				return this.getInteractionSlideData(this.activeInteraction);
			}
		},
		mounted() {
			const self = this;
			window.onYouTubeIframeAPIReady = () => {
				if (self.mediaUrl && self.mediaType === 'youtube') {
					self.processUrl(self.mediaUrl);
				}
			};
			if (!window.YT) {
				const tag = document.createElement('script');
				tag.src = "https://www.youtube.com/iframe_api";
				const firstScriptTag = document.getElementsByTagName('script')[0];
				if (firstScriptTag && firstScriptTag.parentNode) {
					firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
				} else {
					document.head.appendChild(tag);
				}
			}
		},
		beforeUnmount() {
			this.stopTimeCheck();
			if (this.ytPlayer) {
				try {
					this.ytPlayer.destroy();
				} catch (e) {}
			}
		},
		methods: {
			// Dữ liệu học liệu cũ có thể truyền URL dưới dạng object; chuẩn hóa trước phép xử lý chuỗi.
			normalizeMediaUrl(value) {
				if (typeof value === 'string') return value.trim();
				if (typeof value === 'number') return String(value);
				if (!value || typeof value !== 'object') return '';
				for (const key of ['url', 'source', 'viewerSource', 'externalSource', 'audioUrl',
					'FILE_URL', 'fileUrl', 'FileURL', 'href', 'src']) {
					const nested = this.normalizeMediaUrl(value[key]);
					if (nested) return nested;
				}
				const videoId = this.normalizeMediaUrl(value.videoId);
				return videoId ? `https://www.youtube.com/watch?v=${videoId}` : '';
			},

			// Chuẩn hóa cả schema mới (một marker có questions[]) và schema cũ (mỗi interaction một question).
						// Các interaction phẳng cùng time được gom lại để không hiển thị/trả lời cùng một mốc nhiều lần.
						normalizeInteractionMarkers(list) {
							const grouped = [];
							const byTime = {};
							(list || []).forEach((raw, index) => {
				if (!raw || typeof raw !== 'object') return;
				// Câu bị đánh dấu inactive ở bước import không được tạo marker hoặc chặn video.
				if (raw.isActive === false) return;
								const time = Math.max(0, Math.floor(Number(raw.timeMarker ?? raw.timerMarker ?? raw.time) || 0));
								const key = String(time);
								let marker = byTime[key];
								if (!marker) {
									marker = { ...raw, id: raw.id || 'timer_marker_' + time + '_' + index, time: time, timeMarker: time, questions: [] };
									byTime[key] = marker;
									grouped.push(marker);
								}
								let questions = Array.isArray(raw.questions) ? raw.questions : (raw.question ? [raw.question] : [raw]);
				questions = questions.filter(question => question?.isActive !== false).map(question => {
									// interactions phẳng do Content Hub cũ phát ra có thêm wrapper question.
									return question && question.question && question.question.type ? question.question : question;
								});
								questions.forEach(question => {
									if (question && typeof question === 'object' && !marker.questions.includes(question)) marker.questions.push(question);
								});
								marker.question = marker.questions[0] || null;
								marker.prompt = marker.question?.content?.prompt || marker.prompt || '';
							});
				return grouped.filter(marker => marker.questions.length).sort((a, b) => a.time - b.time);
						},
						processUrl(urlStr) {
				urlStr = this.normalizeMediaUrl(urlStr);
				if (!urlStr) {
					this.error = "Không có đường dẫn media.";
					this.isLoading = false;
					return;
				}

				if (this.currentProcessedUrl === urlStr && (this.ytPlayer || this.mediaType)) {
					return;
				}
				this.currentProcessedUrl = urlStr;

				this.isLoading = true;
				this.error = null;
				this.completedInteractions = [];
				this.unlockedInteractionIds = [];
				this.activeInteraction = null;
				this.showInteractionOverlay = false;
				this.lastTriggeredInteractionId = null;
				this.stopTimeCheck();

				// Kiểm tra link Youtube
				try {
					let videoId = '';
					if (urlStr.includes('youtube.com') || urlStr.includes('youtu.be')) {
						const url = new URL(urlStr);
						if (url.pathname.includes('embed/')) {
							const urlSplit = url.pathname.split('embed/');
							videoId = urlSplit[1] ? urlSplit[1].split('?')[0].split('&')[0] : '';
						} else if (url.hostname.includes('youtube.com')) {
							videoId = url.searchParams.get('v');
						} else if (url.hostname.includes('youtu.be')) {
							videoId = url.pathname.slice(1).split('?')[0];
						}
						
						if (!videoId && url.pathname.includes('shorts/')) {
							const urlSplit = url.pathname.split('shorts/');
							videoId = urlSplit[1] ? urlSplit[1].split('?')[0].split('&')[0] : '';
						}
					}

					if (videoId) {
						this.mediaType = 'youtube';
						this.mediaUrl = `https://www.youtube.com/embed/${videoId}`;
						this.isLoading = false;
						this.$nextTick(() => {
							setTimeout(() => {
								this.initYoutubePlayer(videoId);
							}, 200);
						});
						return;
					}
				} catch (e) {
					console.warn('URL parsing error, falling back to file extensions', e);
				}

				let domain = '';
				try {
					if (typeof vueData !== 'undefined' && vueData?.v_Set) {
						domain = vueData.v_Set.urlReadFile || vueData.v_Set.urlReturnFile || '';
					}
				} catch(e) {}
				if (!domain && typeof window !== 'undefined' && window.vueData && window.vueData.v_Set) {
					domain = window.vueData.v_Set.urlReadFile || window.vueData.v_Set.urlReturnFile || '';
				}

				// Kiểm tra đuôi file audio
				const audioExtensions = ['.mp3', '.wav', '.ogg', '.m4a'];
				if (audioExtensions.some(ext => urlStr.toLowerCase().endsWith(ext))) {
					this.mediaType = 'audio';
					this.mediaUrl = urlStr.startsWith('http') ? urlStr : (domain + urlStr);
					this.isLoading = false;
					return;
				}

				// Kiểm tra đuôi file video
				const videoExtensions = ['.mp4', '.avi', '.mov', '.webm', '.m3u8'];
				if (videoExtensions.some(ext => urlStr.toLowerCase().endsWith(ext)) || urlStr.startsWith('http') || urlStr.startsWith('/')) {
					this.mediaType = 'video';
					this.mediaUrl = urlStr.startsWith('http') ? urlStr : (domain + urlStr);
					this.isLoading = false;
					return;
				}

				this.mediaType = 'unknown';
				this.error = "Định dạng media không được hỗ trợ.";
				this.isLoading = false;
			},

			ensureYoutubeApiLoaded() {
				if (window.YT && window.YT.Player) {
					return Promise.resolve(window.YT);
				}
				if (window.__ytApiPromise) {
					return window.__ytApiPromise;
				}
				window.__ytApiPromise = new Promise((resolve) => {
					const prev = window.onYouTubeIframeAPIReady;
					window.onYouTubeIframeAPIReady = () => {
						if (typeof prev === 'function') prev();
						resolve(window.YT);
					};
					if (!document.querySelector('script[src*="youtube.com/iframe_api"]')) {
						const tag = document.createElement('script');
						tag.src = "https://www.youtube.com/iframe_api";
						const firstScriptTag = document.getElementsByTagName('script')[0];
						if (firstScriptTag && firstScriptTag.parentNode) {
							firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
						} else {
							document.head.appendChild(tag);
						}
					}
				});
				return window.__ytApiPromise;
			},

			initYoutubePlayer(videoId) {
				if (this.currentVideoId === videoId && this.ytPlayer) {
					return;
				}
				this.currentVideoId = videoId;
				let self = this;
				this.ensureYoutubeApiLoaded().then(() => {
					if (self.ytPlayer) {
						try {
							self.ytPlayer.destroy();
						} catch(e) {}
						self.ytPlayer = null;
					}
					const init = () => {
						let playerEl = document.getElementById(self.playerId);
						const wrapper = self.$refs.ytWrapper || (playerEl ? playerEl.parentElement : document.querySelector('.video-preview-box'));
						if (wrapper && !playerEl) {
							playerEl = document.createElement('div');
							playerEl.id = self.playerId;
							playerEl.className = 'w-100 h-100';
							wrapper.insertBefore(playerEl, wrapper.firstChild);
						}
						if (document.getElementById(self.playerId) && window.YT && window.YT.Player) {
							self.ytPlayer = new window.YT.Player(self.playerId, {
								height: '100%',
								width: '100%',
								videoId: videoId,
								playerVars: {
									// Video thường dùng controls native; video có câu hỏi mới khóa controls để
									// timeline tùy chỉnh kiểm soát việc tua và dừng tại timerMarker.
									controls: self.hasQuestions ? 0 : 1,
									disablekb: self.hasQuestions ? 1 : 0,
									modestbranding: 1,
									rel: 0,
									cc_load_policy: 0,
									iv_load_policy: 3
								},
								events: {
									'onReady': self.onPlayerReady,
									'onStateChange': self.onPlayerStateChange
								}
							});
						}
					};

					let checkCount = 0;
					const checkYT = setInterval(() => {
						checkCount++;
						let el = document.getElementById(self.playerId);
						const wrapper = self.$refs.ytWrapper || (el ? el.parentElement : document.querySelector('.video-preview-box'));
						if (wrapper && !el) {
							el = document.createElement('div');
							el.id = self.playerId;
							el.className = 'w-100 h-100';
							wrapper.insertBefore(el, wrapper.firstChild);
						}
						if (window.YT && window.YT.Player && (el || document.getElementById(self.playerId))) {
							clearInterval(checkYT);
							init();
						} else if (checkCount > 150) {
							clearInterval(checkYT);
						}
					}, 100);
				});
			},

			onPlayerReady(event) {
				const player = event.target;
				this.ytPlayer = player;
				this.videoDuration = Math.floor(player.getDuration() || 0);
				this.disableYtCC(player);
				// Video thường cần polling để cập nhật timer tùy chỉnh; interaction cũng dùng polling để bắt mốc timeMarker.
				this.startTimeCheck();
			},

			onPlayerStateChange(event) {
				if (event.data === window.YT.PlayerState.PLAYING) {
					this.videoPlaying = true;
					this.startTimeCheck();
					this.disableYtCC(event.target);
				} else {
					this.videoPlaying = false;
					// Giữ polling khi có interaction để không bỏ sót mốc; video thường có thể dừng polling khi pause.
					if (this.hasQuestions && !this.timeCheckInterval) this.startTimeCheck();
					if (!this.hasQuestions) this.stopTimeCheck();
				}
			},

			disableYtCC(player) {
				if (!player) return;
				try {
					if (typeof player.unloadModule === 'function') {
						player.unloadModule('captions');
						player.unloadModule('cc');
					}
					if (typeof player.setOption === 'function') {
						player.setOption('captions', 'track', {});
						player.setOption('cc', 'track', {});
					}
				} catch (e) {
					console.warn("Lỗi tắt phụ đề YouTube", e);
				}
			},

			togglePlay() {
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube') {
					if (player && typeof player.getPlayerState === 'function') {
						try {
							const state = player.getPlayerState();
							if (state === 1) { // 1 = PLAYING
								player.pauseVideo();
								this.videoPlaying = false;
							} else {
								player.playVideo();
								this.videoPlaying = true;
							}
						} catch (e) {
							if (typeof player.playVideo === 'function') {
								if (this.videoPlaying) {
									player.pauseVideo();
									this.videoPlaying = false;
								} else {
									player.playVideo();
									this.videoPlaying = true;
								}
							}
						}
					} else if (player && typeof player.playVideo === 'function') {
						if (this.videoPlaying) {
							player.pauseVideo();
							this.videoPlaying = false;
						} else {
							player.playVideo();
							this.videoPlaying = true;
						}
					}
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					const htmlPlayer = this.$refs.htmlVideoPlayer;
					if (htmlPlayer.paused) {
						const promise = htmlPlayer.play();
						if (promise !== undefined) {
							promise.then(() => {
								this.videoPlaying = true;
							}).catch(e => {
								console.warn("Play request was interrupted or prevented", e);
								this.videoPlaying = false;
							});
						} else {
							this.videoPlaying = true;
						}
					} else {
						htmlPlayer.pause();
						this.videoPlaying = false;
					}
				}
			},

			showToast(msg, type = 'warning') {
				if (typeof Vue !== 'undefined' && Vue.$toast && typeof Vue.$toast[type] === 'function') {
					Vue.$toast[type](msg);
				} else if (this.$toast && typeof this.$toast[type] === 'function') {
					this.$toast[type](msg);
				} else if (typeof toastr !== 'undefined' && typeof toastr[type] === 'function') {
					toastr[type](msg);
				} else if (this.snackbarRef?.value?.showSnackbar) {
					this.snackbarRef.value.showSnackbar({
						message: msg,
						color: type === 'warning' ? 'warning' : type === 'success' ? 'success' : 'error'
					});
				} else {
					alert(msg);
				}
			},

			onTimelineTrackMouseDown(e) {
				if (e.target && e.target.closest && e.target.closest('.interaction-marker-dot')) {
					return;
				}
				const bar = this.$refs.timelineTrack;
				if (!bar) return;
				
				this.dragStartTime = this.lastConfirmedTime || this.videoCurrentTime;
				this.isDraggingSlider = true;
				const updateTimeFromEvent = (event) => {
					const rect = bar.getBoundingClientRect();
					const clientX = event.clientX || (event.touches && event.touches[0] ? event.touches[0].clientX : 0);
					let ratio = (clientX - rect.left) / rect.width;
					if (ratio < 0) ratio = 0;
					if (ratio > 1) ratio = 1;
					const dur = this.videoDuration || 1;
					this.videoCurrentTime = Math.floor(ratio * dur);
				};

				updateTimeFromEvent(e);

				const onMouseMove = (event) => {
					if (this.isDraggingSlider) {
						updateTimeFromEvent(event);
					}
				};

				const onMouseUp = () => {
					window.removeEventListener('mousemove', onMouseMove);
					window.removeEventListener('touchmove', onMouseMove);
					window.removeEventListener('mouseup', onMouseUp);
					window.removeEventListener('touchend', onMouseUp);
					if (this.isDraggingSlider) {
						this.isDraggingSlider = false;
						this.lastConfirmedTime = this.dragStartTime;
						this.seekVideo(this.videoCurrentTime);
					}
				};

				window.addEventListener('mousemove', onMouseMove);
				window.addEventListener('touchmove', onMouseMove);
				window.addEventListener('mouseup', onMouseUp);
				window.addEventListener('touchend', onMouseUp);
			},
			onVideoSliderEnd(val) {
				this.isDraggingSlider = false;
				let sec = val;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.videoCurrentTime;
				}
				this.seekVideo(sec);
			},
			onSliderChange(val) {
				let sec = val;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.videoCurrentTime;
				}
				this.seekVideo(sec);
			},
			seekVideo(seconds) {
				let sec = seconds;
				if (sec === undefined || sec === null || typeof sec === 'object' || isNaN(Number(sec))) {
					sec = this.videoCurrentTime;
				}
				sec = Math.floor(Number(sec) || 0);

				const unanswered = this.normalizedInteractions
					.filter(item => !this.completedInteractions.includes(item.id))
					.map(item => item.time);

				if (unanswered.length > 0) {
					const nextUnanswered = Math.min(...unanswered);
					if (sec > nextUnanswered) {
						sec = nextUnanswered;
						const now = Date.now();
						if (!this.lastWarningTime || now - this.lastWarningTime > 1500) {
							this.lastWarningTime = now;
							this.showToast("⚠️ Em không được tua vượt qua câu hỏi chưa trả lời nhé!", "warning");
						}
					}
				}

				this.videoCurrentTime = sec;
				this.lastConfirmedTime = sec;
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube' && player && typeof player.seekTo === 'function') {
					player.seekTo(sec, true);
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.currentTime = sec;
				}

				// Kiểm tra nếu mốc tua rơi vào câu hỏi chưa làm -> Kích hoạt câu hỏi ngay!
				const targetInteraction = this.normalizedInteractions.find(item => item.time === sec && !this.completedInteractions.includes(item.id));
				if (targetInteraction) {
					this.unlockInteraction(targetInteraction);
					this.lastTriggeredInteractionId = targetInteraction.id;
					this.triggerInteraction(targetInteraction);
				}
			},

			watchAgain() {
				if (!this.activeInteraction) return;
				const currentId = this.activeInteraction.id;
				const targetTime = Math.max(0, this.activeInteraction.time - 10);
				this.showInteractionOverlay = false;
				
				// Reset trạng thái để khi video tự phát lại tới mốc câu hỏi này sẽ tự động bật lại popup
				this.completedInteractions = this.completedInteractions.filter(id => id !== currentId);
				this.lastTriggeredInteractionId = null;

				this.seekVideo(targetTime);
				this.activeInteraction = null;
				
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube' && player && typeof player.playVideo === 'function') {
					player.playVideo();
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.play();
				}
			},

			formatTime(seconds) {
				if (!seconds || isNaN(seconds)) return '00:00';
				const h = Math.floor(seconds / 3600);
				const m = Math.floor((seconds % 3600) / 60);
				const s = Math.floor(seconds % 60);
				
				const mm = m < 10 ? '0' + m : m;
				const ss = s < 10 ? '0' + s : s;
				
				if (h > 0) {
					const hh = h < 10 ? '0' + h : h;
					return `${hh}:${mm}:${ss}`;
				}
				return `${mm}:${ss}`;
			},

			getInteractionType(item) {
						if (!item) return 'QUIZ_SINGLE_CHOICE';
						if (Array.isArray(item.questions) && item.questions.length > 1) return 'QUIZ_COMPOSITE';
				if (item.question && item.question.type) return item.question.type;
				if (item.questions?.[0]?.type) return item.questions[0].type;
				if (item.type) return item.type;
				return 'QUIZ_SINGLE_CHOICE';
			},

					getInteractionSlideData(item) {
						if (!item) return null;
						if (Array.isArray(item.questions) && item.questions.length > 1) {
							// uc-quiz-composite đã xử lý tuần tự nhiều loại câu hỏi; dùng nó cho toàn bộ câu trong một timeMarker.
							return {
								type: 'QUIZ_COMPOSITE',
								content: {
									title: 'Câu hỏi tương tác tại ' + this.formatTime(item.time),
									isInteractiveMode: true,
															questions: item.questions.map(question => {
																const slide = this.getInteractionSlideData(question);
																return slide ? { ...slide, id: question.id || undefined } : null;
															}).filter(Boolean)
								}
							};
						}
						let type = this.getInteractionType(item);
				
				// Hợp nhất các nguồn dữ liệu câu hỏi từ nhiều cấu trúc lưu trữ khác nhau
				let rawContent = {
					...(item || {}),
					...(item.config || {}),
					...(item.question?.config || {}),
					...(item.question?.content || {}),
					...(item.content || {})
				};

				// Trích xuất prompt câu hỏi
				let prompt = rawContent.prompt || rawContent.questionText || item.prompt || item.questionText || item.title || '';

				// Trích xuất options/choices
				let options = rawContent.options || rawContent.choices || item.options || item.question?.options || [];
				if (Array.isArray(options)) {
					options = options.map((opt, idx) => {
						if (typeof opt === 'string') {
							return { id: 'opt_' + idx, text: opt };
						}
						return {
							...opt,
							id: opt.id !== undefined && opt.id !== null ? opt.id : ('opt_' + idx),
							text: opt.text !== undefined ? opt.text : (opt.label || opt.value || opt.content || '')
						};
					});
				} else {
					options = [];
				}

				// Xử lý riêng cho từng dạng câu hỏi để uc-slide-viewer-v3 render mượt mà
				let content = {
					...rawContent,
					prompt: prompt,
					options: options,
					isInteractiveMode: true
				};

				// Các dạng đặc thù:
				if (type === 'QUIZ_ORDERING') {
					content.items = rawContent.items || options || [];
				} else if (type === 'QUIZ_MATCHING') {
					content.columnA = rawContent.columnA || rawContent.leftItems || rawContent.itemsA || [];
					content.columnB = rawContent.columnB || rawContent.rightItems || rawContent.itemsB || [];
					content.correctPairs = rawContent.correctPairs || rawContent.pairs || [];
				} else if (type === 'QUIZ_CONNECTION') {
					content.groups = rawContent.groups || [];
					content.items = rawContent.items || [];
				} else if (type === 'QUIZ_DRAG_DROP_CATEGORIZE') {
					content.categories = rawContent.categories || [];
					content.items = rawContent.items || [];
				} else if (type === 'QUIZ_FILL_IN_BLANK') {
					content.parts = rawContent.parts || [];
				}

				return {
					type: type,
					content: content
				};
			},

			getTypeName(type) {
				if (type === 'QUIZ_SINGLE_CHOICE') return 'Trắc nghiệm đơn';
				if (type === 'QUIZ_MULTIPLE_CHOICE') return 'Trắc nghiệm nhiều lựa chọn';
				if (type === 'QUIZ_TRUE_FALSE') return 'Đúng sai';
				if (type === 'QUIZ_FILL_IN_BLANK') return 'Điền từ';
				if (type === 'QUIZ_MATCHING') return 'Ghép nối';
				if (type === 'QUIZ_ORDERING') return 'Sắp xếp';
				if (type === 'QUIZ_CONNECTION') return 'Nối cặp';
				if (type === 'QUIZ_DRAG_DROP_CATEGORIZE') return 'Phân loại';
				if (type === 'QUIZ_COMPOSITE') return 'Tổ hợp nhiều câu hỏi';
				return 'Câu hỏi';
			},

			getTypeBadgeColor(type) {
				if (type === 'QUIZ_SINGLE_CHOICE') return '#059669';
				if (type === 'QUIZ_MULTIPLE_CHOICE') return '#0284c7';
				if (type === 'QUIZ_TRUE_FALSE') return '#7c3aed';
				if (type === 'QUIZ_FILL_IN_BLANK') return '#d97706';
				if (type === 'QUIZ_MATCHING') return '#db2777';
				if (type === 'QUIZ_ORDERING') return '#4f46e5';
				if (type === 'QUIZ_CONNECTION') return '#0d9488';
				if (type === 'QUIZ_DRAG_DROP_CATEGORIZE') return '#ea580c';
				if (type === 'QUIZ_COMPOSITE') return '#f43f5e';
				return '#475569';
			},

			onInteractionQuizResult(res) {
				console.log('onInteractionQuizResult:', res);
				const result = res?.result && typeof res.result === 'object' ? res.result : res;
				const isCorrect = !!(result && (result.result === true || result.isCorrect === true || result.passed === true));
				this.isAnswerCorrect = isCorrect;
				if (isCorrect && this.activeInteraction) {
					if (!this.completedInteractions.includes(this.activeInteraction.id)) {
						this.completedInteractions.push(this.activeInteraction.id);
					}
				}
			},

			startTimeCheck() {
				if (this.mediaType !== 'youtube') return;
				if (this.timeCheckInterval) return;
				this.timeCheckInterval = setInterval(() => {
					const player = this.ytPlayer;
					if (player && typeof player.getDuration === 'function') {
						const dur = Math.floor(player.getDuration() || 0);
						if (dur > 0 && this.videoDuration !== dur) {
							this.videoDuration = dur;
						}
					}
					if (!this.isDraggingSlider && this.mediaType === 'youtube' && player && typeof player.getCurrentTime === 'function') {
						const currentTime = Math.floor(player.getCurrentTime());
						this.videoCurrentTime = currentTime;
						this.lastConfirmedTime = currentTime;
						const interaction = this.hasQuestions
							? this.normalizedInteractions.find(item => currentTime >= item.time && currentTime <= item.time + 1 && !this.completedInteractions.includes(item.id))
							: null;
						if (interaction && this.lastTriggeredInteractionId !== interaction.id) {
							this.unlockInteraction(interaction);
							this.lastTriggeredInteractionId = interaction.id;
							this.videoCurrentTime = interaction.time;
							this.triggerInteraction(interaction);
						}
					}
				}, 300);
			},

			stopTimeCheck() {
				if (this.timeCheckInterval) {
					clearInterval(this.timeCheckInterval);
					this.timeCheckInterval = null;
				}
			},

			onHtmlVideoTimeUpdate(event) {
				const video = event.target;
				const currentTime = Math.floor(video.currentTime);
				this.videoCurrentTime = currentTime;
				this.lastConfirmedTime = currentTime;
				if (!this.hasQuestions) return;
				const interaction = this.normalizedInteractions.find(item => currentTime >= item.time && currentTime <= item.time + 1 && !this.completedInteractions.includes(item.id));
			if (interaction && this.lastTriggeredInteractionId !== interaction.id) {
					this.unlockInteraction(interaction);
					this.lastTriggeredInteractionId = interaction.id;
					this.videoCurrentTime = interaction.time;
					video.pause();
					this.triggerInteraction(interaction);
				}
			},

			onHtmlVideoMetadata(event) {
				this.videoDuration = Math.floor(event.target.duration || 0);
			},

			sanitizeSvgHtml(str) {
				if (!str || typeof str !== 'string') return str || '';
				return str
					.replace(/%22(https?:\/\/[^"'\s\\]+)/gi, '$1')
					.replace(/[\\]+["']/g, '"')
					.replace(/=\\?"+([^"\\]+)\\?"+/g, '="$1"')
					.replace(/="""+/g, '="');
			},

			stripHtml(html) {
				if (!html) return '';
				return html.replace(/<[^>]*>?/gm, '').trim();
			},

			unlockInteraction(interaction) {
				if (!interaction || this.unlockedInteractionIds.includes(interaction.id)) return;
				this.unlockedInteractionIds.push(interaction.id);
			},

			isInteractionUnlocked(interaction) {
				if (!interaction) return false;
				return this.unlockedInteractionIds.includes(interaction.id)
					|| this.completedInteractions.includes(interaction.id);
			},

			getQuestionPrompt(question) {
				return question?.content?.prompt
					|| question?.config?.questionText
					|| question?.prompt
					|| question?.questionText
					|| '';
			},

			triggerInteraction(interaction) {
				this.unlockInteraction(interaction);
				this.stopTimeCheck();
				this.videoPlaying = false;
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube' && player && typeof player.pauseVideo === 'function') {
					try {
						player.pauseVideo();
					} catch(e) {}
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.pause();
				}
				this.activeInteraction = interaction;
				
				this.studentSingleChoiceAnswer = null;
				this.studentMultipleChoiceAnswers = [];
				this.studentTrueFalseAnswers = {};
				this.studentBlankAnswers = {};
				
				if (interaction.question?.type === 'QUIZ_TRUE_FALSE' && interaction.question.content?.options) {
					interaction.question.content.options.forEach(opt => {
						this.studentTrueFalseAnswers[opt.id] = null;
					});
				}
				
				this.isAnswered = false;
				this.isAnswerCorrect = false;
				this.showInteractionOverlay = true;
			},

			submitAnswer() {
				if (!this.activeInteraction || !this.activeInteraction.question) return;
				const type = this.activeInteraction.question.type;
				const content = this.activeInteraction.question.content;
				let isCorrect = false;

				if (type === 'QUIZ_SINGLE_CHOICE') {
					isCorrect = this.studentSingleChoiceAnswer === content.correctAnswer;
				} else if (type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = content.correctAnswers || [];
					isCorrect = correctAnswers.length === this.studentMultipleChoiceAnswers.length && 
						correctAnswers.every(ans => this.studentMultipleChoiceAnswers.includes(ans));
				} else if (type === 'QUIZ_TRUE_FALSE') {
					isCorrect = content.options.every(opt => this.studentTrueFalseAnswers[opt.id] === opt.correctAnswer);
				} else if (type === 'QUIZ_FILL_IN_BLANK') {
					isCorrect = content.parts.every((part, idx) => {
						if (part.type !== 'blank') return true;
						return (this.studentBlankAnswers[idx] || '').trim().toLowerCase() === part.correctAnswer.trim().toLowerCase();
					});
				}

				this.isAnswered = true;
				this.isAnswerCorrect = isCorrect;

				if (isCorrect) {
					this.showToast("Chính xác!", "success");
				} else {
					this.showToast("Đáp án chưa chính xác. Vui lòng chọn lại!", "error");
				}
			},

			continueVideo() {
				if (!this.isAnswerCorrect) {
					this.showToast("⚠️ Em phải trả lời đúng câu hỏi mới được tiếp tục video nhé!", "warning");
					return;
				}
				let resumeTime = this.videoCurrentTime;
				if (this.activeInteraction) {
					if (!this.completedInteractions.includes(this.activeInteraction.id)) {
						this.completedInteractions.push(this.activeInteraction.id);
					}
					resumeTime = Number(this.activeInteraction.time) || this.videoCurrentTime;
				}
				this.showInteractionOverlay = false;
				this.activeInteraction = null;
				this.isAnswered = false;
				this.isAnswerCorrect = false;
				this.lastTriggeredInteractionId = null;
				
				this.videoCurrentTime = resumeTime;
				this.lastConfirmedTime = resumeTime;

				// Resume phát video từ chính mốc câu hỏi vừa hoàn thành
				const player = this.ytPlayer;
				if (this.mediaType === 'youtube' && player && typeof player.playVideo === 'function') {
					if (typeof player.seekTo === 'function') {
						player.seekTo(resumeTime, true);
					}
					player.playVideo();
					this.videoPlaying = true;
					this.startTimeCheck();
				} else if (this.mediaType === 'video' && this.$refs.htmlVideoPlayer) {
					this.$refs.htmlVideoPlayer.currentTime = resumeTime;
					const promise = this.$refs.htmlVideoPlayer.play();
					if (promise !== undefined) {
						promise.catch(e => console.warn(e));
					}
					this.videoPlaying = true;
				}
			},

			getOptionStyle(opt) {
				if (!this.activeInteraction || !this.activeInteraction.question) return {};
				const type = this.activeInteraction.question.type;
				const content = this.activeInteraction.question.content;

				let isCorrect = false;
				let isChosen = false;

				if (type === 'QUIZ_SINGLE_CHOICE') {
					isCorrect = opt.id === content.correctAnswer;
					isChosen = opt.id === this.studentSingleChoiceAnswer;
				} else if (type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = content.correctAnswers || [];
					isCorrect = correctAnswers.includes(opt.id);
					isChosen = this.studentMultipleChoiceAnswers.includes(opt.id);
				}

				if (isCorrect) {
					return { borderColor: '#4caf50', backgroundColor: '#e8f5e9', borderWidth: '2px' };
				}
				if (isChosen && !isCorrect) {
					return { borderColor: '#f44336', backgroundColor: '#ffebee', borderWidth: '2px' };
				}
				return { borderColor: '#e0e0e0', backgroundColor: '#ffffff' };
			},

			getOptionIcon(opt) {
				if (!this.activeInteraction || !this.activeInteraction.question) return 'mdi-circle-outline';
				const type = this.activeInteraction.question.type;
				const content = this.activeInteraction.question.content;

				let isCorrect = false;
				let isChosen = false;

				if (type === 'QUIZ_SINGLE_CHOICE') {
					isCorrect = opt.id === content.correctAnswer;
					isChosen = opt.id === this.studentSingleChoiceAnswer;
				} else if (type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = content.correctAnswers || [];
					isCorrect = correctAnswers.includes(opt.id);
					isChosen = this.studentMultipleChoiceAnswers.includes(opt.id);
				}

				if (isCorrect) return 'mdi-check-circle';
				if (isChosen) return 'mdi-close-circle';
				return 'mdi-circle-outline';
			},

			getOptionIconColor(opt) {
				if (!this.activeInteraction || !this.activeInteraction.question) return 'grey';
				const type = this.activeInteraction.question.type;
				const content = this.activeInteraction.question.content;

				let isCorrect = false;
				let isChosen = false;

				if (type === 'QUIZ_SINGLE_CHOICE') {
					isCorrect = opt.id === content.correctAnswer;
					isChosen = opt.id === this.studentSingleChoiceAnswer;
				} else if (type === 'QUIZ_MULTIPLE_CHOICE') {
					const correctAnswers = content.correctAnswers || [];
					isCorrect = correctAnswers.includes(opt.id);
					isChosen = this.studentMultipleChoiceAnswers.includes(opt.id);
				}

				if (isCorrect) return 'success';
				if (isChosen) return 'error';
				return 'grey';
			}
		}
  };
  Vue.component("uc-media-player", compDef);
})();

;(function() {
  const compDef = {
    template: `<!-- Office / PPT / PDF Reader Container chiếm trọn 100% viewport -->
	<div
		ref="officeReaderContainer"
		class="office-reader-container fill-height w-100 pa-0 ma-0"
		:class="{ 'office-reader-fullscreen': isFullscreen }"
		:data-zoom="zoomPercent"
	>
		<div v-if="isLoading" class="loading-overlay">
			<v-progress-circular indeterminate size="64" color="primary"></v-progress-circular>
			<p class="mt-4 text-grey-darken-1">Đang tải tài liệu...</p>
		</div>

		<!-- <div v-if="" class="docx" id="docx-container"></div> -->
		<iframe
			v-else
			:src="viewerUrl"
			class="office-iframe fill-height w-100 pa-0 ma-0"
			frameborder="0"
			allow="fullscreen"
			allowfullscreen
			@load="onIframeLoad"
			@error="onIframeError"
		></iframe>

		<!-- External viewer không dùng được toolbar của HTML/PDF nên có bộ điều khiển riêng ở lớp ngoài iframe. -->
		<div
			v-if="viewerUrl && !error"
			class="lh-floating-controls office-reader-controls"
			:class="{ 'lh-controls-fullscreen': isFullscreen }"
		>
			<button class="lh-tool-btn" @click="zoomOut" title="Thu nhỏ">
				<v-icon size="16">mdi-magnify-minus-outline</v-icon>
			</button>
			<button class="lh-tool-btn lh-zoom-badge" @click="resetZoom" title="Đặt lại kích thước chuẩn">
				{{ zoomPercent }}%
			</button>
			<button class="lh-tool-btn" @click="zoomIn" title="Phóng to">
				<v-icon size="16">mdi-magnify-plus-outline</v-icon>
			</button>
			<div class="lh-tool-divider"></div>
			<button
				class="lh-tool-btn lh-fullscreen-toggle-btn"
				@click="toggleFullscreen"
				:title="isFullscreen ? 'Thoát toàn màn hình (Esc)' : 'Toàn màn hình'"
			>
				<v-icon size="18">{{ isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
			</button>
		</div>

		<div v-if="error" class="error-overlay">
			<v-icon color="warning" size="64">mdi-cloud-alert-outline</v-icon>
			<p class="mt-4 font-weight-medium text-body-1">{{ error }}</p>
			<div class="mt-6 d-flex ga-3">
				<v-btn color="primary" :href="fileUrl" target="_blank" prepend-icon="mdi-download">
					Tải về
				</v-btn>
				<!-- THÊM NÚT THỬ LẠI Ở ĐÂY -->
				<v-btn variant="tonal" @click="retryLoad" prepend-icon="mdi-refresh">
					Thử lại
				</v-btn>
			</div>
		</div>
	</div>`,
    name: 'uc-office-reader',
		props: {
			fileUrl: {
				type: String,
				required: true
			},
			fileType: {
				type: String,
				default: ''
			}
		},
		data() {
			return {
				viewerUrl: '',
				isLoading: false,//true,
				error: null,
				zoomLevel: 1,
				isFullscreen: false,
				vueData,
				window,
				_fileUrl: this.fileUrl
			}
		},
		mounted() {
			this.generateViewerUrl(this._fileUrl);
			document.addEventListener('fullscreenchange', this.onFullscreenChange);
		},
		beforeUnmount() {
			document.removeEventListener('fullscreenchange', this.onFullscreenChange);
		},
		watch: {
			fileUrl(newVal) {
				this._fileUrl = newVal;
				this.generateViewerUrl(newVal);
			}
		},
		computed: {
			zoomPercent() {
				return Math.round(this.zoomLevel * 100);
			},
			nameFile: function () {
				let name = ''
				if (this.fileUrl.includes('drive.google.com')) {
					name = 'drive'
				}
				else if (!this.fileUrl.includes("http")) {
	
				}
				return name
			}
		},
		methods: {
			zoomIn() {
				const steps = [0.5, 0.65, 0.8, 0.9, 1, 1.15, 1.3, 1.5, 1.75, 2, 2.5];
				const next = steps.find(step => step > this.zoomLevel + 0.001);
				if (next) this.zoomLevel = next;
			},
			zoomOut() {
				const steps = [0.5, 0.65, 0.8, 0.9, 1, 1.15, 1.3, 1.5, 1.75, 2, 2.5];
				const previous = [...steps].reverse().find(step => step < this.zoomLevel - 0.001);
				if (previous) this.zoomLevel = previous;
			},
			resetZoom() {
				this.zoomLevel = 1;
			},
			async toggleFullscreen() {
				const container = this.$refs.officeReaderContainer;
				if (!container) return;

				try {
					if (document.fullscreenElement) {
						await document.exitFullscreen();
					} else if (container.requestFullscreen) {
						await container.requestFullscreen();
					} else {
						this.isFullscreen = !this.isFullscreen;
					}
				} catch (error) {
					// Một số trình duyệt/iframe chặn Fullscreen API; fallback CSS vẫn mở rộng viewer trong viewport.
					this.isFullscreen = !this.isFullscreen;
				}
			},
			onFullscreenChange() {
				const container = this.$refs.officeReaderContainer;
				this.isFullscreen = !!container && document.fullscreenElement === container;
			},
			async renderDocxFromUrl(url, containerId) {
				try {
					const response = await fetch(url, {
						headers: {
							"Authorization": $awt,
						}
					});
	
					if (!response.ok) {
						throw new Error(`Failed to fetch file from URL: ${url} - Status: ${response.status}`);
					}
	
					const arrayBuffer = await response.arrayBuffer();
					const container = document.getElementById(containerId);
	
					//document, bodyContainer, styleContainer = null, options
					await window.docx.renderAsync(arrayBuffer, container, null, {
						debug: true,
						experimental: true,
						className: "docx"
					});
	
					console.log("✅ DOCX rendered successfully.");
	
				} catch (err) {
					console.error("❌ Error rendering DOCX:", err);
				}
			},
			generateViewerUrl(url) {
				this.isLoading = true;
				this.error = null;
	
				if (!url) {
					this.error = "Không có đường dẫn file.";
					this.isLoading = false;
					return;
				}
	
				let absoluteUrl = url;
				if (!/^https?:\/\//i.test(url)) {
					const baseUrl = vueData?.v_Set?.urlReturnFile || vueData?.v_Set?.urlReadFile || '';
					absoluteUrl = baseUrl
						? `${String(baseUrl).replace(/\/$/, '')}/${String(url).replace(/^\//, '')}`
						: url;
				}

				// Giữ viewer Office mặc định cho URL file Office trực tiếp; các nguồn ngoài có
				// format embed riêng phải chuẩn hóa trước, nếu không iframe có thể chỉ hiện URL thô.
				this.viewerUrl = this.resolveExternalViewerUrl(absoluteUrl);
				this.isLoading = false
			},
			resolveExternalViewerUrl(absoluteUrl) {
				const sourceUrl = String(absoluteUrl || '');
				const encodedUrl = encodeURIComponent(sourceUrl);

				// Google Slides cần endpoint embed; không nhúng trực tiếp trang /edit hoặc /preview.
				const googleSlidesId = sourceUrl.match(/docs\.google\.com\/presentation\/d\/([^/?#]+)/i)?.[1];
				if (googleSlidesId) {
					return `https://docs.google.com/presentation/d/${encodeURIComponent(googleSlidesId)}/embed?start=false&loop=false&delayms=3000`;
				}

				// Google Docs/Sheets dùng preview riêng để tránh nhúng trang chỉnh sửa.
				const googleDocumentMatch = sourceUrl.match(/docs\.google\.com\/(document|spreadsheets)\/d\/([^/?#]+)/i);
				if (googleDocumentMatch) {
					return `https://docs.google.com/${googleDocumentMatch[1]}/d/${encodeURIComponent(googleDocumentMatch[2])}/preview`;
				}

				// Drive file phải chuyển /view hoặc /uc sang /preview giống luồng Content Hub.
				const driveFileId = sourceUrl.match(/drive\.google\.com\/file\/d\/([^/?#]+)/i)?.[1]
					|| (() => {
						try {
							const parsed = new URL(sourceUrl);
							return /(?:^|\.)drive\.google\.com$/i.test(parsed.hostname) ? parsed.searchParams.get('id') : '';
						} catch (error) {
							return '';
						}
					})();
				if (driveFileId) {
					return `https://drive.google.com/file/d/${encodeURIComponent(driveFileId)}/preview`;
				}

				// Canva thường lưu link /edit kèm query tracking; đổi sang /view?embed để iframe hiển thị thiết kế.
				if (/canva\.com/i.test(sourceUrl)) {
					try {
						const parsed = new URL(sourceUrl);
						const designMatch = parsed.pathname.match(/\/design\/([^/]+)/i);
						if (designMatch) {
							let embedPath = parsed.pathname.replace(/\/+$/, '');
							embedPath = embedPath.replace(/\/(?:edit|watch)$/i, '/view');
							if (!/\/view$/i.test(embedPath)) embedPath += '/view';
							return `${parsed.origin}${embedPath}?embed`;
						}
					} catch (error) {
						console.warn('Canva URL không hợp lệ:', sourceUrl);
					}
				}

				return `https://view.officeapps.live.com/op/embed.aspx?src=${encodedUrl}`;
			},
			onIframeLoad() {
				setTimeout(() => {
					this.isLoading = false;
				}, 1500); // Giảm thời gian chờ một chút
			},
			onIframeError() {
				this.isLoading = false;
				this.error = "Không thể hiển thị bản xem trước. File có thể không truy cập được hoặc có lỗi tạm thời.";
			},
			// THÊM HÀM MỚI ĐỂ TẢI LẠI
			retryLoad() {
				// Đặt lại viewerUrl để buộc iframe tải lại hoàn toàn
				const urlToReload = this.viewerUrl;
				this.viewerUrl = ''; // Xóa URL cũ để iframe reset
				this.$nextTick(() => {
					this.isLoading = true;
					this.error = null;
					this.viewerUrl = urlToReload; // Gán lại URL mới để kích hoạt tải lại
				});
			}
		}
  };
  Vue.component("uc-office-reader", compDef);
})();

;(function() {
  const compDef = {
    template: `<div class="pdf-book-reader" ref="bookContainer">
		<!-- Loading State -->
		<div v-if="this.isLoading" class="book-loading">
			<v-progress-circular indeterminate size="64" color="primary"></v-progress-circular>
			<p class="mt-4">Đang tải sách...</p>
		</div>

		<!-- Error State -->
		<div v-else-if="this.error" class="book-error">
			<v-icon size="64" color="error">mdi-book-alert</v-icon>
			<p class="mt-2 error--text">{{ this.error }}</p>
			<v-btn @click="retryLoad" color="primary" class="mt-2">Thử lại</v-btn>
		</div>

		<!-- Book Reader -->
		<div v-else class="book-container">
			<!-- Book Spine and Binding -->
			<div class="book-spine"></div>

			<!-- Book Pages Container -->
			<div class="book-pages" ref="bookPages">
				<!-- Thumbnails Sidebar -->
				<div v-if="this.showThumbnails" class="book-thumbnails">
					<div class="thumbnails-header">
						<h4>Mục lục</h4>
						<v-btn icon small @click="showThumbnails = false">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</div>
					<div class="thumbnails-list">
						<div v-for="page in this.totalPages" :key="page" class="thumbnail-item"
							:class="{ 'active': page === this.currentPage }" @click="goToPage(page)">
							<div class="thumbnail-preview">
								<div class="thumbnail-placeholder">{{ page }}</div>
							</div>
							<div class="thumbnail-number">{{ page }}</div>
						</div>
					</div>
				</div>

				<!-- Main Book Area -->
				<div class="main-book-area" :style="{ marginLeft: this.showThumbnails ? '250px' : '0' }">
					<!-- Left Page (Even pages) -->
					<div class="page-left" :class="{ 'page-visible': this.isDoublePage && this.currentPage > 1 }">
						<canvas ref="leftCanvas" class="page-canvas" @click="prevPage"></canvas>
						<div class="page-number left">{{ this.isDoublePage && this.currentPage > 1 ? this.currentPage -
							1 : '' }}</div>
					</div>

					<!-- Right Page (Odd pages) -->
					<div class="page-right page-visible">
						<canvas ref="rightCanvas" class="page-canvas" @click="nextPage"></canvas>
						<div class="page-number right">{{ this.currentPage }}</div>
					</div>
				</div>
			</div>

			<!-- Controls -->
			<div class="book-controls">
				<!-- Navigation -->
				<div class="nav-controls">
					<v-btn icon :disabled="this.currentPage <= (this.isDoublePage ? 2 : 1)" @click="prevPage"
						title="Trang trước">
						<v-icon>mdi-chevron-left</v-icon>
					</v-btn>

					<div class="page-info">
						<span v-if="this.isDoublePage && this.currentPage > 1">
							{{ this.currentPage - 1 }}-{{ this.currentPage }} / {{ this.totalPages }}
						</span>
						<span v-else>
							{{ this.currentPage }} / {{ this.totalPages }}
						</span>
					</div>

					<v-btn icon :disabled="this.currentPage >= this.totalPages" @click="nextPage" title="Trang sau">
						<v-icon>mdi-chevron-right</v-icon>
					</v-btn>
				</div>

				<!-- View Controls -->
				<div class="view-controls">
					<v-btn icon @click="toggleDoublePage" :color="this.isDoublePage ? 'primary' : 'default'"
						title="Chế độ 2 trang">
						<v-icon>mdi-book-open-page-variant</v-icon>
					</v-btn>

					<v-btn icon @click="showThumbnails = !showThumbnails"
						:color="this.showThumbnails ? 'primary' : 'default'" title="Mục lục">
						<v-icon>mdi-view-list</v-icon>
					</v-btn>

					<v-btn icon @click="toggleFullscreen" title="Toàn màn hình">
						<v-icon>{{ this.isFullscreen ? 'mdi-fullscreen-exit' : 'mdi-fullscreen' }}</v-icon>
					</v-btn>
				</div>

				<!-- Zoom Controls -->
				<div class="zoom-controls">
					<v-btn icon @click="zoomOut" title="Thu nhỏ">
						<v-icon>mdi-minus</v-icon>
					</v-btn>
					<span class="zoom-level">{{ Math.round(this.scale * 100) }}%</span>
					<v-btn icon @click="zoomIn" title="Phóng to">
						<v-icon>mdi-plus</v-icon>
					</v-btn>
					<v-btn icon @click="fitToPage" title="Vừa trang">
						<v-icon>mdi-fit-to-page</v-icon>
					</v-btn>
				</div>
			</div>
		</div>
	</div>`,
    name: 'uc-pdf-book-reader',
	props: {
		pdfUrl: {
			type: String,
			required: true
		},
		initialPage: {
			type: Number,
			default: 1
		}
	},
	emits: ['page-changed'],
	data() {
		return {
			// UI State
			currentPage: 2, // Start at page 2 to show pages 1-2
			totalPages: 0,
			isLoading: true,
			error: null,
			scale: 1.0,
			isDoublePage: true, // Start with double page mode
			showThumbnails: false,
			isFullscreen: false,
			
			// Page flip animation
			isFlipping: false,
			flipDirection: 'next',
			
			// Throttling
			lastEmitTime: 0,
			emitThrottle: 1000
		}
	},
	async mounted() {
		console.log('🚀 Component mounted');
		
		// Initialize PDF components directly in component
		this.initPDFComponents();
		
		// Load PDF
		await this.initializePDF();
		
		// Setup keyboard shortcuts
		this.setupKeyboardShortcuts();
		
		// Add manual render button to window for debugging (remove in production)
		if (typeof window !== 'undefined') {
			window.manualRender = () => this.manualRender();
		}
	},
	beforeDestroy() {
		this.cleanup();
	},
	methods: {
		initPDFComponents() {
			// Store non-reactive PDF components
			this._pdfDocument = null;
			this._pageCache = new Map();
			this._isReady = false;
		},

		async ensurePDFJSLoaded() {
			if (this._isReady) return true;

			try {
				if (!window.pdfjsLib) {
					const script = document.createElement('script');
					script.src = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js';
					
					await new Promise((resolve, reject) => {
						script.onload = resolve;
						script.onerror = reject;
						document.head.appendChild(script);
					});
				}

				if (window.pdfjsLib) {
					window.pdfjsLib.GlobalWorkerOptions.workerSrc = 
						'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
					this._isReady = true;
					return true;
				}
				return false;
			} catch (error) {
				console.error('Failed to load PDF.js:', error);
				return false;
			}
		},

		async loadPDFDocument(url, onProgress) {
			if (!this._isReady) {
				throw new Error('PDF.js not ready');
			}

			try {
				const loadingTask = window.pdfjsLib.getDocument({
					url: url,
					disableWorker: true,
					disableRange: true,
					disableStream: true,
					isEvalSupported: false
				});

				if (onProgress) {
					loadingTask.onProgress = onProgress;
				}

				this._pdfDocument = await loadingTask.promise;
				return this._pdfDocument.numPages;
			} catch (error) {
				console.error('PDF loading error:', error);
				throw error;
			}
		},

		async renderPageToCanvas(pageNumber, canvas, scale = 1.0) {
			if (!this._pdfDocument || !canvas) {
				throw new Error('PDF document or canvas not available');
			}

			try {
				// Check cache
				const cacheKey = `${pageNumber}_${scale}`;
				const cached = this._pageCache.get(cacheKey);
				
				if (cached) {
					const ctx = canvas.getContext('2d');
					canvas.width = cached.width;
					canvas.height = cached.height;
					ctx.putImageData(cached.imageData, 0, 0);
					return;
				}

				// Get page
				const page = await this._pdfDocument.getPage(pageNumber);
				const viewport = page.getViewport({ scale });
				
				// Setup canvas
				const context = canvas.getContext('2d');
				canvas.width = viewport.width;
				canvas.height = viewport.height;
				
				// Clear canvas
				context.fillStyle = 'white';
				context.fillRect(0, 0, canvas.width, canvas.height);

				// Render
				const renderContext = {
					canvasContext: context,
					viewport: viewport
				};

				await page.render(renderContext).promise;

				// Cache result
				try {
					const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
					this._pageCache.set(cacheKey, {
						width: canvas.width,
						height: canvas.height,
						imageData: imageData
					});
				} catch (e) {
					console.warn('Caching failed:', e);
				}

			} catch (error) {
				console.error(`Error rendering page ${pageNumber}:`, error);
				this.renderErrorToCanvas(canvas, pageNumber);
			}
		},

		renderErrorToCanvas(canvas, pageNumber) {
			const ctx = canvas.getContext('2d');
			canvas.width = 400;
			canvas.height = 300;
			
			ctx.fillStyle = '#f5f5f5';
			ctx.fillRect(0, 0, canvas.width, canvas.height);
			
			ctx.fillStyle = '#666';
			ctx.font = '16px Arial';
			ctx.textAlign = 'center';
			ctx.fillText(`Lỗi tải trang ${pageNumber}`, canvas.width / 2, canvas.height / 2);
		},

		async initializePDF() {
			try {
				this.isLoading = true;
				this.error = null;

				// Initialize PDF.js
				const pdfReady = await this.ensurePDFJSLoaded();
				if (!pdfReady) {
					throw new Error('Failed to initialize PDF.js');
				}

				// Load PDF with progress callback
				const totalPages = await this.loadPDFDocument(
					this.pdfUrl,
					(progress) => {
						if (progress.total > 0) {
							const percent = Math.round((progress.loaded / progress.total) * 100);
							console.log(`Loading: ${percent}%`);
						}
					}
				);

				this.totalPages = totalPages;
				this.currentPage = Math.max(2, Math.min(this.initialPage || 2, totalPages)); // Start at page 2 to show 1-2

				console.log(`PDF loaded: ${totalPages} pages`);

				// Set initial page for double page mode (show pages 1-2)
				if (this.isDoublePage) {
					this.currentPage = Math.min(2, totalPages);
				} else {
					this.currentPage = 1;
				}

				console.log(`Starting with page: ${this.currentPage} (double page: ${this.isDoublePage})`);

				// Stop loading state to show the UI first
				this.isLoading = false;

				// Wait for Vue to render the template with canvas elements
				await this.$nextTick();
				await this.$nextTick(); // Double nextTick to ensure complete render
				await new Promise(resolve => setTimeout(resolve, 1000)); // Extra wait for DOM
				
				// Now try to render with canvas elements available
				let renderSuccess = false;
				for (let attempt = 1; attempt <= 5; attempt++) {
					console.log(`🎯 Render attempt ${attempt}/5`);
					
					// Check if canvas elements exist
					const leftCanvas = this.$refs.leftCanvas;
					const rightCanvas = this.$refs.rightCanvas;
					
					console.log('Canvas availability:', { 
						left: !!leftCanvas, 
						right: !!rightCanvas,
						leftParent: leftCanvas?.parentElement?.tagName,
						rightParent: rightCanvas?.parentElement?.tagName
					});
					
					if (!rightCanvas) {
						console.warn(`❌ Right canvas not found on attempt ${attempt}, waiting...`);
						await new Promise(resolve => setTimeout(resolve, 1000));
						continue;
					}
					
					try {
						// Force canvas to be visible and properly sized
						this.setupCanvasElements();
						
						// Wait a bit more after setup
						await new Promise(resolve => setTimeout(resolve, 500));
						
						// Try rendering
						await this.renderCurrentPages();
						
						// Verify render success
						if (rightCanvas.width > 0 && rightCanvas.height > 0) {
							console.log('✅ Render successful!');
							renderSuccess = true;
							break;
						}
						
					} catch (error) {
						console.error(`❌ Render attempt ${attempt} failed:`, error);
					}
					
					// Progressive wait time
					await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
				}
				
				if (!renderSuccess) {
					console.error('❌ All render attempts failed - will render on user interaction');
				}
				
				// Auto focus the container for keyboard navigation
				this.$nextTick(() => {
					if (this.$refs.bookContainer) {
						this.$refs.bookContainer.focus();
						this.$refs.bookContainer.setAttribute('tabindex', '0');
					}
				});
				
				// Emit page change
				this.emitPageChange();

			} catch (error) {
				console.error('PDF initialization error:', error);
				this.error = this.formatError(error);
			} finally {
				// Ensure loading is stopped even if render fails
				this.isLoading = false;
			}
		},

		formatError(error) {
			if (error.name === 'InvalidPDFException') {
				return 'File PDF không hợp lệ';
			} else if (error.name === 'MissingPDFException') {
				return 'Không tìm thấy file PDF';
			} else if (error.name === 'UnexpectedResponseException') {
				return 'Lỗi tải PDF - kiểm tra đường dẫn';
			} else if (error.message && error.message.includes('fetch')) {
				return 'Lỗi kết nối - không thể tải PDF';
			}
			return `Lỗi: ${error.message || 'Không xác định'}`;
		},

		async retryLoad() {
			await this.initializePDF();
		},

		async renderCurrentPages() {
			try {
				console.log('🎨 Starting renderCurrentPages...', { 
					currentPage: this.currentPage, 
					totalPages: this.totalPages,
					isDoublePage: this.isDoublePage 
				});
				
				const leftCanvas = this.$refs.leftCanvas;
				const rightCanvas = this.$refs.rightCanvas;
				
				if (this.isDoublePage) {
					// Double page mode: show page (currentPage-1) on left, currentPage on right
					
					// Left page (currentPage - 1)
					if (leftCanvas && this.currentPage > 1) {
						const leftPageNum = this.currentPage - 1;
						console.log(`📄 Rendering LEFT page: ${leftPageNum}`);
						
						if (leftPageNum >= 1 && leftPageNum <= this.totalPages) {
							await this.renderPageToCanvas(leftPageNum, leftCanvas, this.scale);
							console.log(`✅ LEFT page ${leftPageNum} rendered`);
						} else {
							console.log(`⚠️ LEFT page ${leftPageNum} out of range`);
							this.clearCanvas(leftCanvas);
						}
					} else if (leftCanvas) {
						console.log('🧹 Clearing left canvas (no page to show)');
						this.clearCanvas(leftCanvas);
					}
					
					// Right page (currentPage)
					if (rightCanvas) {
						const rightPageNum = this.currentPage;
						console.log(`📄 Rendering RIGHT page: ${rightPageNum}`);
						
						if (rightPageNum >= 1 && rightPageNum <= this.totalPages) {
							await this.renderPageToCanvas(rightPageNum, rightCanvas, this.scale);
							console.log(`✅ RIGHT page ${rightPageNum} rendered`);
						} else {
							console.log(`⚠️ RIGHT page ${rightPageNum} out of range`);
							this.clearCanvas(rightCanvas);
						}
					}
				} else {
					// Single page mode: only show currentPage on right
					if (leftCanvas) {
						console.log('🧹 Clearing left canvas (single page mode)');
						this.clearCanvas(leftCanvas);
					}
					
					if (rightCanvas && this.currentPage >= 1 && this.currentPage <= this.totalPages) {
						console.log(`📄 Rendering SINGLE page: ${this.currentPage}`);
						await this.renderPageToCanvas(this.currentPage, rightCanvas, this.scale);
						console.log(`✅ SINGLE page ${this.currentPage} rendered`);
					}
				}
				
				console.log('✅ renderCurrentPages completed successfully');
				
			} catch (error) {
				console.error('❌ Error in renderCurrentPages:', error);
				throw error;
			}
		},

		clearCanvas(canvas) {
			if (canvas) {
				console.log('🧹 Clearing canvas');
				const ctx = canvas.getContext('2d');
				
				// Set default size if canvas has no dimensions
				if (canvas.width === 0 || canvas.height === 0) {
					canvas.width = 400;
					canvas.height = 500;
				}
				
				ctx.clearRect(0, 0, canvas.width, canvas.height);
				// Set a light background to indicate empty page
				ctx.fillStyle = '#f8f9fa';
				ctx.fillRect(0, 0, canvas.width, canvas.height);
				
				// Add a subtle border
				ctx.strokeStyle = '#dee2e6';
				ctx.lineWidth = 1;
				ctx.strokeRect(0, 0, canvas.width, canvas.height);
			}
		},

		setupCanvasElements() {
			console.log('🔧 Setting up canvas elements...');
			
			const leftCanvas = this.$refs.leftCanvas;
			const rightCanvas = this.$refs.rightCanvas;
			
			if (rightCanvas) {
				// Ensure canvas is visible and has proper parent
				const container = rightCanvas.closest('.page-right');
				if (container) {
					container.style.display = 'flex';
					container.style.visibility = 'visible';
				}
				
				// Set minimum dimensions
				if (rightCanvas.width === 0 || rightCanvas.height === 0) {
					rightCanvas.width = 400;
					rightCanvas.height = 500;
					rightCanvas.style.width = '100%';
					rightCanvas.style.height = '100%';
				}
				
				console.log('✅ Right canvas setup:', rightCanvas.width, 'x', rightCanvas.height);
			}
			
			if (leftCanvas) {
				const container = leftCanvas.closest('.page-left');
				if (container) {
					container.style.display = 'flex';
					container.style.visibility = 'visible';
				}
				
				if (leftCanvas.width === 0 || leftCanvas.height === 0) {
					leftCanvas.width = 400;
					leftCanvas.height = 500;
					leftCanvas.style.width = '100%';
					leftCanvas.style.height = '100%';
				}
				
				console.log('✅ Left canvas setup:', leftCanvas.width, 'x', leftCanvas.height);
			}
		},

		// Add method to manually trigger render (useful for debugging)
		async manualRender() {
			this.setupCanvasElements();
			await this.renderCurrentPages();
			this.emitPageChange();
		},

		// Navigation methods with page flip animation
		async nextPage() {
			if (this.currentPage >= this.totalPages || this.isFlipping) return;
			
			// Ensure canvas elements are ready before animation
			this.setupCanvasElements();
			
			await this.animatePageFlip('next', () => {
				if (this.isDoublePage) {
					this.currentPage = Math.min(this.currentPage + 2, this.totalPages);
				} else {
					this.currentPage++;
				}
			});
		},

		async prevPage() {
			if (this.currentPage <= (this.isDoublePage ? 2 : 1) || this.isFlipping) return;
			
			// Ensure canvas elements are ready before animation
			this.setupCanvasElements();
			
			await this.animatePageFlip('prev', () => {
				if (this.isDoublePage) {
					this.currentPage = Math.max(this.currentPage - 2, 2);
				} else {
					this.currentPage--;
				}
			});
		},

		async goToPage(pageNum) {
			if (pageNum === this.currentPage || this.isFlipping) return;
			
			// Adjust page number for double page mode
			if (this.isDoublePage && pageNum === 1) {
				pageNum = 2; // Show pages 1-2
			}
			
			// Ensure canvas elements are ready
			this.setupCanvasElements();
			
			const direction = pageNum > this.currentPage ? 'next' : 'prev';
			
			await this.animatePageFlip(direction, () => {
				this.currentPage = Math.max(this.isDoublePage ? 2 : 1, Math.min(pageNum, this.totalPages));
			});
		},

		async animatePageFlip(direction, updatePageCallback) {
			if (this.isFlipping) return;
			
			this.isFlipping = true;
			this.flipDirection = direction;
			
			try {
				// Get the main book area for animation
				const mainBookArea = this.$refs.bookPages?.querySelector('.main-book-area');
				const pageLeft = this.$refs.bookPages?.querySelector('.page-left');
				const pageRight = this.$refs.bookPages?.querySelector('.page-right');
				
				console.log('Starting page flip animation:', direction);
				
				// Add animation classes
				if (mainBookArea) {
					mainBookArea.classList.add('page-flipping', `flip-${direction}`);
				}
				
				if (pageLeft && pageRight) {
					pageLeft.classList.add('flipping');
					pageRight.classList.add('flipping');
				}
				
				// Wait for half the animation
				await new Promise(resolve => setTimeout(resolve, 300));
				
				// Update page number in the middle of animation
				updatePageCallback();
				
				// Render new pages
				await this.renderCurrentPages();
				
				// Complete the animation
				await new Promise(resolve => setTimeout(resolve, 300));
				
				// Remove animation classes
				if (mainBookArea) {
					mainBookArea.classList.remove('page-flipping', `flip-${direction}`);
				}
				
				if (pageLeft && pageRight) {
					pageLeft.classList.remove('flipping');
					pageRight.classList.remove('flipping');
				}
				
				this.emitPageChange();
				
				console.log('Page flip animation completed. New page:', this.currentPage);
				
			} catch (error) {
				console.error('Page flip animation error:', error);
			} finally {
				this.isFlipping = false;
			}
		},

		// View controls
		async toggleDoublePage() {
			console.log('Toggling double page mode from:', this.isDoublePage, 'to:', !this.isDoublePage);
			this.isDoublePage = !this.isDoublePage;
			this._pageCache.clear();
			
			await this.$nextTick();
			// Longer timeout to ensure DOM updates
			setTimeout(async () => {
				await this.renderCurrentPages();
			}, 300);
		},

		toggleFullscreen() {
			if (!this.isFullscreen) {
				if (this.$refs.bookContainer.requestFullscreen) {
					this.$refs.bookContainer.requestFullscreen();
				}
			} else {
				if (document.exitFullscreen) {
					document.exitFullscreen();
				}
			}
		},

		// Zoom controls
		async zoomIn() {
			this.scale = Math.min(this.scale * 1.25, 3.0);
			this._pageCache.clear();
			await this.renderCurrentPages();
		},

		async zoomOut() {
			this.scale = Math.max(this.scale * 0.8, 0.5);
			this._pageCache.clear();
			await this.renderCurrentPages();
		},

		async fitToPage() {
			const container = this.$refs.bookPages;
			if (container) {
				const containerWidth = container.clientWidth - (this.showThumbnails ? 250 : 0);
				const targetWidth = this.isDoublePage ? containerWidth / 2 : containerWidth;
				this.scale = Math.max(0.5, Math.min(targetWidth / 595, 2.0));
				this._pageCache.clear();
				await this.renderCurrentPages();
			}
		},

		// Event handling
		emitPageChange() {
			const now = Date.now();
			if (now - this.lastEmitTime < this.emitThrottle) {
				return;
			}
			
			this.lastEmitTime = now;
			
			this.$emit('page-changed', {
				page: this.currentPage,
				total: this.totalPages,
				timestamp: new Date().toISOString()
			});
		},

		setupKeyboardShortcuts() {
			this.keyHandler = (e) => {
				if (!this.$refs.bookContainer?.contains(document.activeElement)) return;

				switch(e.key) {
					case 'ArrowRight':
					case ' ':
						e.preventDefault();
						this.nextPage();
						break;
					case 'ArrowLeft':
						e.preventDefault();
						this.prevPage();
						break;
					case 'Home':
						e.preventDefault();
						this.goToPage(1);
						break;
					case 'End':
						e.preventDefault();
						this.goToPage(this.totalPages);
						break;
					case 'f':
						e.preventDefault();
						this.toggleFullscreen();
						break;
					case 'Escape':
						if (this.isFullscreen) {
							e.preventDefault();
							this.toggleFullscreen();
						}
						break;
				}
			};
			document.addEventListener('keydown', this.keyHandler);

			this.fullscreenHandler = () => {
				this.isFullscreen = !!document.fullscreenElement;
			};
			document.addEventListener('fullscreenchange', this.fullscreenHandler);
		},

		cleanup() {
			// Remove event listeners
			if (this.keyHandler) {
				document.removeEventListener('keydown', this.keyHandler);
			}
			if (this.fullscreenHandler) {
				document.removeEventListener('fullscreenchange', this.fullscreenHandler);
			}
			
			// Cleanup PDF document
			if (this._pdfDocument) {
				try {
					this._pdfDocument.destroy();
				} catch (error) {
					console.warn('Error destroying PDF:', error);
				}
				this._pdfDocument = null;
			}
			
			// Clear cache
			if (this._pageCache) {
				this._pageCache.clear();
			}
		}
	}
  };
  Vue.component("uc-pdf-book-reader", compDef);
})();

;(function() {
  const compDef = {
    template: `<div class="uc-quiz-composite">
		<!-- 🚀 Màn hình Bắt đầu -->
		<div v-if="quizState === 'start'" class="lh-quiz-start">
			<div class="lh-start-hero">
				<h1 class="lh-start-title" v-html="stripP(slideData.content.title)"></h1>
				<p class="lh-start-subtitle">Cùng trả lời các câu hỏi tương tác nhé!</p>
			</div>

			<div class="lh-start-info">
				<div v-if="!slideData?.content?.isInteractiveMode" class="lh-info-card">
					<div class="lh-info-icon">⏰</div>
					<div class="lh-info-content">
						<div class="lh-info-label">Thời gian</div>
						<div class="lh-info-value">{{ Math.floor((slideData.content.timeLimit || 0) / 60) }} phút</div>
					</div>
				</div>
				<div class="lh-info-card">
					<div class="lh-info-icon">📝</div>
					<div class="lh-info-content">
						<div class="lh-info-label">Số câu hỏi</div>
						<div class="lh-info-value">{{ totalQuestions }} câu</div>
					</div>
				</div>
				<div v-if="!slideData?.content?.isInteractiveMode" class="lh-info-card">
					<div class="lh-info-icon">🎯</div>
					<div class="lh-info-content">
						<div class="lh-info-label">Để qua bài</div>
						<div class="lh-info-value">{{ slideData.content.passingScore || Math.ceil(totalPoints * 0.7) }}/{{ totalPoints }}</div>
					</div>
				</div>
			</div>

			<!-- Groups Preview -->
			<div v-if="slideData.content.hasGroups" class="lh-groups-preview">
				<h3 class="lh-preview-title">Cấu trúc bài kiểm tra:</h3>
				<div class="lh-preview-groups">
					<div v-for="(group, index) in slideData.content.groups" :key="group.id" class="lh-preview-group">
						<div class="lh-preview-group-header">
							<span class="lh-preview-group-number">Phần {{ index + 1 }}</span>
							<span class="lh-preview-group-title">{{ group.title }}</span>
						</div>
						<div class="lh-preview-group-info">
							<span>{{ group.questions.length }} câu</span>
							<span>{{ group.points }} điểm</span>
							<span v-if="group.timeLimit">{{ Math.floor(group.timeLimit / 60) }} phút</span>
						</div>
						<div v-if="group.description" class="lh-preview-group-desc">{{ group.description }}</div>
					</div>
				</div>
			</div>

			<div class="lh-start-actions">
				<button class="lh-btn lh-btn-primary lh-btn-large" @click="startTest">
					<span class="lh-btn-icon">🚀</span>
					<span>Bắt đầu làm bài</span>
				</button>
			</div>
		</div>

		<!-- 📝 Màn hình Làm bài -->
		<div v-else-if="quizState === 'doing'" class="lh-quiz-layout">

			<!-- Content Area -->
			<div class="lh-quiz-content">

				<!-- Fullscreen Button -->
				<button class="lh-fullscreen-btn" @click="toggleQuizFullscreen"
					:title="isQuizFullscreen ? 'Thoát toàn màn hình' : 'Xem toàn màn hình'">
					<span class="lh-fullscreen-icon">{{ isQuizFullscreen ? '⛔' : '⛶' }}</span>
				</button>

				<div v-if="currentQuestion && userAnswers && userAnswers.composite && userAnswers.composite[currentQuestion.id]" class="lh-question-container">

					<!-- Question Header -->
					<div class="lh-question-header">
						<div class="lh-question-number">
							<span class="lh-question-badge">Câu {{ currentQuestionGlobalIndex + 1 }}</span>
							<span class="lh-question-type">{{ getQuestionTypeLabel(currentQuestion.type) }}</span>
						</div>
						<div v-if="currentGroup" class="lh-question-group-info">
							<span class="lh-group-badge">{{ currentGroup.title }}</span>
							<span class="lh-group-points">{{ currentQuestion.points || 1 }} điểm</span>
						</div>
					</div>

					<!-- Group Instruction -->
					<div v-if="currentGroup && currentGroup.instruction" class="lh-group-current-instruction">
						<div class="lh-instruction-header">
							<span class="lh-instruction-icon">💡</span>
							<span class="lh-instruction-title">Hướng dẫn {{ currentGroup.title }}:</span>
						</div>
						<div class="lh-instruction-content">{{ currentGroup.instruction }}</div>
					</div>

					<!-- Question Content -->
					<div class="lh-question-block"
						:class="'lh-quiz-' + currentQuestion.type.toLowerCase().replace('quiz_', '')">

						<!-- SingleChoice trong composite -->
						<div v-if="currentQuestion.type === 'QUIZ_SINGLE_CHOICE'" class="lh-single-choice">
							<!-- Prompt -->
							<uc-latex-view class="lh-question-prompt" :key="'prompt-' + currentQuestion.id"
								:content="currentQuestion.content.prompt" />

							<div class="lh-options-grid">
								<label v-for="option in currentQuestion.content.options" :key="option.id"
									class="lh-option-card"
									:class="{ 'lh-selected': userAnswers.composite[currentQuestion.id].singleChoice === option.id }">
									<input type="radio" :value="option.id"
										v-model="userAnswers.composite[currentQuestion.id].singleChoice"
										class="lh-option-input">
									<div class="lh-option-content">
										<div class="lh-option-indicator"></div>
										<!-- Option text -->
										<uc-latex-view class="lh-option-text"
											:key="'option-' + currentQuestion.id + '-' + option.id"
											:content="option.text" />
									</div>
								</label>
							</div>
						</div>

						<!-- MultipleChoice trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_MULTIPLE_CHOICE'" class="lh-multiple-choice">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion?.id" />
							<div class="lh-options-grid">
								<label v-for="option in currentQuestion.content.options" :key="option.id"
									class="lh-option-card lh-checkbox-card"
									:class="{ 'lh-selected': userAnswers.composite[currentQuestion.id].multipleChoice.includes(option.id) }">
									<input type="checkbox" :value="option.id"
										v-model="userAnswers.composite[currentQuestion.id].multipleChoice"
										class="lh-option-input">
									<div class="lh-option-content">
										<div class="lh-checkbox-indicator">
											<div class="lh-checkmark">✓</div>
										</div>
										<uc-latex-view class="lh-option-text" :content="option.text"
											:key="'option-' + currentQuestion.id + '-' + option.id" />
									</div>
								</label>
							</div>
						</div>

						<!-- Ordering trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_ORDERING'" class="lh-ordering">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion.id" />
							<div class="lh-ordering-hint">
								<span class="lh-hint-icon">💡</span>
								<span>Kéo thả để sắp xếp theo thứ tự đúng</span>
							</div>
							<div class="lh-ordering-container" :ref="'orderingContainer_' + currentQuestion.id">
								<div v-for="(item, index) in userAnswers.composite[currentQuestion.id].ordering"
									:key="item.id" class="lh-ordering-item" :data-id="item.id">
									<div class="lh-ordering-handle">
										<span class="lh-ordering-number">{{ index + 1 }}</span>
										<span class="lh-drag-icon">⋮⋮</span>
									</div>
									<uc-latex-view class="lh-ordering-text" :content="item.text"
										:key="'option-' + currentQuestion.id + '-' + item.id" />
								</div>
							</div>
						</div>

						<!-- Fill in blank trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_FILL_IN_BLANK'" class="lh-fill-blank">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion.id" />
							<div class="lh-fill-container">
								<template v-for="(part, index) in currentQuestion.content.parts" :key="index">
									<!-- SỬA: dùng v-html cho text có MathML -->
									<uc-latex-view v-if="part.type === 'text'" class="lh-fill-text"
										:content="part.value" />
									<div v-if="part.type === 'blank'" class="lh-fill-input-wrapper">
										<input type="text"
											v-model="userAnswers.composite[currentQuestion.id].fillInTheBlank[part.id]"
											class="lh-fill-input"
											:style="{ width: Math.max((part.size || 10) * 12, 80) + 'px' }"
											:placeholder="'___'">
									</div>
								</template>
							</div>
						</div>

						<!-- Matching trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_MATCHING'" class="lh-matching">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt || 'Nối các mục ở cột A với cột B cho phù hợp:'"
								:key="'prompt-' + currentQuestion.id" />
							<div class="lh-matching-container">
								<div class="lh-matching-column lh-column-a">
									<div class="lh-column-title">Cột A</div>
									<div
										v-for="itemA in currentQuestion.content.columnA"
										:key="itemA.id"
										class="lh-matching-pair-row"
										@click="handleCompositeMatchingRowClick(itemA.id)"
									>
										<div class="lh-matching-item-a">
											<uc-latex-view :content="itemA.text" />
										</div>
										<div class="lh-matching-dropzone" :data-item-a-id="itemA.id" :ref="'compositeMatchingDropzones_' + currentQuestion.id">
											<div v-if="getMatchedItemB(currentQuestion.id, itemA.id)"
												class="lh-matching-item-b lh-matched-item"
												:data-id="getMatchedItemB(currentQuestion.id, itemA.id).id"
												@click.stop="handleRemoveMatchedItemB(currentQuestion.id, itemA.id)"
												@pointerdown="startCompositeMatchingPointerDrag($event, getMatchedItemB(currentQuestion.id, itemA.id), currentQuestion.id)"
											>
												<span class="lh-drag-icon">⋮⋮</span>
												<uc-latex-view class="lh-matching-text" :content="getMatchedItemB(currentQuestion.id, itemA.id).text" />
												<span class="lh-remove-icon" title="Gỡ đáp án" @click.stop="handleRemoveMatchedItemB(currentQuestion.id, itemA.id)">✕</span>
											</div>
											<div v-else class="lh-dropzone-placeholder">Thả Cột B vào đây</div>
										</div>
									</div>
								</div>
								<div class="lh-matching-column lh-column-b">
									<div class="lh-column-title">Cột B</div>
									<div class="lh-matching-list" :ref="'compositeMatchingBContainer_' + currentQuestion.id">
										<div
											v-for="itemB in getUnmatchedItemsB(currentQuestion.id)"
											:key="itemB.id"
											class="lh-matching-item-b"
											:data-id="itemB.id"
											@click="selectCompositeItemB(itemB.id)"
											@pointerdown="startCompositeMatchingPointerDrag($event, itemB, currentQuestion.id)"
										>
											<span class="lh-drag-icon">⋮⋮</span>
											<uc-latex-view class="lh-matching-text" :content="itemB.text" />
										</div>
									</div>
									<div v-if="getCompositeRemainingBCount(currentQuestion.id) === 0" class="lh-column-b-empty">
										🎉 Đã ghép hết
									</div>
								</div>
							</div>
						</div>

						<!-- Categorize trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_DRAG_DROP_CATEGORIZE'" class="lh-categorize">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion.id" />

							<div class="lh-source-pool">
								<div class="lh-pool-title">
									<span class="lh-pool-icon">📦</span>
									<span>Kéo từ đây:</span>
								</div>
								<div class="lh-items-container" :ref="'sourceContainer_' + currentQuestion.id">
									<div v-for="item in userAnswers.composite[currentQuestion.id].unclassifiedItems"
										:key="item.id" class="lh-draggable-item" :data-id="item.id">
										<span class="lh-item-text">{{ item.text }}</span>
									</div>
								</div>
							</div>

							<div class="lh-categories-grid">
								<div v-for="category in currentQuestion.content.categories" :key="category.id"
									class="lh-category-box">
									<div class="lh-category-header">
										<img v-if="isImage(category.name)" :src="category.name" alt="Category"
											class="lh-category-image">
										<span v-else class="lh-category-name">{{ category.name }}</span>
									</div>
									<div class="lh-category-dropzone" :data-category-id="category.id"
										:ref="'categoryContainer_' + currentQuestion.id + '_' + category.id"
										:data-ref="'categoryContainer_' + currentQuestion.id + '_' + category.id">
										<div class="lh-dropzone-hint">Thả vào đây</div>
									</div>
								</div>
							</div>
						</div>

						<!-- TRUE_FALSE trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_TRUE_FALSE'" class="lh-single-choice">
							<!-- Prompt -->
							<uc-latex-view class="lh-question-prompt" :key="'prompt-' + currentQuestion.id"
								:content="currentQuestion.content.prompt" />
							<div class="lh-options-grid"
								style="grid-template-columns: repeat(auto-fit, minmax(700px, 1fr));">
								<label v-for="option in currentQuestion.content.options" :key="option.id"
									class="lh-option-card"
									:class="[getOptionClass(option.id), { 'lh-selected': getTrueFalseValue(option.id) !== undefined }]">

									<v-select placeholder="Đúng/Sai..."
										:items="[{title: '✅ Đúng', value: true}, {title: '❌ Sai', value: false}]"
										item-title='title' item-value='value'
										:model-value="getTrueFalseValue(option.id)"
										@update:modelValue="updateTrueFalseComposite(option, $event)"
										:bg-color="getTrueFalseBackgroundColor(option.id)" style="min-width:150px" />

									<div class="lh-option-content">
										<!-- Option text -->
										<uc-latex-view class="lh-option-text"
											:key="'option-' + currentQuestion.id + '-' + option.id"
											:content="option.text" />
									</div>
								</label>
							</div>
						</div>

						<!-- Connection (Nối đường thẳng) trong composite -->
						<div v-else-if="currentQuestion.type === 'QUIZ_CONNECTION'" class="lh-connection">
							<uc-latex-view class="lh-question-prompt" :content="currentQuestion.content.prompt"
								:key="'prompt-' + currentQuestion.id" />

							<div class="lh-connection-instructions">
								<span class="lh-hint-icon">💡</span>
								<span>Bước 1: Chọn nhóm bên trái → Bước 2: Chọn mục bên phải để nối</span>
							</div>

							<div class="lh-connection-parent-container" :ref="'connectionParent_' + currentQuestion.id">
								<svg class="lh-connection-lines-svg" :ref="'svgContainer_' + currentQuestion.id"
									style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none;">
									<line v-for="(line, index) in getConnectionLines(currentQuestion.id)"
										:key="'line-' + index" :x1="line.x1" :y1="line.y1" :x2="line.x2" :y2="line.y2"
										:stroke="line.color" stroke-width="4" stroke-linecap="round"
										class="lh-connection-line" />
								</svg>

								<div class="lh-connection-container" :ref="'connectionContainer_' + currentQuestion.id">
									<div class="lh-connection-column lh-groups-column">
										<div class="lh-connection-header">
											<span class="lh-connection-icon">🏷️</span>
											<span>Nhóm</span>
										</div>
										<div class="lh-connection-items">
											<div v-for="group in currentQuestion.content.groups"
												:key="'group-' + group.id"
												:id="'connect-' + currentQuestion.id + '-group-' + group.id"
												class="lh-connection-item lh-connection-group"
												:class="getCompositeGroupClass(currentQuestion.id, group.id)"
												:style="{ backgroundColor: getCompositeGroupColor(currentQuestion.id, group.id) }"
												@click="selectCompositeGroup(currentQuestion.id, group.id)">
												<div class="lh-group-content">
													<span class="lh-group-text">{{ group.text }}</span>
													<span
														v-if="getCompositeActiveGroup(currentQuestion.id) === group.id"
														class="lh-active-indicator">👆</span>
												</div>
											</div>
										</div>
									</div>

									<div class="lh-connection-column lh-items-column">
										<div class="lh-connection-header">
											<span class="lh-connection-icon">📝</span>
											<span>Mục</span>
										</div>
										<div class="lh-connection-items">
											<div v-for="item in currentQuestion.content.items" :key="'item-' + item.id"
												:id="'connect-' + currentQuestion.id + '-item-' + item.id"
												class="lh-connection-item lh-connection-item-target"
												:class="getCompositeItemClass(currentQuestion.id, item.id)"
												@click="selectCompositeItem(currentQuestion.id, item.id)">
												<div class="lh-item-content">
													<span class="lh-item-text">{{ item.text }}</span>
													<span
														v-if="getCompositeConnectionForItem(currentQuestion.id, item.id)"
														class="lh-connected-indicator">🔗</span>
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>

							<div v-if="getCompositeActiveGroup(currentQuestion.id)" class="lh-connection-status">
								<span class="lh-status-icon">👉</span>
								<span>Đã chọn nhóm: <strong>{{ getCompositeGroupText(currentQuestion.id,
										getCompositeActiveGroup(currentQuestion.id)) }}</strong>
									- Giờ hãy chọn mục để nối!</span>
							</div>
						</div>

						<!-- Bottom Navigation Controls (Bấm chuyển câu tiện lợi ngay dưới đáp án) -->
						<div class="lh-bottom-nav-controls d-flex ga-2 mt-4 pt-3 border-t">
							<button class="lh-btn lh-btn-secondary flex-grow-1 py-2" :disabled="currentQuestionGlobalIndex === 0"
								@click="previousQuestion">
								<span class="lh-btn-icon">⬅️</span>
								<span>Câu trước</span>
							</button>
							<button class="lh-btn lh-btn-primary flex-grow-1 py-2"
								:disabled="currentQuestionGlobalIndex === allQuestions.length - 1" @click="nextQuestion">
								<span>Câu tiếp</span>
								<span class="lh-btn-icon">➡️</span>
							</button>
						</div>

					</div>
				</div>
			</div>

			<!-- Navigation Panel -->
			<div class="lh-quiz-sidebar">
				<div class="lh-sidebar-content">

					<!-- Timer -->
					<div v-if="!slideData?.content?.isInteractiveMode" class="lh-timer-card">
						<div class="lh-timer-icon">⏰</div>
						<div class="lh-timer-time">{{ formatTime(timeLeft) }}</div>
						<div class="lh-timer-label">Thời gian còn lại</div>
					</div>

					<!-- Progress -->
					<div class="lh-progress-card">
						<div class="lh-progress-header">
							<span class="lh-progress-icon">📊</span>
							<span class="lh-progress-title">Tiến độ</span>
						</div>
						<div class="lh-progress-stats">
							<span class="lh-progress-number">{{ getCompletedCount() }}/{{ totalQuestions }}</span>
							<span class="lh-progress-text">đã làm</span>
						</div>
						<div class="lh-progress-bar">
							<div class="lh-progress-fill" :style="{ width: getProgressPercentage() + '%' }"></div>
						</div>
						<div v-if="!slideData?.content?.isInteractiveMode" class="lh-progress-stars">
							<span v-for="n in 5" :key="n" class="lh-star"
								:class="{ 'lh-star-filled': n <= Math.ceil(getProgressPercentage() / 20) }">⭐</span>
						</div>
					</div>

					<!-- Question Grid với Groups -->
					<div class="lh-questions-grid">
						<div class="lh-grid-title">
							<span class="lh-grid-icon">📝</span>
							<span>Danh sách câu hỏi</span>
						</div>

						<!-- Hiển thị có groups -->
						<div v-if="slideData.content.hasGroups" class="lh-groups-container">
							<div v-for="(group, groupIndex) in slideData.content.groups" :key="group.id"
								class="lh-group-section">
								<div class="lh-group-header">
									<span class="lh-group-title">{{ group.title }}</span>
									<span class="lh-group-info">{{ group.questions.length }} câu - {{ group.points }}
										điểm</span>
									<div v-if="group.timeLimit" class="lh-group-timer">
										⏱️ {{ Math.floor(group.timeLimit / 60) }}p
									</div>
									<div class="lh-group-progress" :style="{ width: getGroupProgress(group) + '%' }">
									</div>
								</div>
								<div class="lh-group-questions">
									<button v-for="(q, qIndex) in group.questions" :key="q.id" class="lh-question-btn"
										:class="getQuestionButtonClass(getGlobalIndex(groupIndex, qIndex), q.id)"
										@click="navigateToQuestion(getGlobalIndex(groupIndex, qIndex))">
										<span class="lh-question-btn-number">{{ getGlobalIndex(groupIndex, qIndex) + 1
											}}</span>
										<span v-if="isQuestionCompleted(q.id)" class="lh-question-btn-check">✓</span>
									</button>
								</div>
							</div>
						</div>

						<!-- Hiển thị danh sách câu hỏi -->
						<div v-else class="lh-grid-container">
							<button v-for="(q, index) in allQuestions" :key="q.id"
								class="lh-question-btn" :class="getQuestionButtonClass(index, q.id)"
								@click="navigateToQuestion(index)">
								<span class="lh-question-btn-number">{{ index + 1 }}</span>
								<span v-if="isQuestionCompleted(q.id)" class="lh-question-btn-check">✓</span>
							</button>
						</div>
					</div>

					<!-- Submit Button (Unique single button) -->
					<div class="lh-submit-section mt-3">
						<button class="lh-btn lh-btn-success lh-btn-large w-100" @click="submitTest">
							<span class="lh-btn-icon">🏁</span>
							<span>NỘP BÀI</span>
						</button>
					</div>

				</div>
			</div>
		</div>

		<!-- 🏆 Màn hình Kết quả -->
		<div v-else-if="quizState === 'result'" class="lh-quiz-result"
			:class="{ 'lh-result-passed': testResult.passed, 'lh-result-failed': !testResult.passed }">
			<div class="lh-result-hero">
				<div class="lh-result-icon">{{ testResult.passed ? '🎉' : '💪' }}</div>
				<h1 class="lh-result-title">{{ testResult.passed ? 'Xuất sắc!' : 'Cố gắng lên!' }}</h1>
				<p class="lh-result-subtitle">{{ testResult.passed ? 'Em đã hoàn thành bài kiểm tra!' : 'Hãy ôn tập và
					thử lại nhé!' }}</p>
			</div>

			<div class="lh-result-score">
				<div class="lh-score-circle">
					<div class="lh-score-number">{{ testResult.score }}</div>
					<div class="lh-score-total">/{{ testResult.totalPoints }}</div>
				</div>
				<div class="lh-score-percentage">{{ testResult.percentage }}%</div>
				<div class="lh-score-stars">
					<span v-for="n in 5" :key="n" class="lh-star"
						:class="{ 'lh-star-filled': n <= Math.ceil(testResult.percentage / 20) }">⭐</span>
				</div>
			</div>

			<!-- Groups Result Detail (nếu có) -->
			<div v-if="slideData.content.hasGroups" class="lh-groups-result">
				<h3 class="lh-result-groups-title">Kết quả chi tiết theo phần:</h3>
				<div class="lh-result-groups-grid">
					<div v-for="(group, index) in slideData.content.groups" :key="group.id"
						class="lh-result-group-card">
						<div class="lh-result-group-header">
							<span class="lh-result-group-name">{{ group.title }}</span>
							<span class="lh-result-group-score">{{ getGroupScore(group) }}/{{ group.points }}</span>
						</div>
						<div class="lh-result-group-progress">
							<div class="lh-result-progress-bar">
								<div class="lh-result-progress-fill"
									:style="{ width: (getGroupScore(group) / group.points * 100) + '%' }"></div>
							</div>
							<span class="lh-result-group-percentage">{{ Math.round(getGroupScore(group) / group.points *
								100) }}%</span>
						</div>
						<div class="lh-result-group-stats">
							<span>{{ getGroupCompletedCount(group) }}/{{ group.questions.length }} câu đúng</span>
						</div>
					</div>
				</div>
			</div>

			<div class="lh-result-actions">
				<button class="lh-btn lh-btn-primary lh-btn-large" @click="reviewTest">
					<span class="lh-btn-icon">🔍</span>
					<span>Xem lại bài làm</span>
				</button>
			</div>
		</div>
	</div>`,
    name: 'uc-quiz-composite',
		props: {
			slideData: { type: Object, required: true }
		},
		emits: ['quiz-completed'],
	
		data() {
			return {
				// Quiz states
				selectedCompositeBId: null,
				activeDragItemB: null,
				quizState: 'start', // 'start', 'doing', 'result'
				currentQuestionIndex: 0,
				timer: null,
				timeLeft: 0,
				testResult: { score: 0, passed: false },
	
				// User answers for composite quiz
				userAnswers: {
					composite: {}
				},
	
				// Sortable instances management
				sortableInstances: [],
	
				// Fullscreen states
				isQuizFullscreen: false,
				fullscreenContainer: null,
				originalParent: null,
				originalNextSibling: null,
	
				// Connection quiz specific data
				compositeGroupColors: {},
				compositeLines: {},
	
				// Question type labels for display
				questionTypeLabels: {
					'QUIZ_SINGLE_CHOICE': '🎯 Chọn một đáp án',
					'QUIZ_MULTIPLE_CHOICE': '☑️ Chọn nhiều đáp án',
					'QUIZ_FILL_IN_BLANK': '✏️ Điền vào chỗ trống',
					'QUIZ_ORDERING': '📝 Sắp xếp thứ tự',
					'QUIZ_MATCHING': '🔗 Ghép nối',
					'QUIZ_DRAG_DROP_CATEGORIZE': '📦 Phân loại',
					'QUIZ_CONNECTION': '🔗 Nối đường thẳng',
					'QUIZ_COMPOSITE': '📝 Nhiều câu hỏi',
					'QUIZ_TRUE_FALSE': '🎯 Chọn đáp án đúng sai',
				}
			}
		},
	
		computed: {
			// Tính tổng điểm của composite quiz
			totalPoints() {
				if (this.slideData.content.hasGroups) {
					return this.slideData.content.groups.reduce((total, group) => total + group.points, 0);
				} else {
					return this.slideData.content.questions.reduce((total, q) => total + (q.points || 1), 0);
				}
			},
	
			// Tính tổng số câu hỏi
			totalQuestions() {
				if (this.slideData.content.hasGroups) {
					return this.slideData.content.groups.reduce((total, group) => total + group.questions.length, 0);
				} else {
					return this.slideData.content.questions.length;
				}
			},
	
			// Lấy tất cả questions từ groups hoặc direct questions với ID duy nhất
			allQuestions() {
				let list = [];
				if (this.slideData?.content?.hasGroups) {
					(this.slideData.content.groups || []).forEach(group => {
						list = list.concat(group.questions || []);
					});
				} else {
					list = this.slideData?.content?.questions || [];
				}
				return list.map((q, idx) => {
					const uniqueId = q.id ? String(q.id) : ('q_' + idx);
					return Object.assign({}, q, { id: uniqueId });
				});
			},
	
			// Lấy question hiện tại
			currentQuestion() {
				if (this.quizState === 'doing') {
					const questions = this.allQuestions;
					return questions[this.currentQuestionIndex];
				}
				return null;
			},
	
			// Lấy group hiện tại của question đang làm
			currentGroup() {
				if (this.slideData.content.hasGroups && this.currentQuestion) {
					return this.slideData.content.groups.find(group =>
						group.questions.some(q => q.id === this.currentQuestion.id)
					);
				}
				return null;
			},
	
			// Lấy index của question trong tất cả questions
			currentQuestionGlobalIndex() {
				return this.currentQuestionIndex || 0;
			}
		},
	
		watch: {
	
			slideData: {
				handler(newSlide) {
					if (newSlide) {
						this.initializeQuiz();
					}
				},
				immediate: true,
				deep: false
			},
	
			userAnswers: {
				handler(newAnswers) {
					// Redraw connection lines for current question if it's connection type
					if (this.currentQuestion?.type === 'QUIZ_CONNECTION') {
						Vue.nextTick(() => {
							setTimeout(() => {
								this.drawCompositeConnectionLines(this.currentQuestion.id);
							}, 100);
						});
					}
				},
				deep: true
			}
		},
	
		methods: {
			stripP(text) {
				if (!text) return '';
				return String(text).replace(/<\/?p>/gi, '').trim();
			},

			getMatchedItemB(questionId, itemAId) {
				if (!questionId || !this.userAnswers?.composite[questionId]) return null;
				const slots = this.userAnswers.composite[questionId].matchingSlots;
				if (!slots) return null;
				const itemBId = slots[String(itemAId)];
				if (!itemBId) return null;

				const question = this.allQuestions.find(q => String(q.id) === String(questionId));
				const columnB = question?.content?.columnB || [];
				return columnB.find(b => String(b.id) === String(itemBId)) || null;
			},

			getUnmatchedItemsB(questionId) {
				if (!questionId || !this.userAnswers?.composite[questionId]) return [];
				const question = this.allQuestions.find(q => String(q.id) === String(questionId));
				const columnB = question?.content?.columnB || [];
				const slots = this.userAnswers.composite[questionId].matchingSlots || {};
				const matchedBIds = new Set(Object.values(slots).map(String));

				const initialBList = this.userAnswers.composite[questionId].matching || columnB;
				return initialBList.filter(b => !matchedBIds.has(String(b.id)));
			},

			getCompositeRemainingBCount(questionId) {
				return this.getUnmatchedItemsB(questionId).length;
			},

			selectCompositeItemB(itemBId) {
				if (this.selectedCompositeBId === itemBId) {
					this.selectedCompositeBId = null;
				} else {
					this.selectedCompositeBId = itemBId;
				}
			},

			setProp(obj, key, val) {
				if (!obj) return;
				if (typeof this.$set === 'function') {
					this.$set(obj, key, val);
				} else {
					obj[key] = val;
				}
			},

			deleteProp(obj, key) {
				if (!obj) return;
				if (typeof this.$delete === 'function') {
					this.$delete(obj, key);
				} else {
					delete obj[key];
				}
			},

			handleRemoveMatchedItemB(questionId, itemAId) {
				if (!questionId || !itemAId) return;
				const slots = this.userAnswers?.composite[questionId]?.matchingSlots;
				if (slots && slots[String(itemAId)]) {
					this.deleteProp(slots, String(itemAId));
					this.selectedCompositeBId = null;
					this.playSound('navigate');
					this.$forceUpdate();
				}
			},

			handleCompositeMatchingRowClick(itemAId) {
				const questionId = this.currentQuestion?.id;
				if (!questionId) return;

				if (this.selectedCompositeBId) {
					this.assignCompositeMatchingPair(questionId, itemAId, this.selectedCompositeBId);
					this.selectedCompositeBId = null;
					return;
				}

				this.handleRemoveMatchedItemB(questionId, itemAId);
			},

			assignCompositeMatchingPair(questionId, itemAId, itemBId) {
				if (!this.userAnswers?.composite[questionId]) return;
				if (!this.userAnswers.composite[questionId].matchingSlots) {
					this.setProp(this.userAnswers.composite[questionId], 'matchingSlots', {});
				}

				const slots = this.userAnswers.composite[questionId].matchingSlots;
				const existingAId = Object.keys(slots).find(aId => String(slots[aId]) === String(itemBId));
				const targetOldBId = slots[String(itemAId)];

				if (existingAId && targetOldBId && String(existingAId) !== String(itemAId)) {
					// SWAP: Move itemBId to itemAId, move targetOldBId to existingAId
					this.setProp(slots, String(existingAId), String(targetOldBId));
					this.setProp(slots, String(itemAId), String(itemBId));
				} else if (existingAId && String(existingAId) !== String(itemAId)) {
					// Move itemBId from existingAId to target itemAId
					this.deleteProp(slots, String(existingAId));
					this.setProp(slots, String(itemAId), String(itemBId));
				} else {
					this.setProp(slots, String(itemAId), String(itemBId));
				}

				this.playSound('drop');
				this.$forceUpdate();
			},

			restoreCompositeMatchingDOM(questionId) {
				// Purely reactive rendering handles matching DOM state
				this.$forceUpdate();
			},

			isMatchingPair(itemA, itemB, correctPairs, columnA, columnB) {
				if (!itemA || !itemB) return false;
				const itemA_Id = String(itemA.id || '');
				const itemB_Id = String(itemB.id || '');

				// 1. Check correctPairs array
				if (correctPairs && Array.isArray(correctPairs) && correctPairs.length > 0) {
					const pair = correctPairs.find(p => {
						const pLeft = String(p.from !== undefined ? p.from : (p.id !== undefined ? p.id : (p.itemAId !== undefined ? p.itemAId : (p.leftId !== undefined ? p.leftId : ''))));
						return pLeft === itemA_Id;
					});
					if (pair) {
						const expectedB = String(pair.to !== undefined ? pair.to : (pair.itemBId !== undefined ? pair.itemBId : (pair.correctBId !== undefined ? pair.correctBId : (pair.rightId !== undefined ? pair.rightId : ''))));
						if (expectedB === itemB_Id) return true;
					}
				}

				// 2. Check itemA properties: correctBId, to, targetId
				if (itemA.correctBId !== undefined && itemA.correctBId !== null) {
					if (String(itemA.correctBId) === itemB_Id) return true;
				}
				if (itemA.to !== undefined && itemA.to !== null) {
					if (String(itemA.to) === itemB_Id) return true;
				}
				if (itemA.targetId !== undefined && itemA.targetId !== null) {
					if (String(itemA.targetId) === itemB_Id) return true;
				}

				// 3. Check pairId matching
				if (itemA.pairId !== undefined && itemA.pairId !== null) {
					if (String(itemA.pairId) === String(itemB.pairId || itemB.id)) return true;
				}
				if (itemB.pairId !== undefined && itemB.pairId !== null) {
					if (String(itemB.pairId) === itemA_Id) return true;
				}

				// 4. Fallback: ID matching
				if (itemA_Id && itemB_Id && itemA_Id === itemB_Id) return true;

				// 5. Fallback: Trailing number matching in text (e.g. "Mục A1" <-> "Mục B1")
				const textA = (itemA.text || itemA.title || '').toString();
				const textB = (itemB.text || itemB.title || '').toString();
				const numA = textA.match(/\d+/);
				const numB = textB.match(/\d+/);
				if (numA && numB && numA[0] === numB[0]) return true;

				return false;
			},

			startCompositeMatchingPointerDrag(event, itemB, questionId) {
				if (!itemB) return;
				if (event.cancelable) event.preventDefault();

				// Destroy any stale avatar elements left in body
				const staleAvatars = document.querySelectorAll('#composite-matching-drag-avatar, #matching-drag-avatar');
				staleAvatars.forEach(a => a.remove());

				const pointer = event.touches ? event.touches[0] : event;
				const itemEl = event.currentTarget || event.target.closest('.lh-matching-item-b');
				if (!itemEl) return;

				this.activeDragItemB = itemB;
				this.activeDragEl = itemEl;

				const rect = itemEl.getBoundingClientRect();
				const targetDz = document.querySelector('.lh-matching-dropzone');
				const dzWidth = targetDz ? targetDz.getBoundingClientRect().width : 0;
				const avatarWidth = (dzWidth && dzWidth > 40) ? dzWidth : Math.min(rect.width, 180);
				const avatarHeight = rect.height;
				const avatar = itemEl.cloneNode(true);
				avatar.id = 'composite-matching-drag-avatar';
				avatar.className = 'lh-drag-avatar-clone';
				avatar.style.position = 'fixed';
				avatar.style.left = (pointer.clientX - avatarWidth / 2) + 'px';
				avatar.style.top = (pointer.clientY - avatarHeight / 2) + 'px';
				avatar.style.width = avatarWidth + 'px';
				avatar.style.maxWidth = avatarWidth + 'px';
				avatar.style.height = avatarHeight + 'px';
				avatar.style.zIndex = '9999999';
				avatar.style.pointerEvents = 'none';
				avatar.style.boxShadow = '0 12px 28px rgba(0,0,0,0.3)';
				avatar.style.transform = 'scale(1.05) rotate(2deg)';
				avatar.style.opacity = '0.92';
				avatar.style.transition = 'none';
				avatar.style.border = '2px solid #10b981';
				avatar.style.background = '#ffffff';
				avatar.style.borderRadius = '10px';
				avatar.style.touchAction = 'none';

				document.body.appendChild(avatar);
				this.dragAvatarEl = avatar;

				// Hide source element during drag
				itemEl.style.visibility = 'hidden';

				const bContainerRef = 'compositeMatchingBContainer_' + questionId;

				const onPointerMove = (e) => {
					if (e.cancelable) e.preventDefault();
					const p = e.touches ? e.touches[0] : e;
					if (this.dragAvatarEl) {
						this.dragAvatarEl.style.left = (p.clientX - avatarWidth / 2) + 'px';
						this.dragAvatarEl.style.top = (p.clientY - avatarHeight / 2) + 'px';
					}

					const elemBelow = document.elementFromPoint(p.clientX, p.clientY);
					const dropzones = Array.from(document.querySelectorAll('.lh-matching-dropzone'));
					dropzones.forEach(d => d.classList.remove('lh-dropzone-hover'));

					if (elemBelow) {
						const dz = elemBelow.closest('.lh-matching-dropzone') || elemBelow.closest('.lh-matching-pair-row');
						if (dz) {
							const targetDz = dz.classList.contains('lh-matching-dropzone') ? dz : dz.querySelector('.lh-matching-dropzone');
							if (targetDz) targetDz.classList.add('lh-dropzone-hover');
						}
					}
				};

				const onPointerUp = (e) => {
					window.removeEventListener('mousemove', onPointerMove);
					window.removeEventListener('mouseup', onPointerUp);
					window.removeEventListener('pointermove', onPointerMove);
					window.removeEventListener('pointerup', onPointerUp);
					window.removeEventListener('touchmove', onPointerMove);
					window.removeEventListener('touchend', onPointerUp);
					window.removeEventListener('touchcancel', onPointerUp);

					// Remove avatar BEFORE detecting element below to prevent raycast collision
					const allAvatars = document.querySelectorAll('#composite-matching-drag-avatar, #matching-drag-avatar');
					allAvatars.forEach(a => a.remove());
					this.dragAvatarEl = null;

					const p = e.changedTouches ? e.changedTouches[0] : (e.touches ? e.touches[0] : e);
					const elemBelow = document.elementFromPoint(p.clientX, p.clientY);

					if (this.activeDragEl) {
						this.activeDragEl.style.visibility = 'visible';
						this.activeDragEl.style.display = '';
						this.activeDragEl.style.opacity = '1';
					}

					const dropzones = Array.from(document.querySelectorAll('.lh-matching-dropzone'));
					dropzones.forEach(d => d.classList.remove('lh-dropzone-hover'));

					if (elemBelow) {
						const dz = elemBelow.closest('.lh-matching-dropzone') || elemBelow.closest('.lh-matching-pair-row');
						if (dz) {
							const targetDz = dz.classList.contains('lh-matching-dropzone') ? dz : dz.querySelector('.lh-matching-dropzone');
							if (targetDz) {
								const itemA_Id = targetDz.dataset.itemAId;
								this.assignCompositeMatchingPair(questionId, itemA_Id, itemB.id);
								this.playSound('drop');
								this.activeDragItemB = null;
								this.activeDragEl = null;
								this.$forceUpdate();
								return;
							}
						}
					}

					// Dropped outside any dropzone -> If itemB was previously placed, remove it back to Column B!
					const slots = this.userAnswers?.composite[questionId]?.matchingSlots;
					if (slots) {
						const placedAId = Object.keys(slots).find(aId => String(slots[aId]) === String(itemB.id));
						if (placedAId) {
							this.deleteProp(slots, String(placedAId));
							this.playSound('navigate');
						}
					}

					this.activeDragItemB = null;
					this.activeDragEl = null;
					this.$forceUpdate();
				};

				window.addEventListener('mousemove', onPointerMove, { passive: false });
				window.addEventListener('mouseup', onPointerUp, { passive: false });
				window.addEventListener('pointermove', onPointerMove, { passive: false });
				window.addEventListener('pointerup', onPointerUp, { passive: false });
				window.addEventListener('touchmove', onPointerMove, { passive: false });
				window.addEventListener('touchend', onPointerUp, { passive: false });
				window.addEventListener('touchcancel', onPointerUp, { passive: false });
			},
			// ==================== QUIZ LIFECYCLE METHODS ====================
			initializeQuiz() {
				// Initialize quiz state
				const isInteractive = !this.slideData?.content?.timeLimit || !!this.slideData?.content?.isInteractiveMode;
				this.quizState = isInteractive ? 'doing' : 'start';
				this.currentQuestionIndex = 0;
				this.timeLeft = this.slideData.content.timeLimit || 3600;
				this.userAnswers = { composite: {} };
				this.compositeGroupColors = {};
				this.compositeLines = {};

				// Pre-initialize answers for all questions
				this.initializeCompositeAnswers();
	
				// Clear any existing timer
				if (this.timer) {
					clearInterval(this.timer);
					this.timer = null;
				}
			},
	
			startTest() {
				this.quizState = 'doing';
				this.timeLeft = this.slideData.content.timeLimit || 3600; // Default 1 hour
				this.currentQuestionIndex = 0;
	
				// Initialize answers for all questions
				this.initializeCompositeAnswers();
	
				// Initialize sortables for current question
				Vue.nextTick(() => {
					this.initCompositeSortables();
				});
	
				this.startTimer();
				this.playSound('start');
			},
	
			initializeCompositeAnswers() {
				const initialAnswers = {};
				const questions = this.allQuestions;
	
				questions.forEach(q => {
					if (q.type === 'QUIZ_SINGLE_CHOICE') {
						initialAnswers[q.id] = { singleChoice: null };
					} else if (q.type === 'QUIZ_MULTIPLE_CHOICE') {
						initialAnswers[q.id] = { multipleChoice: [] };
					} else if (q.type === 'QUIZ_ORDERING') {
						initialAnswers[q.id] = { ordering: this.shuffleArray([...q.content.items]) };
					} else if (q.type === 'QUIZ_FILL_IN_BLANK') {
						const fillInBlank = {};
						q.content.parts.forEach(part => {
							if (part.type === 'blank') {
								fillInBlank[part.id] = '';
							}
						});
						initialAnswers[q.id] = { fillInTheBlank: fillInBlank };
					} else if (q.type === 'QUIZ_MATCHING') {
						initialAnswers[q.id] = { matching: this.shuffleArray([...(q.content.columnB || [])]), matchingSlots: {} };
					} else if (q.type === 'QUIZ_DRAG_DROP_CATEGORIZE') {
						initialAnswers[q.id] = { unclassifiedItems: this.shuffleArray([...q.content.items]) };
					} else if (q.type === 'QUIZ_TRUE_FALSE') {
						initialAnswers[q.id] = { trueFalse: {} };
					} else if (q.type === 'QUIZ_CONNECTION') {
						initialAnswers[q.id] = {
							connection: {
								activeGroup: null,
								selections: []
							}
						};
						// Generate colors for this question's groups
						this.generateCompositeGroupColors(q.id, q.content.groups);
					}
				});
				this.userAnswers.composite = initialAnswers;
			},
	
			startTimer() {
				if (this.timer) clearInterval(this.timer);
				this.timer = setInterval(() => {
					if (this.timeLeft > 0) {
						this.timeLeft--;
					} else {
						clearInterval(this.timer);
						this.submitTest();
					}
				}, 1000);
			},
	
			formatTime(seconds) {
				const m = Math.floor(seconds / 60).toString().padStart(2, '0');
				const s = (seconds % 60).toString().padStart(2, '0');
				return `${m}:${s}`;
			},
	
			// ==================== CONNECTION QUIZ METHODS FOR COMPOSITE ====================
			generateCompositeGroupColors(questionId, groups) {
				const presetColors = [
					'#FF6B6B', '#4DD0E1', '#FFD93D',
					'#6BCB77', '#FF9F1C', '#C084FC',
					'#38BDF8', '#F472B6', '#FBBF24', '#34D399'
				];
	
				if (!this.compositeGroupColors[questionId]) {
					this.compositeGroupColors[questionId] = {};
				}
	
				let i = 0;
				groups.forEach(group => {
					this.compositeGroupColors[questionId][group.id] = presetColors[i % presetColors.length];
					i++;
				});
			},
	
			selectCompositeGroup(questionId, groupId) {
				if (!this.userAnswers.composite[questionId]) {
					this.userAnswers.composite[questionId] = {
						connection: { activeGroup: null, selections: [] }
					};
				}
				if (!this.userAnswers.composite[questionId].connection) {
					this.userAnswers.composite[questionId].connection = { activeGroup: null, selections: [] };
				}
	
				this.userAnswers.composite[questionId].connection.activeGroup = groupId;
				this.playSound('navigate');
			},
	
			selectCompositeItem(questionId, itemId) {
				if (!this.userAnswers.composite[questionId]?.connection) {
					return;
				}
	
				const activeGroup = this.userAnswers.composite[questionId].connection.activeGroup;
				if (!activeGroup) {
					this.showToast("Vui lòng chọn một mục ở cột trái trước.", 'warning');
					return;
				}
	
				console.log('Connecting:', activeGroup, 'to', itemId, 'for question:', questionId);
	
				// Remove old connection for this item
				this.userAnswers.composite[questionId].connection.selections =
					this.userAnswers.composite[questionId].connection.selections.filter(sel => sel.to !== itemId);
	
				// Add new connection
				this.userAnswers.composite[questionId].connection.selections.push({
					from: activeGroup,
					to: itemId
				});
	
				console.log('Current selections:', this.userAnswers.composite[questionId].connection.selections);
	
				this.playSound('drop');
	
				// Draw lines for this question
				Vue.nextTick(() => {
					setTimeout(() => {
						this.drawCompositeConnectionLines(questionId);
					}, 100);
				});
			},
	
			drawCompositeConnectionLines(questionId) {
				if (!this.userAnswers.composite[questionId]?.connection?.selections?.length) {
					if (!this.compositeLines) this.compositeLines = {};
					this.compositeLines[questionId] = [];
					return;
				}
	
				// Wait for DOM update and ensure elements are ready
				this.$nextTick(() => {
					setTimeout(() => {
						const containerEl = this.$refs['connectionContainer_' + questionId];
						const parentEl = this.$refs['connectionParent_' + questionId];
	
						if (!containerEl || !parentEl) {
							console.warn('Connection refs not found for question:', questionId);
							return;
						}
	
						const parentRect = parentEl.getBoundingClientRect();
						const newLines = [];
	
						console.log('Drawing lines for question:', questionId, 'selections:', this.userAnswers.composite[questionId].connection.selections);
	
						this.userAnswers.composite[questionId].connection.selections.forEach((selection, index) => {
							const fromEl = document.getElementById('connect-' + questionId + '-group-' + selection.from);
							const toEl = document.getElementById('connect-' + questionId + '-item-' + selection.to);
	
							if (fromEl && toEl) {
								const fromRect = fromEl.getBoundingClientRect();
								const toRect = toEl.getBoundingClientRect();
	
								// Calculate relative to parent container
								const x1 = fromRect.right - parentRect.left - 10;
								const y1 = fromRect.top + fromRect.height / 2 - parentRect.top;
								const x2 = toRect.left - parentRect.left + 10;
								const y2 = toRect.top + toRect.height / 2 - parentRect.top;
	
								const line = {
									x1: Math.max(0, x1),
									y1: Math.max(0, y1),
									x2: Math.min(parentRect.width, Math.max(0, x2)),
									y2: Math.max(0, y2),
									color: this.getCompositeGroupColor(questionId, selection.from)
								};
	
								console.log(`Line ${index} for question ${questionId}:`, line);
								newLines.push(line);
							} else {
								console.warn(`Elements not found for selection:`, selection, 'question:', questionId);
							}
						});
	
						// Store lines for this question
						if (!this.compositeLines) this.compositeLines = {};
						this.compositeLines[questionId] = [...newLines];
						console.log('Lines updated for question:', questionId, 'count:', newLines.length);
					}, 100);
				});
			},
	
			getConnectionLines(questionId) {
				if (!this.compositeLines) this.compositeLines = {};
				return this.compositeLines[questionId] || [];
			},
	
			getCompositeActiveGroup(questionId) {
				return this.userAnswers.composite[questionId]?.connection?.activeGroup || null;
			},
	
			getCompositeGroupClass(questionId, groupId) {
				const isActive = this.getCompositeActiveGroup(questionId) === groupId;
				const hasConnection = this.userAnswers.composite[questionId]?.connection?.selections?.find(s => s.from === groupId);
				return {
					'lh-active': isActive,
					'lh-connected': hasConnection
				};
			},
	
			getCompositeItemClass(questionId, itemId) {
				const matches = this.userAnswers.composite[questionId]?.connection?.selections?.filter(s => s.to === itemId) || [];
				return matches.length > 0 ? 'lh-connected' : '';
			},

			getCompositeGroupColor(questionId, groupId) {
				return this.compositeGroupColors[questionId]?.[groupId] || '#4CAF50';
			},

			getCompositeConnectionForItem(questionId, itemId) {
				return this.userAnswers.composite[questionId]?.connection?.selections?.find(s => s.to === itemId);
			},

			getCompositeGroupText(questionId, groupId) {
				const question = this.allQuestions.find(q => q.id === questionId);
				const group = question?.content?.groups?.find(g => g.id === groupId);
				return group ? group.text : '';
			},

			navigateToQuestion(globalIndex) {
				// Save current sortable state before switching
				this.saveCurrentSortableState();
	
				// Clean up current sortables
				this.destroySortableInstances();
	
				this.currentQuestionIndex = globalIndex;
	
				// Initialize sortables for new question
				Vue.nextTick(() => {
					// Draw connection lines if it's connection type
					if (this.currentQuestion?.type === 'QUIZ_CONNECTION') {
						setTimeout(() => {
							this.drawCompositeConnectionLines(this.currentQuestion.id);
						}, 200);
					}
					if (this.currentQuestion?.type === 'QUIZ_MATCHING') {
						this.restoreCompositeMatchingDOM(this.currentQuestion.id);
					}
					this.initCompositeSortables();
				});
	
				this.playSound('navigate');
			},

			nextQuestion() {
				if (this.currentQuestionGlobalIndex < this.allQuestions.length - 1) {
					this.navigateToQuestion(this.currentQuestionGlobalIndex + 1);
				}
			},
	
			previousQuestion() {
				if (this.currentQuestionGlobalIndex > 0) {
					this.navigateToQuestion(this.currentQuestionGlobalIndex - 1);
				}
			},
	
			// ==================== PROGRESS TRACKING METHODS ====================
			getCompletedCount() {
				const questions = this.allQuestions;
				return questions.filter(question => {
					return this.isQuestionCompleted(question.id);
				}).length;
			},
	
			getProgressPercentage() {
				const totalQuestions = this.allQuestions.length;
				if (totalQuestions === 0) return 0;
				return Math.round((this.getCompletedCount() / totalQuestions) * 100);
			},
	
			isQuestionCompleted(questionId) {
				const answer = this.userAnswers.composite[questionId];
				if (!answer) return false;
	
				// Check specific answer types
				if (answer.singleChoice !== null && answer.singleChoice !== undefined) {
					return true;
				}
	
				if (answer.multipleChoice && Array.isArray(answer.multipleChoice) && answer.multipleChoice.length > 0) {
					return true;
				}
	
				if (answer.fillInTheBlank && typeof answer.fillInTheBlank === 'object') {
					const hasFilledBlanks = Object.values(answer.fillInTheBlank).some(val => val && val.toString().trim() !== '');
					return hasFilledBlanks;
				}
	
				if (answer.trueFalse && typeof answer.trueFalse === 'object') {
					const hasAnswered = Object.keys(answer.trueFalse).length > 0;
					return hasAnswered;
				}
	
				if (answer.connection && typeof answer.connection === 'object') {
					const hasConnections = answer.connection.selections && answer.connection.selections.length > 0;
					return hasConnections;
				}
	
				const allQuestions = this.allQuestions;
				const question = allQuestions.find(q => String(q.id) === String(questionId));
				if (question && question.type === 'QUIZ_MATCHING') {
					const totalA = question.content?.columnA?.length || 0;

					// 1. Check DOM dropzones
					const dropzoneRef = 'compositeMatchingDropzones_' + questionId;
					const dropzonesRef = this.$refs[dropzoneRef];
					const dropzones = dropzonesRef ? (Array.isArray(dropzonesRef) ? dropzonesRef : [dropzonesRef]) : Array.from(document.querySelectorAll('.lh-matching-dropzone'));
					const filledCount = dropzones.filter(dz => dz.querySelector('.lh-matching-item-b')).length;
					if (totalA > 0 && filledCount >= totalA) return true;

					// 2. Check matchingSlots state
					const slots = answer.matchingSlots || {};
					const count = Object.keys(slots).length;
					if (totalA > 0 && count >= totalA) return true;

					return false;
				}

				if (answer.ordering && (answer.orderingTouched || answer.ordering.length > 0)) {
					return true;
				}

				if (answer.remainingCount !== undefined) {
					if (question && question.content && question.content.items) {
						return answer.remainingCount < question.content.items.length;
					}
				}

				if (answer.unclassifiedItems !== undefined) {
					if (question && question.content && question.content.items) {
						const completed = answer.unclassifiedItems.length < question.content.items.length;
						return completed;
					}
				}
	
				return false;
			},

			getQuestionButtonClass(globalIndex, questionId) {
				const classes = ['lh-question-btn'];
				if (this.isQuestionCompleted(questionId)) {
					classes.push('lh-completed');
				} else {
					classes.push('lh-pending');
				}
				if (this.currentQuestionGlobalIndex === globalIndex) {
					classes.push('lh-current');
				}
				return classes;
			},

			getGlobalIndex(groupIndex, questionIndex) {
				let globalIndex = 0;
				for (let i = 0; i < groupIndex; i++) {
					globalIndex += this.slideData.content.groups[i].questions.length;
				}
				return globalIndex + questionIndex;
			},

			getGroupProgress(group) {
				const completedInGroup = group.questions.filter(q =>
					this.isQuestionCompleted(q.id)).length;
				return Math.round((completedInGroup / group.questions.length) * 100);
			},

			getGroupScore(group) {
				let score = 0;
				group.questions.forEach(question => {
					if (this.checkQuestionAnswer(question)) {
						score += question.points || 1;
					}
				});
				return score;
			},

			getGroupCompletedCount(group) {
				return group.questions.filter(question => this.checkQuestionAnswer(question)).length;
			},

			// ==================== SORTABLE METHODS ====================
			initCompositeSortables() {
				if (!this.currentQuestion) return;

				// Destroy existing instances first
				this.destroySortableInstances();

				if (this.currentQuestion.type === 'QUIZ_ORDERING') {
					this.initOrderingSortable(this.currentQuestion.id);
				} else if (this.currentQuestion.type === 'QUIZ_MATCHING') {
					this.restoreCompositeMatchingDOM(this.currentQuestion.id);
					this.initMatchingSortable(this.currentQuestion.id);
				} else if (this.currentQuestion.type === 'QUIZ_DRAG_DROP_CATEGORIZE') {
					this.initCategorizeSortable(this.currentQuestion.id);
				}
			},

			initOrderingSortable(questionId) {
				const refName = 'orderingContainer_' + questionId;
				let container = this.$refs[refName];
				if (Array.isArray(container)) container = container[0];
				if (container) {
					const instance = new Sortable(container, {
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						chosenClass: 'lh-sortable-chosen',
						dragClass: 'lh-sortable-drag',
						onEnd: (evt) => {
							this.playSound('drop');
							if (this.userAnswers.composite[questionId]) {
								this.userAnswers.composite[questionId].orderingTouched = true;
								const itemEls = Array.from(container.children);
								const itemIds = itemEls.map(el => String(el.getAttribute('data-id')));
								const items = this.userAnswers.composite[questionId].ordering || [];
								const itemMap = new Map(items.map(item => [String(item.id), item]));
								const newOrdering = itemIds.map(id => itemMap.get(id)).filter(Boolean);
								this.userAnswers.composite[questionId].ordering = newOrdering;
								this.userAnswers.composite = { ...this.userAnswers.composite };
							}
						}
					});
					this.sortableInstances.push(instance);
				}
			},
	
			initMatchingSortable(questionId) {
				// Purely reactive rendering and PointerDrag handle matching drag-and-drop without SortableJS conflicts
			},
	
			initCategorizeSortable(questionId) {
				const updateUnclassified = (sourceContainer) => {
					if (sourceContainer && this.userAnswers.composite[questionId]) {
						const remainingCount = sourceContainer.querySelectorAll('.lh-draggable-item').length;
						const totalItems = this.currentQuestion.content.items?.length || 0;
						// Update counter flag without replacing array reference to prevent Vue template wipe
						this.userAnswers.composite[questionId].remainingCount = remainingCount;
					}
				};

				// Source container
				const sourceRefName = 'sourceContainer_' + questionId;
				let sourceContainer = this.$refs[sourceRefName];
				if (Array.isArray(sourceContainer)) sourceContainer = sourceContainer[0];
				if (sourceContainer) {
					const sourceInstance = new Sortable(sourceContainer, {
						group: 'categorize-group-' + questionId,
						animation: 200,
						ghostClass: 'lh-sortable-ghost',
						chosenClass: 'lh-sortable-chosen',
						dragClass: 'lh-sortable-drag',
						onEnd: () => {
							this.playSound('drop');
							updateUnclassified(sourceContainer);
						}
					});
					this.sortableInstances.push(sourceInstance);
				}
	
				// Category containers
				if (this.currentQuestion.content.categories) {
					this.currentQuestion.content.categories.forEach(category => {
						const categoryRefName = 'categoryContainer_' + questionId + '_' + category.id;
						let categoryContainer = this.$refs[categoryRefName];
						if (Array.isArray(categoryContainer)) categoryContainer = categoryContainer[0];
						if (categoryContainer) {
							const categoryInstance = new Sortable(categoryContainer, {
								group: 'categorize-group-' + questionId,
								animation: 200,
								ghostClass: 'lh-sortable-ghost',
								chosenClass: 'lh-sortable-chosen',
								dragClass: 'lh-sortable-drag',
								onEnd: () => {
									this.playSound('drop');
									updateUnclassified(sourceContainer);
								}
							});
							this.sortableInstances.push(categoryInstance);
						}
					});
				}
			},
	
			destroySortableInstances() {
				this.sortableInstances.forEach(instance => {
					try {
						instance.destroy();
					} catch (e) {
						console.warn('Error destroying sortable instance:', e);
					}
				});
				this.sortableInstances = [];
			},
	
			saveCurrentSortableState() {
				if (!this.currentQuestion) return;
	
				const questionId = this.currentQuestion.id;
	
				if (this.currentQuestion.type === 'QUIZ_ORDERING') {
					const refName = 'orderingContainer_' + questionId;
					const container = this.$refs[refName];
					if (container) {
						const orderedItems = Array.from(container.children).map(el => {
							const itemId = el.dataset.id;
							return this.userAnswers.composite[questionId].ordering.find(item => item.id === itemId);
						}).filter(Boolean);
						this.userAnswers.composite[questionId].ordering = orderedItems;
					}
				} else if (this.currentQuestion.type === 'QUIZ_MATCHING') {
					if (!this.userAnswers.composite[questionId]) return;
					if (!this.userAnswers.composite[questionId].matchingSlots) {
						this.setProp(this.userAnswers.composite[questionId], 'matchingSlots', {});
					}
					const dropzones = Array.from(document.querySelectorAll('.lh-matching-dropzone'));
					dropzones.forEach(dz => {
						const itemAId = dz.dataset.itemAId;
						const itemBEl = dz.querySelector('.lh-matching-item-b');
						if (itemAId && itemBEl && itemBEl.dataset.id) {
							this.setProp(this.userAnswers.composite[questionId].matchingSlots, String(itemAId), String(itemBEl.dataset.id));
						}
					});
				}
			},
	
			// ==================== SUBMISSION & SCORING METHODS ====================
			submitTest() {
				if (this.timer) clearInterval(this.timer);

				// Save current state
				this.saveCurrentSortableState();

				// Calculate score
				let score = 0;
				const questions = this.allQuestions;

				questions.forEach(question => {
					if (this.checkQuestionAnswer(question)) {
						score += question.points || 1;
					}
				});

				const totalPoints = this.totalPoints || questions.length || 1;
				const isAllCorrect = (score >= questions.length);

				this.testResult = {
					score: score,
					totalPoints: totalPoints,
					passed: isAllCorrect,
					isCorrect: isAllCorrect,
					result: isAllCorrect,
					percentage: Math.round((score / totalPoints) * 100)
				};

				if (isAllCorrect) {
					this.showToast("🎉 Tuyệt vời! Em đã hoàn thành đúng tất cả các câu hỏi!", "success");
				} else {
					this.showToast("😅 Chưa đúng hết các câu hỏi. Em hãy kiểm tra lại nhé!", "warning");
				}

				this.playSound(isAllCorrect ? 'success' : 'try-again');

				// Emit result to parent
				this.$emit('quiz-result', {
					isCorrect: isAllCorrect,
					result: isAllCorrect,
					passed: isAllCorrect,
					slideId: this.slideData?.id
				});
				this.$emit('quiz-completed', this.testResult);
			},
	
			reviewTest() {
				this.quizState = 'doing';
				this.currentQuestionIndex = 0;
			},
	
			checkQuestionAnswer(question) {
				const userAnswer = this.userAnswers.composite[question.id];
				if (!userAnswer) return false;

				switch (question.type) {
					case 'QUIZ_SINGLE_CHOICE':
						const userChoice = String(userAnswer.singleChoice);
						const correctChoice = String(question.content.correctAnswer);
						return userChoice === correctChoice;
	
					case 'QUIZ_MULTIPLE_CHOICE':
						const correctAnswers = (question.content.correctAnswers || []).map(String).sort();
						const userAnswers = (userAnswer.multipleChoice || []).map(String).sort();
						return JSON.stringify(userAnswers) === JSON.stringify(correctAnswers);

					case 'QUIZ_MATCHING':
						const columnA_Items = question.content?.columnA || [];
						const columnB_Items = question.content?.columnB || [];
						const correctPairs = question.content?.pairs || question.content?.correctPairs || [];

						if (columnA_Items.length === 0) return false;

						const slots = userAnswer.matchingSlots || {};
						const dropzoneRef = 'compositeMatchingDropzones_' + question.id;
						const dropzonesRef = this.$refs[dropzoneRef];
						let matchCorrect = true;

						for (let i = 0; i < columnA_Items.length; i++) {
							const itemA = columnA_Items[i];
							let assignedBId = slots[String(itemA.id)];

							if (!assignedBId && dropzonesRef) {
								const dropzones = Array.isArray(dropzonesRef) ? dropzonesRef : [dropzonesRef];
								const dz = dropzones.find(d => String(d.dataset.itemAId) === String(itemA.id));
								if (dz) {
									const itemBEl = Array.from(dz.children).find(c => c.classList.contains('lh-matching-item-b'));
									if (itemBEl) assignedBId = itemBEl.dataset.id;
								}
							}

							if (!assignedBId) {
								matchCorrect = false;
								break;
							}

							const itemB = columnB_Items.find(b => String(b.id) === String(assignedBId));
							if (!itemB || !this.isMatchingPair(itemA, itemB, correctPairs, columnA_Items, columnB_Items)) {
								matchCorrect = false;
								break;
							}
						}
						return matchCorrect;
	
					case 'QUIZ_FILL_IN_BLANK':
						let allCorrect = true;
						question.content.parts.forEach(part => {
							if (part.type === 'blank') {
								const userAns = (userAnswer.fillInTheBlank[part.id] || '').toLowerCase().trim();
								const correctAns = (part.correctAnswer || '').toLowerCase().trim();
								if (userAns !== correctAns) {
									allCorrect = false;
								}
							}
						});
						return allCorrect;
	
					case 'QUIZ_CONNECTION':
						let correctCount = 0;
						const userSelectionsMap = new Map(
							(userAnswer.connection?.selections || []).map(s => [String(s.to), String(s.from)])
						);
	
						question.content.items.forEach(item => {
							const userGroup = userSelectionsMap.get(String(item.id));
							const correctGroup = String(item.groupId);
							console.log(`Connection item ${item.id} - User group: ${userGroup}, Correct group: ${correctGroup}`);
							if (userGroup === correctGroup) {
								correctCount++;
							}
						});
						const isCorrect = correctCount === question.content.items.length;
						console.log('Connection - Correct count:', correctCount, 'Total items:', question.content.items.length, 'Result:', isCorrect);
						return isCorrect;
	
					case 'QUIZ_TRUE_FALSE':
					case 'QUIZ_TRUE_FALSE_LIST':
					case 'TRUE_FALSE':
					case 'MATCHING_TF': {
						const userTFMap = userAnswer.trueFalse || {};
						const options = question.content?.options || question.content?.items || [];
						if (!options || options.length === 0) return false;

						let allTFCorrect = true;
						for (const option of options) {
							const userChoice = userTFMap[option.id];
							if (userChoice === undefined || userChoice === null) {
								allTFCorrect = false;
								break;
							}

							let expectedValue = null;
							if (typeof option.isCorrect === 'boolean') {
								expectedValue = option.isCorrect;
							} else if (typeof option.correctAnswer === 'boolean') {
								expectedValue = option.correctAnswer;
							} else if (typeof option.isTrue === 'boolean') {
								expectedValue = option.isTrue;
							} else if (option.correctAnswer !== undefined && option.correctAnswer !== null) {
								const strAns = String(option.correctAnswer).trim().toLowerCase();
								expectedValue = (strAns === 'true' || strAns === '1' || strAns === 'đúng' || strAns === 'dung');
							} else if (option.isCorrect !== undefined && option.isCorrect !== null) {
								const strAns = String(option.isCorrect).trim().toLowerCase();
								expectedValue = (strAns === 'true' || strAns === '1' || strAns === 'đúng' || strAns === 'dung');
							} else if (option.answer !== undefined && option.answer !== null) {
								const strAns = String(option.answer).trim().toLowerCase();
								expectedValue = (strAns === 'true' || strAns === '1' || strAns === 'đúng' || strAns === 'dung');
							} else if (option.value !== undefined && option.value !== null) {
								const strAns = String(option.value).trim().toLowerCase();
								expectedValue = (strAns === 'true' || strAns === '1' || strAns === 'đúng' || strAns === 'dung');
							}

							if (expectedValue !== null && Boolean(userChoice) !== Boolean(expectedValue)) {
								allTFCorrect = false;
								break;
							}
						}
						return allTFCorrect;
					}

					// Add other question types here...
					default:
						return false;
				}
			},
	
			// ==================== TRUE/FALSE METHODS ====================
			updateTrueFalseComposite(option, val) {
				if (val !== null && val !== undefined) {
					if (this.currentQuestion) {
						if (!this.userAnswers.composite[this.currentQuestion.id]) {
							this.userAnswers.composite[this.currentQuestion.id] = { trueFalse: {} };
						}
						if (!this.userAnswers.composite[this.currentQuestion.id].trueFalse) {
							this.userAnswers.composite[this.currentQuestion.id].trueFalse = {};
						}
	
						this.userAnswers.composite[this.currentQuestion.id].trueFalse[option.id] = val;
					}
				}
			},
	
			getTrueFalseValue(optionId) {
				if (this.currentQuestion && this.userAnswers.composite[this.currentQuestion.id]?.trueFalse) {
					return this.userAnswers.composite[this.currentQuestion.id].trueFalse[optionId];
				}
				return undefined;
			},
	
			getTrueFalseBackgroundColor(optionId) {
				const value = this.getTrueFalseValue(optionId);
				if (value === true) return 'success';
				if (value === false) return 'error';
				return 'white';
			},
	
			// ==================== UTILITY METHODS ====================
			shuffleArray(array) {
				const newArray = [...array];
				for (let i = newArray.length - 1; i > 0; i--) {
					const j = Math.floor(Math.random() * (i + 1));
					[newArray[i], newArray[j]] = [newArray[j], newArray[i]];
				}
				return newArray;
			},
	
			getQuestionTypeLabel(type) {
				return this.questionTypeLabels[type] || type;
			},
	
			getOptionClass(optionId) {
				// Return empty for now in composite quiz
				return '';
			},
	
			isImage(value) {
				if (!value) return false;
				const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
				return /^https?:\/\//.test(value) && imageExtensions.some(ext => value.toLowerCase().endsWith(ext));
			},
	
			playSound(type) {
				const sounds = {
					start: '/_cdn/lhbs-lms/sounds/start.mp3',
					correct: '/_cdn/lhbs-lms/sounds/correct.mp3',
					wrong: '/_cdn/lhbs-lms/sounds/wrong.mp3',
					success: '/_cdn/lhbs-lms/sounds/success.mp3',
					'try-again': '/_cdn/lhbs-lms/sounds/try-again.mp3',
					navigate: '/_cdn/lhbs-lms/sounds/click.mp3',
					drop: '/_cdn/lhbs-lms/sounds/drop.mp3',
					'fullscreen-enter': '/_cdn/lhbs-lms/sounds/fullscreen-enter.mp3',
					'fullscreen-exit': '/_cdn/lhbs-lms/sounds/fullscreen-exit.mp3'
				};
	
				if (sounds[type]) {
					const audio = new Audio(sounds[type]);
					audio.volume = 0.3;
					audio.play().catch(() => { }); // Ignore audio errors
				}
			},
	
			showToast(message, type = 'info') {
				// Use Vue toast if available, otherwise fallback to console
				if (this.$toast) {
					this.$toast[type](message);
				} else if (Vue.$toast) {
					Vue.$toast[type](message);
				} else {
					// console.log(`[${type.toUpperCase()}] ${message}`);
				}
			},
	
			// ==================== FULLSCREEN METHODS ====================
			toggleQuizFullscreen() {
				if (this.isQuizFullscreen) {
					this.exitQuizFullscreen();
				} else {
					this.enterQuizFullscreen();
				}
			},
	
			enterQuizFullscreen() {
				const container = this.$el.querySelector('.lh-quiz-layout');
				if (!container) return;
	
				container.requestFullscreen().then(() => {
					this.isQuizFullscreen = true;
					document.addEventListener('keydown', this.handleFullscreenKeydown);
					this.playSound('fullscreen-enter');
				}).catch((err) => {
					console.error('Fullscreen failed:', err);
				});
			},
	
			exitQuizFullscreen() {
				if (document.fullscreenElement) {
					document.exitFullscreen();
					this.isQuizFullscreen = false;
					document.removeEventListener('keydown', this.handleFullscreenKeydown);
					this.playSound('fullscreen-exit');
				}
			},
	
			handleFullscreenKeydown(event) {
				if (event.key === 'Escape') {
					event.preventDefault();
					this.exitQuizFullscreen();
				}
			},
	
			addFullscreenOverlay() {
				const overlay = document.createElement('div');
				overlay.className = 'lh-fullscreen-overlay';
				overlay.id = 'lh-fullscreen-overlay';
				overlay.addEventListener('click', this.exitQuizFullscreen);
				document.body.appendChild(overlay);
			},
	
			removeFullscreenOverlay() {
				const overlay = document.getElementById('lh-fullscreen-overlay');
				if (overlay) {
					overlay.remove();
				}
			},
	
			announceFullscreen(message) {
				const announcer = document.createElement('div');
				announcer.setAttribute('aria-live', 'polite');
				announcer.setAttribute('aria-atomic', 'true');
				announcer.style.position = 'absolute';
				announcer.style.left = '-10000px';
				announcer.textContent = message;
	
				document.body.appendChild(announcer);
	
				setTimeout(() => {
					announcer.remove();
				}, 1000);
			},
	
			resetStates() {
				// Clear timer
				if (this.timer) {
					clearInterval(this.timer);
					this.timer = null;
				}
	
				// Destroy sortable instances
				this.destroySortableInstances();
	
				// Exit fullscreen if active
				if (this.isQuizFullscreen) {
					this.exitQuizFullscreen();
				}
	
				// Reset to initial state
				this.quizState = 'start';
				this.currentQuestionIndex = 0;
				this.timeLeft = 0;
				this.userAnswers = { composite: {} };
				this.testResult = { score: 0, passed: false };
				this.compositeGroupColors = {};
				this.compositeLines = {};
			}
		},
	
		mounted() {
			// Component mounted logic
			if (this.slideData) {
				this.initializeQuiz();
			}
	
			// Add window resize listener for connection quiz
			this.resizeHandler = () => {
				if (this.currentQuestion?.type === 'QUIZ_CONNECTION') {
					setTimeout(() => {
						this.drawCompositeConnectionLines(this.currentQuestion.id);
					}, 100);
				}
			};
			window.addEventListener('resize', this.resizeHandler);
		},
	
		beforeDestroy() {
			this.resetStates();
	
			// Clean up resize listener
			if (this.resizeHandler) {
				window.removeEventListener('resize', this.resizeHandler);
			}
		}
  };
  Vue.component("uc-quiz-composite", compDef);
})();

})();

