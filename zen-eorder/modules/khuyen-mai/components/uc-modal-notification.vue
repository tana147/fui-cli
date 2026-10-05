<template>
    <v-dialog v-model="vueData.IsShowDialogNoti" scrollable width="1200">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>Thiết lập nội dung thông báo</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="vueData.IsShowDialogNoti = false"><v-icon>mdi-close</v-icon></v-btn>
            </v-toolbar>
            <v-card-text>
                <v-row>
                    <v-col md="12">
                        <p class="success--text subtitle-1 mb-0"><b>Thông báo nhận khuyến mãi</b></p>
                    </v-col>
                    <v-col md="2">
                        <f-image-update v-model="CTKhuyenMai.ThongBao_Nhan_HinhAnh_Url" v-on:update="onUpdateImage_Nhan" :api-upload="vueData.v_Set.apiFile" label="Ảnh thông báo" dialog-width="600" dialog-height="400" :size="{width: 500, height: 500}" quality="0.5" :croper-attr="{'stencil-props': {aspectRatio: 1}, 'default-size': {width: 9999, height: 9999}, transitions: true, 'image-restriction': 'fit-area'}" />
                    </v-col>
                    <v-col md="10">
                        <v-text-field v-model="CTKhuyenMai.ThongBao_Nhan_TieuDe" label="Tiêu đề" outlined dense hide-details></v-text-field>
                        <v-textarea class="mt-3" v-model="CTKhuyenMai.ThongBao_Nhan_NoiDung" label="Nội dung" rows="8" outlined dense hide-details></v-textarea>
                    </v-col>
                </v-row>
                <v-row>
                    <v-col md="12">
                        <p class="success--text subtitle-1 mb-0"><b>Thông báo sử dụng khuyến mãi</b></p>
                    </v-col>
                    <v-col md="2">
                        <f-image-update v-model="CTKhuyenMai.ThongBao_SuDung_HinhAnh_Url" v-on:update="onUpdateImage_SuDung" :api-upload="vueData.v_Set.apiFile" label="Ảnh thông báo" dialog-width="600" dialog-height="400" :size="{width: 500, height: 500}" quality="0.5" :croper-attr="{'stencil-props': {aspectRatio: 1}, 'default-size': {width: 9999, height: 9999}, transitions: true, 'image-restriction': 'fit-area'}" />
                    </v-col>
                    <v-col md="10">
                        <v-text-field v-model="CTKhuyenMai.ThongBao_SuDung_TieuDe" label="Tiêu đề" outlined dense hide-details></v-text-field>
                        <v-textarea class="mt-3" v-model="CTKhuyenMai.ThongBao_SuDung_NoiDung" label="Nội dung" rows="8" outlined dense hide-details></v-textarea>
                    </v-col>
                </v-row>
                <v-row>
                    <v-col md="12">
                        <p class="success--text subtitle-1 mb-0"><b>Thông báo hết hạn khuyến mãi</b></p>
                    </v-col>
                    <v-col md="2" class="text-center">
                        <f-image-update v-model="CTKhuyenMai.ThongBao_HetHan_HinhAnh_Url" v-on:update="onUpdateImage_HetHan" :api-upload="vueData.v_Set.apiFile" label="Ảnh thông báo" dialog-width="600" dialog-height="400" :size="{width: 500, height: 500}" quality="0.5" :croper-attr="{'stencil-props': {aspectRatio: 1}, 'default-size': {width: 9999, height: 9999}, transitions: true, 'image-restriction': 'fit-area'}" />
                    </v-col>
                    <v-col md="10">
                        <v-text-field v-model="CTKhuyenMai.ThongBao_HetHan_TieuDe" label="Tiêu đề" outlined dense hide-details></v-text-field>
                        <v-textarea class="mt-3" v-model="CTKhuyenMai.ThongBao_HetHan_NoiDung" label="Nội dung" rows="8" outlined dense hide-details></v-textarea>
                    </v-col>
                </v-row>
            </v-card-text>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="onSave" color="success">Lưu</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["ct_khuyenmai"],
    computed: {
        CTKhuyenMai: function () {
            return this.ct_khuyenmai
        },
    },
    methods: {
        onUpdateImage_Nhan: function ($event) {
            const $this = this
            $this.CTKhuyenMai.ThongBao_Nhan_HinhAnh = $event.returnData.Files[0].FileID
            $this.CTKhuyenMai.ThongBao_Nhan_HinhAnh_Url = vueData.v_Set.urlReturnFile + $event.returnData.Files[0].Url
        },
        onUpdateImage_SuDung: function ($event) {
            const $this = this
            $this.CTKhuyenMai.ThongBao_SuDung_HinhAnh = $event.returnData.Files[0].FileID
            $this.CTKhuyenMai.ThongBao_SuDung_HinhAnh_Url = vueData.v_Set.urlReturnFile + $event.returnData.Files[0].Url
        },
        onUpdateImage_HetHan: function ($event) {
            const $this = this
            $this.CTKhuyenMai.ThongBao_HetHan_HinhAnh = $event.returnData.Files[0].FileID
            $this.CTKhuyenMai.ThongBao_HetHan_HinhAnh_Url = vueData.v_Set.urlReturnFile + $event.returnData.Files[0].Url
        },
        onSave: function () {
            const $this = this
            const params = {
                ChuongTrinhID: $this.CTKhuyenMai.ChuongTrinhID,
                ThongBao_Nhan_TieuDe: $this.CTKhuyenMai.ThongBao_Nhan_TieuDe,
                ThongBao_Nhan_NoiDung: $this.CTKhuyenMai.ThongBao_Nhan_NoiDung,
                ThongBao_Nhan_HinhAnh: $this.CTKhuyenMai.ThongBao_Nhan_HinhAnh,
                ThongBao_SuDung_TieuDe: $this.CTKhuyenMai.ThongBao_SuDung_TieuDe,
                ThongBao_SuDung_NoiDung: $this.CTKhuyenMai.ThongBao_SuDung_NoiDung,
                ThongBao_SuDung_HinhAnh: $this.CTKhuyenMai.ThongBao_SuDung_HinhAnh,
                ThongBao_HetHan_TieuDe: $this.CTKhuyenMai.ThongBao_HetHan_TieuDe,
                ThongBao_HetHan_NoiDung: $this.CTKhuyenMai.ThongBao_HetHan_NoiDung,
                ThongBao_HetHan_HinhAnh: $this.CTKhuyenMai.ThongBao_HetHan_HinhAnh,
            }
            ajaxCALL("/eorder/ChuongTrinh_Update_ThongBao", params, (res) => {
                showMessage({type: "green", title: "Lưu thiết lập thông báo thành công"})
                vueData.IsShowDialogNoti = false
                runAction(vueData.getChuongTrinh)
            })
        },
    },
}
</script>
