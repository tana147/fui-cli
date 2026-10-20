<template>
	<v-card flat class="uc-lesson-component-library h-100 d-flex flex-column">
		<div class="pa-3 py-2 d-flex align-center justify-space-between bg-grey-lighten-4">
			<div class="d-flex align-center ga-2">
				<v-icon color="primary">mdi-view-grid-plus-outline</v-icon>
				<div>
					<div class="text-subtitle-2 font-weight-bold">{{ $t('message.ContentLibrary') }}</div>
					<div class="text-caption text-medium-emphasis">{{ IsEngLish ? 'Add a block to your lesson' : 'Thêm khối nội dung vào bài giảng' }}</div>
				</div>
			</div>
			<v-chip color="primary" variant="tonal" size="small">{{ contentElements.length }}</v-chip>
		</div>

		<!-- Mỗi hàng là thao tác thêm trực tiếp nên không lặp lại dấu cộng ở cuối hàng. -->
		<v-list density="compact" nav class="pa-2 flex-grow-1">
			<template v-for="section in contentSections" :key="section.key">
				<v-list-subheader class="px-2">{{ section.title }}</v-list-subheader>
				<v-list-item v-for="item in section.items" :key="item.type" @click="$emit('add-element', item)" link rounded="lg" class="my-1">
					<template v-slot:prepend>
						<v-avatar :color="item.color || 'primary'" variant="tonal" size="36">
							<v-icon :icon="item.icon" :color="item.color || 'primary'"></v-icon>
						</v-avatar>
					</template>
					<v-list-item-title class="font-weight-medium">{{ item.label }}</v-list-item-title>
					<v-list-item-subtitle>{{ getDescription(item.type) }}</v-list-item-subtitle>
				</v-list-item>
			</template>
		</v-list>
	</v-card>
</template>

<script>
	export default {
		emits: ['add-element'],
		data() {
			this.$i18n.locale = (localStorage.getItem('IsLanguage') && localStorage.getItem('IsLanguage') == 'true') ? 'en' : 'vi'
			return {
				contentElements: [
					{
						type: 'TEXT', label: this.$t('message.TextBlock'), icon: 'mdi-format-text', defaultData: {
							title: this.$t('message.TextTitle'),
							content: `<p>${this.$t('message.NewTextContent')}</p>`
						}
					},
					{
						type: 'IMAGE', label: this.$t('message.Image'), icon: 'mdi-image-outline',
						defaultData: {
							title: this.$t('message.ImageTitle'),
							sources: []
						}
					},
					{
						type: 'YOUTUBE', label: 'Video (YouTube)', icon: 'mdi-youtube',
						defaultData: {
							title: this.$t('message.YoutubeTitle'),
							source: ''
						}
					},
					{
						type: 'FILE', label: this.$t('message.Attachment'), icon: 'mdi-paperclip',
						defaultData: {
							title: this.$t('message.FileTitle'),
							sources: []
						}
					},
					{
						type: 'AUDIO', label: this.$t('message.Audio'), icon: 'mdi-volume-high', color: 'orange-darken-2',
						defaultData: {
							title: this.$t('message.AudioTitle'),
							source: ''
						}
					},
					{
						type: 'HTML', label: 'HTML', icon: 'mdi-language-html5', color: 'orange-darken-2',
						defaultData: {
							title: this.$t('message.HtmlTitle'),
							IsHTML: true,
							source: ''
						}
					},
	
					// {
					// 	type: 'QUIZ_SINGLE_CHOICE', label: 'Trắc nghiệm (1 đáp án)', icon: 'mdi-radiobox-marked',
					// 	defaultData: {
					// 		config: {
					// 			isAdvanced: false,
					// 			questionText: 'Câu hỏi...',
					// 			options: [
					// 				{ id: 'opt1', text: 'A' },
					// 				{ id: 'opt2', text: 'B' }],
					// 			correctAnswer: 'opt1'
					// 		}
					// 	}
					// },
					// {
					// 	type: 'QUIZ_MULTIPLE_CHOICE', label: 'Trắc nghiệm (Nhiều đáp án)', icon: 'mdi-checkbox-multiple-marked-outline',
					// 	defaultData: {
					// 		config: {
					// 			isAdvanced: false,
					// 			questionText: 'Câu hỏi...',
					// 			options: [
					// 				{ id: 'opt1', text: 'A' },
					// 				{ id: 'opt2', text: 'B' }],
					// 			correctAnswers: ['opt1', 'opt2']
					// 		}
					// 	}
					// },
					// {
					// 	type: 'QUIZ_TRUE_FALSE', label: 'Đúng / Sai', icon: 'mdi-check-circle-outline',
					// 	defaultData: {
					// 		config: {
					// 			isAdvanced: false,
					// 			questionText: 'Câu hỏi...',
					// 			options: [
					// 				{ id: true, text: 'Đúng' },
					// 				{ id: false, text: 'Sai' }],
					// 			correctAnswer: true
					// 		}
					// 	}
					// },
					// {
					// 	type: 'QUIZ_FILL_IN_BLANK', label: 'Điền vào chỗ trống', icon: 'mdi-form-textbox',
					// 	defaultData: {
					// 		config: {
					// 			isAdvanced: false,
					// 			questionText: 'Câu hỏi...',
					// 			parts: [
					// 				{ type: 'text', value: 'Điền vào ' },
					// 				{ type: 'blank', id: 'blank_1', acceptedAnswers: ['chỗ trống'] },
					// 				{ type: 'text', value: ' này.' }
					// 			]
					// 		}
	
					// 	}
					// },
					// {
					// 	type: 'QUIZ_MATCHING', label: 'Ghép nối', icon: 'mdi-merge',
					// 	defaultData: {
					// 		config: {
					// 			isAdvanced: false,
					// 			questionText: 'Câu hỏi...',
					// 			columnA: [],
					// 			columnB: [],
					// 			correctPairs: []
					// 		}
					// 	}
					// },
				]
			}
		},
		computed: {
			IsEngLish: function () {
				return this.$i18n.locale === 'en'
			},
			contentSections: function () {
				var groups = [
					{ key: 'basic', title: this.IsEngLish ? 'Text & visuals' : 'Văn bản & hình ảnh', types: ['TEXT', 'IMAGE'] },
					{ key: 'media', title: this.IsEngLish ? 'Media & files' : 'Media & tài liệu', types: ['YOUTUBE', 'FILE', 'AUDIO'] },
					{ key: 'embed', title: this.IsEngLish ? 'Embedded content' : 'Nội dung nhúng', types: ['HTML'] }
				]

				return groups.map(function (group) {
					return {
						key: group.key,
						title: group.title,
						items: this.contentElements.filter(function (item) { return group.types.indexOf(item.type) !== -1 })
					}
				}, this).filter(function (group) { return group.items.length > 0 })
			}
		},
		methods: {
			getDescription: function (type) {
				var descriptions = {
					TEXT: this.IsEngLish ? 'Text, links and formatted content' : 'Văn bản, liên kết và nội dung định dạng',
					IMAGE: this.IsEngLish ? 'Add an illustrative image' : 'Thêm hình ảnh minh họa',
					YOUTUBE: this.IsEngLish ? 'Embed a YouTube video' : 'Nhúng video YouTube',
					FILE: this.IsEngLish ? 'Attach a document for learners' : 'Đính kèm tài liệu cho người học',
					AUDIO: this.IsEngLish ? 'Record or upload audio' : 'Ghi âm hoặc tải tệp âm thanh',
					HTML: this.IsEngLish ? 'Embed HTML content' : 'Nhúng nội dung HTML'
				}
				return descriptions[type] || ''
			}
		}
	}
</script>