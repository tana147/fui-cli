function updateStatus(data) {
    const formData = data.data
    const params = {
        BanID: formData.BanID,
        TinhTrang: formData.TinhTrang,
    }
    if (formData.BanID) {
        ajaxCALL("/eorder/Ban_Update_TinhTrang", params, (res) => {
            if (res.data) {
                formData.TinhTrang = formData.TinhTrang === 0 ? 1 : 0 //Set ngược lại table
            }
        })
    }
}
Vue.component("qrcode", {
    methods: {
        init() {
            const qrcode = vueData.v_Set.hostUrl + "/order/" + vueData.CTBan[0].QrCode
            const options = {
                render: "canvas",
                text: qrcode,
            }
            $("#divQrCode").qrcode(options)
        },
        createNewQr() {
            confirm({
                title: "Xác nhận tạo mới QR Code",
                content: "Bạn có chắc muốn tạo mới QR Code cho bàn " + vueData.CTBan[0].TenBan,
                action: function () {
                    const $this = this
                    const params = {
                        BanID: vueData.CTBan[0].BanID,
                    }
                    ajaxCALL("/eorder/Ban_Update_QrCode", params, (res) => {
                        if (res.data) {
                            vueData.CTBan[0].QrCode = res.data[0].QrCode
                            $("#divQrCode").empty()
                            $this.init()
                        }
                    })
                },
            })
        },
        downloadQrCode() {
            var div = document.getElementById("divQrCode")
            var canvas = div.children
            var anchor = document.createElement("a")
            anchor.href = canvas[0].toDataURL("image/png")
            anchor.download = "qrcode.png"
            anchor.click()
            anchor.remove()
        },
    },
    mounted() {
        this.init()
    },
    template: /*html*/ `
        <div>
            <div id="divQrCode"></div>
            <p class="title mb-4" style="line-height: 1.5;">
                Mã QR: <a :href="'/order/' + vueData.CTBan[0]?.QrCode" target="_blank" class='red--text'>{{vueData.CTBan[0]?.QrCode}}</a>
                <br/> {{vueData.CTBan[0]?.TenCuaHang}}
                <br/> {{vueData.CTBan[0]?.TenLau}} / {{vueData.CTBan[0]?.TenKhu}} / {{vueData.CTBan[0]?.TenBan}} <br/>
            </p>
            <v-btn color="success" text @click="createNewQr()">Tạo mới QR Code</v-btn>
            <v-btn class="ml-2" color="success" text @click="downloadQrCode()">Tải mã QR Code</v-btn>
        </div>
      `,
})