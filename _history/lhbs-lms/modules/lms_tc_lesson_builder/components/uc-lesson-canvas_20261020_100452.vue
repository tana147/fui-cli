<template>
	<div class="lesson-canvas">
		<div v-if="!elements || elements.length === 0" class="text-center pa-10 text-grey empty-canvas">
			<v-icon size="64" class="mb-4">mdi-file-plus-outline</v-icon>
			<p>{{ $t('message.StartAddingContent') }}</p>
		</div>

		<div v-for="(element, index) in elements" :key="getElementKey(element, index)" class="element-preview"
			:class="{ 'selected': selectedIndex === index }" @click="$emit('update:selectedIndex', index)">
			<div class="d-flex ga-2 element-title">
				<p v-if="element.ElementData.title" class="mb-0" style="word-break: break-word;">
					{{ element.ElementData.title }}
				</p>
				<v-chip v-if="element.ElementData.sourceTracking?.sourceType === 'HOC_LIEU_SO'"
					size="x-small" color="primary" variant="tonal" class="mt-1 flex-shrink-0"
					:v-tooltip="'Học liệu #' + element.ElementData.sourceTracking.HocLieuID + ' · Nội dung #' + element.ElementData.sourceTracking.NoiDungID">
					<v-icon start size="14">mdi-database-import-outline</v-icon>Học liệu số
				</v-chip>
					<v-spacer />
					<v-btn size="x-small" variant="text" :loading="isRemovingElement(element)"
						:disabled="isRemovingElement(element)" @click.stop="removeElementAt(index)" class="delete-btn"
						icon="mdi-delete-outline" />
			</div>

				<div class="element-content" :class="{'with-title': element.ElementData.title}">
					<div v-if="element.ElementType === 'TEXT'">
						<!-- Link trong nội dung soạn bài được mở qua iframeRef để giáo viên không rời màn hình biên tập. -->
						<div v-if="element.ElementData.content" v-html="getTextContent(element.ElementData.content)"
							class="text-content" @click="handleTextContentClick" style="word-break: auto-phrase;" />
					<div v-else class="empty-element-state">
						<v-icon>mdi-text-box-remove-outline</v-icon>
						<span>Chưa có nội dung văn bản</span>
					</div>
				</div>

					<div v-else-if="element.ElementType === 'IMAGE'">
						<div v-if="element.ElementData.sources?.length" class="d-flex ga-2">
						<div v-for="(file, fileIndex) in element.ElementData.sources" :key="file.id || fileIndex"
							class="lesson-image-thumb" style="width: 200px" role="button" tabindex="0"
							:aria-label="'Xem ảnh lớn ' + (file.name || '')"
							@click.stop="openImagePreview(file, element)"
							@keydown.enter.prevent="openImagePreview(file, element)"
							@keydown.space.prevent="openImagePreview(file, element)">
							<v-img v-if="getImageSource(file)" :src="getImageSource(file)" :lazy-src="getImageSource(file)"
								:alt="file.name || element.ElementData.title || 'Hình ảnh'" height="180" contain>
							<template v-slot:placeholder>
								<div class="d-flex align-center justify-center fill-height">
									<v-progress-circular color="grey-lighten-4" indeterminate></v-progress-circular>
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
							<div v-else class="empty-element-state">
							<v-icon>mdi-image-off-outline</v-icon>
							<span>Chưa có đường dẫn hình ảnh</span>
						</div>
						<p class="text-caption text-center text-medium-emphasis">{{ file.caption }}</p>
					</div>
					</div>
					<div v-else class="empty-element-state">
						<v-icon>mdi-image-off-outline</v-icon>
						<span>Chưa có hình ảnh</span>
					</div>
				</div>

				<div v-else-if="element.ElementType === 'YOUTUBE'">
					<div v-if="element.ElementData.source.length > 0">
						<!-- 1. Video ở trên -->
						<iframe width="100%" height="420"
							:src="renderUrlYoutube(element.ElementData.source)" title="YouTube video player" frameborder="0"
							allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
							allowfullscreen class="rounded border"></iframe>

						<!-- 2. Danh sách câu hỏi tương tác ở dưới -->
						<div v-if="element.ElementData.interactive || element.ElementData.interactions?.length" class="mt-3">
							<div class="d-flex align-center justify-space-between mb-2">
								<div class="d-flex align-center ga-2">
									<v-chip size="small" color="deep-purple" variant="flat">
										<v-icon start size="14">mdi-timeline-text-outline</v-icon>Video tương tác
									</v-chip>
									<span class="text-subtitle-2 font-weight-bold text-deep-purple">
										Danh sách câu hỏi tương tác ({{ (element.ElementData.interactions || []).length }})
									</span>
								</div>
							</div>

							<div class="d-flex flex-column ga-3">
								<v-card v-for="(item, idx) in (element.ElementData.interactions || [])" :key="idx"
									variant="outlined" class="pa-3 border-purple-lighten-2 bg-purple-lighten-5">
									<div class="d-flex align-center justify-space-between mb-2">
										<div class="d-flex align-center ga-2">
											<v-chip size="small" color="deep-purple" variant="flat" class="font-weight-bold">
												<v-icon start size="14">mdi-clock-outline</v-icon>
												{{ formatInteractionTime(item.time) }}
											</v-chip>
											<v-chip size="small" :color="getInteractionTypeBadge(item).color" variant="tonal">
												{{ getInteractionTypeBadge(item).label }}
											</v-chip>
											<span class="font-weight-bold text-body-2 text-grey-darken-3">Câu {{ idx + 1 }}</span>
										</div>
									</div>

									<!-- Nội dung câu hỏi dùng uc-latex-view -->
									<div class="text-body-1 font-weight-medium text-grey-darken-4 mb-3">
										<uc-latex-view :content="getInteractionPromptRaw(item)" />
									</div>

									<!-- Danh sách đáp án cho câu trắc nghiệm -->
									<div v-if="getCorrectInteractionOptions(item).length" class="d-grid ga-2" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));">
										<div v-for="(opt, optIdx) in getCorrectInteractionOptions(item)" :key="opt.id || optIdx"
											class="pa-2 rounded d-flex align-center ga-2 text-body-2"
											:class="isCorrectOption(item, opt) ? 'bg-green-lighten-4 border border-success font-weight-bold text-success' : 'bg-white border text-grey-darken-3'">
											<v-icon size="16" :color="isCorrectOption(item, opt) ? 'success' : 'grey'">
												{{ isCorrectOption(item, opt) ? 'mdi-check-circle' : 'mdi-circle-outline' }}
											</v-icon>
											<div class="flex-grow-1">
												<uc-latex-view :content="opt.text || opt" />
											</div>
											<v-chip v-if="isCorrectOption(item, opt)" size="x-small" color="success" variant="flat">
												Đáp án đúng
											</v-chip>
										</div>
									</div>

									<!-- Đáp án dạng Đúng/Sai, Điền từ, Nối cặp... -->
									<div v-else-if="getInteractionDetailsText(item)" class="text-body-2 text-grey-darken-3 bg-white pa-2 rounded border">
										<span class="font-weight-bold text-success mr-1">Đáp án:</span>
										<uc-latex-view :content="getInteractionDetailsText(item)" style="display: inline-block;" />
									</div>
								</v-card>
							</div>
						</div>
					</div>
					<div v-else class="empty-element-state">
						<v-icon>mdi-youtube-off</v-icon>
						<span>Chưa có video</span>
					</div>
				</div>
				<div v-else-if="element.ElementType === 'FILE'">
					<div v-if="element.ElementData.sources?.length" class="file-source-grid">
					<div v-for="(file, fileIndex) in element.ElementData.sources" :key="file.id || fileIndex"
						class="file-source-card">
						<!-- FileData trả binary/attachment nên iframe trực tiếp thường bị trắng với DOCX/XLSX/PPTX.
							Dùng viewer URL đã chuẩn hóa; URL gốc vẫn được giữ cho thao tác mở/tải file. -->
						<iframe v-if="getFilePreviewSource(file)" class="file-source-iframe" :src="getFilePreviewSource(file)"
							:title="file.name || 'Tệp đính kèm'" loading="lazy" allowfullscreen />
						<div v-else class="file-source-fallback">
							<v-icon size="36" color="primary">mdi-file-outline</v-icon>
							<div class="file-source-name" :title="file.name">{{ file.name }}</div>
						</div>
					</div>
					</div>
					<div v-else class="empty-element-state">
						<v-icon>mdi-file-alert-outline</v-icon>
						<span>Chưa có tệp đính kèm</span>
					</div>
				</div>

				<div v-else-if="element.ElementType === 'AUDIO'">
					<uc-wave-audio-player v-if="element.ElementData.source" :audio-url="element.ElementData.source" />
					<div v-else class="empty-element-state">
						<v-icon>mdi-volume-off</v-icon>
						<span>Chưa có âm thanh</span>
					</div>
				</div>
				<div v-else-if="element.ElementType === 'HTML'" style="width: 100%">
					<!-- <div v-html="element.ElementData.source" /> -->
					<template v-if="element.ElementData.source">
					<iframe v-if="element.ElementData?.IsHTML" :srcdoc="element.ElementData.source"
						sandbox="allow-scripts allow-popups allow-forms allow-same-origin" style="width: 100%;height: 600px;">
					</iframe>

					<iframe v-else :src="element.ElementData.source"
						sandbox="allow-scripts allow-popups allow-forms allow-same-origin" style="width: 100%;height: 600px;">
					</iframe>
					</template>
					<div v-else class="empty-element-state">
						<v-icon>mdi-language-html5</v-icon>
						<span>Chưa có nội dung HTML</span>
					</div>
				</div>
				<div v-else-if="element.ElementType?.includes('QUIZ')">
					<template v-if="element.ElementData.config?.questionText">
						<uc-latex-view :content="element.ElementData.config.questionText" />
						<component :is="getQuestionComponent(element.ElementType)" :question="element.ElementData"
							:answer="getAnswerForChild(element)" :isGrade="false" :readonly="true" />
					</template>
					<div v-else class="empty-element-state">
						<v-icon>mdi-help-box-outline</v-icon>
						<span>Chưa có nội dung câu hỏi</span>
					</div>
				</div>

				<div v-else class="text-center pa-4 text-grey">
					<v-icon size="32">{{ getIconForType(element.ElementType) }}</v-icon>
					<p class="mt-2">{{ getLabelForType(element.ElementType) }}</p>
				</div>
			</div>

			</div>

		<!-- Preview ảnh dùng chung cho giáo viên; đặt ngoài v-for để mỗi canvas chỉ có một dialog. -->
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
		props: ['elements', 'selectedIndex'],
		emits: ['update:elements', 'update:selectedIndex'],
		inject: ['iframeRef'],
		data() {
			this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
				return {
					window,
					removingElementIds: {},
					imagePreviewDialog: false,
					imagePreview: { src: '', title: 'Hình ảnh', caption: '' },
				elementTypes: [
					{ value: 'TEXT', label: this.$t('message.TextBlock'), icon: 'mdi-format-text' },
					{ value: 'IMAGE', label: this.$t('message.Image'), icon: 'mdi-image-outline' },
					{ value: 'YOUTUBE', label: 'Video', icon: 'mdi-youtube' },
					{ value: 'FILE', label: this.$t('message.Attachment'), icon: 'mdi-paperclip' },
					{ value: 'AUDIO', label: 'Audio', icon: 'mdi-volume-high' },
					{ value: 'HTML', label: 'HTML', icon: 'mdi-language-html5' },
					// { value: 'QUIZ', label: 'Câu hỏi nhanh', icon: 'mdi-frequently-asked-questions' },
					// { type: 'QUIZ_SINGLE_CHOICE', label: 'Trắc nghiệm (1 đáp án)', icon: 'mdi-radiobox-marked' },
					// { type: 'QUIZ_MULTIPLE_CHOICE', label: 'Trắc nghiệm (Nhiều đáp án)', icon: 'mdi-checkbox-multiple-marked-outline' },
					// { type: 'QUIZ_TRUE_FALSE', label: 'Đúng / Sai', icon: 'mdi-check-circle-outline' },
					// { type: 'QUIZ_FILL_IN_BLANK', label: 'Điền vào chỗ trống', icon: 'mdi-form-textbox' },
					// { type: 'QUIZ_MATCHING', label: 'Ghép nối', icon: 'mdi-merge' },
				]
			}
		},
		methods: {
			// Google Drive folder cần endpoint embeddedfolderview thì mới hiển thị ổn định trong iframeRef.
			normalizeIframeUrl(url) {
				if (!url) return url
				try {
					const parsedUrl = new URL(url, window.location.href)
					const folderMatch = parsedUrl.hostname === 'drive.google.com'
						? parsedUrl.pathname.match(/\/folders\/([^/]+)/i)
						: null
					if (!folderMatch) return url
					const folderId = decodeURIComponent(folderMatch[1])
					return `https://drive.google.com/embeddedfolderview?id=${encodeURIComponent(folderId)}#list`
				} catch (error) {
					return url
				}
			},
			// v-html không gắn được @click cho từng thẻ a; bắt click ở container để mở cửa sổ nội dung dùng chung.
			handleTextContentClick(event) {
				const anchor = event.target?.closest?.('a')
				if (!anchor) return
				const href = anchor.dataset.lessonLink || anchor.href
				if (!/^https?:\/\//i.test(href)) return

				event.preventDefault()
				event.stopPropagation()
				const payload = {
					title: (anchor.textContent || 'Nội dung liên kết').trim(),
					url: this.normalizeIframeUrl(href),
					icon: 'mdi-link-variant'
				}
				if (this.iframeRef?.value?.openWindow) {
					this.iframeRef.value.openWindow(payload)
					return
				}
				if (window?.parent && window.parent !== window) {
					window.parent.postMessage({ type: 'iframeRef_openWindow', ...payload }, '*')
					return
				}
				window.open(href, '_blank', 'noopener,noreferrer')
			},
			// Chuyển URL thuần trong TEXT thành link nhưng giữ nguyên các thẻ HTML/link đã có sẵn.
			getTextContent(content) {
				if (typeof content !== 'string' || !content || typeof DOMParser === 'undefined') return content || ''
				const parser = new DOMParser()
				const parsed = parser.parseFromString(`<div>${content}</div>`, 'text/html')
				const root = parsed.body.firstElementChild
				if (!root) return content

				const urlPattern = /(?:https?:\/\/|www\.)[^\s<]+/gi
				const ignoredTags = new Set(['A', 'BUTTON', 'CODE', 'PRE', 'SCRIPT', 'STYLE'])
				const linkifyTextNode = node => {
					const text = node.nodeValue || ''
					urlPattern.lastIndex = 0
					let match
					let lastIndex = 0
					let hasUrl = false
					const fragment = parsed.createDocumentFragment()
					while ((match = urlPattern.exec(text)) !== null) {
						const matchedUrl = match[0]
						let linkText = matchedUrl
						let trailingText = ''
						const punctuation = linkText.match(/[.,;:!?…]+$/u)
						if (punctuation) {
							trailingText = punctuation[0]
							linkText = linkText.slice(0, -trailingText.length)
						}
						const openingParentheses = (linkText.match(/\(/g) || []).length
						const closingParentheses = (linkText.match(/\)/g) || []).length
						if (linkText.endsWith(')') && closingParentheses > openingParentheses) {
							trailingText = `)${trailingText}`
							linkText = linkText.slice(0, -1)
						}
						if (match.index > lastIndex) fragment.appendChild(parsed.createTextNode(text.slice(lastIndex, match.index)))
						const anchor = parsed.createElement('a')
						const href = linkText.toLowerCase().startsWith('www.') ? `https://${linkText}` : linkText
						anchor.href = href
						anchor.target = '_blank'
						anchor.rel = 'noopener noreferrer'
						anchor.className = 'lesson-inline-link'
						anchor.setAttribute('data-lesson-link', href)
						anchor.setAttribute('aria-label', 'Mở liên kết trong cửa sổ nội dung')
						anchor.textContent = linkText
						fragment.appendChild(anchor)
						if (trailingText) fragment.appendChild(parsed.createTextNode(trailingText))
						lastIndex = match.index + matchedUrl.length
						hasUrl = true
					}
					if (!hasUrl) return
					if (lastIndex < text.length) fragment.appendChild(parsed.createTextNode(text.slice(lastIndex)))
					node.parentNode.replaceChild(fragment, node)
				}
				const walk = node => {
					if (node.nodeType === 3) return linkifyTextNode(node)
					if (node.nodeType !== 1 || node.tagName === 'A' || ignoredTags.has(node.tagName)) return
					Array.from(node.childNodes).forEach(walk)
				}
				walk(root)
				return root.innerHTML
			},
			getElementKey(element, index) {
				const elementId = Number(element?.ElementID || 0)
				return elementId > 0 ? 'element-' + elementId : 'draft-' + index
			},
			isRemovingElement(element) {
				const elementId = Number(element?.ElementID || 0)
				return elementId > 0 && this.removingElementIds[elementId] === true
			},
			setRemovingElement(elementId, isRemoving) {
				const next = { ...this.removingElementIds }
				if (isRemoving) next[elementId] = true
				else delete next[elementId]
				this.removingElementIds = next
			},
			// Element import từ Content Hub/Học liệu số chỉ sở hữu liên kết trong bài học;
			// không đưa nguồn dùng chung vào danh sách dọn file Drive khi xóa element.
			isSharedContentSource(elementData, source = null) {
				const sourceType = source?.sourceTracking?.sourceType || elementData?.sourceTracking?.sourceType
				return ['CONTENT_HUB', 'HOC_LIEU_SO'].includes(
					String(sourceType || '').trim().toUpperCase().replace(/[\s-]+/g, '_')
				)
			},
				// Xóa trực tiếp theo hành vi cũ của màn soạn bài; trạng thái loading/rollback vẫn bảo vệ thao tác API.
			removeElementAt(index) {
					const element = this.elements?.[index]
					if (!element || this.isRemovingElement(element)) return
					this.removeElement({
						elementId: Number(element.ElementID || 0),
						element
					})
				},
			removeElementFromCanvas(element, fallbackIndex) {
				const elementId = Number(element?.ElementID || 0)
				const nextElements = [...(this.elements || [])]
				const removedIndex = elementId > 0
					? nextElements.findIndex(item => Number(item?.ElementID || 0) === elementId)
					: fallbackIndex
				if (removedIndex < 0 || removedIndex >= nextElements.length) return -1
				nextElements.splice(removedIndex, 1)
				this.$emit('update:elements', nextElements)
				if (this.selectedIndex === removedIndex) this.$emit('update:selectedIndex', null)
				else if (this.selectedIndex > removedIndex) this.$emit('update:selectedIndex', this.selectedIndex - 1)
				return removedIndex
			},
			restoreElementToCanvas(element, originalIndex) {
				const elementId = Number(element?.ElementID || 0)
				const currentElements = [...(this.elements || [])]
				if (elementId > 0 && currentElements.some(item => Number(item?.ElementID || 0) === elementId)) return
				const insertIndex = Math.min(Math.max(originalIndex, 0), currentElements.length)
				currentElements.splice(insertIndex, 0, element)
				this.$emit('update:elements', currentElements)
			},
			getUploadManager() {
				return window.UploadManager
			},
			deleteLmsFileData(fileId) {
				if (!fileId) return Promise.resolve()
				const manager = this.getUploadManager()
				if (!manager || typeof manager.deleteLmsFileData !== 'function') {
					return Promise.reject(new Error('UploadManager chưa được khởi tạo để xóa LMS FileData'))
				}
				return new Promise((resolve, reject) => {
					let settled = false
					const complete = value => { if (!settled) { settled = true; resolve(value) } }
					const fail = error => { if (!settled) { settled = true; reject(error) } }
					try {
						const result = manager.deleteLmsFileData(fileId, { onComplete: complete, onError: fail })
						if (result && typeof result.then === 'function') result.then(complete).catch(fail)
					} catch (error) { fail(error) }
				})
			},
			getYoutubeId(elementData, source) {
				if (elementData?.videoId) return String(elementData.videoId)
				if (source?.videoId) return String(source.videoId)
				const value = String(source?.externalSource || source?.source || '')
				const match = value.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/|shorts\/))([^?&#/]+)/i)
				return match?.[1] || ''
			},
			deleteYoutubeFile(videoId, accessToken) {
				const manager = this.getUploadManager()
				if (!manager || typeof manager.deleteFromYouTube !== 'function') {
					return Promise.reject(new Error('UploadManager chưa được khởi tạo để xóa video YouTube'))
				}
				return new Promise((resolve, reject) => manager.deleteFromYouTube(videoId, {
					accessToken,
					onComplete: resolve,
					onError: reject,
				}))
			},
			getMediaEntries(element) {
				const elementData = element?.ElementData || {}
				const entries = Array.isArray(elementData.sources) ? elementData.sources.map(source => ({ source, elementData })) : []
				if (elementData.source) entries.push({ source: elementData, elementData })
				return entries
			},
			cleanupOwnedMedia(element) {
				const entries = this.getMediaEntries(element).filter(entry => !this.isSharedContentSource(entry.elementData, entry.source))
				if (!entries.length) return Promise.resolve()

				const nodeIds = [...new Set(entries.map(entry => String(entry.source?.resourceNodeId || '').trim()).filter(Boolean))]
				const lmsFileIds = [...new Set(entries.map(entry => {
					const source = entry.source || {}
					const rawUrl = String(source.source || source.url || source.dbSource || '').trim()
					const urlFileId = rawUrl.match(/\/FileData\/([^/?#]+)/i)?.[1] || ''
					const isLmsFileData = /(?:file\.lhbs\.vn|lms\.lhbs\.vn)\/lms\/FileData\//i.test(rawUrl) || /(?:^|\/)FileData\//i.test(rawUrl)
					return String(
						source.resourceFileId
						|| source.dbFileId
						|| (source.mediaSource === 'db' ? source.id : '')
						|| (isLmsFileData ? urlFileId : '')
					).trim()
				}).filter(Boolean))]
				const youtubeIds = [...new Set(entries.map(entry => this.getYoutubeId(entry.elementData, entry.source)).filter(Boolean))]
				const driveIds = [...new Set(entries.map(entry => {
					const source = entry.source || {}
					if (this.getYoutubeId(entry.elementData, source)) return ''
					return String(source.externalId || '').trim() || this.getDriveFileId(source.externalSource || source.source)
				}).filter(Boolean))]

			// Xóa resource node và file vật lý trước khi xóa element để không còn element mồ côi
			// hoặc trường hợp element đã mất nhưng LMS FileData/Drive vẫn còn.
			const deleteNodes = Promise.all(nodeIds.map(id => fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: id }, { cache: false })))
			const needsExternalToken = youtubeIds.length || driveIds.length
			const tokenPromise = needsExternalToken
				? new Promise((resolve, reject) => ajaxCALL('lms/FP_Youtube_Token_Get', null, response => {
					const token = response?.data?.access_token || response?.access_token
					if (token) resolve(token)
					else reject(new Error('Không lấy được quyền dọn file bên thứ ba'))
				}))
				: Promise.resolve('')

			return deleteNodes
				.then(() => tokenPromise)
				.then(accessToken => Promise.all([
					...youtubeIds.map(videoId => this.deleteYoutubeFile(videoId, accessToken)),
					...driveIds.map(fileId => fetch('https://www.googleapis.com/drive/v3/files/' + fileId, {
						method: 'DELETE',
						headers: { Authorization: 'Bearer ' + accessToken },
					}).then(response => {
						if (!response.ok) throw new Error('Xóa file Google Drive thất bại: ' + response.statusText)
					})),
				]))
				.then(() => Promise.all(lmsFileIds.map(fileId => this.deleteLmsFileData(fileId))))
			},
			async removeElement(target) {
				const elementId = Number(target?.elementId || 0)
				const currentElements = this.elements || []
				const currentIndex = elementId > 0
					? currentElements.findIndex(item => Number(item?.ElementID || 0) === elementId)
					: currentElements.indexOf(target?.element)
				if (currentIndex < 0) return
				const element = elementId > 0 ? currentElements[currentIndex] : target.element
				// Element chưa có ID chỉ tồn tại trên canvas; không gọi API với ElementID rỗng.
				if (!elementId) {
					this.removeElementFromCanvas(element, currentIndex)
					return
				}
				if (this.isRemovingElement(element)) return
				const originalIndex = currentIndex
				this.setRemovingElement(elementId, true)
				try {
					// Dọn toàn bộ media sở hữu trước; nếu dọn thất bại thì giữ element để người dùng thử lại.
					await this.cleanupOwnedMedia(element)
					await new Promise((resolve, reject) => ajaxCALL('lms/EL_Element_Delete', {
						ElementID: elementId
					}, response => response?.data ? resolve(response) : reject(new Error('Xóa nội dung bài học thất bại'))))
					// Dùng ElementID để loại đúng block kể cả khi danh sách đã thay đổi trong lúc API đang chạy.
					this.removeElementFromCanvas(element, originalIndex)
					// Không gọi getLessonData ngay tại đây: callback async có thể trả snapshot cũ và chèn element vừa xóa trở lại canvas.
				} catch (error) {
					this.restoreElementToCanvas(element, originalIndex)
					console.error('Lỗi xóa block bài học:', error)
					Vue.$toast.error(error.message || 'Không thể xóa nội dung bài học', { position: 'top' })
				} finally {
					this.setRemovingElement(elementId, false)
				}
			},

			// Ảnh import từ Content Hub có thể là URL LMS, URL ngoài hoặc Google Drive; không được ép mọi nguồn về thumbnail Drive.
				getFileSource(file) {
					const rawSource = String(file?.source || file?.url || file?.externalSource || '').trim()
					if (!rawSource) return ''
					if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(rawSource)) {
						return rawSource.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
					}
					if (/^https?:\/\//i.test(rawSource) || /^(?:data|blob):/i.test(rawSource)) return rawSource
					const base = vueData?.v_Set?.urlReadFile || vueData?.v_Set?.urlReturnFile || 'https://file.lhbs.vn/lms'
					return base.replace(/\/+$/, '') + '/' + rawSource.replace(/^\/+/, '')
				},
				getFilePreviewSource(file) {
					const source = this.getFileSource(file)
					if (!source) return ''

					const driveFileId = this.getDriveFileId(source)
					if (driveFileId) {
						// Google Drive preview đã là một viewer; dùng đúng endpoint /preview thay vì nhúng link download.
						return 'https://drive.google.com/file/d/' + encodeURIComponent(driveFileId) + '/preview'
					}

					const value = String((file?.name || '') + ' ' + (file?.contentType || '') + ' ' + source).toLowerCase()
					const isOffice = /\.(docx?|xlsx?|pptx?)\b|application\/(?:msword|vnd\.openxmlformats-officedocument|vnd\.ms-excel|vnd\.ms-powerpoint)/.test(value)
					if (!isOffice) return source

					const lmsFileId = String(file?.resourceFileId || file?.fileId || file?.dbFileId || file?.id || '').trim()
					const sourceFileId = source.match(/\/FileData\/([^/?#]+)/i)?.[1] || ''
					const fileId = lmsFileId || sourceFileId
					const isLmsFileData = /(?:file\.lhbs\.vn|lms\.lhbs\.vn)\/lms\/FileData\//i.test(source) || /(?:^|\/)FileData\//i.test(source)
					if (isLmsFileData && fileId) {
						// Viewer LMS cần tên file ở path để xác định đúng định dạng và tránh trả binary attachment.
						const rawName = String(file?.name || 'file').trim() || 'file'
						const lastDot = rawName.lastIndexOf('.')
						const baseName = lastDot > -1 ? rawName.slice(0, lastDot) : rawName
						const extension = lastDot > -1 ? rawName.slice(lastDot) : ''
						const safeBaseName = baseName.replace(/[&+%#?:/\\*"<>|]/g, '_').trim() || 'file'
						const safeName = safeBaseName + extension
						return 'https://file.lhbs.vn/lms/viewer/FileData/' + encodeURIComponent(fileId) + '/' + encodeURIComponent(safeName)
					}

					// Office Viewer chỉ dùng cho URL ngoài LMS có thể truy cập công khai.
					return /^https?:\/\//i.test(source)
						? 'https://view.officeapps.live.com/op/view.aspx?src=' + encodeURIComponent(source)
						: source
				},
				getImageSource(file) {
				const source = String(file?.source || file?.url || file?.externalSource || '').trim()
				if (!source) return ''
				if (/drive\.google\.com/i.test(source)) {
					const driveId = file?.externalId || file?.id || this.getDriveFileId(source)
					return driveId ? `https://drive.google.com/thumbnail?id=${driveId}&sz=w1000` : source
				}
				if (/^https?:\/\/lms\.lhbs\.vn\/FileData\//i.test(source)) {
					return source.replace(/^https?:\/\/lms\.lhbs\.vn\/FileData\//i, 'https://file.lhbs.vn/lms/FileData/')
				}
				if (/^https?:\/\//i.test(source) || /^(?:data|blob):/i.test(source)) return source
				const base = vueData?.v_Set?.urlReadFile || 'https://file.lhbs.vn/lms'
					return `${base.replace(/\/+$/, '')}/${source.replace(/^\/+/, '')}`
				},
				openImagePreview(file, element) {
					const source = this.getImageSource(file)
					if (!source) return
					this.imagePreview = {
						src: source,
						title: file?.name || element?.ElementData?.title || 'Hình ảnh',
						caption: file?.caption || '',
					}
					this.imagePreviewDialog = true
				},
				getDriveFileId(url) {
				const match = String(url || '').match(/\/d\/([^/]+)/)
				return match?.[1] || null
			},
	
			getYoutubeEmbedUrl(url) {
				if (!url || typeof url !== 'string') return null;
				let videoId = null;
				const urlParts = url.split(/(vi\/|v=|\/v\/|youtu\.be\/|\/embed\/)/);
				videoId = (urlParts[2] !== undefined) ? urlParts[2].split(/[^0-9a-z_\-]/i)[0] : urlParts[0];
	
				if (videoId) {
					return `https://www.youtube.com/embed/${videoId}`;
				}
				return null;
			},
	
			getIconForType(type) {
				const found = this.elementTypes.find(t => t.value === type);
				return found ? found.icon : 'mdi-help-box';
			},
	
			getLabelForType(type) {
				const found = this.elementTypes.find(t => t.value === type);
				return found ? found.label : this.$t('message.UnknownComponent');
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
			getAnswerForChild(element) {
				let answerObject = null
				if (element.ElementType === 'QUIZ_SINGLE_CHOICE') answerObject = element.ElementData.config?.correctAnswer
				if (element.ElementType === 'QUIZ_MULTIPLE_CHOICE') answerObject = element.ElementData.config?.correctAnswers
				if (element.ElementType === 'QUIZ_TRUE_FALSE') answerObject = element.ElementData.config?.correctAnswer
				if (element.ElementType === 'QUIZ_FILL_IN_BLANK') {
					const _ = element.ElementData.config.parts.filter(item => item.type == 'blank') //.map(item => item.acceptedAnswers[0]).join(", ")
					const obj = {}
					for (var item of _) {
						obj[item.id] = item.acceptedAnswers[0]
					}
					answerObject = obj
				}
				if (element.ElementType === 'QUIZ_MATCHING') answerObject = element.ElementData.config?.correctPairs
				return answerObject;
			},
			formatInteractionTime(seconds) {
				const s = Math.floor(Number(seconds) || 0);
				const mins = Math.floor(s / 60);
				const secs = s % 60;
				return `${mins}:${String(secs).padStart(2, '0')}`;
			},
			getInteractionTypeBadge(item) {
				const rawType = item?.question?.type || item?.type || 'QUIZ_SINGLE_CHOICE';
				const map = {
					QUIZ_SINGLE_CHOICE: { label: 'Trắc nghiệm đơn', color: 'success' },
					QUIZ_MULTIPLE_CHOICE: { label: 'Chọn nhiều', color: 'info' },
					QUIZ_TRUE_FALSE: { label: 'Đúng / Sai', color: 'purple' },
					QUIZ_FILL_IN_BLANK: { label: 'Điền từ', color: 'indigo' },
					QUIZ_MATCHING: { label: 'Nối cặp', color: 'deep-orange' },
					QUIZ_ORDERING: { label: 'Sắp xếp', color: 'teal' }
				};
				return map[rawType] || { label: 'Câu hỏi', color: 'grey' };
			},
			getInteractionPromptRaw(item) {
				if (!item) return 'Câu hỏi tương tác';
				const content = this.getInteractionContent(item);
				const raw = content?.prompt ?? content?.questionText ?? item?.prompt ?? item?.question ?? 'Câu hỏi tương tác';
				return raw || 'Câu hỏi tương tác';
			},
			getInteractionPromptFull(item) {
				if (!item) return 'Câu hỏi tương tác';
				const content = this.getInteractionContent(item);
				const raw = content?.prompt ?? content?.questionText ?? item?.prompt ?? item?.question ?? 'Câu hỏi tương tác';
				if (!raw) return 'Câu hỏi tương tác';
				return String(raw).replace(/<[^>]*>?/gm, '').replace(/&[^;]+;/g, ' ').trim() || 'Câu hỏi tương tác';
			},
			getInteractionContent(item) {
				return {
					...(item || {}),
					...(item?.content || {}),
					...(item?.question?.content || {}),
					...(item?.config || {}),
					...(item?.question?.config || {})
				};
			},
			getInteractionOptions(item) {
				const content = this.getInteractionContent(item);
				if (Array.isArray(content.options)) return content.options;
				if (Array.isArray(item?.options)) return item.options;
				return [];
			},
			getCorrectInteractionOptions(item) {
				return this.getInteractionOptions(item).filter(option => this.isCorrectOption(item, option));
			},
			isCorrectOption(item, opt) {
				const content = this.getInteractionContent(item);
				const correctAns = content.correctAnswer ?? item?.correctAnswer;
				const correctAnsArr = content.correctAnswers ?? item?.correctAnswers;
				const optId = opt?.id ?? opt;
				const optIndex = this.getInteractionOptions(item).indexOf(opt);
				if (typeof correctAns === 'number' && !opt?.id) {
					return correctAns === optIndex;
				}
				if (correctAns !== undefined && correctAns !== null) {
					return String(correctAns) === String(optId);
				}
				if (Array.isArray(correctAnsArr)) {
					return correctAnsArr.map(String).includes(String(optId));
				}
				return false;
			},
			getInteractionDetailsText(item) {
				const content = this.getInteractionContent(item);
				if (content.parts && Array.isArray(content.parts)) {
					return content.parts.map(p => p.type === 'blank' ? `[___: ${(p.acceptedAnswers || []).join(', ')}]` : p.value).join(' ');
				}
				if (content.correctAnswer !== undefined) {
					return `Đáp án: ${content.correctAnswer === true ? 'Đúng' : content.correctAnswer === false ? 'Sai' : content.correctAnswer}`;
				}
				return '';
			},
			renderUrlYoutube
		}
	}
</script>

<style scoped>
/* Overlay chỉ là affordance; toàn bộ thumbnail vẫn click được để hoạt động tốt trên mobile. */
		.lesson-canvas .lesson-image-thumb {
			position: relative;
			cursor: zoom-in;
		}

		.lesson-canvas .lesson-image-preview-hint {
			position: absolute;
			right: 6px;
			bottom: 6px;
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

		.lesson-canvas .file-source-card {
			overflow: hidden;
			border: 1px solid rgba(0, 0, 0, 0.12);
			border-radius: 8px;
			background: #f5f5f5;
		}

		.lesson-canvas .file-source-iframe {
			display: block;
			width: 100%;
			height: 420px;
			border: 0;
			background: #fff;
		}

		@media (hover: none) {
			.lesson-canvas .lesson-image-preview-hint {
				opacity: 1;
			}
		}
</style>