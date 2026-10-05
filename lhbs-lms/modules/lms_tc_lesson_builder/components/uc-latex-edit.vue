<template>
	<v-dialog max-width="900">
		<template v-slot:activator="{ props: activatorProps }">
			<div v-bind="activatorProps" style="width: 500px">
				<div v-if="isEditable">
					<div v-if="isEmpty" class="cursor-pointer empty-content">
						{{ $t('message.ClickTo') }} <v-icon color="success" size="small">mdi-pencil</v-icon> {{
						$t('message.EditContentShort') }}
					</div>
					<div v-else ref="contentContainer" class="cursor-pointer uc-latex-edit" v-html="renderedContent"
						style="word-break: auto-phrase;" />
				</div>
				<div v-else ref="contentContainer" class="uc-latex-edit" v-html="renderedContent" />
			</div>
		</template>

		<template v-slot:default="{ isActive }">
			<v-card :title="$t('message.EditContent')">
				<v-card-text>
					<f-editor v-model="contentEditor" :imageapi="vueData.v_Set.apiImageAdapter" :height="400" variant="outlined"
						rows="6" auto-grow :label="$t('message.ContentHtmlLatex')"
						@update:modelValue="val => console.log('upd', val)" @input="v => console.log('v', v)" />
					<!-- Không lặp preview trong popup; canvas bên ngoài đã hiển thị nội dung sau khi lưu. -->
				</v-card-text>

				<v-card-actions>
					<v-spacer />
					<v-btn :text="$t('message.Cancel')" variant="text" @click="cancelEdit(isActive)"></v-btn>
					<v-btn :text="$t('message.Save')" color="primary" @click="saveContent(isActive)"></v-btn>
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
			this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
				return {
					contentEditor: this.content,
					renderedContent: '',
					vueData
			}
		},
		computed: {
			isEmpty() {
				return !this.content || this.content.trim() === ''
			},
		},
		watch: {
			content: {
				immediate: true,
				handler(newContent) {
					this.contentEditor = newContent
					this.renderContent(newContent)
				}
			},
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
	
			renderContent(content) {
				if (!content) {
					this.renderedContent = ''
					return
				}
	
				this.renderedContent = content
	
				this.$nextTick(() => {
					if (window.MathJax && window.MathJax.typesetPromise) {
						window.MathJax.typesetPromise([this.$refs.contentContainer])
							.catch(err => console.error('MathJax render error:', err))
					}
				})
			},
	
		async saveContent(isActive) {
				await this.deleteRemovedUploadedImages(this.content, this.contentEditor)
				this.$emit('update:content', this.contentEditor)
				isActive.value = false
			},
	
			cancelEdit(isActive) {
				this.contentEditor = this.content
				isActive.value = false
			},

			extractImageSources(html) {
				const sources = new Set()
				const regex = /<img[^>]+src=["']([^"']+)["']/gi
				let match
				while ((match = regex.exec(html || ''))) sources.add(match[1])
				return sources
			},

			getLmsFileId(source) {
				if (!source || typeof source !== 'string') return null
				const match = source.match(/\/FileData\/([^/?#"']+)/i)
				return match?.[1] || null
			},

			async deleteRemovedUploadedImages(previousContent, nextContent) {
				const previousImages = this.extractImageSources(previousContent)
				const nextImages = this.extractImageSources(nextContent)
				const removedFileIds = [...previousImages]
					.filter(source => !nextImages.has(source))
					.map(source => this.getLmsFileId(source))
					.filter(Boolean)
				if (!removedFileIds.length) return

				const manager = window.UploadManager
				if (!manager?.deleteLmsFile) return
				await Promise.allSettled(removedFileIds.map(fileId => manager.deleteLmsFileData(fileId)))
			}
		}
	}
</script>