<template>
	<div v-if="item" class="uc-baihoc-content">
		<h2 class="text-h6 mb-4 d-flex align-center">
			<uc-latex-view :content="item.TenNoiDung || ''" />
		</h2>

		<!-- Parent có nội dung riêng cần được giới thiệu trước danh sách node con. -->
		<div v-if="hasNodeContent && hasChildNodes" class="node-content-preview mb-4">
			<div class="node-content-preview__header d-flex align-center justify-space-between flex-wrap ga-2">
				<div class="d-flex align-center ga-2">
					<v-icon color="teal-darken-2" size="20">mdi-book-open-page-variant-outline</v-icon>
					<strong class="text-subtitle-2 text-teal-darken-3">Nội dung của {{ item.TenNoiDung || 'bài học' }}</strong>
				</div>
				<v-btn
					color="success"
					variant="tonal"
					size="small"
					rounded="pill"
					@click="handleClick(item)"
				>
					<v-icon start size="small">mdi-play-circle</v-icon> Mở nội dung
				</v-btn>
			</div>
			<!-- Parent có nội dung riêng và phần con chỉ hiển thị tóm tắt; không đổ HTML/JSON thô vào trang mục lục. -->
			<div class="node-content-preview__body d-flex align-center ga-3">
				<v-icon color="teal-darken-2" size="32">{{ getIcon(item.LoaiNoiDung) }}</v-icon>
				<div>
					<div class="text-subtitle-2 font-weight-bold text-teal-darken-3">{{ getContentTypeLabel(item) }}</div>
					<div class="text-body-2 text-grey-darken-1">
						Mục này có nội dung riêng và {{ getChildCount(item) }} phần bên trong. Chọn “Mở nội dung” để xem chi tiết.
					</div>
				</div>
			</div>
		</div>

		<div v-if="hasChildNodes" class="children-section-title d-flex align-center ga-2 mb-3">
			<v-icon color="teal" size="18">mdi-format-list-bulleted</v-icon>
			<strong class="text-subtitle-2">Các phần trong {{ item.TenNoiDung || 'bài học' }}</strong>
		</div>

		<!-- DÀNH CHO MÀN HÌNH MÁY TÍNH (DESKTOP): ĐẦY ĐỦ CHI TIẾT -->
		<div class="d-none d-sm-block">
			<!-- Trường hợp 1: Mục chứa các Nhóm con có chứa hoạt động -->
			<div v-if="hasGroupChildren">
				<template v-for="(nhom, index) in item.children" :key="nhom.NoiDungID || index">
					<!-- NẾU MỤC LÀ 1 HOẠT ĐỘNG / TÀI LIỆU ĐƠN LẺ KHÔNG CÓ CON (Ví dụ: Ví dụ 3, Vận dụng, Mô phỏng...) -->
					<!-- Thiết kế dạng thẻ hoạt động độc lập (card) với icon, badge phân loại và nút Học ngay, tránh tạo khoảng trắng thừa hay banner rỗng -->
					<div
						v-if="!nhom.children || nhom.children.length === 0"
						class="lesson-standalone-card pa-3 mb-3 border rounded-lg d-flex justify-space-between align-center bg-white"
						:class="{ 'lesson-item--active': isItemActive(nhom) }"
						@click="handleClick(nhom)"
					>
						<div class="d-flex align-center flex-grow-1 min-width-0 pr-3">
							<div class="lesson-standalone-icon-wrap d-flex align-center justify-center mr-3 rounded-circle flex-shrink-0">
								<v-icon size="20" color="teal-darken-2">{{ getIcon(nhom.LoaiNoiDung) }}</v-icon>
							</div>
							<div class="min-width-0">
								<div class="d-flex align-center flex-wrap ga-2">
									<uc-latex-view class="text-subtitle-2 font-weight-bold text-slate-800" :content="nhom.TenNoiDung || ''" />
									<!-- Hiển thị badge loại học liệu để người dùng nhận diện nhanh loại nội dung -->
									<v-chip size="x-small" color="teal" variant="tonal" class="font-weight-medium">
										{{ getContentTypeLabel(nhom) }}
									</v-chip>
									<v-chip v-if="nhom.IsTeacherOnly" size="x-small" color="warning" variant="flat" class="font-weight-medium" label>
										<v-icon start size="x-small">mdi-account-tie</v-icon>
										Chỉ GV
									</v-chip>
								</div>
							</div>
						</div>
						<div class="d-flex align-center flex-shrink-0">
							<v-btn
								v-if="hasExecutableContent(nhom)"
								color="success"
								variant="tonal"
								size="small"
								rounded="pill"
								class="font-weight-bold px-3"
								@click.stop="handleClick(nhom)"
							>
								<v-icon start size="small">mdi-play-circle</v-icon> Học ngay
							</v-btn>
						</div>
					</div>

					<!-- NẾU NHÓM LÀ TIÊU ĐỀ CONTAINER CHỨA CÁC BÀI/HOẠT ĐỘNG CON -->
					<div v-else class="lesson-box mb-4 border rounded-lg overflow-hidden bg-white">
						<div class="lesson-header lesson-header--group pa-3 font-weight-bold d-flex justify-space-between align-center">
							<div class="d-flex align-center flex-grow-1 min-width-0">
								<v-icon class="mr-2" size="20" color="teal-darken-3">mdi-folder-open-outline</v-icon>
								<uc-latex-view class="text-subtitle-1 font-weight-bold text-teal-darken-3" :content="nhom.TenNoiDung || ''" />
							</div>
							<span class="node-child-count d-flex align-center text-caption font-weight-bold text-teal-darken-3 flex-shrink-0 ml-2">
								<v-icon size="15" class="mr-1">mdi-format-list-bulleted</v-icon>
								{{ getChildCount(nhom) }} phần
							</span>
						</div>
						
						<!-- Danh sách các hoạt động con bên trong nhóm -->
						<div class="pa-1">
							<div
								v-for="(hoatDong, i) in nhom.children"
								:key="hoatDong.NoiDungID"
								class="lesson-item pa-3 d-flex justify-space-between align-center border-bottom rounded-md my-1"
								:class="{ 'lesson-item--active': isItemActive(hoatDong) }"
								@click="handleClick(hoatDong)"
							>
								<div class="d-flex align-center flex-grow-1 pr-2 min-width-0">
									<strong class="mr-2 text-grey-darken-1 text-caption">{{ i + 1 }}.</strong>
									<v-icon class="node-icon mr-2 flex-shrink-0" size="small" :color="isItemActive(hoatDong) ? 'success' : 'teal'">{{ getIcon(hoatDong.LoaiNoiDung) }}</v-icon>
									<uc-latex-view class="text-body-2" :class="isItemActive(hoatDong) ? 'font-weight-bold text-success' : 'font-weight-medium'" :content="hoatDong.TenNoiDung || ''" />
								</div>
								<div class="d-flex align-center flex-shrink-0 ml-2">
									<!-- Hiển thị số phần con ngay trên dòng nếu mục có con -->
									<span v-if="shouldShowChildCount(hoatDong)" class="node-child-count d-flex align-center text-caption font-weight-bold text-teal-darken-3 mr-2">
										<v-icon size="15" class="mr-1">mdi-format-list-bulleted</v-icon>
										{{ getChildCount(hoatDong) }} phần
									</span>
									<!-- Nút Học ngay mở trực tiếp nội dung tương tác -->
									<v-btn
										v-if="hasExecutableContent(hoatDong)"
										color="success"
										variant="tonal"
										size="x-small"
										rounded="pill"
										class="font-weight-bold px-3"
										@click.stop="handleClick(hoatDong)"
									>
										<v-icon start size="x-small">mdi-play-circle</v-icon> Học ngay
									</v-btn>
								</div>
							</div>
						</div>
					</div>
				</template>
			</div>

			<!-- Trường hợp 2: Mục chứa danh sách Hoạt Động trực tiếp (không có nhóm trung gian) -->
			<div v-else-if="item.children && item.children.length > 0" class="lesson-box mb-4 border rounded-lg overflow-hidden pa-1 bg-white">
				<div
					v-for="(hoatDong, i) in item.children"
					:key="hoatDong.NoiDungID"
					class="lesson-item pa-3 d-flex justify-space-between align-center border-bottom rounded-md my-1"
					:class="{ 'lesson-item--active': isItemActive(hoatDong) }"
					@click="handleClick(hoatDong)"
				>
					<div class="d-flex align-center flex-grow-1 pr-2">
						<strong class="mr-2 text-grey-darken-1">{{ i + 1 }}.</strong>
						<v-icon class="node-icon mr-2" size="small" :color="isItemActive(hoatDong) ? 'success' : 'teal'">{{ getIcon(hoatDong.LoaiNoiDung) }}</v-icon>
						<uc-latex-view class="text-body-2" :class="isItemActive(hoatDong) ? 'font-weight-bold text-success' : 'font-weight-medium'" :content="hoatDong.TenNoiDung || ''" />
					</div>
					<div class="d-flex align-center flex-shrink-0 ml-2">
						<span v-if="shouldShowChildCount(hoatDong)" class="node-child-count d-flex align-center text-caption font-weight-bold text-teal-darken-3">
							<v-icon size="15" class="mr-1">mdi-format-list-bulleted</v-icon>
							{{ getChildCount(hoatDong) }} phần
						</span>
						<v-btn
							v-if="hasExecutableContent(hoatDong)"
							color="success"
							variant="tonal"
							size="x-small"
							rounded="pill"
							class="font-weight-bold ml-2 px-3"
							@click.stop="handleClick(hoatDong)"
						>
							<v-icon start size="x-small">mdi-play-circle</v-icon> Học ngay
						</v-btn>
					</div>
				</div>
			</div>

			<!-- Trường hợp 3: Mục là HOẠT ĐỘNG ĐƠN LẺ / LEAF NODE CÓ THỂ HỌC (Bài học HTML, Quiz, Video, Slide, Tài liệu, Mô phỏng...) -->
			<!-- Thiết kế gọn gàng, hiện đại; không nhúng khung preview dài làm loãng mục lục -->
			<div v-else-if="isPlayableLeafNode(item)" class="single-activity-box text-center pa-6 border rounded-xl bg-white shadow-sm mt-3 mx-auto" style="max-width: 680px;">
				<!-- Badge nhận diện loại nội dung học liệu -->
				<div class="d-flex justify-center mb-3">
					<v-chip
						:color="getActivityColor(item)"
						variant="tonal"
						size="small"
						class="font-weight-bold px-3"
					>
						<v-icon start size="16">{{ getActivityIcon(item) }}</v-icon>
						{{ getContentTypeLabel(item) }}
					</v-chip>
				</div>

				<!-- Biểu tượng chính đại diện cho loại học liệu -->
				<div class="single-activity-icon-wrap mx-auto mb-3 d-flex align-center justify-center rounded-circle" :class="getActivityBgClass(item)">
					<v-icon size="36" :color="getActivityColor(item)">{{ getActivityIcon(item) }}</v-icon>
				</div>

				<!-- Tiêu đề hoạt động / bài học -->
				<h3 class="text-subtitle-1 text-md-h6 font-weight-bold mb-2 text-slate-800">
					<uc-latex-view :content="item.TenNoiDung || ''" />
				</h3>

				<!-- Mô tả ngắn gọn, đúng thuật ngữ sư phạm cho từng loại -->
				<p class="text-body-2 text-grey-darken-1 mb-4 mx-auto" style="max-width: 540px;">
					{{ getActivityDescription(item) }}
				</p>

				<!-- Nút mở nội dung bài học -->
				<div class="d-flex justify-center mt-2">
					<v-btn
						:color="getActivityButtonColor(item)"
						size="large"
						rounded="pill"
						class="px-6 font-weight-bold single-activity-button elevation-1"
						@click="handleClick(item)"
					>
						<div class="d-flex align-center justify-center ga-2">
							<v-icon size="20">{{ getActivityButtonIcon(item) }}</v-icon>
							<span class="text-subtitle-2 font-weight-bold single-activity-button__label">{{ getActivityButtonLabel(item) }}</span>
						</div>
					</v-btn>
				</div>
			</div>

			<!-- Trường hợp 4: Mục CHƯƠNG / CONTAINER KHÔNG CÓ TRỰC TIẾP MEDIA -->
			<div v-else class="single-activity-box text-center pa-6 border rounded-xl bg-teal-lighten-5 mt-4">
				<v-icon size="48" color="teal-darken-2" class="mb-2">mdi-folder-text-outline</v-icon>
				<h3 class="text-subtitle-1 font-weight-bold text-teal-darken-3 mb-1">
					<uc-latex-view :content="item.TenNoiDung || ''" />
				</h3>
				<p class="text-caption text-grey-darken-1 mb-0">Đây là thư mục chương/nhóm bài học. Vui lòng chọn bài học cụ thể từ danh sách mục lục bên trên hoặc từ cây bên trái.</p>
			</div>
		</div>

		<!-- DÀNH CHO MÀN HÌNH MOBILE (SM AND DOWN) -->
		<div class="d-block d-sm-none">
			<!-- Nếu là Bài học đơn lẻ / Leaf Node playable -->
			<div v-if="isPlayableLeafNode(item)" class="single-activity-box text-center pa-4 border rounded-xl bg-white shadow-sm mt-2">
				<div class="d-flex justify-center mb-2">
					<v-chip
						:color="getActivityColor(item)"
						variant="tonal"
						size="x-small"
						class="font-weight-bold px-2"
					>
						<v-icon start size="14">{{ getActivityIcon(item) }}</v-icon>
						{{ getContentTypeLabel(item) }}
					</v-chip>
				</div>

				<div class="single-activity-icon-wrap mx-auto mb-2 d-flex align-center justify-center rounded-circle" :class="getActivityBgClass(item)" style="width: 52px; height: 52px;">
					<v-icon size="30" :color="getActivityColor(item)">{{ getActivityIcon(item) }}</v-icon>
				</div>

				<h3 class="text-subtitle-2 font-weight-bold text-slate-800 mb-1">
					<uc-latex-view :content="item.TenNoiDung || ''" />
				</h3>

				<p class="text-caption text-grey-darken-1 mb-3">
					{{ getActivityDescription(item) }}
				</p>

				<v-btn
					:color="getActivityButtonColor(item)"
					size="medium"
					rounded="pill"
					block
					class="font-weight-bold elevation-1 single-activity-button single-activity-button--mobile mt-2"
					@click="handleClick(item)"
				>
					<div class="d-flex align-center justify-center ga-2">
						<v-icon size="18">{{ getActivityButtonIcon(item) }}</v-icon>
						<span class="text-subtitle-2 font-weight-bold single-activity-button__label">{{ getActivityButtonLabel(item) }}</span>
					</div>
				</v-btn>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: {
			item: { type: Object, default: null },
			onHoatDongClick: { type: Function, default: () => {} }
		},
		computed: {
			hasGroupChildren() {
				if (!this.item || !this.item.children || !Array.isArray(this.item.children)) return false;
				return this.item.children.some(child => child.children && Array.isArray(child.children) && child.children.length > 0);
			},
			hasChildNodes() {
				return !!(this.item && Array.isArray(this.item.children) && this.item.children.length > 0);
			},
			nodeContent() {
				return this.normalizeNodeContent(this.item && this.item.DataJson);
			},
			hasNodeContent() {
				if (!this.item) return false;
				// Mục Bài tạo từ tab Tạo mục không có nội dung riêng nếu chưa có DataJson;
				// card preview chỉ hiện khi node thực sự có dữ liệu hoặc là loại nội dung xem được.
				return !!this.nodeContent.html || !!this.nodeContent.text || this.hasExecutableContent(this.item);
			},
			// Trích xuất cấu trúc chi tiết của câu hỏi / bài tập từ DataJson
			parsedQuizData() {
				if (!this.item) return null;
				const loai = String(this.item.LoaiNoiDung || '').toUpperCase();
				if (!this.isQuizType(loai)) return null;

				try {
					let raw = this.item.DataJson;
					if (!raw) return { type: loai, question: this.item.TenNoiDung, options: [] };
					let data = typeof raw === 'object' ? raw : JSON.parse(raw);
					if (data.content && typeof data.content === 'object') data = { ...data, ...data.content };
					if (data.config && typeof data.config === 'object') data = { ...data, ...data.config };
					if (data.question && typeof data.question === 'object') data = { ...data, ...data.question };

					let opts = data.options || data.answers || data.choices || data.dapAn || data.Options || [];
					let qText = data.questionText || data.prompt || data.question || data.cauHoi || data.title || this.item.TenNoiDung || '';
					if (typeof qText === 'object') {
						qText = qText.html || qText.text || qText.content || '';
					}

					return {
						type: loai,
						question: qText,
						options: Array.isArray(opts) ? opts : [],
						explanation: data.explanation || data.loiGiai || '',
						parts: Array.isArray(data.parts) ? data.parts : []
					};
				} catch (e) {
					return { type: loai, question: this.item.TenNoiDung, options: [] };
				}
			}
		},
		methods: {
			// Lấy nhãn chuỗi đại diện cho từng phương án trắc nghiệm
			getOptionText(opt) {
				if (opt === null || opt === undefined) return '';
				if (typeof opt === 'string') return opt;
				if (typeof opt === 'object') {
					return opt.text || opt.label || opt.title || opt.content || opt.value || JSON.stringify(opt);
				}
				return String(opt);
			},

			// Phân loại tổng quát Câu hỏi / Bài tập
			isQuizType(loai) {
				const l = String(loai || '').toUpperCase();
				return l.startsWith('QUIZ') || l.includes('QUIZ') || l.includes('TRAC_NGHIEM') || l.includes('QUESTION');
			},

			// Câu hỏi trắc nghiệm chọn đáp án (Single / Multiple Choice)
			isQuizChoiceType(loai) {
				const l = String(loai || '').toUpperCase();
				return ['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ', 'TRAC_NGHIEM'].includes(l) || (!l.includes('FILL') && !l.includes('MATCH') && !l.includes('ORDER') && this.isQuizType(l));
			},

			isMultipleChoice(loai) {
				const l = String(loai || '').toUpperCase();
				return l === 'QUIZ_MULTIPLE_CHOICE';
			},

			isFillInBlank(loai) {
				const l = String(loai || '').toUpperCase();
				return l === 'QUIZ_FILL_IN_BLANK' || l.includes('FILL') || l.includes('DIEN_KHUYET');
			},

			isMatching(loai) {
				const l = String(loai || '').toUpperCase();
				return l === 'QUIZ_MATCHING' || l.includes('MATCH') || l.includes('GHEP_DOI');
			},

			isOrdering(loai) {
				const l = String(loai || '').toUpperCase();
				return l === 'QUIZ_ORDERING' || l.includes('ORDER') || l.includes('SAP_XEP');
			},

			// Kiểm tra loại nội dung là Video
			isVideoType(loai) {
				const l = String(loai || '').toUpperCase();
				return l === 'VIDEO' || l === 'YOUTUBE' || l === 'MEDIA';
			},

			// Kiểm tra loại nội dung là Slide trình chiếu
			isSlideType(loai) {
				const l = String(loai || '').toUpperCase();
				return l === 'SLIDE' || l === 'ISPRING_CONTENT' || l === 'PRESENTATION';
			},

			// Kiểm tra loại nội dung là Tài liệu
			isDocType(loai) {
				const l = String(loai || '').toUpperCase();
				return ['TAILIEU', 'TAI_LIEU', 'READING', 'PDF', 'DOCUMENT', 'DOC'].includes(l);
			},

			// Kiểm tra loại nội dung là Bài đọc / HTML
			isHtmlDoc(loai) {
				const l = String(loai || '').toUpperCase();
				return l === 'HTML' || l === 'READING' || l === 'READINGWITHIMAGE';
			},

			// Kiểm tra loại nội dung là Mô phỏng tương tác
			isInteractive(loai) {
				const l = String(loai || '').toUpperCase();
				return l === 'INTERACTIVE' || l === 'GEOGEBRA' || l === 'PHET' || l === 'DESMOS';
			},

			// Mô tả ngữ cảnh chi tiết, chuẩn xác theo từng loại nội dung
			getActivityDescription(node) {
				if (!node) return '';
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (this.isQuizChoiceType(loai)) {
					return 'Câu hỏi trắc nghiệm tương tác giúp củng cố kiến thức. Chọn để bắt đầu làm bài.';
				}
				if (this.isFillInBlank(loai)) {
					return 'Bài tập điền khuyết rèn luyện kỹ năng và công thức. Chọn để hoàn thành bài tập.';
				}
				if (this.isMatching(loai)) {
					return 'Bài tập nối cột, ghép đôi các cặp khái niệm tương ứng. Chọn để làm bài.';
				}
				if (this.isOrdering(loai)) {
					return 'Bài tập sắp xếp theo trình tự logic của quy trình hoặc bài toán. Chọn để làm bài.';
				}
				if (this.isVideoType(loai)) {
					return 'Video bài giảng trực quan, sinh động. Chọn để theo dõi bài giảng.';
				}
				if (this.isSlideType(loai)) {
					return 'Bài trình chiếu bài giảng điện tử. Chọn để mở xem toàn màn hình.';
				}
				if (this.isDocType(loai)) {
					return 'Tài liệu học tập và phiếu hướng dẫn học tập. Chọn để mở xem tài liệu.';
				}
				if (this.isInteractive(loai)) {
					return 'Mô phỏng tương tác trực quan. Chọn để khám phá và thực hành.';
				}
				if (loai === 'HTML' || loai === 'READING' || loai === 'READINGWITHIMAGE') {
					return 'Bài đọc và nội dung lý thuyết minh họa. Chọn để vào xem bài học.';
				}
				return 'Nội dung học tập tương tác. Chọn để mở bài học.';
			},

			// Nhãn nút tương ứng với từng loại nội dung
			getActivityButtonLabel(node) {
				if (!node) return 'Vào bài học';
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (this.isQuizType(loai)) return 'Bắt đầu làm bài';
				if (this.isVideoType(loai)) return 'Xem video bài giảng';
				if (this.isSlideType(loai)) return 'Xem bài trình chiếu';
				if (this.isDocType(loai)) return 'Xem tài liệu';
				if (this.isInteractive(loai)) return 'Khám phá mô phỏng';
				if (this.isHtmlDoc(loai)) return 'Vào bài học';
				return 'Vào bài học';
			},

			// Biểu tượng nút tương ứng
			getActivityButtonIcon(node) {
				if (!node) return 'mdi-book-open-page-variant-outline';
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (this.isQuizType(loai)) return 'mdi-pencil-outline';
				if (this.isVideoType(loai)) return 'mdi-play-circle';
				if (this.isSlideType(loai)) return 'mdi-presentation';
				if (this.isDocType(loai)) return 'mdi-file-eye-outline';
				if (this.isInteractive(loai)) return 'mdi-open-in-app';
				if (this.isHtmlDoc(loai)) return 'mdi-book-open-page-variant-outline';
				return 'mdi-play-circle';
			},

			getActivityIcon(loai) {
				return this.getIcon(typeof loai === 'object' ? loai.LoaiNoiDung : loai);
			},

			// Màu chủ đạo của chip và icon
			getActivityColor(node) {
				if (!node) return 'teal-darken-2';
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (this.isQuizType(loai)) return 'teal-darken-2';
				if (this.isVideoType(loai)) return 'red-darken-1';
				if (this.isSlideType(loai)) return 'amber-darken-3';
				if (this.isDocType(loai)) return 'blue-darken-2';
				if (this.isInteractive(loai)) return 'purple-darken-2';
				if (this.isHtmlDoc(loai)) return 'teal-darken-2';
				return 'teal-darken-2';
			},

			// Màu sắc nút hành động
			getActivityButtonColor(node) {
				if (!node) return 'primary';
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (this.isQuizType(loai)) return 'success';
				if (this.isVideoType(loai)) return 'error';
				if (this.isSlideType(loai)) return 'warning';
				if (this.isDocType(loai)) return 'primary';
				if (this.isInteractive(loai)) return 'purple';
				if (this.isHtmlDoc(loai)) return 'primary';
				return 'primary';
			},

			// Lớp nền cho khối icon
			getActivityBgClass(node) {
				if (!node) return 'bg-teal-lighten-5';
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (this.isQuizType(loai)) return 'bg-teal-lighten-5';
				if (this.isVideoType(loai)) return 'bg-red-lighten-5';
				if (this.isSlideType(loai)) return 'bg-amber-lighten-5';
				if (this.isDocType(loai)) return 'bg-blue-lighten-5';
				if (this.isInteractive(loai)) return 'bg-purple-lighten-5';
				if (this.isHtmlDoc(loai)) return 'bg-teal-lighten-5';
				return 'bg-teal-lighten-5';
			},

			// DataJson có thể là HTML thuần, JSON hoặc object; chuẩn hóa về một mẫu để tránh hiện [object Object].
			normalizeNodeContent(rawValue) {
				if (rawValue === null || rawValue === undefined) return { html: '', text: '' };
				if (typeof rawValue === 'object') return this.extractNodeContent(rawValue);

				const rawText = String(rawValue).trim();
				if (!rawText) return { html: '', text: '' };
				try {
					return this.extractNodeContent(JSON.parse(rawText));
				} catch (error) {
					if (this.isHtmlContent(rawText)) {
						return { html: this.cleanHtml(rawText), text: this.stripHtml(rawText) };
					}
					return { html: '', text: rawText };
				}
			},

			extractNodeContent(value) {
				if (value === null || value === undefined) return { html: '', text: '' };
				if (typeof value === 'string') return this.normalizeNodeContent(value);
				if (Array.isArray(value)) {
					const text = value.map(item => this.extractNodeContent(item).text).filter(Boolean).join(' · ');
					return { html: '', text };
				}

				const htmlValue = value.htmlContent || value.contentHtml || value.bodyHtml || value.html;
				if (htmlValue) return { html: this.cleanHtml(String(htmlValue)), text: this.stripHtml(String(htmlValue)) };
				const textValue = value.textContent || value.description || value.summary || value.text;
				if (textValue && typeof textValue !== 'object') return { html: '', text: String(textValue) };
				if (value.content) return this.extractNodeContent(value.content);
				if (Array.isArray(value.parts)) return this.extractNodeContent(value.parts);
				return { html: '', text: '' };
			},

			isHtmlContent(value) {
				return /<\/?[a-z][\s\S]*>/i.test(String(value || ''));
			},

			stripHtml(value) {
				return String(value || '').replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
			},

			cleanHtml(value) {
				// Nội dung học liệu được lưu từ hệ thống; loại script/event handler trước khi render preview bằng v-html.
				return String(value || '')
					.replace(/<script[\s\S]*?<\/script>/gi, '')
					.replace(/<style[\s\S]*?<\/style>/gi, '')
					.replace(/\son\w+\s*=\s*(['"]).*?\1/gi, '')
					.replace(/(href|src)\s*=\s*(['"])\s*javascript:[\s\S]*?\2/gi, '$1="#"');
			},

			isPlayableLeafNode(node) {
				if (!node) return false;
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (['CHUONG', 'NHOM_KY_NANG', 'NHOM', 'FOLDER'].includes(loai)) {
					return false;
				}
				if (node.children && node.children.length > 0) {
					return false;
				}
				return this.hasExecutableContent(node);
			},
			handleClick(hoatDong) {
				const target = hoatDong || this.item;
				if (this.onHoatDongClick) {
					this.onHoatDongClick(target);
				}
			},

			isItemActive(hoatDong) {
				if (!hoatDong) return false;
				const activeId = typeof vueData !== 'undefined' ? vueData.activeActivityId : null;
				return activeId && String(hoatDong.NoiDungID) === String(activeId);
			},

			// Số phần con là tín hiệu trực quan để người dùng biết node còn nội dung bên trong mà chưa cần mở thử.
			getChildCount(node) {
				return node && Array.isArray(node.children) ? node.children.length : 0;
			},

			// Một phần con không cần thêm badge vì tiêu đề và cấu trúc danh sách đã đủ rõ; giữ badge khi có nhiều phần.
			shouldShowChildCount(node) {
				return this.getChildCount(node) > 1;
			},

			// Hiển thị loại nội dung thân thiện, chuẩn xác theo thuật ngữ học liệu LMS
			getContentTypeLabel(node) {
				const loai = String(node && node.LoaiNoiDung || '').toUpperCase();
				const labels = {
					HTML: 'Bài đọc lý thuyết',
					READING: 'Bài đọc lý thuyết',
					READINGWITHIMAGE: 'Bài đọc kèm hình ảnh',
					VIDEO: 'Video bài giảng',
					TAILIEU: 'Tài liệu học tập',
					TAI_LIEU: 'Tài liệu học tập',
					SLIDE: 'Bài trình chiếu',
					INTERACTIVE: 'Mô phỏng tương tác',
					QUIZ_SINGLE_CHOICE: 'Câu hỏi trắc nghiệm',
					QUIZ_MULTIPLE_CHOICE: 'Câu hỏi nhiều đáp án',
					QUIZ_ORDERING: 'Bài tập sắp xếp',
					QUIZ_MATCHING: 'Bài tập ghép đôi',
					QUIZ_DRAG_DROP_CATEGORIZE: 'Bài tập phân loại',
					QUIZ_FILL_IN_BLANK: 'Bài tập điền khuyết',
					QUIZ_CONNECTION: 'Bài tập kết nối',
					QUIZ_COMPOSITE: 'Bài kiểm tra tổng hợp'
				};
				return labels[loai] || 'Nội dung bài học';
			},

			hasChildNodesOf(node) {
				return this.getChildCount(node) > 0;
			},

			hasExecutableContent(node) {
				if (!node) return false;
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				const dataJson = node.DataJson == null ? '' : String(node.DataJson).trim();
				const hasValidData = dataJson !== '' && dataJson !== 'null' && dataJson !== '{}';
				// Bài không có DataJson là mục cấu trúc; tài liệu/bài tập vẫn được mở theo loại nội dung.
				return !!hasValidData || ['VIDEO', 'HTML', 'READING', 'READINGWITHIMAGE', 'TAILIEU', 'TAI_LIEU', 'SLIDE', 'INTERACTIVE', 'QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_ORDERING', 'QUIZ_MATCHING', 'QUIZ_DRAG_DROP_CATEGORIZE', 'QUIZ_FILL_IN_BLANK', 'QUIZ_CONNECTION', 'QUIZ_COMPOSITE'].includes(loai);
			},

			getIcon(loai) {
				switch ((loai || '').toUpperCase()) {
					case 'CHUONG': return 'mdi-folder-outline';
					case 'BAI': return 'mdi-notebook-outline';
					case 'VIDEO': return 'mdi-play-circle-outline';
					case 'HTML':
					case 'READING':
					case 'READINGWITHIMAGE': return 'mdi-book-open-page-variant-outline';
					case 'TAILIEU':
					case 'TAI_LIEU': return 'mdi-file-document-outline';
					case 'INTERACTIVE': return 'mdi-xml';
					case 'QUIZ_SINGLE_CHOICE': return 'mdi-radiobox-marked';
					case 'QUIZ_MULTIPLE_CHOICE': return 'mdi-checkbox-multiple-marked';
					case 'QUIZ_ORDERING': return 'mdi-order-numeric-ascending';
					case 'QUIZ_MATCHING': return 'mdi-connection';
					case 'QUIZ_DRAG_DROP_CATEGORIZE': return 'mdi-drag';
					case 'QUIZ_FILL_IN_BLANK': return 'mdi-form-textbox';
					case 'QUIZ_CONNECTION': return 'mdi-lan-connect';
					case 'QUIZ_COMPOSITE': return 'mdi-format-list-checks';
					case 'SLIDE': return 'mdi-presentation';
					default: return 'mdi-bookmark-outline';
				}
			}
		}
	}
</script>