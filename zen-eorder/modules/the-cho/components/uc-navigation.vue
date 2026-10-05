<template>
    <div>
        <v-row>
            <v-col cols="6">
                <v-select v-model="CuaHangID" label="Cửa hàng" :items="vueData.DSCuaHang" item-value="CuaHangID" item-text="TenCuaHang" outlined dense hide-details> </v-select>
            </v-col>
            <v-col cols="1">
                <v-text-field type="number" v-model="SoChoTu" label="Số thẻ từ" outlined dense hide-details> </v-text-field>
            </v-col>
            <v-col cols="1">
                <v-text-field type="number" v-model="SoChoDen" label="Số thẻ đến" outlined dense hide-details> </v-text-field>
            </v-col>
            <v-col cols="2">
                <v-btn :disabled="IsDisable" color="primary" @click="onClickCreateQR" elevation="0" block><v-icon left> mdi-plus</v-icon> Tạo mã QR</v-btn>
            </v-col>
            <v-col cols="2">
                <v-btn color="success" @click="downloadAllQR" elevation="0" block> <v-icon left>mdi-download</v-icon> Tải tất cả QR </v-btn>
            </v-col>
        </v-row>
    </div>
</template>

<script>
export default {
    props: [],
    data() {
        return {
            CuaHangID: 0,
            SoChoTu: 0,
            SoChoDen: 0,
        }
    },
    mounted() {},
    computed: {
        IsDisable: function () {
            return this.CuaHangID > 0 && this.SoChoTu !== "" && this.SoChoDen !== "" && parseInt(this.SoChoTu) > 0 && parseInt(this.SoChoDen) > 0 && parseInt(this.SoChoTu) <= parseInt(this.SoChoDen) ? false : true
        },
    },
    watch: {
        CuaHangID: function () {
            $("#qr_result").empty()
        },
    },
    methods: {
        async downloadAllQR() {
            const start = parseInt(this.SoChoTu)
            const end = parseInt(this.SoChoDen)
            for (let i = start; i <= end; i++) {
                const canvas = document.querySelector(`#qr_${i} canvas`)
                if (canvas) {
                    const link = document.createElement("a")
                    link.download = `THECHO_${i}.png`
                    link.href = canvas.toDataURL("image/png")
                    link.click()
                    await new Promise((r) => setTimeout(r, 150)) // tránh trình duyệt chặn tải nhiều file
                }
            }
        },
        onClickCreateQR() {
            $("#qr_result").empty()
            for (let i = parseInt(this.SoChoTu); i <= parseInt(this.SoChoDen); i++) {
                const qrUrl = `https://eorder.zentea.vn/hdc?chid=${this.CuaHangID}&stt=${i}`
                const qrContainerId = `qr_${i}`
                $("#qr_result").append(`
							      <div id="${qrContainerId}" style="display:inline-block; text-align:center; margin:10px;">
							        <div></div>
							        <div style="margin-top:5px; font-weight:bold;">Số thẻ: ${i}</div>
							      </div>
							    `)
                $(`#${qrContainerId} div:first`).qrcode({
                    text: qrUrl,
                    render: "canvas",
                })
                $("#qr_result canvas").css({width: "75px", height: "75px"})
            }
        },
    },
}
</script>
