<template>
    <v-dialog v-model="is_dialog" width="640" persistent>
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title> Ảnh menu</v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="$emit('on_close')">
                    <v-icon>mdi-close</v-icon>
                </v-btn>
            </v-toolbar>
            <v-card-text>
                <f-image-update 
                v-model="ct_menu[0].Menu_Url" 
                v-on:update="onUpload" 
                :api-upload="vueData.v_Set.apiFile" 
                label="Upload Ảnh Menu" 
                dialog-width="1000" 
                dialog-height="600" 
                :size="{width: 2880, height: 1620}" 
                quality="0.5" 
                :image-attr="{style: 'width: 100%;'}" 
                :croper-attr="{ 'default-size': {width: 99999, height: 99999}, transitions: true, 'image-restriction': 'fit-area'}" />
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    props: ["is_dialog", "ct_menu"],
    data() {
        return {}
    },
    computed: {},
    mounted: function () {},
    methods: {
        onUpload($event) {
            const $this = this
            $this.ct_menu[0].Menu_FileID = $event.returnData.Files[0].FileID
            $this.ct_menu[0].Menu_Url = vueData.v_Set.urlReturnFile + $event.returnData.Files[0].Url
            const params = {
                CuaHangID: $this.ct_menu[0].CuaHangID,
                Menu_FileID: $this.ct_menu[0].Menu_FileID,
            }
            ajaxCALL("/eorder/CuaHang_Update_Menu", params, (res) => {
                showMessage({type: "green", title: "Cập nhật ảnh menu thành công"})
                $this.$emit("on_close")
            })
        },
    },
}
</script>
