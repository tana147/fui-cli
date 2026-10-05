<template>
    <v-dialog :fullscreen="$vuetify.display.xs" v-model="showQrDialog" width="500"
        transition="dialog-bottom-transition">
        <v-card class="bg-black">
            <v-toolbar color="transparent" theme="dark">
                <v-toolbar-title>Quét mã tài sản</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon="mdi-close" @click="showQrDialog = false"></v-btn>
            </v-toolbar>
            <v-card-text class="pa-0 d-flex flex-column align-center justify-center" style="height: 100%">
                <uc-qr v-model="maCaBietQuet" @scan-success="kiemKeBangMa" ref="qrScanner" :cooldown-ms="1000"
                    :continuous="true" style="width: 100%; aspect-ratio: 1/1;">
                </uc-qr>
                <div class="mt-4 text-white text-center px-4">Di chuyển camera đến mã QR trên tài sản</div>
                <v-btn class="mt-4" variant="outlined" color="white" prepend-icon="mdi-image"
                    @click="$refs.qrScanner?.triggerFileInput()">Chọn ảnh từ thư viện</v-btn>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {

    props: {
    },

    data() {
        return {
        }
    },

    mounted() {
    },
    computed: {
    },

    watch: {
    },

    methods: {
    }

}
</script>
