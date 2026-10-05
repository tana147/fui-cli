<template>
	<v-card
		class="sach-card-modern position-relative rounded-xl overflow-hidden fill-height d-flex flex-column"
		elevation="2"
		hover
		@click="handleClick"
		style="cursor: pointer; transition: all 0.25s ease;"
	>
		<!-- Khung chứa ảnh bìa sách -->
		<div class="card-img-wrapper position-relative overflow-hidden" style="aspect-ratio: 3/4; width: 100%; background: #f1f5f9;">
			<img
				v-if="displayImgUrl && item.ThumbnailURL"
				:src="displayImgUrl"
				class="w-100 h-100 card-thumb"
				style="object-fit: cover; display: block; width: 100%; height: 100%;"
				@error="() => item.ThumbnailURL = ''"
				alt="Cover"
			/>

			<!-- Ảnh fallback nếu không có ảnh -->
			<div v-else class="d-flex flex-column align-center justify-center fill-height pa-4 text-center bg-teal-lighten-5">
				<v-icon size="48" color="teal-darken-2" class="mb-2">mdi-book-open-page-variant</v-icon>
				<span class="text-caption font-weight-bold text-teal-darken-3 text-truncate w-100">
					{{ item.TenMonHoc || item.TenHocLieu }}
				</span>
			</div>

			<!-- Badge Tình trạng / Loại sách -->
			<div class="position-absolute" style="top: 8px; right: 8px; z-index: 2;">
				<v-chip color="success" variant="flat" size="x-small" class="font-weight-bold elevation-1 px-2">
					<v-icon start icon="mdi-check-circle" size="12"></v-icon>
					{{ item.TinhTrang || 'Public' }}
				</v-chip>
			</div>
		</div>

		<!-- Thông tin sách -->
		<v-card-text class="pa-3 flex-grow-1 d-flex flex-column justify-space-between bg-white">
			<div>
				<div class="text-caption text-grey-darken-1 font-weight-medium mb-1 text-truncate" :title="item.TenBoSach">
					{{ item.TenBoSach || 'Bộ sách giáo khoa' }}
				</div>
				<h4 class="text-subtitle-2 font-weight-bold text-slate-800 line-clamp-2 mb-2" style="line-height: 1.35; color: #1e293b;" :title="item.TenHocLieu">
					{{ item.TenHocLieu }}
				</h4>
			</div>

			<v-btn
				color="success"
				variant="tonal"
				size="small"
				block
				rounded="lg"
				class="mt-2 font-weight-bold"
			>
				<v-icon start size="small">mdi-book-open-variant</v-icon> Mở bài học
			</v-btn>
		</v-card-text>
	</v-card>
</template>

<script>
	export default {
		name: 'uc-sach-card',
		props: {
			item: { type: Object, required: true }
		},
		computed: {
			displayImgUrl() {
				const url = this.item.ThumbnailURL;
				if (!url) return '';
				if (url.startsWith('http://') || url.startsWith('https://')) {
					return url;
				}
				const domain = vueData?.v_Set?.urlReturnFile || vueData?.v_Set?.urlReadFile || '';
				if (url.startsWith('/FileData/')) {
					return domain + url;
				}
				if (url.startsWith('/')) {
					return domain + url;
				}
				return domain + '/FileData/' + url;
			}
		},
		methods: {
			handleClick() {
				redirect(`/chi-tiet-hoc-lieu?id=${this.item.HocLieuID}`);
			}
		}
	}
</script>

<style scoped>
.sach-card-modern:hover {
		transform: translateY(-4px);
		box-shadow: 0 12px 24px -8px rgba(16, 185, 129, 0.25) !important;
	}
	.sach-card-modern:hover .card-thumb {
		transform: scale(1.05);
	}
	.card-thumb {
		transition: transform 0.3s ease;
	}
	.line-clamp-2 {
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
</style>