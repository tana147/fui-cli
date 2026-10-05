<template>
    <v-dialog v-model="vueData.IsShowBanner" fullscreen hide-overlay>
        <div class="div-banner-carousel">
            <v-carousel cycle :interval="5000" touchless hide-delimiters height="100%">
                <v-carousel-item v-for="(item, i) in BannerImage" :key="i" :src="item.src" reverse-transition="fade-transition" />
            </v-carousel>
            <v-btn v-if="vueData.KhachHangID === 'Z00010678'" @click="vueData.IsShowBanner = false" large color="primary" class="btn-close-banner">Tham gia chương trình</v-btn>
        </div>
    </v-dialog>
</template>

<script>
export default {
    props: [],
    data() {
        const banners = []
        return {
            BannerImage: _.shuffle(banners),
        }
    },
}
</script>
