<template>
    <div>
        <f-table
            class="mt-1"
            :excel="true"
            :items-per-page="-1"
            label="Danh sách loại ly"
            item-key="LoaiLyID"
            :items="vueData.DS_LoaiLy"
            :headers="HeaderLoaiLy"
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
            IsShowModelAdd: false,
            HeaderLoaiLy: [
                {
                    text: "Mã loại ly",
                    value: "MaLoaiLy",
                },
                {
                    text: "Tên loại ly",
                    value: "TenLoaiLy",
                },
                {
                    text: "Sản phẩm",
                    el: "span",
                    value: "MaSanPham",
                    innerHTML: "{{item.MaSanPham}} - {{item.TenSanPham}} <v-chip color='error' small class='ml-2' v-if='item.TinhTrang === 1'>Tạm hết</v-chip>",
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
                        "v-model": "MaLoaiLy",
                        label: "Mã loại ly",
                    },
                    w: 4,
                },
                {
                    el: "v-text-field",
                    attr: {
                        "v-model": "TenLoaiLy",
                        label: "Tên loại ly",
                    },
                    w: 8,
                },
                {
                    el: "v-combobox",
                    attr: {
                        "v-model": "vueData.SanPham_Selected",
                        label: "Chọn sản phẩm",
                        clearable: true,
                        ":items": "vueData.DSSanPham",
                        ":rules": false,
                    },
                    w: 12,
                },
            ],
            UpdateApi: {
                "edit-action": {
                    IF: "item.SanPhamID > 0",
                    THEN: {
                        EXE: "vueData.SanPham_Selected = {text: `${item.MaSanPham} - ${item.TenSanPham} (${item.GiaBan_CuaHang?.toLocaleString('vi-vn')}) [${item.VAT_CuaHang}%]`, value: item.SanPhamID}",
                    },
                    ELSE: {
                        EXE: "vueData.SanPham_Selected = null",
                    },
                },
                new: {
                    CONFIRM: "Bạn có muốn thêm mới loại ly",
                    API: "/eorder/Loaily_Insert",
                    IN: {
                        MaLoaiLy: "item.MaLoaiLy",
                        TenLoaiLy: "item.TenLoaiLy",
                        SanPhamID: "vueData.SanPham_Selected?.value ?? 0",
                    },
                    MESS: "Thêm mới thành công",
                    CALLBACK: { CALL: "getLoaiLy" },
                },
                edit: {
                    CONFIRM: "Bạn có muốn cập nhật loại ly <br /><b>{{item.TenLoaiLy}}</b>",
                    API: "/eorder/Loaily_Update",
                    IN: {
                        LoaiLyID: "item.LoaiLyID",
                        MaLoaiLy: "item.MaLoaiLy",
                        TenLoaiLy: "item.TenLoaiLy",
                        SanPhamID: "vueData.SanPham_Selected?.value ?? 0",
                    },
                    MESS: "Cập nhật thành công",
                    CALLBACK: { CALL: "getLoaiLy" },
                },
                delete: {
                    CONFIRM: "Bạn có muốn xóa loại ly <br /><b>{{item.TenLoaiLy}}</b>",
                    API: "/eorder/Loaily_Delete",
                    IN: {
                        LoaiLyID: "item.LoaiLyID",
                    },
                    MESS: "Xóa thành công",
                    CALLBACK: { CALL: "getLoaiLy" },
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
