<template>
	<v-dialog max-width="900">
		<template v-slot:activator="{ props: activatorProps }">
			<div v-bind="activatorProps" style="width: 500px">
				<div v-if="isEditable">
					<div v-if="isEmpty" class="cursor-pointer empty-content">
						Bấm để <v-icon color="success" size="small">mdi-pencil</v-icon> soạn nội dung...
					</div>
					<div v-else ref="contentContainer" class="cursor-pointer uc-latex-edit" v-html="renderedContent" />
				</div>
				<div v-else>
					<div ref="contentContainer" class="uc-latex-edit" v-html="renderedContent" />
				</div>
			</div>
		</template>

		<template v-slot:default="{ isActive }">
			<v-card title="Chỉnh sửa nội dung">
				<v-card-text>
					<uc-rich-text-editor v-model="contentEditor" :imageapi="vueData.v_Set.apiFile" variant="outlined"
						rows="6" auto-grow label="Nội dung (hỗ trợ HTML, LaTeX & GeoGebra)"
						@update:modelValue="val => console.log('upd', val)" @input="v => console.log('v', v)" />
					<!-- Preview -->
					<div class="preview-section mt-4">
						<label class="text-subtitle-2 mb-2">Xem trước:</label>
						<div class="preview-content uc-latex-edit">
							<div v-if="previewEmpty" class="text-grey">
								<em>Không có nội dung...</em>
							</div>
							<div v-else ref="previewContainer" v-html="previewContent"></div>
						</div>
					</div>
				</v-card-text>

				<v-card-actions>
					<v-spacer></v-spacer>
					<v-btn text="Hủy" variant="text" @click="cancelEdit(isActive)"></v-btn>
					<v-btn text="Lưu" color="primary" @click="saveContent(isActive)"></v-btn>
				</v-card-actions>
			</v-card>
		</template>
	</v-dialog>
</template>

<script>
	export default {
		name: 'uc-latex-edit',
		props: {
			content: {
				type: String,
				default: ''
			},
			isEditable: {
				type: Boolean,
				default: true
			}
		},
		data() {
			return {
				contentEditor: this.content,
				renderedContent: '',
				previewContent: '',
				contentRenderVersion: 0,
				previewRenderVersion: 0,
				vueData
			}
		},
		computed: {
			isEmpty() {
				return !this.content || this.content.trim() === ''
			},
			previewEmpty() {
				return !this.contentEditor || this.contentEditor.trim() === ''
			}
		},
		watch: {
			content: {
				immediate: true,
				handler(newContent) {
					this.contentEditor = newContent
					this.renderContent(newContent)
				}
			},
			contentEditor(newContent) {
				this.renderPreview(newContent)
			}
		},
		mounted() {
			this.loadMathJax()
		},
		methods: {
			loadMathJax() {
				if (!window.MathJax) {
	
					const script = document.createElement('script')
					script.src = 'https://cdnjs.cloudflare.com/ajax/libs/mathjax/3.2.2/es5/tex-mml-chtml.min.js'
					script.onload = () => {
						this.configureMathJax()
						this.renderContent(this.content)
					}
					document.head.appendChild(script)
				} else {
					console.log("đã loà MathJAX");
					this.renderContent(this.content)
				}
			},
	
			configureMathJax() {
				window.MathJax = {
					tex: {
						inlineMath: [['$', '$'], ['\\(', '\\)']],
						displayMath: [['$$', '$$'], ['\\[', '\\]']]
					},
					svg: {
						fontCache: 'global'
					}
				}
			},

			normalizeLatexDelimiters(content) {
				return String(content || '')
					.replace(/\$\$([\s\S]+?)\$\$/g, '\\[$1\\]')
					.replace(/(^|[^\\])\$([^$\n]+?)\$/g, (match, prefix, formula) => `${prefix}\\(${formula}\\)`)
			},

			loadWmfRenderer() {
				if (window.WMF) return Promise.resolve(window.WMF)
				if (window.__wmfRendererPromise) return window.__wmfRendererPromise

				window.__wmfRendererPromise = new Promise((resolve, reject) => {
					const script = document.createElement('script')
					script.src = 'https://cdn.jsdelivr.net/npm/wmf@1.0.2/dist/wmf.js'
					script.onload = () => {
						if (window.WMF) resolve(window.WMF)
						else reject(new Error('Không tìm thấy bộ chuyển WMF'))
					}
					script.onerror = () => reject(new Error('Không tải được bộ chuyển WMF'))
					document.head.appendChild(script)
				})

				return window.__wmfRendererPromise
			},

			convertWmfImages(content) {
				const html = String(content || '')
				if (!/data:image\/(?:x-)?wmf;base64,/i.test(html)) return Promise.resolve(html)

				return this.loadWmfRenderer().then((WMF) => {
					const parsed = new DOMParser().parseFromString(html, 'text/html')
					const imageNodes = Array.from(parsed.querySelectorAll('img'))

					imageNodes.forEach((imageNode) => {
						const src = imageNode.getAttribute('src') || ''
						const match = src.match(/^data:image\/(?:x-)?wmf;base64,([\s\S]+)$/i)
						if (!match) return

						try {
							const binary = atob(match[1].replace(/\s/g, ''))
							const bytes = new Uint8Array(binary.length)
							for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)
							const size = WMF.image_size(bytes)
							const width = Math.ceil(Number(size && size[0]))
							const height = Math.ceil(Number(size && size[1]))
							if (!Number.isFinite(width) || !Number.isFinite(height) || width < 1 || height < 1 || width > 4096 || height > 4096) return

							const canvas = document.createElement('canvas')
							canvas.width = width
							canvas.height = height
							WMF.draw_canvas(bytes, canvas)
							imageNode.setAttribute('src', canvas.toDataURL('image/png'))
						} catch (error) {
							console.warn('[uc-latex-edit] Không chuyển được ảnh WMF:', error)
						}
					})

					return parsed.body.innerHTML
				}).catch((error) => {
					console.warn('[uc-latex-edit] Không tải được bộ chuyển WMF:', error)
					return html
				})
			},
	
			renderContent(content) {
				const renderVersion = ++this.contentRenderVersion
				if (!content) {
					this.renderedContent = ''
					return
				}
	
				const normalizedContent = this.normalizeLatexDelimiters(content)
				this.convertWmfImages(normalizedContent).then((convertedContent) => {
					if (renderVersion !== this.contentRenderVersion) return
					this.renderedContent = convertedContent
					this.$nextTick(() => {
						if (window.MathJax && window.MathJax.typesetPromise && this.$refs.contentContainer) {
							window.MathJax.typesetPromise([this.$refs.contentContainer])
								.catch(err => console.error('MathJax render error:', err))
						}
					})
				})
			},
	
			renderPreview(content) {
				const renderVersion = ++this.previewRenderVersion
				if (!content) {
					this.previewContent = ''
					return
				}
	
				const normalizedContent = this.normalizeLatexDelimiters(content)
				this.convertWmfImages(normalizedContent).then((convertedContent) => {
					if (renderVersion !== this.previewRenderVersion) return
					this.previewContent = convertedContent
					this.$nextTick(() => {
						if (window.MathJax && window.MathJax.typesetPromise && this.$refs.previewContainer) {
							window.MathJax.typesetPromise([this.$refs.previewContainer])
								.catch(err => console.error('MathJax preview error:', err))
						}
					})
				})
			},
	
			saveContent(isActive) {
				this.$emit('update:content', this.contentEditor)
				isActive.value = false
			},
	
			cancelEdit(isActive) {
				this.contentEditor = this.content
				isActive.value = false
			}
		}
	}
</script>