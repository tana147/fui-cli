<template>
    <v-dialog v-model="localDialog" scrollable width="450">
        <v-card>
            <v-toolbar dense flat>
                <v-toolbar-title>
                    Chọn cửa hàng áp dụng <span class="primary--text pl-1">({{ CuaHang_Selected.length }} cửa
                        hàng)</span>
                </v-toolbar-title>
                <v-spacer></v-spacer>
                <v-btn icon @click="localDialog = false">
                    <v-icon>mdi-close</v-icon>
                </v-btn>
            </v-toolbar>

            <v-card-text>
                <v-treeview v-model="CuaHang_Selected" selectable :items="DSCuaHang_Tree" selected-color="primary"
                    hoverable dense></v-treeview>
            </v-card-text>

            <v-card-actions>
                <v-spacer />
                <v-btn text @click="onSave" color="primary">Áp dụng</v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script>
    export default {
  props: ["is_dialog", "ct_cuahang"],
  data() {
    return {
      localDialog: false,         // dialog nội bộ
      CuaHang_Selected: [],
      DSCuaHang_Tree: []
    }
  },
  computed: {
    CTCuaHang() {
      return this.ct_cuahang[0] ?? null
    }
  },
  watch: {
    is_dialog(val) {
      this.localDialog = val
    },
    localDialog(val) {
      if (!val) this.$emit('on_close')
    }
  },
  mounted() {
    this.localDialog = this.is_dialog
    this.getStore()
  },
  methods: {
    getStore() {
      ajaxCALL("/eorder/CuaHang_Select_Tree", {}, (res) => {
        this.DSCuaHang_Tree = convertJsonToTree(res.data)
      })
    },
    onSave() {
      if (!this.CTCuaHang) return
      const params = {
        CuaHangID: this.CTCuaHang.CuaHangID,
        CuaHangApDungID: this.CuaHang_Selected.join(",") || "",
      }
      ajaxCALL("/eorder/CuaHangMenu_Update_CuaHang", params, (res) => {
        showMessage({type: "green", title: "Lưu thiết lập cửa hàng thành công"})
        this.localDialog = false
      })
    }
  }
}
</script>