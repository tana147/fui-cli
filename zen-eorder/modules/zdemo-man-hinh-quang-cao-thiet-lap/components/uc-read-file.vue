<template>
	<div v-if="vueData.AnhManHinh_FileID_View">
		<!-- Nếu là hình ảnh -->
		<div v-if="vueData.AnhManHinh_FileID_ContentType?.includes('image')" class="media-container">
			<img :src="'https://file.zenfoodcourt.vn/eorder/auth/FileData/'+ vueData.AnhManHinh_FileID_View" width="200" />
			<div class="v-btn v-btn--icon v-btn--round theme--light v-size--default cursor-pointer custom-button-close"
				@click="onClose">
				<v-icon>mdi-close</v-icon>
			</div>
		</div>

		<!-- Nếu là video -->
		<div v-else-if="vueData.AnhManHinh_FileID_ContentType?.includes('mp4')"  class="media-container">
			<video :src="imageBlobUrl" width="200" controls></video>
			<div class="v-btn v-btn--icon v-btn--round theme--light v-size--default cursor-pointer custom-button-close"
				@click="onClose">
				<v-icon>mdi-close</v-icon>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		data() {
			return {
				vueData: vueData
			}
		},
		watch: {
		
		},
		computed: {
	
		},
		methods: {
			
			onClose: function () {
				vueData.AnhManHinh_FileID_View = null;
			}
		}
	}
</script>