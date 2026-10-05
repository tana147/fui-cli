<template>
    <div>
        <v-row>
            <v-col cols="4">
                <f-table class="mt-1" :show-search="true" :excel="true" label="Nhóm loại ly" item-key="LoaiLyID" :items="vueData.DS_NhomLoaiLy" :headers="HeaderNhomLoaiLy" height="calc(100vh - 131px)" :fixed-header="true" dense hide-default-footer="false" :items-per-page="-1"> </f-table>
            </v-col>
            <v-col cols="8" class="pl-0">
                <f-table class="mt-1" :excel="true" :items-per-page="-1" :label="labelThietLapDiem" item-key="NhomLoaiLyDiemID" :items="vueData.DS_ThietLap" :headers="HeaderThietLap" height="calc(100vh - 131px)" :show-search="true" :fixed-header="true" dense :update-form="UpdateFormThietLap" :update-api="UpdateApiThietLap" hide-default-footer="false"> </f-table>
            </v-col>
        </v-row>
    </div>
</template>
<script>
export default {
    props: [],
    data() {
        return {
            HeaderNhomLoaiLy: [
                {
                    text: "Tên nhóm loại ly",
                    value: "TenNhomLoaiLy",
                },
                {
                    text: "",
                    value: "xemChiTiet",
                    el: "t-button",
                    align: "right",
                    attr: {
                        color: "primary",
                        label: "Thiết lập",
                        ":action": [
                            {
                                CALL: "getNhomLoaiLyDiem",
                            },
                            {
                                EXE: "vueData.NhomLoaiLy_Selected = item",
                            },
                        ],
                    },
                },
            ],
            HeaderThietLap: [
                {
                    text: "Thứ tự",
                    value: "ThuTu",
                    align: "center"
                },
                {
                    text: "Tên nhóm loại ly",
                    value: "TenNhomLoaiLy",
                },
                {
                    text: "Mã loại ly",
                    value: "MaLoaiLy",
                    align: "center",
                },
                {
                    text: "Tên loại ly",
                    value: "TenLoaiLy",
                },
                {
                    text: "Hiển thị trên POS",
                    el: "v-chip",
                    align: "center",
                    value: "Is_HienThi",
                    attr: {"v-if": "item.Is_HienThi === 1", color: "success", ":small": true},
                    innerHTML: "Có",
                },
                {
                    text: "Điểm tối thiểu",
                    value: "DiemToiThieu",
                },
                {
                    text: "Điểm tối đa ",
                    value: "DiemToiDa",
                },
                {
                    text: "",
                    value: "ctrl-update",
                    align: "center",
                },
            ],
            UpdateFormThietLap: [
                {
                    el: "v-select",
                    attr: {
                        "v-model": "NhomLoaiLyID",
                        label: "Nhóm loại ly",
                        ":items": "vueData.DS_NhomLoaiLy",
                        "item-text": "TenNhomLoaiLy",
                        "item-value": "NhomLoaiLyID",
                        ":disabled": "vueData.IsEdit",
                    },
                    w: 6,
                },
                {
                    el: "v-select",
                    attr: {
                        "v-model": "LoaiLyID",
                        label: "Loại ly",
                        ":items": "vueData.DS_LoaiLy",
                        "item-text": "TenLoaiLy",
                        "item-value": "LoaiLyID",
                        ":disabled": "vueData.IsEdit",
                    },
                    w: 6,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "ThuTu",
                        label: "Thứ tự",
                        type: "number",
                    },
                    w: 2,
                },
                {
                    el: "v-select",
                    attr: {
                        "v-model": "Is_HienThi",
                        label: "Hiển thị trên POS",
                        ":items": "vueData.OptionHienThi",
                    },
                    w: 4,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "DiemToiThieu",
                        label: "Điểm tối thiểu",
                        ":disabled": "Is_HienThi === 1",
                        ":rules": false,
                    },
                    w: 3,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "DiemToiDa",
                        label: "Điểm tối đa",
                        ":disabled": "Is_HienThi === 1",
                        ":rules": false,
                    },
                    w: 3,
                },
            ],
            UpdateApiThietLap: {
                "default-item": {
                    NhomLoaiLyID: "vueData.NhomLoaiLy_Selected.NhomLoaiLyID",
                    Is_HienThi: 0,
                    ThuTu: 0
                },
                "new-action": {
                    IsEdit: false,
                },
                "edit-action": {
                    IsEdit: true,
                },
                new: {
                    CONFIRM: "Bạn có muốn thêm mới phần thiết lập",
                    API: "/eorder/NhomLoaiLyDiem_Insert",
                    IN: {
                        NhomLoaiLyID: "item.NhomLoaiLyID",
                        LoaiLyID: "item.LoaiLyID",
                        ThuTu: "item.ThuTu",
                        DiemToiThieu: "item.DiemToiThieu ?? 0",
                        DiemToiDa: "item.DiemToiDa ?? 0",
                        Is_HienThi: "item.Is_HienThi",
                    },
                    MESS: "Thêm mới thành công",
                    CALLBACK: {CALL: "getNhomLoaiLyDiem"},
                },
                edit: {
                    CONFIRM: "Bạn có muốn cập nhật phần thiết lập <br /><b>{{item.TenNhomLoaiLy}}</b>",
                    API: "/eorder/NhomLoaiLyDiem_Update",
                    IN: {
                        NhomLoaiLyDiemID: "item.NhomLoaiLyDiemID",
                        ThuTu: "item.ThuTu",
                        DiemToiThieu: "item.DiemToiThieu ?? 0",
                        DiemToiDa: "item.DiemToiDa ?? 0",
                        Is_HienThi: "item.Is_HienThi",
                    },
                    MESS: "Cập nhật thành công",
                    CALLBACK: {CALL: "getNhomLoaiLyDiem"},
                },
                delete: {
                    CONFIRM: "Bạn có muốn xóa phần thiết lập <br /><b>{{item.TenNhomLoaiLy}}</b>",
                    API: "/eorder/NhomLoaiLyDiem_Delete",
                    IN: {
                        NhomLoaiLyDiemID: "item.NhomLoaiLyDiemID",
                    },
                    MESS: "Xóa thành công",
                    CALLBACK: {CALL: "getNhomLoaiLyDiem"},
                },
            },
        }
    },
    mounted() {},
    computed: {
        labelThietLapDiem: function () {
            return `Thiết lập điểm - ${vueData.NhomLoaiLy_Selected?.TenNhomLoaiLy ?? ""}`
        },
    },
    watch: {},
    methods: {
        reloadData() {
            // lấy lại dữ liệu nhóm loại ly + thiết lập điểm
            this.getNhomLoaiLy()
            this.getNhomLoaiLyDiem()
        },
        getNhomLoaiLy() {
            ajaxCALL("/eorder/NhomLoaiLy_Select", {}, (res) => {
                if (res.data) {
                    vueData.DS_NhomLoaiLy = res.data
                }
            })
        },
        getNhomLoaiLyDiem() {
            ajaxCALL("/eorder/NhomLoaiLyDiem_Select", {}, (res) => {
                if (res.data) {
                    vueData.DS_ThietLap = res.data
                }
            })
        },
    },
}
</script>