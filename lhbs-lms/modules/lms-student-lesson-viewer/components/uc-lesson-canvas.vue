<template>
	<div class="lesson-canvas">
		<!-- Giao diện khi canvas rỗng -->
		<div v-if="!elements || elements.length === 0" class="text-center pa-10 text-grey empty-canvas">
			<v-icon size="64" class="mb-4">mdi-file-plus-outline</v-icon>
			<p>
				{{
				isViewer ? 'Bài giảng này chưa có nội dung.' : `Bắt đầu thêm nội dung cho bài giảng của bạn từ thư viện
				bên trái.`
				}}
			</p>
		</div>

		<div v-for="(element, index) in elements" :key="element.ElementID || index" :id="'element-' + index"
			class="element-preview"
			:class="{ 'selectable': !isViewer, 'selected': !isViewer && selectedIndex === index, 'element-completed': isViewer && elementProgress[element.ElementID]?.Status === 'COMPLETED' }"
			@click="!isViewer && $emit('update:selectedIndex', index)">

			<!-- Nút xóa (chỉ ở chế độ soạn bài) -->
			<v-btn v-if="!isViewer" icon size="x-small" variant="text" @click.stop="removeElement(index)"
				class="delete-btn">
				<v-icon>mdi-delete-outline</v-icon>
			</v-btn>

			<!-- Tiêu đề nâng cấp -->
			<div v-if="element.ElementData.title" class="element-title"
				:style="{ color: isViewer ? getVisualsForType(element.ElementType).color : 'inherit' }">
				<v-icon v-if="isViewer" :icon="getVisualsForType(element.ElementType).icon" class="mr-3" size="22">
				</v-icon>
				<span>{{ element.ElementData.title }}</span>
				<v-chip v-if="isViewer && elementProgress[element.ElementID]?.Status === 'COMPLETED'" size="x-small" color="success" variant="tonal" class="ml-2">Hoàn thành</v-chip>
			</div>

			<div v-if="isElementLocked(index)" class="element-content pa-6 text-center text-medium-emphasis rounded border bg-grey-lighten-5">
				<v-icon size="28" class="mb-2">mdi-lock-outline</v-icon>
				<div>Hoàn thành khối bắt buộc phía trên để mở nội dung này.</div>
			</div>
			<div v-else class="element-content" :class="{ 'with-title': !!element.ElementData.title }">
				<!-- URL được đổi thành liên kết chữ; click sẽ mở GlobalIframeWindow của hệ thống. -->
				<div v-if="element.ElementType === 'TEXT'" v-html="getTextContent(element.ElementData.content)"
					class="text-content" @click="handleTextContentClick">
				</div>

				<div v-else-if="element.ElementType === 'IMAGE'" class="d-flex ga-2 flex-wrap">
					<template v-if="getImageFiles(element).length">
						<div v-for="(file, fileIndex) in getImageFiles(element)"
							:key="(file.source || file.url || file.fileId || fileIndex) + fileIndex"
							class="lesson-image-thumb" style="width: 100%;" role="button" tabindex="0"
							:aria-label="'Xem ảnh lớn ' + (file.name || file.fileName || '')"
							@click.stop="openImagePreview(file, element)"
							@keydown.enter.prevent="openImagePreview(file, element)"
							@keydown.space.prevent="openImagePreview(file, element)">
							<v-img v-if="getImageSource(file)" :src="getImageSource(file)"
								:alt="file.name || file.fileName || 'Hình ảnh'" max-height="720" contain>
								<template v-slot:placeholder>
									<div class="d-flex align-center justify-center fill-height">
										<v-progress-circular color="grey-lighten-4" indeterminate />
									</div>
								</template>
								<template v-slot:error>
									<div class="d-flex flex-column align-center justify-center fill-height text-grey">
										<v-icon>mdi-image-broken-variant</v-icon>
										<span class="text-caption">Không tải được hình ảnh</span>
									</div>
								</template>
							</v-img>
							<div v-if="getImageSource(file)" class="lesson-image-preview-hint d-flex align-center ga-1">
								<v-icon size="18">mdi-magnify-plus-outline</v-icon>
								<span>Xem ảnh</span>
							</div>
							<p class="text-caption text-center text-medium-emphasis mt-1">
								{{ file.caption || file.Caption || '' }}
							</p>
						</div>
					</template>
					<div v-else class="d-flex flex-column align-center justify-center text-grey pa-6 w-100">
						<v-icon size="32">mdi-image-off-outline</v-icon>
						<span class="text-caption mt-2">Không tìm thấy nguồn hình ảnh</span>
					</div>
				</div>

				<div v-else-if="element.ElementType === 'YOUTUBE'">
					<uc-media-player v-if="getYoutubeEmbedUrl(element.ElementData.source)" :url="element.ElementData.source"
						:title="element.ElementData.title" :interactions="element.ElementData.interactions || []" />
					<div v-else class="text-center text-grey pa-4 border rounded">URL video không hợp lệ.</div>
				</div>

				<div v-else-if="element.ElementType === 'FILE'" class="d-flex ga-2 flex-wrap">
					<v-chip class="chip-style" v-for="(file, fileIndex) in element.ElementData.sources"
						:key="file.source + fileIndex" @click="window.open(file.source, '_blank')" label
						prepend-icon="mdi-download" color="primary">{{ file.name }}
					</v-chip>
				</div>

				<div v-else-if="element.ElementType === 'AUDIO'">
					<uc-wave-audio-player :audio-url="element.ElementData.source" />
				</div>
				<div v-else-if="element.ElementType === 'HTML'" style="width: 100%">
					<iframe v-if="element.ElementData?.IsHTML" :srcdoc="element.ElementData.source"
						sandbox="allow-scripts allow-popups allow-forms allow-same-origin"
						style="width: 100%;height: 600px;">
					</iframe>
					<iframe v-else :src="element.ElementData.source" style="width: 100%;height: 600px;">
					</iframe>
				</div>
				<!-- <div v-else-if="element.ElementType?.includes('QUIZ')">
					<div v-html="element.ElementData?.config?.questionText" />
					<component :is="getQuestionComponent(element.ElementType)" :question="element.ElementData"
						:answer="getAnswerForChild(element)" :isGrade="false" :readonly="false" />
				</div> -->

				<div v-else class="text-center pa-4 text-grey">
					<v-icon size="32">{{ getVisualsForType(element.ElementType).icon }}</v-icon>
					<p class="mt-2">{{ getVisualsForType(element.ElementType).label }}</p>
				</div>
			</div>
		</div>

		<!-- Mở ảnh ở kích thước lớn để học sinh xem rõ hơn, đặc biệt trên màn hình mobile. -->
		<v-dialog v-model="imagePreviewDialog" max-width="1100" scrollable>
			<v-card class="lesson-image-dialog">
				<v-card-title class="d-flex align-center ga-2">
					<span class="text-truncate">{{ imagePreview.title }}</span>
					<v-spacer />
					<v-btn icon="mdi-close" variant="text" aria-label="Đóng xem ảnh"
						@click="imagePreviewDialog = false" />
				</v-card-title>
				<v-card-text class="pa-2">
					<v-img :src="imagePreview.src" :alt="imagePreview.title" max-height="78vh" contain>
						<template v-slot:error>
							<div class="d-flex flex-column align-center justify-center fill-height text-grey">
								<v-icon>mdi-image-broken-variant</v-icon>
								<span>Không tải được hình ảnh</span>
							</div>
						</template>
					</v-img>
					<div v-if="imagePreview.caption" class="text-caption text-center mt-2">
						{{ imagePreview.caption }}
					</div>
				</v-card-text>
			</v-card>
		</v-dialog>

	</div>
</template>

<script>
	export default {
		name: 'uc-lesson-canvas',
		props: {
			elements: Array,
			selectedIndex: Number,
			isViewer: { type: Boolean, default: false },
			elementProgress: { type: Object, default: () => ({}) },
			isSequential: { type: Boolean, default: false },
			firstIncompleteRequiredIndex: { type: Number, default: -1 }
		},
		emits: ['update:elements', 'update:selectedIndex'],
		inject: ['iframeRef'],
		data() {
			return {
				window,
				imagePreviewDialog: false,
				imagePreview: { src: '', title: 'Hình ảnh', caption: '' },
				elementTypes: [
					{ type: 'TEXT', label: 'Đoạn văn bản', icon: 'mdi-text-long', color: '#3B82F6' },
					{ type: 'IMAGE', label: 'Hình ảnh', icon: 'mdi-image-multiple-outline', color: '#8B5CF6' },
					{ type: 'YOUTUBE', label: 'Video', icon: 'mdi-youtube', color: '#EF4444' },
					{ type: 'FILE', label: 'Tệp đính kèm', icon: 'mdi-paperclip', color: '#F97316' },
					{ type: 'AUDIO', label: 'Audio', icon: 'mdi-volume-high', color: '#10B981' },
					{ type: 'QUIZ_SINGLE_CHOICE', label: 'Trắc nghiệm (1 đáp án)', icon: 'mdi-help-circle-outline', color: '#0EA5E9' },
					{ type: 'QUIZ_MULTIPLE_CHOICE', label: 'Trắc nghiệm (Nhiều đáp án)', icon: 'mdi-help-circle-outline', color: '#0EA5E9' },
					{ type: 'QUIZ_TRUE_FALSE', label: 'Đúng / Sai', icon: 'mdi-help-circle-outline', color: '#0EA5E9' },
					{ type: 'QUIZ_FILL_IN_BLANK', label: 'Điền vào chỗ trống', icon: 'mdi-help-circle-outline', color: '#0EA5E9' },
					{ type: 'QUIZ_MATCHING', label: 'Ghép nối', icon: 'mdi-help-circle-outline', color: '#0EA5E9' },
				]
			}
		},
		mounted() {
			console.log('this.elements', this.elements)
		},
	
		methods: {
			// Khi chọn học tuần tự, chỉ ẩn nội dung sau element bắt buộc đầu tiên chưa hoàn thành.
			isElementLocked(index) {
				return this.isViewer && this.isSequential
					&& this.firstIncompleteRequiredIndex >= 0
					&& index > this.firstIncompleteRequiredIndex;
			},
			// Google Drive không render ổn định khi mở URL /drive/folders/... trong iframe.
			// YouTube cũng không cho nhúng trang /watch vào iframe, nên phải đổi sang
			// endpoint /embed trước khi chuyển URL cho GlobalIframeWindow.
			normalizeIframeUrl(url) {
				if (!url) return url;
				try {
					const parsedUrl = new URL(url, window.location.href);
					const hostname = parsedUrl.hostname.toLowerCase();
					let youtubeVideoId = '';

					// Chuẩn hóa các dạng link YouTube thường xuất hiện trong nội dung bài học.
					// Chỉ dùng video ID hợp lệ để tránh biến link YouTube khác thành URL embed sai.
					if (hostname === 'youtu.be') {
						youtubeVideoId = parsedUrl.pathname.split('/').filter(Boolean)[0] || '';
					} else if (hostname === 'youtube.com' || hostname === 'www.youtube.com') {
						if (parsedUrl.pathname === '/watch') {
							youtubeVideoId = parsedUrl.searchParams.get('v') || '';
						} else {
							const pathMatch = parsedUrl.pathname.match(/^\/(?:embed|shorts)\/([^/]+)/i);
							youtubeVideoId = pathMatch?.[1] || '';
						}
					}

					if (/^[a-zA-Z0-9_-]{11}$/.test(youtubeVideoId)) {
						return `https://www.youtube.com/embed/${youtubeVideoId}?rel=0&modestbranding=1`;
					}

					const folderMatch = parsedUrl.hostname === 'drive.google.com'
						? parsedUrl.pathname.match(/\/folders\/([^/]+)/i)
						: null;
					if (!folderMatch) return url;

					const folderId = decodeURIComponent(folderMatch[1]);
					return `https://drive.google.com/embeddedfolderview?id=${encodeURIComponent(folderId)}#list`;
				} catch (error) {
					return url;
				}
			},

			// Nội dung TEXT được render bằng v-html nên không gắn trực tiếp @click
			// cho từng anchor; bắt sự kiện ở container rồi mở cửa sổ iframe dùng chung.
			handleTextContentClick(event) {
				if (!this.isViewer) return;
				const anchor = event.target.closest('a');
				if (!anchor) return;

				const href = anchor.dataset.lessonLink || anchor.href;
				if (!/^https?:\/\//i.test(href)) return;

				event.preventDefault();
				event.stopPropagation();
			const payload = {
				title: (anchor.textContent || 'Nội dung liên kết').trim(),
				url: href,
				icon: 'mdi-link-variant'
			};

			// Wordwall chặn /resource bằng X-Frame-Options. Resolve qua oEmbed trước
			// khi mở iframeRef; URL gốc trong nội dung bài học không bị thay đổi.
			const wordwallResourceUrl = this.getWordwallResourceUrl(href);
			if (wordwallResourceUrl) {
				const self = this;
				this.resolveWordwallEmbedUrl(wordwallResourceUrl, function(embedUrl) {
					if (embedUrl) {
						payload.url = embedUrl;
						self.openLessonLink(payload);
						return;
					}
					// Không đưa lại /resource vào iframe vì sẽ lặp lỗi refused to connect.
					self.openLessonLink(payload, true);
				});
				return;
			}

			payload.url = this.normalizeIframeUrl(href);
			this.openLessonLink(payload);
		},

		openLessonLink(payload, externalOnly) {
			// Fallback Wordwall mở tab ngoài; các link khác vẫn dùng cửa sổ nội dung FUI.
			if (externalOnly) {
				window.open(payload.url, '_blank', 'noopener,noreferrer');
				return;
			}
			if (this.iframeRef?.value?.openWindow) {
				this.iframeRef.value.openWindow(payload);
				return;
			}

			// Component có thể được render độc lập ngoài Global.vue; giữ fallback để link không bị chết.
			if (window?.parent && window.parent !== window) {
				window.parent.postMessage({ type: 'iframeRef_openWindow', ...payload }, '*');
				return;
			}
			window.open(payload.url, '_blank', 'noopener,noreferrer');
		},

		getWordwallResourceUrl(url) {
			try {
				const parsedUrl = new URL(url, window.location.href);
				const isWordwall = ['wordwall.net', 'www.wordwall.net'].includes(parsedUrl.hostname.toLowerCase());
				const isResource = /^\/(?:[a-z]{2}\/)?resource\/\d+(?:\/|$)/i.test(parsedUrl.pathname);
				return isWordwall && isResource ? parsedUrl.toString() : '';
			} catch (error) {
				return '';
			}
		},

		resolveWordwallEmbedUrl(resourceUrl, callback) {
			const endpoint = 'https://wordwall.net/api/oembed?url=' + encodeURIComponent(resourceUrl) + '&format=json';
			const request = new XMLHttpRequest();
			request.timeout = 5000;
			request.open('GET', endpoint, true);
			request.onreadystatechange = function() {
				if (request.readyState !== 4) return;
				if (request.status < 200 || request.status >= 300) {
					callback('');
					return;
				}
				try {
					const data = JSON.parse(request.responseText || '{}');
					const parser = typeof DOMParser !== 'undefined' ? new DOMParser() : null;
					const documentNode = parser?.parseFromString(data.html || '', 'text/html');
					const embedUrl = documentNode?.querySelector('iframe')?.getAttribute('src') || '';
					callback(embedUrl ? new URL(embedUrl, 'https://wordwall.net').toString() : '');
				} catch (error) {
					callback('');
				}
			};
			request.onerror = function() { callback(''); };
			request.ontimeout = function() { callback(''); };
			request.send();
		},

			// Chỉ tự động tạo liên kết ở chế độ học sinh; giáo viên cần nhìn thấy đúng nội dung đang soạn.
			getTextContent(content) {
				if (!this.isViewer || typeof content !== 'string' || !content) return content || '';
				return this.linkifyViewerContent(content);
			},

			// Duyệt các nút văn bản thay vì replace trực tiếp toàn bộ HTML để không làm hỏng
			// thẻ <a> có sẵn hoặc biến URL trong thuộc tính HTML thành một liên kết lồng nhau.
			linkifyViewerContent(content) {
				if (typeof DOMParser === 'undefined') return content;

				const parser = new DOMParser();
				const documentFragment = parser.parseFromString(`<div>${content}</div>`, 'text/html');
				const root = documentFragment.body.firstElementChild;
				if (!root) return content;

				const urlPattern = /(?:https?:\/\/|www\.)[^\s<]+/gi;
				const ignoredTags = new Set(['A', 'BUTTON', 'CODE', 'PRE', 'SCRIPT', 'STYLE']);

				const linkifyTextNode = (node) => {
					const text = node.nodeValue || '';
					urlPattern.lastIndex = 0;
					let match;
					let lastIndex = 0;
					let hasUrl = false;
					const fragment = documentFragment.createDocumentFragment();

					while ((match = urlPattern.exec(text)) !== null) {
						const matchedUrl = match[0];
						let linkText = matchedUrl;
						let trailingText = '';

						// Dấu câu kết thúc câu không nên trở thành một phần của URL.
						const punctuation = linkText.match(/[.,;:!?…]+$/u);
						if (punctuation) {
							trailingText = punctuation[0];
							linkText = linkText.slice(0, -trailingText.length);
						}
						const openingParentheses = (linkText.match(/\(/g) || []).length;
						const closingParentheses = (linkText.match(/\)/g) || []).length;
						if (linkText.endsWith(')') && closingParentheses > openingParentheses) {
							trailingText = `)${trailingText}`;
							linkText = linkText.slice(0, -1);
						}

						if (match.index > lastIndex) {
							fragment.appendChild(documentFragment.createTextNode(text.slice(lastIndex, match.index)));
						}

						const anchor = documentFragment.createElement('a');
						const href = linkText.toLowerCase().startsWith('www.') ? `https://${linkText}` : linkText;
						anchor.href = href;
						anchor.target = '_blank';
						anchor.rel = 'noopener noreferrer';
						anchor.className = 'lesson-inline-link';
						anchor.setAttribute('data-lesson-link', href);
						anchor.setAttribute('aria-label', 'Mở liên kết trong cửa sổ nội dung');
						anchor.textContent = linkText;
						fragment.appendChild(anchor);

						if (trailingText) fragment.appendChild(documentFragment.createTextNode(trailingText));
						lastIndex = match.index + matchedUrl.length;
						hasUrl = true;
					}

					if (!hasUrl) return;
					if (lastIndex < text.length) {
						fragment.appendChild(documentFragment.createTextNode(text.slice(lastIndex)));
					}
					node.parentNode.replaceChild(fragment, node);
				};

				const walk = (node) => {
					if (node.nodeType === 3) {
						linkifyTextNode(node);
						return;
					}
					if (node.nodeType !== 1) return;
					if (node.tagName === 'A') {
						// Chuẩn hóa cả thẻ <a> do giáo viên tạo sẵn để không mở trong cùng trang.
						if (/^https?:\/\//i.test(node.href || node.getAttribute('href') || '')) {
							node.target = '_blank';
							node.rel = 'noopener noreferrer';
						}
						return;
					}
					if (ignoredTags.has(node.tagName)) return;
					Array.from(node.childNodes).forEach(walk);
				};

				walk(root);
				return root.innerHTML;
			},

			removeElement(index) {
				if (this.isViewer) return;
				const element = this.elements[index];
	
				if (element && element.ElementID) {
					ajaxCALL('lms/EL_Element_Delete', { ElementID: element.ElementID }, res => {
						CALL('getLessonData');
						if (this.selectedIndex === index) {
							this.$emit('update:selectedIndex', null);
						}
					});
				} else {
					const newElements = [...this.elements];
					newElements.splice(index, 1);
					this.$emit('update:elements', newElements);
					if (this.selectedIndex === index) {
						this.$emit('update:selectedIndex', null);
					}
				}
			},
			getYoutubeEmbedUrl(url) {
				if (!url || typeof url !== 'string') return null;
				let videoId = null;
				const patterns = [
					/(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/,
					/(?:https?:\/\/)?youtu\.be\/([a-zA-Z0-9_-]{11})/,
					/(?:https?:\/\/)?(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/
				];
				for (const pattern of patterns) {
					const match = url.match(pattern);
					if (match && match[1]) {
						videoId = match[1];
						break;
					}
				}
				return videoId ? `https://www.youtube.com/embed/${videoId}` : null;
			},
			getDriveFileId(url) {
				if (!url) return null;
				const value = String(url);
				const pathMatch = value.match(/\/d\/([^/?#]+)/i);
				if (pathMatch?.[1]) return pathMatch[1];
				try {
					return new URL(value).searchParams.get('id');
				} catch (error) {
					return null;
				}
			},
			// Dữ liệu cũ có thể dùng `source` đơn, còn dữ liệu mới dùng `sources`; chuẩn hóa cả hai
			// để bài học học sinh không bị khung trắng khi API trả về format khác phiên bản.
			getImageFiles(element) {
				let data = element?.ElementData || {};
				for (let attempt = 0; attempt < 2 && typeof data === 'string'; attempt++) {
					try {
						data = JSON.parse(data);
					} catch (error) {
						break;
					}
				}
				if (!data || typeof data !== 'object') return [];

				let files = data.sources ?? data.Sources ?? data.fileSources ?? data.FileSources;
				const singleSource = data.source ?? data.Source ?? data.url ?? data.URL ?? data.fileUrl ?? data.FileURL
					?? data.FILE_URL ?? data.fileURL;
				const hasSingleSource = singleSource != null || data.resourceFileId || data.resourceFileID || data.fileId
					|| data.FileID || data.FILE_ID;
				// Một số bản ghi ảnh đơn đã có `sources: []` nhưng vẫn giữ FileID ở ElementData;
				// coi ElementData như một source để không làm mất ảnh khi học sinh xem bài.
				if (files == null || (Array.isArray(files) && files.length === 0 && hasSingleSource)) {
					files = hasSingleSource ? [data] : files;
				}
				if (typeof files === 'string') {
					try {
						files = JSON.parse(files);
					} catch (error) {
						files = [{ source: files }];
					}
				}
				if (Array.isArray(files)) {
					if (files.length === 0 && hasSingleSource) return [data];
					return files.filter(Boolean);
				}
				if (files && typeof files === 'object') {
					const hasSource = files.source || files.Source || files.url || files.URL || files.fileUrl || files.FileURL
						|| files.FILE_URL || files.fileURL || files.resourceFileId || files.resourceFileID || files.fileId
						|| files.FileID || files.FILE_ID;
					return hasSource ? [files] : Object.values(files).filter(Boolean);
				}
				return [];
			},
			// Nguồn ảnh có thể là LMS FileData, URL ngoài hoặc Google Drive; chỉ Drive mới cần thumbnail API.
			getImageSource(file) {
				const sourceValue = [
					file?.source, file?.Source, file?.url, file?.URL, file?.externalSource,
					file?.fileUrl, file?.FileURL, file?.FILE_URL, file?.fileURL, file?.FileDataURL,
				].find(value => value !== null && value !== undefined && String(value).trim());
				const fileId = file?.resourceFileId || file?.resourceFileID || file?.fileId || file?.FileID || file?.FILE_ID
					|| file?.FileId;
				const configuredBase = vueData?.v_Set?.urlReadFile || vueData?.v_Set?.urlReturnFile || 'https://file.lhbs.vn/lms';
				const base = String(configuredBase).replace(/\/+$/, '').replace(/\/FileData$/i, '');
				let source = String(sourceValue || '').trim();
				if (!source && fileId) source = `${base}/FileData/${encodeURIComponent(fileId)}`;
				if (!source) return '';
				if (/drive\.google\.com/i.test(source)) {
					const driveId = file?.externalId || file?.id || file?.fileId || this.getDriveFileId(source);
					return driveId ? `https://drive.google.com/thumbnail?id=${driveId}&sz=w1000` : source;
				}
				// Một số bản ghi cũ lưu đường dẫn viewer/download hoặc domain đọc file cũ;
				// ảnh phải trỏ về endpoint FileData trực tiếp để trình duyệt học sinh tải được.
				source = source
					.replace(/^https?:\/\/lms\.lhbs\.vn\/(?:viewer\/|download\/)?FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
					.replace(/^(https?:\/\/file\.lhbs\.vn\/lms)\/(?:viewer|download|upload)\/FileData\//i, '$1/FileData/')
					.replace(/^\/?(?:viewer|download)\/FileData\//i, 'FileData/');
				if (/^https?:\/\//i.test(source) || /^(?:data|blob):/i.test(source)) return source;
				return `${base}/${source.replace(/^\/+/, '')}`;
			},
			openImagePreview(file, element) {
				const source = this.getImageSource(file);
				if (!source) return;
				this.imagePreview = {
					src: source,
					title: file?.name || element?.ElementData?.title || 'Hình ảnh',
					caption: file?.caption || '',
				};
				this.imagePreviewDialog = true;
			},
			getQuestionComponent(type) {
				const map = {
					'QUIZ_SINGLE_CHOICE': 'uc-question-single-choice',
					'QUIZ_MULTIPLE_CHOICE': 'uc-question-multiple-choice',
					'QUIZ_TRUE_FALSE': 'uc-question-true-false',
					'QUIZ_FILL_IN_BLANK': 'uc-question-fill-in-blank',
					'QUIZ_MATCHING': 'uc-question-matching',
				};
				return map[type] || 'div';
			},
	
			// =================================================================
			// == SỬA LỖI LOGIC TẠI ĐÂY                                      ==
			// =================================================================
			getAnswerForChild(element) {
				const config = element.ElementData?.config;
				if (!config) return null;
	
				// --- Ở chế độ Học bài của Học sinh (isViewer = true) ---
				// Trả về kiểu dữ liệu đúng nhưng rỗng để component con không bị lỗi
				if (this.isViewer) {
					switch (element.ElementType) {
						case 'QUIZ_MULTIPLE_CHOICE': return []; // Trả về mảng rỗng
						case 'QUIZ_MATCHING': return []; // Trả về mảng rỗng
						case 'QUIZ_FILL_IN_BLANK': return {}; // Trả về object rỗng
						default: return null; // Các trường hợp khác (single-choice, true-false) có thể nhận null
					}
				}
	
				// --- Ở chế độ Soạn bài của Giáo viên (isViewer = false) ---
				// Giữ nguyên logic cũ để giáo viên thấy đáp án đúng
				let answerObject = null;
				switch (element.ElementType) {
					case 'QUIZ_SINGLE_CHOICE': answerObject = config.correctAnswer; break;
					case 'QUIZ_MULTIPLE_CHOICE': answerObject = config.correctAnswers; break;
					case 'QUIZ_TRUE_FALSE': answerObject = config.correctAnswer; break;
					case 'QUIZ_FILL_IN_BLANK': {
						const blanks = config.parts?.filter(item => item.type === 'blank');
						const obj = {};
						if (blanks) {
							for (var item of blanks) {
								obj[item.id] = item.acceptedAnswers?.[0];
							}
						}
						answerObject = obj;
						break;
					}
					case 'QUIZ_MATCHING': answerObject = config.correctPairs; break;
				}
				return answerObject;
			},
	
			getVisualsForType(elementType) {
				const defaults = { label: 'Thành phần không xác định', icon: 'mdi-file-question-outline', color: '#4B5563' };
				if (!elementType) return defaults;
				const found = this.elementTypes.find(t => t.type === elementType);
				return found || defaults;
			},
		}
	}
</script>

<style scoped>
/* Hover gợi ý trên desktop, còn mobile luôn hiện để người học biết ảnh có thể bấm xem lớn. */
		.lesson-canvas .lesson-image-thumb {
			position: relative;
			cursor: zoom-in;
		}

		.lesson-canvas .lesson-image-preview-hint {
			position: absolute;
			right: 8px;
			bottom: 8px;
			z-index: 2;
			padding: 4px 8px;
			border-radius: 6px;
			background: rgba(0, 0, 0, 0.62);
			color: #fff;
			font-size: 12px;
			opacity: 0;
			pointer-events: none;
			transition: opacity 0.15s ease;
		}

		.lesson-canvas .lesson-image-thumb:hover .lesson-image-preview-hint,
		.lesson-canvas .lesson-image-thumb:focus-visible .lesson-image-preview-hint {
			opacity: 1;
		}

		.lesson-canvas .lesson-image-dialog {
			width: min(1100px, 95vw);
		}

		@media (hover: none) {
			.lesson-canvas .lesson-image-preview-hint {
				opacity: 1;
			}
		}
</style>