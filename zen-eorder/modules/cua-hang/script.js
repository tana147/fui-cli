function openDialogActiveTime(item) {
    vueData.CuaHangActiveTime = Object.assign({}, item.data ?? null)
    vueData.IsDialogActiveTime = true
}
function openDialogIpAddress(item) {
    vueData.CuaHangIPItem = item.data ?? null
    loadDSCuaHangIP().then(() => {
        vueData.IsDialogIPAddress = true
    })
}
function loadDSCuaHangIP() {
    return new Promise((resolve) => {
        const params = {CuaHangID: vueData.CuaHangIPItem.CuaHangID}
        ajaxCALL("/eorder/CuaHangIP_Select_ByCuaHangId", params, (res) => {
            resolve(res)
        })
    })
}
Vue.component("uc-dialog-ipaddress", {
    props: ["isshow"],
    data() {
        return {
            DSIPAddress: [],
            headers: [
                {
                    text: "Địa chỉ IP",
                    value: "IPAddress",
                },
                {
                    text: "",
                    value: "ctrl-update",
                    align: "center",
                    width: 100,
                    sortable: false,
                },
            ],
            updateForm: [
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "IPAddress",
                        label: "Địa chỉ IP",
                    },
                    w: 12,
                },
            ],
            updateApi: {
                new: {
                    API: "/eorder/CuaHangIP_Insert",
                    IN: {
                        CuaHangID: "vueData.CuaHangIPItem.CuaHangID",
                        IPAddress: "item.IPAddress",
                    },
                    MESS: "Thêm IP cửa hàng thành công",
                    CALLBACK: [
                        {
                            EXE: "loadDSCuaHangIP()",
                        },
                    ],
                },
                edit: {
                    API: "/eorder/CuaHangIP_Update",
                    IN: {
                        CuaHangID: "vueData.CuaHangIPItem.CuaHangID",
                        IPAddress: "item.IPAddress",
                        CuaHangIPID: "item.CuaHangIPID",
                    },
                    MESS: "Cập nhật IP cửa hàng thành công",
                    CALLBACK: [
                        {
                            EXE: "loadDSCuaHangIP()",
                        },
                    ],
                },
                delete: {
                    API: "/eorder/CuaHangIP_Delete",
                    IN: {
                        CuaHangIPID: "item.CuaHangIPID",
                        CuaHangID: "vueData.CuaHangIPItem.CuaHangID",
                    },
                    MESS: "Xóa thành công",
                    CALLBACK: [
                        {
                            EXE: "loadDSCuaHangIP()",
                        },
                    ],
                },
            },
        }
    },
    watch: {
        isshow: function (val) {
            if (val) {
                loadDSCuaHangIP().then((res) => {
                    this.DSIPAddress = res.data
                })
            }
        },
    },
    template: /*html*/ `
        <v-dialog
            v-model="isshow"
            scrollable
            width="600"
        >
            <v-card>
              <v-toolbar dense flat>
                <v-toolbar-title>Thiết lập địa chỉ IP: {{vueData.CuaHangIPItem.TenCuaHang}}</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsDialogIPAddress = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
                <f-table
                        class="mx-3 mb-5"
                        label="Danh sách địa chỉ IP"
                        :headers="headers"
                        :items="DSIPAddress"
                        :excel= "true"
                        dense
                        :update-form="updateForm"
                        :update-api= "updateApi"
                        :items-per-page='-1'
                        hide-default-footer="true"
                    ></f-table>
            </v-card>
        </v-dialog>
    `,
})