<template>
    <div class="page-section">
        <v-card elevation="0">
            <v-toolbar dense flat>
                <v-toolbar-title>Mô tả sản phẩm</v-toolbar-title>
            </v-toolbar>
            <v-card-text style="width: 500px">
                <f-editor v-model="ct_sanpham.NoiDung" :height="400" :toolbar="toolbar" :imageapi="vueData.v_Set.apiImageAdapter" />
            </v-card-text>
            <v-card-actions>
                <v-btn color="success" v-on:click="onUpdateNoiDung()" elevation="0"><v-icon left>mdi-content-save</v-icon>Lưu mô tả</v-btn>
            </v-card-actions>
        </v-card>
    </div>
</template>
<script>
export default {
    props: ["ct_sanpham"],
    data() {
        return {
            toolbar: ["bold", "italic", "underline", "|", "undo", "redo", "removeFormat", "alignment", "fontSize", "fontFamily", "fontColor", "|", "bulletedList", "numberedList", "|", "imageUpload"],
        }
    },
    methods: {
        onUpdateNoiDung() {
            const $this = this
            const formData = $this.ct_sanpham
            const params = {
                SanPhamID: formData.SanPhamID,
                NoiDung: formData.NoiDung,
            }
            if (params.SanPhamID) {
                ajaxCALL("/eorder/SanPham_Update_NoiDung", params, (res) => {
                    showToast({type: "green", title: "Cập nhật nội dung mô tả thành công!"})
                })
            }
        },
    },
}
</script>
