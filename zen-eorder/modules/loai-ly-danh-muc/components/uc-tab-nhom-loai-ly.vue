<template>
    <div>
        <f-table
            class="mt-1"
            :excel="true"
            :items-per-page="-1"
            label="Danh sách nhóm loại ly"
            item-key="LoaiLyID"
            :items="vueData.DS_NhomLoaiLy"
            :headers="HeaderTable"
            height="calc(100vh - 131px)"
            :show-search="true"
            :fixed-header="true"
            dense
            :update-form="UpdateForm"
            :update-api="UpdateApi"
            hide-default-footer="false"
        >
        </f-table>
    </div>
</template>
<script>
export default {
    props: [],
    data() {
        return {
            HeaderTable: [
                {
                    text: "Tên nhóm loại ly",
                    value: "TenNhomLoaiLy",
                },
                {
                    text: "Mô tả",
                    value: "MoTa",
                },
                {
                    text: "",
                    value: "ctrl-update",
                    align: "center",
                },
            ],
            UpdateForm: [
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "TenNhomLoaiLy",
                        label: "Tên nhóm loại ly",
                    },
                    w: 12,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "MoTa",
                        label: "Mô tả",
                        ":rules": false,
                    },
                    w: 12,
                },
            ],
            UpdateApi: {
                new: {
                    CONFIRM: "Bạn có muốn thêm mới nhóm loại ly",
                    API: "/eorder/NhomLoaiLy_Insert",
                    IN: {
                        TenNhomLoaiLy: "item.TenNhomLoaiLy",
                        MoTa: "item.MoTa",
                    },
                    MESS: "Thêm mới thành công",
                    CALLBACK: { CALL: "getNhomLoaiLy" },
                },
                edit: {
                    CONFIRM: "Bạn có muốn cập nhật nhóm loại ly <br /><b>{{item.TenNhomLoaiLy}}</b>",
                    API: "/eorder/NhomLoaiLy_Update",
                    IN: {
                        NhomLoaiLyID: "item.NhomLoaiLyID",
                        TenNhomLoaiLy: "item.TenNhomLoaiLy",
                        MoTa: "item.MoTa",
                    },
                    MESS: "Cập nhật thành công",
                    CALLBACK: { CALL: "getNhomLoaiLy" },
                },
                delete: {
                    CONFIRM: "Bạn có muốn xóa nhóm loại ly <br /><b>{{item.TenNhomLoaiLy}}</b>",
                    API: "/eorder/NhomLoaiLy_Delete",
                    IN: {
                        NhomLoaiLyID: "item.NhomLoaiLyID",
                    },
                    MESS: "Xóa thành công",
                    CALLBACK: { CALL: "getNhomLoaiLy" },
                },
            },
        }
    },
    mounted() {},
    computed: {},
    watch: {},
    methods: {},
}
</script>
